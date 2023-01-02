`include "defines.v"


module RS(
    input clk,rst,rdy,
    //CDB of ROB(decode)
    // input  wire [31 : 0]     imm,
    input  wire [5 : 0 ]     opcode,
    input wire  [6 : 0 ]     ophead,
    // input  wire [4 : 0 ]     rs1,rs2,
    input  wire              opflag,
    output wire              rs_full,
    input  wire              rs1_ready,rs2_ready,
    input  wire [31 : 0]     rs1_val,rs2_val,
    input wire  [3 : 0]      rob_reorder,
    //CDB of ROB commit
    // input  wire [3 : 0 ]     rob_reorder,   //rd变量在ROB中的编号
    // input  wire [31 : 0]     rd_val,        //rd变量的现有值
    // input  wire              rd_flag,        
    //ALU
    output reg  [5 : 0 ]     op_alu,
    output reg  [31 : 0]     rs1_alu,
    output reg  [31 : 0]     rs2_alu,
    output reg               flag_alu,
    output reg [3 : 0]       rob_alu,
    input wire               alu_ans_flag,
    input wire [3 : 0]       alu_ans_reorder,
    input wire [31 : 0]      alu_ans,
    //LSB
    input wire lsb_flag,
    input wire [`RBID] lsb_reorder,
    input wire [31 : 0] lsb_val

);
    reg  [`ILEN]    ins             [`RSSZ];                            // RS 中保存的指令
    reg  [`RSSZ]    used;                                               // RS 的使用状态
    reg  [`RLEN]    val1            [`RSSZ];                            // RS 存的 rs1 寄存器值
    reg  [`RLEN]    val2            [`RSSZ];                            // RS 存的 rs2 寄存器值
    reg  [`RSSZ]    val1_ready;                                         // RS 中 rs1 是否拿到真值
    reg  [`RSSZ]    val2_ready;                                         // RS 中 rs2 是否拿到真值
    reg  [`RBID]    ROB_idx         [`RSSZ];                            // RS 要把结果发送到的 ROB 编号
    reg isfull;
    assign rs_full = isfull;
    integer i;


always @(*) begin
    if(rst)begin
        isfull = 0;
        for(i = 0; i < 16; i = i+1)begin
            ins[i] = 6'b0;
            val1[i] = 32'b0;
            val2[i] = 32'b0;
            ROB_idx[i] = 4'b0;
        end        
    end
    else if(!rdy)begin
       
    end

    else begin
        if(used==~(16'b0))isfull = 1;
        else isfull = 0;
    end
end
always @(posedge clk)begin
    if(rst)begin
        used <= 16'b0;
        val1_ready <= 16'b0;
        val2_ready <= 16'b0;
        flag_alu <= 0;
    end
    else if(!rdy)begin
        // $display("%s","RDY appear");
         flag_alu <= `False;
    end
    else if(opflag)begin//加入新的op
        begin:loop
            for(i = 0; i < `RSSIZE; i = i + 1)begin//考虑RS is full的情况
                if(!used[i])begin
                    ins[i]<=opcode;
                    ROB_idx[i] <= rob_reorder;//考虑ROB满的情况  
                    case(ophead)
                        `LUIOP:;
                        `AUIPCOP:;
                        `JALOP:;
                        `JALROP:begin
                            val1_ready[i] <= rs1_ready;
                            val1[i] <= rs1_val;
                            val2[i] <= rs2_val;
                            val2_ready[i] <= 1;
                            used[i] <= `True;
                        end 
                        `BRANCHOP:begin
                            val1_ready[i] <= rs1_ready;
                            val1[i] <= rs1_val;
                            val2_ready[i] <= rs2_ready;
                            val2[i] <= rs2_val;
                            used[i] <= `True; 
                        end
                        `ITYPEOP:begin
                            // val1_ready[i] <= rs1_ready;
                            // val1[i] <= rs1_val;
                            // val2_ready[i] <= 1;
                            // val2[i] <= rs2_val;
                            // used[i] <= `True;
                        end
                        `STYPEOP:begin
                            // val1_ready[i] <= rs1_ready;
                            // val1[i] <= rs1_val;
                            // val2_ready[i] <= rs2_ready;
                            // val2[i] <= rs2_val;
                            // used[i] <= `True; 
                        end
                        `ADDIOP:begin
                            val1_ready[i] <= rs1_ready;
                            val1[i] <= rs1_val;
                            val2_ready[i] <= 1;
                            val2[i] <= rs2_val;
                            used[i] <= `True; 
                        end
                        `RTYPEOP:begin
                            val1_ready[i] <= rs1_ready;
                            val1[i] <= rs1_val;
                            val2_ready[i] <= rs2_ready;
                            val2[i] <= rs2_val;
                            used[i] <= `True; 
                        end
                    endcase
                    disable loop; 
                end
            end
            // if(i== `RSSIZE) isfull <= 1;
            // else isfull <= 0; 
        end
    end
    else ;
    
    if(lsb_flag)begin
       for(i = 0; i < `RSSIZE; i = i + 1)begin
                // $display("%d",i);
                // $display("%d",val2[0]);
                // $display("%d",val1[0]);
                if(used[i]&&!val1_ready[i]&&val1[i] == {28'b0,lsb_reorder})begin
                    val1_ready[i] <= `True;
                    val1[i] <= lsb_val;
                end
                if(used[i]&&!val2_ready[i]&&val2[i] == {28'b0,lsb_reorder})begin
                    val2_ready[i] <= `True;
                    val2[i] <= lsb_val;
                end
        end 
    end
    else ;
    if(alu_ans_flag)begin//给rename赋值
    
        for(i = 0; i < `RSSIZE; i = i + 1)begin
                if(used[i]&&!val1_ready[i]&&val1[i] == {28'b0,alu_ans_reorder})begin
    
    
                    val1_ready[i] <= `True;
                    val1[i] <= alu_ans;
                end
                if(used[i]&&!val2_ready[i]&&val2[i] == {28'b0,alu_ans_reorder})begin
    
    
                    val2_ready[i] <= `True;
                    val2[i] <= alu_ans;
                end
        end
    end
    else;
    begin:forloop
    for(i = 0; i < `RSSIZE; i = i+1)begin//发射给alu
        
        if (val1_ready[i]&&val2_ready[i]&&used[i])begin
            flag_alu <= `True;
            rs1_alu <= val1[i];
            rs2_alu <= val2[i];
            op_alu <= ins[i];
            rob_alu <= ROB_idx[i];
            used[i] <= `False; 
            disable forloop;
        end
        else ;
        
    end
    end
    if(i==`RSSIZE)begin
        flag_alu <= `False;
        // $display("%s","CRYCRY");
    end
    else ;
end

                    
endmodule