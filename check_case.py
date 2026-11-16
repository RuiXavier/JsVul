#!/usr/bin/env python3
"""check_case.py - check case.json files against SCHEMA.md.

Usage: python3 check_case.py [case.json ...]     check these files (default: every cases/*/case.json)
       python3 check_case.py --staged             check the staged version of every staged cases/*/case.json
       python3 check_case.py --install-hook       make the pre-commit and pre-merge-commit hooks run --staged

It prints one line per problem and exits with 1 when it finds one. `git commit --no-verify` skips the hook.
Only the Python standard library is used."""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
CASE_KEYS = {"name", "version", "repo", "sha", "from", "origin", "role", "entry", "capabilities", "vulnerabilities"}
CASE_OPTIONAL = {"subdir", "siblings"}
ORIGINS = {"npm", "repository"}
ROLES = {"library", "application", "mcp", "extension", "action"}
VULN_KEYS = {"id", "from", "cve", "ghsa", "snyk", "cwe", "class", "sinks", "sources", "poc", "fix"}
VULN_OPTIONAL = {"originalSink", "originalClass", "sourceKinds"}
CLASSES = {"code-injection", "command-injection", "path-traversal", "stored-command-injection"}
SOURCE_KINDS = {"environment", "file", "process-output"}
LOC_KEYS = {"file", "startline", "startcol", "endline", "endcol", "range"}
FIX_KEYS = {"version", "commit", "patch", "locations"}


def is_int_or_none(x):
    return x is None or (isinstance(x, int) and not isinstance(x, bool) and x >= 1)


def check_location(loc, where, prefix, out):
    if not isinstance(loc, dict):
        return out.append(f"{where}: a location is no object")
    missing, extra = LOC_KEYS - set(loc), set(loc) - LOC_KEYS - {"code"}
    if missing or extra:
        out.append(f"{where}: location keys missing {sorted(missing)} unknown {sorted(extra)}")
    if not isinstance(loc.get("file"), str) or (prefix and not loc["file"].startswith(prefix)):
        out.append(f"{where}: file {loc.get('file')!r} does not start with {prefix!r}")
    if not (isinstance(loc.get("startline"), int) and loc["startline"] >= 1):
        out.append(f"{where}: startline {loc.get('startline')!r} is no line number")
    for k in ("startcol", "endline", "endcol"):
        if not is_int_or_none(loc.get(k)):
            out.append(f"{where}: {k} {loc.get(k)!r} is no number or null")
    if not isinstance(loc.get("range"), bool):
        out.append(f"{where}: range {loc.get('range')!r} is no boolean")
    if "code" in loc and not (loc["code"] is None or isinstance(loc["code"], str)):
        out.append(f"{where}: code is no string or null")


def check_case(case, case_dir, where):
    out = []
    if not isinstance(case, dict):
        return [f"{where}: case.json holds no object"]
    if "type" in case:
        out.append(f"{where}: `type` is replaced by `origin` and `role` (SCHEMA.md)")
    missing, extra = CASE_KEYS - set(case), set(case) - CASE_KEYS - CASE_OPTIONAL - {"type"}
    if missing:
        out.append(f"{where}: missing case fields {sorted(missing)}")
    if extra:
        out.append(f"{where}: unknown case fields {sorted(extra)}")
    if case.get("origin") not in ORIGINS:
        out.append(f"{where}: origin {case.get('origin')!r} is not one of {sorted(ORIGINS)}")
    if case.get("role") not in ROLES:
        out.append(f"{where}: role {case.get('role')!r} is not one of {sorted(ROLES)}")
    froms = case.get("from")
    if not (isinstance(froms, list) and froms and all(isinstance(f, str) for f in froms)):
        out.append(f"{where}: from is no non-empty list of names")
        froms = []
    entry = case.get("entry")
    if not (isinstance(entry, list) and entry and all(isinstance(e, str) for e in entry)):
        out.append(f"{where}: entry is no non-empty list of paths")
    elif os.path.isdir(case_dir):
        for e in entry:
            if not os.path.exists(os.path.join(case_dir, e)):
                out.append(f"{where}: entry path {e} does not exist")
    if not (case.get("capabilities") is None or isinstance(case.get("capabilities"), dict)):
        out.append(f"{where}: capabilities is no object or null")
    vulns = case.get("vulnerabilities")
    if not (isinstance(vulns, list) and vulns):
        return out + [f"{where}: vulnerabilities is no non-empty list"]
    for i, v in enumerate(vulns):
        w = f"{where}: vulnerability {i} ({v.get('id') if isinstance(v, dict) else '?'})"
        if not isinstance(v, dict):
            out.append(f"{w}: no object")
            continue
        missing, extra = VULN_KEYS - set(v), set(v) - VULN_KEYS - VULN_OPTIONAL
        if missing or extra:
            out.append(f"{w}: fields missing {sorted(missing)} unknown {sorted(extra)}")
        if v.get("from") not in froms:
            out.append(f"{w}: from {v.get('from')!r} is not in the case's from")
        if v.get("class") not in CLASSES:
            out.append(f"{w}: class {v.get('class')!r} is not one of {sorted(CLASSES)}")
        for k in ("cve", "ghsa", "snyk", "cwe"):
            if not isinstance(v.get(k), list):
                out.append(f"{w}: {k} is no list")
        if not (isinstance(v.get("sinks"), list) and v["sinks"]):
            out.append(f"{w}: sinks is no non-empty list")
        for j, s in enumerate(v.get("sinks") or []):
            check_location(s, f"{w} sink {j}", "package/", out)
        for j, s in enumerate(v.get("sources") if isinstance(v.get("sources"), list) else []):
            check_location(s, f"{w} source {j}", "package/", out)
        if not isinstance(v.get("sources"), list):
            out.append(f"{w}: sources is no list")
        for j, s in enumerate(v.get("originalSink") or []):
            check_location(s, f"{w} originalSink {j}", "", out)
        if "sourceKinds" in v and not (isinstance(v["sourceKinds"], list) and set(v["sourceKinds"]) <= SOURCE_KINDS):
            out.append(f"{w}: sourceKinds {v['sourceKinds']!r} holds values outside {sorted(SOURCE_KINDS)}")
        if not (v.get("poc") is None or isinstance(v.get("poc"), str)):
            out.append(f"{w}: poc is no string or null")
        fix = v.get("fix")
        if not (isinstance(fix, dict) and set(fix) == FIX_KEYS and isinstance(fix.get("locations"), list)):
            out.append(f"{w}: fix is no object with {sorted(FIX_KEYS)}")
        else:
            for j, s in enumerate(fix["locations"]):
                check_location(s, f"{w} fix location {j}", "", out)
    return out


def git(*args):
    return subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=True, check=True).stdout


def install_hook():
    hooks = git("rev-parse", "--git-path", "hooks").strip()
    hooks = hooks if os.path.isabs(hooks) else os.path.join(ROOT, hooks)
    for name in ("pre-commit", "pre-merge-commit"):
        path = os.path.join(hooks, name)
        if os.path.exists(path) and "check_case.py" not in open(path).read():
            sys.exit(f"{path} exists and is another hook; add `python3 -I check_case.py --staged` to it by hand")
        with open(path, "w") as f:
            f.write('#!/bin/sh\n# check the staged case.json files against SCHEMA.md (check_case.py)\n'
                    'exec python3 -I "$(git rev-parse --show-toplevel)/check_case.py" --staged\n')
        os.chmod(path, 0o755)
        print("installed", path)


def main():
    args = sys.argv[1:]
    if args == ["--install-hook"]:
        return install_hook()
    problems, n = [], 0
    if args == ["--staged"]:
        paths = [p for p in git("diff", "--cached", "--name-only", "--diff-filter=ACMR", "--", "cases/*/case.json").split()]
        for p in paths:
            n += 1
            try:
                case = json.loads(git("show", ":" + p))
            except ValueError as e:
                problems.append(f"{p}: no JSON ({e})")
                continue
            problems += check_case(case, os.path.join(ROOT, os.path.dirname(p)), p)
    else:
        paths = args or sorted(os.path.join("cases", c, "case.json") for c in os.listdir(os.path.join(ROOT, "cases"))
                               if os.path.isfile(os.path.join(ROOT, "cases", c, "case.json")))
        for p in paths:
            n += 1
            full = p if os.path.isabs(p) else os.path.join(ROOT, p)
            try:
                with open(full) as f:
                    case = json.load(f)
            except ValueError as e:
                problems.append(f"{p}: no JSON ({e})")
                continue
            problems += check_case(case, os.path.dirname(full), p)
    for p in problems:
        print(p)
    if problems:
        print(f"check_case.py: {len(problems)} problems in {n} case.json files (SCHEMA.md)", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
