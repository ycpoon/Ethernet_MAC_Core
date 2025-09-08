`timescale 1ns / 1ps

module eth_mac_core (
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_90,      // 90-degree phase shifted clock
    input  logic        clk_125m,    // 125MHz for 1000Mbps
    input  logic        clk_25m,     // 25MHz for 100Mbps
    input  logic        clk_2_5m,    // 2.5MHz for 10Mbps
    
    // Configuration Interface
    input  logic [15:0] config_data,
    input  logic [4:0]  config_addr,
    input  logic        config_write,
    input  logic        config_read,
    output logic [15:0] config_rd_data,
    
    // Transmit Interface
    input  logic [7:0]  tx_data_in,
    input  logic        tx_valid_in,
    input  logic        tx_last_in,
    output logic        tx_ready_out,
    
    // Receive Interface
    output logic [7:0]  rx_data_out,
    output logic        rx_valid_out,
    output logic        rx_last_out,
    output logic        rx_error_out,
    
    // RGMII PHY Interface
    output logic [3:0]  rgmii_txd,
    output logic        rgmii_tx_ctl,
    output logic        rgmii_txc,
    input  logic [3:0]  rgmii_rxd,
    input  logic        rgmii_rx_ctl,
    input  logic        rgmii_rxc,
    
    // MDIO Interface
    output logic        mdio_clk,
    inout  logic        mdio_data,
    output logic        mdio_oe,
    
    // Speed Selection
    input  logic [1:0]  speed_select, // 00: 10M, 01: 100M, 10: 1000M
    input  logic [1:0]  interface_mode // 00: MII, 01: GMII, 10: RGMII, 11: RMII
    
);

    // Internal signals
    logic [7:0]  tx_fifo_to_ctrl;
    logic        tx_fifo_valid;
    logic        tx_fifo_ready;
    logic        tx_fifo_last;
    
    logic [7:0]  rx_ctrl_to_fifo;
    logic        rx_ctrl_valid;
    logic        rx_ctrl_last;
    logic        rx_ctrl_error;
    
    logic        crc_gen_enable;
    logic [31:0] crc_gen_result;
    logic        crc_check_enable;
    logic        crc_check_error;
    
    logic [31:0] stat_counters;
    logic [15:0] mdio_rd_data;

    // PHY interface signals (abstracted)
    logic [7:0]  phy_tx_data;
    logic        phy_tx_en;
    logic        phy_tx_er;
    logic [7:0]  phy_rx_data;
    logic        phy_rx_dv;
    logic        phy_rx_er;
    logic        phy_rx_clk;

    // Instantiate RGMII Control
    rgmii_control rgmii_ctrl_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .clk_90         (clk_90),
        .clk_125m       (clk_125m),
        .clk_25m        (clk_25m),
        .clk_2_5m       (clk_2_5m),
        .tx_data_in     (phy_tx_data),
        .tx_en_in       (phy_tx_en),
        .tx_er_in       (phy_tx_er),
        .tx_ready_out   (tx_fifo_ready),
        .rx_data_out    (phy_rx_data),
        .rx_dv_out      (phy_rx_dv),
        .rx_er_out      (phy_rx_er),
        .rgmii_txd      (rgmii_txd),
        .rgmii_tx_ctl   (rgmii_tx_ctl),
        .rgmii_txc      (rgmii_txc),
        .rgmii_rxd      (rgmii_rxd),
        .rgmii_rx_ctl   (rgmii_rx_ctl),
        .rgmii_rxc      (rgmii_rxc),
        .speed_select   (speed_select)
    );

    tx_fifo tx_fifo_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (tx_data_in),
        .valid_in       (tx_valid_in),
        .last_in        (tx_last_in),
        .ready_out      (tx_ready_out),
        .data_out       (tx_fifo_to_ctrl),
        .valid_out      (tx_fifo_valid),
        .ready_in       (tx_fifo_ready),
        .last_out       (tx_fifo_last)
    );

    tx_control tx_control_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (tx_fifo_to_ctrl),
        .valid_in       (tx_fifo_valid),
        .last_in        (tx_fifo_last),
        .ready_out      (tx_fifo_ready),
        .crc_result     (crc_gen_result),
        .phy_tx_data    (phy_tx_data),
        .phy_tx_en      (phy_tx_en),
        .phy_tx_er      (phy_tx_er),
        .speed_select   (speed_select),
        .interface_mode (interface_mode)
    );

    // Instantiate CRC Generator
    crc_generator crc_gen_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (tx_fifo_to_ctrl),
        .valid_in       (tx_fifo_valid),
        .last_in        (tx_fifo_last),
        .enable         (crc_gen_enable),
        .crc_out        (crc_gen_result)
    );

    // Instantiate Receive Control
    rx_control rx_control_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .phy_rx_data    (phy_rx_data),
        .phy_rx_dv      (phy_rx_dv),
        .phy_rx_er      (phy_rx_er),
        .phy_rx_clk     (phy_rx_clk),
        .crc_error      (crc_check_error),
        .data_out       (rx_ctrl_to_fifo),
        .valid_out      (rx_ctrl_valid),
        .last_out       (rx_ctrl_last),
        .error_out      (rx_ctrl_error),
        .speed_select   (speed_select),
        .interface_mode (interface_mode)
    );

    // Instantiate Receive FIFO
    rx_fifo rx_fifo_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (rx_ctrl_to_fifo),
        .valid_in       (rx_ctrl_valid),
        .last_in        (rx_ctrl_last),
        .error_in       (rx_ctrl_error),
        .data_out       (rx_data_out),
        .valid_out      (rx_valid_out),
        .last_out       (rx_last_out),
        .error_out      (rx_error_out)
    );

    // Instantiate CRC Checker
    crc_checker crc_check_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (rx_ctrl_to_fifo),
        .valid_in       (rx_ctrl_valid),
        .last_in        (rx_ctrl_last),
        .crc_error      (crc_check_error)
    );

    // Instantiate Configuration and Statistics
    config_stats config_stats_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .config_data    (config_data),
        .config_addr    (config_addr),
        .config_write   (config_write),
        .config_read    (config_read),
        .config_rd_data (config_rd_data),
        .stat_counters  (stat_counters),
        .tx_activity    (tx_fifo_valid),
        .rx_activity    (rx_ctrl_valid),
        .rx_errors      (rx_ctrl_error | crc_check_error)
    );

    // Instantiate MDIO Master
    mdio_master mdio_master_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .config_data    (config_data),
        .config_addr    (config_addr),
        .config_write   (config_write),
        .config_read    (config_read),
        .mdio_rd_data   (mdio_rd_data),
        .mdio_clk       (mdio_clk),
        .mdio_data      (mdio_data),
        .mdio_oe        (mdio_oe)
    );

    // PHY Clock generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_tx_clk <= 1'b0;
        end else begin
            case (speed_select)
                2'b00: phy_tx_clk <= ~phy_tx_clk; // 10MHz
                2'b01: phy_tx_clk <= ~phy_tx_clk; // 100MHz
                2'b10: phy_tx_clk <= 1'b0;        // 1000MHz (external)
                default: phy_tx_clk <= 1'b0;
            endcase
        end
    end

endmodule