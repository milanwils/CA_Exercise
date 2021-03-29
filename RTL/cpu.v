//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

reg [31:0] updated_pc_IF_ID, instruction_IF_ID;

wire signed [31:0] immediate_extended;

reg [31:0] updated_pc_ID_EXE;
reg [31:0] instruction_ID_EXE;
reg [31:0] Rs_ID_EXE;
reg [31:0] Rt_ID_EXE;
reg [31:0] Sign_Extend_Instr_ID_EXE;
reg MemtoReg_ID_EXE, RegWrite_ID_EXE, Branch_ID_EXE, MemWrite_ID_EXE, MemRead_ID_EXE, Jump_ID_EXE, ALUSrc_ID_EXE, RegDst_ID_EXE;
reg[1:0] ALUOp_ID_EXE;

// EXE/MEM
reg [31:0] branch_pc_EXE_MEM, jump_pc_EXE_MEM, alu_out_EXE_MEM, Rt_EXE_MEM;
reg [4:0] Rd_EXE_MEM;
reg zero_flag_EXE_MEM, MemtoReg_EXE_MEM, RegWrite_EXE_MEM, Branch_EXE_MEM, MemWrite_EXE_MEM, MemRead_EXE_MEM, Jump_EXE_MEM;

// MEM/WB
reg [31:0] ReadData_MEM_WB, alu_out_MEM_WB;
reg [4:0] Rd_MEM_WB;
reg MemtoReg_MEM_WB, RegWrite_MEM_WB;

assign immediate_extended = $signed(instruction[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_EXE_MEM),
   .jump_pc   (jump_pc_EXE_MEM  ),
   .zero_flag (zero_flag_EXE_MEM),
   .branch    (Branch_EXE_MEM    ),
   .jump      (Jump_EXE_MEM      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

control_unit control_unit(
   .opcode   (instruction_IF_ID[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch            ),
   .mem_read (mem_read          ),
   .mem_2_reg(mem_2_reg         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write         ),
   .alu_src  (alu_src           ),
   .reg_write(reg_write         ),
   .jump     (jump              )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction_ID_EXE[15:11]),
   .input_b (instruction_ID_EXE[20:16]),
   .select_a(RegDst_ID_EXE     ),
   .mux_out (regfile_waddr     )
);

register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(RegWrite_MEM_WB         ),
   .raddr_1  (instruction_IF_ID[25:21]),
   .raddr_2  (instruction_IF_ID[20:16]),
   .waddr    (Rd_MEM_WB     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);


alu_control alu_ctrl(
   .function_field (instruction_ID_EXE[5:0]),
   .alu_op         (ALUOp_ID_EXE    ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (Sign_Extend_Instr_ID_EXE),
   .input_b (Rt_ID_EXE    ),
   .select_a(ALUSrc_ID_EXE           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (Rs_ID_EXE     ),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction_ID_EXE[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_EXE_MEM),
   .wen      (MemWrite_EXE_MEM     ),
   .ren      (MemRead_EXE_MEM      ),
   .wdata    (Rt_EXE_MEM    ),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);



mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (ReadData_MEM_WB),
   .input_b  (alu_out_MEM_WB),
   .select_a (MemtoReg_MEM_WB),
   .mux_out  (regfile_wdata)
);



branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc_ID_EXE ),
   .instruction  (instruction_ID_EXE       ),
   .branch_offset(Sign_Extend_Instr_ID_EXE),
   .branch_pc    (branch_pc       ),
   .jump_pc      (jump_pc         )
);

// Register for IF/ID

// Updated PC
reg_arstn #(.DATA_W(32)) updated_pc_pipe_IF_ID(
   .clk(clk),
   .arst_n(arst_n),
   .din(updated_pc),
   .dout(updated_pc_IF_ID)
);

// Instruction
reg_arstn #(.DATA_W(32)) instruction_pipe_IF_ID(
   .clk(clk),
   .arst_n(arst_n),
   .din(instruction),
   .dout(instruction_IF_ID)
);

// Registers for ID/EXE

// Updated PC
reg_arstn_en #(.DATA_W(32)) updated_pc_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (updated_pc_IF_ID),
   .en     (enable),
   .dout   (updated_pc_ID_EXE)
);

// Instruction [20:11]
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (instruction_IF_ID),
   .en     (enable),
   .dout   (instruction_ID_EXE)
);

// Rs
reg_arstn_en #(.DATA_W(32)) Rs_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (regfile_data_1),
   .en     (enable),
   .dout   (Rs_ID_EXE)
);

// Rt
reg_arstn_en #(.DATA_W(32)) Rt_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (regfile_data_2),
   .en     (enable),
   .dout   (Rt_ID_EXE)
);

// Sign_Extend_Instr
reg_arstn_en #(.DATA_W(32)) Sign_Extend_Instr_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (immediate_extended),
   .en     (enable),
   .dout   (Sign_Extend_Instr_ID_EXE)
);

// Control signals
// WB::MemtoReg
reg_arstn_en #(.DATA_W(1)) MemtoReg_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (mem_2_reg),
   .en     (enable),
   .dout   (MemtoReg_ID_EXE)
);

// WB::RegWrite
reg_arstn_en #(.DATA_W(1)) RegWrite_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (reg_write),
   .en     (enable),
   .dout   (RegWrite_ID_EXE)
);

// M::Branch
reg_arstn_en #(.DATA_W(1)) Branch_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (branch),
   .en     (enable),
   .dout   (Branch_ID_EXE)
);

// M::MemWrite
reg_arstn_en #(.DATA_W(1)) MemWrite_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (mem_write),
   .en     (enable),
   .dout   (MemWrite_ID_EXE)
);

// M::MemRead
reg_arstn_en #(.DATA_W(1)) MemRead_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (mem_read),
   .en     (enable),
   .dout   (MemRead_ID_EXE)
);

// M::Jump
reg_arstn_en #(.DATA_W(1)) Jump_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (jump),
   .en     (enable),
   .dout   (Jump_ID_EXE)
);

// EX::ALUSrc
reg_arstn_en #(.DATA_W(1)) ALUSrc_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (alu_src),
   .en     (enable),
   .dout   (ALUSrc_ID_EXE)
);

// EX::ALUOp
reg_arstn_en #(.DATA_W(2)) ALUOp_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (alu_op),
   .en     (enable),
   .dout   (ALUOp_ID_EXE)
);

// EX::RegDst
reg_arstn_en #(.DATA_W(1)) RegDst_pipe_ID_EXE(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (reg_dst),
   .en     (enable),
   .dout   (RegDst_ID_EXE)
);

// Registers for EXE/MEM
// branch pc
reg_arstn_en#(
   .DATA_W(32)
)branch_pc_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (branch_pc),
   .dout   (branch_pc_EXE_MEM)
);

// jump pc
reg_arstn_en#(
   .DATA_W(32)
)jump_pc_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (jump_pc),
   .dout   (jump_pc_EXE_MEM)
);

// ALU result
reg_arstn_en#(
   .DATA_W(32)
)ALU_result_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (alu_out),
   .dout   (alu_out_EXE_MEM)
);

// ALU result zero flag
reg_arstn_en#(
   .DATA_W(1)
)ALU_result_zero_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (zero_flag),
   .dout   (zero_flag_EXE_MEM)
);

// Register data 2
reg_arstn_en#(
   .DATA_W(32)
)Rt_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (Rt_ID_EXE),
   .dout   (Rt_EXE_MEM)
);

// Register writeback address
reg_arstn_en#(
   .DATA_W(5)
)Rd_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .en     (enable),
   .din    (regfile_waddr),
   .dout   (Rd_EXE_MEM)
);

// Control signals
// WB::MemtoReg
reg_arstn_en #(.DATA_W(1)) MemtoReg_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (MemtoReg_ID_EXE),
   .en     (enable),
   .dout   (MemtoReg_EXE_MEM)
);

// WB::RegWrite
reg_arstn_en #(.DATA_W(1)) RegWrite_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (RegWrite_ID_EXE),
   .en     (enable),
   .dout   (RegWrite_EXE_MEM)
);

// M::Branch
reg_arstn_en #(.DATA_W(1)) Branch_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (Branch_ID_EXE),
   .en     (enable),
   .dout   (Branch_EXE_MEM)
);

// M::MemWrite
reg_arstn_en #(.DATA_W(1)) MemWrite_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (MemWrite_ID_EXE),
   .en     (enable),
   .dout   (MemWrite_EXE_MEM)
);

// M::MemRead
reg_arstn_en #(.DATA_W(1)) MemRead_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (MemRead_ID_EXE),
   .en     (enable),
   .dout   (MemRead_EXE_MEM)
);

// M::Jump
reg_arstn_en #(.DATA_W(1)) Jump_pipe_EXE_MEM(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (Jump_ID_EXE),
   .en     (enable),
   .dout   (Jump_EXE_MEM)
);


// Registers for MEM/WB

// ReadData
reg_arstn #(.DATA_W(32)) ReadData_pipe_MEM_WB(
   .clk(clk),
   .arst_n(arst_n),
   .din(dram_data),
   .dout(ReadData_MEM_WB)
);

// ALU Result
reg_arstn #(.DATA_W(32)) alu_out_pipe_MEM_WB(
   .clk(clk),
   .arst_n(arst_n),
   .din(alu_out_EXE_MEM),
   .dout(alu_out_MEM_WB)
);

// Rd
reg_arstn #(.DATA_W(5)) Rd_pipe_MEM_WB(
   .clk(clk),
   .arst_n(arst_n),
   .din(Rd_EXE_MEM),
   .dout(Rd_MEM_WB)
);

// WB::MemtoReg
reg_arstn #(.DATA_W(1)) MemtoReg_pipe_MEM_WB(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (MemtoReg_EXE_MEM),
   .dout   (MemtoReg_MEM_WB)
);

// WB::RegWrite
reg_arstn #(.DATA_W(1)) RegWrite_pipe_MEM_WB(
   .clk    (clk),
   .arst_n (arst_n),
   .din    (RegWrite_EXE_MEM),
   .dout   (RegWrite_MEM_WB)
);

endmodule


