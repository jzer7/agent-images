TOP       := ..
include $(TOP)/rules/common.mk
ASSET_DIR := $(TOP)/assets
CUR_DIR   := $(notdir $(CURDIR))

# ----------------------------------------------------------

IMAGE_VERSION ?= latest
BASE_IMAGE    ?= jzer7/agent:base-$(IMAGE_VERSION)
IMAGE_TAG     ?= $(CUR_DIR)-$(IMAGE_VERSION)
IMAGE_NAME    := jzer7/agent:$(IMAGE_TAG)

# Regex patterns are separated by the pipe symbol ('|')
TEST_HELP_PATTERNS    := ^Command Code v|^Usage$$|^Options$$
TEST_VERSION_PATTERNS := ^[0-9]+[.][0-9]+[.][0-9]+

# ----------------------------------------------------------

.PHONY: all
all: build lint test ## 🚀 Run default pipeline

.PHONY: build
build: Dockerfile ## 📦 Build container image
	docker buildx build \
		$(BUILD_EXTRA_ARGS) \
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
test: test-help test-version ## 🧪 Run tests

.PHONY: test-help
test-help: build
	@echo "=== Starting test (help) of image $(IMAGE_NAME)"
	@output=$$(docker run --rm $(IMAGE_NAME) --help) && \
	$(call check_for_all_patterns,$(TEST_HELP_PATTERNS),$$output)
	@echo "=== Completed test (help) of image $(IMAGE_NAME)"

.PHONY: test-version
test-version: build
	@echo "=== Starting test (version) of image $(IMAGE_NAME)"
	@output=$$(docker run --rm $(IMAGE_NAME) --version) && \
	$(call check_for_all_patterns,$(TEST_VERSION_PATTERNS),$$output)
	@echo "=== Completed test (version) of image $(IMAGE_NAME)"
