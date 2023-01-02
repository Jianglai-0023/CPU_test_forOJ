`include "defines.v"
module IF(
    input wire          clk,rst,rdy,
    //I-Cache
    input wire [31:0]   ins_ori,       //ins from cache
    output reg[31:0]    pc_cache,      //to cache pc
    input wire          ins_ori_flag,  //ins is just from cache
    output wire          pc_flag,       //cache pc is just sent
    //Decoder
    output wire[31:0]   ins,
    output reg         ins_flag,
    output reg [31 : 0] ins_imm,
    output reg [31 : 0] rd_val,
    // output reg [31 : 0] pc_decode,
    // output reg[31:0]    pc_decode_bc,
    // output reg          pc_decode_bc_flag,
    // input wire          stall, //every branch ins
    //ROB
    // input wire[31:0]    jp_pc,
    // input wire          jp_wrong,
    
    //CDB from ROB
    input wire           jp_ok,
    input wire [31 : 0]  jp_target,
    input wire           jp_isjalr,
    input wire lsb_full,
    input wire rob_full,
    input wire rs_full

);
reg     is_stall;
//在得到此条pc对应的ins之前不会发出下一个pc，同时pc_flag也要一起变


    // assign ins_flag = ins_ori_flag;
    assign ins = ins_ori;
    assign pc_flag = !ins_ori_flag&&!is_stall&&!rob_full&&!lsb_full&&!rs_full;
    //calculate imm
    always @(*)begin//向decode输出结果
        //修改输出的bc
        ins_imm = 32'b0;
        if(rst)begin
            ins_flag = 0;
        end
        else if(!rdy)begin
            
        end
        else if(jp_ok)begin
            // ins_flag = `True;·
        end
        else if(ins_ori_flag&&!is_stall&&!lsb_full && !rob_full && !rs_full)begin
            ins_flag = ins_ori_flag;
            // pc_decode = pc_cache;
            case(ins_ori[6:0])
                `AUIPCOP:begin
                     ins_imm = {ins_ori[31:12],12'b0};
                     rd_val = pc_cache + ins_imm;
                end
                `LUIOP  : begin
                    ins_imm = {ins_ori[31:12], 12'b0};   
                    rd_val = ins_imm;
                end                              
                `JALROP : begin 
                    ins_imm = {{20{ins_ori[31]}}, ins_ori[31:20]};
                    rd_val = pc_cache + 4;
                end
                `JALOP  :begin
                    ins_imm = {{12{ins_ori[31]}}, ins_ori[19:12], ins_ori[20], ins_ori[30:21]} << 1;
                    rd_val = pc_cache + 4;
                end 
                `BRANCHOP: begin 
                    ins_imm = {{20{ins_ori[31]}}, ins_ori[7], ins_ori[30:25], ins_ori[11:8]} << 1;
                end
                `ITYPEOP:begin
                    ins_imm = {{20{ins_ori[31]}},ins_ori[31 : 20]};
                end
                `STYPEOP:begin
                    ins_imm={{20{ins_ori[31]}},ins_ori[31 : 25],ins_ori[11:7]};
                end
                `ADDIOP:begin
                    case(ins_ori[14 : 12])
                    3'b001:ins_imm={27'b0,ins_ori[24 : 20]};
                    3'b101:ins_imm={27'b0,ins_ori[24 : 20]};
                    default:ins_imm= {{20{ins_ori[31]}},ins_ori[31 : 20]};
                    endcase
                    
                end
                default: ins_imm = 32'b0; //branch
            endcase
        end 
        else ins_flag = `False;
    
    end
   reg [31 :0] debug = 0; 
    always @(posedge clk)begin //接受icache并修改自己的pc
       
        debug <= debug + 1;
        // $display("%d",debug); 
        if(rst)begin
            
            is_stall <= 0;
            pc_cache <= 32'b0;
        end
        else if(jp_ok)begin 
            is_stall <= `False;
            // pc_flag <= `True;
            // ins_flag <= `True;
            if(jp_isjalr)pc_cache<=jp_target;
            else pc_cache <= pc_cache + jp_target;
        end
        else if(ins_ori_flag&&!is_stall&&!lsb_full && !rob_full && !rs_full)begin
            // pc_flag <= `True;
            // ins_flag <= ins_ori_flag;
            if(ins_ori_flag)begin   
                
                // $display("%x",pc_cache);
            case(ins_ori[6:0])
            
                `AUIPCOP:begin
                    pc_cache <= pc_cache + 4;
                    // pc_flag <= `True;
                end 
                `JALOP  :begin
                    pc_cache <= pc_cache + ins_imm;
                    // pc_flag <= `False;
                end 
                `JALROP: begin
                    is_stall <= `True;
                    // pc_flag <= `False;
                    // ins_flag <= `False;
                end
                `BRANCHOP:begin 
                    is_stall <= `True; 
                    // pc_flag <= `False;               
                    // ins_flag <= `False;
                    end
                default: begin
                    pc_cache <= pc_cache + 4;
                    // pc_flag <= `True;
                end
            endcase
        end 
        else ;
        end
        else begin
            // pc_flag <= `False;
            // ins_flag <= `False;
        end
        
    end
    
    
endmodule