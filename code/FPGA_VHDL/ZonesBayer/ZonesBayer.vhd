--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : ZonesBayer
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- A partir des signaux  de contrôle, ce module s'occupe de fournir
-- (au bon moment) à notre MoyenneurBayer les facteurs de moyennage
-- afin d'obliger celui-ci à  donner d'avantage de détails dans une
-- zone dite détaillée (centrale) et moins en périphérie

--=============================================================--

-- Fréqu.  | Logique | Latence | Lignes | CRC
-- 175 MHz | 197 LE  |    1    |  327   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity ZonesBayer is
		
	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de Contrôle
		
		  inCfgPerMoyX   : in tNombre6;
		  inCfgPerMoyY   : in tNombre6;
		  inCfgPerMoyPre : in tPrediv5;
		  inCfgPerMoyDiv : in tNombre6;
		
		  inCfgDetMoyX   : in tNombre6;
		  inCfgDetMoyY   : in tNombre6;
		  inCfgDetMoyPre : in tPrediv5;
		  inCfgDetMoyDiv : in tNombre6;
		
		  inCfgDetDebX : in tPosition11;
		  inCfgDetDebY : in tPosition11;
		  inCfgDetFinX : in tPosition11;
		  inCfgDetFinY : in tPosition11;
	
		  -- SIGNAUX de Caméra
		
	      inSyncVHP : in tSyncVHP;
	      inCouleur : in tColor10;
	
		  -- SIGNAUX vers MoyenneurBayer
		
		  outCfgMoyX   : out tNombre6;
		  outCfgMoyY   : out tNombre6;
		  outCfgMoyPre : out tPrediv5;
		  outCfgMoyDiv : out tNombre6;
		
		  outSyncVHP : out tSyncVHP;
		  outCouleur : out tColor10);

end ZonesBayer;

--=============================================================--

architecture STRUCT of ZonesBayer is
	
	-- Détection des Flans des Signaux de Synchro (IN)
	signal soldSyncVHP, soldSyncVHP_Futur : tSyncVHP;
	
	-- Mise à Jour de la Config @ chaque Nouvelle Image (CFG)
	signal sCfgPerMoyX,   sCfgPerMoyX_Futur   : tNombre6;
	signal sCfgPerMoyY,   sCfgPerMoyY_Futur   : tNombre6;
	signal sCfgPerMoyPre, sCfgPerMoyPre_Futur : tPrediv5;
	signal sCfgPerMoyDiv, sCfgPerMoyDiv_Futur : tNombre6;
		
	signal sCfgDetMoyX,   sCfgDetMoyX_Futur   : tNombre6;
	signal sCfgDetMoyY,   sCfgDetMoyY_Futur   : tNombre6;
	signal sCfgDetMoyPre, sCfgDetMoyPre_Futur : tPrediv5;
	signal sCfgDetMoyDiv, sCfgDetMoyDiv_Futur : tNombre6;
		
	signal sCfgDetDebX, sCfgDetDebX_Futur : tPosition11;
	signal sCfgDetDebY, sCfgDetDebY_Futur : tPosition11;
	signal sCfgDetFinX, sCfgDetFinX_Futur : tPosition11;
	signal sCfgDetFinY, sCfgDetFinY_Futur : tPosition11;
	
	-- Positionnement dans le Motif de Bayer (BAY)
	signal sDeltaX, sDeltaX_Futur : tBayerPosX;
	signal sDeltaY, sDeltaY_Futur : tBayerPosY;
	signal sNoPixX, sNoPixX_Futur : tPosition11;
	signal sNoPixY, sNoPixY_Futur : tPosition11;
	
	-- Signaux de Synchro / Couleur en Sortie (OUT)
	signal soutCfgMoyX,   soutCfgMoyX_Futur   : tNombre6;
	signal soutCfgMoyY,   soutCfgMoyY_Futur   : tNombre6;
	signal soutCfgMoyPre, soutCfgMoyPre_Futur : tPrediv5;
	signal soutCfgMoyDiv, soutCfgMoyDiv_Futur : tNombre6;
	
	type tRegSyncVHP is array (0 to 1) of tSyncVHP;
	type tRegColor10 is array (0 to 1) of tColor10;
	
	signal soutSyncVHP, soutSyncVHP_Futur : tRegSyncVHP;
	signal soutCouleur, soutCouleur_Futur : tRegColor10;

begin --=======================================================--
			
	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
	
		if nReset='0' then
		
			soldSyncVHP <= "000";  							-- IN
			
			sCfgPerMoyX   <= to_unsigned(nPerMoyX,6);		-- CFG
			sCfgPerMoyY   <= to_unsigned(nPerMoyY,6);		-- CFG
			sCfgPerMoyPre <= to_unsigned(nPerMoyPre,5);		-- CFG
			sCfgPerMoyDiv <= to_unsigned(nPerMoyDiv,6);		-- CFG
		
			sCfgDetMoyX   <= to_unsigned(nDetMoyX,6);		-- CFG
			sCfgDetMoyY   <= to_unsigned(nDetMoyY,6);		-- CFG
			sCfgDetMoyPre <= to_unsigned(nDetMoyPre,5);		-- CFG
			sCfgDetMoyDiv <= to_unsigned(nDetMoyDiv,6);		-- CFG
		
			sCfgDetDebX <= to_unsigned(nDetDebX,11);		-- CFG
			sCfgDetDebY <= to_unsigned(nDetDebY,11);		-- CFG
			sCfgDetFinX <= to_unsigned(nDetFinX,11);		-- CFG
			sCfgDetFinY <= to_unsigned(nDetFinY,11);		-- CFG
			
			sDeltaX <= G; 									-- BAY
			sDeltaY <= H; 									-- BAY
			sNoPixX <= (others=>'0'); 						-- BAY
			sNoPixY <= (others=>'0'); 						-- BAY
			
			soutCfgMoyX   <= to_unsigned(nPerMoyX,6);		-- OUT
			soutCfgMoyY   <= to_unsigned(nPerMoyY,6);		-- OUT
			soutCfgMoyPre <= to_unsigned(nPerMoyPre,5);		-- OUT
			soutCfgMoyDiv <= to_unsigned(nPerMoyDiv,6);		-- OUT
					
			soutSyncVHP <= (others=>"000");					-- OUT
			soutCouleur <= (others=>(others=>'0'));			-- OUT
	
		elsif rising_edge (Clock24MHz) then
		
			soldSyncVHP <= soldSyncVHP_Futur; 				-- IN
			
			sCfgPerMoyX   <= sCfgPerMoyX_Futur;				-- CFG
			sCfgPerMoyY   <= sCfgPerMoyY_Futur;				-- CFG
			sCfgPerMoyPre <= sCfgPerMoyPre_Futur;			-- CFG
			sCfgPerMoyDiv <= sCfgPerMoyDiv_Futur;			-- CFG
		
			sCfgDetMoyX   <= sCfgDetMoyX_Futur;				-- CFG
			sCfgDetMoyY   <= sCfgDetMoyY_Futur;				-- CFG
			sCfgDetMoyPre <= sCfgDetMoyPre_Futur;			-- CFG
			sCfgDetMoyDiv <= sCfgDetMoyDiv_Futur;			-- CFG
		
			sCfgDetDebX <= sCfgDetDebX_Futur;				-- CFG
			sCfgDetDebY <= sCfgDetDebY_Futur;				-- CFG
			sCfgDetFinX <= sCfgDetFinX_Futur;				-- CFG
			sCfgDetFinY <= sCfgDetFinY_Futur;				-- CFG
				
			sDeltaX <= sDeltaX_Futur; 						-- BAY
			sDeltaY <= sDeltaY_Futur; 						-- BAY
			sNoPixX <= sNoPixX_Futur; 						-- BAY
			sNoPixY <= sNoPixY_Futur; 						-- BAY
			
			soutCfgMoyX   <= soutCfgMoyX_Futur;				-- OUT
			soutCfgMoyY   <= soutCfgMoyY_Futur;				-- OUT
			soutCfgMoyPre <= soutCfgMoyPre_Futur;			-- OUT
			soutCfgMoyDiv <= soutCfgMoyDiv_Futur;			-- OUT
			
			soutSyncVHP <= soutSyncVHP_Futur; 				-- OUT
			soutCouleur <= soutCouleur_Futur; 				-- OUT
					
		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	soldSyncVHP_Futur <= inSyncVHP; 						-- IN
	
	soutSyncVHP_Futur <= inSyncVHP & soutSyncVHP(0);		-- OUT
	soutCouleur_Futur <= inCouleur & soutCouleur(0);		-- OUT
	
	outCfgMoyX   <= soutCfgMoyX;							-- OUT
	outCfgMoyY   <= soutCfgMoyY;							-- OUT
	outCfgMoyPre <= soutCfgMoyPre;							-- OUT
	outCfgMoyDiv <= soutCfgMoyDiv;							-- OUT
	
	outSyncVHP <= soutSyncVHP(0);							-- OUT
	outCouleur <= soutCouleur(0);							-- OUT
	
	-- Processus de Changement de Configuration Intelligent ======--
	
	process(inSyncVHP,
			inCfgDetDebX,inCfgDetDebY,inCfgDetFinX,inCfgDetFinY,
			inCfgPerMoyX,inCfgPerMoyY,inCfgPerMoyPre,inCfgPerMoyDiv,
			inCfgDetMoyX,inCfgDetMoyY,inCfgDetMoyPre,inCfgDetMoyDiv,
			sCfgDetDebX,sCfgDetDebY,sCfgDetFinX,sCfgDetFinY,
			sCfgPerMoyX,sCfgPerMoyY,sCfgPerMoyPre,sCfgPerMoyDiv,
			sCfgDetMoyX,sCfgDetMoyY,sCfgDetMoyPre,sCfgDetMoyDiv)
	begin
		sCfgPerMoyX_Futur   <= sCfgPerMoyX;					-- CFG
		sCfgPerMoyY_Futur   <= sCfgPerMoyY;					-- CFG
		sCfgPerMoyPre_Futur <= sCfgPerMoyPre;				-- CFG
		sCfgPerMoyDiv_Futur <= sCfgPerMoyDiv;				-- CFG
		
		sCfgDetMoyX_Futur   <= sCfgDetMoyX;					-- CFG
		sCfgDetMoyY_Futur   <= sCfgDetMoyY;					-- CFG
		sCfgDetMoyPre_Futur <= sCfgDetMoyPre;				-- CFG
		sCfgDetMoyDiv_Futur <= sCfgDetMoyDiv;				-- CFG
		
		sCfgDetDebX_Futur <= sCfgDetDebX;					-- CFG
		sCfgDetDebY_Futur <= sCfgDetDebY;					-- CFG
		sCfgDetFinX_Futur <= sCfgDetFinX;					-- CFG
		sCfgDetFinY_Futur <= sCfgDetFinY;					-- CFG
		
		-- Mise à jour entre deux images
		if inSyncVHP(2 downto 1)="00" then
			sCfgPerMoyX_Futur   <= inCfgPerMoyX;			-- CFG
			sCfgPerMoyY_Futur   <= inCfgPerMoyY;			-- CFG
			sCfgPerMoyPre_Futur <= inCfgPerMoyPre;			-- CFG
			sCfgPerMoyDiv_Futur <= inCfgPerMoyDiv;			-- CFG
		
			sCfgDetMoyX_Futur   <= inCfgDetMoyX;			-- CFG
			sCfgDetMoyY_Futur   <= inCfgDetMoyY;			-- CFG
			sCfgDetMoyPre_Futur <= inCfgDetMoyPre;			-- CFG
			sCfgDetMoyDiv_Futur <= inCfgDetMoyDiv;			-- CFG
		
			sCfgDetDebX_Futur <= inCfgDetDebX;				-- CFG
			sCfgDetDebY_Futur <= inCfgDetDebY;				-- CFG
			sCfgDetFinX_Futur <= inCfgDetFinX;				-- CFG
			sCfgDetFinY_Futur <= inCfgDetFinY;				-- CFG
		end if;

	end process;
	
	-- Processus de Zonnage ======================================--
	
	process (inSyncVHP,soldSyncVHP,
			 sDeltaX,sDeltaY,sNoPixX,sNoPixY)
	begin
	
		sDeltaX_Futur <= sDeltaX;							-- BAY
		sDeltaY_Futur <= sDeltaY;							-- BAY
		sNoPixX_Futur <= sNoPixX;							-- BAY
		sNoPixY_Futur <= sNoPixY;							-- BAY
		
		case inSyncVHP(2 downto 1) is

		-- Pause Image, en attendant la Nouvelle  -----------
		when "00"=>
		
			sDeltaX_Futur <= G; 							-- BAY
			sDeltaY_Futur <= H; 							-- BAY
			sNoPixX_Futur <= (others=>'0'); 				-- BAY
			sNoPixY_Futur <= (others=>'0'); 				-- BAY
		
		-- Pause Ligne, en attendant la Nouvelle ------------
		when "10"=>
		
			sDeltaX_Futur <= G; 							-- BAY
			sNoPixX_Futur <= (others=>'0'); 				-- BAY

			if soldSyncVHP(1)='1' then						-- SYN
			
				-- La Prochaine Ligne...
				sDeltaY_Futur <= Ne_BayerPosY(sDeltaY);		-- BAY
				
				-- Nouveau "Groupe" (2x2) de Pixels
				if sDeltaY=B then							-- BAY
					sNoPixY_Futur <= sNoPixY+1;				-- BAY
				end if;
				
			end if;
		
		-- Nouveau Pixel d'une Ligne ------------------------
		when "11"=>
		
			if inSyncVHP(0)='1' then						-- SYN
		
				-- Le Prochain Pixel ...
				sDeltaX_Futur <= Ne_BayerPosX(sDeltaX);		-- BAY
			
				-- Nouveau "Groupe" (2x2) de Pixels
				if sDeltaX=D then							-- BAY
					sNoPixX_Futur <= sNoPixX+1;				-- BAY
				end if;
				
			end if;
		
		when others=> null;
		
		end case;
		
	end process;

	-- Processus de Sortie =======================================--
	
	process(sCfgDetDebX,sCfgDetDebY,sCfgDetFinX,sCfgDetFinY,
			sCfgPerMoyX,sCfgPerMoyY,sCfgPerMoyPre,sCfgPerMoyDiv,
			sCfgDetMoyX,sCfgDetMoyY,sCfgDetMoyPre,sCfgDetMoyDiv,
			sNoPixX,sNoPixY)
	begin			
		soutCfgMoyX_Futur   <= sCfgPerMoyX;					-- OUT
		soutCfgMoyY_Futur   <= sCfgPerMoyY;					-- OUT
		soutCfgMoyPre_Futur <= sCfgPerMoyPre;				-- OUT
		soutCfgMoyDiv_Futur <= sCfgPerMoyDiv;				-- OUT
			
		if  sNoPixY>=sCfgDetDebY and sNoPixY<=sCfgDetFinY
		and sNoPixX>=sCfgDetDebX and sNoPixX<=sCfgDetFinX then
			soutCfgMoyX_Futur   <= sCfgDetMoyX;				-- OUT
			soutCfgMoyY_Futur   <= sCfgDetMoyY;				-- OUT
			soutCfgMoyPre_Futur <= sCfgDetMoyPre;			-- OUT
			soutCfgMoyDiv_Futur <= sCfgDetMoyDiv;			-- OUT
		end if;
	end process;

end STRUCT;