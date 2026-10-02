#!/usr/bin/env python3
"""Fail if an installed extension reads or declares a config key with upper-case characters.

Extension settings reach CKAN as CKANEXT__* environment variables via
ckanext-envvars, which lowercases the name. A key containing upper-case
characters can therefore never be set that way and is silently ignored.

This is a static text search over the extension sources, so dynamically built
key names are not detected. Keys that are known and handled on purpose are
listed in config-key-exceptions.txt.

Run inside the ckan container:
    python3 /tools/check-config-keys.py
"""
import os
import re
import sys
from pathlib import Path

SRC_DIR = Path(os.environ.get("CKAN_SRC", "/srv/app/src"))
EXCEPTIONS_FILE = Path(__file__).with_name("config-key-exceptions.txt")

# Projects under SRC_DIR that are not extensions with settings of their own.
SKIP_PROJECTS = {"ckan", "ckanext-envvars"}
SKIP_DIRS = {".git", "node_modules", "tests", "test", "__pycache__"}

KEY = r"[A-Za-z0-9_\-]+(?:\.[A-Za-z0-9_\-]+)+"
PATTERNS = [
    # Any quoted literal in the extension namespace: 'ckanext.foo.barBaz'
    ("ckanext literal", re.compile(r"""["'](ckanext\.[A-Za-z0-9_.\-]+)["']"""), {".py", ".html", ".txt", ".json"}),
    # config.get('foo.barBaz'), config['foo.barBaz'], config.get("...", default)
    (
        "config access",
        re.compile(r"""config(?:\.get|\.get_value)?[\(\[]\s*["'](""" + KEY + r""")["']"""),
        {".py", ".html"},
    ),
    # config_declaration.yaml: "key: ...". legacy_key entries are the old names kept
    # for backward compatibility on purpose, so they are not matched.
    (
        "declaration",
        re.compile(r"""^\s*-?\s*key:\s*["']?(""" + KEY + r""")["']?\s*$""", re.M),
        {".yaml", ".yml"},
    ),
]


def load_exceptions():
    if not EXCEPTIONS_FILE.exists():
        return set()
    lines = (line.split("#", 1)[0].strip() for line in EXCEPTIONS_FILE.read_text().splitlines())
    return {line for line in lines if line}


def iter_files(project):
    for root, dirs, files in os.walk(project):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            yield Path(root) / name


def main():
    exceptions = load_exceptions()
    projects = sorted(p for p in SRC_DIR.glob("ckanext-*") if p.is_dir() and p.name not in SKIP_PROJECTS)
    if not projects:
        print(f"ERROR: no extensions found under {SRC_DIR}")
        return 1

    found = {}  # (project, key) -> sorted set of "file:line"
    for project in projects:
        for path in iter_files(project):
            for _label, regex, suffixes in PATTERNS:
                if path.suffix not in suffixes:
                    continue
                try:
                    text = path.read_text(errors="replace")
                except OSError:
                    continue
                for m in regex.finditer(text):
                    key = m.group(1)
                    if key == key.lower() or key in exceptions:
                        continue
                    line = text.count("\n", 0, m.start(1)) + 1
                    found.setdefault((project.name, key), set()).add(f"{path.relative_to(project)}:{line}")

    print(f"Checked {len(projects)} extension(s) for config keys with upper-case characters.")
    if not found:
        return 0

    print("ERROR: config key(s) with upper-case characters cannot be set via CKANEXT__* variables:")
    for (project, key), places in sorted(found.items()):
        print(f"  {project}: {key}")
        for place in sorted(places)[:3]:
            print(f"      {place}")
    print("Rename the key to lowercase in the extension (keep the old name as legacy_key), "
          f"or add it to {EXCEPTIONS_FILE.name} if it is handled on purpose.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
