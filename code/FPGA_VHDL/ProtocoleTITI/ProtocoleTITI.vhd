--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : ProtocoleTITI
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Produit des trames au protocole TITI à partir des données
-- de synchronisation et des trois composantes colorimétriques

--               15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0  Visuel
-- TRAME n°IMAGE  1  ---- n° d'image sur 15 bits ----- 0x8.-0xF.
-- TRAME n°LIGNE  0  1 -- n° de ligne sur 14 bits ---- 0x4.-0x7.
-- TRAME CRC      0  0  1 -- n°CRC -- -- CRC_8bits --- 0x2.-0x3.
-- TRAME PIXEL    0  0  0  1  . - Type - Couleur_8bits 0x1.-0x1.

-- Type : 000 = Rouge   001 = Vert        010 = Bleu
--        100 = Teinte  101 = Saturation  110 = Luminance

--=============================================================--

-- Fréqu.  | Logique | MOTS-FIFO  | Latence  | Lignes | CRC
-- 143 MHz | 203 LE  | 512-13'824 | requêtes |  321   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : gestion du CRC (now il est bidon (=0))!
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;

Entity ProtocoleTITI is

	generic (FIFO_TailleMots : natural := 512;
			 FIFO_TailleBits : natural := 9);

    port(Clock48MHz : in std_logic;
         nReset     : in std_logic;

		 -- SIGNAUX de RVB_ou_HSL
		
		 inClock24MHz : in std_logic;
         inTypeFlux   : in tTypeFlux;
		 inSyncVHP    : in tSyncVHP;
		 inCouleur1   : in tColor8;
		 inCouleur2   : in tColor8;
		 inCouleur3   : in tColor8;

		 -- SIGNAUX vers InterfaceFX2
		
		 outSynch : out std_logic;
		 outTrame : out tTrame16);
		 
end ProtocoleTITI;

--=============================================================--

architecture STRUCT of ProtocoleTITI is

	-- Mémoire FIFO M4K
	component FIFO_TITI is
		generic (TailleMots, TailleBits : natural);
		port (aclr	  : in std_logic := '0';
			  data	  : in tNombre27;
			  rdclk	  : in std_logic;
			  rdreq	  : in std_logic;
			  wrclk	  : in std_logic;
			  wrreq	  : in std_logic;
			  q		  : out tNombre27;
			  rdempty : out std_logic;
			  wrempty : out std_logic;
			  wrfull  : out std_logic);
	end component;
	
	-- Détection des Flans des Signaux de Synchro (IN)
	signal soldSyncVH, soldSyncVH_Futur : tSyncVH;
	
	-- Stockage du Pixel => envoi en 3 x Trames PIXEL (PIX)
	signal sinCouleur1, sinCouleur1_Futur : tColor8;
	signal sinCouleur2, sinCouleur2_Futur : tColor8;
	signal sinCouleur3, sinCouleur3_Futur : tColor8;
	
	-- Signaux de Gestion des FIFO's (FIFO)
	signal sFIFO_Alerte, sFIFO_Alerte_Futur : std_logic;
	signal sFIFO_Write,  sFIFO_Write_Futur  : std_logic;
	signal sFIFO_Read,   sFIFO_Read_Futur   : std_logic;
	signal sFIFO_Data,   sFIFO_Data_Futur   : tNombre27;
	signal sFIFO_Empty  : std_logic;
	signal sFIFO_EmptyW : std_logic;
	signal sFIFO_FullW  : std_logic;
	signal sFIFO_Q      : tNombre27;
	
	alias sFIFO_SyncVHP  : tSyncVHP is sFIFO_Q(26 downto 24);
	alias sFIFO_Couleur1 : tColor8  is sFIFO_Q(23 downto 16);
	alias sFIFO_Couleur2 : tColor8  is sFIFO_Q(15 downto  8);
	alias sFIFO_Couleur3 : tColor8  is sFIFO_Q( 7 downto  0);
	
	-- Requêtes d'envoi de Trames vers le FX2 (REQ)
	signal sTrameIMAGE, sTrameIMAGE_Futur : std_logic;
	signal sTrameLIGNE, sTrameLIGNE_Futur : std_logic;
	signal sTrameCRC,   sTrameCRC_Futur   : std_logic;
	signal sTramePIXEL, sTramePIXEL_Futur : tNombre2;

	-- Compteurs d'Image et de Ligne (CPT)
	signal sNoImage, sNoImage_Futur : tNoImage15;
	signal sNoLigne, sNoLigne_Futur : tNoLigne14;
	
	-- Signaux de Synchro / Trame en Sortie (OUT)
	signal soutSynch, soutSynch_Futur : std_logic;
	signal soutTrame, soutTrame_Futur : tTrame16;

begin --=======================================================--
			
	FIFO_TITI_inst : FIFO_TITI
		generic map (TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
		port map (aclr => not nReset,
			  	  wrclk	=> inClock24MHz,
			  	  wrreq	=> sFIFO_Write,
			  	  data	=> sFIFO_Data,
			  	  rdclk	  => Clock48MHz,
			  	  rdreq	  => sFIFO_Read,
			  	  q		  => sFIFO_Q,
			  	  rdempty => sFIFO_Empty,
			      wrempty => sFIFO_EmptyW,
			      wrfull  => sFIFO_FullW);
			
	-- Processus Synchrone de Gestion du FIFO ====================--
	
	process (inClock24MHz,nReset)
	begin

		if nReset='0' then

			sFIFO_Alerte <= '0';							-- FIFO
			sFIFO_Write  <= '0';							-- FIFO
			sFIFO_Data   <= (others=>'0');					-- FIFO
		
		elsif rising_edge (inClock24MHz) then
		
			sFIFO_Alerte <= sFIFO_Alerte_Futur;				-- FIFO
			sFIFO_Write  <= sFIFO_Write_Futur;				-- FIFO
			sFIFO_Data   <= sFIFO_Data_Futur;				-- FIFO
		
		end if;

	end process;

	-- Processus de Gestion du FIFO ==============================--
		
	sFIFO_Alerte_Futur <= (sFIFO_Alerte or sFIFO_FullW)
								   and not sFIFO_EmptyW;
	
	sFIFO_Write_Futur <= not sFIFO_Alerte_Futur;
	sFIFO_Data_Futur  <= inSyncVHP&inCouleur1&inCouleur2&inCouleur3;

	-- Processus Synchrone =======================================--
	
	process (Clock48MHz,nReset)
	begin
	
		if nReset='0' then 
		
			soldSyncVH <= "00";								-- IN
			
			sinCouleur1 <= (others=>'0');					-- PIX
			sinCouleur2 <= (others=>'0');					-- PIX
			sinCouleur3 <= (others=>'0');					-- PIX
				
			sFIFO_Read <= '0';								-- FIFO
					
			sTrameIMAGE <= '0';								-- REQ
			sTrameLIGNE <= '0';								-- REQ
			sTrameCRC   <= '0';								-- REQ
			sTramePIXEL <= "00";							-- REQ
		
			sNoImage <= (others=>'0');						-- CPT
			sNoLigne <= (others=>'0');						-- CPT
			
			soutSynch <= '0';								-- OUT
			soutTrame <= (others=>'0');						-- OUT
		
		elsif rising_edge (Clock48MHz) then
			
			soldSyncVH <= soldSyncVH_Futur;					-- IN

			sinCouleur1 <= sinCouleur1_Futur;				-- PIX
			sinCouleur2 <= sinCouleur2_Futur;				-- PIX
			sinCouleur3 <= sinCouleur3_Futur;				-- PIX
			
			sFIFO_Read <= sFIFO_Read_Futur;					-- FIFO
							
			sTrameIMAGE <= sTrameIMAGE_Futur;				-- REQ
			sTrameLIGNE <= sTrameLIGNE_Futur;				-- REQ
			sTrameCRC   <= sTrameCRC_Futur;					-- REQ
			sTramePIXEL <= sTramePIXEL_Futur;				-- REQ

			sNoImage <= sNoImage_Futur;						-- CPT
			sNoLigne <= sNoLigne_Futur;						-- CPT
			
			soutSynch <= soutSynch_Futur;					-- OUT
			soutTrame <= soutTrame_Futur;					-- OUT
			
		end if;

	end process;
	
	-- Câblages ==================================================--
	
	soldSyncVH_Futur <= soldSyncVH when sFIFO_Empty='1'		-- IN
				   				   else sFIFO_SyncVHP(2 downto 1);
	
	outSynch <= soutSynch;									-- OUT
	outTrame <= soutTrame;									-- OUT
	
	-- Processus du Protocole TITI ===============================--
	
	-- Lecture du FIFO, niveau performances
	-- le fait de prendre en compte "01" permet de lire en avance...
	sFIFO_Read_Futur <= '1' when sTramePIXEL(1)='0' else '0';

	process(inTypeFlux,
			sFIFO_Empty,sFIFO_SyncVHP,soldSyncVH,
			sFIFO_Couleur1,sFIFO_Couleur2,sFIFO_Couleur3,
			sinCouleur1,sinCouleur2,sinCouleur3,
			sTrameIMAGE,sTrameLIGNE,sTrameCRC,sTramePIXEL,
			sNoImage,sNoLigne)
			
		variable vFlux : tNombre6;
	begin

		sinCouleur1_Futur <= sinCouleur1;					-- PIX
		sinCouleur2_Futur <= sinCouleur2;					-- PIX
		sinCouleur3_Futur <= sinCouleur3;					-- PIX
			
		sTrameIMAGE_Futur <= sTrameIMAGE;					-- REQ
		sTrameLIGNE_Futur <= sTrameLIGNE;					-- REQ
		sTrameCRC_Futur   <= sTrameCRC;						-- REQ
		sTramePIXEL_Futur <= sTramePIXEL;					-- REQ
		
		sNoImage_Futur <= sNoImage;							-- CPT
		sNoLigne_Futur <= sNoLigne;							-- CPT
		
		soutSynch_Futur <= '0';								-- OUT
		soutTrame_Futur <= (others=>'0');					-- OUT
		
		-- Avons-nous un signal dans le FIFO de resynchro
		-- provenant du flux de caméra basé sur du 24MHz,
		-- dans ce module synchrone avec le FX2 en 48MHz.
		if sFIFO_Empty='0' then								-- FIFO
		
			-- Nouvelle Image => TRAME IMAGE
			if sFIFO_SyncVHP(2)='1' and soldSyncVH(1)='0' then
				sTrameIMAGE_Futur <= '1';					-- REQ
			end if;
		
			-- Nouvelle Ligne => TRAME LIGNE
			if sFIFO_SyncVHP(1)='1' and soldSyncVH(0)='0' then
				sTrameLIGNE_Futur <= '1';					-- REQ
			end if;
					
			-- Fin d'Image => TRAME CRC
			if sFIFO_SyncVHP(2)='0' and soldSyncVH(1)='1' then
				sTrameCRC_Futur <= '1';						-- REQ
			end if;
		
			-- Nouveau Pixel => (après) 3xTRAME PIXEL
			if sFIFO_SyncVHP(0)='1' and sTramePIXEL="00" then
				sTramePIXEL_Futur <= "11";					-- REQ
				sinCouleur1_Futur <= sFIFO_Couleur1;		-- PIX
				sinCouleur2_Futur <= sFIFO_Couleur2;		-- PIX
				sinCouleur3_Futur <= sFIFO_Couleur3;		-- PIX
			end if;
		
		end if;

		-- Gestion avec Priorités
		-- des Trames à envoyer!
			
		if sTrameIMAGE='1' then								-- REQ
			sTrameIMAGE_Futur <= '0';						-- REQ
			soutSynch_Futur <= '1';							-- OUT
			soutTrame_Futur <= '1'&sNoImage;				-- OUT
			sNoImage_Futur <= sNoImage + 1;					-- CPT
			sNoLigne_Futur <= (others=>'0');				-- CPT
			
		elsif sTrameLIGNE='1' then							-- REQ
			sTrameLIGNE_Futur <= '0';						-- REQ
			soutSynch_Futur <= '1';							-- OUT
			soutTrame_Futur <= "01"&sNoLigne;				-- OUT
			sNoLigne_Futur  <= sNoLigne + 1;				-- CPT
			
		elsif sTramePIXEL>0 then							-- REQ
			sTramePIXEL_Futur <= sTramePIXEL - 1;			-- REQ
			soutSynch_Futur <= '1';							-- OUT
			
			vFlux := "00010"&inTypeFlux;					-- IN
			
			case sTramePIXEL is								-- REQ
			when "11" => soutTrame_Futur <= vFlux&"00"&sinCouleur1;
			when "10" => soutTrame_Futur <= vFlux&"01"&sinCouleur2;
			when "01" => soutTrame_Futur <= vFlux&"10"&sinCouleur3;
			when others => null;							-- OUT
			end case;
			
		elsif sTrameCRC='1' then							-- REQ
			sTrameCRC_Futur <= '0';							-- REQ
			soutSynch_Futur <= '1';							-- OUT
			soutTrame_Futur <= "0010000000000000";			-- OUT
			
		end if;
		
	end process;
end STRUCT;