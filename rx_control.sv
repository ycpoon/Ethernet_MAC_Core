module rx_control (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  phy_rx_data,
    input  logic        phy_rx_dv,
    input  logic        phy_rx_er,
    input  logic        phy_rx_clk,
    input  logic        crc_error,
    output logic [7:0]  data_out,
    output logic        valid_out,
    output logic        last_out,
    output logic        error_out,
    input  logic [1:0]  speed_select,
    input  logic [1:0]  interface_mode
);

    typedef enum logic [2:0] {
        IDLE,
        PREAMBLE,
        SFD,
        DATA,
        CRC_CHECK
    } rx_state_t;

    rx_state_t state;
    logic [2:0] preamble_count;
    logic [3:0] crc_count;
    logic       sfd_detected;
    logic [7:0] rx_data_sync;

    // Clock domain crossing synchronizer
    always_ff @(posedge clk) begin
        rx_data_sync <= phy_rx_data;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            preamble_count <= 0;
            crc_count <= 0;
            sfd_detected <= 0;
            valid_out <= 0;
            last_out <= 0;
            error_out <= 0;
            data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 0;
                    last_out <= 0;
                    error_out <= 0;
                    if (phy_rx_dv && phy_rx_data == 8'h55) begin
                        state <= PREAMBLE;
                        preamble_count <= 1;
                    end
                end

                PREAMBLE: begin
                    if (phy_rx_dv) begin
                        if (phy_rx_data == 8'hD5) begin
                            state <= DATA;
                            sfd_detected <= 1;
                        end else if (phy_rx_data == 8'h55) begin
                            preamble_count <= preamble_count + 1;
                        end else begin
                            state <= IDLE; // Invalid preamble
                        end
                    end else begin
                        state <= IDLE;
                    end
                end

                DATA: begin
                    if (phy_rx_dv) begin
                        data_out <= rx_data_sync;
                        valid_out <= 1;
                        error_out <= phy_rx_er;
                    end else begin
                        state <= CRC_CHECK;
                        valid_out <= 0;
                    end
                end

                CRC_CHECK: begin
                    if (crc_count < 4) begin
                        crc_count <= crc_count + 1;
                    end else begin
                        if (crc_error) begin
                            error_out <= 1;
                        end
                        last_out <= 1;
                        state <= IDLE;
                        crc_count <= 0;
                    end
                end
            endcase
        end
    end

endmodule