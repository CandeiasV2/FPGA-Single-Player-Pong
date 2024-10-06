----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Tiago
-- 
-- Create Date: 09/23/2024 11:54:38 PM
-- Design Name: Graphics_Controller
-- Module Name: Graphics_Controller - Behavioral
-- Project Name: Pong Game with VGA Display
-- Target Devices: Digilent Basys 3 Board featuring the Xilinx Artix-7 FPGA (XC7A35T-1CPG236C)
-- Tool Versions: Vivado 2024.1.2
-- Description: 
-- This module handles all the graphics rendering and game logic for the Pong game.
-- It processes the player's inputs, manages the ball and paddle movements, and 
-- determines the score. The ball's movement is updated based on collisions with 
-- the paddles and screen edges, and a Linear Feedback Shift Register (LFSR) is 
-- used for random angle generation when the round begins.
-- 
-- Dependencies: 
-- - A package file (Number_Package) containing arrays of digit representations
--   for rendering the scores on the VGA screen.
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- This module operates on a 25MHz clock and interacts with the VGA_Controller 
-- module for pixel position and synchronization. It supports random number 
-- generation using an LFSR to change the ball's angle.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Include the package for number 0 to 3
library work;
use work.Number_Package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Graphics_Controller is
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
end Graphics_Controller;

architecture Behavioral of Graphics_Controller is
    
    -- Pixel Position
    signal Hpixel : unsigned(9 downto 0) := (others => '0');
    signal Vpixel : unsigned(9 downto 0) := (others => '0');
    
    -- Player Locations
	signal P1Location : integer := 198;    -- Middle of screen
	signal P2Location : integer := 198;    -- Middle of screen
	signal playerSpeed : integer := 1;
	signal playerCLK : std_logic := '0';
	
	-- Ball Location and Movements
    signal ballCLK : std_logic := '0';
	signal ballAngle : integer := 0;
	signal ballX : integer := 315;
	signal ballY : integer := 232;
	signal ballSpeedX : integer := 1;
	signal ballSpeedY : integer := 1;
	
	-- Signals to RST game after win
	signal gameGoalScoreP1 : integer := 0;
	signal gameGoalScoreP2 : integer := 0;
	signal gameRST : std_logic := '1';
	signal gameGoal : std_logic := '0';
	
	-- Signal for Linear Feedback Shift Register (LFSR)-based random number generation
    signal lfsr : std_logic_vector(3 downto 0) := "1011"; -- Initial value of the LFSR

begin

    -- Generating Clock for the Players Movement
    -- VideoOn Goes HIGH Once Every Frame, or 60 Times per Second
    playerClockDivider : process(VideoOn)       -- The maximum speed is at clk_counter = 9, The medium speed is at clk_counter = 30, The lowest speed is at clk_counter = 50
        variable clk_counter : integer := 0;
    begin
        if rising_edge(VideoOn) then
            if (clk_counter = 50) then
                clk_counter := 0;
                playerCLK <= NOT playerCLK;
            else 
                clk_counter := clk_counter + 1;
            end if;
        end if;
    end process;
    
    -- Generating Clock for the Ball Movement
    -- VideoOn Goes HIGH Once Every Frame, or 60 Times per Second
    ballClockDivider : process(VideoOn)         -- The maximum speed is at clk_counter = 30, good speed is 70
        variable clk_counter : integer := 0;
    begin
        if rising_edge(VideoOn) then
            if (clk_counter = 70) then
                clk_counter := 0;
                ballCLK <= NOT ballCLK;
            else 
                clk_counter := clk_counter + 1;
            end if;
        end if;
    end process;
    
    -- Updating Ball Location
    ballMovement : process(ballCLK, RST, gameRST, ballAngle)
    begin
        if (RST = '1' or gameRST = '1') then
            ballX <= 315;
            ballY <= 232;
        elsif (rising_edge(ballCLK)) then
            case ballAngle is
                when 0 =>
                    -- Do Not Move Ball
				when 1 =>
					-- Move Ball Up/Right
					ballY <= ballY - ballSpeedY;
					ballX <= ballX + ballSpeedX;
				when 2 =>
					-- Move Ball Down/Right
					ballX <= ballX + ballSpeedX;
					ballY <= ballY + ballSpeedY;
				when 3 =>
					-- Move Ball Down/Left
					ballY <= ballY + ballSpeedY;
					ballX <= ballX - ballSpeedX;
				when 4 =>
					-- Move Ball Up/Left
					ballY <= ballY - ballSpeedY;
					ballX <= ballX - ballSpeedX;
                when others =>              
            end case;
        end if; 
    end process;
    
    -- LFSR process for random number generation
    LFSR_process : process(ballCLK, RST)
    begin
        if (RST = '1') then
            lfsr <= "1011"; -- Reset LFSR to the initial value
        elsif (rising_edge(ballCLK)) then
            lfsr <= lfsr(2 downto 0) & (lfsr(3) xor lfsr(0)); -- Shift and feedback
        end if;
    end process;
    
    -- Updating Ball Angle From Obstacle Hit (Player Paddles or Walls)
    ballUpdateAngle : process(ballCLK, RST, gameGoal, lfsr, ballAngle, ballX, ballY, P1Location, P2Location)
    begin
        if (RST = '1' or gameGoal = '1') then
            ballAngle <= 0;
        elsif (rising_edge(ballCLK)) then
            if (ballAngle = 0) then
                -- set 'ballAngle' to a random integer from 1 to 4
                case lfsr(1 downto 0) is
                    when "00" => ballAngle <= 1;    -- Map to 1
                    when "01" => ballAngle <= 2;    -- Map to 2
                    when "10" => ballAngle <= 3;    -- Map to 3
                    when others => ballAngle <= 4;  -- Map to 4
                end case;
            elsif (ballY <= 30) then
				-- If ball hits top white line
				if (ballAngle = 4) then
					ballAngle <= 3;
				elsif (ballAngle = 1) then
					ballAngle <= 2;
				end if;			
			elsif ((ballY+15) >= 450) then
				-- If ball hits bottom white line
				if (ballAngle = 3) then
					ballAngle <= 4;
				elsif (ballAngle = 2) then
					ballAngle <= 1;
				end if;			
			elsif ((ballX <= 30) and (ballY >= P2Location and ballY <= (P2Location+84))) then
				-- If ball hits player 2
				if (ballAngle = 3) then
					ballAngle <= 2;
				elsif (ballAngle = 4) then
					ballAngle <= 1;
				end if;			
			elsif ((ballX >= (640-30-11)) and ((ballY+15) >= P1Location and (ballY+15) <= (P1Location+84))) then
				-- If ball hits player 1
				if (ballAngle = 1) then
					ballAngle <= 4;
				elsif (ballAngle = 2) then
					ballAngle <= 3;
				end if;
			end if;
        end if;
    end process;
    
    -- Check If Goal Occurred, Reset Game Afterwards
    goalScored : process(ballCLK, RST, gameGoal, ballX, VideoOn, gameRST)
        variable clk_counter : integer := 0;
    begin
        if (RST = '1') then
            gameGoalScoreP1 <= 0;
            gameGoalScoreP2 <= 0;
            gameGoal <= '0';
            gameRST <= '1';  
        elsif (rising_edge(ballCLK)) then
            if (gameRST = '0') then
                if (gameGoal = '0') then
                    if ((ballX+11) >= (640-20)) then
                        gameGoalScoreP2 <= gameGoalScoreP2 + 1;
                        gameGoal <= '1';
                    elsif ((ballX) <= 20) then
                        gameGoalScoreP1 <= gameGoalScoreP1 + 1;
                        gameGoal <= '1';
                    end if;
                else
                    if (clk_counter = 480) then
                        clk_counter := 0;
                        gameGoal <= '0';
                        gameRST <= '1';
                    else 
                        clk_counter := clk_counter + 1;
                    end if;
                end if;
            else    -- gameRST = '1'
                if (clk_counter = 480) then
                    clk_counter := 0;
                    gameGoal <= '0';
                    gameRST <= '0';
                    if (gameGoalScoreP1 = 3 or gameGoalScoreP2 = 3) then    
                        -- Reset scores after reaching 3 score win
                        gameGoalScoreP1 <= 0;
                        gameGoalScoreP2 <= 0;
                    end if;
                else 
                    clk_counter := clk_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Updating P1 Movements
    P1Movement : process(playerCLK, RST, P1Location, P1_SW_UP, P1_SW_DN)
    begin
        if (RST = '1') then
            P1Location <= 198;
        elsif (rising_edge(playerCLK)) then
            if ((P1_SW_UP = '1') and (P1_SW_DN = '0') and (P1Location <= 30)) then
                -- At the top of play area already, so do nothing
            elsif ((P1_SW_UP = '1') and (P1_SW_DN = '0') and (P1Location > 30)) then
                P1Location <= P1Location - playerSpeed;     -- Move player up
            elsif ((P1_SW_UP = '0') and (P1_SW_DN = '1') and (P1Location >= 366)) then -- bottom frame - paddle height = 450-84 = 366
                -- At the bottom of play area already, so do nothing
            elsif ((P1_SW_UP = '0') and (P1_SW_DN = '1') and (P1Location < 366)) then
                P1Location <= P1Location + playerSpeed;     -- Move player down
            elsif ((P1_SW_UP = '1') and (P1_SW_DN = '1')) then
                -- Both controls pressed, so do nothing
            end if;
        end if; 
    end process;
    
    -- Updating P2 Movements
    P2Movement : process(playerCLK, RST, P2Location, ballY)
    begin
        if (RST = '1') then
            P2Location <= 198;
        elsif (rising_edge(playerCLK)) then
            if ((ballY+7 < P2Location+42) and (P2Location > 30)) then
                P2Location <= P2Location - playerSpeed;     -- Move player up
            elsif ((ballY+7 > P2Location+42) and (P2Location < 366)) then  -- bottom frame - paddle height = 450-84 = 366
                P2Location <= P2Location + playerSpeed;     -- Move player down
            end if;
        end if; 
    end process;

    -- Drawing the Background
	drawBackground : process(CLK, RST, VideoOn, Hpixel, Vpixel, ballX, ballY, gameGoal)
    begin
        if (RST = '1') then
            vgaRed <= "0000";
            vgaBlue <= "0000";
            vgaGreen <= "0000";
        elsif rising_edge(CLK) then
            if (VideoOn = '1') then
                -- Set the background to green
                vgaRed <= "0000";
                vgaBlue <= "0000";
                vgaGreen <= "1111";
                
                if ((Hpixel >= 15 and Hpixel <= 625) and ((Vpixel >= 15 and Vpixel <= 30) OR (Vpixel >= 450 and Vpixel <= 465))) then
					-- Set boundary lines to white
					vgaRed <= "1111";
                    vgaBlue <= "1111";
                    vgaGreen <= "1111";
                elsif ((Hpixel >= 20 and Hpixel <= 30) and ((Vpixel >= P2Location) and (Vpixel <= (P2Location+84)))) then
					-- Drawing P2 as blue
					vgaRed <= "0000";
                    vgaBlue <= "1111";
                    vgaGreen <= "0000";
				elsif ((Hpixel >= 610 and Hpixel <= 620) and ((Vpixel >= P1Location) and (Vpixel <= (P1Location+84)))) then
					-- Drawing P1 as magenta
					vgaRed <= "1111";
                    vgaBlue <= "1111";
                    vgaGreen <= "0000";
                elsif ((Hpixel >= ballX and Hpixel <= (ballX+11)) and (Vpixel >= ballY and Vpixel <= (ballY+15))) then
                    if (gameGoal = '0') then
                        -- Drawing the ball as yellow
                        vgaRed <= "1111";
                        vgaBlue <= "0000";
                        vgaGreen <= "1111"; 
                    else 
                        -- Goal, drawing the ball as red
                        vgaRed <= "1111";
                        vgaBlue <= "0000";
                        vgaGreen <= "0000";
                    end if;
                elsif ((Hpixel >= 317 and Hpixel <= 321) and ((Vpixel > 30 and Vpixel <= 73) or (Vpixel >= 93 and Vpixel <= 136) or (Vpixel >= 156 and Vpixel <= 199) or (Vpixel >= 219 and Vpixel <= 262) or
                                                              (Vpixel >= 282 and Vpixel <= 325) or (Vpixel >= 345 and Vpixel <= 388) or (Vpixel >= 408 and Vpixel < 450))) then
                    -- Set 7 central dashed lines to black
					vgaRed <= "0000";
                    vgaBlue <= "0000";
                    vgaGreen <= "0000";
                elsif ((Hpixel >= 346 and Hpixel < 376) and (Vpixel >= 45 and Vpixel < 129)) then
                    -- Drawing the score for P1
                    if (numbers(gameGoalScoreP1)(to_integer(Hpixel) - 346, to_integer(Vpixel) - 45) = '1') then
                        vgaRed <= "1111";
                        vgaBlue <= "1111";
                        vgaGreen <= "1111";
                    end if;
                elsif ((Hpixel >= 262 and Hpixel < 292) and (Vpixel >= 45 and Vpixel < 129)) then
                    -- Drawing the score for P2
                    if (numbers(gameGoalScoreP2)(to_integer(Hpixel) - 262, to_integer(Vpixel) - 45) = '1') then
                        vgaRed <= "1111";
                        vgaBlue <= "1111";
                        vgaGreen <= "1111";
                    end if;
                end if;
                
            else
                -- Set video colour to LOW/OFF outside active image area
                vgaRed <= "0000";
                vgaBlue <= "0000";
                vgaGreen <= "0000";
            end if;
        end if;
    end process;

    Hpixel <= unsigned(Hpos);
    Vpixel <= unsigned(Vpos);

end Behavioral;
