--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : Pupille
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- A partir des données de la caméra KAC-9630
-- Détecte la position de la Pupille

--=============================================================--

-- Pipe | Fréqu. | Logique | Latence | Lignes | CRC
-- 4    | 43 MHz | 674 LE  |  ...    |  261   |
-- 1    | 24 MHz | 601 LE  |  ...    |  261   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : différents algorithmes demandés
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity Pupille is

	generic (Pipe : natural := 4);
	
	port (Clock9MHz : in std_logic;
		  nReset    : in std_logic;
		
		  -- SIGNAUX de CameraKAC9630
		
		  inSyncVH    : in tSyncVH;
		  inLuminance : in tColor8;
		
		  -- SIGNAUX vers Contrôle
			
		  outSyncPos : out std_logic;
		  outFluxPos : out tPosition16;
		
		  outSeuilN : out tColor8);
		
end Pupille;

--=============================================================--

architecture STRUCT of Pupille is

	-- Diviseur 20bits/14bits pipeliné
	component Diviseur20bits14bits is
		generic (Pipe : natural);
		port (aclr	   : in std_logic;
			  clock	   : in std_logic;
			  denom	   : in tNombre14;
			  numer	   : in tNombre20;
			  quotient : out tNombre20;
			  remain   : out tNombre14);
	end component;

	-- Mise en Registre des Entrées, nécessaire pour
	-- la Détection de Flanc (IN)
	signal sinSyncVH, sinSyncVH_Futur : tSyncVH;

	-- Position dans l'Image (POS)
	signal sC, sC_Futur : std_logic;
	signal sX, sX_Futur : tPosition8;
	signal sY, sY_Futur : tPosition8;

	-- Sommes permettant le calcul du Bayrcentre (BAR)
	signal sSeuilN, sSeuilN_Futur : tColor8;
	signal sSommeX, sSommeX_Futur : tNombre20;
	signal sSommeY, sSommeY_Futur : tNombre20;
	signal sSommeP, sSommeP_Futur : tNombre14;
	
	-- Signaux de Gestion de la Division (DIV)
	signal sDivEtape,  sDivEtape_Futur  : tNombre6;
	signal sDivNombre, sDivNombre_Futur : tNombre20;
	signal sDivResult, sDivResult_Futur : tNombre20;
	
	-- Position du Centre de la Pupille (OUT)
	signal soutPosX, soutPosX_Futur : tPosition8;
	signal soutPosY, soutPosY_Futur : tPosition8;

begin --=======================================================--

	-- Notre Diviseur 20bits/14bits pipeliné de 3
	Diviseur20bits14bits_inst : Diviseur20bits14bits
		generic map (Pipe => Pipe)
		port map (aclr	   => not nReset,
				  clock	   => Clock9MHz,
				  numer	   => sDivNombre,
				  denom	   => sSommeP,
				  quotient => sDivResult_Futur);

	-- Processus Synchrone =======================================--
	
	process (Clock9MHz,nReset)
	begin
	
		if nReset='0' then
		
			sinSyncVH <= "00"; 								-- IN
		
			sC <= '0';										-- POS
			sX <= (others=>'0');							-- POS
			sY <= (others=>'0');							-- POS
		
			sSeuilN <= to_unsigned(64,8);					-- BAR
			sSommeX <= (others=>'0');						-- BAR
			sSommeY <= (others=>'0');						-- BAR
			sSommeP <= (others=>'0');						-- BAR
			
			sDivEtape  <= (others=>'0');					-- DIV
			sDivNombre <= (others=>'0');					-- DIV
			sDivResult <= (others=>'0');					-- DIV

			soutPosX <= (others=>'0');						-- OUT
			soutPosY <= (others=>'0');						-- OUT
			
		elsif rising_edge (Clock9MHz) then
		
			sinSyncVH <= sinSyncVH_Futur; 					-- IN
		
			sC <= sC_Futur;									-- POS
			sX <= sX_Futur;									-- POS
			sY <= sY_Futur;									-- POS
		
			sSeuilN <= sSeuilN_Futur;						-- BAR
			sSommeX <= sSommeX_Futur;						-- BAR
			sSommeY <= sSommeY_Futur;						-- BAR
			sSommeP <= sSommeP_Futur;						-- BAR
			
			sDivEtape  <= sDivEtape_Futur;					-- DIV
			sDivNombre <= sDivNombre_Futur;					-- DIV
			sDivResult <= sDivResult_Futur;					-- DIV

			soutPosX <= soutPosX_Futur;						-- OUT
			soutPosY <= soutPosY_Futur;						-- OUT
			
		end if;
		
	end process;

	-- Câblages ==================================================--
	
	sinSyncVH_Futur <= inSyncVH;							-- IN
	
	outSyncPos <= sC;										-- OUT
	outFluxPos <= soutPosX&soutPosY;						-- OUT
	outSeuilN <= sSeuilN;									-- OUT
	
	-- Processus de Bayrcentre ===================================--
	
	process (inSyncVH,sinSyncVH,inLuminance,sSeuilN,
			 sSommeX,sSommeY,sSommeP,sX,sY,
			 sDivEtape,sDivResult,
			 soutPosX,soutPosY)
	begin

		sC_Futur <= '0';									-- POS
		sX_Futur <= sX;										-- POS
		sY_Futur <= sY;										-- POS
		
		sSeuilN_Futur <= sSeuilN;							-- BAR
		sSommeX_Futur <= sSommeX;							-- BAR
		sSommeY_Futur <= sSommeY;							-- BAR
		sSommeP_Futur <= sSommeP;							-- BAR
		
		sDivEtape_Futur  <= (others=>'0');					-- DIV
		sDivNombre_Futur <= (others=>'0');					-- DIV
		
		soutPosX_Futur <= soutPosX;							-- OUT
		soutPosY_Futur <= soutPosY;							-- OUT
		
		case inSyncVH is
		
		-- Pause Image, en attendant la Nouvelle  -----------
		
		when "00"=>
			sX_Futur <= (others=>'0');						-- POS
			sY_Futur <= (others=>'0');						-- POS
			
			sSommeX_Futur <= (others=>'0');					-- BAR
			sSommeY_Futur <= (others=>'0');					-- BAR
			sSommeP_Futur <= (others=>'0');					-- BAR
			
			-- Fin d'Image - Calcul du Barycentre
			if sinSyncVH(1)='1' then						-- IN
				sDivEtape_Futur  <= to_unsigned(Pipe+4,6);	-- DIV
				sDivNombre_Futur <= sSommeX;				-- DIV
				sSommeX_Futur <= sSommeX;					-- BAR
				sSommeY_Futur <= sSommeY;					-- BAR
				sSommeP_Futur <= sSommeP;					-- BAR
			end if;

		-- Nouveau Pixel - X++ et si OK -> ajouté au Barycentre
		
		when "11"=>
			sX_Futur <= sX+1;								-- POS
		
			-- Un Pixel plus foncé que le Seuil ==> OK
			if inLuminance <= sSeuilN then					-- IN
				sSommeX_Futur <= sSommeX + sX;				-- BAR
				sSommeY_Futur <= sSommeY + sY;				-- BAR
				sSommeP_Futur <= sSommeP + 1;				-- BAR
			end if;
		
		-- Pause Ligne, en attendant la Nouvelle ------------
		
		when "10"=>
			if sinSyncVH(0)='1' then						-- IN
				sX_Futur <= (others=>'0');					-- POS
				sY_Futur <= sY+1;							-- POS
			end if;
			
		when others=>null;
		
		end case;
		
		-- Maintien des Sommes pour le Barycentre -----------
		
		if sDivEtape > 0 then								-- DIV
			sDivEtape_Futur <= sDivEtape - 1;				-- DIV
			sSommeX_Futur <= sSommeX;						-- BAR
			sSommeY_Futur <= sSommeY;						-- BAR
			sSommeP_Futur <= sSommeP;						-- BAR
		end if;
		
		-- Suivant la Valeure du Compteur ('multiplexage') --
		
		case sDivEtape is									-- DIV
		
		when to_unsigned(Pipe+4,6)=> sDivNombre_Futur <= sSommeY; 			      -- DIV
		when to_unsigned(Pipe+3,6)=> sDivNombre_Futur <= to_unsigned(128*101,20); -- DIV
			
		when to_unsigned(3,6)=> soutPosX_Futur <= sDivResult(tPosition8'high downto 0);
		when to_unsigned(2,6)=>	soutPosY_Futur <= sDivResult(tPosition8'high downto 0);
		
		-- Optimisation du Seuil
		when to_unsigned(1,6)=>
		
			if    sDivResult > 10 then sSeuilN_Futur <= sSeuilN + 8;
			elsif sDivResult < 10 then sSeuilN_Futur <= sSeuilN - 8;
			end if;
			
			sC_Futur <= '1';
			
		when others=>null;
		
		end case;
		
	end process;

end STRUCT;