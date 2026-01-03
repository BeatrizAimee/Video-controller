// See SysWip code for original version.
// SysWip.com is no longer alive. Some versions of the code may be usable
// using Web Archive...

// For clean colored output (out of modelsim transcript)
`define STDERR 32'h8000_0002

package PACKET;

// symbol mask selection
typedef enum {random_selection, full_selection} selection_mode ;


///////////////////////////////////////////////////////////////////////////////
// Class Packet:
///////////////////////////////////////////////////////////////////////////////
class Packet #(int SYMBOL_W=8, int NUMSYMBOLS=4) ;

  typedef logic    [SYMBOL_W-1:0]   symbol_type;
  typedef symbol_type [NUMSYMBOLS-1:0] word_type ;
  typedef logic    [NUMSYMBOLS-1:0] sel_type;
  typedef word_type packet[$];
  typedef sel_type sel_packet[$];

  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  // Generation of random masks
  local rand logic [7:0] rndSymbol ;

   // Constraints for masks aligned to bytes/halfword/word/double word  boundaries
  rand logic [7:0] rndMask;
  constraint word_align {
                          NUMSYMBOLS == 8 -> rndMask[7:0] inside { 8'b00000000, 8'b00000001, 8'b00000010, 8'b00000100,
                                                               8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000,
                                                               8'b10000000, 8'b00000011, 8'b00001100, 8'b00110000,
                                                               8'b11000000, 8'b00001111, 8'b11110000, 8'b11111111 } ;
                          NUMSYMBOLS == 4 -> rndMask[3:0] inside { 4'b0000, 4'b0001, 4'b0010, 4'b0100,
                                                               4'b1000, 4'b0011, 4'b1100, 4'b1111} ;
                          NUMSYMBOLS == 2 -> rndMask[1:0] inside { 2'b00, 2'b01, 4'b10, 4'b11 }  ;
                        }

  //
  static int AllChecks     = 0;
  static int AllChecksFail = 0;
  local  int Checks        = 0;
  local  int ChecksFail    = 0;
  local  time refTime,writeTime,readTime;



/////////////////////////////////////////////////////////////////////////////
//************************* Class Methods *********************************//
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////////////
  /*- genRndPkt(): Generates random packet with the given length.*/
  // added random selection bit / or "all selected" bits
  // for a 16 bits bus allowed masks are (01,10,11)
  // for a 32 bits bus (0001, 0010, 0101, 1111)
  // ...
  //  nbWords : the number of "words" of "data_bytes" bytes to generate
  /////////////////////////////////////////////////////////////////////////////
  task genRndPkt(input int nbWords, input selection_mode selMode, output packet pkt, output sel_packet selpkt);

    // Default selection pattern is "all bytes selected"
    automatic sel_type  selpattern = '1 ;
    automatic word_type data ;
    pkt = {};
    selpkt = {};
    for (int i = 0; i < nbWords; i++) begin
       if(selMode == random_selection)
       begin
         assert (this.randomize())
         else $fatal(0, "Gen Random Number: Randomize failed");
         selpattern = this.rndMask;
       end
       for(int j=0; j < NUMSYMBOLS; j++) // Generate all symbols of a word
            //data[j] = $urandom_range(0,255); // random symbol
            assert(this.randomize())
            data[j] = this.rndSymbol ; // random symbol
       pkt.push_back(data); // random word
       selpkt.push_back(selpattern); // random selection but
    end
  endtask

  /////////////////////////////////////////////////////////////////////////////
  /*- CheckPkt(): Compares 2 given packets and returns '0' if they are equal.
  // Otherwise returns '-1'.*/
  /////////////////////////////////////////////////////////////////////////////
   function int CheckPkt(packet initPkt, packet resPkt, expPkt, sel_packet selPkt, int addr);
    sel_type errPkt[$];
    int dataError = 0;
    this.Checks++;
    this.AllChecks++;

    for (int i = 0; i < initPkt.size(); i++) begin
      sel_type err = 0;
      for(int j = 0; j < NUMSYMBOLS; j++) begin
          if (((resPkt[i][j] !== expPkt[i][j])  && selPkt[i][j]) ||   // Selected symbols of final read packet should be identical to written symbols
              ((resPkt[i][j] !== initPkt[i][j]) && !selPkt[i][j])     // Unselected bytes of final read packet should be identical to unwritten bytes
          )
          begin
           err[j] = 1 ;
           dataError++;
          end //if
      end // for symbols
      errPkt.push_back(err);
    end // for pkt.size
    Print3Pkt(initPkt, resPkt, expPkt, selPkt, errPkt, addr);

    if (dataError == 0) begin
       //$fwrite(`STDERR,"   Passed!!! \n");
    CheckPkt = 0;
    end else begin
        $fwrite(`STDERR,"#-----Check %0d",this.Checks);
        $fwrite(`STDERR,"   Failed. Current Check has %0d errors\n", dataError);
        CheckPkt = -1;
        this.ChecksFail++;
        this.AllChecksFail++;
    end
  endfunction

/////////////////////////////////////////////////////////////////////////////
  /*- Print3Pkt(): Prints given "str" string and then packet containt.*/
  // added selection packet
  /////////////////////////////////////////////////////////////////////////////
  function void Print3Pkt(packet initPkt, packet resPkt, packet expPkt, sel_packet selpkt, sel_packet errPkt, int addr);
    int mask ;
    int naddr=addr ;
    int pos ;
    string results[$] ;
    string sr ;
    bit sel;

    $fwrite(`STDERR,"\nPacket size is %0d words\n",expPkt.size());
    // Warning we expect that the time precision is 1ps...
    $timeformat(-12,3,"ns",0) ;
    $fwrite(`STDERR,"Start times: Initial Read (%t), Write (%t), Read (%t)\n",refTime,writeTime,readTime);
    if(NUMSYMBOLS==8) $fwrite(`STDERR," Address      Initial Data      Write Data&Mask         Read Data\n") ;
    if(NUMSYMBOLS==4) $fwrite(`STDERR," Address  Initial Data  Write Data/Mask Read Data\n") ;
    if(NUMSYMBOLS==2) $fwrite(`STDERR," Address  Initial Data  Write Data/Mask Read Data\n") ;

    for (int i = 0; i < initPkt.size(); i++) begin
      $fwrite(`STDERR,"%h  ", naddr) ;
      naddr = naddr + NUMSYMBOLS ;
      $fwrite(`STDERR,"    %08h",initPkt[i]) ;
      $fwrite(`STDERR,"    %08h",expPkt[i])  ;
      $fwrite(`STDERR," %04b  ",selpkt[i])  ;
      //$fwrite(`STDERR,"  %08h",resPkt[i])  ;
      for (int j=NUMSYMBOLS-1; j >=0 ; j--) begin
         if(errPkt[i][j])
            $fwrite(`STDERR,"\033[91m%h\033[0m",resPkt[i][j]);
         else
            $fwrite(`STDERR,"\033[92m%h\033[0m",resPkt[i][j]);
      end
      $fwrite(`STDERR,"\n") ;
    end

  endfunction
   /////////////////////////////////////////////////////////////////////////////
  /*- printStatus(): Print checks and failed checks information.*/
  /////////////////////////////////////////////////////////////////////////////
  function void printStatus();
    $fwrite(`STDERR,"---Number of Checks        %0d \n", this.Checks);
    $fwrite(`STDERR,"---Number of failed Checks %0d \n", this.ChecksFail);
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- printFullStatus(): Print checks and failed checks information.*/
  /////////////////////////////////////////////////////////////////////////////
  function void printFullStatus();
    $fwrite(`STDERR,"---Number of Checks        %0d \n", this.AllChecks);
    $fwrite(`STDERR,"---Number of failed Checks %0d \n", this.AllChecksFail);
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- setRefTime(int time): Store Read Reference time.*/
  /////////////////////////////////////////////////////////////////////////////
  function void setRefTime(time refTime);
    this.refTime = refTime;
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- setWriteTime(int time): Store write Reference time.*/
  /////////////////////////////////////////////////////////////////////////////
  function void setWriteTime(time writeTime);
    this.writeTime = writeTime;
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- setReadTime(int time): Store read Reference time.*/
  /////////////////////////////////////////////////////////////////////////////
  function void setReadTime(time readTime);
    this.readTime = readTime;
  endfunction





endclass // Packet
endpackage
