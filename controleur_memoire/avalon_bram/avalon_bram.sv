`timescale 1ns/1ps
`default_nettype none

module avalon_bram #(parameter RAM_ADD_W = 8, BURSTCOUNT_W = 4 ) (
    avalon_if.agent avalon_a
);

    //FSM
    typedef enum logic [1:0] {
        IDLE     = 2'd0,
        READ     = 2'd1, 
        WRITE    = 2'd2  
    } state_t;

    state_t state;
    
    //ADRESSES
    logic [7:0] memory_bank [2**RAM_ADD_W][4];

    logic [RAM_ADD_W-1:0] start_addr;
    assign start_addr = avalon_a.address[RAM_ADD_W+1 : 2];

    logic [RAM_ADD_W-1:0]    next_addr; 
    logic [BURSTCOUNT_W-1:0] burst_count; // remaining transfers in the burst after first

    //asserts wait based on the state, with priority as READ - WRITE - IDLE
    assign avalon_a.waitrequest = avalon_a.reset ? 1'b1 : (state == READ)  ? 1'b1 : (state == WRITE) ? ~avalon_a.write : 1'b0;

    //FSM BEHAVIOR
    always_ff @(posedge avalon_a.clk) begin
        if (avalon_a.reset) begin
            state       <= IDLE;
            next_addr   <= '0;
            burst_count <= '0;
        end else begin
            case (state)
                IDLE: begin
                  
                    if (avalon_a.write) begin //write
                        if (avalon_a.burstcount != 1) begin
                            state        <= WRITE;
                            burst_count  <= avalon_a.burstcount - 1; 
                            next_addr    <= start_addr + 1'b1;
                        end
                    end else if (avalon_a.read) begin //read
                            state        <= READ;
                            burst_count  <= avalon_a.burstcount; 
                            next_addr    <= start_addr;
                        end
                end

                READ: begin
                    
                    if (burst_count == 1) begin
                        burst_count   <= '0;
                        state         <= IDLE;
                    end else begin
                        burst_count <= burst_count - 1;
                        next_addr   <= next_addr + 1'b1;
                    end
                end

                WRITE: begin

                    if (avalon_a.write) begin
                        next_addr <= next_addr + 1'b1;
                        if (burst_count == 1) begin
                            burst_count   <= '0;
                            state         <= IDLE;
                        end else begin
                            burst_count <= burst_count - 1;
                            next_addr   <= next_addr + 1'b1;
                        end
                    end
                end

                default: begin
                    state       <= IDLE;
                end
            endcase
        end
    end

   
    // SIGNAL CONTROL 
    always_ff @(posedge avalon_a.clk) begin
        if (avalon_a.reset)
            avalon_a.readdatavalid <= 1'b0;
        else
            avalon_a.readdatavalid <= (state == READ);
    end

    // MEMORY ACESS
    always_ff @(posedge avalon_a.clk) begin

        if ((state == IDLE && avalon_a.write) || (state == WRITE && avalon_a.write)) begin
            logic [RAM_ADD_W-1:0] mem_addr;
            mem_addr = (state == IDLE) ? start_addr : next_addr;

            if (avalon_a.byteenable[3]) memory_bank[mem_addr][3] <= avalon_a.writedata[31:24];
            if (avalon_a.byteenable[2]) memory_bank[mem_addr][2] <= avalon_a.writedata[23:16];
            if (avalon_a.byteenable[1]) memory_bank[mem_addr][1] <= avalon_a.writedata[15: 8];
            if (avalon_a.byteenable[0]) memory_bank[mem_addr][0] <= avalon_a.writedata[ 7: 0];
        end

        else if (state == READ) begin
            avalon_a.readdata <= {
                memory_bank[next_addr][3],
                memory_bank[next_addr][2],
                memory_bank[next_addr][1],
                memory_bank[next_addr][0]
            };
        end
    end

endmodule