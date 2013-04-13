--------------------------------------------------------------------
-- i2c_clkgen.vhd -- I2C base clock generator 
--                   with clock stretching feature
---------------------------------------------------------------------------------

	-- Project   Camera et Encodeur MPEG-4 Embarqué
	-- Support   FPGA Cyclone - EP1C12Q240C8 de Altera
	-- Version   0.1
	-- History   10-apr-2006 EW 0.1 initial  
	-- Author    Eugene wonyu    
	----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity i2c_clkgen is 
	port (
		signal clk     : in std_logic;
		signal rst     : in std_logic;
		
		-- count used for dividing clk signal
		signal clk_cnt : in std_logic_vector(7 downto 0);
		
		-- I2C clock output generated
		signal sclk    : out std_logic;
		
		-- I2C clock line SCL (used for clock stretching)
		signal scl_in  : in std_logic;
		signal scl_out : in std_logic
	);

end i2c_clkgen;

architecture behavioral of i2c_clkgen is

signal clk_ctr   : unsigned(7 downto 0);
signal clk_wait  : std_logic;
signal i_clk_out : std_logic;

begin

sclk <= i_clk_out; 

process(clk, rst)
begin
	if ( rst = '1' ) then
		clk_ctr   <= (others => '0');
		i_clk_out <= '1';
	elsif (rising_edge(clk)) then
		if ( clk_ctr >= unsigned(clk_cnt) ) then
			clk_ctr   <= (others => '0');
			i_clk_out <= '1'; 
		else
			if ( clk_wait = '0' ) then
				clk_ctr <= clk_ctr + 1;
			end if;
			i_clk_out <= '0';
		end if;
	end if;
end process;

-- clk_wait <= '1' when (scl_out = '1' and scl_in = '0') else '0'; -- problem rencontres avec ce mode
clk_wait <= '0';

end behavioral;