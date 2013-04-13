--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : Temporisation
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.VisionStereoPack.all;

entity Temporisation is

	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  inSyncStart : in  std_logic;
		  inSecondes  : in  tNombre14;
		  outSyncStop : out std_logic;
		
		  outSeconde : out std_logic);
	
end Temporisation;

architecture STRUCT of Temporisation is

	constant cDecompte24MHz : tNombre27 := to_unsigned(24000000,27);
	
	signal sDecompte24MHz, sDecompte24MHz_Futur : tNombre27;
	
	signal sDecompte, sDecompte_Futur : tNombre14;
	signal sSeconde,  sSeconde_Futur  : std_logic;
	
	type tEtatTemp is (Initial,Temporise);
	
	signal sEtatTemp,    sEtatTemp_Futur    : tEtatTemp;
	signal soutSyncStop, soutSyncStop_Futur : std_logic;

begin

	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
	
		if nReset='0' then
		
			sEtatTemp      <= Initial;
			sDecompte24MHz <= (others=>'0');				-- CLK
			sDecompte      <= (others=>'0');				-- CLK
			sSeconde       <= '0';
			soutSyncStop   <= '0';
	
		elsif rising_edge(Clock24MHz) then
		
			sEtatTemp      <= sEtatTemp_Futur;
			sDecompte24MHz <= sDecompte24MHz_Futur;			-- CLK
			sDecompte  	   <= sDecompte_Futur;				-- CLK
			sSeconde 	   <= sSeconde_Futur;
			soutSyncStop   <= soutSyncStop_Futur;

		end if;
		
	end process;
	
	process (inSyncStart,inSecondes,
			 sEtatTemp,
			 sDecompte24MHz,
			 sDecompte,sSeconde,
			 soutSyncStop)
	begin
		
		sEtatTemp_Futur      <= sEtatTemp;
		sDecompte24MHz_Futur <= sDecompte24MHz;
		sDecompte_Futur  	 <= sDecompte;
		sSeconde_Futur 		 <= '0';
		soutSyncStop_Futur   <= '0';
		
		case sEtatTemp is
		
		when Initial =>
		
			if inSyncStart='1' then
				sEtatTemp_Futur <= Temporise;
				sDecompte_Futur <= inSecondes;
			end if;
			
		when Temporise =>
	
			-- Décompte de l'Horloge --> Seconde
			sDecompte24MHz_Futur <= sDecompte24MHz+1;
		
			-- 1 Seconde viens de passer...
			if sDecompte24MHz=cDecompte24MHz-1 then
			
				sDecompte24MHz_Futur <= (others=>'0');
				sSeconde_Futur 		 <= '1';
				
				-- Décompte des Secondes --> Temporisation
				sDecompte_Futur <= sDecompte-1;
				
				-- La Temporisation viens de passer...
				if sDecompte=0+1 then
					sEtatTemp_Futur    <= Initial;
					soutSyncStop_Futur <= '1';
				end if;
			end if;
			
		end case;
		
	end process;
		
	-- Sorties
	
	outSyncStop <= soutSyncStop;
	outSeconde  <= sSeconde;

end STRUCT;