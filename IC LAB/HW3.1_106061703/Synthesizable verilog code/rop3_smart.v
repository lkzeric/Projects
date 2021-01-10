/*
* Module      : rop3_smart
* Description : Implement this module using the bit-hack technique mentioned in the assignment handout.
*               This module should support all the possible modes of ROP3.
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the output to be a register
*/

module rop3_smart
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
reg [7:0] temp1 , temp2;


always @(*) begin :for_loop
	integer i;
	for (i=0;i<N;i=i+1)
		begin
			temp1[7:0]=8'h1<<{P[i],S[i],D[i]};
			temp2[7:0]=temp1[7:0] & Mode[7:0];
			Result_[i]= |temp2[7:0];
		end	


end

always @(posedge clk) begin
 
		Result <= Result_;

end

endmodule