module convolution #(
    parameter PARAM_WIDTH = 4,
    parameter PARAM_NUM = 9,
    parameter DATA_WIDTH = 8,
    parameter DATA_NUM_PER_SRAM_ADDR = 4
)
(
input clk,
input rst_n,
input [3:0] state,

input [9:0] cnt_CONV1_1,
input [20:0] cnt_CONV1_1_data,
input [2:0] type_data,

input [31:0] cnt_CONV1_2,
input [31:0] cnt_CONV1_2_data,
input [2:0] type_data_conv1_2,

input [31:0] cnt_CONV1_2_data_new,

input [PARAM_NUM*PARAM_WIDTH-1:0] sram_rdata_param_in,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a0_in,  //32 bits
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a1_in,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a2_in,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a3_in,

input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b0_in,  //32 bits
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b1_in,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b2_in,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b3_in,


output reg signed [31:0] result_all,

output reg signed [31:0] result_conv1_2_a_final,
output reg signed [31:0] result_conv1_2_b_final,
output reg signed [31:0] result_conv1_2_c_final,
output reg signed [31:0] result_conv1_2_d_final
);


localparam IDLE=3'd0,PREPARE=3'd1, LOAD_IMAGE=3'd2, CONV1_1_BIAS=3'd3, CONV1_1=3'd4, CONV1_2andPOOL1_BIAS=3'd5,CONV1_2andPOOL1=3'd6;

//////////  CONV1_1 ////////////
//wire [5:0] cnt_weight_1_2;
//assign cnt_weight_1_2=cnt_CONV1_2_data%20;

reg signed [3:0] weight   [8:0]; //9 elements, 4 bits/element
reg signed [3:0] weight_n [8:0];

reg signed [7:0] data_window [15:0]; // 16 elements, 8 bits/element
reg signed [7:0] data_window_n [15:0]; // 16 elements, 8 bits/element

reg signed [7:0] D [0:8];
reg signed [7:0] D_n [0:8];

wire signed [11:0] weight_result [0:8]; // weight*data_window
wire signed [31:0] result ;

reg signed [31:0] result_1,result_2,result_3 ;
reg signed [31:0] result_1_n,result_2_n,result_3_n ;

//reg signed [31:0] result_all;
reg signed [31:0] result_all_n;



/////////// CONV1_2 //////////

reg signed [3:0] weight1_2[8:0]; 
reg signed [3:0] weight1_2_n[8:0];

reg signed [7:0] D1_2[15:0];
reg signed [7:0] D1_2_n[15:0];

reg signed [31:0] result_conv1_2_a[19:0];
reg signed [31:0] result_conv1_2_b[19:0];
reg signed [31:0] result_conv1_2_c[19:0];
reg signed [31:0] result_conv1_2_d[19:0];

//reg signed [31:0] result_conv1_2_a_final;
//reg signed [31:0] result_conv1_2_b_final;
//reg signed [31:0] result_conv1_2_c_final;
//reg signed [31:0] result_conv1_2_d_final;


///////////////////////// weight ////////////////////////
integer i,j,k,l;
always @(posedge clk) begin
	if(~rst_n) begin
		for (j=0;j<16;j=j+1) begin   
			data_window[j]<=0;
		end 
		
		for (k=0;k<9;k=k+1) begin   // save the  weight
			weight[k]<=0;
		end 
		
		
	end
	
	else begin 
		for (j=0;j<16;j=j+1) begin   
			data_window[j]<=data_window_n[j];
		end 
	
		for (k=0;k<9;k=k+1) begin   // save the weight
			weight[k]<=weight_n[k];
		end 
	end
end

always @(*) begin

	if (state==CONV1_1)	 begin
	
		weight_n[0]=sram_rdata_param_in[35:32];
		weight_n[1]=sram_rdata_param_in[31:28];
		weight_n[2]=sram_rdata_param_in[27:24];
		weight_n[3]=sram_rdata_param_in[23:20];
		weight_n[4]=sram_rdata_param_in[19:16];
		weight_n[5]=sram_rdata_param_in[15:12];
		weight_n[6]=sram_rdata_param_in[11:8];
		weight_n[7]=sram_rdata_param_in[7:4];
		weight_n[8]=sram_rdata_param_in[3:0];

	end
	else begin
		
		weight_n[0]=0;
		weight_n[1]=0;
		weight_n[2]=0;
		weight_n[3]=0;
		weight_n[4]=0;
		weight_n[5]=0;
		weight_n[6]=0;
		weight_n[7]=0;
		weight_n[8]=0;
	
	end

end


always @(*) begin
		for (i=0;i<16;i=i+1) begin
			data_window_n[i]=255;
		end
	if (state==CONV1_1) begin
		if (type_data==1) begin
			data_window_n[0]=sram_rdata_a0_in[31:24];
			data_window_n[1]=sram_rdata_a0_in[23:16];
			data_window_n[2]=sram_rdata_a1_in[31:24];
			data_window_n[3]=sram_rdata_a1_in[23:16];
			
			data_window_n[4]=sram_rdata_a0_in[15:8];
			data_window_n[5]=sram_rdata_a0_in[7:0];
			data_window_n[6]=sram_rdata_a1_in[15:8];
			data_window_n[7]=sram_rdata_a1_in[7:0];
			
			data_window_n[8]=sram_rdata_a2_in[31:24];
			data_window_n[9]=sram_rdata_a2_in[23:16];
			data_window_n[10]=sram_rdata_a3_in[31:24];
			data_window_n[11]=sram_rdata_a3_in[23:16];
			
			data_window_n[12]=sram_rdata_a2_in[15:8];
			data_window_n[13]=sram_rdata_a2_in[7:0];
			data_window_n[14]=sram_rdata_a3_in[15:8];
			data_window_n[15]=sram_rdata_a3_in[7:0];
		end
		else if(type_data==2) begin
			data_window_n[0]=sram_rdata_a1_in[31:24];
			data_window_n[1]=sram_rdata_a1_in[23:16];
			data_window_n[2]=sram_rdata_a0_in[31:24];
			data_window_n[3]=sram_rdata_a0_in[23:16];
			
			data_window_n[4]=sram_rdata_a1_in[15:8];
			data_window_n[5]=sram_rdata_a1_in[7:0];
			data_window_n[6]=sram_rdata_a0_in[15:8];
			data_window_n[7]=sram_rdata_a0_in[7:0];
			
			data_window_n[8]=sram_rdata_a3_in[31:24];
			data_window_n[9]=sram_rdata_a3_in[23:16];
			data_window_n[10]=sram_rdata_a2_in[31:24];
			data_window_n[11]=sram_rdata_a2_in[23:16];
			
			data_window_n[12]=sram_rdata_a3_in[15:8];
			data_window_n[13]=sram_rdata_a3_in[7:0];
			data_window_n[14]=sram_rdata_a2_in[15:8];
			data_window_n[15]=sram_rdata_a2_in[7:0];
		
		
		end
		
		else if(type_data==3) begin
			data_window_n[0]=sram_rdata_a2_in[31:24];
			data_window_n[1]=sram_rdata_a2_in[23:16];
			data_window_n[2]=sram_rdata_a3_in[31:24];
			data_window_n[3]=sram_rdata_a3_in[23:16];
			
			data_window_n[4]=sram_rdata_a2_in[15:8];
			data_window_n[5]=sram_rdata_a2_in[7:0];
			data_window_n[6]=sram_rdata_a3_in[15:8];
			data_window_n[7]=sram_rdata_a3_in[7:0];
			
			data_window_n[8]=sram_rdata_a0_in[31:24];
			data_window_n[9]=sram_rdata_a0_in[23:16];
			data_window_n[10]=sram_rdata_a1_in[31:24];
			data_window_n[11]=sram_rdata_a1_in[23:16];
			
			data_window_n[12]=sram_rdata_a0_in[15:8];
			data_window_n[13]=sram_rdata_a0_in[7:0];
			data_window_n[14]=sram_rdata_a1_in[15:8];
			data_window_n[15]=sram_rdata_a1_in[7:0];
		
		
		end
		
		else if(type_data==4) begin
			data_window_n[0]=sram_rdata_a3_in[31:24];
			data_window_n[1]=sram_rdata_a3_in[23:16];
			data_window_n[2]=sram_rdata_a2_in[31:24];
			data_window_n[3]=sram_rdata_a2_in[23:16];
			
			data_window_n[4]=sram_rdata_a3_in[15:8];
			data_window_n[5]=sram_rdata_a3_in[7:0];
			data_window_n[6]=sram_rdata_a2_in[15:8];
			data_window_n[7]=sram_rdata_a2_in[7:0];
			
			data_window_n[8]=sram_rdata_a1_in[31:24];
			data_window_n[9]=sram_rdata_a1_in[23:16];
			data_window_n[10]=sram_rdata_a0_in[31:24];
			data_window_n[11]=sram_rdata_a0_in[23:16];
			
			data_window_n[12]=sram_rdata_a1_in[15:8];
			data_window_n[13]=sram_rdata_a1_in[7:0];
			data_window_n[14]=sram_rdata_a0_in[15:8];
			data_window_n[15]=sram_rdata_a0_in[7:0];
		
		
		end
		
		else begin
			for (i=0;i<16;i=i+1) begin
				data_window_n[i]=255;
			end
		
		end
	end
	else begin
		for (i=0;i<16;i=i+1) begin
				data_window_n[i]=255;
			end
	
	end
end

integer a;

always @(*) begin
	for(a=0;a<9;a=a+1) begin
		D[a]=0;
	end

	if (state==CONV1_1 && cnt_CONV1_1>2) begin
		if( (cnt_CONV1_1_data-1)%4==0) begin
			D[0]=data_window[0]; D[1]=data_window[1]; D[2]=data_window[2]; D[3]=data_window[4]; D[4]=data_window[5];
			D[5]=data_window[6]; D[6]=data_window[8]; D[7]=data_window[9]; D[8]=data_window[10];
		end
		else if( (cnt_CONV1_1_data-1)%4==1) begin
			D[0]=data_window[1]; D[1]=data_window[2]; D[2]=data_window[3]; D[3]=data_window[5]; D[4]=data_window[6];
			D[5]=data_window[7]; D[6]=data_window[9]; D[7]=data_window[10]; D[8]=data_window[11];
		end
		
		else if( (cnt_CONV1_1_data-1) %4==2) begin
			D[0]=data_window[4]; D[1]=data_window[5]; D[2]=data_window[6]; D[3]=data_window[8]; D[4]=data_window[9];
			D[5]=data_window[10]; D[6]=data_window[12]; D[7]=data_window[13]; D[8]=data_window[14];
				
		end
		
		else if((cnt_CONV1_1_data-1) %4==3) begin
			D[0]=data_window[5]; D[1]=data_window[6]; D[2]=data_window[7]; D[3]=data_window[9]; D[4]=data_window[10];
			D[5]=data_window[11]; D[6]=data_window[13]; D[7]=data_window[14]; D[8]=data_window[15];
		end

	end
end

always @(posedge clk) begin
	if (~rst_n) begin
		result_1<=0;
		result_2<=0;
		result_3<=0;
		result_all<=0;
	end
	else begin
		result_1<=result_1_n;
		result_2<=result_2_n;
		result_3<=result_3_n;
		result_all<=result_all_n;
	end

end


always @(*) begin
	
	result_1_n=D[0]*weight[0] + D[1]*weight[1] + D[2]*weight[2];
	result_2_n=D[3]*weight[3] + D[4]*weight[4] + D[5]*weight[5];	
	result_3_n=D[6]*weight[6] + D[7]*weight[7] + D[8]*weight[8];
end

always @(*) begin
	result_all_n=result_1+result_2+result_3;
end

//////////////////  CONV1_2 //////////////////////

integer aa,bb;



always @(posedge clk) begin
	if (~rst_n) begin 
		for (aa=0;aa<9;aa=aa+1) begin
			weight1_2[aa]<=0;
		end
		for (bb=0;bb<16;bb=bb+1) begin
			D1_2[bb]<=0;
		end
	end
	else begin
		for (aa=0;aa<9;aa=aa+1) begin
			weight1_2[aa]<=weight1_2_n[aa];
		end
		for (bb=0;bb<16;bb=bb+1) begin
			D1_2[bb]<=D1_2_n[bb];
		end
	end
end


/*

integer x;
always @(*) begin
	if (state==CONV1_2andPOOL1) begin
		weight1_2[0]=sram_rdata_param_in[35:32];
		weight1_2[1]=sram_rdata_param_in[31:28];
		weight1_2[2]=sram_rdata_param_in[27:24];
		weight1_2[3]=sram_rdata_param_in[23:20];
		weight1_2[4]=sram_rdata_param_in[19:16];
		weight1_2[5]=sram_rdata_param_in[15:12];
		weight1_2[6]=sram_rdata_param_in[11:8];
		weight1_2[7]=sram_rdata_param_in[7:4];
		weight1_2[8]=sram_rdata_param_in[3:0];
    end
	else begin
		for (x=0;x<9;x=x+1) begin
			weight1_2[x]=0;
		end
	end
end
*/

integer x;
always @(*) begin
	if (state==CONV1_2andPOOL1) begin
		weight1_2_n[0]=sram_rdata_param_in[35:32];
		weight1_2_n[1]=sram_rdata_param_in[31:28];
		weight1_2_n[2]=sram_rdata_param_in[27:24];
		weight1_2_n[3]=sram_rdata_param_in[23:20];
		weight1_2_n[4]=sram_rdata_param_in[19:16];
		weight1_2_n[5]=sram_rdata_param_in[15:12];
		weight1_2_n[6]=sram_rdata_param_in[11:8];
		weight1_2_n[7]=sram_rdata_param_in[7:4];
		weight1_2_n[8]=sram_rdata_param_in[3:0];
    end
	else begin
		for (x=0;x<9;x=x+1) begin
			weight1_2_n[x]=0;
		end
	end
end




integer b;

always @(*) begin

	for(b=0;b<16;b=b+1) begin
		D1_2_n[b]=0;
	end
	
	if (state==CONV1_2andPOOL1) begin
		if (type_data_conv1_2==1) begin
			D1_2_n[0]=sram_rdata_b0_in[31:24];
			D1_2_n[1]=sram_rdata_b0_in[23:16];
			D1_2_n[2]=sram_rdata_b1_in[31:24];
			D1_2_n[3]=sram_rdata_b1_in[23:16];
			
			D1_2_n[4]=sram_rdata_b0_in[15:8];
			D1_2_n[5]=sram_rdata_b0_in[7:0];
			D1_2_n[6]=sram_rdata_b1_in[15:8];
			D1_2_n[7]=sram_rdata_b1_in[7:0];
			
			D1_2_n[8]=sram_rdata_b2_in[31:24];
			D1_2_n[9]=sram_rdata_b2_in[23:16];
			D1_2_n[10]=sram_rdata_b3_in[31:24];
			D1_2_n[11]=sram_rdata_b3_in[23:16];
			
			D1_2_n[12]=sram_rdata_b2_in[15:8];
			D1_2_n[13]=sram_rdata_b2_in[7:0];
			D1_2_n[14]=sram_rdata_b3_in[15:8];
			D1_2_n[15]=sram_rdata_b3_in[7:0];
		end
		else if(type_data_conv1_2==2) begin
			D1_2_n[0]=sram_rdata_b1_in[31:24];
			D1_2_n[1]=sram_rdata_b1_in[23:16];
			D1_2_n[2]=sram_rdata_b0_in[31:24];
			D1_2_n[3]=sram_rdata_b0_in[23:16];
			
			D1_2_n[4]=sram_rdata_b1_in[15:8];
			D1_2_n[5]=sram_rdata_b1_in[7:0];
			D1_2_n[6]=sram_rdata_b0_in[15:8];
			D1_2_n[7]=sram_rdata_b0_in[7:0];
			
			D1_2_n[8]=sram_rdata_b3_in[31:24];
			D1_2_n[9]=sram_rdata_b3_in[23:16];
			D1_2_n[10]=sram_rdata_b2_in[31:24];
			D1_2_n[11]=sram_rdata_b2_in[23:16];
			
			D1_2_n[12]=sram_rdata_b3_in[15:8];
			D1_2_n[13]=sram_rdata_b3_in[7:0];
			D1_2_n[14]=sram_rdata_b2_in[15:8];
			D1_2_n[15]=sram_rdata_b2_in[7:0];
		
		
		end
		
		else if(type_data_conv1_2==3) begin
			D1_2_n[0]=sram_rdata_b2_in[31:24];
			D1_2_n[1]=sram_rdata_b2_in[23:16];
			D1_2_n[2]=sram_rdata_b3_in[31:24];
			D1_2_n[3]=sram_rdata_b3_in[23:16];
			
			D1_2_n[4]=sram_rdata_b2_in[15:8];
			D1_2_n[5]=sram_rdata_b2_in[7:0];
			D1_2_n[6]=sram_rdata_b3_in[15:8];
			D1_2_n[7]=sram_rdata_b3_in[7:0];
			
			D1_2_n[8]=sram_rdata_b0_in[31:24];
			D1_2_n[9]=sram_rdata_b0_in[23:16];
			D1_2_n[10]=sram_rdata_b1_in[31:24];
			D1_2_n[11]=sram_rdata_b1_in[23:16];
			
			D1_2_n[12]=sram_rdata_b0_in[15:8];
			D1_2_n[13]=sram_rdata_b0_in[7:0];
			D1_2_n[14]=sram_rdata_b1_in[15:8];
			D1_2_n[15]=sram_rdata_b1_in[7:0];
		
		
		end
		
		else if(type_data_conv1_2==4) begin
			D1_2_n[0]=sram_rdata_b3_in[31:24];
			D1_2_n[1]=sram_rdata_b3_in[23:16];
			D1_2_n[2]=sram_rdata_b2_in[31:24];
			D1_2_n[3]=sram_rdata_b2_in[23:16];
			
			D1_2_n[4]=sram_rdata_b3_in[15:8];
			D1_2_n[5]=sram_rdata_b3_in[7:0];
			D1_2_n[6]=sram_rdata_b2_in[15:8];
			D1_2_n[7]=sram_rdata_b2_in[7:0];
			
			D1_2_n[8]=sram_rdata_b1_in[31:24];
			D1_2_n[9]=sram_rdata_b1_in[23:16];
			D1_2_n[10]=sram_rdata_b0_in[31:24];
			D1_2_n[11]=sram_rdata_b0_in[23:16];
			
			D1_2_n[12]=sram_rdata_b1_in[15:8];
			D1_2_n[13]=sram_rdata_b1_in[7:0];
			D1_2_n[14]=sram_rdata_b0_in[15:8];
			D1_2_n[15]=sram_rdata_b0_in[7:0];
		
		
		end
		


	end
	
end









/*

integer b;

always @(*) begin

	for(b=0;b<16;b=b+1) begin
		D1_2[b]=0;
	end
	
	if (state==CONV1_2andPOOL1) begin
		if (type_data_conv1_2==1) begin
			D1_2[0]=sram_rdata_b0_in[31:24];
			D1_2[1]=sram_rdata_b0_in[23:16];
			D1_2[2]=sram_rdata_b1_in[31:24];
			D1_2[3]=sram_rdata_b1_in[23:16];
			
			D1_2[4]=sram_rdata_b0_in[15:8];
			D1_2[5]=sram_rdata_b0_in[7:0];
			D1_2[6]=sram_rdata_b1_in[15:8];
			D1_2[7]=sram_rdata_b1_in[7:0];
			
			D1_2[8]=sram_rdata_b2_in[31:24];
			D1_2[9]=sram_rdata_b2_in[23:16];
			D1_2[10]=sram_rdata_b3_in[31:24];
			D1_2[11]=sram_rdata_b3_in[23:16];
			
			D1_2[12]=sram_rdata_b2_in[15:8];
			D1_2[13]=sram_rdata_b2_in[7:0];
			D1_2[14]=sram_rdata_b3_in[15:8];
			D1_2[15]=sram_rdata_b3_in[7:0];
		end
		else if(type_data_conv1_2==2) begin
			D1_2[0]=sram_rdata_b1_in[31:24];
			D1_2[1]=sram_rdata_b1_in[23:16];
			D1_2[2]=sram_rdata_b0_in[31:24];
			D1_2[3]=sram_rdata_b0_in[23:16];
			
			D1_2[4]=sram_rdata_b1_in[15:8];
			D1_2[5]=sram_rdata_b1_in[7:0];
			D1_2[6]=sram_rdata_b0_in[15:8];
			D1_2[7]=sram_rdata_b0_in[7:0];
			
			D1_2[8]=sram_rdata_b3_in[31:24];
			D1_2[9]=sram_rdata_b3_in[23:16];
			D1_2[10]=sram_rdata_b2_in[31:24];
			D1_2[11]=sram_rdata_b2_in[23:16];
			
			D1_2[12]=sram_rdata_b3_in[15:8];
			D1_2[13]=sram_rdata_b3_in[7:0];
			D1_2[14]=sram_rdata_b2_in[15:8];
			D1_2[15]=sram_rdata_b2_in[7:0];
		
		
		end
		
		else if(type_data_conv1_2==3) begin
			D1_2[0]=sram_rdata_b2_in[31:24];
			D1_2[1]=sram_rdata_b2_in[23:16];
			D1_2[2]=sram_rdata_b3_in[31:24];
			D1_2[3]=sram_rdata_b3_in[23:16];
			
			D1_2[4]=sram_rdata_b2_in[15:8];
			D1_2[5]=sram_rdata_b2_in[7:0];
			D1_2[6]=sram_rdata_b3_in[15:8];
			D1_2[7]=sram_rdata_b3_in[7:0];
			
			D1_2[8]=sram_rdata_b0_in[31:24];
			D1_2[9]=sram_rdata_b0_in[23:16];
			D1_2[10]=sram_rdata_b1_in[31:24];
			D1_2[11]=sram_rdata_b1_in[23:16];
			
			D1_2[12]=sram_rdata_b0_in[15:8];
			D1_2[13]=sram_rdata_b0_in[7:0];
			D1_2[14]=sram_rdata_b1_in[15:8];
			D1_2[15]=sram_rdata_b1_in[7:0];
		
		
		end
		
		else if(type_data_conv1_2==4) begin
			D1_2[0]=sram_rdata_b3_in[31:24];
			D1_2[1]=sram_rdata_b3_in[23:16];
			D1_2[2]=sram_rdata_b2_in[31:24];
			D1_2[3]=sram_rdata_b2_in[23:16];
			
			D1_2[4]=sram_rdata_b3_in[15:8];
			D1_2[5]=sram_rdata_b3_in[7:0];
			D1_2[6]=sram_rdata_b2_in[15:8];
			D1_2[7]=sram_rdata_b2_in[7:0];
			
			D1_2[8]=sram_rdata_b1_in[31:24];
			D1_2[9]=sram_rdata_b1_in[23:16];
			D1_2[10]=sram_rdata_b0_in[31:24];
			D1_2[11]=sram_rdata_b0_in[23:16];
			
			D1_2[12]=sram_rdata_b1_in[15:8];
			D1_2[13]=sram_rdata_b1_in[7:0];
			D1_2[14]=sram_rdata_b0_in[15:8];
			D1_2[15]=sram_rdata_b0_in[7:0];
		
		
		end
		


	end
	
end
*/


/////////////////////////////////////////////

reg [31:0] result_a,result_a_n;
wire [31:0] result_a_now;

reg [31:0] result_b,result_b_n;
wire [31:0] result_b_now;

reg [31:0] result_c,result_c_n;
wire [31:0] result_c_now;

reg [31:0] result_d,result_d_n;
wire [31:0] result_d_now;

always @(posedge clk )begin
	if(~rst_n) begin
		result_a<=0;
		result_b<=0;
		result_c<=0;
		result_d<=0;
	end
	else begin
		result_a<=result_a_n;
		result_b<=result_b_n;
		result_c<=result_c_n;
		result_d<=result_d_n;
	end

end






//----------share the multiplier-------------//




reg signed [31:0] a_now_1, a_now_2 ,a_now_3;
reg signed [31:0] b_now_1, b_now_2 ,b_now_3;
reg signed [31:0] c_now_1, c_now_2 ,c_now_3;
reg signed [31:0] d_now_1, d_now_2 ,d_now_3;


reg signed [31:0] a_now_1_n, a_now_2_n ,a_now_3_n;
reg signed [31:0] b_now_1_n, b_now_2_n ,b_now_3_n;
reg signed [31:0] c_now_1_n, c_now_2_n ,c_now_3_n;
reg signed [31:0] d_now_1_n, d_now_2_n ,d_now_3_n;

always@(posedge clk) begin
	if (~rst_n) begin
		a_now_1<=0;
		a_now_2<=0;
		a_now_3<=0;
		
		b_now_1<=0;
		b_now_2<=0;
		b_now_3<=0;
		
		c_now_1<=0;
		c_now_2<=0;
		c_now_3<=0;
		
		d_now_1<=0;
		d_now_2<=0;
		d_now_3<=0;

	end

		a_now_1<=a_now_1_n;
		a_now_2<=a_now_2_n;
		a_now_3<=a_now_3_n;
		
		b_now_1<=b_now_1_n;
		b_now_2<=b_now_2_n;
		b_now_3<=b_now_3_n;
		
		c_now_1<=c_now_1_n;
		c_now_2<=c_now_2_n;
		c_now_3<=c_now_3_n;
		
		d_now_1<=d_now_1_n;
		d_now_2<=d_now_2_n;
		d_now_3<=d_now_3_n;


end


always@(*) begin
	a_now_1_n=weight1_2[0]*D1_2[0]+weight1_2[1]*D1_2[1]+weight1_2[2]*D1_2[2];
	a_now_2_n=weight1_2[3]*D1_2[4]+weight1_2[4]*D1_2[5]+weight1_2[5]*D1_2[6];
	a_now_3_n=weight1_2[6]*D1_2[8]+weight1_2[7]*D1_2[9]+weight1_2[8]*D1_2[10];

	b_now_1_n=weight1_2[0]*D1_2[1]+weight1_2[1]*D1_2[2]+weight1_2[2]*D1_2[3];
	b_now_2_n=weight1_2[3]*D1_2[5]+weight1_2[4]*D1_2[6]+weight1_2[5]*D1_2[7];
	b_now_3_n=weight1_2[6]*D1_2[9]+weight1_2[7]*D1_2[10]+weight1_2[8]*D1_2[11];
	
	c_now_1_n=weight1_2[0]*D1_2[4]+weight1_2[1]*D1_2[5]+weight1_2[2]*D1_2[6];
	c_now_2_n=weight1_2[3]*D1_2[8]+weight1_2[4]*D1_2[9]+weight1_2[5]*D1_2[10];
	c_now_3_n=weight1_2[6]*D1_2[12]+weight1_2[7]*D1_2[13]+weight1_2[8]*D1_2[14];	
	
	d_now_1_n=weight1_2[0]*D1_2[5]+weight1_2[1]*D1_2[6]+weight1_2[2]*D1_2[7];
	d_now_2_n=weight1_2[3]*D1_2[9]+weight1_2[4]*D1_2[10]+weight1_2[5]*D1_2[11];
	d_now_3_n=weight1_2[6]*D1_2[13]+weight1_2[7]*D1_2[14]+weight1_2[8]*D1_2[15];

end

assign result_a_now=a_now_1+a_now_2+a_now_3;
assign result_b_now=b_now_1+b_now_2+b_now_3;
assign result_c_now=c_now_1+c_now_2+c_now_3;
assign result_d_now=d_now_1+d_now_2+d_now_3;




/*



assign result_a_now=	weight1_2[0]*D1_2[0]+weight1_2[1]*D1_2[1]+weight1_2[2]*D1_2[2]
						+weight1_2[3]*D1_2[4]+weight1_2[4]*D1_2[5]+weight1_2[5]*D1_2[6]
					   +weight1_2[6]*D1_2[8]+weight1_2[7]*D1_2[9]+weight1_2[8]*D1_2[10] ;
					   
assign result_b_now=	 weight1_2[0]*D1_2[1]+weight1_2[1]*D1_2[2]+weight1_2[2]*D1_2[3]+
						weight1_2[3]*D1_2[5]+weight1_2[4]*D1_2[6]+weight1_2[5]*D1_2[7]
						+weight1_2[6]*D1_2[9]+weight1_2[7]*D1_2[10]+weight1_2[8]*D1_2[11];					   
					   
assign result_c_now=     weight1_2[0]*D1_2[4]+weight1_2[1]*D1_2[5]+weight1_2[2]*D1_2[6]+
						weight1_2[3]*D1_2[8]+weight1_2[4]*D1_2[9]+weight1_2[5]*D1_2[10]
						+weight1_2[6]*D1_2[12]+weight1_2[7]*D1_2[13]+weight1_2[8]*D1_2[14];

assign result_d_now=   weight1_2[0]*D1_2[5]+weight1_2[1]*D1_2[6]+weight1_2[2]*D1_2[7]+
						weight1_2[3]*D1_2[9]+weight1_2[4]*D1_2[10]+weight1_2[5]*D1_2[11]
						+weight1_2[6]*D1_2[13]+weight1_2[7]*D1_2[14]+weight1_2[8]*D1_2[15];				   
					   
*/
   

always @(*) begin

	result_a_n=0;
	result_b_n=0;
	result_c_n=0;
	result_d_n=0;

	if (state==CONV1_2andPOOL1 && cnt_CONV1_2>2) begin
		if( (cnt_CONV1_2_data-1-1)%20==0) begin
			result_a_n= result_a_now;
			result_b_n= result_b_now;
			result_c_n= result_c_now;
			result_d_n= result_d_now;
		end
		//else if(cnt_CONV1_2_data%20 >=1 && cnt_CONV1_2_data%20 <=19  ) begin
		else begin	
			result_a_n = result_a_now + result_a;
			result_b_n = result_b_now + result_b;
			result_c_n = result_c_now + result_c;
			result_d_n = result_d_now + result_d;
		end	
		
	end
	else begin
		
		result_a_n=0;
		result_b_n=0;
		result_c_n=0;
		result_d_n=0;
	end

end


//wire [31:0] cnt_CONV1_2_data_new;
//assign cnt_CONV1_2_data_new=cnt_CONV1_2_data-1;

reg signed [31:0] result_conv1_2_a_final_n;
reg signed [31:0] result_conv1_2_b_final_n;
reg signed [31:0] result_conv1_2_c_final_n;
reg signed [31:0] result_conv1_2_d_final_n;


always@ (posedge clk) begin
	if(~rst_n) begin
		result_conv1_2_a_final<=0;
		result_conv1_2_b_final<=0;
		result_conv1_2_c_final<=0;
		result_conv1_2_d_final<=0;
	
	end
	else begin
		result_conv1_2_a_final<=result_conv1_2_a_final_n;
		result_conv1_2_b_final<=result_conv1_2_b_final_n;
		result_conv1_2_c_final<=result_conv1_2_c_final_n;
		result_conv1_2_d_final<=result_conv1_2_d_final_n;


	end

end





always @(*) begin
	if (state==CONV1_2andPOOL1 && cnt_CONV1_2_data_new%20==19) begin
	
		
		result_conv1_2_a_final_n=result_a;
		result_conv1_2_b_final_n=result_b;
		result_conv1_2_c_final_n=result_c;
		result_conv1_2_d_final_n=result_d;
		
	end
	else begin
		result_conv1_2_a_final_n=0;
		result_conv1_2_b_final_n=0;
		result_conv1_2_c_final_n=0;
		result_conv1_2_d_final_n=0;
	end

end

/*
always @(*) begin
	if (state==CONV1_2andPOOL1 && cnt_CONV1_2_data_new%20==19) begin
	
		
		result_conv1_2_a_final=result_a;
		result_conv1_2_b_final=result_b;
		result_conv1_2_c_final=result_c;
		result_conv1_2_d_final=result_d;
		
	end
	else begin
		result_conv1_2_a_final=0;
		result_conv1_2_b_final=0;
		result_conv1_2_c_final=0;
		result_conv1_2_d_final=0;
	end

end
*/



endmodule















