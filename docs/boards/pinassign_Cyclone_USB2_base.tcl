###############################################################################
#
# pin.tcl
#
# Cible    : USB2 - Cyclone
# Autheur  : Geoffrey Wisner 
# Revision : 0.0 GW version de base
# Date     : 23.08.2004
# 
# Règle de syntaxe : GROUPE_NOM[bit]
#
# GROUPE : spécifie un interface particulier (ex: SDR_)
# NOM    : nom du signal (ex: CONFIG, D, ...)
# bit    : indice du signal( en tcl, mettre \[  et \]  pour [  ] )
#
###############################################################################

# set top entity name
set project_name clk-test
set top_name clk-test

if { ![project exists ./$project_name] } {
	project create ./$project_name
}
# project open ./$project_name

set cmp_settings_group $top_name
if { ![project cmp_exists $cmp_settings_group] } {
        project create_cmp $top_name
}
project set_active_cmp $top_name

cmp add_assignment $top_name "" "" DEVICE EP1C12F256C8


##############################
# JTAG
##############################

# cmp add_assignment $top_name "" TCK LOCATION "Pin_J14"
# cmp add_assignment $top_name "" TDI LOCATION "Pin_H14"
# cmp add_assignment $top_name "" TDO LOCATION "Pin_H15"
# cmp add_assignment $top_name "" TMS LOCATION "Pin_J15"


##############################
# Bus config.
##############################

# cmp add_assignment $top_name "" MSEL0 LOCATION "Pin_J3"
# cmp add_assignment $top_name "" MSEL1 LOCATION "Pin_J2"
# cmp add_assignment $top_name "" DCLK LOCATION "Pin_K4"
# cmp add_assignment $top_name "" NCONFIG LOCATION "Pin_H3"
# cmp add_assignment $top_name "" NSTATUS LOCATION "Pin_J13"
# cmp add_assignment $top_name "" CONF_DONE LOCATION "Pin_K13"
# cmp add_assignment $top_name "" NCE LOCATION "Pin_J4"
# cmp add_assignment $top_name "" NCEO LOCATION "Pin_H4"
# cmp add_assignment $top_name "" DATA0 LOCATION "Pin_H2"
cmp add_assignment $top_name "" INIT_DONE LOCATION "Pin_D4"
cmp add_assignment $top_name "" CLKUSR LOCATION "Pin_C2"
cmp add_assignment $top_name "" NCSO LOCATION "Pin_G4"
cmp add_assignment $top_name "" ASDO LOCATION "Pin_K3" 


##############################
# Horloges
##############################

cmp add_assignment $top_name "" FPGA_CLK LOCATION "Pin_H1"
#cmp add_assignment $top_name "" FPGA_CLK LOCATION "Pin_H16"
cmp add_assignment $top_name "" CLKOUT4 LOCATION "Pin_G1"
cmp add_assignment $top_name "" CLKOUT5 LOCATION "Pin_G16"


##############################
# LEDs + poussoirs
##############################

cmp add_assignment $top_name "" LED1N LOCATION "Pin_L4"
cmp add_assignment $top_name "" LED2N LOCATION "Pin_K2"

cmp add_assignment $top_name "" SW1N LOCATION "Pin_B2"
cmp add_assignment $top_name "" SW2N LOCATION "Pin_A2"


##############################
# Bus 8051
##############################

cmp add_assignment $top_name "" FX2_CSN LOCATION "Pin_B5"
cmp add_assignment $top_name "" FX2_WRN LOCATION "Pin_A4"
cmp add_assignment $top_name "" FX2_RDN LOCATION "Pin_B4"
cmp add_assignment $top_name "" FX2_OEN LOCATION "Pin_B3"
cmp add_assignment $top_name "" FX2_PSENN LOCATION "Pin_C4"

cmp add_assignment $top_name "" FX2_A\[0\] LOCATION "Pin_B7"
cmp add_assignment $top_name "" FX2_A\[1\] LOCATION "Pin_C7"
cmp add_assignment $top_name "" FX2_A\[2\] LOCATION "Pin_D7"
cmp add_assignment $top_name "" FX2_A\[3\] LOCATION "Pin_B8"
cmp add_assignment $top_name "" FX2_A\[4\] LOCATION "Pin_A8"
cmp add_assignment $top_name "" FX2_A\[5\] LOCATION "Pin_E8"
cmp add_assignment $top_name "" FX2_A\[6\] LOCATION "Pin_D8"
cmp add_assignment $top_name "" FX2_A\[7\] LOCATION "Pin_C8"
cmp add_assignment $top_name "" FX2_A\[8\] LOCATION "Pin_E10"
cmp add_assignment $top_name "" FX2_A\[9\] LOCATION "Pin_C9"
cmp add_assignment $top_name "" FX2_A\[10\] LOCATION "Pin_D9"
cmp add_assignment $top_name "" FX2_A\[11\] LOCATION "Pin_B9"
cmp add_assignment $top_name "" FX2_A\[12\] LOCATION "Pin_A9"
cmp add_assignment $top_name "" FX2_A\[13\] LOCATION "Pin_D10"
cmp add_assignment $top_name "" FX2_A\[14\] LOCATION "Pin_C10"
cmp add_assignment $top_name "" FX2_A\[15\] LOCATION "Pin_B10"

cmp add_assignment $top_name "" FX2_D\[0\] LOCATION "Pin_C5"
cmp add_assignment $top_name "" FX2_D\[1\] LOCATION "Pin_E6"
cmp add_assignment $top_name "" FX2_D\[2\] LOCATION "Pin_D5"
cmp add_assignment $top_name "" FX2_D\[3\] LOCATION "Pin_D6"
cmp add_assignment $top_name "" FX2_D\[4\] LOCATION "Pin_C6"
cmp add_assignment $top_name "" FX2_D\[5\] LOCATION "Pin_B6"
cmp add_assignment $top_name "" FX2_D\[6\] LOCATION "Pin_E7"
cmp add_assignment $top_name "" FX2_D\[7\] LOCATION "Pin_A6"


##############################
# GPIF/FIFO
##############################

cmp add_assignment $top_name "" FX2_IFCLK LOCATION "Pin_F5"
cmp add_assignment $top_name "" PLL1_OUT LOCATION "Pin_J1"

cmp add_assignment $top_name "" FX2_SLRD LOCATION "Pin_M1"
cmp add_assignment $top_name "" FX2_SLWR LOCATION "Pin_N1"
cmp add_assignment $top_name "" FX2_SLOE LOCATION "Pin_L2"

#cmp add_assignment $top_name "" FX2_FLAGA LOCATION "Pin_M3"
#cmp add_assignment $top_name "" FX2_FLAGB LOCATION "Pin_N2"
#cmp add_assignment $top_name "" FX2_FLAGC LOCATION "Pin_L3"
#cmp add_assignment $top_name "" FX2_FLAGD LOCATION "Pin_H5"
cmp add_assignment $top_name "" FX2_FLAG\[0\] LOCATION "Pin_M3"
cmp add_assignment $top_name "" FX2_FLAG\[1\] LOCATION "Pin_N2"
cmp add_assignment $top_name "" FX2_FLAG\[2\] LOCATION "Pin_L3"
cmp add_assignment $top_name "" FX2_FLAG\[3\] LOCATION "Pin_H5"

cmp add_assignment $top_name "" FX2_FIFOADR\[0\] LOCATION "Pin_L1"
cmp add_assignment $top_name "" FX2_FIFOADR\[1\] LOCATION "Pin_K1"
cmp add_assignment $top_name "" FX2_PKTEND LOCATION "Pin_M2"

cmp add_assignment $top_name "" FX2_FD\[0\] LOCATION "Pin_F1"
cmp add_assignment $top_name "" FX2_FD\[1\] LOCATION "Pin_G2"
cmp add_assignment $top_name "" FX2_FD\[2\] LOCATION "Pin_E1"
cmp add_assignment $top_name "" FX2_FD\[3\] LOCATION "Pin_F2"
cmp add_assignment $top_name "" FX2_FD\[4\] LOCATION "Pin_G3"
cmp add_assignment $top_name "" FX2_FD\[5\] LOCATION "Pin_F3"
cmp add_assignment $top_name "" FX2_FD\[6\] LOCATION "Pin_D1"
cmp add_assignment $top_name "" FX2_FD\[7\] LOCATION "Pin_E2"
cmp add_assignment $top_name "" FX2_FD\[8\] LOCATION "Pin_D2"
cmp add_assignment $top_name "" FX2_FD\[9\] LOCATION "Pin_E3"
cmp add_assignment $top_name "" FX2_FD\[10\] LOCATION "Pin_E4"
cmp add_assignment $top_name "" FX2_FD\[11\] LOCATION "Pin_D3"
cmp add_assignment $top_name "" FX2_FD\[12\] LOCATION "Pin_F4"
cmp add_assignment $top_name "" FX2_FD\[13\] LOCATION "Pin_G5"
cmp add_assignment $top_name "" FX2_FD\[14\] LOCATION "Pin_B1"
cmp add_assignment $top_name "" FX2_FD\[15\] LOCATION "Pin_C3"


##############################
# I2C
##############################

cmp add_assignment $top_name "" I2C_SCL LOCATION "Pin_L5"
cmp add_assignment $top_name "" I2C_SDA LOCATION "Pin_K5"


##############################
# Intercon. diverses avec FX2
##############################

cmp add_assignment $top_name "" FX2_RESETN LOCATION "Pin_N4"
cmp add_assignment $top_name "" FX2_BKPT LOCATION "Pin_P2"
cmp add_assignment $top_name "" FX2_WAKEUPN LOCATION "Pin_P3"
cmp add_assignment $top_name "" FX2_T2OUT LOCATION "Pin_E5"
cmp add_assignment $top_name "" FX2_T2IN LOCATION "Pin_E12"
cmp add_assignment $top_name "" FX2_INT4 LOCATION "Pin_M4"


##############################
# Connecteurs ext.
##############################

cmp add_assignment $top_name "" EXT_IOE LOCATION "Pin_N3"


# Connecteur ext. #1

cmp add_assignment $top_name "" EXT_CLK1 LOCATION "Pin_M5"
cmp add_assignment $top_name "" EXT_CTL1 LOCATION "Pin_R10"

cmp add_assignment $top_name "" EXT_IO\[0\] LOCATION "Pin_R9"
cmp add_assignment $top_name "" EXT_IO\[1\] LOCATION "Pin_T9"
cmp add_assignment $top_name "" EXT_IO\[2\] LOCATION "Pin_P9"
cmp add_assignment $top_name "" EXT_IO\[3\] LOCATION "Pin_N9"
cmp add_assignment $top_name "" EXT_IO\[4\] LOCATION "Pin_M9"
cmp add_assignment $top_name "" EXT_IO\[5\] LOCATION "Pin_R8"
cmp add_assignment $top_name "" EXT_IO\[6\] LOCATION "Pin_T8"
cmp add_assignment $top_name "" EXT_IO\[7\] LOCATION "Pin_N8"
cmp add_assignment $top_name "" EXT_IO\[8\] LOCATION "Pin_P8"
cmp add_assignment $top_name "" EXT_IO\[9\] LOCATION "Pin_M8"
cmp add_assignment $top_name "" EXT_IO\[10\] LOCATION "Pin_N7"
cmp add_assignment $top_name "" EXT_IO\[11\] LOCATION "Pin_P7"
cmp add_assignment $top_name "" EXT_IO\[12\] LOCATION "Pin_R7"
cmp add_assignment $top_name "" EXT_IO\[13\] LOCATION "Pin_R6"
cmp add_assignment $top_name "" EXT_IO\[14\] LOCATION "Pin_T6"
cmp add_assignment $top_name "" EXT_IO\[15\] LOCATION "Pin_P6"


# Connecteur ext. #2

cmp add_assignment $top_name "" EXT_CLK2 LOCATION "Pin_M12"
cmp add_assignment $top_name "" EXT_CTL2 LOCATION "Pin_M10"

cmp add_assignment $top_name "" EXT_IO\[16\] LOCATION "Pin_P10"
cmp add_assignment $top_name "" EXT_IO\[17\] LOCATION "Pin_R15"
cmp add_assignment $top_name "" EXT_IO\[18\] LOCATION "Pin_N11"
cmp add_assignment $top_name "" EXT_IO\[19\] LOCATION "Pin_T13"
cmp add_assignment $top_name "" EXT_IO\[20\] LOCATION "Pin_R11"
cmp add_assignment $top_name "" EXT_IO\[21\] LOCATION "Pin_P13"
cmp add_assignment $top_name "" EXT_IO\[22\] LOCATION "Pin_N12"
cmp add_assignment $top_name "" EXT_IO\[23\] LOCATION "Pin_P12"
cmp add_assignment $top_name "" EXT_IO\[24\] LOCATION "Pin_R12"
cmp add_assignment $top_name "" EXT_IO\[25\] LOCATION "Pin_T11"
cmp add_assignment $top_name "" EXT_IO\[26\] LOCATION "Pin_R13"
cmp add_assignment $top_name "" EXT_IO\[27\] LOCATION "Pin_P11"
cmp add_assignment $top_name "" EXT_IO\[28\] LOCATION "Pin_R14"
cmp add_assignment $top_name "" EXT_IO\[29\] LOCATION "Pin_M11"
cmp add_assignment $top_name "" EXT_IO\[30\] LOCATION "Pin_T15"
cmp add_assignment $top_name "" EXT_IO\[31\] LOCATION "Pin_N10"


# Connecteur ext. #3
# Partage les IOs 0 => 31 avec les connecteurs ext. #1 et #2

cmp add_assignment $top_name "" EXT_OE LOCATION "Pin_A2"
cmp add_assignment $top_name "" EXT_CLRN LOCATION "Pin_B2"

cmp add_assignment $top_name "" EXT_IO\[32\] LOCATION "Pin_N5"
cmp add_assignment $top_name "" EXT_IO\[33\] LOCATION "Pin_M6"
cmp add_assignment $top_name "" EXT_IO\[34\] LOCATION "Pin_N6"
cmp add_assignment $top_name "" EXT_IO\[35\] LOCATION "Pin_R5"
cmp add_assignment $top_name "" EXT_IO\[36\] LOCATION "Pin_P5"
cmp add_assignment $top_name "" EXT_IO\[37\] LOCATION "Pin_M7"
cmp add_assignment $top_name "" EXT_IO\[38\] LOCATION "Pin_R4"
cmp add_assignment $top_name "" EXT_IO\[39\] LOCATION "Pin_T4"


##############################
# UART #0 + #1
##############################

cmp add_assignment $top_name "" EXT_RXD0 LOCATION "Pin_T2"
cmp add_assignment $top_name "" EXT_TXD0 LOCATION "Pin_R2"

cmp add_assignment $top_name "" EXT_RXD1 LOCATION "Pin_R3"
cmp add_assignment $top_name "" EXT_TXD1 LOCATION "Pin_P4"


##############################
# SDRAM
##############################

cmp add_assignment $top_name "" SDR_CLK LOCATION "Pin_J16"
cmp add_assignment $top_name "" SDR_CKE LOCATION "Pin_L15"
cmp add_assignment $top_name "" SDR_RASN LOCATION "Pin_D14"
cmp add_assignment $top_name "" SDR_CASN LOCATION "Pin_G12"
cmp add_assignment $top_name "" SDR_WEN LOCATION "Pin_H13"
cmp add_assignment $top_name "" SDR_CS0N LOCATION "Pin_L12"
cmp add_assignment $top_name "" SDR_CS1N LOCATION "Pin_F12"

cmp add_assignment $top_name "" SDR_A\[0\] LOCATION "Pin_C11"
cmp add_assignment $top_name "" SDR_A\[1\] LOCATION "Pin_D11"
cmp add_assignment $top_name "" SDR_A\[2\] LOCATION "Pin_D12"
cmp add_assignment $top_name "" SDR_A\[3\] LOCATION "Pin_E9"
cmp add_assignment $top_name "" SDR_A\[4\] LOCATION "Pin_E11"
cmp add_assignment $top_name "" SDR_A\[5\] LOCATION "Pin_C13"
cmp add_assignment $top_name "" SDR_A\[6\] LOCATION "Pin_B13"
cmp add_assignment $top_name "" SDR_A\[7\] LOCATION "Pin_A13"
cmp add_assignment $top_name "" SDR_A\[8\] LOCATION "Pin_C12"
cmp add_assignment $top_name "" SDR_A\[9\] LOCATION "Pin_B12"
cmp add_assignment $top_name "" SDR_A\[10\] LOCATION "Pin_B14"
cmp add_assignment $top_name "" SDR_A\[11\] LOCATION "Pin_A15"
cmp add_assignment $top_name "" SDR_A\[12\] LOCATION "Pin_B15"

cmp add_assignment $top_name "" SDR_BA\[0\] LOCATION "Pin_B11"
cmp add_assignment $top_name "" SDR_BA\[1\] LOCATION "Pin_A11"

cmp add_assignment $top_name "" SDR_D\[0\] LOCATION "Pin_P15"
cmp add_assignment $top_name "" SDR_D\[1\] LOCATION "Pin_L13"
cmp add_assignment $top_name "" SDR_D\[2\] LOCATION "Pin_N15"
cmp add_assignment $top_name "" SDR_D\[3\] LOCATION "Pin_N16"
cmp add_assignment $top_name "" SDR_D\[4\] LOCATION "Pin_M14"
cmp add_assignment $top_name "" SDR_D\[5\] LOCATION "Pin_N13"
cmp add_assignment $top_name "" SDR_D\[6\] LOCATION "Pin_N14"
cmp add_assignment $top_name "" SDR_D\[7\] LOCATION "Pin_P14"
cmp add_assignment $top_name "" SDR_D\[8\] LOCATION "Pin_K14"
cmp add_assignment $top_name "" SDR_D\[9\] LOCATION "Pin_K12"
cmp add_assignment $top_name "" SDR_D\[10\] LOCATION "Pin_M16"
cmp add_assignment $top_name "" SDR_D\[11\] LOCATION "Pin_L16"
cmp add_assignment $top_name "" SDR_D\[12\] LOCATION "Pin_R16"
cmp add_assignment $top_name "" SDR_D\[13\] LOCATION "Pin_M15"
cmp add_assignment $top_name "" SDR_D\[14\] LOCATION "Pin_M13"
cmp add_assignment $top_name "" SDR_D\[15\] LOCATION "Pin_L14"
cmp add_assignment $top_name "" SDR_D\[16\] LOCATION "Pin_G14"
cmp add_assignment $top_name "" SDR_D\[17\] LOCATION "Pin_F16"
cmp add_assignment $top_name "" SDR_D\[18\] LOCATION "Pin_G15"
cmp add_assignment $top_name "" SDR_D\[19\] LOCATION "Pin_G13"
cmp add_assignment $top_name "" SDR_D\[20\] LOCATION "Pin_F14"
cmp add_assignment $top_name "" SDR_D\[21\] LOCATION "Pin_H12"
cmp add_assignment $top_name "" SDR_D\[22\] LOCATION "Pin_K15"
cmp add_assignment $top_name "" SDR_D\[23\] LOCATION "Pin_K16"
cmp add_assignment $top_name "" SDR_D\[24\] LOCATION "Pin_E14"
cmp add_assignment $top_name "" SDR_D\[25\] LOCATION "Pin_E13"
cmp add_assignment $top_name "" SDR_D\[26\] LOCATION "Pin_F15"
cmp add_assignment $top_name "" SDR_D\[27\] LOCATION "Pin_E16"
cmp add_assignment $top_name "" SDR_D\[28\] LOCATION "Pin_E15"
cmp add_assignment $top_name "" SDR_D\[29\] LOCATION "Pin_D16"
cmp add_assignment $top_name "" SDR_D\[30\] LOCATION "Pin_D15"
cmp add_assignment $top_name "" SDR_D\[31\] LOCATION "Pin_D13"

cmp add_assignment $top_name "" SDR_DQM\[0\] LOCATION "Pin_B16"
cmp add_assignment $top_name "" SDR_DQM\[1\] LOCATION "Pin_C15"
cmp add_assignment $top_name "" SDR_DQM\[2\] LOCATION "Pin_C14"
cmp add_assignment $top_name "" SDR_DQM\[3\] LOCATION "Pin_F13"


##############################
# Autres
##############################

cmp add_assignment $top_name "" P5V_GOODN LOCATION "Pin_R1"
