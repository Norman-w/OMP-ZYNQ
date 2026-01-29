//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Thu Jul 25 10:57:57 2024
//Host        : DESKTOP-JCJ439V running 64-bit major release  (build 9200)
//Command     : generate_target System_wrapper.bd
//Design      : System_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module System_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    TP_Rst_tri_io,
    ad7606_busy_i_0,
    ad7606_convst_o_0,
    ad7606_cs_n_o_0,
    ad7606_db_i_0,
    ad7606_os_o_0,
    ad7606_rd_n_o_0,
    ad7606_reset_o_0,
    lcd_0_bl,
    lcd_0_data,
    lcd_0_de,
    lcd_0_hs,
    lcd_0_pclk,
    lcd_0_vs);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  inout [0:0]TP_Rst_tri_io;
  input ad7606_busy_i_0;
  output ad7606_convst_o_0;
  output ad7606_cs_n_o_0;
  input [15:0]ad7606_db_i_0;
  output [2:0]ad7606_os_o_0;
  output ad7606_rd_n_o_0;
  output ad7606_reset_o_0;
  output lcd_0_bl;
  output [15:0]lcd_0_data;
  output lcd_0_de;
  output lcd_0_hs;
  output lcd_0_pclk;
  output lcd_0_vs;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [0:0]TP_Rst_tri_i_0;
  wire [0:0]TP_Rst_tri_io_0;
  wire [0:0]TP_Rst_tri_o_0;
  wire [0:0]TP_Rst_tri_t_0;
  wire ad7606_busy_i_0;
  wire ad7606_convst_o_0;
  wire ad7606_cs_n_o_0;
  wire [15:0]ad7606_db_i_0;
  wire [2:0]ad7606_os_o_0;
  wire ad7606_rd_n_o_0;
  wire ad7606_reset_o_0;
  wire lcd_0_bl;
  wire [15:0]lcd_0_data;
  wire lcd_0_de;
  wire lcd_0_hs;
  wire lcd_0_pclk;
  wire lcd_0_vs;

  System System_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .TP_Rst_tri_i(TP_Rst_tri_i_0),
        .TP_Rst_tri_o(TP_Rst_tri_o_0),
        .TP_Rst_tri_t(TP_Rst_tri_t_0),
        .ad7606_busy_i_0(ad7606_busy_i_0),
        .ad7606_convst_o_0(ad7606_convst_o_0),
        .ad7606_cs_n_o_0(ad7606_cs_n_o_0),
        .ad7606_db_i_0(ad7606_db_i_0),
        .ad7606_os_o_0(ad7606_os_o_0),
        .ad7606_rd_n_o_0(ad7606_rd_n_o_0),
        .ad7606_reset_o_0(ad7606_reset_o_0),
        .lcd_0_bl(lcd_0_bl),
        .lcd_0_data(lcd_0_data),
        .lcd_0_de(lcd_0_de),
        .lcd_0_hs(lcd_0_hs),
        .lcd_0_pclk(lcd_0_pclk),
        .lcd_0_vs(lcd_0_vs));
  IOBUF TP_Rst_tri_iobuf_0
       (.I(TP_Rst_tri_o_0),
        .IO(TP_Rst_tri_io[0]),
        .O(TP_Rst_tri_i_0),
        .T(TP_Rst_tri_t_0));
endmodule
