.PHONY: all clean build

all: rv32i_simple.v

build:
	dune build @all

rv32i_simple.v:
	dune build top.exe
	./_build/default/top.exe > rv32i_simple.v

clean:
	dune clean
	rm -f rv32i_simple.v
