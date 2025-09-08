module config_stats (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] config_data,
    input  logic [4:0]  config_addr,
    input  logic        config_write,
    input  logic        config_read,
    output logic [15:0] config_rd_data,
    output logic [31:0] stat_counters,
    input  logic        tx_activity,
    input  logic        rx_activity,
    input  logic        rx_errors
);

    logic [15:0] config_reg [0:31];
    logic [31:0] tx_packet_count;
    logic [31:0] rx_packet_count;
    logic [31:0] rx_error_count;
    logic [31:0] tx_byte_count;
    logic [31:0] rx_byte_count;

    assign stat_counters = {tx_packet_count[15:0], rx_packet_count[15:0]};

    // Configuration registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++) begin
                config_reg[i] <= 16'h0;
            end
            config_rd_data <= 16'h0;
        end else begin
            if (config_write) begin
                config_reg[config_addr] <= config_data;
            end
            if (config_read) begin
                config_rd_data <= config_reg[config_addr];
            end
        end
    end

    // Statistics counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_packet_count <= 0;
            rx_packet_count <= 0;
            rx_error_count <= 0;
            tx_byte_count <= 0;
            rx_byte_count <= 0;
        end else begin
            // TX statistics
            if (tx_activity) begin
                tx_byte_count <= tx_byte_count + 1;
            end

            // RX statistics
            if (rx_activity) begin
                rx_byte_count <= rx_byte_count + 1;
                if (rx_errors) begin
                    rx_error_count <= rx_error_count + 1;
                end
            end
        end
    end

endmodule