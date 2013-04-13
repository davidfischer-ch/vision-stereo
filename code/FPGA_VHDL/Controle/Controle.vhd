--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : Controle
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Contrôle l'ensemble de la FPGA ainsi que
-- les Caméras, permet d'avoir une Interaction
-- avec l'extérieur via les signaux de commande

--=============================================================--

-- Fréqu.  | Logique | Latence   | Lignes | CRC
-- 216 MHz | 220 LE  | contrôle! |  621   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : gestion du fenêtrage de la caméra couleur
-- A FAIRE : gestion des ordres provenant de l'interface fx2
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity Controle is
		
	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de InterfaceFX2

		  inSyncCtrl : in std_logic;
		  inFluxCtrl : in tTrame16;
		
		  -- SIGNAUX de Pupille

		  inSyncPos : in std_logic;
		  inFluxPos : in tPosition16;

		  -- SIGNAUX vers InterfaceFX2
		
		  outCfgTypeFlux : out tTypeFlux;

		  -- SIGNAUX vers ZonesBayer
				
		  outCfgPerMoyX   : out tNombre6;
		  outCfgPerMoyY   : out tNombre6;
		  outCfgPerMoyPre : out tPrediv5;
		  outCfgPerMoyDiv : out tNombre6;
		
		  outCfgDetMoyX   : out tNombre6;
		  outCfgDetMoyY   : out tNombre6;
		  outCfgDetMoyPre : out tPrediv5;
		  outCfgDetMoyDiv : out tNombre6;
		
		  outCfgDetDebX : out tPosition11;
		  outCfgDetDebY : out tPosition11;
		  
		  outCfgDetFinX : out tPosition11;
		  outCfgDetFinY : out tPosition11;
		
		  -- SIGNAUX vers Bayer_a_RVB
		
		  outFluxPos : out tPosition22;
		
		  -- SIGNAUX vers les Caméras
		
		  busSCL : inout std_logic;
		  busSDA : inout std_logic;
		
		  outSO1 : out std_logic;
		  outSO2 : out std_logic;
		  outSO3 : out std_logic;
		  outSO4 : out std_logic);
		
end Controle;

--=============================================================--

architecture STRUCT of Controle is

	-- Gestion de l'I2C
	component GestionI2C is
		
	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  inSyncWDR    : in std_logic;
		  inDeviceWDR  : in tRegI2C;
		  inAdresseWDR : in tRegI2C;
		  inDonneeWDR  : in tRegI2C;
		
		  outOQP_WDR : out std_logic;
		  outIRQ_WDR : out std_logic;

		  -- SIGNAUX vers (les?) i2c_interface
		
		  busSCL : inout std_logic;
		  busSDA : inout std_logic);
		
	end component;
	
	-- Gestion du Temps
	component Temporisation is

	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  inSyncStart : in  std_logic;
		  inSecondes  : in  tNombre14;
		  outSyncStop : out std_logic;
		
		  outSeconde : out std_logic);
	
	end component;
	
	-- Gestion de l'Initialisation des Caméras
	
	constant cDevice9630 : tRegI2C := "10001000"; -- 0x88
	constant cDevice9648 : tRegI2C := "10101010"; -- 0xAA
	
	constant c9630_MCFG : tRegI2C := "00000001"; -- 0x01

	constant c9648_PWD_RST : tRegI2C := "00000110"; -- 0x06
	constant c9648_OPCTRL  : tRegI2C := "00001001"; -- 0x09
	
	constant c9648_DVBUSCONFIG1 : tRegI2C := "01010011"; -- 0x53
	constant c9648_DVBUSCONFIG2 : tRegI2C := "01010100"; -- 0x54
	
	constant c9648_ITIMEH : tRegI2C := "00100100"; -- 0x24
	constant c9648_ITIMEL : tRegI2C := "00100101"; -- 0x25
	
	constant c9648_FDELAYH : tRegI2C := "00100000"; -- 0x20
	constant c9648_FDELAYL : tRegI2C := "00100001"; -- 0x21
	constant c9648_RDELAYH : tRegI2C := "00100010"; -- 0x22
	constant c9648_RDELAYL : tRegI2C := "00100011"; -- 0x23
	
	constant c9648_WROWS   : tRegI2C := "00011001"; -- 0x19
	constant c9648_WROWE   : tRegI2C := "00011010"; -- 0x1A
	constant c9648_WROWLSB : tRegI2C := "00011011"; -- 0x1B
	constant c9648_WCOLS   : tRegI2C := "00011100"; -- 0x1C
	constant c9648_WCOLE   : tRegI2C := "00011101"; -- 0x1D
	constant c9648_WCOLLSB : tRegI2C := "00011110"; -- 0x1E

	-- Registres Internes & co ===================================--
	
	alias sFluxCtrl_Ordre   is inFluxCtrl (15 downto 8);
	alias sFluxCtrl_Nombre1 is inFluxCtrl (0);
	alias sFluxCtrl_Nombre3 is inFluxCtrl (2 downto 0);
	alias sFluxCtrl_Nombre6 is inFluxCtrl (5 downto 0);
	alias sFluxCtrl_Nombre8 is inFluxCtrl (7 downto 0);
	
	alias sFluxPosX is inFluxPos(15 downto 8);
	alias sFluxPosY is inFluxPos( 7 downto 0);
	
	constant cFluxCtrl_TypeFlux : tNombre8 := "00000000";
	constant cFluxCtrl_PosPupX  : tNombre8 := "00000001";
	constant cFluxCtrl_PosPupY  : tNombre8 := "00000010";
	
	-- MACHINE D'ETAT DE LA LOGIQUE DE CONTROLE ==================--
	
	signal so1, so1_Futur : std_logic;
	signal so2, so2_Futur : std_logic;
	signal so3, so3_Futur : std_logic;
	signal so4, so4_Futur : std_logic;
	
	type tEtatCtrl is (PowerOn,DelaiOn,ConfigCams,Principal);
	
	signal sEtatCtrl,   sEtatCtrl_Futur   : tEtatCtrl;
	signal sConfigCams, sConfigCams_Futur : std_logic;
	signal sCompteur,   sCompteur_Futur   : tNombre5;
	
	-- GESTION DU TEMPORISATEUR
	
	signal sSyncStart, sSyncStart_Futur : std_logic;
	signal sSecondes,  sSecondes_Futur  : tNombre14;
	signal sSyncStop : std_logic;
	
	-- GESTION DE L'ECRITURE EN I2C
	signal sSyncWDR,    sSyncWDR_Futur    : std_logic;
	signal sDeviceWDR,  sDeviceWDR_Futur  : tRegI2C;
	signal sAdresseWDR, sAdresseWDR_Futur : tRegI2C;
	signal sDonneeWDR,  sDonneeWDR_Futur  : tRegI2C;
	signal sOQP_WDR : std_logic;
	signal sIRQ_WDR : std_logic;
	
	-- CONFIGURATION DU TYPE DE FLUX (RVB/HSL)
	signal soutCfgTypeFlux, soutCfgTypeFlux_Futur : tTypeFlux;

	-- CONFIGURATION DE LA CREATION DE ZONES (MOYENNEUR)
	signal soutCfgPerMoyX,   soutCfgPerMoyX_Futur   : tNombre6;
	signal soutCfgPerMoyY,   soutCfgPerMoyY_Futur   : tNombre6;
	signal soutCfgPerMoyPre, soutCfgPerMoyPre_Futur : tPrediv5;
	signal soutCfgPerMoyDiv, soutCfgPerMoyDiv_Futur : tNombre6;
	
	signal soutCfgDetMoyX,   soutCfgDetMoyX_Futur   : tNombre6;
	signal soutCfgDetMoyY,   soutCfgDetMoyY_Futur   : tNombre6;
	signal soutCfgDetMoyPre, soutCfgDetMoyPre_Futur : tPrediv5;
	signal soutCfgDetMoyDiv, soutCfgDetMoyDiv_Futur : tNombre6;
	
	signal soutCfgDetDebX, soutCfgDetDebX_Futur : tPosition11;
	signal soutCfgDetDebY, soutCfgDetDebY_Futur : tPosition11;
		  
	signal soutCfgDetFinX, soutCfgDetFinX_Futur : tPosition11;
	signal soutCfgDetFinY, soutCfgDetFinY_Futur : tPosition11;
	
	-- CONFIGURATION DU POSITIONNEMENT (FENETRAGE)
	signal sCfgFenetreDebX, sCfgFenetreDebX_Futur : tPosition11;
	signal sCfgFenetreDebY, sCfgFenetreDebY_Futur : tPosition11;
	
	signal sCfgFenetreFinX, sCfgFenetreFinX_Futur : tPosition11;
	signal sCfgFenetreFinY, sCfgFenetreFinY_Futur : tPosition11;
			
begin --=======================================================--

	-- Notre Gestion de l'I2C
	GestionI2C_inst : GestionI2C
		port map (Clock24MHz => Clock24MHz,
		  		  nReset     => nReset,
				  inSyncWDR    => sSyncWDR,
				  inDeviceWDR  => sDeviceWDR,
				  inAdresseWDR => sAdresseWDR,
				  inDonneeWDR  => sDonneeWDR,
				  outOQP_WDR   => sOQP_WDR,
				  outIRQ_WDR   => sIRQ_WDR,
				  busSCL => busSCL,
				  busSDA => busSDA);
			
	-- Notre Gestion du Temps	
	Temporisation_inst : Temporisation
		port map (Clock24MHz => Clock24MHz,
		  		  nReset     => nReset,
		  		  inSyncStart => sSyncStart,
		  		  inSecondes  => sSecondes,
		  		  outSyncStop => sSyncStop);

	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
	
		if nReset='0' then
		
			so1 <= '0';
			so2 <= '0';
			so3 <= '0';
			so4 <= '0';
		
			sEtatCtrl   <= PowerOn;
			sConfigCams <= '0';
			sCompteur   <= (others=>'0');
		
			sSyncStart <= '0';
			sSecondes  <= (others=>'0');
			
			sSyncWDR    <= '0';
			sDeviceWDR  <= (others=>'0');
			sAdresseWDR <= (others=>'0');
			sDonneeWDR  <= (others=>'0');
		
			soutCfgTypeFlux <= cDefCfgTypeFlux;
		
			soutCfgPerMoyX   <= to_unsigned(nPerMoyX,6);
			soutCfgPerMoyY   <= to_unsigned(nPerMoyY,6);
			soutCfgPerMoyPre <= to_unsigned(nPerMoyPre,5);
			soutCfgPerMoyDiv <= to_unsigned(nPerMoyDiv,6);

			soutCfgDetMoyX   <=  to_unsigned(nDetMoyX,6);
			soutCfgDetMoyY   <=  to_unsigned(nDetMoyY,6);
			soutCfgDetMoyPre <=  to_unsigned(nDetMoyPre,5);
			soutCfgDetMoyDiv <=  to_unsigned(nDetMoyDiv,6);
			
			soutCfgDetDebX <=  to_unsigned(nDetDebX,11);
			soutCfgDetDebY <=  to_unsigned(nDetDebY,11);
			
			soutCfgDetFinX <=  to_unsigned(nDetFinX,11);
			soutCfgDetFinY <=  to_unsigned(nDetFinY,11);
			
			sCfgFenetreDebX <=  to_unsigned(nFenetreDebX,11);
			sCfgFenetreDebY <=  to_unsigned(nFenetreDebY,11);
			
			sCfgFenetreFinX <=  to_unsigned(nFenetreFinX,11);
			sCfgFenetreFinY <=  to_unsigned(nFenetreFinY,11);
	
		elsif rising_edge (Clock24MHz) then
		
			so1 <= so1_Futur;
			so2 <= so2_Futur;
			so3 <= so3_Futur;
			so4 <= so4_Futur;
		
			sEtatCtrl   <= sEtatCtrl_Futur;
			sConfigCams <= sConfigCams_Futur;
			sCompteur   <= sCompteur_Futur;
			
			sSyncStart <= sSyncStart_Futur;
			sSecondes  <= sSecondes_Futur;
			
			sSyncWDR    <= sSyncWDR_Futur;
			sDeviceWDR  <= sDeviceWDR_Futur;
			sAdresseWDR <= sAdresseWDR_Futur;
			sDonneeWDR  <= sDonneeWDR_Futur;
			
			soutCfgTypeFlux <= soutCfgTypeFlux_Futur;
		
			soutCfgPerMoyX   <= soutCfgPerMoyX_Futur;
			soutCfgPerMoyY   <= soutCfgPerMoyY_Futur;
			soutCfgPerMoyPre <= soutCfgPerMoyPre_Futur;
			soutCfgPerMoyDiv <= soutCfgPerMoyDiv_Futur;

			soutCfgDetMoyX   <= soutCfgDetMoyX_Futur;
			soutCfgDetMoyY   <= soutCfgDetMoyY_Futur;
			soutCfgDetMoyPre <= soutCfgDetMoyPre_Futur;
			soutCfgDetMoyDiv <= soutCfgDetMoyDiv_Futur;
			
			soutCfgDetDebX <= soutCfgDetDebX_Futur;
			soutCfgDetDebY <= soutCfgDetDebY_Futur;
			
			soutCfgDetFinX <= soutCfgDetFinX_Futur;
			soutCfgDetFinY <= soutCfgDetFinY_Futur;
			
			sCfgFenetreDebX <= sCfgFenetreDebX_Futur;
			sCfgFenetreDebY <= sCfgFenetreDebY_Futur;
			
			sCfgFenetreFinX <= sCfgFenetreFinX_Futur;
			sCfgFenetreFinY <= sCfgFenetreFinY_Futur;
					
		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	outCfgTypeFlux <= soutCfgTypeFlux;
	
	outCfgPerMoyX   <= soutCfgPerMoyX;
	outCfgPerMoyY   <= soutCfgPerMoyY;
	outCfgPerMoyPre <= soutCfgPerMoyPre;
	outCfgPerMoyDiv <= soutCfgPerMoyDiv;
	
	outCfgDetMoyX   <= soutCfgDetMoyX;
	outCfgDetMoyY   <= soutCfgDetMoyY;
	outCfgDetMoyPre <= soutCfgDetMoyPre;
	outCfgDetMoyDiv <= soutCfgDetMoyDiv;
	
	outCfgDetDebX <= soutCfgDetDebX;
	outCfgDetDebY <= soutCfgDetDebY;
			
	outCfgDetFinX <= soutCfgDetFinX;
	outCfgDetFinY <= soutCfgDetFinY;
	
	outFluxPos <= sCfgFenetreDebX&sCfgFenetreDebY;
	
	-- Processus de Contrôle =====================================--
	
	outSO1 <= so1;
	outSO2 <= so2;
	outSO3 <= so3;
	outSO4 <= so4;
	
	so1_Futur <= '1' when sEtatCtrl=PowerOn    else '0';
	so2_Futur <= '1' when sEtatCtrl=DelaiOn    else '0';
	so3_Futur <= '1' when sEtatCtrl=ConfigCams else '0';
	so4_Futur <= '1' when sEtatCtrl=Principal  else '0';
	
	process (inSyncCtrl,inSyncPos,
			 sEtatCtrl,sCompteur,
			 soutCfgTypeFlux,
			 sSyncStop,sIRQ_WDR,sConfigCams,
			 soutCfgPerMoyX,soutCfgPerMoyY,
			 soutCfgPerMoyPre,soutCfgPerMoyDiv,
			 soutCfgDetMoyX,soutCfgDetMoyY,
			 soutCfgDetMoyPre,soutCfgDetMoyDiv,
			 soutCfgDetDebX,soutCfgDetDebY,
			 soutCfgDetFinX,soutCfgDetFinY,
			 sCfgFenetreDebX,sCfgFenetreDebY,
			 sCfgFenetreFinX,sCfgFenetreFinY)
			
		variable vNombre : tNombre16;
		variable vDebut  : tPosition11;
	begin
	
		sSyncStart_Futur <= '0';
		sSecondes_Futur  <= (others=>'0');
	
		sSyncWDR_Futur    <= '0';
		sDeviceWDR_Futur  <= (others=>'0');
		sAdresseWDR_Futur <= (others=>'0');
		sDonneeWDR_Futur  <= (others=>'0');
		
		soutCfgTypeFlux_Futur <= soutCfgTypeFlux;

		soutCfgPerMoyX_Futur   <= soutCfgPerMoyX;
		soutCfgPerMoyY_Futur   <= soutCfgPerMoyY;
		soutCfgPerMoyPre_Futur <= soutCfgPerMoyPre;
		soutCfgPerMoyDiv_Futur <= soutCfgPerMoyDiv;

		soutCfgDetMoyX_Futur   <= soutCfgDetMoyX;
		soutCfgDetMoyY_Futur   <= soutCfgDetMoyY;
		soutCfgDetMoyPre_Futur <= soutCfgDetMoyPre;
		soutCfgDetMoyDiv_Futur <= soutCfgDetMoyDiv;
			
		soutCfgDetDebX_Futur <= soutCfgDetDebX;
		soutCfgDetDebY_Futur <= soutCfgDetDebY;
				
		soutCfgDetFinX_Futur <= soutCfgDetFinX;
		soutCfgDetFinY_Futur <= soutCfgDetFinY;
		
		sCfgFenetreDebX_Futur <= sCfgFenetreDebX;
		sCfgFenetreDebY_Futur <= sCfgFenetreDebY;
		
		sCfgFenetreFinX_Futur <= sCfgFenetreFinX;
		sCfgFenetreFinY_Futur <= sCfgFenetreFinY;
		
		-- Gestion de la Machine d'Etat ---------------------
		
		sEtatCtrl_Futur   <= sEtatCtrl;
		sConfigCams_Futur <= '0';
		sCompteur_Futur   <= sCompteur;
		
		case sEtatCtrl is
		
		when PowerOn =>
		
			-- Tiens je me réveille...
			
			sEtatCtrl_Futur  <= DelaiOn;
			--sSyncStart_Futur <= '1';
			--sSecondes_Futur  <= to_unsigned(5,14);
			
		when DelaiOn =>
		
			-- Délai de 5 secondes...
			
			--if sSyncStop='1' then
				sEtatCtrl_Futur   <= ConfigCams;
				sConfigCams_Futur <= '1';
				sCompteur_Futur   <= (others=>'0');
			--end if;
			
		when ConfigCams =>
		
			-- Initialisation des Caméras
		
			-- A chaque accusé ou départ...
			if sIRQ_WDR='1' or sConfigCams='1' then
			
				sCompteur_Futur <= sCompteur+1;
			
				case sCompteur is
		
				-- CAMÉRA MONOCHROME - MASTER
				when to_unsigned(0,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9630;
					sAdresseWDR_Futur <= c9630_MCFG;
					sDonneeWDR_Futur  <= "00000000"; -- 0x00
				
				-- CAMÉRA COULEUR - RESET
				when to_unsigned(1,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_PWD_RST;
					sDonneeWDR_Futur  <= "00000010"; -- 0x02
				
				-- CAMÉRA COULEUR - MASTER + LOW LIGHT
				when to_unsigned(2,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_OPCTRL;
					sDonneeWDR_Futur  <= "00001111"; -- 0x07
				
				-- CAMÉRA COULEUR - SYNCHROS ACTIF POSITIF
				when to_unsigned(3,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_DVBUSCONFIG1;
					sDonneeWDR_Futur  <= "00001011"; -- 0x0B
				
				-- CAMÉRA COULEUR - PAS DE PIXEL BLACK	
				when to_unsigned(4,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_DVBUSCONFIG2;
					sDonneeWDR_Futur  <= "10110000"; -- 0xB0
					
				-- CAMÉRA COULEUR - TEMPS D'INTÉGRATION
--				when to_unsigned(5,5)=>
--					sSyncWDR_Futur    <= '1';
--					sDeviceWDR_Futur  <= cDevice9648;
--					sAdresseWDR_Futur <= c9648_ITIMEH;
--					sDonneeWDR_Futur  <= "0000"&"0000"; -- 0x00
					
--				when to_unsigned(6,5)=>
--					sSyncWDR_Futur    <= '1';
--					sDeviceWDR_Futur  <= cDevice9648;
--					sAdresseWDR_Futur <= c9648_ITIMEL;
--					sDonneeWDR_Futur  <= '0'&"1000000"; -- 0x00
					
				-- CAMÉRA COULEUR - DÉLAI DE LIGNE
				when to_unsigned(5,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_RDELAYH;
					sDonneeWDR_Futur  <= cDefCfgDelaiLigne(12 downto 5);

				when to_unsigned(6,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_RDELAYL;
					sDonneeWDR_Futur  <= "000"&cDefCfgDelaiLigne(4 downto 0);
					
				-- CAMÉRA COULEUR - DÉLAI D'IMAGE
				when to_unsigned(7,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_FDELAYH;
					sDonneeWDR_Futur  <= cDefCfgDelaiImage(14 downto 7);
										
				when to_unsigned(8,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_FDELAYL;
					sDonneeWDR_Futur  <= '0'&cDefCfgDelaiImage(6 downto 0);
					
				-- CAMERA COULEUR - CONFIGURATION DU FENÊTRAGE
				when to_unsigned(9,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WROWS;
					sDonneeWDR_Futur  <= sCfgFenetreDebY(10 downto 3);
					
				when to_unsigned(10,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WROWE;
					sDonneeWDR_Futur  <= sCfgFenetreFinY(10 downto 3);
					
				when to_unsigned(11,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WROWLSB;
					sDonneeWDR_Futur  <= "00"&sCfgFenetreDebY(2 downto 0)
										     &sCfgFenetreFinY(2 downto 0);
				when to_unsigned(12,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WCOLS;
					sDonneeWDR_Futur  <= sCfgFenetreDebX(10 downto 3);
					
				when to_unsigned(13,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WCOLE;
					sDonneeWDR_Futur  <= sCfgFenetreFinX(10 downto 3);
					
				when to_unsigned(14,5)=>
					sSyncWDR_Futur    <= '1';
					sDeviceWDR_Futur  <= cDevice9648;
					sAdresseWDR_Futur <= c9648_WCOLLSB;
					sDonneeWDR_Futur  <= "00"&sCfgFenetreDebX(2)&"00"
										     &sCfgFenetreFinX(2 downto 0);
			
				when others=> sEtatCtrl_Futur <= Principal;
				end case;
				
			end if;
		
		when Principal =>
		
				if inSyncPos='1' then
					sEtatCtrl_Futur   <= ConfigCams;
					sConfigCams_Futur <= '1';
					sCompteur_Futur   <= to_unsigned(9,5);
					
					--sCfgFenetreDebX_Futur <= sFluxPosX&"000";
					--sCfgFenetreDebY_Futur <= sFluxPosY&"000";
					--sCfgFenetreFinX_Futur <= (sFluxPosX&"000")+to_unsigned(nTailleX,11);
					--sCfgFenetreFinY_Futur <= (sFluxPosY&"000")+to_unsigned(nTailleY,11);
				end if;
		
		end case;
		
		-- Gestion du Flux de Contrôle ----------------------
	
--		if inSyncCtrl='1' then	
--			case sFluxCtrl_Ordre is		
--			when cFluxCtrl_TypeFlux =>			
--				if sFluxCtrl_Nombre1=cTypeFluxRVB then
--					 soutCfgTypeFlux_Futur <= RVB;
--				else soutCfgTypeFlux_Futur <= HSL;
--				end if;
				
--			when cFluxCtrl_PosPupX =>		
--				vNombre := sFluxCtrl_Nombre8*nFacteurX;
--				vDebut := to_unsigned(nFenetreDebX,11)
--					     +vNombre(15 downto 8);			
--				sCfgFenetreDebX_Futur <= vDebut;
--				sCfgFenetreFinX_Futur <= vDebut+to_unsigned(nTailleX-1,11);
			
--			when cFluxCtrl_PosPupY =>		
--				vNombre := sFluxCtrl_Nombre8*nFacteurY;
--				vDebut := to_unsigned(nFenetreDebY,11)
--					     +vNombre(15 downto 8);
--				sCfgFenetreDebY_Futur <= vDebut;
--				sCfgFenetreFinY_Futur <= vDebut+to_unsigned(nTailleY-1,11);
			
--			when others => null;		
--			end case;		
--		end if;
			
	end process;

end STRUCT;