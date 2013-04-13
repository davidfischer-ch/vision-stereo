--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : pseudo_controle
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.VisionStereoPack.all;
		
entity pseudo_controle is
	port (outSyncWDR    : out std_logic;
		  outDeviceWDR  : out tRegI2C;
		  outAdresseWDR : out tRegI2C;
		  outDonneeWDR  : out tRegI2C);
	
end pseudo_controle;

architecture STRUCT of pseudo_controle is

begin

	outSyncWDR    <= '1';
	outDeviceWDR  <= "10001000"; -- KAC-9630
	outAdresseWDR <= "00000001"; -- MCFG
	outDonneeWDR  <= "00000000"; -- Master

end STRUCT;