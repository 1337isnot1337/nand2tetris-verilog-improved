Nand2Tetris verilog, with additions of a Global History Branch Predictor, two stage fetch/execute pipeline, and sesquiscalar operations!

I also switched to Verilator from Icarus Verilog

Files I changed that are important:
05/  cpu_optimized.sv
     globalHistoryBranchPredictor.sv
     mod_cpu_tests.sv
     normal_cpu_tb.sv
and the test.py
