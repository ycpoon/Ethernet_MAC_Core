module rx_fifo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        last_in,
    input  logic        error_in,
    output logic [7:0]  data_out,
    output logic        valid_out,
    output logic        last_out,
    output logic        error_out
);

    parameter DEPTH = 1024;

    logic [7:0]  fifo [0:DEPTH-1];
    logic        error_fifo [0:DEPTH-1];
    logic        last_fifo [0:DEPTH-1];
    logic [10:0] write_ptr;
    logic [10:0] read_ptr;
    logic [10:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            valid_out <= 0;
            last_out <= 0;
            error_out <= 0;
        end else begin
            // Write operation
            if (valid_in) begin
                fifo[write_ptr] <= data_in;
                error_fifo[write_ptr] <= error_in;
                last_fifo[write_ptr] <= last_in;
                write_ptr <= write_ptr + 1;
                count <= count + 1;
            end

            // Read operation
            if (count > 0) begin
                data_out <= fifo[read_ptr];
                error_out <= error_fifo[read_ptr];
                last_out <= last_fifo[read_ptr];
                valid_out <= 1'b1;
                read_ptr <= read_ptr + 1;
                count <= count - 1;
            end else begin
                valid_out <= 1'b0;
                last_out <= 1'b0;
                error_out <= 1'b0;
            end
        end
    end

endmodule