TOP       := ..
include $(TOP)/rules/common.mk
ASSET_DIR := $(TOP)/assets
CUR_DIR   := $(notdir $(CURDIR))

DRY_RUN   ?=     # Any non-blank value will make this a dry run

ifneq ($(DRY_RUN),)
_DRYRUN   := @echo "== [DRY-RUN] =="
endif

# ----------------------------------------------------------

IMAGE_VERSION ?= latest
BASE_IMAGE    ?= node:26-trixie-slim
IMAGE_TAG     ?= $(CUR_DIR)-$(IMAGE_VERSION)
IMAGE_NAME    := jzer7/agent:$(IMAGE_TAG)

# Regex patterns are separated by the pipe symbol ('|')
TEST_HELP_PATTERNS    := ^Usage: uv|^Commands:$$|^Cache options:$$|^Python options:$$
TEST_VERSION_PATTERNS := '^uv '

# ----------------------------------------------------------

.PHONY: all
all: build lint test ## 🚀 Run default pipeline

.PHONY: build
build: Dockerfile ## 📦 Build container image
	$(_DRYRUN) docker buildx build \
		$(BUILDX_EXTRA_ARGS) \
		--load \
		--build-context assets=$(ASSET_DIR) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-t $(IMAGE_NAME) .
	@echo "=== Completed build of image $(IMAGE_NAME)"

.PHONY: lint
lint: ## 🔍 Lint Dockerfile

.PHONY: clean
clean: ## 🧹 Clean transient and temporary files

.PHONY: distclean
distclean: clean ## 🧼 Clean all generated files and built Docker image
	-docker rmi $(IMAGE_NAME) 2>/dev/null || true

# ----------------------------------------------------------
.PHONY: test
test: test-uv-help test-uv-version ## 🧪 Run tests

.PHONY: test-uv-help
test-uv-help: build
	@echo "=== Starting test (uv-help) of image $(IMAGE_NAME)"
	ifeq ($(_DRYRUN),)
	@output=$$(docker run --rm $(IMAGE_NAME) uv --help) && \
	$(call check_for_all_patterns,$(TEST_HELP_PATTERNS),$$output)
	endif
	@echo "=== Completed test (uv-help) of image $(IMAGE_NAME)"

.PHONY: test-uv-version
test-uv-version: build
	@echo "=== Starting test (uv-version) of image $(IMAGE_NAME)"
	ifeq ($(_DRYRUN),)
	@output=$$(docker run --rm $(IMAGE_NAME) uv --version) && \
	$(call check_for_all_patterns,$(TEST_VERSION_PATTERNS),$$output)
	endif
	@echo "=== Completed test (uv-version) of image $(IMAGE_NAME)"
