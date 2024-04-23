# Bicubic Interpolation in Verilog HDL

将960×540图像上采样至3840×2160。采用Bicubic插值方法，用Verilog HDL实现。

## Reference

- [Cubic Convolution Interpolation for Digital Image Processing](http://hmi.stanford.edu/doc/Tech_Notes/filtergram_interpolation/Keys_cubic_interp.pdf)
- [Why systolic architectures?](https://www.cse.wustl.edu/~roger/560M.f17/01653825.pdf)

## Requirements

- Ubuntu 20.04
- Vivado 2023.2

## Content

主要内容：

1. [理论分析](./Doc/Theory.md) - 分析三次立方插值的可行性
2. [脉动阵列](./Doc/Systolic.md) - 介绍硬件实现bicubic插值的方式
3. [软件模拟](./Doc/Scripts.md) - 用软件模拟硬件的计算过程
4. [仿真与实现](./Doc/Result.md) - 具体硬件涉及，仿真结果与实现结果
