module random_bit_generator(
    input clk,
    output reg [15:0] rand16 
);
    initial rand16 = 16'h1;
    always @(posedge clk) begin
        rand16 <= {rand16[14:0], rand16[15] ^ rand16[13]};
    end
endmodule

module spi_simulation (
    input wire MCLK,    // Master clock
    input wire CLK_IN,  // External clock input
    input wire RESET,   // Reset signal
    input wire ENABLE,  // Enable signal
    output reg TX_RDY,  // Transmit ready
    output reg RX_RDY,  // Receive ready
    output reg BUSY,    // Busy flag
    output wire CSS,    // Chip select signal
    inout wire [15:0] DIN,  // Data input bus
    inout wire [15:0] DOUT, // Data output bus
    input wire MISO,    // Master In Slave Out
    output reg MOSI     // Master Out Slave In
);

// signals
reg [15:0] input_buffer;
reg [15:0] output_buffer;
reg [15:0] conveyor;
integer i;

// Instance of random_bit_generator
wire [15:0] rand16;
random_bit_generator rng(MCLK, rand16);


// Generate random bits for the input buffer
always @(posedge MCLK or posedge RESET) begin
    if (RESET) begin
        input_buffer <= 16'b0;
    end else if (ENABLE) begin
        input_buffer <= rand16;
        TX_RDY <= 1'b1;
    end
end



// Conveyor logic to shift bits
always @(posedge CLK_IN or posedge RESET) begin
    if (RESET) begin
        conveyor <= 16'b0;
        MOSI <= 1'b0;
        RX_RDY <= 1'b0;
    end else if (TX_RDY && !BUSY) begin
        BUSY <= 1'b1;
        conveyor <= input_buffer;
        for (i = 0; i < 16; i = i + 1) begin
            MOSI <= conveyor[15];
            conveyor <= conveyor << 1;
            conveyor[0] <= MISO;
            #1; // Wait for 1 time unit
        end
        output_buffer <= conveyor;
        RX_RDY <= 1'b1;
        BUSY <= 1'b0;
        TX_RDY <= 1'b0;
    end
end

// Debugging: Print the state of the buffers and the conveyor
always @(posedge MCLK) begin
    if (RX_RDY) begin
        $display("Input Buffer: %b", input_buffer);
        $display("Output Buffer: %b", output_buffer);
        $display("Conveyor: %b", conveyor);
    end
end

endmodule
