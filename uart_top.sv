module uart_top(
    input logic clk,
    input logic reset,
    input logic rx_en,
    input logic [7:0] input_data,
    input logic tx_en,
    output logic rx_busy,
    output logic tx_busy,
    output logic rx_done,
    output logic [7:0] output_data 
);
    logic rx_tick, tx_tick;   //wire for baude rate connection
    logic serial_in; //wire for interconnection

    baud_gen baude (.clk(clk), .reset(reset), .rx_tick(rx_tick), .tx_tick(tx_tick));
    uart_tx TX (.rst(reset), .clk(clk), .tx_tick(tx_tick), .Data_in(input_data), .tx_en(tx_en), .tx_busy(tx_busy), .out_tx(serial_in));
    uart_rx RX (.serial_in(serial_in), .clk(clk), .rx_tick(rx_tick), .rx_en(rx_en), .rst(reset), .rx_busy(rx_busy), .data_out(output_data), .rx_done(rx_done));


endmodule

