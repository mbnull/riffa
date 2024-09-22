`timescale 1ns/1ps

module translation_gowin
    #(
  parameter C_PCI_DATA_WIDTH = 256
)
    (
  input                          CLK,
  input                          RST_IN,

  // Interface: Gowin RX 
  input [C_PCI_DATA_WIDTH-1:0]   TL_RX_DATA,
  input [0:0]                    TL_RX_SOP,
  input [0:0]                    TL_RX_EOP,
  input [7:0]                    TL_RX_VALID,
  input [7:0]                    TL_RX_BARDEC,
  output                         TL_RX_WAIT,


  // Interface: Gowin TX
  output [C_PCI_DATA_WIDTH-1:0]  TX_ST_DATA,
  output [0:0]                   TX_ST_VALID,
  input                          TX_ST_READY,
  output [0:0]                   TX_ST_EOP,
  output [0:0]                   TX_ST_SOP,
  output [0:0]                   TX_ST_EMPTY,

  // Interface: Altera Config
  //  input [`SIG_CFG_CTL_W-1:0]     TL_CFG_CTL,
  //  input [`SIG_CFG_ADD_W-1:0]     TL_CFG_ADD,
  //  input [`SIG_CFG_STS_W-1:0]     TL_CFG_STS,

  // Interface: Altera Flow Control
  //  input [`SIG_FC_CPLH_W-1:0]     KO_CPL_SPC_HEADER,
  //  input [`SIG_FC_CPLD_W-1:0]     KO_CPL_SPC_DATA,

  // Interface: Gowin Interrupt
  input                          APP_MSI_ACK,
  output                         APP_MSI_REQ,

  // Interface: RX Classic
  output [C_PCI_DATA_WIDTH-1:0]            RX_TLP,
  output                                   RX_TLP_VALID,
  output                                   RX_TLP_START_FLAG,
  output [clog2s(C_PCI_DATA_WIDTH/32)-1:0] RX_TLP_START_OFFSET,
  output                                   RX_TLP_END_FLAG,
  output [clog2s(C_PCI_DATA_WIDTH/32)-1:0] RX_TLP_END_OFFSET,
  output [`SIG_BARDECODE_W-1:0]            RX_TLP_BAR_DECODE,
  input                                    RX_TLP_READY,

  // Interface: TX Classic
  output                         TX_TLP_READY,
  input [C_PCI_DATA_WIDTH-1:0]   TX_TLP,
  input                          TX_TLP_VALID,
  input                          TX_TLP_START_FLAG,
  input [`SIG_OFFSET_W-1:0]      TX_TLP_START_OFFSET,
  input                          TX_TLP_END_FLAG,
  input [`SIG_OFFSET_W-1:0]      TX_TLP_END_OFFSET,

  // Interface: Configuration
  output [`SIG_CPLID_W-1:0]      CONFIG_COMPLETER_ID,
  output                         CONFIG_BUS_MASTER_ENABLE,
  output [`SIG_LINKWIDTH_W-1:0]  CONFIG_LINK_WIDTH,
  output [`SIG_LINKRATE_W-1:0]   CONFIG_LINK_RATE,
  output [`SIG_MAXREAD_W-1:0]    CONFIG_MAX_READ_REQUEST_SIZE,
  output [`SIG_MAXPAYLOAD_W-1:0] CONFIG_MAX_PAYLOAD_SIZE,
  output                         CONFIG_INTERRUPT_MSIENABLE,
  output                         CONFIG_CPL_BOUNDARY_SEL,
  output [`SIG_FC_CPLD_W-1:0]    CONFIG_MAX_CPL_DATA, // Receive credit limit for data
  output [`SIG_FC_CPLH_W-1:0]    CONFIG_MAX_CPL_HDR, // Receive credit limit for headers

  // Interface: Interrupt     
  output                         INTR_MSI_RDY, // High when interrupt is able to be sent
  input                          INTR_MSI_REQUEST // High to request interrupt
);

  assign CONFIG_LINK_WIDTH = 6'b000100;
  assign CONFIG_LINK_RATE = 4'b0010;
  assign CONFIG_MAX_PAYLOAD_SIZE  = 3'b010;

  assign RX_TLP = TL_RX_DATA;
  assign RX_TLP_VALID = |TL_RX_VALID;
  assign RX_TLP_START_OFFSET = 'b0;
  assign RX_TLP_START_FLAG = TL_RX_SOP;
  assign RX_TLP_END_FLAG = TL_RX_EOP;
  assign RX_TLP_BAR_DECODE = TL_RX_BARDEC;
  always_comb begin
    case (TL_RX_VALID)
      8'hFF : RX_TLP_END_OFFSET = 3'b000;
      8'hFE : RX_TLP_END_OFFSET = 3'b001;
      8'hFC : RX_TLP_END_OFFSET = 3'b010;
      8'hF8 : RX_TLP_END_OFFSET = 3'b011;
      8'hF0 : RX_TLP_END_OFFSET = 3'b100;
      8'hE0 : RX_TLP_END_OFFSET = 3'b101;
      8'hC0 : RX_TLP_END_OFFSET = 3'b110;
      8'h80 : RX_TLP_END_OFFSET = 3'b111; // should at least 32bit valid
      default : RX_TLP_END_OFFSET = 3'b000; // not posible
    endcase
  end
  assign TL_RX_WAIT = RX_TLP_READY;

endmodule // translation_layer

