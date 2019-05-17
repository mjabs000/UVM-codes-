import uvm_pkg::*;
`include "uvm_macros.svh"

module test;

class simple_packet extends uvm_object;
`uvm_object_utils (simple_packet)
   rand bit [7:0] addr;
   rand bit [7:0] data;
   bit     rwb;
   constraint c_addr { addr > 8'h2a; }
   constraint c_data { data > 8'h14 & data < 8'he9;}
endclass

class producer extends uvm_component;
  `uvm_component_utils(producer)
   uvm_blocking_put_port#(simple_packet) out;
   simple_packet pkt;
   function new(string name, uvm_component parent = null);
     super.new(name,parent);
   endfunction 
   virtual function void build_phase (uvm_phase phase);
      super.build_phase (phase);
      out = new ("out", this);
   endfunction
   virtual task run_phase (uvm_phase phase);
    //  phase.raise_objection(this);
      repeat (5) begin
         pkt = simple_packet::type_id::create ("pkt");
         assert(pkt.randomize ()); 
         `uvm_info ("COMPA", "Packet sent to CompB", UVM_LOW)
         pkt.print (uvm_default_line_printer);
         out.put (pkt);
      end
    //  phase.drop_objection(this);
   endtask
endclass 
 
class consumer extends uvm_component;
  `uvm_component_utils(consumer)
   uvm_blocking_put_imp#(simple_packet,consumer) in;
   function new(string name, uvm_component parent = null);
     super.new(name,parent);
     in = new("in",this);
   endfunction 
   task put (simple_packet pkt);
     `uvm_info ("COMPB", "Packet received from CompA", UVM_LOW)
      pkt.print ();
   endtask
endclass  

class env extends uvm_env;
  `uvm_component_utils(consumer)
   producer p;
   consumer c;

   function new(string name, uvm_component parent = null);
     super.new(name,parent);
  
   endfunction 
 
    virtual function void build_phase (uvm_phase phase);
      super.build_phase (phase);
      p = producer::type_id::create ("p", this);
      c = consumer::type_id::create ("c", this);
    endfunction
   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      p.out.connect(c.in);  
   endfunction 
endclass  
  initial begin 
   env e;
   e = new("e");
   run_test();
  end
endmodule
