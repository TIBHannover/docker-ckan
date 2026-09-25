#!/bin/bash
set -euo pipefail

if [[ " ${CKAN__PLUGINS:-} " == *" harvest "* ]]; then
    ckan -c "$CKAN_INI" db upgrade -p harvest
else
    echo "Not configuring Harvest"
fi
