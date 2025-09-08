module rgmii_control (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_90,      // 90-degree phase shifted clock for TX
    input  logic        clk_125m,    // 125MHz clock for 1000Mbps
    input  logic        clk_25m,     // 25MHz clock for 100Mbps
    input  logic        clk_2_5m,    // 2.5MHz clock for 10Mbps
    
    // TX Interface from MAC
    input  logic [7:0]  tx_data_in,
    input  logic        tx_en_in,
    input  logic        tx_er_in,
    output logic        tx_ready_out,
    
    // RX Interface to MAC
    output logic [7:0]  rx_data_out,
    output logic        rx_dv_out,
    output logic        rx_er_out,
    
    // RGMII PHY Interface
    output logic [3:0]  rgmii_txd,
    output logic        rgmii_tx_ctl,
    output logic        rgmii_txc,
    input  logic [3:0]  rgmii_rxd,
    input  logic        rgmii_rx_ctl,
    input  logic        rgmii_rxc,
    
    // Speed selection
    input  logic [1:0]  speed_select
);

    // Internal signals
    logic [7:0]  tx_data_reg;
    logic        tx_en_reg;
    logic        tx_er_reg;
    logic [7:0]  rx_data_reg;
    logic        rx_dv_reg;
    logic        rx_er_reg;
    
    logic        tx_clk;
    logic        rx_clk;
    logic [3:0]  tx_data_rising;
    logic [3:0]  tx_data_falling;
    logic        tx_ctl_rising;
    logic        tx_ctl_falling;
    
    // Clock selection based on speed
    always_comb begin
        case (speed_select)
            2'b00: tx_clk = clk_2_5m;  // 10Mbps
            2'b01: tx_clk = clk_25m;   // 100Mbps
            2'b10: tx_clk = clk_125m;  // 1000Mbps
            default: tx_clk = clk_125m;
        endcase
    end

    assign rgmii_txc = tx_clk;
    assign rx_clk = rgmii_rxc;

    // TX Path: DDR output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_reg <= 8'h0;
            tx_en_reg <= 1'b0;
            tx_er_reg <= 1'b0;
            tx_data_rising <= 4'h0;
            tx_data_falling <= 4'h0;
            tx_ctl_rising <= 1'b0;
            tx_ctl_falling <= 1'b0;
        end else begin
            tx_data_reg <= tx_data_in;
            tx_en_reg <= tx_en_in;
            tx_er_reg <= tx_er_in;
            
            // Prepare DDR data
            tx_data_rising <= tx_data_in[3:0];
            tx_data_falling <= tx_data_in[7:4];
            tx_ctl_rising <= tx_en_in ^ tx_er_in;  // TX_CTL = TX_EN XOR TX_ER
            tx_ctl_falling <= tx_en_reg ^ tx_er_reg;
        end
    end

    // DDR output registers
    always_ff @(posedge clk_90) begin
        rgmii_txd <= tx_data_rising;
        rgmii_tx_ctl <= tx_ctl_rising;
    end

    always_ff @(negedge clk_90) begin
        rgmii_txd <= tx_data_falling;
        rgmii_tx_ctl <= tx_ctl_falling;
    end

    // RX Path: DDR input
    logic [3:0] rx_data_rising;
    logic [3:0] rx_data_falling;
    logic       rx_ctl_rising;
    logic       rx_ctl_falling;
    
    // Capture rising edge data
    always_ff @(posedge rx_clk) begin
        rx_data_rising <= rgmii_rxd;
        rx_ctl_rising <= rgmii_rx_ctl;
    end
    
    // Capture falling edge data
    always_ff @(negedge rx_clk) begin
        rx_data_falling <= rgmii_rxd;
        rx_ctl_falling <= rgmii_rx_ctl;
    end
    
    // Reconstruct 8-bit data and control signals
    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_reg <= 8'h0;
            rx_dv_reg <= 1'b0;
            rx_er_reg <= 1'b0;
        end else begin
            rx_data_reg <= {rx_data_falling, rx_data_rising};
            rx_dv_reg <= rx_ctl_rising;  // RX_DV is the rising edge of RX_CTL
            rx_er_reg <= rx_ctl_rising ^ rx_ctl_falling;  // RX_ER = RX_CTL_rising XOR RX_CTL_falling
        end
    end

    // Output assignments
    assign rx_data_out = rx_data_reg;
    assign rx_dv_out = rx_dv_reg;
    assign rx_er_out = rx_er_reg;
    assign tx_ready_out = 1'b1;  // Always ready for RGMII

endmodule