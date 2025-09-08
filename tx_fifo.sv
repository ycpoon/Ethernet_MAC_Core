module tx_fifo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        valid_in,
    input  logic        last_in,
    output logic        ready_out,
    output logic [7:0]  data_out,
    output logic        valid_out,
    input  logic        ready_in,
    output logic        last_out
);

    parameter DEPTH = 1024;
    parameter THRESHOLD = 512;

    logic [7:0]  fifo [0:DEPTH-1];
    logic [10:0] write_ptr;
    logic [10:0] read_ptr;
    logic [10:0] count;
    logic        last_flag;

    assign ready_out = (count < THRESHOLD);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            last_flag <= 0;
            valid_out <= 0;
        end else begin
            // Write operation
            if (valid_in && ready_out) begin
                fifo[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1;
                count <= count + 1;
                if (last_in) last_flag <= 1'b1;
            end

            // Read operation
            if (ready_in && count > 0) begin
                data_out <= fifo[read_ptr];
                valid_out <= 1'b1;
                read_ptr <= read_ptr + 1;
                count <= count - 1;
                if (read_ptr == write_ptr - 1 && last_flag) begin
                    last_out <= 1'b1;
                    last_flag <= 1'b0;
                end else begin
                    last_out <= 1'b0;
                end
            end else begin
                valid_out <= 1'b0;
                last_out <= 1'b0;
            end
        end
    end

endmodule