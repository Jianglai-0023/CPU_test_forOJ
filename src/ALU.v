`include "defines.v"
module ALU(
    //RS
    input wire [31 : 0] val1,val2,
    input wire          flag,
    input wire [5 : 0] opcode,
    input wire [`RBID] rob_reorder,
    //CDB
    output reg [31 : 0] ans,
    output wire flag_out,
    output wire [`RBID] rob_,
    output wire [5 : 0]op
);
assign flag_out = flag;
assign rob_ = rob_reorder;
assign op = opcode;
// assign jp_ok = (opcode==`BEQ|opcode==`BNE|opcode==`JALR|opcode==`BLT|opcode==`BGE|opcode==`BLTU|opcode==`BGEU);
    always @(*) begin
        
        if(flag)begin
        case(opcode)
        `SUB :ans = val1 - val2;
        `ADD :ans = val1 + val2;     
        `ADDI:ans = val1 + val2;
        `XOR :ans = val1 ^ val2; 
        `XORI:ans = val1 ^ val2; 
        `OR  :ans = val1 | val2; 
        `ORI :ans = val1 | val2; 
        `AND :ans = val1 & val2; 
        `ANDI:ans = val1 & val2;  
        `SLL :ans = val1 << val2[4:0];
        `SLLI:ans = val1 << val2[4:0]; 
        `SRL :ans = val1 >> val2[4:0]; 
        `SRLI:ans = val1 >> val2[4:0];  
        `SRA :ans = $signed(val1) >> val2; 
        `SRAI:ans = $signed(val1) >> val2[4:0]; 
        `SLTI:ans = $signed(val1) < $signed(val2); 
        `SLT :ans = $signed(val1) < $signed(val2); 
        `SLTIU:ans = val1 < val2;
        `SLTU:ans = val1 < val2; 
        `BEQ :ans = val1 == val2; 
        `BNE :ans = val1 != val2; 
        `BLT :begin 
            ans = $signed(val1) < $signed(val2); 
            //  $display("%s","BLT");
            // $display("%b",val1);
            // $display("%b",val2);
        end
        `BGE :ans = $signed(val1) >= $signed(val2); 
        `BLTU:begin
             ans = val1 < val2; 
            // $display("%s","BLTU");
            // $display("%b",val1);
            // $display("%b",val2);
        end
        `BGEU:ans = val1 >= val2; 
        `JALR:ans = (val1 + val2)&~(32'b1);
        default:ans = `null32;
        endcase 
        end
        else begin
            ans = `null32;
        end
    end
endmodule