# Verilator 使用说明

## 编译命令

```bash
verilator -Wall --cc alu.sv --exe main.cpp --build
```

### 选项含义

| 选项 | 说明 |
|------|------|
| `-Wall` | 开启所有警告，帮助发现 RTL 代码中的潜在问题 |
| `--cc` | 生成 C++ 输出（而非 SystemC），这是最常用的模式 |
| `--exe <file>` | 指定要链接的用户 C++ 主文件（如 `main.cpp`），生成可执行文件而非仅静态库 |
| `--build` | 自动编译链接，等价于运行生成的 `Makefile`；不加此选项只生成 `.cpp/.h` 不编译 |
| `alu.sv` | 输入 SystemVerilog 源文件 |

执行后目录下会生成 `obj_dir/` 文件夹，包含所有 Verilator 生成的 C++ 代码和编译产物。

---

## obj_dir 文件结构

```
obj_dir/
├── Valu                    # 最终生成的可执行文件（仿真程序）
├── Valu.mk                 # 主 Makefile，make -f Valu.mk 可单独编译
├── Valu_classes.mk         # 列出所有生成类的分类（fast/slow）
├── Valu__ALL.cpp           # 聚合包含全部生成源码（预编译头加速）
├── Valu__ALL.a             # 静态库文件
│
├── Valu.h                  # 模块顶层头文件，用户 main.cpp 需 #include 它
├── Valu.cpp                # 顶层模块的实现
├── Valu__Syms.h            # 符号表头文件，管理所有模块的层次化信号
├── Valu__Syms__Slow.cpp    # 符号表慢速路径实现
│
├── Valu___024root.h        # 根模块 (top-level) 头文件
├── Valu___024root__0.cpp   # 根模块 fast 路径实现（组合逻辑求值）
├── Valu___024root__0__Slow.cpp  # 根模块 slow 路径（复位、时序逻辑）
├── Valu___024root__Slow.cpp     # 根模块 slow 辅助函数
│
├── Valu___024unit.h        # 单元级（enum/typedef 等）声明
├── Valu___024unit__Slow.cpp
│
├── Valu__Trace__0.cpp           # VCD 波形 trace 支持（fast）
├── Valu__Trace__0__Slow.cpp     # VCD 波形 trace 初始化（slow）
├── Valu__TraceDecls__0__Slow.cpp # trace 信号声明
│
├── Valu__pch.h             # 预编译头
│
├── Valu__ver.d             # 依赖关系文件
├── Valu__verFiles.dat      # 记录参与编译的源文件列表
├── Valu__ALL.d             # ALL.cpp 的依赖文件
│
├── sim_main.o              # 用户 main.cpp 编译后的目标文件
├── verilated.o             # Verilator 运行时库编译产物
├── verilated_vcd_c.o       # VCD 波形库编译产物
├── verilated_threads.o     # 线程支持库编译产物
└── *.d                     # 各 .o 的依赖关系文件
```

### 文件分类说明

- **`Valu` 前缀**：由模块名决定（`alu.sv` → `Valu`），`V` 是 Verilator 固定前缀
- **`__024root`**：对应 Verilog 的 `$root` 空间，`024` 是 `$` 的 ASCII 码转义
- **`__024unit`**：对应文件级声明（typedef、enum 等）
- **`__Slow`**：慢速路径，含初始化和时序逻辑，优化等级较低
- **fast（无 `__Slow`）**：快速路径，纯组合逻辑，高优化等级
- **`__Trace`**：VCD 波形追踪相关，仅在开启 tracing 时生成
