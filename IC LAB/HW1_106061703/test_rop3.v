

module rop3_smart_test;

parameter CYCLE = 10;
parameter N=4;


//input
reg clk;
reg [N-1:0] P;
reg [N-1:0] S;
reg [N-1:0] D;
reg [7:0] Mode;
//output
wire [N-1:0] Result_smart ;
wire [N-1:0] Result_part3 ;

// import module
rop3_lut256 
#(.N(N)) 
part3
(
  .clk(clk),
  .P(P),
  .S(S),
  .D(D),
  .Mode(Mode),
  .Result(Result_part3)
);

rop3_smart 
#(.N (N))
smart
(
  .clk(clk),
  .P(P),  
  .S(S),
  .D(D),
  .Mode(Mode),
  .Result(Result_smart)
);


// create clock
initial begin
	clk=0;
	//rst_n=1;
	#(CYCLE) clk=1;
	//#(CYCLE)rst_n=0;
	//#(CYCLE)rst_n=1;
end

always #(CYCLE/2)clk=~clk;
/////////////////////////////


/*
initial begin
   $fsdbDumpfile("rop3_lut256.fsdb");
   $fsdbDumpvars;
end
 */
integer i,j,k,m;
integer error=0;
integer t=0;




// part_1 & smart input feeding
initial begin

  P = 8'hxx;
  S = 8'hxx;
  D = 8'hxx;



  for(m=0; m<256; m=m+1) begin
	for(k=0; k<2**N; k=k+1) begin
	  for(i=0; i<2**N; i=i+1) begin
        for(j=0; j<2**N; j=j+1) begin
			@(negedge clk) Mode=m;
						   P=k; 
						   S=i; 
						   D=j;
			t=t+1;
			/*$display("Mode=%h,{P,S,D}={%2h,%2h,%2h}, part3 result=%2h ",m,k,i,j, Result_part3);
                      
			$display("------------------------------");
			$display("Mode=%h,(P,S,D)=(%d,%d,%d)",Mode_array[m],k,i,j);
			$display("part1 result=%b",Result_part1);
			$display("smart result=%b",Result_smart);
			*/
			
			if (Result_part3 !== Result_smart) begin
				$display("Comparison failed at  Mode=%h, {P,S,D}={%2h,%2h,%2h}, part3 result=%2h, smart result=%2h",
                      m,k,i,j, Result_part3, Result_smart);
				error=error+1;
			end
			else begin
				 $display(">>>>>number=%d,Comparison Pass at Mode=%h,{P,S,D}={%2h,%2h,%2h} part3=%2h, smart=%2h <<<<<",
					  t,m,k,i,j,Result_part3, Result_smart);
			
			end
		    
			end
		end
	end
  end
  # (CYCLE*2);
  P = 8'hxx;
  S = 8'hxx;
  D = 8'hxx;
  
    if (error > 0) begin
        $display("\nxxxxxxxxxxx Comparison Fail xxxxxxxxxxx");
        $display("            Total %0d errors\n  Please check your error messages...", error);
        $display("xxxxxxxxxxx Comparison Fail xxxxxxxxxxx\n");
        
    end 
	else begin
        $display("\n============= Congratulations!! The answers are all correct~~~~ =============");
    end
    $finish;
end

endmodule
