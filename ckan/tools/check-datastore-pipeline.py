#!/usr/bin/env python3
"""Verify the resource upload -> DataPusher -> DataStore pipeline end to end.

This is the one infrastructure path shared by every extension that ships
resources (multiuploader, tif_imageview, etc.) but exercised by none of
them individually, so it belongs here rather than in any single
extension's own test suite. It creates and cleans up its own throwaway
dataset via the live HTTP API (not the in-process action API) so the
upload goes through a real multipart request, matching what the browser
does.

Run inside the ckan container:
    python3 /tools/check-datastore-pipeline.py
"""
import io
import os
import sys
import time
import warnings

warnings.filterwarnings("ignore")

import requests

BASE = "http://127.0.0.1:5000/api/3/action"
MARKER = "docker-ckan-ci-datastore-pipeline"
CSV_BODY = b"id,name,value\n1,foo,10\n2,bar,20\n"


def call(session, action, **kwargs):
    r = session.post(f"{BASE}/{action}", **kwargs)
    body = r.json()
    if not body.get("success"):
        raise RuntimeError(f"{action} failed: {body.get('error')}")
    return body["result"]


def get_or_create_admin_token():
    token_name = "ci-datastore-pipeline"
    import subprocess

    out = subprocess.run(
        ["ckan", "-c", os.environ.get("CKAN_INI", "/srv/app/ckan.ini"),
         "user", "token", "add", "ckan_admin", token_name],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip().splitlines()[-1].strip()


def main():
    token = get_or_create_admin_token()
    session = requests.Session()
    session.headers["Authorization"] = token

    org = call(session, "organization_create", json={"name": f"{MARKER}-org", "title": MARKER})
    pkg = call(session, "package_create", json={"name": MARKER, "title": MARKER, "owner_org": org["id"]})

    try:
        resource = call(
            session, "resource_create",
            data={"package_id": pkg["id"], "name": "data.csv", "format": "CSV"},
            files={"upload": ("data.csv", io.BytesIO(CSV_BODY), "text/csv")},
        )
        if resource.get("url_type") != "upload":
            print(f"FAIL: resource url_type is {resource.get('url_type')!r}, expected 'upload' - file upload did not go through")
            sys.exit(1)

        # CKAN core auto-submits uploaded CSV/xls/... resources to
        # DataPusher via an IResourceController.after_create hook - no
        # explicit datapusher_submit call needed, just poll for the result.
        deadline = time.monotonic() + 60
        state = None
        while time.monotonic() < deadline:
            status = call(session, "datapusher_status", json={"resource_id": resource["id"]})
            state = status.get("status")
            if state in ("complete", "error"):
                break
            time.sleep(3)

        if state != "complete":
            print(f"FAIL: DataPusher job ended in state {state!r} (expected 'complete') within 60s")
            sys.exit(1)

        rows = call(session, "datastore_search", json={"resource_id": resource["id"]})
        if rows.get("total") != 2:
            print(f"FAIL: datastore_search returned {rows.get('total')} rows, expected 2")
            sys.exit(1)

        print("OK: resource upload -> DataPusher -> DataStore pipeline works end to end.")
    finally:
        call(session, "package_delete", json={"id": pkg["id"]})
        call(session, "dataset_purge", json={"id": pkg["id"]})
        call(session, "organization_purge", json={"id": org["id"]})


if __name__ == "__main__":
    main()
