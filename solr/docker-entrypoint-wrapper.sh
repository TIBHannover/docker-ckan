#!/bin/bash
set -euo pipefail

CORE_NAME=ckan
CONFIGSET_DIR="${SOLR_CONFIG_DIR}/${CORE_NAME}"
CORE_DIR="${SOLR_HOME}/${CORE_NAME}"
# The active schema file is "managed-schema" (no extension - Solr's Managed
# Schema feature may rewrite it at runtime). The unrelated "managed-schema.xml"
# in the same directory is an unused stock example and must not be read here.
SCHEMA_FILE_NAME=managed-schema

schema_name() {
    grep -oE '<schema name="[^"]*"' "$1" | cut -d'"' -f2
}

image_schema_name="$(schema_name "${CONFIGSET_DIR}/conf/${SCHEMA_FILE_NAME}")"

if [ -d "$CORE_DIR" ]; then
    core_schema_file="${CORE_DIR}/conf/${SCHEMA_FILE_NAME}"
    if [ -f "$core_schema_file" ]; then
        core_schema_name="$(schema_name "$core_schema_file")"
    else
        core_schema_name=""
    fi

    if [ "$core_schema_name" != "$image_schema_name" ]; then
        echo "$0: Solr core '${CORE_NAME}' schema '${core_schema_name:-none}' does not match image schema '${image_schema_name}' - recreating core from the image configset."
        echo "$0: The CKAN search index is a derived copy of the database; ckan/docker-entrypoint.d triggers a full reindex once Solr is back up."
        rm -rf "$CORE_DIR"
    else
        echo "$0: Solr core '${CORE_NAME}' schema '${core_schema_name}' already matches the image - no changes needed."
    fi
else
    echo "$0: No existing Solr core '${CORE_NAME}' found - it will be created fresh from the image configset."
fi

exec docker-entrypoint.sh solr-precreate "$CORE_NAME" "$CONFIGSET_DIR"
