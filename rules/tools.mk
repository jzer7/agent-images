# ----------------------------------------------------------
# Purpose:
#   At runtime, detect tools in the system or fallback to
#   alternatives (Docker containers, bunx, npx).
#
#		It read versions from environment variables or '.tool-versions'.
#
#   It does not install the tools permanently. For that, use 'install-tools.sh'.
#
# Sets variables:
#   HADOLINT_CMD
#   MARKDOWNLINT_CMD
#   PRETTIER_CMD
#   SHELLCHECK_CMD
#   SHFMT_CMD
# ----------------------------------------------------------

-include $(TOP)/.tool-versions

HADOLINT_VERSION      ?= 2.15.1
MARKDOWNLINT_VERSION  ?= 0.22.1
PRETTIER_VERSION      ?= 3.9.9
SHELLCHECK_VERSION    ?= 0.11.0
SHFMT_VERSION         ?= 3.14.1

# ----------------------------------------------------------
# Linters
# ----------------------------------------------------------

# Pick the first one available (local, or container)
ifneq (,$(shell which hadolint))
  HADOLINT_CMD := hadolint
else ifneq (,$(shell which docker))
  HADOLINT_IMAGE  := hadolint/hadolint:v$(HADOLINT_VERSION)
  HADOLINT_CMD := docker run --rm -i $(HADOLINT_IMAGE) hadolint
else
  $(warning "No suitable Docker linter found. Please install 'hadolint' or ensure 'docker' is globally available.")
endif

# Pick the first one available (local, bunx, npx)
ifneq (,$(shell which markdownlint-cli2))
  MARKDOWNLINT_CMD := markdownlint-cli2
else ifneq (,$(shell which bunx))
  MARKDOWNLINT_CMD := bunx markdownlint-cli2@$(MARKDOWNLINT_VERSION)
else ifneq (,$(shell which npx))
  MARKDOWNLINT_CMD := npx markdownlint-cli2@$(MARKDOWNLINT_VERSION)
else
  $(warning "No suitable Markdown linter found. Please install 'markdownlint-cli2' globally or ensure 'bunx' or 'npx' is available.")
endif

# Pick the first one available (local, or container)
ifneq (,$(shell which shellcheck))
  SHELLCHECK_CMD := shellcheck
else ifneq (,$(shell which docker))
  SHELLCHECK_IMAGE := koalaman/shellcheck:v$(SHELLCHECK_VERSION)
  SHELLCHECK_CMD   := docker run --rm -i $(SHELLCHECK_IMAGE)
else
  $(warning "No suitable Shell linter found. Please install 'shellcheck' or ensure 'docker' is globally available.")
endif

# ----------------------------------------------------------
# Formatters
# ----------------------------------------------------------

# Pick the first one available (local, bunx, npx)
ifneq (,$(shell which prettier))
  PRETTIER_CMD := prettier
else ifneq (,$(shell which bunx))
  PRETTIER_CMD := bunx prettier@$(PRETTIER_VERSION)
else ifneq (,$(shell which npx))
  PRETTIER_CMD := npx prettier@$(PRETTIER_VERSION)
else
  $(warning "No suitable Markdown formatter found. Please install 'prettier' globally or ensure 'bunx' or 'npx' is available.")
endif

# Pick the first one available (local, or container)
ifneq (,$(shell which shfmt))
  SHFMT_CMD := shfmt
else ifneq (,$(shell which docker))
  SHFMT_IMAGE := mvdan/shfmt:v$(SHFMT_VERSION)
  SHFMT_CMD   := docker run --rm -i $(SHFMT_IMAGE)
else
  $(warning "No suitable Shell formatter found. Please install 'shfmt' or ensure 'docker' is globally available.")
endif

