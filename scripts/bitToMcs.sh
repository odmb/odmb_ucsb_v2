#!/bin/sh
# Author: Jaebak Kim
# Date: 2019/08/29
# Referenced from *.prm and https://www.xilinx.com/support/documentation/sw_manuals/xilinx14_1/devref.pdf and https://forums.xilinx.com/t5/Design-Tools-Others/promgen-Command-Line-Help/td-p/322729
# Converts bit file to prom
#OUTPUT_FILE=./v3-20v1_odmb_ucsb
if [ $# -ne 3 ]; then
  echo Not enough arguments.
  echo $0 OUTPUT_FILE INPUT_BIT_FILE INPUT_DATA_FILE
  echo Example: $0 v3-20v0_odmb_ucsb ODMB_UCSB_V2.bit odmb_toprom.hex
  exit 1
fi
#OUTPUT_FILE=./testing
#INPUT_BIT_FILE=./ODMB_UCSB_V2.bit
#INPUT_DATA_FILE=./odmb_toprom.hex
OUTPUT_FILE=$1
INPUT_BIT_FILE=$2
INPUT_DATA_FILE=$3
promgen -w -p mcs -c FF -o $OUTPUT_FILE -x xcf128x -u 00000000 $INPUT_BIT_FILE -data_file up 300000 $INPUT_DATA_FILE -bpi_dc parallel -data_width 16
