FROM ckan/ckan-base:2.10.7-py3.10

USER root

COPY tools/* /tools/
RUN chmod +x /tools/*
#     export PATH=$PATH:/tools
ENV PATH="/tools:${PATH}"

# Copy custom initialization scripts
COPY docker-entrypoint.d/* /docker-entrypoint.d/

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY patches ${APP_DIR}/patches

RUN for d in $APP_DIR/patches/*; do \
        if [ -d $d ]; then \
            for f in `ls $d/*.patch | sort -g`; do \
                cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
            done ; \
        fi ; \
    done

### Copy customization files
COPY customization/logo.png ${APP_DIR}/src/ckan/ckan/public/base/images/logo.png
# Theme needs to be tested
#COPY customization/logo.png ${APP_DIR}/src/ckan/ckan/public/base/css/theme.css

### Add extensions (in alphabetical order)

# Install CKAN extensions using ckanext-install.sh
RUN ckanext-install.sh TIBHannover/ckanext-cancel-dataset-creation 1.0.0 && \
    ckanext-install.sh TIBHannover/ckanext-close-for-guests 1.1.6 && \
    ckanext-install.sh TIBHannover/ckanext-dataset-metadata-automation 1.0.0 && \
    ckanext-install.sh TIBHannover/ckanext-Dataset-Reference 3.0.0 && \
    ckanext-install.sh TIBHannover/ckanext-email-notification 1.1.0 && \
    ckanext-install.sh TIBHannover/ckanext-feature-image 1.0.1 && \
    ckanext-install.sh TIBHannover/ckanext-multiuploader 2.0.0 && \
    ckanext-install.sh TIBHannover/ckanext-organization-group 1.0.0 && \
    ckanext-install.sh TIBHannover/ckanext-tif-imageview 1.1.0 && \
    ckanext-install.sh TIBHannover/ckanext-user-manual 1.0.0 && \
    ckanext-install.sh bhavin2897/ckanext-md_comp_layout 0.1.0


