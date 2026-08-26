// dem nam: gom khoi dem nam va chuyen sang bcd bang thuat toan double dabble

module year_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output reg [3:0] ones, tens, hundreds, thousands,       // tung chu so cua nam de hien thi             
    output reg [13:0] year                               // output de dua vao khoi day_counter. Max nawm 9999 , 14bit                                
);

    always @(posedge clk_50MHz or negedge rst_n) begin

        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin
            year <= 14'd2026;           // Reset ve nam hien tai
        end
        else begin 
            // tang tin hieu (nut bam, xung)
            if (up == 1'b1) begin 
                if (year == 14'd9999) begin     
                    year <= 14'd1;
                end
                else begin
                    year <= year + 14'd1;
                end
            end

            // giam tin hieu
            else if (down == 1'b1) begin
                if (year == 14'd1) begin
                    year <= 14'd9999;
                end
                else begin
                    year <= year - 14'd1;
                end
            end

            // khong tang khong giam
            else begin 
                year <= year;
            end
        end
    end

    // Khoi giai ma sang BCD (Dung Double Dabble de xu ly so lon)

    integer i;                  // su dung trong vong lap
    reg [29:0] shift_reg;       //14 bit cho nam. Hien thi 4cs, moi cs 4 bit -> tong 30 bit
    
    always @(year) begin
        
        // Buoc 1: Reset thanh ghi dich
        shift_reg = 30'd0;
        shift_reg[13:0] = year;
        
        // Buoc 2: Dich bit va cong 3
        for (i = 0; i < 14; i = i + 1) begin
            if (shift_reg[29:26] >= 4'd5) begin 
                shift_reg[29:26] = shift_reg[29:26] + 4'd3; 
            end
            
            if (shift_reg[25:22] >= 4'd5) begin 
                shift_reg[25:22] = shift_reg[25:22] + 4'd3; 
            end
            
            if (shift_reg[21:18] >= 4'd5) begin 
                shift_reg[21:18] = shift_reg[21:18] + 4'd3; 
            end
            
            if (shift_reg[17:14] >= 4'd5) begin 
                shift_reg[17:14] = shift_reg[17:14] + 4'd3; 
            end
            
            shift_reg = shift_reg << 1;
        end
        
        // Buoc 3: Gan ket qua ra output theo dung ten bien
        thousands = shift_reg[29:26];
        hundreds  = shift_reg[25:22];
        tens      = shift_reg[21:18];
        ones      = shift_reg[17:14];
    end
endmodule