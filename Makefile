# Compiler and tools
CC=gcc
AS=as
OCAMLOPT=ocamlfind ocamlopt
OCAML_WHERE=$(shell ocamlc -where)

# Flags
CFLAGS=-I$(OCAML_WHERE) -Iinclude -fPIC -g
# -thread: enables threading mode
# -package unix,threads: tells ocamlfind to resolve these dependencies
# -linkpkg: automatically links the required library archives
OCAMLOPT_FLAGS=-g -thread -package unix,threads -linkpkg

.PHONY: all clean

all: build/main.exe

build/:
	mkdir -p build/

build/engine.o: src/engine.s | build/
	$(AS) src/engine.s -o build/engine.o

build/stub.o: src/stub.c | build/
	$(CC) $(CFLAGS) -c src/stub.c -o build/stub.o

build/libengine.a: build/engine.o build/stub.o
	ar rcs build/libengine.a build/engine.o build/stub.o

# Build main.exe using ocamlfind
build/main.exe: src/main.ml build/libengine.a | build/
	$(OCAMLOPT) $(OCAMLOPT_FLAGS) -o $@ src/main.ml build/libengine.a

clean:
	rm -rf build/*