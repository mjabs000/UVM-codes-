//https://www.edaplayground.com/x/296
//https://www.youtube.com/watch?v=Qn6SvG-Kya0

// This is the SystemVerilog interface that we will use to connect
// our design to our UVM testbench.
interface dut_if;
  logic clock, reset;
  logic cmd;
  logic [7:0] addr;
  logic [7:0] data;
endinterface

`include "uvm_macros.svh"

// This is our design module.
// 
// It is an empty design that simply prints a message whenever
// the clock toggles.
module dut(dut_if dif);
  import uvm_pkg::*;
  always @(posedge dif.clock)
    if (dif.reset != 1) begin
      `uvm_info("DUT",
                $sformatf("Received cmd=%b, addr=0x%2h, data=0x%2h",
                          dif.cmd, dif.addr, dif.data), UVM_MEDIUM)
    end
endmodule

//transcation class
class my_transaction extends uvm_sequence_item;

  `uvm_object_utils(my_transaction)

  rand bit cmd;
  rand int addr;
  rand int data;

  constraint c_addr { addr >= 0; addr < 256; }
  constraint c_data { data >= 0; data < 256; }

  function new (string name = "");
    super.new(name);
  endfunction

endclass: my_transaction

class my_sequence extends uvm_sequence#(my_transaction);

  `uvm_object_utils(my_sequence)

  function new (string name = "");
    super.new(name);
  endfunction

  task body;
    repeat(8) begin
      req = my_transaction::type_id::create("req");
      start_item(req);

      if (!req.randomize()) begin
        `uvm_error("MY_SEQUENCE", "Randomize failed.");
      end

      // If using ModelSim, which does not support randomize(),
      // we must randomize item using traditional methods, like
      // req.cmd = $urandom;
      // req.addr = $urandom_range(0, 255);
      // req.data = $urandom_range(0, 255);

      finish_item(req);
    end
  endtask: body

endclass: my_sequence

//driver

class my_driver extends uvm_driver #(my_transaction);

  `uvm_component_utils(my_driver)

  virtual dut_if dut_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // Get interface reference from config database
    if(!uvm_config_db#(virtual dut_if)::get(this, "", "dut_vif", dut_vif)) begin
      `uvm_error("", "uvm_config_db::get failed")
    end
  endfunction 

  task run_phase(uvm_phase phase);
    // First toggle reset
    dut_vif.reset = 1;
    @(posedge dut_vif.clock);
    #1;
    dut_vif.reset = 0;
    
    // Now drive normal traffic
    forever begin
      seq_item_port.get_next_item(req);

      // Wiggle pins of DUT
      dut_vif.cmd  = req.cmd;
      dut_vif.addr = req.addr;
      dut_vif.data = req.data;
      @(posedge dut_vif.clock);

      seq_item_port.item_done();
    end
  endtask

endclass: my_driver

//pkg

package my_testbench_pkg;
  import uvm_pkg::*;
  
  // The UVM sequence, transaction item, and driver are in these files:
 // `include "my_sequence.svh"
 // `include "my_driver.svh"
  
  // The agent contains sequencer, driver, and monitor (not included)
  class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)
    
    my_driver driver;
    uvm_sequencer#(my_transaction) sequencer;
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      driver = my_driver ::type_id::create("driver", this);
      sequencer =
        uvm_sequencer#(my_transaction)::type_id::create("sequencer", this);
    endfunction    
    
    // In UVM connect phase, we connect the sequencer to the driver.
    function void connect_phase(uvm_phase phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
    
    task run_phase(uvm_phase phase);
      // We raise objection to keep the test from completing
      phase.raise_objection(this);
      begin
        my_sequence seq;
        seq = my_sequence::type_id::create("seq");
        seq.start(sequencer);
      end
      // We drop objection to allow the test to complete
      phase.drop_objection(this);
    endtask

  endclass
  
  class my_env extends uvm_env;
    `uvm_component_utils(my_env)
    
    my_agent agent;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      agent = my_agent::type_id::create("agent", this);
    endfunction

  endclass
  
  class my_test extends uvm_test;
    `uvm_component_utils(my_test)
    
    my_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      env = my_env::type_id::create("env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
      // We raise objection to keep the test from completing
      phase.raise_objection(this);
      #10;
      `uvm_warning("", "Hello World!")
      // We drop objection to allow the test to complete
      phase.drop_objection(this);
    endtask

  endclass
  
endpackage

//TB

/*******************************************
This is a basic UVM "Hello World" testbench.

Explanation of this testbench on YouTube:
https://www.youtube.com/watch?v=Qn6SvG-Kya0
*******************************************/

`include "uvm_macros.svh"
`include "my_testbench_pkg.svh"

// The top module that contains the DUT and interface.
// This module starts the test.
module top;
  import uvm_pkg::*;
  import my_testbench_pkg::*;
  
  // Instantiate the interface
  dut_if dut_if1();
  
  // Instantiate the DUT and connect it to the interface
  dut dut1(.dif(dut_if1));
  
  // Clock generator
  initial begin
    dut_if1.clock = 0;
    forever #5 dut_if1.clock = ~dut_if1.clock;
  end
  
  initial begin
    // Place the interface into the UVM configuration database
    uvm_config_db#(virtual dut_if)::set(null, "*", "dut_vif", dut_if1);
    // Start the test
    run_test("my_test");
  end
  
  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
  end
  
endmodule
