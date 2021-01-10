/*
* Module      : rop3_lut16
* Description : Implement this module using the look-up table (LUT) 
*               This module should support all the 15-modes listed in table-1
*               For modes not in the table-1, set the Result to 0
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the output to be a register
*/

module rop3_lut16
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

always @(*) begin
	case(Mode)
		8'h00: Result_={N{1'b0}};
		8'h11: Result_=~(D|S);
		8'h33: Result_=~S;
		8'h44: Result_=S&~D;
		8'h55: Result_=~D; 
		8'h5A: Result_=D^P;
		8'h66: Result_=D^S;
		8'h88: Result_=D&S;
		8'hBB: Result_=D|~S;
		8'hC0: Result_=P&S;
		8'hCC: Result_=S;
		8'hEE: Result_=D|S;
		8'hF0: Result_=P;
		8'hFB: Result_=D|P|~S;
		8'hFF: Result_={N{1'b1}};
		default: Result_=0;
	endcase
	
end

always @(posedge clk) begin
	Result <= Result_;
end


endmodule