/**
  *****************************************************************************
  * 					����ACM7606����һ������ʾ����
  *****************************************************************************
  *
  * @File   : main.c
  * @By     : С÷���Ŷ�
  * @Version: V1.2
  * @Date   : 2022 / 06 / 28
  * @Shop	: https://xiaomeige.taobao.com/
  * @Forum  : http://www.corecourse.cn/
  *****************************************************************************
**/


#include "COMMON.h"
#include "xil_printf.h"


void Handle_Events(void);


//������
int main(void)
{
	xil_printf("Hello Norman\n\r");
	Init_Homepage();//��ʼ����ҳ�Ϳ�����

	//ѭ�������¼�
	while(1) {
		Handle_Events();
	}
	return 0;
}

void Handle_Events(void)
{
	//��������˵��δ����������ɹ���STOP��ȡ��������ָ�ԭ״
	if(Single_TriggerFlag && (ADC_ROUND_DONE || Cancel_Trigger)) {
		Single_TriggerFlag = 0;	//���־
		Handle_Single_Trigger();//�������δ����¼�
	}
	//ÿ�ִ��������ˢ��DCache��������һ�ִ���
	if(ADC_ROUND_DONE && Wave_Run && (!Single_TriggerFlag)) {
		Handle_Round_Done();
	}
	//��ʱˢ�²��δ��ڣ�10msһ��
	if(Flag_DrawWave) {
		Flag_DrawWave = 0;
		Refresh_WaveWindow();	//ˢ�²��δ���
	}
	//��ʱ��ⴥ����30msһ��
	if(Flag_TouchScan) {
		Flag_TouchScan = 0;
		Touch_Scan();					//����ɨ��
	}
	//��ʱˢ���񱳾���20msһ��
	if(Flag_DrawGrid) {
		Flag_DrawGrid = 0;
		Draw_Grid_Background(ADC_Wave);	//�������񱳾�
	}
	//��ʱˢ����ֵ��500msһ��
	if(Flag_Refresh_Val && Wave_Run) {
		Flag_Refresh_Val = 0;
		Refresh_Measure_Val();			//ˢ�²���ֵ
	}
}
