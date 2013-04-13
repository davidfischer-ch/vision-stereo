--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : hybride_adaptateur
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.VisionStereoPack.all;

entity hybride_adaptateur is
	port (inSyncVH  : in tSyncVH;
		  inCouleur : in tColor8;
		
		  outSyncVHP : out tSyncVHP;
		  outCouleur : out tColor10);
	
end hybride_adaptateur;

architecture STRUCT of hybride_adaptateur is

begin

	outSyncVHP <= inSyncVH&'1';
	outCouleur <= "00"&inCouleur;

end STRUCT;