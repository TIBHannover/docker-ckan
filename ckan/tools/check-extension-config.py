#!/usr/bin/env python3
"""Verify that CKANEXT__* variables arrive as the expected config keys in CKAN.

ckanext-envvars turns CKANEXT__SMW__BASEURL into the config key
ckanext.smw.baseurl. For every non-empty CKANEXT__* variable of this container
this check asserts that

  * an installed extension declares the resulting key (a typo in the variable
    name would otherwise be ignored silently), and
  * the running CKAN configuration holds exactly the value from the variable.

With --warn-only (used at container start) only undeclared keys are reported,
as warnings, and the exit status is always 0.

Run inside the ckan container:
    python3 /tools/check-extension-config.py [--warn-only]
"""
import configparser
import os
import sys
import warnings

warnings.filterwarnings("ignore")

PREFIX = "CKANEXT__"


def to_config_key(name):
    return name.lower().replace("__", ".")


def main():
    warn_only = "--warn-only" in sys.argv[1:]
    variables = {k: v for k, v in os.environ.items() if k.startswith(PREFIX) and v}
    if not variables:
        if warn_only:
            return 0
        print(f"ERROR: no {PREFIX}* variable is set, so nothing is verified")
        return 1

    from ckan.config.middleware import make_app

    ckan_ini = os.environ.get("CKAN_INI", "/srv/app/ckan.ini")
    cp = configparser.ConfigParser()
    cp.read(ckan_ini)
    conf = dict(cp["app:main"])
    conf["__file__"] = ckan_ini
    conf["here"] = os.path.dirname(ckan_ini)
    make_app(conf)

    from ckan.common import config, config_declaration

    declared = {str(k) for k in config_declaration.iter_options()}

    failures = []
    for name, value in sorted(variables.items()):
        key = to_config_key(name)
        if key not in declared:
            failures.append(f"{name}: key {key!r} is not declared by any installed extension")
        elif warn_only:
            continue
        elif config.get(key) != value:
            failures.append(f"{name}: config {key!r} is {config.get(key)!r}, expected {value!r}")
        else:
            print(f"ok  {name} -> {key}")

    if warn_only:
        for failure in failures:
            print(f"WARNING: {failure}; the variable may have no effect (typo?)")
        return 0
    if failures:
        print(f"{len(failures)} problem(s):")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print(f"Checked {len(variables)} {PREFIX}* variable(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
