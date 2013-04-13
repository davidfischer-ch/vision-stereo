--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : VisionStereoPack
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Paquetage du Projet (commentaires à mettre à jour)

--=============================================================--

-- Clock   => Horloge principale de chaque module
-- inClock => Horloge en entrée différente de la 'notre'
-- nReset  => Reset en logique actif-bas

-- CfgMoyX => Facteur X de réduction en nombre de pixels
-- CfgMoyY => Facteur Y de réduction en nombre de pixels

-- CfgMoyPre => Prédivision (lecture de la couleur depuis
--				le Xème LSB) nous permettant d'éviter
-- 				l'overflow pour de gros facteurs de réduction

-- CfgMoyDiv => Facteur de division nous permettant d'obtenir
-- 			    la moyenne doit être égal à
--				inCfgMoyX*inCfgMoyY/2^inCfgMoyPrediv

-- PosX(Contrôle) => Position en X du début du fenêtrage
-- PosY(Contrôle) => Position en Y du début du fenêtrage

-- PosX(Pupille) => Position en X du centre de la Pupille
-- PosY(Pupille) => Position en Y du centre de la Pupille

-- SyncVH  => Signaux de synchronisation
-- SyncVHP => Signaux de synchronisation + synchro pixel

-- Couleur   => Luminosité du pixel en cours (cas Couleur)
-- Luminance => Luminosité du pixel en cours (cas Monochrome)

-- Rouge => Composante rouge du pixel
-- Vert  => Composante verte du pixel
-- Bleu  => Composante bleue du pixel

-- Teinte     => Composante teinte du pixel en cours
-- Saturation => Composante saturation du pixel en cours
-- Luminance  => Composante luminance  du pixel en cours

-- TypeFlux => Type de flux (RVB-HSL) à fournir en sortie
-- Couleur1 => Première  composante du flux (Rouge-Teinte)
-- Couleur2 => Deuxième  composante du flux (Verte-Saturation)
-- Couleur3 => Troisième composante du flux (Bleue-Luminance)

-- Synch => Signal de synchronisation trame
-- Trame => Trame (dans notre cas trame du protocole TITI)

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;

package VisionStereoPack is
	
	-- Types de Synchronisation ==================================--
	
	subtype tSyncVH  is unsigned (1 downto 0);
	subtype tSyncVHP is unsigned (2 downto 0);
	
	-- Types de Position / Adresse / Nombre ======================--
	
	subtype tPosition6  is unsigned ( 5 downto 0);
	subtype tPosition8  is unsigned ( 7 downto 0);
	subtype tPosition11 is unsigned (10 downto 0);
	subtype tPosition16 is unsigned (15 downto 0);
	subtype tPosition22 is unsigned (21 downto 0);
	
	subtype tAdresse2  is unsigned (1  downto 0);
	subtype tAdresse7  is unsigned (6  downto 0);
	subtype tAdresse8  is unsigned (7  downto 0);
	
	subtype tNombre2  is unsigned ( 1 downto 0);
	subtype tNombre3  is unsigned ( 2 downto 0);
	subtype tNombre5  is unsigned ( 4 downto 0);
	subtype tNombre6  is unsigned ( 5 downto 0);
	subtype tNombre8  is unsigned ( 7 downto 0);
	subtype tNombre13 is unsigned (12 downto 0);
	subtype tNombre14 is unsigned (13 downto 0);
	subtype tNombre15 is unsigned (14 downto 0);
	subtype tNombre16 is unsigned (15 downto 0);
	subtype tNombre20 is unsigned (19 downto 0);
	subtype tNombre27 is unsigned (26 downto 0);
	
	subtype tNoLigne14 is unsigned (13 downto 0);
	subtype tNoImage15 is unsigned (14 downto 0);

	subtype tTrame16 is unsigned (15 downto 0);
	
	subtype tPrediv5 is unsigned (4 downto 0);
	
	subtype tRegI2C is unsigned (7 downto 0);
	
	-- Types Couleur =============================================--
	
	subtype tColor8      is unsigned ( 7 downto 0);
	subtype tColor8_Add  is unsigned ( 8 downto 0);
	subtype tColor8_Div2 is unsigned (14 downto 0);
	subtype tColor8_Div  is unsigned (15 downto 0);
	
	subtype tColor10 is unsigned ( 9 downto 0);
	subtype tColor16 is unsigned (15 downto 0);
	
	-- Types Représentant Bayer ==================================--
	
	type tBayerPosX is (G,D);
	type tBayerPosY is (B,H);
	type tBayerMat  is (BG,BD,HG,HD);
	
	-- Constantes de Contrôle ====================================--
	
	subtype tTypeFlux is std_logic;
	
	constant cTypeFluxRVB : tTypeFlux := '0';
	constant cTypeFluxHSL : tTypeFlux := '1';
	
	constant cDefCfgTypeFlux : tTypeFlux := cTypeFluxHSL;
	
	-- VERSION NUMÉRIQUE DE LA CONFIGURATION DU MOYENNEUR
	
	-- pareil en X et en Y...
	-- ----------------------------------------------------
	-- | 6x4 | .. 8  x | 3x2 | ... 16*2 x | 6x4 | .. 8  x |
	-- | périphérie    | détaillée        | périphérie    |
	-- ----------------------------------------------------
	
	constant nPerMoyX   : natural := 6;
	constant nPerMoyY   : natural := 4;
	constant nPerMoyPre : natural := 1;
	constant nPerMoyDiv : natural := 24;
	
	constant nDetMoyX   : natural := 3;
	constant nDetMoyY   : natural := 2;
	constant nDetMoyPre : natural := 1;
	constant nDetMoyDiv : natural := 6;
	
	constant nPerPerX : natural := 8; -- 8 blocs --> 8 pixels au final
	constant nPerPerY : natural := nPerPerX;
	constant nDetDetX : natural := 32;
	constant nDetDetY : natural := nDetDetX;
	constant nPerDetX : natural := 16;
	constant nPerDetY : natural := nPerDetX;
	
	constant nDetDebX : natural := nPerMoyX*nPerPerX;
	constant nDetDebY : natural := nPerMoyY*nPerPerY;
	constant nDetFinX : natural := nDetDebX+nPerMoyX*nPerDetX;
	constant nDetFinY : natural := nDetDebY+nPerMoyY*nPerDetY;
	
	-- VERSION NUMÉRIQUE DE LA CONFIGURATION DU FENÊTRAGE
	
	constant nCameraX : natural := 1280;
	constant nCameraY : natural := 1024;
	
	constant nTailleX : natural := 2*(nPerMoyX*(nPerPerX*2+nPerDetX));
	constant nTailleY : natural := 2*(nPerMoyY*(nPerPerY*2+nPerDetY));
	
	constant nFenetreDebX : natural := 4;
	constant nFenetreDebY : natural := 4;
	
	constant nFenetreFinX : natural := nFenetreDebX+nTailleX-1;
	constant nFenetreFinY : natural := nFenetreDebY+nTailleY-1;
	
	constant nFacteurX : natural := (nCameraX-nTailleX-1);
	constant nFacteurY : natural := (nCameraY-nTailleY-1);
	
	-- VERSION NUMÉRIQUE DE LA CONFIGURATION DES DÉLAIS
	
	-- DélaiImage = 24'000'000/(Nb.(DelaiLigne+TailleX+140+34)-TailleY
	-- TempsHorizontal = 140+34+TailleX+DelaiLigne
	
	constant nDelaiImage : natural := 256;
	constant nDelaiLigne : natural := 2048;
	
	-- VERSION CONSTANTES DE LA CONFIGURATION DES DÉLAIS
	
	constant cDefCfgDelaiImage : tNombre15 := to_unsigned(nDelaiImage,15);
	constant cDefCfgDelaiLigne : tNombre13 := to_unsigned(nDelaiLigne,13);
	
	-- Fonctions =================================================--
	
	function To_Unsigned (e : std_logic) return unsigned;
	function Mod_Position6 (e : tPosition6; m : tNombre6) return tPosition6;
	
	function To_BayerPosX (e : std_logic) return tBayerPosX;
	function Ne_BayerPosX (e : tBayerPosX) return tBayerPosX;
	
	function To_BayerPosY (e : std_logic) return tBayerPosY;
	function Ne_BayerPosY (e : tBayerPosY) return tBayerPosY;

end VisionStereoPack;

package body VisionStereoPack is
	
	function To_Unsigned (e : std_logic) return unsigned is
	begin
		if e='1' then
		     return to_unsigned(1,1);
		else return to_unsigned(0,1);
		end if;
	end To_Unsigned;
	
	function Mod_Position6 (e : tPosition6; m : tNombre6) return tPosition6 is
	begin
		if e >= m then
			 return (others=>'0');
		else return e+1;
		end if;
	end Mod_Position6;
	
	function To_BayerPosX (e : std_logic) return tBayerPosX is
	begin
		if e='0' then return G;
		else 		  return D;
		end if;
	end To_BayerPosX;
	
	function Ne_BayerPosX (e : tBayerPosX) return tBayerPosX is
	begin
		if e=G then return D;
		else		return G;
		end if;
	end Ne_BayerPosX;
	
	function To_BayerPosY (e : std_logic) return tBayerPosY is
	begin
		if e='0' then return H;
		else 		  return B;
		end if;
	end To_BayerPosY;
	
	function Ne_BayerPosY (e : tBayerPosY) return tBayerPosY is
	begin
		if e=B then return H;
		else		return B;
		end if;
	end Ne_BayerPosY;
		
end VisionStereoPack;