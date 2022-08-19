module pipe_MIPS16 (clk1, clk2); 
 input clk1, clk2; // Two-phase clock 
  reg [15:0] PC, IF_ID_IR, IF_ID_NPC; 
  reg [15:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm; 
 reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; 
  reg [15:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B; 
 reg EX_MEM_cond; 
  reg [15:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD; 
  reg [7:0] Reg [0:15]; // Register bank (32 x 32) 
  reg [15:0] Mem [0:1023]; // 1024 x 32 memory
 parameter ADD=4'b0001,SUB=4'b1100, AND=4'b0110, OR=4'b0011, SLT=4'b1110, MUL=4'b0101,HLT=4'b1111, LW=4'b0100,SW=4'b0101, ADDI=4'b0000, SUBI=4'b1011,SLTI=4'b0010,  BNEQZ=4'b1101, BEQZ=4'b1000;  
 parameter RR_ALU=3'b000,RM_ALU=3'b001,LOAD=3'b010,STORE=3'b011,BRANCH=3'b100,HALT=3'b101; 
 reg HALTED;  // Set after HLT instruction is completed (in WB stage) 
 reg TAKEN_BRANCH; // Required to disable instructions after branch
 
 always @(posedge clk1) // IF Stage 
 if (HALTED == 0) 
 begin 
   if (((EX_MEM_IR[15:12] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[15:12] == BNEQZ) && (EX_MEM_cond == 0))) 
 begin 
 IF_ID_IR <= #2 Mem[EX_MEM_ALUOut]; 
 TAKEN_BRANCH <= #2 1'b1; 
 IF_ID_NPC <= #2 EX_MEM_ALUOut + 1; 
 PC <= #2 EX_MEM_ALUOut + 1; 
 end
 else 
 begin 
 IF_ID_IR <= #2 Mem[PC]; 
 IF_ID_NPC <= #2 PC + 1; 
 PC <= #2 PC + 1; 
 end 
 end
 
 always @(posedge clk2) // ID Stage
  if (HALTED == 0) 
 begin 
   if (IF_ID_IR[11:9] == 3'b000) ID_EX_A <= 0; 
   else ID_EX_A <= #2 Reg[IF_ID_IR[11:9]]; // "rs" 
   if (IF_ID_IR[8:6] == 3'b000) ID_EX_B <= 0; 
   else ID_EX_B <= #2 Reg[IF_ID_IR[8:6]]; // "rt" 
 ID_EX_NPC <= #2 IF_ID_NPC; 
 ID_EX_IR <= #2 IF_ID_IR; 
   ID_EX_Imm <= #2 {{10{IF_ID_IR[5]}}, {IF_ID_IR[5:0]}};
   case (IF_ID_IR[15:12]) 
 ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= #2 RR_ALU; 
 ADDI,SUBI,SLTI: ID_EX_type <= #2 RM_ALU; 
 LW: ID_EX_type <= #2 LOAD; 
 SW: ID_EX_type <= #2 STORE; 
 BNEQZ,BEQZ: ID_EX_type <= #2 BRANCH; 
 HLT: ID_EX_type <= #2 HALT; 
 default: ID_EX_type <= #2 HALT; 
 // Invalid opcode
 endcase
 end
 
  always @(posedge clk1) // EX Stage 
 if (HALTED == 0) 
 begin 
 EX_MEM_type <= #2 ID_EX_type; 
 EX_MEM_IR <= #2 ID_EX_IR; 
 TAKEN_BRANCH <= #2 0; 
 case (ID_EX_type) 
 RR_ALU: begin 
   case (ID_EX_IR[15:12]) // "opcode" 
 ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B; 
 SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B; 
 AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B; 
 OR: EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B; 
 SLT: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B; 
 MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B; 
 default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
 endcase
 end
 
 
 RM_ALU: begin 
   case (ID_EX_IR[15:12]) // "opcode" 
 ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; 
 SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm; 
 SLTI: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm; 
 default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
 endcase
 end
 
 
 LOAD, STORE: 
 begin 
 EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; 
 EX_MEM_B <= #2 ID_EX_B; 
 end
 BRANCH: begin 
    EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm; 
    EX_MEM_cond <= #2 (ID_EX_A == 0); 
   end 
  endcase
 end
 
 
 always @(posedge clk2) // MEM Stage 
 if (HALTED == 0) 
 begin 
  MEM_WB_type <= EX_MEM_type; 
  MEM_WB_IR <= #2 EX_MEM_IR; 
  case (EX_MEM_type) 
   RR_ALU, RM_ALU: 
   MEM_WB_ALUOut <= #2 EX_MEM_ALUOut; 
   LOAD: MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut]; 
   STORE: if (TAKEN_BRANCH == 0) // Disable write 
   Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B; 
  endcase
 end
 
 
 always @(posedge clk1) // WB Stage 
 begin 
 if (TAKEN_BRANCH == 0) // Disable write if branch taken 
  case (MEM_WB_type) 
   RR_ALU: Reg[MEM_WB_IR[5:3]] <= #2 MEM_WB_ALUOut; // "rd" 
   RM_ALU: Reg[MEM_WB_IR[8:6]] <= #2 MEM_WB_ALUOut; // "rt" 
   LOAD: Reg[MEM_WB_IR[8:6]] <= #2 MEM_WB_LMD; // "rt" 
   HALT: HALTED <= #2 1'b1; 
  endcase
 end 
endmodule
 