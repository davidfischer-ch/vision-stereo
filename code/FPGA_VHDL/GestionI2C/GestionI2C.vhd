--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : GestionI2C
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Gestion de l'I2C <--> registre d'un périphérique
-- Gestion de l'écriture pas de la lecture

--=============================================================--

-- Fréqu.  | Logique | Latence    | Lignes | CRC
-- 209 MHz | 177 LE  | interface! |  448   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : gestion de la lecture du registre d'un device
-- A FAIRE : gestion des erreurs I2C (STATUS)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity GestionI2C is
		
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
		
end GestionI2C;

--=============================================================--

architecture STRUCT of GestionI2C is

	-- Interface I2C de sys.num.
	component i2c_interface is
		port (clk   : in std_logic;
			  reset : in std_logic;
			  address    : in tAdresse2;
			  chipselect : in std_logic;
			  write	     : in std_logic;
			  writedata  : in tRegI2C;
			  read       : in std_logic;
			  readdata   : out tRegI2C;
			  irq        : out std_logic;
			  scl : inout std_logic;
			  sda : inout std_logic);
	end component;
	
	-- Types spéciaux pour SetDataCtrl ===========================--
	
	constant DATA_I2C    : tAdresse2 := "00";
	constant CONTROL_I2C : tAdresse2 := "01";
	constant STATUS_I2C  : tAdresse2 := "10";
	
	constant STATUS_TIP : natural := 3;
	constant STATUS_LRA : natural := 0;
	
	constant CONTROL_WRITE : tRegI2C := "00010000";
	constant CONTROL_START : tRegI2C := "00000100";
	constant CONTROL_STOP  : tRegI2C := "00000010";
	
	type tEtatSDC is (Initial,    Donnee,  Controle,
					  Transition, WaitEOT, Final);
	
	type tEtatWDR is (Initial, Device, AttenteDevice, StatusDevice,
							   Adresse,AttenteAdresse,StatusAdresse,
							   Donnee, AttenteDonnee, StatusDonnee);
	
	-- Registres Internes & co ===================================--
	
	-- Gestion de la pseudo-procédure SetDataControl (SDC)
	
	signal sEtatSDC,     sEtatSDC_Futur     : tEtatSDC;
	signal sSyncSDC,     sSyncSDC_Futur     : std_logic;
	signal sDonneeSDC,   sDonneeSDC_Futur   : tRegI2C;
	signal sControleSDC, sControleSDC_Futur : tRegI2C;
	
	-- Gestion de la pseudo-procédure WriteDeviceReg (WDR)
	
	signal sEtatWDR,    sEtatWDR_Futur    : tEtatWDR;
	signal sSyncWDR,    sSyncWDR_Futur    : std_logic;
	signal sDeviceWDR,  sDeviceWDR_Futur  : tRegI2C;
	signal sAdresseWDR, sAdresseWDR_Futur : tRegI2C;
	signal sDonneeWDR,  sDonneeWDR_Futur  : tRegI2C;
	
	-- Gestion de l'Interface I2C fourni par l'équipe du
	-- laboratoire de systèmes numériques (I2C)
	
	signal sI2C_Adresse,    sI2C_Adresse_Futur    : tAdresse2;
	signal sI2C_ChipSelect, sI2C_ChipSelect_Futur : std_logic;
	signal sI2C_WriteEn,    sI2C_WriteEn_Futur    : std_logic;
	signal sI2C_WriteData,  sI2C_WriteData_Futur  : tRegI2C;
	signal sI2C_ReadEn,     sI2C_ReadEn_Futur     : std_logic;
	signal sI2C_ReadData : tRegI2C;
	signal sI2C_IRQ      : std_logic;
		
begin --=======================================================--

	-- Notre Interface I2C
	i2c_interface_C : i2c_interface
		port map (clk   => Clock24MHz,
			  	  reset => not nReset,
			  	  address    => sI2C_Adresse,
			  	  chipselect => sI2C_ChipSelect,
			  	  write	     => sI2C_WriteEn,
			  	  writedata  => sI2C_WriteData,
			  	  read       => sI2C_ReadEn,
			  	  readdata   => sI2C_ReadData,
			  	  irq        => sI2C_IRQ,
			  	  scl => busSCL,
			  	  sda => busSDA);

	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
	
		if nReset='0' then
		
			sEtatSDC     <= Initial;						-- SDC
			sSyncSDC     <= '0';							-- SDC
			sDonneeSDC   <= (others=>'0');					-- SDC
			sControleSDC <= (others=>'0');					-- SDC
			
			sEtatWDR    <= Initial;							-- WDR
			sSyncWDR    <= '0';								-- WDR
			sDeviceWDR  <= (others=>'0');					-- WDR
			sAdresseWDR <= (others=>'0');					-- WDR
			sDonneeWDR  <= (others=>'0');					-- WDR
		
			sI2C_Adresse    <= "00";						-- I2C
			sI2C_ChipSelect <= '0';							-- I2C
			sI2C_WriteEn    <= '0';							-- I2C
			sI2C_WriteData  <= (others=>'0');				-- I2C
			sI2C_ReadEn     <= '0';							-- I2C
	
		elsif rising_edge (Clock24MHz) then
		
			sEtatSDC     <= sEtatSDC_Futur;					-- SDC
			sSyncSDC     <= sSyncSDC_Futur;					-- SDC
			sDonneeSDC   <= sDonneeSDC_Futur;				-- SDC
			sControleSDC <= sControleSDC_Futur;				-- SDC
			
			sEtatWDR    <= sEtatWDR_Futur;					-- WDR
			sSyncWDR    <= sSyncWDR_Futur;					-- WDR
			sDeviceWDR  <= sDeviceWDR_Futur;				-- WDR
			sAdresseWDR <= sAdresseWDR_Futur;				-- WDR
			sDonneeWDR  <= sDonneeWDR_Futur;				-- WDR

			sI2C_Adresse    <= sI2C_Adresse_Futur;			-- I2C
			sI2C_ChipSelect <= sI2C_ChipSelect_Futur;		-- I2C
			sI2C_WriteEn    <= sI2C_WriteEn_Futur;			-- I2C
			sI2C_WriteData  <= sI2C_WriteData_Futur;		-- I2C
			sI2C_ReadEn     <= sI2C_ReadEn_Futur;			-- I2C
					
		end if;
		
	end process;
	
	-- Câblages ==================================================--
	
	sI2C_ChipSelect_Futur <= '1';							-- I2C
	
	-- OQP = WriteDeviceReg occupé ou non  (non retardé)?
	-- IRQ = WriteDeviceReg viens de finir (non retardé)?
	outOQP_WDR <= '0' when sEtatWDR_Futur=Initial else '1';	-- OUT
	outIRQ_WDR <= '1' when sEtatWDR_Futur=Initial
					   and sEtatWDR=StatusDonnee else '0';	-- OUT
	
	-- Processus s'occupant de gérer la demande d'écriture =======--
	
	process (inSyncWDR, inDeviceWDR, inAdresseWDR, inDonneeWDR,
			 sEtatWDR,  sDeviceWDR,  sAdresseWDR,  sDonneeWDR)
	begin
	
		sSyncWDR_Futur    <= '0';							-- WDR
		sDeviceWDR_Futur  <= sDeviceWDR;					-- WDR
		sAdresseWDR_Futur <= sAdresseWDR;					-- WDR
		sDonneeWDR_Futur  <= sDonneeWDR;					-- WDR
	
		-- Mémorise quoi écrire pour la suite de l'opération...
		if inSyncWDR='1' and sEtatWDR=Initial then			-- WDR
			sSyncWDR_Futur    <= '1';						-- WDR
			sDeviceWDR_Futur  <= inDeviceWDR;				-- WDR
			sAdresseWDR_Futur <= inAdresseWDR;				-- WDR
			sDonneeWDR_Futur  <= inDonneeWDR;				-- WDR
		end if;
		
	end process;
	
	--
	-- Adr RW Name 
	-- 00  RW DR - transmit and receive data register
	-- 01  WO CR - control register
	-- 10  RO SR - status register  
	-- 11  RW CD - clock divisor  
	--
	-- SR - status register bits
	--
	--  +---------+-------+-------+-------+-------+
	--  |bit 5-7  | bit 3 | bit 2 | bit 1 | bit 0 | 
	--  +---------+-------+-------+-------+-------+
	--  | UNUSED  | TIP   | IPE   | BSY   | LAR   |
	--  +---------+-------+-------+-------+-------+
	--
	-- TIP   - transfer in progress
	-- IPE   - interrupt pending
	-- BSY   - I2C bus busy
	-- LAR   - last acknowledge received
	-- 
	-- CR - control register bits
	--
	--  +---------+-------+-------+-------+-------+-------+-------+
	--  | bit 6-7 | bit 5 | bit 4 | bit 3 | bit 2 | bit 1 | bit 0 |
	--  +---------+-------+-------+-------+-------+-------+-------+
	--  | UNUSED  | IEN   | WR    | RD    | STA   | STP   | ACK   |
	--  +---------+-------+-------+-------+-------+-------+-------+
	--
	-- ACK    - Acknowledge bit for reading 
	-- STP    - Generate a I2C Stop Sequence 
	-- STA    - Generate a I2C Start Sequence
	-- RD     - Read command bit 
	-- WR     - Write command bit
	-- IEN    - Interrupt Enable
	--
	-- To start a transfer WR or RD *MUST* BE set.
	-- When command transfer has started TIP goes high 
	-- and write to CR are ignored until TIP goes low.
	-- At end of transfer IRQ goes high if interrupt is en. (IEN=1).
	--
	
	-- Processus regroupant les deux pseudo-fonctions I2C ========--
	-- traduites pour le VHDL à partir d'un code C ===============--
	
	process (sEtatWDR,sSyncWDR,sDeviceWDR,sAdresseWDR,sDonneeWDR,
			 sEtatSDC,sSyncSDC,sDonneeSDC,sControleSDC,
			 sI2C_Adresse,sI2C_ReadData)
	begin
	
		sI2C_Adresse_Futur   <= sI2C_Adresse;				-- I2C
		sI2C_WriteEn_Futur   <= '0';						-- I2C
		sI2C_WriteData_Futur <= (others=>'0');				-- I2C
		sI2C_ReadEn_Futur    <= '0';						-- I2C
	
		-- SetDataCtrl (Donnee,Controle)
		--  	WaitForEOT
		--  	DATA = Donnee
		--  	CTRL = Controle
		--  	WaitForEOT (attente STATUS.TIP=0)

		sEtatSDC_Futur     <= sEtatSDC;						-- SDC
		sSyncSDC_Futur     <= '0';							-- SDC
		sDonneeSDC_Futur   <= sDonneeSDC;					-- SDC
		sControleSDC_Futur <= sControleSDC;					-- SDC
		
		case sEtatSDC is
		
		when Initial=>
			
			-- Ecriture enclenchée de la part de notre maître
			if sSyncSDC='1' then							-- SDC
			
				-- Prépare la WaitEOT
				sEtatSDC_Futur     <= Donnee;				-- SDC
				sI2C_ReadEn_Futur  <= '1';					-- I2C
				sI2C_Adresse_Futur <= STATUS_I2C;			-- I2C
			end if;
			
		when Donnee=>
		
			-- Attente de fin de transfert
			if sI2C_ReadData(STATUS_TIP)='0' then			-- I2C

				-- Ecriture de Donnée -> DATA_REG
				sEtatSDC_Futur       <= Controle;			-- SDC
				sI2C_Adresse_Futur   <= DATA_I2C;			-- I2C
				sI2C_WriteEn_Futur   <= '1';				-- I2C
				sI2C_WriteData_Futur <= sDonneeSDC;			-- I2C
			else
				-- Relecture du STATUS
				sI2C_ReadEn_Futur <= '1';					-- I2C
			end if;

		when Controle=>
		
			-- Ecriture de Contrôle -> CONTROL
			sEtatSDC_Futur       <= Transition;				-- SDC
			sI2C_Adresse_Futur   <= CONTROL_I2C;			-- I2C
			sI2C_WriteEn_Futur   <= '1';					-- I2C
			sI2C_WriteData_Futur <= sControleSDC;			-- I2C
			
		when Transition=>
		
			sEtatSDC_Futur <= WaitEOT;						-- SDC
			
		when WaitEOT=>
		
			-- Prépare la WaitEOT
			sEtatSDC_Futur     <= Final;					-- SDC
			sI2C_Adresse_Futur <= STATUS_I2C;				-- I2C
			sI2C_ReadEn_Futur  <= '1';						-- I2C
		
		when Final=>
		
			-- Attente de fin de transfert
			-- / sinon / Relecture du STATUS
			if sI2C_ReadData(STATUS_TIP)='0' then			-- I2C
				 sEtatSDC_Futur    <= Initial;				-- SDC
			else sI2C_ReadEn_Futur <= '1';					-- I2C
			end if;
			
		end case;
	
		-- WriteDeviceReg (Device,Adresse,Donnee)
	
		-- 		SetDataCtrl (Device & 0xFE, START&WRITE)
		-- 		if STATUS.LRA=1 then CTRL=STOP => erreur
	
		-- 		SetDataCtrl (Adresse, WRITE)
		-- 		if STATUS.LRA=1 then CTRL=STOP => erreur
	
		-- 		SetDataCtrl (Donnee, STOP&WRITE)
		-- 		if STATUS.LRA=1 then => erreur	
		
		sEtatWDR_Futur <= sEtatWDR;							-- WDR
		
		case sEtatWDR is
		
		when Initial=>
		
			-- Ecriture enclenchée de la part du maître
			if sSyncWDR='1' then							-- WDR
				sEtatWDR_Futur     <= Device;				-- WDR
				sSyncSDC_Futur     <= '1';					-- SDC
				sDonneeSDC_Futur   <= sDeviceWDR and "11111110";
				sControleSDC_Futur <= CONTROL_START or
									  CONTROL_WRITE;		-- SDC
			end if;
			
		when Device=>
		
			-- Laisse le temps au SDC de s'enclencher!
			sEtatWDR_Futur <= AttenteDevice;				-- WDR
		
		when AttenteDevice=>			
		
			--SDC a fait son boulot?
			if sEtatSDC=Initial then						-- SDC
			
				-- Prépare le LRA
				sEtatWDR_Futur     <= StatusDevice;			-- WDR
				sI2C_ReadEn_Futur  <= '1';					-- I2C
				sI2C_Adresse_Futur <= STATUS_I2C;			-- I2C
			end if;
			
		when StatusDevice=>
		
			-- Lecture du LRA... OK?
			--if sI2C_ReadData(STATUS_LRA)='1' then
				-- Erreur!
			--else
				sEtatWDR_Futur     <= Adresse;				-- WDR
				sSyncSDC_Futur     <= '1';					-- SDC
				sDonneeSDC_Futur   <= sAdresseWDR;			-- SDC
				sControleSDC_Futur <= CONTROL_WRITE;		-- SDC
			--end if;
			
		when Adresse=>
		
			-- Laisse le temps au SDC de s'enclencher!
			sEtatWDR_Futur <= AttenteAdresse;				-- WDR
			
		when AttenteAdresse=>
		
			--SDC a fait son boulot?
			if sEtatSDC=Initial then						-- SDC
			
				-- Prépare le LRA
				sEtatWDR_Futur     <= StatusAdresse;		-- WDR
				sI2C_ReadEn_Futur  <= '1';					-- I2C
				sI2C_Adresse_Futur <= STATUS_I2C;			-- I2C
			end if;
		
		when StatusAdresse=>
		
			-- Lecture du LRA... OK?
			--if sI2C_ReadData(STATUS_LRA)='1' then
				-- Erreur!
			--else
				sEtatWDR_Futur     <= Donnee;				-- WDR
				sSyncSDC_Futur     <= '1';					-- SDC
				sDonneeSDC_Futur   <= sDonneeWDR;			-- SDC
				sControleSDC_Futur <= CONTROL_WRITE or
									  CONTROL_STOP;			-- SDC
			--end if;
		
		when Donnee=>
		
			-- Laisse le temps au SDC de s'enclencher!
			sEtatWDR_Futur <= AttenteDonnee;				-- WDR
		
		when AttenteDonnee=>
		
			--SDC a fait son boulot?
			if sEtatSDC=Initial then						-- SDC
			
				sEtatWDR_Futur <= StatusDonnee;				-- WDR
				
				-- Prépare le LRA
				sI2C_ReadEn_Futur  <= '1';					-- I2C
				sI2C_Adresse_Futur <= STATUS_I2C;			-- I2C
			end if;
		
		when StatusDonnee=>
		
			-- Lecture du LRA... OK?
			--if sI2C_ReadData(STATUS_LRA)='1' then
				-- Erreur!
			--else
				sEtatWDR_Futur <= Initial;					-- WDR
			--end if;
			
		end case;
		
	end process;

end STRUCT;