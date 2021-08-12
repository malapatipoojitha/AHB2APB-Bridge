module bridge_top(input [31:0] HADDR,
    input [31:0] HWDATA,
    input HWRITE,
    input HCLK,
    input HRESET,
    input [1:0] HTRANS,
    input HREADY,
    input [31:0] prdata,
    output [31:0] paddr,
    output  pwrite,
    output [31:0] pwdata,
    output penable,
    output [2:0] pselx,
    output hready_out,
    output [1:0] hresp,
    output [31:0] hrdata
    );

wire VALID;
wire HWRITE_REG;
wire [2:0] TEMP_SELX;
//Pipelining registers
wire [31:0] HADDR_1,HADDR_2,HWDATA_1,HWDATA_2;



//Instantiating AHB_SLAVE
AHB_SLAVE ahb_slave(HADDR,HWDATA,HWRITE,HCLK,HRESET,HTRANS,HREADY,VALID,HADDR_1,HADDR_2,HWDATA_1,HWDATA_2,HWRITE_REG,TEMP_SELX);

//Instantiating FSM Controller
ahb_fsm fsm_controller(VALID,HADDR_1,HADDR_2,HWDATA_1,HWDATA_2,HWRITE_REG,TEMP_SELX,HCLK,HRESET,HWRITE,prdata,paddr,pwrite,
  pwdata,penable,pselx,hready_out,hresp,hrdata);
  
endmodule:bridge_top



//AHB Slave
module AHB_SLAVE(
    input [31:0] HADDR,
    input [31:0] HWDATA,
    input HWRITE,
    input HCLK,
    input HRESET,
    input [1:0] HTRANS,
    input HREADY,
    output reg VALID,
    output reg [31:0] HADDR_1,HADDR_2,HWDATA_1,HWDATA_2,
    output reg HWRITE_REG,
    output reg [2:0] TEMP_SELX
    );

//different slaves used	
parameter INTERURPT_CONTROLLER = 3'b001,COUNTER_TIMER = 3'b010,REMAP_PAUSE = 3'b100,UNDEFINED = 3'b000;

//Data transition type
parameter IDLE = 2'b00, BUSY = 2'b01, NON_SEQ = 2'b10, SEQ = 2'b11;


//pipelining adress,data and hwrite
always@(posedge HCLK or negedge HRESET)
  begin:pipeline_block
	  if(~HRESET)//Asynchronous Negative Reset
      begin : reset_block

        HADDR_1 <= 0;
        HADDR_2 <= 0;
        HWDATA_1 <= 0;
        HWDATA_2 <= 0;
        HWRITE_REG <= 0;

      end : reset_block

   else
     begin:else_block

       HADDR_1 <= HADDR;
       HADDR_2 <= HADDR_1;
       HWDATA_1 <= HWDATA;
       HWDATA_2 <= HWDATA_1;
       HWRITE_REG <= HWRITE;

     end:else_block
   end:pipeline_block


//slave select logic
always@(*)
  begin : slave_select
    TEMP_SELX=UNDEFINED;

    if(32'h8400_0000>=HADDR>=32'h8000_0000) 
       TEMP_SELX = INTERURPT_CONTROLLER;
    if(32'h8800_0000>=HADDR>=32'h8400_0001) 
       TEMP_SELX = COUNTER_TIMER;
    if(32'h8c00_0000>=HADDR>=32'h8800_0001) 
       TEMP_SELX = REMAP_PAUSE;

  end : slave_select


//valid signal logic
always@(*)
  begin : valid_logic
    VALID = 1'b0;
    if(HRESET)
       if((HADDR > 32'h8000_0000 && HADDR < 32'h8c00_0000 &&                                                    HTRANS != IDLE&& HTRANS != BUSY&& HREADY ==1'b1  ))
             VALID = 1'b1;
     else
       VALID = 1'b0;
  end :valid_logic

endmodule : AHB_SLAVE




//AHB fsm controller
module ahb_fsm(
    input valid,
    input [31:0] haddr_1,
    input [31:0] haddr_2,
    input [31:0] hwdata_1,
    input [31:0] hwdata_2,
    input hwrite_reg,
    input [2:0] temp_selx,
    input hclk,
    input hreset,
    input hwrite,
    input [31:0] prdata,
    output reg [31:0] paddr,
    output reg pwrite,
    output reg [31:0] pwdata,
    output reg penable,
    output reg [2:0] pselx,
    output reg hready_out,
    output [1:0] hresp,
    output [31:0] hrdata
    );

//states in fsm
parameter ST_IDLE=3'b000,
          ST_WWAIT=3'b001,
	     ST_READ=3'b010,
	     ST_WRITE=3'b011,
		ST_WRITEP=3'b100,
		ST_RENABLE=3'b101,
	      ST_WENABLE=3'b110,
		 ST_WENABLEP=3'b111;	 

//present state and next state registers
reg [2:0] present_state,next_state;
reg [31:0] paddr_temp,pwdata_temp,addr;
reg pwrite_temp,penable_temp;
reg [2:0] pselx_temp;
reg hready_out_temp;


//present state logic
always@(posedge hclk or negedge hreset)
  begin
    if(~hreset)
      present_state <= ST_IDLE;
    else
      present_state <= next_state;
  end

  
//next state logic
always@(*)
  begin:ns_block
    next_state <= ST_IDLE;//default state
    case(present_state) 
       ST_IDLE: 
         begin
           if(valid == 1 && hwrite == 0)
			  next_state <= ST_READ;
			else if(valid && hwrite)
			  next_state <= ST_WWAIT;
			else
			  next_state <= ST_IDLE;
		  end

       ST_WWAIT:
         begin
           if(valid)
			 next_state <= ST_WRITEP;
		   else
			 next_state <= ST_WRITE;
		 end

      ST_READ: next_state <= ST_RENABLE;

      ST_WRITE:
        begin
          if(valid)
			 next_state <= ST_WENABLEP;
		  else
			 next_state <= ST_WENABLE;
		end

      ST_WRITEP: next_state <= ST_WENABLEP;

      ST_RENABLE:
        begin
           if(valid == 0)
			  next_state <= ST_IDLE;
		   if(valid == 1 && hwrite == 0)
			  next_state <= ST_READ;
		   else if(valid && hwrite)
			  next_state <= ST_WWAIT;
        end

     ST_WENABLE: 
       begin
         if(valid == 0)
		   next_state <= ST_IDLE;
		 if(valid == 1 && hwrite == 0)
		   next_state <= ST_READ;
		 else if(valid && hwrite)
		   next_state <= ST_WWAIT;
	   end
			 
    ST_WENABLEP: 
      begin
        if(hwrite_reg ==0)
		   next_state <= ST_READ;
		else if(hwrite_reg == 1 && valid == 0)
		  next_state <= ST_WRITE;
		else if(hwrite_reg == 1 && valid == 1)
		  next_state <= ST_WRITEP;
      end
  endcase
end:ns_block
  
  
//signals values
always@(*)
  begin
    paddr_temp = 0;
    pwdata_temp = 0;
    pwrite_temp = 0;
    penable_temp = 0;
    pselx_temp = 0;
    hready_out_temp = 0;
    case(present_state)
      ST_IDLE : hready_out_temp = 1;
      ST_WWAIT : hready_out_temp = 1;
      ST_READ : 
        begin
          paddr_temp = haddr_1;
		  pselx_temp = temp_selx;
		  hready_out_temp = 0;
        end
      ST_RENABLE : 
        begin
          penable_temp = 1;
		  hready_out_temp = 1;
		  paddr_temp = haddr_2;
		  pselx_temp = temp_selx;
        end
      
      ST_WRITE : 
        begin
          paddr_temp = haddr_1;
		  hready_out_temp = 0;
		  pselx_temp = temp_selx;
		  pwdata_temp = hwdata_1;
		  pwrite_temp = 1;
         end
      
      ST_WENABLE :
        begin
           paddr_temp = haddr_1;
		   hready_out_temp = 1;
		   pselx_temp = temp_selx;
		   pwdata_temp = hwdata_1;
		   pwrite_temp = 1;
		   penable_temp = 1;
         end
      
     ST_WRITEP :  
       begin
         paddr_temp = haddr_2;
		 addr = paddr_temp;
		 pselx_temp = temp_selx;
		 pwdata_temp = hwdata_1;
		 pwrite_temp = 1;
       end
      
    ST_WENABLEP :
      begin
        paddr_temp = addr;
	    hready_out_temp = 1;
		pselx_temp = temp_selx;
		pwdata_temp = hwdata_2;
		pwrite_temp = 1;
		penable_temp = 1;
      end
				 
  endcase
end
  
  
always@(posedge hclk)
  begin
    if(~hreset)
      begin
        paddr <= 0;
        pwrite <= 0;
        pwdata <= 0;
        pselx <= 0;
        penable <= 0;
        hready_out <= 0;
      end
    else
      begin
        paddr <= paddr_temp;
        pwrite <= pwrite_temp;
        pwdata <= pwdata_temp;
        pselx <= pselx_temp;
        penable <= penable_temp;
        hready_out <= hready_out_temp;
      end
  end
  
assign hrdata = prdata;
assign hresp  = 0;
  
endmodule : ahb_fsm




