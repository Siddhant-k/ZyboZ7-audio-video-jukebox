library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.VComponents.all;

entity Lab5 is
    Port ( sys_clk : in std_logic;
          reset_btn   : in std_logic;
          TMDS, TMDSB : out std_logic_vector(3 downto 0);
          --**************************Audio****************************--
           clk : in STD_LOGIC;
           fast : in STD_Logic;
           slow : in STD_logic;
           stop : in std_logic;
           pause : in std_logic;
           twink_start: in std_logic;
           jingle_start: in std_logic;
           christmas_start: in std_logic;
           mclk : out STD_LOGIC;
           bclk : out STD_LOGIC;
           mute : out STD_LOGIC;
           pbdat : out STD_logic;
           pblrc : out STD_LOGIC
           --**********************Audio*****************************--
           );
          end Lab5;

architecture Behavioral of Lab5 is

-- Video Timing Parameters
--1280x720@60HZ
constant HPIXELS_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(1280, 11)); --Horizontal Live Pixels
constant VLINES_HDTV720P  : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(720, 11));  --Vertical Live ines
constant HSYNCPW_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(80, 11));  --HSYNC Pulse Width
constant VSYNCPW_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(5, 11));    --VSYNC Pulse Width
constant HFNPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(72, 11));   --Horizontal Front Porch
constant VFNPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(3, 11));    --Vertical Front Porch
constant HBKPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(216, 11));  --Horizontal Front Porch
constant VBKPRCH_HDTV720P : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(22, 11));   --Vertical Front Porch

constant pclk_M : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(36, 8));
constant pclk_D : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(24, 8)); 

constant tc_hsblnk: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1);
constant tc_hssync: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P);
constant tc_hesync: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P);
constant tc_heblnk: std_logic_vector(10 downto 0) := (HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P);
constant tc_vsblnk: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1);
constant tc_vssync: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P);
constant tc_vesync: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P);
constant tc_veblnk: std_logic_vector(10 downto 0) := (VLINES_HDTV720P - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P);
signal sws_clk: std_logic_vector(3 downto 0); --clk synchronous output
signal sws_clk_sync: std_logic_vector(3 downto 0); --clk synchronous output
signal bgnd_hblnk : std_logic;
signal bgnd_vblnk : std_logic;


signal red_data, green_data, blue_data : std_logic_vector(7 downto 0) := (others => '0');
signal hcount, vcount : signed(10 downto 0);
signal hsync, vsync, active : std_logic;
signal pclk : std_logic;

signal clkfb : std_logic;
signal rgb_data : std_logic_vector(23 downto 0) := (others => '0');

Signal slow_clk: std_logic :='0';
Signal slow_counter: unsigned (28 downto 0) := (others => '0');

constant UBBLUE_RED    : std_logic_vector(7 downto 0) := x"00";
constant UBBLUE_GREEN  : std_logic_vector(7 downto 0) := x"5B";
constant UBBLUE_BLUE   : std_logic_vector(7 downto 0) := x"BB";

constant CAPEN_RED    : std_logic_vector(7 downto 0) := x"99";
constant CAPEN_GREEN  : std_logic_vector(7 downto 0) := x"00";
constant CAPEN_BLUE   : std_logic_vector(7 downto 0) := x"00";

constant BRONZE_RED    : std_logic_vector(7 downto 0) := x"AD";
constant BRONZE_GREEN  : std_logic_vector(7 downto 0) := x"84";
constant BRONZE_BLUE   : std_logic_vector(7 downto 0) := x"1F";

constant BAIRD_RED    : std_logic_vector(7 downto 0) := x"E4";
constant BAIRD_GREEN  : std_logic_vector(7 downto 0) := x"E4";
constant BAIRD_BLUE   : std_logic_vector(7 downto 0) := x"E4";

--Defining types for Finite State Machine
type state_type is (IDLE,TYPE1, TYPE2, TYPE3, TYPE4, TYPE5, TYPE6, TYPE7);
signal state: state_type := IDLE;
                --******************************Audio********************************--
Signal r_data, l_data : std_logic_vector(23 downto 0) :=(others=>'0');
Signal mclk_sig, ready, slow_clk5, slow_clk1, slow_clk2, slow_clk3, note_size,slow_clk_break: std_logic :='0';
Signal slow_counter3,slow_counter1,slow_counter_break: unsigned (23 downto 0) := (others => '0');
Signal slow_counter2: unsigned (25 downto 0) := (others => '0');

-- Signals for generating audio square wave
Signal tone_counter: unsigned (8 downto 0) := (others => '0');
Signal tone_terminal_count: unsigned (8 downto 0) := (others => '0');

--Clock cycle counts for 200Hz, 400Hz, 800Hz, 1600Hz
--constant COUNT_C5: unsigned(6 downto 0) := to_unsigned(92,7); -- 48Khz audio rate, 523Hz signal
--constant COUNT_E5: unsigned(6 downto 0) := to_unsigned(73,7); -- 48Khz audio rate, 658Hz signal
--constant COUNT_G5: unsigned(6 downto 0) := to_unsigned(61,7); -- 48Khz audio rate, 787Hz signal
--constant COUNT_C6: unsigned(6 downto 0) := to_unsigned(46,7); -- 48Khz audio rate, 1044Hz signal
--This was for the lab, see below for bonus

constant COUNT_C5: unsigned(8 downto 0) := to_unsigned(92,9); -- 48Khz audio rate, 523Hz signal
constant COUNT_D5: unsigned(8 downto 0) := to_unsigned(82,9); -- 48Khz audio rate, 523Hz signal
constant COUNT_E5: unsigned(8 downto 0) := to_unsigned(73,9); -- 48Khz audio rate, 658Hz signal
constant COUNT_F5: unsigned(8 downto 0) := to_unsigned(69,9); -- 48Khz audio rate, 658Hz signal
constant COUNT_G5: unsigned(8 downto 0) := to_unsigned(61,9); -- 48Khz audio rate, 787Hz signal
constant COUNT_A5: unsigned(8 downto 0) := to_unsigned(55,9); -- 48Khz audio rate, 658Hz signal
constant COUNT_B5: unsigned(8 downto 0) := to_unsigned(49,9); -- 48Khz audio rate, 658Hz signal
constant COUNT_C6: unsigned(8 downto 0) := to_unsigned(46,9); -- 48Khz audio rate, 1044Hz signal
constant COUNT_B3: unsigned(8 downto 0) := to_unsigned(194,9); -- 48Khz audio rate, 440Hz signal

-- ********** TWINKLE TWINKLE LITTLE STAR ************

constant COUNT_A4: unsigned(8 downto 0) := to_unsigned(109,9); -- 48Khz audio rate, 440Hz signal
constant COUNT_B4: unsigned(8 downto 0) := to_unsigned(97,9); -- 48Khz audio rate, 440Hz signal
constant COUNT_C4: unsigned(8 downto 0) := to_unsigned(183,9); -- 48Khz audio rate, 262Hz signal
constant COUNT_D4: unsigned(8 downto 0) := to_unsigned(163,9); -- 48Khz audio rate, 294Hz signal
constant COUNT_E4: unsigned(8 downto 0) := to_unsigned(145,9); -- 48Khz audio rate, 330Hz signal
constant COUNT_F4: unsigned(8 downto 0) := to_unsigned(138,9); -- 48Khz audio rate, 349Hz signal
constant COUNT_FS4: unsigned(8 downto 0) := to_unsigned(130,9); -- 48Khz audio rate, 349Hz signal
constant COUNT_G4: unsigned(8 downto 0) := to_unsigned(122,9); -- 48Khz audio rate, 392Hz signal
constant break: unsigned(8 downto 0) := to_unsigned(0,9);
-- *********** TWINKLE TWINKLE ENDS *******************

type music is array(0 to 90) of unsigned(8 downto 0);
type music2 is array(0 to 110) of unsigned(8 downto 0);
type music3 is array(0 to 196) of unsigned(8 downto 0);

Signal twinkle: music := (break,break,COUNT_C4,break,COUNT_C4,break,COUNT_G4,break,COUNT_G4,break,COUNT_A4,break,COUNT_A4,break,COUNT_G4, COUNT_G4,break, COUNT_F4,break, COUNT_F4,break, COUNT_E4,break, COUNT_E4,break, COUNT_D4,break, COUNT_D4,break,COUNT_C4,COUNT_C4,break,COUNT_G4,break,COUNT_G4,break,COUNT_F4,break, COUNT_F4,break,COUNT_E4,break,COUNT_E4,break,COUNT_D4,COUNT_D4,break,COUNT_G4,break,COUNT_G4,break,COUNT_F4,break,COUNT_F4,break,COUNT_E4,break, COUNT_E4,break, COUNT_D4,COUNT_D4,break,COUNT_C4,break,COUNT_C4,break,COUNT_G4,break,COUNT_G4,break,COUNT_A4,break,COUNT_A4,break, COUNT_G4,COUNT_G4,break,COUNT_F4,break, COUNT_F4,break,COUNT_E4,break,COUNT_E4,break,COUNT_D4,break, COUNT_D4,break,COUNT_C4,COUNT_C4);
Signal jingle: music2 := (break,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,break,COUNT_G4,break,COUNT_C4,break,COUNT_D4,break,COUNT_E4,COUNT_E4,COUNT_E4,COUNT_E4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,break,COUNT_D4,break,COUNT_D4,break,COUNT_D4,COUNT_D4,COUNT_G4,COUNT_G4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,break,COUNT_G4,break,COUNT_C4,break,COUNT_D4,break,COUNT_E4,COUNT_E4,COUNT_E4,COUNT_E4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_F4,break,COUNT_E4,break,COUNT_E4,break,COUNT_E4,break,COUNT_G4,break,COUNT_G4,break,COUNT_F4,break,COUNT_D4,break,COUNT_C4,COUNT_C4,COUNT_C4,COUNT_C4);
Signal christmas: music3 := (break,break,COUNT_D4,COUNT_D4,break,COUNT_B4,COUNT_B4,break,COUNT_B4,break,COUNT_C5,break,COUNT_B4,break,COUNT_A4,break,COUNT_G4,COUNT_G4,break,COUNT_E4,COUNT_E4,break,COUNT_D4,break,COUNT_D4,break,COUNT_E4,COUNT_E4,break,COUNT_A4,COUNT_A4,break,COUNT_FS4,COUNT_FS4,break,COUNT_G4,COUNT_G4,COUNT_G4,COUNT_G4,break,COUNT_D4,COUNT_D4,break,COUNT_G4,COUNT_G4,break,COUNT_G4,break,COUNT_A4,break,COUNT_G4,break,COUNT_FS4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_A4,COUNT_A4,break,COUNT_A4,break,COUNT_B4,break,COUNT_A4,break,COUNT_G4,break,COUNT_FS4,COUNT_FS4,break,COUNT_D4,COUNT_D4,break,COUNT_D4,COUNT_D4,break,COUNT_B4,COUNT_B4,break,COUNT_B4,break,COUNT_C5,break,COUNT_B4,break,COUNT_A4,break,COUNT_G4,COUNT_G4,break,COUNT_E4,COUNT_E4,break,COUNT_D4,break,COUNT_D4,break,COUNT_E4,COUNT_E4,break,COUNT_A4,COUNT_A4,break,COUNT_FS4,COUNT_FS4,break,COUNT_G4,COUNT_G4,COUNT_G4,COUNT_G4,break,COUNT_D4,COUNT_D4,COUNT_G4,COUNT_G4,break,COUNT_G4,break,COUNT_A4,break,COUNT_G4,break,COUNT_FS4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_E4,COUNT_E4,break,COUNT_A4,COUNT_A4,break,COUNT_A4,break,COUNT_B4,break,COUNT_A4,break,COUNT_G4,break,COUNT_FS4,COUNT_FS4,break,COUNT_D4,COUNT_D4,break,COUNT_D4,COUNT_D4,break,COUNT_B4,COUNT_B4,break,COUNT_B4,break,COUNT_C5,break,COUNT_B4,break,COUNT_A4,break,COUNT_G4,COUNT_G4,break,COUNT_E4,COUNT_E4,break,COUNT_D4,break,COUNT_D4,break,COUNT_E4,COUNT_E4,break,COUNT_A4,COUNT_A4,break,COUNT_FS4,COUNT_FS4,break,COUNT_G4,COUNT_G4,COUNT_G4,COUNT_G4,break,COUNT_D4,COUNT_D4);

Signal i,j,k: integer:= 0;
signal twink_check,jingle_check,christmas_check: std_logic:='0';

component ssm2603_i2s
    port(  sys_clk : in STD_LOGIC;
           r_data : in STD_LOGIC_VECTOR (23 downto 0);
           l_data : in STD_LOGIC_VECTOR (23 downto 0);
           bclk : out STD_LOGIC;
           pbdat : out STD_LOGIC;
           pblrc : out STD_LOGIC;
           mclk : out STD_LOGIC;
           mute : out STD_LOGIC;
           ready : out STD_LOGIC
);
end component;
                  
begin
codec: ssm2603_i2s port map(
    sys_clk => clk,
    mclk => mclk_sig,
    bclk => bclk,
    mute => mute,
    pblrc => pblrc,
    pbdat => pbdat,
    l_data => l_data,
    r_data => r_data,
    ready => ready
    );
    mclk <= mclk_sig;

--*******************************************end audio***********************************--
 
 
--Create a PLL that takes in sys_clk and drives the pclk signal.
--pclk should be 74.25MHz
--You may connect the locked output to open - we aren't using it.
--You may connect the reset input to '0' as in Lab4

pixel_clock_gen : entity work.pxl_clk_gen port map (
    clk_in1 => sys_clk,
    clk_out1 => pclk,
    clk_out2 => mclk_sig,
    locked => open,
    reset => '0'
);

timing_inst : entity work.timing port map (
	tc_hsblnk=>tc_hsblnk, --input
	tc_hssync=>tc_hssync, --input
	tc_hesync=>tc_hesync, --input
	tc_heblnk=>tc_heblnk, --input
	hcount=>hcount, --output
	hsync=>hsync, --output
	hblnk=>bgnd_hblnk, --output
	tc_vsblnk=>tc_vsblnk, --input
	tc_vssync=>tc_vssync, --input
	tc_vesync=>tc_vesync, --input
	tc_veblnk=>tc_veblnk, --input
	vcount=>vcount, --output
	vsync=>vsync, --output
	vblnk=>bgnd_vblnk, --output
	restart=>reset_btn,
	clk=>pclk);
	
hdmi_controller : entity work.rgb2dvi 
    generic map (
        kClkRange => 2
    )
    port map (
        TMDS_Clk_p => TMDS(3),
        TMDS_Clk_n => TMDSB(3),
        TMDS_Data_p => TMDS(2 downto 0),
        TMDS_Data_n => TMDSB(2 downto 0),
        aRst => '0',
        aRst_n => '1',
        vid_pData => rgb_data,
        vid_pVDE => active,
        vid_pHSync => hsync,
        vid_pVSync => vsync,
        PixelClk => pclk, 
        SerialClk => '0');
        
        
active <= not(bgnd_hblnk) and not(bgnd_vblnk); 
rgb_data <= red_data & blue_data & green_data;	 

clk_slow: process (pclk)
    begin
        if rising_edge(pclk) then
            if slow_counter = 74250000 then
            slow_counter <= (others => '0');
            slow_clk <= '1';
            else
            slow_counter <= slow_counter + 1;
            slow_clk <= '0';
            end if;
       end if;
end process clk_slow;

state_proc: process (mclk_sig)
    begin
        if rising_edge(mclk_sig) then
            case state is
                when IDLE =>
                if slow_clk5 ='1' then 
                
                if twink_check = '1' then
                state <= TYPE5;
                end if;
                
                if jingle_check = '1' then
                state <= TYPE1;
                end if;
                
                if christmas_check ='1' then
                state <= TYPE3;
                end if;
                end if;
                
                when TYPE1 =>
                if slow_clk5 ='1' then 
                
                if jingle_check = '1' then
                state <= TYPE2;
                   if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE1;
                    elsif stop = '1' and pause = '1' then
                    state <= TYPE1;
                    end if;
                end if;
                
                if jingle_check ='0' then
                state <= IDLE;
                end if;
                end if;
                    
                when TYPE2 => 
                if slow_clk5 ='1' then
                
                if jingle_check = '1' then
                state <= TYPE1;
                    if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE2;
                    elsif stop = '1' and pause = '1' then
                    state <= TYPE2;
                    end if;
                end if;
                
                if jingle_check = '0' then
                state <= IDLE;
                end if;
                end if;
                
                
                when TYPE3 => 
                if slow_clk5 ='1' then
                
                if christmas_check = '1' then 
                state <= TYPE4; 
                  if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE3;
                    end if;
                end if;
                
                if christmas_check = '0' then
                state <= IDLE;
                end if;
                end if;
                
                
                when TYPE4 => 
                if slow_clk5 ='1' then 
                
                if christmas_check = '1' then
                state <= TYPE7; 
                  if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE4;
                    end if;
                end if;
                
                if christmas_check = '0' then
                state <= IDLE;
                end if;
                
                end if;
                
                when TYPE5 => 
                if slow_clk5 ='1' then
                
                if twink_check = '1' then 
                state <= TYPE6;
                  if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE5;
                    end if;
                end if;
                
                if twink_check = '0' then
                state <= IDLE;
                end if;
                
                end if;
                
                when TYPE6 => 
                if slow_clk5 ='1' then 
                
                if twink_check ='1' then
                state <= TYPE5;
                  if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE6;
                    end if;
                end if;
                
                if twink_check = '0' then
                state <= IDLE; 
                end if;
                
                end if;

                when TYPE7 => 
                if slow_clk5 ='1' then
                
                if christmas_check = '1' then 
                state <= TYPE3; 
                  if stop = '1' then
                    state <= IDLE;
                    elsif pause = '1' then
                    state <= TYPE7;
                    end if;
                end if;
                
                if christmas_check = '0' then
                state <= IDLE;
                end if;
                end if;
                
                
                end case;
        end if;
end process state_proc;

process(hcount, vcount, state)
begin
--    If hcount >= 200 and hcount<=500 and vcount >= 200 and vcount<=500 then 
----        If state= TYPE1 then
----            red_data <= UBBLUE_RED;
----            green_data <= UBBLUE_GREEN;
----            blue_data <= UBBLUE_BLUE; end if;
--         If state= TYPE2 then
--             red_data <= CAPEN_RED;
--             green_data <= CAPEN_GREEN;
--             blue_data <= CAPEN_BLUE; end if;
             
If state = Idle then
red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
end if;           
If state= TYPE1 then
    If vcount>600   then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsif (hcount<300 and hcount>200 and vcount>300 and vcount<400) or (hcount<500 and hcount>400 and vcount>500 and vcount<600) or (hcount<500 and hcount>400 and vcount>300 and vcount<400) or (hcount<300 and hcount>200 and vcount>500 and vcount<600) then
    red_data <= (others=>'0');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    elsif (hcount>=300 and hcount<= 400 and vcount > 300 and vcount < 600) or (hcount>200 and hcount< 300 and vcount > 400 and vcount < 500) or (hcount>400 and hcount< 500 and vcount > 400 and vcount < 500)then
    red_data <= (others=>'1');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 If state= TYPE2 then
 If vcount>600   then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsif (hcount<300 and hcount>200 and vcount>300 and vcount<400) or (hcount<500 and hcount>400 and vcount>500 and vcount<600) or (hcount<500 and hcount>400 and vcount>300 and vcount<400) or (hcount<300 and hcount>200 and vcount>500 and vcount<600) then
    red_data <= (others=>'1');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    elsif (hcount>=300 and hcount<= 400 and vcount > 300 and vcount < 600) or (hcount>200 and hcount< 300 and vcount > 400 and vcount < 500) or (hcount>400 and hcount< 500 and vcount > 400 and vcount < 500)then
    red_data <= (others=>'0');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 If state= TYPE3 then
 If vcount< 150 and ((hcount mod 5) =2 or hcount mod 5 =3) and ((vcount mod 3) =2 or vcount mod 3 =0) then
  red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
      elsIf vcount>600   then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsif (hcount<300 and hcount>200 and vcount>300 and vcount<400) or (hcount<500 and hcount>400 and vcount>500 and vcount<600) or (hcount<500 and hcount>400 and vcount>300 and vcount<400) or (hcount<300 and hcount>200 and vcount>500 and vcount<600) then
    red_data <= (others=>'1');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    elsif (hcount>=300 and hcount<= 400 and vcount > 300 and vcount < 600) or (hcount>200 and hcount< 300 and vcount > 400 and vcount < 500) or (hcount>400 and hcount< 500 and vcount > 400 and vcount < 500)then
    red_data <= (others=>'0');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 
 
 If state= TYPE4 then
 If vcount< 580 and ((hcount mod 5) =1 or hcount mod 5 =0)and ((vcount mod 3) =1 or vcount mod 3 =0) then
  red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsIf vcount>580   then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsif (hcount<300 and hcount>200 and vcount>300 and vcount<400) or (hcount<500 and hcount>400 and vcount>500 and vcount<600) or (hcount<500 and hcount>400 and vcount>300 and vcount<400) or (hcount<300 and hcount>200 and vcount>500 and vcount<600) then
    red_data <= (others=>'0');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    elsif (hcount>=300 and hcount<= 400 and vcount > 300 and vcount < 600) or (hcount>200 and hcount< 300 and vcount > 400 and vcount < 500) or (hcount>400 and hcount< 500 and vcount > 400 and vcount < 500)then
    red_data <= (others=>'1');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;

 
 If state= TYPE5 then
    If hcount-300 <vcount and hcount-100 <vcount and vcount -300 <hcount and vcount-100 <hcount and hcount+ vcount >400 and hcount+vcount < 600  then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 If state= TYPE6 then
    If hcount-300 <vcount and hcount-100 <vcount and vcount -300 <hcount and vcount-100 <hcount and hcount+ vcount >400 and hcount+vcount < 600  then 
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'1');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 
  If state= TYPE7 then
 If vcount>600   then 
    red_data <= (others=>'1');
    green_data <= (others=>'1');
    blue_data <= (others=>'1');
    elsif (hcount<300 and hcount>200 and vcount>300 and vcount<400) or (hcount<500 and hcount>400 and vcount>500 and vcount<600) or (hcount<500 and hcount>400 and vcount>300 and vcount<400) or (hcount<300 and hcount>200 and vcount>500 and vcount<600) then
    red_data <= (others=>'0');
    green_data <= (others=>'1');
    blue_data <= (others=>'0');
    elsif (hcount>=300 and hcount<= 400 and vcount > 300 and vcount < 600) or (hcount>200 and hcount< 300 and vcount > 400 and vcount < 500) or (hcount>400 and hcount< 500 and vcount > 400 and vcount < 500)then
red_data <= (others=>'1');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    else
    red_data <= (others=>'0');
    green_data <= (others=>'0');
    blue_data <= (others=>'0');
    end if;
 end if;
 
end process;
       --******************************************************Rest audio***********************************************************--
       clk_slow2: process (mclk_sig)
    begin
    If rising_edge(mclk_sig) then
--            If state /= IDLE then
                if slow_counter1 = 3072000 then
                    slow_counter1 <= (others => '0');
                    slow_clk1 <= '1';
                else
                    slow_counter1 <= slow_counter1 + 1;
                    slow_clk1 <= '0';
--                end if;
                  end if;    
    end if;
       
end process clk_slow2;

clk_superslow: process (mclk_sig)
    begin
    If rising_edge(mclk_sig) then
                if slow_counter2 = 4144000 then
                    slow_counter2 <= (others => '0');
                    slow_clk3 <= '1';
                else
                    slow_counter2 <= slow_counter2 + 1;
                    slow_clk3 <= '0';
                end if;
         
    end if;
       
end process clk_superslow;

clk_fast: process (mclk_sig)
begin
if rising_edge(mclk_sig) then
                     if slow_counter3 = 1536000 then
                        slow_counter3 <= (others => '0');
                        slow_clk2 <= '1';
                     else
                        slow_counter3 <= slow_counter3 + 1;
                        slow_clk2 <= '0';
                     end if;
  end if;
end process clk_fast;

tone_counter_proc: process(mclk_sig)
begin
    if rising_edge(mclk_sig) then
        if ready = '1' then
            if  tone_counter < tone_terminal_count then
            tone_counter <= tone_counter + 1;
            else
            tone_counter  <= (others => '0');
            end if;
        end if;
    end if;
end process tone_counter_proc;

twinkle_proc: process(mclk_sig)
    begin
    if rising_edge(mclk_sig) then
         if twink_start = '1' then
            twink_check <= '1';
            
            jingle_check<= '0';
            if fast = '0' and slow = '0' then
                j <= 0;
            end if;
            
            christmas_check <= '0';
            if fast = '0' and slow = '0' then
                k <= 0;
            end if;
            
         end if;
         
         if pause = '1' and twink_check = '1' then
            tone_terminal_count<= break;
         end if;
         
            if twink_check = '1' and pause = '0' then           
               if slow_clk5 = '1' then
               tone_terminal_count <= twinkle(i);
                 i<=i+1;
                end if;
                if i > 91 or stop = '1' then
                     twink_check <= '0';
                        i <= 0;
                     jingle_check<= '0';
                        k <= 0;
                     christmas_check <= '0';
                        j <= 0;
                     tone_terminal_count <= break;     
                end if;     
              end if;
              
 -- **** TWINKLE TWINKLE ENDS HERE *****             
 -- **** JINGLE BELLS STARTS HERE ******   
           
            if jingle_start = '1' then
               jingle_check <= '1';
               
               twink_check <= '0';
               if fast = '0' and slow = '0' then
                i <= 0;
               end if;
               
               christmas_check <= '0';
               if fast = '0' and slow = '0' then
                k <= 0;
               end if;
         end if;
         if pause = '1' and jingle_check = '1' then
            tone_terminal_count<= break;
         end if;
         if jingle_check = '1' and pause = '0' then           
               if slow_clk5 = '1' then
               tone_terminal_count <= jingle(j);
               j<=j+1;       
               end if;
                if j > 110 or stop = '1' then
                     twink_check <= '0';
                        i <= 0;
                     jingle_check<= '0';
                        k <= 0;
                     christmas_check <= '0';
                        j <= 0;
                     tone_terminal_count <= break;    
                end if;     
        end if;
 -- **** JINGLE BELLS ENDS HERE *****
 -- **** CHRISTMAS/HNY STARTS HERE *****
        if christmas_start = '1' then
            christmas_check <= '1';
            
            jingle_check<= '0';
            if fast = '0' and slow = '0' then
                j <= 0;
            end if;
            
             twink_check <= '0';
             if fast = '0' and slow = '0' then
                i <= 0;
             end if;
         end if;
         if pause = '1' and christmas_check = '1' then
            tone_terminal_count<= break;
         end if;
            if christmas_check = '1' and pause = '0' then           
               if slow_clk5 = '1' then
               tone_terminal_count <= christmas(k);
                 k<=k+1;
                end if;
                if k > 196 or stop = '1' then
                     twink_check <= '0';
                        i <= 0;
                     jingle_check<= '0';
                        k <= 0;
                     christmas_check <= '0';
                        j <= 0;
                     tone_terminal_count <= break;     
                end if;     
              end if;
-- ****** CHRISTMAS/HNY ENDS HERE *******

    end if;
    end process twinkle_proc;

    
r_data <= (others => '0') when tone_counter < (tone_terminal_count/2) else X"0FFFFF"; -- full amp output gives us an almost max feq square wave
l_data <= (others => '0') when tone_counter < (tone_terminal_count/2) else X"0FFFFF"; -- full amp output gives us an almost max feq square wave

slow_clk5<= slow_clk2 when fast='1' and slow='0' else slow_clk3 when fast='0' and slow='1' else slow_clk1;


--tone_terminal_count <= twinkle(i) when twink_check ='1' else 
--jingle(j) when jingle_check ='1' else 
--christmas(k) when christmas_check = '1'; 
--tone_terminal_count <= christmas(k) when christmas_check = '1'; 


       
       
                                       
end Behavioral;

