`timescale 1ns/1ps

module vending_fsm (
    input clk,
    input rst,
    input coin_5,
    input coin_10,
    input cancel,
    input select_btn,
    input [1:0] select,

    output reg dispense_coke,
    output reg dispense_pepsi,
    output reg dispense_thumsup,
    output reg insufficient,
    output reg return_5,
    output reg return_10
);

    // ================= STATES =================
    parameter IDLE    = 2'b00;
    parameter COLLECT = 2'b01;
    parameter DISPENSE= 2'b10;
    parameter RETURN  = 2'b11;

    reg [1:0] present_state, next_state;

    // ================= REGISTERS =================
    reg [5:0] balance, next_balance;
    reg [5:0] change, next_change;

    // ================= EDGE DETECTION =================
    reg coin_5_d, coin_10_d, cancel_d, select_btn_d;

    wire coin_5_edge, coin_10_edge, cancel_edge, select_edge;

    always @(posedge clk) begin
        coin_5_d     <= coin_5;
        coin_10_d    <= coin_10;
        cancel_d     <= cancel;
        select_btn_d <= select_btn;
    end

    assign coin_5_edge  = coin_5  & ~coin_5_d;
    assign coin_10_edge = coin_10 & ~coin_10_d;
    assign cancel_edge  = cancel  & ~cancel_d;
    assign select_edge  = select_btn & ~select_btn_d;

    // ================= STATE REGISTER =================
    always @(posedge clk or posedge rst) begin
        if (rst)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    // ================= NEXT STATE LOGIC =================
    always @(*) begin
        case (present_state)

            IDLE: begin
                if (coin_5_edge || coin_10_edge)
                    next_state = COLLECT;
                else
                    next_state = IDLE;
            end

            COLLECT: begin
                if (cancel_edge)
                    next_state = RETURN;
                else if (select_edge)
                    next_state = DISPENSE;
                else
                    next_state = COLLECT;
            end

            DISPENSE: begin
                // Go to RETURN only if purchase is valid
                if (
                    (select == 2'b00 && balance >= 15) ||
                    (select == 2'b01 && balance >= 20) ||
                    (select == 2'b10 && balance >= 25)
                )
                    next_state = RETURN;
                else
                    next_state = COLLECT; // wait for more money
            end

            RETURN: begin
                if (change == 0)
                    next_state = IDLE;
                else
                    next_state = RETURN;
            end

            default: next_state = IDLE;
        endcase
    end

    // ================= DATA + OUTPUT LOGIC =================
    always @(*) begin
        // defaults
        next_balance = balance;
        next_change  = change;

        dispense_coke = 0;
        dispense_pepsi = 0;
        dispense_thumsup = 0;
        insufficient = 0;
        return_5 = 0;
        return_10 = 0;

        case (present_state)

            // -------- IDLE --------
            IDLE: begin
                if (coin_5_edge)
                    next_balance = balance + 5;
                else if (coin_10_edge)
                    next_balance = balance + 10;
            end

            // -------- COLLECT --------
            COLLECT: begin
                // Correct accumulation
                if (coin_5_edge)
                    next_balance = next_balance + 5;

                if (coin_10_edge)
                    next_balance = next_balance + 10;

                // Cancel handling
                if (cancel_edge) begin
                    next_change  = balance;
                    next_balance = 0;
                end
            end

            // -------- DISPENSE --------
            DISPENSE: begin
                case (select)

                    2'b00: begin // Coke ₹15
                        if (balance >= 15) begin
                            dispense_coke = 1;
                            next_change = balance - 15;
                            next_balance = 0;
                        end else begin
                            insufficient = 1;
                        end
                    end

                    2'b01: begin // Pepsi ₹20
                        if (balance >= 20) begin
                            dispense_pepsi = 1;
                            next_change = balance - 20;
                            next_balance = 0;
                        end else begin
                            insufficient = 1;
                        end
                    end

                    2'b10: begin // ThumsUp ₹25
                        if (balance >= 25) begin
                            dispense_thumsup = 1;
                            next_change = balance - 25;
                            next_balance = 0;
                        end else begin
                            insufficient = 1;
                        end
                    end

                    default: insufficient = 1;
                endcase
            end

            // -------- RETURN --------
            RETURN: begin
                if (change >= 10) begin
                    return_10 = 1;
                    next_change = change - 10;
                end
                else if (change >= 5) begin
                    return_5 = 1;
                    next_change = change - 5;
                end
            end

        endcase
    end

    // ================= REGISTER UPDATE =================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            balance <= 0;
            change  <= 0;
        end else begin
            balance <= next_balance;
            change  <= next_change;
        end
    end

endmodule