--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : InterfaceFX2
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Interface du FX2 de Cypress
-- ... lisez la documentation!

-- Effectue sous forme de tournus l'accès aux différents FIFO's
-- du FX2  (microprocesseur USB2);  Au final nous avons un flux
-- IMAGE allant en IN, un autre de pupille (position) et, de la
-- part du logiciel (PC),  un dernier en OUT (in pour nous) que
-- nous allons rediriger en direction du module de contrôle

--=============================================================--

-- Fréqu.  | Logique | MOTS-FIFO | Latence    | Lignes | CRC
-- 178 MHz | 96 LE   | 512-8'192 | interface! |  391   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- EN COURS : gestion du flux contrôle
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;

entity InterfaceFX2 is

	generic (FIFO_TailleMots : natural := 512;
			 FIFO_TailleBits : natural := 9);
		
	port (Clock48MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de ProtocoleTITI
		
		  inSynchIMAGE : in std_logic;
		  inTrameIMAGE : in tTrame16;
		
		  -- SIGNAUX de FIFO Contrôle
		
		  inSyncPos : in std_logic;
		  inFluxPos : in tPosition16;
		
		  -- SIGNAUX vers Contrôle
		
		  outSyncCtrl : out std_logic;
		  outFluxCtrl : out tTrame16;

		  -- SIGNAUX vers FX2

		  outSLWR  : out std_logic;
		  outSLRD  : out std_logic;
		  outSLOE  : out std_logic;
		
		  inFLAGA  : in std_logic;
		  inFLAGB  : in std_logic;
		  inFLAGC  : in std_logic;
		  outFLAGD : out std_logic;
		
		  outPKTEND : out std_logic;
		
		  outFIFOADR : out   tAdresse2;
		  busFD      : inout tTrame16);
		
end InterfaceFX2;

--=============================================================--

architecture STRUCT of InterfaceFX2 is

	-- Mémoire FIFO M4K
	component FIFO_FX2 is
		generic (TailleMots, TailleBits : natural);
		port (aclr  : in std_logic;
		      clock : in std_logic;
			  data	: in tTrame16;
			  rdreq	: in std_logic;
			  wrreq	: in std_logic;
			  empty : out std_logic;
			  full  : out std_logic;
			  q		: out tTrame16);
	end component;
	
	-- Types spéciaux pour InterfaceFX2 ==========================--
	
	type tEtatFX2 is (PauseFX2,AttenteFX2,OperationFX2);
	
	constant cJetonIMAGE_FX2 : tAdresse2 := "00";
	constant cJetonCTRL_FX2  : tAdresse2 := "01";
	constant cJetonINFO_FX2  : tAdresse2 := "10";
	
	-- Registres Internes & co ===================================--
	
	-- Gestion du FIFO des Pixels RVB-HSL (IMG)

	signal sIMAGE_Alerte, sIMAGE_Alerte_Futur : std_logic;
	signal sIMAGE_Write,  sIMAGE_Write_Futur  : std_logic;
	signal sIMAGE_Read,   sIMAGE_Read_Futur   : std_logic;
	signal sIMAGE_Data,   sIMAGE_Data_Futur   : tTrame16;
	signal sIMAGE_Empty : std_logic;
	signal sIMAGE_Full  : std_logic;
	signal sIMAGE_Q     : tTrame16;
	
	-- Gestion du FIFO des Informations (INFO)
	
	signal sINFO_Alerte, sINFO_Alerte_Futur : std_logic;
	signal sINFO_Write,  sINFO_Write_Futur  : std_logic;
	signal sINFO_Read,   sINFO_Read_Futur   : std_logic;
	signal sINFO_Data,   sINFO_Data_Futur   : tTrame16;
	signal sINFO_Empty : std_logic;
	signal sINFO_Full  : std_logic;
	signal sINFO_Q     : tTrame16;
	
	-- Etat et Jeton du tournus RVB/HSL/CTRL du FX2 (JET)
	signal sEtatFX2,  sEtatFX2_Futur  : tEtatFX2;
	signal sJetonFX2, sJetonFX2_Futur : tAdresse2;
	
	-- Flux de Contrôle (OUTC)
	signal soutSyncCtrl, soutSyncCtrl_Futur : std_logic;
	signal soutFluxCtrl, soutFluxCtrl_Futur : tNombre16;
	
	-- Drapeaux du FX2 (FLAG)
	signal sinFX2_FlagFull  : std_logic;
	signal sinFX2_FlagEmpty : std_logic;
	
	-- Commandes en direction du FX2 (écriture-lecture) (FX2)
	signal soutFX2_SlaveWrite, soutFX2_SlaveWrite_Futur  :std_logic;
	signal soutFX2_SlaveRead,  soutFX2_SlaveRead_Futur   :std_logic;
	signal soutFX2_SlaveReadOE,soutFX2_SlaveReadOE_Futur :std_logic;
	signal soutFX2_FifoAdresse,soutFX2_FifoAdresse_Futur :tAdresse2;
	signal soutFX2_FifoDataBus,soutFX2_FifoDataBus_Futur :tTrame16;
		
begin --=======================================================--
	
	-- Notre FIFO RVB-HSL M4K
	FIFO_IMAGE : FIFO_FX2
		generic map (TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
		port map (aclr  => not nReset,
				  clock => Clock48MHz,
			  	  wrreq	=> sIMAGE_Write,
			  	  data	=> sIMAGE_Data,
			  	  rdreq	=> sIMAGE_Read,
				  empty => sIMAGE_Empty,
				  full  => sIMAGE_Full,
			  	  q		=> sIMAGE_Q);
			
	FIFO_INFO : FIFO_FX2
		generic map (TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
		port map (aclr  => not nReset,
				  clock => Clock48MHz,
			  	  wrreq	=> sINFO_Write,
			  	  data	=> sINFO_Data,
			  	  rdreq	=> sINFO_Read,
				  empty => sINFO_Empty,
				  full  => sINFO_Full,
			  	  q		=> sINFO_Q);
					
	-- Processus Synchrone =======================================--
	
	process (Clock48MHz,nReset)
	begin
	
		if nReset='0' then

			sIMAGE_Alerte <= '0';							-- IMG
			sIMAGE_Write  <= '0';							-- IMG
			sIMAGE_Read   <= '0';							-- IMG
			sIMAGE_Data   <= (others=>'0');					-- IMG
			
			sINFO_Alerte <= '0';							-- INFO
			sINFO_Write  <= '0';							-- INFO
			sINFO_Read   <= '0';							-- INFO
			sINFO_Data   <= (others=>'0');					-- INFO
			
			sEtatFX2  <= AttenteFX2; 						-- JET
			sJetonFX2 <= cJetonIMAGE_FX2;  					-- JET
			
			soutSyncCtrl <= '0'; 							-- OUTC
			soutFluxCtrl <= (others=>'0'); 					-- OUTC
	
			soutFX2_SlaveWrite  <= '0';  					-- FX2	
			soutFX2_SlaveRead   <= '0';  					-- FX2
			soutFX2_SlaveReadOE <= '0';  					-- FX2

			soutFX2_FifoAdresse <= cJetonIMAGE_FX2; 		-- FX2
			soutFX2_FifoDataBus <= (others=>'0'); 			-- FX2
			
		elsif rising_edge (Clock48MHz) then
			
			sIMAGE_Alerte <= sIMAGE_Alerte_Futur;			-- IMG
			sIMAGE_Write  <= sIMAGE_Write_Futur;			-- IMG
			sIMAGE_Read   <= sIMAGE_Read_Futur;				-- IMG
			sIMAGE_Data   <= sIMAGE_Data_Futur;				-- IMG
			
			sINFO_Alerte <= sINFO_Alerte_Futur;				-- INFO
			sINFO_Write  <= sINFO_Write_Futur;				-- INFO
			sINFO_Read   <= sINFO_Read_Futur;				-- INFO
			sINFO_Data   <= sINFO_Data_Futur;				-- INFO

			sEtatFX2  <= sEtatFX2_Futur;  					-- JET
			sJetonFX2 <= sJetonFX2_Futur; 					-- JET
			
			soutSyncCtrl <= soutSyncCtrl_Futur; 			-- OUTC
			soutFluxCtrl <= soutFluxCtrl_Futur; 			-- OUTC
			
			soutFX2_SlaveWrite  <= soutFX2_SlaveWrite_Futur;-- FX2
			soutFX2_SlaveRead   <= soutFX2_SlaveRead_Futur; -- FX2
			soutFX2_SlaveReadOE <= soutFX2_SlaveReadOE_Futur;--FX2

			soutFX2_FifoAdresse <= soutFX2_FifoAdresse_Futur;--FX2
			soutFX2_FifoDataBus <= soutFX2_FifoDataBus_Futur;--FX2
				
		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	outSyncCtrl <= soutSyncCtrl;							-- OUTC
	outFluxCtrl <= soutFluxCtrl;							-- OUTC
	
	sinFX2_FlagFull  <= not inFLAGB;						-- FX2
	sinFX2_FlagEmpty <= not inFLAGC;						-- FX2
	
	outSLWR <= not soutFX2_SlaveWrite;						-- FX2
	outSLRD <= not soutFX2_SlaveRead;						-- FX2
	outSLOE <= not soutFX2_SlaveReadOE;						-- FX2

	outFLAGD <= '1';										-- FX2
	outPKTEND <= '1';										-- FX2
		
	outFIFOADR <= soutFX2_FifoAdresse;						-- FX2
	
	busFD <= (others=>'Z') when soutFX2_SlaveReadOE='1' else
					soutFX2_FifoDataBus;					-- FX2
	
	-- Processus de Gestion du FIFO ==============================--
	
	sIMAGE_Alerte_Futur <= (sIMAGE_Alerte or sIMAGE_Full)
									 and not sIMAGE_Empty;	-- IMG
	
	sIMAGE_Write_Futur <= inSynchIMAGE and not sIMAGE_Alerte_Futur;
	sIMAGE_Data_Futur  <= inTrameIMAGE;						-- IMG
	
	sINFO_Alerte_Futur <= (sINFO_Alerte or sINFO_Full)
									 and not sINFO_Empty;	-- INFO
	
	sINFO_Write_Futur <= inSyncPos and not sINFO_Alerte_Futur;
	sINFO_Data_Futur  <= inFluxPos;							-- INFO
	
	-- Processus d'Emission et Réception =======================--
			
	soutFX2_FifoAdresse_Futur <= sJetonFX2;					-- JET

	process (sIMAGE_Empty,sIMAGE_Q,
		 	 sINFO_Empty,sINFO_Q,
			 sEtatFX2,sJetonFX2,
			 sinFX2_FlagEmpty,
			 sinFX2_FlagFull,
			 soutFX2_FifoDataBus,busFD)
	begin
		
		sIMAGE_Read_Futur <= '0';							-- IMG
		sINFO_Read_Futur  <= '0';							-- INFO
				
		sEtatFX2_Futur  <= sEtatFX2;						-- JET
		sJetonFX2_Futur <= sJetonFX2;						-- JET
		
		soutSyncCtrl_Futur <= '0';							-- OUTC
		soutFluxCtrl_Futur <= (others=>'0');				-- OUTC
		
		soutFX2_SlaveReadOE_Futur <= '0';					-- FX2
		soutFX2_SlaveRead_Futur   <= '0';					-- FX2
		soutFX2_SlaveWrite_Futur  <= '0';					-- FX2
		soutFX2_FifoDataBus_Futur <= soutFX2_FifoDataBus;	-- FX2
		
		case sJetonFX2 is									-- JET
		
		-----------------------------------------------------
		
		when cJetonIMAGE_FX2=>
		
			case sEtatFX2 is								-- JET
			
			when AttenteFX2=>
			
				-- Ici les Flags du FX2 ne sont pas encore posés
				sEtatFX2_Futur <= OperationFX2;				-- JET
			
			when OperationFX2=>
					
				-- Si le FIFO du FX2 n'est pas Full
				if sIMAGE_Empty='0' then					-- IMG
					if sinFX2_FlagFull='0' then				-- FX2
						sEtatFX2_Futur <= AttenteFX2;		-- JET
						sIMAGE_Read_Futur <= '1';			-- IMG
						soutFX2_SlaveWrite_Futur  <= '1';	-- FX2
						soutFX2_FifoDataBus_Futur <= sIMAGE_Q;
					end if;
				else
					sJetonFX2_Futur <= cJetonCTRL_FX2;		-- JET
					sEtatFX2_Futur  <= AttenteFX2;			-- JET
				end if;
				
			when others=> sEtatFX2_Futur <= AttenteFX2;		-- JET

			end case;
					
		-----------------------------------------------------
		
		when cJetonCTRL_FX2 =>
		
--			soutFX2_SlaveReadOE_Futur <= '1';
--						
			case sEtatFX2 is								-- JET
			
			when AttenteFX2=> -- Atttente que les FLAGS soient OK
				sEtatFX2_Futur <= PauseFX2;					-- JET
			
			when PauseFX2=>
				-- Le FX2 a un ORDRE en poche ou alors au suivant...
				if sinFX2_FlagEmpty='0' then 				-- FLAG
					sEtatFX2_Futur <= OperationFX2;			-- JET
				else
					sJetonFX2_Futur <= cJetonIMAGE_FX2;		-- JET
					sEtatFX2_Futur  <= AttenteFX2;			-- JET
				end if;
				
			when OperationFX2=>
				sJetonFX2_Futur <= cJetonIMAGE_FX2;			-- JET
				sEtatFX2_Futur  <= AttenteFX2;				-- JET
				soutSyncCtrl_Futur <= '1';					-- OUTC
				soutFluxCtrl_Futur <= busFD;				-- OUTC
				soutFX2_SlaveRead_Futur <= '1';		   		-- FX2
	
			end case;
			
		-----------------------------------------------------
		
		when cJetonINFO_FX2 =>
		
			case sEtatFX2 is								-- JET
			
			when AttenteFX2=>
			
				-- Ici les Flags du FX2 ne sont pas encore posés
				sEtatFX2_Futur <= OperationFX2;				-- JET
			
			when OperationFX2=>
					
				-- Si le FIFO du FX2 n'est pas Full
				if sINFO_Empty='0' then						-- INFO
					if sinFX2_FlagFull='0' then				-- FX2
						sEtatFX2_Futur <= AttenteFX2;		-- JET
						sINFO_Read_Futur <= '1';			-- IMG
						soutFX2_SlaveWrite_Futur  <= '1';	-- FX2
						soutFX2_FifoDataBus_Futur <= sINFO_Q;--FX2
					end if;
				else
					sJetonFX2_Futur <= cJetonIMAGE_FX2;		-- JET
					sEtatFX2_Futur  <= AttenteFX2;			-- JET
				end if;
				
			when others=> sEtatFX2_Futur <= AttenteFX2;		-- JET

			end case;
			
		-----------------------------------------------------
		
		when others => sJetonFX2_Futur <= cJetonIMAGE_FX2;	-- JET
			
		end case;
	
	end process;
	
end STRUCT;