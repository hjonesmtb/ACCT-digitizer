/* Target Protect Project*/

// function: Create a socket server. Dump the received message from the client and loopack the message to client.
// usage: TPServer PortNum, PortNum is a interger larger than 2000.)

// Mods histories:
// Oct.10,2018, SL: created from the DE10 Nano TCP socket demo example



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>

//#include <pthread.h>


#include "main.h"




void error_exit(const char *msg)
{
    perror(msg);
    exit(1);
}

int cmd_proc(char *cmdString_in , int *value_back, char **string_back, int **array_Ptr, int *array_Dim);
void Load_Conf();


void* VR_BASE;
char cmdString[256];


int main(int argc, char* argv[])
{
    if (argc < 2) {
         fprintf(stderr,"ERROR, no port provided\n");
         fprintf(stderr,"Usage: TPServer portnum\n");
         exit(1);
     }
     
    // Mappming address of the FPGA registers/fifo to user space
  	
	int fd;
	
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		error_exit("open \"/dev/mem\"");
        
	}

	VR_BASE = mmap( NULL, HW_REGS_SPAN,( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );
	
	if( VR_BASE == MAP_FAILED ) {
    	close( fd );
		error_exit("mmap");	       
	}

    
                          
    
     int sockfd, newsockfd, portno;
     socklen_t clilen;
     
     struct sockaddr_in serv_addr, cli_addr;
          
     sockfd = socket(AF_INET, SOCK_STREAM, 0);
     if (sockfd < 0) 
        error_exit("ERROR opening socket"); 
     
     bzero((char *) &serv_addr, sizeof(serv_addr));
     portno = atoi(argv[1]);
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = INADDR_ANY;
     serv_addr.sin_port = htons(portno);
     
     if (bind(sockfd, (struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) 
        error_exit("ERROR on binding");
     
     listen(sockfd,5); //non-blocking, return immediatly
     clilen = sizeof(cli_addr);
     
     int n,value, sendTrue, strLength;
     int *array_Ptr,array_Dim;
     int array_Index;
	 char valueString[50],arrayString[STRING_MAX_LENGTH];
	 char *string_back;
	 //char arrayString[STRING_MAX_LENGTH];
	 
	 //load configration from eeprom
	 Load_Conf();
         
       
     while(1) {
        printf("Accepting for connection request...\n");    
        newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen); //blocking until received a connection request
        if (newsockfd < 0) error_exit("ERROR on accept");
     
        printf("TCP Socket Connection Established!\n"); 
        
        //*(uint32_t*) (VR_BASE+CR) = 1;   
       
        while(1) {
            
            bzero(cmdString,256);
            n=read(newsockfd,cmdString,255);
            if ( n <= 0) {perror("connection closed by client"); break; }
            else printf("Received message: %s, n=%d \n",cmdString,n);
            
            sendTrue = cmd_proc(cmdString,&value, &string_back, &array_Ptr, &array_Dim);  	 /* process the command */
              
            if (sendTrue != 0 ){
		        if (sendTrue == 1){
			        sprintf(valueString,"%d\r\n",value);
			        strLength = strlen(valueString);
			        printf("value readback from FPGA = %d \n",value);
			        if ( write(newsockfd,valueString,strLength) < 0) //Send to client
			            {perror("ERROR writing to client"); break; }
		        }   
		        if (sendTrue == 3){
			        arrayString[0]= '\0';
			        for (array_Index=0; array_Index<array_Dim; array_Index++) {
				        if(array_Index == array_Dim - 1)
					        sprintf(valueString,"%d\r\n",*(array_Ptr +array_Index)); 
					        //the termination chars changed from \n\r to \r\n, due to Labview TCP_read requires so, SL, 2018_0531
				        else  sprintf(valueString,"%d,",*(array_Ptr +array_Index));
				        if ( (strLength = strlen(arrayString)) < (STRING_MAX_LENGTH - strlen(valueString)) )
					        strcat(arrayString, valueString);
				        else printf("Main.c: data is too long for the output string \n\r");
			        }
			        strLength = strlen(arrayString);
    			    if (write(newsockfd, arrayString, strLength) < 0)	
				        {perror("ERROR writing to client"); break; }
				    else printf("FIFO transfer successfully string length = %d \n\r",strLength);    
			    }
            }
            
            
             
            if ( write(newsockfd,"0",1) < 0) //ack to client
			            {perror("ERROR writing to client"); break; }
            
           
        
                
        } //new connection      
        
        close(newsockfd); 
         
     } //waitting for connection request
 

close(sockfd);
return 0; 

     

}
//this is the awake bpm write format: 
 //com+' '+str(data)+'\r\n'   
//Disable FIFO Interrupts
//    writeReg(fifo_csr_addr, 3, 0x00000000);
     