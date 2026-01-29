
`timescale 1 ns / 1 ps

	module ADC_Acq2DDR_IP_v1_0 #
	(
		// Users to add parameters here
        parameter ONE_ROUND_LENGTH = 1024,
        parameter ADC_CLK_FREQ = 100000000,//ADC输入时钟频率
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        input  Clk_100M,
        output ad7606_cs_n_o,       //AD 片选信号 可以从AD7606中读取转换结果时，需要使该信号为低电平
        output ad7606_rd_n_o,       //AD 读请求信号
        input ad7606_busy_i,        //AD 忙碌信号
        input [15:0]ad7606_db_i,    //AD 采集的数据
        output [2:0]ad7606_os_o,    //AD OS设置
        output ad7606_reset_o,      //AD 复位信号
        output ad7606_convst_o,     //AD 转换开始信号
        output Acq_Valid,           //采集有效标志
	    //m_axis信号
	    output wire [15:0]m_axis_tdata,
	    output wire [1:0]m_axis_tkeep,
	    output wire m_axis_tlast,
	    input wire m_axis_tready,
	    output wire m_axis_tvalid,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	
	//0号寄存器相关
	wire Start_Round_Acq;//启动一轮采集
    wire [2:0]ADC_Channel;//通道设置
    wire [10:0]ADC_Sample_Rate;
    wire [15:0]ADC_Trigger_Value;
    wire [1:0]ADC_Trigger_Mode;
    //1号寄存器相关
    wire  [15:0]ADC_Max_Val;
    wire  [15:0]ADC_Min_Val;
    //2号寄存器相关
    wire  [15:0]ADC_Mid_Val;
    wire  Acq_Trigger_State;
    reg  Acq_Round_Done;
    //3号寄存器相关
    wire  [31:0]RegRD_ADC_Freq;
    
    //ADC驱动相关信号
	wire [15:0]ADC_Data;   //ADC数据
    wire ADC_Conv_Done;     //单次采集完成
    wire [15:0]Acq_Trigger_Value;//采集触发值

    
// Instantiation of Axi Bus Interface S00_AXI
	ADC_Acq2DDR_IP_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) ADC_Acq2DDR_IP_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
        .ADC_Channel(ADC_Channel),
		.ADC_Sample_Rate(ADC_Sample_Rate),
		.ADC_Trigger_Value(ADC_Trigger_Value),
		.ADC_Trigger_Mode(ADC_Trigger_Mode),
        .ADC_Max_Val(ADC_Max_Val),
        .ADC_Min_Val(ADC_Min_Val),
        .ADC_Mid_Val(ADC_Mid_Val),
        .Acq_Trigger_State(Acq_Trigger_State),
        .Acq_Round_Done(Acq_Round_Done),
        .RegRD_ADC_Freq(RegRD_ADC_Freq),
        .Start_Round_Acq(Start_Round_Acq)
	);

	// Add user logic here
	assign Acq_Trigger_Value = ADC_Trigger_Mode[0]?ADC_Trigger_Value:ADC_Mid_Val;//如果设定模式为x0则自动触发
	assign m_axis_tkeep = 2'd3;
	assign m_axis_tdata = ADC_Data;
	//assign m_axis_tlast = m_axis_tvalid;
	
	
//	ADC128S102 ADC128S102(
//        .Clk(Clk_100M),
//        .Rst_n(s00_axi_aresetn),
//        .Channel(ADC_Channel),
//        .Data(ADC_Data),
//        .En_Conv(1),
//        .Conv_Done(ADC_Conv_Done),
//        .DIV_PARAM(2'd2),//固定分频为4/2=2
//        .ADC_SCLK(ADC_SCLK),
//        .ADC_DOUT(ADC_DOUT),
//        .ADC_DIN(ADC_DIN),
//        .ADC_CS_N(ADC_CS_N)
//    );
    
        AD7606_Driver AD7606_Driver(
       .Clk(Clk_100M),
       .Reset_n(s00_axi_aresetn),
       .Go(1),
       .Speed_Set(26'd499),//200K采样率
       .Channel_Set(ADC_Channel),
       .ad7606_cs_n_o(ad7606_cs_n_o),
       .ad7606_rd_n_o(ad7606_rd_n_o),
       .ad7606_busy_i(ad7606_busy_i),
       .ad7606_db_i(ad7606_db_i),
       .ad7606_os_o(ad7606_os_o),
       .ad7606_reset_o(ad7606_reset_o),
       .ad7606_convst_o(ad7606_convst_o),
       .data_mult_ch(ADC_Data),
       .ch_dat_valid(ADC_Conv_Done)
    );

    ADC_Measure_Freq # (
        .TIME_CNT_VAL(ADC_CLK_FREQ - 1)
    ) ADC_Measure_Freq (
        .Clk(Clk_100M),
        .Rst_n(s00_axi_aresetn),
        .Trig_Val(ADC_Mid_Val),         //触发值连接到测量电压的中值
        .ADC_Data(ADC_Data),            //ADC数据
        .ADC_Conv_Done(Acq_Valid),  //ADC单次采集完成信号
        .Freq_Val(RegRD_ADC_Freq)      //频率测量值
    );
    
    ADC_Special_Val # (
        .UPDATERATE(ADC_CLK_FREQ - 1)
    ) ADC_Special_Val (
        .Clk(Clk_100M),
        .Rst_n(s00_axi_aresetn),
        .ADC_IN(ADC_Data),
        .Data_Valid(ADC_Conv_Done),
        .VMax(ADC_Max_Val),
        .VMin(ADC_Min_Val),
        .VMid(ADC_Mid_Val)
    );
    
    FIFO_Ctrl FIFO_Ctrl(
        .Clk(Clk_100M),
        .Rst_n(s00_axi_aresetn),
        .ADC_Sample_Rate(ADC_Sample_Rate),//采样分频值，物理采样率为200KHz
        .ADC_Conv_Done(ADC_Conv_Done),             
        .Acq_Valid(Acq_Valid)     //采集有效标志//Debug     
    );
    
    Trigger_Detect # (
        .ONE_ROUND_LENGTH(ONE_ROUND_LENGTH)
    ) Trigger_Detect (
        .Clk100M(Clk_100M),
        .Clk125M(s00_axi_aclk),
        .Rst_n(s00_axi_aresetn),
        .ADC_Data(ADC_Data),
        .Acq_Valid(Acq_Valid),
        .Start_Round_Acq(Start_Round_Acq),
        .Acq_Trigger_Value(Acq_Trigger_Value),
        .t_valid(m_axis_tvalid),
        .t_last(m_axis_tlast)
);
	// User logic ends

	endmodule
