--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : DivClockPar2
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Génère une Horloge à 9 MHz à partir d'un autre à 18 MHz

--=============================================================--

-- Fréqu.  | Logique | RAM | Latence | Lignes | CRC
-- 182 MHz | 196 LE  |  0  | ->image |  326   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;

entity DivClockPar2 is

	port (Clock18MHz   : in std_logic;
		  nReset       : in std_logic;
		  outClock9MHz : out std_logic);
		
end DivClockPar2;

architecture STRUCT of DivClockPar2 is

	signal sClock9MHz, sClock9MHz_Futur : std_logic;

begin

	process (Clock18MHz,nReset)
	begin
	
		if nReset='0' then 
			sClock9MHz <= '0';
		elsif rising_edge (Clock18MHz) then
			sClock9MHz <= sClock9MHz_Futur;
		end if;
		
	end process;
	
	sClock9MHz_Futur <= not sClock9MHz;
	
	outClock9MHz <= sClock9MHz;

end STRUCT;