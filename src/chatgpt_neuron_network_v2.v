module chatgpt_neuron_network (
    input clk,                          // clock input
    input reset,                        // asynchronous reset
    input [3:0] addr,                   // 4-bit address to select parameter
    input [7:0] data_in,                // 8-bit data from the register file
    input write_enable,                 // write enable signal for register file
    input [2:0] spikes_in,              // 3-bit input spikes
    output [2:0] spikes_out             // 3-bit vector for spike outputs from the second layer
);

    reg [7:0] THRESHOLD, LEAK_RATE, REFRAC_PERIOD;
    reg [7:0] SECOND_LAYER_WEIGHTS[2:0][2:0];
    reg [7:0] FIRST_LAYER_WEIGHTS[2:0];  // Weights for each neuron in the first layer
    integer i, j, a, b, c;  // Loop variables
    reg [7:0] input_currents[2:0];  // Computed input currents for the first layer

    // Process data_in based on addr input
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            THRESHOLD <= 8'd255;
            LEAK_RATE <= 8'd0;
            REFRAC_PERIOD <= 8'd0;
            for (i = 0; i < 3; i = i + 1) begin
                FIRST_LAYER_WEIGHTS[i] <= 8'd0;
                for (j = 0; j < 3; j = j + 1) begin
                    SECOND_LAYER_WEIGHTS[i][j] <= 8'd0;
                end
            end
        end else if (write_enable) begin
            case (addr)
                4'd0: THRESHOLD <= data_in;
                4'd1: LEAK_RATE <= data_in;
                4'd2: REFRAC_PERIOD <= data_in;
                4'd3: FIRST_LAYER_WEIGHTS[0] <= data_in;
                4'd4: FIRST_LAYER_WEIGHTS[1] <= data_in;
                4'd5: FIRST_LAYER_WEIGHTS[2] <= data_in;
                default: 
                    if (addr >= 4'd6 && addr <= 4'd14) begin
                        i = (addr - 4'd6) / 3;
                        j = (addr - 4'd6) % 3;
                        SECOND_LAYER_WEIGHTS[i][j] <= data_in;
                    end
            endcase
        end
    end

    // Compute input currents from spikes_in and FIRST_LAYER_WEIGHTS
    always @(*) begin
        for (a = 0; a < 3; a = a + 1) begin
            input_currents[a] = spikes_in[a] ? FIRST_LAYER_WEIGHTS[i] : 8'd0;
        end
    end

    // First layer of neurons
    wire [2:0] first_layer_spikes;
    genvar k;

    generate
        for (k = 0; k < 3; k = k + 1) begin : FIRST_LAYER_GEN
            leaky_integrate_fire_neuron first_layer_inst (
                .clk(clk),
                .reset(reset),
                .THRESHOLD(THRESHOLD),
                .LEAK_RATE(LEAK_RATE),
                .REFRAC_PERIOD(REFRAC_PERIOD),
                .current(input_currents[k]),
                .spike(first_layer_spikes[k])
            );
        end
    endgenerate

    // Logic to compute effective current for second layer neurons based on spikes and SECOND_LAYER_WEIGHTS
    reg [7:0] second_layer_currents[2:0];
    always @(posedge clk) begin
        for (b = 0; b < 3; b = b + 1) begin
            second_layer_currents[i] = 0;
            for (c = 0; c < 3; c = c + 1) begin
                if (first_layer_spikes[j]) begin
                    // Check for potential overflow
                    if ((255 - second_layer_currents[b]) < SECOND_LAYER_WEIGHTS[c][b]) 
                        second_layer_currents[b] = 255;  // Set to max value if overflow occurs
                    else
                        second_layer_currents[b] = second_layer_currents[b] + SECOND_LAYER_WEIGHTS[c][b];
                end
            end
        end
    end

    // Second layer of neurons
    genvar kk;
    generate
        for (kk = 0; kk < 3; kk = kk + 1) begin : SECOND_LAYER_GEN
            leaky_integrate_fire_neuron second_layer_inst (
                .clk(clk),
                .reset(reset),
                .THRESHOLD(THRESHOLD),
                .LEAK_RATE(LEAK_RATE),
                .REFRAC_PERIOD(REFRAC_PERIOD),
                .current(second_layer_currents[kk]),
                .spike(spikes_out[kk])
            );
        end
    endgenerate

endmodule
