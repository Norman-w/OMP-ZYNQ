
#ifndef ADC_ACQ2DDR_IP_H
#define ADC_ACQ2DDR_IP_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xparameters.h"
#include "xil_io.h"

#define	ADC_IP_BASEADDR XPAR_ADC_ACQ2DDR_IP_0_S00_AXI_BASEADDR	//ADC IP»ùµØÖ·
#define REG_ADC_CONTROL 0
#define REG_ADC_MINMAX  4
#define REG_ADC_STATE   8
#define REG_ADC_FREQ    12

#define SET_ADC_REG(RegOffset, Data)	ADC_ACQ2DDR_IP_mWriteReg(ADC_IP_BASEADDR,RegOffset,Data)
#define GET_ADC_REG(RegOffset)			ADC_ACQ2DDR_IP_mReadReg(ADC_IP_BASEADDR,RegOffset)


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a ADC_ACQ2DDR_IP register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the ADC_ACQ2DDR_IPdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void ADC_ACQ2DDR_IP_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define ADC_ACQ2DDR_IP_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a ADC_ACQ2DDR_IP register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the ADC_ACQ2DDR_IP device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 ADC_ACQ2DDR_IP_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define ADC_ACQ2DDR_IP_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

void Set_ADC_Mode(uint32_t Channel,uint32_t Sample_Rate,
		uint32_t Trigger_Val,uint32_t Trigger_Mode);
uint32_t Get_ADC_Freq();
float Get_ADC_Vmin();
float Get_ADC_Vmax();
float Get_ADC_Vmid();
uint16_t Get_ADC_MidVal();

#endif // ADC_ACQ2DDR_IP_H
