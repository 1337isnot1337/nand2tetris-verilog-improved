# nand2tetris-verilog-improved

This was my Capstone Project for Elements of Computing Systems I. This is an improved Verilog implementation of the Hack CPU with an additional global history branch predictor chip, and some simple fused instructions. I did not write the base verilog files, from projects 01 to 04 and a bit of 05, they are from **jopdorp/nand2tetris-verilog**. I also made the CPU **2-stage pipelined** for the branch predictor to be able to squash right.

The ISA is mostly similar to Hack CPU specification besides that you need to watch out for the pipelining and also the fused instruction set.

---

## Files I Changed

### Project 05 CPU + branch prediction
- `05/cpu_optimized.sv`  
  Pipelined CPU. It predicts jumps/branches in fetch, verifies in execute, flushes on mispredict

- `05/globalHistoryBranchPredictor.sv`  
  This is a chip holding together 3 seperate components to make the predictor:
  - **GHR (Global History Register)** is a shift register of last N branch outcomes
  - **PHT (Pattern History Table)** is a 2 bit sat counters indexed by history
  - **BTB (Branch Target Buffer)** caches jump targets

### Testbenches
- `05/mod_cpu_tests.sv`  
  Minimal testbench for the modified CPU `cpu_optimized` that prints internal state including `mispredict`

- `05/normal_cpu_tb.sv`  
  Baseline comparison testbench for `cpu_jopdorp_optimized`, the original optimized CPU

### Test runner
- `test.py`  
  I modified the normal test runner `test.py`. Now this project uses Verilator instead of Icarus Verilog. It compiles a chosen project’s testbenches into native executables and runs them. I have only tested the modified version on project 05 since that is all I need to do.

---

## Branch predictor design

### 1. Global History Register (GHR)
- Stores the outcomes of the last N resolved branches as bits, where taken = 1, not taken = 0.
- Updates only when a branch resolves, aka `updateValid`.

### 2. Pattern History Table (PHT)
- Table of 2-bit saturating counters.
- MSB is the prediction:
  - `00` strongly not taken
  - `01` weakly not taken
  - `10` weakly taken
  - `11` strongly taken
- On reset counters start at `01`

### 3. Branch Target Buffer (BTB)
- Direct-mapped BTB with 8 entries
- Each entry stores
  - a valid bit
  - a tag to avoid false hits from index aliasing
  - the target (the `A` at branch execution time)
- BTB updates only on taken branches

### Predictor output
A fetch is allowed to redirect the PC only if:
1. the fetched instruction is a branch or jump
2. the PHT predicts taken and
3. the BTB has a tag match for that PC

---

## CPU integration details (`cpu_optimized.sv`)

This CPU is a simple 2 stage pipeline:

### Fetch stage
- Reads `inst` at `pc_f`
- Classifies whether it’s a branch/jump instruction or not
- Queries predictor for `(predTaken, predTarget)` using the fetch PC
- Chooses next PC
  - predicted target (if branch + predicted taken + BTB hit),
  - if not just the normal step forward `pc + 1`

### Execute stage
- Executes the prior cycle’s instruction (`ex_inst` at `ex_pc`)
- Computes the true branch decision (`ex_do_jump`) from ALU flags and jump bits.
- Computes the true next PC:
  - `A` if taken,
  - `ex_pc + 1` if not taken.
- Compares actual next PC vs the predicted next PC from fetch

### Mispredict recovery
On mispredict:
- redirect fetch PC to the correct next PC
- inject a **NOP** into execute to squash the wrong-path instruction

### Predictor updates
On every resolved branch/jump:
- `updatePc = ex_pc`
- `updateTarget = A`
- `updateTaken = ex_do_jump`
- `updateValid = ex_is_branch`

Because the GHR update and the PHT update are clocked together, the PHT is updated using pre-shift history

---

## Running the tests

### Dependencies
- Python 3
- `pip install -r requirements.txt`
- **Verilator** in your PATH (`verilator`)

### Run the 05 testbenches, only do these 01-04 are irrelevant
```bash
python3 test.py 05
