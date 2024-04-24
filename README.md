# Bicubic Interpolation in Verilog HDL

用Verilog实现Bicubic插值，将960×540图像上采样至3840×2160。

## Reference

- [Cubic Convolution Interpolation for Digital Image Processing](http://hmi.stanford.edu/doc/Tech_Notes/filtergram_interpolation/Keys_cubic_interp.pdf)
- [Why systolic architectures?](https://www.cse.wustl.edu/~roger/560M.f17/01653825.pdf)

## Restrictions

**这个IP只能用于实现960×540图像至3840×2160图像的上采样**。因为卷积核的系数是固定的，在IP内部是通过实例化多个常系数乘法器实现的矩阵乘法功能。乘法器的系数、个数都是固定的，滑窗的大小等等都是固定的，所以无法支持其它的上采样需求。

## Requirements

- Ubuntu 20.04
- Vivado 2023.2

代码是在2022年8月写的，到现在快两年过去了，一直没有好好整理，现在回想起来很多细节忘了，只能大概理一下设计的思路。源码都存放在[bicubic.srcs](./Logic/bicubic/bicubic.srcs/)目录，我是用Vivado 2023.2重新构建的工程（当时写的时候用的是Vivado 2021.2），如果Vivado版本太低，则需要从源码重新构建工程。我没试过回退低版本，可能会遇到IP版本无法回退的问题T_T。

我也用Vivado 2023.2将IP打包，并放在了[ip_repo](./Logic/ip_repo/)目录下。

## Interface

<!-- TODO(qiujiandong): 添加接口，寄存器说明 -->

## Content

- [Logic](./Logic/)目录存放的主要是Verilog逻辑代码
- [Mock](./Mock/)目录存放的是用C语言模拟硬件执行过程，并将结果作为参照与硬件执行结果进行比对
- [Scripts](./Scripts/)目录存放了运行软件模拟测试的脚本，和一些其它实用脚本
- [Doc](./Doc/)目录存放的是相关的说明文档

主要内容：

1. [理论分析](./Doc/Theory.md) - 分析三次立方插值的可行性
2. [脉动阵列](./Doc/Systolic.md) - 介绍硬件实现bicubic插值的方式
3. [软件模拟](./Doc/Scripts.md) - 用软件模拟硬件的计算过程
4. [仿真与实现](./Doc/Result.md) - 具体逻辑设计，仿真结果与实现结果
