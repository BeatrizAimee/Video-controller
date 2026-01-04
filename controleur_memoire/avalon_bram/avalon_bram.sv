`timescale 1ns/1ps
`default_nettype none

module avalon_bram #(parameter RAM_ADD_W = 8, BURSTCOUNT_W = 4 ) (
      avalon_if.agent avalon_a
);

    // Declarations
    logic [7:0] memory_bank [2**RAM_ADD_W][4];

    logic [RAM_ADD_W-1:0] word;
    assign word = avalon_a.address[RAM_ADD_W+1 : 2];

    // Signal Control 
    always_ff @(posedge avalon_a.clk) begin
        avalon_a.waitrequest   <= avalon_a.reset ? 1'b1 : avalon_a.read;
        avalon_a.readdatavalid <= avalon_a.reset ? 1'b0 : avalon_a.read;
    end

    // Memory access
    always_ff @(posedge avalon_a.clk) begin
        // WRITE
        if (avalon_a.write) begin
            if (avalon_a.byteenable[3]) memory_bank[word][3] <= avalon_a.writedata[31:24];
            if (avalon_a.byteenable[2]) memory_bank[word][2] <= avalon_a.writedata[23:16];
            if (avalon_a.byteenable[1]) memory_bank[word][1] <= avalon_a.writedata[15: 8];
            if (avalon_a.byteenable[0]) memory_bank[word][0] <= avalon_a.writedata[ 7: 0];
        end else begin
        // READ
            avalon_a.readdata = {
                  memory_bank[word][3],
                  memory_bank[word][2],
                  memory_bank[word][1],
                  memory_bank[word][0]
            };
        end
    end

endmodule
