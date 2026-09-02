// dem gio: gom 2 khoi dem gio va chuyen sang bcd

module hour_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output sig_1d,
    output reg [3:0] ones, tens
);

    reg [4:0] hour;          // toi da 24h -> can 5bit
    assign sig_1d = (up == 1'b1 && hour == 5'd23) ? 1'b1 : 1'b0;

    always @(posedge clk_50MHz or negedge rst_n) begin

        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin
            hour <= 5'd0;
        end
        else begin 
            // tang tin hieu (xung clk_50MHz hoac nut bam)
            if (up == 1'b1) begin 
                if (hour == 5'd23) begin
                    hour <= 5'd0;
                end
                else begin
                    hour <= hour + 5'd1;
                end
            end

            // giam tin hieu
            else if (down == 1'b1) begin
                if (hour == 5'd0) begin
                    hour <= 5'd23;
                end
                else begin
                    hour <= hour - 5'd1;
                end
            end

            // khong tang khong giam
            else begin 
                hour <= hour;
            end
        end
    end

    always @(hour) begin
                        
        if (hour < 10) begin 
            tens = 4'd0; 
            ones = hour;
        end
        else if (hour < 20) begin
            tens = 4'd1; 
            ones = hour - 10;
        end
        else begin 
            tens = 4'd2;
            ones = hour - 20;
        end 
    end
endmodule