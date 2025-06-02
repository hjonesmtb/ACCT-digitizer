#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>
#include <semaphore.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"

#define FW_VERSION 20250522 // firmware version (20241216)
//#define FW_VERSION 20190002 //firmware version 

#define HIST_LENGTH 10 // number of samples to calculate std dev from

#define BUFFER_MAX_SIZE 4000
#define STRING_MAX_LENGTH 36864


#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

#define FPGA_STATUS_REG_ADDR 4*0
#define FPGA_CONTROL_REG_ADDR 4*1
//#define FPGA_MASK_REG_ADDR 4*2
#define FPGA_VER_ADDR 4*3
#define CH_SELECT_ADDR 4*4
//#define PCA_GAIN_ADDR 4*5
#define ADC_INIT_ADDR 4*6

#define SFIFO_WD_ADDR 4*7
#define SFIFO_ADDR 4*8

#define FIFO_CLR_ADDR 4*9
#define FIFO_WD_ADDR 4*10
#define FIFO_ADDR 4*11

//#define BEAM_AVG_ADDR 4*12

//#define RELAY_ADDR 4*13

//#define TRIG_TH_ADDR 4*14

#define EEPROM_RD_ADDR 4*15
#define EEPROM_WR_ADDR 4*16

//#define TRIP_TH0_ADDR 4*30
//#define TRIP_TH1_ADDR 4*31

#define ADC_READ_ADDR 4*32

#define CAL_WAVE_ADDR 4*33

#define IIR_OUT_BF_K1_ADDR 4*38
#define IIR_OUT_BF_K2_ADDR 4*39

//#define DCR_PU_ADDR 4*40
//#define DCR_PD_ADDR 4*41

#define ALPHA_ADDR 4*42

#define IIR_OUT_SA_K1_ADDR 4*47
#define IIR_OUT_SA_K2_ADDR 4*48

#define FP_SLOPE_ADDR 4*49
#define FP_OFFSET_ADDR 4*50

#define FP_CH0_G_ADDR 4*43
#define FP_CH0_Z_ADDR 4*44
#define FP_CH1_G_ADDR 4*45
#define FP_CH1_Z_ADDR 4*46

/*
#define FP_CH0_K0_ADDR 4*34
#define FP_CH0_K1_ADDR 4*35
#define FP_CH0_K2_ADDR 4*36
#define FP_CH0_K3_ADDR 4*37
#define FP_CH0_K4_ADDR 4*43
#define FP_CH0_K5_ADDR 4*44
#define FP_CH0_K6_ADDR 4*45
#define FP_CH0_K7_ADDR 4*46
#define FP_CH0_K8_ADDR 4*59
#define FP_CH0_K9_ADDR 4*60

#define FP_CH1_K0_ADDR 4*61
#define FP_CH1_K1_ADDR 4*62
#define FP_CH1_K2_ADDR 4*63
#define FP_CH1_K3_ADDR 4*64
#define FP_CH1_K4_ADDR 4*65
#define FP_CH1_K5_ADDR 4*66
#define FP_CH1_K6_ADDR 4*67
#define FP_CH1_K7_ADDR 4*68
#define FP_CH1_K8_ADDR 4*69
#define FP_CH1_K9_ADDR 4*70

#define FP_CH0_K10_ADDR 4*73
#define FP_CH0_K11_ADDR 4*74
#define FP_CH1_K10_ADDR 4*75
#define FP_CH1_K11_ADDR 4*76

*/

#define MODULE_ID0_ADDR 4*71
#define MODULE_ID1_ADDR 4*72


#define CR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_CONTROL_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define SR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_STATUS_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
//#define MR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_MASK_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FPGA_VER  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_VER_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define CH_SEL  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + CH_SELECT_ADDR ) & (unsigned long) (HW_REGS_MASK))
//#define PCA_GAIN  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + PCA_GAIN_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define ADC_INIT  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + ADC_INIT_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define ADC_READ  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + ADC_READ_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define SFIFO_WD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + SFIFO_WD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define SFIFO  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + SFIFO_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FIFO_WD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_WD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO_CLR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_CLR_ADDR ) & (unsigned long) (HW_REGS_MASK))
//#define RELAY  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + RELAY_ADDR ) & (unsigned long) (HW_REGS_MASK))

//#define BEAM_AVG  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + BEAM_AVG_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define EEPROM_RD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + EEPROM_RD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define EEPROM_WR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + EEPROM_WR_ADDR ) & (unsigned long) (HW_REGS_MASK))

//#define TRIG_TH  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIG_TH_ADDR ) & (unsigned long) (HW_REGS_MASK))
//
//#define TRIP_TH0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH0_ADDR ) & (unsigned long) (HW_REGS_MASK))
//#define TRIP_TH1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH1_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define CAL_WAVE   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + CAL_WAVE_ADDR ) & (unsigned long) (HW_REGS_MASK))

//#define DCR_PU   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + DCR_PU_ADDR ) & (unsigned long) (HW_REGS_MASK))
//#define DCR_PD   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + DCR_PD_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define ALPHA   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + ALPHA_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define IIR_OUT_BF_K1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + IIR_OUT_BF_K1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define IIR_OUT_BF_K2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + IIR_OUT_BF_K2_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define IIR_OUT_SA_K1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + IIR_OUT_SA_K1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define IIR_OUT_SA_K2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + IIR_OUT_SA_K2_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FP_SLOPE   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_SLOPE_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_OFFSET  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_OFFSET_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FP_CH0_G   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_G_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_Z   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_Z_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_G   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_G_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_Z   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_Z_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define MODULE_ID0  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + MODULE_ID0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define MODULE_ID1  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + MODULE_ID1_ADDR ) & (unsigned long) (HW_REGS_MASK))

/*
#define FP_CH0_G0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_G0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_G1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_G1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_G2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_G2_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_G3   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_G3_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FP_CH1_G0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_G0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_G1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_G1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_G2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_G2_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_G3   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_G3_ADDR ) & (unsigned long) (HW_REGS_MASK))
*/

extern sem_t       buffer_1_sem;
extern uint8_t*    buffer_1;
extern int         buffer_1_currentSize;

extern sem_t       buffer_2_sem;
extern uint8_t*    buffer_2;
extern int         buffer_2_currentSize;

/*
#define FP_CH0_K0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K2_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K3   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K3_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K4   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K4_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K5   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K5_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K6   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K6_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K7   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K7_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K8   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K8_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K9   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K9_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH0_K10   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K10_ADDR ) & (unsigned long) (HW_REGS_MASK)) 
#define FP_CH0_K11   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH0_K11_ADDR ) & (unsigned long) (HW_REGS_MASK)) 

#define FP_CH1_K0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K2_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K3   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K3_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K4   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K4_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K5   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K5_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K6   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K6_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K7   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K7_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K8   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K8_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FP_CH1_K9   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K9_ADDR ) & (unsigned long) (HW_REGS_MASK)) 
#define FP_CH1_K10   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K10_ADDR ) & (unsigned long) (HW_REGS_MASK)) 
#define FP_CH1_K11   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FP_CH1_K11_ADDR ) & (unsigned long) (HW_REGS_MASK)) 
*/


#endif/*__COMMON_H__ */
