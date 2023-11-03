module chatgpt_neuron_network (
    input clk,                          // clock input
    input reset,                        // asynchronous reset
    input [3:0] addr,                   // 4-bit address to select parameter
    input [7:0] data_in,                // 8-bit data from the register file
    input write_enable,                 // write enable signal for register file
    input [2:0] spikes_in_async,              // 3-bit input spikes
    output [2:0] spikes_out             // 3-bit vector for spike outputs from the second layer
);

    reg [7:0] THRESHOLD, LEAK_RATE, REFRAC_PERIOD;
    reg [7:0] SECOND_LAYER_WEIGHTS[2:0][2:0];
    reg [7:0] FIRST_LAYER_WEIGHTS[2:0];  // Weights for each neuron in the first layer
    integer idx1, idx2, idx3, idx4, idx5, idx6, idx7;  // Loop variables
    reg [7:0] input_currents[2:0];  // Computed input currents for the first layer

    // Synchronizer flip-flops
    reg [2:0] spikes_in_stage1, spikes_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            spikes_in_stage1 <= 3'b000;
            spikes_in <= 3'b000;
        end else begin
            spikes_in <= spikes_in_stage1;
            spikes_in_stage1 <= spikes_in_async;
            
        end
    end

    // Process data_in based on addr input
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            THRESHOLD <= 8'd255;
            LEAK_RATE <= 8'd0;
            REFRAC_PERIOD <= 8'd0;
            for (idx1 = 0; idx1 < 3; idx1 = idx1 + 1) begin
                FIRST_LAYER_WEIGHTS[idx1] <= 8'd0;
                for (idx2 = 0; idx2 < 3; idx2 = idx2 + 1) begin
                    SECOND_LAYER_WEIGHTS[idx1][idx2] <= 8'd0;
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
                        SECOND_LAYER_WEIGHTS[(addr - 4'd6) / 3][(addr - 4'd6) % 3] <= data_in;
                    end
            endcase
        end
    end

    // Compute input currents from spikes_in and FIRST_LAYER_WEIGHTS
    always @(*) begin
        for (idx3 = 0; idx3 < 3; idx3 = idx3 + 1) begin
            input_currents[idx3] = spikes_in[idx3] ? FIRST_LAYER_WEIGHTS[idx3] : 8'd0;
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
    reg [7:0] next_second_layer_currents[2:0];  // intermediate variables

    // Combinatorial block
    always @* begin
        for (idx4 = 0; idx4 < 3; idx4 = idx4 + 1) begin
            next_second_layer_currents[idx4] = 0;  // default to current value
            for (idx5 = 0; idx5 < 3; idx5 = idx5 + 1) begin
                if (first_layer_spikes[idx5]) begin
                    // Check for potential overflow
                    if ((255 - next_second_layer_currents[idx4]) < SECOND_LAYER_WEIGHTS[idx5][idx4]) 
                        next_second_layer_currents[idx4] = 255;  // Set to max value if overflow occurs
                    else
                        next_second_layer_currents[idx4] = next_second_layer_currents[idx4] + SECOND_LAYER_WEIGHTS[idx5][idx4];
                end
            end
        end
    end

    // Sequential block
    always @(posedge clk) begin
        for (idx4 = 0; idx4 < 3; idx4 = idx4 + 1) begin
            second_layer_currents[idx4] <= next_second_layer_currents[idx4];
        end
    end




    // Second layer of neurons
    generate
        for (k = 0; k < 3; k = k + 1) begin : SECOND_LAYER_GEN
            leaky_integrate_fire_neuron second_layer_inst (
                .clk(clk),
                .reset(reset),
                .THRESHOLD(THRESHOLD),
                .LEAK_RATE(LEAK_RATE),
                .REFRAC_PERIOD(REFRAC_PERIOD),
                .current(second_layer_currents[k]),
                .spike(spikes_out[k])
            );
        end
    endgenerate

endmodule
