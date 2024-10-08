APP_NAME=morghulis
BIN_DIR=build
OUTPUT=$(BIN_DIR)/src/$(APP_NAME)

# Default target for development
dev: 
	ninja -C $(BIN_DIR)
	@./$(OUTPUT)

# Target for production builds
build: 
	ninja -C $(BIN_DIR)
