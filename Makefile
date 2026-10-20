# Simple 16-bit processor - simulation with Icarus Verilog

RTL = rtl/proc.v rtl/regn.v rtl/dec3to8.v
TB  = tb/proc_testbench.v
SIM = sim.out
VCD = proc_testbench.vcd

.PHONY: all sim test wave clean

all: sim

# compile and run the testbench
sim: $(SIM)
	vvp $(SIM)

$(SIM): $(RTL) $(TB)
	iverilog -g2005 -o $(SIM) $(RTL) $(TB)

# same as sim, but fails if any check fails (used by CI)
test: $(SIM)
	vvp $(SIM) | tee sim.log
	grep -q "ALL TESTS PASSED" sim.log

# open the waveforms in GTKWave
wave: sim
	gtkwave $(VCD) &

clean:
	rm -f $(SIM) $(VCD) sim.log
