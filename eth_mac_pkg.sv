package eth_mac_pkg;

    // Configuration addresses
    parameter CONFIG_MAC_CONTROL = 5'h00;
    parameter CONFIG_MAC_ADDR_HI = 5'h01;
    parameter CONFIG_MAC_ADDR_LO = 5'h02;
    parameter CONFIG_SPEED_MODE  = 5'h03;
    parameter CONFIG_STATS       = 5'h04;

    // Speed modes
    parameter SPEED_10M  = 2'b00;
    parameter SPEED_100M = 2'b01;
    parameter SPEED_1000M = 2'b10;

    // Interface modes
    parameter MODE_MII   = 2'b00;
    parameter MODE_GMII  = 2'b01;
    parameter MODE_RGMII = 2'b10;
    parameter MODE_RMII  = 2'b11;

endpackage