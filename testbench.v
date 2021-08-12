module testbench();
  reg hclk,hreset;
  wire hreadyout;
  wire pwrite_out,penable_out;
  wire [31:0] paddr_out,pwdata_out,prdata;
  wire [2:0] pselx_out;
  
  wire [1:0] hresp;
  wire [31:0] hrdata;
  wire [31:0] haddr,hwdata;
  wire hwrite,hreadyin;
  wire [1:0] htrans;
  
  wire penable,pwrite;
  wire [2:0] pselx;
  wire [31:0] paddr,pwdata;

  assign hrdata = prdata;
 
 //ahb_master
  ahb_master  ahb_master_dut(hclk,hreset,hreadyout,hrdata,hresp,haddr,hwdata,hwrite,hreadyin,htrans);


 //bridge_top
 bridge_top top_bridge_dut(haddr,hwdata,hwrite,hclk,hreset,htrans,hreadyin,prdata,paddr,pwrite,pwdata,penable,pselx,hreadyout,hresp,hrdata);

 //apb_interface
  apb_interface apb_interface_dut(penable,pwrite,paddr,pwdata,pselx,pwrite_out,penable_out,paddr_out,pwdata_out,prdata,pselx_out);
  
//clock 
  initial
    begin
      hclk = 0;
      forever #5 hclk = ~ hclk;
    end

//reset
  task rst;
    begin
      hreset = 0;
      #4;
      hreset =1;
    end
  endtask

//burst_read of type INCR8 and BYTE size
  initial
    begin
      rst;
      ahb_master_dut.burst_read(`INCR8,`BYTE);
      @(posedge hclk);
      #300 $finish;
    end

//dumping variables for waveform analysis
  initial
    begin
      $dumpfile("dump.vcd");
      $dumpvars;
    end
endmodule