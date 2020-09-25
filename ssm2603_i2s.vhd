----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/18/2019 12:12:52 AM
-- Design Name: 
-- Module Name: ssm2603_i2s - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ssm2603_i2s is
    Port ( clk : in STD_LOGIC;
           r_data : in STD_LOGIC_VECTOR (23 downto 0);
           l_data : in STD_LOGIC_VECTOR (23 downto 0);
           bclk : out STD_LOGIC;
           pbdat : out STD_LOGIC;
           pblrc : out STD_LOGIC;
           mclk : out STD_LOGIC;
           mute : out STD_LOGIC;
           ready : out STD_LOGIC);
end ssm2603_i2s;

architecture Behavioral of ssm2603_i2s is
signal mclk_sig : std_logic;
signal bclk_sig : std_logic := '0';
signal lrc_sig  : std_logic := '0';
signal mclk_cnt : std_logic := '0';
signal bclk_cnt : unsigned(5 downto 0) := (others => '0');
signal lr_cnt   : unsigned(6 downto 0) := (others => '0');
signal tx_data  : std_logic_vector(63 downto 0);

begin


clk_gen : entity work.mclk_gen port map (
    clk_in1 => clk,
    clk_out1 => mclk_sig,
    locked => open,
    reset => '0'
);

bclk_proc : process(mclk_sig)
begin
    if rising_edge(mclk_sig) then
        mclk_cnt <= not mclk_cnt;
        lr_cnt <= lr_cnt + 1;
        if mclk_cnt = '1' then
            bclk_sig <= not bclk_sig;
            if bclk_sig = '1' then
                bclk_cnt <= bclk_cnt + 1;
            end if;
        end if;
        if lr_cnt = 127 then
            lrc_sig <= not lrc_sig;
            if lrc_sig = '1' then
                ready <= '1';
            end if;
        else
            ready <= '0';
        end if;
    end if;
end process bclk_proc;

tx_data <= '0' & r_data & X"00" & r_data & "0000000";
pbdat <= tx_data(to_integer(bclk_cnt));

mclk <= mclk_sig;
bclk <= bclk_sig;
pblrc <= lrc_sig;
mute <= '1';

end Behavioral;
