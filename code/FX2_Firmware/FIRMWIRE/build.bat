@echo off
REM #--------------------------------------------------------------------------
REM #	File:		BUILD.BAT
REM #	Contents:	Batch file to build EZ-USB FX2 firmware frameworks.
REM #
REM #	Copyright (c) 2000 Cypress Semiconductor All rights reserved
REM #--------------------------------------------------------------------------

REM # command line switches
REM # ---------------------
REM # -clean delete temporary files
REM # -i     Locate code in internal RAM.  Also builds EEPROM images.  Requires full
REM #        version of Keil Tools

REM ### Compile FrameWorks code ###
c51 fw.c debug objectextend code small moddp2

REM ### Compile user peripheral code ###
REM ### Note: This code does not generate interrupt vectors ###
c51 bulksrc.c db oe code small moddp2 noiv

REM ### Assemble descriptor table ###
a51 dscr.a51 errorprint debug

REM ### Link object code (includes debug info) ###
REM ### Note: XDATA and CODE must not overlap ###
REM ### Note: using a response file here for line longer than 128 chars
echo fw.obj, dscr.obj, bulksrc.obj, > tmp.rsp
echo %CYUSB%\target\lib\FX2\USBJmpTb.obj, >> tmp.rsp
echo %CYUSB%\target\lib\FX2\EZUSB.lib  >> tmp.rsp
if "%1" == "-i" echo TO bulksrc RAMSIZE(256) PL(68) PW(78) CODE(80h) XDATA(1900h)  >> tmp.rsp
if not "%1" == "-i" echo TO bulksrc RAMSIZE(256) PL(68) PW(78) CODE(4000h) XDATA(5900h)  >> tmp.rsp
bl51 @tmp.rsp

REM ### Generate intel hex image of binary (no debug info) ###
oh51 bulksrc HEXFILE(bulksrc.hex)

REM ### Generate serial eeprom image for C2 (EZ-USB FX2)bootload ###
if "%1" == "-i" %CYUSB%\bin\hex2bix -i -f 0xC2 -o bulksrc.iic bulksrc.hex

echo WARNING: Frameworks must relocate descriptors to internal mem with 4K Compiler.

REM ### usage: build -clean to remove intermediate files after build
if "%1" == "-clean" del tmp.rsp
if "%1" == "-clean" del *.lst
if "%1" == "-clean" del *.obj
if "%1" == "-clean" del *.m51

