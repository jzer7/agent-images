# ----------------------------------------------------------
define check_for_all_patterns
printf '%s\n' "$(2)" | awk -v required='$(1)' 'BEGIN { n = split(required, patterns, /[|]/) } { for (i = 1; i <= n; i++) if ($$0 ~ patterns[i]) found[i] = 1 } END { for (i = 1; i <= n; i++) if (!found[i]) exit 1 }'
endef

# ----------------------------------------------------------
.PHONY: help
help: ## ❓ Display help information for Makefile targets
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  $(_C_CYAN)%-30s$(_C_OFF) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
# ----------------------------------------------------------