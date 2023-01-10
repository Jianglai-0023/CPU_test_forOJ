`include "defines.v"
module MemCtrl(
    input wire           clk,rst,rdy,
    //RAM
    output reg [31 : 0]  mem_a,
    output reg [7  : 0]  mem_write,
    output reg           is_write,
    input  wire          cannot_read,//io-buffer
    input  wire [7 : 0]  mem_result,

    //ICache
    input  wire [31 : 0] addr_target,
    input  wire          ic_flag, // is wating for instruction
    output reg [31 : 0]  ic_val_out,
    output reg           ic_isok, //==>ins_flag_mem

    //LSB
    input  wire [31 : 0] lsb_addr,
    input  wire          lsb_flag,
    input  wire [5 : 0]  opcode,
    input  wire [31 : 0] lsb_store,
    output reg          lsb_isok,
    output reg  [31 : 0] lsb_val_out
);
//todo lsb的store指令，一次写入不一定为4字节
reg [1:0] if_stp;
reg [1:0] lsb_stp;
reg       lsb_onestp;
reg [31 : 0] ic_val;
reg  [31 : 0] lsb_val;
reg           ic_is_in;
initial begin
    if_stp = 2'b0;
    lsb_stp = 2'b0;
    lsb_onestp = 1'b0;
    ic_val = 32'b0;
    lsb_val = 32'b0;
    ic_isok = 0;
    lsb_isok = 0;
    is_write = 0;
    ic_is_in = 0;
    // mem_a = 32'b0;
end
always @(*) begin
    if(cannot_read)begin 
        is_write = `False;
    end
    if(!rdy)begin
        is_write = `False;
    end
    else if(rst)begin
        is_write = `False;
    end
    else begin
        case(opcode)
            `LB:lsb_val_out = {{24{mem_result[7]}},mem_result};
            `LH:lsb_val_out = {{16{mem_result[7]}},mem_result,lsb_val[7:0]};
            `LW:lsb_val_out = {mem_result,lsb_val[23 : 0]};
            `LBU:lsb_val_out = {24'b0,mem_result};
            `LHU:lsb_val_out = {8'b0,mem_result,lsb_val[15:0]};
        default:lsb_val_out = 32'b0;
        endcase
    //    ic_val_out = {mem_result,ic_val[23:0]}; 
        if(lsb_flag && !ic_is_in && !lsb_isok)begin
            case(opcode)
                `LB:begin
                    mem_a = lsb_addr;
                    is_write = `False;
                end
                `LH:begin 
                    mem_a = lsb_addr + {31'b0,lsb_onestp};
                    is_write = `False;
                end
                `LW:begin
                    mem_a = lsb_addr + {30'b0,lsb_stp};
                    is_write = `False;
                end
                `LBU:begin
                    mem_a = lsb_addr;
                    is_write = `False;
                end
                `LHU:begin
                    mem_a = lsb_addr + {31'b0,lsb_onestp};
                    is_write = `False;
                end
                `SB:begin
                    if(lsb_addr==32'h30000)begin
                        // $display("%s","###");
                        // $display("%d",lsb_store[7 : 0]);
                        // is_write = `False;
                        mem_a = lsb_addr;
                        mem_write = lsb_store[7 : 0];
                        is_write = `True;
                    end
                    else begin
                        mem_a = lsb_addr;
                        mem_write = lsb_store[7 : 0];
                        is_write = `True;
                    end

                end
                `SH:begin
                    mem_a = lsb_addr + {31'b0,lsb_onestp};
                    case(lsb_onestp)
                    1'b0:begin
                        mem_write = lsb_store[7 : 0];
                        is_write = `True;
                    end
                    1'b1:begin
                        mem_write = lsb_store[15 : 8];
                        is_write = `True;
                    end
                    endcase
                end 
                `SW:begin
                    mem_a = lsb_addr + {30'b0,lsb_stp};
                    case(lsb_stp)
                    2'b00:begin
                        mem_write = lsb_store[7 : 0];
                        is_write = `True;
                    end
                    2'b01:begin
                        mem_write = lsb_store[15 : 8];
                        is_write = `True;
                    end
                    2'b10:begin
                        mem_write = lsb_store[23 : 16];
                        is_write = `True;
                    end
                    2'b11:begin
                        mem_write = lsb_store[31 : 24];
                        is_write = `True; 
                    end
                    endcase
                end
                default:begin
                    is_write = `False;
                    mem_a = 32'b0;
                end
            endcase
       end
       else if(ic_flag )begin
            is_write = `False;
            mem_a = addr_target + {30'b0,if_stp}; 
            ic_val_out = {mem_result,ic_val[23 : 0]};
       end
       else begin
            is_write = `False;
            mem_a = 32'b0;
       end
    end
end

always @(posedge clk) begin
    if(!rdy)begin
    
    end
    else if(rst)begin
        if_stp <= 2'b0;
        lsb_stp <= 2'b0;
        lsb_onestp <= 1'b0;
        ic_val <= 32'b0;
        lsb_val <= 32'b0;
        ic_isok <= 0;
        lsb_isok <= 0;
        
    end
    else if(lsb_isok)lsb_isok<=`False;
    else begin
        if(cannot_read)begin end
        else begin 
            if(ic_isok)ic_is_in<=0;
            else ;
            if(lsb_flag && !ic_is_in)begin
                ic_isok <= `False;
                case(opcode)
                `LB:begin
                        lsb_isok <= 1;
                end
                `LH:begin
                    lsb_onestp <= -(~lsb_onestp);
                    case(lsb_onestp)
                        1'b0:ic_isok <= 0;
                        1'b1:begin
                            lsb_isok <= 1;
                            lsb_val[7:0] <= mem_result;
                        end
                    endcase
                end
                `LW:begin
                    lsb_stp <= -(~lsb_stp);
                    case(lsb_stp)
                        2'b01:begin
                            lsb_val[7:0] <= mem_result;
                            lsb_isok <= 0;
                        end
                        2'b10:begin
                            lsb_val[15:8] <= mem_result;
                            lsb_isok <= 0;
                        end
                        2'b11:begin
                            lsb_val[23:16] <= mem_result;
                            lsb_isok <= 1;
                        end
                        default: lsb_isok <= 0;
                    endcase
                end
                `LBU:begin
                    lsb_isok <= 1;
                end
                `LHU:begin
                    lsb_onestp <= -(~lsb_onestp);
                    case(lsb_onestp)
                        1'b0:lsb_isok <= 0;
                        1'b1:begin
                            lsb_isok <= 1;
                            lsb_val[7:0] <= mem_result;
                        end
                    endcase
                end
                `SB:begin
                        lsb_isok <= `True;
                end
                `SH:begin
                    lsb_onestp <= -(~lsb_onestp);
                    case(lsb_onestp)
                    1'b0:begin
                        // mem_write <= lsb_val[7 : 0];
                        lsb_isok <= `False;
                    end
                    1'b1:begin
                        // mem_write <= lsb_val[15 : 8];
                        lsb_isok <= `True;
                    end
                    endcase
                end
                `SW:begin
                    lsb_stp <= -(~lsb_stp);
                    case(lsb_stp)
                    2'b00:begin
                        lsb_isok <= `False;
                        // mem_write<=lsb_val[7 : 0];
                    end
                    2'b01:begin
                        lsb_isok <= `False;
                        // mem_write <= lsb_val[15 : 8];
                    end
                    2'b10:begin
                        lsb_isok <= `False;
                        // mem_write <= lsb_val[23 : 16];
                    end
                    2'b11:begin
                        lsb_isok <= `True;
                        // mem_write <= lsb_val[31 : 24];
                    end 
                    endcase
                end
                default;
                endcase
            end
            else if(ic_flag)begin
                if(!ic_is_in)begin
                    if_stp<=2'b00;
                    ic_is_in<=1;
                end
                else begin
                    if_stp <= -(~if_stp);
                case(if_stp)
                    2'b00:begin
                        ic_isok <= 0;
                        ic_is_in <= 1;
                    end
                    2'b01:begin//1
                        ic_val[7:0] <= mem_result;
                        ic_isok <= `False;
                        ic_is_in <= 1;
                    end 
                    2'b10:begin//2
                        ic_val[15:8] <= mem_result;
                        ic_isok <= `False;
                        ic_is_in <= 1;
                    end
                    2'b11: begin//3 
                        ic_val[23:16] <= mem_result; 
                        ic_isok <= 1;
                        ic_is_in<= 1;
                    end
                endcase 
                end;
                
            end
            else begin
                ic_isok <= `False;
                ic_is_in <= 0;
            end 
        end
    end
end
    // end
    
// end
endmodule