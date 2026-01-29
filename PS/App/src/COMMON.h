#ifndef ACZ702_LIB_COMMON_H_
#define ACZ702_LIB_COMMON_H_


//ϵͳͷ�ļ�
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>


//Xilinxͷ�ļ�
#include "xil_types.h"
#include "sleep.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xscutimer.h"
#include "ff.h"


//AC820ͷ�ļ�
#include "ISR.h"
#include "SCU_GIC.h"
#include "SCU_TIMER.h"

#include "AXI_DMA.h"
#include "PS_GPIO.h"
#include "PS_IIC.h"
#include "ADC_Acq2DDR_IP.h"
#include "PageDesign.h"
#include "Touch.h"
#include "BMP_WR.h"

//�û�ͷ�ļ�
#include "Handle_Process.h"



//�û��궨��
#define	CPU_CLK_HZ	XPAR_PS7_CORTEXA9_0_CPU_CLK_FREQ_HZ	//CPUʱ��Ƶ��(��λHz)
#define INPUT		1
#define OUTPUT		0
#define	REG8		8
#define	REG16		16
#define PS_KEY 47       //PS_KEYΪMIO47����Ӧ��GPIO���Ϊ47


//�û���������

#endif /* AC820_LIB_COMMON_H_ */
