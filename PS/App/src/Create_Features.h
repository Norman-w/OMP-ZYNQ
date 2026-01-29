#ifndef _CREATE_FEATURES_H_
#define _CREATE_FEATURES_H_

#include "PageDesign.h"

//�����������������
Button Button_RUN = {
		{15,395,105,60},	//��������X1��Y1����ȡ��߶�
		LCD_BLACK,LCD_GREEN,//�����ڵ��ı���ɫ�ͱ�����ɫ
		32,{{"RUN"}}	//�����ı��������С���ı�����
};
Button Button_AUTO = {
		{15,315,105,60},
		LCD_BLACK,LCD_GREEN,
		32,{{"AUTO"}}
};
Button Button_CH_INC = {
		{715,60,70,60},
		LCD_WHITE,LCD_BLACK,
		32,{{'+'}}
};
Button Button_CH_DEC = {
		{715,175,70,60},
		LCD_WHITE,LCD_BLACK,
		32,{{'-'}}
};
Button Button_SA_INC = {
		{715,280,70,60},
		LCD_WHITE,LCD_BLACK,
		32,{{'+'}}
};
Button Button_SA_DEC = {
		{715,395,70,60},
		LCD_WHITE,LCD_BLACK,
		32,{{'-'}}
};

Button Button_Tri_Mode = {
		{15,160,105,65},
		LCD_WHITE,LCD_BLACK,
		24,{
				{"Auto"},
				{"Trigger"}
		}
};


Button Button_TriggerVal = {//��ǰ��ѹ����ֵ
		{15,240,105,60},
		LCD_WHITE,LCD_GRAY,
		24,{{"0.000V"}}
};

//���岨�λ���
Button Wave_Slider = {
		{450,10,240,40},
		LCD_PINK,LCD_BLACK,//�����ڵ��ı���ɫ�ͱ�����ɫ
		16,{{"  "}}	//�����ı��������С���ı�����
};

//���廬��ʵ��
Box_XY Slider = {
		450,10,40,40
};


//�����ı�����
Text Text_CHANNEL = {	//��ǰ����ͨ��
		{705,125,90,45},
		LCD_WHITE,LCD_BLACK,
		24
};

Text Text_SAMPLE = {	//��ǰ������
		{705,345,90,45},
		LCD_WHITE,LCD_BLACK,
		24
};

Text Text_Vmax = {		//��ǰ��ѹ�����ֵ
		{290,460,150,20},
		LCD_YELLOW,LCD_BLACK,
		16
};

Text Text_Vmin = {		//��ǰ��ѹ����Сֵ
		{125,460,150,20},
		LCD_YELLOW,LCD_BLACK,
		16
};

Text Text_Vpp = {		//��ǰ��ѹ�ķ��ֵ
		{455,460,150,20},
		LCD_YELLOW,LCD_BLACK,
		16
};

Text Text_Freq = {		//��ǰ���ε�Ƶ��
		{620,460,150,20},
		LCD_YELLOW,LCD_BLACK,
		16
};

Text Text_Point_V = {		//��ǰ����ѹֵ
		{145,20,150,20},
		LCD_CYAN,LCD_BLACK,
		16
};

Text Text_Point_T = {		//��ǰ���ʱ��
		{295,20,150,20},
		LCD_CYAN,LCD_BLACK,
		16
};

Text Text_Date = {		//RTCʱ��
		{705,5,90,20},
		LCD_YELLOW,LCD_BLACK,
		12
};

Text Text_Clock = {		//RTCʱ��
		{705,25,90,20},
		LCD_YELLOW,LCD_BLACK,
		12
};

Text Text_TouchXY = {		//��ǰ�������꣬����ʱʹ��
		{290,5,150,20},
		LCD_YELLOW,LCD_BLACK,
		16
};

//���岨�ν���Ĳ������ԣ�ʣ�µ�ʹ��Get_Waveform_Window_Parameters�����������
Wave_Page ADC_Wave = {
		{135,60,565,395},	//���δ�������X1��Y1����ȡ��߶�
		5,15				//��ѹ���̺�ADCλ��
};

#endif /* _CREATE_FEATURES_H_ */
