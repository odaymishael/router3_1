  module router_fifo(input clock,resetn,write_enb,read_enb,soft_reset,lfd_state,
		                     input[7:0]data_in,
             output  full,empty,
            output reg[7:0]data_out);

                parameter DEPTH=16;
                  parameter WIDTH=9;
                  parameter ADDR=5;

             
               reg [6:0]count;

         reg [WIDTH-1:0]mem[DEPTH-1:0];
         reg [ADDR-1:0]rd_ptr,wr_ptr;
           reg lfd;

            integer i;
     
always@(posedge clock)
begin
if(~resetn)
lfd<=0;
else
lfd<=lfd_state;
end
//write logic
          
            always@(posedge clock)
                 begin
                    
                        if(!resetn)
                              begin
                                //data_out<=0;
                                
 				                   
										   for(i=0;i<DEPTH;i=i+1)
                                   mem[i]<=0;
										 end
										 
                               else if(soft_reset)
                              begin
                                //data_out<=0;
                                 
                                
                             
                             for(i=0;i<DEPTH;i=i+1)
                                   mem[i]<=0;
                                end
                                
                                    else
                                     begin
                                if(write_enb && ~full)
                              {mem[wr_ptr[3:0]][8],mem[wr_ptr[3:0]][7:0]}<={lfd,data_in};
										/*if(read_enb && ~empty )
				                	data_out<=mem[rd_ptr[3:0]];*/
										
                                    end
												end


// read logic
          

             always@(posedge clock)
                 begin
                      
                        if(!resetn)
                              begin
                                data_out<=0;
                                
 				                
									  /*for(j=0;j<DEPTH;j=j+1)
                                  mem[i]<=0;*/
											 end
									  
                               else if(soft_reset)
                              begin
                                data_out<=0;
                                 
                                
                             
                             /*for(j=0;j<DEPTH;j=j+1)
                                  mem[j]<=0;*/
                          end
								  
                            
				              else
					           begin
                  if(read_enb && ~empty )
					data_out<=mem[rd_ptr[3:0]][7:0];
			      end
					end
                       

//pointer logic							  
								always@(posedge clock)
								begin
								if(!resetn)
								begin
					             			rd_ptr<=0;
					    				wr_ptr<=0;
								end
                             if(soft_reset)
                               begin
                                 rd_ptr<=0;
                                  wr_ptr<=0;
 									end
			  		 			  else
		                         begin
		     						if(write_enb && ~full)
								wr_ptr<=wr_ptr+1'b1;
								if(read_enb && ~empty )
                          rd_ptr<=rd_ptr+1'b1;
                          end
								   end
                        						  
                                            

      ///counter logic  	       					
                    
                     
                     always@(posedge clock)
			  begin
                               if(!resetn)
                           count<=0;
                           else if(soft_reset)
                            count<=0;
			 else if(read_enb && ~empty)
				begin
                                 if (mem[rd_ptr[3:0]][8])
					count<=mem[rd_ptr[3:0]][7:2] + 1'b1;
                              	else 
                                   /* if(count>0)
                                 	count<=count-1'b1;*/         
                              // else
                                   	count<=0;    
                             	end
		/*	else
				  count<=0;*/
			  end
         	      

                    
                  	assign full = {wr_ptr[4] != rd_ptr[4]&&wr_ptr[3:0]==rd_ptr[3:0]} ? 1'b1:1'b0;
           	          assign empty = (wr_ptr == rd_ptr);
              								 
                               endmodule



module router_fsm(input clock,resetn,pkt_valid,fifo_full,fifo_empty_0,fifo_empty_1,fifo_empty_2,soft_reset_0,soft_reset_1,soft_reset_2,parity_done,low_packet_valid,
    input [1:0]data_in,
  output  write_enb_reg,detect_add,lfd_state,laf_state,ld_state,full_state,
               rst_int_reg,busy);



reg[7:0]state;
reg[7:0]next_state;

parameter  DECODE_ADDRESS =8'd1;
parameter  CHECK_PARITY_ERROR = 8'd128;
parameter WAIT_TILL_EMPTY  = 8'd64;
parameter LOAD_PARITY = 8'd8;
parameter LOAD_FIRST_DATA=8'd2;
parameter LOAD_DATA = 8'd4;
parameter FIFO_FULL_STATE = 8'd16;
parameter LOAD_AFTER_FULL=8'd32;

//reset

always@(posedge clock)
begin
if(!resetn)
 state<=DECODE_ADDRESS;
else if((soft_reset_0 && data_in ==2'b00) ||(soft_reset_1 && data_in ==2'b01) ||(soft_reset_2 && data_in ==2'b10)) 
state<=DECODE_ADDRESS;
else
state<=next_state;
end



always@(*)
begin
case(state)
        
DECODE_ADDRESS:
              begin  
if((pkt_valid && (data_in[1:0] ==0) && ~fifo_empty_0)||( pkt_valid && (data_in[1:0]==1) && ~fifo_empty_1) || ( pkt_valid && (data_in[1:0] ==2) && ~fifo_empty_2))
 		next_state=WAIT_TILL_EMPTY;

else if((pkt_valid && (data_in[1:0] ==0) && fifo_empty_0)||( pkt_valid && (data_in[1:0] ==1) &&  fifo_empty_1) || ( pkt_valid && (data_in[1:0] ==2) && fifo_empty_2))
 		next_state=LOAD_FIRST_DATA;

else
next_state = DECODE_ADDRESS;
end
LOAD_FIRST_DATA:


next_state = LOAD_DATA;

LOAD_DATA:
begin

if(fifo_full)
  next_state=FIFO_FULL_STATE;
else if(fifo_full ==0 && pkt_valid==0)
 next_state=LOAD_PARITY;
else
next_state=LOAD_DATA;
end

LOAD_PARITY:


next_state=CHECK_PARITY_ERROR;

FIFO_FULL_STATE:
begin
 

if(fifo_full==0)
next_state=LOAD_AFTER_FULL;
else
next_state=FIFO_FULL_STATE;
end

LOAD_AFTER_FULL:
begin
 next_state=LOAD_AFTER_FULL;
if(parity_done == 0 && low_packet_valid ==0 )
   next_state=LOAD_DATA;
else if(parity_done == 0 && low_packet_valid == 1)

 next_state=LOAD_PARITY;

else if(parity_done)
 next_state=DECODE_ADDRESS;
end


WAIT_TILL_EMPTY:
begin
             next_state=WAIT_TILL_EMPTY;
		
		if((fifo_empty_0 || fifo_empty_1 || fifo_empty_2))


    next_state=LOAD_FIRST_DATA;

else if((~fifo_empty_0 ||  ~fifo_empty_1 || ~fifo_empty_2))
next_state=WAIT_TILL_EMPTY;
end

CHECK_PARITY_ERROR:
begin

if(fifo_full)
next_state=FIFO_FULL_STATE;

else 
next_state=DECODE_ADDRESS;
end
endcase
end

assign detect_add = (state == DECODE_ADDRESS);
assign lfd_state = (state == LOAD_FIRST_DATA );
assign busy = (state == LOAD_FIRST_DATA || state == LOAD_PARITY || state == FIFO_FULL_STATE || state == LOAD_AFTER_FULL || state == WAIT_TILL_EMPTY || state == CHECK_PARITY_ERROR);
assign ld_state = (state == LOAD_DATA);
assign write_enb_reg = (state == LOAD_DATA || state== LOAD_PARITY ||state== LOAD_AFTER_FULL);
assign laf_state = (state == LOAD_AFTER_FULL);
assign rst_int_reg = (state == CHECK_PARITY_ERROR);
assign full_state = (state == FIFO_FULL_STATE);

endmodule

module router_sync(input clock ,resetn,detect_add,full_0,full_1,full_2,empty_0,empty_1,empty_2,read_enb_0,read_enb_1,read_enb_2,write_enb_reg,
                    input [1:0] data_in,
                    output reg[2:0]write_enb,
                     output reg fifo_full,soft_reset_0,soft_reset_1,soft_reset_2,
                     output vld_out_0,vld_out_1,vld_out_2);


 reg [4:0]count_0,count_1,count_2;
reg[1:0]temp;
//reg[4:0]count;


//reset
always@(posedge clock)
begin
if(!resetn)
temp<=0;
else if(detect_add)
temp<=data_in;
end

//fifo condtion

always@(*)
begin
if(detect_add)
begin
case(temp)
2'b00:  fifo_full=full_0;
2'b01:  fifo_full=full_1;
2'b10:  fifo_full=full_2;
default: fifo_full=0;
endcase
end
end


//validout


assign vld_out_0 = ~empty_0;
assign vld_out_1 = ~empty_1;
assign vld_out_2 = ~empty_2;



//write enb

always@(*)
begin
if(write_enb_reg)
begin
case(temp)
2'b00: write_enb = 3'b001;
2'b01: write_enb =  3'b010;
2'b10: write_enb =   3'b100;
default:write_enb = 3'b000;
endcase

end
else
write_enb = 3'b000;

end








//counter logic0

always@(posedge clock)
begin
if(!resetn)
begin
soft_reset_0<=0;
count_0<=0;
end
else if(vld_out_0)
begin
if(~read_enb_0)
begin
if(count_0==29)
begin
soft_reset_0<=1;
count_0<=0;
end
else
begin
soft_reset_0<=0;
count_0<=count_0 + 1'b1;
end
end
else
begin
soft_reset_0 <= 0;
count_0 <= 0;
end
end
/*else
begin
soft_reset_0<=0;
count_0 <= 0;
end*/
end


//counter logic1

always@(posedge clock)
begin
if(!resetn)
begin
soft_reset_1<=0;
count_1<=1'b0;
end
else if(vld_out_1)
begin
if(~read_enb_1)
begin
if(count_1==29)
begin
soft_reset_1<=1;
count_1<=0;
end
else
begin
soft_reset_1<=0;
count_1<=count_1 + 1'b1;
end
end
else
begin
soft_reset_1 <= 0;
count_1 <= 0;
end
end
/*else
begin
soft_reset_1<=0;
count_1<=0;
end*/
end



//counter logic2
always@(posedge clock)
begin
if(!resetn)
begin
soft_reset_2<=0;
count_2<=0;
end
else if(vld_out_2)
begin
if(~read_enb_2)
begin
if(count_2==29)
begin
soft_reset_2<=1;
count_2<=0;
end
else
begin
soft_reset_2<=0;
count_2<=count_2 + 1'b1;
end
end
else
begin
soft_reset_2 <= 0;
count_2 <= 0;
end
end
/*else
begin
soft_reset_2<=0;
count_2<=0;
end*/
end
endmodule



 module router_reg(input clock,resetn,pkt_valid,fifo_full,detect_add,ld_state,laf_state,full_state,lfd_state,rst_int_reg,
                  input [7:0]data_in,
                  output reg err,parity_done,low_packet_valid,
 			output reg [7:0]dout);


reg [7:0] header,fifo_full_state_byte,internal_parity;
reg [7:0] packet_parity;


//dout

always@(posedge clock)
begin
if(!resetn)
dout<=0;
else if(detect_add && pkt_valid && data_in[1:0] !=3)
dout<=dout;
else if(lfd_state)
dout<=header;
else if(ld_state)
  begin
      if(~fifo_full)
	dout<=data_in;
      else
       dout<=dout;
  end

else if(laf_state)
dout<=fifo_full_state_byte;

else if(~laf_state)
dout<=dout;
end


//header

always@(posedge clock)
begin
if(!resetn)
header <= 0;
else if(detect_add && pkt_valid && data_in[1:0]!=3)
header <= data_in;
else
header<=header;
end


//fifo_fulll_state

always@(posedge clock)
begin
if(!resetn)
fifo_full_state_byte<=0;
else if(ld_state && fifo_full)
fifo_full_state_byte <=fifo_full_state_byte;
end


//internal parity 


always@(posedge clock)
begin
if(!resetn)
internal_parity<=0;
else if(detect_add)
internal_parity<=0;
else if(lfd_state)
internal_parity<=internal_parity^header;
else if(pkt_valid && ld_state && ~full_state)
internal_parity<=(internal_parity^data_in);
end


//parity done



always@(posedge clock)
begin
if(!resetn)
parity_done<=0;
else if((ld_state && ~fifo_full &&  ~pkt_valid || laf_state && low_packet_valid))
parity_done<=1;
else if(detect_add)
parity_done<=0;
end


//lowpacket


always@(posedge clock)
begin
if(!resetn)
low_packet_valid  <= 0;
else if(rst_int_reg)
low_packet_valid <=0;
else if(~pkt_valid && ld_state)
low_packet_valid<=1;
end


//error


always@(posedge clock)
begin
if(!resetn)
err  <= 0;
else if(packet_parity)
begin
if(packet_parity == internal_parity)
err <= 0;
else
err<=1;
end
end

//packet parirty

always@(posedge clock)
begin
if(!resetn)
packet_parity  <= 0;
else if(detect_add)
packet_parity <=0;
else if(ld_state && ~pkt_valid && ~fifo_full)
packet_parity<= data_in;

end

endmodule


         
module router_top(input pkt_valid,clock,resetn,read_enb_0,read_enb_1,read_enb_2,
                   input [7:0]data_in,
 			output [7:0] data_out_0,data_out_1,data_out_2,
			output vld_out_0,vld_out_1,vld_out_2,err,busy);


wire [2:0]write_enb;
wire [7:0]dout;


  router_sync  S1(clock,resetn,detect_add,full_0,full_1,full_2,fifo_empty_0,fifo_empty_1,fifo_empty_2,read_enb_0,read_enb_1,read_enb_2,write_enb_reg,data_in[1:0],
                    write_enb, fifo_full,soft_reset_0,soft_reset_1,soft_reset_2,vld_out_0,vld_out_1,vld_out_2);

   

 router_reg  S2 ( clock,resetn,pkt_valid,fifo_full,detect_add,ld_state,laf_state,full_state,lfd_state,rst_int_reg,
                   data_in,err,parity_done,low_packet_valid,dout);


router_fsm   S3 ( clock,resetn,pkt_valid,fifo_full,fifo_empty_0,fifo_empty_1,fifo_empty_2,soft_reset_0,soft_reset_1,soft_reset_2,parity_done,low_packet_valid,
    data_in[1:0], write_enb_reg,detect_add,lfd_state,laf_state,ld_state,full_state,rst_int_reg,busy);



router_fifo   S4 (clock,resetn,write_enb[0],read_enb_0,soft_reset_0,lfd_state, dout,full_0,fifo_empty_0,data_out_0);

router_fifo   S5 (clock,resetn,write_enb[1],read_enb_1,soft_reset_1,lfd_state, dout,full_1,fifo_empty_1,data_out_1);
 
router_fifo  S6(clock,resetn,write_enb[2],read_enb_2,soft_reset_2,lfd_state, dout,full_2,fifo_empty_2,data_out_2);
                		                                                                  
                     



endmodule
