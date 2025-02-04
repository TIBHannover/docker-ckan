#!/bin/bash

## Core
ckan config-tool "$CKAN_INI" "WTF_CSRF_SSL_STRICT=${WTF_CSRF_SSL_STRICT:-true}"

## Branding
ckan config-tool "$CKAN_INI" "ckan.site_title=${CKAN_SITE_TITLE:-CKAN}"
ckan config-tool "$CKAN_INI" "ckan.site_logo=${CKAN_SITE_LOGO:-/base/images/ckan-logo.png}"
ckan config-tool "$CKAN_INI" "ckan.theme=${CKAN_THEME:-css/main}"

## E-Mail
ckan config-tool "$CKAN_INI" "smtp.server=$CKAN_SMTP_SERVER"
ckan config-tool "$CKAN_INI" "smtp.starttls=${CKAN_SMTP_STARTTLS:-false}"
ckan config-tool "$CKAN_INI" "smtp.user=$CKAN_SMTP_USER"
ckan config-tool "$CKAN_INI" "smtp.password=$CKAN_SMTP_PASSWORD"
ckan config-tool "$CKAN_INI" "smtp.mail_from=$CKAN_SMTP_MAIL_FROM"
ckan config-tool "$CKAN_INI" "smtp.reply_to=$CKAN_SMTP_REPLY_TO"
ckan config-tool "$CKAN_INI" "ckan.activity_streams_email_notifications=$CKAN_ACTIVITY_STREAMS_EMAIL_NOTIFICATION"