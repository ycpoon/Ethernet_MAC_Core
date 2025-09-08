module crc_checker (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        last_in,
    output logic        crc_error
);

    logic [31:0] crc_reg;
    logic [7:0]  data_reg;

    parameter [31:0] POLY = 32'hEDB88320;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
            crc_error <= 0;
        end else begin
            if (valid_in) begin
                data_reg <= data_in;
                
                for (int i = 0; i < 8; i++) begin
                    if (crc_reg[31] ^ data_reg[i]) begin
                        crc_reg <= {crc_reg[30:0], 1'b0} ^ POLY;
                    end else begin
                        crc_reg <= {crc_reg[30:0], 1'b0};
                    end
                end
            end

            if (last_in) begin
                // After receiving CRC, the remainder should be 0xC704DD7B
                crc_error <= (crc_reg != 32'hC704DD7B);
                crc_reg <= 32'hFFFFFFFF;
            end
        end
    end

endmodule