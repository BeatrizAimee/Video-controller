//Comparison and exchange module
//Inputs: 2 buses of WIDTH bits (A and B), in this case WIDTH = 8
//Outputs: the max of the two pixels received (WIDTH-bits) - MAX
//         the min of the two pixels received (WIDTH-bits) - MIN

module MCE #(parameter  WIDTH = 8)(
    input logic [WIDTH-1:0] A,
    input logic [WIDTH-1:0] B,
    output logic [WIDTH-1:0] MAX,
    output logic [WIDTH-1:0] MIN);

assign MAX = (A>B) ? A : B; // If A>B, MAX=A. Otherwise MAX=B
assign MIN = (A<B) ? A : B; // If A<B, MIN=A. Otherwise MIN=B

endmodule


//Work made alone