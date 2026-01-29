`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/29 18:22:24
// Design Name: 
// Module Name: ADC_Measure_Freq
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 测量ADC驱动测出的电压频率
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ADC_Measure_Freq(
    input Clk,
    input Rst_n,
    input signed [15:0]Trig_Val,       //触发值
    input signed [15:0]ADC_Data,       //ADC数据
    input ADC_Conv_Done,        //ADC单次采集完成信号
    output reg [31:0]Freq_Val  //频率测量值
);
parameter TIME_CNT_VAL = 99999999; //设定计数值来控制采样时间
reg signed [15:0]ADC_Data_Pre;   //保存上一个采样值
reg ADC_Conv_Done_r;      //单次采集完成信号打拍
reg [31:0]Time_Cnt;       //时间计数器
reg [31:0]Cycle_Cnt_Pre;  //保存上一次周期值
reg signed [15:0]Trig_Val_r;     //存储触发值，防止中途改变
reg [31:0]Cycle_Cnt; //周期计数器
reg [31:0]Freq_Add;   //单位时间内频率累加

//计数1秒
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Time_Cnt <= 0;
    else if(Time_Cnt >= TIME_CNT_VAL)
		Time_Cnt <= 0;
    else
        Time_Cnt <= Time_Cnt + 1;
end

//1秒内累加触发计数，以此测出频率
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Freq_Add <= 0;
	else if(Time_Cnt >= TIME_CNT_VAL)
		Freq_Add <= 0;
	else if((ADC_Data_Pre <= Trig_Val_r) && (ADC_Data >= Trig_Val_r) && (ADC_Data_Pre < ADC_Data) && ADC_Conv_Done) begin
        if(Cycle_Cnt <= Cycle_Cnt_Pre[31:1])//当前周期计数小于等于上一个计数周期的一半，则此次触发异常，触发计数无效
            Freq_Add <= Freq_Add;
        else 
            Freq_Add <= Freq_Add + 1;
    end
	else
        Freq_Add <= Freq_Add;
end

//记录一次触发周期的时间
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Cycle_Cnt <= 0;
    else if((ADC_Data_Pre <= Trig_Val_r) && (ADC_Data >= Trig_Val_r) && (ADC_Data_Pre < ADC_Data) && ADC_Conv_Done)
		Cycle_Cnt <= 0;
    else
        Cycle_Cnt <= Cycle_Cnt + 1;
end

//保存上一次触发周期的时间
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Cycle_Cnt_Pre <= 0;
    else if((ADC_Data_Pre <= Trig_Val_r) && (ADC_Data >= Trig_Val_r) && (ADC_Data_Pre < ADC_Data) && ADC_Conv_Done)
		Cycle_Cnt_Pre <= Cycle_Cnt;
    else
        Cycle_Cnt_Pre <= Cycle_Cnt_Pre;
end

//保存触发设定值，防止中途被修改，每次测完一秒后才允许修改
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Trig_Val_r <= 0;
    else if(Time_Cnt >= TIME_CNT_VAL)
		Trig_Val_r <= Trig_Val;
    else
        Trig_Val_r <= Trig_Val_r;
end

//保存上一次ADC测量值
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n) begin
        ADC_Data_Pre <= 0;
    end
    else if(ADC_Conv_Done) begin
        ADC_Data_Pre <= ADC_Data;
    end
    else begin
        ADC_Data_Pre <= ADC_Data_Pre;
    end
end

//ADC单次转换完成信号打拍
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        ADC_Conv_Done_r <= 0;
    else
        ADC_Conv_Done_r <= ADC_Conv_Done;
end

//计数1秒后输出测量频率
always@(posedge Clk or negedge Rst_n)
begin
    if(!Rst_n)
        Freq_Val <= 0;
	else if(Time_Cnt >= TIME_CNT_VAL)
	    Freq_Val <= Freq_Add;
    else
        Freq_Val <= Freq_Val;
end

endmodule
