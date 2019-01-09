/*
 * cmd_proc.c  
 */

//Oct.11,2018, SL: created for Target Protect DE10 Server

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"

#define BLOCK_SIZE 1024 //block transfer size for FAST FIFO
#define PACKET_SIZE 32 //block transfer size for PACKET

static inline void writeReg(void* addr, uint32_t value)
{
    *(uint32_t*) (addr) = value;
}

static inline uint32_t readReg(void* addr)
{

    return *(uint32_t*) (addr);
}

int dataArray[1024];
extern void* VR_BASE;

int cmd_proc(char *cmdString_in , int *value_back, char **string_back, int **array_Ptr, int *array_Dim)
{

char cmd[50],*sdp,*chp;

  //uint32_t trash;
  //uint32_t fifo_wd;

  uint32_t cmdlen, val_len;
  uint32_t invalue,cntr;

    
	strcpy(cmd, cmdString_in);
	chp = strchr(cmd,'\r');
	*chp = '\0';
	cmdlen = strlen(cmd);

	//printf("\n\r cmd_porc.c:Your command is %s, Len=%d\n\r",cmd, cmdlen);
	
	  
	if ( cmdlen == 0 ){
    	printf("\n\r Error: Your command doesn't contain any characters \n\r" );  return 0;}
	else {
		if ((sdp = strchr(cmd,' ')) != NULL){				  // There is a space in the command
			*sdp = '\0';
			sdp++;
			if ((chp = strchr(sdp,' ')) != NULL){
				chp = strrchr(sdp,' ');                       // Check if there were more than one spaces
				sdp = ++chp;
			}

			val_len = strlen(sdp);
			if (val_len > 0){
				if (val_len == strspn(sdp,"-1234567890")) {
					invalue = atoi(sdp);
				}
				else { printf("\n\r Error: There is a non digit character in value \n\r" ); return 0;
				}
			}
		}
        
		//printf("\n\r cmd_porc.c:Your command is %s %d\n\r",cmd,invalue );
		
		if ( strcmp(cmd,"CR")== 0 ) {writeReg(VR_BASE+CR,invalue);return 0;}
		if ( strcmp(cmd,"CR?")== 0 ) {*value_back = readReg(VR_BASE+CR);return 1;}
		if ( strcmp(cmd,"SR?")== 0 ) {*value_back = readReg(VR_BASE+SR);return 1;}
		if ( strcmp(cmd,"MR")== 0 ) {writeReg(VR_BASE+MR,invalue);return 0;}
		if ( strcmp(cmd,"MR?")== 0 ) {*value_back = readReg(VR_BASE+MR);return 1;}
		if ( strcmp(cmd,"FPGA_VER?")== 0 ) {*value_back = readReg(VR_BASE+FPGA_VER);return 1;}
				
		if ( strcmp(cmd,"CH:SEL")== 0 ) {writeReg(VR_BASE+CH_SEL,invalue);return 0;}
		
		if ( strcmp(cmd,"PCA:GAIN")== 0 ) {writeReg(VR_BASE+PCA_GAIN,invalue);return 0;}
		if ( strcmp(cmd,"PCA:GAIN?")== 0 ) {*value_back = readReg(VR_BASE+PCA_GAIN);return 1;}
		
		if ( strcmp(cmd,"RELAY")== 0 ) {writeReg(VR_BASE+RELAY,invalue);return 0;}
		if ( strcmp(cmd,"RELAY?")== 0 ) {*value_back = readReg(VR_BASE+RELAY);return 1;}
		
		if ( strcmp(cmd,"CONF2EEPROM")== 0 ) {writeReg(VR_BASE+EEPROM_WR,invalue);return 0;}
		if ( strcmp(cmd,"EEPROM2CONF")== 0 ) {writeReg(VR_BASE+EEPROM_RD,invalue);return 0;}
		
		if ( strcmp(cmd,"REG2CONF")== 0 ) {writeReg(VR_BASE+CONF_WR,invalue);return 0;}
		if ( strcmp(cmd,"CONF2REG")== 0 ) {writeReg(VR_BASE+CONF_RD,invalue);return 0;;}
		
		if ( strcmp(cmd,"SFIFO:WD?")== 0 ) {*value_back = readReg(VR_BASE+SFIFO_WD);return 1;}
		if ( strcmp(cmd,"SFIFO?")== 0 ) {
    		for(cntr=0;cntr<PACKET_SIZE;cntr++)  dataArray[cntr]= readReg(VR_BASE+SFIFO);
			*array_Ptr = &dataArray[0]; *array_Dim = PACKET_SIZE;
    		return 3;}
		
		if ( strcmp(cmd,"FIFO:CLR")== 0 ) {writeReg(VR_BASE+FIFO_CLR,invalue);return 0;}
		if ( strcmp(cmd,"FIFO:WD?")== 0 ) {*value_back = readReg(VR_BASE+FIFO_WD);return 1;}	
		if ( strcmp(cmd,"FIFO?")== 0 ) {
    		for(cntr=0;cntr<BLOCK_SIZE;cntr++)  dataArray[cntr]= readReg(VR_BASE+FIFO);
			*array_Ptr = &dataArray[0]; *array_Dim = BLOCK_SIZE;
    		return 3;}
		
        if ( strcmp(cmd,"TRIP:TH0")== 0 ) {writeReg(VR_BASE+TRIP_TH0,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH0?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH0);return 1;}

        if ( strcmp(cmd,"TRIP:TH1")== 0 ) {writeReg(VR_BASE+TRIP_TH1,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH1?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH1);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH2")== 0 ) {writeReg(VR_BASE+TRIP_TH2,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH2?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH2);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH3")== 0 ) {writeReg(VR_BASE+TRIP_TH3,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH3?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH3);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH4")== 0 ) {writeReg(VR_BASE+TRIP_TH4,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH4?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH4);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH5")== 0 ) {writeReg(VR_BASE+TRIP_TH5,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH5?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH5);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH6")== 0 ) {writeReg(VR_BASE+TRIP_TH6,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH6?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH6);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH7")== 0 ) {writeReg(VR_BASE+TRIP_TH7,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH7?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH7);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH8")== 0 ) {writeReg(VR_BASE+TRIP_TH8,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH8?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH8);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH9")== 0 ) {writeReg(VR_BASE+TRIP_TH9,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH9?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH9);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH10")== 0 ) {writeReg(VR_BASE+TRIP_TH10,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH10?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH10);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH11")== 0 ) {writeReg(VR_BASE+TRIP_TH11,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH11?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH11);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH12")== 0 ) {writeReg(VR_BASE+TRIP_TH12,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH12?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH12);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH13")== 0 ) {writeReg(VR_BASE+TRIP_TH13,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH13?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH13);return 1;}
		
        if ( strcmp(cmd,"TRIP:TH14")== 0 ) {writeReg(VR_BASE+TRIP_TH14,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH14?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH14);return 1;}																														
    		
        if ( strcmp(cmd,"TRIP:TH15")== 0 ) {writeReg(VR_BASE+TRIP_TH15,invalue);return 0;}
		if ( strcmp(cmd,"TRIP:TH15?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH15);return 1;}
				
		
    	printf("\n\r Error: Bad command %s \n\r", cmd);
		
		}

    return 0;

}
