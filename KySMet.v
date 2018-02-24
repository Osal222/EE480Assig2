// basic sizes of things
`define WORD	[15:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]
`define STATE	[4:0]
`define REGSIZE [63:0]
`define MEMSIZE [65535:0]

// opcode values, also state numbers
`define trap	16'b0000000000000000
`define ret	16'b0000000000000001
`define pushen	16'b0000000000000010
`define popen	16'b0000000000000100
`define allen	16'b0000000000001000
`define call	16'b0001000000000000
`define jump 	16'b0001000000000001
`define jumpf	16'b0001xxxx00000011
`define lnot 	16'b0010xxxxxxxx0000
`define jumpf	16'b0001xxxx00000011

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `WORD regfile `REGSIZE;
reg `WORD mainmem `MEMSIZE;
reg `WORD pc = 0;
reg `WORD ir;
reg `STATE s = `Start;
integer a;

always @(reset) begin
  halt = 0;
  pc = 0;
  s = `Start;
  $readmemh0(regfile);
  $readmemh1(mainmem);
end

always @(posedge clk) begin
  case (s)
    `Start: begin ir <= mainmem[pc]; s <= `Start1; end
    `Start1: begin
             pc <= pc + 1;            // bump pc
	     case (ir `Opcode)
	     `OPjzsz:
                case (ir `Src)	      // use Src as extended opcode
                `SRCsys: s <= `OPsys; // sys call
                `SRCsz: s <= `OPsz;   // sz
                default: s <= `OPjz;  // jz
	     endcase
             default: s <= ir `Opcode; // most instructions, state # is opcode
	     endcase
	    end

    `OPadd: begin regfile[ir `Dest] <= regfile[ir `Dest] + regfile[ir `Src]; s <= `Start; end
    `OPand: begin regfile[ir `Dest] <= regfile[ir `Dest] & regfile[ir `Src]; s <= `Start; end
    `OPany: begin regfile[ir `Dest] <= |regfile[ir `Src]; s <= `Start; end
    `OPdup: begin regfile[ir `Dest] <= regfile[ir `Src]; s <= `Start; end
    `OPjz: begin if (regfile[ir `Dest] == 0) pc <= regfile[ir `Src]; s <= `Start; end
    `OPld: begin regfile[ir `Dest] <= mainmem[regfile[ir `Src]]; s <= `Start; end
    `OPli: begin regfile[ir `Dest] <= mainmem[pc]; pc <= pc + 1; s <= `Start; end
    `OPor: begin regfile[ir `Dest] <= regfile[ir `Dest] | regfile[ir `Src]; s <= `Start; end
    `OPsz: begin if (regfile[ir `Dest] == 0) pc <= pc + 1; s <= `Start; end
    `OPshr: begin regfile[ir `Dest] <= regfile[ir `Src] >> 1; s <= `Start; end
    `OPst: begin mainmem[regfile[ir `Src]] <= regfile[ir `Dest]; s <= `Start; end
    `OPxor: begin regfile[ir `Dest] <= regfile[ir `Dest] ^ regfile[ir `Src]; s <= `Start; end

    default: halt <= 1;
  endcase
end
endmodule
