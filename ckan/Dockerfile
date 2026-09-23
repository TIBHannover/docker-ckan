FROM ckan/ckan-base:2.11.6-py3.10
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3002
USER root

COPY tools/* /tools/
RUN chmod +x /tools/*
#     export PATH=$PATH:/tools
ENV PATH="/tools:${PATH}"

# Copy custom initialization scripts
COPY docker-entrypoint.d/* /docker-entrypoint.d/

# Copy compatibility patches. CKAN core patches are applied before extension
# installation; extension patches are applied after their sources exist.
COPY patches ${APP_DIR}/patches

# Apply CKAN core patches while the base-image source is still untouched.
# hadolint ignore=DL3003
RUN set -e; \
    shopt -s nullglob; \
    for f in "${APP_DIR}"/patches/ckan/*.patch; do \
        cd "${SRC_DIR}/ckan"; \
        echo "$0: Applying patch $f to ${SRC_DIR}/ckan"; \
        patch --batch --forward --fuzz=0 -p1 < "$f"; \
    done

### Copy customization files
COPY customization/logo.png ${APP_DIR}/src/ckan/ckan/public/base/images/logo.png
# Theme needs to be tested
#COPY customization/logo.png ${APP_DIR}/src/ckan/ckan/public/base/css/theme.css

### i18n customization: compile all *.po files from customization/i18n/<lang>/LC_MESSAGES/
COPY customization /tmp/customization

RUN if [ -d /tmp/customization/i18n ]; then \
      find /tmp/customization/i18n -name "*.po" -type f | \
      while IFS= read -r po; do \
          lang="${po#/tmp/customization/i18n/}"; \
          lang="${lang%%/*}"; \
          mkdir -p "${APP_DIR}/src/ckan/ckan/i18n/${lang}/LC_MESSAGES"; \
          pybabel compile -f -i "$po" \
              -o "${APP_DIR}/src/ckan/ckan/i18n/${lang}/LC_MESSAGES/ckan.mo"; \
      done; \
    fi

### Add extensions (in alphabetical order)

# Install CKAN extensions using ckanext-install.sh
RUN ckanext-install.sh TIBHannover/ckanext-cancel-dataset-creation 1.0.4 && \
    ckanext-install.sh TIBHannover/ckanext-close-for-guests 1.1.8 && \
    ckanext-install.sh TIBHannover/ckanext-dataset-metadata-automation 1.0.1 && \
    ckanext-install.sh TIBHannover/ckanext-Dataset-Reference 3.0.2 && \
    ckanext-install.sh TIBHannover/ckanext-email-notification 1.1.1 && \
    ckanext-install.sh TIBHannover/ckanext-feature-image 1.0.3 && \
    ckanext-install.sh TIBHannover/ckanext-multiuploader 2.1.0 && \
    ckanext-install.sh TIBHannover/ckanext-organization-group 1.0.2 && \
    ckanext-install.sh TIBHannover/ckanext-tif-imageview 1.1.1 && \
    ckanext-install.sh TIBHannover/ckanext-user-manual 1.0.1 && \
    ckanext-install.sh TIBHannover/ckanext-scheming trr375-1.0.0

# Apply temporary compatibility patches to the pinned extension sources.
# Remove these patches after the corresponding fixes have tagged releases.
# hadolint ignore=DL3003
RUN set -e; \
    shopt -s nullglob; \
    for d in "${APP_DIR}"/patches/*; do \
        [ -d "$d" ] || continue; \
        [ "$(basename "$d")" != ckan ] || continue; \
        target="${SRC_DIR}/$(basename "$d")"; \
        [ -d "$target" ] || { echo "$0: Missing patch target $target" >&2; exit 1; }; \
        for f in "$d"/*.patch; do \
            cd "$target"; \
            echo "$0: Applying patch $f to $target"; \
            patch --batch --forward --fuzz=0 -p1 < "$f"; \
        done; \
    done
