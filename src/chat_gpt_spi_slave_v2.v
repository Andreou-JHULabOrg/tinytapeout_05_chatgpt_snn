// module spi_slave (
//     input clk,      // System Clock
//     input sclk,     // SPI Clock
//     input reset,    // System Reset
//     input cs_n,     // SPI Chip Select (Active Low)
//     input mosi,     // SPI Master Out Slave In
//     output reg [3:0] addr_out,
//     output reg [7:0] data_out,
//     output reg write_enable,
//     output miso
// );

//     // States of the SPI slave FSM
//     parameter IDLE = 2'b00, ADDR_SHIFT = 2'b01, DATA_SHIFT = 2'b10, WRITE_EN = 2'b11;

//     reg [1:0] state = IDLE;            
//     reg [3:0] shift_addr;              
//     reg [7:0] shift_data;              
//     reg [3:0] state_count;             
//     reg [11:0] miso_output = 12'b0;    

//     reg sclk_prev, sclk_prev2;         
//     reg sclk_posedge, sclk_negedge;    

//     reg miso_buf;  // Buffer to hold miso value for an sclk cycle

//     // Registers for synchronizing cs_n and mosi
//     reg cs_n_synced, cs_n_synced2;
//     reg mosi_synced, mosi_synced2;

//     // Synchronization logic for cs_n and mosi
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             cs_n_synced <= 1'b1;     // Assume active low, so default to 'de-asserted'
//             cs_n_synced2 <= 1'b1;
//             mosi_synced <= 1'b0;
//             mosi_synced2 <= 1'b0;
//         end else begin
//             cs_n_synced <= cs_n;
//             cs_n_synced2 <= cs_n_synced;
//             mosi_synced <= mosi;
//             mosi_synced2 <= mosi_synced;
//         end
//     end

//     // Shift register to sample edges of sclk
//     always @(posedge clk) begin
//         sclk_prev2 <= sclk_prev;
//         sclk_prev <= sclk;
//         sclk_posedge <= ~sclk_prev2 & sclk_prev;       
//         sclk_negedge <= sclk_prev2 & ~sclk_prev;       
//     end

//     // FSM transition and miso_output update using synchronized cs_n and mosi
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             state <= IDLE;
//             addr_out <= 4'b0;
//             data_out <= 8'b0;
//             shift_addr <= 4'b0;
//             shift_data <= 8'b0;
//             state_count <= 4'b0;
//             write_enable <= 0;
//             miso_buf <= 1'b0;
//         end else begin
//             if (!cs_n_synced2) begin
//                 if (sclk_posedge) begin
//                     case(state)
//                         IDLE: begin
//                             shift_addr <= 4'b0;
//                             shift_data <= 8'b0;
//                             state_count <= 4'b0;
//                             write_enable <= 0;
//                             state <= ADDR_SHIFT;
//                         end

//                         ADDR_SHIFT: begin
//                             shift_addr <= {shift_addr[2:0], mosi_synced2};
//                             state_count <= state_count + 1'b1;
//                             if (state_count == 3'b11) begin
//                                 state_count <= 4'b0;
//                                 state <= DATA_SHIFT;
//                             end
//                         end

//                         DATA_SHIFT: begin
//                             shift_data <= {shift_data[6:0], mosi_synced2};
//                             state_count <= state_count + 1'b1;
//                             if (state_count == 4'b0111) begin
//                                 state_count <= 4'b0;
//                                 state <= WRITE_EN;
//                             end
//                         end

//                         WRITE_EN: begin
//                             addr_out <= shift_addr;
//                             data_out <= shift_data;
//                             write_enable <= 1;
//                             miso_output <= {shift_addr, shift_data};
//                             state <= IDLE;
//                         end
//                     endcase
//                 end
//                 if (sclk_negedge) begin
//                     miso_output <= {miso_output[10:0], 1'b0};
//                     miso_buf <= miso_output[11];
//                 end
//             end else begin
//                 state <= IDLE;
//                 write_enable <= 0;
//             end
//         end
//     end

//     // MISO behavior using assign statement
//     assign miso = (cs_n_synced2) ? 1'b0 : miso_buf;

// endmodule

module spi_slave (
    input clk,         // System Clock
    input reset,       // System Reset
    input sclk,        // SPI Clock
    input cs_n,        // SPI Chip Select (Active Low)
    input mosi,        // SPI Master Out Slave In
    output reg miso,   // SPI Master In Slave Out
    output reg [3:0] addr_out,      
    output reg [7:0] data_out,      
    output reg write_enable         
);
    // SPI state definitions
    // typedef enum {IDLE, TRANSFER, COMPLETE} spi_state;
    parameter IDLE = 0;
    parameter TRANSFER = 1;
    parameter COMPLETE = 2;

    reg [1:0] state, next_state;
    reg [15:0] shift_reg; 
    reg [7:0] addr_reg;  
    integer bit_count;
    // SPI state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    // SPI logic
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                next_state = IDLE;
                if (!cs_n) begin
                    bit_count <= 15;  // Reset bit count
                    next_state = TRANSFER;
                end
            end
            TRANSFER: begin
                shift_reg[bit_count] <= mosi;
                if (bit_count == 0) begin
                    next_state = COMPLETE;
                end else begin
                    bit_count <= bit_count - 1;
                end
            end
            COMPLETE: begin
                if (cs_n) begin
                    next_state = IDLE;
                    addr_reg <= shift_reg[15:8]; 
                    data_out <= shift_reg[7:0];  
                    write_enable <= 1;
                end
            end
        endcase
    end
    // MISO signal assignment
    always @(posedge clk) begin
        if (state == TRANSFER) begin
            miso <= shift_reg[15];
        end
    end
    always @(*) begin
        addr_out = addr_reg;
        if (state != COMPLETE) begin
            write_enable = 0;
        end
    end
endmodule
