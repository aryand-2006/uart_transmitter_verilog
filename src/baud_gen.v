// as 50MHz is much faster than our ideal baud rate we are generating a counter that divides system clock to give tick pulses at exactly the bit period
module baud_gen #(parameter CLK_FREQ = 50_000_000, parameter BAUD_RATE = 9600) (input wire clk, input wire reset, output reg tick);
    localparam integer DIVISOR = CLK_FREQ / BAUD_RATE;
    integer count;
    
    always @(posedge clk or posedge reset)
        begin
            if (reset) begin
                count <= 0;
                tick <= 1'b0;
            end 
            else if (count == DIVISOR -1) begin
                count <= 0;
                tick <= 1'b1;
            end
            else begin
                count <= count+1;
                tick <= 1'b0;
            end
        end
endmodule
