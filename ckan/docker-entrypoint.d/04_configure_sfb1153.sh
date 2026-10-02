#!/bin/bash
set -euo pipefail

has_plugin() {
  [[ " ${CKAN__PLUGINS:-} " == *" $1 "* ]]
}

# The extension settings (CKANEXT__SMW__*, CKANEXT__MEDIAWIKI_CREDENTIALS_PATH,
# CKANEXT__APACHEJENA__ENDPOINT) reach CKAN through ckanext-envvars, this script
# does not write any config key. It only checks that the settings required by
# the active plugins are present and creates the SMW credentials file, because
# the extensions read a file path, not the credentials themselves.
if has_plugin machine_link || has_plugin sample_link || has_plugin protocol_link; then
  if [[ -z "${CKANEXT__SMW__BASEURL:-}" || -z "${CKANEXT__SMW__MEDIAWIKI__API__ENDPOINT:-}" ]]; then
    echo "SFB1153: CKANEXT__SMW__BASEURL and CKANEXT__SMW__MEDIAWIKI__API__ENDPOINT must be configured" >&2
    exit 1
  fi

  if [[ -n "${CKAN_SMW_USERNAME:-}" && -n "${CKAN_SMW_PASSWORD:-}" ]]; then
    if [[ -z "${CKANEXT__MEDIAWIKI_CREDENTIALS_PATH:-}" ]]; then
      echo "SFB1153: CKANEXT__MEDIAWIKI_CREDENTIALS_PATH must be configured when credentials are used" >&2
      exit 1
    fi

    umask 077
    printf 'username=%s\npassword=%s\n' \
      "${CKAN_SMW_USERNAME}" "${CKAN_SMW_PASSWORD}" > "${CKANEXT__MEDIAWIKI_CREDENTIALS_PATH}"
  else
    echo "SFB1153: SMW credentials not configured; authenticated SMW actions are disabled"
  fi
fi
