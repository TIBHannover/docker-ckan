ARG SOLR_IMAGE_VERSION=2.11-solr9
FROM ckan/ckan-solr:${SOLR_IMAGE_VERSION}

COPY --chmod=755 docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]
