//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.11 Education
//Created Time: 2023-06-21 01:16:09
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {ex_clk_27m}] -add
create_clock -name clk_3m6 -period 277.778 -waveform {0 138.889} [get_ports {ex_clk_3m6}] -add

create_generated_clock -name clk_135 -source [get_ports {ex_clk_27m}] -master_clock clk -divide_by 1 -multiply_by 5 -add [get_nets {vdp4/clk_135}]

create_generated_clock -name clk_sdramp -source [get_ports {ex_clk_27m}] -master_clock clk -divide_by 1 -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_nets {vdp4/clk_sdramp}]
create_generated_clock -name clk_sdram -source [get_ports {ex_clk_27m}] -master_clock clk -divide_by 1 -multiply_by 4 -add [get_nets {vdp4/clk_sdram}]
