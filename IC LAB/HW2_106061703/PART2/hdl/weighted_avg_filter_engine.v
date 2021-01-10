//===============================================
// Top module for intensity-weighted average filter engine (7-tap)
//Filter Mode: 0 ~ 3        
//	- Mode[0]: Filter for 1 times
//	- Mode[1]: Filter for 2 times
//	- Mode[2]: Filter for 3 times
//	- Mode[3]: Filter for 4 times
//===============================================

module weighted_avg_filter_engine
#(parameter DATA_WIDTH=8)
(
input clk,
//==== control signals ====
input rstn,		                       	//synchronous reset; 0: reset all your FSMs
input [1:0] filter_mode, 				//the operating mode of filter
input valid_pixel_in,                   //1: pixel_in is valid
input first_pixel_in,                   //1: pixel_in is the first pixel of the current segment
input last_pixel_in,                    //1: pixel_in is the last pixel of the current segment

output reg valid_pixel_out,             //1: pixel_out is valid
//==== data signals ====
input  [DATA_WIDTH-1:0] pixel_in,       //filter input
output reg [DATA_WIDTH-1:0] pixel_out   //filter output
);

//write your code here

localparam IDLE=2'd0, Start_transition=2'd1,  Steady=2'd2 , End_transition=2'd3 ,ORDER=7;
reg [1:0] state,nstate;
reg [2:0] counter_start,counter_start_tmp,counter_end,counter_end_tmp,counter_Idle,counter_Idle_tmp;
reg [15:0] number,number_tmp;


//from the instant of the first_pixel_in to the three times of the Start_trasition => Start_trasition
//from the instant of the last_pixel_in to the three times of the End_trasition => End_transition




always @(posedge clk) begin 
	if (~rstn) begin
	
		//valid_pixel_out=0;
		state <= IDLE;
		end
	else
		state <= nstate;

end



///////// define the every possible state first ///////////
always @(*) begin
	case(state)
	 Start_transition: begin
					  if (valid_pixel_in==0)
						nstate=IDLE;
					  else	
						  if (counter_start==4)
						    begin
							nstate=Steady;
							
							end
						  else	
							nstate=Start_transition;
							
					  end
	 Steady:  begin
			  if (~valid_pixel_in)
			    nstate=IDLE;
			  else
				  if (last_pixel_in==1)
				    nstate=End_transition;
				  else
				    nstate=Steady;
			  end
	 
	 End_transition: /*begin
					 if (~valid_pixel_in)   //because End_transition is after the last_pixel_in, the valid_pixel_in must be 0,					  
					   nstate=IDLE;     	//so don't have to consider valid_pixel_in==0
					 else */  
						 if (counter_end==5)
						   begin
						   nstate=IDLE;
						
						   end
					     else 
						   nstate=End_transition;
					 //end
			    IDLE:  begin
					  if (valid_pixel_in==0)
						nstate=IDLE;
					  else
						  if (first_pixel_in==1 || (counter_start>0 && counter_start<4))
						    nstate=Start_transition;
						  else if((counter_start==0 || counter_start==4) && last_pixel_in==0)  /////////// have to check again
							nstate=Steady;
						  else if (last_pixel_in==1 || counter_end !=0)
						  //else if (counter_end !==0)
							nstate=End_transition;
						  else
							nstate=IDLE;
						    
					  end
	
	 
	endcase	
end


///////////// counter ///////////
/*
always @(*) begin
	counter_start_tmp=3'b0;  /// Warnings: Latches
							 /// Latches are resulted from the unknown value, so we can declare the value at the begining 
	counter_end_tmp=3'b0;    /// of the block. If it's declared in the Default case, it's likely to not going to that case	
	case(nstate)             /// and there would be some unknown value.
	
				
	 Start_transition: begin
					   if (counter_start==4) begin
						counter_start_tmp=3'b0;
						nstate=Steady; /////////// have to check again
						end
					   else
						counter_start_tmp=counter_start+1;	 
					   end
			   
	 End_transition:  begin
					  if (counter_end==5)
						counter_end_tmp=3'b0;
					  else
						counter_end_tmp=counter_end+1; 
					  end
					  
			   IDLE:  begin
					  counter_start_tmp=counter_start;
					  counter_end_tmp=counter_end;
					  end
				  

				///counter_Idle_tmp=3'b0;
			  
	 endcase
end


always @(posedge clk) begin
	if (~rstn) begin
		counter_start <= 0;
		counter_end   <= 0;
		//number <=0;
		end
	else
		begin
		counter_start <= counter_start_tmp;
		counter_end   <= counter_end_tmp;
		//number <= number_tmp;
		end
end
*/
////////////////////////////

/////////////// New counter ///////////////
always @(posedge clk) begin
	if(rstn==0) begin
		counter_start<=0;
		counter_end	 <=0;

	end
	
	else begin
	case(nstate)
	 Start_transition: begin
					  if (counter_start==4) begin
						counter_start<=3'b0;
						//nstate<=Steady; /////////// have to check again
						end
					  else
						counter_start<=counter_start+1;	 
					  end
					  
	 End_transition:  begin
					  if (counter_end==5)
						counter_end<=3'b0;
					  else
						counter_end<=counter_end+1; 
					  end
					  
			   IDLE:  begin
					  counter_start<=counter_start;
					  counter_end<=counter_end;
					  end
				  
	 default: begin
				counter_start<=3'b0;
				counter_end<=3'b0;
				
			  end
	 endcase
	 
	end
end


//////////////////////////////////////////



reg [8-1:0] sample [7-1:0];	

wire [4-1:0] weight [7-1:0]; // not clearly sure the vairable type of the weight
							 // how can I declare the parameter of the size of the 'weight'? 
							 // Or directly specify the size?
						 

							 
weight my_weight(
  
  .sample0(sample[0]), 
  .sample1(sample[1]),
  .sample2(sample[2]),
  .sample3(sample[3]),
  .sample4(sample[4]),
  .sample5(sample[5]),
  .sample6(sample[6]),
  .W0(weight[0]),
  .W1(weight[1]),
  .W2(weight[2]),
  .W3(weight[3]),
  .W4(weight[4]),
  .W5(weight[5]),
  .W6(weight[6])
);

wire [7-1:0] divisor; 
wire [8-1:0] div_inverse;
wire [4-1:0] div_shift;

assign divisor=weight[0]+weight[1]+weight[2]+weight[3]+weight[4]+weight[5]+weight[6];

inverse_table my_inverse_table(
  .divisor (divisor),
  .div_inverse (div_inverse),
  .div_shift(div_shift)
);

reg [DATA_WIDTH-1:0] pixel_out_; 
wire [15-1:0] dividend;
wire [15-1:0] quotient;



assign dividend=weight[0]*sample[0]+weight[1]*sample[1]+weight[2]*sample[2]+weight[3]*sample[3]+weight[4]*sample[4]+weight[5]*sample[5]+weight[6]*sample[6];          
mul_and_shift my_mul_and_shift(
  .dividend(dividend),
  .div_inverse(div_inverse),
  .div_shift(div_shift),
  .quotient(quotient)
);

always @(*) begin
	if (quotient>255)
	  pixel_out_=255;
	else 
	  pixel_out_=quotient[7:0]; //truncate the bit size

end




reg [DATA_WIDTH-1:0] pixel_out_1 [3000:0];
reg [DATA_WIDTH-1:0] pixel_out_2 [3000:0];
reg [DATA_WIDTH-1:0] pixel_out_3 [3000:0];
always @(*) begin
	if (filter_mode==0)
	pixel_out_1[number]=pixel_out_;
	else if (filter_mode==1)
	pixel_out_2[number]=pixel_out_;
	else if (filter_mode==2)
	pixel_out_3[number]=pixel_out_;
end




integer i ,k;



always @(posedge clk) begin

	if (rstn==0) begin
		number<=0;
		//for(k=0;k<ORDER;k=k+1)  //Warnings: Multi drivers
		//sample[k]<=0;	          //The same reg variable are assigned value in different always blocks. 
	end
	
	
	
	else begin
		case(nstate)
		//Only the state of the Steady and the End_transition have to output the result
		//Start_trasition and  IDLE just need to remain the value
	
	
		//record the value, doesn't output the pixel_out
		Start_transition: begin
						  if (filter_mode==0) begin
							if(counter_start==0) begin
								number<=0;
								sample[3]<=pixel_in;
								end
							else if(counter_start==1) begin
								sample[4]<=pixel_in;
								sample[2]<=pixel_in;
								end
							else if(counter_start==2) begin
								sample[5]<=pixel_in;
								sample[1]<=pixel_in;
								end
							else if(counter_start==3) begin
								sample[6]<=pixel_in;
								sample[0]<=pixel_in;
							
								end
						  end
						  ////////////////////////////////
						  
						  else if(filter_mode==1 ) begin
						  
						  	if(counter_start==0) begin
								number<=0;
								sample[3]<=pixel_out_1[0];
								end
							else if(counter_start==1) begin
								sample[4]<=pixel_out_1[1];
								sample[2]<=pixel_out_1[1];
								end
							else if(counter_start==2) begin
								sample[5]<=pixel_out_1[2];
								sample[1]<=pixel_out_1[2];
								end
							else if(counter_start==3) begin
								sample[6]<=pixel_out_1[3];
								sample[0]<=pixel_out_1[3];
								number<=0;
								end
					
						  end
						  
						  ////////////////////////////////
						  
						  else if(filter_mode==2 ) begin
						  
						  	if(counter_start==0) begin
								number<=0;
								sample[3]<=pixel_out_2[0];
								end
							else if(counter_start==1) begin
								sample[4]<=pixel_out_2[1];
								sample[2]<=pixel_out_2[1];
								end
							else if(counter_start==2) begin
								sample[5]<=pixel_out_2[2];
								sample[1]<=pixel_out_2[2];
								end
							else if(counter_start==3) begin
								sample[6]<=pixel_out_2[3];
								sample[0]<=pixel_out_2[3];
								number<=0;
								end
							
						  end
						  ////////////////////////////////////
						  else begin
						  
						  	if(counter_start==0) begin
								number<=0;
								sample[3]<=pixel_out_3[0];
								end
							else if(counter_start==1) begin
								sample[4]<=pixel_out_3[1];
								sample[2]<=pixel_out_3[1];
								end
							else if(counter_start==2) begin
								sample[5]<=pixel_out_3[2];
								sample[1]<=pixel_out_3[2];
								end
							else if(counter_start==3) begin
								sample[6]<=pixel_out_3[3];
								sample[0]<=pixel_out_3[3];
								number<=0;
								end
						
						  end
						  
						  
						  
						  end
	
		//output pixel_out
				  Steady: begin
						  
						  pixel_out<=pixel_out_;
				          if (filter_mode==0) begin
							number<=number+1;
							valid_pixel_out<=1;
						  
							sample[0]<=pixel_in;
							for(i=1;i<ORDER;i=i+1) begin
							sample[i]<=sample[i-1];
							end
						  
							
							
						  end
						  ///////////////////////////////////
						  
						 else if (filter_mode==1 ) begin
							number<=number+1;
							valid_pixel_out<=1;
						  
							sample[0]<=pixel_out_1[4+number]; /// have to +4 to make up the gap
							for(i=1;i<ORDER;i=i+1) begin
							sample[i]<=sample[i-1];
							end

						  end
						  ///////////////////////////////////
						  
						  else if (filter_mode==2 ) begin
							number<=number+1;
							valid_pixel_out<=1;
						  
							sample[0]<=pixel_out_2[4+number]; /// have to +4 to make up the gap
							for(i=1;i<ORDER;i=i+1) begin
							sample[i]<=sample[i-1];
							end

						  end
						  ///////////////////////////////////
						  else  begin
							number<=number+1;
							valid_pixel_out<=1;
						  
							sample[0]<=pixel_out_3[4+number]; /// have to +4 to make up the gap
							for(i=1;i<ORDER;i=i+1) begin
							sample[i]<=sample[i-1];
							end

						  end
						  
						  end
		//output pixel_out
		  End_transition: begin
						  pixel_out<=pixel_out_;

						  if (filter_mode==0) begin
							number<=number+1;
							valid_pixel_out<=1;
							
							if (counter_end==0) begin
								sample[0]<=pixel_in;
								
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];
								end
							end
						  
							else if (counter_end==1) begin
								sample[0]<=sample[1];
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
							end
						  
							else if (counter_end==2) begin
								sample[0]<=sample[3];
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
							end
						  
							else if (counter_end==3) begin
								sample[0]<=sample[5];
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
												
							end
							end
							
							
						/////////////////////////////////
						
						else if (filter_mode==1 ) begin
							number<=number+1;
							valid_pixel_out<=1;
							
							if (counter_end==0) begin
								sample[0]<=pixel_out_1[number+4];

								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];
								end
								
							end
						  
							else if (counter_end==1) begin
								sample[0]<=pixel_out_1[number+4-2];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
						  
							else if (counter_end==2) begin
								sample[0]<=pixel_out_1[number+4-4];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
							
							else  if (counter_end==3)begin
								sample[0]<=pixel_out_1[number+4-6];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								

							end
							
							else if (counter_end==4) begin
								for (i=0;i<3000;i=i+1) begin
									pixel_out_1[i]<=0;
								
								
								end

							end
										
							
						end
						
						/////////////////////////////////////////////
						
						else if (filter_mode==2 ) begin
							number<=number+1;
							valid_pixel_out<=1;
							
							if (counter_end==0) begin
								sample[0]<=pixel_out_2[number+4];
						
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];
								end
								
						    end
						  
							else if (counter_end==1) begin
								sample[0]<=pixel_out_2[number+4-2];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
						  
							else if (counter_end==2) begin
								sample[0]<=pixel_out_2[number+4-4];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
						  
							else  if (counter_end==3)begin
								sample[0]<=pixel_out_2[number+4-6];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
						
							end
							
							else if (counter_end==4) begin
								for (i=0;i<3000;i=i+1) begin
									pixel_out_2[i]<=0;
		
								
								end
							end
							
												
							
						end	
						
                         ////////////////////////////////////////////
						 
						else  begin
							number<=number+1;
							valid_pixel_out<=1;
							
							if (counter_end==0) begin
								sample[0]<=pixel_out_3[number+4];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];
								end
								
							end
						  
							else if (counter_end==1) begin
								sample[0]<=pixel_out_3[number+4-2];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
						  
							else if (counter_end==2) begin
								sample[0]<=pixel_out_3[number+4-4];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
						  
							else if (counter_end==3) begin
								sample[0]<=pixel_out_3[number+4-6];
							
								for(i=1;i<ORDER;i=i+1) begin
								sample[i]<=sample[i-1];							
								end
								
							end
							
							else if (counter_end==4) begin
								for (i=0;i<3000;i=i+1) begin
									pixel_out_3[i]<=0;
						

								
								end
							end
										
							
						end	
						
						end
	   	IDLE: begin
					valid_pixel_out <=0;
		
			  end
		endcase
	end
end
endmodule
