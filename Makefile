VERSION            = 0.0.2
IMG_BASE           = grokloc/grokloc-perl5:base
IMG_DEV            = grokloc/grokloc-perl5:dev
IMG_VERSIONED      = grokloc/grokloc-perl5:$(VERSION)
DOCKER             = docker
DOCKER_RUN         = $(DOCKER) run --rm
DOCKER_COMPOSE     = docker-compose
COMPOSE_APP        = app
COMPOSE_DB         = db
CWD                = $(shell pwd)
BASE               = /grokloc
VOLUMES            = -v $(CWD):$(BASE) -v /tmp:/repos
LOCAL_RUN          = $(DOCKER_RUN) $(VOLUMES) -w $(BASE) --env-file=env/dev.env --name=dev --net=host $(IMG_VERSIONED)
PERL5              = perl
DEV_RUNNER         = morbo
TEST_RUNNER        = yath --max-open-jobs=1000
TIDY               = perltidier -dws -io -i=2 -pt=2 -bt=2 -pvt=2
PERLIMPORTS        = perlimports -i --no-preserve-unused --libs lib,service/app/lib --ignore-modules-filename ./.perlimports-ignore -f
CRITIC_ARGS        =
TCRITIC_ARGS       = --theme=tests
LIBS               = $(shell find . -type f -name \*pm)
LIB_TESTS          = $(shell find t -type f)
APP_TESTS          = $(shell if [ -d service/app/t ]; then find service/app/t -type f; fi)
APP_MAIN           = service/app/script/app
APP_PORTS          = -p 3000:3000

# don't want to clash with env vars...prefix with _
_POSTGRES_APP_URL  = postgres://grokloc:grokloc@db:5432/app

# ---------------------------------------------
# SECTION: LOCAL DEV
# local dev workflow using grokloc-perl5:$(VERSION) toolchain - make sure to run "make local-db" first
# before running any of the rules in this section

.DEFAULT_GOAL := all

# start a "local" (net=host) db for iterating with build, test rules below
.PHONY: local-db
local-db:
	$(DOCKER) run --rm -d --name=db --env-file=env/dev.env -p 5432:5432 grokloc/grokloc-postgres:0.0.5

# bring down the "local" db
.PHONY: local-db-down
local-db-down:
	$(DOCKER) stop db

# get a shell inside the dev image with sources mounted (for running individual tests etc)
.PHONY: shell
shell:
	$(DOCKER) run --rm -it $(VOLUMES) -w $(BASE) --env-file=env/dev.env --name=dev --net=host $(IMG_VERSIONED) /bin/bash

.PHONY: _check
_check:
	@echo "--- CHECK ---"
	for i in `find . -name \*.pm`; do perl -c $$i; done
	for i in `find . -name \*.t`; do perl -c $$i; done

.PHONY: check
check:
	$(LOCAL_RUN) make _check

.PHONY: _test
_test:
	@echo "--- TESTS ---"
	$(TEST_RUNNER) $(LIB_TESTS) $(APP_TESTS)

.PHONY: test
test:
	$(LOCAL_RUN) make _test

.PHONY: _imports
_imports:
	@echo "--- PERLIMPORTS ---"
	find -name \*.pm -print0 | xargs -0 $(PERLIMPORTS)
	find -name \*.t -print0 | xargs -0 $(PERLIMPORTS)

.PHONY: imports
imports:
	$(LOCAL_RUN) make _imports

.PHONY: _tidy
_tidy:
	@echo "--- PERLTIDY ---"
	find -name \*.pm -print0 | xargs -0 $(TIDY) -b 2>/dev/null
	find -name \*.t -print0 | xargs -0 $(TIDY) -b 2>/dev/null
	find -name \*bak -delete
	find -name \*.ERR -delete

.PHONY: tidy
tidy:
	$(LOCAL_RUN) make _tidy

.PHONY: _critic
_critic:
	@echo "--- PERLCRITIC ---"
	perlcritic $(CRITIC_ARGS) $(LIBS)
	perlcritic $(TCRITIC_ARGS) $(LIB_TESTS)

.PHONY: critic
critic:
	$(LOCAL_RUN) make _critic

.PHONY: all
all:
	$(LOCAL_RUN) make _check _test _imports _tidy _critic

# run app
.PHONY: run-app
run-app:
	$(DEV_RUNNER) $(APP_MAIN)

# ---------------------------------------------
# SECTION: DOCKER COMPOSE
#

# bring up compose env
.PHONY: up
up:
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d

# truncate all tables in compose db
.PHONY: truncate
truncate:
	$(DOCKER) exec -it $(COMPOSE_DB) psql $(_POSTGRES_APP_URL) -c "truncate users"
	$(DOCKER) exec -it $(COMPOSE_DB) psql $(_POSTGRES_APP_URL) -c "truncate orgs"
	$(DOCKER) exec -it $(COMPOSE_DB) psql $(_POSTGRES_APP_URL) -c "truncate repositories"
	$(DOCKER) exec -it $(COMPOSE_DB) psql $(_POSTGRES_APP_URL) -c "truncate audit"

# bring compose env down
.PHONY: down
down: truncate
	$(DOCKER_COMPOSE) down -t 2
	$(DOCKER) rmi -f grokloc-perl5-app:latest

.PHONY: compose-test
compose-test:
	$(DOCKER_COMPOSE) exec -it $(COMPOSE_APP) make _test

.PHONY: compose-critic
compose-critic:
	$(DOCKER_COMPOSE) exec -it $(COMPOSE_APP) make _critic

.PHONY: compose-rm
compose-rm:
	$(DOCKER) rmi -f grokloc-perl5-app:latest

.PHONY: compose-all
compose-all: compose-rm up compose-test compose-critic

# ---------------------------------------------
# SECTION: DOCKER ADMINISTRATION (some rules require docker login for grokloc)
#
.PHONY: docker
docker:
	$(DOCKER) build . -f Dockerfile.base -t $(IMG_BASE)
	$(DOCKER) build . -f Dockerfile.dev -t $(IMG_VERSIONED)
	$(DOCKER) tag $(IMG_VERSIONED) $(IMG_DEV)

.PHONY: docker-push
docker-push:
	$(DOCKER) push $(IMG_BASE)
	$(DOCKER) push $(IMG_VERSIONED)
	$(DOCKER) push $(IMG_DEV)

.PHONY: docker-pull
docker-pull:
	$(DOCKER) pull $(IMG_BASE)
	$(DOCKER) pull $(IMG_VERSIONED)
	$(DOCKER) pull $(IMG_DEV)

# ---------------------------------------------
# SECTION: UTILITIES
#

# get a psql prompt in the db
.PHONY: psql
psql:
	$(DOCKER_COMPOSE) exec -it $(COMPOSE_DB) psql $(_POSTGRES_DB_URL)

# get a shell in the compose env
.PHONY: compose-shell
compose-shell:
	$(DOCKER_COMPOSE) exec -it $(COMPOSE_APP) /bin/bash

# clean out everything installed after `make down` to tear down compose resources
.PHONY: clean
clean:
	$(DOCKER) volume rm grokloc-app_grokloc-db-data
	$(DOCKER) volume rm grokloc-app_grokloc-sample-repos

