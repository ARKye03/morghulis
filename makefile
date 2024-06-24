APP_NAME=zoore_layer
SRC_DIR=src
BIN_DIR=bin

# Source files
SOURCES=$(wildcard $(SRC_DIR)/*.vala)

# Output binary name
OUTPUT=$(BIN_DIR)/$(APP_NAME)

GTK4=--pkg gtk4
GTK4_LAYER_SHELL=--pkg gtk4-layer-shell-0

DEV_FLAGS=$(GTK4) $(GTK4_LAYER_SHELL) 
BUILD_FLAGS=$(GTK4) $(GTK4_LAYER_SHELL)

# Default target for development
dev: $(SOURCES)
	@mkdir -p $(BIN_DIR)
	valac $(DEV_FLAGS) -o $(OUTPUT) $^
	@echo "Running the application..."
	@./$(OUTPUT)

# Target for production builds
build: $(SOURCES)
	@mkdir -p $(BIN_DIR)
	valac $(BUILD_FLAGS) -o $(OUTPUT) $^

# Clean the build
clean:
	@rm -rf $(BIN_DIR)