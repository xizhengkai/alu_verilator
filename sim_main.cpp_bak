#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Valu.h"

#define MAX_SIM_TIME 100  // 仿真总时间
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);

    // 创建 DUT
    Valu *dut = new Valu;

    // 开启波形追踪
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);       // trace 5 层 hierarchy
    m_trace->open("waveform.vcd");

    // 初始化信号
    dut->clk = 0;
    dut->rst = 1;
    dut->op_in = 0;
    dut->a_in = 0;
    dut->b_in = 0;
    dut->in_valid = 0;

    // 先复位几个周期
    for (int i = 0; i < 4; i++) {
        dut->clk = 0; dut->eval(); m_trace->dump(sim_time++); 
        dut->clk = 1; dut->eval(); m_trace->dump(sim_time++); 
    }
    dut->rst = 0;  // 释放复位

    // 主仿真循环
    while (sim_time < MAX_SIM_TIME) {
        // 每个时钟上升沿生成随机输入
        if (dut->clk == 0) {
            dut->op_in = rand() % 3;             // 随机操作：0=nop 1=add 2=sub
            dut->a_in = rand() % 64;             // 6-bit 随机数
            dut->b_in = rand() % 64;             // 6-bit 随机数
            dut->in_valid = rand() % 2;          // 随机有效位
        }

        // 翻转时钟
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time++);

        // 打印上升沿结果
        if (dut->clk == 1 && dut->out_valid) {
            std::cout << "Time " << sim_time 
                      << " | op=" << (int)dut->op_in 
                      << " a=" << (int)dut->a_in 
                      << " b=" << (int)dut->b_in 
                      << " out=" << (int)dut->out 
                      << std::endl;
        }
    }

    // 关闭波形并释放资源
    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
