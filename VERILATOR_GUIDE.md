# Verilator 使用指南：SystemVerilog → C++ 仿真

Verilator 将 SystemVerilog 硬件代码转换为 C++ 模型，然后用 C++ 写 testbench 来仿真验证。

本仓库以一个 **ALU（算术逻辑单元）** 模块为例演示完整流程。

---

## 一、Verilator 环境配置

### 安装

```bash
sudo apt-get install verilator        # Ubuntu/Debian
# 或
brew install verilator                # macOS
```

### 验证

```bash
verilator --version
```

能正常输出版本号即安装成功。

---

## 二、Verilator 编译命令详解

```bash
verilator -Wall --cc alu.sv --exe sim_main.cpp --build
```

| 选项 | 作用 |
|------|------|
| `-Wall` | 开启所有编译警告，帮助排查 RTL 代码中的问题 |
| `--cc` | 生成 C++ 代码（另一种模式 `--sc` 生成 SystemC） |
| `alu.sv` | 输入的 SystemVerilog 设计文件 |
| `--exe sim_main.cpp` | 指定 C++ testbench 文件，让 Verilator 生成 **可执行文件**（不加则只生成静态库） |
| `--build` | 转换后自动调用 make 编译链接（不加则只生成 .cpp/.h，需手动 make） |

**分步执行（转换 → 编译分开做）：**
```bash
verilator -Wall --cc alu.sv --exe sim_main.cpp    # 只转换，生成 obj_dir/
make -C obj_dir -f Valu.mk                         # 手动编译
./obj_dir/Valu                                     # 运行仿真
```

---

## 三、两个源文件的作用

### alu.sv — RTL 设计

定义 6-bit ALU，支持三种操作：`nop`（0）、`add`（1，加法）、`sub`（2，减法）。

三段式流水线：**输入寄存 → 组合逻辑运算 → 输出寄存**。

注意枚举类型上的 `/*verilator public*/` 标记，它告诉 Verilator 把这个枚举暴露到 C++ 中，testbench 才能直接使用 `add`、`sub` 这些名字。

### sim_main.cpp — C++ Testbench

仿真主程序，流程很简单：

```
创建 Valu 模型 → 初始化信号 → 复位 4 个周期 → 时钟循环 200 拍 → 释放
```

核心机制：
- **`dut->clk` / `dut->rst` / `dut->a_in` 等**：直接读写 RTL 模块的端口信号
- **`dut->eval()`**：关键函数，每改变一次输入都要调用，让 Verilator 计算组合逻辑并更新时序逻辑
- **`dut->clk ^= 1`**：翻转时钟产生上升沿/下降沿

---

## 四、obj_dir 生成的文件

执行命令后，Verilator 在 `obj_dir/` 下生成以下文件：

### 顶层接口（用户需关注）

| 文件 | 作用 |
|------|------|
| **Valu.h** | 顶层头文件，定义 `Valu` 类，把 SV 端口映射为 C++ 成员变量（`clk`, `rst`, `a_in`...），提供 `eval()` 接口。**写 testbench 必须 `#include` 这个文件** |
| **Valu.mk** | Makefile，描述如何编译和链接。`make -f Valu.mk` 用它 |
| **Valu** | 最终编译出的可执行仿真文件，运行 `./obj_dir/Valu` 即可仿真 |

### 内部实现（一般不需关心）

| 文件 | 作用 |
|------|------|
| **Valu.cpp** | `eval()` 的具体实现 |
| **Valu__Syms.h** | 符号表，管理模型所有内部信号和子模块 |
| **Valu___024root.h/cpp** | 顶层 root 实例，对应 SV 中 `alu` 模块的顶层作用域 |
| **Valu___024unit.h/cpp** | 用户自定义类型映射（如 `operation_t` 枚举） |
| **Valu_ALL.cpp** | 将所有生成代码聚合到一个文件，加速编译 |
| **Valu_ALL.a** | 模型编译后的静态库 |
| **Valu__pch.h** | 预编译头，加速编译 |
| **Valu_classes.mk** | 辅助 Makefile，列出文件分类（fast / slow 路径） |
| **Valu__verFiles.dat** | 记录参与编译的源文件列表 |
| **\*.o / \*.d** | 编译目标文件和依赖关系文件 |

### 命名规则说明

- **`V` + 模块名**：模块 `alu` → `Valu`（`V` 是 Verilator 固定前缀）
- **`__024root`**：`024` 是 `$` 的 ASCII 码，`$root` 表示 Verilog 顶层作用域
- **`__024unit`**：文件级声明（typedef、enum 等）
- **`__Slow`**：慢速路径，含初始化和时序逻辑
- **无 `__Slow`**：快速路径，纯组合逻辑，高优化等级
