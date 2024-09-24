`include "trellis.vh"
`include "riffa.vh"
`include "tlp.vh"
`include "gowin.vh"

module GW5ASTGen2_x4lf256
    #(
    parameter C_NUM_CHNL = 1,
    parameter C_NUM_LANES = 4,
    parameter C_PCI_DATA_WIDTH = 256,
    parameter C_MAX_PAYLOAD_BYTES = 1024,
    parameter C_LOG_NUM_TAGS = 5
)(
    input clk,
    input rst_n,
    output [3:0] LED
);

    logic tl_rx_sop;
    logic tl_rx_eop;
    logic [C_PCI_DATA_WIDTH-1:0]tl_rx_data;
    logic tl_rx_wait;
    logic [7:0]tl_rx_valid;
    logic [5:0]tl_rx_bardec;

    logic tl_tx_sop;
    logic tl_tx_eop;
    logic [C_PCI_DATA_WIDTH-1:0]tl_tx_data;
    logic [7:0]tl_tx_valid;
    logic tl_tx_wait;

    logic [31:0]tl_tx_cpl;
    logic [12:0]tl_cfg_busdev;

    logic msi_en;
    logic msi_req;
    logic msi_ack;
    logic msinum;

    SerDes_Top pcie_serder_top(
        .PCIE_Controller_Top_pcie_rstn_i(rst_n), //input PCIE_Controller_Top_pcie_rstn_i
        .PCIE_Controller_Top_pcie_tl_clk_i(clk), //input PCIE_Controller_Top_pcie_tl_clk_i
        .PCIE_Controller_Top_pcie_linkup_o(), //output PCIE_Controller_Top_pcie_linkup_o

        // rx data
        .PCIE_Controller_Top_pcie_tl_rx_sop_o(tl_rx_sop), //output PCIE_Controller_Top_pcie_tl_rx_sop_o
        .PCIE_Controller_Top_pcie_tl_rx_eop_o(tl_rx_eop), //output PCIE_Controller_Top_pcie_tl_rx_eop_o
        .PCIE_Controller_Top_pcie_tl_rx_data_o(tl_rx_data), //output [255:0] PCIE_Controller_Top_pcie_tl_rx_data_o
        .PCIE_Controller_Top_pcie_tl_rx_valid_o(tl_rx_valid), //output [7:0] PCIE_Controller_Top_pcie_tl_rx_valid_o
        .PCIE_Controller_Top_pcie_tl_rx_bardec_o(tl_rx_bardec), //output [5:0] PCIE_Controller_Top_pcie_tl_rx_bardec_o
        .PCIE_Controller_Top_pcie_tl_rx_err_o(), //output [7:0] PCIE_Controller_Top_pcie_tl_rx_err_o
        .PCIE_Controller_Top_pcie_tl_rx_wait_i(tl_rx_wait), //input PCIE_Controller_Top_pcie_tl_rx_wait_i
        .PCIE_Controller_Top_pcie_tl_rx_masknp_i(0), //input PCIE_Controller_Top_pcie_tl_rx_masknp_i

        // tx data
        .PCIE_Controller_Top_pcie_tl_tx_sop_i(tl_tx_sop), //input PCIE_Controller_Top_pcie_tl_tx_sop_i
        .PCIE_Controller_Top_pcie_tl_tx_eop_i(tl_tx_eop), //input PCIE_Controller_Top_pcie_tl_tx_eop_i
        .PCIE_Controller_Top_pcie_tl_tx_data_i(tl_tx_data), //input [255:0] PCIE_Controller_Top_pcie_tl_tx_data_i
        .PCIE_Controller_Top_pcie_tl_tx_valid_i(tl_tx_valid), //input [7:0] PCIE_Controller_Top_pcie_tl_tx_valid_i
        .PCIE_Controller_Top_pcie_tl_tx_wait_o(tl_tx_wait), //output PCIE_Controller_Top_pcie_tl_tx_wait_o

        // config
        .PCIE_Controller_Top_pcie_ltssm_o(), //output [4:0] PCIE_Controller_Top_pcie_ltssm_o
        .PCIE_Controller_Top_pcie_tl_tx_creditsp_o(), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditsp_o
        .PCIE_Controller_Top_pcie_tl_tx_creditsnp_o(), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditsnp_o
        .PCIE_Controller_Top_pcie_tl_tx_creditscpl_o(tl_tx_cpl), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditscpl_o
        .PCIE_Controller_Top_pcie_tl_cfg_busdev_o(tl_cfg_busdev), //output [12:0] PCIE_Controller_Top_pcie_tl_cfg_busdev_o

        // msi 
        .PCIE_Controller_Top_pcie_tl_int_status_i(msi_en), //input PCIE_Controller_Top_pcie_tl_int_status_i
        .PCIE_Controller_Top_pcie_tl_int_req_i(msi_req), //input PCIE_Controller_Top_pcie_tl_int_req_i
        .PCIE_Controller_Top_pcie_tl_int_msinum_i(msinum), //input [4:0] PCIE_Controller_Top_pcie_tl_int_msinum_i
        .PCIE_Controller_Top_pcie_tl_int_ack_o(msi_ack), //output PCIE_Controller_Top_pcie_tl_int_ack_o
    );

    wire                               rst_out;
    wire [C_NUM_CHNL-1:0]              chnl_rx_clk; 
    wire [C_NUM_CHNL-1:0]              chnl_rx; 
    wire [C_NUM_CHNL-1:0]              chnl_rx_ack; 
    wire [C_NUM_CHNL-1:0]              chnl_rx_last; 
    wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_rx_len; 
    wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_rx_off; 
    wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]   chnl_rx_data; 
    wire [C_NUM_CHNL-1:0]                      chnl_rx_data_valid; 
    wire [C_NUM_CHNL-1:0]                      chnl_rx_data_ren;

    wire [C_NUM_CHNL-1:0]                      chnl_tx_clk; 
    wire [C_NUM_CHNL-1:0]                      chnl_tx; 
    wire [C_NUM_CHNL-1:0]                      chnl_tx_ack;
    wire [C_NUM_CHNL-1:0]                      chnl_tx_last; 
    wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_tx_len; 
    wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_tx_off; 
    wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]   chnl_tx_data; 
    wire [C_NUM_CHNL-1:0]                      chnl_tx_data_valid; 
    wire [C_NUM_CHNL-1:0]                      chnl_tx_data_ren;

    GW5AST_wrapper #(
        .C_NUM_CHNL(C_NUM_CHNL),
        .C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH),
        .C_MAX_PAYLOAD_BYTES(C_MAX_PAYLOAD_BYTES),
        .C_LOG_NUM_TAGS(C_LOG_NUM_TAGS),
        .C_FPGA_ID()
    ) GW5AST_wrapper_instance (
        .RST_OUT                       (rst_out),
        .CHNL_RX                       (chnl_rx[C_NUM_CHNL-1:0]),
        .CHNL_RX_LAST                  (chnl_rx_last[C_NUM_CHNL-1:0]),
        .CHNL_RX_LEN                   (chnl_rx_len[(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]),
        .CHNL_RX_OFF                   (chnl_rx_off[(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0]),
        .CHNL_RX_DATA                  (chnl_rx_data[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]),
        .CHNL_RX_DATA_VALID            (chnl_rx_data_valid[C_NUM_CHNL-1:0]),
        .CHNL_RX_CLK                   (chnl_rx_clk[C_NUM_CHNL-1:0]),
        .CHNL_RX_ACK                   (chnl_rx_ack[C_NUM_CHNL-1:0]),
        .CHNL_RX_DATA_REN              (chnl_rx_data_ren[C_NUM_CHNL-1:0]),

        .CHNL_TX_ACK                   (chnl_tx_ack[C_NUM_CHNL-1:0]),
        .CHNL_TX_DATA_REN              (chnl_tx_data_ren[C_NUM_CHNL-1:0]),
        .CHNL_TX_CLK                   (chnl_tx_clk[C_NUM_CHNL-1:0]),
        .CHNL_TX                       (chnl_tx[C_NUM_CHNL-1:0]),
        .CHNL_TX_LAST                  (chnl_tx_last[C_NUM_CHNL-1:0]),
        .CHNL_TX_LEN                   (chnl_tx_len[(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]),
        .CHNL_TX_OFF                   (chnl_tx_off[(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0]),
        .CHNL_TX_DATA                  (chnl_tx_data[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]),
        .CHNL_TX_DATA_VALID            (chnl_tx_data_valid[C_NUM_CHNL-1:0]),

        .tl_rx_sop(tl_rx_sop),
        .tl_rx_eop(tl_rx_eop),
        .tl_rx_data(tl_rx_data),
        .tl_rx_valid(tl_rx_valid),
        .tl_rx_bardec(tl_rx_bardec),
        .tl_rx_wait(tl_rx_wait),
        .tl_tx_sop(tl_tx_sop),
        .tl_tx_eop(tl_tx_eop),
        .tl_tx_data(tl_tx_data),
        .tl_tx_valid(tl_tx_valid),
        .tl_tx_wait(tl_tx_wait),
        .tl_tx_cpl(tl_tx_cpl),
        .tl_cfg_busdev(tl_cfg_busdev),
        .msi_en(msi_en),
        .msi_req(msi_req),
        .msinum(msinum),
        .msi_ack(msi_ack)
    );

    genvar                                     chnl;
    generate
        for (chnl = 0; chnl < C_NUM_CHNL; chnl = chnl + 1) begin : test_channels
            chnl_tester 
                    #(
                      .C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH)
                      ) 
            module1 
                    (.CLK(clk),
                     .RST(rst_out),    // riffa_reset includes riffa_endpoint resets
                     // Rx interface
                     .CHNL_RX_CLK(chnl_rx_clk[chnl]), 
                     .CHNL_RX(chnl_rx[chnl]), 
                     .CHNL_RX_ACK(chnl_rx_ack[chnl]), 
                     .CHNL_RX_LAST(chnl_rx_last[chnl]), 
                     .CHNL_RX_LEN(chnl_rx_len[32*chnl +:32]), 
                     .CHNL_RX_OFF(chnl_rx_off[31*chnl +:31]), 
                     .CHNL_RX_DATA(chnl_rx_data[C_PCI_DATA_WIDTH*chnl +:C_PCI_DATA_WIDTH]), 
                     .CHNL_RX_DATA_VALID(chnl_rx_data_valid[chnl]), 
                     .CHNL_RX_DATA_REN(chnl_rx_data_ren[chnl]),
                     // Tx interface
                     .CHNL_TX_CLK(chnl_tx_clk[chnl]), 
                     .CHNL_TX(chnl_tx[chnl]), 
                     .CHNL_TX_ACK(chnl_tx_ack[chnl]), 
                     .CHNL_TX_LAST(chnl_tx_last[chnl]), 
                     .CHNL_TX_LEN(chnl_tx_len[32*chnl +:32]), 
                     .CHNL_TX_OFF(chnl_tx_off[31*chnl +:31]), 
                     .CHNL_TX_DATA(chnl_tx_data[C_PCI_DATA_WIDTH*chnl +:C_PCI_DATA_WIDTH]), 
                     .CHNL_TX_DATA_VALID(chnl_tx_data_valid[chnl]), 
                     .CHNL_TX_DATA_REN(chnl_tx_data_ren[chnl])
                     );    
        end
    endgenerate
endmodule
