`timescale 1ns / 1ps

module Trigger_Detect(
    input Clk100M,
    input Clk125M,
    input Rst_n,
    input signed [15:0]ADC_Data,
    input Acq_Valid,
    input Start_Round_Acq,
    input signed [15:0]Acq_Trigger_Value,
    output t_valid,
    output wire t_last
);
parameter ONE_ROUND_LENGTH = 1024;	//一轮采集的长度，以数据的个数为单位

localparam 
    IDLE = 2'b01,//空闲态
    WAIT = 2'b10;//等待触发态
    
reg Data_Valid;	//数据有效信号，在数据有效期间一直为高，传输完毕后变为低
reg Trigger_Done;//触发完成信号
reg [15:0]Cnt;	//传输计数

reg signed [15:0]ADC_Average_Val_Pre;         //存储上次ADC数据
reg [1:0]State;
reg Start_Signal;//启动信号

reg signed [15:0]ADC_Data_Reg[7:0];//寄存器
reg signed [18:0]ADC_Data_Reg_Add; //累加器
wire signed [15:0]ADC_Average_Val; //平均值

always@(posedge Clk100M)
	if (Acq_Valid) begin
		ADC_Data_Reg[7] <= ADC_Data;
		ADC_Data_Reg[6] <= ADC_Data_Reg[7];
		ADC_Data_Reg[5] <= ADC_Data_Reg[6];
		ADC_Data_Reg[4] <= ADC_Data_Reg[5];
		ADC_Data_Reg[3] <= ADC_Data_Reg[4];
		ADC_Data_Reg[2] <= ADC_Data_Reg[3];
		ADC_Data_Reg[1] <= ADC_Data_Reg[2];
		ADC_Data_Reg[0] <= ADC_Data_Reg[1];
	end

always@(posedge Clk100M)
begin
    if(Acq_Valid)
	ADC_Data_Reg_Add <= ADC_Data_Reg[7] + ADC_Data_Reg[6] +
						ADC_Data_Reg[5] + ADC_Data_Reg[4] +
						ADC_Data_Reg[3] + ADC_Data_Reg[2] +
						ADC_Data_Reg[1] + ADC_Data_Reg[0];
end
assign ADC_Average_Val = ADC_Data_Reg_Add[18:3];

//保存上次ADC数据
always@(posedge Clk100M or negedge Rst_n)
begin
    if (!Rst_n)
        ADC_Average_Val_Pre <= 0;
    else if(Acq_Valid)
        ADC_Average_Val_Pre <= ADC_Average_Val;
    else
        ADC_Average_Val_Pre <= ADC_Average_Val_Pre;
end


//跨时钟域的启动信号，125M -> 100M : Start_Round_Acq -> Start_Signal
always@(posedge Clk125M or negedge Rst_n)
begin
    if(!Rst_n)
        Start_Signal <= 0;
    else if(Start_Round_Acq)
        Start_Signal <= 1;
    else if(State == WAIT)
        Start_Signal <= 0;
    else
        Start_Signal <= Start_Signal;
end

//状态机
always@(posedge Clk100M or negedge Rst_n)
    if(!Rst_n)begin
        Trigger_Done <= 0;
        State <= IDLE;
    end
    else begin
        case(State)
        IDLE: begin
            Trigger_Done <= 0;
            if(Start_Signal)
                State <= WAIT;
            else
                State <= IDLE;
        end
        WAIT: begin
            if((ADC_Average_Val_Pre <= Acq_Trigger_Value)&&(ADC_Average_Val >= Acq_Trigger_Value)) begin
                Trigger_Done <= 1;
                State <= IDLE;
            end else
                Trigger_Done <= 0;
        end
        default:State <= IDLE;
        endcase
    end

//传输计数器
always@(posedge Clk100M or negedge Rst_n)
begin
    if (!Rst_n)
        Cnt <= 0;
	else if(Data_Valid)
        begin
            if(Cnt >= ONE_ROUND_LENGTH)
                Cnt <= 0;
            else if(Acq_Valid)
                Cnt <= Cnt + 1;
            else
                Cnt <= Cnt;
        end
    else
        Cnt <= 0;
end

//Data_Valid信号
always@(posedge Clk100M or negedge Rst_n)
begin
    if (!Rst_n)
        Data_Valid <= 0;
	else if(Trigger_Done)
		Data_Valid <= 1;
	else if(Cnt >= ONE_ROUND_LENGTH)
		Data_Valid <= 0;
end

assign t_last = (Cnt == ONE_ROUND_LENGTH - 1) && t_valid;
assign t_valid = Data_Valid && Acq_Valid;

endmodule
