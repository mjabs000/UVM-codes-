// Testing the concepts date 17 May 2019

import uvm_pkg::*;
`include "uvm_macros.svh"

module top;

  class test extends uvm_test;
   `uvm_component_utils (test)
    
    function new( string name, uvm_component parent = null);
      super.new(name,parent);
    endfunction   
   
    task run_phase(uvm_phase phase);
       super.run_phase(phase);
       phase.raise_objection(this);
       #10;
       `uvm_info("TEST", "Hello World!",UVM_LOW)
       phase.drop_objection(this);
    endtask
  endclass : test

   initial begin 
    automatic test c = new("c");
    run_test();
   end

endmodule: top


 