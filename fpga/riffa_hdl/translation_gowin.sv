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
  output [C_PCI_DATA_WIDTH-1:0]  TL_TX_DATA,
  output [7:0]                   TL_TX_VALID,
  input                          TL_TX_WAIT,
  output [0:0]                   TL_TX_EOP,
  output [0:0]                   TL_TX_SOP,

  // Interface: Gowin Config
  input [12:0]                   TL_CFG_BUSDEV,

  // Interface: Gowin Flow Control
  input [31:0]                   TL_TX_CPL,

  // Interface: Gowin Interrupt
  input                          APP_MSI_ACK,
  output                         APP_MSI_REQ,
  output                         APP_MSI_EN,
  output [4:0]                   APP_MSI_MSINUM,

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

  // Interface: Flow Control
  output [`SIG_FC_CPLD_W-1:0]    CONFIG_MAX_CPL_DATA, // Receive credit limit for data
  output [`SIG_FC_CPLH_W-1:0]    CONFIG_MAX_CPL_HDR, // Receive credit limit for headers

  // Interface: Interrupt     
  output                         INTR_MSI_RDY, // High when interrupt is able to be sent
  input                          INTR_MSI_REQUEST // High to request interrupt
);

  // {{{ Gowin TX
  assign RX_TLP = TL_RX_DATA;
  assign RX_TLP_VALID = |TL_RX_VALID;
  assign RX_TLP_START_OFFSET = 'b0;
  assign RX_TLP_START_FLAG = TL_RX_SOP;
  assign RX_TLP_END_FLAG = TL_RX_EOP;
  assign RX_TLP_BAR_DECODE = TL_RX_BARDEC;
  logic [2:0] reoff;
  always_comb begin
    case (TL_RX_VALID)
      8'hFF : reoff = 3'b000;
      8'hFE : reoff = 3'b001;
      8'hFC : reoff = 3'b010;
      8'hF8 : reoff = 3'b011;
      8'hF0 : reoff = 3'b100;
      8'hE0 : reoff = 3'b101;
      8'hC0 : reoff = 3'b110;
      8'h80 : reoff = 3'b111; // should at least 32bit valid
      default : reoff = 3'b000; // not posible
    endcase
  end
  assign RX_TLP_END_OFFSET = reoff;
  assign TL_RX_WAIT = RX_TLP_READY;
  // }}}

  // {{{ Gowin RX
  logic rTxStReady;
  logic [7:0] TxExtend;
  assign TxExtend = {8{TX_TLP_VALID}};
  always_ff@(posedge CLK)begin
    rTxStReady <= ~TL_TX_WAIT&|TL_TX_VALID;
  end
  assign TL_TX_DATA = TX_TLP;
  assign TL_TX_SOP = TX_TLP_START_FLAG;
  assign TL_TX_EOP = TX_TLP_END_FLAG;
  assign TX_TLP_READY = rTxStReady; // wait means activate in low
  assign TL_TX_VALID = ((TxExtend>>(7-TX_TLP_START_OFFSET))<<TX_TLP_END_OFFSET);
  assign TL_TX_VALID = TxExtend[7-TX_TLP_START_OFFSET[2:0]:TX_TLP_END_OFFSET[2:0]];
  // }}}

  // {{{ Gowin MSI 
  logic rMsien;
  assign INTR_MSI_RDY = APP_MSI_ACK;
  assign APP_MSI_REQ = INTR_MSI_REQUEST;
  assign APP_MSI_EN = rMsien | INTR_MSI_REQUEST;
  assign APP_MSI_MSINUM = 'b0;
  always_ff@(posedge CLK)begin
    if(!RST_IN)begin
      rMsien <= 1'b0;
    end else if(INTR_MSI_REQUEST) begin
      rMsien <= 1'b1;
    end else if (APP_MSI_ACK) begin
      rMsien <= 1'b0;
    end
  end
  // }}}

  // {{{ Gowin Config
  assign CONFIG_LINK_WIDTH = 6'b000100;
  assign CONFIG_LINK_RATE = 4'b0010;
  assign CONFIG_MAX_PAYLOAD_SIZE  = 3'b010;
  assign CONFIG_MAX_READ_REQUEST_SIZE = 3'b010;
  assign CONFIG_COMPLETER_ID = {TL_CFG_BUSDEV,3'b000};
  assign CONFIG_BUS_MASTER_ENABLE = 1'b1;
  assign CONFIG_INTERRUPT_MSIENABLE = 1'b1;
  assign CONFIG_CPL_BOUNDARY_SEL = 1'b1;
  // }}}

  // {{{ Gowin Flow Controller
  assign CONFIG_MAX_CPL_DATA = TL_TX_CPL[12:0];
  assign CONFIG_MAX_CPL_HDR = TL_TX_CPL[24:16];
  // }}}

endmodule // translation_layer

