
module Pong
	(
		LEDR,
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  HEX0,
		  HEX1,
		  HEX2,
		  HEX3,
		  HEX4,
		  HEX5,
		  HEX6,
		  HEX7,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;
	output [15:0] LEDR;
	
	output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7;
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn   = KEY[0];
	wire startGame 	= KEY[1];
	wire paddleUp 	= KEY[2];
	wire paddleDown	= KEY[3];
	 
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	 	
	wire [3:0] 	score;
	// x's boarder is 159 // 8'b10011111;
	// y's boarder is 119 // 7'b1110111;
	 
	 wire finishedDrawingBall, //sign to FSM that datapath finished drawing the ball
			finishedDrawingPaddle, // sign to FSM that datapath finished drawing the paddle
			lose; // sign to FSM to datapath that the user lost the game
			
	wire [15:0] backgroundResetCounter; // counter to turn all pixels to black
			
	wire drawBallCommand,    // permission from FSM to datapath to allow datapath to draw the ball
		 drawPaddleCommand,
		 movePaddleUp,
		 movePaddleDown,
		  ballMoving, // permission from FSM to datapath
		  resetBallCounterCommand,        // permission from FSM to datapath to reset the ball
		  resetGame;       // permission from FSM to datapathto restart the entire game
	 
	
	wire [3:0] moveUpAmount;
	wire [3:0] moveDownAmount;
	
	wire [7:0] ball_x;
	wire [6:0] ball_y;
	wire [7:0] paddle_x;
	wire [6:0] paddle_y;
	wire [7:0] x_move;
	wire [6:0] y_move;

	wire [3:0] ballCounter; // helper to draw 2x2 ball
	
	wire slowclock;
	
	downclock slowerclock(CLOCK_50, slowclock);
	
	
	hex_decoder scoreHEX(score, HEX7);
	
	hex_decoder ball_y1HEX(ball_y[6:4], HEX1);
	hex_decoder ball_y2HEX(ball_y[3:0], HEX0);
	
	hex_decoder ball_x1HEX(ball_x[7:4], HEX3);
	hex_decoder ball_x2HEX(ball_x[3:0], HEX2);
	
	hex_decoder paddle_y1HEX(paddle_y[6:4], HEX5);
	hex_decoder paddle_y2HEX(paddle_y[3:0], HEX4);
	
	ball_physics testballphysics(	//--input--//
									slowclock, // clock
									ball_x[7:0],
									ball_y[6:0],
									paddle_x [7:0],
									paddle_y [6:0],
									ballMoving,
									startGame,
									resetn,
									//--output--//
									x_move [7:0],
									y_move [6:0],
									score [3:0],
									lose
									);



	datapath testdatapath(
							    slowclock, // clock
								resetn,    // resetn which is the KEY0
								drawBallCommand,  
								drawPaddleCommand, 
								movePaddleUp,
								movePaddleDown,
								ballMoving,      
								resetBallCounterCommand,         
								resetGame,
								lose,
								x_move [7:0],
								y_move [6:0],
								//outputs
								x,			
								y,				
								colour,
								finishedDrawingBall,
								finishedDrawingPaddle,
								backgroundResetCounter,
								moveUpAmount[3:0],
								moveDownAmount[3:0],
								ball_x[7:0],
								ball_y[6:0],
								paddle_x[7:0],
								paddle_y[6:0],
								ballCounter[3:0],
								LEDR[15:9]
								);			



	 control c0(
					startGame, 
					paddleUp,
					paddleDown,
					finishedDrawingBall,
					finishedDrawingPaddle,
					lose,
					slowclock, // clock
					resetn,
					backgroundResetCounter[15:0],
					moveUpAmount[3:0],
					moveDownAmount[3:0],
					ballCounter[3:0],
					// outputs below //
					drawBallCommand,
					drawPaddleCommand,
					movePaddleUp,
					movePaddleDown,
					ballMoving,
					resetBallCounterCommand,
					resetGame,
					writeEn,
					LEDR[8:0]);
					
    
endmodule


module downclock (clock, downclock);
	input clock;
	output reg downclock;
	reg [27:0] testspeed;
	always@(posedge clock)
	begin
		if (testspeed == 27'd20000)
			begin
				testspeed <= 1'b0;
				downclock <= 1'b1;
			end
		else
			begin
				testspeed <= testspeed + 1'b1;
				downclock <= 1'b0;
			end
	end
endmodule


// start of FSM
module control (	
						input startGame, // start game uses KEY1
						input paddleUp,  // paddleUP uses KEY2
						input paddleDown, // paddleDown uses KEY3
					   input finishedDrawingBall, // given from datapath when it's done drawing the current elememt 1 if done, 0 if not
						input finishedDrawingPaddle, // given from datapath when finished drawing the paddle
						input lose, // signal from datapath that ball reaches left border
						input clock, // hooked up to base clock
						input resetn, // clear the screen/start from the beginni
						input [15:0] backgroundResetCounter, // helper for making whole screen black
						input [3:0] moveUpAmount, //number of times we shift the paddle up
						input [3:0] moveDownAmount, //number of times we shift the paddle up
						input [3:0] ballCounter,
						output reg drawBallCommand, // permission to draw ball
						output reg drawPaddleCommand, // permission to draw paddle
						output reg movePaddleUp, // permission to move paddle up
						output reg movePaddleDown,// permission to move paddle down
						output reg ballMoving, // permission to move the ball
						output reg resetBallCounterCommand, // reset ball position
						output reg resetGame, // reset everything to initial position
						output reg writeEn, // gives the vga permission to draw
						output reg [8:0] LEDR
						);

	reg [5:0] current_state, next_state;
	reg paddleWantsUp;
	reg paddleWantsDown;

	localparam		START 				= 5'd0,
					DRAW_BALL 	    	   = 5'd1, // draws the ball
					DRAW_PADDLE         = 5'd2, // draws the paddle
					PADDLE_WANTS_UP  	   = 5'd3,
					PADDLE_UP 			   = 5'd4,
					PADDLE_WANTS_DOWN 	= 5'd5,
					PADDLE_DOWN			   = 5'd6,
					BALL_MOVING			   = 5'd7,
					RESET_BALL_COUNTER	= 5'd8,
					RESET_GAME			   = 5'd9; // resets score and ball position
					
					
	// begin state table
	always@(*)
	begin: state_table
		case(current_state)
			START		         : next_state = startGame ? START: DRAW_BALL;
			DRAW_BALL	      : next_state = finishedDrawingBall ? DRAW_PADDLE : DRAW_BALL;
			DRAW_PADDLE	      : next_state = finishedDrawingPaddle ? PADDLE_WANTS_UP: DRAW_PADDLE;
			PADDLE_WANTS_UP   : next_state = paddleUp ? PADDLE_WANTS_DOWN : PADDLE_UP;
			PADDLE_UP		   : next_state = (moveUpAmount[3:0] >= 4'b0001) ? BALL_MOVING: PADDLE_UP;
			PADDLE_WANTS_DOWN : next_state = paddleDown ? BALL_MOVING : PADDLE_DOWN;
			PADDLE_DOWN		   : next_state = (moveDownAmount[3:0] >= 4'b0001)? BALL_MOVING: PADDLE_DOWN;
			BALL_MOVING		   : next_state = (finishedDrawingBall) ? RESET_BALL_COUNTER: BALL_MOVING;
			RESET_BALL_COUNTER: next_state = (ballCounter == 4'b0000) ? PADDLE_WANTS_UP: RESET_BALL_COUNTER;
			RESET_GAME		   : next_state = (backgroundResetCounter[15:0] >= 15'b101000000000000) ? START : RESET_GAME;
			default: next_state = START;
		endcase // state_table
	end// state logic
	
	// begin state logic
	always@(*)
	begin: state_logic
		drawBallCommand = 1'b0; 
		drawPaddleCommand = 1'b0;
		movePaddleUp = 1'b0;
		movePaddleDown = 1'b0;
		ballMoving = 1'b0;
		resetBallCounterCommand = 1'b0;
		resetGame = 1'b0;
		writeEn = 1'b0; // allow the vga to draw
		LEDR[0] = 1'b0;
		LEDR[1] = 1'b0;
		LEDR[2] = 1'b0;
		LEDR[3] = 1'b0;
		LEDR[4] = 1'b0;
		LEDR[5] = 1'b0;
		LEDR[6] = 1'b0;
		//LEDR[7] = 1'b0;
		//LEDR[8] = 1'b0;
		// begin state permissions
		case (current_state)
			DRAW_BALL:
				begin
					drawBallCommand = 1'b1; // draw the initial 3 board pieces
					writeEn = 1'b1; // allow the vga to draw
					LEDR[0] = 1'b1;
				end	
			DRAW_PADDLE:
				begin
					drawPaddleCommand = 1'b1;
					writeEn = 1'b1; // allow the vga to draw
					LEDR[1] = 1'b1;
				end
			PADDLE_UP:
				begin
					movePaddleUp = 1'b1; // allow the paddle to go up
					writeEn = 1'b1; // allow the vga to draw
					LEDR[2] = 1'b1;
				end
			PADDLE_DOWN:
				begin
					movePaddleDown = 1'b1;
					writeEn = 1'b1; // allow the vga to draw
					LEDR[3] = 1'b1;
				end
			BALL_MOVING:
				begin
					ballMoving = 1'b1; // enables user to move the paddle and ball will move
					writeEn = 1'b1; // allow the vga to draw
					LEDR[4] = 1'b1;
				end
			RESET_BALL_COUNTER:
				begin
					resetBallCounterCommand = 1'b1;
					//writeEn = 1'b1; // allow the vga to draw
					LEDR[5] = 1'b1;
				end
			RESET_GAME:
				begin
					resetGame = 1'b1;
					writeEn = 1'b1; // allow the vga to draw
					LEDR[6] = 1'b1; // change led for debug purposes
				end
		endcase
	end // state_logic
			
	// begin reset logic
		always@(posedge clock)
		begin
			if(!resetn)       
				current_state <= RESET_GAME; 
			else 
				current_state <= next_state;
		end // end reset logic
		
endmodule // end FSM


module datapath (
						input clock,
						input resetKey,
						input drawBallCommand, // draw the beginning 3 board pieces
						input drawPaddleCommand,
						input movePaddleUp,
						input movePaddleDown,
						input ballMoving, // switches and keys
						input resetBallCounterCommand, // reset ball position
						input resetGame, // reset everything to initial positio
						input lose,
						// handles ball physics
						input [7:0] x_move,
						input [6:0] y_move,
						//------drawBallCommand--------------------------------//
						output reg [7:0]	x,
						output reg [6:0]	y,
						output reg [2:0] colour_out,
						output reg finishedDrawingBall,
						output reg finishedDrawingPaddle,
						output reg [15:0] backgroundResetCounter,
						output reg [3:0] moveUpAmount,
						output reg [3:0] moveDownAmount,
						output reg [7:0] ball_x,
						output reg [6:0] ball_y,
						output reg [7:0] paddle_x,
						output reg [6:0] paddle_y,
						output reg [3:0] ballCounter, // helper to draw 2x2 ball
						output reg [15:9] LEDR
					);
					
	
	reg [4:0] paddleCounter; // helper to draw 2x16 paddle
	
	// for PaddleUp
	reg [2:0] redrawPaddleCount; // counts up to 4, 1/2 erases the bottom of the paddle
											// , 3/4 draws the top of the paddle
	
	reg [6:0] redrawPaddleY; // register to hold the position of the current y co-ordinate to be redrawn
	
	reg [2:0] sunnyCounter;
	reg [27:0] ballSpeed;
	
	// x's boarder is 159 // 8'b10011111;redrawPaddleCount
	// y's boarder is 119 // 7'b1110111;
	localparam INITIAL_X = 8'b01001111, INITIAL_Y = 7'b0111011;
	localparam INITIAL_PADDLE_X = 8'b0000_0000, INITIAL_PADDLE_Y = 7'b0110111;
	
	// downclock for testing
	reg [27:0] testspeed;
	always@(posedge clock)
	begin
		if (testspeed == 27'd999)
				testspeed <= 1'b0;
		else
				testspeed <= testspeed + 1'b1;
	end
		
	
	
	always@(posedge clock)
	begin
		LEDR[9] <= 1'b0;
		LEDR[10] <= 1'b0;
		LEDR[11] <= 1'b0;
		LEDR[12] <= 1'b0;
		LEDR[13] <= 1'b0;
		LEDR[14] <= 1'b0;
		if (resetGame)
			begin
				x <= backgroundResetCounter[7:0];
				y <= backgroundResetCounter[14:8];
				backgroundResetCounter <= backgroundResetCounter + 1'b1;
				colour_out = 3'b000;
				ball_x = INITIAL_X;
				ball_y = INITIAL_Y;
				
				ballCounter <= 4'd0; 
				paddleCounter <= 5'd0; 
				finishedDrawingBall <= 1'b0;
				finishedDrawingPaddle <= 1'b0;
				moveUpAmount <= 3'd0;
				moveDownAmount <= 3'd0;
			end
		else
		begin
			if (drawBallCommand)
				begin // draws the ball at the initial position
					if (ballCounter < 4'b0100)
						begin
							backgroundResetCounter <= 15'd0;
							ball_x = INITIAL_X;
							ball_y = INITIAL_Y;
							x <= ball_x[7:0] + ballCounter[0];
							y <= ball_y[6:0] + ballCounter[1];
							ballCounter <= ballCounter + 1'b1;
							colour_out <= 3'b111;
						end
					if (ballCounter == 4'b0100)
						begin
							finishedDrawingBall <= 1'b1;
							ballCounter <= 4'b0000;
						end
				end // finishes drawing the ball at the initial position
			
			if (drawPaddleCommand)
				begin
					ballCounter <= 4'b0000; // resets the ball counter after the finishes drawing ball command is given
					finishedDrawingBall <= 1'b0; 
					paddle_x = INITIAL_PADDLE_X;
					paddle_y = INITIAL_PADDLE_Y;
					// draws a 2x16 paddle
					x <= paddle_x[7:0] + paddleCounter[0];
					y <= paddle_y[6:0] + paddleCounter[4:1];
					paddleCounter <= paddleCounter + 1'b1;
					colour_out <= 3'b111; // in white
					if (paddleCounter == 5'b11111)
						finishedDrawingPaddle <= 1'b1; // signify that the vga is done drawing
				end
			if (movePaddleUp)
				begin
					// erases the last 2 pixels of the paddle
					if (redrawPaddleCount < 2'd2) // run twice/black out bottom 2 pixels
						begin
							moveDownAmount <= 3'd0;
							ballCounter <= 4'b0000;
							redrawPaddleY = paddle_y + 5'd15;
							// use counter to colour those pixels black
							x <= paddle_x + redrawPaddleCount[0];
							y <= redrawPaddleY;
							redrawPaddleCount <= redrawPaddleCount + 1'b1;
							colour_out <= 3'b000;
						end
					// whitens the upper 2 bits of the paddle
					if (redrawPaddleCount < 3'd4) // run twice/whitens out top 2 pixels
						begin
							redrawPaddleY = paddle_y - 1'b1;
							// use counter to colour those pixels white
							x <= paddle_x + redrawPaddleCount[0];
							y <= redrawPaddleY;
							redrawPaddleCount <= redrawPaddleCount + 1'b1;
							colour_out <= 3'b111;
						end
					if (redrawPaddleCount == 3'd4)
						begin
							redrawPaddleCount <= 3'd0;
							moveUpAmount <= moveUpAmount + 1'b1;
							paddle_y = paddle_y - 1'b1;
						end
				end
			if (movePaddleDown)
				begin
					// draw the last 2 pixels of the paddle
					if (redrawPaddleCount < 3'd2) //
						begin
							moveUpAmount <= 3'd0;
							ballCounter <= 4'b0000;
							redrawPaddleY = paddle_y + 5'd17;
							// use counter to colour those pixels white
							x <= paddle_x + redrawPaddleCount[0];
							y <= redrawPaddleY;
							redrawPaddleCount <= redrawPaddleCount + 1'b1;
							colour_out <= 3'b111;
						end
					// blackening the upper 2 bits of the paddle
					if (redrawPaddleCount < 3'd4)
						begin
							redrawPaddleY = paddle_y;
							// use counter to colour those pixels black
							x <= paddle_x + redrawPaddleCount[0];
							y <= redrawPaddleY;
							redrawPaddleCount <= redrawPaddleCount + 1'b1;
							colour_out <= 3'b000;
						end
					if (redrawPaddleCount == 3'd4)
						begin
							redrawPaddleCount <= 3'd0;
							moveDownAmount <= moveDownAmount + 1'b1;
							paddle_y = paddle_y + 1'b1;
						end
				end
			if (ballMoving)
				begin
					if (ballCounter < 4'b0100) // for ballCounter abcd ->  a represents done drawing all
						begin							//									b represents done drawing ball
														//									c represents the x value to add
														//									d represents the y value to add
														
							// erases the ball
							backgroundResetCounter <= 13'd0;
							moveUpAmount <= 3'd0;
							moveDownAmount <= 3'd0;
							x <= ball_x + ballCounter[0];
							y <= ball_y + ballCounter[1];
							ballCounter <= ballCounter + 1'b1;
							colour_out <= 3'b000;
							LEDR[11] <= 1'b1;
						end
							// sets the new ball position
					if (ballCounter == 4'b0100)  
						begin
								ball_x = ball_x + x_move;
								ball_y = ball_y + y_move;
								ballCounter <= 4'b1000;
								LEDR[12] <= 1'b1;
						end
							// draws the ball at the new position after 1*0.5s (sunnyCounter represents 0.5s intervals)
					if (ballCounter < 4'b1100)
						begin
							if (sunnyCounter == 3'd1)
								begin
									// draws the ball
									x <= ball_x + ballCounter[0];
									y <= ball_y + ballCounter[1];
									ballCounter <= ballCounter + 1'b1;
									colour_out <= 3'b111;
									
									// done erasing and redrawing - reset all counters
									if (ballCounter == 4'b1011)
										begin
											sunnyCounter = 1'b0;
											LEDR[9] <= 1'b1;
											finishedDrawingBall <= 1'b1;
										end
								end
							// counts 0.5s intervals
							if (ballSpeed == 27'd4)
								begin
									sunnyCounter = sunnyCounter + 1'b1;
									ballSpeed <= 27'd0;
								end
							else
								ballSpeed <= ballSpeed + 1'b1;
						end
					//if (ballCounter == 4'b1100)
					//	begin
							//ballCounter <= 4'd0;
						//end
				end
				if (resetBallCounterCommand)
					begin
						ballCounter <= 4'd0;
						finishedDrawingBall <= 1'b0;
					end
			end
	end
					
					
endmodule// datapath

module ball_physics(	input clock,
							input [7:0] ball_x,
							input [6:0] ball_y,
							input [7:0] paddle_x,
							input [6:0] paddle_y,
							input ballMoving,
							input start,
							input reset,
							output reg [7:0]x_move,
							output reg [6:0] y_move,
							output reg [3:0] score,
							output reg isLose);
							
	always@(*)
		begin
			if (~reset | ~start)
				begin
					x_move <= 8'b1111_1111;
					y_move <= 7'b111_1111;
				end
			else
				begin
					// x's boarder is 159 // 8'b10011111;
					// y's boarder is 119 // 7'b1110111;
					if (ball_y == 7'd2)  // ball reached top of the screen
						begin
							y_move = 7'b000_0001;			// change movement direction to down
						end
					if (ball_y == 7'd120)	// ball reached the bottom of the screen
						begin
							y_move = 7'b111_1111;		// move change movement direction to up
						end
					if ((ball_x == 8'd2) && ((paddle_y <= ball_y) && (ball_y <= (paddle_y + 5'd16))))// paddle y in range of ball y
						begin
							x_move = 8'b0000_0001;			// ball bounces to the right
							score <= score + 1'b1;
						end
					if (ball_x == 8'd160)		// ball reached the right side of the screen
						begin
							x_move = 8'b1111_1111;		// make it bounce left
						end
					if (ball_x == 8'd1)			// if the ball reached the left-most edge
						begin 
							score <= 4'b0000;
						end
				end
		end

endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule




