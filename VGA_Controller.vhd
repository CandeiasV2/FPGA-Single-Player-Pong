----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Tiago
-- 
-- Create Date: 09/23/2024 01:58:19 PM
-- Design Name: VGA_Controller
-- Module Name: VGA_Controller - Behavioral
-- Project Name: Pong Game with VGA Display
-- Target Devices: Digilent Basys 3 Board featuring the Xilinx Artix-7 FPGA (XC7A35T-1CPG236C)
-- Tool Versions: Vivado 2024.1.2
-- Description: 
-- This module is responsible for generating the VGA synchronization signals 
-- (horizontal sync, vertical sync) and provides the horizontal and vertical pixel
-- positions. It divides the display into active video regions and sync regions
-- using the parameters defined for the 640x480 @ 60Hz VGA standard. The `VideoOn` 
-- signal is used to indicate when the VGA controller is in the active display region.
-- 
-- Dependencies: 
-- None.
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- This design implements the standard 640x480 @ 60Hz VGA timing with a 25MHz clock
-- input. The horizontal and vertical counters are incremented to produce the sync
-- signals, and the `VideoOn` signal ensures that drawing is restricted to the active
-- display area.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA_Controller is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           Hsync : out STD_LOGIC;
           Vsync : out STD_LOGIC;
           Hpos : out STD_LOGIC_VECTOR (9 downto 0);
           Vpos : out STD_LOGIC_VECTOR (9 downto 0);
           VideoOn : out STD_LOGIC);
end VGA_Controller;

architecture Behavioral of VGA_Controller is
    
    -- Synchronization Signals
    signal HOR : std_logic := '1';
    signal VER : std_logic := '1';
    
    -- Pixel Position
    signal Hpixel : unsigned(9 downto 0) := (others => '0');
    signal Vpixel : unsigned(9 downto 0) := (others => '0');
    
    -- Video On Signal
    signal VideoOnTemp : std_logic := '0';
    
    -- VGA Horizontal Parameters
    constant HD     : integer := 639;       -- Horizontal Display (active image area, 640 pixels)
    constant HFP    : integer := 16;        -- Front Porch
    constant HSP    : integer := 96;        -- Sync Pulse
    constant HBP    : integer := 48;        -- Back Porch
    
    -- VGA Vertical Parameters
    constant VD     : integer := 479;       -- Vertical Display (active image area, 480 pixels)
    constant VFP    : integer := 10;        -- Front Porch
    constant VSP    : integer := 2;         -- Sync Pulse
    constant VBP    : integer := 33;         -- Back Porch
    

begin

    -- Horizontal and Vertical Pixel Position Counter
    PixelCounter : process(CLK, RST)
    begin
        if (RST = '1') then
            -- Reset all to zero
            Hpixel <= (others => '0');          
            Vpixel <= (others => '0');
            
        elsif (rising_edge(CLK)) then
            if (Hpixel = HD + HFP + HSP + HBP) then
                -- Reset horizontal back to zero after completing line
                Hpixel <= (others => '0');
                
                -- After each completed horizontal line, the vertical line must increment
                if (Vpixel = VD + VFP + VSP + VBP) then
                    -- Reset vertical back to zero after completing line
                    Vpixel <= (others => '0');
                else
                    -- Otherwise, increment by one pixel
                    Vpixel <= Vpixel + 1;            
                end if;
                
            else
                -- Otherwise, increment by one pixel
                Hpixel <= Hpixel + 1; 
            end if;
        end if;
    end process;
        
    -- Setting Horizontal Synchronization Signal
    HorizontalSynchronization : process(CLK, RST, Hpixel)
    begin
        if (RST = '1') then
            HOR <= '1';
        elsif (rising_edge(CLK)) then
            if ((Hpixel > HD + HFP) and (Hpixel <= HD + HFP + HSP)) then
                HOR <= '0';
            else 
                HOR <= '1';
            end if;
        end if;
    end process;
    
    -- Setting Vertical Synchronization Signal
    VerticalSynchronization : process(CLK, RST, Vpixel)
    begin
        if (RST = '1') then
            VER <= '1';
        elsif (rising_edge(CLK)) then
            if ((Vpixel > VD + VFP) and (Vpixel <= VD + VFP + VSP)) then
                VER <= '0';
            else 
                VER <= '1';
            end if;
        end if;
    end process;
    
    -- Setting Video Signal High When Inside Active Image Area
    InsideActiveArea : process(CLK, RST, Hpixel, Vpixel)
    begin
        if (RST = '1') then
            VideoOnTemp <= '0';
        elsif (rising_edge(CLK)) then
            -- Ensure VideoOnTemp is set to '1' only for valid pixel positions
            if ((Hpixel <= HD) and (Vpixel <= VD)) then
                VideoOnTemp <= '1';  -- Active display area
            else
                VideoOnTemp <= '0';  -- Outside active display area
            end if;
        end if;
    end process;
    
    Hsync <= HOR;
    Vsync <= VER;
    Hpos <= std_logic_vector(Hpixel);
    Vpos <= std_logic_vector(Vpixel);
    VideoOn <= VideoOnTemp;

end Behavioral;
