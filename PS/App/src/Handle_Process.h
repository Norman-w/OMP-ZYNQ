#ifndef __HANDLE_PROCESS_H__
#define __HANDLE_PROCESS_H__

#include "COMMON.h"
#include "Touch.h"


extern uint16_t *P_ADC_Data;


//������������
void Read_Wave_Data();		//��DDR��ȡ��������
void Init_Homepage();		//��ʼ��������
void Refresh_Measure_Val();	//ˢ�²���ֵ
void Refresh_WaveWindow();	//ˢ�²��δ���
void Touch_Scan();			//����ɨ��
void STOP_Disable_Press();		//��STOP״̬�¶���ĳЩ����
void STOP_Ensable_Press();		//�����STOP״̬�±�����Ĳ���
void Trigger_Disable_Press();	//�ڵ��δ���״̬�¶���ĳЩ����
void Trigger_Enable_Press();	//����ڵ��δ���״̬�±�����Ĳ���
void Perform_STOP();		//ִ��STOP����

void Handle_Single_Trigger();
void Handle_Round_Done();

#endif /* HANDLE_PROCESS_H */
