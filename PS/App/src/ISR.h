#ifndef AC820_LIB_ISR_H_
#define AC820_LIB_ISR_H_

#include "COMMON.h"

//������־
extern uint8_t Wave_Run;			//���βɼ���־
extern uint8_t Single_TriggerFlag;	//������־
extern uint8_t Cancel_Trigger;		//ȡ������

//�����������̵ı�־
extern uint8_t Flag_DrawWave;		//���Ʋ��Σ�10msһ��
extern uint8_t Flag_DrawGrid;		//��������20msһ��
extern uint8_t Flag_TouchScan;		//����ɨ�裬30msһ��
extern uint8_t Flag_Refresh_Val;	//ˢ�µ�ѹ��Ƶ����ֵ��500msһ��

//��־�жϴ���������ڽ��¼�֪ͨӦ�ó���������
extern volatile int RxDone;
extern volatile int Error;

void ScuTimer_IRQ_Handler(void *CallBackRef);
void AXI_DMARx_IRQHandler(void *Callback);
void PS_GPIO_IRQ_Handler(void *CallBackRef, uint32_t Bank, uint32_t Status);

#endif /* AC820_LIB_ISR_H_ */
