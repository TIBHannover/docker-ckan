#!/bin/bash
set -euo pipefail

echo "Building CKAN assets..."
ckan -c "$CKAN_INI" asset build
