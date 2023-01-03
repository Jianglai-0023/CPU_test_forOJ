`include "defines.v"
module LSB(
    input wire          clk,rst,rdy,
    //ROB(CDB)
    input wire          op_flag,
    input wire [5 : 0]  opcode,
    input wire [31 : 0] imm,
    input wire [4 : 0]  rd,
    input wire [31 : 0] rs1_val_, rs2_val_,
    input wire          is_val1,is_val2,
    input wire [6 : 0]  ophead,
    input wire [`RBID]  input_reorder,
    //MemCtrl
    output wire          flag,    
    output reg [31 : 0] addr,    
    input wire [31 : 0] val_in,
    input wire          mem_ok,
    output reg [31 : 0] val_out,
    output reg [5 : 0]  lsb_op,
    //CDB
    output reg [`RBID] rob_reorder,
    output reg [31 : 0]lsb_val,
    output reg         lsb_flag,
    output wire        isfull,
    output reg [5 : 0] lsb_rob_op,
    
    //CDB alu
    input wire [`RBID] alu_reorder,
    input wire [31 : 0] alu_val,
    input wire          alu_flag,
    input wire [5 : 0]  alu_op

);
    reg full;
    reg [`ILEN]     ins                 [`LSSZ];     //存储指令
    reg [`LSSZ]     is_commit                  ;     //是否该条指令已经push
    reg [`RLEN]     imm_val             [`LSSZ];    
    reg [`RLEN]     rs1_val             [`LSSZ]; 
    reg [`RLEN]     rs2_val             [`LSSZ]; 
    reg [`LSSZ]     rs1_ready,rs2_ready        ;
    reg [`RBID]     ROB_idx             [`LSSZ];      //load 对应的rob   
    reg [`LSID]     front,rear;                      //rear放在最后一个空节点，头节点放数据；
    integer i;
    reg tomem_flag;
assign isfull = full;
assign flag = !mem_ok & tomem_flag;
always @(*) begin
    if(rst)begin
        for(i = 0; i < 16;i = i+1)begin
            ins[i] =6'b0;
            imm_val[i] = 32'b0;
            rs1_val[i] = 32'b0;
            rs2_val[i] = 32'b0;
            ROB_idx[i] = 4'b0;
        end
       full = 0;
    end
    else if(!rdy);
    else begin
        if(is_commit==32'b0)begin
            full = 1;
        end
        else full = 0;
    end
end
always @(posedge clk) begin//接受信息，将指令加入lsb
    if(rst)begin
        tomem_flag <= 0;
        is_commit <= 16'b1111111111111111;
        // full <= 0;
        rs1_ready <= 16'b0;
        rs2_ready <= 16'b0;
        front <= 4'b0;
        rear <= 4'b0;
        lsb_flag <= `False;
    end
    else if(!rdy)begin
        
    end
    else if(!full&&op_flag)begin//加入信息
        case(ophead)
            `JALROP:begin
                ins[rear] <= opcode;
                imm_val[rear] <= imm;
                rs1_val[rear] <= rs1_val_;
                rs2_val[rear] <= rs2_val_;
                rs1_ready[rear] <= is_val1;
                rs2_ready[rear] <= is_val2; 
            end
            `BRANCHOP:begin
                ins[rear] <= opcode;
                imm_val[rear] <= imm;
                rs1_val[rear] <= rs1_val_;
                rs2_val[rear] <= rs2_val_;
                rs1_ready[rear] <= 1;
                rs2_ready[rear] <= 1;
                rear <= -(~rear);
                is_commit[rear] <= `False;
            end
            `ITYPEOP:begin
                ins[rear] <= opcode;
                rs1_val[rear] <= rs1_val_;
                rs2_val[rear] <= rs2_val_;
                rs1_ready[rear] <= is_val1;
                rs2_ready[rear] <= is_val2;
                rear <= -(~rear); 
                is_commit[rear] <= `False;
                ROB_idx[rear] <= input_reorder;
            end
            `STYPEOP:begin
                ins[rear] <= opcode;
                imm_val[rear] <= imm;
                rs1_val[rear] <= rs1_val_;
                rs2_val[rear] <= rs2_val_;
                rs1_ready[rear] <= is_val1;
                rs2_ready[rear] <= is_val2;
                rear <= -(~rear);
                is_commit[rear] <= `False;
            end
            default:;
        endcase
        // if(ophead==`JALROP || ophead == `BRANCHOP || ophead == `ITYPEOP || ophead == `STYPEOP)begin
        //     if(front==-(~rear) && rs1_ready[front] && rs2_ready[front])begin//rear
        //         if(ins[front]==`JALR || ins[front]==`BEQ||ins[front]==`BNE||ins[front]==`BLT||ins[front]==`BGE||ins[front]==`BLTU||ins[front]==`BGEU)begin
        //             full <= `False;
        //         end
        //         else if(mem_ok)begin
        //             full <= `False;
        //         end
        //         else full <= `False;
        //     end
        // end
    end
    
    
    if(front != rear || (front == rear && is_commit[front] == `False))begin//push front
        if(rs1_ready[front]&&rs2_ready[front])begin
            if(ins[front]==`JALR || ins[front]==`BEQ||ins[front]==`BNE||ins[front]==`BLT||ins[front]==`BGE||ins[front]==`BLTU||ins[front]==`BGEU)begin
                is_commit[front] <= `True;
                front <= -(~front);
                lsb_flag<=`False;
                // if(full)full <= `False;
                // else ;
            end
            else begin
                lsb_op <= ins[front];
                lsb_rob_op<=ins[front];
                // if(mem_ok)begin
                //     $display("%s","------");
                //     $display("%d",lsb_op);
                //     $display("%d",addr); 
                //     if(lsb_op==`SB || lsb_op == `SW || lsb_op == `SH)begin
                    
                //         $display("%d",val_out);
                //     end
                //     else begin
                        
                //         case(lsb_op)
                //         `LB:$display("%d",{{24{val_in[7]}}, val_in[7:0]});
                //         `LH:$display("%d",{{16{val_in[15]}},val_in[15:0]});
                //         `LW:$display("%d",val_in);
                //         `LBU:$display("%d",{24'b0,val_in[7:0]});
                //         `LHU:$display("%d",{16'b0,val_in[15:0]});
                //         endcase
                //     end
                // end
                // else ;
                case(ins[front])//todo 可以先统一load/store 再根据位数处理
                    `LB:begin
                        if(mem_ok)begin
                            tomem_flag <= `False;
                            lsb_flag <= `True;
                            // rob_op<=ins[front];
                            rob_reorder <= ROB_idx[front];
                            lsb_val <={{24{val_in[7]}}, val_in[7:0]};
                            is_commit[front] <= `True;
                            front <= -(~front);
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                            lsb_flag <= `False;
                            addr <= rs1_val[front] + rs2_val[front];
                            tomem_flag <= `True; 
                        end

                    end
                    `LH:begin
                        if(mem_ok)begin
                           tomem_flag <= `False;
                            lsb_flag <= `True;
                            rob_reorder <= ROB_idx[front];
                            lsb_val <= {{16{val_in[15]}},val_in[15:0]};
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                            lsb_flag <= `False;
                            addr <= rs1_val[front] + rs2_val[front];
                            tomem_flag <= `True; 
                        end
                    end
                    `LW:begin
                        if(mem_ok)begin
                            tomem_flag <= `False;
                            lsb_flag <= `True;
                            rob_reorder <= ROB_idx[front];
                            lsb_val <= val_in;
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                            
                        end
                        else begin
                            lsb_flag <= `False;
                            addr <= rs1_val[front] + rs2_val[front];
                            
                            tomem_flag <= `True; 
                        end 

                    end
                    `LBU:begin
                        if(mem_ok)begin
                           tomem_flag <= `False;
                            lsb_flag <= `True;
                            rob_reorder <= ROB_idx[front];
                            lsb_val <= {24'b0,val_in[7:0]};
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                            lsb_flag <= `False;
                            addr <= rs1_val[front] + rs2_val[front];
                            tomem_flag <= `True; 
                        end  
                    end
                    `LHU:begin
                        if(mem_ok)begin
                           tomem_flag <= `False;
                            lsb_flag <= `True;
                            rob_reorder <= ROB_idx[front];
                            lsb_val <= {16'b0,val_in[15:0]};
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                            lsb_flag <= `False;
                            addr <= rs1_val[front] + rs2_val[front];
                            tomem_flag <= `True; 
                        end   
                    end
                    `SB:begin
                        lsb_flag <= `False;
                        if(mem_ok)begin
                            tomem_flag <= `False;
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                        
                            addr <= rs1_val[front] + imm_val[front];
                            val_out <= {24'b0,rs2_val[front][7:0]};
                            tomem_flag <= `True;

                        end   
                    end
                    `SW:begin
                        lsb_flag <= `False;
                        if(mem_ok)begin
                            tomem_flag <= `False;
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                            // $display("%s","-----SW-----");
                            // $display("%d",addr);
                            // $display("%x",addr); 
                            // // $display("%d",rs2_val[front]);
                            // // $display("%x",rs2_val[front]);
                            // $display("%s","***SW***");
                        end
                        else begin
                            addr <= rs1_val[front] + imm_val[front];
                            val_out <= rs2_val[front];
                            tomem_flag <= `True;
                            
                        end   
                    end
                    `SH:begin
                        lsb_flag <= `False;
                        if(mem_ok)begin
                            tomem_flag <= `False;
                            is_commit[front] <= `True;
                            front <= -(~front); 
                            // if(full)full <= `False;
                            // else ;
                        end
                        else begin
                            addr <= rs1_val[front] + imm_val[front];
                            val_out <= {16'b0,rs2_val[front][15:0]};
                            tomem_flag <= `True;
                        end   
                    end
                    default begin
                        tomem_flag <= `False;
                        lsb_flag <= `False;
                    end
                endcase
            end 
        end
        else begin
        lsb_flag <=`False;
        tomem_flag <= `False;
        end   
    end

    if(alu_flag)begin
        for(i = 0; i < `LSBSIZE; i = i + 1)begin
            if(is_commit[i] == `False && !rs1_ready[i]&&rs1_val[i]=={28'b0,alu_reorder})begin
                rs1_ready[i] <= `True;
                rs1_val[i] <= alu_val;   
            end
            else;
                                   
            if(is_commit[i] == `False && !rs2_ready[i]&&rs2_val[i]=={28'b0,alu_reorder})begin
                rs2_ready[i] <= `True;
                rs2_val[i] <= alu_val;
            end
            else ;
        end
    end
    else;

    if(lsb_flag)begin
        for(i = 0; i < `LSBSIZE; i = i + 1)begin
            if(is_commit[i] == `False && !rs1_ready[i]&&rs1_val[i]=={28'b0,rob_reorder})begin
                rs1_ready[i] <= `True;
                rs1_val[i] <= lsb_val;   
            end
                                   
            if(is_commit[i] == `False && !rs2_ready[i]&&rs2_val[i]=={28'b0,rob_reorder})begin
                rs2_ready[i] <= `True;
                rs2_val[i] <= lsb_val;
            end
            else ;
        end 
    end
    else;
end
endmodule