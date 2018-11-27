/*
 * cmd_proc.c  
 */

//Oct.11,2018, SL: created for Target Protect DE10 Server

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"

#define BLOCK_SIZE 1024 //block transfer size

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
		
		if ( strcmp(cmd,"CH:SEL")== 0 ) {writeReg(VR_BASE+CH_SEL,invalue);return 0;}
		
		if ( strcmp(cmd,"PCA:GAIN")== 0 ) {writeReg(VR_BASE+PCA_GAIN,invalue);return 0;}
		if ( strcmp(cmd,"PCA:GAIN?")== 0 ) {*value_back = readReg(VR_BASE+PCA_GAIN);return 1;}
		
		if ( strcmp(cmd,"RELAY")== 0 ) {writeReg(VR_BASE+RELAY,invalue);return 0;}
		if ( strcmp(cmd,"RELAY?")== 0 ) {*value_back = readReg(VR_BASE+RELAY);return 1;}
		
		if ( strcmp(cmd,"CONF2EEPROM")== 0 ) {writeReg(VR_BASE+EEPROM_WR,invalue);return 0;}
		if ( strcmp(cmd,"EEPROM2CONF")== 0 ) {writeReg(VR_BASE+EEPROM_RD,invalue);return 0;}
		
		if ( strcmp(cmd,"REG2CONF")== 0 ) {writeReg(VR_BASE+CONF_WR,invalue);return 0;}
		if ( strcmp(cmd,"CONF2REG")== 0 ) {writeReg(VR_BASE+CONF_RD,invalue);return 0;;}
		
		if ( strcmp(cmd,"FIFO:CLR")== 0 ) {writeReg(VR_BASE+FIFO_CLR,invalue);return 0;}
		if ( strcmp(cmd,"FPGA_VER?")== 0 ) {*value_back = readReg(VR_BASE+FPGA_VER);return 1;}
		if ( strcmp(cmd,"FIFO:WD?")== 0 ) {*value_back = readReg(VR_BASE+FIFO_WD);return 1;}
		
		if ( strcmp(cmd,"FIFO?")== 0 ) {
    		for(cntr=0;cntr<BLOCK_SIZE;cntr++)  dataArray[cntr]= readReg(VR_BASE+FIFO);
			*array_Ptr = &dataArray[0]; *array_Dim = BLOCK_SIZE;
    		return 3;}
		
        printf("\n\r Error: Bad command %s \n\r", cmd);
		
		}

    return 0;

}
