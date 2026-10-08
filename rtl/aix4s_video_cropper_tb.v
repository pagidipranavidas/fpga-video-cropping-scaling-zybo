`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2026 15:51:05
// Design Name: 
// Module Name: aix4s_video_cropper_tb
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


module axi4s_video_cropper_tb;

    parameter TDATA_WIDTH = 24;
    parameter H_TOTAL     = 1920;
    parameter V_TOTAL     = 1080;
    parameter H_CROP      = 1280;
    parameter V_CROP      = 720;
    // Clock and reset
    reg aclk;
    reg aresetn;
    // Input AXI4-Stream
    reg  [TDATA_WIDTH-1:0] s_axis_tdata;
    reg                    s_axis_tvalid;
    wire                   s_axis_tready;
    reg                    s_axis_tuser;
    reg                    s_axis_tlast;
    // Output AXI4-Stream
    wire [TDATA_WIDTH-1:0] m_axis_tdata;
    wire                   m_axis_tvalid;
    reg                    m_axis_tready;
    wire                   m_axis_tuser;
    wire                   m_axis_tlast;
    // DUT
    axi4s_video_cropper #(
        .TDATA_WIDTH(TDATA_WIDTH),
        .H_TOTAL    (H_TOTAL),
        .V_TOTAL    (V_TOTAL),
        .H_CROP     (H_CROP),
        .V_CROP     (V_CROP)
    ) dut (
        .aclk          (aclk),
        .aresetn       (aresetn),

        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tuser  (s_axis_tuser),
        .s_axis_tlast  (s_axis_tlast),

        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tuser  (m_axis_tuser),
        .m_axis_tlast  (m_axis_tlast)
    );

    initial begin
        aclk = 0;
        forever #4.0185 aclk = ~aclk;
    end
    
    integer row;
    integer col;
    integer frame;
    // Send  1920 x 1080 frame
    initial begin
        // Initial values
        aresetn       = 0;
        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tuser  = 0;
        s_axis_tlast  = 0;
        // Output always ready
        m_axis_tready = 1;
        // Reset
        repeat(5) @(posedge aclk);
        // Release reset
        @(negedge aclk);
        aresetn = 1;
        // Send frame
    end

initial begin

    aresetn       = 0;
    s_axis_tdata  = 0;
    s_axis_tvalid = 0;
    s_axis_tuser  = 0;
    s_axis_tlast  = 0;
    m_axis_tready = 1;

    repeat(5) @(posedge aclk);

    @(negedge aclk);
    aresetn = 1;

    // Send multiple frames
    for (frame = 0; frame < 12; frame = frame + 1) begin
        for (row = 0; row < V_TOTAL; row = row + 1) begin
            for (col = 0; col < H_TOTAL; col = col + 1) begin
                @(negedge aclk);
                while (!s_axis_tready)
                    @(negedge aclk);
                s_axis_tvalid = 1;
                s_axis_tdata = {row[11:0], col[11:0]};

                if ((row == 0) && (col == 0))
                    s_axis_tuser = 1;
                else
                    s_axis_tuser = 0;
                if (col == H_TOTAL - 1)
                    s_axis_tlast = 1;
                else
                    s_axis_tlast = 0;
                @(posedge aclk);
            end
        end
    end
    @(negedge aclk);
    s_axis_tvalid = 0;
    s_axis_tuser  = 0;
    s_axis_tlast  = 0;
    #100_000_000 $finish;
end
endmodule