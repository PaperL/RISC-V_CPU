# RISC-V CPU



## 简介

- 一个用 Verilog 编写的 RISC-V CPU, 功能为运行二进制可执行文件
- 本项目为 ACM 班 20 级大二大作业, 题面见: [RISCV-CPU](https://github.com/ACMClassCourses/RISCV-CPU)
- 目前进度: `Finish IF`

## 结构

- Tomasulo's algorithm
- 设计手稿见 `Design.pdf`
  - [![owIJht.jpg](https://s4.ax1x.com/2021/12/04/owIJht.jpg)](https://imgtu.com/i/owIJht)


## 说明

- 整体文件结构说明见 [tutorial.md](https://github.com/PaperL/RISC-V_CPU/blob/main/tutorial.md)
- 文件格式化使用 VS Code 插件 `verilog-formatter` v1.0.0
  - 使用 `K&R` Style, 附加参数为 `--convert-tabs -o -p --break-elseifs` (参考 [istyle-verilog-formatter](https://github.com/thomasrussellmurphy/istyle-verilog-formatter))
- 运行指令详见 `riscv/my_test.sh`

