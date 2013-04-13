--
-- Nom de l'étudiant : David FISCHER TE3
-- Nom du projet     : Caméra CMOS 2006
-- Nom du vhdl       : Ligne_a_Coeffs
-- Nom du processeur : Cyclone - EP1C12F256C7
--
-- Conversion d'un Pixel 10 bits [0-1023] en
-- Coefficients d'une BSpline de degré 3 []
--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use 	work.CameraCMOSPack.all;

entity Ligne_a_Coeffs is
	port (Clock  : in std_logic;
		  nReset : in std_logic;
		  
		  inSync     : in std_logic;
		  inColorLgn : in tColorLgn;
		
		  outSync     : out std_logic;
		  outCoeffLgn : out tCoeffLgn;
		
		  outOQP : out std_logic);

end Ligne_a_Coeffs;

architecture STRUCT of Ligne_a_Coeffs is
	
	signal sEtatSplineP       : tEtatSplineP;
	signal sEtatSplineM       : tEtatSplineM;
	signal sEtatSplineP_Futur : tEtatSplineP;
	signal sEtatSplineM_Futur : tEtatSplineM;
	
	signal sSyncP, sSyncP_Futur : std_logic;
	signal sSyncM, sSyncM_Futur : std_logic;
	
	signal sLigneP, sLigneP_Futur : tCoeffLgn;
	signal sLigneM, sLigneM_Futur : tCoeffLgn;
	
	signal sPosP, sPosP_Futur : tPosMat;
	signal sPosM, sPosM_Futur : tPosMat;
	
	-- OQP est désactivé 1 cycle en avance
	-- comme  ça le système  peut recevoir
	-- les couleurs de la part du "maître"
	-- au bon moment!
	signal sOQP, sOQP_Futur : std_logic;
	
begin

	outSync     <= sSyncM;
	outCoeffLgn <= sLigneM;
	outOQP		<= sOQP;

	-- Processus Synchrone
	process (Clock,nReset)
	begin
		if nReset='0' then
			sEtatSplineP <= InitCpK;
			sEtatSplineM <= InitCmK;
			sSyncP  <= '0';
			sSyncM  <= '0';
			sLigneP <= (others=>(others=>'0'));
			sLigneM <= (others=>(others=>'0'));
			sPosP   <= 0;
			sPosM   <= 0;
			sOQP    <= '0';
		elsif rising_edge(Clock) then
			sEtatSplineP <= sEtatSplineP_Futur;
			sEtatSplineM <= sEtatSplineM_Futur;
			sSyncP  <= sSyncP_Futur;
			sSyncM  <= sSyncM_Futur;
			sLigneP <= sLigneP_Futur;
			sLigneM <= sLigneM_Futur;
			sPosP   <= sPosP_Futur;
			sPosM   <= sPosM_Futur;
			sOQP	<= sOQP_Futur;
		end if;
	end process;
	
	-- Génération des Coefficients ->->->->
	process(inSync,inColorLgn,sEtatSplineP,sPosP,sLigneP,sOQP)
	begin
		sEtatSplineP_Futur <= sEtatSplineP;
		sSyncP_Futur  <= '0';
		sLigneP_Futur <= sLigneP;
		sPosP_Futur   <= sPosP;
		sOQP_Futur	  <= sOQP;
		
		case sEtatSplineP is
		when InitCpK=>
		
			if inSync='1' then
				sLigneP_Futur(0) <=
				MultCfCf(ConvCrCf(inColorLgn(0)),Z1ks(0))+
				MultCfCf(ConvCrCf(inColorLgn(1)),Z1ks(1))+
				MultCfCf(ConvCrCf(inColorLgn(2)),Z1ks(2))+
				MultCfCf(ConvCrCf(inColorLgn(3)),Z1ks(3))+
				MultCfCf(ConvCrCf(inColorLgn(4)),Z1ks(4));

				sEtatSplineP_Futur <= CalculCpK;
				sPosP_Futur 	   <= 1;
				sOQP_Futur		   <= '1';
			end if;
			
		when CalculCpK=>
				
			if sPosP < cMaxK then
				sLigneP_Futur(sPosP)
					<= ConvCrCf(inColorLgn(sPosP))
				 	 + MultCfCf(sLigneP(sPosP-1),Z1ks(1));	
				
				sPosP_Futur <= sPosP + 1;
			else
				sLigneP_Futur(cMaxK)
					<= MultCfCf(ConvCrCf(inColorLgn(cMaxK)),Z1d1mZ2)
			 	 	 + MultCfCf(sLigneP(cMaxK-1),Z3d1mZ2);
			
				sEtatSplineP_Futur <= InitCpK;
				sSyncP_Futur  	   <= '1';
			end if;
			
			if sPosP = cMaxK-1 then
				sOQP_Futur <= '0';
			end if;
		end case;
	end process;
		
	-- Génération des Coefficients <-<-<-<-
	process(sSyncP,sLigneP,sEtatSplineM,sPosM,sLigneM)
	begin
		sEtatSplineM_Futur <= sEtatSplineM;
		sSyncM_Futur  <= '0';
		sLigneM_Futur <= sLigneM;
		sPosM_Futur   <= sPosM;
		
		case sEtatSplineM is
		when InitCmK=>
			
			if sSyncP='1' then
				sLigneM_Futur <= sLigneP;
				sPosM_Futur   <= cMaxK-1;
				
				sEtatSplineM_Futur <= CalculCmK;
			end if;

		when CalculCmK=>
			
			sLigneM_Futur(sPosM)
				<= MultCfCf(Z1ks(1),sLigneM(sPosM+1)-sLigneM(sPosM));
			
			sPosM_Futur <= sPosM - 1;
			
			if sPosM = 0 then
				sEtatSplineM_Futur <= InitCmK;
				sSyncM_Futur 	   <= '1';
			end if;
		end case;
	end process;
	
end STRUCT;