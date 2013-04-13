#include <fx2.h>
#include <fx2regs.h>


void EZUSB_Delay(WORD ms)
{

   //
   // Adjust the delay based on the CPU clock
   // EZUSB_Delay1ms() assumes a 24MHz clock
   //
   if ((CPUCS & bmCLKSPD) == 0)              // 12Mhz
      ms = (ms + 1) / 2;                     // Round up before dividing so we can accept 1.
   else if ((CPUCS & bmCLKSPD) == bmCLKSPD1)   // 48Mhz
      ms = ms * 2;

	while(ms--)
		EZUSB_Delay1ms();
}
