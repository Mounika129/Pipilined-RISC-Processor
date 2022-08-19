module test_mips16; 
 reg clk1, clk2; 
 integer k; 
 pipe_MIPS16 mips (clk1, clk2); 
 initial 
 begin 
 clk1 = 0; clk2 = 0; 
 repeat (20) // Generating two-phase clock 
 begin 
 #5 clk1 = 1; #5 clk1 = 0; 
 #5 clk2 = 1; #5 clk2 = 0; 
 end 
 end
 
 
  initial 
 begin 
   for (k=0; k<7; k=k+1) 
   mips.Reg[k] = k; 
   mips.Mem[0] = 16'h004a; // ADDI R1,R0,10 
   mips.Mem[1] = 16'h0094; // ADDI R2,R0,20 
   mips.Mem[2] = 16'h00d9; // ADDI R3,R0,25 
   mips.Mem[3] = 16'h3ff8; // OR R7,R7,R7 -- dummy instr. 
   mips.Mem[4] = 16'h3ff8; // OR R7,R7,R7 -- dummy instr. 
   mips.Mem[5] = 16'h12a0; // ADD R4,R1,R2 
   mips.Mem[6] = 16'h3ff8; // OR R7,R7,R7 -- dummy instr. 
   mips.Mem[7] = 16'h18e8; // ADD R5,R4,R3 
   mips.Mem[8] = 16'hf000; // HLT
 
 mips.HALTED = 0; 
 mips.PC = 0; 
 mips.TAKEN_BRANCH = 0; 
 #280 
 for (k=0; k<6; k=k+1) 
  $display ("R%1d - %2d", k, mips.Reg[k]); 
 end 
 initial 
 begin 
 $dumpfile ("mips.vcd"); 
 $dumpvars (0, test_mips32); 
 #300 $finish; 
 end 
endmodule
