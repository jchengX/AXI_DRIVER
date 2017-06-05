///////////////////////////////////////////////////////////////////////////////////////////
// File : axi_if.sv
// Date : 2017/06/03
// Description : axi virtual interface which is a connection pool interface for DUT and TB
//////////////////////////////////////////////////////////////////////////////////////////

interface axi_if #(
		    int AXI_ID_WIDTH = 4,
		    int AXI_ADDR_WIDTH= 32,
       		    int AXI_REG_WITH = 4,
		    int AXI_DATA_WIDTH = 32,
		    int AXI_LEN_WIDTH = 8,
		    int AXI_SIZE_WIDTH= 3,
		    int AXI_BURST_WIDTH = 2,
		    int AXI_CACHE_WIDTH = 4,
		    int AXI_PROT_WIDTH = 3,
		    int AXI_QOS_WIDTH = 4,
		    int AXI_STRB_WIDTH= 4,
		    int AXI_RESP_WIDTH= 2,
       		    int AXI_LOCK_WIDTH  = 1,
       		    int AXI_VALID_WIDTH = 1,
       		    int AXI_READY_WIDTH = 1,
       		    int AXI_LAST_WIDTH  = 1
		   )
		(input ACLK, input ARESET_N);//define axi interface

    // AXI address write channel
    logic [AXI_ID_WIDTH-1:0]		AWID;
    logic [AXI_ADDR_WIDTH-1:0]		AWADDR;
    logic [AXI_REG_WITH-1:0]    	AWREG;
    logic [AXI_LEN_WIDTH-1:0]		AWLEN;
    logic [AXI_SIZE_WIDTH-1:0]		AWSIZE;
    logic [AXI_BURST_WIDTH-1:0]		AWBURST;
    logic [AXI_LOCK_WIDTH-1:0]		AWLOCK;
    logic [AXI_CACHE_WIDTH-1:0]		AWCACHE;
    logic [AXI_PROT_WIDTH-1:0]		AWPROT;
    logic [AXI_QOS_WIDTH-1:0]		AWQOS;
    logic [AXI_VALID_WIDTH-1:0]		AWVALID;
    logic [AXI_READY_WIDTH-1:0]		AWREADY;

    // AXI data write channel
    logic [AXI_ID_WIDTH-1:-0]		WID;
    logic [AXI_DATA_WIDTH-1:0]		WDATA;
    logic [AXI_STRB_WIDTH-1:0]		WSTRB;
    logic [AXI_LAST_WIDTH-1:0]		WLAST;
    logic [AXI_VALID_WIDTH-1:0]		WVALID;
    logic [AXI_READY_WIDTH-1:0]		WREADY;

    // AXI response write channel
    logic [AXI_ID_WIDTH-1:0]		BID;
    logic [AXI_RESP_WIDTH-1:0]		BRESP;
    logic [AXI_VALID_WIDTH-1:0]		BVALID;
    logic [AXI_READY_WIDTH-1:0]		BREADY;

    // AXI address read channel
    logic [AXI_ID_WIDTH-1:0]		ARID;
    logic [AXI_ADDR_WIDTH-1:0]		ARADDR;
    logic [AXI_REG_WITH-1:0]     	ARREG;
    logic [AXI_LEN_WIDTH-1:0]		ARLEN;
    logic [AXI_SIZE_WIDTH-1:0]		ARSIZE;
    logic [AXI_BURST_WIDTH-1:0]		ARBURST;
    logic [AXI_LOCK_WIDTH-1:0]		ARLOCK;
    logic [AXI_CACHE_WIDTH-1:0]		ARCACHE;
    logic [AXI_PROT_WIDTH-1:0]		ARPROT;
    logic [AXI_QOS_WIDTH-1:0]		ARQOS;
    logic [AXI_VALID_WIDTH-1:0]		ARVALID;
    logic [AXI_READY_WIDTH-1:0]		ARREADY;

    // AXI data read channel
    logic [AXI_ID_WIDTH-1:0]		RID;
    logic [AXI_DATA_WIDTH-1:0]		RDATA;
    logic [AXI_RESP_WIDTH-1:0]		RRESP;
    logic [AXI_LAST_WIDTH-1:0]		RLAST;
    logic [AXI_VALID_WIDTH-1:0]		RVALID;
    logic [AXI_READY_WIDTH-1:0]		RREADY;

	

	modport slave(input 	AWID,
		      input	AWADDR,
                      input     AWREG,
                      input     AWLEN,
                      input     AWSIZE,
                      input     AWBURST,
                      input     AWLOCK,
                      input     AWCACHE,
                      input     AWPROT,
                      input     AWQOS,
                      input     AWVALID,
                      output    AWREADY,
                              
                      input     WID,
                      input     WDATA,
                      input     WSTRB,
                      input     WLAST,
                      input     WVALID,
                      output    WREADY,
                                    
                      output    BID,
                      output    BRESP,
                      output    BVALID,
                      input     BREADY,
                 
                      input     ARID,
                      input     ARADDR,
                      input     ARREG,
                      input     ARLEN,
                      input     ARSIZE,
                      input     ARBURST,
                      input     ARLOCK,
                      input     ARCACHE,
                      input     ARPROT,
                      input     ARQOS,
                      input     ARVALID,
                      output    ARREADY,
                                
                      output    RID,
                      output    RDATA,
		      output    RRESP,
		      output    RLAST,
                      output    RVALID,
		      input     RREADY
			);
	modport master(output 	AWID,
		      output    AWADDR,
                      output    AWREG,
                      output    AWLEN,
                      output    AWSIZE,
                      output    AWBURST,
                      output    AWLOCK,
                      output    AWCACHE,
                      output    AWPROT,
                      output    AWQOS,
                      output    AWVALID,
                      input     AWREADY,
                              
                      output    WID,
                      output    WDATA,
                      output    WSTRB,
                      output    WLAST,
                      output    WVALID,
                      input     WREADY,
                                    
                      input     BID,
                      input     BRESP,
                      input     BVALID,
                      output    BREADY,
                 
                      output    ARID,
                      output    ARADDR,
                      output    ARREG,
                      output    ARLEN,
                      output    ARSIZE,
                      output    ARBURST,
                      output    ARLOCK,
                      output    ARCACHE,
                      output    ARPROT,
                      output    ARQOS,
                      output    ARVALID,
                      input     ARREADY,
                                 
                      input     RID,
                      input     RDATA,
		      input     RRESP,
		      input     RLAST,
                      input     RVALID,
		      output    RREADY
			);

`ifdef SIMULATION
	default clocking cb_drv @(posedge ACLK);
		input AWREADY,WREADY,...;
		output AWID,AWADDR,...;
	endclocking:cb_drv
	
	clocking cb_mon @(posedge ACLK);
		input AWID,AWADDR,...;
	endclocking:cb_mon

	clocking cb_recv @(posedge ACLK);
		input AWID,AWADDR,...;
		output AWREADY,WREADY,...;
	endclocking:cb_recv
	
	modport driver(
		input ACLK,ARESET_N,
		input cb_drv
		);
	modport monitor(
		input ACLK,ARESET_N,
		input cb_mon
		);
	modport reciver(
		input ACLK,ARESET_N,
		input cb_recv
		);

endinterface:axi_if 
