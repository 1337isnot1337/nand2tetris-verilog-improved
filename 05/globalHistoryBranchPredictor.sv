/* verilator lint_off DECLFILENAME */

module globalHistoryRegister #(
    parameter N = 8
)(
    input              clk,
    input              reset,
    input              addToReg,
    input              result,
    output [N-1:0]     ghr_out
);

    reg [N-1:0] ghrReg;
    assign ghr_out = ghrReg;

    always @(posedge clk) begin
        if (reset) begin
            ghrReg <= {N{1'b0}};
        end else if (addToReg) begin
            ghrReg <= {result, ghrReg[N-1:1]};
        end
    end
endmodule


module patternHistoryTable #(
    parameter N = 8
)(
    input              clk,
    input              reset,
    input      [N-1:0] readAddr,
    input      [N-1:0] updateAddr,
    input              updateTaken,
    input              updateEnable,
    output     [1:0]   counterOut,
    output             prediction
);

    wire [2:0] readIndex   = readAddr[2:0];
    wire [2:0] updateIndex = updateAddr[2:0];

    reg [1:0] p0;
    reg [1:0] p1;
    reg [1:0] p2;
    reg [1:0] p3;
    reg [1:0] p4;
    reg [1:0] p5;
    reg [1:0] p6;
    reg [1:0] p7;

    always @(posedge clk) begin
        if (reset) begin
            p0 <= 2'b01; p1 <= 2'b01; p2 <= 2'b01; p3 <= 2'b01;
            p4 <= 2'b01; p5 <= 2'b01; p6 <= 2'b01; p7 <= 2'b01;
        end else if (updateEnable) begin
            case (updateIndex)
                3'b000: begin
                    if (updateTaken) begin if (p0 != 2'b11) p0 <= p0 + 2'b01; end
                    else            begin if (p0 != 2'b00) p0 <= p0 - 2'b01; end
                end
                3'b001: begin
                    if (updateTaken) begin if (p1 != 2'b11) p1 <= p1 + 2'b01; end
                    else            begin if (p1 != 2'b00) p1 <= p1 - 2'b01; end
                end
                3'b010: begin
                    if (updateTaken) begin if (p2 != 2'b11) p2 <= p2 + 2'b01; end
                    else            begin if (p2 != 2'b00) p2 <= p2 - 2'b01; end
                end
                3'b011: begin
                    if (updateTaken) begin if (p3 != 2'b11) p3 <= p3 + 2'b01; end
                    else            begin if (p3 != 2'b00) p3 <= p3 - 2'b01; end
                end
                3'b100: begin
                    if (updateTaken) begin if (p4 != 2'b11) p4 <= p4 + 2'b01; end
                    else            begin if (p4 != 2'b00) p4 <= p4 - 2'b01; end
                end
                3'b101: begin
                    if (updateTaken) begin if (p5 != 2'b11) p5 <= p5 + 2'b01; end
                    else            begin if (p5 != 2'b00) p5 <= p5 - 2'b01; end
                end
                3'b110: begin
                    if (updateTaken) begin if (p6 != 2'b11) p6 <= p6 + 2'b01; end
                    else            begin if (p6 != 2'b00) p6 <= p6 - 2'b01; end
                end
                3'b111: begin
                    if (updateTaken) begin if (p7 != 2'b11) p7 <= p7 + 2'b01; end
                    else            begin if (p7 != 2'b00) p7 <= p7 - 2'b01; end
                end
                default: begin end
            endcase
        end
    end

    reg [1:0] readCounter;
    always @(*) begin
        case (readIndex)
            3'b000: readCounter = p0;
            3'b001: readCounter = p1;
            3'b010: readCounter = p2;
            3'b011: readCounter = p3;
            3'b100: readCounter = p4;
            3'b101: readCounter = p5;
            3'b110: readCounter = p6;
            3'b111: readCounter = p7;
            default: readCounter = 2'b01;
        endcase
    end

    assign counterOut  = readCounter;
    assign prediction  = readCounter[1];

endmodule


module branchTargetBuffer #(
    parameter M         = 8,
    parameter AddrWidth = 15
)(
    input                      clk,
    input                      reset,
    input      [AddrWidth-1:0] pc,
    input      [AddrWidth-1:0] updatePc,
    input      [AddrWidth-1:0] updateTarget,
    input                      updateEnable,
    input                      readEnable,
    output     [AddrWidth-1:0] predTarget,
    output                     hit
);

    wire [2:0] readIndex   = pc[2:0];
    wire [2:0] updateIndex = updatePc[2:0];

    reg                 v0, v1, v2, v3, v4, v5, v6, v7;
    reg [AddrWidth-1:0] t0, t1, t2, t3, t4, t5, t6, t7;
    reg [AddrWidth-1:0] g0, g1, g2, g3, g4, g5, g6, g7;

    always @(posedge clk) begin
        if (reset) begin
            v0 <= 1'b0; v1 <= 1'b0; v2 <= 1'b0; v3 <= 1'b0;
            v4 <= 1'b0; v5 <= 1'b0; v6 <= 1'b0; v7 <= 1'b0;
        end else if (updateEnable) begin
            case (updateIndex)
                3'b000: begin t0 <= updateTarget; g0 <= updatePc; v0 <= 1'b1; end
                3'b001: begin t1 <= updateTarget; g1 <= updatePc; v1 <= 1'b1; end
                3'b010: begin t2 <= updateTarget; g2 <= updatePc; v2 <= 1'b1; end
                3'b011: begin t3 <= updateTarget; g3 <= updatePc; v3 <= 1'b1; end
                3'b100: begin t4 <= updateTarget; g4 <= updatePc; v4 <= 1'b1; end
                3'b101: begin t5 <= updateTarget; g5 <= updatePc; v5 <= 1'b1; end
                3'b110: begin t6 <= updateTarget; g6 <= updatePc; v6 <= 1'b1; end
                3'b111: begin t7 <= updateTarget; g7 <= updatePc; v7 <= 1'b1; end
                default: begin end
            endcase
        end
    end

    reg                 selValid;
    reg [AddrWidth-1:0] selTarget;
    reg [AddrWidth-1:0] selTag;

    always @(*) begin
        case (readIndex)
            3'b000: begin selValid = v0; selTarget = t0; selTag = g0; end
            3'b001: begin selValid = v1; selTarget = t1; selTag = g1; end
            3'b010: begin selValid = v2; selTarget = t2; selTag = g2; end
            3'b011: begin selValid = v3; selTarget = t3; selTag = g3; end
            3'b100: begin selValid = v4; selTarget = t4; selTag = g4; end
            3'b101: begin selValid = v5; selTarget = t5; selTag = g5; end
            3'b110: begin selValid = v6; selTarget = t6; selTag = g6; end
            3'b111: begin selValid = v7; selTarget = t7; selTag = g7; end
            default: begin
                selValid  = 1'b0;
                selTarget = {AddrWidth{1'b0}};
                selTag    = {AddrWidth{1'b0}};
            end
        endcase
    end

    wire tagMatch = (selTag == pc);

    assign hit        = readEnable && selValid && tagMatch;
    assign predTarget = hit ? selTarget : {AddrWidth{1'b0}};

endmodule


module globalHistoryBranchPredictor #(
    parameter N         = 8,
    parameter M         = 8,
    parameter AddrWidth = 15
)(
    input                      clk,
    input                      reset,

    input      [AddrWidth-1:0] pc,
    input                      fetchValid,
    output                     predTaken,
    output     [AddrWidth-1:0] predTarget,
    output                     btbHit,

    input                      updateValid,
    input      [AddrWidth-1:0] updatePc,
    input      [AddrWidth-1:0] updateTarget,
    input                      updateTaken,
    output     [N-1:0]         currentGhr
);

    wire [N-1:0] ghrValue;

    globalHistoryRegister #(
        .N(N)
    ) ghr_u (
        .clk     (clk),
        .reset   (reset),
        .addToReg(updateValid),
        .result  (updateTaken),
        .ghr_out (ghrValue)
    );

    assign currentGhr = ghrValue;

    wire [1:0] phtCounter;
    wire       phtPrediction;

    patternHistoryTable #(
        .N(N)
    ) pht (
        .clk         (clk),
        .reset       (reset),
        .readAddr    (ghrValue),
        .updateAddr  (ghrValue),
        .updateTaken (updateTaken),
        .updateEnable(updateValid),
        .counterOut  (phtCounter),
        .prediction  (phtPrediction)
    );

    wire [AddrWidth-1:0] btbTarget;
    wire                 btbHitInt;

    branchTargetBuffer #(
        .M        (M),
        .AddrWidth(AddrWidth)
    ) btb (
        .clk         (clk),
        .reset       (reset),
        .pc          (pc),
        .updatePc    (updatePc),
        .updateTarget(updateTarget),
        .updateEnable(updateValid && updateTaken), // only taken branches in BTB
        .readEnable  (fetchValid),
        .predTarget  (btbTarget),
        .hit         (btbHitInt)
    );

    assign predTaken  = phtPrediction;
    assign predTarget = btbTarget;
    assign btbHit     = btbHitInt;

endmodule

/* verilator lint_on DECLFILENAME */
