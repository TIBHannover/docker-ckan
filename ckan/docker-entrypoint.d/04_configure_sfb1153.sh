#!/bin/bash
set -euo pipefail

has_plugin() {
  [[ " ${CKAN__PLUGINS:-} " == *" $1 "* ]]
}

# These extensions still use mixed-case legacy keys. ckanext-envvars
# lowercases undeclared keys, so write them to the INI explicitly.
if has_plugin machine_link || has_plugin sample_link; then
  ckan config-tool "${CKAN_INI}" \
    "ckanext.smw.baseUrl=${CKAN_SMW_BASE_URL:-https://smw.service.tib.eu/sfb1153/}" \
    "ckanext.smw.mediaWiki.api.endpont=${CKAN_SMW_API_ENDPOINT:-smw.service.tib.eu}"

  if [[ -n "${CKAN_SMW_USERNAME:-}" && -n "${CKAN_SMW_PASSWORD:-}" ]]; then
    credentials_path="${CKAN_SMW_CREDENTIALS_PATH:-/var/lib/ckan/smw1153-credentials.txt}"
    umask 077
    printf 'username=%s\npassword=%s\n' \
      "${CKAN_SMW_USERNAME}" "${CKAN_SMW_PASSWORD}" > "${credentials_path}"
    ckan config-tool "${CKAN_INI}" \
      "ckanext.mediaWiki_credentials_path=${credentials_path}"
  else
    echo "SFB1153: SMW credentials not configured; authenticated SMW actions are disabled"
  fi
fi

if has_plugin crc1153_dcat_profile && [[ -n "${CKAN_APACHE_JENA_ENDPOINT:-}" ]]; then
  ckan config-tool "${CKAN_INI}" \
    "ckanext.apacheJena.endpoint=${CKAN_APACHE_JENA_ENDPOINT}"
fi
