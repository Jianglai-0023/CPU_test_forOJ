`include "defines.v"
module ALU(
    //RS
    input wire [31 : 0] val1,val2,
    input wire          flag,
    input wire [5 : 0] opcode,
    input wire [`RBID] rob_reorder,
    //CDB
    output reg [31 : 0] ans,
    output reg flag_out,
    output reg [`RBID] rob_,
    output reg [5 : 0]op
);
// assign flag_out = flag;
// assign rob_ = rob_reorder;
// assign op = opcode;
// assign jp_ok = (opcode==`BEQ|opcode==`BNE|opcode==`JALR|opcode==`BLT|opcode==`BGE|opcode==`BLTU|opcode==`BGEU);
    always @(*) begin
        
        if(flag)begin
            flag_out = `True;
            rob_ = rob_reorder;
            op = opcode;
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
            `SRLI:begin
                ans = val1 >> val2[4:0];  
            //        $display("%s","SRLI");
            //     $display("%b",val1);
            //     $display("%b",val2[4 : 0]); 
            //    $display("%b",ans);  
            end
            `SRA :ans = $signed(val1) >> val2[4 : 0]; 
            `SRAI:begin
                ans = $signed(val1) >> val2[4:0]; 

            end
            `SLTI:ans = $signed(val1) < $signed(val2); 
            `SLT :ans = $signed(val1) < $signed(val2); 
            `SLTIU:ans = val1 < val2;
            `SLTU:ans = val1 < val2; 
            `BEQ :begin
                ans = val1 == val2; 
                //     $display("%s","BEQ");
                // $display("%b",val1);
                // $display("%b",val2); 
            end
            `BNE :ans = val1 != val2; 
            `BLT :begin 
                ans = $signed(val1) < $signed(val2); 
                //  $display("%s","BLT");
                // $display("%b",val1);
                // $display("%b",val2);
            end
            `BGE :begin
                ans = $signed(val1) >= $signed(val2); 
            //    $display("%s","BGE");
            //     $display("%b",val1);
            //     $display("%b",val2); 
            end
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
            flag_out = `False;
            rob_ = 4'b0;
            op = 6'b0;
        end
    end
endmodule