--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : RVB_ou_HSL
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- A partir des  flux RVB et HSL ce module nous  produit en sortie
-- un des deux flux, suivant la valeure du sélecteur inCfgTypeFlux,
-- ceci  de façon  cohérente, c'est à dire que le  changement s'il
-- a lieu ne se produira qu'entre deux images!

--=============================================================--

-- Fréqu.  | Logique | Latence | Lignes | CRC
-- 274 MHz | 28 LE   |    1    |  129   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity RVB_ou_HSL is
		
	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;

		  -- SIGNAUX de Contrôle
		
		  inCfgTypeFlux : in tTypeFlux;

		  -- SIGNAUX de RVB_a_HSL
		
		  inSyncVHP : in tSyncVHP;
		
		  inRouge : in tColor8;
		  inVert  : in tColor8;
		  inBleu  : in tColor8;
		
		  inTeinte     : in tColor8;
		  inSaturation : in tColor8;
		  inLuminance  : in tColor8;
		
		  -- SIGNAUX vers ProtocoleTITI
		
          outTypeFlux : out tTypeFlux;
		  outSyncVHP  : out tSyncVHP;
		  outCouleur1 : out tColor8;
		  outCouleur2 : out tColor8;
		  outCouleur3 : out tColor8);
		
end RVB_ou_HSL;

--=============================================================--

architecture STRUCT of RVB_ou_HSL is

	-- Signaux de Type de Flux / Synchro / Couleur en Sortie (OUT)
	signal soutTypeFlux, soutTypeFlux_Futur : tTypeFlux;
	signal soutSyncVHP,  soutSyncVHP_Futur  : tSyncVHP;
	signal soutCouleur1, soutCouleur1_Futur : tColor8;
	signal soutCouleur2, soutCouleur2_Futur : tColor8;
	signal soutCouleur3, soutCouleur3_Futur : tColor8;
	
begin --=======================================================--

	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin

		if nReset='0' then

			soutTypeFlux <= cDefCfgTypeFlux;				-- OUT
			soutSyncVHP  <= "000";							-- OUT
			soutCouleur1 <= (others=>'0');					-- OUT
			soutCouleur2 <= (others=>'0');					-- OUT
			soutCouleur3 <= (others=>'0');					-- OUT

		elsif rising_edge (Clock24MHz) then

			soutTypeFlux <= soutTypeFlux_Futur;				-- OUT
			soutSyncVHP  <= soutSyncVHP_Futur;				-- OUT
			soutCouleur1 <= soutCouleur1_Futur;				-- OUT
			soutCouleur2 <= soutCouleur2_Futur;				-- OUT
			soutCouleur3 <= soutCouleur3_Futur;				-- OUT

		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	soutSyncVHP_Futur  <= inSyncVHP;						-- IN
	
	soutCouleur1_Futur <= inRouge when soutTypeFlux_Futur=cTypeFluxRVB
					 else inTeinte;							-- OUT
					
	soutCouleur2_Futur <= inVert when soutTypeFlux_Futur=cTypeFluxRVB
					 else inSaturation;						-- OUT
					
	soutCouleur3_Futur <= inBleu when soutTypeFlux_Futur=cTypeFluxRVB
					 else inLuminance;						-- OUT
	
	outTypeFlux <= soutTypeFlux;							-- OUT
	outSyncVHP  <= soutSyncVHP;								-- OUT
	outCouleur1 <= soutCouleur1;							-- OUT
	outCouleur2 <= soutCouleur2;							-- OUT
	outCouleur3 <= soutCouleur3;							-- OUT
	
	-- Processus de Multiplexage Intelligent =====================--
	
	process (inCfgTypeFlux,inSyncVHP,soutTypeFlux)
	begin
		case inSyncVHP(2 downto 1) is						-- SYN
		when "00"=>   soutTypeFlux_Futur <= inCfgTypeFlux;	-- OUT
		when others=> soutTypeFlux_Futur <= soutTypeFlux;	-- OUT
		end case;
	end process;

end STRUCT;