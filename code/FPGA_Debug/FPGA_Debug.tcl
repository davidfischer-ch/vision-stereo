###############################################################################
#
# CameraCMOS.tcl
#
# Cible    : USB2 - Cyclone - Camera
# Autheur  : David FISCHER
# Revision : 0.0 GW version de base
# Date     : 26.10.2006
# 
# Règle de syntaxe : GROUPE_NOM[bit]
#
# GROUPE : spécifie un interface particulier (ex: SDR_)
# NOM    : nom du signal (ex: CONFIG, D, ...)
# bit    : indice du vecteur signal( en tcl, mettre \[  et \]  pour [  ] )
#
###############################################################################

# set top entity name
set project_name FPGA_Debug
set top_name     FPGA_Debug

project set_active_cmp $top_name

cmp add_assignment $top_name "" "" DEVICE EP1C12F256C7

##############################
# Bus config.
#############################

cmp add_assignment $top_name "" INIT_DONE LOCATION "Pin_D4"
cmp add_assignment $top_name "" CLKUSR    LOCATION "Pin_C2"
cmp add_assignment $top_name "" NCSO      LOCATION "Pin_G4"
cmp add_assignment $top_name "" ASDO      LOCATION "Pin_K3"

##############################
# Horloges
##############################

cmp add_assignment $top_name "" Clock48MHz LOCATION "Pin_H1"
cmp add_assignment $top_name "" nReset     LOCATION "Pin_N4"


##############################
# GPIF/FIFO
############################## 

cmp add_assignment $top_name "" inIFCLK LOCATION "Pin_J1"

cmp add_assignment $top_name "" outSLRD LOCATION "Pin_M1"
cmp add_assignment $top_name "" outSLWR LOCATION "Pin_N1"
cmp add_assignment $top_name "" outSLOE LOCATION "Pin_L2"

cmp add_assignment $top_name "" inFLAGA LOCATION "Pin_M3"
cmp add_assignment $top_name "" inFLAGB LOCATION "Pin_N2"
cmp add_assignment $top_name "" inFLAGC LOCATION "Pin_L3"
cmp add_assignment $top_name "" outFLAGD LOCATION "Pin_H5"

cmp add_assignment $top_name "" outFIFOADR\[0\] LOCATION "Pin_L1"
cmp add_assignment $top_name "" outFIFOADR\[1\] LOCATION "Pin_K1"
cmp add_assignment $top_name "" outPKTEND       LOCATION "Pin_M2"

cmp add_assignment $top_name "" outFD\[0\] LOCATION "Pin_F1"
cmp add_assignment $top_name "" outFD\[1\] LOCATION "Pin_G2"
cmp add_assignment $top_name "" outFD\[2\] LOCATION "Pin_E1"
cmp add_assignment $top_name "" outFD\[3\] LOCATION "Pin_F2"
cmp add_assignment $top_name "" outFD\[4\] LOCATION "Pin_G3"
cmp add_assignment $top_name "" outFD\[5\] LOCATION "Pin_F3"
cmp add_assignment $top_name "" outFD\[6\] LOCATION "Pin_D1"
cmp add_assignment $top_name "" outFD\[7\] LOCATION "Pin_E2"
cmp add_assignment $top_name "" outFD\[8\] LOCATION "Pin_D2"
cmp add_assignment $top_name "" outFD\[9\] LOCATION "Pin_E3"
cmp add_assignment $top_name "" outFD\[10\] LOCATION "Pin_E4"
cmp add_assignment $top_name "" outFD\[11\] LOCATION "Pin_D3"
cmp add_assignment $top_name "" outFD\[12\] LOCATION "Pin_F4"
cmp add_assignment $top_name "" outFD\[13\] LOCATION "Pin_G5"
cmp add_assignment $top_name "" outFD\[14\] LOCATION "Pin_B1"
cmp add_assignment $top_name "" outFD\[15\] LOCATION "Pin_C3"


##############################
# Connecteurs ext.
##############################

cmp add_assignment $top_name "" EXT_IOE  LOCATION "Pin_N3"
cmp add_assignment $top_name "" EXT_CLK1 LOCATION "Pin_M5"
cmp add_assignment $top_name "" EXT_CTL1 LOCATION "Pin_R10"
                                          
# Connecteur externe n°1 connecté à la caméra RVB KAC-9648

# Numéro	Pin		Documentation	Branché à

# J1-1				(vcc) triangle	automatique
# J1-20				(gnd) trait		automatique

# J1-2 		R10		mclk			outC_MCLK
# J1-18		T6		resetb			outC_NRESET

# J1-19 	P6		pwd				outC_PWD
# J1-17		R6		snapshot		outC_SNAPSHOT
# J1-16		R7		extsync			inC_EXTSYNC

# J3-3		x		sclk			busC_SCL
# J13-4		x		sda				busC_SDA

# J1-14 	N7		hsync 			inC_SYNC[0]
# J1-15 	P7		vsync 			inC_SYNC[1]
# J1-3		M5		pclk			inC_SYNC[2]

# J1-13:4 	N7:R9	d[9:0] 			inC_DATA[9:0]

cmp add_assignment $top_name "" outC_MCLK   LOCATION "Pin_R10"
cmp add_assignment $top_name "" outC_NRESET LOCATION "Pin_T6"

cmp add_assignment $top_name "" outC_PWD 	  LOCATION "Pin_P6"
cmp add_assignment $top_name "" outC_SNAPSHOT LOCATION "Pin_R6"
cmp add_assignment $top_name "" inC_EXTSYNC   LOCATION "Pin_R7"

cmp add_assignment $top_name "" inC_SYNC\[2\] LOCATION "Pin_P7"
cmp add_assignment $top_name "" inC_SYNC\[1\] LOCATION "Pin_N7"
cmp add_assignment $top_name "" inC_SYNC\[0\] LOCATION "Pin_M5"

cmp add_assignment $top_name "" inC_DATA\[0\] LOCATION "Pin_R9"
cmp add_assignment $top_name "" inC_DATA\[1\] LOCATION "Pin_T9"
cmp add_assignment $top_name "" inC_DATA\[2\] LOCATION "Pin_P9"
cmp add_assignment $top_name "" inC_DATA\[3\] LOCATION "Pin_N9"
cmp add_assignment $top_name "" inC_DATA\[4\] LOCATION "Pin_M9"
cmp add_assignment $top_name "" inC_DATA\[5\] LOCATION "Pin_R8"
cmp add_assignment $top_name "" inC_DATA\[6\] LOCATION "Pin_T8"
cmp add_assignment $top_name "" inC_DATA\[7\] LOCATION "Pin_N8"
cmp add_assignment $top_name "" inC_DATA\[8\] LOCATION "Pin_P8"
cmp add_assignment $top_name "" inC_DATA\[9\] LOCATION "Pin_M8"

# version avec 1 seul connecteur car le 2ème est naze

cmp add_assignment $top_name "" outP_MCLK 	LOCATION "Pin_R10"
cmp add_assignment $top_name "" outP_NRESET LOCATION "Pin_T6"

cmp add_assignment $top_name "" busP_SCL LOCATION "Pin_R6"
cmp add_assignment $top_name "" busP_SDA LOCATION "Pin_R7"

cmp add_assignment $top_name "" inP_SYNC\[1\] LOCATION "Pin_P7"
cmp add_assignment $top_name "" inP_SYNC\[0\] LOCATION "Pin_N7"

cmp add_assignment $top_name "" inP_DATA\[0\] LOCATION "Pin_R9"
cmp add_assignment $top_name "" inP_DATA\[1\] LOCATION "Pin_T9"
cmp add_assignment $top_name "" inP_DATA\[2\] LOCATION "Pin_P9"
cmp add_assignment $top_name "" inP_DATA\[3\] LOCATION "Pin_N9"
cmp add_assignment $top_name "" inP_DATA\[4\] LOCATION "Pin_M9"
cmp add_assignment $top_name "" inP_DATA\[5\] LOCATION "Pin_R8"
cmp add_assignment $top_name "" inP_DATA\[6\] LOCATION "Pin_T8"
cmp add_assignment $top_name "" inP_DATA\[7\] LOCATION "Pin_N8"


# Connecteur externe n°2 connecté à la caméra N&B KAC-9630

# Numéro	Pin		Documentation	Branché à

# J1-1				(vcc) triangle	automatique
# J1-20				(gnd) trait		automatique

# J1-2 		M10		mclk			outP_MCLK
# J1-18		T15		nReset			outP_NRESET

# J1-17		M11		sclk			busP_SCL
# J1-16		R14		sda				busP_SDA

# J1-15 	P11		vsync 			inP_SYNC[1]
# J1-14 	R13		hsync 			inP_SYNC[0]

# J1-11:4 	P12:P10	d[7:0] 			inP_DATA[7:0]

#cmp add_assignment $top_name "" outP_MCLK 	LOCATION "Pin_M10"
#cmp add_assignment $top_name "" outP_NRESET LOCATION "Pin_T15"

#cmp add_assignment $top_name "" busP_SCL LOCATION "Pin_M11"
#cmp add_assignment $top_name "" busP_SDA LOCATION "Pin_R14"

#cmp add_assignment $top_name "" inP_SYNC\[1\] LOCATION "Pin_P11"
#cmp add_assignment $top_name "" inP_SYNC\[0\] LOCATION "Pin_R13"

#cmp add_assignment $top_name "" inP_DATA\[0\] LOCATION "Pin_P10"
#cmp add_assignment $top_name "" inP_DATA\[1\] LOCATION "Pin_R15"
#cmp add_assignment $top_name "" inP_DATA\[2\] LOCATION "Pin_N11"
#cmp add_assignment $top_name "" inP_DATA\[3\] LOCATION "Pin_T13"
#cmp add_assignment $top_name "" inP_DATA\[4\] LOCATION "Pin_R11"
#cmp add_assignment $top_name "" inP_DATA\[5\] LOCATION "Pin_P13"
#cmp add_assignment $top_name "" inP_DATA\[6\] LOCATION "Pin_N12"
#cmp add_assignment $top_name "" inP_DATA\[7\] LOCATION "Pin_P12"

##############################
# Autres
##############################

cmp add_assignment $top_name "" P5V_GOODN LOCATION "Pin_R1"



