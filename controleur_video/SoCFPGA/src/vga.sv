module vga #(parameter HDISP = 800, parameter VDISP = 480)(
    input  logic        pixel_clk,
    input  logic        pixel_rst,
    video_if.master     video_ifm,
    avalon_if.host  avalon_ifh
);

// VGA SIGNAL PARAMETERS
localparam HFP    = 40; // Horizontal front porch
localparam HPULSE = 48; // Horizontal sync pulse
localparam HBP    = 40; // Horizontal back porch
localparam VFP    = 13; // Vertical front porch
localparam VPULSE = 3;  // Vertical sync pulse
localparam VBP    = 29; // Vertical back porch

localparam HTOTAL = HDISP + HFP + HPULSE + HBP; // Horizontal total
localparam VTOTAL = VDISP + VFP + VPULSE + VBP; // Vertical total

localparam HCOUNT_WIDTH = $clog2(HTOTAL);
localparam VCOUNT_WIDTH = $clog2(VTOTAL);

logic [HCOUNT_WIDTH-1:0] h_count; // Counter for horizontal pixels
logic [VCOUNT_WIDTH-1:0] v_count; // Counter for vertical lines

// ACTIVE WINDOW START
localparam HACTIVE_START = HFP + HPULSE + HBP;
localparam VACTIVE_START = VFP + VPULSE + VBP;

assign video_ifm.CLK = pixel_clk; // Clock assignment

// PIXEL/LINE COUNT
always_ff @(posedge pixel_clk) begin
    if (pixel_rst) begin
        h_count <= '0;
        v_count <= '0;
    end else begin
        if (h_count == HTOTAL - 1) begin // If the line ended
            h_count <= '0; // Reset horizontal count
            if (v_count == VTOTAL - 1) // check if the there are more vertical lines to count
                v_count <= '0; // If not, reset vertical count (restart frame)
            else 
                v_count <= v_count + 1'b1; // If yes, increment vertical count
        end else begin
            h_count <= h_count + 1'b1; // If the line didnt end, increment horizontal count
        end
    end
end

// These signals indicate whether we are inside the active display area
logic is_inside_active_x;
logic is_inside_active_y;

assign is_inside_active_x = (h_count >= HACTIVE_START) && (h_count < HACTIVE_START + HDISP); // If true, we are inside active horizontal area
assign is_inside_active_y = (v_count >= VACTIVE_START) && (v_count < VACTIVE_START + VDISP); // If true, we are inside active vertical area

// GENERATES TIMING SIGNALS
always_ff @(posedge pixel_clk) begin
    if (pixel_rst) begin
        video_ifm.HS    <= 1'b1;
        video_ifm.VS    <= 1'b1;
        video_ifm.BLANK <= 1'b0;
    end else begin
        if ((h_count >= HFP) && (h_count < HFP + HPULSE)) // After HFP, HS is low for HPULSE duration
            video_ifm.HS <= 1'b0;
        else
            video_ifm.HS <= 1'b1;

        if ((v_count >= VFP) && (v_count < VFP + VPULSE))  // After VFP, VS is low for VPULSE duration
            video_ifm.VS <= 1'b0;
        else
            video_ifm.VS <= 1'b1;

        video_ifm.BLANK <= is_inside_active_x && is_inside_active_y; // BLANK is high only in active area
    end
end

// FIFO AND AVALON PARAMETERS
localparam BURSTSIZE = 16;
localparam LAST_ADDR = (HDISP * VDISP * 4) - 4; // byte address
localparam ALMOST_FULL_THRESHOLD = (1 << 8) - BURSTSIZE - 1; // Shift 8 bits to get 256 depth, then minus burst size and 1 (last before full)

// FIFO SIGNALS
logic [23:0] fifo_rdata;
logic        fifo_empty;
logic        walmost_full;
wire         fifo_read;

// FIFO INSTANTIATION
async_fifo #(.DATA_WIDTH(24), .DEPTH_WIDTH(8), .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD)) fifo0 (
    .rst          (avalon_ifh.reset),
    .rclk         (pixel_clk),
    .read         (fifo_read),
    .rdata        (fifo_rdata),
    .rempty       (fifo_empty),
    .wclk         (avalon_ifh.clk),
    .wdata        (avalon_ifh.readdata[23:0]),
    .write        (avalon_ifh.readdatavalid),
    .wfull        (),
    .walmost_full (walmost_full)
);

// AVALON LOGIC
assign avalon_ifh.byteenable = 4'b1111; // Always read all bytes
assign avalon_ifh.burstcount = BURSTSIZE; 
assign avalon_ifh.write      = 1'b0;

// FSM STATES
typedef enum logic [1:0] {
    IDLE    = 2'd0, // Initial state
    REQUEST = 2'd1, // Requesting data
    READ    = 2'd2, // Reading data
    WAIT    = 2'd3  // Waiting for next burst
} state_t;

state_t state;

logic [4:0] burst_count; // Remaining transfers in the burst

assign avalon_ifh.read = (state == REQUEST) && (walmost_full == 1'b0); // Only request when FIFO can accept more

// AVALON FSM
always_ff @(posedge avalon_ifh.clk) begin
    if (avalon_ifh.reset) begin
        state      <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                avalon_ifh.address <= '0;
                burst_count        <= BURSTSIZE;
                state              <= WAIT;
            end

            REQUEST: begin // Sends a burst read request
                if (!avalon_ifh.waitrequest && !walmost_full) // We only proceed if not waiting and FIFO can accept more data
                    state <= READ;
            end

            READ: begin
                if (avalon_ifh.readdatavalid) begin
                    burst_count <= burst_count - 1'b1;

                    if (avalon_ifh.address == LAST_ADDR)
                        avalon_ifh.address <= '0;
                    else
                        avalon_ifh.address <= avalon_ifh.address + 4;

                    if (burst_count == 5'd1) // If this was the last data in the burst
                        state <= WAIT;
                end
            end

            WAIT: begin
                burst_count <= BURSTSIZE;
                if (walmost_full == 1'b0) // When there is space in FIFO, go to request new burst
                    state <= REQUEST;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end


// FIFO OUTPUT
logic enable_read;

always_ff @(posedge pixel_clk) begin
    if (pixel_rst)
        enable_read <= 1'b0;
    else if (walmost_full && (v_count < VACTIVE_START)) // Enable read when FIFO is almost full and we are before active video (means our framebuffer is ready)
        enable_read <= 1'b1;
end

assign fifo_read = enable_read && video_ifm.BLANK ? 1'b1 : 1'b0; // Read from FIFO only when its ready and in active video
assign video_ifm.RGB = fifo_read ? fifo_rdata : 24'h000000; // Connects FIFO data to video output, black otherwise

endmodule

`default_nettype wire