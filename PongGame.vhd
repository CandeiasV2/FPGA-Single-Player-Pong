----------------------------------------------------------------------------------
-- Company:
-- Engineer: Tiago
-- 
-- Create Date: 09/23/2024 09:57:38 PM
-- Design Name: PongGame
-- Module Name: PongGame - Behavioral
-- Project Name: Pong Game with VGA Display
-- Target Devices: Digilent Basys 3 Board featuring the Xilinx Artix-7 FPGA (XC7A35T-1CPG236C)
-- Tool Versions: Vivado 2024.1.2
-- Description: 
-- This module is the top-level design for a Pong game that interfaces with a VGA
-- controller to display the game on a monitor. It includes clock division from 
-- a 100MHz input to a 25MHz clock for VGA timing. Two components are instantiated:
-- VGA_Controller for VGA signal generation and Graphics_Controller for handling
-- game graphics such as paddles, ball movement, and scoring.
-- 
-- Dependencies: 
-- - VGA_Controller (provides horizontal and vertical synchronization signals)
-- - Graphics_Controller (generates game graphics and handles player input)
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- This module integrates a clock divider to generate a 25MHz clock from the 100MHz 
-- input. The game graphics and logic for handling user input and VGA signals are 
-- managed through component instantiation.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PongGame is
    Port ( CLK100MHZ : in STD_LOGIC;
           RST : in STD_LOGIC;
           Hsync : out STD_LOGIC;
           Vsync : out STD_LOGIC;
           SW_UP : in STD_LOGIC;
           SW_DN : in STD_LOGIC;
           vgaRed : out STD_LOGIC_VECTOR (3 downto 0);
           vgaBlue : out STD_LOGIC_VECTOR (3 downto 0);
           vgaGreen : out STD_LOGIC_VECTOR (3 downto 0));
end PongGame;

architecture Behavioral of PongGame is
    
    -- Declerating Components
    component VGA_Controller
        Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           Hsync : out STD_LOGIC;
           Vsync : out STD_LOGIC;
           Hpos : out STD_LOGIC_VECTOR (9 downto 0);
           Vpos : out STD_LOGIC_VECTOR (9 downto 0);
           VideoOn : out STD_LOGIC);
    end component;
    
    component Graphics_Controller 
        Port ( CLK : in STD_LOGIC;
               RST : in STD_LOGIC;
               Hpos : in STD_LOGIC_VECTOR (9 downto 0);
               Vpos : in STD_LOGIC_VECTOR (9 downto 0);
               VideoOn : in STD_LOGIC;
               P1_SW_UP : in STD_LOGIC;
               P1_SW_DN : in STD_LOGIC;
               vgaRed : out STD_LOGIC_VECTOR (3 downto 0);
               vgaBlue : out STD_LOGIC_VECTOR (3 downto 0);
               vgaGreen : out STD_LOGIC_VECTOR (3 downto 0));
        end component;
    
    -- Declaring Signals
    signal CLK : std_logic := '0';  -- 25MHz Clock Signal
    signal Hpos_VGA : std_logic_vector(9 downto 0);
    signal Vpos_VGA : std_logic_vector(9 downto 0);
    signal VideoOn_VGA : std_logic;

begin

    -- Clock Divider to Get a 25MHz Clock Signal From the 100MHz
    ClkDivider : process(CLK100MHZ)
        variable counter : integer := 0;
    begin
        if (rising_edge(CLK100MHZ)) then
            if (counter = 1) then
                CLK <= not CLK;
                counter := 0;
            else
                counter := 1;
            end if;
        end if;
    end process;
    
    -- Instantiate the Components
    VGA_ControllerInst : VGA_Controller
        Port map (
            CLK => CLK,
            RST => RST,
            Hsync => Hsync,
            Vsync => Vsync,
            Hpos => Hpos_VGA,
            Vpos => Vpos_VGA,
            VideoOn => VideoOn_VGA
        );
    
    Graphics_ControllerInst : Graphics_Controller
        Port map (
            CLK => CLK,
            RST => RST,
            Hpos => Hpos_VGA,
            Vpos => Vpos_VGA,
            VideoOn => VideoOn_VGA,
            P1_SW_UP => SW_UP,
            P1_SW_DN => SW_DN,
            vgaRed => vgaRed,
            vgaBlue => vgaBlue,
            vgaGreen => vgaGreen
        );
    
    --vgaRed <= "1111" when VideoOn_VGA = '1' else "0000";
    --vgaBlue <= "0000";
    --vgaGreen <= "0000";

end Behavioral;
