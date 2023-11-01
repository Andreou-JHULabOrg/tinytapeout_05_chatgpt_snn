module leaky_integrate_fire_neuron (
    input clk,                  // clock input
    input reset,                // asynchronous reset
    input [7:0] current,        // 8-bit current input
    input [7:0] THRESHOLD,      // spiking threshold
    input [7:0] LEAK_RATE,      // decrease by 1 per cycle
    input [7:0] REFRAC_PERIOD,  // refractory period in cycles
    output reg spike            // output spike signal
);

    // Internal states
    reg [7:0] membrane_potential = 8'd0; // current value of the membrane potential
    reg [7:0] refrac_counter = 8'd0; // refractory period counter
    reg in_refrac = 0; // refractory period flag

    // On every clock cycle
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            membrane_potential <= 8'd0;
            refrac_counter <= 8'd0;
            in_refrac <= 0;
            spike <= 0;
        end else begin
            spike <= 0; // By default, reset the spike signal
            
            if(in_refrac) begin
                refrac_counter <= refrac_counter - 1'b1;
                if(refrac_counter == 8'd0) in_refrac <= 0;
            end else begin
                // Check for potential underflow
                if (membrane_potential < LEAK_RATE) begin
                    membrane_potential <= current; // Directly set to current
                end else if (membrane_potential + current < membrane_potential) begin
                    // Potential overflow detected, clamp to THRESHOLD
                    membrane_potential <= THRESHOLD;
                end else begin
                    membrane_potential <= membrane_potential + current - LEAK_RATE;
                end
                
                // Check for spiking
                if (membrane_potential >= THRESHOLD) begin
                    membrane_potential <= 8'd0;
                    spike <= 1;
                    in_refrac <= 1;
                    refrac_counter <= REFRAC_PERIOD;
                end 
            end
        end
    end

endmodule
