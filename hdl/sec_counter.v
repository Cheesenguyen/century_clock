// bo dem giay: gom 2 khoi dem giay, chuyen sang bcd


module sec_counter (
    input clk_50MHz, rst_n,              // xung clk_50MHz, tin hieu reset low active
    input up,                           // +1 gia tri giay (cong bang button hoac xung 1Hz)
    input down,
    output sig_1min,                    // tin hieu phut ghi giay dem den 60
    output reg [3:0] ones, tens          // tach tung giay ra thanh chuc, don vi, Chuyen he 10 -> 2 (phan mem tu lam). Max 9 -> toi da 4 bit
);

    reg [5:0] sec;      // bien luu gia tri cua second dang nhi phan
    assign sig_1min = (up == 1'b1 && sec == 6'd59) ? 1'b1 : 1'b0;

    always @(posedge clk_50MHz or negedge rst_n) begin        // dau ra thay doi thi suon duong clk_50MHz va suon am rst_n
        // TIN HIEU RESET DUOC KICH HOAT
        if(rst_n == 1'b0) begin     
            sec <= 6'd0;            // sec va sig_1min reset ve 0
        end

        // TIN HIEU RESET KHONG DUOC KICH HOAT
        else begin 
            // tang tin hieu: xung clk_50MHz hoac nut bam
            if (up == 1'b1) begin 
                if (sec == 6'd59) begin         // khi tin hieu giay dem den 59
                    sec <= 6'd0;                // quay tro lai 0
                end
                else begin 
                    sec <= sec + 1;             // cong 1s
                end
            end

            // giam tin hieu (nut bam)
            else if (down == 1'b1) begin 
                if (sec == 6'd0) begin
                    sec <= 6'd59;               // vong nguoc tro ve phut 59          
                end
                else begin
                    sec <= sec -1'b1; 
                end
            end

            // tin hieu khong tang khong giam: giu nguyen gia tri 
            else begin
                sec <= sec;
            end
        end

    end  

    always @(sec) begin
                        
        if (sec < 10) begin 
            tens = 4'd0; 
            ones = sec;
        end
        else if (sec < 20) begin
            tens = 4'd1; 
            ones = sec - 10;
        end
        else if (sec < 30) begin 
            tens = 4'd2;
            ones = sec - 20;
        end 
        else if (sec < 40) begin
            tens = 4'd3;
            ones = sec - 30;
        end
        else if (sec < 50) begin 
            tens = 4'd4;
            ones = sec - 40;
        end else begin
            tens = 4'd5;
            ones = sec - 50;
        end
    end
endmodule
    