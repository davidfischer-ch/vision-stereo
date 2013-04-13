--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : master_clock
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.VisionStereoPack.all;

entity master_clock is
	port (inSyncVHP  : in  tSyncVHP;
		  outSyncVHP : out tSyncVHP);
end master_clock;

architecture STRUCT of master_clock is
begin
	outSyncVHP <= inSyncVHP or "001";
end STRUCT;