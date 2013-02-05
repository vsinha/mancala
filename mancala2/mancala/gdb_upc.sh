#!/bin/sh
[ -n "$GDB_UPC" ] \
  || export GDB_UPC=/usr/local/upc/bin/gdb
[ -n "$UDA_GUPC_PLUGIN_LIBRARY" ] \
  || export UDA_GUPC_PLUGIN_LIBRARY=/usr/local/upc/uda-plugin/uda-plugin.so
if [ '!' -f "$GDB_UPC" ]; then
  echo "not found: $GDB_UPC" >&2
  exit 2
fi
if [ '!' -x "$GDB_UPC" ]; then
  echo "not executable: $GDB_UPC" >&2
  exit 2
fi
if !"$GDB_UPC" -v 2>&1 | grep -sq 'GDB UPC'; then
  echo "not GDB UPC: $GDB_UPC" >&2
  exit 2
fi
if [ ! -f "$UDA_GUPC_PLUGIN_LIBRARY" ]; then
  echo "UDA plugin not found: ${UPC_GUPC_PLUGIN_LIBRARY}" >&2
  exit 2
fi
if ! file "$UDA_GUPC_PLUGIN_LIBRARY" | grep -sqi 'shared object'; then
  echo "UDA plugin not a shared object: ${UPC_GUPC_PLUGIN_LIBRARY}" >&2
  exit 2
fi
if [ ! -w . ]; then
  echo "can't write into current working directory: $PWD" >&2
  exit 2
fi
if ! cat > ./.gdb-upc-init << EOF
set pagination off
set target-async on
set detach-on-fork off
set non-stop on
set upcstartgate on
EOF
then
  echo "can't write to: $PWD/.gdb-upc-init" >&2
  exit 2
fi
${GDB_UPC} -x ./.gdb-upc-init "$@"
rm -f ./.gdb-upc-init

