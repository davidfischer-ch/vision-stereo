#pragma NOIV               // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
// File:      bulksrc.c
// Contents:   Hooks required to implement USB peripheral function.
//
// $Archive: /USB/Examples/Fx2/bulksrc/bulksrc.c $
// $Date: 11/10/01 11:41a $
// $Revision: 9 $
//
//   Copyright (c) 2000 Cypress Semiconductor All rights reserved
//-----------------------------------------------------------------------------
#include "fx2.h"
#include "fx2regs.h"
#include "fx2sdly.h"            // SYNCDELAY macro

extern BOOL GotSUD;             // Received setup data flag
extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

BYTE Configuration;             // Current configuration
BYTE AlternateSetting;          // Alternate settings
BYTE xdata myBuffer[512];

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------

void TD_Init(void)              // Called once at startup
{
  
  int i;
  REVCTL    = 0x03; 
  SYNCDELAY;
  // set the CPU clock to 48MHz
  CPUCS = ((CPUCS & ~bmCLKSPD) | bmCLKSPD1) ;
  //CPUCS = 0x02  ; //15-13

  // set the slave FIFO interface to 48MHz
  IFCONFIG |= 0xE3; // 1110 0011 clk interne //0x43,clk externe, slave fifo synchrone 13-10
  
  SYNCDELAY; 
  FIFORESET = 0x80;
  SYNCDELAY;            
  FIFORESET = 0x02;
  SYNCDELAY;  // see TRM section 15.14
  FIFORESET = 0x04;
  SYNCDELAY;  
  FIFORESET = 0x06;
  SYNCDELAY;  
  FIFORESET = 0x08;
  SYNCDELAY;               
  FIFORESET = 0x00;
  SYNCDELAY;      

  EP2FIFOCFG = 0x4D; // 0100 1101  bit 7->0 : Infm1 = 0, Oep1 = 0, Auto-Out = 0, Auto-In = 1 ,  Zerolenin = 1, bit 1->0, Wordwide = 1 , 
  SYNCDELAY;        // anticipe mise à jour status fifo plein et 16 bit de large	
  EP2CFG = 0xE2;   // 1010 0010 : bit 7->0 : Valid(1), Direction(1=in), Bulk(10), Size: 0 = 512 bytes, bit 2 = 0, double(1 0) 
  SYNCDELAY;  
                 
  EP4CFG = 0xA0; // 1010 0000 : bit 7->0 : Valid(1), Direction(0=out), Bulk(1 0), Size: 0 = 512 bytes, bit 2 = 0,  double(1 0)  
  SYNCDELAY;   
               
  EP6CFG = 0xE2; // 1010 0010 : bit 7->0 : Valid(1), Direction(1=in), Bulk(1 0), Size: 0 = 512 bytes, bit 2 = 0,  quad(1 0)  
  SYNCDELAY;   
 
  EP8CFG = 0xE0;
  SYNCDELAY; 

  PINFLAGSAB = 0x00; //page 15-19
  SYNCDELAY; 
  PINFLAGSCD = 0x00; //page 15-18
  SYNCDELAY; 


  PORTACFG     = 0X00;
  FIFOPINPOLAR = 0X00;

  SYNCDELAY;
  EP2AUTOINLENH = 0x02;//mode AUTOIN avec AUTOINLENGTH = 512 Avec ce mode, il n'est pas nécessaire de 'commiter' chaque paquet USB de 512 octets. 
                       //Dès que 512 octets ont été stockés dans les buffers de l'endpoint 2,  sans intervention du CPU du FX2   
                       // un paquet USB est automatiquement 'commité'	     
  SYNCDELAY;
  EP2AUTOINLENL = 0x00;

  SYNCDELAY;
  EP2FIFOPFH = 0x82;
  SYNCDELAY;
  EP2FIFOPFL = 0x00;
  
  // since the defaults are double buffered we must write dummy byte counts twice
  // arm EP4OUT by writing byte count w/skip.
  SYNCDELAY;                    
  EP4BCL = 0x80;    
  SYNCDELAY;                   
  EP4BCL = 0x80; 
  SYNCDELAY; 
                    
 
 for (i=0;i<1024;i++){
  EP2FIFOBUF[i] = 0x00 ;
  SYNCDELAY; 
 } 
  SYNCDELAY;// 
  EP2BCH = 0x02;
  SYNCDELAY;                    // 
  EP2BCL = 0x00;

 

  // enable dual autopointer(s)
  AUTOPTRSETUP |= 0x01;  

  Rwuen = TRUE;                 // Enable remote-wakeup
}

void TD_Poll(void)              // Called repeatedly while the device is idle
{

   // if EP2 IN is available, re-arm it
  /*  if(!(EP2468STAT & bmEP2FULL))
   {
      SYNCDELAY;                // 
      EP2BCH = 0x02;
      SYNCDELAY;                // 
      EP2BCL = 0x00;
   }
 */

}

BOOL TD_Suspend(void)          // Called before the device goes into suspend mode
{
   return(TRUE);
}

BOOL TD_Resume(void)          // Called after the device resumes
{
   return(TRUE);
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------

BOOL DR_GetDescriptor(void)
{
   return(TRUE);
}

BOOL DR_SetConfiguration(void)   // Called when a Set Configuration command is received
{
   Configuration = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetConfiguration(void)   // Called when a Get Configuration command is received
{
   EP0BUF[0] = Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_SetInterface(void)       // Called when a Set Interface command is received
{
   AlternateSetting = SETUPDAT[2];
   return(TRUE);            // Handled by user code
}

BOOL DR_GetInterface(void)       // Called when a Set Interface command is received
{
   EP0BUF[0] = AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);            // Handled by user code
}

BOOL DR_GetStatus(void)
{
   return(TRUE);
}

BOOL DR_ClearFeature(void)
{
   return(TRUE);
}

BOOL DR_SetFeature(void)
{
   return(TRUE);
}

BOOL DR_VendorCmnd(void)
{
   return(TRUE);
}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav(void) interrupt 0
{
   GotSUD = TRUE;            // Set flag
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUDAV;         // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUTOK;         // Clear SUTOK IRQ
}

void ISR_Sof(void) interrupt 0
{
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSOF;            // Clear SOF IRQ
}

void ISR_Ures(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
   }
   
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmURES;         // Clear URES IRQ
}

void ISR_Susp(void) interrupt 0
{
   Sleep = TRUE;
   EZUSB_IRQ_CLEAR();
   USBIRQ = bmSUSP;
}

void ISR_Highspeed(void) interrupt 0
{
   if (EZUSB_HIGHSPEED())
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
   }

   EZUSB_IRQ_CLEAR();
   USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack(void) interrupt 0
{
}
void ISR_Stub(void) interrupt 0
{
}
void ISR_Ep0in(void) interrupt 0
{
}
void ISR_Ep0out(void) interrupt 0
{
}
void ISR_Ep1in(void) interrupt 0
{
}
void ISR_Ep1out(void) interrupt 0
{
}
void ISR_Ep2inout(void) interrupt 0
{
}
void ISR_Ep4inout(void) interrupt 0
{
}
void ISR_Ep6inout(void) interrupt 0
{
}
void ISR_Ep8inout(void) interrupt 0
{
}
void ISR_Ibn(void) interrupt 0
{
}
void ISR_Ep0pingnak(void) interrupt 0
{
}
void ISR_Ep1pingnak(void) interrupt 0
{
}
void ISR_Ep2pingnak(void) interrupt 0
{
}
void ISR_Ep4pingnak(void) interrupt 0
{
}
void ISR_Ep6pingnak(void) interrupt 0
{
}
void ISR_Ep8pingnak(void) interrupt 0
{
}
void ISR_Errorlimit(void) interrupt 0
{
}
void ISR_Ep2piderror(void) interrupt 0
{
}
void ISR_Ep4piderror(void) interrupt 0
{
}
void ISR_Ep6piderror(void) interrupt 0
{
}
void ISR_Ep8piderror(void) interrupt 0
{
}
void ISR_Ep2pflag(void) interrupt 0
{
}
void ISR_Ep4pflag(void) interrupt 0
{
}
void ISR_Ep6pflag(void) interrupt 0
{
}
void ISR_Ep8pflag(void) interrupt 0
{
}
void ISR_Ep2eflag(void) interrupt 0
{
}
void ISR_Ep4eflag(void) interrupt 0
{
}
void ISR_Ep6eflag(void) interrupt 0
{
}
void ISR_Ep8eflag(void) interrupt 0
{
}
void ISR_Ep2fflag(void) interrupt 0
{
}
void ISR_Ep4fflag(void) interrupt 0
{
}
void ISR_Ep6fflag(void) interrupt 0
{
}
void ISR_Ep8fflag(void) interrupt 0
{
}
void ISR_GpifComplete(void) interrupt 0
{
}
void ISR_GpifWaveform(void) interrupt 0
{
}
