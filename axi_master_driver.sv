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


//function void axi_master_driver::assign_vif(virtual interface axi_if vif);
//  m_vif = vif;
//endfunction

//function void axi_master_driver::assign_conf(axi_master_conf conf);
//  m_conf = conf;
//endfunction

//UVM connect_phase
function void axi_master_driver::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (!uvm_config_db#(virtual interface axi_if)::get(this, "", "m_vif", m_vif))
   `uvm_fatal("axi_master_driver","virtual interface must be set for m_vif")
endfunction : connect_phase

// UVM run_phase
task axi_master_driver::run_phase(uvm_phase phase);
    fork
      get_and_drive();
      reset();
      sent_addr_write_trx();
      sent_data_write_trx();
      received_resp_write_trx();
      sent_addr_read_trx();
      received_data_read_trx();
      free_write_trx();
      free_read_trx();
    join
endtask : run_phase

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:
//input:axi master signal
//output:n/a
//description:Gets transfers from the sequencer and passes them to the driver.
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::get_and_drive();
    wait_for_reset();
    sent_trx_to_seq();
endtask : get_and_drive

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


task axi_master_driver::wait_for_reset();
    @(posedge m_vif.AXI_ARESET_N)
    `uvm_info(get_type_name(), "Reset dropped", UVM_MEDIUM)

endtask : wait_for_reset


// get next trx when reset has already done
task axi_master_driver::sent_trx_to_seq();
     forever begin
        @(posedge m_vif.AXI_ACLK);
        seq_item_port.get_next_item(req);
        drive_transfer(req);
        seq_item_port.item_done();
    end
endtask : sent_trx_to_seq

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:send
//input:axi master signal
//output:n/a
//description:reset all signals
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::send(axi_transaction tr);
  forver begin
  case(tr::op_cmd)
    RESET:reset();
    READ:begin
         m_rd_queue.push_back(tr);
	 end
    WRITE:begin
         m_wr_queue.push_back(tr);
	 end
    default:`uvm_fatal("axi_master_driver","axi_transaction must have a valid command!!")
  endcase

    m_num_sent++;
    `uvm_info(get_type_name(), $psprintf("Item %0d Sent ...", m_num_sent), UVM_HIGH)
    end
endtask:send

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write
//input:AWREADY,WREADY
//output:AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWLOCK,AWCACHE,AWPROT,AWQOS,AWREGION,AWUSER,AWVALID,WID,WDATA,WSTRB,WLAST,WUSER,WVALID
//description:axi write 
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::write();
    axi_transaction m_tr;

    forever begin
      // if write trx has existed...
      repeat(m_wr_queue.size()==0) @(posedge m_vif.ACLK);

      if (m_wr_addr_indx < m_wr_queue.size()) begin
          m_trx = m_wr_queue[m_wr_addr_indx];

          repeat(m_trx.addr_wt_delay) @(posedge m_vif.ACLK);

          // sent trx
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

          // free trx
          `delay(m_conf.half_cycle);
          m_vif.AXI_AWVALID <= 1'b0;
          m_trx.addr_done = `TRUE;
          @(posedge m_vif.AXI_ACLK);

          m_wr_addr_indx += 1;

      end else begin
        @(posedge m_vif.AXI_ACLK);
      end
    end

endtask:write


// data write trx task by event_sent_write_trx.trigger
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write
//input:AWREADY,WREADY
//output:AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWLOCK,AWCACHE,AWPROT,AWQOS,AWREGION,AWUSER,AWVALID,WID,WDATA,WSTRB,WLAST,WUSER,WVALID
//description:axi write 
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::write_data();
    int unsigned  i = 0;
    AXI_transfer  m_trx;

    forever begin

      repeat(m_wr_queue.size()==0) @(posedge m_vif.AXI_ACLK);

      if (m_wr_data_indx < m_wr_queue.size()) begin
          m_trx = m_wr_queue[m_wr_data_indx];

          repeat(m_trx.data_wt_delay) @(posedge m_vif.AXI_ACLK);

          // sent trx
          while (i<=m_trx.len) begin

            `delay(m_conf.half_cycle);
            m_vif.WVALID  <= 1'b1;
            m_vif.WDATA   <= m_tr.data[i];
            m_vif.WSTRB   <= m_tr.strb[i];
            m_vif.WID     <= m_tr.id;
            m_vif.WLAST   <= (i==m_trx.len)? 1'b1 : 1'b0;
            @(posedge m_vif.AXI_ACLK);

            if (m_vif.AXI_WREADY && m_vif.AXI_WVALID)
              i = i+1;
          end

          // hold until all finish

          // free trx
          `delay(m_conf.half_cycle);
          m_vif.AXI_WVALID <= 1'b0;
          m_vif.AXI_WLAST  <= 1'b0;
          i = 0;
          m_trx.data_done = `TRUE;
          @(posedge m_vif.AXI_ACLK);

          m_wr_data_indx += 1;

        end else begin
          @(posedge m_vif.AXI_ACLK);
        end
      end

endtask : sent_data_write_trx


// data resp trx collect resp to trx
task axi_master_driver::received_resp_write_trx();

  forever begin
    `delay(m_conf.half_cycle);
     m_vif.AXI_BREADY <= 1'b0;
     repeat($urandom_range(4,8)) @(posedge m_vif.AXI_ACLK);

    `delay(m_conf.half_cycle);
     m_vif.AXI_BREADY <= 1'b1;
     @(posedge m_vif.AXI_ACLK);

    // hold until BVALID received
    while(!m_vif.AXI_BVALID) @(posedge m_vif.AXI_ACLK);
  end

endtask : received_resp_write_trx


// addr read trx
task axi_master_driver::sent_addr_read_trx();
    AXI_transfer m_trx;

    forever begin

      repeat(m_rd_queue.size()==0) @(posedge m_vif.AXI_ACLK);

      if (m_rd_addr_indx < m_rd_queue.size()) begin
          m_trx = m_rd_queue[m_rd_addr_indx];

          repeat(m_trx.addr_rd_delay) @(posedge m_vif.AXI_ACLK);

          // sent trx
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
         m_vif.AXI_ARVALID <= 1'b0;
         @(posedge m_vif.AXI_ACLK);

         m_rd_addr_indx += 1;

      end else begin
        @(posedge m_vif.AXI_ACLK);
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

