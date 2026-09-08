#!/bin/bash
set -e

if [ -n "${CKAN__SCHEMING__DATASET_SCHEMAS:-}" ]; then
    ckan config-tool "$CKAN_INI" \
        "scheming.dataset_schemas=${CKAN__SCHEMING__DATASET_SCHEMAS}"
fi

if [ -n "${CKAN__SCHEMING__GROUP_SCHEMAS:-}" ]; then
    ckan config-tool "$CKAN_INI" \
        "scheming.group_schemas=${CKAN__SCHEMING__GROUP_SCHEMAS}"
fi

if [ -n "${CKAN__SCHEMING__ORGANIZATION_SCHEMAS:-}" ]; then
    ckan config-tool "$CKAN_INI" \
        "scheming.organization_schemas=${CKAN__SCHEMING__ORGANIZATION_SCHEMAS}"
fi

if [ -n "${CKAN__SCHEMING__PRESETS:-}" ]; then
    ckan config-tool "$CKAN_INI" \
        "scheming.presets=${CKAN__SCHEMING__PRESETS}"
fi

if [ -n "${CKAN__SCHEMING__DATASET_FALLBACK:-}" ]; then
    ckan config-tool "$CKAN_INI" \
        "scheming.dataset_fallback=${CKAN__SCHEMING__DATASET_FALLBACK}"
fi