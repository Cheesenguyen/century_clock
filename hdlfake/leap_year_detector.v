// xac dinh nam nhuan

// doi hang nghin, tram thanh so tuong duong so co 2 chu so he 10 (thuc te he 2)
module hundreds_thousands_bin(
    input [3:0] hundreds,
    input [3:0] thousands,
    output [6:0] binary_2digit
);

    assign binary_2digit = (thousands * 4'd10) + hundreds;
endmodule

// xac dinh nam nhuan
module leap_year_detector(
    input [13:0] year, 
    input [3:0] ones, tens, hundreds, thousands, 
    output leap
);

    wire [6:0] binary_hundreds_thousands;           // gia tri nhi phan cua 2cs dau cua nam de kiem tra chia het cho 400

    hundreds_thousands_bin my_hundreds_thousands_bin(
        .thousands(thousands),
        .hundreds(hundreds),
        .binary_2digit(binary_hundreds_thousands)
    );

    // cach xac dinh nam nhuan: nam chia het cho 4, khong chia het cho 100; chia het cho 100

    wire div4 = year[1:0] == 2'b00;       // so nhi phan chia het cho 4 khi 2 cs cuoi la so 0
    wire div100 = ones == 4'd0 && tens == 4'd0;
    wire div400 = (ones == 4'd0 && tens == 4'd0) && (binary_hundreds_thousands[1:0] == 2'b00);

    assign leap = (div4 && !div100) || div400;
endmodule
