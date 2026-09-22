#!/usr/bin/env python3
"""Verify every registered webassets bundle resolves without an unknown-asset error.

Run inside the ckan container, e.g.:
    ckan -c "$CKAN_INI" ... # not applicable; run directly:
    python3 /tools/check-webassets.py
"""
import configparser
import logging
import os
import sys
import warnings

warnings.filterwarnings("ignore")


class Capture(logging.Handler):
    def __init__(self):
        super().__init__()
        self.records = []

    def emit(self, record):
        self.records.append(self.format(record))


def main():
    logging.basicConfig(level=logging.ERROR)
    capture = Capture()
    logging.getLogger("ckan.lib.webassets_tools").addHandler(capture)

    from ckan.config.middleware import make_app

    ckan_ini = os.environ.get("CKAN_INI", "/srv/app/ckan.ini")
    cp = configparser.ConfigParser()
    cp.read(ckan_ini)
    conf = dict(cp["app:main"])
    conf["__file__"] = ckan_ini
    conf["here"] = os.path.dirname(ckan_ini)

    wsgi_app = make_app(conf)
    flask_app = wsgi_app.app.app

    from ckan.lib import webassets_tools

    with flask_app.test_request_context("/"):
        env = webassets_tools.env
        names = sorted(getattr(env, "_named_bundles", {}).keys())
        failures = {}
        for name in names:
            capture.records.clear()
            try:
                webassets_tools.include_asset(name)
            except Exception as exc:  # noqa: BLE001 - report, don't hide
                failures[name] = str(exc)
                continue
            if capture.records:
                failures[name] = "; ".join(capture.records)

    print(f"Checked {len(names)} webassets bundle(s).")
    if failures:
        print(f"{len(failures)} bundle(s) reference unknown assets:")
        for name, err in sorted(failures.items()):
            print(f"  {name}: {err}")
        sys.exit(1)
    print("All webassets bundles resolved cleanly.")


if __name__ == "__main__":
    main()
