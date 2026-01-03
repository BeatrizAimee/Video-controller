`timescale 1ns/1ps
// Le wrapper a pour but d'une part d'éviter d'exposer
// l'interface au niveau global et d'autre part 
// d'interposer des registres sur les IO pour permettre
// a nextpnr de calculer une fréquence MAX en toute 
// situation (nextpnr n'intègre pas des chemins 
// DFF->IO ou IO->DFF dans les mesures de timing)
// Le résultat est un surcôut de 110 registres qui
// est enlevé des statistiques pour avoir une estimation
// correcte de la complexité.
module wrapper(
    input wire clk,
    input wire reset,
    input wire [31:0] address,
    input wire [3:0] byteenable,
    input wire read,
    input wire write,
    input  wire [31:0] writedata,
    input wire [5:0] burstcount,
    output logic [31:0] readdata,
    output logic readdatavalid,
    output logic waitrequest) ;

// Ces paramètres doivent être identiques à ceux du testbench
localparam AV_BURSTCOUNT_W = 6 ;
localparam MAX_BURST_SIZE=2**(AV_BURSTCOUNT_W-1) ;
localparam RAMSIZE=64*MAX_BURST_SIZE ;
localparam RAM_ADD_W=$clog2(RAMSIZE);


avalon_if #(.DATA_BYTES(4),.BURSTCOUNT_W(6)) avalon_if0(clk,reset) ;

// Registres: 32+1+1=34
always @(posedge clk) begin
    readdata <= avalon_if0.readdata ;
    readdatavalid <= avalon_if0.readdatavalid ;
    waitrequest <= avalon_if0.waitrequest ;
end

// Registres: 32+32+4+1+1+6=76
(* keep *) logic [31:0] internal_address ;
(* keep *) logic [5:0] internal_burstcount ;

// Total 110 registres

always @(posedge clk) begin
    internal_address <= address;
    avalon_if0.writedata <= writedata;
    avalon_if0.byteenable <=  byteenable;
    avalon_if0.write <=  write;
    avalon_if0.read <=  read;
    internal_burstcount <= burstcount ;
end

assign avalon_if0.address = internal_address;
assign avalon_if0.burstcount = internal_burstcount ;

avalon_bram #(.RAM_ADD_W(RAM_ADD_W), .BURSTCOUNT_W(AV_BURSTCOUNT_W)) u_ctrl
  (
   .avalon_a(avalon_if0)
  );

endmodule


