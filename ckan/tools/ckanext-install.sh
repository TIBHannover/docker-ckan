#!/bin/bash

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
requirements_url="https://raw.githubusercontent.com/${repo}/${version}/requirements.txt"

if curl --fail --silent --head "$requirements_url" >/dev/null; then
    pip install -r "$requirements_url"
else
    echo "No requirements.txt found for ${repo}@${version}, skipping"
fi