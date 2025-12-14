//Modulo to control and generate the signals for MED module
//Inputs: DI (bus from where pixels arrive), DSI (indicate existence of bit in DI), nRST (reset signal, activate at 0), CLK (clock)
//Output: DO (median value), DSO (indicates value present in DO)

module MEDIAN #(parameter WIDTH = 8, parameter REG = 9)(
    input  logic [WIDTH-1:0] DI,
    input  logic             DSI,
    input  logic             nRST,
    input  logic             CLK,
    output logic [WIDTH-1:0] DO,
    output logic             DSO
);

logic BYP;                 //internal signal 
logic [WIDTH-1:0] count;   //counts cycles
logic [WIDTH-1:0] step;    //which STEP pass we are in (0 = STEP1, 1 = STEP2, ...)

//number of steps needed. For REG=9 -> (9+1)/2 = 5 steps
localparam int steps_num = (REG + 1) / 2;

//instantiate MED module
MED #(.WIDTH(WIDTH), .REG(REG)) med(
    .DI (DI),
    .DSI(DSI),
    .BYP(BYP),
    .CLK(CLK),
    .DO (DO)
);

//FSM states
typedef enum logic [1:0] {
    IDLE, //wait first pixel
    LOAD, //loading the remaining pixels
    STEP, //perform STEP passes (replaces STEP1..STEP5 using "step" counter)
    DONE  //output, valid for one cycle
} State;

State state, next_state;

always_ff @(posedge CLK or negedge nRST) begin
    if (!nRST) begin
        state <= IDLE;
        count <= 0;
        step  <= 0;
    end else begin
        state <= next_state; //update state in the end of clock

        case(state)

            IDLE: begin
                //waiting: reset counters
                count <= 0;
                step  <= 0;
            end

            LOAD: begin
                //we keep step=0 because STEP passes only start after all pixels loaded
                step <= 0;

                //count increases only when DSI=1 (pixel present)
                if (DSI) begin
                    if (count == (REG-2))
                        count <= 0;        //loaded last pixel -> REG-2 (7) -> reset count for STEP
                    else
                        count <= count + 1;
                end
            end

            STEP: begin
                //- "step" says which pass (0..steps_num-1)
                //- "count" says which cycle inside that pass

                
                //2 cases to know if we finished the step:
                //last pass (step == steps_num-1) is shorter, ends at count == steps_num-2
                //other passes are full length, end at count == REG-1
                if ( (step == (steps_num-1) && count == (steps_num-2)) || (step != (steps_num-1) && count == (REG-1)) ) begin

                    count <= 0; //finished this pass -> reset counter for next pass
                    
                    if (step == (steps_num-1)) //if this was the last pass, reset step (next_state will go to DONE)
                        step <= 0;
                    else
                        step <= step + 1; //go to next pass
                end else begin
                    count <= count + 1; //still inside current pass
                end
            end

            DONE: begin
                //one-cycle done pulse state, then we go back to IDLE
                count <= 0;
                step  <= 0;
            end
        endcase
    end
end


always_comb begin
    //Default
    next_state = state;
    DSO        = 0;
    BYP        = 1;

    case (state)

        IDLE: begin
            // do nothing until first pixel arrives
            BYP = 1;
            if (DSI)
                next_state = LOAD; 
        end

        LOAD: begin
            //keep bypass during load
            BYP = 1;

            //finish load when the last pixel was accepted (DSI=1 and count==REG-2)
            if (DSI && (count == (REG-2)))
                next_state = STEP;
        end

        STEP: begin
            //STEP1 (step0): BYP=0 for count<=REG-2, then BYP=1 at the last cycle
            //STEP2 (step1): BYP=0 for count<=REG-3, then BYP=1
            //so we have = (REG-2) - step as the moment when it changes to 1
            BYP = (count <= ((REG-2) - step)) ? 0 : 1;

            //go to DONE only when finishing the last pass at its last cycle
            if ((step == (steps_num-1)) && (count == (steps_num-2)))
                next_state = DONE;
        end

        DONE: begin
            //median is ready on DO in this cycle, so signal DSO
            DSO        = 1;
            BYP        = 1;
            next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
            DSO        = 0;
            BYP        = 1;
        end
    endcase
end

endmodule