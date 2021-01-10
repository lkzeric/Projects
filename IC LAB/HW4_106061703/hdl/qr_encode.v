module qr_encode(
    input           clk,                    //clock input
    input           srstn,                  //synchronous reset (active low)
    input           qr_encode_start,        //start encoding for one QR code
                                            //1: start (one-cycle pulse)
    output  reg     qr_encode_finish,       //1: encoding one QR code is finished

    //sram
    input      [3:0]   sram_rdata,             //read data from SRAM===========input the data from the sram
    output reg [3:0]   sram_wdata,             //write data to SRAM ===========output the data to the sram
	
    output reg [9:0]   sram_raddr,             //read address from SRAM
    output reg [9:0]   sram_waddr,             //write address to SRAM
    output reg         sram_rw_en,             //read-write enable,0:write,1:read
	output reg         sram_csb,               //sram chip enable, active low
    output reg [3:0]   sram_wmask,             //write mask: determine which bit should be writed into sram when operate write
                                            //total bits=4,for each bit, 0:Write to addressed memory location,1:Memory location unchanged
    //jis8 code
    input           jis8_code_end,          //1: represent the end of JIS8 code
    input   [7:0]   jis8_code,              //JIS8 code which need to be encoded
    output reg         get_jis8_code_start     //1: start to get JIS8 code
);






localparam IDLE=9'd0 , DETECT=9'd1, DETECT_1=9'd130;
localparam CHECK_DOWN=9'd2, CHECK_RIGHT=9'd3, CHECK_DOWN_RIGHT=9'd4,EVA=9'd6;
localparam HOLD=9'd7,DETECT_AGAIN=9'd8 ,ORIENT=9'd9,RECORD=9'd10,ADD=9'd11,MASK=9'd12,ENCODE=9'd13,DETECT_SQUARE=9'd14;


localparam BREAK=9'd15,SQUARE_1=9'd16 ,SQUARE_2=9'd17 ,SQUARE_3=9'd18 ,SQUARE_4=9'd19,SQUARE_5=9'd20 ,SQUARE_6=9'd21 ,SQUARE_7=9'd22 ,SQUARE_8=9'd23;
localparam SQUARE_9=9'd24 ,SQUARE_10=9'd25 ,SQUARE_11=9'd26 ,SQUARE_12=9'd27,SQUARE_13=9'd28 ,SQUARE_14=9'd29 ,SQUARE_15=9'd30 ,SQUARE_16=9'd31;
localparam SQUARE_17=9'd32 ,SQUARE_18=9'd33 ,SQUARE_19=9'd34 ,SQUARE_20=9'd35,SQUARE_21=9'd36 ,SQUARE_22=9'd37 ,SQUARE_23=9'd38 ,SQUARE_24=9'd39;
localparam SQUARE_25=9'd40 ,SQUARE_26=9'd41 ,SQUARE_27=9'd42;

//////////////////////////////////////////////////////////
localparam BREAK_A=9'd43, A_SQUARE_1=9'd44 ,A_SQUARE_2=9'd45 ,A_SQUARE_3=9'd46 ,A_SQUARE_4=9'd47,A_SQUARE_5=9'd48 ,A_SQUARE_6=9'd49 ,A_SQUARE_7=9'd50;
localparam A_SQUARE_8=9'd51,A_SQUARE_9=9'd52 ,A_SQUARE_10=9'd53 ,A_SQUARE_11=9'd54 ,A_SQUARE_12=9'd55,A_SQUARE_13=9'd56 ,A_SQUARE_14=9'd57 ;
localparam A_SQUARE_15=9'd58 ,A_SQUARE_16=9'd59,A_SQUARE_17=9'd60 ,A_SQUARE_18=9'd61 ,A_SQUARE_19=9'd62 ,A_SQUARE_20=9'd63,A_SQUARE_21=9'd64 ,A_SQUARE_22=9'd65;
localparam A_SQUARE_23=9'd66 ,A_SQUARE_24=9'd67,A_SQUARE_25=9'd68 ,A_SQUARE_26=9'd69 ,A_SQUARE_27=9'd70;


//////////////////////////////////////////////////////////
localparam BREAK_B=9'd71,B_SQUARE_1=9'd72 ,B_SQUARE_2=9'd73 ,B_SQUARE_3=9'd74 ,B_SQUARE_4=9'd75,B_SQUARE_5=9'd76 ,B_SQUARE_6=9'd77 ,B_SQUARE_7=9'd78 ,
B_SQUARE_8=9'd79;
localparam B_SQUARE_9=9'd80 ,B_SQUARE_10=9'd81 ,B_SQUARE_11=9'd82 ,B_SQUARE_12=9'd83,B_SQUARE_13=9'd84 ,B_SQUARE_14=9'd85 ,B_SQUARE_15=9'd86 ,B_SQUARE_16=9'd87;
localparam B_SQUARE_17=9'd88 ,B_SQUARE_18=9'd89 ,B_SQUARE_19=9'd90 ,B_SQUARE_20=9'd91,B_SQUARE_21=9'd92 ,B_SQUARE_22=9'd93 ,B_SQUARE_23=9'd94 ,B_SQUARE_24=9'd95;
localparam B_SQUARE_25=9'd96 ,B_SQUARE_26=9'd97 ,B_SQUARE_27=9'd98;

//////////////////////////////////////////////////////////
localparam BREAK_C=9'd99,C_SQUARE_1=9'd100 ,C_SQUARE_2=9'd101 ,C_SQUARE_3=9'd102 ,C_SQUARE_4=9'd103,C_SQUARE_5=9'd104 ,C_SQUARE_6=9'd105 ,C_SQUARE_7=9'd106 ,C_SQUARE_8=9'd107;
localparam C_SQUARE_9=9'd108 ,C_SQUARE_10=9'd109 ,C_SQUARE_11=9'd110 ,C_SQUARE_12=9'd111,C_SQUARE_13=9'd112 ,C_SQUARE_14=9'd113 ,
C_SQUARE_15=9'd114 ,C_SQUARE_16=9'd115;
localparam C_SQUARE_17=9'd116 ,C_SQUARE_18=9'd117 ,C_SQUARE_19=9'd118 ,C_SQUARE_20=9'd119,C_SQUARE_21=9'd120 ,C_SQUARE_22=9'd121 ,C_SQUARE_23=9'd122;
localparam C_SQUARE_24=9'd123,C_SQUARE_25=9'd124 ,C_SQUARE_26=9'd125 ,C_SQUARE_27=9'd126;

//////////////////////////////////////////////////////////
localparam BACK_2=9'd150,BACK_1=9'd151,BACK=9'd152,CHECK_LEFT=9'd160,CHECK_DOWN_LEFT=9'd161;



reg [8:0] state,state_n;

reg [9:0] tmp_address,tmp_address_n;
//// INPUT ////
reg qr_encode_start_in;
reg [7:0] jis8_code_in;
reg jis8_code_end_in;


//// OUTPUT ////
wire qr_encode_finish_n;
reg get_jis8_code_start_n;

////////////////////// SRAM parameter //////////////////////
reg  [9:0] sram_raddr_n;
reg  [3:0] sram_rdata_in;

wire   [9:0] sram_waddr_n;
wire   [3:0] sram_wdata_n;
wire   [3:0] sram_wmask_n;


reg sram_rw_en_n;
wire [9:0] raddr;
assign raddr = (sram_raddr != 0) ? sram_raddr -2 : 0; // the address and the data has two cycle delay


/////////////------------ SRAM FUNCTION ------------//////////////
always @(posedge clk) begin
	if (~srstn) begin
		sram_wdata<=0;
		sram_raddr<=0;
		sram_waddr<=0;
		sram_wmask<=0;
		sram_csb<=1;
		sram_rw_en<=0;
		sram_rdata_in<=0;
	end
	else begin
		sram_wdata<=sram_wdata_n;
		sram_raddr<=sram_raddr_n;
		sram_waddr<=sram_waddr_n;
		sram_wmask<=sram_wmask_n;
		sram_csb<=0;
		sram_rw_en<=sram_rw_en_n;
		sram_rdata_in<=sram_rdata;
	end

end

always @(*) begin
	
	if (state==ENCODE) begin sram_rw_en_n=0; end
	else begin sram_rw_en_n=1; end
end 
///////////////////////////////////////////

always @(posedge clk) begin
	if (~srstn) begin 
		qr_encode_start_in<=0;
		qr_encode_finish<=0;
		jis8_code_in<=0;
		jis8_code_end_in<=0;
		get_jis8_code_start<=0;
		
	end
	else begin 
		qr_encode_start_in<=qr_encode_start;
		qr_encode_finish<=qr_encode_finish_n;
		jis8_code_in<=jis8_code;
		jis8_code_end_in<=jis8_code_end;
		get_jis8_code_start<=get_jis8_code_start_n;
	
	end

end






/////////////// DETECT parameter ////////////
reg [5:0] detect_posi_i,detect_posi_j;
reg [5:0] detect_posi_i_n,detect_posi_j_n;


reg [5:0] A_detect_posi_i,A_detect_posi_j;
reg [5:0] A_detect_posi_i_n,A_detect_posi_j_n;

reg [5:0] B_detect_posi_i, B_detect_posi_j;
reg [5:0] B_detect_posi_i_n,B_detect_posi_j_n;

reg [5:0] C_detect_posi_i,C_detect_posi_j;
reg [5:0] C_detect_posi_i_n,C_detect_posi_j_n;

reg search_valid;
reg search_valid_1;
reg search_valid_2;
reg search_valid_3;

reg[2:0] choice,choice_n;








////////////// DETECT_SQUARE  //////////////
reg correct_1,correct_1_n;



wire [5:0] posi_i[3:0];
wire [5:0] posi_j[3:0];
assign posi_i[0]=detect_posi_i;
assign posi_j[0]=detect_posi_j;

assign posi_i[1]=A_detect_posi_i;
assign posi_j[1]=A_detect_posi_j;

assign posi_i[2]=B_detect_posi_i;
assign posi_j[2]=B_detect_posi_j;

assign posi_i[3]=C_detect_posi_i;
assign posi_j[3]=C_detect_posi_j;



wire [5:0] decided_posi_i,decided_posi_j;

assign decided_posi_i=posi_i[choice];
assign decided_posi_j=posi_j[choice];



///////////// CHECK_DOWN parameter ////////////
wire [5:0] check_down_posi_i,check_down_posi_j;
assign check_down_posi_i=decided_posi_i+5'd20;
assign check_down_posi_j=decided_posi_j;
reg down_valid,down_valid_n;



////////// CHECK_RIGHT parameter ///////////////	
wire [5:0] check_right_posi_i,check_right_posi_j;
assign check_right_posi_i=decided_posi_i;
assign check_right_posi_j=decided_posi_j+5'd20;
reg right_valid,right_valid_n;



//////////// CHECK_DOWN_RIGHT parameter ///////////	
wire [5:0] check_down_right_posi_i,check_down_right_posi_j;
assign check_down_right_posi_i=decided_posi_i+5'd20;
assign check_down_right_posi_j=decided_posi_j+5'd20;	
reg down_right_valid,down_right_valid_n;

/////////// CHECK_LEFT parameter ////////////////
wire [5:0] check_left_posi_i,check_left_posi_j;
assign check_left_posi_i=decided_posi_i;
assign check_left_posi_j=decided_posi_j-5'd14;
reg left_valid,left_valid_n;


////////// CHECK_DOWN_LEFT parameter ////////////
wire [5:0] check_down_left_posi_i,check_down_left_posi_j;
assign check_down_left_posi_i=decided_posi_i+5'd20;
assign check_down_left_posi_j=decided_posi_j-5'd14;
reg down_left_valid,down_left_valid_n;



////////// ORIENT parameter ///////////////
reg [2:0] angle, angle_n;

///////// ADD parameter ///////////////////
reg add_finish,add_finish_n;

//////// MASK parameter ///////////////////


reg mask_finish,mask_finish_n;

// 0 degree 
wire [5:0] mask_1_i,mask_2_i,mask_3_i;
wire [5:0] mask_1_j,mask_2_j,mask_3_j;


assign mask_1_i=decided_posi_i+5'd8;
assign mask_1_j=decided_posi_j+5'd2;

assign mask_2_i=decided_posi_i+5'd8;
assign mask_2_j=decided_posi_j+5'd3;

assign mask_3_i=decided_posi_i+5'd8;
assign mask_3_j=decided_posi_j+5'd4;

// 90 degree
wire [5:0] mask_1_i_90,mask_2_i_90,mask_3_i_90;
wire [5:0] mask_1_j_90,mask_2_j_90,mask_3_j_90;


assign mask_1_i_90=decided_posi_i+5'd18;
assign mask_1_j_90=decided_posi_j+5'd8;

assign mask_2_i_90=decided_posi_i+5'd17;
assign mask_2_j_90=decided_posi_j+5'd8;

assign mask_3_i_90=decided_posi_i+5'd16;
assign mask_3_j_90=decided_posi_j+5'd8;


// 180 degree
wire [5:0] mask_1_i_180,mask_2_i_180,mask_3_i_180;
wire [5:0] mask_1_j_180,mask_2_j_180,mask_3_j_180;


assign mask_1_i_180=decided_posi_i+5'd20-5'd8;
assign mask_1_j_180=decided_posi_j-5'd14+5'd18;

assign mask_2_i_180=decided_posi_i+5'd20-5'd8;
assign mask_2_j_180=decided_posi_j-5'd14+5'd17;

assign mask_3_i_180=decided_posi_i+5'd20-5'd8;
assign mask_3_j_180=decided_posi_j-5'd14+5'd16;






// 270 degree
wire [5:0] mask_1_i_270,mask_2_i_270,mask_3_i_270;
wire [5:0] mask_1_j_270,mask_2_j_270,mask_3_j_270;


assign mask_1_i_270=decided_posi_i+5'd2;
assign mask_1_j_270=decided_posi_j+5'd12;

assign mask_2_i_270=decided_posi_i+5'd3;
assign mask_2_j_270=decided_posi_j+5'd12;

assign mask_3_i_270=decided_posi_i+5'd4;
assign mask_3_j_270=decided_posi_j+5'd12;


////////// ENCODE parameter ///////////////
reg place_finish;
	
	


///////////////////////////////////////////


reg [3:0] cnt_LEFT,cnt_LEFT_n;
reg [3:0] cnt_DOWN_LEFT,cnt_DOWN_LEFT_n;

reg [5:0] cnt_SQUARE_1 ,cnt_SQUARE_1_n;
reg [5:0] cnt_DETECT ,cnt_DETECT_n;
reg [3:0] cnt_BREAK,cnt_BREAK_n;
reg [3:0] cnt_DOWN	  ,cnt_DOWN_n;
reg [3:0] cnt_RIGHT	  ,cnt_RIGHT_n;
reg [3:0] cnt_DOWN_RIGHT,cnt_DOWN_RIGHT_n;
reg [3:0] cnt_EVA,cnt_EVA_n;
reg [3:0] cnt_ORIENT, cnt_ORINT_n;
reg [3:0] cnt_HOLD, cnt_HOLD_n;
reg [3:0] cnt_DETECT_AGAIN,cnt_DETECT_AGAIN_n;
reg [5:0] cnt_RECORD, cnt_RECORD_n;
reg [5:0] cnt_MASK,cnt_MASK_n;
always @(posedge clk) begin
	if (~srstn) begin
		
		cnt_DETECT<=0;
		cnt_BREAK<=0;
		cnt_SQUARE_1<=0;
	
	
		cnt_DOWN<=0;
		cnt_RIGHT<=0;
		cnt_DOWN_RIGHT<=0;
		cnt_LEFT<=0;
		cnt_DOWN_LEFT<=0;
		
		
		
		cnt_EVA<=0;
		cnt_ORIENT<=0;
		cnt_HOLD<=0;
		cnt_DETECT_AGAIN<=0;
		cnt_RECORD<=0;
		cnt_MASK<=0;
	end
	else begin
		
		cnt_DETECT<=cnt_DETECT_n;
		cnt_BREAK<=cnt_BREAK_n;
		cnt_SQUARE_1<=cnt_SQUARE_1_n;
	
			
		
		cnt_DOWN<=cnt_DOWN_n;
		cnt_RIGHT<=cnt_RIGHT_n;
		cnt_DOWN_RIGHT<=cnt_DOWN_RIGHT_n;
		cnt_LEFT<=cnt_LEFT_n;
		cnt_DOWN_LEFT<=cnt_DOWN_LEFT_n;
		
		
		
		cnt_EVA<=cnt_EVA_n;
		cnt_ORIENT<=cnt_ORINT_n;
		cnt_HOLD<=cnt_HOLD_n;
		cnt_DETECT_AGAIN<=cnt_DETECT_AGAIN_n;
		cnt_RECORD<=cnt_RECORD_n;
		cnt_MASK<=cnt_MASK_n;
	end
end

always @(*) begin
	
	cnt_DETECT_n=0;
	cnt_BREAK_n=0;
	cnt_SQUARE_1_n=0;
	
	
	cnt_DOWN_n=0; cnt_RIGHT_n=0; cnt_DOWN_RIGHT_n=0;
	cnt_LEFT_n=0;cnt_DOWN_LEFT_n=0;
	
	
	cnt_EVA_n=0 ; cnt_ORINT_n=0; cnt_HOLD_n=0; 
	cnt_DETECT_AGAIN_n=0; cnt_RECORD_n=0;cnt_MASK_n=0;
	
	case(state)
		
		///////////////////////////////////////////////
		  DETECT:   	cnt_DETECT_n=cnt_DETECT+1;
		   BREAK:   cnt_BREAK_n=cnt_BREAK+1;
		   
		   
		SQUARE_1:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_2:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_3:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_4:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		SQUARE_5:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_6:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_7:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_8:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_9:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_10:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_11:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_12:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_13:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_14:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_15:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_16:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_17:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_18:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		SQUARE_19:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_20:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_21:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_22:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_23:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_24:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_25:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		SQUARE_26:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		SQUARE_27:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		
		////////////////////////////////////////////////
					
		   BREAK_A:   cnt_BREAK_n=cnt_BREAK+1;
		   
		   
		A_SQUARE_1:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_2:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_3:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_4:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		A_SQUARE_5:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_6:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_7:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_8:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_9:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_10:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_11:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_12:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_13:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_14:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_15:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_16:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_17:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_18:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		A_SQUARE_19:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_20:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_21:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_22:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_23:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_24:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_25:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		A_SQUARE_26:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		A_SQUARE_27:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		
		
		////////////////////////////////////////////////			
		   BREAK_B:   cnt_BREAK_n=cnt_BREAK+1;	
				
		B_SQUARE_1:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_2:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_3:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_4:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		B_SQUARE_5:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_6:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_7:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_8:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_9:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_10:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_11:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_12:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_13:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_14:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_15:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_16:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_17:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_18:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		B_SQUARE_19:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_20:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_21:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_22:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_23:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_24:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_25:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		B_SQUARE_26:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		B_SQUARE_27:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
			
		
		////////////////////////////////////////////////
		
		   BREAK_C:  cnt_BREAK_n=cnt_BREAK+1;	
							
					  
		
		C_SQUARE_1:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_2:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_3:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_4:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		C_SQUARE_5:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_6:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_7:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_8:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_9:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_10:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_11:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_12:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_13:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_14:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_15:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_16:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_17:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_18:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;		
		C_SQUARE_19:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_20:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_21:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_22:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_23:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_24:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_25:   cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;			
		C_SQUARE_26:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		C_SQUARE_27:  cnt_SQUARE_1_n=(cnt_SQUARE_1<4)?cnt_SQUARE_1+1:0;
		
		
		////////////////////////////////////////////////
		
		
	
		CHECK_DOWN:  	  cnt_DOWN_n=cnt_DOWN+1;
		CHECK_RIGHT: 	  cnt_RIGHT_n=cnt_RIGHT+1;
		CHECK_DOWN_RIGHT: cnt_DOWN_RIGHT_n=cnt_DOWN_RIGHT+1;
		CHECK_LEFT: 	  cnt_LEFT_n=cnt_LEFT+1;
		CHECK_DOWN_LEFT:  cnt_DOWN_LEFT_n=cnt_DOWN_LEFT+1;
		
		
		
					 EVA: cnt_EVA_n=cnt_EVA+1;
				  ORIENT: cnt_ORINT_n=cnt_ORIENT+1;
				    HOLD: cnt_HOLD_n=cnt_HOLD+1;
			DETECT_AGAIN: cnt_DETECT_AGAIN_n=cnt_DETECT_AGAIN+1;
				  RECORD: cnt_RECORD_n=cnt_RECORD+1;
				    MASK: cnt_MASK_n=cnt_MASK+1;
					
  		default: begin cnt_DETECT_n=0; cnt_BREAK_n=0; cnt_SQUARE_1_n=0; 
					   cnt_DOWN_n=0; cnt_RIGHT_n=0; cnt_DOWN_RIGHT_n=0;	cnt_LEFT_n=0;cnt_DOWN_LEFT_n=0;
					   cnt_EVA_n=0;cnt_ORINT_n=0; cnt_HOLD_n=0; cnt_DETECT_AGAIN_n=0; 
					   cnt_RECORD_n=0;cnt_MASK_n=0;end
	endcase
end

///////////////////////// STATE FUNCTION ////////////////////////////
always @(posedge clk) begin
	if (~srstn) begin
		state<=IDLE;
	
	end
	else begin
		state<=state_n;
	
	end

end

always @(*) begin
	case(state)
		IDLE:    state_n=(qr_encode_start_in)?DETECT:IDLE;
		DETECT:  begin 
					if (search_valid==1) state_n=SQUARE_1;
					else if (search_valid_1==1) state_n=A_SQUARE_1;
					else if (search_valid_2==1) state_n=B_SQUARE_1;
					else if (search_valid_3==1) state_n=C_SQUARE_1;
					else state_n=DETECT;
				 		 
				 end
		
		BREAK:   state_n=A_SQUARE_1;
		
		
		
		SQUARE_1: state_n=(cnt_SQUARE_1<4)?SQUARE_1:((correct_1==0)?BREAK:SQUARE_2);			
		SQUARE_2: state_n=(cnt_SQUARE_1<4)?SQUARE_2:((correct_1==0)?BREAK:SQUARE_3); 				
		SQUARE_3: state_n=(cnt_SQUARE_1<4)?SQUARE_3:((correct_1==0)?BREAK:SQUARE_4);	
		SQUARE_4: state_n=(cnt_SQUARE_1<4)?SQUARE_4:((correct_1==0)?BREAK:SQUARE_5);			
		SQUARE_5: state_n=(cnt_SQUARE_1<4)?SQUARE_5:((correct_1==0)?BREAK:SQUARE_6); 				
		SQUARE_6: state_n=(cnt_SQUARE_1<4)?SQUARE_6:((correct_1==0)?BREAK:SQUARE_7);
		SQUARE_7: state_n=(cnt_SQUARE_1<4)?SQUARE_7:((correct_1==0)?BREAK:SQUARE_8);			
		SQUARE_8: state_n=(cnt_SQUARE_1<4)?SQUARE_8:((correct_1==0)?BREAK:SQUARE_9); 				
		SQUARE_9: state_n=(cnt_SQUARE_1<4)?SQUARE_9:((correct_1==0)?BREAK:SQUARE_10);
		SQUARE_10: state_n=(cnt_SQUARE_1<4)?SQUARE_10:((correct_1==0)?BREAK:SQUARE_11);			
		SQUARE_11: state_n=(cnt_SQUARE_1<4)?SQUARE_11:((correct_1==0)?BREAK:SQUARE_12); 				
		SQUARE_12: state_n=(cnt_SQUARE_1<4)?SQUARE_12:((correct_1==0)?BREAK:SQUARE_13);
		SQUARE_13: state_n=(cnt_SQUARE_1<4)?SQUARE_13:((correct_1==0)?BREAK:SQUARE_14);			
		SQUARE_14: state_n=(cnt_SQUARE_1<4)?SQUARE_14:((correct_1==0)?BREAK:SQUARE_15); 				
		SQUARE_15: state_n=(cnt_SQUARE_1<4)?SQUARE_15:((correct_1==0)?BREAK:SQUARE_16);		
		SQUARE_16: state_n=(cnt_SQUARE_1<4)?SQUARE_16:((correct_1==0)?BREAK:SQUARE_17);			
		SQUARE_17: state_n=(cnt_SQUARE_1<4)?SQUARE_17:((correct_1==0)?BREAK:SQUARE_18); 				
		SQUARE_18: state_n=(cnt_SQUARE_1<4)?SQUARE_18:((correct_1==0)?BREAK:SQUARE_19);
		SQUARE_19: state_n=(cnt_SQUARE_1<4)?SQUARE_19:((correct_1==0)?BREAK:SQUARE_20);			
		SQUARE_20: state_n=(cnt_SQUARE_1<4)?SQUARE_20:((correct_1==0)?BREAK:SQUARE_21); 				
		SQUARE_21: state_n=(cnt_SQUARE_1<4)?SQUARE_21:((correct_1==0)?BREAK:SQUARE_22);
		SQUARE_22: state_n=(cnt_SQUARE_1<4)?SQUARE_22:((correct_1==0)?BREAK:SQUARE_23);			
		SQUARE_23: state_n=(cnt_SQUARE_1<4)?SQUARE_23:((correct_1==0)?BREAK:SQUARE_24); 				
		SQUARE_24: state_n=(cnt_SQUARE_1<4)?SQUARE_24:((correct_1==0)?BREAK:SQUARE_25);
		SQUARE_25: state_n=(cnt_SQUARE_1<4)?SQUARE_25:((correct_1==0)?BREAK:SQUARE_26);			
		SQUARE_26: state_n=(cnt_SQUARE_1<4)?SQUARE_26:((correct_1==0)?BREAK:SQUARE_27); 		
		SQUARE_27: state_n=(cnt_SQUARE_1<4)?SQUARE_27:((correct_1==0)?BREAK:CHECK_DOWN);
		
		///////////////////////////////////////////////////////////////////////////////////////
		
		BREAK_A:state_n=B_SQUARE_1;
		
		A_SQUARE_1: state_n=(cnt_SQUARE_1<4)?A_SQUARE_1:((correct_1==0)?BREAK_A:A_SQUARE_2);			
		A_SQUARE_2: state_n=(cnt_SQUARE_1<4)?A_SQUARE_2:((correct_1==0)?BREAK_A:A_SQUARE_3); 				
		A_SQUARE_3: state_n=(cnt_SQUARE_1<4)?A_SQUARE_3:((correct_1==0)?BREAK_A:A_SQUARE_4);	
		A_SQUARE_4: state_n=(cnt_SQUARE_1<4)?A_SQUARE_4:((correct_1==0)?BREAK_A:A_SQUARE_5);			
		A_SQUARE_5: state_n=(cnt_SQUARE_1<4)?A_SQUARE_5:((correct_1==0)?BREAK_A:A_SQUARE_6); 				
		A_SQUARE_6: state_n=(cnt_SQUARE_1<4)?A_SQUARE_6:((correct_1==0)?BREAK_A:A_SQUARE_7);
		A_SQUARE_7: state_n=(cnt_SQUARE_1<4)?A_SQUARE_7:((correct_1==0)?BREAK_A:A_SQUARE_8);			
		A_SQUARE_8: state_n=(cnt_SQUARE_1<4)?A_SQUARE_8:((correct_1==0)?BREAK_A:A_SQUARE_9); 				
		A_SQUARE_9: state_n=(cnt_SQUARE_1<4)?A_SQUARE_9:((correct_1==0)?BREAK_A:A_SQUARE_10);
		A_SQUARE_10: state_n=(cnt_SQUARE_1<4)?A_SQUARE_10:((correct_1==0)?BREAK_A:A_SQUARE_11);			
		A_SQUARE_11: state_n=(cnt_SQUARE_1<4)?A_SQUARE_11:((correct_1==0)?BREAK_A:A_SQUARE_12); 				
		A_SQUARE_12: state_n=(cnt_SQUARE_1<4)?A_SQUARE_12:((correct_1==0)?BREAK_A:A_SQUARE_13);
		A_SQUARE_13: state_n=(cnt_SQUARE_1<4)?A_SQUARE_13:((correct_1==0)?BREAK_A:A_SQUARE_14);			
		A_SQUARE_14: state_n=(cnt_SQUARE_1<4)?A_SQUARE_14:((correct_1==0)?BREAK_A:A_SQUARE_15); 				
		A_SQUARE_15: state_n=(cnt_SQUARE_1<4)?A_SQUARE_15:((correct_1==0)?BREAK_A:A_SQUARE_16);		
		A_SQUARE_16: state_n=(cnt_SQUARE_1<4)?A_SQUARE_16:((correct_1==0)?BREAK_A:A_SQUARE_17);			
		A_SQUARE_17: state_n=(cnt_SQUARE_1<4)?A_SQUARE_17:((correct_1==0)?BREAK_A:A_SQUARE_18); 				
		A_SQUARE_18: state_n=(cnt_SQUARE_1<4)?A_SQUARE_18:((correct_1==0)?BREAK_A:A_SQUARE_19);
		A_SQUARE_19: state_n=(cnt_SQUARE_1<4)?A_SQUARE_19:((correct_1==0)?BREAK_A:A_SQUARE_20);			
		A_SQUARE_20: state_n=(cnt_SQUARE_1<4)?A_SQUARE_20:((correct_1==0)?BREAK_A:A_SQUARE_21); 				
		A_SQUARE_21: state_n=(cnt_SQUARE_1<4)?A_SQUARE_21:((correct_1==0)?BREAK_A:A_SQUARE_22);
		A_SQUARE_22: state_n=(cnt_SQUARE_1<4)?A_SQUARE_22:((correct_1==0)?BREAK_A:A_SQUARE_23);			
		A_SQUARE_23: state_n=(cnt_SQUARE_1<4)?A_SQUARE_23:((correct_1==0)?BREAK_A:A_SQUARE_24); 				
		A_SQUARE_24: state_n=(cnt_SQUARE_1<4)?A_SQUARE_24:((correct_1==0)?BREAK_A:A_SQUARE_25);
		A_SQUARE_25: state_n=(cnt_SQUARE_1<4)?A_SQUARE_25:((correct_1==0)?BREAK_A:A_SQUARE_26);			
		A_SQUARE_26: state_n=(cnt_SQUARE_1<4)?A_SQUARE_26:((correct_1==0)?BREAK_A:A_SQUARE_27); 		
		A_SQUARE_27: state_n=(cnt_SQUARE_1<4)?A_SQUARE_27:((correct_1==0)?BREAK_A:CHECK_DOWN);
			
		///////////////////////////////////////////////////////////////////////////////////


		BREAK_B:state_n=C_SQUARE_1;
		
		B_SQUARE_1: state_n=(cnt_SQUARE_1<4)?B_SQUARE_1:((correct_1==0)?BREAK_B:B_SQUARE_2);			
		B_SQUARE_2: state_n=(cnt_SQUARE_1<4)?B_SQUARE_2:((correct_1==0)?BREAK_B:B_SQUARE_3); 				
		B_SQUARE_3: state_n=(cnt_SQUARE_1<4)?B_SQUARE_3:((correct_1==0)?BREAK_B:B_SQUARE_4);	
		B_SQUARE_4: state_n=(cnt_SQUARE_1<4)?B_SQUARE_4:((correct_1==0)?BREAK_B:B_SQUARE_5);			
		B_SQUARE_5: state_n=(cnt_SQUARE_1<4)?B_SQUARE_5:((correct_1==0)?BREAK_B:B_SQUARE_6); 				
		B_SQUARE_6: state_n=(cnt_SQUARE_1<4)?B_SQUARE_6:((correct_1==0)?BREAK_B:B_SQUARE_7);
		B_SQUARE_7: state_n=(cnt_SQUARE_1<4)?B_SQUARE_7:((correct_1==0)?BREAK_B:B_SQUARE_8);			
		B_SQUARE_8: state_n=(cnt_SQUARE_1<4)?B_SQUARE_8:((correct_1==0)?BREAK_B:B_SQUARE_9); 				
		B_SQUARE_9: state_n=(cnt_SQUARE_1<4)?B_SQUARE_9:((correct_1==0)?BREAK_B:B_SQUARE_10);
		B_SQUARE_10: state_n=(cnt_SQUARE_1<4)?B_SQUARE_10:((correct_1==0)?BREAK_B:B_SQUARE_11);			
		B_SQUARE_11: state_n=(cnt_SQUARE_1<4)?B_SQUARE_11:((correct_1==0)?BREAK_B:B_SQUARE_12); 				
		B_SQUARE_12: state_n=(cnt_SQUARE_1<4)?B_SQUARE_12:((correct_1==0)?BREAK_B:B_SQUARE_13);
		B_SQUARE_13: state_n=(cnt_SQUARE_1<4)?B_SQUARE_13:((correct_1==0)?BREAK_B:B_SQUARE_14);			
		B_SQUARE_14: state_n=(cnt_SQUARE_1<4)?B_SQUARE_14:((correct_1==0)?BREAK_B:B_SQUARE_15); 				
		B_SQUARE_15: state_n=(cnt_SQUARE_1<4)?B_SQUARE_15:((correct_1==0)?BREAK_B:B_SQUARE_16);		
		B_SQUARE_16: state_n=(cnt_SQUARE_1<4)?B_SQUARE_16:((correct_1==0)?BREAK_B:B_SQUARE_17);			
		B_SQUARE_17: state_n=(cnt_SQUARE_1<4)?B_SQUARE_17:((correct_1==0)?BREAK_B:B_SQUARE_18); 				
		B_SQUARE_18: state_n=(cnt_SQUARE_1<4)?B_SQUARE_18:((correct_1==0)?BREAK_B:B_SQUARE_19);
		B_SQUARE_19: state_n=(cnt_SQUARE_1<4)?B_SQUARE_19:((correct_1==0)?BREAK_B:B_SQUARE_20);			
		B_SQUARE_20: state_n=(cnt_SQUARE_1<4)?B_SQUARE_20:((correct_1==0)?BREAK_B:B_SQUARE_21); 				
		B_SQUARE_21: state_n=(cnt_SQUARE_1<4)?B_SQUARE_21:((correct_1==0)?BREAK_B:B_SQUARE_22);
		B_SQUARE_22: state_n=(cnt_SQUARE_1<4)?B_SQUARE_22:((correct_1==0)?BREAK_B:B_SQUARE_23);			
		B_SQUARE_23: state_n=(cnt_SQUARE_1<4)?B_SQUARE_23:((correct_1==0)?BREAK_B:B_SQUARE_24); 				
		B_SQUARE_24: state_n=(cnt_SQUARE_1<4)?B_SQUARE_24:((correct_1==0)?BREAK_B:B_SQUARE_25);
		B_SQUARE_25: state_n=(cnt_SQUARE_1<4)?B_SQUARE_25:((correct_1==0)?BREAK_B:B_SQUARE_26);			
		B_SQUARE_26: state_n=(cnt_SQUARE_1<4)?B_SQUARE_26:((correct_1==0)?BREAK_B:B_SQUARE_27); 		
		B_SQUARE_27: state_n=(cnt_SQUARE_1<4)?B_SQUARE_27:((correct_1==0)?BREAK_B:CHECK_DOWN);
		
		///////////////////////////////////////////////////////////////////////////////////
		
		BREAK_C: state_n=DETECT;
		
		C_SQUARE_1: state_n=(cnt_SQUARE_1<4)?C_SQUARE_1:((correct_1==0)?BREAK_C:C_SQUARE_2);			
		C_SQUARE_2: state_n=(cnt_SQUARE_1<4)?C_SQUARE_2:((correct_1==0)?BREAK_C:C_SQUARE_3); 				
		C_SQUARE_3: state_n=(cnt_SQUARE_1<4)?C_SQUARE_3:((correct_1==0)?BREAK_C:C_SQUARE_4);	
		C_SQUARE_4: state_n=(cnt_SQUARE_1<4)?C_SQUARE_4:((correct_1==0)?BREAK_C:C_SQUARE_5);			
		C_SQUARE_5: state_n=(cnt_SQUARE_1<4)?C_SQUARE_5:((correct_1==0)?BREAK_C:C_SQUARE_6); 				
		C_SQUARE_6: state_n=(cnt_SQUARE_1<4)?C_SQUARE_6:((correct_1==0)?BREAK_C:C_SQUARE_7);
		C_SQUARE_7: state_n=(cnt_SQUARE_1<4)?C_SQUARE_7:((correct_1==0)?BREAK_C:C_SQUARE_8);			
		C_SQUARE_8: state_n=(cnt_SQUARE_1<4)?C_SQUARE_8:((correct_1==0)?BREAK_C:C_SQUARE_9); 				
		C_SQUARE_9: state_n=(cnt_SQUARE_1<4)?C_SQUARE_9:((correct_1==0)?BREAK_C:C_SQUARE_10);
		C_SQUARE_10: state_n=(cnt_SQUARE_1<4)?C_SQUARE_10:((correct_1==0)?BREAK_C:C_SQUARE_11);			
		C_SQUARE_11: state_n=(cnt_SQUARE_1<4)?C_SQUARE_11:((correct_1==0)?BREAK_C:C_SQUARE_12); 				
		C_SQUARE_12: state_n=(cnt_SQUARE_1<4)?C_SQUARE_12:((correct_1==0)?BREAK_C:C_SQUARE_13);
		C_SQUARE_13: state_n=(cnt_SQUARE_1<4)?C_SQUARE_13:((correct_1==0)?BREAK_C:C_SQUARE_14);			
		C_SQUARE_14: state_n=(cnt_SQUARE_1<4)?C_SQUARE_14:((correct_1==0)?BREAK_C:C_SQUARE_15); 				
		C_SQUARE_15: state_n=(cnt_SQUARE_1<4)?C_SQUARE_15:((correct_1==0)?BREAK_C:C_SQUARE_16);		
		C_SQUARE_16: state_n=(cnt_SQUARE_1<4)?C_SQUARE_16:((correct_1==0)?BREAK_C:C_SQUARE_17);			
		C_SQUARE_17: state_n=(cnt_SQUARE_1<4)?C_SQUARE_17:((correct_1==0)?BREAK_C:C_SQUARE_18); 				
		C_SQUARE_18: state_n=(cnt_SQUARE_1<4)?C_SQUARE_18:((correct_1==0)?BREAK_C:C_SQUARE_19);
		C_SQUARE_19: state_n=(cnt_SQUARE_1<4)?C_SQUARE_19:((correct_1==0)?BREAK_C:C_SQUARE_20);			
		C_SQUARE_20: state_n=(cnt_SQUARE_1<4)?C_SQUARE_20:((correct_1==0)?BREAK_C:C_SQUARE_21); 
		
		C_SQUARE_21: state_n=(cnt_SQUARE_1<4)?C_SQUARE_21:((correct_1==0)?BREAK_C:C_SQUARE_22);
		C_SQUARE_22: state_n=(cnt_SQUARE_1<4)?C_SQUARE_22:((correct_1==0)?BREAK_C:C_SQUARE_23);			
		C_SQUARE_23: state_n=(cnt_SQUARE_1<4)?C_SQUARE_23:((correct_1==0)?BREAK_C:C_SQUARE_24); 				
		C_SQUARE_24: state_n=(cnt_SQUARE_1<4)?C_SQUARE_24:((correct_1==0)?BREAK_C:C_SQUARE_25);
		C_SQUARE_25: state_n=(cnt_SQUARE_1<4)?C_SQUARE_25:((correct_1==0)?BREAK_C:C_SQUARE_26);			
		C_SQUARE_26: state_n=(cnt_SQUARE_1<4)?C_SQUARE_26:((correct_1==0)?BREAK_C:C_SQUARE_27); 		
		C_SQUARE_27: state_n=(cnt_SQUARE_1<4)?C_SQUARE_27:((correct_1==0)?BREAK_C:CHECK_DOWN);
		
		
		
		///////////////////////////////////////////////////////////////////////////////////	
		
		CHECK_DOWN:   state_n=(cnt_DOWN<5)?CHECK_DOWN: CHECK_RIGHT;  
					 
				 
	 	CHECK_RIGHT:  state_n=(cnt_RIGHT<5)?CHECK_RIGHT: CHECK_DOWN_RIGHT;
			
		
		CHECK_DOWN_RIGHT: state_n=(cnt_DOWN_RIGHT<5)?CHECK_DOWN_RIGHT: CHECK_LEFT;
		
		CHECK_LEFT:       state_n=(cnt_LEFT<5)?CHECK_LEFT:CHECK_DOWN_LEFT;
		
		CHECK_DOWN_LEFT:  state_n=(cnt_DOWN_LEFT<5)?CHECK_DOWN_LEFT:ORIENT;
		

				  ORIENT: state_n=(cnt_ORIENT<5)?ORIENT:RECORD;
				  RECORD: state_n=(jis8_code_end_in)?ADD:RECORD;
					 ADD: state_n=(add_finish)? MASK:ADD;
					MASK: state_n=(mask_finish)?ENCODE:MASK;
				  ENCODE: state_n=(qr_encode_finish)? IDLE:ENCODE;
				  
				  
		default  state_n=IDLE;

	endcase
end 




reg [5:0] ii,jj;

wire [9:0] square_i,square_j;
assign square_i=detect_posi_i+ii;
assign square_j=detect_posi_j+jj;

wire [9:0] A_square_i,A_square_j;
assign A_square_i=A_detect_posi_i+ii;
assign A_square_j=A_detect_posi_j+jj;

wire [9:0] B_square_i,B_square_j;
assign B_square_i=B_detect_posi_i+ii;
assign B_square_j=B_detect_posi_j+jj;

wire [9:0] C_square_i,C_square_j;
assign C_square_i=C_detect_posi_i+ii;
assign C_square_j=C_detect_posi_j+jj;



always@(posedge clk) begin
	if (~srstn) tmp_address<=0;
	else tmp_address<=tmp_address_n;

end

///address control
always@(*)begin

	tmp_address_n=tmp_address;
	ii=0;
	jj=0;

	case(state)
		IDLE: begin sram_raddr_n = 0; tmp_address_n=0; end

		DETECT:  begin 
				   
				  sram_raddr_n = sram_raddr + 1; tmp_address_n=sram_raddr; 
				 end
			
		SQUARE_1: begin ii=0;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_2: begin ii=0;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_3: begin ii=0;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end		
		SQUARE_4: begin ii=0;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_5: begin ii=0;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_6: begin ii=0;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		
		SQUARE_7: begin ii=1;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_8: begin ii=1;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_9: begin ii=1;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_10: begin ii=1;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_11: begin ii=1;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_12: begin ii=1;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_13: begin ii=1;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		
		
		SQUARE_14: begin ii=2;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_15: begin ii=2;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_16: begin ii=2;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_17: begin ii=2;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_18: begin ii=2;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_19: begin ii=2;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_20: begin ii=2;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		
		
		SQUARE_21: begin ii=3;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_22: begin ii=3;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_23: begin ii=3;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_24: begin ii=3;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_25: begin ii=3;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_26: begin ii=3;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		SQUARE_27: begin ii=3;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{square_i[5:1],square_j[5:1]}:0; end
		/////////////////////////////////////////////////////////////////////////////////////
		
		BREAK_A: sram_raddr_n=0;
			
		A_SQUARE_1: begin ii=0;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_2: begin ii=0;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_3: begin ii=0;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end		
		A_SQUARE_4: begin ii=0;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_5: begin ii=0;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_6: begin ii=0;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		
		A_SQUARE_7: begin ii=1;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_8: begin ii=1;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_9: begin ii=1;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_10: begin ii=1;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_11: begin ii=1;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_12: begin ii=1;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_13: begin ii=1;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		
		
		A_SQUARE_14: begin ii=2;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_15: begin ii=2;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_16: begin ii=2;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_17: begin ii=2;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_18: begin ii=2;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_19: begin ii=2;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_20: begin ii=2;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		
		A_SQUARE_21: begin ii=3;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_22: begin ii=3;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_23: begin ii=3;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_24: begin ii=3;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_25: begin ii=3;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_26: begin ii=3;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
		A_SQUARE_27: begin ii=3;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{A_square_i[5:1],A_square_j[5:1]}:0; end
	
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		
		
		BREAK_B: sram_raddr_n=0;
			
		B_SQUARE_1: begin ii=0;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_2: begin ii=0;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_3: begin ii=0;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end		
		B_SQUARE_4: begin ii=0;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_5: begin ii=0;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_6: begin ii=0;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		
		B_SQUARE_7: begin ii=1;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_8: begin ii=1;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_9: begin ii=1;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_10: begin ii=1;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_11: begin ii=1;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_12: begin ii=1;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_13: begin ii=1;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		
		
		B_SQUARE_14: begin ii=2;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_15: begin ii=2;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_16: begin ii=2;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_17: begin ii=2;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_18: begin ii=2;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_19: begin ii=2;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_20: begin ii=2;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		
		
		B_SQUARE_21: begin ii=3;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_22: begin ii=3;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_23: begin ii=3;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_24: begin ii=3;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_25: begin ii=3;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_26: begin ii=3;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		B_SQUARE_27: begin ii=3;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{B_square_i[5:1],B_square_j[5:1]}:0; end
		

		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		BREAK_C:  sram_raddr_n=tmp_address-1;
		//BREAK_C:  sram_raddr_n=0;
				 
				 
				 
				 
		C_SQUARE_1: begin ii=0;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_2: begin ii=0;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_3: begin ii=0;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end		
		C_SQUARE_4: begin ii=0;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_5: begin ii=0;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_6: begin ii=0;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		
		C_SQUARE_7: begin ii=1;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_8: begin ii=1;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_9: begin ii=1;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_10: begin ii=1;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_11: begin ii=1;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_12: begin ii=1;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_13: begin ii=1;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		
		
		C_SQUARE_14: begin ii=2;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_15: begin ii=2;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_16: begin ii=2;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_17: begin ii=2;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_18: begin ii=2;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_19: begin ii=2;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_20: begin ii=2;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		
		
		C_SQUARE_21: begin ii=3;jj=0; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_22: begin ii=3;jj=1; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_23: begin ii=3;jj=2; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_24: begin ii=3;jj=3; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_25: begin ii=3;jj=4; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_26: begin ii=3;jj=5; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		C_SQUARE_27: begin ii=3;jj=6; sram_raddr_n=(cnt_SQUARE_1<2)?{C_square_i[5:1],C_square_j[5:1]}:0; end
		
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		CHECK_DOWN:       sram_raddr_n = {check_down_posi_i[5:1] , check_down_posi_j[5:1]};
		CHECK_RIGHT:      sram_raddr_n = {check_right_posi_i[5:1] , check_right_posi_j[5:1]};
		CHECK_DOWN_RIGHT: sram_raddr_n = {check_down_right_posi_i[5:1] , check_down_right_posi_j[5:1]};
		CHECK_LEFT:       sram_raddr_n = {check_left_posi_i[5:1] , check_left_posi_j[5:1]};
		CHECK_DOWN_LEFT:  sram_raddr_n = {check_down_left_posi_i[5:1] , check_down_left_posi_j[5:1]};
		/*
		
					HOLD: sram_raddr_n = {hold_posi_i[5:1] , hold_posi_j[5:1]};
			DETECT_AGAIN: sram_raddr_n = sram_raddr+1;	
			
		*/
					MASK: begin 	
							if (angle==3'b001) begin
								if (cnt_MASK==1) begin sram_raddr_n= {mask_1_i[5:1] , mask_1_j[5:1]};end 
								else if (cnt_MASK==2) begin sram_raddr_n= {mask_2_i[5:1] , mask_2_j[5:1]}; end
								else if (cnt_MASK==3) begin sram_raddr_n= {mask_3_i[5:1] , mask_3_j[5:1]};end
								else sram_raddr_n=0;
							end
							else if (angle==3'b010) begin
								if (cnt_MASK==1) begin sram_raddr_n= {mask_1_i_90[5:1] , mask_1_j_90[5:1]};end 
								else if (cnt_MASK==2) begin sram_raddr_n= {mask_2_i_90[5:1] , mask_2_j_90[5:1]}; end
								else if (cnt_MASK==3) begin sram_raddr_n= {mask_3_i_90[5:1] , mask_3_j_90[5:1]};end
								else sram_raddr_n=0;
							end	
							else if (angle==3'b011) begin
								if (cnt_MASK==1) begin sram_raddr_n= {mask_1_i_180[5:1] , mask_1_j_180[5:1]};end 
								else if (cnt_MASK==2) begin sram_raddr_n= {mask_2_i_180[5:1] , mask_2_j_180[5:1]}; end
								else if (cnt_MASK==3) begin sram_raddr_n= {mask_3_i_180[5:1] , mask_3_j_180[5:1]};end
								else sram_raddr_n=0;
							end	
							else if (angle==3'b100) begin
								if (cnt_MASK==1) begin sram_raddr_n= {mask_1_i_270[5:1] , mask_1_j_270[5:1]};end 
								else if (cnt_MASK==2) begin sram_raddr_n= {mask_2_i_270[5:1] , mask_2_j_270[5:1]}; end
								else if (cnt_MASK==3) begin sram_raddr_n= {mask_3_i_270[5:1] , mask_3_j_270[5:1]};end
								else sram_raddr_n=0;		
							end
							
							else begin sram_raddr_n=0; end
						  end
		default: begin sram_raddr_n = 0; tmp_address_n=tmp_address; end
	endcase
end

//////////////////////////////////////////////////////////////////////////////////


//////////// DETECT(find the top left point of the qr code)
	
always@(posedge clk)begin
	if(~srstn)  begin
		detect_posi_i <= 0;
		detect_posi_j <= 0;
		A_detect_posi_i <= 0;
		A_detect_posi_j <= 0;
		B_detect_posi_i <= 0;
		B_detect_posi_j <= 0;
		C_detect_posi_i <= 0;
		C_detect_posi_j <= 0;
	end
	else begin	
		detect_posi_i <= detect_posi_i_n;
		detect_posi_j <= detect_posi_j_n;
		A_detect_posi_i <= A_detect_posi_i_n;
		A_detect_posi_j <= A_detect_posi_j_n;
		B_detect_posi_i <= B_detect_posi_i_n;
		B_detect_posi_j <= B_detect_posi_j_n;
		C_detect_posi_i <= C_detect_posi_i_n;
		C_detect_posi_j <= C_detect_posi_j_n;
	end
end
always@(*)begin
	if(state == DETECT && cnt_DETECT>1) begin
		if(sram_rdata_in[0]==1)	begin detect_posi_i_n={raddr[9:5],1'b0}; detect_posi_j_n= {raddr[4:0],1'b0};search_valid = 1;end
	
		else begin detect_posi_i_n=0; detect_posi_j_n=0;search_valid = 0; search_valid_1=0; 
				   
		end
	end
	
	if(state == DETECT && cnt_DETECT>1) begin
		
		if(sram_rdata_in[1]==1)	begin A_detect_posi_i_n={raddr[9:5],1'b0}; A_detect_posi_j_n= {raddr[4:0],1'b1};search_valid_1 = 1;end

		else begin search_valid_1=0; 
				   A_detect_posi_i_n=0; A_detect_posi_j_n=0; 
		end
	end
	
	if(state == DETECT && cnt_DETECT>1) begin
		
		if(sram_rdata_in[2]==1)	begin B_detect_posi_i_n={raddr[9:5],1'b1}; B_detect_posi_j_n= {raddr[4:0],1'b0};search_valid_2 = 1;end

		else begin search_valid_2=0; 
				   B_detect_posi_i_n=0; B_detect_posi_j_n=0;
		end
	end
	
	if(state == DETECT && cnt_DETECT>1) begin
		
		if(sram_rdata_in[3]==1)	begin C_detect_posi_i_n={raddr[9:5],1'b1}; C_detect_posi_j_n= {raddr[4:0],1'b1};search_valid_3= 1;end
		else begin search_valid_3=0; 
				  C_detect_posi_i_n=0; C_detect_posi_j_n=0;
		end
	end
	
	
	
	
	else  begin detect_posi_i_n=detect_posi_i ; detect_posi_j_n=detect_posi_j ;search_valid = 0;search_valid_1=0; search_valid_2=0; search_valid_3=0;
				 A_detect_posi_i_n=A_detect_posi_i; A_detect_posi_j_n=A_detect_posi_j;
				 B_detect_posi_i_n=B_detect_posi_i; B_detect_posi_j_n=B_detect_posi_j;
				 C_detect_posi_i_n=C_detect_posi_i; C_detect_posi_j_n=C_detect_posi_j;
		end
	
end






////////////////// SQUARE ///////////////////
always@(posedge clk) begin
	if (~srstn) begin 
		correct_1<=0;
		choice<=0;
		
	end
	else begin
		correct_1<=correct_1_n;
		choice<=choice_n;
	end
end










//////////////////////////    SQUARE        //////////////////////////////

always@(*) begin

	choice_n=choice;
	
	if (state==SQUARE_1  && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	else if (state==SQUARE_2 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	
	else if (state==SQUARE_3 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_4 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	else if (state==SQUARE_5 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_6 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	//////////////////////////////////////////////////////////////////
	
	else if (state==SQUARE_7 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_8 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_9 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_10 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_11 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_12 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_13 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	///////////////////////////////////////////////////////////////////
	
	else if (state==SQUARE_14 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_15 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_16 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_17 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_18 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_19 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_20 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	/////////////////////////////////////////////////////////////////
	
	else if (state==SQUARE_21 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_22 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_23 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_24 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_25 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_26 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==SQUARE_27 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{square_i[0],square_j[0]}]==1) begin correct_1_n=1;choice_n=0; end
		else correct_1_n=0;
	end
	
	/////////////////////////// A SQUARE ////////////////////////////////
	

    else if (state==A_SQUARE_1  && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	else if (state==A_SQUARE_2 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	
	else if (state==A_SQUARE_3 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_4 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	else if (state==A_SQUARE_5 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_6 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	//////////////////////////////////////////////////////////////////
	
	else if (state==A_SQUARE_7 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_8 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_9 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_10 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_11 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_12 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_13 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	///////////////////////////////////////////////////////////////////
	
	else if (state==A_SQUARE_14 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_15 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_16 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_17 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_18 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_19 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_20 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	/////////////////////////////////////////////////////////////////
	
	else if (state==A_SQUARE_21 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_22 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_23 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_24 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_25 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_26 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==A_SQUARE_27 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{A_square_i[0],A_square_j[0]}]==1) begin correct_1_n=1; choice_n=1; end
		else correct_1_n=0;
	end
	
	///////////////////////////// B SQUARE //////////////////////////////////
	
	
    else if (state==B_SQUARE_1  && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	else if (state==B_SQUARE_2 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	
	else if (state==B_SQUARE_3 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_4 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	else if (state==B_SQUARE_5 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_6 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	//////////////////////////////////////////////////////////////////
	
	else if (state==B_SQUARE_7 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_8 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_9 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_10 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_11 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_12 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_13 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	///////////////////////////////////////////////////////////////////
	
	else if (state==B_SQUARE_14 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_15 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_16 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_17 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_18 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_19 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_20 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	/////////////////////////////////////////////////////////////////
	
	else if (state==B_SQUARE_21 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_22 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_23 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_24 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_25 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_26 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==B_SQUARE_27 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{B_square_i[0],B_square_j[0]}]==1) begin correct_1_n=1; choice_n=2; end
		else correct_1_n=0;
	end
	
	
	/////////////////////////////  C SQUARE ////////////////////////////////////
	
    else if (state==C_SQUARE_1  && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	else if (state==C_SQUARE_2 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end

	
	else if (state==C_SQUARE_3 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_4 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	else if (state==C_SQUARE_5 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_6 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	//////////////////////////////////////////////////////////////////
	
	else if (state==C_SQUARE_7 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_8 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_9 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_10 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_11 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_12 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_13 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	///////////////////////////////////////////////////////////////////
	
	else if (state==C_SQUARE_14 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_15 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_16 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_17 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_18 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_19 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_20 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	/////////////////////////////////////////////////////////////////
	
	else if (state==C_SQUARE_21 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_22 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_23 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_24 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_25 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_26 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==0) correct_1_n=1;
		else correct_1_n=0;
	end
	
	else if (state==C_SQUARE_27 && cnt_SQUARE_1>2) begin
		if (sram_rdata_in[{C_square_i[0],C_square_j[0]}]==1) begin correct_1_n=1; choice_n=3;end
		else correct_1_n=0;
	end
	
	
	/////////////////////////////////////////////////////////////////////////
	
	else begin
		correct_1_n=correct_1;
	end


end






///////////CHECK DOWN & CHECK RIGHT & CHECK_DOWN_RIGHT(check the corner)

always@(posedge clk)begin
	if(~srstn)  begin
		down_valid <= 0;
		right_valid<= 0;
		down_right_valid<=0;
		left_valid<=0;
		down_left_valid<=0;
	end
	else begin	
		down_valid<=down_valid_n;
		right_valid<=right_valid_n;
		down_right_valid<=down_right_valid_n;
		left_valid<=left_valid_n;
		down_left_valid<=down_left_valid_n;
	end
end


always @(*) begin
	if (state == CHECK_DOWN && cnt_DOWN>3 ) begin
		if (sram_rdata_in[{check_down_posi_i[0],check_down_posi_j[0]}]==1) begin down_valid_n=1;  end
		else begin  down_valid_n=0;  end
	
		
	end
	
	else begin down_valid_n=down_valid;end
end


always @(*) begin
	if (state == CHECK_RIGHT && cnt_RIGHT>3 ) begin
		if (sram_rdata_in[{check_right_posi_i[0],check_right_posi_j[0]}]==1) begin right_valid_n=1;  end
		else begin  right_valid_n=0;  end
	end
	
	else begin right_valid_n=right_valid;end
end


always @(*) begin
	if (state == CHECK_DOWN_RIGHT && cnt_DOWN_RIGHT>3 ) begin
		if (sram_rdata_in[{check_down_right_posi_i[0],check_down_right_posi_j[0]}]==1) begin down_right_valid_n=1;  end
		else begin  down_right_valid_n=0;  end
		
	end
	
	else begin down_right_valid_n=down_right_valid;end
end

always @(*) begin
	if (state == CHECK_LEFT && cnt_LEFT>3 ) begin
		if (sram_rdata_in[{check_left_posi_i[0],check_left_posi_j[0]}]==1) begin left_valid_n=1;  end
		else begin  left_valid_n=0;  end
		
	end
	
	else begin left_valid_n=left_valid;end
end

always @(*) begin
	if (state == CHECK_DOWN_LEFT && cnt_DOWN_LEFT>3 ) begin
		if (sram_rdata_in[{check_down_left_posi_i[0],check_down_left_posi_j[0]}]==1) begin down_left_valid_n=1;  end
		else begin  down_left_valid_n=0;  end
		
	end
	
	else begin down_left_valid_n=down_left_valid;end
end
	


////////// ORIENT (decided the orientation)
always @(posedge clk) begin
	if (~srstn) begin
		angle<=0;
	end
	else begin
		angle<=angle_n;
	end
end

always @(*) begin
	if (state==ORIENT) begin
		if (left_valid==0 && down_valid==1 && down_left_valid==1 && A_detect_posi_i!=26)
			 angle_n=3'b011;  //180 degree
		else if (down_valid==1 && right_valid==1 && down_right_valid==0 )
			angle_n=3'b001;  //0 degree
			
		
		else if (down_valid==1 && right_valid==0 && down_right_valid==1) 
			angle_n=3'b010;  //90 degree
	
		
		else if (down_valid==0 && right_valid==1 && down_right_valid==1 )
			angle_n=3'b100;  //270 degree
			
		else angle_n=3'b000;
			
	end		

	else begin angle_n=angle; end
end


///////// RECORD parameter ////////////////
reg [7:0] length,length_n;
//assign length=cnt_RECORD-3;

reg [7:0] record_data [17:0];
reg [7:0] record_data_n [17:0];
integer i;

always @(posedge clk) begin
	if (~srstn) begin 
		length<=0;
		add_finish<=0;
		for (i=0;i<18;i=i+1) begin
		record_data[i]<=0;
		end
	end
	else begin 
		length<=length_n;
		add_finish<=add_finish_n;
		for (i=0;i<18;i=i+1) begin
			record_data[i]<=record_data_n[i];
		end
	end
end

always @(*) begin
	if (state==RECORD) begin length_n=cnt_RECORD-2; end
	else begin length_n=length; end

end

always @(*) begin

	for (i=0;i<18;i=i+1) begin
			record_data_n[i]=record_data[i];
		end
	get_jis8_code_start_n=0;
	add_finish_n=0;


	if (state==RECORD ) begin
		case(cnt_RECORD)	
			1: get_jis8_code_start_n=1;
			2: get_jis8_code_start_n=0; 
			3: record_data_n[0]=jis8_code_in;
			4: record_data_n[1]=jis8_code_in;
			5: record_data_n[2]=jis8_code_in;
			6: record_data_n[3]=jis8_code_in;
			7: record_data_n[4]=jis8_code_in;
			8: record_data_n[5]=jis8_code_in;
			9: record_data_n[6]=jis8_code_in;
			10: record_data_n[7]=jis8_code_in;
			11: record_data_n[8]=jis8_code_in;
			12: record_data_n[9]=jis8_code_in;
			13: record_data_n[10]=jis8_code_in;
			14: record_data_n[11]=jis8_code_in;
			15: record_data_n[12]=jis8_code_in;
			16: record_data_n[13]=jis8_code_in;
			17: record_data_n[14]=jis8_code_in;
			18: record_data_n[15]=jis8_code_in;
			19: record_data_n[16]=jis8_code_in;
			20: record_data_n[17]=jis8_code_in;
		

		default:begin 
				for (i=0;i<18;i=i+1)  begin
					record_data_n[i]=0;
					end
				end
		endcase
	
	end
	else if (state==ADD) begin 
			case(length)
				5: begin record_data_n[5]=8'b0000_1110; record_data_n[6]=8'b1100_0001; record_data_n[7]=8'b0001_1110; record_data_n[8]=8'b1100_0001;
					 record_data_n[9]=8'b0001_1110; record_data_n[10]=8'b1100_0001; record_data_n[11]=8'b0001_1110; record_data_n[12]=8'b1100_0001;	
					 record_data_n[13]=8'b0001_1110; record_data_n[14]=8'b1100_0001; record_data_n[15]=8'b0001_1110; record_data_n[16]=8'b1100_0001;
					 record_data_n[17]=8'b0001_0000; add_finish_n=1;
					end
					
				13: begin record_data_n[13]=8'b0000_1110; record_data_n[14]=8'b1100_0001; record_data_n[15]=8'b0001_1110; 
					record_data_n[16]=8'b1100_0001; record_data_n[17]=8'b0001_0000; add_finish_n=1;end
					
				14: begin record_data_n[14]=8'b0000_1110; record_data_n[15]=8'b1100_0001; record_data_n[16]=8'b0001_1110; 
					record_data_n[17]=8'b1100_0000; add_finish_n=1;end
					
				15: begin record_data_n[15]=8'b0000_1110; record_data_n[16]=8'b1100_0001; record_data_n[17]=8'b0001_0000; add_finish_n=1;end
				16: begin record_data_n[16]=8'b0000_1110; record_data_n[17]=8'b1100_0000; add_finish_n=1;end
				17: begin record_data_n[17]=8'b0000_0000; add_finish_n=1; end
				
		   default: begin
					for (i=0;i<18;i=i+1) begin
						record_data_n[i]=record_data[i];
					end
			
					end
		
			endcase
	end
	
	else begin
		for (i=0;i<18;i=i+1) begin
			record_data_n[i]=record_data[i];
		end
		get_jis8_code_start_n=0;
		add_finish_n=0;
	end

end

//////////// MASK //////////////////////////
reg mask_1,mask_2,mask_3;
reg mask_1_n,mask_2_n,mask_3_n;


always @(posedge clk) begin
	if (~srstn) begin
		mask_1<=0;
		mask_2<=0;
		mask_3<=0;
		mask_finish<=0;
	end
	else begin
		mask_1<=mask_1_n;
		mask_2<=mask_2_n;
		mask_3<=mask_3_n;
		mask_finish<=mask_finish_n;
	end
end


always @(*) begin

	mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0;
	
	if (state==MASK && angle==3'b001 ) begin
		if (cnt_MASK==4) begin mask_1_n=sram_rdata_in[{mask_1_i[0],mask_1_j[0]}] ;end
		else if (cnt_MASK==5) begin mask_2_n=sram_rdata_in[{mask_2_i[0],mask_2_j[0]}] ;end
		else if (cnt_MASK==6) begin mask_3_n=sram_rdata_in[{mask_3_i[0],mask_3_j[0]}] ; mask_finish_n=1; end
		else begin mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0; end
	end
	
	else if (state==MASK && angle==3'b010) begin
		if (cnt_MASK==4) begin mask_1_n=sram_rdata_in[{mask_1_i_90[0],mask_1_j_90[0]}] ;end
		else if (cnt_MASK==5) begin mask_2_n=sram_rdata_in[{mask_2_i_90[0],mask_2_j_90[0]}] ;end
		else if (cnt_MASK==6) begin mask_3_n=sram_rdata_in[{mask_3_i_90[0],mask_3_j_90[0]}] ; mask_finish_n=1; end
		else begin mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0; end
	end	
	else if (state==MASK && angle==3'b011) begin
		if (cnt_MASK==4) begin mask_1_n=sram_rdata_in[{mask_1_i_180[0],mask_1_j_180[0]}] ;end
		else if (cnt_MASK==5) begin mask_2_n=sram_rdata_in[{mask_2_i_180[0],mask_2_j_180[0]}] ;end
		else if (cnt_MASK==6) begin mask_3_n=sram_rdata_in[{mask_3_i_180[0],mask_3_j_180[0]}] ; mask_finish_n=1; end
		else begin mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0; end	
	end
	else if (state==MASK && angle==3'b100) begin
		if (cnt_MASK==4) begin mask_1_n=sram_rdata_in[{mask_1_i_270[0],mask_1_j_270[0]}] ;end
		else if (cnt_MASK==5) begin mask_2_n=sram_rdata_in[{mask_2_i_270[0],mask_2_j_270[0]}] ;end
		else if (cnt_MASK==6) begin mask_3_n=sram_rdata_in[{mask_3_i_270[0],mask_3_j_270[0]}] ; mask_finish_n=1; end
		else begin mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0; end
	
	end
	
	
	
	
	else begin mask_1_n=mask_1; mask_2_n=mask_2; mask_3_n=mask_3; mask_finish_n=0; end
end


 

state_encode_0 my_state_encode_0(
	.clk(clk),                    //clock input
    .srstn(srstn),                  //synchronous reset (active low)
	.state(state),
	
	.detect_posi_i(decided_posi_i),
	.detect_posi_j(decided_posi_j),
	

	.length(length),
	.angle(angle),
	//// intput jis8_code
	.record_data0(record_data[0]),
	.record_data1(record_data[1]),
	.record_data2(record_data[2]),
	.record_data3(record_data[3]),
	.record_data4(record_data[4]),
	.record_data5(record_data[5]),
	.record_data6(record_data[6]),
	.record_data7(record_data[7]),
	.record_data8(record_data[8]),
	.record_data9(record_data[9]),
	.record_data10(record_data[10]),
	.record_data11(record_data[11]),
	.record_data12(record_data[12]),
	.record_data13(record_data[13]),
	.record_data14(record_data[14]),
	.record_data15(record_data[15]),
	.record_data16(record_data[16]),
	.record_data17(record_data[17]),

	
	.mask_1(mask_1),
	.mask_2(mask_2),
	.mask_3(mask_3),	
    .qr_encode_finish_n(qr_encode_finish_n),       //1: encoding one QR code is finishe
	
    .sram_wdata_n(sram_wdata_n),             //write data to SRAM ===========output the data to the sram
    .sram_waddr_n(sram_waddr_n),             //write address to SRAM
    .sram_wmask_n(sram_wmask_n)             //write mask: determine which bit should be writed into sram when operate write
                                            //total bits=4,for each bit, 0:Write to addressed memory location,1:Memory location unchanged

);



endmodule





















