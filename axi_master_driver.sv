////////////////////////////////////////////
// File : axi_master_driver.sv
// Date : 2017/06/03
// Description : axi master driver
////////////////////////////////////////////

`ifndef AXI_MASTER_DRIVER__SV
`define AXI_MASTER_DRIVER__SV

class axi_master_driver extends uvm_driver #(axi_transaction);

  virtual interface axi_if    m_vif;
  m_vif.cb_drv hook;
  logic [AXI_DATA_WIDTH-1:0]  rd_data;
  axi_transaction             m_wr_queue[$];
  axi_transaction             m_rd_queue[$];
  int unsigned                m_wr_addr_indx = 0;
  int unsigned                m_wr_data_indx = 0;
  int unsigned                m_rd_addr_indx = 0;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction:new

  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual protected task reset();
  
  extern virtual task write_addr();
  extern virtual task write_data();
  extern virtual task received_resp_write();
  extern virtual task read_addr();
  extern virtual task read_data();
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
     	RESET:fork
		reset();
	      join
	WRITE:fork 
		write_addr();write_data();received_resp_write();
	      join
	READ: fork
		read_addr();read_data(rd_data);
	      join
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
      //@(posedge m_vif.ARESET_N);
        hook.AWID   <= 0;
        hook.AWADDR <= 0;
	hook.AWLEN  <= 0;
		...
    end
endtask:reset

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:write_addr
//description:axi write address channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::write_addr();
    axi_transaction m_tr;
    forever begin
      // if write tr has existed...
      repeat(m_wr_queue.size()==0) @(posedge m_vif.ACLK);

      if (m_wr_addr_indx < m_wr_queue.size()) begin
          m_tr = m_wr_queue[m_wr_addr_indx];
          repeat(m_trx.addr_wt_delay) @(posedge m_vif.ACLK);
	  
          // sent tr
          hook.AWVALID <= 1'b1;
          hook.AWID    <= m_tr.id;
          hook.AWADDR  <= m_tr.addr;
          hook.AWREG   <= m_tr.region;
          hook.AWLEN   <= m_tr.len;
          hook.AWSIZE  <= m_tr.size;
          hook.AWBURST <= m_tr.burst;
          hook.AWLOCK  <= m_tr.lock;
          hook.AWCACHE <= m_tr.cache;
          hook.AWPROT  <= m_tr.prot;
          hook.AWQOS   <= m_tr.qos;

          //wait AWREADY
          while (!hook.AWREADY) @(posedge m_vif.ACLK);
          hook.AWVALID <= 1'b0;
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
            hook.WVALID  <= 1'b1;
            hook.WDATA   <= m_tr.data[i];
            hook.WSTRB   <= m_tr.strb[i];
            hook.WID     <= m_tr.id;
            hook.WLAST   <= (i==m_tr.len)? 1'b1 : 1'b0;
            @(posedge m_vif.ACLK);

            if (m_vif.WREADY && m_vif.WVALID)
              i = i+1;
          end
	  
          // free tr
          hook.WVALID <= 1'b0;
          hook.WLAST  <= 1'b0;
          i = 0;
          @(posedge m_vif.ACLK);
          m_wr_data_indx += 1;
        end 
	else begin
          @(posedge m_vif.ACLK);
        end
      end
endtask:write_data

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:received_resp_write
//description:axi write respone channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::received_resp_write();
  forever begin
     hook.BREADY <= 1'b0;
     repeat(2) @(posedge m_vif.ACLK);

     hook.BREADY <= 1'b1;
     @(posedge m_vif.ACLK);

    //wait BVALID received
    while(!m_vif.BVALID) @(posedge m_vif.ACLK);
  end
endtask : received_resp_write

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:read_addr
//description:axi read address channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::read_addr();
    axi_transaction m_tr;

    forever begin
      repeat(m_rd_queue.size()==0) @(posedge m_vif.ACLK);
      if (m_rd_addr_indx < m_rd_queue.size()) begin
          m_trx = m_rd_queue[m_rd_addr_indx];
          repeat(m_tr.addr_rd_delay) @(posedge m_vif.ACLK);

          // sent tr
          hook.ARVALID <= 1'b1;
          hook.ARID    <= m_tr.id;
          hook.ARADDR  <= m_tr.addr;
          hook.ARREADY <= m_tr.region;
          hook.ARLEN   <= m_tr.len;
          hook.ARSIZE  <= m_tr.size;
          hook.ARBURST <= m_tr.burst;
          hook.ARLOCK  <= m_tr.lock;
          hook.ARCACHE <= m_tr.cache;
          hook.ARPROT  <= m_tr.prot;
          hook.ARQOS   <= m_tr.qos;

          //wait ARREADY received
          while(!hook.ARREADY) @(posedge m_vif.ACLK);
          hook.ARVALID <= 1'b0;
          @(posedge m_vif.ACLK);
	  m_rd_addr_indx += 1;
      end 
      else begin
        @(posedge m_vif.ACLK);
      end
    end
endtask : read_addr

//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
//task:read_data
//description:axi read data channel
//TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
task axi_master_driver::read_data(output logic [AXI_DATA_WIDTH-1:0] rd_data);
  always@(posedge m_vif.ACLK)
  rd_data = (m_vif.RVALID && m_vif.RREADY)? m_vif.RDATA : 0;
  forever begin
     m_vif.RREADY <= 1'b0;
     repeat(2) @(posedge m_vif.ACLK);
     hook.RREADY <= 1'b1;
     
     //wait RVALID received
     while(!hook.RVALID) @(posedge m_vif.ACLK);   
     // continuous burst case
     while(!hook.RLAST) @(posedge m_vif.ACLK);
     hook.RREADY <= 1'b0;
  end
endtask : read_data

`endif // AXI_MASTER_DRIVER__SV
