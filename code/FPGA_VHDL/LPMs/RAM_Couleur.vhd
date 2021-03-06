-- megafunction wizard: %RAM: 2-PORT%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altsyncram 

-- ============================================================
-- File Name: RAM_Couleur.vhd
-- Megafunction Name(s):
-- 			altsyncram
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 6.0 Build 202 06/20/2006 SP 1 SJ Web Edition
-- ************************************************************


--Copyright (C) 1991-2006 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

ENTITY RAM_Couleur IS
	GENERIC (TailleMots : natural := 256;
			 TailleBits : natural := 8);
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (TailleBits-1 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (TailleBits-1 DOWNTO 0);
		wren		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END RAM_Couleur;


ARCHITECTURE SYN OF ram_couleur IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (15 DOWNTO 0);



	COMPONENT altsyncram
	GENERIC (
		address_aclr_a		: STRING;
		address_aclr_b		: STRING;
		address_reg_b		: STRING;
		indata_aclr_a		: STRING;
		intended_device_family		: STRING;
		lpm_type		: STRING;
		numwords_a		: NATURAL;
		numwords_b		: NATURAL;
		operation_mode		: STRING;
		outdata_aclr_b		: STRING;
		outdata_reg_b		: STRING;
		power_up_uninitialized		: STRING;
		ram_block_type		: STRING;
		read_during_write_mode_mixed_ports		: STRING;
		widthad_a		: NATURAL;
		widthad_b		: NATURAL;
		width_a		: NATURAL;
		width_b		: NATURAL;
		width_byteena_a		: NATURAL;
		wrcontrol_aclr_a		: STRING
	);
	PORT (
			wren_a	: IN STD_LOGIC ;
			aclr0	: IN STD_LOGIC ;
			clock0	: IN STD_LOGIC ;
			address_a	: IN STD_LOGIC_VECTOR (TailleBits-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (TailleBits-1 DOWNTO 0);
			q_b	: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
			data_a	: IN STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	q    <= sub_wire0(15 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_aclr_a => "CLEAR0",
		address_aclr_b => "CLEAR0",
		address_reg_b => "CLOCK0",
		indata_aclr_a => "CLEAR0",
		intended_device_family => "Cyclone",
		lpm_type => "altsyncram",
		numwords_a => TailleMots,--256,
		numwords_b => TailleMots,--256,
		operation_mode => "DUAL_PORT",
		outdata_aclr_b => "CLEAR0",
		outdata_reg_b => "CLOCK0",
		power_up_uninitialized => "FALSE",
		ram_block_type => "M4K",
		read_during_write_mode_mixed_ports => "DONT_CARE",
		widthad_a => TailleBits,--8,
		widthad_b => TailleBits,--8,
		width_a => 16,
		width_b => 16,
		width_byteena_a => 1,
		wrcontrol_aclr_a => "CLEAR0"
	)
	PORT MAP (
		wren_a => wren,
		aclr0 => aclr,
		clock0 => clock,
		address_a => wraddress,
		address_b => rdaddress,
		data_a => data,
		q_b => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
-- Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
-- Retrieval info: PRIVATE: BYTEENA_ACLR_A NUMERIC "0"
-- Retrieval info: PRIVATE: BYTEENA_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_ENABLE_A NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_ENABLE_B NUMERIC "0"
-- Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
-- Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
-- Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
-- Retrieval info: PRIVATE: CLRdata NUMERIC "1"
-- Retrieval info: PRIVATE: CLRq NUMERIC "1"
-- Retrieval info: PRIVATE: CLRrdaddress NUMERIC "1"
-- Retrieval info: PRIVATE: CLRrren NUMERIC "0"
-- Retrieval info: PRIVATE: CLRwraddress NUMERIC "1"
-- Retrieval info: PRIVATE: CLRwren NUMERIC "1"
-- Retrieval info: PRIVATE: Clock NUMERIC "0"
-- Retrieval info: PRIVATE: Clock_A NUMERIC "0"
-- Retrieval info: PRIVATE: Clock_B NUMERIC "0"
-- Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
-- Retrieval info: PRIVATE: INDATA_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: INDATA_REG_B NUMERIC "0"
-- Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
-- Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone"
-- Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
-- Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
-- Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
-- Retrieval info: PRIVATE: MEMSIZE NUMERIC "4096"
-- Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "0"
-- Retrieval info: PRIVATE: MIFfilename STRING ""
-- Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
-- Retrieval info: PRIVATE: OUTDATA_ACLR_B NUMERIC "1"
-- Retrieval info: PRIVATE: OUTDATA_REG_B NUMERIC "1"
-- Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "2"
-- Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
-- Retrieval info: PRIVATE: REGdata NUMERIC "1"
-- Retrieval info: PRIVATE: REGq NUMERIC "1"
-- Retrieval info: PRIVATE: REGrdaddress NUMERIC "1"
-- Retrieval info: PRIVATE: REGrren NUMERIC "1"
-- Retrieval info: PRIVATE: REGwraddress NUMERIC "1"
-- Retrieval info: PRIVATE: REGwren NUMERIC "1"
-- Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
-- Retrieval info: PRIVATE: VarWidth NUMERIC "0"
-- Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "16"
-- Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "16"
-- Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "16"
-- Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "16"
-- Retrieval info: PRIVATE: WRADDR_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: WRADDR_REG_B NUMERIC "0"
-- Retrieval info: PRIVATE: WRCTRL_ACLR_B NUMERIC "0"
-- Retrieval info: PRIVATE: enable NUMERIC "0"
-- Retrieval info: PRIVATE: rden NUMERIC "0"
-- Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "CLEAR0"
-- Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "CLEAR0"
-- Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: INDATA_ACLR_A STRING "CLEAR0"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
-- Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
-- Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
-- Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
-- Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "CLEAR0"
-- Retrieval info: CONSTANT: OUTDATA_REG_B STRING "CLOCK0"
-- Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
-- Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "M4K"
-- Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
-- Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
-- Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
-- Retrieval info: CONSTANT: WIDTH_A NUMERIC "16"
-- Retrieval info: CONSTANT: WIDTH_B NUMERIC "16"
-- Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
-- Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "CLEAR0"
-- Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT GND aclr
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: data 0 0 16 0 INPUT NODEFVAL data[15..0]
-- Retrieval info: USED_PORT: q 0 0 16 0 OUTPUT NODEFVAL q[15..0]
-- Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
-- Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
-- Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
-- Retrieval info: CONNECT: @data_a 0 0 16 0 data 0 0 16 0
-- Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
-- Retrieval info: CONNECT: q 0 0 16 0 @q_b 0 0 16 0
-- Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
-- Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
-- Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: @aclr0 0 0 0 0 aclr 0 0 0 0
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL RAM_Couleur.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL RAM_Couleur.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL RAM_Couleur.cmp FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL RAM_Couleur.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL RAM_Couleur_inst.vhd FALSE
