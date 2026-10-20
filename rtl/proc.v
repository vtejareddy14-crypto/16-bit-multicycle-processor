module proc(DIN, Resetn, Clock, Run, Done);
input [15:0] DIN;
input Resetn, Clock, Run;
output reg Done;
wire [15:0] ALU_out;
wire [15:0]_A;
wire [15:0]_G;
reg [15:0] Buswires;
reg [15:0] IR;
wire [2:0] III;
wire IMM;
wire [2:0] rX, rY;
reg [3:0]Sel_rX,Sel_rY;
wire [7:0] R_in;
reg rX_in, A_in, G_in, IR_in, AddSub;
reg [3:0] Select;

reg [2:0] Tstep_Q, Tstep_D;

wire [15:0] r0,r1,r2,r3,r4,r5,r6,r7;

assign III = IR[15:13];
assign IMM = IR[12];
assign rX = IR[11:9];
assign rY = IR[2:0];
dec3to8 dec_inst (rX_in, rX, R_in); // produce r0- r7 register enables
parameter T0 = 3'b000, T1 = 3'b001, T2 = 3'b010, T3 = 3'b011;

always@(posedge Clock or negedge Resetn)begin 
if(!Resetn)
IR<=16'b0;
else if(IR_in)
IR<=DIN;
end 
// Control FSM state table
always@(*)begin
Tstep_D = Tstep_Q;
case(Tstep_Q)
T0:begin  // data is loaded into IR in this time step
if (Run) Tstep_D = T1;
else Tstep_D = T0;
end 
T1:begin 
Tstep_D = T2;
end 
T2: begin 
Tstep_D = T3;
end 
T3: begin 
Tstep_D = T0;
end 
endcase
end

parameter mv = 3'b000, mvt = 3'b001, add = 3'b010, sub = 3'b011;
// selectors for the BusWires multiplexer
parameter _R0=4'b0000, _R1=4'b0001,_R2=4'b0010,_R3=4'b0011,_R4=4'b0100,
_R5=4'b0101,_R6=4'b0110,_R7=4'b0111,_GSEL=4'b1000,_IR8_IR8_0=4'b1001,_IR7_0_0=4'b1010;


always @(*) begin
rX_in = 1'b0; Done = 1'b0;A_in=1'b0;AddSub=1'b0;G_in=1'b0;IR_in=1'b0;Select=4'b0000;// default values for variables
case (Tstep_Q)
T0: begin
if(Run)
    IR_in = 1'b1;
end
T1: begin
case (III)
mv: begin
 Select = IMM ? _IR8_IR8_0 : Sel_rY;
 rX_in = 1'b1;
Done=1'b1;
end
mvt: begin
 Select = _IR7_0_0;
 rX_in = 1'b1;
 Done  = 1'b1;
 end
add, sub: begin
 Select = Sel_rX;  
 A_in   = 1'b1;
end
default:;
endcase
end
T2:begin // define signals in time step T2
case(III) 
add, sub: begin
if(!IMM) Select=Sel_rY;
else Select=_IR8_IR8_0;
AddSub=(III==sub);
G_in=1'b1;
end
default:;
endcase
end
T3: begin
  case (III)
add, sub: begin
 Select = _GSEL;
 rX_in=1'b1;
 Done   = 1'b1;
end
default: ;
 endcase
end
endcase
end
always@(posedge Clock, negedge Resetn)begin
if (!Resetn)
Tstep_Q<=T0;
else
Tstep_Q<=Tstep_D;
end 

regn reg_0(Buswires,Resetn,R_in[0],Clock,r0);
regn reg_1(Buswires,Resetn,R_in[1],Clock,r1);
regn reg_2(Buswires,Resetn,R_in[2],Clock,r2);
regn reg_3(Buswires,Resetn,R_in[3],Clock,r3);
regn reg_4(Buswires,Resetn,R_in[4],Clock,r4);
regn reg_5(Buswires,Resetn,R_in[5],Clock,r5);
regn reg_6(Buswires,Resetn,R_in[6],Clock,r6);
regn reg_7(Buswires,Resetn,R_in[7],Clock,r7);
regn reg_A(Buswires,Resetn,A_in,Clock,_A);
regn reg_G(ALU_out, Resetn, G_in, Clock,_G);

assign ALU_out = (AddSub==1'b0)? _A+Buswires:_A-Buswires;

always @(*) begin
    case (rX)
        3'b000: Sel_rX = _R0;
        3'b001: Sel_rX = _R1;
        3'b010: Sel_rX = _R2;
        3'b011: Sel_rX = _R3;
        3'b100: Sel_rX = _R4;
        3'b101: Sel_rX = _R5;
        3'b110: Sel_rX = _R6;
        3'b111: Sel_rX = _R7;
        default: Sel_rX = _R0;
    endcase
end

always @(*) begin
    case (rY)
        3'b000: Sel_rY = _R0;
        3'b001: Sel_rY = _R1;
        3'b010: Sel_rY = _R2;
        3'b011: Sel_rY = _R3;
        3'b100: Sel_rY = _R4;
        3'b101: Sel_rY = _R5;
        3'b110: Sel_rY = _R6;
        3'b111: Sel_rY = _R7;
        default: Sel_rY = _R0;
    endcase
end


always@(*) begin 
case(Select)
_R0: Buswires=r0;
_R1: Buswires =r1;
_R2: Buswires=r2;
_R3: Buswires=r3;
_R4: Buswires=r4;
_R5: Buswires=r5;
_R6: Buswires=r6;
_R7: Buswires=r7;
_GSEL : Buswires= _G;
_IR8_IR8_0:Buswires={{7{IR[8]}},IR[8:0]};
_IR7_0_0: Buswires= {IR[7:0],8'b00000000};
default: Buswires = 16'b0;
endcase
end 
endmodule

