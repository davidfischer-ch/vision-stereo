NAME		SUSP
PUBLIC		EZUSB_SUSP

$include (fx2regs.inc)

EZUSB		segment	code

		rseg	EZUSB		
EZUSB_SUSP:	
        mov     dptr,#WAKEUPCS     ; TGE fx2bug - Clear the Wake Source bit(s) in
		movx	a,@dptr		     ; the WAKEUPCS register
		orl	    a,#0C0H           ; TGE fx2bug - clear PA2 and WPIN
		movx	@dptr,a

        mov     dptr,#SUSPEND    ; TGE fx2bug - new to FX2
        movx    @dptr,a          ; TGE fx2bug - write any walue to SUSPEND register

		orl	PCON,#00000001b	     ; Place the processor in idle

		nop			             ; Insert some meaningless instruction
		nop			             ; fetches to insure that the processor
		nop			             ; suspends and resumes before RET
		nop
		nop
er_end:		ret
		end
