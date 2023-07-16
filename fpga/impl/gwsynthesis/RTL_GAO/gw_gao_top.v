module gw_gao(
    ex_clk_3m6,
    \clk_360k_counter[3] ,
    \clk_360k_counter[2] ,
    \clk_360k_counter[1] ,
    \clk_360k_counter[0] ,
    clk_360k,
    \clk_36k_counter[3] ,
    \clk_36k_counter[2] ,
    \clk_36k_counter[1] ,
    \clk_36k_counter[0] ,
    clk_36k,
    \opll_wav7[31] ,
    \opll_wav7[30] ,
    \opll_wav7[29] ,
    \opll_wav7[28] ,
    \opll_wav7[27] ,
    \opll_wav7[26] ,
    \opll_wav7[25] ,
    \opll_wav7[24] ,
    \filtro_fm/clk_1m8 ,
    \filtro_fm/clk_360k ,
    \filtro_fm/clk_36k ,
    \filtro_fm/opll_wav[31] ,
    \filtro_fm/opll_wav[30] ,
    \filtro_fm/opll_wav[29] ,
    \filtro_fm/opll_wav[28] ,
    \filtro_fm/opll_wav[27] ,
    \filtro_fm/opll_wav[26] ,
    \filtro_fm/opll_wav[25] ,
    \filtro_fm/opll_wav[24] ,
    ex_clk_27m,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input ex_clk_3m6;
input \clk_360k_counter[3] ;
input \clk_360k_counter[2] ;
input \clk_360k_counter[1] ;
input \clk_360k_counter[0] ;
input clk_360k;
input \clk_36k_counter[3] ;
input \clk_36k_counter[2] ;
input \clk_36k_counter[1] ;
input \clk_36k_counter[0] ;
input clk_36k;
input \opll_wav7[31] ;
input \opll_wav7[30] ;
input \opll_wav7[29] ;
input \opll_wav7[28] ;
input \opll_wav7[27] ;
input \opll_wav7[26] ;
input \opll_wav7[25] ;
input \opll_wav7[24] ;
input \filtro_fm/clk_1m8 ;
input \filtro_fm/clk_360k ;
input \filtro_fm/clk_36k ;
input \filtro_fm/opll_wav[31] ;
input \filtro_fm/opll_wav[30] ;
input \filtro_fm/opll_wav[29] ;
input \filtro_fm/opll_wav[28] ;
input \filtro_fm/opll_wav[27] ;
input \filtro_fm/opll_wav[26] ;
input \filtro_fm/opll_wav[25] ;
input \filtro_fm/opll_wav[24] ;
input ex_clk_27m;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire ex_clk_3m6;
wire \clk_360k_counter[3] ;
wire \clk_360k_counter[2] ;
wire \clk_360k_counter[1] ;
wire \clk_360k_counter[0] ;
wire clk_360k;
wire \clk_36k_counter[3] ;
wire \clk_36k_counter[2] ;
wire \clk_36k_counter[1] ;
wire \clk_36k_counter[0] ;
wire clk_36k;
wire \opll_wav7[31] ;
wire \opll_wav7[30] ;
wire \opll_wav7[29] ;
wire \opll_wav7[28] ;
wire \opll_wav7[27] ;
wire \opll_wav7[26] ;
wire \opll_wav7[25] ;
wire \opll_wav7[24] ;
wire \filtro_fm/clk_1m8 ;
wire \filtro_fm/clk_360k ;
wire \filtro_fm/clk_36k ;
wire \filtro_fm/opll_wav[31] ;
wire \filtro_fm/opll_wav[30] ;
wire \filtro_fm/opll_wav[29] ;
wire \filtro_fm/opll_wav[28] ;
wire \filtro_fm/opll_wav[27] ;
wire \filtro_fm/opll_wav[26] ;
wire \filtro_fm/opll_wav[25] ;
wire \filtro_fm/opll_wav[24] ;
wire ex_clk_27m;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(ex_clk_27m),
    .data_i({ex_clk_3m6,\clk_360k_counter[3] ,\clk_360k_counter[2] ,\clk_360k_counter[1] ,\clk_360k_counter[0] ,clk_360k,\clk_36k_counter[3] ,\clk_36k_counter[2] ,\clk_36k_counter[1] ,\clk_36k_counter[0] ,clk_36k,\opll_wav7[31] ,\opll_wav7[30] ,\opll_wav7[29] ,\opll_wav7[28] ,\opll_wav7[27] ,\opll_wav7[26] ,\opll_wav7[25] ,\opll_wav7[24] ,\filtro_fm/clk_1m8 ,\filtro_fm/clk_360k ,\filtro_fm/clk_36k ,\filtro_fm/opll_wav[31] ,\filtro_fm/opll_wav[30] ,\filtro_fm/opll_wav[29] ,\filtro_fm/opll_wav[28] ,\filtro_fm/opll_wav[27] ,\filtro_fm/opll_wav[26] ,\filtro_fm/opll_wav[25] ,\filtro_fm/opll_wav[24] }),
    .clk_i(ex_clk_27m)
);

endmodule