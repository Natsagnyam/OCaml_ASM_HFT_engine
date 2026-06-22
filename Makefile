CC=gcc
AS=as
OCAML_WHERE=$(shell ocamlc -where)
# Consolidate flags for consistency
CFLAGS=-I$(OCAML_WHERE) -fPIC -g
OCAMLOPT_FLAGS=-g

all: build/main.exe

# Ensure the build directory exists
build/:
	mkdir -p build/

build/engine.o: src/engine.s | build/
	$(AS) $(ASFLAGS) src/engine.s -o build/engine.o

build/stub.o: src/stub.c | build/
	$(CC) $(CFLAGS) -c src/stub.c -o build/stub.o

build/libengine.a: build/engine.o build/stub.o
	ar rcs build/libengine.a build/engine.o build/stub.o

build/main.exe: src/main.ml build/libengine.a | build/
	ocamlopt $(OCAMLOPT_FLAGS) -o build/main.exe src/main.ml build/libengine.a

clean:
	rm -rf build/*