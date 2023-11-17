`default_nettype none

module tt_um_chatgpt_snn_mtomlin5 #( parameter MAX_COUNT = 24'd10_000_000 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire sclk;
    wire cs_n;
    wire copi;
    wire cipo;
    wire [2:0] spikes_in;
    wire [2:0] spikes_out;
    wire reset;
    reg [7:0] x;
    reg [7:0] y;

    assign reset = ~rst_n;
    assign sclk = ui_in[0];
    assign cs_n = ui_in[1];
    assign copi = ui_in[2];
    assign uo_out = {4'b0, cipo, spikes_out};
    assign spikes_in = ui_in[5:3];
    assign uio_oe = y; // use bidirectionals as outputs
    assign uio_out = x;

    integer i;
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            y[i] = 1'b1;
        end
        for (i = 0; i < 8; i = i + 1) begin
            x[i] = 1'b1;
        end
    end
    
    top i_top (
        .clk            (clk       ),
        .reset          (reset     ),
        .sclk           (sclk      ),
        .cs_n           (cs_n      ),
        .mosi           (copi      ),
        .miso           (cipo      ),
        .spikes_in_async(spikes_in ),
        .spikes_out     (spikes_out)
    );


endmodule
