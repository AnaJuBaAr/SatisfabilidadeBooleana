CC      ?= cc
CFLAGS  := -std=c11 -Wall -Wextra -Wpedantic -O2 -Iinclude
LDFLAGS :=

SRC_DIR   := src
BUILD_DIR := build
BIN_DIR   := bin
TARGET    := $(BIN_DIR)/escalonador

SRCS     := $(wildcard $(SRC_DIR)/*.c)
OBJS     := $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
DEPS     := $(OBJS:.o=.d)
LIB_OBJS := $(filter-out $(BUILD_DIR)/main.o,$(OBJS))

TEST_SRCS := $(wildcard tests/*.c)
TEST_BINS := $(TEST_SRCS:tests/%.c=$(BUILD_DIR)/tests/%)

# Parâmetros do alvo "run" (ex.: make run ALG=rr Q=3)
ALG  ?= fcfs
Q    ?= 2
FILE ?= data/processes.txt

.PHONY: all run compare test debug clean help

all: $(TARGET)

$(TARGET): $(OBJS) | $(BIN_DIR)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/tests/%: tests/%.c $(LIB_OBJS) | $(BUILD_DIR)/tests
	$(CC) $(CFLAGS) $< $(LIB_OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR) $(BIN_DIR) $(BUILD_DIR)/tests:
	mkdir -p $@

run: $(TARGET)
	./$(TARGET) -a $(ALG) -q $(Q) -f $(FILE)

compare: $(TARGET)
	@for a in fcfs sjf srtf rr priority; do \
		./$(TARGET) -a $$a -q $(Q) -f $(FILE) | sed -n "1p;/^Resumo/,\$$p"; echo; \
	done

test: $(TEST_BINS)
	@for t in $(TEST_BINS); do echo "==> $$t"; ./$$t || exit 1; done

# Build com símbolos de depuração e sanitizers (para achar bugs de memória)
debug: CFLAGS  := -std=c11 -Wall -Wextra -Wpedantic -g -O0 -Iinclude -fsanitize=address,undefined
debug: LDFLAGS := -fsanitize=address,undefined
debug: clean $(TARGET)

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

help:
	@echo "make            compila o simulador"
	@echo "make run         executa (ALG=fcfs|sjf|srtf|rr|priority Q=2 FILE=...)"
	@echo "make compare     executa todos os algoritmos e mostra o resumo"
	@echo "make test        compila e roda os testes"
	@echo "make debug       build com -g e sanitizers"
	@echo "make clean       remove build/ e bin/"

-include $(DEPS)