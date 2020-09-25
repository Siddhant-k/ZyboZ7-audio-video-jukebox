// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Wed Nov 27 12:45:32 2019
// Host        : DESKTOP-4H8L9CM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {C:/Users/siddh/Desktop/EE478_UBuffalo/Lab5 - Final
//               Project/lab5.srcs/sources_1/ip/pxl_clk_gen/pxl_clk_gen_stub.v}
// Design      : pxl_clk_gen
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module pxl_clk_gen(clk_out1, clk_out2, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_out2,reset,locked,clk_in1" */;
  output clk_out1;
  output clk_out2;
  input reset;
  output locked;
  input clk_in1;
endmodule
