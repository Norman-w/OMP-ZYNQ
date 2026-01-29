`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/29 18:22:24
// Design Name: 
// Module Name: ADC_Special_Val
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ADC_Special_Val(
	input Clk,
	input Rst_n,
	input [15:0]ADC_IN,
	input Data_Valid,
	output reg [15:0]VMax,
	output reg [15:0]VMin,
	output [15:0]VMid
);
    parameter UPDATERATE = 99999999;//计时一秒
    wire [16:0]VMid_r;
    reg [31:0]counter;
   	reg [15:0]VMax_r;
	reg [15:0]VMin_r;
	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		counter <= 0;
	else if(counter >= UPDATERATE)
		counter <= 0;
	else
		counter <= counter + 1'b1;
	always@(posedge Clk)
	if(counter >= UPDATERATE)
		VMax_r <= -16'd32767;//-32767
	else if((ADC_IN[15] < VMax_r[15]) && Data_Valid)//IN为正，r为负，IN>r
        VMax_r <= ADC_IN;
    else if((ADC_IN[15] == VMax_r[15]) && (ADC_IN > VMax_r) && Data_Valid)
        VMax_r <= ADC_IN;
	else
		VMax_r <= VMax_r;

	always@(posedge Clk)
	if(counter >= UPDATERATE)
		VMin_r <= 16'd32767;
	else if((ADC_IN[15] > VMin_r[15]) && Data_Valid)//IN为负，r为正，IN<r
        VMin_r <= ADC_IN;
    else if((ADC_IN[15] == VMin_r[15]) && (ADC_IN < VMin_r) && Data_Valid)
        VMin_r <= ADC_IN;
	else
		VMin_r <= VMin_r;

	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)begin 
		VMin <= 0;
		VMax <= 0;
	end
	else begin
		if(counter >= UPDATERATE)begin
			VMin <= VMin_r;
			VMax <= VMax_r;
		end
		else begin
			VMin <= VMin;
			VMax <= VMax;		
		end
	end
	
	assign VMid_r = $signed(VMax) + $signed(VMin);
	assign VMid = VMid_r[16:1];
endmodule