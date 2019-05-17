class register;
 local bit[31:0] contents;
 
  
 function void write(bit[31:0] d);
   contents = d;
  endfunction

  function bit[31:0] read();
   return contents;
  endfunction 

endclass

module top;
 
  register r;
  bit[31:0] d;
 
   initial begin 
     r = new();
     r.write(32'h00ff72a8);
     d = r.read();
     if( d == 32'h00ff72a8) begin
      $display("TC passed !!! ");
     end
   end 
endmodule