module PISO(
    input logic rst,
    input logic tick,
    input logic clk,
    input logic load,
    input logic [7:0]d_in,
    input logic shift,
    output logic serial_out
);
    logic [7:0]shift_reg;       //internal register to store nd shift
    assign serial_out = shift_reg[0];       //lsb as serial out of the register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) shift_reg <= 8'd0;
        else if(load && tick) shift_reg <= d_in;
        else if (shift && tick) shift_reg <= {1'b0, shift_reg[7:1]};   
    end

endmodule

module COUNTER(
    input logic clk, 
    input logic tick,
    input logic rst,
    output logic [2:0] count
);
    always_ff @(posedge clk) begin
        if (rst) count <= 3'd0;
        else if (tick)count <= count + 1;
    end
endmodule

module uart_tx (
    input logic rst,
    input logic clk,
    input logic tx_tick,
    input logic [7:0]Data_in,
    input logic tx_en,
    output logic tx_busy,  //output
    output logic out_tx    //output
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state = IDLE, next = IDLE;

    //internal declarations
    logic serial_out;
    logic cnt_rst;
    logic [2:0]count;
    logic load_en, shift_en;
    assign shift_en = (state == DATA);
    assign load_en = (state == IDLE && tx_en);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else if (tx_tick) state <= next;
    end

    always_comb begin
        out_tx = 1'b1;
        tx_busy = 1'b0;
        cnt_rst = 1'b1;
        next = state;
        unique case (state)
            IDLE: begin
                out_tx = 1'b1;
                tx_busy = 1'b0;
                if (tx_en) next = START;
                else next = IDLE;
            end 
            START: begin
                out_tx = 1'b0;
                tx_busy = 1'b1;
                next = DATA;
            end
            DATA: begin
                cnt_rst = 1'b0;
                out_tx = serial_out;
                tx_busy = 1'b1;
                if (count == 3'b111) next = STOP;
                else next = DATA;
            end
            STOP: begin
                out_tx = 1'b1;
                tx_busy = 1'b1;
                next = IDLE;
            end
            default: begin
                out_tx = 1'b1;
                tx_busy = 1'b0;
                next = IDLE;
            end
        endcase
    end

    COUNTER count_ (.clk(clk), .tick(tx_tick), .rst(cnt_rst), .count(count));
    PISO Shift(.rst(rst), .tick(tx_tick), .clk(clk), .load(load_en), .d_in(Data_in), .shift(shift_en), .serial_out(serial_out));

endmodule