`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/*B V S Sai Kiran(2020H1230233P)
Gautam Vikhe(2020H1400169P)
Raghava Agrawal(2020H1230241P)*/
/////////////////////////////////////////////////////////////////////////////////
module FFT_top_module(clk);
input clk;
parameter N=8;
reg [31:0] Memory [0:N-1];
reg [15:0] Memory_real [0:N-1];
reg [15:0] Memory_img [0:N-1];
reg [15:0] Memory_img_bit_rev [0:N-1];
reg [15:0] Memory_real_bit_rev [0:N-1];
reg [31:0] Memory_out [0:N-1];

reg [31:0] Twiddle[0:N/2-1];
reg [15:0] Twiddle_real [0:N/2-1];
reg [15:0] Twiddle_img [0:N/2-1];

reg [15:0] tw_factor_real;
reg [15:0] tw_factor_img;
reg [7:0] twiddle_addr;
reg [15:0] ar,ai,br,bi;
reg [7:0] ja,jb;
wire[15:0] ar_out,ai_out,br_out,bi_out;
integer k2,k1;
integer k=0;
reg i,j,x=0;
integer n;
reg [7:0]tfc;

///Memory Declaration and BIT REVERSAL
always @(posedge clk)
begin
 if(k==0)
 begin
 /*Computation of common values based on N*/
 case(N)
    8:  begin 
        n=3'b011;
        k2=3'b000;
        x=3'b000;
        tfc=8'b1111_1100;
        end
    16: begin
        n=3'b100;
        k2=4'b0000;
        x=4'b0000;
        tfc=8'b1111_1000;
        end
    32: begin
        n=3'b101;
        k2=5'b00000;
        x=5'b00000;
        tfc=8'b1111_0000;
        end
    default: begin 
    n=32'bx;
    k2=32'bx;
    x=32'bx;
    end
    endcase
    end
     /*Reading inputs from memory file*/
    $readmemb("memory_file_inputs.mem", Memory);  
    for(k=0;k<N;k=k+1)
    begin
        Memory_real[k]=Memory[k][31:16];
        Memory_img[k]=Memory[k][15:0];
    end
    /*Reading Twiddle factors from memory file based on N value and storing input in bit reversed address*/
    if(n==3)
    begin
   $readmemb("Twiddle_values_8bit.mem", Twiddle);
        for(k=0;k<N/2;k=k+1)
        begin
            Twiddle_real[k]=Twiddle[k][31:16];
            Twiddle_img[k]=Twiddle[k][15:0];
        end
        for (k=0;k<N;k=k+1)
        begin
            k2={k2[0],k2[1],k2[2]};
            Memory_real_bit_rev[k]=Memory_real[k2];
            Memory_img_bit_rev[k]=Memory_img[k2];
            x=x+1'b1;
            k2=x;
        end
    end
    else if(n==4)
    begin
   $readmemb("Twiddle_values_16bit.mem", Twiddle);
        for(k=0;k<N/2;k=k+1)
        begin
            Twiddle_real[k]=Twiddle[k][31:16];
            Twiddle_img[k]=Twiddle[k][15:0];
        end
        for (k=0;k<N;k=k+1)
        begin
            k2={k2[0],k2[1],k2[2],k2[3]};
            Memory_real_bit_rev[k]=Memory_real[k2];
            Memory_img_bit_rev[k]=Memory_img[k2];
            x=x+1'b1;
            k2=x;
        end
    end
    else if(n==5)
    begin
    $readmemb("Twiddle_values_32bit.mem", Twiddle);
        for(k=0;k<N/2;k=k+1)
        begin
            Twiddle_real[k]=Twiddle[k][31:16];
            Twiddle_img[k]=Twiddle[k][15:0];
        end
        for (k=0;k<N;k=k+1)
        begin
            k2={k2[0],k2[1],k2[2],k2[3],k2[4]};
            Memory_real_bit_rev[k]=Memory_real[k2];
            Memory_img_bit_rev[k]=Memory_img[k2];
            x=x+1'b1;
            k2=x;
        end
      
    end
    $display("twiddle value %b",Twiddle[1]);
    $display("Memory %b",Memory[1]);
    $display("Memory_real_bit_rev %b",Memory_real_bit_rev[1]);
    i=0;
    j=0;
end

butterfly BF(ar,ai,br,bi,tw_factor_real,tw_factor_img,clk,ar_out, ai_out, br_out, bi_out);

always@(i | j)
begin
       /*Input address and twiddle address calculation each pair */
       i=i;
       j=j;
       ja = j<<1;
       jb = ja+1;
       ja = ((ja << i)|(ja >> (n-i))) & (N-1);   
       jb = ((jb << i)|(jb >> (n-i))) & (N-1);   

       twiddle_addr = ((tfc>>i)& 4'hf)& j;   
       
       ar=Memory_real_bit_rev[ja];
       ai=Memory_img_bit_rev[ja];
       br=Memory_real_bit_rev[jb];
       bi=Memory_img_bit_rev[jb];
       
       tw_factor_real=Twiddle_real[twiddle_addr];
       tw_factor_img=Twiddle_img[twiddle_addr];
end

always@(ar_out|ai_out|br_out|bi_out)
begin
       Memory_real_bit_rev[ja]=ar_out;
       Memory_img_bit_rev[ja]=ai_out;
       Memory_real_bit_rev[jb]=br_out;
       Memory_img_bit_rev[jb]=bi_out;
         
       
          if(j!=N/2) 
            j=j+1;
            if((i<n) && (j==N/2))
            begin 
             i=i+1;
            j=0;
            if(i==n)
            begin
	        i=n;      
	        j=N/2;
	        for(k1=0;k1<N;k1=k1+1)
	        begin
	        Memory_out[k1][31:16]=Memory_real_bit_rev[k1];
	        Memory_out[k1][15:0]=Memory_img_bit_rev[k1];
	        end
	        $writememb("output_values.mem", Memory_out);
	       end       
	     end


end
endmodule

module butterfly(ar,ai,br,bi,tw_factor_real,tw_factor_img,clk,ar_out, ai_out, br_out, bi_out);
input  [15:0] ar,ai,br,bi,tw_factor_real,tw_factor_img;
///output real bf_out_ar,bf_out_ai,bf_out_br,bf_out_bi;
input clk;
output  [15:0] ar_out, ai_out, br_out, bi_out;
wire [15:0] ar_bf, ai_bf, br_bf, bi_bf;
wire [15:0] temp_r, temp_i;
reg [15:0] Input_mulA,Input_mulB;
wire [15:0] temp_1, temp_2, temp_3, temp_4;
wire [15:0] output_addC,output_subC;
reg [15:0] Input_addA,Input_addB;
reg [15:0] Input_subA,Input_subB;

demomul_1 M1(temp_1,br,tw_factor_real,clk);
demomul_1 M2(temp_2,bi,tw_factor_img,clk);
demomul_1 M3(temp_3,bi,tw_factor_real,clk);
demomul_1 M4(temp_4,br,tw_factor_img,clk);

Floating_adder_2 FA(temp_3,temp_4,temp_i);
Floating_sub FB(temp_1,temp_2,temp_r);

Floating_adder_2 FA1(ar,temp_r,ar_out);
Floating_adder_2 FA2(ai,temp_i,ai_out);
Floating_sub FB1(ar,temp_r,br_out);
Floating_sub FB2(ai,temp_i,bi_out);
endmodule

////MULTIPLIER module

module demomul_1(AB,InputA,InputB,CLOCK);
input [15:0] InputA,InputB;
input CLOCK;
output [15:0] AB;

//Mantissa and Exponent related Variables
reg [9:0] L_Mantissa_A,L_Mantissa_B;
reg [9:0] L_Mantissa_UnNormalized;
reg [4:0] L_Exponent_A,L_Exponent_B;
reg [4:0] L_Exponent_unbiased,L_Exponent_biased;
reg L_Sign_A,L_Sign_B;
reg L_Sign;

reg [22:0] L_AB;
reg [10:0] a,b;  //M1 and M2
reg [22:0] p;
reg [10:0] q;
integer i;
reg [15:0] L_ABFINAL;

always@(InputA|InputB)
begin
    /*Extraction of exponent sign and mantissa*/
     L_Sign_A=InputA[15];
     L_Sign_B=InputB[15];
     L_Mantissa_A=InputA[9:0];
     L_Mantissa_B=InputB[9:0];
     L_Exponent_A=InputA[14:10];
     L_Exponent_B=InputB[14:10];
    /*if any one input is 0 result zero*/
    if (({L_Exponent_A,L_Mantissa_A})==0 |({L_Exponent_B,L_Mantissa_B})==0)
    begin
    L_ABFINAL=16'b0;
    end
     /*Calculation for non zero inputs*/
    else
    begin
    L_Sign=L_Sign_A^L_Sign_B;
    L_Exponent_unbiased=L_Exponent_A-15;
    L_Exponent_biased=L_Exponent_B+L_Exponent_unbiased;    
        a={1'b1,L_Mantissa_A}; 
        b={1'b1,L_Mantissa_B}; 
        L_AB=0;
        p=a;
        q=b;
        for(i=0;i<11;i=i+1)
        begin
        if(q[0]==0)
              begin
                p=p<<1;
                q=q>>1;
              end
        else
              begin
                L_AB=L_AB+p;  
                 p=p<<1;
                 q=q>>1;
              end
         end   
        /*Overflow checking and exponent adjustment*/          
       if (L_AB[21]==1)
       begin
       L_Exponent_biased=L_Exponent_biased+1;
      if (L_AB[20]==1)
      L_AB=L_AB<<1;
       end
       else if (L_AB[21]==0)
       begin
       if(L_AB[20]==1)
       begin
       L_AB=L_AB<<1;
       end
       end
       L_Mantissa_UnNormalized=L_AB[20:11];
       /*concatenating final values*/
       L_ABFINAL={L_Sign,L_Exponent_biased,L_Mantissa_UnNormalized};
end   
end 
assign AB=L_ABFINAL;
endmodule
  
////ADDER module

module Floating_adder_2(input_addA,input_addB,output_addC);
input [15:0]input_addA,input_addB;
output reg [15:0] output_addC;
reg Sign_add_A,Sign_add_B,clk,Sign_exor_add,sign_swap;
reg Sign_out_add;
reg [4:0]exponent_add_A,exponent_add_B,exponent_swap;
reg [4:0] Shift_add,Exponent_out_add;
reg [10:0] a_add,b_add,C_add_diff;
reg [11:0] C_add;
reg [9:0] C_temp_add;
reg [9:0]Mantissa_add_A,Mantissa_add_B,Mantissa_out_add,Mantissa_swap;
integer x_add=4'b0000;
always @ (input_addA|input_addB)
begin
 Sign_add_A=input_addA[15];
 Sign_add_B=input_addB[15];
 exponent_add_A=input_addA[14:10];
 exponent_add_B=input_addB[14:10];
 Mantissa_add_A=input_addA[9:0];
 Mantissa_add_B=input_addB[9:0];
 Sign_exor_add=Sign_add_A^Sign_add_B;
if (({exponent_add_A,Mantissa_add_A})==0 & ({exponent_add_B,Mantissa_add_B})==0)
begin
output_addC=16'b0;
end
else if ({exponent_add_A,Mantissa_add_A}=={exponent_add_B,Mantissa_add_B} & Sign_exor_add==1)
begin
output_addC=16'b0;
end
else if ({exponent_add_A,Mantissa_add_A}==0)
begin
output_addC=input_addB;
end
else if ({exponent_add_B,Mantissa_add_B}==0)
begin
output_addC=input_addA;
end
else
begin
/*******************Swap start****************************/
if(exponent_add_B>exponent_add_A)
begin
 Sign_add_A=input_addB[15];
 Sign_add_B=input_addA[15];
 exponent_add_A=input_addB[14:10];
 exponent_add_B=input_addA[14:10];
 Mantissa_add_A=input_addB[9:0];
 Mantissa_add_B=input_addA[9:0];
end
/*******************Swap end****************************/
a_add={1'b1,Mantissa_add_A};
b_add={1'b1,Mantissa_add_B};
Shift_add=exponent_add_A-exponent_add_B;
b_add=b_add>>Shift_add;
//$display("Sift=%b",Shift_add);
/*******************Same Sign start****************************/
if(Sign_exor_add==0)
begin
C_add=a_add+b_add;
//$display("C_add before=%b",C_add);
if(C_add[11]==1)
begin
Exponent_out_add=exponent_add_A+1'b1;
C_add={1'b1,C_add[11:1]};
Sign_out_add=Sign_add_A;
Mantissa_out_add=C_add[9:0];
end
else
begin
Exponent_out_add=exponent_add_A;
Sign_out_add=Sign_add_A;
Mantissa_out_add=C_add[9:0];
end
end
/*******************Same Sign end****************************/
/*******************Different Sign Start****************************/
else if (Sign_exor_add==1)
begin
C_add=a_add+(~(b_add)+1'b1);
if(C_add[11]==1 & C_add[10]==0)
begin
C_add=C_add>>1;
Exponent_out_add=exponent_add_A+1;
end
else if ((C_add[11]==1 & C_add[10]==1)|(C_add[11]==0 & C_add[10]==1))
begin
C_add=C_add;
Exponent_out_add=exponent_add_A;
end
else
begin
if (C_add[9]==1)
x_add=1;
else if (C_add[9]==0 & C_add[8]==1)
x_add=2;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==1)
x_add=3;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==1)
x_add=4;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==0 & C_add[5]==1)
x_add=5;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==0 & C_add[5]==0 & C_add[4]==1)
x_add=6;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==0 & C_add[5]==0 & C_add[4]==0 & C_add[3]==1 )
x_add=7;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==0 & C_add[5]==0 & C_add[4]==0 & C_add[3]==0 & C_add[2]==1)
x_add=8;
else if (C_add[9]==0 & C_add[8]==0 & C_add[7]==0 & C_add[6]==0 & C_add[5]==0 & C_add[4]==0 & C_add[3]==0 & C_add[2]==0 & C_add[1]==1)
x_add=9;
C_add=C_add<<x_add;
Exponent_out_add=exponent_add_A-x_add;
end
Mantissa_out_add=C_add[9:0];
Sign_out_add=Sign_add_A;
/*******************Different Sign end****************************/
end
output_addC={Sign_out_add,Exponent_out_add,Mantissa_out_add};
end
end
endmodule

////SUBTRACTOR module

module Floating_sub(input_subA,input_subB,output_subC);
input [15:0]input_subA,input_subB;
output reg [15:0] output_subC;
reg Sign_sub_A,Sign_sub_B,clk,Sign_exor_sub,sign_swap,Sign_sub_B_temp;
reg Sign_out_sub;
reg [4:0]exponent_sub_A,exponent_sub_B,exponent_swap;
reg [4:0] Shift_sub,Exponent_out_sub;
reg [10:0] a_sub,b_sub;
reg [11:0] C_sub;
reg [9:0]Mantissa_sub_A,Mantissa_sub_B,Mantissa_out_sub,Mantissa_swap;
reg [3:0]x_sub=4'b0000;
always @ (input_subA|input_subB)
begin
Sign_sub_A=input_subA[15];
Sign_sub_B_temp=input_subB[15];
exponent_sub_A=input_subA[14:10];
exponent_sub_B=input_subB[14:10];
Mantissa_sub_A=input_subA[9:0];
Mantissa_sub_B=input_subB[9:0];
Sign_sub_B=~Sign_sub_B_temp;
Sign_exor_sub=Sign_sub_A^Sign_sub_B;
/*******************Special Cases**************/
if (({exponent_sub_A,Mantissa_sub_A})==0 & ({exponent_sub_B,Mantissa_sub_B})==0)
begin
output_subC=16'b0;
end
else if ({exponent_sub_A,Mantissa_sub_A}=={exponent_sub_B,Mantissa_sub_B} & Sign_exor_sub==1)
begin
output_subC=16'b0;
end
else if ({exponent_sub_A,Mantissa_sub_A}==0)
begin
output_subC={Sign_sub_B,exponent_sub_B,Mantissa_sub_B};
end
else if ({exponent_sub_B,Mantissa_sub_B}==0)
begin
output_subC=input_subA;
end
else
begin
/*******************Swap start****************************/
if(exponent_sub_B>exponent_sub_A)
begin
  Sign_sub_A=~(input_subB[15]);
  Sign_sub_B=input_subA[15];
  exponent_sub_A=input_subB[14:10];
  exponent_sub_B=input_subA[14:10];
  Mantissa_sub_A=input_subB[9:0];
  Mantissa_sub_B=input_subA[9:0];
end
/*******************Swap end****************************/
a_sub={1'b1,Mantissa_sub_A};
b_sub={1'b1,Mantissa_sub_B};
Shift_sub=exponent_sub_A-exponent_sub_B;
b_sub=b_sub>>Shift_sub;
/*******************Same Sign start****************************/
if(Sign_exor_sub==0)
begin
C_sub=a_sub+b_sub;
if(C_sub[11]==1)
begin
Exponent_out_sub=exponent_sub_A+1'b1;
C_sub={1'b1,C_sub[11:1]};
Sign_out_sub=Sign_sub_A;
Mantissa_out_sub=C_sub[9:0];
end
else
begin
Exponent_out_sub=exponent_sub_A;
Sign_out_sub=Sign_sub_A;
Mantissa_out_sub=C_sub[9:0];
end
end
/*******************Same Sign end****************************/
/*******************Different Sign Start****************************/
else if (Sign_exor_sub==1)
begin
C_sub=a_sub+(~(b_sub)+1'b1);
if(C_sub[11]==1 & C_sub[10]==0)
begin
C_sub=C_sub>>1;
Exponent_out_sub=exponent_sub_A+1;
end
else if ((C_sub[11]==1 & C_sub[10]==1)|(C_sub[11]==0 & C_sub[10]==1))
begin
C_sub=C_sub;
Exponent_out_sub=exponent_sub_A;
end
else
begin
if (C_sub[9]==1)
x_sub=1;
else if (C_sub[9]==0 & C_sub[8]==1)
x_sub=2;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==1)
x_sub=3;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==1)
x_sub=4;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==0 & C_sub[5]==1)
x_sub=5;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==0 & C_sub[5]==0 & C_sub[4]==1)
x_sub=6;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==0 & C_sub[5]==0 & C_sub[4]==0 & C_sub[3]==1)
x_sub=7;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==0 & C_sub[5]==0 & C_sub[4]==0 & C_sub[3]==0 & C_sub[2]==1)
x_sub=8;
else if (C_sub[9]==0 & C_sub[8]==0 & C_sub[7]==0 & C_sub[6]==0 & C_sub[5]==0 & C_sub[4]==0 & C_sub[3]==0 & C_sub[2]==0 & C_sub[1]==1)
x_sub=9;
C_sub=C_sub<<x_sub;
Exponent_out_sub=exponent_sub_A-x_sub;
end
Mantissa_out_sub=C_sub[9:0];
Sign_out_sub=Sign_sub_A;
/*******************Different Sign end****************************/
end
output_subC={Sign_out_sub,Exponent_out_sub,Mantissa_out_sub};
end
end
endmodule

module testbench();
reg clock;
FFT_top_module FTP(clock);
initial
begin
clock=0;
forever #10 clock=~clock;
#10 $finish;
end
endmodule
