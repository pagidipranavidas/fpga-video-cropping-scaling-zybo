# FPGA-Based Real-Time Video Cropping and Scaling Pipeline

A real-time FPGA video-processing pipeline implemented on the
Digilent Zybo Z7-10.

## Overview

This project extends a Zybo Z7 HDMI reference design with custom
AXI4-Stream video-processing logic.

The pipeline performs:

1920×1080 Input
        ↓
Custom AXI4-Stream Cropper
        ↓
1280×720
        ↓
AXI VDMA + DDR
        ↓
VPSS Scaler Only
        ↓
1920×1080
        ↓
HDMI Output

## Key Contributions

- Designed a custom buffer-free AXI4-Stream video cropper in Verilog.
- Extracted a centered 1280×720 region from a 1920×1080 stream.
- Generated and aligned AXI4-Stream TUSER and TLAST.
- Integrated the cropper with AXI VDMA and DDR frame buffering.
- Configured VPSS Scaler Only for 720p-to-1080p scaling.
- Developed Vitis bare-metal C code for video pipeline initialization.
- Debugged AXI4-Stream and VDMA data-path issues.
- Validated 1080p60 HDMI output on Zybo Z7-10 hardware.

## Hardware

- Digilent Zybo Z7-10
- HDMI monitor

## Tools

- AMD/Xilinx Vivado
- Vitis
- Verilog/SystemVerilog
- AXI4-Stream
- AXI VDMA
- VPSS
- HDMI

## Video Formats

| Stage | Resolution |
|---|---|
| Input | 1920×1080 |
| Cropper Output | 1280×720 |
| Scaler Output | 1920×1080 |
| Display | 1920×1080 @ 60 FPS |

## Important Note

The project was developed by extending an existing Zybo Z7 HDMI
reference design. Custom RTL was developed for the AXI4-Stream
cropper, while AMD/Xilinx video-processing IPs were integrated and
configured as part of the overall pipeline.


## Author

**Pranavi Pagidi**

FPGA Design & Verification Intern
HTIC, IIT Madras Research Park

GitHub: https://github.com/pagidipranavidas
