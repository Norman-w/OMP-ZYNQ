`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/27 16:48:31
// Design Name: 
// Module Name: AD7606_Driver
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


module AD7606_Driver(
	Clk,
	Reset_n,
	Go,
	Speed_Set,
	Conv_Done,
	Channel_Set,
	ad7606_cs_n_o,   
	ad7606_rd_n_o,   
	ad7606_busy_i,   
	ad7606_db_i,     
	ad7606_os_o,     
	ad7606_reset_o,  
	ad7606_convst_o, 
	
	data_flag,
	data_mult_ch,
	ch_dat_valid
	
);

	input wire Clk;        //时钟，为了让采样速率准确，要求为100MHz
	input wire Reset_n;    //复位，低电平复位
	input wire Go;         //采样使能信号，为高电平就使能采样，低电平则在已经开始的一轮采样结束后，停止下一次采样。
	input wire [25:0]Speed_Set; //采样速率控制端口，Speed_Set = 100000000/speed - 1
	input wire [2:0]Channel_Set;//采样通道设置，采集从0通道到设定通道Channel_Set的值

	output reg Conv_Done;          //一次采样完成标志信号，单时钟周期脉冲信号。每次8个通道结果都输出后，产生一个高脉冲信号。

	output wire ad7606_cs_n_o;     //AD 片选信号 可以从AD7606中读取转换结果时，需要使该信号为低电平
	output reg ad7606_rd_n_o;      //AD 读请求信号
	input wire ad7606_busy_i;      //AD 忙碌信号
	input wire [15:0]ad7606_db_i;  //AD 采集的数据
	output wire [2:0]ad7606_os_o;  //AD OS设置
	output reg ad7606_reset_o;     //AD 复位信号
	output reg ad7606_convst_o;    //AD 转换开始信号
		
	/***
	多通道数据输出端口，该通道16位，在不同的时刻，输出不同通道的转换结果，使用时，与data_flag信号配合，
    data_flag 的哪一位出现高脉冲，则代表当前data_mult_ch的值为该通道的转换结果。
    该端口设计的目的是用于往FIFO、RAM 等存储器中存储结果时使用。
	***/
	output reg [15:0]data_mult_ch;         //多通道数据输出端口
	output reg [7:0]data_flag;             //8个通道的转换结果有效标志信号
	
	output reg ch_dat_valid;

	assign ad7606_os_o = 0;                //不使用过采样
	assign ad7606_cs_n_o = ad7606_rd_n_o;  //将读请求信号连接到片选信号
	reg [7:0]state;                        //线性序列机计数
	reg [1:0]ad7606_busy_r;                //记录busy信号的前后两次状态
	
	//更新ad7606_busy_r，高位为上次ad7606_busy_i的状态，低位为本次状态
	always@(posedge Clk)
		ad7606_busy_r <= {ad7606_busy_r[0],ad7606_busy_i};
	
	//由线性序列机的计数值得到当前有效通道标志
	always@(posedge Clk or negedge Reset_n)
	if(!Reset_n)
		data_flag <= 0;
	else begin
		data_flag[0] <= state == 30;
		data_flag[1] <= state == 40;
		data_flag[2] <= state == 50;
		data_flag[3] <= state == 60;
		data_flag[4] <= state == 70;
		data_flag[5] <= state == 80;
		data_flag[6] <= state == 90;
		data_flag[7] <= state == 100;	
	end
	
	//在每个通道数据采集完成后，将新的采集值更新
	always@(posedge Clk or negedge Reset_n)
	if(!Reset_n)
		data_mult_ch <= 0;
	else begin
		data_mult_ch <= 
			 (  (state == 30)
			 || (state == 40)
			 || (state == 50)
			 || (state == 60)
			 || (state == 70)
			 || (state == 80)
			 || (state == 90)
			 || (state == 100)
			)? ad7606_db_i:data_mult_ch;	
	end

	reg [25:0]cnt;     //创建计数变量cnt
	
	//计数值每周期加一，当计数到到Speed_Set时将计数值清零
	always@(posedge Clk or negedge Reset_n)
	if(!Reset_n)
		cnt <= 0;
	else if(cnt == Speed_Set)
		cnt <= 0;
	else
		cnt <= cnt + 1'b1;
		
	wire trig = cnt == Speed_Set;  //当cnt=Speed_Set时，trig=1，否则为0
	
	//使用线性序列机模拟时序，每次计数到Speed_Set时读取数据
	always@(posedge Clk or negedge Reset_n)
	if(!Reset_n)begin
		state <= 0;
		ad7606_convst_o <= 1;
		Conv_Done <= 0;
		ad7606_rd_n_o <= 1;
		ad7606_reset_o <= 0;
	end
	else begin
		case(state)
			0:
				if(Go && trig)begin
					state <= 10;
					ad7606_convst_o <= 0;
					ad7606_rd_n_o <= 1;
					Conv_Done <= 0;
					ad7606_reset_o <= 0;
				end
				else begin
					state <= 0;
					ad7606_convst_o <= 1;
					ad7606_rd_n_o <= 1;
					ad7606_reset_o <= 0;
				end
					
			1: state <= state + 1'b1;
			2: state <= state + 1'b1;
			3: state <= state + 1'b1;
			4: state <= state + 1'b1;
			5: state <= state + 1'b1;
			6: state <= state + 1'b1;
			7: state <= state + 1'b1;
			8: state <= state + 1'b1;
			9: state <= state + 1'b1;
			10: state <= state + 1'b1;
			11: begin state <= state + 1'b1;ad7606_convst_o <= 1;end  //convst上升沿，启动采样转换
			12: begin state <= state + 1'b1;end
			13: state <= state + 1'b1;
			14: state <= state + 1'b1;
			15: state <= state + 1'b1;
			16: state <= state + 1'b1;
			17: state <= state + 1'b1;
			18: state <= state + 1'b1;
			19: if(ad7606_busy_r[1])state <= state;  //若ad7606_busy_i上次为高说明转换未完成，则循环本次状态直到转换完成
			    else begin state <= state + 3'd4;ad7606_rd_n_o <= 0;end  //若上次ad7606_busy_i为低，说明已转换完成，更新采样结果并跳到14
			20: state <= state + 1'b1;
			21: state <= state + 1'b1;
			22: state <= state + 1'b1;
			23: state <= state + 1'b1;
			24: state <= state + 1'b1;
			25: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end
			26: state <= state + 1'b1;
			27: state <= state + 1'b1;
			28: state <= state + 1'b1;
			29: begin ad7606_rd_n_o <= 1; state <= state + 1'b1;end  // ad7606_rd_n_o上升沿，外界可读取更新数据
			30: state <= state + 1'b1;
			31: state <= state + 1'b1;
			32: state <= state + 1'b1;
			33: state <= state + 1'b1;
			34: state <= state + 1'b1;
			35: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			36: begin state <= state + 1'b1;end  
			37: begin state <= state + 1'b1;end
			38: begin state <= state + 1'b1;end
			39: begin ad7606_rd_n_o <= 1; state <= state + 1'b1;end  //ad7606_rd_n_o上升沿，外界可读取更新数据
			40: state <= state + 1'b1;
			41: state <= state + 1'b1;
			42: state <= state + 1'b1;
			43: state <= state + 1'b1;
			44: state <= state + 1'b1;
			45: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			46: state <= state + 1'b1;
			47: begin state <= state + 1'b1;end
			48: begin state <= state + 1'b1;end
			49: begin ad7606_rd_n_o <= 1;  state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			50: state <= state + 1'b1;
			51: state <= state + 1'b1;
			52: state <= state + 1'b1;
			53: state <= state + 1'b1;
			54: state <= state + 1'b1;
			55: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			56: state <= state + 1'b1;
			57: begin state <= state + 1'b1;end
			58: begin state <= state + 1'b1;end
			59: begin ad7606_rd_n_o <= 1;  state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			60: state <= state + 1'b1;
			61: state <= state + 1'b1;
			62: state <= state + 1'b1;
			63: state <= state + 1'b1;
			64: state <= state + 1'b1;
			65: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			66: state <= state + 1'b1;
			67: begin state <= state + 1'b1;end
			68: begin state <= state + 1'b1;end
			69: begin ad7606_rd_n_o <= 1;  state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			70: state <= state + 1'b1;
			71: state <= state + 1'b1;
			72: state <= state + 1'b1;
			73: state <= state + 1'b1;
			74: state <= state + 1'b1;
			75: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			76: state <= state + 1'b1;
			77: begin state <= state + 1'b1;end
			78: begin state <= state + 1'b1;end
			79: begin ad7606_rd_n_o <= 1;  state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			80: state <= state + 1'b1;
			81: state <= state + 1'b1;
			82: state <= state + 1'b1;
			83: state <= state + 1'b1;
			84: state <= state + 1'b1;
			85: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			86: state <= state + 1'b1;
			87: begin state <= state + 1'b1;end
			88: begin state <= state + 1'b1;end
			89: begin ad7606_rd_n_o <= 1; state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			90: state <= state + 1'b1;
			91: state <= state + 1'b1;
			92: state <= state + 1'b1;
			93: state <= state + 1'b1;
			94: state <= state + 1'b1;
			95: begin ad7606_rd_n_o <= 0; state <= state + 1'b1;end  //ad7606_rd_n_o下降沿，更新采样结果
			96: state <= state + 1'b1;
			97: begin state <= state + 1'b1;end
			98: begin state <= state + 1'b1;end
			99: begin ad7606_rd_n_o <= 1;  state <= state + 1'b1;end //ad7606_rd_n_o上升沿，外界可读取更新数据
			100: begin state <= state + 1'b1; Conv_Done <= 1; end    //转换完成信号Conv_Done变为高电平
			101: begin state <= state + 1'b1; ad7606_reset_o <= 1; Conv_Done <= 0; end//复位ad7606内部各个功能单元的工作状态,Conv_Done变为低电平
			102: begin state <= 0;ad7606_reset_o <= 0; end    //ad7606_reset_o变高，state清零
			default:
				begin
					state <= 0;
					ad7606_convst_o <= 1;
					Conv_Done <= 0;
					ad7606_rd_n_o <= 1;
					ad7606_reset_o <= 0;
				end
		endcase
	end
	
	//由线性序列机的计数值得到stream传输相关信号
	always@(posedge Clk or negedge Reset_n)
	if(!Reset_n)
		ch_dat_valid <= 0;
	else if(state==(Channel_Set+3)*10)
        ch_dat_valid <= 1;
	else
        ch_dat_valid <= 0;
        
    

endmodule


