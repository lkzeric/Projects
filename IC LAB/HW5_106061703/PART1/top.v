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
input [DATA_WIDTH-1 : 0] input_data,

input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a0,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a1,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a2,
input [DATA_NUM_PER_SRAM_ADDR*DATA_WIDTH-1:0] sram_rdata_a3,

output reg busy,
output reg valid,
output reg [9:0] sram_raddr_a0,
output reg [9:0] sram_raddr_a1,
output reg [9:0] sram_raddr_a2,
output reg [9:0] sram_raddr_a3,

// write enable is active low
output reg sram_wen_a0, 
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,

output reg [3:0] sram_bytemask_a,   // active low
output reg [9:0] sram_waddr_a,
output reg [31:0] sram_wdata_a //32 bits need to store 4 sets input data

);

// The following is the frational length for parameter
localparam CONV1_1_WEIGHT_FL = 3;     //the fractional width of weight in CONV1_1 is 3 bit.
localparam CONV1_2_WEIGHT_FL = 5;     //the fractional width of weight in CONV1_2 is 5 bit.

localparam CONV1_1_BIAS_FL = 5;     //the fractional width of bias in CONV1 is 5 bit.
localparam CONV1_2_BIAS_FL = 7;     //the fractional width of bias in CONV1 is 7 bit.

// The following is the frational length for Activation
localparam CONV2_DATA_IN_FL = 5;    //the fractional width of input image is 8 bit.
localparam CONV2_DATA_OUT_FL = 4;  //the fractional width of output feature map in CONV2 is 4 bit.

localparam ACT_INPUT_FRA = 8;
localparam ACT_conv1_1_fra = 6; 
localparam ACT_conv1_2_fra = 4; 


/////////// state localparam //////////
localparam IDLE=3'd0, LOAD_IMAGE=3'd1, CONV1_1=3'd2, CONV1_2andPOOL1=3'd3,PREPARE=3'd4;




reg [3:0] state,state_n;

////// inpuut parameter //////
reg enable_in;
reg [DATA_WIDTH-1 : 0] input_data_in; //8 bits



////// output parameter //////
reg busy_n;
reg valid_n;


reg sram_wen_a0_n;
reg sram_wen_a1_n;
reg sram_wen_a2_n;
reg sram_wen_a3_n;

reg [3:0] sram_bytemask_a_n;   // active low
reg [9:0] sram_waddr_a_n;
reg [31:0] sram_wdata_a_n; //32 bits need to store 4 sets input data

////// Input FF  ////////
always @(posedge clk) begin
	if(~rst_n) begin
		enable_in<=0;
		input_data_in<=0;
		
	end
	else begin
		enable_in<=enable;
		input_data_in<=input_data;
	
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
		sram_bytemask_a<=4'b1111;
		sram_waddr_a<=0;
		sram_wdata_a<=0;
	end
	else begin
		busy<=busy_n;
		valid<=valid_n;
		
		sram_wen_a0<=sram_wen_a0_n;
		sram_wen_a1<=sram_wen_a1_n;
		sram_wen_a2<=sram_wen_a2_n;
		sram_wen_a3<=sram_wen_a3_n;
		sram_bytemask_a<=sram_bytemask_a_n;
		sram_waddr_a<=sram_waddr_a_n;
		sram_wdata_a<=sram_wdata_a_n;
	
	end
end



/////////// counter ///////////

reg [9:0] cnt_LOAD ,cnt_LOAD_n;
reg [2:0]  cnt_PREPARE, cnt_PREPARE_n;
wire [10:0] cnt_pixel;
//reg [6:0] cnt_LOAD_ADDR, cnt_LOAD_ADDR_n;
always @(posedge clk) begin
	if(~rst_n) begin
		cnt_LOAD<=0;
		cnt_PREPARE<=0;
		//cnt_LOAD_ADDR<=0;
	end
	else begin
		cnt_LOAD<=cnt_LOAD_n;
		cnt_PREPARE<=cnt_PREPARE_n;
		//cnt_LOAD_ADDR<=cnt_LOAD_ADDR_n;
	end
end


always @(*) begin
	cnt_LOAD_n=0; cnt_PREPARE_n=0;
	case(state)
		LOAD_IMAGE: cnt_LOAD_n=cnt_LOAD+1;
		PREPARE: cnt_PREPARE_n=cnt_PREPARE+1;
		
		
		default: begin
				 cnt_LOAD_n=0; cnt_PREPARE_n=0;
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
		LOAD_IMAGE: state_n=(valid_n==1)?CONV1_1:LOAD_IMAGE;
		
		default:state_n=IDLE;
	endcase
end

///////// LOAD_IMAGE(read the data from the picture, then write the data to the  sram) ////////////

always @(*) begin
	if (state==PREPARE || state==LOAD_IMAGE) busy_n=0;
	else busy_n=1;
end



/////// LOAD_IMAGE(set SRAM BANK) ////////

always @(*) begin
	case(state)
		LOAD_IMAGE: begin 
						if (  (cnt_LOAD%4==2 ||  cnt_LOAD%4==3) && ((cnt_LOAD/28)%4==2 || (cnt_LOAD/28)%4==3 ))  begin //A3 
								sram_wen_a0_n=1;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=0;
							end
						else if	(  (cnt_LOAD%4==0 ||  cnt_LOAD%4==1) && ((cnt_LOAD/28)%4==2 || (cnt_LOAD/28)%4==3) ) begin //A2
								sram_wen_a0_n=1;
								sram_wen_a1_n=1;	
								sram_wen_a2_n=0;
								sram_wen_a3_n=1;
							end
						else if	(  (cnt_LOAD%4==2 ||  cnt_LOAD%4==3) && ((cnt_LOAD/28)%4==0 || (cnt_LOAD/28)%4==1) ) begin //A1
								sram_wen_a0_n=1;
								sram_wen_a1_n=0;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
							end
						else if	(  (cnt_LOAD%4==0 ||  cnt_LOAD%4==1) && ((cnt_LOAD/28)%4==0 || (cnt_LOAD/28)%4==1) ) begin //A0
								sram_wen_a0_n=0;
								sram_wen_a1_n=1;
								sram_wen_a2_n=1;
								sram_wen_a3_n=1;
							end
						else begin sram_wen_a0_n=1; sram_wen_a1_n=1; sram_wen_a2_n=1; sram_wen_a3_n=1;  end
					end
	    default: begin sram_wen_a0_n=1; sram_wen_a1_n=1; sram_wen_a2_n=1; sram_wen_a3_n=1; end
	endcase
end

////// LOAD_IMAGE(set SRAM ADDR) ///////
wire [9:0] num_big_block_row;
wire [9:0] num_small_block;


assign num_big_block_row=(cnt_LOAD)/112;
assign num_small_block=((cnt_LOAD)%112)%28;


always @(*) begin
	case (state) 
		LOAD_IMAGE: begin 
						sram_waddr_a_n= (num_big_block_row*7)+(num_small_block/4)+1-1;
									
					end

		default: begin sram_waddr_a_n=0; end
	endcase
end




///// LOAD_IMAGE (set pixel and bytemask) ////////
always @(*) begin
	case (state)
		LOAD_IMAGE: begin
						if(cnt_LOAD%2 ==0 && (cnt_LOAD/28)%2==1) begin 
							sram_bytemask_a_n=4'b1101;
							sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000,input_data_in ,8'b0000_0000 };
						end
						else if(cnt_LOAD%2 ==1 && (cnt_LOAD/28)%2==1) begin
							sram_bytemask_a_n=4'b1110;
							sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000,input_data_in};
						end
						else if(cnt_LOAD%2 ==0 && (cnt_LOAD/28)%2==0) begin
							sram_bytemask_a_n=4'b0111;
							sram_wdata_a_n={input_data_in,8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000};
						end
						/*
						else if(cnt_LOAD%2 ==1 && (cnt_LOAD/28)%2==0) begin 
							sram_bytemask_a_n=4'b1011;
							sram_wdata_a_n={8'b0000_0000 ,input_data_in,8'b0000_0000 ,8'b0000_0000};
						end
						*/
						else  begin
							sram_bytemask_a_n=4'b1011;
							sram_wdata_a_n={8'b0000_0000 ,input_data_in,8'b0000_0000 ,8'b0000_0000};
						end						
						end

		default: begin sram_bytemask_a_n=4'b1111; sram_wdata_a_n={8'b0000_0000 ,8'b0000_0000 ,8'b0000_0000,8'b0000_0000}; end
	endcase
end



///// LOAD_IMAGE (valid_n) ///////
always @(*) begin
	if (cnt_LOAD==800) valid_n=1;
	else valid_n=0;

end


endmodule
























