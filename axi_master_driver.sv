////////////////////////////////////////////
// File : axi_master_driver.sv
// Date : 2017/06/03
// Description : axi master driver
////////////////////////////////////////////

`ifndef AXI_MASTER_DRIVER__SV
`define AXI_MASTER_DRIVER__SV

class axi_master_driver extends uvm_driver #(axi_transaction);

  virtual interface axi_if    m_vif;
  axi_master_conf             m_confg;
  axi_transaction                m_wr_queue[$];
  axi_transaction                m_rd_queue[$];
  int unsigned                m_num_sent;

  event                       event_sent_write_trx;
  event                       event_sent_read_trx;

  int unsigned                m_wr_addr_indx = 0;
  int unsigned                m_wr_data_indx = 0;
  int unsigned                m_rd_addr_indx = 0;

	`uvm_component_utils_begin(axi_master_driver)
		`uvm_field_int	(m_num_sent,UVM_ALL_ON)
	`uvm_component_utils_end

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction:new

  // Additional class methods
  //extern virtual function void assign_vif(virtual interface axi_if vif);
  //extern virtual function void assign_conf(axi_master_conf conf);
  
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual protected task get_and_drive();
  extern virtual protected task reset();
  extern virtual protected task drive_transfer(AXI_transfer trx);
 // extern virtual function void report();

  extern virtual task sent_addr_write_trx();
  extern virtual task sent_data_write_trx();
  extern virtual task received_resp_write_trx();

  extern virtual task sent_addr_read_trx();
  extern virtual task received_data_read_trx();

  extern virtual task free_write_trx();
  extern virtual task free_read_trx();

  extern virtual protected task wait_for_reset();
  extern virtual protected task sent_trx_to_seq();

endclass : axi_master_driver

//UVM connect_phase
function void axi_master_driver::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "m_vif", m_vif))
   `uvm_fatal("axi_master_driver","No virtual interface specified dor this instance")
endfunction : connect_phase

// UVM run_phase
task axi_master_driver::run_phase(uvm_phase phase);
 super.run_phase(phase);
 reset();
    forever begin
     seq_item_port.get_next_item(seq);
     case(seq.op_cmd)
     	RESET:begin
		reset();end
	WRITE:begin 
		write_addr();write_data;end
	READ:begin
		read_addr();read_data;end
	default:`uvm_fatal("axi_driver","No valid command")
     endcase
     seq_item_port.item_done();
     end
endtask : run_phase

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:reset
//input:n/a
//output:n/a
//description:reset all signals
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::reset();
    begin
      @(posedge m_vif.ARESET_N);
        m_vif.AWID   <= 0;
        m_vif.AWADDR <= 0;
	m_vif.AWLEN  <= 0;
		...
    end
endtask:reset

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write
//description:axi write address channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::write_addr();
    axi_transaction m_tr;
    forever begin
      // if write trx has existed...
      repeat(m_wr_queue.size()==0) @(posedge m_vif.ACLK);

      if (m_wr_addr_indx < m_wr_queue.size()) begin
          m_tr = m_wr_queue[m_wr_addr_indx];
          repeat(m_trx.addr_wt_delay) @(posedge m_vif.ACLK);
	  
          // sent tr
          m_vif.AXI_AWVALID <= 1'b1;
          m_vif.AXI_AWID    <= m_tr.id;
          m_vif.AXI_AWADDR  <= m_tr.addr;
          m_vif.AXI_AWREG   <= m_tr.region;
          m_vif.AXI_AWLEN   <= m_tr.len;
          m_vif.AXI_AWSIZE  <= m_tr.size;
          m_vif.AXI_AWBURST <= m_tr.burst;
          m_vif.AXI_AWLOCK  <= m_tr.lock;
          m_vif.AXI_AWCACHE <= m_tr.cache;
          m_vif.AXI_AWPROT  <= m_tr.prot;
          m_vif.AXI_AWQOS   <= m_tr.qos;
          @(posedge m_vif.ACLK);

          //wait AWREADY
          while (!m_vif.AXI_AWREADY) @(posedge m_vif.ACLK);
	  @(posedge m_vif.ACLK);
          m_vif.AXI_AWVALID <= 1'b0;
          m_wr_addr_indx += 1;
      end 
      else begin
        @(posedge m_vif.ACLK);
      end
    end

endtask:write

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write_data
//description:axi write data channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::write_data();
    int unsigned  i = 0;
    axi_transaction  m_tr;

    forever begin
      repeat(m_wr_queue.size()==0) @(posedge m_vif.ACLK);
      if (m_wr_data_indx < m_wr_queue.size()) begin
          m_tr = m_wr_queue[m_wr_data_indx];
          repeat(m_tr.data_wt_delay) @(posedge m_vif.ACLK);

          // sent trx
          while (i<=m_tr.len) begin
            m_vif.WVALID  <= 1'b1;
            m_vif.WDATA   <= m_tr.data[i];
            m_vif.WSTRB   <= m_tr.strb[i];
            m_vif.WID     <= m_tr.id;
            m_vif.WLAST   <= (i==m_tr.len)? 1'b1 : 1'b0;
            @(posedge m_vif.ACLK);

            if (m_vif.WREADY && m_vif.WVALID)
              i = i+1;
          end
	  
          // free tr
          m_vif.WVALID <= 1'b0;
          m_vif.WLAST  <= 1'b0;
          i = 0;
          @(posedge m_vif.ACLK);
          m_wr_data_indx += 1;
        end 
	else begin
          @(posedge m_vif.ACLK);
        end
      end
endtask:write_data


// data resp trx collect resp to trx
task axi_master_driver::received_resp_write_trx();

  forever begin
    `delay(m_conf.half_cycle);
     m_vif.AXI_BREADY <= 1'b0;
     repeat($urandom_range(4,8)) @(posedge m_vif.ACLK);

    `delay(m_conf.half_cycle);
     m_vif.AXI_BREADY <= 1'b1;
     @(posedge m_vif.ACLK);

    // hold until BVALID received
    while(!m_vif.BVALID) @(posedge m_vif.ACLK);
  end

endtask : received_resp_write_trx


// addr read trx
task axi_master_driver::sent_addr_read_trx();
    AXI_transfer m_trx;

    forever begin

      repeat(m_rd_queue.size()==0) @(posedge m_vif.ACLK);

      if (m_rd_addr_indx < m_rd_queue.size()) begin
          m_trx = m_rd_queue[m_rd_addr_indx];

          repeat(m_tr.addr_rd_delay) @(posedge m_vif.ACLK);

          // sent tr
          `delay(m_conf.half_cycle);
          m_vif.ARVALID <= 1'b1;
          m_vif.ARID    <= m_tr.id;
          m_vif.ARADDR  <= m_tr.addr;
          m_vif.ARREADY <= m_tr.region;
          m_vif.ARLEN   <= m_tr.len;
          m_vif.ARSIZE  <= m_tr.size;
          m_vif.ARBURST <= m_tr.burst;
          m_vif.ARLOCK  <= m_tr.lock;
          m_vif.ARCACHE <= m_tr.cache;
          m_vif.ARPROT  <= m_tr.prot;
          m_vif.ARQOS   <= m_tr.qos;
          @(posedge m_vif.ACLK);

          // hold until ARREADY received
          while(!m_vif.ARREADY) @(posedge m_vif.ACLK);
          //void'(m_rd_queue.pop_front());

          // free trx
         `delay(m_conf.half_cycle);
         m_vif.ARVALID <= 1'b0;
         @(posedge m_vif.ACLK);

         m_rd_addr_indx += 1;

      end else begin
        @(posedge m_vif.ACLK);
      end
    end

endtask : sent_addr_read_trx


// data read trx
task axi_master_driver::received_data_read_trx();

  forever begin
    `delay(m_conf.half_cycle);
     m_vif.AXI_RREADY <= 1'b0;
     repeat($urandom_range(4,8)) @(posedge m_vif.AXI_ACLK);

    `delay(m_conf.half_cycle);
     m_vif.AXI_RREADY <= 1'b1;
    @(posedge m_vif.AXI_ACLK);

     // hold until RVALID received
     while(!m_vif.AXI_RVALID) @(posedge m_vif.AXI_ACLK);

    // continuous burst case
    `delay(m_conf.half_cycle);
    m_vif.AXI_RREADY <= 1'b1;
    repeat($urandom_range(4,16)) @(posedge m_vif.AXI_ACLK);
  end

endtask : received_data_read_trx


// finish read trx

`endif // AXI_MASTER_DRIVER__SV

