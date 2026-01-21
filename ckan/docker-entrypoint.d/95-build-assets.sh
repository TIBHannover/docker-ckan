#!/bin/bash
set -e

echo "Building CKAN assets..."
ckan -c $CKAN_INI asset build
