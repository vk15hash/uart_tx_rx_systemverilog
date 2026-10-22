module bit4_counter(
    input logic clk,
    input logic tick,
    input logic rst,
    output logic [3:0]count
);
    always_ff @(posedge clk) begin
        if (tick) begin
            if(rst) count <= 4'b0000;
            else count <= count + 1'b1;
        end
    end
endmodule


module SIPO (
    input logic clk,
    input logic tick,
    input logic rst,
    input logic d_in,
    input logic out_en,
    input logic shift_en,
    output logic [7:0]Data
);
    logic [7:0]shift_reg; 
    always_ff @(posedge clk) begin
        if (rst) shift_reg <= 8'd0;
        else if (shift_en && tick) begin
            shift_reg <= {d_in, shift_reg[7:1]};
        end
        else if (out_en && tick) begin
            Data <= shift_reg;
        end
    end
endmodule

module uart_rx (
    input logic serial_in,
    input logic clk,
    input logic rx_tick,
    input logic rx_en,
    input logic rst,
    output logic rx_busy,
    output logic [7:0]data_out,
    output logic rx_done
);
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_r;
    state_r state, next;

    logic in_rx;        //to be stored serially in reg
    logic [3:0]count_7 = 4'd7;   //counter limit for tick 
    logic [3:0]count_16 = 4'd15; //counter limit for tick
    logic cnt_rst;      //counter reset
    logic [3:0]tick_count;   //tick count indicator
    logic [3:0]bit_count = 4'd0;     //bit count indicator
    logic shift_en, out_en, reg_rst;

    assign  shift_en = (state == DATA && tick_count == count_7);
    assign  out_en = (state == STOP && tick_count > count_7);
    assign  reg_rst = (state == START);


    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else if (rx_tick) begin 
            state <= next;
            if (state == DATA && tick_count == count_16)
            bit_count <= bit_count + 1'b1;
            else if (state != DATA)
            bit_count <= 4'd0;
        end
    end


    always_comb begin
        in_rx = 1'b0;       //initialised to be zero
        rx_busy = 1'b0;     
        next = state;
        rx_done = 1'b0;
        cnt_rst = 1'b1;
        unique case (state)
            IDLE: begin
                rx_busy = 1'b0;
                cnt_rst = 1'b1;
                rx_done = 1'b0;
                
                if(rx_en && !serial_in) next = START;
                else next = IDLE;
            end
            START: begin
                rx_busy = 1'b1;
                cnt_rst = 1'b0;
                rx_done = 1'b0;
                if (tick_count == count_7) in_rx = serial_in; 
                else if (tick_count == count_16) begin next = DATA; cnt_rst = 1'b1; end
                else next = START;
            end
            DATA: begin
                rx_busy = 1'b1;
                rx_done = 1'b0;
                cnt_rst = 1'b0;
                if (tick_count == count_7) in_rx = serial_in;
                else if (tick_count == count_16)begin
                    cnt_rst = 1'b1;
                    if (bit_count == 4'b0111) next = STOP;
                    else next = DATA; 
                end
                else next = DATA;
            end
            STOP: begin
                rx_busy = 1'b1;
                cnt_rst = 1'b0;
                if (tick_count == count_7) in_rx = serial_in;
                else if (tick_count == count_16) begin next = IDLE; cnt_rst = 1'b1; rx_done = 1'b1; end
                else next = STOP;   
            end
            default: begin
                rx_busy = 1'b0;
                cnt_rst = 1'b1;
                next = IDLE;
            end
        endcase
    end

    bit4_counter counter (.clk(clk), .tick(rx_tick), .rst(cnt_rst), .count(tick_count));
    SIPO shift_register (.clk(clk), .tick(rx_tick), .rst(reg_rst), .d_in(in_rx), .out_en(out_en), .shift_en(shift_en), .Data(data_out));

endmodule