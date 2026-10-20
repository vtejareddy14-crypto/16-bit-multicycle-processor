`timescale 1ns / 1ps

module proc_testbench;
reg [15:0] DIN;
reg Resetn;
reg Clock;          // inputs as reg
reg Run;

wire Done;          // output as wire

integer errors = 0;
reg [15:0] result;

// instantiation of processor here
proc uut(
    .DIN(DIN),
    .Resetn(Resetn),
    .Clock(Clock),
    .Run(Run),
    .Done(Done)
    );

initial Clock = 0;
always #10 Clock = ~Clock;   // every 10ns clock toggles

// print the main signals whenever one of them changes
initial
    $monitor("%4d ns | T%0d Run=%b IR=%h Bus=%h A=%h G=%h Done=%b | r0=%h r1=%h r2=%h r3=%h",
             $time, uut.Tstep_Q, Run, uut.IR, uut.Buswires, uut._A, uut._G, Done,
             uut.r0, uut.r1, uut.r2, uut.r3);

// give one instruction to the processor, wait 4 clocks (T0-T3), then check rX
task run_instr;
input [15:0] instr;
input [15:0] expected;   // value rX should have afterwards
begin
    @(negedge Clock);
    DIN = instr;
    Run = 1;
    @(negedge Clock);
    Run = 0;
    repeat (3) @(negedge Clock);

    case (instr[11:9])   // rX field
        3'd0: result = uut.r0;
        3'd1: result = uut.r1;
        3'd2: result = uut.r2;
        3'd3: result = uut.r3;
        3'd4: result = uut.r4;
        3'd5: result = uut.r5;
        3'd6: result = uut.r6;
        3'd7: result = uut.r7;
    endcase

    if (result !== expected) begin
        $display("---- FAIL: r%0d = %h, expected %h", instr[11:9], result, expected);
        errors = errors + 1;
    end
    else
        $display("---- PASS: r%0d = %h", instr[11:9], result);
end
endtask

initial begin
$dumpfile("proc_testbench.vcd");   // for GTKWave
$dumpvars(0, proc_testbench);

Resetn = 0;   // initial values
Run = 0;
DIN = 16'b0;

#25           // hold reset for some time
Resetn = 1;

// encoding: III IMM XXX DDDDDDDDD   (mv=000, mvt=001, add=010, sub=011)
run_instr(16'b000_1_000_000000101, 16'h0005);   // mv  r0, #5
run_instr(16'b000_1_001_000000111, 16'h0007);   // mv  r1, #7
run_instr(16'b010_0_000_000000001, 16'h000C);   // add r0, r1   -> 12
run_instr(16'b011_0_000_000000001, 16'h0005);   // sub r0, r1   -> 5
run_instr(16'b000_0_010_000000000, 16'h0005);   // mv  r2, r0
run_instr(16'b001_1_011_011111111, 16'hFF00);   // mvt r3, #0xFF
run_instr(16'b010_1_011_011111111, 16'hFFFF);   // add r3, #0xFF
run_instr(16'b000_1_001_111100100, 16'hFFE4);   // mv  r1, #-28 (sign extension)

if (errors == 0) $display("\nALL TESTS PASSED");
else             $display("\n%0d TEST(S) FAILED", errors);

#20;
$finish;
end

endmodule
