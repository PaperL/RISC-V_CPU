# RISC-V CPU



## 简介

- 一个用 Verilog 编写的 RISC-V CPU, 功能为运行二进制可执行文件
- 本项目为 ACM 班 20 级大二大作业, 题面见: [RISCV-CPU](https://github.com/ACMClassCourses/RISCV-CPU)
- 目前进度: `Finish IS`

## 结构

- Tomasulo's algorithm
- 设计手稿见 [Design Draft](Design.pdf)

## 说明

- 题面文件结构说明见 [tutorial.md](tutorial.md)
- 开发环境 Windows, VS Code, iVerilog, Vivado
- VS Code 所用插件
  - 语言支持 [`Verilog-HDL/SystemVerilog/Bluespec SystemVerilog`](https://github.com/mshr-h/vscode-verilog-hdl-support) `v1.5.1`
  - 自动代码格式化 [`verilog-formatter`](https://github.com/IsaacJT/Verilog-Formatter) `v1.0.0`
    - 使用 `K&R` Style, 附加参数为 `--convert-tabs -o -p --break-elseifs` (参考 [istyle-verilog-formatter](https://github.com/thomasrussellmurphy/istyle-verilog-formatter))
  - VCD 文件浏览器 [`impulse`](https://github.com/toem/impulse.vscode) `v0.3.4`
- 运行指令详见 [`riscv/my_test.sh`](riscv/my_test.sh)

## 支持指令

> 非完整 RV64I BASE INTEGER INSTRUCTION (51 instructions)，缺少以下指令：
>
> LD, LWU, ADDIW, SLLIW, SRLIW, SRAIW, SD, ADDW, SUBW, SLLW, SRLW, SRAW, ECALL, EBREAK (14 instructions)
>
> 下表为实现的 37 个指令
>
> 缺省表示同上。内部编码可重复，因为该编码会分发给 RS 或 LSB，各个元件内指令编码不会重复

| 指令名称  | 内部编码 | 指令类型 | OPCODE  | FUNCT3 | FUNCT7  | 说明                                  |
| --------- | -------- | -------- | ------- | ------ | ------- | ------------------------------------- |
| **LUI**   | 00001    | U        | 0110111 |        |         | Load Upper Immediate                  |
| **AUIPC** | 00010    |          | 0010111 |        |         | Add Upper Immediate to PC             |
| **JAL**   | 00011    | UJ       | 1101111 |        |         | Jump & Link                           |
| **JALR**  | 00100    | I        | 1100111 |        |         | Jump & Link Register                  |
| **BEQ**   | 00101    | SB       | 1100011 | 000    |         | Branch Equal                          |
| **BNE**   | 00110    |          |         | 001    |         | Branch Not Equal                      |
| **BLT**   | 00111    |          |         | 100    |         | Branch Less Than                      |
| **BGE**   | 01000    |          |         | 101    |         | Branch Greater than or Equal          |
| **BLTU**  | 01001    |          |         | 110    |         | Branch Less than Unsigned             |
| **BGEU**  | 01010    |          |         | 111    |         | Branch Greater than or Equal Unsigned |
| **LB**    | 0001     | I        | 0000011 | 000    |         | Load Byte                             |
| **LH**    | 0010     |          |         | 001    |         | Load Halfword                         |
| **LW**    | 0011     |          |         | 010    |         | Load Word                             |
| **LBU**   | 0100     |          |         | 100    |         | Load Byte Unsigned                    |
| **LHU**   | 0101     |          |         | 101    |         | Load Halfword Unsigned                |
| **SB**    | 0110     | S        | 0100011 | 000    |         | Store Byte                            |
| **SH**    | 0111     |          |         | 001    |         | Store Halfword                        |
| **SW**    | 1000     |          |         | 010    |         | Store Word                            |
| **ADDI**  | 01011    | I        | 0010011 | 000    |         | ADD Immediate                         |
| **SLLI**  | 01100    |          |         | 001    |         | Shift Left Immediate                  |
| **SLTI**  | 01101    |          |         | 010    |         | Set Less than Immediate               |
| **SLTIU** | 01110    |          |         | 011    |         | Set Less than Immediate Unsigned      |
| **XORI**  | 01111    |          |         | 100    |         | XOR Immediate                         |
| **SRLI**  | 10000    |          |         | 101    | 0000000 | Shift Right Immediate                 |
| **SRAI**  | 10001    |          |         | 101    | 0100000 | Shift Right Arith Immediate           |
| **ORI**   | 10010    |          |         | 110    |         | OR Immediate                          |
| **ANDI**  | 10011    |          |         | 111    |         | AND Immediate                         |
| **ADD**   | 10100    | R        | 0110011 | 000    | 0000000 | ADD                                   |
| **SUB**   | 10101    |          |         | 000    | 0100000 | SUBtract                              |
| **SLL**   | 10110    |          |         | 001    |         | Shift Left                            |
| **SLT**   | 10111    |          |         | 010    |         | Set Less than                         |
| **SLTU**  | 11000    |          |         | 011    |         | Set Less than Unsigned                |
| **XOR**   | 11001    |          |         | 100    |         | XOR                                   |
| **SRL**   | 11010    |          |         | 101    | 0000000 | Shift Right                           |
| **SRA**   | 11011    |          |         | 101    | 0100000 | Shift Right Arithmetic                |
| **OR**    | 11100    |          |         | 110    |         | OR                                    |
| **AND**   | 11101    |          |         | 111    |         | AND                                   |

