`timescale 1ns/1ps

module uart_tx_tb;

    // DIVISOR = CLK_FREQ / BAUD_RATE = 1000 / 100 = 10 clock cycles per bit
    localparam CLK_FREQ  = 1000;
    localparam BAUD_RATE = 100;
    localparam CLK_PERIOD = 10; // ns, arbitrary for simulation

    reg       clk;
    reg       reset;
    reg       tx_start;
    reg [7:0] data_in;
    wire      tx;
    wire      tx_busy;

    reg [7:0] received_byte;
    integer   i;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task: send one byte and wait until done
    task send_byte(input [7:0] byte_to_send);
        begin
            @(posedge clk);
            data_in  = byte_to_send;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;
            wait (tx_busy == 1'b0);
        end
    endtask

    // Task: sample the tx line and reconstruct the byte, for self-checking
    task capture_and_check(input [7:0] expected);
        integer bit_period_cycles;
        begin
            bit_period_cycles = CLK_FREQ / BAUD_RATE;

            // Wait for start bit (tx goes low)
            wait (tx == 1'b0);

            // Move to the middle of the start bit, then step bit by bit
            #(bit_period_cycles * CLK_PERIOD * 1.5);

            for (i = 0; i < 8; i = i + 1) begin
                received_byte[i] = tx;
                #(bit_period_cycles * CLK_PERIOD);
            end

            if (received_byte === expected)
                $display("PASS: sent 8'h%0h, received 8'h%0h", expected, received_byte);
            else
                $display("FAIL: sent 8'h%0h, received 8'h%0h", expected, received_byte);
        end
    endtask

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        clk      = 0;
        reset    = 1;
        tx_start = 0;
        data_in  = 8'h00;

        #(CLK_PERIOD*2);
        reset = 0;

        // Test 1: alternating bit pattern, easy to visually verify in GTKWave
        fork
            send_byte(8'h55);
            capture_and_check(8'h55);
        join

        #(CLK_PERIOD*5);

        // Test 2: all zeros
        fork
            send_byte(8'h00);
            capture_and_check(8'h00);
        join

        #(CLK_PERIOD*5);

        // Test 3: all ones
        fork
            send_byte(8'hFF);
            capture_and_check(8'hFF);
        join

        #(CLK_PERIOD*5);

        // Test 4: a random byte
        fork
            send_byte(8'hA3);
            capture_and_check(8'hA3);
        join

        #(CLK_PERIOD*5);

        $display("All tests completed.");
        $finish;
    end

endmodule