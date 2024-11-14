// Timescale directive
`timescale 1 ns / 1 ns

// Path to the ALTERA host BFM
`define HOST  mm_host_bfm_0

// For clean colored outputs under modelsim
`define STDERR 32'h8000_0002

//-----------------------------------------------------------------
// The testbench
//-----------------------------------------------------------------

module testbench_top();

	// ------------------------------------------------------------
	// Local parameters
	// ------------------------------------------------------------
    // BFM related parameters
    localparam AV_ADDRESS_W    = 32 ;
    localparam AV_SYMBOL_W     = 8 ;
    localparam AV_NUMSYMBOLS   = 4 ;
    localparam AV_BURSTCOUNT_W = 6 ;
    // Derived parameters
    localparam  AV_DATA_W = (AV_SYMBOL_W * AV_NUMSYMBOLS) ;
	// Clock period
	localparam time CLK_PERIOD = 20ns;
    // Number of data packets transfers to be tested
    localparam ITRNUM=10 ;
    // Each packet contains a random number of maximum MAX_BURST_SIZE words
    localparam MAX_BURST_SIZE=2**(AV_BURSTCOUNT_W-1) ;
    // RAM SIZE: ARBITRATY number of words of the RAM
    // SHOULD BE A MULTIPLE OF MAX_BURST_SIZE IN
    // ORDER TO HAVE A CORRECT BEHAVIOR OF THE FILLING
    // TEST OF THE RAM
    localparam RAMSIZE=64*MAX_BURST_SIZE ;
    localparam RAM_ADD_W=$clog2(RAMSIZE);

	// ------------------------------------------------------------
	// Packages
	// ------------------------------------------------------------
	//
	import verbosity_pkg::*;
	import avalon_mm_pkg::*;
    import PACKET::*;

	// ------------------------------------------------------------
	// Local variables and signals
	// ------------------------------------------------------------
	//
	logic        clk;
	logic        reset;

	// Testbench variables
	logic [AV_ADDRESS_W-1:0] master_addr;
    logic [AV_NUMSYMBOLS-1:0] master_byte_enable;
	logic [AV_NUMSYMBOLS-1:0][AV_SYMBOL_W-1:0] master_rddata, master_wrdata;

    // TimeStamps in order to compute the time needed for each step
    time t0,t1,t2,t3 ;

	// ------------------------------------------------------------
	// Clock generator
	// ------------------------------------------------------------
	//
	initial
		clk = 1'b1;
	always
		#(CLK_PERIOD/2) clk <= ~clk;

    // ------------------------------------------------------------
	// Reset generation
    // Active high reset
	// ------------------------------------------------------------
	initial begin
        reset = 1'b1 ;
        repeat(8) @(posedge clk) ;
        #1ns;
        reset = 1'b0 ;
    end

    // ------------------------------------------------------------
    // Avalon Interface
    // ------------------------------------------------------------
     avalon_if #(.DATA_BYTES(AV_NUMSYMBOLS), .BURSTCOUNT_W(AV_BURSTCOUNT_W)) avalon_if_0( .clk(clk), .reset(reset));

    // ------------------------------------------------------------
    // The device under test
    // ------------------------------------------------------------
    avalon_bram #(.RAM_ADD_W(RAM_ADD_W),.BURSTCOUNT_W(AV_BURSTCOUNT_W)) dut_0(.avalon_a(avalon_if_0.agent));

    // ------------------------------------------------------------
    // ALTERA Avalon BFMS common params
    // ------------------------------------------------------------
`define COMMON_BFM_PARAMS \
        .AV_ADDRESS_W               (32),\
		.AV_SYMBOL_W                (8),\
		.AV_NUMSYMBOLS              (AV_NUMSYMBOLS),\
		.AV_BURSTCOUNT_W            (AV_BURSTCOUNT_W),\
		.AV_CONSTANT_BURST_BEHAVIOR (0),\
		.AV_BURST_LINEWRAP          (0),\
		.AV_BURST_BNDR_ONLY         (0),\
		.REGISTER_WAITREQUEST       (0),\
		.AV_MAX_PENDING_READS       (0),\
		.AV_MAX_PENDING_WRITES      (0),\
		.AV_FIX_READ_LATENCY        (1),\
		.USE_READ                   (1),\
		.USE_WRITE                  (1),\
		.USE_ADDRESS                (1),\
		.USE_BYTE_ENABLE            (1),\
		.USE_BURSTCOUNT             (1),\
		.USE_READ_DATA              (1),\
		.USE_READ_DATA_VALID        (1),\
		.USE_WRITE_DATA             (1),\
		.USE_BEGIN_TRANSFER         (0),\
		.USE_BEGIN_BURST_TRANSFER   (0),\
		.USE_WAIT_REQUEST           (1),\
		.USE_TRANSACTIONID          (0),\
		.USE_WRITERESPONSE          (0),\
		.USE_READRESPONSE           (0),\
		.USE_CLKEN                  (0),\
		.AV_READ_WAIT_TIME          (1),\
		.AV_WRITE_WAIT_TIME         (0),\
		.AV_REGISTERINCOMINGSIGNALS (0),


    // ------------------------------------------------------------
    // ALTERA Avalon host BFM
    // ------------------------------------------------------------
    altera_avalon_mm_master_bfm #(
        `COMMON_BFM_PARAMS
		.AV_READRESPONSE_W          (8),
		.AV_WRITERESPONSE_W         (8),
        .VHDL_ID                    (0),
        .PRINT_HELLO                (0)
	) mm_host_bfm_0 (
		.clk                    (clk),
		.reset                  (reset),
		.avm_address            (avalon_if_0.address),
		.avm_burstcount         (avalon_if_0.burstcount),
		.avm_readdata           (avalon_if_0.readdata),
		.avm_writedata          (avalon_if_0.writedata),
		.avm_waitrequest        (avalon_if_0.waitrequest),
		.avm_write              (avalon_if_0.write),
		.avm_read               (avalon_if_0.read),
		.avm_byteenable         (avalon_if_0.byteenable),
		.avm_readdatavalid      (avalon_if_0.readdatavalid),
		.avm_begintransfer      (),
		.avm_beginbursttransfer (),
		.avm_arbiterlock        (),
		.avm_lock               (),
		.avm_debugaccess        (),
		.avm_transactionid      (),
		.avm_readid             (8'b00000000),
		.avm_writeid            (8'b00000000),
		.avm_clken              (),
		.avm_response           (2'b00),
		.avm_writeresponsevalid (1'b0),
		.avm_writeresponserequest(),
		.avm_readresponse       (8'b00000000),
		.avm_writeresponse      (8'b00000000)
	);

    // ------------------------------------------------------------
    // TPT/ALTERA Avalon monitor assertions
    // ------------------------------------------------------------
    tpt_altera_avalon_mm_monitor_assertion #(
        `COMMON_BFM_PARAMS
        .AV_READ_TIMEOUT            (0),
        .AV_WRITE_TIMEOUT           (0),
        .AV_WAITREQUEST_TIMEOUT     (1),
        .AV_MAX_READ_LATENCY        (0),
        .AV_MAX_WAITREQUESTED_READ (0),
        .AV_MAX_WAITREQUESTED_WRITE(0),
        .SLAVE_ADDRESS_TYPE         ("SYMBOLS"),
        .MASTER_ADDRESS_TYPE        ("SYMBOLS"),
        .USE_ARBITERLOCK            (0),
        .USE_LOCK                   (0),
        .USE_DEBUGACCESS            (0)
    ) mm_monitor_assertions_0 (.avalon_mon(avalon_if_0.monitor)) ;

    // ------------------------------------------------------------
	// Test stimulus
	// ------------------------------------------------------------
	initial
	begin

        automatic Packet #(AV_SYMBOL_W,AV_NUMSYMBOLS) pkt  = new();

        // Dynamic arrays for storage of data packets
        logic [AV_DATA_W-1:0]     dataIn[$];
        logic [AV_DATA_W-1:0]     dataOutRef[$];
        logic [AV_DATA_W-1:0]     dataOut[$];
        logic [AV_NUMSYMBOLS-1:0] selIn[$];
        int tmp_addr ;

		// --------------------------------------------------------
		// Initialize the HOST BFM
		// --------------------------------------------------------
		set_verbosity(VERBOSITY_WARNING);
		`HOST.init();

		// Give the system reset synchronizers a few clocks
        repeat(20) @(posedge clk) ;

        // --------------------------------------------------------
		// Message de départ
		// --------------------------------------------------------
		//
		$fwrite(`STDERR,"\n");
		$fwrite(`STDERR,"=====================================================================\n");
        $fwrite(`STDERR," %0d randomly sized packets transmission using Avalon\n",ITRNUM);
        $fwrite(`STDERR," PIPELINED mode, SINGLE transfers, for each paquet:\n") ;
        $fwrite(`STDERR," - The current content of the memory is read\n") ;
        $fwrite(`STDERR," - The new packet is written with random datas and random byte-enable\n" ) ;
        $fwrite(`STDERR," - The packet is read again, and compared with expected results\n") ;
		$fwrite(`STDERR,"=====================================================================\n");
		$fwrite(`STDERR,"\n");

        // Timestamp
        t0=$time();
        // Initialize random generators for packet address and packet size
        $srandom(0);


        $timeformat(-9,3,"ns",20);
        $display("\n%t: INFO:  Starting FIRST sequence of packets read/write/verify",$time);

        for(int itr=1;itr <=ITRNUM;itr++) begin
            repeat(5) @(posedge clk) ;
            // Generate an aligned start address for the packetaddress
            // (repeat 2 times the same address in order to test overwritten
            // values)
            // Max address is arbitrary limited
            if(itr %2) master_addr = ($urandom  & 16'h3FFF) << $clog2(AV_NUMSYMBOLS) ;

            // Generate also the byte_enable words associated to the packet
            pkt.genRndPkt(
                $urandom_range(1,MAX_BURST_SIZE),
                random_selection,
                dataIn,
                selIn
                );

            // 1 Read the current content of the memory at the given location of the packet
            dataOutRef.delete() ; // Initialize the queue of responses
            pkt.setRefTime($time);
            for(int i=0;i<dataIn.size();i++) begin
            // generate an aligned address ;
                tmp_addr = master_addr + AV_NUMSYMBOLS*i ;
                // Read the current content of the memory
		        avalon_read(tmp_addr, master_rddata,$urandom & 1'b1); // AVALON READ No needs for masks when reading
                dataOutRef.push_back(master_rddata) ; // store result in a queue.
		        // $display("HOST: Read (addr, rddata) = (%.8Xh, %.8Xh)", tmp_addr, master_rddata);
            end

            // 2 Write new contents using the masks
            // generate associated bytes and masks
            @(posedge clk) ;
            pkt.setWriteTime($time);
            for(int i=0;i<dataIn.size();i++) begin
                // generate an aligned address ;
                tmp_addr = master_addr + AV_NUMSYMBOLS*i ;
                master_wrdata = dataIn[i] ;
                master_byte_enable = selIn[i] ;
		        avalon_write(tmp_addr, master_wrdata,master_byte_enable,$urandom & 1'b1); // AVALON WRITE with mask
		        // $display("HOST: Write (addr, data, byte_enable) = (%.8Xh, %.8Xh, %.4bb)", tmp_addr, master_wrdata, master_byte_enable);
            end

            // 3 Read back the current content of the memory at the given location of the packet
            @(posedge clk) ;
            dataOut.delete() ; // Initialize the queue of responses
            pkt.setReadTime($time);
            for(int i=0;i<dataIn.size();i++) begin
                // generate an aligned address ;
                tmp_addr = master_addr + AV_NUMSYMBOLS*i ;
                // Read the new content of the memory
		        avalon_read(tmp_addr, master_rddata,$urandom & 1'b1); // AVALON READ No needs for masks when reading
                dataOut.push_back(master_rddata) ; // store result in a queue.
		        // $display("HOST: Read (addr, rddata) = (%.8Xh, %.8Xh)", tmp_addr, master_rddata);
            end
            // 4 Check the consistency of the read/write/read sequence
            if (pkt.CheckPkt(dataOutRef, dataOut, dataIn, selIn, master_addr)==-1) begin
                $timeformat(-9,3,"ns",20);
                $display("%t: FAILURE: wrong packet read/write/read sequence, see file packet.log for details",$time);
                $error(1) ;
            end
        end
        t1 = $time;

        $timeformat(-9,3,"ns",20);
        $display("%t: INFO:  Finished FIRST packet read/write/read sequences",$time);
        $display("%t: INFO:  Total time for simple Pipelined packet transfer sequences: %06d\n",$time,t1-t0) ;

		// Delay between tests
		repeat(10) @(posedge clk);

        $fwrite(`STDERR,"\n");
		$fwrite(`STDERR,"=====================================================================\n");
        $fwrite(`STDERR," %0d randomly sized packets transmission using Avalon\n",ITRNUM);
        $fwrite(`STDERR," PIPELINED & BURST mode transfers, for each paquet:\n") ;
        $fwrite(`STDERR," - The current content of the memory is read\n") ;
        $fwrite(`STDERR," - The new packet is written with random datas and random byte-enable\n" ) ;
        $fwrite(`STDERR," - The packet is read again, and compared with expected results\n") ;
		$fwrite(`STDERR,"=====================================================================\n");
		$fwrite(`STDERR,"\n");

        t2 = $time;
        // Initialize random generators for packet address and random generators
        // in order to have the same packet/address sequence as the previous one
        $srandom(0);
        $timeformat(-9,3,"ns",20);
        $display("%t: INFO:  Starting SECOND second sequence of packets read/write/verify",$time);

        for(int itr=1;itr <=ITRNUM;itr++) begin
            repeat(5) @(posedge clk) ;
            // Generate an aligned start address for the packetaddress
            // (repeat 2 times the same address in order to test overwritten
            // values)
            // Max address is arbitrary limited to 16 bits
            if(itr %2) master_addr = ($urandom  & 16'h3FFF) << $clog2(AV_NUMSYMBOLS) ;

            // Generate a randomly sized packet of data to write, aligned to the word size
            // Generate also the byte_enable words associated to the packet
            pkt.genRndPkt(
                $urandom_range(1,MAX_BURST_SIZE),
                random_selection,
                dataIn,
                selIn
                );

            // 1 Read the current content of the memory at the given location of the packet
            pkt.setRefTime($time);
            // Read the current content of the memory
		    avalon_read_burst(master_addr, dataOutRef,dataIn.size()); // AVALON READ BURST
            @(posedge clk) ;

            // 2 Write new contents using the masks
            // generate associated bytes and masks
            pkt.setWriteTime($time);
		    avalon_write_burst(master_addr, dataIn, selIn, dataIn.size(),1);
            @(posedge clk) ;

            // 3 Read back the current content of the memory at the given location of the packet
            pkt.setReadTime($time);
		    avalon_read_burst(master_addr, dataOut,dataIn.size()); // AVALON READ BURST
            // 4 Check the consistency of the read/write/read sequence
            if (pkt.CheckPkt(dataOutRef, dataOut, dataIn, selIn, master_addr)==-1) begin
                $timeformat(-9,3,"ns",20);
                $display("%t: FAILURE: wrong packet read/write/read sequence, see file packet.log for details",$time);
                $error(1) ;
            end
        end
        t3 = $time();

        pkt.printFullStatus();


        $timeformat(-9,3,"ns",20);
        $display("%t: INFO:  Finished SECOND packet read/write/read sequences",$time);
        $display("%t: INFO:  Total time for Pipelined and Burst  packet transfer: %06d\n",$time,t3-t2) ;

		// Delay between tests
		repeat(10) @(posedge clk);


        $timeformat(-9,3,"ns",20);
        $display("%t: INFO:  Starting RAM config tests",$time);
        $display("%t: INFO:  %0d words written in the RAM with increasing adresses and values (sel = 1111)",$time,RAMSIZE) ;

        // Write enough bursts of MAX_BURST_SIZE to fill the memory
        // Warnong RAMSIZE should be a multiple of MAX_BURST_SIZE...
        for(int itr=0;itr < RAMSIZE/MAX_BURST_SIZE;itr++) begin
            master_addr = 4*MAX_BURST_SIZE*itr ;
            dataIn.delete() ;
            selIn.delete() ;
            for(int w=0;w < MAX_BURST_SIZE;w++) begin
                dataIn.push_back(MAX_BURST_SIZE*itr+w);
                selIn.push_back(4'b1111) ;
            end
		    avalon_write_burst(master_addr, dataIn, selIn, dataIn.size(),0);
        end
        // Read back the content of the memory and check the contents
        for(int itr=0;itr < RAMSIZE/MAX_BURST_SIZE;itr++) begin
            master_addr = 4*MAX_BURST_SIZE*itr ;
            dataOut.delete() ;
		    avalon_read_burst(master_addr, dataOut,dataIn.size()); // AVALON READ BURST
            for(int w=0;w < MAX_BURST_SIZE;w++) begin
                if(!(dataOut[w] === MAX_BURST_SIZE*itr+w)) begin
                    $timeformat(-9,3,"ns",20);
                    $display("%t: FAILURE: Possible incorrect memory size",$time) ;
                    $display("%t: FAILURE: Data value at address 0x%8h should be %0d, read value is %0d",$time,master_addr+4*w, MAX_BURST_SIZE*itr+w, dataOut[w]) ;
                    $error(1) ;
                end
            end
        end
        // Test if memory is oversized
        $display("%t: INFO:  Value 32'h12345678 written at first address above RAM last address and read back at address 0",$time) ;
         avalon_write(4*RAMSIZE, 32'h12345678,4'b1111,0);
         avalon_read(0, master_rddata,0);
         if (!(master_rddata === 32'h12345678)) begin
                    $timeformat(-9,3,"ns",20);
                    $display("%t: FAILURE: Possible incorrect memory size",$time) ;
                    $display("%t: FAILURE: Data value at address 0x%8h should be 32'h%8h, read value is 32'h%8h\n",$time,0, 32'h12345678, master_rddata) ;
                    $error(1) ;
         end
        $timeformat(-9,3,"ns",20);
        $display("%t: INFO:  Finished tests of RAM size without errors.",$time);
		$finish;
	end

	// ============================================================
    // General timeoutwatchdog
	// ============================================================
    initial begin
        #(130us) ;
        $timeformat(-9,5,"ns",20);
	    $display("%t: %s %s",$time, "FAILURE:", "Simulation didn't finish before the expected time, probable stalled process waiting for something...");
        $error(1);
        $stop;
    end

	// ============================================================
	// Tasks
	// ============================================================
	//
	// Avalon-MM single-transaction read and write procedures.
	//
	// ------------------------------------------------------------
	task avalon_write (
	// ------------------------------------------------------------
		input [AV_ADDRESS_W-1:0] addr,
		input [AV_DATA_W-1:0]    data,
        input [AV_NUMSYMBOLS-1:0] byte_enable,
        input int init_latency
	);
	begin
		// Construct the BFM request
		`HOST.set_command_request(REQ_WRITE);
		`HOST.set_command_idle(0, 0);
		`HOST.set_command_init_latency(init_latency);
		`HOST.set_command_address(addr);
		`HOST.set_command_byte_enable(byte_enable,0);
		`HOST.set_command_burst_size(1);
		`HOST.set_command_burst_count(1);
		`HOST.set_command_data(data, 0);

		// Queue the command
		`HOST.push_command();

		// Wait until the transaction has completed
		while (`HOST.get_response_queue_size() != 1)
			@(posedge clk);

		// Dequeue the response and discard
		`HOST.pop_response();
	end
	endtask

	// ------------------------------------------------------------
	task avalon_read (
	// ------------------------------------------------------------
		input  [AV_ADDRESS_W-1:0] addr,
		output [AV_DATA_W-1:0]    data,
        input int init_latency
	);
	begin
		// Construct the BFM request
		`HOST.set_command_request(REQ_READ);
		`HOST.set_command_idle(0, 0);
		`HOST.set_command_init_latency(init_latency);
		`HOST.set_command_address(addr);
		`HOST.set_command_byte_enable('1,0);
		`HOST.set_command_burst_size(1);
		`HOST.set_command_burst_count(1);
		`HOST.set_command_data(0, 0);

		// Queue the command
		`HOST.push_command();

		// Wait until the transaction has completed
		while (`HOST.get_response_queue_size() != 1)
			@(posedge clk);

		// Dequeue the response and return the data
		`HOST.pop_response();
		data = `HOST.get_response_data(0);
	end
	endtask

	// ------------------------------------------------------------
	//
	// Avalon-MM burst-transaction read and write procedures.
	//
	// ------------------------------------------------------------
	task avalon_write_burst (
	// ------------------------------------------------------------
		input [AV_ADDRESS_W-1:0] addr,
		input [AV_DATA_W-1:0]    data [$],
        input [AV_NUMSYMBOLS-1:0] byte_enable [$],
        input int burst_size,
        input bit randb
	);
	begin
		// Construct the BFM request
		`HOST.set_command_request(REQ_WRITE);
		`HOST.set_command_init_latency(0);
            for(int i=0;i < burst_size; i++) begin
            if(randb) 
		     `HOST.set_command_idle($urandom & 1'b1,i);
            else
		     `HOST.set_command_idle(0,i);
            end
		`HOST.set_command_address(addr);
		`HOST.set_command_burst_size(burst_size);
		`HOST.set_command_burst_count(burst_size);

		for (int i = 0; i < burst_size; i++) begin
		    `HOST.set_command_byte_enable(byte_enable[i],i);
			`HOST.set_command_data(data[i], i);
        end

		// Queue the command
		`HOST.push_command();

		// Wait until the transaction has completed
		while (`HOST.get_response_queue_size() != 1)
			@(posedge clk);

		// Dequeue the response and discard
		`HOST.pop_response();
	end
	endtask

	// ------------------------------------------------------------
	task avalon_read_burst (
	// ------------------------------------------------------------
		input  [AV_ADDRESS_W-1:0] addr,
		output [AV_DATA_W-1:0]    data [$],
        input int burst_size
	);
	begin
		// Construct the BFM request
		`HOST.set_command_request(REQ_READ);
		`HOST.set_command_idle(0, 0);
		`HOST.set_command_init_latency(0);
		`HOST.set_command_address(addr);
		`HOST.set_command_byte_enable('1,0);
		`HOST.set_command_burst_size(burst_size);
		`HOST.set_command_burst_count(burst_size);
		`HOST.set_command_data(0, 0);

        // Clean return queue before starting
        data.delete();

		// Queue the command
		`HOST.push_command();

		// Wait until the transaction has completed
		while (`HOST.get_response_queue_size() != 1)
			@(posedge clk);

		// Dequeue the response and return the data
		`HOST.pop_response();

		for (int i = 0; i < burst_size; i++)
            data.push_back(`HOST.get_response_data(i));
	end
	endtask


endmodule
