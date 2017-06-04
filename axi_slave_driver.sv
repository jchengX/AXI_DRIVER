//////////////////////////////////////////
// File : axi_slave_driver.sv
// Date : 2017/06/03
// Description : axi slave driver
/////////////////////////////////////////

`ifndef AXI_SLAVE_DRIVER__SV
`define AXI_SLAVE_DRIVER__SV

class axi_slave_driver extends uvm_driver #(axi_transaction);

  virtual interface axi_vif   m_vif;
  int unsigned                m_mem[int unsigned];

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual protected task reset();
  extern virtual protected task write_addr();
  extern virtual protected task write_data();
  extern virtual protected task sent_resp_write();
  extern virtual protected task read_addr();
  extern virtual protected task read_data();
endclass : AXI_slave_driver

//UVM connect_phase
function void axi_slave_driver::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "m_vif", m_vif))
   `uvm_fatal("axi_slave_driver","No virtual interface specified for this driver instance!")
endfunction : connect_phase

// UVM run_phase
task axi_slave_driver::run_phase(uvm_phase phase);
    super.run_phase(phase)
    reset();
    	fork
   	 read_addr();
    	 read_data();
  	 write_addr();
   	 write_data();
   	 sent_resp_write();
        join
endtask : run_phase

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:reset
//description:reset all signals
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_slave_driver::reset();
      //@(posedge m_vif.ARESET_N);
      begin
        // addr write
        m_vif.AWREADY   <= 0;
        // data write
        m_vif.WREADY    <= 0;
        // resp write
        m_vif.BID       <= 0;
	m_vif.BRESP     <= 0;
	m_vif.BUSER     <= 0;
	m_vif.BVALID    <= 0;
        // addr read
	m_vif.ARREADY   <= 0;
        // data read
        m_vif.RID       <= 0;
	m_vif.RDATA     <= 0;
	m_vif.RRESP     <= 0;        
	m_vif.RLAST     <= 0;
	m_vif.RUSER     <= 0;
	m_vif.RVALID    <= 0;
    end
endtask : reset

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write_addr
//description:axi slave write address channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_slave_driver::write_addr();
   begin
    m_vif.AWREADY <= 1'b0;
    @(posedge m_vif.ACLK);
    m_vif.AWREADY <= 1'b1;
    @(posedge m_vif.ACLK);
    // wait AWVALID received
    while(!m_vif.AWVALID) @(posedge m_vif.ACLK);
  end
endtask : write_addr

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write_data
//description:axi slave write data channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_slave_driver::write_data();
   forever begin
    m_vif.WREADY <= 1'b0;
    repeat(2) @(posedge m_vif.ACLK);
    m_vif.WREADY <= 1'b1;
    @(posedge m_vif.ACLK);
    // wait WVALID received
    while(!m_vif.WVALID) @(posedge m_vif.ACLK);
    // continuous hold cycle for burst case
    @(posedge m_vif.ACLK);
    m_vif.WREADY <= 1'b1;
    repeat(2) @(posedge m_vif.ACLK);
  end
endtask : sent_data_write_trx

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:send_resp_write
//description:axi slave write respone channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_slave_driver::sent_resp_write();
  forever begin
    repeat(m_wr_queue.size()==0) @(posedge m_vif.ACLK);
      // sent tr
      m_vif.BVALID <= 1'b1;
      m_vif.BID    <= tr.id;
      m_vif.BRESP  <= OKAY;
      @(posedge m_vif.ACLK);
      // wait BREADY received
      while(!m_vif.BREADY) @(posedge m_vif.ACLK);
      m_vif.BVALID <= 1'b0;
      @(posedge m_vif.ACLK);
    end
  end
endtask : sent_resp_write

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:read_addr
//description:axi slave read address channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_slave_driver::read_addr();
  forever begin
    m_vif.ARREADY <= 1'b0;
    repeat(2) @(posedge m_vif.ACLK);
    m_vif.ARREADY <= 1'b1;
    @(posedge m_vif.ACLK);
    // wait ARVALID received
    while(!m_vif.ARVALID) @(posedge m_vif.ACLK);
  end
endtask : read_addr

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:read_data
//description:axi slave read data channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task slave_driver::read_data();
  int unsigned i = 0;
  forever begin
    repeat(m_rd_queue.size()==0) @(posedge m_vif.ACLK);
    if (m_rd_queue.size()!=0) begin
        tr = m_rd_queue[0];
        i = 0;
        repeat(m_conf.data_rd_delay) @(posedge m_vif.ACLK);
         // sent tr
         while (i!=tr.len+1) begin
             m_vif.RVALID  <= 1'b1;
             m_vif.RDATA   <= m_mem[tr.mem_addrs[i]];
             m_vif.RID     <= tr.id;
             m_vif.RRESP   <= OKAY;
             m_vif.RLAST   <= (i==tr.len)? 1'b1 : 1'b0;
             @(posedge m_vif.ACLK);
             if (m_vif.RREADY && m_vif.RVALID)
               i = i+1;
         end
        m_vif.RVALID <= 1'b0;
        m_vif.RLAST  <= 1'b0;
        @(posedge m_vif.ACLK);
      end
  end
endtask : read_data

`endif // AXI_SLAVE_DRIVER__SV
