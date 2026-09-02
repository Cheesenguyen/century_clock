// dem phut: gom 2 khoi dem phut va chuyen sang bcd

module min_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output sig_1h,
    output reg [3:0] ones, tens
);

    reg [5:0] min;
    assign sig_1h = (up == 1'b1 && min == 6'd59) ? 1'b1 : 1'b0;

    always @(posedge clk_50MHz or negedge rst_n) begin

        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin
            min <= 6'd0;
        end
        else begin 
            // tang tin hieu (xung clk_50MHz hoac nut bam)
            if (up == 1'b1) begin 
                if (min == 6'd59) begin
                    min <= 6'd0;
                end
                else begin
                    min <= min + 6'd1;
                end
            end

            // giam tin hieu
            else if (down == 1'b1) begin
                if (min == 6'd0) begin
                    min <= 6'd59;
                end
                else begin
                    min <= min - 6'd1;
                end
            end

            // khong tang khong giam
            else begin 
                min <= min;
            end
        end
    end

    always @(min) begin
                        
        if (min < 10) begin 
            tens = 4'd0; 
            ones = min;
        end
        else if (min < 20) begin
            tens = 4'd1; 
            ones = min - 10;
        end
        else if (min < 30) begin 
            tens = 4'd2;
            ones = min - 20;
        end 
        else if (min < 40) begin
            tens = 4'd3;
            ones = min - 30;
        end
        else if (min < 50) begin 
            tens = 4'd4;
            ones = min - 40;
        end else begin
            tens = 4'd5;
            ones = min - 50;
        end
    end
endmodule