# FPGA Pong Game

A simple, single-player Pong game implemented on an FPGA board. The player controls the paddle using the UP and DN buttons, while a computer-controlled paddle automatically tracks the ball. The game includes a score counter, which resets the game after one player reaches three goals.

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [How to Play](#how-to-play)
- [Game Controls](#game-controls)
- [Implementation Details](#implementation-details)
- [Hardware Used](#hardware-used)
- [File Structure](#file-structure)

## Project Overview

This project is a Pong game built on an FPGA to help developers get familiar with FPGA-based game development. It is inspired by the classic Pong game but has been simplified for learning purposes, with one human player and a computer-controlled opponent. 

The game is built using VHDL for FPGA and includes a real-time scoring system that resets after the third goal.

## Features
- Single-player Pong game with a computer-controlled opponent
- Real-time score display
- Game reset after three goals
- Player paddle controlled via board buttons (UP/DN)
- Computer paddle follows the ball
- Reset functionality using a slide switch

## How to Play
- Control the player paddle using the UP and DN buttons on the FPGA board.
- The computer paddle will automatically follow the ball based on its position.
- Each time the ball passes a paddle, the opposing player earns a point.
- The first to score three goals wins the match, and the game resets.

## Game Controls
- **Move Paddle Up:** Press the UP button
- **Move Paddle Down:** Press the DN button
- **Reset Game:** Toggle the first slide switch up and down

## Implementation Details
- **VGA Output:** The game renders graphics on a VGA monitor connected to the FPGA. 
- **Scoring System:** The score is displayed on top of the playing area and increments each time a player earns a point.
- **Game Logic:** The computer paddle tracks the ball's Y-coordinate, making it follow the ball smoothly.
- **Game Reset:** After the third goal is scored, the game resets to its initial state.
  
## Hardware Used
- **FPGA Board:** Digilent [Basys 3](https://digilent.com/shop/basys-3-artix-7-fpga-trainer-board-recommended-for-introductory-users/) Board featuring the Xilinx Artix-7 FPGA (XC7A35T-1CPG236C)
- **Buttons for Player Paddle Control:** UP (BTNU) and DN (BTND) buttons on the FPGA board
- **Slide Switch for Reset:** The first slide switch (SW0) on the FPGA board
- **VGA Connector:** For displaying the game output
- **Ball and Paddle Control:** Managed using VHDL

## File Structure

- `PongGame.vhd`:  This module is the top-level design for a Pong game that interfaces with a VGA controller to display the game on a monitor. It includes clock division from a 100MHz input to a 25MHz clock for VGA timing. Two components are instantiated: `VGA_Controller.vhd` for VGA signal generation and `Graphics_Controller.vhd` for handling game graphics such as paddles, ball movement, and scoring.

- `VGA_Controller.vhd`:  This module is responsible for generating the VGA synchronization signals (horizontal sync, vertical sync) and provides the horizontal and vertical pixel positions. It divides the display into active video regions and sync regions using the parameters defined for the 640x480 @ 60Hz VGA standard. The `VideoOn` signal is used to indicate when the VGA controller is in the active display region.

- `Graphics_Controller.vhd`:  This module handles all the graphics rendering and game logic for the Pong game. It processes the player's inputs, manages the ball and paddle movements, and determines the score. The ball's movement is updated based on collisions with  the paddles and screen edges, and a Linear Feedback Shift Register (LFSR) is used for random angle generation when the round begins.

- `Number_Package.vhd`:  This package contains the definitions of arrays used to represent digit patterns for numbers 0-3. These arrays are used to display scores on the VGA display in the Pong game. Each number is represented as a 30x84 matrix of '0' and '1' values, where '1' represents a pixel that should be displayed and '0' represents a pixel that should not be displayed.

- `ConstraintFileBasys3.xdc`:  A constraint file that maps the FPGA's internal signals to the physical pins on the Digilent Basys 3 board. It includes mappings for the VGA output, buttons, and switches.

- `README.md`:  Project documentation
