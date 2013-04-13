--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : CameraKAC9630
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Représente la Caméra KAC-9630 Monochrome

--=============================================================--

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
--use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity CameraKAC9630 is
		
	port (Clock9MHz : in std_logic;
		  nReset    : in std_logic;
		
		  -- SIGNAUX vers Cam_a_Moyenneurs
		
		  outSyncVH  : out tSyncVH;
		  outCouleur : out tColor8);
		
end CameraKAC9630;

architecture STRUCT of CameraKAC9630 is

	constant cIntegrationTime    : tNombre16 := to_unsigned(10,16);--*100*2,16);
	constant cHorizontalBlanking : tNombre16 := to_unsigned(40,16);--*10*40,16);
	
	constant cResolutionX : tNombre16 := to_unsigned(16,16);--128,16);
	constant cResolutionY : tNombre16 := to_unsigned(12,16);--101,16);
	
	type tEtat is (PauseImage,PauseLigne,Pixels);
	
	signal sEtat, sEtat_Futur : tEtat;
	signal sCmpt, sCmpt_Futur : tNombre16;
	
	signal sX, sX_Futur : tNombre16;
	signal sY, sY_Futur : tNombre16;
	signal sC, sC_Futur : tColor8;
	
	signal soutSyncVH,  soutSyncVH_Futur  : tSyncVH;
	signal soutCouleur, soutCouleur_Futur : tColor8;
		
begin

	-- Processus Synchrone
	process (Clock9MHz,nReset)
	begin
		
		if nReset='0' then
			
			sEtat <= PauseImage;
			sCmpt <= (others=>'0');
			
			sX <= (others=>'0');
			sY <= (others=>'0');
			sC <= (others=>'0');
			
			soutSyncVH  <= "00";
			soutCouleur <= (others=>'0');
		
		elsif rising_edge (Clock9MHz) then
			
			sEtat <= sEtat_Futur;
			sCmpt <= sCmpt_Futur;
			
			sX <= sX_Futur;
			sY <= sY_Futur;
			sC <= sC_Futur;
			
			soutSyncVH  <= soutSyncVH_Futur;
			soutCouleur <= soutCouleur_Futur;
		
		end if;
		
	end process;
	
	outSyncVH  <= soutSyncVH;
	outCouleur <= soutCouleur;
	
	-- Processus d'Etat
	process (sEtat,sCmpt,sX,sY,sC)
	begin
	
		sEtat_Futur <= sEtat;
		sCmpt_Futur <= sCmpt+1;
		
		sX_Futur <= sX;
		sY_Futur <= sY;
		sC_Futur <= sC;
		
		soutCouleur_Futur <= (others=>'0');
	
		case sEtat is
		
		when PauseImage=> -- Patience Image
		
			soutSyncVH_Futur <= "00";
		
			if sCmpt=cIntegrationTime-1 then
				sEtat_Futur <= PauseLigne;
				sCmpt_Futur <= (others=>'0');
				sY_Futur    <= (others=>'0');
			end if;
		
		when PauseLigne=> -- Patience Image
		
			soutSyncVH_Futur <= "10";
		
			if sCmpt=cHorizontalBlanking-1 then
				sEtat_Futur <= Pixels;
				sCmpt_Futur <= (others=>'0');
				sX_Futur    <= (others=>'0');
			end if;
		
		when Pixels=>
		
			soutSyncVH_Futur <= "11";

			if sX=cResolutionX-1 then
				if sY=cResolutionY-1 then
					 sEtat_Futur <= PauseImage;
				else sEtat_Futur <= PauseLigne;
				end if;

				sCmpt_Futur <= (others=>'0');
				sY_Futur    <= sY+1;
			end if;
					
			sX_Futur <= sX+1;
			sC_Futur <= sC+1;
			
			if    sY(0)='0' and sX(0)='0' then soutCouleur_Futur <= sC;--to_unsigned(7,10);--sC;
			elsif sY(0)='0' and sX(0)='1' then soutCouleur_Futur <= sC;--to_unsigned(8,10);--sC;
			elsif sY(0)='1' and sX(0)='0' then soutCouleur_Futur <= sC;--to_unsigned(5,10);--sC;
			elsif sY(0)='1' and sX(0)='1' then soutCouleur_Futur <= sC;--to_unsigned(6,10);--sC;
			end if;
			
		end case;
	
	end process;
	
	
end STRUCT;