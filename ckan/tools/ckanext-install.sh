#!/bin/bash
set -euo pipefail

# Check if both parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <GitHub-repo-path> <version>"
    echo "Example: $0 TIBHannover/ckanext-cancel-dataset-creation 1.0.0"
    exit 1
fi

REPO_PATH="$1"
VERSION="$2"
REPO_NAME=$(basename "$REPO_PATH")

# Install the extension
pip install -e "git+https://github.com/$REPO_PATH.git@$VERSION#egg=$REPO_NAME"

# Install the extension's requirements from the checkout pip just created,
# instead of fetching requirements.txt again from raw.githubusercontent.com
# (which intermittently fails with "501 ... Transfer-Encoding not supported").
src_dir="${SRC_DIR:-${VIRTUAL_ENV:-}/src}"
# pip normalizes the checkout directory name (lowercase, "_" -> "-")
checkout_name=$(echo "$REPO_NAME" | tr '[:upper:]_' '[:lower:]-')
checkout=$(find "$src_dir" -maxdepth 1 -type d -name "$checkout_name" 2>/dev/null | head -n 1)

if [ -z "$checkout" ]; then
    echo "ERROR: checkout of ${REPO_PATH}@${VERSION} not found in ${src_dir}" >&2
    exit 1
fi

if [ -f "$checkout/requirements.txt" ]; then
    pip install -r "$checkout/requirements.txt"
else
    echo "No requirements.txt found for ${REPO_PATH}@${VERSION}, skipping"
fi
