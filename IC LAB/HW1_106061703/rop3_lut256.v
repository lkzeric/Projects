/*
* Module      : rop3_lut256
* Description : Implement this module using the look-up table (LUT) 
*               This module should support all the possible modes of ROP3.
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the output to be a register
*/

module rop3_lut256
#(
  parameter N = 4
)
(
  input clk,
  input [N-1:0] P,
  input [N-1:0] S,
  input [N-1:0] D,
  input [7:0] Mode,
  output reg [N-1:0] Result
);

reg [N-1:0] Result_;

wire [N-1:0] a;
wire [N-1:0] b;
wire [N-1:0] c;
wire [N-1:0] d;
wire [N-1:0] e;
wire [N-1:0] f;
wire [N-1:0] g;
wire [N-1:0] h;

assign a=~P&~S&~D;
assign b=~P&~S& D;
assign c=~P& S&~D;
assign d=~P& S& D;
assign e= P&~S&~D;
assign f= P&~S& D;
assign g= P& S&~D;
assign h= P& S& D;




always @(*) begin
	case(Mode)
		8'h00: Result_={N{1'b0}};
		8'h01: Result_=a;
		8'h02: Result_=b;
		8'h03: Result_=b|a;
		8'h04: Result_=c;
		8'h05: Result_=c|a;
		8'h06: Result_=c|b;
		8'h07: Result_=c|a|b;
		8'h08: Result_=d;
		8'h09: Result_=d|a;
		8'h0A: Result_=d|b;
		8'h0B: Result_=d|b|a;
		8'h0C: Result_=d|c;
		8'h0D: Result_=d|c|a;
		8'h0E: Result_=d|c|b;
		8'h0F: Result_=d|c|a|b;
		
		8'h10: Result_=e;
		8'h11: Result_=e|a;
		8'h12: Result_=e|b;
		8'h13: Result_=e|b|a;
		8'h14: Result_=e|c;
		8'h15: Result_=e|c|a;
		8'h16: Result_=e|c|b;
		8'h17: Result_=e|c|a|b;
		8'h18: Result_=e|d;
		8'h19: Result_=e|d|a;
		8'h1A: Result_=e|d|b;
		8'h1B: Result_=e|d|b|a;
		8'h1C: Result_=e|d|c;
		8'h1D: Result_=e|d|c|a;
		8'h1E: Result_=e|d|c|b;
		8'h1F: Result_=e|d|c|a|b;
		
		8'h20: Result_=f;
		8'h21: Result_=f|a;
		8'h22: Result_=f|b;
		8'h23: Result_=f|b|a;
		8'h24: Result_=f|c;
		8'h25: Result_=f|c|a;
		8'h26: Result_=f|c|b;
		8'h27: Result_=f|c|a|b;
		8'h28: Result_=f|d;
		8'h29: Result_=f|d|a;
		8'h2A: Result_=f|d|b;
		8'h2B: Result_=f|d|b|a;
		8'h2C: Result_=f|d|c;
		8'h2D: Result_=f|d|c|a;
		8'h2E: Result_=f|d|c|b;
		8'h2F: Result_=f|d|c|a|b;

		8'h30: Result_=e|f;
		8'h31: Result_=e|f|a;
		8'h32: Result_=e|f|b;
		8'h33: Result_=e|f|b|a;
		8'h34: Result_=e|f|c;
		8'h35: Result_=e|f|c|a;
		8'h36: Result_=e|f|c|b;
		8'h37: Result_=e|f|c|a|b;
		8'h38: Result_=e|f|d;
		8'h39: Result_=e|f|d|a;
		8'h3A: Result_=e|f|d|b;
		8'h3B: Result_=e|f|d|b|a;
		8'h3C: Result_=e|f|d|c;
		8'h3D: Result_=e|f|d|c|a;
		8'h3E: Result_=e|f|d|c|b;
		8'h3F: Result_=e|f|d|c|a|b;
		
		8'h40: Result_=g;
		8'h41: Result_=g|a;
		8'h42: Result_=g|b;
		8'h43: Result_=g|b|a;
		8'h44: Result_=g|c;
		8'h45: Result_=g|c|a;
		8'h46: Result_=g|c|b;
		8'h47: Result_=g|c|a|b;
		8'h48: Result_=g|d;
		8'h49: Result_=g|d|a;
		8'h4A: Result_=g|d|b;
		8'h4B: Result_=g|d|b|a;
		8'h4C: Result_=g|d|c;
		8'h4D: Result_=g|d|c|a;
		8'h4E: Result_=g|d|c|b;
		8'h4F: Result_=g|d|c|a|b;

		8'h50: Result_=e|g;
		8'h51: Result_=e|g|a;
		8'h52: Result_=e|g|b;
		8'h53: Result_=e|g|b|a;
		8'h54: Result_=e|g|c;
		8'h55: Result_=e|g|c|a;
		8'h56: Result_=e|g|c|b;
		8'h57: Result_=e|g|c|a|b;
		8'h58: Result_=e|g|d;
		8'h59: Result_=e|g|d|a;
		8'h5A: Result_=e|g|d|b;
		8'h5B: Result_=e|g|d|b|a;
		8'h5C: Result_=e|g|d|c;
		8'h5D: Result_=e|g|d|c|a;
		8'h5E: Result_=e|g|d|c|b;
		8'h5F: Result_=e|g|d|c|a|b;

		8'h60: Result_=f|g;
		8'h61: Result_=f|g|a;
		8'h62: Result_=f|g|b;
		8'h63: Result_=f|g|b|a;
		8'h64: Result_=f|g|c;
		8'h65: Result_=f|g|c|a;
		8'h66: Result_=f|g|c|b;
		8'h67: Result_=f|g|c|a|b;
		8'h68: Result_=f|g|d;
		8'h69: Result_=f|g|d|a;
		8'h6A: Result_=f|g|d|b;
		8'h6B: Result_=f|g|d|b|a;
		8'h6C: Result_=f|g|d|c;
		8'h6D: Result_=f|g|d|c|a;
		8'h6E: Result_=f|g|d|c|b;
		8'h6F: Result_=f|g|d|c|a|b;

		8'h70: Result_=e|f|g;
		8'h71: Result_=e|f|g|a;
		8'h72: Result_=e|f|g|b;
		8'h73: Result_=e|f|g|b|a;
		8'h74: Result_=e|f|g|c;
		8'h75: Result_=e|f|g|c|a;
		8'h76: Result_=e|f|g|c|b;
		8'h77: Result_=e|f|g|c|a|b;
		8'h78: Result_=e|f|g|d;
		8'h79: Result_=e|f|g|d|a;
		8'h7A: Result_=e|f|g|d|b;
		8'h7B: Result_=e|f|g|d|b|a;
		8'h7C: Result_=e|f|g|d|c;
		8'h7D: Result_=e|f|g|d|c|a;
		8'h7E: Result_=e|f|g|d|c|b;
		8'h7F: Result_=e|f|g|d|c|a|b;

		8'h80: Result_=h;
		8'h81: Result_=h|a;
		8'h82: Result_=h|b;
		8'h83: Result_=h|b|a;
		8'h84: Result_=h|c;
		8'h85: Result_=h|c|a;
		8'h86: Result_=h|c|b;
		8'h87: Result_=h|c|a|b;
		8'h88: Result_=h|d;
		8'h89: Result_=h|d|a;
		8'h8A: Result_=h|d|b;
		8'h8B: Result_=h|d|b|a;
		8'h8C: Result_=h|d|c;
		8'h8D: Result_=h|d|c|a;
		8'h8E: Result_=h|d|c|b;
		8'h8F: Result_=h|d|c|a|b;

		8'h90: Result_=h|e;
		8'h91: Result_=h|e|a;
		8'h92: Result_=h|e|b;
		8'h93: Result_=h|e|b|a;
		8'h94: Result_=h|e|c;
		8'h95: Result_=h|e|c|a;
		8'h96: Result_=h|e|c|b;
		8'h97: Result_=h|e|c|a|b;
		8'h98: Result_=h|e|d;
		8'h99: Result_=h|e|d|a;
		8'h9A: Result_=h|e|d|b;
		8'h9B: Result_=h|e|d|b|a;
		8'h9C: Result_=h|e|d|c;
		8'h9D: Result_=h|e|d|c|a;
		8'h9E: Result_=h|e|d|c|b;
		8'h9F: Result_=h|e|d|c|a|b;

		8'hA0: Result_=h|f;
		8'hA1: Result_=h|f|a;
		8'hA2: Result_=h|f|b;
		8'hA3: Result_=h|f|b|a;
		8'hA4: Result_=h|f|c;
		8'hA5: Result_=h|f|c|a;
		8'hA6: Result_=h|f|c|b;
		8'hA7: Result_=h|f|c|a|b;
		8'hA8: Result_=h|f|d;
		8'hA9: Result_=h|f|d|a;
		8'hAA: Result_=h|f|d|b;
		8'hAB: Result_=h|f|d|b|a;
		8'hAC: Result_=h|f|d|c;
		8'hAD: Result_=h|f|d|c|a;
		8'hAE: Result_=h|f|d|c|b;
		8'hAF: Result_=h|f|d|c|a|b;

		8'hB0: Result_=h|e|f;
		8'hB1: Result_=h|e|f|a;
		8'hB2: Result_=h|e|f|b;
		8'hB3: Result_=h|e|f|b|a;
		8'hB4: Result_=h|e|f|c;
		8'hB5: Result_=h|e|f|c|a;
		8'hB6: Result_=h|e|f|c|b;
		8'hB7: Result_=h|e|f|c|a|b;
		8'hB8: Result_=h|e|f|d;
		8'hB9: Result_=h|e|f|d|a;
		8'hBA: Result_=h|e|f|d|b;
		8'hBB: Result_=h|e|f|d|b|a;
		8'hBC: Result_=h|e|f|d|c;
		8'hBD: Result_=h|e|f|d|c|a;
		8'hBE: Result_=h|e|f|d|c|b;
		8'hBF: Result_=h|e|f|d|c|a|b;

		8'hC0: Result_=g|h;
		8'hC1: Result_=g|h|a;
		8'hC2: Result_=g|h|b;
		8'hC3: Result_=g|h|b|a;
		8'hC4: Result_=g|h|c;
		8'hC5: Result_=g|h|c|a;
		8'hC6: Result_=g|h|c|b;
		8'hC7: Result_=g|h|c|a|b;
		8'hC8: Result_=g|h|d;
		8'hC9: Result_=g|h|d|a;
		8'hCA: Result_=g|h|d|b;
		8'hCB: Result_=g|h|d|b|a;
		8'hCC: Result_=g|h|d|c;
		8'hCD: Result_=g|h|d|c|a;
		8'hCE: Result_=g|h|d|c|b;
		8'hCF: Result_=g|h|d|c|a|b;	
		
		8'hD0: Result_=e|g|h;
		8'hD1: Result_=e|g|h|a;
		8'hD2: Result_=e|g|h|b;
		8'hD3: Result_=e|g|h|b|a;
		8'hD4: Result_=e|g|h|c;
		8'hD5: Result_=e|g|h|c|a;
		8'hD6: Result_=e|g|h|c|b;
		8'hD7: Result_=e|g|h|c|a|b;
		8'hD8: Result_=e|g|h|d;
		8'hD9: Result_=e|g|h|d|a;
		8'hDA: Result_=e|g|h|d|b;
		8'hDB: Result_=e|g|h|d|b|a;
		8'hDC: Result_=e|g|h|d|c;
		8'hDD: Result_=e|g|h|d|c|a;
		8'hDE: Result_=e|g|h|d|c|b;
		8'hDF: Result_=e|g|h|d|c|a|b;
		
		8'hE0: Result_=f|g|h;
		8'hE1: Result_=f|g|h|a;
		8'hE2: Result_=f|g|h|b;
		8'hE3: Result_=f|g|h|b|a;
		8'hE4: Result_=f|g|h|c;
		8'hE5: Result_=f|g|h|c|a;
		8'hE6: Result_=f|g|h|c|b;
		8'hE7: Result_=f|g|h|c|a|b;
		8'hE8: Result_=f|g|h|d;
		8'hE9: Result_=f|g|h|d|a;
		8'hEA: Result_=f|g|h|d|b;
		8'hEB: Result_=f|g|h|d|b|a;
		8'hEC: Result_=f|g|h|d|c;
		8'hED: Result_=f|g|h|d|c|a;
		8'hEE: Result_=f|g|h|d|c|b;
		8'hEF: Result_=f|g|h|d|c|a|b;
		
		8'hF0: Result_=e|f|g|h;
		8'hF1: Result_=e|f|g|h|a;
		8'hF2: Result_=e|f|g|h|b;
		8'hF3: Result_=e|f|g|h|b|a;
		8'hF4: Result_=e|f|g|h|c;
		8'hF5: Result_=e|f|g|h|c|a;
		8'hF6: Result_=e|f|g|h|c|b;
		8'hF7: Result_=e|f|g|h|c|a|b;
		8'hF8: Result_=e|f|g|h|d;
		8'hF9: Result_=e|f|g|h|d|a;
		8'hFA: Result_=e|f|g|h|d|b;
		8'hFB: Result_=e|f|g|h|d|b|a;
		8'hFC: Result_=e|f|g|h|d|c;
		8'hFD: Result_=e|f|g|h|d|c|a;
		8'hFE: Result_=e|f|g|h|d|c|b;
		8'hFF: Result_=e|f|g|h|d|c|a|b;
		

				
	endcase
	
end

always @(posedge clk) begin
	Result <= Result_;
end

endmodule