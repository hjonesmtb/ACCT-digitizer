/*
 * cmd_proc.c  
 */
 
//Oct.11,2018, SL: created for Target Protect DE10 Server

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "main.h"

//#define BLOCK_SIZE 4096 //block transfer size for FAST FIFO
#define BLOCK_SIZE 1024*2 //block transfer size for FAST FIFO
#define PACKET_SIZE 32 //block transfer size for PACKET

#define AVG1_IDX 3
#define AVG2_IDX 4
#define PEAK1_IDX 20
#define PEAK2_IDX 24

#define AVG1_ERR_IDX 10
#define AVG2_ERR_IDX 11
#define PEAK1_ERR_IDX 27
#define PEAK2_ERR_IDX 28

static inline void writeReg(void* addr, uint32_t value)
{
    *(uint32_t*) (addr) = value;
}
 
static inline uint32_t readReg(void* addr)
{

    return *(uint32_t*) (addr);
}

//union Data {
//	int i;
//	float f;
//};

extern int avg1_samples[HIST_LENGTH], avg2_samples[HIST_LENGTH];
extern int peak1_samples[HIST_LENGTH], peak2_samples[HIST_LENGTH];

int dataArray[BLOCK_SIZE];
extern void* VR_BASE;

void Load_Conf()
{
     writeReg(VR_BASE+EEPROM_RD,0);
}

void ADC_Init()
{
    readReg(VR_BASE+ADC_INIT);
}

int get_stddev(int samples[])
{
	int avg = 0;
	int sum_sq = 0;
	int idx = 0;
	for (idx = HIST_LENGTH-1; idx > 0; idx--){
		samples[idx] = samples[idx-1];
		avg += samples[idx];
	}
	samples[0] = readReg(VR_BASE+SFIFO);
	avg += samples[0];
	avg /= HIST_LENGTH;
	//dataArray[cntr] = samples[0];

	for (idx = 0; idx < HIST_LENGTH; idx++){
		sum_sq += (int) pow(samples[idx] - avg,2);
	}
	
	return (int) sqrt(sum_sq/HIST_LENGTH); //std dev
}
	

	int cmd_proc(char *cmdString_in , int *value_back, char **string_back, int **array_Ptr, int *array_Dim)
{

//union Data curr;
//union Data stddev;

int avg1_err=0, avg2_err=0, peak1_err=0, peak2_err=0;

char cmd[50],*sdp,*chp;

  //uint32_t trash; 
  //uint32_t fifo_wd;

  uint32_t cmdlen, val_len;
  uint32_t invalue,cntr;
	
  union fp_conv {
	uint32_t ival;
	float fval;
  } invalue_fp, valueback_fp;
    
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
					invalue_fp.fval = atof(sdp)/100000; // Convert fixed point int into float (i.e '49100' --> 0.491)
				}
				else { printf("\n\r Error: There is a non digit character in value \n\r" ); return 0;
				}
			}
		}
        
		//printf("\n\r cmd_porc.c:Your command is %s %d\n\r",cmd,invalue );
		
		if ( strcmp(cmd,"CR")== 0 ) {writeReg(VR_BASE+CR,invalue);return 0;}
		if ( strcmp(cmd,"CR?")== 0 ) {*value_back = readReg(VR_BASE+CR);return 1;}
		if ( strcmp(cmd,"SR?")== 0 ) {*value_back = readReg(VR_BASE+SR);return 1;}
		//if ( strcmp(cmd,"MR")== 0 ) {writeReg(VR_BASE+MR,invalue);return 0;}
		//if ( strcmp(cmd,"MR?")== 0 ) {*value_back = readReg(VR_BASE+MR);return 1;}
		if ( strcmp(cmd,"FPGA_VER?")== 0 ) {*value_back = readReg(VR_BASE+FPGA_VER);return 1;}
		if ( strcmp(cmd,"FW_VER?")== 0 ) {*value_back = FW_VERSION;return 1;}
		
		if ( strcmp(cmd,"ADC_INIT")== 0 ) {*value_back = readReg(VR_BASE+ADC_INIT);return 1;}
		if ( strcmp(cmd,"ADC_READ")== 0 ) {*value_back = readReg(VR_BASE+ADC_READ);return 1;}
				
		if ( strcmp(cmd,"CH:SEL")== 0 ) {writeReg(VR_BASE+CH_SEL,invalue);return 0;}

//		if ( strcmp(cmd,"PCA:GAIN")== 0 ) {writeReg(VR_BASE+PCA_GAIN,invalue);return 0;}
//		if ( strcmp(cmd,"PCA:GAIN?")== 0 ) {*value_back = readReg(VR_BASE+PCA_GAIN);return 1;}

		if ( strcmp(cmd,"ALPHA")== 0 ) {writeReg(VR_BASE+ALPHA,invalue);return 0;}
		if ( strcmp(cmd,"ALPHA?")== 0 ) {*value_back = readReg(VR_BASE+ALPHA);return 1;}
		
		//if ( strcmp(cmd,"BEAM_AVG?")== 0 ) {*value_back = readReg(VR_BASE+BEAM_AVG);return 1;}
		
		if ( strcmp(cmd,"CONF2EEPROM")== 0 ) {writeReg(VR_BASE+EEPROM_WR,invalue);return 0;}
		if ( strcmp(cmd,"EEPROM2CONF")== 0 ) {writeReg(VR_BASE+EEPROM_RD,invalue);return 0;}
		
		//if ( strcmp(cmd,"REG2CONF")== 0 ) {writeReg(VR_BASE+CONF_WR,invalue);return 0;}
		//if ( strcmp(cmd,"CONF2REG")== 0 ) {writeReg(VR_BASE+CONF_RD,invalue);return 0;;}
		
		if ( strcmp(cmd,"SFIFO:WD?")== 0 ) {*value_back = readReg(VR_BASE+SFIFO_WD);return 1;}
		if ( strcmp(cmd,"SFIFO?")== 0 ) {
    		for(cntr=0;cntr<PACKET_SIZE;cntr++){
				
				if(cntr == AVG1_IDX) { 
					avg1_err = get_stddev(avg1_samples);
					dataArray[cntr] = avg1_samples[0];
				}
				else if(cntr == AVG2_IDX) { 
					avg2_err = get_stddev(avg2_samples);
					dataArray[cntr] = avg2_samples[0];
				}
				else if(cntr == PEAK1_IDX) { 
					peak1_err = get_stddev(peak1_samples);
					//peak1_err = 420;
					dataArray[cntr] = peak1_samples[0];
					
					// NEW
					//dataArray[AVG1_IDX] = peak1_samples[0] - avg1_samples[0];
				}
				else if(cntr == PEAK2_IDX) { 
					peak2_err = get_stddev(peak2_samples);
					dataArray[cntr] = peak2_samples[0];
					
					// NEW
					//dataArray[AVG2_IDX] = peak2_samples[0] - avg2_samples[0];
				}
			
				else if(cntr == AVG1_ERR_IDX){
					dataArray[cntr] = avg1_err;
					readReg(VR_BASE+SFIFO);
				}
				else if(cntr == AVG2_ERR_IDX){
					dataArray[cntr] = avg2_err;
					readReg(VR_BASE+SFIFO);
				}
				else if(cntr == PEAK1_ERR_IDX){
					dataArray[cntr] = peak1_err;
					readReg(VR_BASE+SFIFO);
				}
				else if(cntr == PEAK2_ERR_IDX){
					dataArray[cntr] = peak2_err;
					readReg(VR_BASE+SFIFO);
				}
				else{
					dataArray[cntr] = readReg(VR_BASE+SFIFO);
				}	
			}
//            dataArray[10] = curr_samples2[1];
//			dataArray[11] = curr_samples2[2];
//			dataArray[12] = curr_samples2[3];
//			dataArray[13] = curr_samples2[4];
//			dataArray[14] = curr_samples2[5];
//			dataArray[15] = curr_samples2[6];
//			dataArray[16] = curr_samples2[7];
//			dataArray[17] = curr_samples2[8];
//			dataArray[18] = curr_samples2[9];

			*array_Ptr = &dataArray[0]; *array_Dim = PACKET_SIZE;
    		return 3;}
		
		if ( strcmp(cmd,"FIFO:CLR")== 0 ) {writeReg(VR_BASE+FIFO_CLR,invalue);return 0;}
		if ( strcmp(cmd,"FIFO:WD?")== 0 ) {*value_back = readReg(VR_BASE+FIFO_WD);return 1;}	
		if ( strcmp(cmd,"FIFO?")== 0 ) {
    		for(cntr=0;cntr<BLOCK_SIZE;cntr++)  dataArray[cntr]= readReg(VR_BASE+FIFO);
			*array_Ptr = &dataArray[0]; *array_Dim = BLOCK_SIZE;
    		return 3;}
		
//        if ( strcmp(cmd,"TRIP:TH0")== 0 ) {writeReg(VR_BASE+TRIP_TH0,invalue);return 0;}
//		if ( strcmp(cmd,"TRIP:TH0?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH0);return 1;}
//
//        if ( strcmp(cmd,"TRIP:TH1")== 0 ) {writeReg(VR_BASE+TRIP_TH1,invalue);return 0;}
//		if ( strcmp(cmd,"TRIP:TH1?")== 0 ) {*value_back = readReg(VR_BASE+TRIP_TH1);return 1;}
//
//		if ( strcmp(cmd,"TRIG:TH")== 0 ) {writeReg(VR_BASE+TRIG_TH,invalue);return 0;}
//
		if ( strcmp(cmd,"CAL_WAVE")== 0 ) {writeReg(VR_BASE+CAL_WAVE,invalue);return 0;}
		if ( strcmp(cmd,"CAL_WAVE?")== 0 ) {*value_back = readReg(VR_BASE+CAL_WAVE);return 1;}
		
		if ( strcmp(cmd,"IIR_OUT_BF_K1")== 0 ) {
			//writeReg(VR_BASE+IIR_OUT_BF_K1,invalue_fp.ival);
			writeReg(VR_BASE+IIR_OUT_BF_K1,invalue);
			return 0;
			}
		if ( strcmp(cmd,"IIR_OUT_BF_K1?")== 0 ) {
//			 valueback_fp.ival = readReg(VR_BASE+IIR_OUT_BF_K1);
//			*value_back = (int) 100000*valueback_fp.fval;
			*value_back = readReg(VR_BASE+IIR_OUT_BF_K1);
			return 1;
			}
		
		if ( strcmp(cmd,"IIR_OUT_BF_K2")== 0 ) {
//			writeReg(VR_BASE+IIR_OUT_BF_K2,invalue_fp.ival);
			writeReg(VR_BASE+IIR_OUT_BF_K2,invalue);
			return 0;
			}
		if ( strcmp(cmd,"IIR_OUT_BF_K2?")== 0 ) {
//			 valueback_fp.ival = readReg(VR_BASE+IIR_OUT_BF_K2);
//			*value_back = (int) 100000*valueback_fp.fval;
			*value_back = readReg(VR_BASE+IIR_OUT_BF_K2);
		    return 1;
		    }
		
		if ( strcmp(cmd,"IIR_OUT_SA_K1")== 0 ) {
//		    writeReg(VR_BASE+IIR_OUT_SA_K1,invalue_fp.ival);
			writeReg(VR_BASE+IIR_OUT_SA_K1,invalue);
		    return 0;
		    }
		if ( strcmp(cmd,"IIR_OUT_SA_K1?")== 0 ) {
//			 valueback_fp.ival = readReg(VR_BASE+IIR_OUT_SA_K1);
//			*value_back = (int) 100000*valueback_fp.fval;
			 *value_back = readReg(VR_BASE+IIR_OUT_SA_K1); 
		    return 1;
		    }
		
		if ( strcmp(cmd,"IIR_OUT_SA_K2")== 0 ) {
//		    writeReg(VR_BASE+IIR_OUT_SA_K2,invalue_fp.ival);
			 writeReg(VR_BASE+IIR_OUT_SA_K2,invalue);
		    return 0;
		    }
		if ( strcmp(cmd,"IIR_OUT_SA_K2?")== 0 ) {
//			 valueback_fp.ival = readReg(VR_BASE+IIR_OUT_SA_K2);
//			*value_back = (int) 100000*valueback_fp.fval;
			 
			*value_back = readReg(VR_BASE+IIR_OUT_SA_K2);
		    return 1;
		    }
		
//		if ( strcmp(cmd,"DCR_PU")== 0 ) {writeReg(VR_BASE+DCR_PU,invalue);return 0;}
//		if ( strcmp(cmd,"DCR_PU?")== 0 ) {*value_back = readReg(VR_BASE+DCR_PU);return 1;}
//
//		if ( strcmp(cmd,"DCR_PD")== 0 ) {writeReg(VR_BASE+DCR_PD,invalue);return 0;}
//		if ( strcmp(cmd,"DCR_PD?")== 0 ) {*value_back = readReg(VR_BASE+DCR_PD);return 1;}
//
//		if ( strcmp(cmd,"FP_SLOPE")== 0 ) {writeReg(VR_BASE+FP_SLOPE,invalue);return 0;}
//		if ( strcmp(cmd,"FP_SLOPE?")== 0 ) {*value_back = readReg(VR_BASE+FP_SLOPE);return 1;}
//
//		if ( strcmp(cmd,"FP_OFFSET")== 0 ) {writeReg(VR_BASE+FP_OFFSET,invalue);return 0;}
//		if ( strcmp(cmd,"FP_OFFSET?")== 0 ) {*value_back = readReg(VR_BASE+FP_OFFSET);return 1;}
	 			
		if ( strcmp(cmd,"CONF_LOAD")== 0 ) {writeReg(VR_BASE+EEPROM_RD,0); return 0;}
		
		if ( strcmp(cmd,"MODULE_ID0")== 0 ) {writeReg(VR_BASE+MODULE_ID0,invalue);return 0;}
		if ( strcmp(cmd,"MODULE_ID0?")== 0 ) {*value_back = readReg(VR_BASE+MODULE_ID0);return 1;}
		
		if ( strcmp(cmd,"MODULE_ID1")== 0 ) {writeReg(VR_BASE+MODULE_ID1,invalue);return 0;}
		if ( strcmp(cmd,"MODULE_ID1?")== 0 ) {*value_back = readReg(VR_BASE+MODULE_ID1);return 1;}

		if ( strcmp(cmd,"FP_CH0_G")== 0 ) {
			writeReg(VR_BASE+FP_CH0_G,invalue_fp.ival);
			return 0;
			}
		if ( strcmp(cmd,"FP_CH0_G?")== 0 ) {
			 valueback_fp.ival = readReg(VR_BASE+FP_CH0_G);
			*value_back = (int) 100000*valueback_fp.fval;
			return 1;
			}		
		
		if ( strcmp(cmd,"FP_CH0_Z")== 0 ) {
			writeReg(VR_BASE+FP_CH0_Z,invalue_fp.ival);
			return 0;}
		if ( strcmp(cmd,"FP_CH0_Z?")== 0 ) {
			 valueback_fp.ival = readReg(VR_BASE+FP_CH0_Z);
			*value_back = (int) 100000*valueback_fp.fval;
			return 1;
			}			
		
		if ( strcmp(cmd,"FP_CH1_G")== 0 ) {
		    writeReg(VR_BASE+FP_CH1_G,invalue_fp.ival);
		    return 0;
		    }
		if ( strcmp(cmd,"FP_CH1_G?")== 0 ) {
			valueback_fp.ival = readReg(VR_BASE+FP_CH1_G);
			*value_back = (int) 100000*valueback_fp.fval;
			return 1;
			}			
		
		if ( strcmp(cmd,"FP_CH1_Z")== 0 ) {
		    writeReg(VR_BASE+FP_CH1_Z,invalue_fp.ival);
		    return 0;
		    }
		if ( strcmp(cmd,"FP_CH1_Z?")== 0 ) {
			 valueback_fp.ival = readReg(VR_BASE+FP_CH1_Z);
			*value_back = (int) 100000*valueback_fp.fval;
		    return 1;
		    }
		
    	printf("\n\r Error: Bad command %s \n\r", cmd);
		
		}

    return 0;

}