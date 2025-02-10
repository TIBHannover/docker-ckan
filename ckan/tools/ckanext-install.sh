#!/bin/bash

# Check if both parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <CKAN-extension-name> <version>"
    exit 1
fi

pip install -e "git+https://github.com/TIBHannover/$1.git@$2#egg=$1"
pip install -r "https://raw.githubusercontent.com/TIBHannover/$1/$2/requirements.txt"