`include "defines.v"

module ROB(
  input wire            clk,rst,rdy,
  //Decode
  input wire  [4 : 0]   rd_idx,  //rd对应的寄存器类型
  // input wire            rd_isready,
  input wire  [31 :0]   rd_val,
  input                 flag,
  output wire           full,
  
  input wire [31 : 0]   de_imm,
  input wire [5 :  0]   de_opcode,
  input wire [6 :  0]   de_ophead,
  input wire [4 : 0]    de_rs1,de_rs2,
  input wire            op_flag,

  //CDB for regfile
  output reg [31 : 0]   rd_val_update,   //修改的值
  output reg [4 : 0]    rd_idxin_update,   //需要被修改的reg
  output reg [4 : 0]    rd_idxout_update,   //需要被修改的reg
  output reg [`RBID]    reorder_front,reorder_rear,      //ROB reorder的位置 只有在regfile的reorder与rob reorder相同时，regfile才需要被置零
  output reg            rd_out_fg,rd_in_fg,
  output reg            op_is_jp,      //jp 传递给IF
  output reg [31 : 0]   pc_target,     //
  output reg            pc_isjalr,
  //CDB to RS&LSB
  output wire          op_is_come,
  output wire [5 : 0]  opcode,
  output wire [6 : 0]  ophead,
  output wire [31 : 0] imm,
  output reg [4 : 0]  rd,
  output reg [31 : 0] rs1_val_, rs2_val_,
  output reg          is_val1,is_val2,   

  //RegFile
  output wire [4 : 0 ]     rs1_addr,rs2_addr,
  input  wire              rs1_ready,rs2_ready,
  input  wire [31 : 0]     rs1_val,rs2_val,
  

  //ALU
  input wire [`RBID]    rob_reorder,
  input wire [`RLEN]    alu_val,
  input wire            alu_flag,
  input wire [5 : 0]    alu_opcode,

  //LSB
  input wire [`RBID]    lsb_reorder,
  input wire lsb_flag,
  input wire [5 : 0] lsb_op,
  input wire [31 : 0] lsb_val
  
);
  reg [`RLEN]     val         [`RBSZ];      //rd写入的值
  reg [`RBSZ]     is_commited        ;
  reg             is_full;                  //ROB is full
  reg [`RBSZ]     is_ready;                 //是否ready
  reg [`RIDX]     rd_addr     [`RBSZ];      //写入位置
  reg [31 :0]     pc_num      [`RBSZ];      //branch 增加的指令
  reg             is_pc       [`RBSZ];  
  reg [5 : 0]     op          [`RBSZ];
  integer i;
  reg [`RBID]     front;
  reg [`RBID]     rear; 
  reg [`RBSZ]     is_store;
  
  // reg is_val1;
  // reg is_val2;
  // reg [31 : 0] rs1_val_;
  // reg [31 : 0] rs2_val_;
  assign op_is_come = flag;
  assign full = is_full;
  assign rs1_addr = de_rs1;
  assign rs2_addr = de_rs2;
  // assign is_val1 = rs1_ready ? rs1_ready : is_ready[rs1_val];
  // assign is_val2 = rs2_ready ? rs2_ready : is_ready[rs2_val];
  // assign rs1_val_ = is_val1 ? (rs1_ready ? rs1_val:val[rs1_val]) : rs1_val;
  // assign rs2_val_ = is_val2 ? (rs2_ready ? rs2_val:val[rs2_val]) : rs2_val;
  assign imm = de_imm;
  assign opcode = de_opcode;
  assign ophead = de_ophead;
always @(*) begin
    if(rst)begin
    for(i = 0; i < 16; i=i+1)begin
      val[i] = 32'b0;
      op[i] = 6'b0;
      rd_addr[i] = 5'b0;
      pc_num[i] = 32'b0;
      is_pc[i] = 0;
    end
    rd_in_fg = `False;
    end
    else if(!rdy)begin
      
    end
    else begin
      reorder_rear = rear;
      case(de_ophead)
        `LUIOP:begin
          is_val1 = 1;
          is_val2 = 1;
        end
        `AUIPCOP:begin
         is_val1 = 1;
          is_val2 = 1; 
        end
        `JALOP:begin
          is_val1 = 1;
          is_val2 = 1;
        end
        `JALROP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
         is_val2 = 1; 
         rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
         rs2_val_ = de_imm;
        end
        `BRANCHOP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
         is_val2 = rs2_ready ? rs2_ready : (is_ready[rs2_val] ? is_ready[rs2_val] : ((alu_flag && {28'b0,rob_reorder}==rs2_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs2_val));
         rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
         rs2_val_ =is_val2 ? (rs2_ready ? rs2_val:(is_ready[rs2_val] ? val[rs2_val] : ((alu_flag&&{28'b0,rob_reorder}==rs2_val)? alu_val : lsb_val))) : rs2_val;        
         end
        `ITYPEOP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
          is_val2 =1;
          rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
          rs2_val_ = de_imm;  
        end
        `STYPEOP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
         is_val2 = rs2_ready ? rs2_ready : (is_ready[rs2_val] ? is_ready[rs2_val] : ((alu_flag && {28'b0,rob_reorder}==rs2_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs2_val));
         rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
         rs2_val_ =is_val2 ? (rs2_ready ? rs2_val:(is_ready[rs2_val] ? val[rs2_val] : ((alu_flag&&{28'b0,rob_reorder}==rs2_val)? alu_val : lsb_val))) : rs2_val;        
        end
        `ADDIOP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
          is_val2 = 1; 
          rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
          rs2_val_ = de_imm;
        end
        `RTYPEOP:begin
         is_val1 = rs1_ready ? rs1_ready : (is_ready[rs1_val] ? is_ready[rs1_val] : ((alu_flag && {28'b0,rob_reorder}==rs1_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs1_val));
         is_val2 = rs2_ready ? rs2_ready : (is_ready[rs2_val] ? is_ready[rs2_val] : ((alu_flag && {28'b0,rob_reorder}==rs2_val) ? 1 : lsb_flag && {28'b0,lsb_reorder}==rs2_val));
         rs1_val_ =is_val1 ? (rs1_ready ? rs1_val:(is_ready[rs1_val] ? val[rs1_val] : ((alu_flag&&{28'b0,rob_reorder}==rs1_val)? alu_val : lsb_val))) : rs1_val; 
         rs2_val_ =is_val2 ? (rs2_ready ? rs2_val:(is_ready[rs2_val] ? val[rs2_val] : ((alu_flag&&{28'b0,rob_reorder}==rs2_val)? alu_val : lsb_val))) : rs2_val;        
        end
        default:;
      endcase
      if(!is_full)begin
        if(flag)begin
          if(ophead==`STYPEOP || ophead == `BRANCHOP)begin
            rd_in_fg = `False;
          end
          else begin
            rd_in_fg = `True;
            rd_idxin_update = rd_idx; 
          end
        end
        else rd_in_fg = `False;
      end
      else rd_in_fg = `False;
end
   
  end
always @(posedge clk) begin//考虑ROB is full
  if(rst)begin
    rd_out_fg <= `False;
    // rd_in_fg <= `False;
    // op_is_come <=`False;
    is_full <= 0;
    is_ready <= 16'b0;
     is_commited <= 16'b1111111111111111;
     rear <= 4'b0;
    front <= 4'b0;
    is_store <= 16'b0;
  end
  else if(!rdy)begin
    
  end
  else if(!is_full)begin
        if(flag)begin//加入新的opt 不放入store指令
            is_commited[rear] <= `False;
            rd_addr[rear] <= rd_idx;
            val[rear] <= rd_val;
            op[rear] <= opcode;

            if(ophead==`STYPEOP)begin
              is_store[rear] <= `True;
              // rd_in_fg <= `False;
            end
            else begin
              is_store[rear] <=`False;
              // if(ophead == `BRANCHOP)begin
              //   // rd_in_fg <= `False;  
              // end
              // else begin
              //   // rd_in_fg <= `True;
              //   // rd_idxin_update <= rd_idx;
              // end
            end
            
            if(ophead==`AUIPCOP || ophead == `JALOP || ophead == `LUIOP || ophead == `STYPEOP)begin
              is_ready[rear] <= `True;
            end
            else begin
              is_ready[rear]  <= `False;//must be changed by alu or lsb
            end

            
            if(ophead == `BRANCHOP || ophead == `JALROP)begin
              pc_num[rear] <= de_imm; 
              is_pc[rear]  <= 1;
              // reorder_rear <= rear;
              // rd_in_fg <= `True;
              rear <= -(~rear);
            end 
            else begin
             rear <= -(~rear); 
             is_pc[rear] <= 0;
            end 
            if(rear == front && !is_commited[rear])is_full <= 1;
            else is_full <= 0;
        end  
        else begin
          // op_is_come <= `False;
          // rd_in_fg <= `False;
        end  
  end
  else begin
    // op_is_come<=`False;
    // rd_in_fg <= `False;
  end
 
 
  if((front != rear || !is_commited[front]) && is_ready[front])begin//可以发射指令:非空 & ready
        front <= -(~front);
        is_commited[front] <= `True;
        // val[front] <= 32'b0;
        op_is_jp <= is_pc[front];
        pc_target <= op[front]==`JALR ? pc_num[front] : (val[front]==1 ? pc_num[front] : 32'd4);
        pc_isjalr <= op[front]==`JALR;
        is_pc[front]<=0;
        if(is_store[front])begin
          rd_out_fg <=`False;
          // op_is_jp <= `False;
        end
        else if(is_pc[front]&&op[front]!=`JALR)begin
          rd_out_fg <= `False;
        end
        else begin
            rd_out_fg <= `True;
            rd_val_update <= val[front];
            rd_idxout_update <= rd_addr[front];
            reorder_front <= front;
        end
        if(is_full)is_full<= `False;
        else ;
    end
    else begin
      rd_out_fg<= `False;
      op_is_jp <= `False;
    end

    if(alu_flag)begin//更新ready
        if(alu_opcode==`LB||alu_opcode==`LH||alu_opcode==`LW||alu_opcode==`LBU||alu_opcode==`LHU||alu_opcode == `SB || alu_opcode == `SH || alu_opcode==`SW)begin
        end
        else begin
          if(alu_opcode==`JALR)begin
            pc_num[rob_reorder] <= alu_val;
            // $display("%s","JALR");
            // $display("%d",alu_val);
          end
          else val[rob_reorder] <= alu_val;

          is_ready[rob_reorder] <= `True;  
        end
    end
    else ;

    if(lsb_flag)begin
      if(lsb_op==`LB||lsb_op==`LH||lsb_op==`LW||lsb_op==`LBU||lsb_op==`LHU)begin
        val[lsb_reorder] <= lsb_val;
        is_ready[lsb_reorder] <= 1;
      end
      else ;
    end
    else;
  end
  
  
endmodule