UPC=upc
ifeq ($(DEBUG),1)
OFLAGS=-O0
GFLAGS=-g3 -dwarf-2-upc -fupc-debug
else
OFLAGS=-O3 -DNDEBUG=1
GFLAGS=-g -dwarf-2-upc
endif
LFLAGS=-lrt
WFLAGS=-W -Wextra -pedantic
UPCFLAGS=$(OFLAGS) $(GFLAGS) $(WFLAGS) $(LFLAGS) -n6

%: %.upc
	$(UPC) $(UPCFLAGS) $< -o $@

mancala: mancala.upc
