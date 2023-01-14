`include "defines.v"
module Decoder(
     input wire           clk,rst,rdy,
     //IF
     input wire [31 : 0]  ins,
     input wire           ins_flag,
     inout wire [31 : 0]  ins_imm,
     input wire [31 : 0]  rd_val,
    //  input wire [31 : 0]  pc,
    //  input wire           pc_bc_flag,
    //  input wire [31 : 0]  pc_bc,
    //  output wire          if_stall,
     //RS
     
    //  input wire           bc_out, //不带分支预测，
    
    //ROB
    output reg [5 :  0]  opcode,
    output reg [6 : 0]   ophead,
    output reg [31 : 0]  imm,
    output reg [4 :  0]  rs1,rs2,rd,
    output wire          op_flag,
    output wire [31 : 0] rob_rd_val
);
assign op_flag = ins_flag;
assign rob_rd_val = rd_val; 
// assign if_stall = rob_full|lsb_full|((ins[6:0]==7'b1100111|ins[6:0]==7'b1100011)&!bc_out);//every branch
//for op code
always @(*)begin
   
        if(ins_flag)begin
            imm = ins_imm;
            rs1 = ins[19:15];
            rs2 = ins[24:20];
            rd = ins[11:7];
            ophead = ins[6 : 0];
            case(ins[6:0])
                7'b1100011:begin//Btype
                   case(ins[14:12])
                        3'b000: opcode = `BEQ;
                        3'b001: opcode = `BNE;
                        3'b100: opcode = `BLT;
                        3'b101: opcode = `BGE;
                        3'b110: opcode = `BLTU;
                        3'b111: opcode = `BGEU;
                        default:opcode = 6'b0;
                   endcase 
                end 
                7'b0000011:begin//Itype
                    case(ins[14:12])
                        3'b000: opcode = `LB;
                        3'b001: opcode = `LH;
                        3'b010: opcode = `LW;
                        3'b100: opcode = `LBU;
                        3'b101: opcode = `LHU; 
                        default:opcode = 6'b0;
                    endcase 
                end
                7'b0100011:begin//Stype
                     case(ins[14:12])
                        3'b000: opcode = `SB;
                        3'b001: opcode = `SH;
                        3'b010: opcode = `SW;
                        default:opcode = 6'b0;
                    endcase 
                end
                7'b0010011:begin//Itype
                    case(ins[14:12])
                        3'b000: opcode = `ADDI;
                        3'b010: opcode = `SLTI;
                        3'b011: opcode = `SLTIU;
                        3'b100: opcode = `XORI;
                        3'b110: opcode = `ORI;
                        3'b111: opcode = `ANDI;
                        3'b001: opcode = `SLLI;
                        3'b101:begin
                            case(ins[31:25])
                                7'b0000000: opcode = `SRLI;
                                7'b0100000: opcode = `SRAI;
                                default:opcode = 6'b0;
                            endcase
                        end
                        default:;
                    endcase
                end
                7'b0110011:begin//Rtype
                   case(ins[14:12])
                        3'b000:begin
                            case(ins[31:25])
                                7'b0000000: opcode = `ADD;
                                7'b0100000: opcode = `SUB;
                                default:opcode = 6'b0;
                            endcase                        
                        end
                        3'b001: opcode = `SLL;
                        3'b010: opcode = `SLT;
                        3'b011: opcode = `SLTU;
                        3'b100: opcode = `XOR;
                        3'b101:begin
                            case(ins[31:25])
                               7'b0000000: opcode = `SRL;
                               7'b0100000: opcode = `SRA;
                               default:opcode = 6'b0;
                            endcase
                        end 
                        3'b110: opcode = `OR;
                        3'b111: opcode = `AND;
                        default:opcode = 6'b0;
                   endcase 

                end
                7'b0110111:opcode = `LUI;//LUI
                7'b0010111:opcode = `AUIPC;//AUIPC
                7'b1101111:opcode = `JAL;//JAL
                7'b1100111:opcode = `JALR;//JALR
                default:opcode = 6'b0;
            endcase
        end 
        else begin
            opcode = 6'b0; 
       imm = 32'b0;
       rs1 = 5'b0;
       rs2 = 5'b0;
       rd =  5'b0;
       ophead = 7'b0; 
        end
   
end



endmodule