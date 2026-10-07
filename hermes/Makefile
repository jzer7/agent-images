TOP       := ..
include $(TOP)/rules/common.mk
ASSET_DIR := $(TOP)/assets
CUR_DIR   := $(notdir $(CURDIR))

# The Hermes image is pretty large (do not use it during dev)
DRY_RUN   ?= 1   # Any non-blank value will make this a dry run

ifneq ($(DRY_RUN),)
_DRYRUN   := @echo "== [DRY-RUN] =="
endif

# ----------------------------------------------------------

IMAGE_VERSION ?= latest
BASE_IMAGE    ?= jzer7/agent:base-$(IMAGE_VERSION)
IMAGE_TAG     ?= $(CUR_DIR)-$(IMAGE_VERSION)
IMAGE_NAME    := jzer7/agent:$(IMAGE_TAG)
TEST_SCRIPT   ?= ./test-image.sh

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
test: build ## 🧪 Run tests
ifeq ($(_DRYRUN),)
	@$(TEST_SCRIPT) $(IMAGE_NAME)
endif
