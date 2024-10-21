
module wrapper(
    input wire clk,
    input wire reset,
    input wire [31:0] address,
    input wire [3:0] byteenable,
    input wire read,
    input wire write,
    input  wire [31:0] writedata,
    input wire [5:0] burstcount,
    output wire [31:0] readdata,
    output wire readdatavalid,
    output wire waitrequest) ;

// Ces paramètres doivent être identiques à ceux du testbench
localparam AV_BURSTCOUNT_W = 6 ;
localparam MAX_BURST_SIZE=2**(AV_BURSTCOUNT_W-1) ;
localparam RAMSIZE=64*MAX_BURST_SIZE ;
localparam RAM_ADD_W=$clog2(RAMSIZE);


avalon_if #(.DATA_BYTES(4),.BURSTCOUNT_W(6)) avalon_if0(clk,reset) ;

assign readdata = avalon_if0.readdata ;
assign readdatavalid = avalon_if0.readdatavalid ;
assign waitrequest = avalon_if0.waitrequest ;

assign avalon_if0.writedata = writedata;
assign avalon_if0.address = address;
assign avalon_if0.byteenable =  byteenable;
assign avalon_if0.write =  write;
assign avalon_if0.read =  read;
assign avalon_if0.burstcount = burstcount ;

avalon_bram #(.RAM_ADD_W(RAM_ADD_W), .BURSTCOUNT_W(AV_BURSTCOUNT_W)) u_ctrl
  (
   .avalon_a(avalon_if0)
  );

endmodule


