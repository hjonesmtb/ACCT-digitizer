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
#define CH_SELECT_ADDR 4*4
#define PCA_GAIN_ADDR 4*5

#define SFIFO_WD_ADDR 4*7
#define SFIFO_ADDR 4*8

#define FIFO_CLR_ADDR 4*9
#define FIFO_WD_ADDR 4*10
#define FIFO_ADDR 4*11

#define RELAY_ADDR 4*12

#define CONF_RD_ADDR 4*13
#define CONF_WR_ADDR 4*14

#define EEPROM_RD_ADDR 4*15
#define EEPROM_WR_ADDR 4*16

#define TRIP_TH0_ADDR 4*30
#define TRIP_TH1_ADDR 4*31
#define TRIP_TH2_ADDR 4*32
#define TRIP_TH3_ADDR 4*33
#define TRIP_TH4_ADDR 4*34
#define TRIP_TH5_ADDR 4*35
#define TRIP_TH6_ADDR 4*36
#define TRIP_TH7_ADDR 4*37

#define TRIP_TH8_ADDR 4*38
#define TRIP_TH9_ADDR 4*39
#define TRIP_TH10_ADDR 4*40
#define TRIP_TH11_ADDR 4*41
#define TRIP_TH12_ADDR 4*42
#define TRIP_TH13_ADDR 4*43
#define TRIP_TH14_ADDR 4*44
#define TRIP_TH15_ADDR 4*45

#define CR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_CONTROL_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define SR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_STATUS_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define MR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_MASK_REG_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FPGA_VER  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FPGA_VER_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define CH_SEL  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + CH_SELECT_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define PCA_GAIN  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + PCA_GAIN_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define SFIFO_WD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + SFIFO_WD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define SFIFO  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + SFIFO_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define FIFO_WD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_WD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define FIFO_CLR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + FIFO_CLR_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define RELAY  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + RELAY_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define CONF_RD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + CONF_RD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define CONF_WR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + CONF_WR_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define EEPROM_RD  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + EEPROM_RD_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define EEPROM_WR  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + EEPROM_WR_ADDR ) & (unsigned long) (HW_REGS_MASK))

#define TRIP_TH0   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH0_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH1   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH1_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH2   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH2_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH3   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH3_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH4   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH4_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH5   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH5_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH6   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH6_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH7   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH7_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH8   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH8_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH9   (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH9_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH10  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH10_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH11  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH11_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH12  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH12_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH13  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH13_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH14  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH14_ADDR ) & (unsigned long) (HW_REGS_MASK))
#define TRIP_TH15  (( (unsigned long) ALT_LWFPGASLVS_OFST + MYAVALONBUS32_0_BASE + TRIP_TH15_ADDR ) & (unsigned long) (HW_REGS_MASK))

extern sem_t       buffer_1_sem;
extern uint8_t*    buffer_1;
extern int         buffer_1_currentSize;

extern sem_t       buffer_2_sem;
extern uint8_t*    buffer_2;
extern int         buffer_2_currentSize;

 


#endif/*__COMMON_H__ */
