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