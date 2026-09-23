#!/bin/bash
set -euo pipefail

# The solr service recreates its core from scratch whenever the mounted
# solr_data volume's schema doesn't match the ckan-solr image (see
# solr/docker-entrypoint-wrapper.sh) - e.g. after a CKAN version bump that
# also bumps SOLR_IMAGE_VERSION. That leaves an empty index behind. Detect
# this from the ckan side via the schema name Solr reports and trigger a
# full reindex exactly once per schema change, tracked with a marker file
# on the persistent ckan_storage volume so repeat container starts are a
# no-op.

MARKER_FILE="${CKAN_STORAGE_PATH:-/var/lib/ckan}/.solr_schema_name"

current_schema_name="$(python3 -c "
import json, sys, urllib.request
try:
    with urllib.request.urlopen('${CKAN_SOLR_URL}/schema/name?wt=json', timeout=10) as r:
        print(json.load(r)['name'])
except Exception as e:
    print('unknown', file=sys.stderr)
    print(str(e), file=sys.stderr)
    sys.exit(1)
")"

previous_schema_name=""
if [ -f "$MARKER_FILE" ]; then
    previous_schema_name="$(cat "$MARKER_FILE")"
fi

if [ "$current_schema_name" != "$previous_schema_name" ]; then
    echo "$0: Solr schema is '${current_schema_name}' (was '${previous_schema_name:-none}') - triggering a full search-index rebuild."
    ckan -c "$CKAN_INI" search-index rebuild
    echo "$current_schema_name" > "$MARKER_FILE"
else
    echo "$0: Solr schema '${current_schema_name}' unchanged since the last reindex - skipping."
fi
