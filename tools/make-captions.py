#!/usr/bin/env python3
"""make-captions.py — word-accurate captions from beats.yaml + voiceover audio.

Usage:
  make-captions.py voiceover-txt <beats.yaml> <out.txt>
      Write the TTS input text (beats joined) — single source of truth.
  make-captions.py captions <beats.yaml> <voiceover.mp3> <out.srt>
      Transcribe with faster-whisper (word timestamps), align each beat's
      caption text to the audio, and emit captions.srt with the author's
      original line breaks.

beats.yaml format:
  voice: avocado_v2:Lily        # locked Pepper voice (override per episode)
  beats:
    - shot: "00"
      caption: |
        Marlow says I owe him forty-seven cranks.
        I counted the lift chains myself. There are only twelve.
    - shot: "01"
      caption: |
        ...

Only captioned beats are listed. The silent end-card shot needs no entry —
the assembler gives clips past the last caption a TAIL_DUR hold.
"""
import re
import sys
import os
import unicodedata
from difflib import SequenceMatcher

# Sandbox quirk: no_proxy/NO_PROXY contain bracketed IPv6 literals ([::1])
# that crash this httpx version when huggingface_hub builds its client.
# huggingface.co is never a no_proxy host, so dropping them is safe.
os.environ.pop("no_proxy", None)
os.environ.pop("NO_PROXY", None)

VENV_PY = "/home/hatch/workspace/.venvs/pepper/bin/python"


def load_beats(path):
    """Minimal YAML parse — only handles the beats.yaml shape above."""
    text = open(path).read()
    beats, cur, in_caption, buf = [], None, False, []
    voice = "avocado_v2:Lily"
    for line in text.split("\n"):
        m = re.match(r"^voice:\s*(\S+)\s*$", line)
        if m:
            voice = m.group(1)
            continue
        m = re.match(r"^\s*-\s*shot:\s*\"?(\d+)\"?\s*$", line)
        if m:
            if cur:
                cur["caption"] = "\n".join(buf).strip()
                beats.append(cur)
            cur, buf, in_caption = {"shot": m.group(1)}, [], False
            continue
        m = re.match(r"^\s*caption:\s*\|\s*$", line)
        if m and cur is not None:
            in_caption = True
            continue
        if in_caption and cur is not None:
            if re.match(r"^\s{4,}\S", line) or line.strip() == "":
                buf.append(line.strip())
            else:
                in_caption = False
    if cur:
        cur["caption"] = "\n".join(buf).strip()
        beats.append(cur)
    return voice, [b for b in beats if b.get("caption")]


def norm_tokens(s):
    s = unicodedata.normalize("NFKD", s).lower()
    s = re.sub(r"[’‘`]", "'", s)
    s = re.sub(r"[^a-z0-9'\s]", " ", s)
    return [t for t in s.split() if t]


def write_voiceover_txt(beats_path, out_path):
    _, beats = load_beats(beats_path)
    text = " ".join(re.sub(r"\s+", " ", b["caption"]).strip() for b in beats)
    open(out_path, "w").write(text + "\n")
    print(f"wrote {out_path} ({len(text)} chars, {len(beats)} beats)")


def transcribe(audio_path):
    # Compat shim: faster-whisper passes metadata_errors= to av.open(), but
    # av>=19 removed that kwarg. Our mp3s are clean TTS output, so dropping
    # it (default behavior) is safe.
    import av
    _orig_open = av.open

    def _open(file, mode="r", *args, **kwargs):
        kwargs.pop("metadata_errors", None)
        return _orig_open(file, mode, *args, **kwargs)

    av.open = _open
    from faster_whisper import WhisperModel

    # Local model dir (downloaded once via curl — avoids huggingface_hub's
    # network path, which trips the sandbox proxy handling).
    model = WhisperModel("/home/hatch/workspace/.venvs/pepper/models/faster-whisper-base",
                         device="cpu", compute_type="int8")
    segments, _ = model.transcribe(audio_path, word_timestamps=True, language="en")
    words = []
    for seg in segments:
        for w in seg.words or []:
            words.append({"word": w.word.strip(), "start": w.start, "end": w.end})
    return words


def align_beats(beats, words):
    """Map each beat to a (start, end) span in the audio via token alignment."""
    expected, beat_of_token = [], []
    for bi, b in enumerate(beats):
        toks = norm_tokens(b["caption"])
        b["_toks"] = toks
        for t in toks:
            expected.append(t)
            beat_of_token.append(bi)
    actual = [norm_tokens(w["word"])[0] if norm_tokens(w["word"]) else "" for w in words]

    sm = SequenceMatcher(None, expected, actual, autojunk=False)
    exp2act = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for k in range(i2 - i1):
                exp2act[i1 + k] = j1 + k

    def map_idx(ei):
        if ei in exp2act:
            return exp2act[ei]
        # interpolate between nearest mapped neighbors
        lo = ei - 1
        while lo >= 0 and lo not in exp2act:
            lo -= 1
        hi = ei + 1
        while hi < len(expected) and hi not in exp2act:
            hi += 1
        if lo >= 0 and hi < len(expected):
            frac = (ei - lo) / (hi - lo)
            return int(round(exp2act[lo] + frac * (exp2act[hi] - exp2act[lo])))
        if lo >= 0:
            return min(exp2act[lo] + (ei - lo), len(words) - 1)
        if hi < len(expected):
            return max(exp2act[hi] - (hi - ei), 0)
        return 0

    matched = len(exp2act)
    print(f"alignment: {matched}/{len(expected)} tokens exact "
          f"({100.0 * matched / max(len(expected), 1):.1f}%)", file=sys.stderr)
    if matched < 0.85 * len(expected):
        print("WARNING: low alignment coverage — check voiceover vs beats text",
              file=sys.stderr)

    spans, idx = [], 0
    for b in beats:
        n = len(b["_toks"])
        ai0 = max(0, min(map_idx(idx), len(words) - 1))
        ai1 = max(0, min(map_idx(idx + n - 1), len(words) - 1))
        if ai1 < ai0:
            ai0, ai1 = ai1, ai0
        spans.append((words[ai0]["start"], words[ai1]["end"]))
        idx += n
    return spans


def srt_ts(sec):
    ms = int(round(sec * 1000))
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def write_captions(beats_path, audio_path, out_path):
    _, beats = load_beats(beats_path)
    words = transcribe(audio_path)
    if not words:
        sys.exit("transcription produced no words — aborting")
    spans = align_beats(beats, words)

    # pad + clamp so captions never overlap
    padded = []
    for i, (s, e) in enumerate(spans):
        s = max(0.0, s - 0.08)
        e = e + (0.25 if i == len(spans) - 1 else 0.20)
        padded.append([s, e])
    for i in range(1, len(padded)):
        if padded[i][0] < padded[i - 1][1]:
            mid = (padded[i][0] + padded[i - 1][1]) / 2
            padded[i - 1][1] = mid
            padded[i][0] = mid

    out = []
    for i, b in enumerate(beats):
        s, e = padded[i]
        if e - s < 0.4:
            print(f"WARNING: beat {b['shot']} caption only {e - s:.2f}s", file=sys.stderr)
        out.append(f"{i + 1}\n{srt_ts(s)} --> {srt_ts(e)}\n{b['caption'].strip()}\n")
    open(out_path, "w").write("\n".join(out))
    print(f"wrote {out_path} ({len(beats)} captions)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "voiceover-txt":
        _, b, o = sys.argv[1:4]
        write_voiceover_txt(b, o)
    elif cmd == "voice":
        voice, _ = load_beats(sys.argv[2])
        print(voice)
    elif cmd == "shots":
        _, beats = load_beats(sys.argv[2])
        print(" ".join(b["shot"] for b in beats))
    elif cmd == "captions":
        _, b, a, o = sys.argv[1:5]
        write_captions(b, a, o)
    else:
        sys.exit(f"unknown command {cmd}\n" + __doc__)
