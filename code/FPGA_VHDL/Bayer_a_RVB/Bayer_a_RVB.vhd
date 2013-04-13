--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : Bayer_a_RVB
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- A partir  des signaux  d'image et  de synchronisation provenant
-- d'une Caméra Couleur CMOS [format Bayer] (ou de MoyenneurBayer)
-- ce module s'occupe de regrouper  les quatre composantes couleur
-- rouge, bleue et 2 vertes => 1 seule pour former un pixel RVB

--=============================================================--

-- Fréqu.  | Logique | MOTS-FIFO | Latence   | Lignes | CRC
-- 121 MHz | 167 LE  | 256-4'096 | ->Ligne+2 |  354   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : banc de test! -- échange de rouge & bleu

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity Bayer_a_RVB is
		
	generic (FIFO_TailleMots : natural := 256;
			 FIFO_TailleBits : natural := 8);

	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de Contrôle

		  inFluxPos : in tPosition22;
	
		  -- SIGNAUX de MoyenneurBayer
		
		  inSyncVHP : in tSyncVHP;
		  inCouleur : in tColor10;
	
		  -- SIGNAUX vers RVB_a_HSL
		
		  outSyncVHP : out tSyncVHP;
		  outRouge   : out tColor8;
		  outVert    : out tColor8;
		  outBleu    : out tColor8);
		
end Bayer_a_RVB;

--=============================================================--

architecture STRUCT of Bayer_a_RVB is	

	-- Mémoire FIFO M4K
	component FIFO_Couleur is
		generic (TailleMots, TailleBits : natural);
		port (aclr	: in  std_logic := '0';
			  clock	: in  std_logic;
			  data	: in  tColor8;
			  rdreq	: in  std_logic;
			  wrreq	: in  std_logic;
			  q		: out tColor8);
	end component;
	
	-- Types spéciaux pour Bayer_a_RVB ===========================--
	
	type tBayerPosX_Color8    is array (tBayerPosX) of tColor8;
	type tBayerPosX_Adresse8  is array (tBayerPosX) of tAdresse8;
	type tBayerPosX_std_logic is array (tBayerPosX) of std_logic;
	
	-- Registres Internes & co ===================================--
	
	alias sFluxPosX : tPosition11 is inFluxPos(21 downto 11);
	alias sFluxPosY : tPosition11 is inFluxPos(10 downto  0);
	
	-- Détection des Flans des Signaux de Synchro (IN)
	signal soldSyncVHP, soldSyncVHP_Futur : tSyncVHP;
	signal sinCouleur : tColor8;
	
	-- Mise à Jour de la Config @ chaque Nouvelle Image (CFG)
	signal sPosX, sPosX_Futur : tBayerPosX;
	signal sPosY, sPosY_Futur : tBayerPosY;
	
	-- Positionnement dans le Motif de Bayer (BAY)
	signal sBayerX, sBayerX_Futur : tBayerPosX;
	signal sBayerY, sBayerY_Futur : tBayerPosY;
	signal sDeltaX, sDeltaX_Futur : tBayerPosX;
	signal sDeltaY, sDeltaY_Futur : tBayerPosY;
	
	-- Signaux de Gestion des FIFO's (FIFO)
	signal sData,    sData_Futur    : tColor8;
	signal sReadEn,  sReadEn_Futur  : std_logic;
	signal sWriteEn, sWriteEn_Futur : tBayerPosX_std_logic;
	signal sQ     : tBayerPosX_Color8;
	signal sUsedW : tBayerPosX_Adresse8;
	
	type tRegSyncVHP is array (0 to 1) of tSyncVHP;
	
	-- Signaux de Synchro / Couleur en Sortie (OUT)
	signal soutSyncVHP, soutSyncVHP_Futur : tRegSyncVHP;
	signal soutRouge,   soutRouge_Futur   : tColor8;
	signal soutVert,    soutVert_Futur    : tColor8;
	signal soutBleu,    soutBleu_Futur    : tColor8;
	
	signal sQ2, sQ2_Futur : tColor8;
	signal sQ3, sQ3_Futur : tColor8;

begin --=======================================================--

	-- Notre Mémoire FIFO M4K
	FIFO_Couleur_A : FIFO_Couleur
		generic map (TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
		port map (aclr	=> not nReset,
				  clock	=> Clock24MHz,
				  data	=> sData,
				  rdreq	=> sReadEn,
				  wrreq	=> sWriteEn(G),
				  q		=> sQ(G));

	-- Notre Mémoire FIFO M4K
	FIFO_Couleur_B : FIFO_Couleur
		generic map (TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
		port map (aclr	=> not nReset,
				  clock	=> Clock24MHz,
				  data	=> sData,
				  rdreq	=> sReadEn,
				  wrreq	=> sWriteEn(D),
				  q		=> sQ(D));
			
	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
		if nReset='0' then
		
			soldSyncVHP  <= "000"; 							-- IN
			
			sPosX <= G;										-- CFG
			sPosY <= H;										-- CFG
			
			sBayerX <= G; 									-- BAY
			sBayerY <= H; 									-- BAY
			sDeltaX <= G; 									-- BAY
			sDeltaY <= H; 									-- BAY
			
			sData    <= (others=>'0'); 						-- FIFO
			sReadEn  <= '0'; 		   						-- FIFO
			sWriteEn <= (others=>'0'); 						-- FIFO
			
			soutSyncVHP <= (others=>"000");					-- OUT
			soutRouge   <= (others=>'0'); 					-- OUT
			soutVert    <= (others=>'0'); 					-- OUT
			soutBleu    <= (others=>'0'); 					-- OUT
			
			sQ2 <= (others=>'0'); 							-- OUT
			sQ3 <= (others=>'0'); 							-- OUT
			
		elsif rising_edge (Clock24MHz) then
			
			soldSyncVHP  <= soldSyncVHP_Futur; 				-- IN
			
			sPosX <= sPosX_Futur;							-- CFG
			sPosY <= sPosY_Futur;							-- CFG
					
			sBayerX <= sBayerX_Futur; 						-- BAY
			sBayerY <= sBayerY_Futur; 						-- BAY
			sDeltaX <= sDeltaX_Futur; 						-- BAY
			sDeltaY <= sDeltaY_Futur; 						-- BAY
			
			sData    <= sData_Futur;    					-- FIFO
			sReadEn  <= sReadEn_Futur;  					-- FIFO
			sWriteEn <= sWriteEn_Futur; 					-- FIFO
			
			soutSyncVHP <= soutSyncVHP_Futur; 				-- OUT
			soutRouge   <= soutRouge_Futur;   				-- OUT
			soutVert    <= soutVert_Futur;    				-- OUT
			soutBleu    <= soutBleu_Futur;   				-- OUT
			
			sQ2 <= sQ2_Futur; 								-- OUT
			sQ3 <= sQ3_Futur; 								-- OUT
	
		end if;
	end process;
	
	-- Câblages ==================================================--
	
	soldSyncVHP_Futur <= inSyncVHP; 						-- IN
	sinCouleur <= inCouleur(tColor10'high downto 2);
--	sinCouleur <= inCouleur(tColor8'high downto 0);			-- IN
	
	sData_Futur <= sinCouleur; 								-- FIFO
	sQ2_Futur <= sData;      								-- OUT
	sQ3_Futur <= sinCouleur; 								-- OUT
	
	soutSyncVHP_Futur(1) <= soutSyncVHP(0);					-- OUT
    outSyncVHP <= soutSyncVHP(1);							-- OUT
outRouge <= soutRouge when soutSyncVHP(1)(0)='1' else (others=>'0');
outVert  <= soutVert  when soutSyncVHP(1)(0)='1' else (others=>'0');
outBleu  <= soutBleu  when soutSyncVHP(1)(0)='1' else (others=>'0');

	-- Processus de Changement de Configuration Intelligent ======--
	
	process (inSyncVHP,sFluxPosX,sFluxPosY,sPosX,sPosY)
	begin
	
		sPosX_Futur <= sPosX;								-- CFG
		sPosY_Futur <= sPosY;								-- CFG
		
		-- Mise à jour entre deux images
		if inSyncVHP(2 downto 1)="00" then					-- SYN
		
			if sFluxPosX(0)='1' then						-- IN
				 sPosX_Futur <= D;							-- CFG
			else sPosX_Futur <= G;							-- CFG
			end if;
			if sFluxPosY(0)='1' then						-- SYN
				 sPosY_Futur <= B;							-- CFG
			else sPosY_Futur <= H;							-- CFG
			end if;
			
		end if;
		
	end process;
	
	-- Processus en Sortie des Composantes =======================--
	
	process (sPosX,sPosY,sQ,sQ2,sQ3)
	
		variable vsQ0, vsQ1 : tColor8_Add;
		variable vsQ2, vsQ3 : tColor8_Add;
		
		variable vVert1, vVert2 : tColor8_Add;
		
	begin
		vsQ0 := "0"&sQ(G);
		vsQ1 := "0"&sQ(D);
		vsQ2 := "0"&sQ2;
		vsQ3 := "0"&sQ3;
		
		vVert1 := vsQ1+vsQ2;
		vVert2 := vsQ0+vsQ3;
		
		-- Mémorisation
		soutRouge_Futur <= (others=>'0');					-- OUT
		soutVert_Futur  <= (others=>'0');					-- OUT
		soutBleu_Futur  <= (others=>'0');					-- OUT
		
		if sPosY=H and sPosX=G then -- Vert
			soutVert_Futur  <= vVert2(tColor8_Add'high downto 1);
			soutRouge_Futur <= sQ(D);						-- OUT
			soutBleu_Futur  <= sQ2;							-- OUT
			
		elsif sPosY=H and sPosX=D then -- Rouge
			soutVert_Futur  <= vVert1(tColor8_Add'high downto 1);
			soutRouge_Futur <= sQ(G);						-- OUT
			soutBleu_Futur  <= sQ3;							-- OUT
			
		elsif sPosY=B and sPosX=G then -- Bleu
			soutVert_Futur  <= vVert1(tColor8_Add'high downto 1);
			soutRouge_Futur <= sQ3;							-- OUT
			soutBleu_Futur  <= sQ(G);						-- OUT
			
		elsif sPosY=B and sPosX=D then -- Vert2
			soutVert_Futur  <= vVert2(tColor8_Add'high downto 1);
			soutRouge_Futur <= sQ2;							-- OUT
			soutBleu_Futur  <= sQ(D);						-- OUT
			
		end if;
	end process;
	
	-- Processus de Dé-Bayer-Age =================================--
	
	process (sPosX,sPosY,
	  		 inSyncVHP,soldSyncVHP,
			 sBayerX,sBayerY,sDeltaX,sDeltaY,
			 sReadEn,sData,sQ,
			 soutSyncVHP)
	begin
	
		-- Mémorisation
		sBayerX_Futur <= sBayerX;							-- BAY
		sBayerY_Futur <= sBayerY;							-- BAY
		sDeltaX_Futur <= sDeltaX;							-- BAY
		sDeltaY_Futur <= sDeltaY;							-- BAY
		
		sReadEn_Futur  <= '0';								-- FIFO
		sWriteEn_Futur <= (others=>'0');					-- FIFO
		
		-- Création des Signaux de Synchro en Sortie
		soutSyncVHP_Futur(0)(2) <= inSyncVHP(2);			-- OUT
		soutSyncVHP_Futur(0)(1) <= soutSyncVHP(0)(1) or		-- OUT
								   sReadEn;					-- OUT
		soutSyncVHP_Futur(0)(0) <= sReadEn;					-- OUT
		
		case inSyncVHP(2 downto 1) is
		
		-- Pause Image, en attendant la Nouvelle  -----------
		when "00"=>
		
			sBayerX_Futur <= sPosX; 						-- BAY
			sBayerY_Futur <= sPosY; 						-- BAY
			sDeltaX_Futur <= G; 							-- BAY
			sDeltaY_Futur <= H; 							-- BAY
		
		-- Pause Ligne, en attendant la Nouvelle ------------
		when "10"=>

			sBayerX_Futur <= sPosX; 						-- BAY
			sDeltaX_Futur <= G; 							-- BAY
		
			-- La Prochaine Ligne ...
			if soldSyncVHP(1)='1' then						-- SYN
				sBayerY_Futur <= Ne_BayerPosY(sBayerY);		-- BAY
				sDeltaY_Futur <= Ne_BayerPosY(sDeltaY);		-- BAY
				soutSyncVHP_Futur(0)(1) <= '0';				-- OUT
			end if;
		
		-- Nouveau Pixel d'une Ligne ------------------------
		when "11"=>
		
			if inSyncVHP(0)='1' then						-- SYN
		
				-- Le Prochain Pixel ...
				sBayerX_Futur <= Ne_BayerPosX(sBayerX);		-- BAY
				sDeltaX_Futur <= Ne_BayerPosX(sDeltaX);		-- BAY
			
				-- Ligne Impaire -> Stockage
				if sDeltaY=H then							-- BAY
					sWriteEn_Futur(sDeltaX) <= '1';			-- FIFO

				else -- Ligne Paire -> Lecture
					if sDeltaX=G then						-- BAY
						sReadEn_Futur <= '1';				-- FIFO
					end if;
				end if;
			
			end if;
		
		when others=>null;
		
		end case;
		
	end process;
 
end STRUCT;