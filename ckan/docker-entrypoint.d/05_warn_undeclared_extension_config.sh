#!/bin/bash
set -euo pipefail

# CKANEXT__* variables that do not match a config key declared by an installed
# extension are applied by ckanext-envvars, but usually have no effect (typo in
# the variable name). Report them at startup; never block the start.
python3 /tools/check-extension-config.py --warn-only 2>&1 | grep '^WARNING:' || true
