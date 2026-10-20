module regn (D, Resetn, En, Clock, Q);
input  [15:0] D;
input         Resetn, En, Clock;
output reg [15:0] Q;

always @(posedge Clock or negedge Resetn)
begin
    if (!Resetn)
        Q <= 16'b0;
    else if (En)
        Q <= D;
end
endmodule
