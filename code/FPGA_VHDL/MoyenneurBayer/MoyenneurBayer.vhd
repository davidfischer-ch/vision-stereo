--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : MoyenneurBayer
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- A partir des signaux d'image et de synchronisation provenant
-- d'une Caméra  Couleur CMOS  ce module  s'occupe de regrouper
-- séparément  chaque couleur du filtre de Bayer pour en sortir 
-- une composante moyenne. Le taux de réduction est donné selon
-- un  facteur en largeur  et en hauteur (en pixels). En sortie
-- nous  obtenons  des signaux  pouvant êtres  utilisés  par un
-- système de décodage de Bayer standard

-- Le pipeline  de division contient un LPM_Divide,  donc les
-- signaux de synchronisations subissent un retard grâce à un
-- registre à décalage...

--=============================================================--

-- Pipe | Fréqu. | Logique | MOTS-RAM   | Latence    | Lignes | CRC
--  1   | 39 MHz | 563 LE  | 256-17'920 | ->groupe+2 |  515   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : multiplexage [Pipe=3] de la division (Gauche/Droite)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity MoyenneurBayer is

	generic (Pipe : natural := 1;
			 RAM_TailleMots : natural := 256;
			 RAM_TailleBits : natural := 8);
	
	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de ZonesBayer
		
		  inCfgMoyX   : in tNombre6;
		  inCfgMoyY   : in tNombre6;
		  inCfgMoyPre : in tPrediv5;
		  inCfgMoyDiv : in tNombre6;
		
	      inSyncVHP : in tSyncVHP;
	      inCouleur : in tColor10;
	
		  -- SIGNAUX vers Bayer_a_RVB
		
		  outSyncVHP : out tSyncVHP;
		  outCouleur : out tColor10;
		  
		  testPosY : out tPosition6);

end MoyenneurBayer;

--=============================================================--

architecture STRUCT of MoyenneurBayer is

	-- Mémoire RAM M4K
	component RAM_Couleur is
		generic (TailleMots, TailleBits : natural);
		port (aclr		: in  std_logic := '0';
			  clock		: in  std_logic;
			  data		: in  tColor16;
			  rdaddress	: in  tAdresse8;
			  wraddress	: in  tAdresse8;
			  wren		: in  std_logic;
			  q		    : out tColor16);
	end component;
			
	-- Diviseur 16bits/6bits pipeliné
	component Diviseur16bits6bits is
		generic (Pipe : natural);
		port (aclr		: in  std_logic;
			  clock		: in  std_logic;
			  denom		: in  tNombre6;
			  numer		: in  tColor16;
			  quotient	: out tColor16;
			  remain	: out tNombre6);
	end component;
	
	-- Types spéciaux pour MoyenneurBayer ========================--

	type tBayerPosY_Color8    is array (tBayerPosY) of tColor8;
	type tBayerPosY_Adresse8  is array (tBayerPosY) of tAdresse8;
	type tBayerPosY_std_logic is array (tBayerPosY) of std_logic;
	
	type tBayerMat_Position11 is array (tBayerMat) of tPosition11;
	type tBayerMat_Color16    is array (tBayerMat) of tColor16;
	type tBayerMat_Adresse8   is array (tBayerMat) of tAdresse8;
	type tBayerMat_std_logic  is array (tBayerMat) of std_logic;
	
	type tRegBayerPosY_Adresse8 is array (0 to 3)
		 of tBayerPosY_Adresse8;
	
	type tRegSyncVHP is array (0 to Pipe) of tSyncVHP;
	
	-- Registres Internes & co ===================================--
	
	-- Mise en Registre des Entrées, nécessaire pour
	-- la Détection de Flanc (IN)
	signal sinCfgMoyX,   sinCfgMoyX_Futur   : tNombre6;
	signal sinCfgMoyY,   sinCfgMoyY_Futur   : tNombre6;
	signal sinCfgMoyPre, sinCfgMoyPre_Futur : tPrediv5;
	signal sinCfgMoyDiv, sinCfgMoyDiv_Futur : tNombre6;
	
	signal sinSyncVHP,  sinSyncVHP_Futur  : tSyncVHP;
	signal soldSyncVHP, soldSyncVHP_Futur : tSyncVHP;
	signal sinCouleur,  sinCouleur_Futur  : tColor10;
	
	signal sinCouleur16 : tColor16;
	
	-- Positionnement dans le Motif de Bayer (BAY)
	signal sDeltaX, sDeltaX_Futur : tBayerPosX;
	signal sDeltaY, sDeltaY_Futur : tBayerPosY;
	signal sNoPixX, sNoPixX_Futur : tPosition6;
	
	-- Déplacements dans les RAMs (DEP)
	signal sRdAd, sRdAd_Futur : tAdresse8;
	signal sWrAd, sWrAd_Futur : tAdresse8;
	signal sVaAd, sVaAd_Futur : tAdresse8;
	
	type tRegStdLogic is array (2 downto 0) of std_logic;

	signal sValideY, sValideY_Futur : tRegStdLogic;
	
	-- Signaux de Gestion de la PositionY (POSY)
	signal sPosY : tPosition6;
	signal sDataY, sDataY_Futur : tPosition6;
	signal sWrEnY, sWrEnY_Futur : std_logic;
	signal sQY                  : tColor16;
	
	-- Signaux de Gestion de la RAM (RAM)
	signal sData, sData_Futur : tBayerMat_Color16;
	signal sWrEn, sWrEn_Futur : tBayerMat_std_logic;
	signal sQ                 : tBayerMat_Color16;
	
	-- Signaux de Gestion du Mutltiplexage (MUX)
	signal sDataN, sDataN_Futur : tColor16;
	signal sWrEnN_Futur : std_logic;
	signal sQN 		    : tColor16;
	
	-- Signaux de Synchro / Couleur pour Diviseur (DIV)
	signal sdivSyncVHP,  sdivSyncVHP_Futur  : tSyncVHP;
	signal sdivCouleur,  sdivCouleur_Futur  : tColor16;
	signal sdivDiviseur, sdivDiviseur_Futur : tNombre6;
	
	-- Signaux de Synchro / Couleur en Sortie (OUT)
	signal soutSyncVHP, soutSyncVHP_Futur : tRegSyncVHP;
	signal soutCouleur, soutCouleur_Futur : tColor16;

begin --=======================================================--

	-- Notre Mémoire M4K (Verte)
	RAM_Couleur_HG : RAM_Couleur
		generic map (TailleMots => RAM_TailleMots,
					 TailleBits => RAM_TailleBits)
		port map (aclr		=> '0',
			  	  clock		=> Clock24MHz,
			  	  data		=> sData(HG),
			  	  rdaddress	=> sRdAd,
			  	  wraddress	=> sWrAd,
			  	  wren		=> sWrEn(HG),
			  	  q		    => sQ(HG));
			
	-- Notre Mémoire M4K (Rouge)
	RAM_Couleur_HD : RAM_Couleur
		generic map (TailleMots => RAM_TailleMots,
					 TailleBits => RAM_TailleBits)
		port map (aclr		=> '0',
			  	  clock		=> Clock24MHz,
			  	  data		=> sData(HD),
			  	  rdaddress	=> sRdAd,
			  	  wraddress	=> sWrAd,
			  	  wren		=> sWrEn(HD),
			  	  q		    => sQ(HD));
			
	-- Notre Mémoire M4K (Bleu)
	RAM_Couleur_BG : RAM_Couleur
		generic map (TailleMots => RAM_TailleMots,
					 TailleBits => RAM_TailleBits)
		port map (aclr		=> '0',
			  	  clock		=> Clock24MHz,
			  	  data		=> sData(BG),
			  	  rdaddress	=> sRdAd,
			  	  wraddress	=> sWrAd,
			  	  wren		=> sWrEn(BG),
			  	  q		    => sQ(BG));
			
	-- Notre Mémoire M4K (Verte2)
	RAM_Couleur_BD : RAM_Couleur
		generic map (TailleMots => RAM_TailleMots,
					 TailleBits => RAM_TailleBits)
		port map (aclr		=> '0',
			  	  clock		=> Clock24MHz,
			  	  data		=> sData(BD),
			  	  rdaddress	=> sRdAd,
			  	  wraddress	=> sWrAd,
			  	  wren		=> sWrEn(BD),
			  	  q		    => sQ(BD));
			
	-- Notre Mémoire M4K (NoPosY)
	RAM_NoPosY : RAM_Couleur
		generic map (TailleMots => RAM_TailleMots,
					 TailleBits => RAM_TailleBits)
		port map (aclr		=> '0',
			  	  clock		=> Clock24MHz,
			  	  data		=> "0000000000"&sDataY,
			  	  rdaddress	=> sRdAd,
			  	  wraddress	=> sWrAd,
			  	  wren		=> sWrEnY,
			  	  q		    => sQY);
			
	-- Notre Diviseur 16bits/6bits pipeliné
	Diviseur16bits6bits_inst : Diviseur16bits6bits
		generic map (Pipe => Pipe)
		port map (aclr	   => not nReset,
				  clock	   => Clock24MHz,
				  denom	   => sdivDiviseur,
				  numer	   => sdivCouleur,
				  quotient => soutCouleur_Futur);
			
	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
	
		if nReset='0' then
		
			sinCfgMoyX   <= to_unsigned(nPerMoyX,6);		-- IN
			sinCfgMoyY   <= to_unsigned(nPerMoyY,6);		-- IN
			sinCfgMoyPre <= to_unsigned(nPerMoyPre,5);		-- IN
			sinCfgMoyDiv <= to_unsigned(nPerMoyDiv,6);		-- IN
	
			sinSyncVHP  <= "000";							-- IN
			soldSyncVHP <= "000";  							-- IN
			sinCouleur  <= (others=>'0');					-- IN

			sDeltaX <= G; 									-- BAY
			sDeltaY <= H; 									-- BAY
			sNoPixX <= (others=>'0'); 						-- BAY
			
			sRdAd <= (others=>'0');							-- DEP
			sWrAd <= (others=>'0');							-- DEP
			sVaAd <= (others=>'0');							-- DEP
			
			sValideY <= (others=>'0');
		
			sDataY <= (others=>'0');						-- POSY
			sWrEnY <= '0';									-- POSY
			
			sData <= (others=>(others=>'0')); 				-- RAM
			sWrEn <= (others=>'0');           				-- RAM
			
			sdivSyncVHP  <= "000"; 							-- DIV
			sdivCouleur  <= (others=>'0'); 					-- DIV
			sdivDiviseur <= "000001";						-- DIV
					
			soutSyncVHP <= (others=>"000");					-- OUT
			soutCouleur <= (others=>'0'); 					-- OUT
	
		elsif rising_edge(Clock24MHz) then
		
			sinCfgMoyX   <= sinCfgMoyX_Futur; 				-- IN
			sinCfgMoyY   <= sinCfgMoyY_Futur; 				-- IN
			sinCfgMoyPre <= sinCfgMoyPre_Futur;				-- IN
			sinCfgMoyDiv <= sinCfgMoyDiv_Futur; 			-- IN
	
			sinSyncVHP  <= sinSyncVHP_Futur;  				-- IN
			soldSyncVHP <= soldSyncVHP_Futur; 				-- IN
			sinCouleur  <= sinCouleur_Futur; 				-- IN
				
			sDeltaX <= sDeltaX_Futur; 						-- BAY
			sDeltaY <= sDeltaY_Futur; 						-- BAY
			sNoPixX <= sNoPixX_Futur; 						-- BAY
			
			sRdAd <= sRdAd_Futur;							-- DEP
			sWrAd <= sWrAd_Futur;							-- DEP
			sVaAd <= sVaAd_Futur;							-- DEP
			
			sValideY <= sValideY_Futur;
			
			sDataY <= sDataY_Futur;							-- POSY
			sWrEnY <= sWrEnY_Futur;							-- POSY
			
			sData <= sData_Futur;      						-- RAM
			sWrEn <= sWrEn_Futur;   						-- RAM

			sdivSyncVHP  <= sdivSyncVHP_Futur; 				-- DIV
			sdivCouleur  <= sdivCouleur_Futur; 				-- DIV
			sdivDiviseur <= sdivDiviseur_Futur;				-- DIV
			
			soutSyncVHP <= soutSyncVHP_Futur; 				-- OUT
			soutCouleur <= soutCouleur_Futur; 				-- OUT

		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	testPosY <= sPosY;
	
	sinCfgMoyX_Futur   <= inCfgMoyX-1;						-- IN
	sinCfgMoyY_Futur   <= inCfgMoyY-1;						-- IN
	sinCfgMoyPre_Futur <= inCfgMoyPre;						-- IN
	sinCfgMoyDiv_Futur <= inCfgMoyDiv;						-- IN
	
	sinSyncVHP_Futur  <= inSyncVHP; 						-- IN
	soldSyncVHP_Futur <= sinSyncVHP; 						-- IN
	sinCouleur_Futur  <= inCouleur;							-- IN
	
	with sinCfgMoyPre select
	sinCouleur16 <= "000000"&sinCouleur(9 downto 0) when "00001",
			       "0000000"&sinCouleur(9 downto 1) when "00010",
			      "00000000"&sinCouleur(9 downto 2) when "00100",
      		     "000000000"&sinCouleur(9 downto 3) when "01000",
   		        "0000000000"&sinCouleur(9 downto 4) when "10000",
	      "0000000000000000" when others; 					-- IN
	
	soutSyncVHP_Futur(0) <= sdivSyncVHP;					-- DIV
	soutSyncVHP_Futur(1 to Pipe)
	   <= soutSyncVHP(0 to Pipe-1);							-- DIV
	
	outSyncVHP <= soutSyncVHP(Pipe);						-- OUT
	outCouleur <= soutCouleur(tColor10'high downto 0);		-- OUT
	
	-- Processus de Muliplexage ==================================--
				
	process (sDeltaY,sDeltaX,sData,sQ,
			 sDataN_Futur,sWrEnN_Futur)
	begin
		-- Mémorisation
		sDataN <= (others=>'0');							-- MUX
		sQN    <= (others=>'0');							-- MUX
		
		sData_Futur <= sData;								-- RAM
		sWrEn_Futur <= (others=>'0');						-- RAM
		
		if sDeltaY=H and sDeltaX=G then						-- BAY
			sDataN <= sData(HG);							-- MUX
			sQN    <= sQ(HG);								-- MUX
			sData_Futur(HG) <= sDataN_Futur;				-- MUX
			sWrEn_Futur(HG) <= sWrEnN_Futur;				-- MUX
		
		elsif sDeltaY=H and sDeltaX=D then					-- BAY
			sDataN <= sData(HD);							-- MUX
			sQN    <= sQ(HD);								-- MUX
			sData_Futur(HD) <= sDataN_Futur;				-- MUX
			sWrEn_Futur(HD) <= sWrEnN_Futur;				-- MUX
		
		elsif sDeltaY=B and sDeltaX=G then					-- BAY
			sDataN <= sData(BG);							-- MUX
			sQN    <= sQ(BG);								-- MUX
			sData_Futur(BG) <= sDataN_Futur;				-- MUX
			sWrEn_Futur(BG) <= sWrEnN_Futur;				-- MUX
		
		elsif sDeltaY=B and sDeltaX=D then					-- BAY
			sDataN <= sData(BD);							-- MUX
			sQN    <= sQ(BD);								-- MUX
			sData_Futur(BD) <= sDataN_Futur;				-- MUX
			sWrEn_Futur(BD) <= sWrEnN_Futur;				-- MUX
		end if;
		
	end process;	
	
	-- Processus de Moyennage ====================================--
	
	sValideY_Futur(2 downto 1) <= sValideY(1 downto 0);
	sValideY_Futur(0) <= '1' when sVaAd>sRdAd else '0';
	
	sPosY <= sQY(tPosition6'high downto 0) when sValideY(2)='1' else (others=>'0');
		
	-- Quand nous incrémenterons la position Y...
	sDataY_Futur <= Mod_Position6(sPosY,sinCfgMoyY); -- POSY
	
	process (sinCfgMoyX,sinCfgMoyY,sinCfgMoyDiv,
			 inSyncVHP,sinSyncVHP,soldSyncVHP,sinCouleur16,
			 sDeltaX,sDeltaY,sNoPixX,sPosY,sRdAd,sWrAd,sVaAd,
			 sDataN,sQN,sdivSyncVHP)

		variable vCalcul : tColor16;
	begin
	
		sDeltaX_Futur <= sDeltaX;							-- BAY
		sDeltaY_Futur <= sDeltaY;							-- BAY
		sNoPixX_Futur <= sNoPixX;							-- BAY
		
		sRdAd_Futur <= sRdAd;								-- DEP
		sWrAd_Futur <= sWrAd;								-- DEP
		sVaAd_Futur <= sVaAd;								-- DEP
		
		sWrEnY_Futur <= '0';								-- POSY
		
		sDataN_Futur <= sDataN;								-- MUX
		sWrEnN_Futur <= '0';								-- MUX

		-- Création des signaux pour le Diviseur
		sdivSyncVHP_Futur(2) <= sinSyncVHP(2);				-- DIV
		sdivSyncVHP_Futur(1) <= sdivSyncVHP(1);				-- DIV
		sdivSyncVHP_Futur(0) <= '0';						-- DIV
		sdivCouleur_Futur    <= (others=>'0');				-- DIV
		sdivDiviseur_Futur   <= "000001";					-- DIV

		-- Pause Image, en attendant la Nouvelle  -----------
	
		if sinSyncVHP(2)='0' then							-- SYN
			sDeltaY_Futur <= H; 						  	-- BAY
			sVaAd_Futur   <= (others=>'0');					-- DEP
		end if;
		
		-- Pause Ligne, en attendant la Nouvelle ------------
		
		if sinSyncVHP(1)='0' then							-- SYN
			sDeltaX_Futur <= G; 						 	-- BAY
			sNoPixX_Futur <= (others=>'0'); 			 	-- BAY
			sRdAd_Futur   <= (others=>'0');					-- DEP
			sWrAd_Futur   <= (others=>'1');	 				-- DEP
		end if;
		
		-- dans le cas d'une config moyX=1 pré-incrémente RdAd		
		if sinCfgMoyX=0 and
			sinSyncVHP(1)='0' and inSyncVHP(1)='1' then		-- SYN
			sRdAd_Futur <= to_unsigned(1,8);				-- DEP
		end if;
		
		-- Nouveau Pixel d'une Ligne ------------------------
		
		if sinSyncVHP="111" then							-- SYN
		
			-- Le Prochain Pixel ...
			sDeltaX_Futur <= Ne_BayerPosX(sDeltaX);			-- BAY
			
			-- Nouveau "Groupe" (2) de Pixels
			if sDeltaX=D then								-- BAY
				sNoPixX_Futur <= Mod_Position6(sNoPixX,sinCfgMoyX);
			end if;

			-- Déplacement dans la Mémoire!
			if sDeltaX=G then								-- BAY
				if sNoPixX=0 then							-- BAY
					sWrAd_Futur <= sWrAd+1;					-- DEP
				end if;
			else
				if sNoPixX=(sinCfgMoyX-1) or sinCfgMoyX=0 then
					sRdAd_Futur <= sRdAd+1;					-- DEP
				end if;
			end if;
	
			-- 1er Pixel de la Ligne?
			if sNoPixX = 0 then								-- BAY
				 vCalcul := sinCouleur16;					-- RAM
			else vCalcul := sDataN+sinCouleur16;			-- RAM
			end if;

			-- Dernier Pixel de la Ligne?
			if sNoPixX = sinCfgMoyX then					-- BAY
			
				-- Nous devons stocker le résultat dans
				-- la RAM de la composante en cours...
				sWrEnN_Futur <= '1';						-- RAM

				-- Tout dernier!
				if sDeltaY=B and sDeltaX=D then				-- BAY
					sWrEnY_Futur <= '1';					-- POSY
					
					if sWrAd>=sVaAd then					-- DEP
						sVaAd_Futur <= sWrAd+1;				-- DEP
					end if;
				end if;
					
				-- Si nous avons déjà un début de résultat
				-- en RAM nous le prenons en compte!
				if sPosY > 0 then							-- POSY
					vCalcul := vCalcul+sQN;					-- RAM
				end if;
					
				-- Dernier Pixel du Groupe?
				if sPosY = sinCfgMoyY then   				-- POSY
				
					-- Nous allons donc envoyer un résultat
					-- dans le diviseur -> moyenne
					sdivSyncVHP_Futur(1) <= '1';			-- DIV
					sdivSyncVHP_Futur(0) <= '1';			-- DIV
					sdivDiviseur_Futur <= sinCfgMoyDiv;		-- DIV
					sdivCouleur_Futur  <= vCalcul;	   		-- DIV
				end if;
			end if;
				
			sDataN_Futur <= vCalcul;						-- RAM
			
		end if;
		
		-- Fin d'une Ligne, la Prochaine arrivera! ----------

		if sinSyncVHP(1)='0' and soldSyncVHP(1)='1' then	-- SYN
			sDeltaY_Futur <= Ne_BayerPosY(sDeltaY);			-- BAY
			sdivSyncVHP_Futur(1) <= '0';					-- DIV
		end if;
		
	end process;

end STRUCT;