.PHONY: luacheck
luacheck:
	@luacheck --codes --no-cache ./lua ./spec

.PHONY: fmt
fmt:
	@stylua .

.PHONY: check-fmt
check-fmt:
	@stylua --check .

.PHONY: check-lint
check-lint: luacheck

.PHONY: test
test:
	@busted --lua=nlua
