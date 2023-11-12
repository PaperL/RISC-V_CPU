# ⛳ RISC-V CPU

> For Chinese readme, see [README_CN.md](README_CN.md).

## 🎈 Introduction

- The FPGA circuit implementation of a RISC-V CPU, written in Verilog, capable of running RISC-V executable files
- This project is the assignment for the sophomore year of the ACM class of 2020. The problem statement can be found at: [RISCV-CPU](https://github.com/ACMClassCourses/RISCV-CPU/tree/8f72ea7d582209e5bb1ab51e844141e4081e9712)



## ✒️ CPU Structure

- Tomasulo out-of-order execution algorithm
- See design draft [Draft.pdf](Draft.pdf)



## 📖 Instructions

- Description of provided FPGA communication and test tools (for the AX7035 board) can be found in [tutorial.md](tutorial.md)
- Development environment: Windows, VS Code, iVerilog, Vivado
- VS Code extensions:
  - Language support [`Verilog-HDL/SystemVerilog/Bluespec SystemVerilog`](https://github.com/mshr-h/vscode-verilog-hdl-support) `v1.5.1`
  - Formatting [`verilog-formatter`](https://github.com/IsaacJT/Verilog-Formatter) `v1.0.0`
    - Using `K&R` style with arguments `--convert-tabs -o -p --break-elseifs` (referencing [istyle-verilog-formatter](https://github.com/thomasrussellmurphy/istyle-verilog-formatter))
  - VCD viewer [`impulse`](https://github.com/toem/impulse.vscode) `v0.3.4`
- See execution commands at [`riscv/my_test.sh`](riscv/my_test.sh)



## 📇 Supported Instructions

> RV32I Base Integer Instructions (39 instructions) without ECALL and EBREAK instructions.
>
> The following table lists the implemented 37 instructions.
>
> Blank cell represents the same as above. The internal code can be nonunique because different instructions are processed in different modules.

| Inst      | InternalCode | FMT | Opcode  | Funct3 | Funct7  | Note                                  |
| --------- | ------------ | --- | ------- | ------ | ------- | ------------------------------------- |
| **LUI**   | 00001        | U   | 0110111 |        |         | Load Upper Immediate                  |
| **AUIPC** | 00010        |     | 0010111 |        |         | Add Upper Immediate to PC             |
| **JAL**   | 00011        | UJ  | 1101111 |        |         | Jump & Link **(Jump in IF)**          |
| **JALR**  | 00100        | I   | 1100111 |        |         | Jump & Link Register                  |
| **BEQ**   | 00101        | SB  | 1100011 | 000    |         | Branch Equal                          |
| **BNE**   | 00110        |     |         | 001    |         | Branch Not Equal                      |
| **BLT**   | 00111        |     |         | 100    |         | Branch Less Than                      |
| **BGE**   | 01000        |     |         | 101    |         | Branch Greater than or Equal          |
| **BLTU**  | 01001        |     |         | 110    |         | Branch Less than Unsigned             |
| **BGEU**  | 01010        |     |         | 111    |         | Branch Greater than or Equal Unsigned |
| **LB**    | 0001         | I   | 0000011 | 000    |         | Load Byte                             |
| **LH**    | 0010         |     |         | 001    |         | Load Halfword                         |
| **LW**    | 0011         |     |         | 010    |         | Load Word                             |
| **LBU**   | 0100         |     |         | 100    |         | Load Byte Unsigned                    |
| **LHU**   | 0101         |     |         | 101    |         | Load Halfword Unsigned                |
| **SB**    | 0110         | S   | 0100011 | 000    |         | Store Byte                            |
| **SH**    | 0111         |     |         | 001    |         | Store Halfword                        |
| **SW**    | 1000         |     |         | 010    |         | Store Word                            |
| **ADDI**  | 01011        | I   | 0010011 | 000    |         | ADD Immediate                         |
| **SLLI**  | 01100        |     |         | 001    |         | Shift Left Immediate                  |
| **SLTI**  | 01101        |     |         | 010    |         | Set Less than Immediate               |
| **SLTIU** | 01110        |     |         | 011    |         | Set Less than Immediate Unsigned      |
| **XORI**  | 01111        |     |         | 100    |         | XOR Immediate                         |
| **SRLI**  | 10000        |     |         | 101    | 0000000 | Shift Right Immediate                 |
| **SRAI**  | 10001        |     |         | 101    | 0100000 | Shift Right Arith Immediate           |
| **ORI**   | 10010        |     |         | 110    |         | OR Immediate                          |
| **ANDI**  | 10011        |     |         | 111    |         | AND Immediate                         |
| **ADD**   | 10100        | R   | 0110011 | 000    | 0000000 | ADD                                   |
| **SUB**   | 10101        |     |         | 000    | 0100000 | SUBtract                              |
| **SLL**   | 10110        |     |         | 001    |         | Shift Left                            |
| **SLT**   | 10111        |     |         | 010    |         | Set Less than                         |
| **SLTU**  | 11000        |     |         | 011    |         | Set Less than Unsigned                |
| **XOR**   | 11001        |     |         | 100    |         | XOR                                   |
| **SRL**   | 11010        |     |         | 101    | 0000000 | Shift Right                           |
| **SRA**   | 11011        |     |         | 101    | 0100000 | Shift Right Arithmetic                |
| **OR**    | 11100        |     |         | 110    |         | OR                                    |
| **AND**   | 11101        |     |         | 111    |         | AND                                   |
