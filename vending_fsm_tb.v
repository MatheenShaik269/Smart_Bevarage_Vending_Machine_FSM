`timescale 1ns/1ps

module vending_fsm_tb;

reg clk=0, rst;
reg coin_5, coin_10, cancel, select_btn;
reg [1:0] select;

wire coke, pepsi, thumsup, ins, r5, r10;

// DUT
vending_fsm dut (
    .clk(clk), .rst(rst),
    .coin_5(coin_5), .coin_10(coin_10),
    .cancel(cancel), .select_btn(select_btn),
    .select(select),
    .dispense_coke(coke),
    .dispense_pepsi(pepsi),
    .dispense_thumsup(thumsup),
    .insufficient(ins),
    .return_5(r5), .return_10(r10)
);

// Clock generation
always #5 clk = ~clk;

// ================= TASKS =================
task insert_5;
begin
    @(negedge clk) coin_5 = 1;
    @(negedge clk) coin_5 = 0;
end
endtask

task insert_10;
begin
    @(negedge clk) coin_10 = 1;
    @(negedge clk) coin_10 = 0;
end
endtask

task press_select(input [1:0] item);
begin
    @(negedge clk) select = item;
    @(negedge clk) select_btn = 1;
    @(negedge clk) select_btn = 0;
end
endtask

task press_cancel;
begin
    @(negedge clk) cancel = 1;
    @(negedge clk) cancel = 0;
end
endtask

task reset_dut;
begin
    @(negedge clk)rst=1;
    @(negedge clk)rst=0;
end
endtask

// ================= TEST SEQUENCE =================
initial 
    begin
    // Init
    rst=1; coin_5=0; coin_10=0; cancel=0; select_btn=0; select=0;

    @(posedge clk);
    rst=0;

    repeat(2) @(posedge clk);

    // ============================================
    // TEST 1: Exact money Coke (₹15)
    // ============================================
    $display("\nTEST1: Coke with exact money");
    insert_10();
    insert_5();
    press_select(2'b00);

    repeat(10) @(posedge clk);
    reset_dut();

    // ============================================
    // TEST 2: Extra money Pepsi (₹20, insert 25 → return 5)
    // ============================================
    $display("\nTEST2: Pepsi with extra money");
    insert_10();
    insert_10();
    insert_5();
    press_select(2'b01);

    repeat(10) @(posedge clk);
    reset_dut();

    // ============================================
    // TEST 3: Insufficient balance
    // ============================================
    $display("\nTEST3: Insufficient balance to buy Thumsup");
    insert_10(); // only 10
    press_select(2'b10); // needs 25

    repeat(10) @(posedge clk);
    reset_dut();

    // ============================================
    // TEST 4: Cancel transaction
    // ============================================
    $display("\nTEST4: Cancel and return money");
    insert_10();
    insert_5();
    press_cancel();

    repeat(10) @(posedge clk);
    reset_dut();

    $finish;
end

// ================= MONITOR =================
always @(posedge clk) begin
    $display("time=%0t | coin_10=%b | coin_5=%b | cancel=%b | state=%b | bal=%0d | ch=%0d | sel=%b | coke=%b pepsi=%b thumsup=%b | r5=%b r10=%b | insufficient=%b",
        $time,coin_10,coin_5,cancel,
        dut.present_state,
        dut.balance,
        dut.change,
        select,
        coke, pepsi, thumsup,
        r5, r10,
        ins
    );
end

endmodule
