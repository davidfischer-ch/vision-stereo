library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.std_logic_arith.all;

entity Compteur_bidon2 is

	port (Clock48MHz : in std_logic;
		  nReset     : in std_logic;
		
		  inC_DATA : out unsigned (9 downto 0);
		  inC_SYNC : out unsigned (2 downto 0));
	
end Compteur_bidon2;

architecture STRUCT of Compteur_bidon2 is
	signal cpt,cpt_f : unsigned (12 downto 0);
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
	
	inC_DATA <= cpt(9 downto 0);
	inC_SYNC <= cpt(12 downto 10);

end STRUCT;