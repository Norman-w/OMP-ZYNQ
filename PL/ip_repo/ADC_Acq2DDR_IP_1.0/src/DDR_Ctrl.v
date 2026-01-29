`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/29 18:22:24
// Design Name: 
// Module Name: DDR_Ctrl
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


module DDR_Ctrl(
    input Clk,
    input Rst_n,
    input [15:0]ADC_Data,
    input ADC_Conv_Done,
    input Start_Round_Acq,
    input [15:0]Acq_Trigger_Value,
    output wire DDR_WR_Start
);
localparam 
    IDLE = 2'b01,//空闲态
    WAIT = 2'b10;//等待触发态
    
reg Data_Valid;

reg [15:0]ADC_Average_Val_Pre;         //存储上次ADC数据
reg [1:0]State;

reg [15:0]ADC_Data_Reg[7:0];//寄存值
reg [18:0]ADC_Data_Reg_Add; //累加值
wire [15:0]ADC_Average_Val; //平均值

always@(posedge Clk)
	if (ADC_Conv_Done) begin
		ADC_Data_Reg[7] <= ADC_Data;
		ADC_Data_Reg[6] <= ADC_Data_Reg[7];
		ADC_Data_Reg[5] <= ADC_Data_Reg[6];
		ADC_Data_Reg[4] <= ADC_Data_Reg[5];
		ADC_Data_Reg[3] <= ADC_Data_Reg[4];
		ADC_Data_Reg[2] <= ADC_Data_Reg[3];
		ADC_Data_Reg[1] <= ADC_Data_Reg[2];
		ADC_Data_Reg[0] <= ADC_Data_Reg[1];
	end

always@(posedge Clk)
begin
    if(ADC_Conv_Done)
	ADC_Data_Reg_Add <= ADC_Data_Reg[7] + ADC_Data_Reg[6] +
						ADC_Data_Reg[5] + ADC_Data_Reg[4] +
						ADC_Data_Reg[3] + ADC_Data_Reg[2] +
						ADC_Data_Reg[1] + ADC_Data_Reg[0];
end
assign ADC_Average_Val = ADC_Data_Reg_Add[18:3];

//保存上次ADC数据
always@(posedge Clk or negedge Rst_n)
begin
    if (!Rst_n)
        ADC_Average_Val_Pre <= 0;
    else if(ADC_Conv_Done)
        ADC_Average_Val_Pre <= ADC_Average_Val;
    else
        ADC_Average_Val_Pre <= ADC_Average_Val_Pre;
end

//状态机
always@(posedge Clk or negedge Rst_n)
    if(!Rst_n)begin
        Data_Valid <= 0;
        State <= IDLE;
    end
    else begin
        case(State)
        IDLE: begin
            Data_Valid <= 0;
            if(Start_Round_Acq)
                State <= WAIT;
            else
                State <= IDLE;
        end
        WAIT: begin
            if((ADC_Average_Val_Pre <= Acq_Trigger_Value)&&(ADC_Average_Val >= Acq_Trigger_Value)) begin
                Data_Valid <= 1;
                State <= IDLE;
            end else
                Data_Valid <= 0;
        end
        default:State <= IDLE;
        endcase
    end

assign DDR_WR_Start = Data_Valid;

endmodule
