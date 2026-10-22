`timescale 1ns/1ps
module uart_tb;
    localparam int NUM_RANDOM = 50;

    logic        clk = 0, reset = 1, rx_en = 0, tx_en = 0;
    logic [7:0]  input_data = 8'd0;
    logic        rx_busy, tx_busy, rx_done;
    logic [7:0]  output_data;

    logic [7:0]  exp_q[$];                 // expected bytes, in the order they were sent
    logic [7:0]  want;
    logic        rx_done_q = 1'b0;
    int          errors = 0, checked = 0;

    uart_top dut (
        .clk(clk),               .reset(reset),
        .rx_en(rx_en),
        .input_data(input_data), .tx_en(tx_en),
        .rx_busy(rx_busy),       .tx_busy(tx_busy),
        .rx_done(rx_done),       .output_data(output_data)
    );

    always #5 clk = ~clk;                  // 100 MHz: use the clock your baud_gen is designed for

    // Scoreboard: on every rising edge of rx_done, compare output_data with the oldest expected byte
    always @(negedge clk) begin
        rx_done_q <= rx_done;
        if (!reset && rx_done === 1'b1 && rx_done_q === 1'b0) begin
            if (exp_q.size() == 0) begin
                errors++;  $display("FAIL: byte %h received but none expected", output_data);
            end else begin
                want = exp_q.pop_front();  checked++;
                if (output_data !== want) begin
                    errors++;  $display("FAIL: sent %h got %h", want, output_data);
                end
            end
        end
    end

    // TX samples tx_en on tx_clk (slower than clk), so hold the request until tx_busy rises
    task automatic send(input logic [7:0] b);
        int guard = 0;
        bit started = 0;
        while (tx_busy !== 1'b0) @(negedge clk);      // wait until the transmitter is idle
        @(negedge clk);
        input_data = b;  tx_en = 1;  exp_q.push_back(b);
        while (!started) begin
            @(negedge clk);
            if (tx_busy === 1'b1) started = 1;
            else begin
                guard++;
                if (guard > 1_000_000) begin
                    errors++;  $display("FAIL: TX never started for byte %h", b);  started = 1;
                end
            end
        end
        tx_en = 0;
    endtask

    initial begin
        logic [7:0] r;
        int wait_guard = 0;
        $dumpfile("dump.vcd");  $dumpvars(0, uart_tb);
        repeat (5) @(negedge clk);   reset = 0;       // release reset (active high, as in your TX)
        repeat (2) @(negedge clk);   rx_en = 1;       // enable the receiver
        send(8'h00);  send(8'hFF);  send(8'h55);  send(8'hAA);          // corner patterns
        repeat (NUM_RANDOM) begin r = $urandom;  send(r);  end          // random bytes
        while (exp_q.size() != 0 && wait_guard < 5_000_000) begin       // let the last bytes arrive
            @(negedge clk);  wait_guard++;
        end
        if (exp_q.size() != 0) begin errors++; $display("FAIL: %0d bytes never arrived", exp_q.size()); end
        if (errors == 0) $display("PASS: %0d bytes checked", checked);
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

    initial begin #100_000_000; $display("TIMEOUT"); $finish; end     // 100 ms watchdog
endmodule