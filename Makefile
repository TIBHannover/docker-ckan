-include .env
export

show-current-target = @echo; echo "======= $@ ========"

.PHONY: all
all:

compose = docker compose $(COMPOSE_ARGS)
compose-run = $(compose) run --rm
compose-exec = $(compose) exec -T
compose-cp = docker compose cp

# ======== Run ========

.PHONY: build
build:
	$(show-current-target)
	$(compose) build

.PHONY: up
up:
	$(show-current-target)
	$(compose) up -d

.PHONY: show-status
show-status:
	$(show-current-target)
	$(compose) ps

.PHONY: show-logs
show-logs:
	$(show-current-target)
	$(compose) logs -f || exit 0

.PHONY: stop
stop:
	$(show-current-target)
	$(compose) stop

.PHONY: down
down:
	$(show-current-target)
	$(compose) down

.PHONY: destroy
destroy:
	$(show-current-target)
	$(compose) down --volumes --remove-orphans

# ======== Develop ========

.PHONY: bash
bash:
	$(show-current-target)
	$(compose) exec ckan bash

# ======== Lint ========

dockerfiles = ckan/Dockerfile nginx/Dockerfile postgresql/Dockerfile solr/Dockerfile
shellfiles = $(shell git ls-files '*.sh')

.PHONY: lint
lint: lint-hadolint lint-shellcheck lint-compose

.PHONY: lint-hadolint
lint-hadolint:
	$(show-current-target)
	@for f in $(dockerfiles); do \
		echo "--- hadolint $$f ---"; \
		docker run --rm -i hadolint/hadolint < $$f || exit $$?; \
	done

.PHONY: lint-shellcheck
lint-shellcheck:
	$(show-current-target)
	docker run --rm -v "$(CURDIR):/mnt:ro" -w /mnt koalaman/shellcheck $(shellfiles)

.PHONY: lint-compose
lint-compose:
	$(show-current-target)
	$(compose) config --quiet

# ======== CI ========

.PHONY: wait-for-healthy
wait-for-healthy:
	$(show-current-target)
	@echo "Waiting for all services to become healthy..."
	@timeout=300; \
	while [ $$timeout -gt 0 ]; do \
		unhealthy=$$(docker compose ps --format '{{.Health}}' | grep -v -E '^(healthy|)$$' || true); \
		starting=$$(docker compose ps --format '{{.Health}}' | grep -c 'starting' || true); \
		if [ -z "$$unhealthy" ] && [ "$$starting" -eq 0 ]; then \
			echo "All services healthy."; \
			exit 0; \
		fi; \
		sleep 5; \
		timeout=$$((timeout - 5)); \
	done; \
	echo "Timed out waiting for services to become healthy:"; \
	$(compose) ps; \
	$(compose) logs; \
	exit 1

.PHONY: ci
ci:
	$(show-current-target)
	$(compose) build
	$(compose) up -d
	$(MAKE) wait-for-healthy || { $(compose) down; exit 1; }
	$(MAKE) ci-plugins || { $(compose) down; exit 1; }
	$(MAKE) ci-webassets || { $(compose) down; exit 1; }
	$(compose) down

# Verifies the in-place upgrade path with real volumes (not a fresh stack):
# run this on an already-running stack built from an older branch/image set
# (e.g. the 2.x maintenance branch) to confirm the new images pick up the
# existing pg_data/solr_data/ckan_storage volumes cleanly - Postgres major
# upgrade, Solr schema reindex, DB migrations - and that a second restart
# with no image change is a no-op on all of them. See also "make down"
# (keeps volumes) vs. "make destroy" (removes them).
.PHONY: ci-upgrade
ci-upgrade:
	$(show-current-target)
	$(compose) build
	$(compose) up -d
	$(MAKE) wait-for-healthy || { $(compose) down; exit 1; }
	@echo "--- db upgrade markers ---"; \
	$(compose) logs db | grep -iE "upgrade to postgresql|skipping initialization" || true
	@echo "--- solr schema markers ---"; \
	$(compose) logs solr | grep -iE "docker-entrypoint-wrapper" || true
	@echo "--- ckan reindex markers ---"; \
	$(compose) logs ckan | grep -iE "02_reindex_on_schema_change|search-index rebuild" || true
	$(MAKE) ci-plugins || { $(compose) down; exit 1; }
	$(MAKE) ci-webassets || { $(compose) down; exit 1; }
	@echo "--- restarting to verify idempotence (no rebuild) ---"
	$(compose) down
	$(compose) up -d
	$(MAKE) wait-for-healthy || { $(compose) down; exit 1; }
	@echo "--- db/solr/ckan markers after second start (expect no-ops) ---"; \
	$(compose) logs db | grep -iE "upgrade to postgresql|skipping initialization" || true; \
	$(compose) logs solr | grep -iE "docker-entrypoint-wrapper" || true; \
	$(compose) logs ckan | grep -iE "02_reindex_on_schema_change|search-index rebuild|unchanged since" || true
	$(compose) down

.PHONY: ci-plugins
ci-plugins:
	$(show-current-target)
	@echo "Checking that all configured plugins were actually loaded..."
	@loaded=$$($(compose-exec) ckan python3 -c 'import json,urllib.request; print(" ".join(json.load(urllib.request.urlopen("http://127.0.0.1:5000/api/3/action/status_show"))["result"]["extensions"]))'); \
	echo "Loaded plugins: $$loaded"; \
	missing=""; \
	configured=$$(echo '$(CKAN__PLUGINS)' | tr -d '"'); \
	for p in $$configured; do \
		case " $$loaded " in \
			*" $$p "*) ;; \
			*) missing="$$missing $$p" ;; \
		esac; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "ERROR: configured plugin(s) not loaded by CKAN:$$missing"; \
		exit 1; \
	fi; \
	echo "All configured plugins were loaded."

.PHONY: ci-webassets
ci-webassets:
	$(show-current-target)
	@echo "Checking that all registered webassets bundles resolve..."
	$(compose-exec) ckan python3 /tools/check-webassets.py

# ======== Backup ========

.PHONY: create-backup
create-backup: pull-backup
	$(show-current-target)
	$(compose-run) backup create

.PHONY: restore-backup
restore-backup: pull-backup
	$(show-current-target)
	$(compose-run) -e RESTORE_OWNER=$(RESTORE_OWNER) backup restore
	$(compose-exec) ckan ckan -c ckan.ini search-index rebuild

.PHONY: pull-backup
pull-backup:
	$(show-current-target)
	$(compose) pull backup