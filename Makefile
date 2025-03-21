NASM_SRC = nasm_printf
C_SRC = main
OUTPUT_NAME = nasm_printf.out
BUILD_DIR = build

build:
	@mkdir -p $(BUILD_DIR)
	@nasm -f elf64 $(NASM_SRC).s -o $(BUILD_DIR)/$(NASM_SRC).o
	@gcc -c $(C_SRC).c -o $(BUILD_DIR)/$(C_SRC).o
	@gcc -no-pie -z noexecstack $(BUILD_DIR)/$(C_SRC).o $(BUILD_DIR)/$(NASM_SRC).o -o $(BUILD_DIR)/$(OUTPUT_NAME)

launch:
	./$(BUILD_DIR)/$(OUTPUT_NAME)


debug: build
	r2 -d ./$(BUILD_DIR)/$(OUTPUT_NAME)

all: build
	./$(BUILD_DIR)/$(OUTPUT_NAME)

test:
	nasm -f elf64 test.s
	ld -s -o test.out test.o
	./test.out

.PHONY: build

