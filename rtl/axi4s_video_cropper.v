`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2026 15:06:42
// Design Name: 
// Module Name: axi4s_video_cropper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// axi4s_video_cropper.v
//
// Extracts a centered W_CROP x H_CROP window out of an incoming
// W_TOTAL x H_TOTAL AXI4-Stream video frame (Xilinx video AXI4-Stream
// convention: TUSER = start-of-frame on the first pixel, TLAST = end-
// of-line on the last pixel of each row).
//
// Default parameters give a centered 1920x1080 -> 1280x720 crop
// (320px dropped off each side, 180px dropped off top/bottom).
//
// Purely combinational data path -- every transfer completes in the
// same cycle it's accepted, so there's no internal buffering and
// therefore no risk of violating the "tvalid must stay high until
// tready" rule that a naive registered pipeline can accidentally break.

module axi4s_video_cropper #(
    parameter integer TDATA_WIDTH = 24,
    parameter integer H_TOTAL     = 1920,
    parameter integer V_TOTAL     = 1080,
    parameter integer H_CROP      = 1280,
    parameter integer V_CROP      = 720
)(
    input  wire                     aclk,
    input  wire                     aresetn,

    // Input AXI4-Stream
    input  wire [TDATA_WIDTH-1:0]   s_axis_tdata,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tuser,
    input  wire                     s_axis_tlast,

    // Output AXI4-Stream
    output wire [TDATA_WIDTH-1:0]   m_axis_tdata,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tuser,
    output wire                     m_axis_tlast,
    
    output wire [10:0] debug_col_cnt,
    output wire [10:0] debug_row_cnt
);
    // ------------------------------------------------------------
    // Crop window
    // Input frame : 1920 x 1080
    // Output frame: 1280 x 720
    // Horizontal crop: 320 to 1599
    // Vertical crop  : 180 to 899
    // ------------------------------------------------------------
    localparam integer H_MARGIN = (H_TOTAL - H_CROP) / 2;
    localparam integer V_MARGIN = (V_TOTAL - V_CROP) / 2;
    localparam integer COL_BITS = $clog2(H_TOTAL);
    localparam integer ROW_BITS = $clog2(V_TOTAL);
    // These counters represent the CURRENT input pixel position
    reg [COL_BITS-1:0] col_cnt;
    reg [ROW_BITS-1:0] row_cnt;
    
    assign debug_col_cnt = col_cnt;
    assign debug_row_cnt = row_cnt;
    // ------------------------------------------------------------
    // Crop window detection
    // ------------------------------------------------------------
    wire keep_col;
    wire keep_row;
    wire keep_pixel;

    assign keep_col =
        (col_cnt >= H_MARGIN) &&
        (col_cnt <  H_MARGIN + H_CROP);

    assign keep_row =
        (row_cnt >= V_MARGIN) &&
        (row_cnt <  V_MARGIN + V_CROP);
        
    assign keep_pixel = keep_col && keep_row;
    // ------------------------------------------------------------
    // AXI handshake
    // ------------------------------------------------------------
    // Dropped pixels can always be accepted.
    // Kept pixels must wait for downstream ready.
    assign s_axis_tready = keep_pixel ? m_axis_tready : 1'b1;
    wire fire;
    assign fire = s_axis_tvalid && s_axis_tready;
    // ------------------------------------------------------------
    // Output stream
    // ------------------------------------------------------------
    assign m_axis_tdata  = s_axis_tdata;
    assign m_axis_tvalid = s_axis_tvalid && keep_pixel;
    // First pixel of cropped frame:
    // input coordinate = (row=180, col=320)
    assign m_axis_tuser =
        s_axis_tvalid &&
        keep_pixel &&
        (row_cnt == V_MARGIN) &&
        (col_cnt == H_MARGIN);
    // Last pixel of each cropped line:
    // input coordinate = col 1599
    assign m_axis_tlast =
        s_axis_tvalid &&
        keep_pixel &&
        (col_cnt == H_MARGIN + H_CROP - 1);
    // ------------------------------------------------------------
    // Position counters
    // ------------------------------------------------------------
    always @(posedge aclk) begin
        if (!aresetn) begin
            // Before first pixel, current position is (0,0)
            col_cnt <= 0;
            row_cnt <= 0;
        end
        else if (fire) begin
            // End of line
            if (s_axis_tlast) begin
                col_cnt <= 0;
                if (row_cnt == V_TOTAL - 1)
                    row_cnt <= 0;
                else
                    row_cnt <= row_cnt + 1'b1;
            end
            // Normal pixel
            else begin
                col_cnt <= col_cnt + 1'b1;
            end
            // SOF explicitly resets frame position.
            // This is written last so SOF has priority.
            if (s_axis_tuser) begin
                row_cnt <= 0;
                // Pixel (0,0) is being transferred now.
                // After this transfer, next pixel is (0,1).
                if (s_axis_tlast)
                    col_cnt <= 0;
                else
                    col_cnt <= 1;
            end
        end
    end
endmodule
