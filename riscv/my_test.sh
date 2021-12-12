# You should run this script at "riscv" folder
cd src/
iverilog -o bench ../sim/testbench.v common/block_ram/*.v common/fifo/*.v common/uart/*.v *.vh *.v
mv -f bench ../test/
cd ../test/
