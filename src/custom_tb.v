`timescale 1ns/1ps

module tb ();

localparam SCK_P = 160;
localparam CLK_P = 20;
localparam THRESHOLD_ADDR = 0;
localparam LEAK_RATE_ADDR = 1;
localparam REFRAC_PERIOD_ADDR = 2;
localparam FIRST_LAYER_WEIGHTS0_ADDR = 3;
localparam FIRST_LAYER_WEIGHTS1_ADDR = 4;
localparam FIRST_LAYER_WEIGHTS2_ADDR = 5;
localparam SECOND_LAYER_WEIGHTS00_ADDR = 6;
localparam SECOND_LAYER_WEIGHTS01_ADDR = 7;
localparam SECOND_LAYER_WEIGHTS02_ADDR = 8;
localparam SECOND_LAYER_WEIGHTS10_ADDR = 9;
localparam SECOND_LAYER_WEIGHTS11_ADDR = 10;
localparam SECOND_LAYER_WEIGHTS12_ADDR = 11;
localparam SECOND_LAYER_WEIGHTS20_ADDR = 12;
localparam SECOND_LAYER_WEIGHTS21_ADDR = 13;
localparam SECOND_LAYER_WEIGHTS22_ADDR = 14;

reg clk;
wire spi_cs_n, spi_sck, spi_copi, spi_cipo;
wire rst_n;
wire [2:0] spikes_in, spikes_out;

always #(CLK_P/2) clk = ~clk;

task automatic apply_reset();
	rst_n = 1'b0;
	#(10.2*CLK_P);
	rst_n = 1'b1;
	#(10*CLK_P);
endtask

task automatic spi_write_byte(input wire [3:0] addr, reg [7:0] data);
	wire [15:0] tx_bits;
	tx_bits = {1'b0, addr, data, 3'b0};

	spi_cs_n = 0;
	#(SCK_P/2);
	for (int i = 0; i < 16; i++) begin
		spi_sck = 0;
		spi_copi = tx_bits[15-i];
		#(SCK_P/2);
		spi_sck = 1;
		#(SCK_P/2);
	end
	spi_sck = 0;
	#(SCK_P/2);
	spi_cs_n = 1;
	#(SCK_P/2);
endtask

task automatic apply_spikes(input wire [2:0] mask, integer ncycles);
	begin
		spikes_in = mask;
		#(CLK_P * ncycles);
		spikes_in = '0;
	end
endtask

initial begin
	{clk, spi_sck, spi_copi, spikes_in} = '0;
	spi_cs_n = '1;
	apply_reset();
	spi_write_byte(THRESHOLD_ADDR, 150);
	spi_write_byte(LEAK_RATE_ADDR, 3);
	spi_write_byte(REFRAC_PERIOD_ADDR, 5);
	spi_write_byte(FIRST_LAYER_WEIGHTS0_ADDR, 4);
	spi_write_byte(FIRST_LAYER_WEIGHTS1_ADDR, 5);
	spi_write_byte(FIRST_LAYER_WEIGHTS2_ADDR, 6);
	spi_write_byte(SECOND_LAYER_WEIGHTS00_ADDR, 100);
	spi_write_byte(SECOND_LAYER_WEIGHTS01_ADDR, 75);
	spi_write_byte(SECOND_LAYER_WEIGHTS02_ADDR, 50);
	spi_write_byte(SECOND_LAYER_WEIGHTS10_ADDR, 14);
	spi_write_byte(SECOND_LAYER_WEIGHTS11_ADDR, 15);
	spi_write_byte(SECOND_LAYER_WEIGHTS12_ADDR, 16);
	spi_write_byte(SECOND_LAYER_WEIGHTS20_ADDR, 17);
	spi_write_byte(SECOND_LAYER_WEIGHTS21_ADDR, 18);
	spi_write_byte(SECOND_LAYER_WEIGHTS22_ADDR, 19);
	apply_spikes('1, 100);
	spi_write_byte(FIRST_LAYER_WEIGHTS0_ADDR, 100);
	apply_spikes(3'b001, 100);

	#(100*CLK_P);
	$stop();
end

wire [7:0] ui_in;
wire [7:0] uo_out;
wire [7:0] uio_in;
wire [7:0] uio_out;
wire [7:0] uio_oe;
wire ena;

assign ui_in = {2'b0, spikes_in, spi_copi, spi_cs_n, spi_sck};
assign spi_cipo = uo_out[3];
assign spikes_out = uo_out[2:0];

initial begin
	ena = '1;
end

tt_um_chatgpt_snn_mtomlin5 i_tt_um_chatgpt_snn (
	.ui_in  (ui_in  ),
	.uo_out (uo_out ),
	.uio_in (uio_in ),
	.uio_out(uio_out),
	.uio_oe (uio_oe ),
	.ena    (ena    ),
	.clk    (clk    ),
	.rst_n  (rst_n  )
);

endmodule : tb