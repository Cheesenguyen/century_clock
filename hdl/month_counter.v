// dem thang: gom 2 khoi dem thang va chuyen sang bcd

module month_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output sig_1y,
    output reg [3:0] month, // toi da 12month -> can 4bit
    output reg [3:0] ones, tens
);

    assign sig_1y = (up == 1'b1 && month == 4'd12) ? 1'b1 : 1'b0;

    always @(posedge clk_50MHz or negedge rst_n) begin

        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin
            month <= 4'd1;
        end
        else begin 
            // tang tin hieu (xung clk_50MHz hoac nut bam)
            if (up == 1'b1) begin 
                if (month == 4'd12) begin
                    month <= 4'd1;
                end
                else begin
                    month <= month + 4'd1;
                end
            end

            // giam tin hieu
            else if (down == 1'b1) begin
                if (month == 4'd1) begin
                    month <= 4'd12;
                end
                else begin
                    month <= month - 4'd1;
                end
            end

            // khong tang khong giam
            else begin 
                month <= month;
            end
        end
    end

    always @(month) begin
                        
        if (month < 10) begin 
            tens = 4'd0; 
            ones = month;
        end
        else begin 
            tens = 4'd1;
            ones = month - 10;
        end 
    end
endmodule