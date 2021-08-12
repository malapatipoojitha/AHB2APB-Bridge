// ahb master
module ahb_master(input hclk,hreset,hreadyout,
                  input [31:0] hrdata,input [1:0] hresp,
                  output reg [31:0] haddr,hwdata, 
                  output reg hwrite,hreadyin,
                  output reg [1:0] htrans);
  
`define BYTE 3'b000
`define HALF_WORD 3'b001
`define WORD 3'b010

`define SINGLE 3'b000
`define INCR   3'b001
`define WRAP4  3'b010
`define INCR4  3'b011
`define WRAP8  3'b100
`define INCR8  3'b000
`define WRAP16 3'b000
`define INCR16 3'b000

`define OKAY 2'b00
`define ERROR 2'b01
`define RETRY 2'b10
`define SPLIT 2'b11

`define IDLE 2'b00
`define BUSY 2'b01
`define SEQ 2'b10
`define NONSEQ 2'b11
  
  reg [2:0] hsize;
  reg [2:0] hburst;
  integer i;
  
//task for single_write
  task single_write;
    begin
      @(posedge hclk);
      #1;
      haddr = 32'h8000_0001;
      hwrite = 1;
      hreadyin = 1;
      htrans = 2'b10;
      hburst = 3'b000;
      @(posedge hclk);
      #1;
      hwdata = 32'h1234_5678;
      htrans = 2'b00;
    end
  endtask
  
//task for single read
  task single_read;
    begin
      @(posedge hclk);
      #1;
      haddr = 32'h8000_0002;
      hwrite = 0;
      hreadyin = 1;
      htrans = 2'b10;
      hburst = 3'b000;
      @(posedge hclk);
      #1;
      htrans = 2'd00;
    end
  endtask 
  

  //burst write
  task burst_write(input [2:0] a,b);
    begin
      begin
        @(posedge hclk);
        #1;
        hreadyin = 1;
        hwrite = 1;
        haddr = 32'h8000_0010;
        htrans = `NONSEQ;
        hburst = a;
        hsize = b;
       end
      case(hsize)
        `BYTE :
            begin
               case(hburst)
                 `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 1'b1;
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 1'b1;
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 1'b1;
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:2],haddr[1:0]}={haddr[31:2],(haddr[1:0]+1'b1)};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[2:0]+1'b1)};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:4],haddr[3:0]}={haddr[31:4],(haddr[3:0]+1'b1)};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
              
            end
          endcase
        end
            
        `HALF_WORD : begin
          case(hburst)
            `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 2'd2;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 2'd2;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 2'd2;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:2],haddr[1:0]}={haddr[31:2],(haddr[2:1]+1'b1),haddr[0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[3:1]+1'b1),haddr[0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[4:1]+1'b1),haddr[0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
          endcase
        end
            
        `WORD : begin
          case(hburst)
            `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 3'd4;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 3'd4;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  haddr = haddr + 3'd4;
                  htrans = `SEQ;
                end
               wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:4],(haddr[3:2]+1'b1),haddr[1:0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:5],(haddr[4:2]+1'b1),haddr[1:0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
            `WRAP16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  hwdata = $random;
                  {haddr[31:3],haddr[2:0]}={haddr[31:6],(haddr[5:2]+1'b1),haddr[1:0]};
                  htrans = `SEQ;
                end
              wait(hreadyout);
              @(posedge hclk);
              #1;
              hwdata = $random;
              htrans = `IDLE;
            end
          endcase
        end
          endcase
        end
  endtask
            
     //burst read
  task burst_read(input [2:0] a,b);
    begin
      begin
      @(posedge hclk);
      #1;
      hreadyin = 1;
      hwrite = 0;
      haddr = 32'h8000_0100;
      htrans = `NONSEQ;
      hburst = a;
      hsize = b;
      end
      case(hsize)
        `BYTE : begin
          case(hburst)
            `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 1'b1;
                  htrans = `SEQ;
                end
              htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 1'b1;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 1'd1;
                end
               htrans = `IDLE;
            end
            `WRAP4:begin
               for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  {haddr[31:2],haddr[1:0]}={haddr[31:2],(haddr[1:0]+1'b1)};
                  htrans = `SEQ;
                end
              htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[2:0]+1'b1)};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  htrans = `SEQ;
                   {haddr[31:4],haddr[3:0]}={haddr[31:4],(haddr[3:0]+1'b1)};
                end
               htrans = `IDLE;
            end
          endcase
        end
            
        `HALF_WORD : begin
          case(hburst)
            `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 2'd2;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 2'd2;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 2'd2;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                 {haddr[31:2],haddr[1:0]}={haddr[31:2],(haddr[2:1]+1'b1),haddr[0]};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[3:1]+1'b1),haddr[0]};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP16:begin
               for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  {haddr[31:3],haddr[2:0]}={haddr[31:3],(haddr[4:1]+1'b1),haddr[0]};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
          endcase
        end
            
        `WORD : begin
          case(hburst)
            `INCR4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 3'd4;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `INCR8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 3'd4;
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `INCR16:begin
              for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                  haddr = haddr + 3'd4;
                  htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP4:begin
              for(i=0;i<3;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                 {haddr[31:3],haddr[2:0]}={haddr[31:4],(haddr[3:2]+1'b1),haddr[1:0]};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP8:begin
              for(i=0;i<7;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                 {haddr[31:3],haddr[2:0]}={haddr[31:5],(haddr[4:2]+1'b1),haddr[1:0]};
                   htrans = `SEQ;
                end
               htrans = `IDLE;
            end
            `WRAP16:begin
               for(i=0;i<15;i++)
                begin
                  wait(hreadyout);
                  @(posedge hclk);
                  #1;
                {haddr[31:3],haddr[2:0]}={haddr[31:6],(haddr[5:2]+1'b1),haddr[1:0]};
                  htrans = `SEQ;
                end
               htrans = `IDLE;
            end
          endcase
    end
      endcase
    end
  endtask
  
endmodule