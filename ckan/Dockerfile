FROM ckan/ckan-base:2.10.5

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

### Add extensions

# TIB multiuploader (2023-01-13)
RUN pip install -e git+https://github.com/TIBHannover/ckanext-multiuploader.git@49f5d02af2232f660e1637f4f6f8bdbfc1019082#egg=ckanext-multiuploader && \
    pip install -r https://raw.githubusercontent.com/TIBHannover/ckanext-multiuploader/49f5d02af2232f660e1637f4f6f8bdbfc1019082/requirements.txt
