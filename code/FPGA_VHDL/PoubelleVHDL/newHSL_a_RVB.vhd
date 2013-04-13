--
-- Nom de l'étudiant : David FISCHER TE3
-- Nom du projet     : Blind Cell 2006
-- Nom du vhdl       : HSL_a_RVB
-- Nom du processeur : Cyclone - EP1C12F256C7
--
-- BLA BLA CUI CUI
--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.BlindCellPack.all;
	
entity HSL_a_RVB is
	port (inHue,    inSat,   inLum   : in  tColor;
		  outRouge, outVert, outBleu : out tColor);
		
end HSL_a_RVB;

architecture STRUCT of HSL_a_RVB is
	
	signal sR,sV,sB : tColor;

begin -- Fini les signaux, voici le vi etch di l

	process (inHue,inSat,inLum)
		variable s_l   : tColor;
		variable var_1 : tColorE;
		variable var_2 : tColor;
	begin
		s_l := Multiplication(inSat,inLum);

		if inLum < cCrDemi then
		     var_2 := s_l + inLum;
		else var_2 := (inLum+inSat) - s_l; -- attention overflow!
		end if;
		
		var_1 := inLum&"0" - var_2;

		sR <= Hue_a_RVB (var_1(cCrMax downto 0), var_2, inHue + cCr1Tiers);
		sV <= Hue_a_RVB (var_1(cCrMax downto 0), var_2, inHue);
		sB <= Hue_a_RVB (var_1(cCrMax downto 0), var_2, inHue - cCr1Tiers);
	end process;
	
	outRouge <= sR;
	outVert  <= sV;
	outBleu  <= sB;

end STRUCT;