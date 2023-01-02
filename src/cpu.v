// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);


// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
wire   [31 : 0 ]  ic_if_ins;
wire   [31 : 0 ]  if_ic_pc ;
wire              ic_if_fg ;
wire              if_ic_fg ;
wire   [31 : 0]   if_de_ins;
wire              if_de_insfg ;
wire   [31 : 0]   if_de_imm ;
wire              rob_if_jpok;
wire   [31 : 0]   rob_if_jptarget;
wire              lsb_if_full;
wire              rob_if_full;
wire    [31 : 0]  if_de_rdval;

wire            ic_mem_fg   ;

wire  [31 : 0]  mem_ram_a;
wire  [7  : 0]  mem_ram_wri;
wire           mem_ram_wrifla;
  
wire [7 : 0]  ram_mem_result;
  
wire [31 : 0] ic_mem_a;
wire          ic_mem_flag; // is wating for instruction
wire [31 : 0]  mem_ic_val;
wire           mem_ic_fg; 
  
wire          mem_lsb_memok;

wire  [31 : 0] mem_lsb_val;

wire [5 :  0]  de_rob_op;
wire [6 : 0]   de_rob_oph;
wire [31 : 0]  de_rob_imm;
wire [4 :  0]  de_rob_rs1;
wire [4 :  0]  de_rob_rs2;
wire [4 :  0]  de_rob_rd;
wire          de_rob_flag;
wire [31 : 0] de_rob_rdval;

wire [5 : 0] rs_alu_op;
wire [31 : 0]rs_alu_rs1;
wire [31 : 0]rs_alu_rs2;
wire rs_alu_fg;
wire [3 : 0]rs_alu_rob;
wire rs_if_full;

wire    [31 : 0]     rob_CDB_imm;
wire    [5 : 0]     rob_CDB_op;
wire    [6 : 0]     rob_CDB_oph;
wire                rob_CDB_fg;
wire    [4 : 0]     rob_CDB_rd;
wire    [31 : 0]     rob_CDB_rs1val;
wire    [31 : 0]     rob_CDB_rs2val;
wire                 rob_CDB_rs1fg;
wire                 rob_CDB_rs2fg;

//ALU
wire  [`RBID]   alu_CDB_reorder;
wire   [`RLEN]  alu_CDB_val;
wire            alu_CDB_flag;
wire   [5 : 0]  alu_CDB_op;
//regfile
wire [4 : 0]      rob_reg_rs1a;
wire [4 : 0]      rob_reg_rs2a;
wire              reg_rob_rs1fg;
wire              reg_rob_rs2fg;
wire  [31 : 0]    reg_rob_val1;
wire  [31 : 0]    reg_rob_val2;
//LSB
//  wire [`RBID] lsb_rob_reorder;
//  wire         lsb_rob_fg;
//  wire  [5 : 0] lsb_rob_op;
//  wire  [31 : 0]lsb_rob_val;
//CDB

wire  [31 : 0] rob_CDB_outval;
wire   [4 : 0]rob_CDB_inidx;
wire   [4 : 0]rob_CDB_outidx;
wire   rob_CDB_outflag;
wire   rob_CDB_inflag;
wire  [`RBID] front_CDB;
wire [`RBID] rear_CDB;
wire         rob_if_jalr;

wire   lsb_mem_fg;
wire [31 : 0]  lsb_mem_a;
wire [31 :0]   lsb_mem_val;
wire [5 : 0]  lsb_mem_op;
//CDB to ROB
wire [`RBID]  lsb_CDB_reorder;
wire [31: 0]  lsb_CDB_val;
wire          lsb_CDB_fg;
wire [5 : 0]  lsb_CDB_op;

IF IF(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
//IC
  .ins_ori(ic_if_ins),
  .pc_cache(if_ic_pc),
  .ins_ori_flag(ic_if_fg),
  .pc_flag(if_ic_fg),
//Decoder
  .ins(if_de_ins),
  .ins_flag(if_de_insfg),
  .ins_imm(if_de_imm),
  .rd_val(if_de_rdval),
//CDB from ROB
  .jp_ok(rob_if_jpok),
  .jp_target(rob_if_jptarget),
  .jp_isjalr(rob_if_jalr),
  .lsb_full(lsb_if_full),
  .rob_full(rob_if_full),
  .rs_full(rs_if_full)
);


ICache IC(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in), 

  .ins_ori(ic_if_ins),
  .ins_flag(ic_if_fg),
  .pc(if_ic_pc),
  .pc_flag(if_ic_fg),

  .pc_mem(ic_mem_a),
  .pc_flag_mem(ic_mem_fg),
  .ins_mem(mem_ic_val),
  .ins_mem_flag(mem_ic_fg)         
);
  
MemCtrl Memctrl(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  //RAM
  .mem_a(mem_a),
  .mem_write(mem_dout),
  .is_write(mem_wr),
  .cannot_read(io_buffer_full),
  .mem_result(mem_din),
  //IC
  .addr_target(ic_mem_a),
  .ic_flag(ic_mem_fg),
  .ic_val_out(mem_ic_val),
  .ic_isok(mem_ic_fg),
  //LSB
  .lsb_addr(lsb_mem_a),
  .lsb_flag(lsb_mem_fg),
  .opcode(lsb_mem_op),
  .lsb_store(lsb_mem_val),
  .lsb_isok(mem_lsb_memok),
  .lsb_val_out(mem_lsb_val) 
);
  
  
  
Decoder Decoder(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  //IF
  .ins(if_de_ins),
  .ins_flag(if_de_insfg),
  .ins_imm(if_de_imm),
  .rd_val(if_de_rdval),
  // .pc_bc_flag(if_de_bcfg),
  // .pc_bc(if_de_bc),
  //ROB
  .opcode(de_rob_op),
  .ophead(de_rob_oph),
  .imm(de_rob_imm),
  .rs1(de_rob_rs1),
  .rs2(de_rob_rs2),
  .rd(de_rob_rd),
  .op_flag(de_rob_flag),
  .rob_rd_val(de_rob_rdval)
);


RS RS(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
//ROB
  .opcode(rob_CDB_op),
  .ophead(rob_CDB_oph),
  // .rs1(rob_CDB_rs1),
  // .rs2(rob_CDB_rs2),
  .opflag(rob_CDB_fg),
  .rs_full(rs_if_full),
  //Regfile
  .rs1_ready(rob_CDB_rs1fg),
  .rs2_ready(rob_CDB_rs2fg),
  
  .rs1_val(rob_CDB_rs1val),
  .rs2_val(rob_CDB_rs2val),
  .rob_reorder(rear_CDB),

  // .rob_reorder(rob_CDB_reorder),
  // .rd_val(rob_CDB_outval),
  // .rd_flag(rob_CDB_outflag),
  //alu
  .op_alu(rs_alu_op),
  .rs1_alu(rs_alu_rs1),
  .rs2_alu(rs_alu_rs2),
  .flag_alu(rs_alu_fg),
  .rob_alu(rs_alu_rob),
  .alu_ans_flag(alu_CDB_flag),
  .alu_ans_reorder(alu_CDB_reorder),
  .alu_ans(alu_CDB_val),
  //LSB
  .lsb_reorder(lsb_CDB_reorder),
  .lsb_val(lsb_CDB_val),
  .lsb_flag(lsb_CDB_fg)
);
//CDB to RS&LSB

ROB ROB(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    //Decode
    .rd_idx(de_rob_rd),
    .rd_val(de_rob_rdval),
    .flag(de_rob_flag),
    .full(rob_if_full),
    //decode
    .de_imm(de_rob_imm),
    .de_opcode(de_rob_op),
    .de_ophead(de_rob_oph),
    .de_rs1(de_rob_rs1),
    .de_rs2(de_rob_rs2),
    .op_flag(de_rob_flag),

    //CDB
    .rd_val_update(rob_CDB_outval),
    .rd_idxin_update(rob_CDB_inidx),
    .rd_idxout_update(rob_CDB_outidx),
    .rd_out_fg(rob_CDB_outflag),
    .rd_in_fg(rob_CDB_inflag),
    .reorder_front(front_CDB),
    .reorder_rear(rear_CDB),
    .op_is_jp(rob_if_jpok),
    .pc_target(rob_if_jptarget),
    .pc_isjalr(rob_if_jalr),

    //CDB to RS/LSB
    .op_is_come(rob_CDB_fg),
    .opcode(rob_CDB_op),
    .ophead(rob_CDB_oph),
    .imm(rob_CDB_imm),
    .rd(rob_CDB_rd),
    .rs1_val_(rob_CDB_rs1val), 
    .rs2_val_(rob_CDB_rs2val),
    .is_val1(rob_CDB_rs1fg),
    .is_val2(rob_CDB_rs2fg),   
    //RegFile
    .rs1_addr(rob_reg_rs1a),
    .rs2_addr(rob_reg_rs2a),
    .rs1_ready(reg_rob_rs1fg),
    .rs2_ready(reg_rob_rs2fg),
    .rs1_val(reg_rob_val1),
    .rs2_val(reg_rob_val2),
    //ALU
    .rob_reorder(alu_CDB_reorder),
    .alu_val(alu_CDB_val),
    .alu_flag(alu_CDB_flag),
    .alu_opcode(alu_CDB_op),
    //LSB
    .lsb_reorder(lsb_CDB_reorder),
    .lsb_flag(lsb_CDB_fg),
    .lsb_op(lsb_CDB_op),
    .lsb_val(lsb_CDB_val)
 );  
//memctrl

//alu CDB

LSB LSB(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),
  //ROB
  .op_flag(rob_CDB_fg),          
  .opcode(rob_CDB_op),           
  .imm(rob_CDB_imm),
  .rd(rob_CDB_rd),
  .rs1_val_(rob_CDB_rs1val),
  .rs2_val_(rob_CDB_rs2val),
  .is_val1(rob_CDB_rs1fg),
  .is_val2(rob_CDB_rs2fg),
  .ophead(rob_CDB_oph),
  .input_reorder(rear_CDB),
  //Memctrl

  .flag(lsb_mem_fg),
  .addr(lsb_mem_a),
  .val_in(mem_lsb_val),
  .mem_ok(mem_lsb_memok),
  .val_out(lsb_mem_val),
  .lsb_op(lsb_mem_op),
  //CDB to ROB
  .rob_reorder(lsb_CDB_reorder),
  .lsb_val(lsb_CDB_val),
  .lsb_flag(lsb_CDB_fg),
  .isfull(lsb_if_full),
  .lsb_rob_op(lsb_CDB_op),
  //CDB alu
  .alu_reorder(alu_CDB_reorder),
  .alu_val(alu_CDB_val),
  .alu_flag(alu_CDB_flag)
 );


ALU ALU(
//RS
.val1(rs_alu_rs1),
.val2(rs_alu_rs2),
.flag(rs_alu_fg),
.opcode(rs_alu_op),
.rob_reorder(rs_alu_rob),
//CDB
.ans(alu_CDB_val),
.flag_out(alu_CDB_flag),
.rob_(alu_CDB_reorder),
.op(alu_CDB_op)
); 


RegFile RegFile(
    .clk(clk_in),
    .rdy(rdy_in),
    .rst(rst_in),
    //ROB op
    .rs1(rob_reg_rs1a),
    .rs2(rob_reg_rs2a),
    .rs1_ready(reg_rob_rs1fg),
    .rs2_ready(reg_rob_rs2fg),
    .rs1_val(reg_rob_val1),
    .rs2_val(reg_rob_val2),
    //ROB
    .rd_in_flag(rob_CDB_inflag),
    .rd_out_flag(rob_CDB_outflag),
    .rd_in_a(rob_CDB_inidx),
    .rd_out_a(rob_CDB_outidx),
    .rd_out_val(rob_CDB_outval),
    .rd_in_rob(rear_CDB),
    .rd_out_rob(front_CDB)

);


always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule