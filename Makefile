SHELL := /bin/bash

DOCKER_DEFAULT_IMAGE ?= "builder-ubuntu-16.04:latest"
ifdef DOCKER_IMAGE
	DKR_IMG_EXISTS := $(shell docker images --format '{{.Repository}}:{{.Tag}}' | grep $(DOCKER_IMAGE))
else
	DKR_IMG_EXISTS := $(shell docker images --format '{{.Repository}}:{{.Tag}}' | grep $(DOCKER_DEFAULT_IMAGE))
endif

ruby_files := $(shell find . -name "*.rb")

.PHONY: all header help package docker debug

all: header help requirements

header:
	$(info ---)
	$(info - Build Information)
	$(info - Directory: $(CURDIR))
ifeq ("$(wildcard /etc/issue))","")
	$(info - Operating System: $(shell cat /etc/issue ))
endif
	$(info - Kernel: $(shell uname -prsmn))
ifdef DOCKER_IMAGE
	$(info - DOCKER_IMAGE => $(DOCKER_IMAGE))
else
	$(info - DOCKER_DEFAULT_IMAGE => $(DOCKER_DEFAULT_IMAGE))
endif
ifdef DOCKER_OPTIONS
	$(info - DOCKER_OPTIONS => $(DOCKER_OPTIONS))
endif
ifdef PKG
	$(info - PACKAGE => $(PKG))
endif
	$(info ---)

help:					## Show usage.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed 's/\\$$//;s/##/:/'`); \
	for help_line in $${help_lines[@]}; do \
		IFS=$$':' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed 's/^ *//;s/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed 's/^ *//;s/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-30s %s" $$help_command ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done

requirements:
ifndef DKR_IMG_EXISTS
	$(error $(DOCKER_DEFAULT_IMAGE) is not a valid docker image)
endif

package-docker:				## Create package inside Docker container.
ifdef DOCKER_IMAGE
	docker run -i --rm  --name "build-packages" $(DOCKER_OPTIONS) -v $(CURDIR):/build/packages $(DOCKER_IMAGE) /bin/bash -c "cd /build/packages/$(PKG) && fpm-cook clean && fpm-cook && fpm-cook clean"
else
	docker run -i --rm  --name "build-packages" $(DOCKER_OPTIONS) -v $(CURDIR):/build/packages $(DOCKER_DEFAULT_IMAGE) /bin/bash -c "cd /build/packages/$(PKG) && fpm-cook clean && fpm-cook && fpm-cook-clean"
endif

docker:					## Launch Docker.
ifdef DOCKER_IMAGE
	docker run -i --rm  --name "build-packages" $(DOCKER_OPTIONS) -v $(CURDIR):/build/packages $(DOCKER_IMAGE) /bin/bash
else
	docker run -i --rm  --name "build-packages" $(DOCKER_OPTIONS) -v $(CURDIR):/build/packages $(DOCKER_DEFAULT_IMAGE) /bin/bash
endif

test: header test.syntax
