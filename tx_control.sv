module tx_control (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        last_in,
    output logic        ready_out,
    input  logic [31:0] crc_result,
    output logic [7:0]  phy_tx_data,
    output logic        phy_tx_en,
    output logic        phy_tx_er,
    input  logic [1:0]  speed_select,
    input  logic [1:0]  interface_mode
);

    typedef enum logic [2:0] {
        IDLE,
        PREAMBLE,
        DATA,
        CRC,
        IPG
    } tx_state_t;

    tx_state_t state;
    logic [2:0] preamble_count;
    logic [3:0] crc_count;
    logic [7:0] ipg_count;
    logic [7:0] tx_data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            preamble_count <= 0;
            crc_count <= 0;
            ipg_count <= 0;
            phy_tx_en <= 0;
            phy_tx_er <= 0;
            phy_tx_data <= 8'h0;
            ready_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    phy_tx_en <= 0;
                    ready_out <= 1;
                    if (valid_in) begin
                        state <= PREAMBLE;
                        preamble_count <= 0;
                        ready_out <= 0;
                    end
                end

                PREAMBLE: begin
                    phy_tx_en <= 1;
                    phy_tx_data <= (preamble_count == 6) ? 8'hD5 : 8'h55;
                    if (preamble_count == 6) begin
                        state <= DATA;
                        tx_data_reg <= data_in;
                    end
                    preamble_count <= preamble_count + 1;
                end

                DATA: begin
                    phy_tx_data <= tx_data_reg;
                    if (valid_in) begin
                        tx_data_reg <= data_in;
                    end
                    if (last_in && valid_in) begin
                        state <= CRC;
                        crc_count <= 0;
                    end
                end

                CRC: begin
                    case (crc_count)
                        0: phy_tx_data <= crc_result[31:24];
                        1: phy_tx_data <= crc_result[23:16];
                        2: phy_tx_data <= crc_result[15:8];
                        3: phy_tx_data <= crc_result[7:0];
                    endcase
                    if (crc_count == 3) begin
                        state <= IPG;
                        ipg_count <= 0;
                        phy_tx_en <= 0;
                    end
                    crc_count <= crc_count + 1;
                end

                IPG: begin
                    if (ipg_count == 11) begin // Inter-packet gap
                        state <= IDLE;
                    end
                    ipg_count <= ipg_count + 1;
                end
            endcase
        end
    end

endmodule