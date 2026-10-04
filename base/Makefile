VERSION    ?= latest
ASSET_DIR  := ../assets
CUR_DIR    := $(notdir $(CURDIR))
BASE_IMAGE ?= node:26-trixie-slim
IMAGE_TAG  ?= $(CUR_DIR)-$(VERSION)
IMAGE_NAME := jzer7/agent:$(IMAGE_TAG)

# ----------------------------------------------------------
.PHONY: help
help: ## ❓ Display help information for Makefile targets
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  $(_C_CYAN)%-30s$(_C_OFF) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
# ----------------------------------------------------------

.PHONY: all
all: build lint test ## 🚀 Run default pipeline

.PHONY: build
build: Dockerfile ## 📦 Build container image
	docker buildx build \
		--load \
		--build-context assets=$(ASSET_DIR) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-t $(IMAGE_NAME) .

.PHONY: lint
lint: ## 🔍 Lint Dockerfile

.PHONY: test
test: ## 🧪 Run tests

.PHONY: clean
clean: ## 🧹 Clean transient and temporary files

.PHONY: distclean
distclean: clean ## 🧼 Clean all generated files and built Docker image
	-docker rmi $(IMAGE_NAME) 2>/dev/null || true
