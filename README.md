# RISC-V CPU



## 简介

- 一个用 Verilog 编写的 RISC-V CPU, 功能为运行二进制可执行文件
- 本项目为 ACM 班 20 级大二大作业, 题面见: [RISCV-CPU](https://github.com/ACMClassCourses/RISCV-CPU)
- 目前进度: `Finish IF`

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

