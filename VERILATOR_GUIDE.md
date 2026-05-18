# Verilator 使用指南：SystemVerilog → C++ 仿真

## 概述

Verilator 是一款将 **SystemVerilog (SV)** 硬件描述代码转换为 **C++** 代码的工具。转换后，你可以编写 C++ 测试平台（testbench）来驱动仿真、注入激励、检查输出，甚至生成波形。

本仓库以一个 **ALU（算术逻辑单元）** 模块为例，演示完整流程。

---

## 项目文件结构

```
alu_verilator/
├── alu.sv              # SystemVerilog RTL 设计
├── sim_main.cpp         # C++ 仿真主程序（testbench）
└── obj_dir/             # Verilator 生成的 C++ 代码 + 编译产物
    ├── Valu.h           # 顶层模型类定义（对应 alu 模块）
    ├── Valu.cpp         # 模型实现
    ├── Valu.mk          # Makefile，用于编译链接
    ├── Valu__Syms.h     # 符号表类
    ├── Valu___024root.h # 顶层 root 实例
    ├── Valu___024unit.h # 枚举/类型定义映射
    └── Valu             # 最终编译出的可执行仿真文件
```

---

## 第一步：alu.sv — RTL 设计

[alu.sv](alu.sv) 定义了一个带 **参数化位宽** 的 ALU 模块。

| 特性 | 说明 |
|------|------|
| 位宽 `WIDTH` | 默认 6-bit，可通过参数调整 |
| 操作类型 `operation_t` | `nop=0`、`add=1`、`sub=2` |
| 输入寄存器 | `op_in_r`、`a_in_r`、`b_in_r` — 在时钟上升沿寄存输入 |
| 输出寄存器 | `out`、`out_valid` — 在时钟上升沿寄存结果 |

**关键细节：**
- `/*verilator public*/` 标记在枚举类型上，告诉 Verilator 将该枚举暴露到 C++ 中供 testbench 使用。
- 模块使用 **三段式流水线**：输入寄存 → 组合逻辑运算 → 输出寄存。

---

## 第二步：sim_main.cpp — C++ Testbench

[sim_main.cpp](sim_main.cpp) 是用 C++ 编写的仿真驱动。

### 核心流程

```
创建 Valu 实例 → 初始化信号 → 复位 → 时钟循环 → 释放
```

### 关键要素

| 元素 | 说明 |
|------|------|
| `Valu *dut = new Valu` | 实例化 Verilator 生成的 ALU 模型 |
| `dut->clk`, `dut->rst`, `dut->a_in` ... | 直接读写 RTL 模块的端口信号 |
| `dut->eval()` | **关键函数**：通知 Verilator 评估所有逻辑（组合 + 时序），相当于让仿真前进一步 |
| `dut->clk ^= 1` | 翻转时钟，产生时钟沿 |
| `rand() % N` | 生成随机激励 |

### `eval()` 的作用

`eval()` 是 Verilator 仿真模型的核心方法，它在 **零时间增量** 内完成以下工作：

1. 传播所有组合逻辑
2. 触发时序逻辑（always_ff）
3. 更新所有输出信号

每当你改变任意输入信号的值，都需要调用 `dut->eval()` 来让模型计算新结果。

---

## 第三步：obj_dir — Verilator 生成文件说明

执行 `verilator --build` 后，Verilator 在 `obj_dir/` 下生成以下关键文件：

| 文件 | 作用 |
|------|------|
| **Valu.h** | **顶层头文件**。定义 `Valu` 类，将 SV 模块的端口映射为 C++ 成员变量（`clk`, `rst`, `a_in` 等），提供 `eval()` 接口 |
| **Valu.cpp** | 模型实现文件，包含 `eval()` 的具体逻辑 |
| **Valu.mk** | Makefile，定义了如何编译和链接最终的可执行文件 |
| **Valu__Syms.h** | 符号表类，维护模型内部所有信号和子模块的状态 |
| **Valu___024root.h/cpp** | 顶层 root 实例，对应 SV 中 `alu` 模块顶层的作用域 |
| **Valu___024unit.h/cpp** | 用户定义类型映射，例如 `operation_t` 枚举在 C++ 中对应的实现 |
| **Valu_ALL.cpp** | 所有生成文件的聚合，加速并行编译 |
| **Valu_ALL.a** | 静态库，包含编译后的模型目标文件 |
| **Valu** | **最终可执行文件**，由 Makefile 将 `Valu.cpp` + `sim_main.o` 链接生成 |

---

## 完整操作步骤

### 前提条件

安装 Verilator（5.0+）：

```bash
# Ubuntu / Debian
sudo apt-get install verilator

# 或从源码编译
git clone https://github.com/verilator/verilator
cd verilator
autoconf && ./configure && make -j$(nproc) && sudo make install
```

### 步骤 1：将 SV 转换为 C++

```bash
cd alu_verilator
verilator -Wall --cc alu.sv --exe sim_main.cpp --build
```

| 参数 | 含义 |
|------|------|
| `-Wall` | 开启所有警告 |
| `--cc` | 生成 C++ 输出（而非 SystemC） |
| `alu.sv` | 输入的 SystemVerilog 设计文件 |
| `--exe sim_main.cpp` | 指定 C++ testbench，生成可执行文件 |
| `--build` | 自动调用 make 编译生成最终可执行文件 |

### 步骤 2：运行仿真

```bash
./obj_dir/Valu
```

正常输出示例：

```
Time 0 | op=2 a=63 b=10 out=47
Time 0 | op=1 a=31 b=9 out=44
...
```

### 分步模式（手动编译）

如果你希望先转换、再修改 C++、最后编译：

```bash
# 仅转换（不编译）
verilator -Wall --cc alu.sv --exe sim_main.cpp

# 手动编译
make -C obj_dir -f Valu.mk

# 运行
./obj_dir/Valu
```

---

## 常见问题

### Q：为什么要在 SV 枚举类型上加 `/*verilator public*/`？

Verilator 默认会将 SV 类型优化掉。加上此标记后，Verilator 会在 C++ 中生成对应的枚举定义，使 testbench 能直接使用 `add`、`sub` 等名称。

### Q：`eval()` 对应硬件中的什么？

`eval()` 对应 **一个 delta 周期** 的仿真推进 — 它会计算所有组合逻辑的当前值，然后更新时序逻辑。在时钟循环中，你通常在每个时钟沿变化后调用 `eval()`。

### Q：如何生成 VCD 波形？

在 `sim_main.cpp` 中添加：

```cpp
#include "verilated_vcd_c.h"

// 在 main 中：
VerilatedVcdC *trace = new VerilatedVcdC;
dut->trace(trace, 99);
trace->open("wave.vcd");

// 每次 eval() 后：
trace->dump(sim_time);
```
