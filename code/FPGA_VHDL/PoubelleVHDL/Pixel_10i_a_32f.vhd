--
-- Nom de l'étudiant : David FISCHER TE3
-- Nom du projet     : Caméra CMOS 2006
-- Nom du vhdl       : Pixel_10i_a_32f
-- Nom du processeur : Cyclone - EP1C12F256C7
--
-- Conversion d'un Pixel 10 bits [0-1023] en nombre
-- Flottant IEEE 754 sur 32 bits -> entre [0.0-1.0]
--

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.std_logic_unsigned.all;
use 	work.CameraCMOSPack.all;

entity Pixel_10i_a_32f is

	port (Clk    : in std_logic; -- Horloge du Système
		  nReset : in std_logic; -- Reset du Système
	
		  -- Entrées représentant le Pixel à 10 bits i
		  inSync     : in std_logic; -- Synchro de l'Entrée
		  inPixel10i : in std_logic_vector(9 downto 0);  -- Pixel de 10 bits i
		
		  -- Sorties représentant le Pixel à 32 bits f
		  outSync     : out std_logic; -- Synchro de la Sortie
		  outPixel32f : out std_logic_vector(31 downto 0)); -- Pixel de 32 bits f

end Pixel_10i_a_32f;

architecture STRUCT of Pixel_10i_a_32f is

	signal Sortie_C, Sortie_F : std_logic;
	signal Nombre_C, Nombre_F : std_logic_vector(31 downto 0);

	alias  Signe_F : std_logic is Nombre_F(31); -- Norme IEEE 754
	
	alias  Exposant_F : std_logic_vector (7 downto 0)
						is Nombre_F(30 downto 23);
						
	alias  Mantisse_F : std_logic_vector (22 downto 0)
						is Nombre_F(22 downto  0);

begin

	-- "Câblages"
	outSync     <= Sortie_C;
	outPixel32f <= Nombre_C;
	
	-- Synchro avec la Clock
    process (Clk,nReset)
    begin
		if nReset='0' then
			Sortie_C <= '0';
			Nombre_C <= (others=>'0');
		elsif rising_edge(Clk) then
			Sortie_C <= Sortie_F;
			Nombre_C <= Nombre_F;
		end if;
	end process;
	
	-- Conversion 10i -> 32f
	process (inSync,inPixel10i)
	begin

		Sortie_F <= '0';
		Nombre_F <= (others=>'0');

		if inSync='1' then
		
			Sortie_F <= '1'; -- Nous Aurons un Résultat
			Signe_F  <= '0'; -- Toujours Positif
			
			if inPixel10i(9)='1' then
				Exposant_F( 7 downto  0) <= "01111110"; -- 127-1
				Mantisse_F(22 downto 14) <= inPixel10i(8 downto 0);
				
			elsif inPixel10i(8)='1' then
				Exposant_F( 7 downto  0) <= "01111101"; -- 127-2
				Mantisse_F(22 downto 15) <= inPixel10i(7 downto 0);
				
			elsif inPixel10i(7)='1' then
				Exposant_F( 7 downto  0) <= "01111100"; -- 127-3
				Mantisse_F(22 downto 16) <= inPixel10i(6 downto 0);
				
			elsif inPixel10i(6)='1' then
				Exposant_F( 7 downto  0) <= "01111011"; -- 127-4
				Mantisse_F(22 downto 17) <= inPixel10i(5 downto 0);
				
			elsif inPixel10i(5)='1' then
				Exposant_F( 7 downto  0) <= "01111010"; -- 127-5
				Mantisse_F(22 downto 18) <= inPixel10i(4 downto 0);
				
			elsif inPixel10i(4)='1' then
				Exposant_F( 7 downto  0) <= "01111001"; -- 127-6
				Mantisse_F(22 downto 19) <= inPixel10i(3 downto 0);
				
			elsif inPixel10i(3)='1' then
				Exposant_F( 7 downto  0) <= "01111000"; -- 127-7
				Mantisse_F(22 downto 20) <= inPixel10i(2 downto 0);

			elsif inPixel10i(2)='1' then
				Exposant_F( 7 downto  0) <= "01110111"; -- 127-8
				Mantisse_F(22 downto 21) <= inPixel10i(1 downto 0);
				
			elsif inPixel10i(1)='1' then
				Exposant_F( 7 downto  0) <= "01110110"; -- 127-9
				Mantisse_F(22 downto 22) <= inPixel10i(0 downto 0);
				
			elsif inPixel10i(0)='1' then
				Exposant_F(7 downto 0) <= "01110101"; -- 127-10
				
			end if;
		end if;

	end process;
		
end STRUCT;