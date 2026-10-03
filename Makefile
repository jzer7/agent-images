VERSION ?= latest
BASE_IMAGE := jzer7/agent:base-$(VERSION)
CLAUDE_IMAGE := jzer7/agent:claude-$(VERSION)
CODEX_IMAGE := jzer7/agent:codex-$(VERSION)
HERMES_IMAGE := jzer7/agent:hermes-$(VERSION)
KILO_IMAGE := jzer7/agent:kilo-$(VERSION)
OPENCLAW_IMAGE := jzer7/agent:openclaw-$(VERSION)
PI_IMAGE := jzer7/agent:pi-$(VERSION)

SHELL_SCRIPTS := agent.sh fetch-installer.sh
DOCKERFILES := base.dockerfile claude-agent.dockerfile codex-agent.dockerfile hermes-agent.dockerfile kilo-agent.dockerfile openclaw-agent.dockerfile pi-agent.dockerfile

.PHONY: all build build-base build-claude-agent build-codex-agent build-hermes-agent build-kilo-agent build-openclaw-agent build-pi-agent fetch-installers \
	lint sh-lint docker-lint format sh-format docker-format test qa clean distclean

all: lint format test build

.PHONY: build
build: build-base build-claude-agent build-codex-agent build-hermes-agent build-kilo-agent build-openclaw-agent build-pi-agent ## 📦 Build all Docker images

.PHONY: build-base
build-base: base.dockerfile ## 📦 Build base container image
	docker build -t $(BASE_IMAGE) -f $< .

.PHONY: build-claude-agent
build-claude-agent: claude-agent.dockerfile installers/claude-install.sh build-base ## 📦 Build claude-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(CLAUDE_IMAGE) -f $< .

.PHONY: build-codex-agent
build-codex-agent: codex-agent.dockerfile build-base ## 📦 Build codex-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(CODEX_IMAGE) -f $< .

.PHONY: build-hermes-agent
build-hermes-agent: hermes-agent.dockerfile installers/hermes-install.sh build-base ## 📦 Build hermes-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(HERMES_IMAGE) -f $< .

.PHONY: build-kilo-agent
build-kilo-agent: kilo-agent.dockerfile installers/kilo-install.sh build-base ## 📦 Build kilo-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(KILO_IMAGE) -f $< .

.PHONY: build-openclaw-agent
build-openclaw-agent: openclaw-agent.dockerfile installers/openclaw-install.sh build-base ## 📦 Build openclaw-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(OPENCLAW_IMAGE) -f $< .

.PHONY: build-pi-agent
build-pi-agent: pi-agent.dockerfile build-base ## 📦 Build pi-agent container image
	docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) -t $(PI_IMAGE) -f $< .

.PHONY: fetch-installers
fetch-installers: ## 📥 Fetch upstream agent installer scripts
	./fetch-installer.sh

.PHONY: lint
lint: sh-lint docker-lint ## 🔍 Lint shell scripts and Dockerfiles

.PHONY: sh-lint
sh-lint: ## 🔍 Lint shell scripts with shellcheck
	shellcheck $(SHELL_SCRIPTS)

.PHONY: docker-lint
docker-lint: ## 🔍 Lint Dockerfiles with hadolint
	@for df in $(DOCKERFILES); do \
		echo "==> Linting $$df"; \
		docker run --rm -i hadolint/hadolint hadolint --ignore DL3008 --ignore DL3016 - < "$$df" || exit 1; \
	done

.PHONY: format
format: sh-format docker-format ## 🎨 Format shell scripts and validate Dockerfiles

.PHONY: sh-format
sh-format: ## 🎨 Format shell scripts with shfmt
	shfmt -w $(SHELL_SCRIPTS)

.PHONY: docker-format
docker-format: ## 🎨 Format/check Dockerfiles
	@echo "No dedicated Dockerfile formatter configured; syntax validated by lint."

.PHONY: test
test: ## 🧪 Run test suite
	@echo "No tests defined."

.PHONY: qa
qa: lint format test ## ✅ Run all quality assurance checks

.PHONY: clean
clean: ## 🧹 Clean transient and temporary files
	rm -rf .tmp installers/*.tmp.*

.PHONY: distclean
distclean: clean ## 🧼 Clean all generated files and built Docker images
	-docker rmi $(BASE_IMAGE) $(CLAUDE_IMAGE) $(CODEX_IMAGE) $(HERMES_IMAGE) $(KILO_IMAGE) $(OPENCLAW_IMAGE) $(PI_IMAGE) 2>/dev/null || true

