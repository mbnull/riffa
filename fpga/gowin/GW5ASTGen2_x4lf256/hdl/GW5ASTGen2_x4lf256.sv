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



    SerDes_Top pcie_serder_top(
        .PCIE_Controller_Top_pcie_tl_rx_sop_o(PCIE_Controller_Top_pcie_tl_rx_sop_o_o), //output PCIE_Controller_Top_pcie_tl_rx_sop_o
        .PCIE_Controller_Top_pcie_tl_rx_eop_o(PCIE_Controller_Top_pcie_tl_rx_eop_o_o), //output PCIE_Controller_Top_pcie_tl_rx_eop_o
        .PCIE_Controller_Top_pcie_tl_rx_data_o(PCIE_Controller_Top_pcie_tl_rx_data_o_o), //output [255:0] PCIE_Controller_Top_pcie_tl_rx_data_o
        .PCIE_Controller_Top_pcie_tl_rx_valid_o(PCIE_Controller_Top_pcie_tl_rx_valid_o_o), //output [7:0] PCIE_Controller_Top_pcie_tl_rx_valid_o
        .PCIE_Controller_Top_pcie_tl_rx_bardec_o(PCIE_Controller_Top_pcie_tl_rx_bardec_o_o), //output [5:0] PCIE_Controller_Top_pcie_tl_rx_bardec_o
        .PCIE_Controller_Top_pcie_tl_rx_err_o(PCIE_Controller_Top_pcie_tl_rx_err_o_o), //output [7:0] PCIE_Controller_Top_pcie_tl_rx_err_o
        .PCIE_Controller_Top_pcie_tl_tx_wait_o(PCIE_Controller_Top_pcie_tl_tx_wait_o_o), //output PCIE_Controller_Top_pcie_tl_tx_wait_o
        .PCIE_Controller_Top_pcie_tl_int_ack_o(PCIE_Controller_Top_pcie_tl_int_ack_o_o), //output PCIE_Controller_Top_pcie_tl_int_ack_o
        .PCIE_Controller_Top_pcie_ltssm_o(PCIE_Controller_Top_pcie_ltssm_o_o), //output [4:0] PCIE_Controller_Top_pcie_ltssm_o
        .PCIE_Controller_Top_pcie_tl_tx_creditsp_o(PCIE_Controller_Top_pcie_tl_tx_creditsp_o_o), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditsp_o
        .PCIE_Controller_Top_pcie_tl_tx_creditsnp_o(PCIE_Controller_Top_pcie_tl_tx_creditsnp_o_o), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditsnp_o
        .PCIE_Controller_Top_pcie_tl_tx_creditscpl_o(PCIE_Controller_Top_pcie_tl_tx_creditscpl_o_o), //output [31:0] PCIE_Controller_Top_pcie_tl_tx_creditscpl_o
        .PCIE_Controller_Top_pcie_tl_cfg_busdev_o(PCIE_Controller_Top_pcie_tl_cfg_busdev_o_o), //output [12:0] PCIE_Controller_Top_pcie_tl_cfg_busdev_o
        .PCIE_Controller_Top_pcie_linkup_o(PCIE_Controller_Top_pcie_linkup_o_o), //output PCIE_Controller_Top_pcie_linkup_o
        .PCIE_Controller_Top_pcie_rstn_i(PCIE_Controller_Top_pcie_rstn_i_i), //input PCIE_Controller_Top_pcie_rstn_i
        .PCIE_Controller_Top_pcie_tl_clk_i(PCIE_Controller_Top_pcie_tl_clk_i_i), //input PCIE_Controller_Top_pcie_tl_clk_i
        .PCIE_Controller_Top_pcie_tl_rx_wait_i(PCIE_Controller_Top_pcie_tl_rx_wait_i_i), //input PCIE_Controller_Top_pcie_tl_rx_wait_i
        .PCIE_Controller_Top_pcie_tl_rx_masknp_i(PCIE_Controller_Top_pcie_tl_rx_masknp_i_i), //input PCIE_Controller_Top_pcie_tl_rx_masknp_i
        .PCIE_Controller_Top_pcie_tl_tx_sop_i(PCIE_Controller_Top_pcie_tl_tx_sop_i_i), //input PCIE_Controller_Top_pcie_tl_tx_sop_i
        .PCIE_Controller_Top_pcie_tl_tx_eop_i(PCIE_Controller_Top_pcie_tl_tx_eop_i_i), //input PCIE_Controller_Top_pcie_tl_tx_eop_i
        .PCIE_Controller_Top_pcie_tl_tx_data_i(PCIE_Controller_Top_pcie_tl_tx_data_i_i), //input [255:0] PCIE_Controller_Top_pcie_tl_tx_data_i
        .PCIE_Controller_Top_pcie_tl_tx_valid_i(PCIE_Controller_Top_pcie_tl_tx_valid_i_i), //input [7:0] PCIE_Controller_Top_pcie_tl_tx_valid_i
        .PCIE_Controller_Top_pcie_tl_int_status_i(PCIE_Controller_Top_pcie_tl_int_status_i_i), //input PCIE_Controller_Top_pcie_tl_int_status_i
        .PCIE_Controller_Top_pcie_tl_int_req_i(PCIE_Controller_Top_pcie_tl_int_req_i_i), //input PCIE_Controller_Top_pcie_tl_int_req_i
        .PCIE_Controller_Top_pcie_tl_int_msinum_i(PCIE_Controller_Top_pcie_tl_int_msinum_i_i) //input [4:0] PCIE_Controller_Top_pcie_tl_int_msinum_i
    );

    GW5AST_wrapper riffa();

    logic rx_clk;

    logic channel_rx;
    logic channel_rx_ack;
    logic channel_rx_last;
    logic channel_rx_len;
    logic channel_rx_off;
    logic channel_rx_data;
    logic channeL_rx_data_valid;
    logic channel_rx_data_ren;

    // user logic
    chnl_tester
    #(
    .C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH)
    )
    module1
    (.CLK(clk),
        .RST(rst_n), // riffa_reset includes riffa_endpoint resets
        // Rx interface
        .CHNL_RX_CLK(rx_clk),
        .CHNL_RX(channel_rx),
        .CHNL_RX_ACK(channel_rx_ack),
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
endmodule