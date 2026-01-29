

/***************************** Include Files *******************************/
#include "ADC_Acq2DDR_IP.h"

/************************** Function Definitions ***************************/
void Set_ADC_Mode(uint32_t Channel,uint32_t Sample_Rate,
		uint32_t Trigger_Val,uint32_t Trigger_Mode)
{
	uint32_t Sample_Div;
	Sample_Div = 200/Sample_Rate;//采样分频=原始采样率200K/设定采样率
	SET_ADC_REG(REG_ADC_CONTROL, Channel | (Sample_Div << 3)
			| (Trigger_Val << 14) | (Trigger_Mode << 30));
}

uint32_t Get_ADC_Freq()
{
	uint32_t ADC_Freq;
	ADC_Freq = GET_ADC_REG(REG_ADC_FREQ);
	return ADC_Freq;
}

float Get_ADC_Vmin()
{
	uint32_t Vmin_Val;
	int16_t Vmin_Tmp;
	float Vmin;
	Vmin_Val = (GET_ADC_REG(REG_ADC_MINMAX) & 0xFFFF);
	Vmin_Tmp = Vmin_Val;	//无符号转有符号
	Vmin = Vmin_Tmp/32768.0*5.0;


	return Vmin;
}

float Get_ADC_Vmax()
{
	uint32_t Vmax_Val;
	int16_t Vmax_Tmp;
	float Vmax;
	Vmax_Val = (GET_ADC_REG(REG_ADC_MINMAX) >> 16);
	Vmax_Tmp = Vmax_Val;	//无符号转有符号
	Vmax = Vmax_Tmp/32768.0*5.0;

	return Vmax;
}

float Get_ADC_Vmid()
{
	uint32_t Vmid_Val;
	int16_t Vmid_Tmp;
	float Vmid;
	Vmid_Val = (GET_ADC_REG(REG_ADC_STATE) & 0xFFFF);
	Vmid_Tmp = Vmid_Val;	//无符号转有符号
	Vmid = Vmid_Tmp/32768.0*5.0;

	return Vmid;
}

uint16_t Get_ADC_MidVal()
{
	uint16_t ADC_MidVal;
	ADC_MidVal = GET_ADC_REG(REG_ADC_STATE) & 0xFFFF;
	return ADC_MidVal;
}
