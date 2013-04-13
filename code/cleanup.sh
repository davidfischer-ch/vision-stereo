#!/usr/bin/env bash

for extension in 'm51' 'bak' 'o' 'i' 'd' 's' 'lst' 'rpt' 'done' 'summary'; do
  find . -iname "*.$extension" -exec rm -f {} \;
done

rm -rf 'FPGA_VHDL/db/' 'FX2_Logiciel_DDRAW/debug/' 2>/dev/null
