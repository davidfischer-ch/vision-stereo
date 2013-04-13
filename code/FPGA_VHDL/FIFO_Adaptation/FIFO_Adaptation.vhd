--=============================================================--
-- Nom de l'étudiant   : David FISCHER TE3
-- Nom du projet       : Vision Stéréoscopique 2006
-- Nom du VHDL         : FIFO_Adaptation
-- Nom de la FPGA      : Cyclone - EP1C12F256C7
-- Nom de la puce USB2 : Cypress - FX2
-- Nom du compilateur  : Quartus II
--=============================================================--

-- Module contenant une FIFO...

--=============================================================--

--=============================================================--

library IEEE;
use     IEEE.std_logic_1164.all;
use		IEEE.std_logic_arith.all;
use 	work.VisionStereoPack.all;
	
entity FIFO_Adaptation is

	generic (nb : natural := 1;
	         FIFO_TailleMots : natural := 4;
			 FIFO_TailleBits : natural := 2);
		
	port (nReset : in std_logic;

		  inCLOCK  : in std_logic;
		  outCLOCK : in std_logic;
		
		  inWRITE : in std_logic;
		  inBITS  : in unsigned (nb-1 downto 0);
		
		  outREAD : out std_logic;
		  outBITS : out unsigned (nb-1 downto 0));
		
end FIFO_Adaptation;

--=============================================================--

architecture STRUCT of FIFO_Adaptation is

	component FIFO_MultiClock is
		generic (NombreBits, TailleMots, TailleBits : natural);
		port (aclr	  : in std_logic := '0';
			  data	  : in unsigned (NombreBits-1 downto 0);
			  rdclk	  : in std_logic;
			  rdreq	  : in std_logic;
			  wrclk	  : in std_logic;
			  wrreq	  : in std_logic;
			  q		  : out unsigned (NombreBits-1 downto 0);
			  rdempty : out std_logic);
	end component;
	
	signal sEMPTY : std_logic;
	signal sREAD, sREAD_Futur : std_logic;
	signal sBITS, sBITS_Futur : unsigned (nb-1 downto 0);
		
begin --=======================================================--

	-- Notre FIFO M4K		
	FIFO_MultiClock_inst : FIFO_MultiClock
		generic map (NombreBits => nb,
					 TailleMots => FIFO_TailleMots,
					 TailleBits => FIFO_TailleBits)
					
		port map (aclr => not nReset,
			  	  wrclk   => inCLOCK,
			  	  wrreq   => inWRITE,
			  	  data	  => inBITS,
			  	  rdclk	  => outCLOCK,
			  	  rdreq	  => sREAD_Futur,
			  	  q		  => sBITS_Futur,
				  rdempty => sEMPTY);
		
	-- Lecture si nous avons quelque chose...	
	process (outCLOCK,nReset)
	begin
		if nReset='0' then
			sREAD <= '0';
			sBITS <= (others=>'0');
		elsif rising_edge (outCLOCK) then
			sREAD <= sREAD_Futur;
			sBITS <= sBITS_Futur;
		end if;
	end process;
	
	sREAD_Futur <= not sEMPTY;
	
	outREAD <= sREAD;
	outBITS <= sBITS;

end STRUCT;