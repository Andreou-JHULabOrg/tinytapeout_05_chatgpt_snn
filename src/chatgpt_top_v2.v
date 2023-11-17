module top (
    input clk,      // System Clock
    input reset,    // System Reset
    input sclk,     // SPI Clock
    input cs_n,     // SPI Chip Select (Active Low)
    input mosi,     // SPI Master Out Slave In
    output miso,    // SPI Master In Slave Out
    input [2:0] spikes_in_async,              // 3-bit input spikes
    output [2:0] spikes_out             // 3-bit vector for spike outputs from the second layer
);

    wire [3:0] addr_out;
    wire [7:0] data_out;
    wire write_enable;

    // SPI Slave Instance
    spi_slave slave (
        .clk(clk),
        .reset(reset),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .addr_out(addr_out),
        .data_out(data_out),
        .write_enable(write_enable),
        .miso(miso)
    );

    // ChatGPT Neuron Network Instance
    chatgpt_neuron_network neural_net (
        .clk(clk),
        .reset(reset),
        .addr(addr_out),
        .data_in(data_out),
        .write_enable(write_enable),
        .spikes_in_async(spikes_in_async),
        .spikes_out(spikes_out)
    );

    reg [7:0] x;
    reg [7:0] y;
    
    integer i;
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            y[i] = 1'b1;
        end
        for (i = 0; i < 8; i = i + 1) begin
            x[i] = 1'b1;
        end
    end

endmodule
