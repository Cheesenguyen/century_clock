module counter_controller (
    input clk_50MHz,
    input rst_n,
    input tick_1hz,             // xung 1Hz tu clock divider, dung de chay dong ho binh thuong
    input edit_enable,          // 1 = dang co switch bat len -> dung toan bo dong ho, chi field duoc chon phan hoi up/down

    /* mode: bien chon nhom dang thao tac. Khoi ben ngoai chiu trach nhiem tu dao gia tri nay moi 1 phut de doi hien thi.
       mode = 0 -> dang lam viec voi nhom GIO : PHUT : GIAY
       mode = 1 -> dang lam viec voi nhom NGAY : THANG : NAM */
    input mode,

    input [1:0] edit_select,    // chon field trong nhom hien tai
    input up, down,              // nut tang/giam khi dang chinh (edit_enable = 1)

    // xuat du lieu BCD cho display
    output [3:0] sec_ones, sec_tens,
    output [3:0] min_ones, min_tens,
    output [3:0] hr_ones, hr_tens,
    output [3:0] day_ones, day_tens,
    output [3:0] mon_ones, mon_tens,
    output [3:0] yr_ones, yr_tens, yr_hundreds, yr_thousands
);

    /* Ma hoa edit_select ket hop voi mode de xac dinh
       dung 1 trong 6 field can chinh:
       mode == 0 (nhom GIO:PHUT:GIAY):
           edit_select = 2'b01 -> GIAY
           edit_select = 2'b10 -> PHUT
           edit_select = 2'b11 -> GIO
       mode == 1 (nhom NGAY:THANG:NAM):
           edit_select = 2'b01 -> NGAY
           edit_select = 2'b10 -> THANG
           edit_select = 2'b11 -> NAM
       edit_select = 2'b00 -> khong co field nao duoc chon */

    localparam SEL_1 = 2'b01;
    localparam SEL_2 = 2'b10;
    localparam SEL_3 = 2'b11;

    // wire carry noi bo giua cac khoi dem
    wire sig_1min, sig_1h, sig_1d, sig_1m, sig_1y;
    wire [3:0] month_bin;   // gia tri nhi phan thang hien tai, day_counter can de biet so ngay toi da
    wire [13:0] year_bin;   // gia tri nhi phan nam hien tai, leap_year_detector can
    wire leap;

    // dong ho chi chay binh thuong khi khong co field nao dang bi chinh
    wire run = !edit_enable;


    sec_counter my_sec (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        // chạy chế độ bình thương: tăng theo xung 1Hz
        // chạy chế độ chỉnh: khi chọn chế độ chỉnh edit_enable = 1, mode = 0 để chỉnh được giây, lựa chọn chỉnh giây và chọn chế độ up
        .up (run ? tick_1hz : (edit_enable && !mode && edit_select==SEL_1 && up) ),
        .down (edit_enable && !mode && edit_select==SEL_1 && down ),
        .sig_1min(sig_1min),
        .ones(sec_ones),
        .tens(sec_tens)
    );

    
    min_counter my_min (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1min : (edit_enable && !mode && edit_select==SEL_2 && up) ),
        .down (edit_enable && !mode && edit_select==SEL_2 && down ),
        .sig_1h(sig_1h),
        .ones(min_ones),
        .tens(min_tens)
    );

   
    hour_counter my_hr (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1h : (edit_enable && !mode && edit_select==SEL_3 && up) ),
        .down (edit_enable && !mode && edit_select==SEL_3 && down ),
        .sig_1d(sig_1d),
        .ones(hr_ones),
        .tens(hr_tens)
    );

    day_counter my_day (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1d : (edit_enable && mode && edit_select==SEL_1 && up) ),
        .down (edit_enable && mode && edit_select==SEL_1 && down ),
        .month(month_bin),
        .leap(leap),
        .sig_1m(sig_1m),
        .ones(day_ones),
        .tens(day_tens)
    );


    month_counter my_month (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1m : (edit_enable && mode && edit_select==SEL_2 && up) ),
        .down (edit_enable && mode && edit_select==SEL_2 && down ),
        .sig_1y(sig_1y),
        .month(month_bin),
        .ones(mon_ones),
        .tens(mon_tens)
    );

 
    year_counter my_year (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1y : (edit_enable && mode && edit_select==SEL_3 && up) ),
        .down (edit_enable && mode && edit_select==SEL_3 && down ),
        .ones(yr_ones),
        .tens(yr_tens),
        .hundreds(yr_hundreds),
        .thousands(yr_thousands),
        .year(year_bin)
    );

    leap_year_detector my_leap (
        .year(year_bin),
        .ones(yr_ones),
        .tens(yr_tens),
        .hundreds(yr_hundreds),
        .thousands(yr_thousands),
        .leap(leap)
    );

endmodule