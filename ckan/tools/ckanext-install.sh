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

# Install the extension's requirements
requirements_url="https://raw.githubusercontent.com/${REPO_PATH}/${VERSION}/requirements.txt"

if python3 -c "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen(urllib.request.Request('$requirements_url', method='HEAD')).status == 200 else 1)" 2>/dev/null; then
    pip install -r "$requirements_url"
else
    echo "No requirements.txt found for ${REPO_PATH}@${VERSION}, skipping"
fi