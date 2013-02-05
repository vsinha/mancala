UPC=upc
UPCFLAGS=-g -O0 -dwarf-2-upc -n6 -lrt

%: %.upc
	$(UPC) $(UPCFLAGS) $< -o $@

mancala: mancala.upc
