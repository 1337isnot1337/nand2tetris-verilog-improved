`timescale 1ns/1ps

module normal_cpu_tb;

    reg  [15:0] inM;
    reg  [15:0] instruction;
    reg         reset;
    reg         clock;

    wire [15:0] outM;
    wire        writeM;
    wire [14:0] addressM;
    wire [14:0] pc;

    cpu_jopdorp_optimized dut (
        .inM        (inM),
        .instruction(instruction),
        .reset      (reset),
        .clock      (clock),
        .outM       (outM),
        .writeM     (writeM),
        .addressM   (addressM),
        .pc         (pc)
    );

    reg [15:0] imem [0:31];

    always #5 clock = ~clock;

    always @(*) begin
        instruction = imem[pc];
    end

    always @(*) begin
        inM = 16'h2222;
    end

    initial begin
        clock = 0;
        reset = 1;

        imem[0]  = 16'd10;
        imem[1]  = 16'b1110_110000_010_000;
        imem[2]  = 16'd20;
        imem[3]  = 16'b1110_000010_010_000;
        imem[4]  = 16'd5;
        imem[5]  = 16'b1110_010011_010_000;
        imem[6]  = 16'b1110_001100_000_001;
        imem[7]  = 16'b1110_101010_000_000;
        imem[8]  = 16'd1;
        imem[9]  = 16'b1110_001110_010_000;
        imem[10] = 16'b1110_001100_000_010;
        imem[11] = 16'b1110_001110_010_000;
        imem[12] = 16'd15;
        imem[13] = 16'b1110_101010_000_111;
        imem[14] = 16'd0;
        imem[15] = 16'd99;
        imem[16] = 16'b1110_110000_010_000;
        imem[17] = 16'b1110_110000_001_000;
        imem[18] = 16'b1110_101010_000_000;
        imem[19] = 16'b1110_101010_000_000;

        #12;
        reset = 0;

        repeat (40) begin
            @(posedge clock);
            $display(
                "t=%0t pc=%0d instr=%h A=%0d D=%0d writeM=%b addrM=%0d outM=%h",
                $time, pc, instruction, dut.a, dut.d,
                writeM, addressM, outM
            );
        end

        $finish;
    end

endmodule
