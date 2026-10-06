TOP := .
include $(TOP)/rules/common.mk
TOOLS_BIN_DIR ?= $(HOME)/.local/bin
include $(TOP)/rules/tools.mk

IMAGE_VERSION       ?= latest

FETCH_SCRIPT        := scripts/fetch-asset.sh
SHELL_SCRIPTS       := $(wildcard scripts/*.sh)
DOCKERFILES         := $(wildcard */Dockerfile)
MARKDOWN_FILES      := $(shell git ls-files --cached --others --exclude-standard -- '*.md')

AGENTS              := $(patsubst %/Dockerfile,%,$(filter-out base/Dockerfile,$(DOCKERFILES)))
AGENT_BUILD_TARGETS := $(addprefix build-,$(AGENTS))
AGENT_TEST_TARGETS  := $(addprefix test-,$(AGENTS))

ACTIONS             := $(shell act --list 2> /dev/null | awk '/^[0-9]/ {print $$2}')
ACTION_TARGETS      := $(addprefix action-,$(ACTIONS))

# ----------------------------------------------------------
# QA tools used during CI
# ----------------------------------------------------------

HADOLINT_ARGS       := --ignore DL3008 --ignore DL3016

# ----------------------------------------------------------
# Top level targets
# ----------------------------------------------------------

.PHONY: all lint format-check format-fix test qa build clean distclean
all: qa build

lint: sh-lint docker-lint ## 🔍 Lint shell scripts and Dockerfiles

format-check: sh-format-check docker-format-check ## 🎨 Check format of shell scripts and validate Dockerfiles

format-fix: sh-format-fix docker-format-fix ## 🎨 Format shell scripts and validate Dockerfiles

test: test-base $(AGENT_TEST_TARGETS) ## 🧪 Run test suite

qa: lint format-check test ## ✅ Run all quality assurance checks

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

.PHONY: refresh-scripts
refresh-scripts: ## 📥 Fetch newer version of upstream agent scripts
	$(FETCH_SCRIPT) --force

# ----------------------------------------------------------
# CI tool installation targets
# ----------------------------------------------------------
.PHONY: install-tools-images install-tools-docs

install-tools-images: ## 🛠️ Install pinned tools for container images
	./scripts/install-tools.sh hadolint shellcheck shfmt

install-tools-docs: ## 🛠️ Install pinned tools for documentation
	./scripts/install-tools.sh markdownlint prettier

# ----------------------------------------------------------
# Lint targets
# ----------------------------------------------------------
.PHONY: sh-lint
sh-lint: ## 🔍 Lint shell scripts with shellcheck
	@for sf in $(SHELL_SCRIPTS); do \
		echo "==> Linting $$sf"; \
		$(SHELLCHECK_CMD) "$$sf"; \
	done

.PHONY: docker-lint
docker-lint: ## 🔍 Lint Dockerfiles with hadolint
	@for df in $(DOCKERFILES); do \
		echo "==> Linting $$df"; \
		$(HADOLINT_CMD) $(HADOLINT_ARGS) - < "$$df" || exit 1; \
	done

.PHONY: md-lint
md-lint: ## 🔍 Lint Markdown files with markdownlint-cli2
	@echo "==> Linting $(MARKDOWN_FILES)"
	$(MARKDOWNLINT_CMD) $(MARKDOWN_FILES)

# ----------------------------------------------------------
# Format targets
# ----------------------------------------------------------

.PHONY: sh-format-check sh-format-fix
sh-format-check: ## 🎨 Format shell scripts with shfmt
	@echo "==> Checking format of $(SHELL_SCRIPTS)"
	$(SHFMT_CMD) -d $(SHELL_SCRIPTS)

sh-format-fix: ## 🎨 Format shell scripts with shfmt
	@echo "==> Formatting $(SHELL_SCRIPTS)"
	$(SHFMT_CMD) -w $(SHELL_SCRIPTS)

.PHONY: docker-format-check docker-format-fix
docker-format-check: ## 🎨 Format/check Dockerfiles
	@echo "No dedicated Dockerfile formatter configured; syntax validated by lint."

docker-format-fix: ## 🎨 Format/check Dockerfiles
	@echo "No dedicated Dockerfile formatter configured; syntax validated by lint."

.PHONY: md-format-check md-format-fix
md-format-check: ## 🔍 Check format of Markdown files with prettier
	@echo "==> Checking format of $(MARKDOWN_FILES)"
	$(PRETTIER_CMD) --check $(MARKDOWN_FILES)

md-format-fix: ## 🔍 Format Markdown files with prettier
	@echo "==> Formatting $(MARKDOWN_FILES)"
	$(PRETTIER_CMD) --write $(MARKDOWN_FILES)

# ----------------------------------------------------------
# Test targets
# ----------------------------------------------------------
.PHONY: $(AGENT_TEST_TARGETS)
test-base: ## 📦 Test the base Docker image
	$(MAKE) -C base test IMAGE_VERSION="$(IMAGE_VERSION)"

$(AGENT_TEST_TARGETS): test-%: ## 📦 Test a specific agent Docker image
	$(MAKE) -C "$*" test IMAGE_VERSION="$(IMAGE_VERSION)"

# ----------------------------------------------------------
# Build targets
# ----------------------------------------------------------
.PHONY: $(AGENT_BUILD_TARGETS)
build-base: ## 📦 Build the base Docker image
	$(MAKE) -C base build IMAGE_VERSION="$(IMAGE_VERSION)"

$(AGENT_BUILD_TARGETS): build-%: build-base ## 📦 Build a specific agent Docker image
	$(MAKE) -C "$*" build IMAGE_VERSION="$(IMAGE_VERSION)"

# ----------------------------------------------------------
# Test GitHub Actions
# ----------------------------------------------------------

ACT_IMAGE ?= ubuntu-latest=catthehacker/ubuntu:act-latest
ACT_ARGS  := -P $(ACT_IMAGE)
ACT_ARGS  += --actor 'jzer7/agent-images'
ACT_ARGS  += --defaultbranch main
ACT_ARGS  += --use-gitignore
ifeq ($(shell uname -m),arm64)
ACT_ARGS  += --container-architecture linux/arm64
endif

actions: ## 📦 List GitHub Action workflows (run with `make action-NAME`)
	@echo "Actions: $(ACTIONS)"

.PHONY: $(ACTION_TARGETS)
$(ACTION_TARGETS): action-%: ## 📦 Run a specific GitHub Action workflow using 'act'
	act -j $* $(ACT_ARGS)
