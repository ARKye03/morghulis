APP_NAME=com.github.ARKye03.zoore_layer
BIN_DIR=build
OUTPUT=$(BIN_DIR)/$(APP_NAME)

# Default target for development
dev: 
	ninja -C $(BIN_DIR)
	@./$(OUTPUT)

# Target for production builds
build: 
	ninja -C $(BIN_DIR)
