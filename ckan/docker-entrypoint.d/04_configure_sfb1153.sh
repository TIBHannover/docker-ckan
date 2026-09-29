#!/bin/bash
set -euo pipefail

has_plugin() {
  [[ " ${CKAN__PLUGINS:-} " == *" $1 "* ]]
}

# These extensions still use mixed-case legacy keys. ckanext-envvars
# lowercases undeclared keys, so write them to the INI explicitly.
if has_plugin machine_link || has_plugin sample_link || has_plugin protocol_link; then
  if [[ -z "${CKAN_SMW_BASE_URL:-}" || -z "${CKAN_SMW_API_ENDPOINT:-}" ]]; then
    echo "SFB1153: CKAN_SMW_BASE_URL and CKAN_SMW_API_ENDPOINT must be configured" >&2
    exit 1
  fi

  ckan config-tool "${CKAN_INI}" \
    "ckanext.smw.baseUrl=${CKAN_SMW_BASE_URL}" \
    "ckanext.smw.mediaWiki.api.endpont=${CKAN_SMW_API_ENDPOINT}"

  if [[ -n "${CKAN_SMW_USERNAME:-}" && -n "${CKAN_SMW_PASSWORD:-}" ]]; then
    if [[ -z "${CKAN_SMW_CREDENTIALS_PATH:-}" ]]; then
      echo "SFB1153: CKAN_SMW_CREDENTIALS_PATH must be configured when credentials are used" >&2
      exit 1
    fi

    umask 077
    printf 'username=%s\npassword=%s\n' \
      "${CKAN_SMW_USERNAME}" "${CKAN_SMW_PASSWORD}" > "${CKAN_SMW_CREDENTIALS_PATH}"
    ckan config-tool "${CKAN_INI}" \
      "ckanext.mediaWiki_credentials_path=${CKAN_SMW_CREDENTIALS_PATH}"
  else
    echo "SFB1153: SMW credentials not configured; authenticated SMW actions are disabled"
  fi
fi

if has_plugin crc1153_dcat_profile && [[ -n "${CKAN_APACHE_JENA_ENDPOINT:-}" ]]; then
  ckan config-tool "${CKAN_INI}" \
    "ckanext.apacheJena.endpoint=${CKAN_APACHE_JENA_ENDPOINT}"
fi
