library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.std_logic_arith.all;

entity Compteur_bidon is

	port (Clock48MHz : in std_logic;
		  nReset     : in std_logic;
		
		  inP_DATA : out unsigned (7 downto 0);
		  inP_SYNC : out unsigned (1 downto 0));
	
end Compteur_bidon;

architecture STRUCT of Compteur_bidon is
	signal cpt,cpt_f : unsigned (9 downto 0);
begin

	process (Clock48MHz,nReset)
	begin
		if nReset='0' then
			cpt <= (others=>'0');
		elsif rising_edge (Clock48MHz) then
			cpt <= cpt_f;
		end if;
	end process;
	
	cpt_f <= cpt+1;
	
	inP_DATA <= cpt(7 downto 0);
	inP_SYNC <= cpt(9 downto 8);

end STRUCT;