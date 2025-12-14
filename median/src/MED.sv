//Extract the median of 9 pixels
//INPUTS: DI (from where pixels arrive), DSI (1 when there are pixels at DI), BYP (Bypass flag), CLK (clock - rising edge)
//OUTPUT: DO (The median value)


module MED #(parameter WIDTH = 8, parameter REG = 9)(
    input logic [WIDTH-1:0] DI,
    input logic DSI,
    input logic BYP,
    input logic CLK, 
    output logic [WIDTH-1:0] DO);


logic [WIDTH-1:0] regs [REG-1:0]; // REG (number of, in this case 9) registers of WIDTH bits (in this case 8)
logic [WIDTH-1:0] MAX, MIN;

//Instance of MCE module
MCE #(.WIDTH(WIDTH)) mce(.A(regs[REG-1]), .B(regs[REG-2]), .MAX(MAX), .MIN(MIN));

always_ff @(posedge CLK) begin : main_logic


    // first, for the first MUX logic, if DSI = 1 the reg gets DI, else he gets MIN from MCE
    regs[0] <= (DSI)? DI:MIN;


    // second, shift the registers (the last one will be assigned later after second mux)
    for(int i = 0; i< REG-2; i++) begin
        regs[i+1] <= regs[i];
    end

    // third, for the second mux logic, if BYP = 1, we bypass the MCE and the value of the output will be the reg 7. Else, we get the MCE max
    regs[REG-1] <= (BYP)? regs[REG-2] : MAX;
end

//Output
assign DO = regs[REG-1];

endmodule
