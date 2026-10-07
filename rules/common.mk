# ----------------------------------------------------------
BUILDX_CACHE_DIR ?= $(TOP)/.cache/buildx
ifeq ($(origin BUILDX_EXTRA_ARGS),undefined)
  BUILDX_EXTRA_ARGS := --cache-from=type=local,src=$(BUILDX_CACHE_DIR) --cache-to=type=local,dest=$(BUILDX_CACHE_DIR),mode=max
endif

# ----------------------------------------------------------
# Checks if LINES has **all** these PATTERNS.
# Patterns are regex separated by a pipe symbol ('|').
# Use as:
#   $(call check_for_all_patterns,$(PATTERNS),$$LINES)
define check_for_all_patterns
printf '%s\n' "$(2)" | awk -v required='$(1)' 'BEGIN { n = split(required, patterns, /[|]/) } { for (i = 1; i <= n; i++) if ($$0 ~ patterns[i]) found[i] = 1 } END { for (i = 1; i <= n; i++) if (!found[i]) exit 1 }'
endef

# ----------------------------------------------------------
# System detection
# e.g. Linux, Darwin, FreeBSD, ...
OS   := $(strip $(shell uname -s))
ARCH := $(strip $(shell uname -m))

ifeq ($(OS),Darwin)
  ifeq ($(ARCH),arm64)
    ARCH := aarch64
  else ifneq ($(ARCH),x86_64)
    $(error "These makefiles have only been tested on x86_64 and aarch64 systems")
  endif
else ifneq ($(OS),Linux)
  $(error "These makefiles have only been tested on Linux and MacOS")
endif

# ----------------------------------------------------------
# Help output
# ----------------------------------------------------------
_C_CYAN := \033[36m
_C_OFF  := \033[0m

.PHONY: help
help: ## ❓ Display help information for Makefile targets
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  $(_C_CYAN)%-30s$(_C_OFF) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
