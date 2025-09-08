module crc_generator (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        last_in,
    output logic        enable,
    output logic [31:0] crc_out
);

    logic [31:0] crc_reg;
    logic [7:0]  data_reg;
    logic        calc_enable;

    // Ethernet CRC32 polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
    parameter [31:0] POLY = 32'hEDB88320;

    assign enable = calc_enable;
    assign crc_out = ~{crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27], crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31],
                      crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19], crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23],
                      crc_reg[8],  crc_reg[9],  crc_reg[10], crc_reg[11], crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15],
                      crc_reg[0],  crc_reg[1],  crc_reg[2],  crc_reg[3],  crc_reg[4],  crc_reg[5],  crc_reg[6],  crc_reg[7]};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
            calc_enable <= 0;
        end else begin
            if (valid_in) begin
                calc_enable <= 1;
                data_reg <= data_in;
                
                for (int i = 0; i < 8; i++) begin
                    if (crc_reg[31] ^ data_reg[i]) begin
                        crc_reg <= {crc_reg[30:0], 1'b0} ^ POLY;
                    end else begin
                        crc_reg <= {crc_reg[30:0], 1'b0};
                    end
                end
            end else if (last_in) begin
                calc_enable <= 0;
            end
        end
    end

endmodule