#!/usr/bin/env python3
"""push-pack.py — push an episode pack (and optionally tools) to zohnner/Pepper.

Usage:
  push-pack.py ep002 "commit message" [--tools] [--dry-run]

Pushes via the GitHub Contents API (one commit per file):
  episodes/<ep>/pack/rough-cut.mp4
  episodes/<ep>/pack/captions.ass
  episodes/<ep>/pack/edit-notes.md
  episodes/<ep>/pack/debt.json        (if present)
  episodes/<ep>/beats.yaml
  episodes/<ep>/script.md             (if present)
  episodes/<ep>/meta.md               (if present)
With --tools, also pushes every file under tools/ (scripts, specs, fonts).

Auth: dynamic_credentials surrogate for custom.github (same as the scaffold push).
"""
import sys, json, base64, os, urllib.request, urllib.error
sys.path.insert(0, "/opt/hatch/skills/skill-creator/bin")
from dynamic_credentials import add_surrogate_to_request

REPO = "zohnner/Pepper"
LOCAL_ROOT = "/home/hatch/workspace/pepper-series"


def req(method, path, data=None):
    url = f"https://api.github.com{path}"
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method,
        headers={"Accept": "application/vnd.github+json", "User-Agent": "muse-agent"})
    add_surrogate_to_request(r, "custom.github", allowed_hosts=["api.github.com"])
    try:
        with urllib.request.urlopen(r) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} {method} {path}: {e.read().decode()[:300]}", file=sys.stderr)
        raise


def push_file(rel, msg, dry_run=False):
    local = f"{LOCAL_ROOT}/{rel}"
    if not os.path.exists(local):
        print(f"skip {rel} (not found)")
        return None
    if dry_run:
        print(f"would push {rel}")
        return "dryrun"
    with open(local, "rb") as fh:
        content = base64.b64encode(fh.read()).decode()
    try:
        cur = req("GET", f"/repos/{REPO}/contents/{rel}")
        sha = cur.get("sha")
    except urllib.error.HTTPError as e:
        sha = None if e.code == 404 else (_ for _ in ()).throw(e)
    payload = {"message": msg, "content": content}
    if sha:
        payload["sha"] = sha
    res = req("PUT", f"/repos/{REPO}/contents/{rel}", payload)
    csha = res["commit"]["sha"]
    print(f"ok {rel} -> {csha[:7]}")
    return csha


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    ep, msg = sys.argv[1], sys.argv[2]
    dry_run = "--dry-run" in sys.argv
    with_tools = "--tools" in sys.argv

    files = [
        f"episodes/{ep}/pack/rough-cut.mp4",
        f"episodes/{ep}/pack/captions.ass",
        f"episodes/{ep}/pack/edit-notes.md",
        f"episodes/{ep}/pack/debt.json",
        f"episodes/{ep}/beats.yaml",
        f"episodes/{ep}/script.md",
        f"episodes/{ep}/meta.md",
    ]
    if with_tools:
        for root, _, names in os.walk(f"{LOCAL_ROOT}/tools"):
            for n in sorted(names):
                full = os.path.join(root, n)
                files.append(os.path.relpath(full, LOCAL_ROOT))
    shas = [s for s in (push_file(f, msg, dry_run) for f in files) if s]
    print(f"pushed {len(shas)} files")


if __name__ == "__main__":
    main()
