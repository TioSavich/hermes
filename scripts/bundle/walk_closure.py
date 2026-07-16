#!/usr/bin/env python3
"""Walk the transitive local-reference closure of one or more entry HTML pages.

Given entry files (repo-relative), this script follows href/src attributes,
CSS url(...) references, path-shaped JavaScript string literals, and
path-shaped string values inside JSON documents, collecting every file the
entry pages reach. External URLs (http/https/data/mailto) are ignored.
Root-absolute paths ("/api/...") are recorded as server routes, not files.

Only git-tracked files are eligible for bundling. A referenced file that
exists locally but is untracked (for example ASKTM student-work images) is
reported as a named skip, never copied: untracked local data is not
distributed. A referenced file that does not exist at all is reported as
missing.

Usage:
  python3 scripts/bundle/walk_closure.py --entry more-zeeman/audience-index.html
  python3 scripts/bundle/walk_closure.py --entry A.html --entry B.html \
      --copy-to build/bundles/name
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict

# File types whose contents are scanned for further references.
SCANNABLE = {".html", ".htm", ".css", ".js", ".mjs", ".json"}

# A candidate string counts as a local path only when the WHOLE string looks
# like a relative path ending in one of these extensions.
PATH_RE = re.compile(
    r"[^\"<>|*?\n]+\.(?:html?|css|js|mjs|json|png|jpe?g|gif|svg|webp|ico|"
    r"pdf|woff2?|ttf|otf|eot|mp4|webm|csv|txt|md)",
    re.IGNORECASE,
)

ATTR_RE = re.compile(r"""(?:href|src|poster)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
CSS_URL_RE = re.compile(r"""url\(\s*["']?([^"')]+)["']?\s*\)""", re.IGNORECASE)
JS_STR_RE = re.compile(r"""["']([^"'\n]{1,300})["']""")

SKIP_PREFIXES = ("http://", "https://", "//", "data:", "mailto:", "javascript:", "tel:", "#")

# Root-absolute references count as server routes only when they look like
# real routes; URL-encoded fragments of inline data-URIs are rejected.
ROUTE_RE = re.compile(r"/[\w\-./]*")


def tracked_files(repo_root):
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=repo_root, capture_output=True, check=True
    ).stdout.decode("utf-8", "replace")
    return set(p for p in out.split("\0") if p)


def clean_candidate(raw):
    """Strip query/fragment; reject externals and non-path strings."""
    s = raw.strip()
    if not s or s.lower().startswith(SKIP_PREFIXES):
        return None, None
    s = s.split("#", 1)[0].split("?", 1)[0]
    if not s:
        return None, None
    if s.startswith("/"):
        if ROUTE_RE.fullmatch(s):
            return None, s  # server route (needs the live app), not a bundle file
        return None, None
    if not PATH_RE.fullmatch(s):
        return None, None
    # Reject ellipsis pseudo-paths from prose/comments (".../render/shell.js").
    if any(part.strip(".") == "" and len(part) > 2 for part in s.split("/")):
        return None, None
    return s, None


def extract_candidates(rel_path, text):
    """Return the set of raw path candidates and server routes found in text."""
    ext = os.path.splitext(rel_path)[1].lower()
    raws = set()
    routes = set()

    def take(raw):
        cand, route = clean_candidate(raw)
        if cand:
            raws.add(cand)
        elif route:
            routes.add(route)

    if ext in (".html", ".htm"):
        for m in ATTR_RE.finditer(text):
            take(m.group(1))
        for m in CSS_URL_RE.finditer(text):
            take(m.group(1))
        for m in JS_STR_RE.finditer(text):
            take(m.group(1))
    elif ext == ".css":
        for m in CSS_URL_RE.finditer(text):
            take(m.group(1))
    elif ext in (".js", ".mjs"):
        for m in JS_STR_RE.finditer(text):
            take(m.group(1))
    elif ext == ".json":
        try:
            doc = json.loads(text)
        except ValueError:
            return raws, routes

        def walk(node):
            if isinstance(node, str):
                take(node)
            elif isinstance(node, list):
                for x in node:
                    walk(x)
            elif isinstance(node, dict):
                for x in node.values():
                    walk(x)

        walk(doc)
    return raws, routes


def resolve(repo_root, base_dirs, cand, tracked):
    """Resolve a candidate against each base directory, then the repo root."""
    tries = [os.path.normpath(os.path.join(b, cand)) for b in sorted(base_dirs)]
    tries.append(os.path.normpath(cand))
    for rel in tries:
        if rel.startswith(".."):
            continue
        if rel in tracked or os.path.exists(os.path.join(repo_root, rel)):
            return rel
    return None


# Assets whose internal paths resolve against the PAGE that loads them, not
# against their own location (shell.js builds nav links this way). These
# inherit their referrers' base directories as extra resolution bases.
INHERITS_BASES = {".js", ".mjs", ".css", ".json"}


def walk(repo_root, entries):
    tracked = tracked_files(repo_root)
    bundled = set()
    local_only = set()        # exists on disk, not tracked: named skip
    missing = defaultdict(set)  # unresolved candidate -> referrers
    routes = defaultdict(set)   # server route -> referrers
    bases = defaultdict(set)    # file -> base dirs its references resolve against
    queue = []

    for entry in entries:
        rel = os.path.normpath(entry)
        if not os.path.exists(os.path.join(repo_root, rel)):
            print(f"ERROR: entry not found: {rel}", file=sys.stderr)
            sys.exit(2)
        if rel not in tracked:
            print(f"ERROR: entry is not git-tracked: {rel}", file=sys.stderr)
            sys.exit(2)
        bundled.add(rel)
        bases[rel].add(os.path.dirname(rel))
        queue.append(rel)

    while queue:
        rel = queue.pop()
        if os.path.splitext(rel)[1].lower() not in SCANNABLE:
            continue
        try:
            with open(os.path.join(repo_root, rel), encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError as e:
            print(f"WARNING: cannot read {rel}: {e}", file=sys.stderr)
            continue
        raws, found_routes = extract_candidates(rel, text)
        for r in found_routes:
            routes[r].add(rel)
        for cand in sorted(raws):
            target = resolve(repo_root, bases[rel], cand, tracked)
            if target is None:
                missing[cand].add(rel)
            elif target in tracked:
                new_bases = {os.path.dirname(target)}
                if os.path.splitext(target)[1].lower() in INHERITS_BASES:
                    new_bases |= bases[rel]
                grew = not new_bases <= bases[target]
                bases[target] |= new_bases
                if target not in bundled or grew:
                    bundled.add(target)
                    queue.append(target)
            else:
                local_only.add(target)

    # A candidate that later resolved through another referrer's bases is not
    # missing; drop stale entries.
    for cand in list(missing):
        for rel_bases in bases.values():
            if resolve(repo_root, rel_bases, cand, tracked):
                del missing[cand]
                break

    # A candidate under a gitignored root (ASKTM_Data, runtime outputs) is
    # declared local data, not a broken reference: on the maintainer's machine
    # it exists untracked, on a fresh clone it is absent, and in both cases the
    # honest category is "local data, not distributed".
    ignored_tops = ignored_top_dirs(repo_root, missing)
    for cand in list(missing):
        rel = os.path.normpath(cand)
        if not rel.startswith("..") and rel.split("/", 1)[0] in ignored_tops:
            local_only.add(rel)
            del missing[cand]

    return bundled, local_only, missing, routes


def ignored_top_dirs(repo_root, missing):
    """Top-level path components of unresolved candidates that git ignores."""
    tops = set()
    for cand in missing:
        rel = os.path.normpath(cand)
        if not rel.startswith(".."):
            tops.add(rel.split("/", 1)[0])
    if not tops:
        return set()
    proc = subprocess.run(
        ["git", "check-ignore", "--stdin"],
        cwd=repo_root, input="\n".join(sorted(tops)),
        capture_output=True, text=True,
    )
    # exit 0 = some ignored, 1 = none ignored; anything else is a real error
    if proc.returncode > 1:
        print(f"WARNING: git check-ignore failed: {proc.stderr.strip()}", file=sys.stderr)
        return set()
    return set(proc.stdout.splitlines())


def group_by_top(paths):
    groups = defaultdict(int)
    for p in paths:
        groups[p.split("/", 1)[0] + "/" if "/" in p else "(root)"] += 1
    return sorted(groups.items(), key=lambda kv: -kv[1])


def report(repo_root, bundled, local_only, missing, routes):
    total = 0
    sizes = []
    for rel in bundled:
        try:
            n = os.path.getsize(os.path.join(repo_root, rel))
        except OSError:
            n = 0
        total += n
        sizes.append((n, rel))
    print(f"closure: {len(bundled)} tracked files, {total / 1e6:.1f} MB")
    for top, count in group_by_top(bundled):
        print(f"  {top}: {count}")
    print("largest files:")
    for n, rel in sorted(sizes, reverse=True)[:8]:
        print(f"  {n / 1e6:6.1f} MB  {rel}")

    if local_only:
        print(f"\nSKIPPED (local data, not distributed): {len(local_only)} files")
        for top, count in group_by_top(local_only):
            print(f"  {top}: {count}  (untracked or gitignored; absent on a fresh clone)")
    if missing:
        print(f"\nMISSING (referenced but not found): {len(missing)}")
        for cand in sorted(missing):
            refs = ", ".join(sorted(missing[cand])[:3])
            print(f"  {cand}   <- {refs}")
    if routes:
        print(f"\nSERVER ROUTES (need the live app, not bundled): {len(routes)}")
        for r in sorted(routes):
            refs = ", ".join(sorted(routes[r])[:2])
            print(f"  {r}   <- {refs}")
    return total


def copy_bundle(repo_root, bundled, dest):
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    for rel in sorted(bundled):
        src = os.path.join(repo_root, rel)
        dst = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
    print(f"\ncopied {len(bundled)} files -> {dest}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--entry", action="append", required=True,
                    help="repo-relative entry file; repeatable")
    ap.add_argument("--copy-to", help="copy the closure into this directory")
    ap.add_argument("--repo-root", default=None,
                    help="repository root (default: git toplevel of cwd)")
    args = ap.parse_args()

    repo_root = args.repo_root or subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    ).stdout.strip()

    bundled, local_only, missing, routes = walk(repo_root, args.entry)
    report(repo_root, bundled, local_only, missing, routes)
    if args.copy_to:
        dest = args.copy_to
        if not os.path.isabs(dest):
            dest = os.path.join(repo_root, dest)
        copy_bundle(repo_root, bundled, dest)


if __name__ == "__main__":
    main()
