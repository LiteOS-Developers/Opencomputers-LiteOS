# Compiler
CXX := g++

# Directories
SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin

TARGET := $(BIN_DIR)/toolchain

# Flags
CXXFLAGS := -std=c++17 -Wall -Wextra -MMD -MP -O2
LDFLAGS :=

SRCS := $(shell find $(SRC_DIR) -name '*.cpp')

OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRCS))

DEPS := $(OBJS:.o=.d)

# Default target
all: $(TARGET)

# Link
$(TARGET): $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

# Compile (auto-create subdirectories)
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Include dependencies
-include $(DEPS)

# Clean
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

rebuild: clean all

.PHONY: all clean rebuild run
