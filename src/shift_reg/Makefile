# Generic Makefile for compiling and running tests on verilog modules
# using icarus verilog simulator. Also generates test vectors with
# python.
# Written by David Bascelli
# August 2018
NAME = shift_reg_tb
SOURCE = $(wildcard *.v)
LIB = 
INC = ../
FLAGS = $(patsubst %, -y%, ${LIB}) $(patsubst %, -I%, ${INC})

${NAME} : ${SOURCE} 
	iverilog ${FLAGS} -o ${NAME}.vvp ${SOURCE}

dump.lx2 : ${NAME}
	vvp ${NAME}.vvp -lxt2

.phoney : run
run : dump.lx2

.phoney : graph
graph : dump.lx2
	gtkwave --script=graph.tcl dump.lx2

.phoney : clean
clean:
	rm -f  ${NAME} *.dat *.vcd *.lx2 *.vvp
