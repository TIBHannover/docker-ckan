FROM ckan/ckan-base:2.10.6-py3.10

USER root

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

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

### Add extensions

# TIBHannover/ckanext-close-for-guests (1.0.0)
RUN pip install -e git+https://github.com/TIBHannover/ckanext-close-for-guests@1.0.0#egg=ckanext-close-for-guests && \
    pip install -r https://raw.githubusercontent.com/TIBHannover/ckanext-close-for-guests/1.0.0/requirements.txt

# TIBHannover/ckanext-email-notification (1.1.0)
RUN pip install -e git+https://github.com/TIBHannover/ckanext-email-notification@1.1.0#egg=ckanext-email-notification && \
    pip install -r https://raw.githubusercontent.com/TIBHannover/ckanext-email-notification/1.1.0/requirements.txt

# TIBHannover/ckanext-multiuploader (2.0.0)
RUN pip install -e git+https://github.com/TIBHannover/ckanext-multiuploader.git@2.0.0#egg=ckanext-multiuploader && \
    pip install -r https://raw.githubusercontent.com/TIBHannover/ckanext-multiuploader/2.0.0/requirements.txt

# TIBHannover/ckanext-tif-imageview (1.1.0)
RUN pip install -e git+https://github.com/TIBHannover/ckanext-tif-imageview.git@1.1.0#egg=ckanext-tif-imageview && \
    pip install -r https://raw.githubusercontent.com/TIBHannover/ckanext-tif-imageview/1.1.0/requirements.txt

