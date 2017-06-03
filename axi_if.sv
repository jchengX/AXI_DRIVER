///////////////////////////////////////////////////////////////////////////////////////////
// File : axi_vif.sv
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
    logic [AXI_ID_WIDTH-1:0]		AXI_AWID;
    logic [AXI_ADDR_WIDTH-1:0]		AXI_AWADDR;
    logic [AXI_REG_WITH-1:0]    	AXI_AWREG;
    logic [AXI_LEN_WIDTH-1:0]		AXI_AWLEN;
    logic [AXI_SIZE_WIDTH-1:0]		AXI_AWSIZE;
    logic [AXI_BURST_WIDTH-1:0]		AXI_AWBURST;
    logic [AXI_LOCK_WIDTH-1:0]		AXI_AWLOCK;
    logic [AXI_CACHE_WIDTH-1:0]		AXI_AWCACHE;
    logic [AXI_PROT_WIDTH-1:0]		AXI_AWPROT;
    logic [AXI_QOS_WIDTH-1:0]		AXI_AWQOS;
    logic [AXI_VALID_WIDTH-1:0]		AXI_AWVALID;
    logic [AXI_READY_WIDTH-1:0]		AXI_AWREADY;

    // AXI data write channel
    logic [AXI_ID_WIDTH-1:-0]		AXI_WID;
    logic [AXI_DATA_WIDTH-1:0]		AXI_WDATA;
    logic [AXI_STRB_WIDTH-1:0]		AXI_WSTRB;
    logic [AXI_LAST_WIDTH-1:0]		AXI_WLAST;
    logic [AXI_VALID_WIDTH-1:0]		AXI_WVALID;
    logic [AXI_READY_WIDTH-1:0]		AXI_WREADY;

    // AXI response write channel
    logic [AXI_ID_WIDTH-1:0]		AXI_BID;
    logic [AXI_RESP_WIDTH-1:0]		AXI_BRESP;
    logic [AXI_VALID_WIDTH-1:0]		AXI_BVALID;
    logic [AXI_READY_WIDTH-1:0]		AXI_BREADY;

    // AXI address read channel
    logic [AXI_ID_WIDTH-1:0]		AXI_ARID;
    logic [AXI_ADDR_WIDTH-1:0]		AXI_ARADDR;
    logic [AXI_REG_WITH-1:0]     	AXI_ARREG;
    logic [AXI_LEN_WIDTH-1:0]		AXI_ARLEN;
    logic [AXI_SIZE_WIDTH-1:0]		AXI_ARSIZE;
    logic [AXI_BURST_WIDTH-1:0]		AXI_ARBURST;
    logic [AXI_LOCK_WIDTH-1:0]		AXI_ARLOCK;
    logic [AXI_CACHE_WIDTH-1:0]		AXI_ARCACHE;
    logic [AXI_PROT_WIDTH-1:0]		AXI_ARPROT;
    logic [AXI_QOS_WIDTH-1:0]		AXI_ARQOS;
    logic [AXI_VALID_WIDTH-1:0]		AXI_ARVALID;
    logic [AXI_READY_WIDTH-1:0]		AXI_ARREADY;

    // AXI data read channel
    logic [AXI_ID_WIDTH-1:0]		AXI_RID;
    logic [AXI_DATA_WIDTH-1:0]		AXI_RDATA;
    logic [AXI_RESP_WIDTH-1:0]		AXI_RRESP;
    logic [AXI_LAST_WIDTH-1:0]		AXI_RLAST;
    logic [AXI_VALID_WIDTH-1:0]		AXI_RVALID;
    logic [AXI_READY_WIDTH-1:0]		AXI_RREADY;

	

	modport slave(input 	AXI_AWID,
		      input	AXI_AWADDR,
                      input     AXI_AWREG,
                      input     AXI_AWLEN,
                      input     AXI_AWSIZE,
                      input     AXI_AWBURST,
                      input     AXI_AWLOCK,
                      input     AXI_AWCACHE,
                      input     AXI_AWPROT,
                      input     AXI_AWQOS,
                      input     AXI_AWVALID,
                      output    AXI_AWREADY,
                              
                      input     AXI_WID,
                      input     AXI_WDATA,
                      input     AXI_WSTRB,
                      input     AXI_WLAST,
                      input     AXI_WVALID,
                      output    AXI_WREADY,
                                    
                      output    AXI_BID,
                      output    AXI_BRESP,
                      output    AXI_BVALID,
                      input     AXI_BREADY,
                 
                      input     AXI_ARID,
                      input     AXI_ARADDR,
                      input     AXI_ARREG,
                      input     AXI_ARLEN,
                      input     AXI_ARSIZE,
                      input     AXI_ARBURST,
                      input     AXI_ARLOCK,
                      input     AXI_ARCACHE,
                      input     AXI_ARPROT,
                      input     AXI_ARQOS,
                      input     AXI_ARVALID,
                      output    AXI_ARREADY,
                                
                      output    AXI_RID,
                      output    AXI_RDATA,
		      output    AXI_RRESP,
		      output    AXI_RLAST,
                      output    AXI_RVALID,
		      input     AXI_RREADY
			);
	modport master(output 	AXI_AWID,
		      output    AXI_AWADDR,
                      output    AXI_AWREG,
                      output    AXI_AWLEN,
                      output    AXI_AWSIZE,
                      output    AXI_AWBURST,
                      output    AXI_AWLOCK,
                      output    AXI_AWCACHE,
                      output    AXI_AWPROT,
                      output    AXI_AWQOS,
                      output    AXI_AWVALID,
                      input     AXI_AWREADY,
                              
                      output    AXI_WID,
                      output    AXI_WDATA,
                      output    AXI_WSTRB,
                      output    AXI_WLAST,
                      output    AXI_WVALID,
                      input     AXI_WREADY,
                                    
                      input     AXI_BID,
                      input     AXI_BRESP,
                      input     AXI_BVALID,
                      output    AXI_BREADY,
                 
                      output    AXI_ARID,
                      output    AXI_ARADDR,
                      output    AXI_ARREG,
                      output    AXI_ARLEN,
                      output    AXI_ARSIZE,
                      output    AXI_ARBURST,
                      output    AXI_ARLOCK,
                      output    AXI_ARCACHE,
                      output    AXI_ARPROT,
                      output    AXI_ARQOS,
                      output    AXI_ARVALID,
                      input     AXI_ARREADY,
                                 
                      input     AXI_RID,
                      input     AXI_RDATA,
		      input     AXI_RRESP,
		      input     AXI_RLAST,
                      input     AXI_RVALID,
		      output    AXI_RREADY
			);

`ifdef SIMULATION
	default clocking cb_drv @(posedge ACLK);
		input 
		output
	endclocking:cb_drv
	
	clocking cb_mon @(posedge ACLK);
		input
	endclocking:cb_mon

	clocking cb_recv @(posedge ACLK);
		input
		output
	endclocking:cb_recv
	
	modport driver(
		input ACLK,ARESET_N,
		input cb_drv
		);
	modport monitor(
		input ACLK,RESET_N,
		input cb_mon
		);
	modport reciver(
		input ACLK,ARESET_N,
		input cb_recv
		);

endinterface:axi_if 
