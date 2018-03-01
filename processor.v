`define WORD      [15:0]
`define REGSIZE   [15:0]
`define MEMSIZE   [65535:0]
`define CALLSIZE  [63:0]
`define ENSIZE    [31:0]
`define STATE     [4:0]
`define OPCODE    [15:12]
`define SECOP     [3:0]
`define DEST      [11:8]
`define SRC       [7:4]
`define IMMED     [7:0]

// State numbers for instructions with unique opcodes
`define OPadd    4'b0001
`define OPand    4'b0010
`define OPmul    4'b0011
`define OPor     4'b0100
`define OPsll    4'b0101
`define OPslt    4'b0110
`define OPsra    4'b0111
`define OPxor    4'b1000
`define OPli8    4'b1001
`define OPlu8    4'b1010
`define OPcall   4'b1100
`define OPjump   4'b1101
`define OPjumpf  4'b1110

// 5 bit states for other instructions
`define OPnoarg  4'b0000
`define OPtwoarg 4'b1011
`define OPtrap   5'b10000
`define OPret    5'b10001
`define OPallen  5'b10010
`define OPpopen  5'b10011
`define OPpushen 5'b10100
`define OPgor    5'b10101
`define OPleft   5'b10110
`define OPlnot   5'b10111
`define OPload   5'b11000
`define OPneg    5'b11001
`define OPright  5'b11010
`define OPstore  5'b11011

`define Start    5'b11111
`define Start1   5'b11110
`define OPjumpf2 5'b11101

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `CALLSIZE callstack = 0;
reg `ENSIZE enstack = ~0;
reg `WORD pc = 0;
reg `STATE s = `Start;
reg `WORD ir;

always @(reset) begin
  halt = 0;
  pc = 0;
  s = `Start;
  $readmemh0(regfile);
  $readmemh1(mainmem);
end

always @(posedge clk) begin
	case (s)
	    `Start:
	    	begin
	    		ir <= mainmem[pc]; s <= `Start1;
	    	end
	    `Start1:
	    	begin
	    		pc <= pc + 1;
	    		case (ir `OPCODE)
	    			`OPnoarg:
	    				s <= { 1'b1, ir `SECOP };
	    			`OPtwoarg:
	    				s <= { 1'b1, ir `SECOP };
	    			default:
	    				s <= ir `OPCODE;
	    		endcase
	    	end
	    `OPadd:
	    	begin
	    		$display("add\n");
                        regfile[ir `DEST] <= regfile[ir `SRC] + regfile[ir `SECOP];
	    		s <= `Start;
	    	end
	    `OPand:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] & regfile[ir `SECOP];
	    		s <= `Start;
	    	end
	    `OPmul:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] * regfile[ir `SECOP];
	    		s <= `Start;
	    	end
	    `OPor:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] | regfile[ir `SECOP];
	    		s <= `Start;
	    	end
	    `OPsll:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] << (regfile[ir `SECOP] & 15);
	    		s <= `Start;
	    	end
	    `OPslt:
	    	begin
	    		regfile[ir `DEST] <= (regfile[ir `SRC] < regfile[ir `SECOP]);
	    		s <= `Start;
	    	end
	    `OPsra:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] >> (regfile[ir `SECOP] & 15);
	    		s <= `Start;
	    	end
	    `OPxor:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC] ^ regfile[ir `SECOP];
	    		s <= `Start;
	    	end
	    `OPli8:
	    	begin
	    		regfile[ir `DEST] <= { {8{ir `IMMED}}, ir `IMMED };
	    		s <= `Start;
	    	end
	    `OPlu8:
	    	begin
	    		regfile[ir `DEST] <= (regfile[ir `DEST] & 255) | (ir `IMMED << 8);
	    		s <= `Start;
	    	end
	    `OPgor:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC];
	    		s <= `Start;
	    	end
	    `OPleft:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC];
	    		s <= `Start;
	    	end
	    `OPlnot:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC];
	    		s <= `Start;
	    	end
	    `OPload:
	    	begin
	    		regfile[ir `DEST] <= mainmem[regfile[ir `SRC]];
	    		s <= `Start;
	    	end
	    `OPneg:
	    	begin
	    		regfile[ir `DEST] <= -regfile[ir `SRC];
	    		s <= `Start;
	    	end
	    `OPright:
	    	begin
	    		regfile[ir `DEST] <= regfile[ir `SRC];
	    		s <= `Start;
	    	end
	    `OPstore:
	    	begin
	    		mainmem[regfile[ir `SRC]] <= regfile[ir `DEST];
	    		s <= `Start;
	    	end
	    `OPcall:
	    	begin
	    		if (enstack[0] == 1)
	    			begin
	    				callstack <= { callstack[47:0], pc };
	    				pc <= mainmem[pc];
	    			end
	    		s <= `Start;
	    	end
	    `OPjump:
	    	begin
	    		pc <= mainmem[pc];
	    		s <= `Start;
	    	end
	    `OPjumpf:
	    	begin
	    		if (regfile[ir `DEST] == 0) enstack <= (enstack & ~1);
	    		s <= `OPjumpf2;
	    	end
	    `OPjumpf2:
	    	begin
	    		if (enstack[0] == 0) pc <= mainmem[pc];
	    		s <= `Start;
	    	end
	    `OPtrap:
	    	begin
                $display("trap\n");
	    		halt <= 1;
	    	end
	    `OPret:
	    	begin
	    		if (enstack[0] == 1)
	    			begin
	    				pc <= callstack[15:0];
	    				callstack <= callstack >> 16;
	    			end
	    		s <= `Start;
	    	end
	    `OPallen:
	    	begin
	    		enstack <= (enstack | 1);
	    		s <= `Start;
	    	end
	    `OPpopen:
	    	begin
	    		enstack <= (enstack >> 1);
	    		s <= `Start;
	    	end
	    `OPpushen:
	    	begin
	    		enstack <= ((enstack << 1) | (enstack & 1));
	    		s <= `Start;
	    	end
	    default: halt <= 1;
	endcase
end
endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
  $dumpfile;
  $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
