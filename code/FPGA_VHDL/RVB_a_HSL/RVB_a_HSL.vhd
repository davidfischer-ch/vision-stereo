--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : RVB_a_HSL
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Convertisseur pipeliné  d'espace colorimétrique, en partant du
-- codage RVB nous donne en sortie deux flux synchronisés, le RVB
-- et son équivalent au codage HSL

--=============================================================--

-- Pipe | Fréqu. | Logique  | Latence | Lignes | CRC
-- 6    | 61 MHz | 1'199 LE |   10    |  378   |
-- 4    | 58 MHz | 1'060 LE |    8    |  378   |

-- A FAIRE : rien ce module est génial (CRC sans le chiffre CRC!)
-- A FAIRE : banc de test!

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;

entity RVB_a_HSL is

	generic (Pipe : natural := 4);

	port (Clock24MHz : in std_logic;
		  nReset     : in std_logic;
		
		  -- SIGNAUX de Bayer_a_RVB
		
		  inSyncVHP : in tSyncVHP;
		  inRouge   : in tColor8;
		  inVert    : in tColor8;
		  inBleu    : in tColor8;
		
		  -- SIGNAUX vers RVB_ou_HSL

		  outSyncVHP : out tSyncVHP;
				
		  outRouge : out tColor8;
		  outVert  : out tColor8;
		  outBleu  : out tColor8;

		  outTeinte     : out tColor8;
		  outSaturation : out tColor8;
		  outLuminance  : out tColor8);
		
end RVB_a_HSL;

--=============================================================--

architecture STRUCT of RVB_a_HSL is

	-- Diviseur 16bits/9bits pipeliné
	component Diviseur16bits9bits is
		generic (Pipe : natural);
		port (aclr		: in  std_logic;
			  clock		: in  std_logic;
			  denom		: in  tColor8_Add;
			  numer		: in  tColor8_Div;
			  quotient	: out tColor8_Div;
			  remain	: out tColor8_Add);
	end component;
	
	-- Diviseur 16bits/8bits pipeliné
	component Diviseur16bits8bits is
		generic (Pipe : natural);
		port (aclr		: in  std_logic;
			  clock		: in  std_logic;
			  denom		: in  tColor8;
			  numer		: in  tColor8_Div;
			  quotient	: out tColor8_Div;
			  remain	: out tColor8);
	end component;

	-- Types spéciaux pour RVB_a_HSL =============================--
	
	type tQUI is (R,V,B);
	
	type tRegSyncVHP     is array (0 to Pipe+3) of tSyncVHP;
	type tRegColor8_RVB  is array (0 to Pipe+3) of tColor8;

	type tRegColor8      is array (0 to Pipe+2) of tColor8;
	type tRegColor8_Add  is array (0 to Pipe+2) of tColor8_Add;
	type tRegColor8_Div2 is array (0 to Pipe+2) of tColor8_Div2;
	
	constant cCr8_Zero   : tColor8 := (others=>'0');
	constant cCr8_Un     : tColor8 := (others=>'1');
	constant cCr8_Demi   : tColor8 := to_unsigned(256/2, 8);
	constant cCr8_1Six   : tColor8 := to_unsigned(256/6, 8);
	constant cCr8_1Tiers : tColor8 := to_unsigned(256/3, 8);
	constant cCr8_2Tiers : tColor8 := to_unsigned(512/3, 8);
	
	-- Registres Internes & co ===================================--

	-- Signaux concernant les MAX/MIN & co (MXX)
	signal sQUI,     sQUI_Futur     : tQUI;
	signal sMAX, 	 sMAX_Futur     : tRegColor8;
	signal sMIN, 	 sMIN_Futur     : tRegColor8;
	signal sMAXmMIN, sMAXmMIN_Futur : tRegColor8;
	signal sMAXpMIN, sMAXpMIN_Futur : tRegColor8_Add;

	-- Signaux RVB retardé pour la Hue (HUE)
	signal sH_Rouge, sH_Rouge_Futur : tColor8_Add;
	signal sH_Vert,  sH_Vert_Futur  : tColor8_Add;
	signal sH_Bleu,  sH_Bleu_Futur  : tColor8_Add;

	-- Signaux de Calcul pour la Hue (HUE)
	signal sH_SUB, sH_SUB_Futur  : tRegColor8_Add;
	signal sH_ADD, sH_ADD_Futur  : tRegColor8;

	-- Signaux de Division pour la Hue (HUE)
	signal sH_BAS,  sH_BAS_Futur  : tColor8;
	signal sH_HAUT, sH_HAUT_Futur : tColor8_Div;
	signal sH_RES : tColor8_Div;

	-- Signaux de Division pour la Saturation (SAT)
	signal sS_BAS,  sS_BAS_Futur  : tColor8_Add;
	signal sS_HAUT, sS_HAUT_Futur : tColor8_Div;
	signal sS_RES : tColor8_Div;

	-- Signaux de Synchro/HSL de Sortie (OUT)
	signal soutSyncVHP, soutSyncVHP_Futur : tRegSyncVHP;

	signal soutRouge, soutRouge_Futur : tRegColor8_RVB;
	signal soutVert,  soutVert_Futur  : tRegColor8_RVB;
	signal soutBleu,  soutBleu_Futur  : tRegColor8_RVB;

	signal soutTeinte,     soutTeinte_Futur     : tColor8;
	signal soutSaturation, soutSaturation_Futur : tColor8;
	signal soutLuminance,  soutLuminance_Futur  : tColor8;

begin --=======================================================--

	-- Notre Diviseur 16bits/9bits pipeliné
	DiviseurSaturation : Diviseur16bits9bits
		generic map (Pipe => Pipe)
		port map (aclr	   => not nReset,
				  clock	   => Clock24MHz,
				  denom	   => sS_BAS,
				  numer	   => sS_HAUT,
				  quotient => sS_RES);
				
	-- Notre Diviseur 16bits/8bits pipeliné
	DiviseurHue : Diviseur16bits8bits
		generic map (Pipe => Pipe)
		port map (aclr	   => not nReset,
				  clock	   => Clock24MHz,
				  denom	   => sH_BAS,
				  numer	   => sH_HAUT,
				  quotient => sH_RES);

	-- Processus Synchrone =======================================--
	
	process (Clock24MHz,nReset)
	begin
		if nReset='0' then
		
			sQUI     <= V; 									-- MXX
			sMAX     <= (others=>(others=>'0')); 			-- MXX
			sMIN     <= (others=>(others=>'0')); 			-- MXX
			sMAXmMIN <= (others=>(others=>'0')); 			-- MXX
			sMAXpMIN <= (others=>(others=>'0')); 			-- MXX
			
			sH_Rouge <= (others=>'0');					 	-- HUE
			sH_Vert  <= (others=>'0'); 						-- HUE
			sH_Bleu  <= (others=>'0'); 						-- HUE
			
			sH_SUB <= (others=>(others=>'0')); 				-- HUE
			sH_ADD <= (others=>(others=>'0')); 				-- HUE
			
			sH_BAS  <= (others=>'0'); 						-- HUE
			sH_HAUT <= (others=>'0'); 						-- HUE
			
			sS_BAS  <= (others=>'0'); 						-- SAT
			sS_HAUT <= (others=>'0'); 						-- SAT
		
			soutSyncVHP <= (others=>"000"); 				-- OUT
			soutRouge <= (others=>(others=>'0'));			-- OUT
			soutVert  <= (others=>(others=>'0'));			-- OUT
			soutBleu  <= (others=>(others=>'0'));			-- OUT
			soutTeinte     <= (others=>'0');   				-- OUT
			soutSaturation <= (others=>'0');   				-- OUT
			soutLuminance  <= (others=>'0');   				-- OUT
			
		elsif rising_edge (Clock24MHz) then
		
			sQUI     <= sQUI_Futur; 						-- MXX
			sMAX     <= sMAX_Futur; 						-- MXX
			sMIN     <= sMIN_Futur; 						-- MXX
			sMAXmMIN <= sMAXmMIN_Futur; 					-- MXX
			sMAXpMIN <= sMAXpMIN_Futur; 					-- MXX
			
			sH_Rouge <= sH_Rouge_Futur; 					-- HUE
			sH_Vert  <= sH_Vert_Futur;  					-- HUE
			sH_Bleu  <= sH_Bleu_Futur;  					-- HUE
			
			sH_SUB <= sH_SUB_Futur; 						-- HUE
			sH_ADD <= sH_ADD_Futur; 						-- HUE
			
			sH_BAS  <= sH_BAS_Futur;  						-- HUE
			sH_HAUT <= sH_HAUT_Futur; 						-- HUE
			
			sS_BAS  <= sS_BAS_Futur;  						-- SAT
			sS_HAUT <= sS_HAUT_Futur; 						-- SAT
		
			soutSyncVHP <= soutSyncVHP_Futur; 				-- OUT
			soutRouge <= soutRouge_Futur;					-- OUT
			soutVert  <= soutVert_Futur;					-- OUT
			soutBleu  <= soutBleu_Futur;					-- OUT
			soutTeinte     <= soutTeinte_Futur; 			-- OUT
			soutSaturation <= soutSaturation_Futur; 		-- OUT
			soutLuminance  <= soutLuminance_Futur; 			-- OUT
			
		end if;
	end process;
	
	-- Câblages ================================================--
	
	soutSyncVHP_Futur(0) <= inSyncVHP;						-- IN
	soutRouge_Futur  (0) <= inRouge;						-- IN
	soutVert_Futur   (0) <= inVert;							-- IN
	soutBleu_Futur   (0) <= inBleu;							-- IN
	
	sMAX_Futur(1 to Pipe+2) <= sMAX(0 to Pipe+1);			-- MXX
	sMIN_Futur(1 to Pipe+2) <= sMIN(0 to Pipe+1);			-- MXX
	sMAXmMIN_Futur(1 to Pipe+2) <= sMAXmMIN(0 to Pipe+1);	-- MXX
	sMAXpMIN_Futur(1 to Pipe+2) <= sMAXpMIN(0 to Pipe+1);	-- MXX
	
	sH_Rouge_Futur <= "0"&inRouge; 							-- HUE
	sH_Vert_Futur  <= "0"&inVert;  							-- HUE
	sH_Bleu_Futur  <= "0"&inBleu;  							-- HUE
	
	sH_SUB_Futur(1 to Pipe+2) <= sH_SUB(0 to Pipe+1);		-- HUE
	sH_ADD_Futur(1 to Pipe+2) <= sH_ADD(0 to Pipe+1);		-- HUE
	
	-- OUT
	soutSyncVHP_Futur(1 to Pipe+3) <= soutSyncVHP(0 to Pipe+2);
	soutRouge_Futur  (1 to Pipe+3) <= soutRouge  (0 to Pipe+2);
	soutVert_Futur   (1 to Pipe+3) <= soutVert   (0 to Pipe+2);
	soutBleu_Futur   (1 to Pipe+3) <= soutBleu   (0 to Pipe+2);
	
	outSyncVHP <= soutSyncVHP(Pipe+3);						-- OUT
	
	outRouge <= soutRouge(Pipe+3);							-- OUT
	outVert  <= soutVert (Pipe+3);							-- OUT
	outBleu  <= soutBleu (Pipe+3);							-- OUT
	
	outTeinte     <= soutTeinte;    						-- OUT
	outSaturation <= soutSaturation;    					-- OUT
	outLuminance  <= soutLuminance;    						-- OUT

	-- Etage s'occupant des MAX/MIN ============================--
	
	process (inRouge,inVert,inBleu)
	
		variable vQUI         : tQUI;
		variable vMAX, vMIN   : tColor8;
		variable vMAX2, vMIN2 : tColor8_Add;
		
	begin
	
		vMAX := inRouge; vQUI := R;
		if inVert > vMAX then vMAX := inVert; vQUI := V; end if;
		if inBleu > vMAX then vMAX := inBleu; vQUI := B; end if;
		
		vMIN := inRouge;
		if inVert < vMIN then vMIN := inVert; end if;
		if inBleu < vMIN then vMIN := inBleu; end if;
		
		sMAX_Futur(0) <= vMAX; -- Que vaut le MAX
		sMIN_Futur(0) <= vMIN; -- Que vaut le MIN
		sQUI_Futur <= vQUI; -- Qui est le MAX?
		sMAXmMIN_Futur(0) <= vMAX-vMIN;
		
		vMAX2 := "0"&vMAX; -- MAX sur 1 Bit de +
		vMIN2 := "0"&vMIN; -- MIN sur 1 Bit de +
		sMAXpMIN_Futur(0) <= vMAX2+vMIN2;
				
	end process;
	
	-- Etage s'occupant de la LUMINOSITÉ =======================--
	-- L = (MAX+MIN)/2
	
	soutLuminance_Futur <=
		sMAXpMIN(Pipe+2)(tColor8_Add'high downto 1);
	
	-- Etage s'occupant de la SATURATION =======================--
	--              0               si MAX=MIN
	-- S = (MAX-MIN)/(MAX+MIN)      si L <= 0.5 [MAX+MIN <= 1.0]
	--     (MAX-MIN)/(2-(MAX+MIN))  si L >  0.5 [MAX+MIN >  1.0]
	
	sS_BAS_Futur <= not sMAXpMIN(1) when sMAXpMIN(1) > cCr8_Un
			       else sMAXpMIN(1); -- MAX+MIN ou 2-(MAX+MIN)

			
	process (sMAXmMIN)
	begin
		sS_HAUT_Futur <= (others=>'0');
		sS_HAUT_Futur(tColor8_Div'high downto tColor8_Add'high)
												<= sMAXmMIN(1);
	end process;
		
	process (sS_RES,sMAXmMIN)
		variable vS : tColor8;
	begin
		if    sMAXmMIN(Pipe+2)=0 then vS := (others=>'0'); -- 0/x=0
		elsif sS_RES>=cCr8_Un    then vS := (others=>'1'); -- x/x~1
		else vS := sS_RES(tColor8'high downto 0);		-- y/x
		end if;
		
		soutSaturation_Futur <= vS;
		
	end process;
	
	-- Etage s'occupant de la TEINTE ===========================--
	--                0              si MAX=MIN
	--      (V-B)/(MAX-MIN)/6 + 0/3  si MAX=R
	-- H =  (B-R)/(MAX-MIN)/6 + 1/3  si MAX=V
	--      (R-V)/(MAX-MIN)/6 + 2/3  si MAX=B

	with sQUI select
	sH_SUB_Futur(0) <= sH_Vert  - sH_Bleu  when R,
	                   sH_Bleu  - sH_Rouge when V,
	                   sH_Rouge - sH_Vert  when B;
	
	with sQUI select
	sH_ADD_Futur(0) <= cCr8_Zero   when R, -- 0
	                   cCr8_1Tiers when V, -- 1/3
	                   cCr8_2Tiers when B; -- 2/3
	
	sH_BAS_Futur <= sMAXmMIN(1);
	
	process (sH_SUB)
		variable vSUB : tColor8;
	begin
		sH_HAUT_Futur <= (others=>'0');
		
		if sH_SUB(0)(tColor8_Add'high)='0' -- Valeure absolue
			then vSUB :=     sH_SUB(0)(tColor8'high downto 0);
			else vSUB := not sH_SUB(0)(tColor8'high downto 0);
		end if;

		sH_HAUT_Futur(tColor8_Div'high downto
					  tColor8_Add'high)	<= vSUB;
	end process;
	
	process (sH_RES,sH_SUB,sH_ADD,sMAXmMIN)
		variable vH : tColor8;
	begin
		if sMAXmMIN(Pipe+2)=0 then 
			vH := (others=>'0');
		else
			if sH_RES>=cCr8_Un then
				 vH := cCr8_1Six; -- x/x ~ 1 mais /6 = 1/6
			else vH := sH_RES(tColor8'high downto 0)/6;
			end if;
		
			if sH_SUB(Pipe+1)(tColor8_Add'high)='0' then
			     vH := sH_ADD(Pipe+1) + vH; -- Positif
			else vH := sH_ADD(Pipe+1) - vH; -- Négatif
			end if;
		end if;
		
		soutTeinte_Futur <= vH;
		
	end process;
	
end STRUCT;