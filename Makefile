# Compiler and tools
CC = gcc
AS = as
OCAMLOPT = ocamlfind ocamlopt
OCAML_WHERE = $(shell ocamlc -where)

# Flags: -O3 for performance, -fPIC for shared object compatibility
CFLAGS = -I$(OCAML_WHERE) -Iinclude -O3 -fPIC -Wall -rdynamic

OCAMLOPT_FLAGS = -O3 -thread -package unix,threads -linkpkg

# Targets
.PHONY: all clean

all: build/main.exe

build/:
	mkdir -p build/

# 1. Assemble Hot Path
build/engine.o: src/engine.s | build/
	$(AS) src/engine.s -o build/engine.o

# 2. Compile FFI Bridge
build/stub.o: src/stub.c | build/
	$(CC) $(CFLAGS) -c src/stub.c -o build/stub.o

# 3. Create Static Archive
build/libengine.a: build/engine.o build/stub.o
	ar rcs build/libengine.a build/engine.o build/stub.o

# 4. Link everything with OCaml Runtime
build/main.exe: src/main.ml build/libengine.a | build/
	$(OCAMLOPT) $(OCAMLOPT_FLAGS) -o $@ build/libengine.a src/main.ml

# Add this to your Makefile
profile: build/main.exe
	perf stat -e instructions,cycles,cache-misses ./build/main.exe

clean:
	rm -rf build/*