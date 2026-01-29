#include "Handle_Process.h"
#include "Create_Features.h"
#include "logo.h"

//����������ݱ���
char str[30];	//�����ַ���
uint16_t *P_ADC_Data = (uint16_t *)ADC_DATA_BASE;//����һ��ָ��ָ��ADC��������
uint8_t Wave_Run = 1;		//���βɼ���־
uint8_t Sample_Set = 4;		//�����ʵ�λ��Ĭ��Ϊ20K��λ,0~7��8��
uint8_t Sample_Set_Last = 0;//��¼��һ�β����ʵ�λ
uint8_t Trigger_Mode = 0;	//0��ʾ�Զ�������1��ʾ�ֶ�������2��ʾ���δ���
int16_t Trigger_Value = 0;	//��������ֵ
int16_t Trigger_Value_Last = 0;//��һ�β�������ֵ
//���������ã�KHz��AD7606���Ϊ200KHz
uint32_t Sample_Rate[8] = {1,2,5,10,20,50,100,200};
uint8_t CH_Set = 0;	//����ͨ������
uint16_t Measure_Point,Measure_Point_Last;
uint16_t Trigger_Point,Trigger_Point_Last;
int16_t Wave_Data[ADC_DATA_LENGTH] = {0};//�洢��ǰ��������
int16_t Pre_Wave_Data[ADC_DATA_LENGTH] = {0};//�洢��һ�β�������
float Point_Voltage;	//���ĵ�ѹֵ
float Point_Time;		//����ʱ��
uint8_t Single_TriggerFlag = 0;	//������־
uint8_t Cancel_Trigger = 0;	//ȡ������
uint32_t ADC_Wave_Offset = 0;//�������ݵ�ַƫ��ֵ
uint16_t Slider_Val = 0;




//��ʼ����ҳ
void Init_Homepage()
{
	FRESULT rc;
	ScuGic_Init();	//��ʼ��ͨ���жϿ�����
	LCD_Init();		//LCD��ʼ��
	GT9147_Init();	//GT9147��ʼ��
	//��ʱ����ʼ����ÿ10ms����һ��
	ScuTimer_Int_Init(10000);
	//DMA��ʼ�������жϹ���
	AXI_DMA_Init(&AxiDma0,XPAR_AXIDMA_0_DEVICE_ID);
	AXI_DMA_RxInt_Init(&AxiDma0,XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR,AXI_DMARx_IRQHandler);

    rc = f_mount(&fatfs, "0:/", 0);		//����SD��
    if (rc != FR_OK) {
    	printf("Mount Failed!\n");		//������ʧ���򷢳�����
    }

	//GPIO��GPIO�жϳ�ʼ��
	PS_GPIO_Init();
	PS_GPIO_Int_Init(PS_GPIO_IRQ_Handler);
	PS_GPIO_SetInt(47,XGPIOPS_IRQ_TYPE_EDGE_FALLING);

	LCD_Clear(LCD_BLACK);	//�������屳��Ϊ��ɫ
	POINT_COLOR = LCD_WHITE;//�ʻ��趨Ϊ��ɫ
	BACK_COLOR = LCD_BLACK;	//�ʻ������趨Ϊ��ɫ

	LCD_ShowString(3,20,180,16,16,0,(uint8_t*)"OMP BY NORMAN (WIP) Basedon Xiaomeige");//��ʾ��ַ
	LCD_DisplayPic(20,50,gImage_logo);//��LOGO

	Draw_Box(ADC_Wave.Window, LCD_WHITE, 0);
	Get_Waveform_Window_Parameters(&ADC_Wave);
	Draw_Waveform_Windows(ADC_Wave, Sample_Rate[Sample_Set]);//KHz

	Draw_Normal_Button(Button_RUN);
	Draw_Normal_Button(Button_AUTO);
	Draw_Normal_Button(Button_CH_INC);
	Draw_Normal_Button(Button_CH_DEC);
	Draw_Normal_Button(Button_SA_INC);
	Draw_Normal_Button(Button_SA_DEC);
	Draw_Normal_Button(Button_Tri_Mode);
	Draw_Normal_Button(Wave_Slider);
	Fill_Box(Slider,LCD_BLUE,5);

	sprintf(str,"%.3fV",Get_ADC_Vmid());
	strcpy(Button_TriggerVal.Text[0],str);
	Draw_Normal_Button(Button_TriggerVal);

	sprintf(str,"CH%d",CH_Set);
	Draw_Normal_Text(Text_CHANNEL, str);
	sprintf(str,"%dKHz",(int)Sample_Rate[Sample_Set]);
	Draw_Normal_Text(Text_SAMPLE, str);

	//�Ȱ�ADC�����������ڴ�����
	memset(P_ADC_Data,0,ADC_DATA_LENGTH*2);

	//�Ȳɼ�һ��
	Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
	//DMA����
	XAxiDma_SimpleTransfer(&AxiDma0,(UINTPTR) P_ADC_Data,
			ADC_DATA_LENGTH*2, XAXIDMA_DEVICE_TO_DMA);
	Measure_Point = ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width/2;		//������ΪY����
	Trigger_Point = ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height/2;	//������ΪX����
}
void Refresh_Measure_Val()
{
	sprintf(str,"Vmin = %.3fV",Get_ADC_Vmin());
	Draw_Normal_Text(Text_Vmin, str);
	sprintf(str,"Vmax = %.3fV",Get_ADC_Vmax());
	Draw_Normal_Text(Text_Vmax, str);
	sprintf(str,"Vpp = %.3fV",Get_ADC_Vmax()-Get_ADC_Vmin());
	Draw_Normal_Text(Text_Vpp, str);
	sprintf(str,"Freq = %luHz",Get_ADC_Freq());
	Draw_Normal_Text(Text_Freq, str);

	if(Trigger_Mode == 0) {	//�����Auto_Trigger��ˢ�µ�ѹ��ֵ
		sprintf(str,"%.3fV",Get_ADC_Vmid());
		strcpy(Button_TriggerVal.Text[0],str);
		Draw_Normal_Button(Button_TriggerVal);
	}
}
void Touch_Scan()
{
	uint8_t i;
	uint32_t Freq;	//Ƶ��
	uint8_t Wave_Density = 4;	//����Auto���ҳ�����Ų����ܶ�
	GT9147_Scan(&Touch_LCD);	//����ɨ��
	if(Touch_LCD.Touched) {		//�����������
		if(!Single_TriggerFlag) {
			if(Judge_TpXY(Touch_LCD,Button_RUN.Box)) {		//RUN����
				Draw_Button_Effect(Button_RUN);
			} else {
				Draw_Normal_Button(Button_RUN);
			}
		}

		if(Judge_TpXY(Touch_LCD,Button_AUTO.Box)) {		//AUTO����
			Draw_Button_Effect(Button_AUTO);
		} else {
			Button_AUTO.BackColor = LCD_GREEN;
			Draw_Normal_Button(Button_AUTO);
		}

		if(Wave_Run && (!Single_TriggerFlag)) {
			if(Judge_TpXY(Touch_LCD,Button_CH_INC.Box)) {	//CH_INC����
				Draw_Button_Effect(Button_CH_INC);
			} else {
				Draw_Normal_Button(Button_CH_INC);
			}

			if(Judge_TpXY(Touch_LCD,Button_CH_DEC.Box)) {	//CH_DEC����
				Draw_Button_Effect(Button_CH_DEC);
			} else {
				Draw_Normal_Button(Button_CH_DEC);
			}

			if(Judge_TpXY(Touch_LCD,Button_SA_INC.Box)) {	//SA_INC����
				Draw_Button_Effect(Button_SA_INC);
			} else {
				Draw_Normal_Button(Button_SA_INC);
			}

			if(Judge_TpXY(Touch_LCD,Button_SA_DEC.Box)) {	//SA_DEC����
				Draw_Button_Effect(Button_SA_DEC);
			} else {
				Draw_Normal_Button(Button_SA_DEC);
			}

			if(Judge_TpXY(Touch_LCD,Button_Tri_Mode.Box)) {	//Tri_Mode����
				Draw_Button_Effect(Button_Tri_Mode);
			} else {
				Draw_Normal_Button(Button_Tri_Mode);
			}

			if((Trigger_Mode==0x03)&&Judge_TpXY(Touch_LCD,Button_TriggerVal.Box)) {//TriggerVal����
				Draw_Button_Effect(Button_TriggerVal);
			} else {

			}
		}

		if(Judge_TpXY(Touch_LCD,Wave_Slider.Box)) { //�������εĻ���
			if(Touch_LCD.Tp_X[0] <= Wave_Slider.Box.X1 + 20)
				Slider_Val = 0;
			else if(Touch_LCD.Tp_X[0] >= Wave_Slider.Box.X1 + Wave_Slider.Box.Width - 20)
				Slider_Val = 200;
			else {
				Slider_Val = Touch_LCD.Tp_X[0] - Wave_Slider.Box.X1 - 20;
			}
			Fill_Box(Slider,Wave_Slider.BackColor,5);
			Slider.X1 = Slider_Val + Wave_Slider.Box.X1;
			Fill_Box(Slider,LCD_BLUE,5);
			ADC_Wave_Offset = Slider_Val*2.5;
		}


		if(Judge_TpXY(Touch_LCD,ADC_Wave.Window) && (!Single_TriggerFlag)) {	//���δ���
			if((1)&&(Wave_Run)&&(!Trigger_Mode)&&
					(Judge_Two_TpXY(Touch_LCD,ADC_Wave.Wave_Area)))//��ָ����
			{
				Sample_Set_Last = Sample_Set;
				if((Touch_LCD.Tp_X[1] > Touch_LCD.Tp_X[0]))
					Sample_Set = (Touch_LCD.Tp_X[1]-Touch_LCD.Tp_X[0])/40;
				else
					Sample_Set = (Touch_LCD.Tp_X[0]-Touch_LCD.Tp_X[1])/40;
				if(Sample_Set >= 7)
					Sample_Set = 7;


				//��������ʸı䣬���޸Ĳ�������
				if(Sample_Set_Last != Sample_Set)
					Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
				sprintf(str,"%dKHz",(int)Sample_Rate[Sample_Set]);
				Draw_Normal_Text(Text_SAMPLE, str);
				Display_Time_Scale(ADC_Wave,Sample_Rate[Sample_Set]);//ˢ��X���ʱ��̶�
			}
			if(Wave_Run == 0) {
				//���������ߣ����϶���ʾÿһ��ĵ�ѹ��ʱ��
				Measure_Point_Last = Measure_Point;
				if(Touch_LCD.Tp_X[0] <= ADC_Wave.Wave_Area.X1)
					Measure_Point = ADC_Wave.Wave_Area.X1;
				else if(Touch_LCD.Tp_X[0] >= ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width)
					Measure_Point = ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width;
				else if(Touch_LCD.Tp_X[0] > ADC_Wave.Wave_Area.X1 &&
						Touch_LCD.Tp_X[0] < ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width)
					Measure_Point = Touch_LCD.Tp_X[0]/5*5;	//���������X�����Ϊ5�ı���ֵ

				//������һ�εı���
				if(Measure_Point_Last != Measure_Point)
				Draw_Mark_Line(1,Measure_Point_Last, ADC_Wave.Wave_Area.Y1,
						ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height,PAGE_COLOR);

			} else if(Trigger_Mode != 0){
				//���ƴ�����ѹ�Ĺ��
				Trigger_Point_Last = Trigger_Point;//��¼��һ������λ��
				if(Touch_LCD.Tp_Y[0] <= ADC_Wave.Wave_Area.Y1)
					Trigger_Point = ADC_Wave.Wave_Area.Y1;
				else if(Touch_LCD.Tp_Y[0] >= ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height)
					Trigger_Point = ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height;
				else if(Touch_LCD.Tp_Y[0] > ADC_Wave.Wave_Area.Y1 &&
						Touch_LCD.Tp_Y[0] < ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height)
					Trigger_Point = Touch_LCD.Tp_Y[0]/1*1;	//���������Y�����Ϊ2�ı���ֵ

				//���ɱ���
				if(Trigger_Point_Last != Trigger_Point)
				Draw_Mark_Line(0,Trigger_Point_Last, ADC_Wave.Wave_Area.X1,
						ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width,PAGE_COLOR);

				Trigger_Value_Last = Trigger_Value;
				//���㴥��ֵ
				Trigger_Value = ((ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height/2
						- Trigger_Point)/ADC_Wave.Precision);

				//�������ֵ���޸ģ��������ò�������
				if(Trigger_Value_Last != Trigger_Value)
					Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
				//ˢ�´�����ѹ��ʾ
				sprintf(str,"%.3fV",Trigger_Value*5.0/32768);
				strcpy(Button_TriggerVal.Text[0],str);
				Draw_Normal_Button(Button_TriggerVal);

			}
		} else {

		}

	} else {
		if(Touch_LCD.Touched_Last) {	//�������δ�������ϴΰ��ˣ���ʾ����
			if(Judge_TpXY(Touch_LCD,Button_RUN.Box) && (!Single_TriggerFlag)) {		//RUN����
				if(Wave_Run) {
					//����STOPģʽ
					Perform_STOP();
				} else {
					Wave_Run = 1;
					Button_RUN.BackColor = LCD_GREEN;
					Button_RUN.TextColor = LCD_BLACK;
					strcpy(Button_RUN.Text[0],"RUN");
					//������ǰ�ı���
					Draw_Mark_Line(1,Measure_Point, ADC_Wave.Wave_Area.Y1,
							ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height,PAGE_COLOR);
					//�����ı�
					Fill_Box(Text_Point_V.Box,Text_Point_V.BackColor,0);
					Fill_Box(Text_Point_T.Box,Text_Point_T.BackColor,0);

					STOP_Ensable_Press();//�����STOP״̬�±�����Ĳ���
				}
				Draw_Normal_Button(Button_RUN);
			}
			if(Judge_TpXY(Touch_LCD,Button_AUTO.Box)) {		//AUTO����
				Set_ADC_Mode(CH_Set, Sample_Rate[7], 0, 0);//�����������ʲ��ɼ�һ��
				if(Single_TriggerFlag)
					Cancel_Trigger = 1;
				Button_AUTO.BackColor = LCD_RED;
				Draw_Button_Effect(Button_AUTO);
				sleep(1);
				Button_AUTO.BackColor = LCD_GREEN;
				Draw_Normal_Button(Button_AUTO);
				Freq = Get_ADC_Freq();
				if(Freq/(2*Sample_Rate[0]) < Wave_Density)
					Sample_Set = 0;
				else if(Freq/(2*Sample_Rate[7]) > Wave_Density)
					Sample_Set = 7;
				else {
					for(i=0;i<7;i++) {
						if((Freq/(2*Sample_Rate[i]) >= Wave_Density) &&
								(Freq/(2*Sample_Rate[i+1]) <= Wave_Density)) {
							if(((float)Freq/(2*Sample_Rate[i]) - Wave_Density) <=
									(Wave_Density - (float)Freq/(2*Sample_Rate[i+1])))
								Sample_Set = i;
							else
								Sample_Set = i + 1;
						}
					}
				}
				sprintf(str,"%dKHz",(int)Sample_Rate[Sample_Set]);
				Draw_Normal_Text(Text_SAMPLE, str);
				Display_Time_Scale(ADC_Wave,Sample_Rate[Sample_Set]);	//ˢ��X���ʱ��̶�
				//����RUN
				Wave_Run = 1;
				Button_RUN.BackColor = LCD_GREEN;
				Button_RUN.TextColor = LCD_BLACK;
				strcpy(Button_RUN.Text[0],"RUN");
				Draw_Normal_Button(Button_RUN);
				//����������
				Draw_Mark_Line(1,Measure_Point, ADC_Wave.Wave_Area.Y1,
						ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height,PAGE_COLOR);
				//���������
				Draw_Mark_Line(0,Trigger_Point, ADC_Wave.Wave_Area.X1,
						ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width,PAGE_COLOR);
				//�����ı�
				Fill_Box(Text_Point_V.Box,Text_Point_V.BackColor,0);
				Fill_Box(Text_Point_T.Box,Text_Point_T.BackColor,0);

				STOP_Ensable_Press();//�����STOP״̬�±�����Ĳ���

				//�л�Ϊ�Զ�����ģʽ
				Trigger_Mode = 0;
				strcpy(Button_Tri_Mode.Text[0],"Auto");
				Draw_Normal_Button(Button_Tri_Mode);
				Button_TriggerVal.TextColor = LCD_WHITE;
				Button_TriggerVal.BackColor = LCD_GRAY;
				Draw_Normal_Button(Button_TriggerVal);
			}

			if(Wave_Run) {
				if(!Single_TriggerFlag) {
					if(Judge_TpXY(Touch_LCD,Button_CH_INC.Box)) {	//CH_INC����
						Draw_Normal_Button(Button_CH_INC);
						if(CH_Set < 7)
							CH_Set++;
						else
							CH_Set = 0;
						//�޸Ĳ�������
						Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
						sprintf(str,"CH%d",CH_Set);
						Draw_Normal_Text(Text_CHANNEL, str);	//����ͨ����ʾ
					}
					if(Judge_TpXY(Touch_LCD,Button_CH_DEC.Box)) {	//CH_DEC����
						Draw_Normal_Button(Button_CH_DEC);
						if(CH_Set > 0)
							CH_Set--;
						else
							CH_Set = 7;
						//�޸Ĳ�������
						Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
						sprintf(str,"CH%d",CH_Set);
						Draw_Normal_Text(Text_CHANNEL, str);	//����ͨ����ʾ
					}
					if(Judge_TpXY(Touch_LCD,Button_SA_INC.Box)) {	//SA_INC����
						Draw_Normal_Button(Button_SA_INC);
						if(Sample_Set < 7)
							Sample_Set++;
						//�޸Ĳ�������
						Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
						sprintf(str,"%dKHz",(int)Sample_Rate[Sample_Set]);
						Draw_Normal_Text(Text_SAMPLE, str);
						Display_Time_Scale(ADC_Wave,Sample_Rate[Sample_Set]);//ˢ��X���ʱ��̶�
					}
					if(Judge_TpXY(Touch_LCD,Button_SA_DEC.Box)) {	//SA_DEC����
						Draw_Normal_Button(Button_SA_DEC);
						if(Sample_Set > 0)
							Sample_Set--;
						//�޸Ĳ�������
						Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
						sprintf(str,"%dKHz",(int)Sample_Rate[Sample_Set]);
						Draw_Normal_Text(Text_SAMPLE, str);
						Display_Time_Scale(ADC_Wave,Sample_Rate[Sample_Set]);//ˢ��X���ʱ��̶�
					}
					if(Judge_TpXY(Touch_LCD,Button_Tri_Mode.Box)) {	//Tri_Mode����
						if(Trigger_Mode == 0x00) {
							Trigger_Mode = 0x01;	//0x01Ϊ�ֶ�����
							strcpy(Button_Tri_Mode.Text[0],"Normal");
							Button_TriggerVal.TextColor = LCD_BLACK;
							Button_TriggerVal.BackColor = LCD_ORANGE;
						} else if(Trigger_Mode == 0x01) {
							Trigger_Mode = 0x03;	//0x03Ϊ���δ���
							strcpy(Button_Tri_Mode.Text[0],"Single");
							Button_TriggerVal.TextColor = LCD_BLACK;
							Button_TriggerVal.BackColor = LCD_GREEN;
						} else {
							Trigger_Mode = 0x00;	//0x00Ϊ�Զ�����
							strcpy(Button_Tri_Mode.Text[0],"Auto");
							Button_TriggerVal.TextColor = LCD_WHITE;
							Button_TriggerVal.BackColor = LCD_GRAY;
							//���������ѹ�Ĺ��
							Draw_Mark_Line(0,Trigger_Point, ADC_Wave.Wave_Area.X1,
									ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width,PAGE_COLOR);
						}
						//�޸Ĳ�������
						Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
						Draw_Normal_Button(Button_Tri_Mode);
						sprintf(str,"%.3fV",Trigger_Value*5.0/32768);
						strcpy(Button_TriggerVal.Text[0],str);
						Draw_Normal_Button(Button_TriggerVal);
					}
				}
				if((Trigger_Mode==0x03)&&Judge_TpXY(Touch_LCD,Button_TriggerVal.Box)) {//TriggerVal����
					//�޸Ĳ�������
					Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
					if(Single_TriggerFlag)
						Cancel_Trigger = 1;
					Single_TriggerFlag = 1;

					Button_TriggerVal.TextColor = LCD_WHITE;
					Button_TriggerVal.BackColor = LCD_RED;
					Draw_Normal_Button(Button_TriggerVal);
					Trigger_Disable_Press();
				}
			}
		}
	}
}



//��ֹ��STOP״ִ̬�е�һЩ����
void STOP_Disable_Press()
{
	Button_CH_INC.BackColor = LCD_GRAY;
	Button_CH_DEC.BackColor = LCD_GRAY;
	Button_SA_INC.BackColor = LCD_GRAY;
	Button_SA_DEC.BackColor = LCD_GRAY;
	Button_Tri_Mode.BackColor = LCD_GRAY;
	Button_TriggerVal.BackColor = LCD_GRAY;
	Draw_Normal_Button(Button_CH_INC);
	Draw_Normal_Button(Button_CH_DEC);
	Draw_Normal_Button(Button_SA_INC);
	Draw_Normal_Button(Button_SA_DEC);
	Draw_Normal_Button(Button_Tri_Mode);
	Draw_Normal_Button(Button_TriggerVal);
}

//�����STOP״̬�±�����Ĳ���
void STOP_Ensable_Press()
{
	Button_CH_INC.BackColor = LCD_BLACK;
	Button_CH_DEC.BackColor = LCD_BLACK;
	Button_SA_INC.BackColor = LCD_BLACK;
	Button_SA_DEC.BackColor = LCD_BLACK;
	Button_Tri_Mode.BackColor = LCD_BLACK;
	if(Trigger_Mode == 0)
		Button_TriggerVal.BackColor = LCD_GRAY;
	else if(Trigger_Mode == 1)
		Button_TriggerVal.BackColor = LCD_ORANGE;
	else
		Button_TriggerVal.BackColor = LCD_GREEN;
	Draw_Normal_Button(Button_CH_INC);
	Draw_Normal_Button(Button_CH_DEC);
	Draw_Normal_Button(Button_SA_INC);
	Draw_Normal_Button(Button_SA_DEC);
	Draw_Normal_Button(Button_Tri_Mode);
	Draw_Normal_Button(Button_TriggerVal);
}

//ִ��STOP����
void Perform_STOP()
{
	Wave_Run = 0;

	//������ΪSTOPģʽ
	Button_RUN.BackColor = LCD_RED;
	Button_RUN.TextColor = LCD_WHITE;
	strcpy(Button_RUN.Text[0],"STOP");
	Draw_Normal_Button(Button_RUN);

	//�������
	Draw_Mark_Line(0,Trigger_Point, ADC_Wave.Wave_Area.X1,
			ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width,PAGE_COLOR);

	//ʹSTOP��ֹ�Ĳ�����ťΪ��ɫ���ɴ�
	STOP_Disable_Press();
}

//��DDR�ж�ȡ��������
void Read_Wave_Data()
{
	memcpy(Pre_Wave_Data,Wave_Data,ADC_DATA_LENGTH*2);	//�����ϴεĲ���ֵ
	memcpy(Wave_Data,P_ADC_Data + ADC_Wave_Offset,
			(ADC_DATA_LENGTH - ADC_Wave_Offset)*2);//��DDR��ȡ��Ҫ�Ĳ���ֵ
}

//ʹ���δ���ʱ��ֹ�Ĳ�����ťΪ��ɫ���ɴ�
void Trigger_Disable_Press()
{
	Button_RUN.BackColor = LCD_GRAY;
	Button_CH_INC.BackColor = LCD_GRAY;
	Button_CH_DEC.BackColor = LCD_GRAY;
	Button_SA_INC.BackColor = LCD_GRAY;
	Button_SA_DEC.BackColor = LCD_GRAY;
	Button_Tri_Mode.BackColor = LCD_GRAY;

	Draw_Normal_Button(Button_RUN);
	Draw_Normal_Button(Button_CH_INC);
	Draw_Normal_Button(Button_CH_DEC);
	Draw_Normal_Button(Button_SA_INC);
	Draw_Normal_Button(Button_SA_DEC);
	Draw_Normal_Button(Button_Tri_Mode);
}

//�ָ����δ�����ֹ�Ĳ�����ť
void Trigger_Enable_Press()
{
	Button_RUN.BackColor = LCD_GREEN;
	Button_CH_INC.BackColor = LCD_BLACK;
	Button_CH_DEC.BackColor = LCD_BLACK;
	Button_SA_INC.BackColor = LCD_BLACK;
	Button_SA_DEC.BackColor = LCD_BLACK;
	Button_Tri_Mode.BackColor = LCD_BLACK;


	Draw_Normal_Button(Button_RUN);
	Draw_Normal_Button(Button_CH_INC);
	Draw_Normal_Button(Button_CH_DEC);
	Draw_Normal_Button(Button_SA_INC);
	Draw_Normal_Button(Button_SA_DEC);
	Draw_Normal_Button(Button_Tri_Mode);
}
void Refresh_WaveWindow()
{
	Read_Wave_Data();//����������
	Draw_Waveform(ADC_Wave,Pre_Wave_Data,Wave_Data);	//������
	if(Wave_Run) {
		if(Trigger_Mode)
			//�������
			Draw_Mark_Line(0,Trigger_Point, ADC_Wave.Wave_Area.X1,
					ADC_Wave.Wave_Area.X1 + ADC_Wave.Wave_Area.Width,LCD_ORANGE);
	} else if(!Wave_Run) {
		//��������
		Draw_Mark_Line(1,Measure_Point, ADC_Wave.Wave_Area.Y1,
				ADC_Wave.Wave_Area.Y1 + ADC_Wave.Wave_Area.Height,LCD_CYAN);

		//ˢ�µ�ѹ��ʾ
		Point_Voltage = Wave_Data[Measure_Point - ADC_Wave.Wave_Area.X1]*5.0/32768;
		if(Point_Voltage >= 0)
			sprintf(str,"Voltage = +%.3fV",Point_Voltage);
		else
			sprintf(str,"Voltage = %.3fV",Point_Voltage);
		Draw_Normal_Text(Text_Point_V, str);

		//ˢ��ʱ����ʾ
		Point_Time = (float)((Measure_Point - ADC_Wave.Wave_Area.X1)-250)/Sample_Rate[Sample_Set];
		if(Point_Time >= 0)
			sprintf(str,"Time = +%.3fms",Point_Time);
		else
			sprintf(str,"Time = %.3fms",Point_Time);
		Draw_Normal_Text(Text_Point_T, str);
	}
}

void Handle_Single_Trigger()
{
	Xil_DCacheFlushRange((UINTPTR)P_ADC_Data,ADC_DATA_LENGTH*2);//ˢ��DDR���ADC����

	//��ť�ָ�ԭɫ
	if(Trigger_Mode == 0x03) {
		Button_TriggerVal.TextColor = LCD_BLACK;
		Button_TriggerVal.BackColor = LCD_GREEN;
	} else {
		Button_TriggerVal.TextColor = LCD_WHITE;
		Button_TriggerVal.BackColor = LCD_GRAY;
	}
	Draw_Normal_Button(Button_TriggerVal);

	Trigger_Enable_Press();

	if(!Cancel_Trigger)//����ȡ������STOP
		Perform_STOP();//ִ��STOP����
	Cancel_Trigger = 0;		//���־
}
void Handle_Round_Done()
{
	RxDone = 0;
	Xil_DCacheFlushRange((UINTPTR)P_ADC_Data,ADC_DATA_LENGTH*2);//ˢ��DDR���ADC����
	//������һ�δ���
	Set_ADC_Mode(CH_Set, Sample_Rate[Sample_Set], Trigger_Value, Trigger_Mode);
	//DMA����
	XAxiDma_SimpleTransfer(&AxiDma0,(UINTPTR) P_ADC_Data,
			ADC_DATA_LENGTH*2, XAXIDMA_DEVICE_TO_DMA);

}
