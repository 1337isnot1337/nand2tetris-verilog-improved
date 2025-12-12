`timescale 1ns/1ps

module mod_cpu_tests;

    reg  [15:0] rdata;
    reg  [15:0] inst;
    reg         reset;
    reg         clk;

    wire [15:0] wdata;
    wire        we;
    wire [14:0] data_addr;
    wire [14:0] pc;

    cpu_optimized dut (
        .rdata     (rdata),
        .inst      (inst),
        .reset     (reset),
        .clk       (clk),
        .wdata     (wdata),
        .we        (we),
        .data_addr (data_addr),
        .pc        (pc)
    );

    reg [15:0] imem [0:31];

    always #5 clk = ~clk;

    always @(*) begin
        inst = imem[pc];
    end

    always @(*) begin
        rdata = 16'h1234;
    end

    initial begin
        clk   = 0;
        reset = 1;

        imem[0]  = 16'd10;
        imem[1]  = 16'b1110_110000_010_000;
        imem[2]  = 16'd20;
        imem[3]  = 16'b1110_000010_010_000;
        imem[4]  = 16'd5;
        imem[5]  = 16'b1110_010011_010_000;
        imem[6]  = 16'b1110_001100_000_001;
        imem[7]  = 16'b1000_101010_000_000;
        imem[8]  = 16'd1;
        imem[9]  = 16'b11110_00000_010_000;
        imem[10] = 16'b1110_001100_000_010;
        imem[11] = 16'd15;
        imem[12] = 16'b1110_001100_000_111;
        imem[13] = 16'd0;
        imem[14] = 16'd0;
        imem[15] = 16'd0;
        imem[16] = 16'd99;
        imem[17] = 16'b1110_110000_010_000;
        imem[18] = 16'b1110_110000_001_000;
        imem[19] = 16'b1000_101010_000_000;
        imem[20] = 16'b1000_101010_000_000;

        #12;
        reset = 0;

        repeat (40) begin
            @(posedge clk);
            $display(
                "t=%0t pc=%0d inst=%h A=%0d D=%0d we=%b wdata=%h mispredict=%b",
                $time, pc, inst, dut.a_reg, dut.d, we, wdata, dut.ex_mispredict
            );
        end

        $finish;
    end

endmodule
