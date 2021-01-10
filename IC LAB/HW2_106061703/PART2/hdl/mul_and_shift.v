module mul_and_shift
#(parameter DIVIDEND_WIDTH=15,WIDTH_INVERSE=8,WIDTH_SHIFT=4)
(
input [DIVIDEND_WIDTH-1:0] dividend,
input [WIDTH_INVERSE-1:0] div_inverse,
input [  WIDTH_SHIFT-1:0] div_shift,

output [DIVIDEND_WIDTH-1:0] quotient
);

wire[DIVIDEND_WIDTH+WIDTH_INVERSE-1:0] mul_out = dividend * div_inverse;
wire[DIVIDEND_WIDTH+WIDTH_INVERSE-1:0] shift_out = mul_out >> div_shift;

assign quotient = shift_out[DIVIDEND_WIDTH-1:0];
/*
always @(*) begin //if the result of the quotient is greater than 255, then clip the value to 255.
	if (quotient>255)
		quotient=255;
	else
	    quotient=quotient;
end

*/
endmodule
