// bo dem ngay: xac dinh ngay toi dang trong cac thang, dem ngay doi sang BCD
module day_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    input [3:0] month,
    input leap,
    output sig_1m,
    output reg [3:0] ones, tens
);

    reg [4:0] max_day_in_month;
    reg [4:0] day;

    //  Xac dinh so ngay toi da trong thang
    always @(month or leap) begin
        case (month)
            4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: begin 
                max_day_in_month = 5'd31;
            end
            4'd4, 4'd6, 4'd9, 4'd11: begin 
                max_day_in_month = 5'd30;
            end
            4'd2: begin 
                if (leap == 1'b1) begin
                    max_day_in_month = 5'd29;
                end
                else begin
                    max_day_in_month = 5'd28;
                end
            end
            default: begin 
                max_day_in_month = 5'd31;
            end
        endcase
    end
    assign sig_1m = (up == 1'b1 && day >= max_day_in_month) ? 1'b1 : 1'b0;

    // Dem ngay
    always @(posedge clk_50MHz or negedge rst_n) begin
        
        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin
            day <= 5'd1;                        // Ngay luon bat dau tu 1
        end
        else begin 
            // tang tin hieu (nut bam)
            if (up == 1'b1) begin 
                if (day >= max_day_in_month) begin
                    day <= 5'd1;
                end
                else begin
                    day <= day + 5'd1;
                end
            end

            // giam tin hieu
            else if (down == 1'b1) begin
                if (day == 5'd1) begin
                    day <= max_day_in_month;    // Vong nguoc ve ngay cuoi cung cua thang
                end
                else begin
                     if (day > max_day_in_month) begin
                        day <= max_day_in_month;
                    end
                    else begin
                        day <= day - 5'd1;
                    end
                end
            end

            // khong tang khong giam
            else begin 
                if (day > max_day_in_month) begin
                    day <= max_day_in_month;
                end
                else begin
                    day <= day;
                end

            end
        end
    end

    // Khoi to hop: Giai ma sang BCD
    always @(day) begin
        
        if (day < 10) begin 
            tens = 4'd0; 
            ones = day;
        end
        else  if(day < 20) begin
            tens = 4'd1; 
            ones = day - 10;
        end
        else if (day < 30) begin 
            tens = 4'd2;
            ones = day - 20;
        end 
        else begin                              
            tens = 4'd3;
            ones = day - 30;
        end 
    end
endmodule