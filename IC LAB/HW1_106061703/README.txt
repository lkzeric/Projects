106061703 ÂÅ°ê·ç

-----------------(1) testbench in part_2---------------------------------
(1) testbench in part_2
    After construct the rop3_smart.v, we have to check if it can work correctly.Therefore, I use the rop3_lut16.v  
built in the part_1 to help to check it. In the testbench, I feed the input(P,S,D,Mode) of both the rop_lut16.v 
and rop3_smart.v with the same value by implementing the "4-layers for loop" on them. I collect all the fifteen 
functions in the Table1 in the array called "Mode_array" so that I can also use the for loop to call the Mode 
value conveniently. We only test the fifteen functions in this part.

    Because the rop3_lut16.v is correct, I can consider the results derived from it are the "Golden Value". Then,
I compare the results from the rop3_smart.v with the "Golden Value". Finally, I get all the answers of the 
rop3_lut16.v and rop3_smart.v are the same which means the construction of the rop3_smart.v is correct.


-------Mode array--------:

  reg [7:0] Mode_array [14:0];

  Mode_array[0]=8'h00; 
  Mode_array[1]=8'h11;
  Mode_array[2]=8'h33;
  Mode_array[3]=8'h44;
  Mode_array[4]=8'h55; 
  Mode_array[5]=8'h5A;
  Mode_array[6]=8'h66;
  Mode_array[7]=8'h88;
  Mode_array[8]=8'hBB; 
  Mode_array[9]=8'hC0;
  Mode_array[10]=8'hCC;
  Mode_array[11]=8'hEE;
  Mode_array[12]=8'hF0; 
  Mode_array[13]=8'hFB;
  Mode_array[14]=8'hFF;

-------For Loop Demonstration-------:

  for(m=0; m<15; m=m+1) -----Mode(15 modes)
	for(k=0; k<2**N; k=k+1) -----P
	  for(i=0; i<2**N; i=i+1) -------S
             for(j=0; j<2**N; j=j+1) --------D









------------------(2) testbench in part_3-------------------------
(2) testbench in part_3
     Testbench in part_3 is almost the same idea with testbench in part_2. The only difference is that the role of 
the "Golden Value" is alternated in part_3. That is, the "Golden Value" comes from rop3_smart.v this time. In the 
same way, I also construct the "4-layers for loop"to feed the input to both the construction. However, in the first
for loop layer, I expand the index from 15 to 256, because we have to test all the 256 functoins in this part.
     Finally, I compare the answers for both of them and I discover results from rop3_lut256.v are identical to
the "Golden Value", so I can consider my rop3_lut256.v is correct.

--------For Loop Demonstration------:

  for(m=0; m<256; m=m+1) -----Mode(256 modes)
	for(k=0; k<2**N; k=k+1) -----P
	  for(i=0; i<2**N; i=i+1) -------S
             for(j=0; j<2**N; j=j+1) --------D











-------------------(3) Way to find out all the 256 functions-------------------
(3) Way to find out all the 256 functions
     Because we can derive the same answer from both the Boolean Equation and the Magic Formula given the 
same input(P,S,D), they must have some connection. First, we should observe the Magic Formula and interpret
what it is actually doing, and I would explain my understanding as following:

------------------------

temp1[7 : 0] = 8¡¦h1 << {P[i],S[i],D[i]}
---> It means the 8'h1 will left shift with some amount which depends on the value  of the {P[i]; S[i];D[i]}. 
    (e.g. if {P[i],S[i],D[i]}={1,0,1},it means 8'h1 have to left shift 5 units and becomes 8'b0010_0000)

temp2[7 : 0] = temp1[7 : 0] & Mode[7 : 0]
---> Because the temp1[7:0] only has one nonzero bit and seven zero bits, the temp2[7:0] will be nonzero if 
     temp1[7:0] coincidentally matches the nonzero bits position of Mode[7:0] because of the bitwise and operation.
     Otherwise ,temp2[7:0] equals zero.


Result[i] = |temp2[7 : 0]
---> Result[i] equals 0 only when all bits in temp2[7:0] are zero. Otherwise, it equals 1.

===>In conclusion, Result[i] equals 1 when 8'h1 left shift the amount of {P[i],S[i],D[i]} concidentally 
      matches the nonzero bits position of Mode[7:0].

--------Let me take an example---------:

    If the Mode is 8'h72= 8'b 0 1 1 1 0 0 1 0

                 position---> 7 6 5 4 3 2 1 0 <---

    Therefore the Result[i] equals 1 only when {P[i],S[i],D[i]}= 1 or 4 or 5 or 6
    (i.e. the nonzero position of the Mode 8'h72 ). In other words, the combination
    of the {P[i],S[i],D[i]} may only be (0,0,1),(1,0,0),(1,0,1),(1,1,0). From now, we 
    look it at a different perspectives:

    -------->  We know there are only 4 combinations will make the Result[i] be 1 given 
    the Mode 8'h72, so the Bitwise Boolean Operation can only let the 
    {P[i],S[i],D[i]} =(0,0,1) or (1,0,0) or (1,0,1) or (1,1,0) become 1. Hence we can 
    derive the Bitwise Boolean Operation backwardly. Based on the possible {P[i],S[i],D[i]},
    we know the Bitwise Boolean Operation is ~P&~S&D | P&~S&~D | P&~S&D | P&S&~D given the 
    Mode 8'72. All in all, we can know the corresponding Bitwise Boolean Operation from given 
    the Mode.

---------------------------------------
<Implementation>
Because there are 8 bits in the mode, it means there are 8 Bitwise Boolean Fundamental Operations
as well. So I use an "assign" method to make it more convenient.

------For example:------

    assign a=~P&~S&~D; //for(0,0,0) i.e. 8'b 0 0 0 0 0 0 0 1
    assign b=~P&~S& D; //for(0,0,1) i.e. 8'b 0 0 0 0 0 0 1 0
    assign c=~P& S&~D; //for(0,1,0) i.e. 8'b 0 0 0 0 0 1 0 0
    assign d=~P& S& D; //for(0,1,1) i.e. 8'b 0 0 0 0 1 0 0 0
    assign e= P&~S&~D; //for(1,0,0) i.e. 8'b 0 0 0 1 0 0 0 0
    assign f= P&~S& D; //for(1,0,1) i.e. 8'b 0 0 1 0 0 0 0 0
    assign g= P& S&~D; //for(1,1,0) i.e. 8'b 0 1 0 0 0 0 0 0
    assign h= P& S& D; //for(1,1,1) i.e. 8'b 1 0 0 0 0 0 0 0

 			        position---> 7 6 5 4 3 2 1 0 <---

All the Bitwise Boolean Operation in ROP3 will be the combination of the above Bitwise Boolean 
Fundamental Operations.

------<The most important example>-------

     Mode:   8'b0010_1001= 8'b0010_0000 | 8'b0000_1000 | 8'b0000_0001 
     
     Hence, Bitwise Boolean Operation of 8'b0010_1001= f | d | a !!!!!!

------- After finding out the rule of ROP3 we can quickly construct the whole 256 operations!!! -------






















