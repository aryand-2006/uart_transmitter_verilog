module uart_tx #(parameter CLK_FREQ = 50_000_000, parameter BAUD_RATE = 9600)
(input wire clk, input wire reset, input wire tx_start, input wire [7:0] data_in, output reg tx, output reg tx_busy);
    
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    wire tick;

    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) baud_instance (.clk(clk), .reset(reset), .tick(tick));

    always @(posedge clk or posedge reset)
        begin
            if (reset) begin
                state     <= IDLE;
                tx        <= 1'b1;   // line stays high i.e 1
                tx_busy   <= 1'b0;
                bit_count   <= 3'b0;
                shift_reg <= 8'b0;
            end 
            else begin
                case (state)
                    IDLE : begin
                        tx <= 1'b1;
                        if (tx_start) begin
                            shift_reg <= data_in; 
                            tx_busy <= 1'b1;
                            state <= START;
                        end
                    end

                    START : begin
                        if (tick) begin
                            tx <= 1'b0;
                            bit_count <= 3'b000;
                            state <= DATA;
                        end
                    end

                    DATA : begin
                        if (tick) begin
                            tx <= shift_reg[bit_count]; 
                            if (bit_count == 3'd7) state <= STOP;
                            else bit_count <= bit_count + 1;
                        end
                    end

                    STOP : begin
                        if (tick) begin
                            tx <= 1'b1;
                            tx_busy <= 1'b0;
                            state <= IDLE;
                        end
                    end

                    default : state <= IDLE;
                endcase
            end
        end
endmodule