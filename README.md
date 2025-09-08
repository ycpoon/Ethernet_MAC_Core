## Ethernet MAC Core Implementation

# Overview

A naive implementation of a configurable Ethernet Media Access Control (MAC) core supporting 10/100/1000 Mbps and multiple physical interfaces. Designed in SystemVerilog for FPGA/ASIC implementation.

# Features

- Triple-Speed Support: 10 Mbps, 100 Mbps, and 1000 Mbps operation

- Support RGMII (Reduced Gigabit Media Independent Interface)

- Integrated FIFOs: Separate transmit and receive FIFOs for data buffering

- CRC Generation/Checking: Hardware CRC-32 computation

- Statistics Counters: Packet and byte counters with error tracking

- MDIO Management: PHY configuration and status monitoring

- Configurable: Software-controlled speed and interface selection

# Block Diagram

This project follows the following block diagram reference from various FPGA/ASIC companies such as Xilinx, Lattice, Efinix:

Image to be Inserted...

# File Structure

eth_mac_core/  
├── eth_mac_core.sv         # Top-level module  
├── eth_mac_pkg.sv          # Package with constants  
├── tx_fifo.sv              # Transmit FIFO  
├── tx_control.sv           # Transmit control logic  
├── crc_generator.sv        # CRC-32 generator  
├── rx_fifo.sv              # Receive FIFO  
├── rx_control.sv           # Receive control logic  
├── crc_checker.sv          # CRC-32 checker  
├── rgmii_control.sv        # RGMII interface control  
├── config_stats.sv         # Configuration and statistics  
├── mdio_master.sv          # MDIO management interface  
└── clock_gen.sv            # Clock generation  

# Interface Signals

Main Interfaces:

- Clock/Reset: clk, rst_n

- Configuration: 32x16-bit registers accessible via config_* signals

- Data Path: AXI-Stream like interface for TX/RX data

- PHY Interface: RGMII signals (rgmii_txd, rgmii_rxd, etc.)

- MDIO: 2-wire management interface

Configuration Registers:

- CONFIG_MAC_CONTROL: Core control and status

- CONFIG_MAC_ADDR_HI/LO: MAC address

- CONFIG_SPEED_MODE: Speed and interface selection

- CONFIG_STATS: Statistics readback

# Testing

Only some unit level testing has been done, this core has not been fully tested by intergration-level testing.

Some possible test scenarios:

- Basic packet transmission/reception

- CRC error injection and detection

- Speed mode switching

- FIFO overflow/underflow conditions

- MDIO register access

# Future Improvements

1. Currently only supports RGMII interface, can redesign rgmii_control to support configurable mode with GMII/RMII/MII as other options.
2. Implement a Pause Frame Control between RX and TX Control.
3. Make a sysdefs for parameterization of MAC address, configurations.
4. Build a comprehensive testbench suite.