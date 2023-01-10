`include "defines.v"
module RegFile(
    input wire clk,rdy,rst,
    //find reg's val or reorder
    //ROB 询问
    input wire  [4 : 0]     rs1,rs2,
    output wire             rs1_ready, rs2_ready,
    output wire [31 : 0]    rs1_val,rs2_val,

    //ROB 分为写入和读出两种情况。ROB in：更新目标reg的rename值；ROB pop：修改目标reg的val，比较rename是否一致
    input wire rd_in_flag,rd_out_flag,
    input wire [4 : 0] rd_in_a,rd_out_a,
    input wire [31 : 0] rd_out_val,
    input wire [3 : 0] rd_in_rob,rd_out_rob
);
reg  [31 : 0]    reg_val    [31:0];       //寄存器中的val
reg  [31 : 0]    reg_state;             //0 有rename；1 无rename
reg  [ 3: 0]    ROB_pos     [31: 0];    //寄存器的rename

integer i;
assign rs1_ready = (rs1==0) ? 1 : reg_state[rs1];
assign rs2_ready = (rs2==0) ? 1 : reg_state[rs2];
assign rs1_val = (rs1==0) ? 0 : (reg_state[rs1] ?  reg_val[rs1] : {28'b0,ROB_pos[rs1]});
assign rs2_val = (rs2==0) ? 0 : (reg_state[rs2] ? reg_val[rs2] : {28'b0,ROB_pos[rs2]});

always @(*) begin
    if(rst)begin
    
    end
    else ;
end
always @(posedge clk) begin
    // $display("%s","UOOU");
    // $display("%d",reg_val[2]);
    if(rst)begin
        for(i = 0; i < 32; i = i+1)begin
        reg_val[i] = 32'b0;
        ROB_pos[i] = 4'b0;
    end
        reg_state <= ~(`null32);
            for (i = 0; i < 32; i = i + 1)begin
                reg_val[i] <= `null32; 
            end
    end
    else if(!rdy)begin
        
    end
    else begin// if in and out 同时
        if(rd_in_flag && rd_out_flag && rd_in_a == rd_out_a)begin
           if(rd_in_a==0)begin//不能修改0号寄存器
                
            end
            else begin
                reg_val[rd_in_a] <= rd_out_val;
                reg_state[rd_in_a] <= 0;
                ROB_pos[rd_in_a] <= rd_in_rob; 
            end 
        end
        else begin
            if(rd_in_flag)begin
                if(rd_in_a==0)begin//不能修改0号寄存器

                end
                else begin
                    // if(rd_out_a==11)begin
                    //     $display("%s","REG-ONE");
                    //     $display("%b",rd_out_val);
                    // end
                    // else if(rd_out_a==12)begin
                    //     $display("%s","REG-TWO");
                    //     $display("%b",rd_out_val);
                    // end
                    reg_state[rd_in_a] <= 0;
                    ROB_pos[rd_in_a] <= rd_in_rob; 
                end
            end
            if(rd_out_flag)begin
                if(rd_out_a==0)begin
                //     $display("%s","RA");
                //    $display("%x",rd_out_val); 
                end
                else begin
                    // if(rd_out_a==15)begin
                    //     $display("%s","REG");
                    //     $display("%d",rd_out_val);
                    // end
                    // else if(rd_out_a==14)begin
                    //     $display("%s","REGTWO");
                    //     $display("%d",rd_out_val);
                    // end
                    if(ROB_pos[rd_out_a] != rd_out_rob)begin
                        reg_val[rd_out_a] <= rd_out_val;
                    end
                    else begin
                        reg_val[rd_out_a] <= rd_out_val;
                        reg_state[rd_out_a] <= 1;
                    end
                end 
            end 
        end
    end
end


endmodule