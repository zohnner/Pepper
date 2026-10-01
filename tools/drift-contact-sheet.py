#!/usr/bin/env python3
"""drift-contact-sheet.py — visual drift-review harness (drift firewall, manual gate).

Usage: drift-contact-sheet.py <ep>   (e.g. drift-contact-sheet.py ep002)

Builds pack/drift-review.jpg: model sheet + marks detail (the authorities)
on top, episode stills below in a labeled grid — the 2-minute human eyeball.
Also appends one row per still to tools/drift-log.csv (verdict left blank;
the agent fills ear/stripe/eyes/socks/verdict during review).

Per the drift-firewall spec, automated verdicts start as HUMAN until the
model judge has 20 consecutive agreements with human verdicts. This script
is the harness; the judgment stays human for now.
"""
import csv, os, sys
from datetime import date
from PIL import Image, ImageDraw

ROOT = "/home/hatch/workspace/pepper-series"
REF = f"{ROOT}/bible/reference"
MODEL_SHEET = f"{REF}/media-generation-pepper-model-sheet-0-b738aac2-6ba8-437a-abb0-a4d5fd7aa41a.webp"
MARKS_DETAIL = f"{REF}/media-generation-pepper-marks-detail-0-2a4503b8-e5d8-46bc-ba7d-d64d32b1c4b6.webp"
LOG = f"{ROOT}/tools/drift-log.csv"
COLS = 3
THUMB_W = 360


def thumb(img, w):
    r = w / img.width
    return img.convert("RGB").resize((w, int(img.height * r)))


def labeled(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, img.width, 34], fill=(11, 14, 20))
    d.text((10, 8), text, fill=(232, 163, 61))
    return img


def main():
    ep = sys.argv[1]
    epdir = f"{ROOT}/episodes/{ep}"
    stills = sorted(
        f for f in os.listdir(f"{epdir}/assets")
        if f.endswith((".webp", ".png", ".jpg"))
        and "shot" in f
        and "_superseded" not in f
        and "anim" not in f
    )
    if not stills:
        sys.exit(f"no stills found in {epdir}/assets")

    auth = [labeled(thumb(Image.open(MODEL_SHEET), 540), "AUTHORITY: model sheet"),
            labeled(thumb(Image.open(MARKS_DETAIL), 540), "AUTHORITY: marks detail")]
    tiles = [labeled(thumb(Image.open(f"{epdir}/assets/{s}"), THUMB_W),
                     f"{ep} / {s[:44]}") for s in stills]

    rows, row, x = [], [], 0
    all_tiles = auth + tiles
    for t in all_tiles:
        row.append(t)
        if len(row) == COLS:
            rows.append(row); row = []
    if row:
        rows.append(row)
    W = COLS * 560
    H = sum(max(t.height for t in r) + 12 for r in rows)
    sheet = Image.new("RGB", (W, H), (20, 24, 32))
    y = 0
    for r in rows:
        rh = max(t.height for t in r)
        x = 0
        for t in r:
            sheet.paste(t, (x + (560 - t.width) // 2, y)); x += 560
        y += rh + 12
    out = f"{epdir}/pack/drift-review.jpg"
    sheet.save(out, quality=88)
    print(f"wrote {out} ({len(stills)} stills)")

    new = not os.path.exists(LOG)
    with open(LOG, "a", newline="") as fh:
        w = csv.writer(fh)
        if new:
            w.writerow(["date", "episode", "shot", "prompt_hash", "model", "vendor",
                        "ear", "stripe", "eyes", "socks", "verdict", "notes"])
        for s in stills:
            w.writerow([date.today().isoformat(), ep, s[:44], "", "", "",
                        "", "", "", "", "", ""])
    print(f"appended {len(stills)} rows to tools/drift-log.csv (verdicts pending)")


if __name__ == "__main__":
    main()
