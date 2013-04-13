@echo off
REM #--------------------------------------------------------------------------
REM #	File:		BUILD.BAT
REM #	Contents:	Batch file to build frameworks lib for EZUSB FX2
REM #
REM #	Copyright (c) 2000 Cypress Semiconductor, Inc. All rights reserved
REM #--------------------------------------------------------------------------

REM set EZTARGET=C:\Cypress\USB\Target
REM set C51INC=C:\Keil\C51\INC;%EZTARGET%\INC

REM ### Compile code ###
c51 resume.c debug oe code small moddp2 "ot(6,size)"
c51 discon.c debug oe code small moddp2 "ot(6,size)"
c51 delay.c debug oe code small moddp2 "ot(6,size)"
c51 ezregs.c debug oe code small moddp2 "ot(6,size)"
c51 i2c.c debug oe code small moddp2 "ot(6,size)"
c51 get_dscr.c debug oe code small moddp2 "ot(6,size)"
c51 get_infc.c debug oe code small moddp2 "ot(6,size)"
c51 get_strd.c debug oe code small moddp2 "ot(6,size)"
c51 get_cnfg.c debug oe code small moddp2 "ot(6,size)"
c51 i2c_rw.c debug oe code small moddp2 "ot(6,size)"


REM ### Assemble  ###
a51 delayms.a51 debug errorprint nomod51
a51 susp.a51 debug errorprint nomod51
a51 USBJmpTb.a51 debug errorprint nomod51
a51 stall.a51 debug errorprint nomod51

if exist ezusb.lib del ezusb.lib
lib51 create ezusb.lib
lib51 add resume.obj to ezusb.lib
lib51 add susp.obj to ezusb.lib
lib51 add stall.obj to ezusb.lib
lib51 add discon.obj to ezusb.lib
lib51 add delayms.obj to ezusb.lib
lib51 add delay.obj to ezusb.lib
lib51 add ezregs.obj to ezusb.lib
lib51 add i2c.obj to ezusb.lib
lib51 add get_dscr.obj to ezusb.lib
lib51 add get_infc.obj to ezusb.lib
lib51 add get_strd.obj to ezusb.lib
lib51 add get_cnfg.obj to ezusb.lib
lib51 add i2c_rw.obj to ezusb.lib

REM ### usage: build -clean to remove intermediate files after build
if "%1" == "-clean" del *.lst

:fini


