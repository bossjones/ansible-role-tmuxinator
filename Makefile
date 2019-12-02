# encoding utf-8

SHELL=/bin/bash

# SOURCE: https://swcarpentry.github.io/make-novice/reference.html
.DEFAULT_GOAL := .molecule.tmp

export CONTAINER_USER = $(USER)
export CONTAINER_UID = $(shell id -u)
export CONTAINER_GID = $(shell id -g)
export _DATE = $(shell date +%Y%m%d_%H%M%S)
DOCKER_COMPOSE_VERSION := 1.24.0

# Workspace
CURRENT_DIR := $(shell pwd)

DETECTED_OS := $(shell uname -s)
WHOAMI := $(shell whoami)

ifeq (${DETECTED_OS}, Darwin)
	HOME_DIR    ?= /Users/$(WHOAMI)
else
	HOME_DIR    ?= /home/jenkins
endif

# list of  all build targets
.PHONY: info ci

# Deploy configuration
PR_SHA                          := $(shell git rev-parse HEAD)
GITHUB_ORG_NAME                 := bossjones
GITHUB_REPO_NAME                := ansible-role-tmuxinator
IMAGE_BASE                      := $(GITHUB_ORG_NAME)/$(GITHUB_REPO_NAME)
IMAGE_TAG                       := $(IMAGE_BASE):$(PR_SHA)

# Build configuration

role_name                 := ansible-role-tmuxinator




###############################################################################################################3
# Docker run command
###############################################################################################################3
DOCKER_RUN=time docker run --rm -e "PLATFORM_NAME=molecule-test-$(PR_SHA)" -e "GIT_SHA=$(PR_SHA)" -e "_DATE=$(_DATE)" -e "TERM=xterm" -w /tmp/ansible-role-tmuxinator
# import aws creds if they are there - assuming KLAM env ones instead of ~/.aws
ifneq ($(AWS_SESSION_TOKEN),)
  DOCKER_RUN+= -e AWS_DEFAULT_REGION="us-east-1" -e AWS_SESSION_TOKEN -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_SECURITY_TOKEN
else ifneq ($(AWS_SECRET_ACCESS_KEY),)
  DOCKER_RUN+= -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID
else ifneq ($(AWS_PROFILE),)
  DOCKER_RUN+= -e AWS_PROFILE --mount type=bind,source=$(HOME)/.aws,destination=/root/.aws
endif

# Set SSH_AUTH_SOCK and mount ssh socket inside of container
ifneq (${SSH_AUTH_SOCK},)
  DOCKER_RUN+= -e SSH_AUTH_SOCK=/root/.foo -v "${SSH_AUTH_SOCK}:/root/.foo"
endif

DOCKER_RUN+= -v "$(CURRENT_DIR):/tmp/ansible-role-tmuxinator:rw"
DOCKER_RUN+= -v "$(CURRENT_DIR)/.molecule.tmp:/tmp/molecule:rw"
DOCKER_RUN+= -v "$(HOME_DIR)/.ssh:/mount/.ssh"
DOCKER_RUN+= -v "/var/run/docker.sock:/var/run/docker.sock"
DOCKER_RUN+= -v "${HOME}/.ssh/known_hosts:/root/.ssh/known_hosts"

###############################################################################################################3


# verify that certain variables have been defined off the bat
check_defined = \
    $(foreach 1,$1,$(__check_defined))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $(value 2), ($(strip $2)))))

list_allowed_args := name inventory

export PATH := ./bin:./venv/bin:$(PATH)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: list help

bootstrap-molecule-default:
	molecule init scenario --role-name $(current_dir) --scenario-name default

help:
	@echo Public Make tasks:
	@grep -E '^[^_][^_][a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo "Private Make tasks: (use at own risk)"
	@grep -E '^__[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-20s\033[0m %s\n", $$1, $$2}'


list:
	@$(MAKE) -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

.PHONY: pull
pull: ## docker pull ansible image
	docker pull $(BUILD_CONTAINER_IMAGE)

vagrant-provision: ## vagrant provision
	vagrant provision

vagrant-up: ## vagrant up
	vagrant up

vagrant-ssh: ## vagrant ssh
	vagrant ssh

vagrant-destroy: ## vagrant destroy
	vagrant destroy

vagrant-halt: ## vagrant halt
	vagrant halt

vagrant-config: ## vagrant ssh-config
	vagrant ssh-config

destroy: ## molecule: destroy active instances
	molecule destroy

ci: .molecule.tmp ## run ci using docker-compose
# docker-compose -f docker-compose.ci.yml run --rm molecule .ci/run_dc_molecule
	$(DOCKER_RUN) -it $(BUILD_CONTAINER_IMAGE) .ci/run_docker_molecule

bash: .molecule.tmp ## run bash in interactive docker container
# docker-compose -f docker-compose.ci.yml run --rm molecule /bin/bash -l
	$(DOCKER_RUN) -it $(BUILD_CONTAINER_IMAGE) /bin/bash -l

converge: ## run molecule converge suite from workstation
	molecule converge

test: ## run molecule test suite from workstation
	molecule test -s default --destroy=always

debug: ## run molecule test suite with debug enabled
	molecule --debug test -s default --destroy=always

lint: ## run molecule lint
	molecule --debug lint

download-roles-force: ## download any ansible roles that we might need
	ansible-galaxy install -r requirements.yml --force

pre-commit-run: ## pre-commit cli run all hooks
	pre-commit run --all-files

pre-commit-install: ## pre-commit cli install all hooks
	pre-commit install -f --install-hooks

dc-build: .molecule.tmp ## docker-compose build
	docker-compose -f docker-compose.ci.yml build molecule

dc-start: .molecule.tmp ## docker-compose start molecule container
	docker-compose -f docker-compose.ci.yml run --rm molecule

get_work_tree_status: ## figure out if local git copy needs to have anything committed
	./contrib/get_work_tree_status.sh

check_git_up_to_date: ## make sure git local copy matches what is in origin remote
	./contrib/check_git_up_to_date.sh

prepare_release: get_work_tree_status ## Check out master version of script and make sure it's up to date with origin
	git checkout master
	git pull --rebase

minor: prepare_release check_git_up_to_date ## create a minor tag release, eg v0.1.0
	./semtag final -s minor

major: prepare_release check_git_up_to_date ## create a minor tag release, eg v1.0.0
	./semtag final -s major

clean: ## clean area before running docker again
	docker-compose -f docker-compose.ci.yml rm || true

.PHONY: pip-tools
pip-tools: ## Install pip-tools, used to manage dependencies
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install pip-tools pipdeptree
else
	pip install pip-tools pipdeptree
endif


.PHONY: pip-tools-osx
pip-tools-osx: pip-tools ## Install pip-tools, used to manage dependencies

.PHONY: pip-tools-upgrade
pip-tools-upgrade: ## Install pip-tools, used to manage dependencies
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install pip-tools pipdeptree --upgrade
else
	pip install pip-tools pipdeptree --upgrade
endif

.PHONY: pip-compile-upgrade-all
pip-compile-upgrade-all: pip-tools ## Install pip-tools,upgrade all dependencies
	pip-compile --output-file requirements.txt requirements.in --upgrade
	pip-compile --output-file requirements-dev.txt requirements-dev.in --upgrade

.PHONY: pip-compile
pip-compile: pip-tools ## pip-compile requirements.txt file
	pip-compile --output-file requirements.txt requirements.in
	pip-compile --output-file requirements-dev.txt requirements-dev.in

.PHONY: pip-compile-rebuild
pip-compile-rebuild: pip-tools ## rebuild pip-compile requirements.txt file
	pip-compile --rebuild --output-file requirements.txt requirements.in

.PHONY: install-deps-all
install-deps-all: ## install all requirements.txt
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt
else
	pip install -r requirements.txt
endif


.PHONY: precheck
precheck: ## check that all of our cli tools are available before moving forward
	contrib/precheck.sh

.PHONY: git-init
git-init: ## git init repo and push up to master in corp git
	git init

.PHONY: git-bootstrap
git-bootstrap: git-init pre-commit-install ## git init repo, install pre-commit hooks, git add and push up to master in corp git
	git add .
	git commit -m "initial commit"
	git remote add origin remote $(current_dir_name) git@github.com:bossjones/$(current_dir_name).git
	git remote -v
	git push -u origin master

.PHONY: get-docker-compose
get-docker-compose:
	curl -L https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/docker-compose-`uname -s`-`uname -m` > docker-compose
	chmod +x docker-compose
	mv docker-compose bin/
	docker-compose --version

.molecule.tmp:
	mkdir .molecule.tmp

.PHONY: yamllint
yamllint: # run yamllint across everything
	pre-commit run --all-files yamllint

.PHONY: doctor
doctor: ## Check that your environment has everything it needs for tests to properly succeed
	./contrib/doctor.py

.PHONY: direnvrc
direnvrc: ## Global config for direnv. Copy direnvrc file to ~/.direnvrc
	cp -i .contrib/.direnvrc ~/.direnvrc

.PHONY: direnvrc
envrc: ## Global config for direnv. Copy envrc file to <PROJECT_ROOT>/.envrc
	cp -i .envrc-sample .envrc
	direnv allow .

.PHONY: run
run:
	ansible-playbook -i "localhost," -c local playbook.yml

.PHONY: run-ubuntu
run-ubuntu:
	ansible-playbook -vvvvv --ask-become-pass -i "localhost," -c local playbook_ubuntu.yml --extra-vars="bossjones__tmuxinator__user=$(WHOAMI)"

.PHONY: run-ubuntu-version-manager
run-ubuntu-version-manager:
	ansible-playbook -vvvvv --ask-become-pass -i "localhost," -c local playbook_ubuntu_version_manager.yml --extra-vars="bossjones__tmuxinator__user=$(WHOAMI) boss__user=$(WHOAMI) boss__group=$(WHOAMI)"

.PHONY: gpr
gpr:
	git pull --rebase

rbenv:
	bash scripts/rbenv.sh
