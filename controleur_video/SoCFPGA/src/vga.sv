module vga #(parameter HDISP = 800, parameter VDISP = 480)(
    input  logic        pixel_clk,
    input  logic        pixel_rst,
    video_if.master     video_ifm
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

// TEST PATTERN GENERATION
logic [HCOUNT_WIDTH-1:0] x_count;
logic [VCOUNT_WIDTH-1:0] y_count;

assign x_count = h_count - HACTIVE_START;
assign y_count = v_count - VACTIVE_START;

always_ff @(posedge pixel_clk) begin
    if (pixel_rst) begin
        video_ifm.RGB <= 24'h000000; // Black on reset
    end else begin
        if (is_inside_active_x && is_inside_active_y) begin // If inside active area
            if ((x_count[3:0] == 4'h0) || (y_count[3:0] == 4'h0)) // Every 16 pixels/lines
                video_ifm.RGB <= 24'hFFFFFF; // White
            else
                video_ifm.RGB <= 24'h000000; // Black
        end else begin
            video_ifm.RGB <= 24'h000000; // Black outside active area
        end
    end
end

endmodule