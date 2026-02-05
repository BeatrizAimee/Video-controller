module avalon_intercon (
    avalon_if.agent avalon_ifa_stream,     // stream (writes pixels to sdram)
    avalon_if.agent avalon_ifa_vga,        // vga (reads pixels from sdram)
    avalon_if.host  avalon_ifh_sdram       // sdram
);

    logic sel_vga; // 0 = stream communicates with sdram, 1 = vga communicates sdram

    // STREAM
    logic [6:0] stream_count;       // counts writes inside the burst
    logic [6:0] stream_burstsize;

    wire is_stream_write_accepted;        // signal that shows if we can write to sdram
    assign is_stream_write_accepted = (!sel_vga) && avalon_ifa_stream.write && !avalon_ifa_stream.waitrequest;

    always_ff @(posedge avalon_ifa_stream.clk) begin
        if (avalon_ifa_stream.reset) begin
            stream_count     <= '0;
            stream_burstsize <= '0;                           
        end else if (is_stream_write_accepted) begin // if we can write
            if (stream_count == 0) begin                          // if a new burst starts                    
                stream_burstsize <= avalon_ifa_stream.burstcount; // receive burstcount at the start of burst
                if (avalon_ifa_stream.burstcount <= 1)            // if burst is only one word, end it immediately
                    stream_count <= '0;
                else
                    stream_count <= 7'd1;                         // if burst is more than one word, count first word
            end else begin                                        // if already inside a burst
                if (stream_count + 1 >= stream_burstsize) begin   // If in the last word of the burst
                    stream_count     <= '0;                       // end burst
                    stream_burstsize <= '0;                       
                end else begin
                    stream_count     <= stream_count + 1'b1;      // if not, continue burst
                end
            end
        end
    end

    logic stream_busy;    // indicates if stream is currently using the bus
    assign stream_busy = (!sel_vga) && (avalon_ifa_stream.write || (stream_count != 0));

    // VGA 
    logic [6:0] vga_count;  
    logic [6:0] vga_burstsize;

    wire is_vga_read_accepted;  // signal that shows if we can read from sdram
    assign is_vga_read_accepted = sel_vga && avalon_ifa_vga.read && !avalon_ifa_vga.waitrequest;

    always_ff @(posedge avalon_ifa_vga.clk) begin
        if (avalon_ifa_vga.reset) begin
            vga_count     <= '0;
            vga_burstsize <= '0;
        end else begin
            if (is_vga_read_accepted) begin                    // if we can read
                vga_count     <= '0;                        
                vga_burstsize <= avalon_ifa_vga.burstcount;    // get burstsize
            end else if (sel_vga && avalon_ifa_vga.readdatavalid && (vga_burstsize != 0)) begin // if we are in a burst
                if (vga_count + 1 >= vga_burstsize) begin  // if read last word 
                    vga_count     <= '0;                   // end burst
                    vga_burstsize <= '0;                 
                end else begin
                    vga_count     <= vga_count + 1'b1;     // continue burst
                end
            end
        end
    end

    logic vga_busy;   // indicates if vga is currently using the bus
    assign vga_busy = sel_vga && (avalon_ifa_vga.read || avalon_ifa_vga.readdatavalid || (vga_burstsize != 0));

    // ARBITER FOR sel_vga
    always_ff @(posedge avalon_ifh_sdram.clk) begin
        if (avalon_ifh_sdram.reset) begin
            sel_vga <= 1'b0;                                       
        end else begin
            if (sel_vga) begin        // if sel_vga == 1, it means VGA module currently has the bus                                
                if (!vga_busy && avalon_ifa_stream.write)            // if vga is not active, and stream wants the bus
                    sel_vga <= 1'b0;                                 // switch to stream
            end else begin            // if sel_vga == 0, it means STREAM module currently has the bus  
                if (!stream_busy && avalon_ifa_vga.read)             // if stream is not active and vga wants the bus
                    sel_vga <= 1'b1;                                 // switch to vga
            end
        end
    end

    // ASSIGNG SDRAM SIGNALS TO VGA OR STREAM
    assign avalon_ifh_sdram.address        = sel_vga ? avalon_ifa_vga.address    : avalon_ifa_stream.address;
    assign avalon_ifh_sdram.byteenable     = sel_vga ? avalon_ifa_vga.byteenable : avalon_ifa_stream.byteenable;
    assign avalon_ifh_sdram.read           = sel_vga ? avalon_ifa_vga.read       : avalon_ifa_stream.read;
    assign avalon_ifh_sdram.write          = sel_vga ? avalon_ifa_vga.write      : avalon_ifa_stream.write;
    assign avalon_ifh_sdram.writedata      = sel_vga ? avalon_ifa_vga.writedata  : avalon_ifa_stream.writedata;
    assign avalon_ifh_sdram.burstcount     = sel_vga ? avalon_ifa_vga.burstcount : avalon_ifa_stream.burstcount;

    // RETURN SDRAM RESPONSES TO VGA
    assign avalon_ifa_vga.waitrequest      = sel_vga ? avalon_ifh_sdram.waitrequest   : 1'b1;
    assign avalon_ifa_vga.readdatavalid    = sel_vga ? avalon_ifh_sdram.readdatavalid : 1'b0;
    assign avalon_ifa_vga.readdata         = sel_vga ? avalon_ifh_sdram.readdata      : 32'b0;

    // RETURN SDRAM RESPONSES TO STREAM
    assign avalon_ifa_stream.waitrequest   = !sel_vga ? avalon_ifh_sdram.waitrequest   : 1'b1;
    assign avalon_ifa_stream.readdatavalid = !sel_vga ? avalon_ifh_sdram.readdatavalid : 1'b0;
    assign avalon_ifa_stream.readdata      = !sel_vga ? avalon_ifh_sdram.readdata      : 32'b0;

endmodule

`default_nettype wire
