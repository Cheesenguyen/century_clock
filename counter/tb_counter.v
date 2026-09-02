// ============================================================================
// TESTBENCH CHI TIET CHO THU MUC counter
// Top-level: counter_controller
// Sub-modules: sec_counter, min_counter, hour_counter, day_counter,
//              month_counter, year_counter, leap_year_detector,
//              hundreds_thousands_bin
//
// Cac kich ban test:
//   1.  Reset toan bo counter
//   2.  Dem giay binh thuong (0->1->...->59->0)
//   3.  Carry giay -> phut (sig_1min)
//   4.  Carry phut -> gio (sig_1h)
//   5.  Carry gio -> ngay (sig_1d)
//   6.  Carry ngay -> thang (sig_1m) - thang 31 ngay
//   7.  Carry thang -> nam (sig_1y)
//   8.  BCD output chinh xac (sec/min/hr/day/mon/yr)
//   9.  Edit mode: chinh giay UP
//  10.  Edit mode: chinh giay DOWN (vong 0->59)
//  11.  Edit mode: chinh phut UP/DOWN
//  12.  Edit mode: chinh gio UP (vong 23->0)
//  13.  Edit mode: chinh gio DOWN (vong 0->23)
//  14.  Edit mode: chinh ngay UP
//  15.  Edit mode: chinh ngay DOWN (vong 1->max_day va giam binh thuong)
//  16.  Edit mode: chinh thang UP (vong 12->1)
//  17.  Edit mode: chinh thang DOWN (vong 1->12)
//  18.  Edit mode: chinh nam UP/DOWN
//  19.  Dong ho dung khi edit_enable = 1
//  20.  So ngay trong thang: thang 1 (31 ngay)
//  21.  So ngay trong thang: thang 4 (30 ngay)
//  22.  So ngay trong thang: thang 2 khong nhuan (28 ngay)
//  23.  So ngay trong thang: thang 2 nam nhuan (29 ngay)
//  24.  Nam nhuan: 2024 (chia 4, ko chia 100)
//  25.  Nam khong nhuan: 1900 (chia 100, ko chia 400)
//  26.  Nam nhuan: 2000 (chia 400)
//  27.  Nam khong nhuan: 2023 (ko chia 4)
//  28.  Year BCD Double Dabble: kiem tra nhieu gia tri
//  29.  Dem lien tuc qua nhieu ngay
//  30.  Carry ngay cuoi thang 2 nhuan -> thang 3
//  31.  Nam vong tron: 9999 -> 1 va 1 -> 9999
//  32.  Edit khong anh huong truong khac (cross-field isolation)
//  33.  Thang 2 -> thang 3 tu dong (dong ho chay binh thuong)
//  34.  So ngay trong tat ca 12 thang
// ============================================================================

`timescale 1ns / 1ps

module tb_counter_controller;

    // ========================================================================
    // KHAI BAO TIN HIEU
    // ========================================================================

    reg         clk_50MHz;
    reg         rst_n;
    reg         tick_1hz;
    reg         edit_enable;
    reg         mode;           // 0: TIME group (sec/min/hr), 1: DATE group (day/mon/yr)
    reg  [1:0]  edit_select;    // 01: field1, 10: field2, 11: field3
    reg         up, down;

    // Dau ra BCD
    wire [3:0] sec_ones, sec_tens;
    wire [3:0] min_ones, min_tens;
    wire [3:0] hr_ones,  hr_tens;
    wire [3:0] day_ones, day_tens;
    wire [3:0] mon_ones, mon_tens;
    wire [3:0] yr_ones,  yr_tens, yr_hundreds, yr_thousands;

    // Bien dem ket qua
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    // ========================================================================
    // KHOI TAO DUT
    // ========================================================================

    counter_controller uut (
        .clk_50MHz  (clk_50MHz),
        .rst_n      (rst_n),
        .tick_1hz   (tick_1hz),
        .edit_enable(edit_enable),
        .mode       (mode),
        .edit_select(edit_select),
        .up         (up),
        .down       (down),
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands)
    );

    // ========================================================================
    // TAO CLOCK 50MHz (chu ky 20ns)
    // ========================================================================
    initial clk_50MHz = 0;
    always #10 clk_50MHz = ~clk_50MHz;

    // ========================================================================
    // HAM VA TASK HO TRO
    // ========================================================================

    // Lay gia tri so tu BCD (2 digit)
    function [7:0] bcd_val;
        input [3:0] t, o;
        begin
            bcd_val = t * 10 + o;
        end
    endfunction

    // Lay gia tri nam tu 4 BCD digit
    function [15:0] year_val;
        input [3:0] th, hu, te, on;
        begin
            year_val = th * 1000 + hu * 100 + te * 10 + on;
        end
    endfunction

    // Kiem tra gia tri (16-bit)
    task check;
        input [15:0] actual;
        input [15:0] expected;
        input [8*60-1:0] desc;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("  [PASS] Test %0d: %0s = %0d", test_num, desc, actual);
            end
            else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] Test %0d: %0s = %0d, mong doi %0d", test_num, desc, actual, expected);
            end
        end
    endtask

    // Tao 1 xung tick_1hz (dem binh thuong)
    task pulse_tick;
        begin
            @(posedge clk_50MHz);
            tick_1hz = 1'b1;
            @(posedge clk_50MHz);
            tick_1hz = 1'b0;
            #20;
        end
    endtask

    // Tao N xung tick_1hz
    task pulse_tick_n;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                pulse_tick;
            end
        end
    endtask

    // Tao 1 xung UP trong edit mode
    task edit_up;
        begin
            @(posedge clk_50MHz);
            up = 1'b1;
            @(posedge clk_50MHz);
            up = 1'b0;
            #40;
        end
    endtask

    // Tao 1 xung DOWN trong edit mode
    task edit_down;
        begin
            @(posedge clk_50MHz);
            down = 1'b1;
            @(posedge clk_50MHz);
            down = 1'b0;
            #40;
        end
    endtask

    // Tao N xung UP
    task edit_up_n;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                edit_up;
            end
        end
    endtask

    // Tao N xung DOWN
    task edit_down_n;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                edit_down;
            end
        end
    endtask

    // Bat edit mode cho 1 truong cu the
    // m: 0=TIME, 1=DATE
    // sel: 01=sec/day, 10=min/mon, 11=hr/yr
    task set_edit;
        input m;
        input [1:0] sel;
        begin
            edit_enable = 1'b1;
            mode = m;
            edit_select = sel;
            #40;
        end
    endtask

    // Tat edit mode
    task clear_edit;
        begin
            edit_enable = 1'b0;
            mode = 1'b0;
            edit_select = 2'b00;
            up = 1'b0;
            down = 1'b0;
            #40;
        end
    endtask

    // Reset he thong
    task do_reset;
        begin
            rst_n       = 1'b0;
            tick_1hz    = 1'b0;
            edit_enable = 1'b0;
            mode        = 1'b0;
            edit_select = 2'b00;
            up          = 1'b0;
            down        = 1'b0;
            #200;
            rst_n = 1'b1;
            #100;
        end
    endtask

    // ========================================================================
    // KICH BAN TEST CHINH
    // ========================================================================
    initial begin
        $display("");
        $display("================================================================");
        $display("  TESTBENCH THU MUC century_clock-main");
        $display("  counter_controller (sec/min/hr/day/mon/yr + leap_year)");
        $display("================================================================");
        $display("");

        // ==============================================================
        // TEST 1: RESET TOAN BO
        // ==============================================================
        $display("--- TEST 1: Reset toan bo counter ---");
        do_reset;

        check(bcd_val(sec_tens, sec_ones), 0,  "Giay sau reset");
        check(bcd_val(min_tens, min_ones), 0,  "Phut sau reset");
        check(bcd_val(hr_tens, hr_ones),   0,  "Gio sau reset");
        check(bcd_val(day_tens, day_ones), 1,  "Ngay sau reset");
        check(bcd_val(mon_tens, mon_ones), 1,  "Thang sau reset");
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2026, "Nam sau reset");
        $display("");

        // ==============================================================
        // TEST 2: DEM GIAY BINH THUONG
        // ==============================================================
        $display("--- TEST 2: Dem giay binh thuong ---");
        do_reset;

        pulse_tick_n(1);
        check(bcd_val(sec_tens, sec_ones), 1, "1 tick: giay=1");
        pulse_tick_n(4);
        check(bcd_val(sec_tens, sec_ones), 5, "5 tick: giay=5");
        pulse_tick_n(5);
        check(bcd_val(sec_tens, sec_ones), 10, "10 tick: giay=10");
        pulse_tick_n(15);
        check(bcd_val(sec_tens, sec_ones), 25, "25 tick: giay=25");
        pulse_tick_n(20);
        check(bcd_val(sec_tens, sec_ones), 45, "45 tick: giay=45");
        pulse_tick_n(14);
        check(bcd_val(sec_tens, sec_ones), 59, "59 tick: giay=59");
        $display("");

        // ==============================================================
        // TEST 3: CARRY GIAY -> PHUT
        // ==============================================================
        $display("--- TEST 3: Carry giay -> phut ---");
        do_reset;

        pulse_tick_n(60);
        check(bcd_val(sec_tens, sec_ones), 0, "60 tick: giay=0 (tran)");
        check(bcd_val(min_tens, min_ones), 1, "60 tick: phut=1");

        pulse_tick_n(60);
        check(bcd_val(sec_tens, sec_ones), 0, "120 tick: giay=0");
        check(bcd_val(min_tens, min_ones), 2, "120 tick: phut=2");

        pulse_tick_n(180);  // tong 360 tick = 6 phut
        check(bcd_val(min_tens, min_ones), 6, "360 tick: phut=6");
        $display("");

        // ==============================================================
        // TEST 4: CARRY PHUT -> GIO
        // ==============================================================
        $display("--- TEST 4: Carry phut -> gio ---");
        do_reset;

        pulse_tick_n(3600);  // 60*60 = 1 gio
        check(bcd_val(sec_tens, sec_ones), 0, "3600 tick: giay=0");
        check(bcd_val(min_tens, min_ones), 0, "3600 tick: phut=0");
        check(bcd_val(hr_tens, hr_ones),   1, "3600 tick: gio=1");

        pulse_tick_n(3600);  // 2 gio
        check(bcd_val(hr_tens, hr_ones), 2, "7200 tick: gio=2");
        $display("");

        // ==============================================================
        // TEST 5: CARRY GIO -> NGAY
        // ==============================================================
        $display("--- TEST 5: Carry gio -> ngay ---");
        do_reset;

        pulse_tick_n(86400);  // 24*3600 = 1 ngay
        check(bcd_val(hr_tens, hr_ones),   0, "86400 tick: gio=0");
        check(bcd_val(day_tens, day_ones), 2, "86400 tick: ngay=2 (tu 1)");
        $display("");

        // ==============================================================
        // TEST 6: CARRY NGAY -> THANG (thang 1 = 31 ngay)
        // ==============================================================
        $display("--- TEST 6: Carry ngay -> thang (thang 1, 31 ngay) ---");
        do_reset;

        // Dat ngay = 31 bang edit
        set_edit(1'b1, 2'b01);  // DATE mode, field1 = DAY
        edit_up_n(30);           // ngay 1 -> 31
        clear_edit;
        check(bcd_val(day_tens, day_ones), 31, "Edit ngay len 31");

        // 1 ngay nua -> ngay tran, thang tang
        pulse_tick_n(86400);
        check(bcd_val(day_tens, day_ones), 1, "Ngay tran: ngay=1");
        check(bcd_val(mon_tens, mon_ones), 2, "Thang tang: thang=2");
        $display("");

        // ==============================================================
        // TEST 7: CARRY THANG -> NAM
        // ==============================================================
        $display("--- TEST 7: Carry thang -> nam ---");
        do_reset;

        // Dat thang = 12
        set_edit(1'b1, 2'b10);  // DATE mode, field2 = MONTH
        edit_up_n(11);           // thang 1 -> 12
        clear_edit;
        check(bcd_val(mon_tens, mon_ones), 12, "Edit thang len 12");

        // Dat ngay = 31
        set_edit(1'b1, 2'b01);  // DAY
        edit_up_n(30);
        clear_edit;
        check(bcd_val(day_tens, day_ones), 31, "Edit ngay len 31");

        // 1 ngay nua -> thang tran 12->1, nam tang
        pulse_tick_n(86400);
        check(bcd_val(day_tens, day_ones), 1, "Ngay=1");
        check(bcd_val(mon_tens, mon_ones), 1, "Thang tran: thang=1");
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2027, "Nam tang: 2027");
        $display("");

        // ==============================================================
        // TEST 8: BCD OUTPUT CHINH XAC
        // ==============================================================
        $display("--- TEST 8: BCD output chinh xac ---");
        do_reset;

        // Dat giay = 37 (tens=3, ones=7)
        set_edit(1'b0, 2'b01);  // TIME mode, field1 = SEC
        edit_up_n(37);
        clear_edit;
        check(sec_tens, 3, "BCD sec_tens=3");
        check(sec_ones, 7, "BCD sec_ones=7");

        // Dat phut = 48
        set_edit(1'b0, 2'b10);  // MIN
        edit_up_n(48);
        clear_edit;
        check(min_tens, 4, "BCD min_tens=4");
        check(min_ones, 8, "BCD min_ones=8");

        // Dat gio = 15
        set_edit(1'b0, 2'b11);  // HR
        edit_up_n(15);
        clear_edit;
        check(hr_tens, 1, "BCD hr_tens=1");
        check(hr_ones, 5, "BCD hr_ones=5");
        $display("");

        // ==============================================================
        // TEST 9: EDIT GIAY UP
        // ==============================================================
        $display("--- TEST 9: Edit giay UP ---");
        do_reset;

        set_edit(1'b0, 2'b01);  // SEC

        edit_up;
        check(bcd_val(sec_tens, sec_ones), 1, "Edit sec UP: 0->1");
        edit_up;
        check(bcd_val(sec_tens, sec_ones), 2, "Edit sec UP: 1->2");
        edit_up_n(8);
        check(bcd_val(sec_tens, sec_ones), 10, "Edit sec UP: ->10");

        // Kiem tra vong 59->0
        edit_up_n(49);
        check(bcd_val(sec_tens, sec_ones), 59, "Edit sec UP: ->59");
        edit_up;
        check(bcd_val(sec_tens, sec_ones), 0, "Edit sec UP: 59->0 (vong)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 10: EDIT GIAY DOWN (vong 0->59)
        // ==============================================================
        $display("--- TEST 10: Edit giay DOWN: 0->59 ---");
        do_reset;

        set_edit(1'b0, 2'b01);  // SEC
        edit_down;
        check(bcd_val(sec_tens, sec_ones), 59, "Sec DOWN: 0->59");
        edit_down;
        check(bcd_val(sec_tens, sec_ones), 58, "Sec DOWN: 59->58");
        edit_down_n(8);
        check(bcd_val(sec_tens, sec_ones), 50, "Sec DOWN: ->50");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 11: EDIT PHUT UP/DOWN
        // ==============================================================
        $display("--- TEST 11: Edit phut UP/DOWN ---");
        do_reset;

        set_edit(1'b0, 2'b10);  // MIN
        edit_up_n(30);
        check(bcd_val(min_tens, min_ones), 30, "Min UP: 0->30");
        edit_down_n(5);
        check(bcd_val(min_tens, min_ones), 25, "Min DOWN: 30->25");
        edit_down_n(25);
        check(bcd_val(min_tens, min_ones), 0, "Min DOWN: 25->0");
        edit_down;
        check(bcd_val(min_tens, min_ones), 59, "Min DOWN: 0->59 (vong)");
        edit_up;
        check(bcd_val(min_tens, min_ones), 0, "Min UP: 59->0 (vong)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 12: EDIT GIO UP (vong 23->0)
        // ==============================================================
        $display("--- TEST 12: Edit gio UP (vong 23->0) ---");
        do_reset;

        set_edit(1'b0, 2'b11);  // HR
        edit_up_n(23);
        check(bcd_val(hr_tens, hr_ones), 23, "Hr UP: 0->23");
        edit_up;
        check(bcd_val(hr_tens, hr_ones), 0, "Hr UP: 23->0 (vong)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 13: EDIT GIO DOWN (vong 0->23)
        // ==============================================================
        $display("--- TEST 13: Edit gio DOWN (vong 0->23) ---");
        do_reset;

        set_edit(1'b0, 2'b11);  // HR
        edit_down;
        check(bcd_val(hr_tens, hr_ones), 23, "Hr DOWN: 0->23 (vong)");
        edit_down;
        check(bcd_val(hr_tens, hr_ones), 22, "Hr DOWN: 23->22");
        edit_down_n(12);
        check(bcd_val(hr_tens, hr_ones), 10, "Hr DOWN: ->10");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 14: EDIT NGAY UP
        // ==============================================================
        $display("--- TEST 14: Edit ngay UP ---");
        do_reset;
        // Reset: day=1, month=1 (31 ngay)

        set_edit(1'b1, 2'b01);  // DAY
        edit_up;
        check(bcd_val(day_tens, day_ones), 2, "Day UP: 1->2");
        edit_up_n(14);
        check(bcd_val(day_tens, day_ones), 16, "Day UP: ->16");
        edit_up_n(15);
        check(bcd_val(day_tens, day_ones), 31, "Day UP: ->31 (max thang 1)");
        edit_up;
        check(bcd_val(day_tens, day_ones), 1, "Day UP: 31->1 (vong, thang +1)");
        check(bcd_val(mon_tens, mon_ones), 2, "Thang tang: 1->2 (carry tu ngay)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 15: EDIT NGAY DOWN (vong 1->max_day va giam binh thuong)
        // ==============================================================
        $display("--- TEST 15: Edit ngay DOWN ---");
        do_reset;
        // month=1 -> max_day=31

        set_edit(1'b1, 2'b01);  // DAY

        // Day = 1, DOWN => vong tro ve max_day_in_month (31)
        edit_down;
        check(bcd_val(day_tens, day_ones), 31, "Day DOWN: 1->31 (vong thang 1)");

        // Day = 31, DOWN => phai giam xuong 30
        edit_down;
        check(bcd_val(day_tens, day_ones), 30, "Day DOWN: 31->30");

        // Day = 30, DOWN => phai giam xuong 29
        edit_down;
        check(bcd_val(day_tens, day_ones), 29, "Day DOWN: 30->29");

        // Giam nhieu lan de kiem tra giam lien tuc
        edit_down_n(14);
        check(bcd_val(day_tens, day_ones), 15, "Day DOWN: ->15");

        edit_down_n(14);
        check(bcd_val(day_tens, day_ones), 1, "Day DOWN: ->1");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 16: EDIT THANG UP (vong 12->1)
        // ==============================================================
        $display("--- TEST 16: Edit thang UP (vong 12->1) ---");
        do_reset;

        set_edit(1'b1, 2'b10);  // MONTH
        edit_up;
        check(bcd_val(mon_tens, mon_ones), 2, "Mon UP: 1->2");
        edit_up_n(10);
        check(bcd_val(mon_tens, mon_ones), 12, "Mon UP: ->12");
        edit_up;
        check(bcd_val(mon_tens, mon_ones), 1, "Mon UP: 12->1 (vong)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 17: EDIT THANG DOWN (vong 1->12)
        // ==============================================================
        $display("--- TEST 17: Edit thang DOWN (vong 1->12) ---");
        do_reset;

        set_edit(1'b1, 2'b10);  // MONTH
        edit_down;
        check(bcd_val(mon_tens, mon_ones), 12, "Mon DOWN: 1->12 (vong)");
        edit_down;
        check(bcd_val(mon_tens, mon_ones), 11, "Mon DOWN: 12->11");
        edit_down_n(5);
        check(bcd_val(mon_tens, mon_ones), 6, "Mon DOWN: ->6");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 18: EDIT NAM UP/DOWN
        // ==============================================================
        $display("--- TEST 18: Edit nam UP/DOWN ---");
        do_reset;
        // year = 2026

        set_edit(1'b1, 2'b11);  // YEAR
        edit_up;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2027, "Year UP: 2026->2027");
        edit_up;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2028, "Year UP: 2027->2028");
        edit_down;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2027, "Year DOWN: 2028->2027");
        edit_down_n(27);
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2000, "Year DOWN: ->2000");
        edit_down_n(100);
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 1900, "Year DOWN: ->1900");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 19: DONG HO DUNG KHI edit_enable = 1
        // ==============================================================
        $display("--- TEST 19: Dong ho dung khi edit ---");
        do_reset;

        // Dem 10 giay binh thuong
        pulse_tick_n(10);
        check(bcd_val(sec_tens, sec_ones), 10, "Truoc edit: giay=10");

        // Bat edit mode
        set_edit(1'b0, 2'b11);  // Edit HR (khong anh huong sec)

        // Phat 5 tick -> dong ho dung (vi edit_enable=1 -> run=0)
        pulse_tick_n(5);
        check(bcd_val(sec_tens, sec_ones), 10, "Trong edit: giay van=10 (dung)");

        // Tat edit -> dong ho chay lai
        clear_edit;
        pulse_tick_n(3);
        check(bcd_val(sec_tens, sec_ones), 13, "Sau edit: giay=13 (chay lai)");
        $display("");

        // ==============================================================
        // TEST 20: SO NGAY THANG 1 (31 ngay)
        // ==============================================================
        $display("--- TEST 20: Thang 1 co 31 ngay ---");
        do_reset;

        set_edit(1'b1, 2'b01);  // DAY
        edit_up_n(30);           // ngay 1->31
        check(bcd_val(day_tens, day_ones), 31, "Thang 1: ngay 31 (max)");
        edit_up;                 // 31->1, thang tang
        check(bcd_val(day_tens, day_ones), 1, "31+1 -> ngay 1 (tran)");
        check(bcd_val(mon_tens, mon_ones), 2, "Thang tang: 1->2");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 21: SO NGAY THANG 4 (30 ngay)
        // ==============================================================
        $display("--- TEST 21: Thang 4 co 30 ngay ---");
        do_reset;

        // Dat thang = 4
        set_edit(1'b1, 2'b10);  // MONTH
        edit_up_n(3);            // thang 1->4
        clear_edit;
        check(bcd_val(mon_tens, mon_ones), 4, "Thang = 4");

        // Tang ngay den 30
        set_edit(1'b1, 2'b01);  // DAY
        edit_up_n(29);           // ngay 1->30
        check(bcd_val(day_tens, day_ones), 30, "Thang 4: ngay 30 (max)");
        edit_up;                 // 30->1, thang tang
        check(bcd_val(day_tens, day_ones), 1, "30+1 -> ngay 1 (tran)");
        check(bcd_val(mon_tens, mon_ones), 5, "Thang tang: 4->5");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 22: THANG 2 KHONG NHUAN (28 ngay)
        // ==============================================================
        $display("--- TEST 22: Thang 2 nam khong nhuan (28 ngay) ---");
        do_reset;
        // year = 2026 (ko nhuan: 2026 % 4 = 2 != 0)

        // Dat thang = 2
        set_edit(1'b1, 2'b10);  // MONTH
        edit_up;                 // thang 1->2
        clear_edit;
        check(bcd_val(mon_tens, mon_ones), 2, "Thang = 2");

        // Tang ngay den 28
        set_edit(1'b1, 2'b01);  // DAY
        edit_up_n(27);           // ngay 1->28
        check(bcd_val(day_tens, day_ones), 28, "Thang 2 ko nhuan: ngay 28 (max)");
        edit_up;                 // 28->1, thang tang
        check(bcd_val(day_tens, day_ones), 1, "28+1 -> ngay 1 (tran)");
        check(bcd_val(mon_tens, mon_ones), 3, "Thang tang: 2->3");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 23: THANG 2 NAM NHUAN (29 ngay)
        // ==============================================================
        $display("--- TEST 23: Thang 2 nam nhuan (29 ngay) ---");
        do_reset;

        // Dat nam = 2024 (nhuan: 2024 % 4 == 0, 2024 % 100 != 0)
        set_edit(1'b1, 2'b11);  // YEAR
        edit_down_n(2);          // 2026 -> 2024
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2024, "Nam = 2024 (nhuan)");

        // Dat thang = 2
        set_edit(1'b1, 2'b10);
        edit_up;
        clear_edit;
        check(bcd_val(mon_tens, mon_ones), 2, "Thang = 2");

        // Tang ngay den 28
        set_edit(1'b1, 2'b01);
        edit_up_n(27);
        check(bcd_val(day_tens, day_ones), 28, "Ngay = 28");

        // Tang them 1 -> ngay 29 (vi nam nhuan)
        edit_up;
        check(bcd_val(day_tens, day_ones), 29, "Thang 2 nhuan: ngay 29 (max)");

        // Tang them 1 -> tran
        edit_up;
        check(bcd_val(day_tens, day_ones), 1, "29+1 -> ngay 1 (tran)");
        check(bcd_val(mon_tens, mon_ones), 3, "Thang tang: 2->3");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 24: NAM NHUAN 2024 (chia 4, ko chia 100)
        // ==============================================================
        $display("--- TEST 24: Nam nhuan 2024 (chia 4, ko chia 100) ---");
        do_reset;

        set_edit(1'b1, 2'b11);
        edit_down_n(2);  // 2026->2024
        clear_edit;

        // Kiem tra gian tiep qua thang 2 = 29 ngay
        set_edit(1'b1, 2'b10);
        edit_up;  // thang 2
        clear_edit;

        set_edit(1'b1, 2'b01);
        edit_up_n(28);  // ngay 1->29
        check(bcd_val(day_tens, day_ones), 29, "2024 nhuan: thang 2 cho ngay 29");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 25: NAM KHONG NHUAN 1900 (chia 100, ko chia 400)
        // ==============================================================
        $display("--- TEST 25: Nam 1900 (chia 100, ko chia 400 -> ko nhuan) ---");
        do_reset;

        // Dat nam = 1900
        set_edit(1'b1, 2'b11);
        edit_down_n(126);  // 2026->1900
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 1900, "Nam = 1900");

        // Thang 2
        set_edit(1'b1, 2'b10);
        edit_up;
        clear_edit;

        // Tang ngay den 28 -> tran (chi 28 ngay)
        set_edit(1'b1, 2'b01);
        edit_up_n(27);
        check(bcd_val(day_tens, day_ones), 28, "1900: thang 2 ngay 28 (max)");
        edit_up;
        check(bcd_val(day_tens, day_ones), 1, "28+1 -> tran (ko nhuan)");
        check(bcd_val(mon_tens, mon_ones), 3, "Thang tang: 2->3");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 26: NAM NHUAN 2000 (chia 400)
        // ==============================================================
        $display("--- TEST 26: Nam 2000 (chia 400 -> nhuan) ---");
        do_reset;

        set_edit(1'b1, 2'b11);
        edit_down_n(26);  // 2026->2000
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2000, "Nam = 2000");

        // Thang 2
        set_edit(1'b1, 2'b10);
        edit_up;
        clear_edit;

        // Tang ngay den 29
        set_edit(1'b1, 2'b01);
        edit_up_n(28);
        check(bcd_val(day_tens, day_ones), 29, "2000 nhuan: thang 2 ngay 29");
        edit_up;
        check(bcd_val(day_tens, day_ones), 1, "29+1 -> tran");
        check(bcd_val(mon_tens, mon_ones), 3, "Thang tang: 2->3");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 27: NAM KHONG NHUAN 2023 (ko chia 4)
        // ==============================================================
        $display("--- TEST 27: Nam 2023 (ko chia 4 -> ko nhuan) ---");
        do_reset;

        set_edit(1'b1, 2'b11);
        edit_down_n(3);  // 2026->2023
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2023, "Nam = 2023");

        // Thang 2
        set_edit(1'b1, 2'b10);
        edit_up;
        clear_edit;

        // Tang ngay den 28
        set_edit(1'b1, 2'b01);
        edit_up_n(27);
        check(bcd_val(day_tens, day_ones), 28, "2023: thang 2 ngay 28 (max)");
        edit_up;
        check(bcd_val(day_tens, day_ones), 1, "28+1 -> tran (ko nhuan)");

        clear_edit;
        $display("");

        // ==============================================================
        // TEST 28: YEAR BCD DOUBLE DABBLE - Nhieu gia tri
        // ==============================================================
        $display("--- TEST 28: Year BCD Double Dabble ---");
        do_reset;

        // year = 2026 sau reset
        check(yr_thousands, 2, "BCD 2026: thousands=2");
        check(yr_hundreds,  0, "BCD 2026: hundreds=0");
        check(yr_tens,      2, "BCD 2026: tens=2");
        check(yr_ones,      6, "BCD 2026: ones=6");

        // Dat year = 1999
        set_edit(1'b1, 2'b11);
        edit_down_n(27);  // 2026->1999
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 1999, "Year = 1999");
        check(yr_thousands, 1, "BCD 1999: thousands=1");
        check(yr_hundreds,  9, "BCD 1999: hundreds=9");
        check(yr_tens,      9, "BCD 1999: tens=9");
        check(yr_ones,      9, "BCD 1999: ones=9");

        // Dat year = 2000 (tu 1999 + 1)
        set_edit(1'b1, 2'b11);
        edit_up;
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2000, "Year = 2000");
        check(yr_thousands, 2, "BCD 2000: thousands=2");
        check(yr_hundreds,  0, "BCD 2000: hundreds=0");
        check(yr_tens,      0, "BCD 2000: tens=0");
        check(yr_ones,      0, "BCD 2000: ones=0");
        $display("");

        // ==============================================================
        // TEST 29: DEM LIEN TUC QUA NHIEU NGAY
        // ==============================================================
        $display("--- TEST 29: Dem lien tuc 3 ngay ---");
        do_reset;
        // Reset: 00:00:00 01/01/2026

        pulse_tick_n(3 * 86400);  // 3 ngay
        check(bcd_val(sec_tens, sec_ones), 0, "Sau 3 ngay: giay=0");
        check(bcd_val(min_tens, min_ones), 0, "Sau 3 ngay: phut=0");
        check(bcd_val(hr_tens, hr_ones),   0, "Sau 3 ngay: gio=0");
        check(bcd_val(day_tens, day_ones),  4, "Sau 3 ngay: ngay=4 (tu 1)");
        check(bcd_val(mon_tens, mon_ones),  1, "Sau 3 ngay: thang=1");
        $display("");

        // ==============================================================
        // TEST 30: CARRY NGAY CUOI THANG 2 NHUAN -> THANG 3
        // ==============================================================
        $display("--- TEST 30: Carry ngay cuoi thang 2 nhuan ---");
        do_reset;

        // Dat nam 2024
        set_edit(1'b1, 2'b11);
        edit_down_n(2);
        clear_edit;

        // Dat thang 2
        set_edit(1'b1, 2'b10);
        edit_up;
        clear_edit;

        // Dat ngay 29
        set_edit(1'b1, 2'b01);
        edit_up_n(28);
        clear_edit;
        check(bcd_val(day_tens, day_ones), 29, "Dat ngay 29/02/2024");

        // Dat gio = 23, phut = 59, giay = 59
        set_edit(1'b0, 2'b11);  // HR
        edit_up_n(23);
        clear_edit;

        set_edit(1'b0, 2'b10);  // MIN
        edit_up_n(59);
        clear_edit;

        set_edit(1'b0, 2'b01);  // SEC
        edit_up_n(59);
        clear_edit;

        check(bcd_val(hr_tens, hr_ones), 23, "Gio = 23");
        check(bcd_val(min_tens, min_ones), 59, "Phut = 59");
        check(bcd_val(sec_tens, sec_ones), 59, "Giay = 59");

        // 1 tick -> 00:00:00 01/03/2024
        pulse_tick;
        check(bcd_val(sec_tens, sec_ones), 0, "Giay = 0");
        check(bcd_val(min_tens, min_ones), 0, "Phut = 0");
        check(bcd_val(hr_tens, hr_ones),   0, "Gio = 0");
        check(bcd_val(day_tens, day_ones),  1, "Ngay = 1 (tu 29)");
        check(bcd_val(mon_tens, mon_ones),  3, "Thang = 3 (tu 2)");
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 2024, "Nam van = 2024");
        $display("");

        // ==============================================================
        // TEST 31: NAM VONG TRON 9999 -> 1 VA 1 -> 9999
        // ==============================================================
        $display("--- TEST 31: Nam vong tron 9999 -> 1 va 1 -> 9999 ---");
        do_reset;

        // Dat nam = 9999
        set_edit(1'b1, 2'b11);  // YEAR
        edit_up_n(7973);         // 2026 + 7973 = 9999
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 9999, "Nam = 9999");
        check(yr_thousands, 9, "BCD 9999: thousands=9");
        check(yr_hundreds,  9, "BCD 9999: hundreds=9");
        check(yr_tens,      9, "BCD 9999: tens=9");
        check(yr_ones,      9, "BCD 9999: ones=9");

        // Tang them 1 -> 1 (year_counter: 9999+1 -> 1, khong phai 0)
        set_edit(1'b1, 2'b11);
        edit_up;
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 1, "Nam UP: 9999->1 (vong)");

        // Giam 1 -> 9999 (year_counter: 1-1 -> 9999)
        set_edit(1'b1, 2'b11);
        edit_down;
        clear_edit;
        check(year_val(yr_thousands, yr_hundreds, yr_tens, yr_ones), 9999, "Nam DOWN: 1->9999 (vong)");
        $display("");

        // ==============================================================
        // TEST 32: EDIT KHONG ANH HUONG TRUONG KHAC (cross-field isolation)
        // ==============================================================
        $display("--- TEST 32: Cross-field isolation ---");
        do_reset;

        // Dem 30 giay
        pulse_tick_n(30);
        check(bcd_val(sec_tens, sec_ones), 30, "Giay = 30");

        // Edit phut, giay phai khong doi (dong ho dung)
        set_edit(1'b0, 2'b10);  // MIN
        edit_up_n(15);
        check(bcd_val(min_tens, min_ones), 15, "Edit phut UP: 0->15");
        check(bcd_val(sec_tens, sec_ones), 30, "Giay van = 30 (khong doi)");
        check(bcd_val(hr_tens, hr_ones),   0,  "Gio van = 0 (khong doi)");
        clear_edit;

        // Edit gio, phut va giay khong doi
        set_edit(1'b0, 2'b11);  // HR
        edit_up_n(8);
        check(bcd_val(hr_tens, hr_ones),   8,  "Edit gio UP: 0->8");
        check(bcd_val(min_tens, min_ones), 15, "Phut van = 15");
        check(bcd_val(sec_tens, sec_ones), 30, "Giay van = 30");
        clear_edit;

        // Edit ngay, time fields khong doi
        set_edit(1'b1, 2'b01);  // DAY
        edit_up_n(10);
        check(bcd_val(day_tens, day_ones), 11, "Edit ngay UP: 1->11");
        check(bcd_val(sec_tens, sec_ones), 30, "Giay van = 30");
        check(bcd_val(min_tens, min_ones), 15, "Phut van = 15");
        check(bcd_val(hr_tens, hr_ones),   8,  "Gio van = 8");
        clear_edit;
        $display("");

        // ==============================================================
        // TEST 33: THANG 2 -> THANG 3 TU DONG (dong ho chay)
        // ==============================================================
        $display("--- TEST 33: Thang 2 -> thang 3 tu dong (dong ho chay) ---");
        do_reset;

        // Dat nam 2026 (ko nhuan), thang 2, ngay 28, gio 23:59:59
        set_edit(1'b1, 2'b10);
        edit_up;  // thang 2
        clear_edit;

        set_edit(1'b1, 2'b01);
        edit_up_n(27);  // ngay 28
        clear_edit;

        set_edit(1'b0, 2'b11);
        edit_up_n(23);  // gio 23
        clear_edit;

        set_edit(1'b0, 2'b10);
        edit_up_n(59);  // phut 59
        clear_edit;

        set_edit(1'b0, 2'b01);
        edit_up_n(59);  // giay 59
        clear_edit;

        check(bcd_val(day_tens, day_ones), 28, "Ngay = 28");
        check(bcd_val(mon_tens, mon_ones), 2, "Thang = 2");
        check(bcd_val(hr_tens, hr_ones), 23, "Gio = 23");
        check(bcd_val(min_tens, min_ones), 59, "Phut = 59");
        check(bcd_val(sec_tens, sec_ones), 59, "Giay = 59");

        // 1 tick -> 00:00:00 01/03/2026
        pulse_tick;
        check(bcd_val(sec_tens, sec_ones), 0, "Giay -> 0");
        check(bcd_val(min_tens, min_ones), 0, "Phut -> 0");
        check(bcd_val(hr_tens, hr_ones),   0, "Gio -> 0");
        check(bcd_val(day_tens, day_ones), 1, "Ngay -> 1 (carry tu 28)");
        check(bcd_val(mon_tens, mon_ones), 3, "Thang -> 3 (carry tu 2)");
        $display("");

        // ==============================================================
        // TEST 34: SO NGAY TRONG TAT CA 12 THANG
        // ==============================================================
        $display("--- TEST 34: So ngay trong tat ca 12 thang ---");
        do_reset;
        // year = 2026 (ko nhuan)

        begin : test34_block
            integer m;
            integer max_days;
            // max_days cho tung thang (nam ko nhuan)
            // Thang: 1  2  3  4  5  6  7  8  9 10 11 12
            // Ngay: 31 28 31 30 31 30 31 31 30 31 30 31

            for (m = 1; m <= 12; m = m + 1) begin
                do_reset;

                // Dat thang = m
                set_edit(1'b1, 2'b10);
                edit_up_n(m - 1);
                clear_edit;
                check(bcd_val(mon_tens, mon_ones), m, "Dat thang");

                // Xac dinh so ngay toi da
                case (m)
                    1, 3, 5, 7, 8, 10, 12: max_days = 31;
                    4, 6, 9, 11:           max_days = 30;
                    2:                     max_days = 28;  // 2026 ko nhuan
                    default:               max_days = 31;
                endcase

                // Tang ngay den max
                set_edit(1'b1, 2'b01);
                edit_up_n(max_days - 1);
                check(bcd_val(day_tens, day_ones), max_days, "Ngay max");

                // Tang them 1 -> tran ve ngay 1
                edit_up;
                check(bcd_val(day_tens, day_ones), 1, "Ngay tran -> 1");

                clear_edit;
            end
        end
        $display("");

        // ==============================================================
        // KET QUA TONG KET
        // ==============================================================
        $display("================================================================");
        $display("  KET QUA TONG KET - CENTURY_CLOCK-MAIN TESTBENCH");
        $display("================================================================");
        $display("  Tong so test : %0d", test_num);
        $display("  PASS         : %0d", pass_count);
        $display("  FAIL         : %0d", fail_count);
        $display("================================================================");
        if (fail_count == 0)
            $display("  >>> TAT CA TEST PASS! <<<");
        else
            $display("  >>> CO %0d TEST THAT BAI! <<<", fail_count);
        $display("================================================================");
        $display("");

        #200;
        $finish;
    end

    // ========================================================================
    // DUMP WAVEFORM
    // ========================================================================
    initial begin
        $dumpfile("tb_counter_controller.vcd");
        $dumpvars(0, tb_counter_controller);
    end

endmodule
