`default_nettype none

module Top #(parameter HDISP = 800, parameter VDISP = 480)(
    // Les signaux externes de la partie FPGA
	input  wire  FPGA_CLK1_50,
	input  wire  [1:0]	KEY, 
	output logic [7:0]	LED,
	input  wire	 [3:0]	SW,
    // Les signaux du support matériel son regroupés dans une interface
    hws_if.master       hws_ifm,
    video_if.master     video_ifm
);

//====================================
//  Déclarations des signaux internes
//====================================
  wire        sys_rst;   // Le signal de reset du système
  wire        sys_clk;   // L'horloge système a 100Mhz
  wire        pixel_clk; // L'horloge de la video 32 Mhz

//=======================================================
//  La PLL pour la génération des horloges
//=======================================================

sys_pll  sys_pll_inst(
		   .refclk(FPGA_CLK1_50),   // refclk.clk
		   .rst(1'b0),              // pas de reset
		   .outclk_0(pixel_clk),    // horloge pixels a 32 Mhz
		   .outclk_1(sys_clk)       // horloge systeme a 100MHz
);

//=============================
//  Les bus Avalon internes
//=============================
avalon_if #( .DATA_BYTES(4)) avalon_if_sdram  (sys_clk, sys_rst);
avalon_if #( .DATA_BYTES(4)) avalon_if_stream (sys_clk, sys_rst);


//=============================
//  Le support matériel
//=============================
hw_support hw_support_inst (
    .avalon_ifa (avalon_if_sdram),
    .avalon_ifh (avalon_if_stream),
    .hws_ifm  (hws_ifm),
	.sys_rst  (sys_rst), // output
    .SW_0     ( SW[0] ),
    .KEY      ( KEY )
 );

//=============================
// On neutralise l'interface
// du flux video pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
assign avalon_if_stream.waitrequest = 1'b1;
assign avalon_if_stream.readdata = '0 ;


//=============================
// On neutralise l'interface SDRAM
// pour l'instant
// A SUPPRIMER PLUS TARD
//=============================
// assign avalon_if_sdram.write  = 1'b0;
// assign avalon_if_sdram.read   = 1'b0;
// assign avalon_if_sdram.address = '0  ;
// assign avalon_if_sdram.writedata = '0 ;
// assign avalon_if_sdram.byteenable = '0 ;


//--------------------------
//------- Code Eleves ------
//--------------------------

//RESET CHECK
assign LED[0] = KEY[0];

//PARAMETERS
`ifdef SIMULATION
  localparam int unsigned SYSCLK_TOGGLE_TICKS   = 100; // Simulation ticks
  localparam int unsigned PIXELCLK_TOGGLE_TICKS = 32;
`else
  localparam int unsigned SYSCLK_TOGGLE_TICKS   = 100_000_000; // sys_clk = 100MHz
  localparam int unsigned PIXELCLK_TOGGLE_TICKS = 32_000_000;  // pixel_clk = 32MHz
`endif

localparam int unsigned SYSCLK_COUNT_WIDTH = $clog2(SYSCLK_TOGGLE_TICKS);
localparam int unsigned PIXELCLK_COUNT_WIDTH = $clog2(PIXELCLK_TOGGLE_TICKS);

//SYS HEARTBEAT
logic [SYSCLK_COUNT_WIDTH-1:0] sysclk_count;

//Counts cycles based on sys_clk and toggles LED[1] when reaching SYSCLK_TOGGLE_TICKS.
always_ff @(posedge sys_clk) begin
    if (sys_rst) begin
        sysclk_count     <= '0;
        LED[1]           <= 1'b0;
    end else begin // After 100000000 cycles, we get 1s with 100MHz clock
        if (sysclk_count == SYSCLK_TOGGLE_TICKS - 1) begin // -1 because we start counting from 0
            sysclk_count <= '0; // Reset counter
            LED[1]       <= ~LED[1]; // Change LED state
        end else begin
            sysclk_count <= sysclk_count + 1'b1;
        end
    end
end

//PIXEL RESET
logic pixel_rst;
logic pixel_rst_stage0;
logic pixel_rst_stage1;

//Flip-Flop chain solution
always_ff @(posedge pixel_clk or posedge sys_rst) begin
    if (sys_rst) begin // Asynchronous reset
        pixel_rst_stage0 <= 1'b1;
        pixel_rst_stage1 <= 1'b1;
    end else begin // Synchronous passage of value
        pixel_rst_stage0 <= 1'b0;
        pixel_rst_stage1 <= pixel_rst_stage0;
    end
end

assign pixel_rst = pixel_rst_stage1;

//PIXEL HEARTBEAT
logic [PIXELCLK_COUNT_WIDTH-1:0] pixelclk_count;

//Same as sys_clk heartbeat but for pixel_clk and LED[2]
always_ff @(posedge pixel_clk) begin
    if (pixel_rst) begin
        pixelclk_count   <= '0;
        LED[2]           <= 1'b0;
    end else begin
        if (pixelclk_count == PIXELCLK_TOGGLE_TICKS - 1) begin
            pixelclk_count <= '0;
            LED[2]         <= ~LED[2];
        end else begin
            pixelclk_count <= pixelclk_count + 1'b1;
        end
    end
end

//VGA block instantiation
vga #(.HDISP(HDISP), .VDISP(VDISP)) vga0(
    .pixel_clk (pixel_clk),
    .pixel_rst (pixel_rst),
    .video_ifm (video_ifm),
    .avalon_ifh(avalon_if_sdram)
);

endmodule
`default_nettype wire
