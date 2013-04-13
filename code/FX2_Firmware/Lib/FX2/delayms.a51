NAME		DELAY1MS
PUBLIC		EZUSB_DELAY1MS

$include (fx2regs.inc)

EZUSB		segment	code

		rseg	EZUSB		
EZUSB_DELAY1MS:
; Delay for 1 millisecond (1000 microseconds).
; 10 cycles * 166.6 ns per cycle is 1.66 microseconds per loop.
; 1000 microseconds / 1.66 = 602.  [assumes 24 MHz clock]
;		
		mov	a, #0			; Clear dps so that we're using dph and dpl!	
		mov	dps, a			; 
		mov	dptr,#(0ffffH - 602) 	; long pulse for operating
		mov	r4,#5

loop:	     	inc     dptr            ; 3 cycles
		mov     a,dpl           ; 2 cycles
                orl     a,dph           ; 2 cycles
                jnz     loop		; 3 cycles
;
er_end:		ret
		end
