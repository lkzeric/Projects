module weight //have to design the sequential circuit because of the storing register
#(parameter ORDER=7, INPUT_DATA_WIDTH=8,OUTPUT_WEIGHT_WIDTH=4,S_WIDTH=20)
(
//input clk,
//input rstn,   
//input [INPUT_DATA_WIDTH-1:0] data_in ,

input [INPUT_DATA_WIDTH-1:0] sample0,
input [INPUT_DATA_WIDTH-1:0] sample1,
input [INPUT_DATA_WIDTH-1:0] sample2,
input [INPUT_DATA_WIDTH-1:0] sample3,
input [INPUT_DATA_WIDTH-1:0] sample4,
input [INPUT_DATA_WIDTH-1:0] sample5,
input [INPUT_DATA_WIDTH-1:0] sample6,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W0,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W1,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W2,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W3,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W4,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W5,
output reg [OUTPUT_WEIGHT_WIDTH-1:0] W6
);

reg [S_WIDTH-1:0] S [ORDER-1:0];
integer k;

wire [INPUT_DATA_WIDTH-1:0] sample [ORDER-1:0];
assign sample[0]=sample0;
assign sample[1]=sample1;
assign sample[2]=sample2;
assign sample[3]=sample3;
assign sample[4]=sample4;
assign sample[5]=sample5;
assign sample[6]=sample6;


reg [OUTPUT_WEIGHT_WIDTH-1:0] W [ORDER-1:0];

always @(*) begin
	W0=W[0];
	W1=W[1];
	W2=W[2];
	W3=W[3];
	W4=W[4];
	W5=W[5];
	W6=W[6];


end

always@(*) begin
	/*
	if(rstn==0) begin

	  for(k=0;k<ORDER;k=k+1)
		sample[k]<=0;

	end
	
	else begin
	
	  sample[0]<=data_in;
	  for(i=1;i<ORDER;i=i+1)
		sample[i]<=sample[i-1];
    */

	  for(k=0;k<ORDER;k=k+1) begin
		S[k]=(sample[k]-sample[3])*(sample[k]-sample[3]);
		
		
			 if (  0<=S[k] && S[k]<=8)   W[k]=15;
		else if (  9<=S[k] && S[k]<=26)  W[k]=14;
		else if ( 27<=S[k] && S[k]<=46)  W[k]=13;
		else if ( 47<=S[k] && S[k]<=68)  W[k]=12;
		else if ( 69<=S[k] && S[k]<=91)  W[k]=11;
		else if ( 92<=S[k] && S[k]<=116) W[k]=10;
		else if (117<=S[k] && S[k]<=145) W[k]=9;
		else if (146<=S[k] && S[k]<=177) W[k]=8;
		else if (178<=S[k] && S[k]<=214) W[k]=7;	
		else if (215<=S[k] && S[k]<=256) W[k]=6;
		else if (257<=S[k] && S[k]<=308) W[k]=5;	
		else if (309<=S[k] && S[k]<=372) W[k]=4;	
		else if (373<=S[k] && S[k]<=458) W[k]=3;	
		else if (459<=S[k] && S[k]<=589) W[k]=2;	
		else if (590<=S[k] && S[k]<=870) W[k]=1;
		else 							 W[k]=0;			
	  end

	
end
endmodule





