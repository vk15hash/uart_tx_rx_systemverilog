module baud_gen #(
    parameter Sysyem_freq = 50_000_000,
    parameter baude_rt = 9600
)
    (
    input logic clk,
    input logic reset,
    output logic rx_tick = 1'b0,
    output logic tx_tick = 1'b0
);
    localparam Fullperiod = Sysyem_freq/ baude_rt;
    localparam RXperiod = Fullperiod/16;
    logic [15:0] count;
    logic [15:0] count_;
    always_ff @(posedge clk or posedge reset) begin
        rx_tick <= 1'b0;
        tx_tick <= 1'b0;
        if (reset) begin
           // clk <= 1'b0;
            count <= 16'd0;
            count_ <= 16'd0;
            rx_tick <= 1'b0;
            tx_tick <= 1'b0;
        end
        else begin
            if (count == Fullperiod - 1) begin
                count <= 16'd0;
                tx_tick <= 1'b1;
            end
            else count <= count+1;
            if (count_ == RXperiod - 1) begin
                count_ <= 16'd0;
                rx_tick <= 1'b1;
            end
            else count_ <= count_ + 1;
        end

    end


endmodule