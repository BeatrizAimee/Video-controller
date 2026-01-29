`timescale 1ns/1ps

`default_nettype none

module tb_Top;

// Entrées sorties extérieures
bit   FPGA_CLK1_50;
logic [1:0]	KEY;
wire  [7:0]	LED;
logic [3:0]	SW;

// Interface vers le support matériel
hws_if      hws_ifm();

// Instance du module Top
Top Top0(.*) ;

///////////////////////////////
//  Code élèves
//////////////////////////////

//CLOCK GENERATION
initial begin
    FPGA_CLK1_50 = 1'b0;
    forever #10ns FPGA_CLK1_50 = ~FPGA_CLK1_50;
end

//KEY STIMULI
initial begin
    KEY = 2'b11;
    #128ns KEY[0] = 1'b0;
    #128ns KEY[0] = 1'b1;
end

//SIMULATION STOP
initial begin
    #4ms $stop();
end


endmodule
