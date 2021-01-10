module state_encode_0(
	
    input           clk,                    //clock input
    input           srstn,                  //synchronous reset (active low)
	input  [8:0]	state,
	input  [5:0] detect_posi_i,
	input  [5:0] detect_posi_j,
	input  [7:0] length,
	input  [2:0]  angle,
	
	//// intput jis8 code and padding code
	input  [7:0] record_data0,
	input  [7:0] record_data1,
	input  [7:0] record_data2,
	input  [7:0] record_data3,
	input  [7:0] record_data4,
	input  [7:0] record_data5,
	input  [7:0] record_data6,
	input  [7:0] record_data7,
	input  [7:0] record_data8,
	input  [7:0] record_data9,
	input  [7:0] record_data10,
	input  [7:0] record_data11,
	input  [7:0] record_data12,
	input  [7:0] record_data13,
	input  [7:0] record_data14,
	input  [7:0] record_data15,
	input  [7:0] record_data16,
	input  [7:0] record_data17,


	
	input		 mask_1,
	input		 mask_2,
	input 		 mask_3,	
    output  reg     qr_encode_finish_n,       //1: encoding one QR code is finished

    //sram
 
    output reg [3:0]   sram_wdata_n,             //write data to SRAM ===========output the data to the sram
    output reg [9:0]   sram_waddr_n,             //write address to SRAM
    output reg [3:0]   sram_wmask_n           //write mask: determine which bit should be writed into sram when operate write
                                            //total bits=4,for each bit, 0:Write to addressed memory location,1:Memory location unchanged
);


localparam ENCODE=9'd13;

reg [5:0] i,j;



////////////////////////////////////////////////
wire [5:0] encode_i_all [3:0];
assign encode_i_all[0]=detect_posi_i+i;
assign encode_i_all[1]=detect_posi_i+(20-j);
assign encode_i_all[2]=detect_posi_i+(20-i);
assign encode_i_all[3]=detect_posi_i+j;

////////////////////////////////////////////////


wire [5:0] encode_j_all [3:0];
assign encode_j_all[0]=detect_posi_j+j;
assign encode_j_all[1]=detect_posi_j+i;
assign encode_j_all[2]=detect_posi_j-5'd14+(20-j);
assign encode_j_all[3]=detect_posi_j+(20-i);


////////////////////////////////////////////////


reg [2:0] orientation;

always @(*) begin
	if (angle==3'b001)
		orientation=0;
	else if (angle==3'b010)
		orientation=1;
	else if (angle==3'b011)
		orientation=2;
	else if (angle==3'b100)
		orientation=3;
	else 
		orientation=0;
end

///////////////////////////////////////////////

wire [2:0] mask_pattern;
assign mask_pattern={mask_1,mask_2,mask_3}^3'b101;

// how to store the mask condition

wire [11:0] condition [7:0];
assign condition[0]=(i+j)%2;
assign condition[1]=i%2;
assign condition[2]=j%3;
assign condition[3]=(i+j)%3;
assign condition[4]=((i/2)+(j/3))%2;
assign condition[5]=(i*j)%2+(i*j)%3;
assign condition[6]=((i*j)%2+(i*j)%3)%2;
assign condition[7]=((i*j)%3+(i+j)%2)%2;





///// counter ENCODE //////
reg [7:0]  cnt_ENCODE,cnt_ENCODE_n;

always @(posedge clk) begin
	if (~srstn) begin cnt_ENCODE<=0; end
	else begin cnt_ENCODE<=cnt_ENCODE_n; end
end

always @(*) begin
	if (state==ENCODE) begin cnt_ENCODE_n=cnt_ENCODE+1;  end
	else begin cnt_ENCODE_n=0;  end
end



/////////////////////////////////////////////////////////
always @(*) begin

	    i=0;
		j=0;
		qr_encode_finish_n=0;
		sram_waddr_n=0;
		sram_wdata_n=0;
		sram_wmask_n=4'b1111;

	if (state==ENCODE ) begin
		case(cnt_ENCODE)
		
			//////////////////////// BLOCK 0 //////////////////////
			1: begin  //3
				i=20;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;end
			   //sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			2:begin
			   i=20;j=19; //2
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=1^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=1;end
			   //sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=1;
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			3:begin
				i=19;j=20; //1
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;end
			   //sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			4:begin
			   i=19;j=19; //0
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;end
			   //sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=0;
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			//////////////////////// BLOCK 1 //////////////////////
			5:begin
				i=18;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[7]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[7];end
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			6:begin
				i=18;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[6]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[6];end
		
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			7:begin
				i=17;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[5]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[5];end
		
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 8:begin
				i=17;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[4]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[4];end

			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 9:begin
				i=16;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[3]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[3];end
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
		     10:begin
				i=16;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[2]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[2];end
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 11:begin
				i=15;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[1]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[1];end
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 12:begin
				i=15;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   if (condition[mask_pattern]==0) begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[0]^1; end
			   else begin sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}]=length[0];end
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			  
			 //////////////////////  BLOCK 2 ///////////////////
			 13:begin
				i=14;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[7]^1:record_data0[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 14:begin
				i=14;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[6]^1:record_data0[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 15:begin
				i=13;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[5]^1:record_data0[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 16:begin
				i=13;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[4]^1:record_data0[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 17:begin
				i=12;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[3]^1:record_data0[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 18:begin
				i=12;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[2]^1:record_data0[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 19:begin
				i=11;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[1]^1:record_data0[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 20:begin
				i=11;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data0[0]^1:record_data0[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 3 ///////////////////
			 21:begin
				i=10;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[7]^1:record_data1[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 22:begin
				i=10;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[6]^1:record_data1[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 23:begin
				i=9;j=20;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[5]^1:record_data1[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 24:begin
				i=9;j=19;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[4]^1:record_data1[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 25:begin
				i=9;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[3]^1:record_data1[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 26:begin
				i=9;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[2]^1:record_data1[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 27:begin
				i=10;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[1]^1:record_data1[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 28:begin
				i=10;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data1[0]^1:record_data1[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 4 ///////////////////
			 29:begin
				i=11;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[7]^1:record_data2[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 30:begin
				i=11;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[6]^1:record_data2[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 31:begin
				i=12;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[5]^1:record_data2[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 32:begin
				i=12;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[4]^1:record_data2[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 33:begin
				i=13;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[3]^1:record_data2[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 34:begin
				i=13;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[2]^1:record_data2[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 35:begin
				i=14;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[1]^1:record_data2[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 36:begin
				i=14;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data2[0]^1:record_data2[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 5 ///////////////////
			 37:begin
				i=15;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[7]^1:record_data3[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 38:begin
				i=15;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[6]^1:record_data3[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 39:begin
				i=16;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[5]^1:record_data3[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 40:begin
				i=16;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[4]^1:record_data3[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 41:begin
				i=17;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[3]^1:record_data3[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 42:begin
				i=17;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[2]^1:record_data3[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 43:begin
				i=18;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[1]^1:record_data3[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 44:begin
				i=18;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data3[0]^1:record_data3[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			   //////////////////////  BLOCK 6 ///////////////////
			 45:begin
				i=19;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[7]^1:record_data4[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 46:begin
				i=19;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[6]^1:record_data4[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 47:begin
				i=20;j=18;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[5]^1:record_data4[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 48:begin
				i=20;j=17;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[4]^1:record_data4[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 49:begin
				i=20;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[3]^1:record_data4[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 50:begin
				i=20;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[2]^1:record_data4[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 51:begin
				i=19;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[1]^1:record_data4[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 52:begin
				i=19;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data4[0]^1:record_data4[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			    //////////////////////  BLOCK 7 ///////////////////
			 53:begin
				i=18;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[7]^1:record_data5[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 54:begin
				i=18;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[6]^1:record_data5[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 55:begin
				i=17;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[5]^1:record_data5[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 56:begin
				i=17;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[4]^1:record_data5[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 57:begin
				i=16;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[3]^1:record_data5[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 58:begin
				i=16;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[2]^1:record_data5[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 59:begin
				i=15;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[1]^1:record_data5[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 60:begin
				i=15;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data5[0]^1:record_data5[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			    //////////////////////  BLOCK 8 ///////////////////
			 61:begin
				i=14;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[7]^1:record_data6[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 62:begin
				i=14;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[6]^1:record_data6[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 63:begin
				i=13;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[5]^1:record_data6[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 64:begin
				i=13;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[4]^1:record_data6[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 65:begin
				i=12;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[3]^1:record_data6[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 66:begin
				i=12;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[2]^1:record_data6[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 67:begin
				i=11;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[1]^1:record_data6[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 68:begin
				i=11;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data6[0]^1:record_data6[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 9 ///////////////////
			 69:begin
				i=10;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[7]^1:record_data7[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 70:begin
				i=10;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[6]^1:record_data7[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 71:begin
				i=9;j=16;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[5]^1:record_data7[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 72:begin
				i=9;j=15;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[4]^1:record_data7[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 73:begin
				i=9;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[3]^1:record_data7[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 74:begin
				i=9;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[2]^1:record_data7[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 75:begin
				i=10;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[1]^1:record_data7[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 76:begin
				i=10;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data7[0]^1:record_data7[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			    //////////////////////  BLOCK 10 ///////////////////
			 77:begin
				i=11;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[7]^1:record_data8[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 78:begin
				i=11;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[6]^1:record_data8[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 79:begin
				i=12;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[5]^1:record_data8[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 80:begin
				i=12;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[4]^1:record_data8[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 81:begin
				i=13;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[3]^1:record_data8[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 82:begin
				i=13;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[2]^1:record_data8[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 83:begin
				i=14;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[1]^1:record_data8[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 84:begin
				i=14;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data8[0]^1:record_data8[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 11 ///////////////////
			 85:begin
				i=15;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[7]^1:record_data9[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 86:begin
				i=15;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[6]^1:record_data9[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 87:begin
				i=16;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[5]^1:record_data9[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 88:begin
				i=16;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[4]^1:record_data9[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 89:begin
				i=17;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[3]^1:record_data9[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 90:begin
				i=17;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[2]^1:record_data9[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 91:begin
				i=18;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[1]^1:record_data9[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 92:begin
				i=18;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data9[0]^1:record_data9[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			      
			   //////////////////////  BLOCK 12 ///////////////////
			 93:begin
				i=19;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[7]^1:record_data10[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 94:begin
				i=19;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[6]^1:record_data10[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 95:begin
				i=20;j=14;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[5]^1:record_data10[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 96:begin
				i=20;j=13;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[4]^1:record_data10[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 97:begin
				i=20;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[3]^1:record_data10[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 98:begin
				i=20;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[2]^1:record_data10[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 99:begin
				i=19;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[1]^1:record_data10[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 100:begin
				i=19;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data10[0]^1:record_data10[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 13 ///////////////////
			 101:begin
				i=18;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[7]^1:record_data11[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 102:begin
				i=18;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[6]^1:record_data11[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 103:begin
				i=17;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[5]^1:record_data11[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 104:begin
				i=17;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[4]^1:record_data11[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 105:begin
				i=16;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[3]^1:record_data11[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 106:begin
				i=16;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[2]^1:record_data11[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 107:begin
				i=15;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[1]^1:record_data11[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 108:begin
				i=15;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data11[0]^1:record_data11[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 14 ///////////////////
			 109:begin
				i=14;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[7]^1:record_data12[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 110:begin
				i=14;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[6]^1:record_data12[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 111:begin
				i=13;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[5]^1:record_data12[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 112:begin
				i=13;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[4]^1:record_data12[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 113:begin
				i=12;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[3]^1:record_data12[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 114:begin
				i=12;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[2]^1:record_data12[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 115:begin
				i=11;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[1]^1:record_data12[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 116:begin
				i=11;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data12[0]^1:record_data12[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 15 ///////////////////
			 117:begin
				i=10;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[7]^1:record_data13[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 118:begin
				i=10;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[6]^1:record_data13[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 119:begin
				i=9;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[5]^1:record_data13[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 120:begin
				i=9;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[4]^1:record_data13[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 121:begin
				i=8;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[3]^1:record_data13[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 122:begin
				i=8;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[2]^1:record_data13[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 123:begin
				i=7;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[1]^1:record_data13[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 124:begin
				i=7;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data13[0]^1:record_data13[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 16 ///////////////////
			 125:begin
				i=5;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[7]^1:record_data14[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 126:begin
				i=5;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[6]^1:record_data14[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 127:begin
				i=4;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[5]^1:record_data14[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 128:begin
				i=4;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[4]^1:record_data14[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 129:begin
				i=3;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[3]^1:record_data14[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 130:begin
				i=3;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[2]^1:record_data14[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 131:begin
				i=2;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[1]^1:record_data14[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 132:begin
				i=2;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data14[0]^1:record_data14[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 17 ///////////////////
			 133:begin
				i=1;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[7]^1:record_data15[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 134:begin
				i=1;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[6]^1:record_data15[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 135:begin
				i=0;j=12;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[5]^1:record_data15[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 136:begin
				i=0;j=11;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[4]^1:record_data15[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 137:begin
				i=0;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[3]^1:record_data15[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 138:begin
				i=0;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[2]^1:record_data15[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 139:begin
				i=1;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[1]^1:record_data15[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 140:begin
				i=1;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data15[0]^1:record_data15[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   //////////////////////  BLOCK 18 ///////////////////
			 141:begin
				i=2;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[7]^1:record_data16[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 142:begin
				i=2;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[6]^1:record_data16[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 143:begin
				i=3;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[5]^1:record_data16[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 144:begin
				i=3;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[4]^1:record_data16[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 145:begin
				i=4;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[3]^1:record_data16[3];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 146:begin
				i=4;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[2]^1:record_data16[2];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 147:begin
				i=5;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[1]^1:record_data16[1];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			  
			 148:begin
				i=5;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data16[0]^1:record_data16[0];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			   
			   //////////////////////  BLOCK 19 ///////////////////
			 149:begin
				i=7;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};

			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data17[7]^1:record_data17[7];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 150:begin
				i=7;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data17[6]^1:record_data17[6];
	
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 151:begin
				i=8;j=10;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data17[5]^1:record_data17[5];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
			   
			 152:begin
				i=8;j=9;
			   sram_waddr_n={encode_i_all[orientation][5:1],encode_j_all[orientation][5:1]};
			   sram_wdata_n[{encode_i_all[orientation][0],encode_j_all[orientation][0]}] = (condition[mask_pattern]==0)? record_data17[4]^1:record_data17[4];
			   sram_wmask_n=15-(1<<{encode_i_all[orientation][0],encode_j_all[orientation][0]});
			   end
		   
			   
		     157: qr_encode_finish_n=1;
		
		
		
		 default: begin
				i=0;
				j=0;
				qr_encode_finish_n=0;
				sram_waddr_n=0;
				sram_wdata_n=0;
				sram_wmask_n=4'b1111;
		 end
			 
	
		endcase
	end


	

end



endmodule



















