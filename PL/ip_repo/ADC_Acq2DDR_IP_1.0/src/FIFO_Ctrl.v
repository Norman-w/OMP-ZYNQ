
module FIFO_Ctrl(
    input Clk,
    input Rst_n,
    input [10:0]ADC_Sample_Rate,    //采样分频值，物理采样率为1000KHz
    input ADC_Conv_Done,
    output reg Acq_Valid           //采集有效标志
);
parameter NUMBER_SAMPLES = 1024;
reg Acq_Valid_r;    //采集有效标志//Debug
reg [10:0]Acq_Div_Cnt;    //采集分频计数器//Debug

//将采样率分频
always@(posedge Clk or negedge Rst_n)
begin
    if (!Rst_n)
        Acq_Div_Cnt <= 0;
    else if(Acq_Div_Cnt >= ADC_Sample_Rate)
        Acq_Div_Cnt <= 0;
    else if(ADC_Conv_Done)
        Acq_Div_Cnt <= Acq_Div_Cnt + 1;
    else
        Acq_Div_Cnt <= Acq_Div_Cnt;
end

//产生数据有效标志,直到采集数据到达目标值，再清除标识
always@(posedge Clk or negedge Rst_n)
begin
    if (!Rst_n)
        Acq_Valid <= 0;
    else if(Acq_Div_Cnt >= ADC_Sample_Rate)
        Acq_Valid <= 1;
    else
        Acq_Valid <= 0;
end

endmodule