module mdio_master (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] config_data,
    input  logic [4:0]  config_addr,
    input  logic        config_write,
    input  logic        config_read,
    output logic [15:0] mdio_rd_data,
    output logic        mdio_clk,
    inout  logic        mdio_data,
    output logic        mdio_oe
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        OPCODE,
        PHY_ADDR,
        REG_ADDR,
        TA,
        DATA,
        DONE
    } mdio_state_t;

    mdio_state_t state;
    logic [4:0]  bit_count;
    logic [31:0] shift_reg;
    logic        mdio_out;
    logic        mdio_in;
    logic        reading;

    assign mdio_data = mdio_oe ? mdio_out : 1'bz;
    assign mdio_in = mdio_data;

    // MDIO clock generation (2.5MHz max)
    logic [7:0] clk_div;
    logic       mdio_clk_en;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            mdio_clk <= 0;
            mdio_clk_en <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == 19) begin // 50MHz/20 = 2.5MHz
                clk_div <= 0;
                mdio_clk <= ~mdio_clk;
                mdio_clk_en <= 1;
            end else begin
                mdio_clk_en <= 0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            mdio_out <= 1;
            mdio_oe <= 0;
            reading <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            mdio_rd_data <= 0;
        end else if (mdio_clk_en) begin
            case (state)
                IDLE: begin
                    mdio_oe <= 0;
                    if (config_write || config_read) begin
                        state <= START;
                        shift_reg <= {2'b01, 
                                     (config_read ? 2'b10 : 2'b01), 
                                     config_addr[4:0], 
                                     config_addr[4:0], 
                                     2'b10, 
                                     config_data};
                        bit_count <= 31;
                        reading <= config_read;
                        mdio_oe <= 1;
                    end
                end

                START: begin
                    mdio_out <= 1;
                    state <= OPCODE;
                end

                OPCODE, PHY_ADDR, REG_ADDR, TA, DATA: begin
                    mdio_out <= shift_reg[31];
                    shift_reg <= {shift_reg[30:0], 1'b0};
                    if (bit_count == 0) begin
                        state <= DONE;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end

                DONE: begin
                    if (reading) begin
                        mdio_rd_data <= shift_reg[31:16];
                    end
                    state <= IDLE;
                    mdio_oe <= 0;
                end
            endcase
        end
    end

endmodule