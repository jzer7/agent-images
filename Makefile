VERSION       ?= latest

FETCH_SCRIPT  := scripts/fetch-asset.sh
SHELL_SCRIPTS := $(wildcard scripts/*.sh)

DOCKERFILES              := $(wildcard */Dockerfile)
AGENTS                   := $(patsubst %/Dockerfile,%,$(filter-out base/Dockerfile,$(DOCKERFILES)))
AGENT_BUILD_TARGETS      := $(addprefix build-,$(AGENTS))

# ----------------------------------------------------------
# Help output
# ----------------------------------------------------------
_C_CYAN := \033[36m
_C_OFF  := \033[0m

.PHONY: help
help: ## ❓ Display help information for Makefile targets
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  $(_C_CYAN)%-30s$(_C_OFF) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ----------------------------------------------------------
# Top level targets
# ----------------------------------------------------------

.PHONY: all lint format test qa build clean distclean
all: qa build

lint: sh-lint docker-lint ## 🔍 Lint shell scripts and Dockerfiles

format: sh-format docker-format ## 🎨 Format shell scripts and validate Dockerfiles

test: ## 🧪 Run test suite
	@echo "No tests defined."

qa: lint format test ## ✅ Run all quality assurance checks

build: fetch-scripts build-base $(AGENT_BUILD_TARGETS) ## 📦 Build all Docker images

clean: ## 🧹 Clean transient and temporary files
	rm -rf .tmp */*.tmp.*

distclean: clean ## 🧼 Clean all generated files and built Docker images
	-docker rmi $(BASE_IMAGE) $(CLAUDE_IMAGE) $(CODEX_IMAGE) $(HERMES_IMAGE) $(KILO_IMAGE) $(OPENCLAW_IMAGE) $(PI_IMAGE) 2>/dev/null || true

# ----------------------------------------------------------
# Fetch targets
# ----------------------------------------------------------
.PHONY: fetch-scripts
fetch-scripts: ## 📥 Fetch upstream agent scripts
	$(FETCH_SCRIPT)

# ----------------------------------------------------------
# Lint targets
# ----------------------------------------------------------
.PHONY: sh-lint
sh-lint: ## 🔍 Lint shell scripts with shellcheck
	shellcheck $(SHELL_SCRIPTS)

.PHONY: docker-lint
docker-lint: ## 🔍 Lint Dockerfiles with hadolint
	@for df in $(DOCKERFILES); do \
		echo "==> Linting $$df"; \
		docker run --rm -i hadolint/hadolint hadolint --ignore DL3008 --ignore DL3016 - < "$$df" || exit 1; \
	done

# ----------------------------------------------------------
# Format targets
# ----------------------------------------------------------

.PHONY: sh-format
sh-format: ## 🎨 Format shell scripts with shfmt
	shfmt -w $(SHELL_SCRIPTS)

.PHONY: docker-format
docker-format: ## 🎨 Format/check Dockerfiles
	@echo "No dedicated Dockerfile formatter configured; syntax validated by lint."

# ----------------------------------------------------------
# Build targets
# ----------------------------------------------------------
.PHONY: $(AGENT_BUILD_TARGETS)
build-base: ## 📦 Build the base Docker image
	$(MAKE) -C base build VERSION="$(VERSION)"

$(AGENT_BUILD_TARGETS): build-%: build-base ## 📦 Build a specific agent Docker image
	$(MAKE) -C "$*" build VERSION="$(VERSION)"
