# Makefile for MkDocs documentation
#
SHELL = /bin/bash

# You can set these variables from the command line.
BUILDDIR        ?= _build/html
MKDOCS          = mkdocs
MKDOCSBUILDOPTS = --clean --strict --verbose
MKDOCSBUILD     = $(MKDOCS) build $(MKDOCSBUILDOPTS)
MKDOCSSERVE     = $(MKDOCS) serve -a 0.0.0.0:8000

SHORT_NAME ?= workflow
VERSION ?= git-$(shell git rev-parse --short HEAD)
IMAGE := ${SHORT_NAME}:${VERSION}

REPO_PATH := github.com/deis/${SHORT_NAME}
DEV_ENV_WORK_DIR := /src/${REPO_PATH}
DEV_ENV_PREFIX := docker run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} -p 8000:8000
DEV_ENV_CMD := ${DEV_ENV_PREFIX} ${DEV_ENV_IMAGE}

BUILD_CMD := $(MKDOCSBUILD) --site-dir $(BUILDDIR) && \
	echo && \
	echo "Build finished. The HTML pages are in $(BUILDDIR)."

TEST_CMD := grep -q "<title>Home - Deis Workflow Documentation</title>" _build/html/index.html && \
	echo && \
	echo "Test finished. The HTML pages are in $(BUILDDIR)."

build:
	$(BUILD_CMD)

serve:
	$(MKDOCSSERVE)

clean:
	rm -rf $(BUILDDIR)/*

deps:
	pip install -r requirements.txt

test: build
	$(TEST_CMD)

docker-build-docs:
	$(DEV_ENV_CMD) ${IMAGE} $(BUILD_CMD)

docker-test: docker-build-docs
	${DEV_ENV_CMD} ${IMAGE} $(TEST_CMD)

docker-build:
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} .

docker-serve:
	${DEV_ENV_CMD} ${IMAGE} $(MKDOCSSERVE)

run: docker-build docker-serve

build-gh-pages-chart:
	helm fetch --untar hephy/workflow
	cp charts/workflow/templates/* workflow/templates/
	cp charts/workflow/requirements.yaml workflow
	cp charts/workflow/values.yaml workflow
	# actually should be "helm dependencies update" but currently
	# the new subcharts aren't released on the chart repo yet
	rm -rf workflow/charts/workflow-manager
	helm package workflow
	helm repo index .
	rm -rf workflow/
	git add -u
	@echo commit this to the gh-pages branch
	git status
