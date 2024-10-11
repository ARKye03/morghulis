APP_NAME := morghulis
BIN_DIR := build
NIX_BIN_DIR := buildNix
OUTPUT := $(BIN_DIR)/src/$(APP_NAME)
NIX_OUTPUT := $(NIX_BIN_DIR)/src/$(APP_NAME)
NIX_RESULT := ./result

# Default target for development
.PHONY: dev
dev: $(BIN_DIR)
	ninja -C $(BIN_DIR)
	@./$(OUTPUT)

# Target for production builds
.PHONY: build
build: $(BIN_DIR)
	ninja -C $(BIN_DIR)

# Target for nix builds
.PHONY: nixbuild
nixbuild: $(NIX_BIN_DIR)
	ninja -C $(NIX_BIN_DIR)

.PHONY: nixdev
nixdev: $(NIX_BIN_DIR)
	ninja -C $(NIX_BIN_DIR)
	@./$(NIX_OUTPUT)

# Clean build directories
.PHONY: clean
clean:
	rm -rf $(BIN_DIR) $(NIX_BIN_DIR) $(NIX_RESULT)

# Create build directories
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(NIX_BIN_DIR):
	mkdir -p $(NIX_BIN_DIR)
