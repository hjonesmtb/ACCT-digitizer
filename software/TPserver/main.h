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

#define BUFFER_MAX_SIZE 4000
#define STRING_MAX_LENGTH 36864

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

#define FPGA_STATUS_REG_ADDR 4*0
#define FPGA_CONTROL_REG_ADDR 4*1
#define FPGA_MASK_REG_ADDR 4*2
#define FPGA_VER_ADDR 4*3
#define PCA_GAIN_ADDR 4*5


#define FIFO_CLR_ADDR 4*9
#define FIFO_WD_ADDR 4*10
#define FIFO_ADDR 4*11

#define RELAY_ADDR 4*12




#define CR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_CONTROL_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define SR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_STATUS_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define MR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_MASK_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FPGA_VER  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_VER_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define PCA_GAIN  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + PCA_GAIN_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FIFO_WD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_WD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO_CLR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_CLR_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define RELAY  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + RELAY_ADDR ) & (unsigned long) (HW_REGS_MASK))


extern sem_t       buffer_1_sem;
extern uint8_t*    buffer_1;
extern int         buffer_1_currentSize;

extern sem_t       buffer_2_sem;
extern uint8_t*    buffer_2;
extern int         buffer_2_currentSize;

 


#endif/*__COMMON_H__ */
