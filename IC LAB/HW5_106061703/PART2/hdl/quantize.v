module quantize #(
    parameter PARAM_WIDTH = 4,
    parameter PARAM_NUM = 9,
    parameter DATA_WIDTH = 8,
    parameter DATA_NUM_PER_SRAM_ADDR = 4
)
(
input clk,
input rst_n,
input [3:0] state,

input [5:0] cnt_CONV1_1_BIAS,
input [5:0] cnt_weight,
input [9:0] cnt_CONV1_1,


input [5:0] cnt_CONV1_2_BIAS,
input [9:0] cnt_3D,

input [PARAM_NUM*PARAM_WIDTH-1:0] sram_rdata_param_in,


input signed [31:0] result_all,

input  signed [31:0] result_conv1_2_a_final,
input  signed [31:0] result_conv1_2_b_final,
input  signed [31:0] result_conv1_2_c_final,
input  signed [31:0] result_conv1_2_d_final,


output reg signed [7:0] q_output,

output reg signed [7:0] conv1_2_a_output,
output reg signed [7:0] conv1_2_b_output,
output reg signed [7:0] conv1_2_c_output,
output reg signed [7:0] conv1_2_d_output
);



// The following is the frational length for parameter
localparam CONV1_1_WEIGHT_FL = 3;     //the fractional width of weight in CONV1_1 is 3 bit.
localparam CONV1_2_WEIGHT_FL = 5;     //the fractional width of weight in CONV1_2 is 5 bit.

localparam CONV1_1_BIAS_FL = 5;     //the fractional width of bias in CONV1_1 is 5 bit.
localparam CONV1_2_BIAS_FL = 7;     //the fractional width of bias in CONV1_2 is 7 bit.

// The following is the frational length for Activation
localparam CONV2_DATA_IN_FL = 5;    //the fractional width of input image is 8 bit.
localparam CONV2_DATA_OUT_FL = 4;  //the fractional width of output feature map in CONV2 is 4 bit.

localparam ACT_INPUT_FRA = 8;
localparam ACT_conv1_1_fra = 6; 
localparam ACT_conv1_2_fra = 4; 
///////////////////////////////

localparam IDLE=3'd0,PREPARE=3'd1, LOAD_IMAGE=3'd2, CONV1_1_BIAS=3'd3, CONV1_1=3'd4, CONV1_2andPOOL1_BIAS=3'd5,CONV1_2andPOOL1=3'd6;



///////////   CONV1_1  ///////////
reg signed [3:0] bias [19:0];  //20 bias
reg signed [3:0] bias_n [19:0];

reg signed [3:0] bias_decided;


reg signed [31:0]conv1_1_output;
reg signed [31:0]conv1_1_output_tmp;
reg signed [7:0] q_output_n;

/////////////////////////////////

///////////   CONV1_2  //////////
reg signed [3:0] bias_2[19:0]; //20 bias
reg signed [3:0] bias_2_n[19:0];







////////////////////////////////

integer j,k;

always @(posedge clk) begin
	if(~rst_n) begin
		for (j=0;j<20;j=j+1) begin   // save the all bias value previously
			bias[j]<=0;
		end 
		
		for (k=0;k<20;k=k+1) begin   // save the all bias value previously
			bias_2[k]<=0;
		end 

	end
	else begin 
		for (j=0;j<20;j=j+1) begin
			bias[j]<=bias_n[j];
		end 
		for (k=0;k<20;k=k+1) begin  
			bias_2[k]<=bias_2_n[k];
		end 

	end
end

always @(*) begin
    for (j=0;j<20;j=j+1) begin
				bias_n[j]=bias[j];
	end
	if (state==CONV1_1_BIAS) begin
		if (cnt_CONV1_1_BIAS==3) bias_n[0]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_1_BIAS==4) bias_n[1]=sram_rdata_param_in[31:28];
		else if (cnt_CONV1_1_BIAS==5) bias_n[2]=sram_rdata_param_in[27:24];
		else if (cnt_CONV1_1_BIAS==6) bias_n[3]=sram_rdata_param_in[23:20];
		else if (cnt_CONV1_1_BIAS==7) bias_n[4]=sram_rdata_param_in[19:16];
		else if (cnt_CONV1_1_BIAS==8) bias_n[5]=sram_rdata_param_in[15:12];
		else if (cnt_CONV1_1_BIAS==9) bias_n[6]=sram_rdata_param_in[11:8];
		else if (cnt_CONV1_1_BIAS==10) bias_n[7]=sram_rdata_param_in[7:4];
		else if (cnt_CONV1_1_BIAS==11) bias_n[8]=sram_rdata_param_in[3:0];
		else if (cnt_CONV1_1_BIAS==12) bias_n[9]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_1_BIAS==13) bias_n[10]=sram_rdata_param_in[31:28];
		else if (cnt_CONV1_1_BIAS==14) bias_n[11]=sram_rdata_param_in[27:24];
		else if (cnt_CONV1_1_BIAS==15) bias_n[12]=sram_rdata_param_in[23:20];
		else if (cnt_CONV1_1_BIAS==16) bias_n[13]=sram_rdata_param_in[19:16];
		else if (cnt_CONV1_1_BIAS==17) bias_n[14]=sram_rdata_param_in[15:12];
		else if (cnt_CONV1_1_BIAS==18) bias_n[15]=sram_rdata_param_in[11:8];
		else if (cnt_CONV1_1_BIAS==19) bias_n[16]=sram_rdata_param_in[7:4];
		else if (cnt_CONV1_1_BIAS==20) bias_n[17]=sram_rdata_param_in[3:0];
		else if (cnt_CONV1_1_BIAS==21) bias_n[18]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_1_BIAS==22) bias_n[19]=sram_rdata_param_in[31:28];
		
		else begin 
			for (j=0;j<20;j=j+1) begin
				bias_n[j]=bias[j];
			end
		end
	end
	
	else begin
		for (j=0;j<20;j=j+1) begin
			bias_n[j]=bias[j];
		end
	
	end
end


always @(*) begin
    
	for (j=0;j<20;j=j+1) begin
				bias_2_n[j]=bias_2[j];
	end
	
	if (state==CONV1_2andPOOL1_BIAS) begin
		if (cnt_CONV1_2_BIAS==3) bias_2_n[0]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_2_BIAS==4) bias_2_n[1]=sram_rdata_param_in[31:28];
		else if (cnt_CONV1_2_BIAS==5) bias_2_n[2]=sram_rdata_param_in[27:24];
		else if (cnt_CONV1_2_BIAS==6) bias_2_n[3]=sram_rdata_param_in[23:20];
		else if (cnt_CONV1_2_BIAS==7) bias_2_n[4]=sram_rdata_param_in[19:16];
		else if (cnt_CONV1_2_BIAS==8) bias_2_n[5]=sram_rdata_param_in[15:12];
		else if (cnt_CONV1_2_BIAS==9) bias_2_n[6]=sram_rdata_param_in[11:8];
		else if (cnt_CONV1_2_BIAS==10) bias_2_n[7]=sram_rdata_param_in[7:4];
		else if (cnt_CONV1_2_BIAS==11) bias_2_n[8]=sram_rdata_param_in[3:0];
		else if (cnt_CONV1_2_BIAS==12) bias_2_n[9]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_2_BIAS==13) bias_2_n[10]=sram_rdata_param_in[31:28];
		else if (cnt_CONV1_2_BIAS==14) bias_2_n[11]=sram_rdata_param_in[27:24];
		else if (cnt_CONV1_2_BIAS==15) bias_2_n[12]=sram_rdata_param_in[23:20];
		else if (cnt_CONV1_2_BIAS==16) bias_2_n[13]=sram_rdata_param_in[19:16];
		else if (cnt_CONV1_2_BIAS==17) bias_2_n[14]=sram_rdata_param_in[15:12];
		else if (cnt_CONV1_2_BIAS==18) bias_2_n[15]=sram_rdata_param_in[11:8];
		else if (cnt_CONV1_2_BIAS==19) bias_2_n[16]=sram_rdata_param_in[7:4];
		else if (cnt_CONV1_2_BIAS==20) bias_2_n[17]=sram_rdata_param_in[3:0];
		else if (cnt_CONV1_2_BIAS==21) bias_2_n[18]=sram_rdata_param_in[35:32];
		else if (cnt_CONV1_2_BIAS==22) bias_2_n[19]=sram_rdata_param_in[31:28];
		
		else begin 
			for (j=0;j<20;j=j+1) begin
				bias_2_n[j]=bias_2[j];
			end
		end
	end
	
	else begin
		for (j=0;j<20;j=j+1) begin
			bias_2_n[j]=bias_2[j];
		end
	
	end
end




////////////////////////////////

always @(*) begin
	if (state==CONV1_1) begin
		if (cnt_weight==0) bias_decided=bias[0];
		else if (cnt_weight==1) bias_decided=bias[1];
		else if (cnt_weight==2) bias_decided=bias[2];
		else if (cnt_weight==3) bias_decided=bias[3];
		else if (cnt_weight==4) bias_decided=bias[4];
		else if (cnt_weight==5) bias_decided=bias[5];
		else if (cnt_weight==6) bias_decided=bias[6];
		else if (cnt_weight==7) bias_decided=bias[7];
		else if (cnt_weight==8) bias_decided=bias[8];
		else if (cnt_weight==9) bias_decided=bias[9];
		else if (cnt_weight==10) bias_decided=bias[10];
		else if (cnt_weight==11) bias_decided=bias[11];
		else if (cnt_weight==12) bias_decided=bias[12];
		else if (cnt_weight==13) bias_decided=bias[13];
		else if (cnt_weight==14) bias_decided=bias[14];
		else if (cnt_weight==15) bias_decided=bias[15];
		else if (cnt_weight==16) bias_decided=bias[16];
		else if (cnt_weight==17) bias_decided=bias[17];
		else if (cnt_weight==18) bias_decided=bias[18];
		else if (cnt_weight==19) bias_decided=bias[19];
		else bias_decided=0;
	end
	else bias_decided=0;
	
end

////////////////////////////////


always @(posedge clk) begin
	if (~rst_n) begin
		q_output<=0;
	end
	else begin
		q_output<=q_output_n;
	end

end



reg [31:0] bias_decided_shift;


always @(*) begin
	if (state==CONV1_1 && cnt_CONV1_1>5) begin	
		bias_decided_shift=bias_decided<<6;
		
		conv1_1_output_tmp=result_all+(bias_decided_shift)+16;
		conv1_1_output=conv1_1_output_tmp>>>5;
		
		if (conv1_1_output>=127) q_output_n=127;
		else if (conv1_1_output<0) q_output_n=0;
		else q_output_n= conv1_1_output[7:0];
 
	end
	else begin
		q_output_n=0;conv1_1_output=0;conv1_1_output_tmp=0; bias_decided_shift=0;
	end
end

//////////////////////////////////  TEST for channel 0 /////////////////////////////////


reg signed [31:0] a;
reg signed [31:0] b;
reg signed [31:0] c;
reg signed [31:0] d;

reg signed [31:0] a_tmp;
reg signed [31:0] b_tmp;
reg signed [31:0] c_tmp;
reg signed [31:0] d_tmp;




reg [31:0] bias_2_shift;

always @(*) begin
	if(state==CONV1_2andPOOL1 ) begin
		bias_2_shift=bias_2[cnt_3D]<<4;
		
		a_tmp=result_conv1_2_a_final+bias_2_shift+64;
		a=a_tmp>>>7;
		
		
		
		if (a>127) conv1_2_a_output=127;
		else if (a<0) conv1_2_a_output=0;
		else conv1_2_a_output=a[7:0];
	end
	else begin
		conv1_2_a_output=0;a=0;a_tmp=0;bias_2_shift=0;
	end	
end


always @(*) begin
	if(state==CONV1_2andPOOL1 ) begin
		bias_2_shift=bias_2[cnt_3D]<<4;
	
		b_tmp=result_conv1_2_b_final+bias_2_shift+64;
		b=b_tmp>>>7;
		
		if (b>127) conv1_2_b_output=127;
		else if (b<0) conv1_2_b_output=0;
		else conv1_2_b_output=b[7:0];
	end
	else begin
		conv1_2_b_output=0; b=0;b_tmp=0;bias_2_shift=0;	
	end
	
end


always @(*) begin
	if(state==CONV1_2andPOOL1 ) begin
		bias_2_shift=bias_2[cnt_3D]<<4;
	
		c_tmp=result_conv1_2_c_final+bias_2_shift+64;
		c=c_tmp>>>7;
		
		if (c>127) conv1_2_c_output=127;
		else if (c<0) conv1_2_c_output=0;
		else conv1_2_c_output=c[7:0];
	end
	else begin
		conv1_2_c_output=0;  c=0; c_tmp=0;bias_2_shift=0;	
	end	
end


always @(*) begin
	if(state==CONV1_2andPOOL1 ) begin
		bias_2_shift=bias_2[cnt_3D]<<4;
	
		d_tmp=result_conv1_2_d_final+bias_2_shift+64;
		d=d_tmp>>>7;
		
		if (d>127) conv1_2_d_output=127;
		else if (d<0) conv1_2_d_output=0;
		else conv1_2_d_output=d[7:0];
	end
	else begin
		conv1_2_d_output=0; d=0; d_tmp=0; bias_2_shift=0;
	end
end





/////////////////////////////




endmodule






