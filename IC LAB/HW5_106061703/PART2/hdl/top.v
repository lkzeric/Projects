module Convnet_top #(
    parameter PARAM_WIDTH = 4,
    parameter PARAM_NUM = 9,
    parameter DATA_WIDTH = 8,
    parameter DATA_NUM_PER_SRAM_ADDR = 4
)
(
input clk,                           //clock input
input rst_n,                         //synchronous reset (active low)

input enable,
input [DATA_WIDTH-1 : 0] input_data,    // input image

input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a0,  //32 bits
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a1,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a2,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a3,

input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b0,  //32 bits
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b1,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b2,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b3,

input [PARAM_NUM*PARAM_WIDTH-1:0] sram_rdata_param,

output  reg [9:0] sram_raddr_a0,
output  reg [9:0] sram_raddr_a1,
output  reg [9:0] sram_raddr_a2,
output  reg [9:0] sram_raddr_a3,

output  reg [9:0] sram_raddr_b0,
output  reg [9:0] sram_raddr_b1,
output  reg [9:0] sram_raddr_b2,
output  reg [9:0] sram_raddr_b3,

output  reg busy,
output  reg valid,   //output valid to check answer

output  reg sram_wen_a0,
output  reg sram_wen_a1,
output  reg sram_wen_a2,
output  reg sram_wen_a3,
output  reg sram_wen_b0,
output  reg sram_wen_b1,
output  reg sram_wen_b2,
output  reg sram_wen_b3,

output  reg [3:0] sram_bytemask_a,
output  reg [9:0] sram_waddr_a,
output  reg [31:0] sram_wdata_a,

output  reg [3:0] sram_bytemask_b,
output  reg [9:0] sram_waddr_b,
output  reg [31:0] sram_wdata_b,

output  reg [8:0] sram_raddr_param       //read address from SRAM weight  
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

localparam max_val = 127, min_val = -128;

//localparam IDLE = 0, LOAD = 1, FINISH = 2;
/////////// state localparam //////////
localparam IDLE=3'd0,PREPARE=3'd1, LOAD_IMAGE=3'd2, CONV1_1_BIAS=3'd3, CONV1_1=3'd4, CONV1_2andPOOL1_BIAS=3'd5,CONV1_2andPOOL1=3'd6;




/////////////////////// SRAM parameter /////////////////////

////// inpuut parameter //////
reg enable_in;
reg [DATA_WIDTH-1 : 0] input_data_in; //8 bits

reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a0_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a1_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a2_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a3_in;

reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b0_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b1_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b2_in;
reg [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_b3_in;

reg [PARAM_NUM*PARAM_WIDTH-1:0] sram_rdata_param_in;

////// output parameter //////
reg busy_n;
reg valid_n;
reg [9:0] sram_raddr_a0_n;
reg [9:0] sram_raddr_a1_n;
reg [9:0] sram_raddr_a2_n;
reg [9:0] sram_raddr_a3_n;


reg sram_wen_a0_n;
reg sram_wen_a1_n;
reg sram_wen_a2_n;
reg sram_wen_a3_n;

reg [3:0] sram_bytemask_a_n;   // active low
reg [9:0] sram_waddr_a_n;
reg [31:0] sram_wdata_a_n; //32 bits need to store 4 sets input data


reg [8:0] sram_raddr_param_n;


reg [9:0] sram_raddr_b0_n;
reg [9:0] sram_raddr_b1_n;
reg [9:0] sram_raddr_b2_n;
reg [9:0] sram_raddr_b3_n;


reg sram_wen_b0_n;
reg sram_wen_b1_n;
reg sram_wen_b2_n;
reg sram_wen_b3_n;

reg [3:0] sram_bytemask_b_n;   // active low
reg [9:0] sram_waddr_b_n;
reg [31:0] sram_wdata_b_n; //32 bits need to store 4 sets input data

////// Input FF  ////////
always @(posedge clk) begin
	if(~rst_n) begin
		enable_in<=0;
		input_data_in<=0;
		sram_rdata_a0_in<=0;
		sram_rdata_a1_in<=0;
		sram_rdata_a2_in<=0;
		sram_rdata_a3_in<=0;
		sram_rdata_b0_in<=0;
		sram_rdata_b1_in<=0;
		sram_rdata_b2_in<=0;
		sram_rdata_b3_in<=0;
		sram_rdata_param_in<=0;
	end
	else begin
		enable_in<=enable;
		input_data_in<=input_data;
		sram_rdata_a0_in<=sram_rdata_a0;
		sram_rdata_a1_in<=sram_rdata_a1;
		sram_rdata_a2_in<=sram_rdata_a2;
		sram_rdata_a3_in<=sram_rdata_a3;
		sram_rdata_b0_in<=sram_rdata_b0;
		sram_rdata_b1_in<=sram_rdata_b1;
		sram_rdata_b2_in<=sram_rdata_b2;
		sram_rdata_b3_in<=sram_rdata_b3;
		sram_rdata_param_in<=sram_rdata_param;
	end
end

////// Output FF ////////

always @(posedge clk) begin
	if(~rst_n) begin
		busy<=1;
		valid<=0;
		
		sram_raddr_a0<=0;
		sram_raddr_a1<=0;
		sram_raddr_a2<=0;
		sram_raddr_a3<=0;
		sram_wen_a0<=1;
		sram_wen_a1<=1;
		sram_wen_a2<=1;
		sram_wen_a3<=1;
		
		
		sram_raddr_b0<=0;
		sram_raddr_b1<=0;
		sram_raddr_b2<=0;
		sram_raddr_b3<=0;
		sram_wen_b0<=1;
		sram_wen_b1<=1;
		sram_wen_b2<=1;
		sram_wen_b3<=1;
		
		sram_bytemask_a<=4'b1111;
		sram_waddr_a<=0;
		sram_wdata_a<=0;
		sram_raddr_param<=500; // have to pay attentiona about the sram_raddr_param, since sram_raddr_param=0 has the nonzero value	
	
		sram_bytemask_b<=4'b1111;
		sram_waddr_b<=0;
		sram_wdata_b<=0;
	end
	else begin
		busy<=busy_n;
		valid<=valid_n;
		
		sram_raddr_a0<=sram_raddr_a0_n;
		sram_raddr_a1<=sram_raddr_a1_n;
		sram_raddr_a2<=sram_raddr_a2_n;
		sram_raddr_a3<=sram_raddr_a3_n;
		sram_wen_a0<=sram_wen_a0_n;
		sram_wen_a1<=sram_wen_a1_n;
		sram_wen_a2<=sram_wen_a2_n;
		sram_wen_a3<=sram_wen_a3_n;
		
		sram_raddr_b0<=sram_raddr_b0_n;
		sram_raddr_b1<=sram_raddr_b1_n;
		sram_raddr_b2<=sram_raddr_b2_n;
		sram_raddr_b3<=sram_raddr_b3_n;
		sram_wen_b0<=sram_wen_b0_n;
		sram_wen_b1<=sram_wen_b1_n;
		sram_wen_b2<=sram_wen_b2_n;
		sram_wen_b3<=sram_wen_b3_n;
		
		
		sram_bytemask_a<=sram_bytemask_a_n;
		sram_waddr_a<=sram_waddr_a_n;
		sram_wdata_a<=sram_wdata_a_n;
		sram_raddr_param<=sram_raddr_param_n;
		
		sram_bytemask_b<=sram_bytemask_b_n;
		sram_waddr_b<=sram_waddr_b_n;
		sram_wdata_b<=sram_wdata_b_n;
	
	end
end

///////////////// STATE //////////////////
reg [3:0] state,state_n;




///////////////// LOAD_IMAGE //////////////////
reg load_finish,load_finish_n;

//////////////// CONV1_1 ///////////////////
reg CONV1_1_finish, CONV1_1_finish_n;

reg signed [3:0] weight   [8:0]; //9 elements, 4 bits/element
reg signed [3:0] weight_n [8:0];


reg signed [3:0] bias [19:0];  //20 bias
reg signed [3:0] bias_n [19:0];
reg signed [7:0] data_window [15:0]; // 16 elements, 8 bits/element

wire signed [11:0] weight_result [0:8]; // weight*data_window

//reg signed [7:0] D0,D1,D2,D3,D4,D5,D6,D7,D8;
reg signed [7:0] D [0:8];
wire signed [31:0] result_conv_all;
wire signed [7:0] q_output;



//////////////// CONV1_2 ////////////////
wire signed [31:0] conv1_2_a_final;
wire signed [31:0] conv1_2_b_final;
wire signed [31:0] conv1_2_c_final;
wire signed [31:0] conv1_2_d_final;

wire signed [7:0] conv1_2_a_output;
wire signed [7:0] conv1_2_b_output;
wire signed [7:0] conv1_2_c_output;
wire signed [7:0] conv1_2_d_output;




//////////////// POOLING ////////////////

wire signed [7:0] pool_a_b;
wire signed [7:0] pool_c_d;
wire signed [7:0] pool_final;

assign pool_a_b=(conv1_2_a_output >= conv1_2_b_output)?conv1_2_a_output : conv1_2_b_output;
assign pool_c_d=(conv1_2_c_output >= conv1_2_d_output)?conv1_2_c_output : conv1_2_d_output;
assign pool_final=(pool_a_b >= pool_c_d)? pool_a_b:pool_c_d;



/////////// counter ///////////

reg [9:0] cnt_LOAD ,cnt_LOAD_n;
reg [2:0] cnt_PREPARE, cnt_PREPARE_n;
reg [5:0] cnt_CONV1_1_BIAS,cnt_CONV1_1_BIAS_n;
reg [9:0] cnt_CONV1_1,cnt_CONV1_1_n;
reg [5:0] cnt_weight,cnt_weight_n;
reg [20:0] cnt_CONV1_1_finish,cnt_CONV1_1_finish_n;
wire [9:0] cnt_q_output;

reg [5:0] cnt_CONV1_2_BIAS,cnt_CONV1_2_BIAS_n;
reg [31:0] cnt_CONV1_2,cnt_CONV1_2_n;
//wire [31:0] cnt_CONV1_2_pixel;
wire [9:0] cnt_CONV1_2_pixel;

reg [9:0] cnt_3D,cnt_3D_n; // 3D weight channel.....
reg [20:0] cnt_CONV1_2_finish,cnt_CONV1_2_finish_n;
wire [31:0] cnt_CONV1_2_data;
//wire [9:0] cnt_CONV1_2_data;
wire [31:0] cnt_CONV1_2_pixel_tmp;

assign cnt_CONV1_2_data=cnt_CONV1_2-3;
wire [31:0] cnt_CONV1_2_data_new;
assign cnt_CONV1_2_data_new=cnt_CONV1_2_data-1-1-1;

assign cnt_CONV1_2_pixel_tmp=((cnt_CONV1_2_data_new-1)/20);
assign cnt_CONV1_2_pixel=cnt_CONV1_2_pixel_tmp[9:0];









always @(posedge clk) begin
	if(~rst_n) begin
		cnt_LOAD<=0;
		cnt_PREPARE<=0;
		cnt_CONV1_1_BIAS<=0;
		cnt_CONV1_1<=0;
		cnt_weight<=0;
		cnt_CONV1_1_finish<=0;
		
		cnt_CONV1_2_BIAS<=0;
		cnt_CONV1_2<=0;
		//cnt_CONV1_2_pixel<=0;
		cnt_3D<=0;
		cnt_CONV1_2_finish<=0;
		
	end
	else begin
		cnt_LOAD<=cnt_LOAD_n;
		cnt_PREPARE<=cnt_PREPARE_n;
		cnt_CONV1_1_BIAS<=cnt_CONV1_1_BIAS_n;
		cnt_CONV1_1<=cnt_CONV1_1_n;
		cnt_weight<=cnt_weight_n;
		cnt_CONV1_1_finish<=cnt_CONV1_1_finish_n;
		
		cnt_CONV1_2_BIAS<=cnt_CONV1_2_BIAS_n;
		cnt_CONV1_2<=cnt_CONV1_2_n;
		//cnt_CONV1_2_pixel<=cnt_CONV1_2_pixel_n;
		cnt_3D<=cnt_3D_n;
		cnt_CONV1_2_finish<=cnt_CONV1_2_finish_n;
		
	end
end


always @(*) begin
	cnt_LOAD_n=0; cnt_PREPARE_n=0; cnt_CONV1_1_n=0;
	cnt_CONV1_1_BIAS_n=0; cnt_weight_n=0;cnt_CONV1_1_finish_n=0;
	cnt_weight_n=0;cnt_CONV1_2_n=0;cnt_3D_n=0;cnt_CONV1_2_finish_n=0;
	cnt_CONV1_2_BIAS_n=0;
	
	case(state)
		LOAD_IMAGE: cnt_LOAD_n=cnt_LOAD+1;
		PREPARE: cnt_PREPARE_n=cnt_PREPARE+1;
		CONV1_1_BIAS: cnt_CONV1_1_BIAS_n=cnt_CONV1_1_BIAS+1;
		
		CONV1_1:  begin  
					
					cnt_CONV1_1_finish_n=cnt_CONV1_1_finish+1;

					
					if (cnt_CONV1_1<700) begin
						cnt_CONV1_1_n=cnt_CONV1_1+1;
						cnt_weight_n=cnt_weight;
					end
					else begin 
						cnt_CONV1_1_n=0;
						cnt_weight_n=cnt_weight+1;
					end
				   end
		CONV1_2andPOOL1_BIAS: cnt_CONV1_2_BIAS_n=cnt_CONV1_2_BIAS+1;	
					
		CONV1_2andPOOL1: begin      
							cnt_CONV1_2_finish_n=cnt_CONV1_2_finish+1;
							if (cnt_CONV1_2<2900) begin
								cnt_3D_n=cnt_3D;
								cnt_CONV1_2_n=cnt_CONV1_2+1;
							end
							else begin 
								cnt_3D_n=cnt_3D+1;
								cnt_CONV1_2_n=0;
							end
						 end
		
		default: begin
				 cnt_LOAD_n=0; cnt_PREPARE_n=0; cnt_CONV1_1_n=0;cnt_CONV1_1_BIAS_n=0; cnt_weight_n=0;
				 cnt_CONV1_2_BIAS_n=0;cnt_CONV1_2_n=0;cnt_3D_n=0;cnt_CONV1_2_finish_n=0;
				 end
	endcase
end



/////////////////// STATE function //////////////////////
always @(posedge clk) begin
	if(~rst_n) begin
		state<=IDLE;
	end
	else begin
		state<=state_n;
	end
end

always @(*) begin
	case(state)
		IDLE: state_n=(enable_in==1)?LOAD_IMAGE:PREPARE;
		PREPARE: state_n=(cnt_PREPARE>0)?LOAD_IMAGE:PREPARE;
		LOAD_IMAGE: state_n=(load_finish==1)?CONV1_1_BIAS : LOAD_IMAGE;
		
		CONV1_1_BIAS: state_n= (cnt_CONV1_1_BIAS>25)?CONV1_1:CONV1_1_BIAS;
		CONV1_1: state_n=(CONV1_1_finish==1)?CONV1_2andPOOL1_BIAS:CONV1_1;
		
		CONV1_2andPOOL1_BIAS: state_n=(cnt_CONV1_2_BIAS>25)?CONV1_2andPOOL1:CONV1_2andPOOL1_BIAS;
		
		CONV1_2andPOOL1: state_n=(valid==1)?IDLE:CONV1_2andPOOL1;
		
		
		default:state_n=IDLE;
	endcase
end

///////// LOAD_IMAGE(read the data from the picture, then write the data to the  sram) ////////////

always @(*) begin
	if (state==PREPARE || state==LOAD_IMAGE) busy_n=0;
	else busy_n=1;
end

always @(posedge clk) begin
	if(~rst_n) load_finish<=0;
	else load_finish<=load_finish_n;

end

always @(*) begin
	if (state==LOAD_IMAGE) begin
		if(cnt_LOAD==790) load_finish_n=1;
		else load_finish_n=0;
	end
	else load_finish_n=load_finish;

end

///// CONV1_1 (CONV1_1_finish_n) ///////

always @(posedge clk) begin
	if(~rst_n) CONV1_1_finish<=0;
	else CONV1_1_finish<=CONV1_1_finish_n;

end


always @(*) begin
	if (state==CONV1_1 && cnt_CONV1_1_finish==14010)	begin
		CONV1_1_finish_n=1;	
	end
	else begin CONV1_1_finish_n=0; end
end



///// CONV1_2 (valid_n) //////

always @(*) begin
	if (state==CONV1_2andPOOL1 && cnt_CONV1_2_finish==58022) begin
		valid_n=1;
	end
	else begin	valid_n=0;	end 

end




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////// LOAD_IMAGE(set SRAM BANK)  && WRITE POOLING result////////  
//--------------- sram_wen_a -----------------//

always @(*) begin
	case(state)
		LOAD_IMAGE: begin 
						if (  (cnt_LOAD[1:0]==2 ||  cnt_LOAD[1:0]==3) && ((cnt_LOAD/28)%4==2 || (cnt_LOAD/28)%4==3 ))  begin //A3 
								sram_wen_a0_n=1;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=0;
							end
						else if	(  (cnt_LOAD[1:0]==0 ||  cnt_LOAD[1:0]==1) && ((cnt_LOAD/28)%4==2 || (cnt_LOAD/28)%4==3) ) begin //A2
								sram_wen_a0_n=1;
								sram_wen_a1_n=1;	
								sram_wen_a2_n=0;
								sram_wen_a3_n=1;
							end
						else if	(  (cnt_LOAD[1:0]==2 ||  cnt_LOAD[1:0]==3) && ((cnt_LOAD/28)%4==0 || (cnt_LOAD/28)%4==1) ) begin //A1
								sram_wen_a0_n=1;
								sram_wen_a1_n=0;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
							end
						else if	(  (cnt_LOAD[1:0]==0 ||  cnt_LOAD[1:0]==1) && ((cnt_LOAD/28)%4==0 || (cnt_LOAD/28)%4==1) ) begin //A0
								sram_wen_a0_n=0;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
							end
						else begin sram_wen_a0_n=1; sram_wen_a1_n=1; sram_wen_a2_n=1; sram_wen_a3_n=1;  end
					end
					
		CONV1_2andPOOL1: begin
							if ((cnt_CONV1_2_data_new-1)%20==19) begin
								sram_wen_a0_n=0;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
							end
							else begin
								sram_wen_a0_n=1;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
		
							end
						 end
	    default: begin sram_wen_a0_n=1; sram_wen_a1_n=1; sram_wen_a2_n=1; sram_wen_a3_n=1; end
	endcase
end


/////// LOAD CONV1_1 ////////  
//--------------- sram_wen_b -----------------//
assign cnt_q_output=cnt_CONV1_1-7;
//reg [3:0] A;

always @(*) begin
	sram_wen_b0_n=1; sram_wen_b1_n=1; sram_wen_b2_n=1; sram_wen_b3_n=1;
	case(state)
		CONV1_1: begin 
				 if (cnt_q_output>=0 && cnt_q_output<676) begin
					if (  (cnt_q_output/52) %2==0 && (cnt_q_output/4) %2 ==0 )  begin //A0
							sram_wen_b0_n=0;
							sram_wen_b1_n=1;
							sram_wen_b2_n=1;
							sram_wen_b3_n=1;
							//A=0;
						end
					else if	( (cnt_q_output/52)%2==0 && (cnt_q_output/4)%2==1 ) begin //A1
							sram_wen_b0_n=1;
							sram_wen_b1_n=0;	
							sram_wen_b2_n=1;
							sram_wen_b3_n=1;
							//A=1;
						end
					else if	(  (cnt_q_output/52)%2==1  && (cnt_q_output/4)%2==1) begin //A2
							sram_wen_b0_n=1;
							sram_wen_b1_n=1;
							sram_wen_b2_n=0;								
							sram_wen_b3_n=1;
							//A=2;
						end
				
					else begin //A3
							sram_wen_b0_n=1;
							sram_wen_b1_n=1;
							sram_wen_b2_n=1;
							sram_wen_b3_n=0;
							//A=3;
						end
				  end
				else begin sram_wen_b0_n=1; sram_wen_b1_n=1; sram_wen_b2_n=1; sram_wen_b3_n=1; end
				
				end
	    default: begin sram_wen_b0_n=1; sram_wen_b1_n=1; sram_wen_b2_n=1; sram_wen_b3_n=1; end
	endcase
end







////// WRITE IMAGE(set SRAM ADDR) & WRITE the POOLING result ///////
//----------------- sram_waddr_a -----------------//
wire [9:0] num_big_block_row;
wire [9:0] num_small_block;


assign num_big_block_row=(cnt_LOAD)/112;
//assign num_small_block=((cnt_LOAD)%112)%28;
assign num_small_block=(cnt_LOAD)%28;

always @(*) begin
	case (state) 
		LOAD_IMAGE: begin 
						sram_waddr_a_n= (num_big_block_row*7)+(num_small_block/4)+1-1;
									
					end
		CONV1_2andPOOL1: begin
							sram_waddr_a_n=cnt_CONV1_2_pixel/4+(cnt_3D*36);
					
						 end

		default: begin sram_waddr_a_n=0; end
	endcase
end

////// WRITE CONV1_1 ////////
//----------------- sram_waddr_b -----------------//



wire [9:0] num_big_block_row_conv1_1;
wire [9:0] num_small_block_conv1_1;


wire [9:0] num_big_block_row_conv1_1_tmp;
assign num_big_block_row_conv1_1_tmp=(cnt_q_output)/104;


assign num_big_block_row_conv1_1=num_big_block_row_conv1_1_tmp[9:0];
//assign num_small_block_conv1_1=((cnt_q_output)%104)%52;
assign num_small_block_conv1_1=(cnt_q_output)%52;

always @(*) begin
	case(state)
		CONV1_1: begin
					sram_waddr_b_n = num_big_block_row_conv1_1*7 + (num_small_block_conv1_1/8)+cnt_weight*49;
				 end
		
		default: begin sram_waddr_b_n=0; end
	endcase

end







///// LOAD_IMAGE (set pixel and bytemask) & WRITE POOLING result ////////
//---------------- sram_bytemask_a && sram_wdata_a ----------------//
always @(*) begin
	case (state)
		LOAD_IMAGE: begin
						if(cnt_LOAD[0] ==0 && (cnt_LOAD/28)%2==1) begin 
							sram_bytemask_a_n=4'b1101;
							sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000,input_data_in ,8'b0000_0000 };
						end
						else if(cnt_LOAD[0] ==1 && (cnt_LOAD/28)%2==1) begin
							sram_bytemask_a_n=4'b1110;
							sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000,input_data_in};
						end
						else if(cnt_LOAD[0] ==0 && (cnt_LOAD/28)%2==0) begin
							sram_bytemask_a_n=4'b0111;
							sram_wdata_a_n={input_data_in,8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000};
						end
						/*
						else if(cnt_LOAD%2 ==1 && (cnt_LOAD/28)%2==0) begin 
							sram_bytemask_a_n=4'b1011;
							sram_wdata_a_n={8'b0000_0000 ,input_data_in,8'b0000_0000 ,8'b0000_0000};
						end
						*/
						else begin
							sram_bytemask_a_n=4'b1011;
							sram_wdata_a_n={8'b0000_0000 ,input_data_in,8'b0000_0000 ,8'b0000_0000};
						end
						end
		CONV1_2andPOOL1: begin
							if(cnt_CONV1_2_pixel[1:0]==0) begin
								sram_bytemask_a_n=4'b0111;
								sram_wdata_a_n={pool_final,8'b0000_0000,8'b0000_0000,8'b0000_0000};							
							end
							
							else if(cnt_CONV1_2_pixel[1:0]==1) begin
								sram_bytemask_a_n=4'b1011;
								sram_wdata_a_n={8'b0000_0000,pool_final,8'b0000_0000,8'b0000_0000};							
							end
							
							else if(cnt_CONV1_2_pixel[1:0]==2) begin
								sram_bytemask_a_n=4'b1101;
								sram_wdata_a_n={8'b0000_0000,8'b0000_0000,pool_final,8'b0000_0000};		
							end
							
							else  begin
								sram_bytemask_a_n=4'b1110;
								sram_wdata_a_n={8'b0000_0000,8'b0000_0000,8'b0000_0000,pool_final};							
							end
		
						 end

		default: begin sram_bytemask_a_n=4'b1111;sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000};end
	endcase
end






///// LOAD CONV1_1 (set pixel and bytemask) ////////
//---------------- sram_bytemask_b && sram_wdata_b ----------------//

always @(*) begin
	case (state)
		CONV1_1 : begin
				  if (cnt_q_output>=0 && cnt_q_output<676) begin
		
						if(cnt_q_output[1:0]==0) begin 
							sram_bytemask_b_n=4'b0111;
							sram_wdata_b_n={q_output, 8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000 };
						end
						else if(cnt_q_output[1:0]==1) begin
							sram_bytemask_b_n=4'b1011;
							sram_wdata_b_n={8'b0000_0000 ,q_output,8'b0000_0000 ,8'b0000_0000};
						end
						else if(cnt_q_output[1:0]==2) begin
							sram_bytemask_b_n=4'b1101;
							sram_wdata_b_n={8'b0000_0000 ,8'b0000_0000,q_output ,8'b0000_0000};
						end
						
						else begin
							sram_bytemask_b_n=4'b1110;
							sram_wdata_b_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000 ,q_output};
						end
					end
					
					else begin
					
						sram_bytemask_b_n=4'b1111;
						sram_wdata_b_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000};
								
					end
					
					
				  end

		default: begin sram_bytemask_b_n=4'b1111;sram_wdata_b_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000};end
	endcase
end








/////////// set the weight window (3*3) and bias ///////////
//----------------- sram_raddr_param ----------------//

reg [31:0] raddr_tmp ;

always @(*) begin 

	raddr_tmp=0;
	case(state)
		
		CONV1_1_BIAS: begin
						if(cnt_CONV1_1_BIAS<9) sram_raddr_param_n=20; // 0~8
						else if (cnt_CONV1_1_BIAS>8 && cnt_CONV1_1_BIAS<18) sram_raddr_param_n=21;   //9~17
						else if (cnt_CONV1_1_BIAS==18 || cnt_CONV1_1_BIAS==19) sram_raddr_param_n=22;
						else sram_raddr_param_n=500;
		
					  end
					  
		
		CONV1_1:begin 
					
					sram_raddr_param_n=cnt_weight;
					
				end
				
		CONV1_2andPOOL1_BIAS: begin
								if(cnt_CONV1_2_BIAS<9) sram_raddr_param_n=423; // 0~8
								else if (cnt_CONV1_2_BIAS>8 && cnt_CONV1_2_BIAS<18) sram_raddr_param_n=424;   //9~17
								else if (cnt_CONV1_2_BIAS==18 || cnt_CONV1_2_BIAS==19) sram_raddr_param_n=425;
								else sram_raddr_param_n=500;
							  end
							  
		CONV1_2andPOOL1: begin
							if (cnt_CONV1_2<2880) begin
							    raddr_tmp=23+ (cnt_CONV1_2%20)+20*cnt_3D;
								sram_raddr_param_n=raddr_tmp[8:0];
							end
							else 
								sram_raddr_param_n=500;
							
						 end
				

		default:sram_raddr_param_n=500;
	endcase
end








/////////// set the data window (4*4) ///////////
//----------------- sram_raddr_a --------------//
// there are 4 types of adress distribution

reg [2:0] type_addr;

always @(*) begin
	type_addr=0;
	if (state==CONV1_1) begin
		if ((cnt_CONV1_1/52)%2==0 ) begin// type_addr:1,2,1,2....
			if (((cnt_CONV1_1%52)/4)%2==0) begin
				type_addr=1;
			end
			//else if (((cnt_CONV1_1%52)/4)%2==1)begin 
			else begin	
				type_addr=2;
			end
		end
		else if ((cnt_CONV1_1/52)%2==1) begin//type_addr:3,4,3,4....
			if (((cnt_CONV1_1%52)/4)%2==0) begin
				type_addr=3;
			end
			//else if (((cnt_CONV1_1%52)/4)%2==1) begin 
			else begin	
				type_addr=4;
			end
		end
		
		else type_addr=0;
	end

	else type_addr=0;

end



always @(*) begin
	sram_raddr_a0_n=500; sram_raddr_a1_n=500; sram_raddr_a2_n=500; sram_raddr_a3_n=500;
	case(state)
	
		CONV1_1: begin
		
				 if (cnt_CONV1_1<676) begin
					if (type_addr==1) begin //  type_addr:1
						    
						sram_raddr_a0_n=(cnt_CONV1_1 %52 )/8 + (cnt_CONV1_1/104)*7;						
						sram_raddr_a2_n=(cnt_CONV1_1 %52 )/8 + (cnt_CONV1_1/104)*7;
						sram_raddr_a1_n=(cnt_CONV1_1 %52 )/8 + (cnt_CONV1_1/104)*7;
						sram_raddr_a3_n=(cnt_CONV1_1 %52 )/8 + (cnt_CONV1_1/104)*7;
						end
					else if (type_addr==2) begin // type_addr:2
					
						sram_raddr_a0_n=((cnt_CONV1_1 %52 )/8)+1+(cnt_CONV1_1/104)*7;				
						sram_raddr_a2_n=((cnt_CONV1_1 %52 )/8)+1+(cnt_CONV1_1/104)*7;
						sram_raddr_a1_n=(cnt_CONV1_1 %52 )/8+(cnt_CONV1_1/104)*7;
						sram_raddr_a3_n=(cnt_CONV1_1 %52 )/8+(cnt_CONV1_1/104)*7;
						end
					
					else if (type_addr==3) begin //type_addr:3
					  
						sram_raddr_a0_n=((cnt_CONV1_1 %52 )/8)+7 + (cnt_CONV1_1/104)*7;				
						sram_raddr_a2_n=((cnt_CONV1_1 %52 )/8) + (cnt_CONV1_1/104)*7;	
						sram_raddr_a1_n=((cnt_CONV1_1 %52 )/8)+7 + (cnt_CONV1_1/104)*7;
						sram_raddr_a3_n=((cnt_CONV1_1 %52 )/8) + (cnt_CONV1_1/104)*7;	
					    end
						
					else if (type_addr==4) begin //type_addr:4
						sram_raddr_a0_n=((cnt_CONV1_1 %52 )/8)+7 +1+ (cnt_CONV1_1/104)*7;						
						sram_raddr_a2_n=((cnt_CONV1_1 %52 )/8)+1 + (cnt_CONV1_1/104)*7;
						sram_raddr_a1_n=((cnt_CONV1_1 %52 )/8)+7 + (cnt_CONV1_1/104)*7;		
						sram_raddr_a3_n=((cnt_CONV1_1 %52 )/8) + (cnt_CONV1_1/104)*7;
						end
					else begin sram_raddr_a0_n=500; sram_raddr_a1_n=500; sram_raddr_a2_n=500; sram_raddr_a3_n=500; end
					
				 end
				 else begin sram_raddr_a0_n=500; sram_raddr_a1_n=500; sram_raddr_a2_n=500; sram_raddr_a3_n=500; end
				 
				 
				 end

		
		default:begin sram_raddr_a0_n=500; sram_raddr_a1_n=500; sram_raddr_a2_n=500; sram_raddr_a3_n=500; end
	endcase
end


///////// CONV1_2 /////////
//----------------- sram_raddr_b --------------//
// there are 4 types of adress distribution

reg [2:0] type_addr_conv1_2;

always @(*) begin
	type_addr_conv1_2=0;
	if (state==CONV1_2andPOOL1 && cnt_CONV1_2<2880) begin
		if ((cnt_CONV1_2/240)%2==0 ) begin  // type_addr_conv1_2: 1,2,1,2....
			if (((cnt_CONV1_2%240)/20)%2==0) begin
				type_addr_conv1_2=1;
			end
			//else if (((cnt_CONV1_2%240)/20)%2==1)begin 
			else begin	
				type_addr_conv1_2=2;
			end
		end
		else if ((cnt_CONV1_2/240)%2==1) begin  //type_addr_conv1_2:3,4,3,4....
			if (((cnt_CONV1_2%240)/20)%2==0) begin
				type_addr_conv1_2=3;
			end
			//else if (((cnt_CONV1_2%240)/20)%2==1) begin 
			else begin	
				type_addr_conv1_2=4;
			end
		end
		
		else type_addr_conv1_2=0;
	end

	else type_addr_conv1_2=0;

end



wire [31:0] sram_raddr_b_tmp;
wire [31:0] sram_raddr_b_tmp_1;
wire [31:0] sram_raddr_b_tmp_7;
wire [31:0] sram_raddr_b_tmp_8;


assign sram_raddr_b_tmp=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
assign sram_raddr_b_tmp_1=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49+1;
assign sram_raddr_b_tmp_7=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49+7;
assign sram_raddr_b_tmp_8=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49+8;



always @(*) begin
	sram_raddr_b0_n=1000;
	sram_raddr_b1_n=1000;
	sram_raddr_b2_n=1000;
	sram_raddr_b3_n=1000;
	
	if (state==CONV1_2andPOOL1 && cnt_CONV1_2<80000) begin
		
			if(type_addr_conv1_2==1) begin
				/*
				sram_raddr_b0_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b1_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b2_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b3_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				*/
				sram_raddr_b0_n=sram_raddr_b_tmp[9:0];
				sram_raddr_b1_n=sram_raddr_b_tmp[9:0];
				sram_raddr_b2_n=sram_raddr_b_tmp[9:0];
				sram_raddr_b3_n=sram_raddr_b_tmp[9:0];
				
			end
			else if (type_addr_conv1_2==2) begin
				/*
				sram_raddr_b0_n=(cnt_CONV1_2%240)/40 +1+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b1_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b2_n=(cnt_CONV1_2%240)/40 +1+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b3_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				*/
				sram_raddr_b0_n=sram_raddr_b_tmp_1[9:0];
				sram_raddr_b1_n=sram_raddr_b_tmp[9:0];
				sram_raddr_b2_n=sram_raddr_b_tmp_1[9:0];
				sram_raddr_b3_n=sram_raddr_b_tmp[9:0];
					
			end
			
			else if (type_addr_conv1_2==3) begin
				/*
				sram_raddr_b0_n=(cnt_CONV1_2%240)/40 +7+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b1_n=(cnt_CONV1_2%240)/40 +7+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b2_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b3_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				*/
				sram_raddr_b0_n=sram_raddr_b_tmp_7[9:0];
				sram_raddr_b1_n=sram_raddr_b_tmp_7[9:0];
				sram_raddr_b2_n=sram_raddr_b_tmp[9:0];
				sram_raddr_b3_n=sram_raddr_b_tmp[9:0];
				
			end
		
			else if (type_addr_conv1_2==4) begin
				/*
				sram_raddr_b0_n=(cnt_CONV1_2%240)/40 +7+1+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b1_n=(cnt_CONV1_2%240)/40 +7+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b2_n=(cnt_CONV1_2%240)/40 +1+ (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				sram_raddr_b3_n=(cnt_CONV1_2%240)/40 + (cnt_CONV1_2/480)*7 +(cnt_CONV1_2%20)*49;
				*/
				sram_raddr_b0_n=sram_raddr_b_tmp_8[9:0];
				sram_raddr_b1_n=sram_raddr_b_tmp_7[9:0];
				sram_raddr_b2_n=sram_raddr_b_tmp_1[9:0];
				sram_raddr_b3_n=sram_raddr_b_tmp[9:0];
				
			end


	end
	else  begin
		 sram_raddr_b0_n=1000; sram_raddr_b1_n=1000; sram_raddr_b2_n=1000; sram_raddr_b3_n=1000;
	end
	
end









//----------------- sram_rdata_a --------------//
reg [2:0] type_data; //data has three cycles delay
wire [20:0] cnt_CONV1_1_data;
assign cnt_CONV1_1_data=cnt_CONV1_1-3;

always @(*) begin
	type_data=0;
	if (state==CONV1_1 && cnt_CONV1_1>2) begin
		if ((cnt_CONV1_1_data/52)%2==0 ) begin// type_data:1,2,1,2....
			if (((cnt_CONV1_1_data%52)/4)%2==0) begin
				type_data=1;
			end
			//else if (((cnt_CONV1_1_data%52)/4)%2==1)begin 
			else begin	
				type_data=2;
			end
		end
		else if ((cnt_CONV1_1_data/52)%2==1) begin//type_data:3,4,3,4....
			if (((cnt_CONV1_1_data%52)/4)%2==0) begin
				type_data=3;
			end
			//else if (((cnt_CONV1_1_data%52)/4)%2==1) begin 
			else begin	
				type_data=4;
			end
		end
		
		else type_data=0;
	end

	else type_data=0;

end


//----------------- sram_rdata_b --------------//
reg [2:0] type_data_conv1_2;




always @(*) begin
	type_data_conv1_2=0;
	if (state==CONV1_2andPOOL1  && cnt_CONV1_2>2) begin
		if ((cnt_CONV1_2_data/240)%2==0 ) begin  // type_addr_conv1_2: 1,2,1,2....
			if (((cnt_CONV1_2_data%240)/20)%2==0) begin
				type_data_conv1_2=1;
			end
			//else if (((cnt_CONV1_2_data%240)/20)%2==1)begin 
			else begin	
				type_data_conv1_2=2;
			end
		end
		else if ((cnt_CONV1_2_data/240)%2==1) begin  //type_addr_conv1_2:3,4,3,4....
			if (((cnt_CONV1_2_data%240)/20)%2==0) begin
				type_data_conv1_2=3;
			end
			//else if (((cnt_CONV1_2_data%240)/20)%2==1) begin 
			else begin	
				type_data_conv1_2=4;
			end
		end
		
		else type_data_conv1_2=0;
	end

	else type_data_conv1_2=0;

end

///////////////////////////////
/*
wire signed [31:0] conv1_2_a_final;
wire signed [31:0] conv1_2_b_final;
wire signed [31:0] conv1_2_c_final;
wire signed [31:0] conv1_2_d_final;

wire signed [7:0] conv1_2_a_output;
wire signed [7:0] conv1_2_b_output;
wire signed [7:0] conv1_2_c_output;
wire signed [7:0] conv1_2_d_output;

wire signed [7:0] pool_a_b;
wire signed [7:0] pool_c_d;
wire signed [7:0] pool_final;


assign pool_a_b=(conv1_2_a_output >= conv1_2_b_output)?conv1_2_a_output : conv1_2_b_output;
assign pool_c_d=(conv1_2_c_output >= conv1_2_d_output)?conv1_2_c_output : conv1_2_d_output;
assign pool_final=(pool_a_b >= pool_c_d)? pool_a_b:pool_c_d;

*/
convolution #(.PARAM_WIDTH(4),.PARAM_NUM(9),.DATA_WIDTH(8),.DATA_NUM_PER_SRAM_ADDR(4))
my_convolution(
.clk(clk),
.rst_n(rst_n),
.state(state),

.cnt_CONV1_1(cnt_CONV1_1),
.cnt_CONV1_1_data(cnt_CONV1_1_data),
.type_data(type_data),

.cnt_CONV1_2(cnt_CONV1_2),
.cnt_CONV1_2_data(cnt_CONV1_2_data),
.cnt_CONV1_2_data_new(cnt_CONV1_2_data_new),
.type_data_conv1_2(type_data_conv1_2),

.sram_rdata_param_in(sram_rdata_param_in),
.sram_rdata_a0_in(sram_rdata_a0_in),
.sram_rdata_a1_in(sram_rdata_a1_in),
.sram_rdata_a2_in(sram_rdata_a2_in),
.sram_rdata_a3_in(sram_rdata_a3_in),


.sram_rdata_b0_in(sram_rdata_b0_in),
.sram_rdata_b1_in(sram_rdata_b1_in),
.sram_rdata_b2_in(sram_rdata_b2_in),
.sram_rdata_b3_in(sram_rdata_b3_in),


.result_all(result_conv_all),
.result_conv1_2_a_final(conv1_2_a_final),
.result_conv1_2_b_final(conv1_2_b_final),
.result_conv1_2_c_final(conv1_2_c_final),
.result_conv1_2_d_final(conv1_2_d_final)
);




quantize #(.PARAM_WIDTH(4),.PARAM_NUM(9),.DATA_WIDTH(8),.DATA_NUM_PER_SRAM_ADDR(4))
my_quantize (
.clk(clk),
.rst_n(rst_n),
.state(state),

.cnt_CONV1_1_BIAS(cnt_CONV1_1_BIAS),
.cnt_weight(cnt_weight),
.cnt_CONV1_1(cnt_CONV1_1),
.cnt_CONV1_2_BIAS(cnt_CONV1_2_BIAS),
.cnt_3D(cnt_3D),

.sram_rdata_param_in(sram_rdata_param_in),
.result_all(result_conv_all),
.result_conv1_2_a_final(conv1_2_a_final),
.result_conv1_2_b_final(conv1_2_b_final),
.result_conv1_2_c_final(conv1_2_c_final),
.result_conv1_2_d_final(conv1_2_d_final),

.q_output(q_output),
.conv1_2_a_output(conv1_2_a_output),  /////// answer of the CONV1_2
.conv1_2_b_output(conv1_2_b_output),
.conv1_2_c_output(conv1_2_c_output),
.conv1_2_d_output(conv1_2_d_output)
);





endmodule
