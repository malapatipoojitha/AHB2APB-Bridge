module apb_interface(input penable,pwrite,
                     input [31:0] paddr,pwdata,
                     input [2:0] pselx,
                     output pwrite_out,penable_out,
                     output [31:0] paddr_out, 
                     pwdata_out,prdata,
                     output [2:0] pselx_out);                                       

  reg prdata; 
   assign penable_out = penable,
          pwrite_out = pwrite,
          paddr_out = paddr,
          pwdata_out = pwdata,
          pselx_out = pselx;
   always@(*)
     begin
      if(penable && ~pwrite)
        prdata = $random;
      else
        prdata = 32'h0000_0000;
     end
endmodule : apb_interface