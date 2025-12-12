`include "../02/alu_optimized.sv"
`include "../05/globalHistoryBranchPredictor.sv"

module cpu_optimized(
    input  [15:0] rdata,
    input  [15:0] inst,
    input         reset,
    input         clk,
    output [15:0] wdata,
    output        we,
    output [14:0] data_addr,
    output [14:0] pc
);

    // Architectural registers
    reg [14:0] a_reg;
    reg [15:0] d;

    // Pipeline registers
    reg [14:0] pc_f;

    reg [14:0] ex_pc;
    reg [15:0] ex_inst;

    reg        ex_pred_taken;
    reg        ex_btb_hit;
    reg [14:0] ex_pred_target;

    // NOP
    localparam [15:0] NOP = 16'b1000_101010_000_000;

    initial begin
        pc_f          = 15'd0;
        ex_pc         = 15'd0;
        ex_inst       = NOP;
        ex_pred_taken = 1'b0;
        ex_btb_hit    = 1'b0;
        ex_pred_target= 15'd0;

        a_reg         = 15'd0;
        d         = 16'd0;
    end

    wire fetch_is_c      = inst[15];
    wire fetch_is_branch = fetch_is_c && (inst[2] || inst[1] || inst[0]);

    // predictor queried on current fetchPC
    wire        pred_taken_f;
    wire [14:0] pred_target_f;
    wire        btb_hit_f;
    wire [7:0]  current_ghr;

    // only use predicted target if it's a branch and BTB hits
    wire fetch_use_taken = fetch_is_branch && pred_taken_f && btb_hit_f;

    wire [14:0] pc_f_plus1 = pc_f + 15'd1;
    wire [14:0] pc_pred_next = fetch_use_taken ? pred_target_f : pc_f_plus1;

    wire ex_is_c = ex_inst[15];


    wire ex_sesqui_plus  = ex_is_c && (ex_inst[14:13] == 2'b01);
    wire ex_sesqui_minus = ex_is_c && (ex_inst[14:13] == 2'b10);
    wire ex_is_sesqui    = ex_sesqui_plus || ex_sesqui_minus;

    wire ex_sel_m = ex_is_c && ex_inst[12];

    wire ex_zx = ex_inst[11];
    wire ex_nx = ex_inst[10];
    wire ex_zy = ex_inst[9];
    wire ex_ny = ex_inst[8];
    wire ex_f  = ex_inst[7];
    wire ex_no = ex_inst[6];

    wire ex_dest_a = ex_is_c && ex_inst[5];
    wire ex_dest_d = ex_is_c && ex_inst[4];
    wire ex_dest_m = ex_is_c && ex_inst[3];

    wire ex_j1 = ex_inst[2];
    wire ex_j2 = ex_inst[1];
    wire ex_j3 = ex_inst[0];

    wire ex_is_branch = ex_is_c && (ex_j1 || ex_j2 || ex_j3);

    // ALU inputs
    wire [15:0] ex_am = ex_sel_m ? rdata : {1'b0, a_reg};

    wire [15:0] alu_out;
    wire        zr;
    wire        ng;

    alu_optimized alu0(
        .x (d),
        .y (ex_am),
        .zx(ex_zx),
        .nx(ex_nx),
        .zy(ex_zy),
        .ny(ex_ny),
        .f (ex_f),
        .no(ex_no),
        .out(alu_out),
        .zr (zr),
        .ng (ng)
    );

    // D updatE
    wire [15:0] d_inc = d + 16'd1;
    wire [15:0] d_dec = d - 16'd1;

    wire [15:0] d_next =
        ex_sesqui_plus  ? d_inc :
        ex_sesqui_minus ? d_dec :
                          alu_out;

    wire load_a = (!ex_is_c) || ex_dest_a;
    wire load_d = ex_dest_d || ex_is_sesqui;

    wire [14:0] next_a =
        !ex_is_c ? ex_inst[14:0] : alu_out[14:0];

    // Jump decision uses current ALU flags
    wire lt = ng;
    wire eq = zr;
    wire gt = (!ng && !zr);

    wire ex_do_jump = ex_is_c && (
                        (ex_j1 && lt) ||
                        (ex_j2 && eq) ||
                        (ex_j3 && gt)
                      );

    // Actual next PC for instruction in EX
    wire [14:0] ex_actual_next_pc = ex_do_jump ? a_reg : (ex_pc + 15'd1);

    // predicted for THIS ex instruction
    wire [14:0] ex_pred_next_pc =
        (ex_pred_taken && ex_btb_hit) ? ex_pred_target : (ex_pc + 15'd1);

    wire ex_mispredict = ex_is_branch && (ex_actual_next_pc != ex_pred_next_pc);

    // Branch predictor
    globalHistoryBranchPredictor #(
        .N        (8),
        .M        (8),
        .AddrWidth(15)
    ) ghbp (
        .clk          (clk),
        .reset        (reset),

        .pc           (pc_f),
        .fetchValid   (1'b1),

        .predTaken    (pred_taken_f),
        .predTarget   (pred_target_f),
        .btbHit       (btb_hit_f),

        .updateValid  (ex_is_branch),
        .updatePc     (ex_pc),
        .updateTarget (a_reg),
        .updateTaken  (ex_do_jump),

        .currentGhr   (current_ghr)
    );

    // commit, pipeline advance, redirect

    always @(posedge clk) begin
        if (reset) begin
            pc_f          <= 15'd0;

            // flush pipeline on reset
            ex_pc         <= 15'd0;
            ex_inst       <= NOP;
            ex_pred_taken <= 1'b0;
            ex_btb_hit    <= 1'b0;
            ex_pred_target<= 15'd0;

            a_reg         <= 15'd0;
            d         <= 16'd0;
        end else begin

            if (load_d) d <= d_next;
            if (load_a) a_reg <= next_a;


            if (ex_mispredict) begin
                // Redirect fetch
                pc_f <= ex_actual_next_pc;

                // flush
                ex_inst        <= NOP;
                ex_pc          <= 15'd0;
                ex_pred_taken  <= 1'b0;
                ex_btb_hit     <= 1'b0;
                ex_pred_target <= 15'd0;
            end else begin
                // advance fetch PC using prediction
                pc_f <= pc_pred_next;

                // Advance pipeline
                ex_inst <= inst;
                ex_pc   <= pc_f;

                // Record the prediction
                ex_pred_taken  <= fetch_is_branch ? pred_taken_f  : 1'b0;
                ex_btb_hit     <= fetch_is_branch ? btb_hit_f     : 1'b0;
                ex_pred_target <= pred_target_f;
            end
        end
    end


    assign pc        = pc_f;
    assign data_addr = a_reg;

    assign we    = ex_dest_m;
    assign wdata = alu_out;

endmodule
