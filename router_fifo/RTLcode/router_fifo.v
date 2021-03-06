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



/*module router_fifo(clock,resetn,write_enb,read_enb,soft_reset,lfd_state,data_in,full,empty,data_out);

input  clock,resetn,write_enb,read_enb,soft_reset,lfd_state;
input  [7:0] data_in;   
output  reg full,empty;
output reg [7:0] data_out;
        
parameter DEPTH=16;
parameter WIDTH=9;
parameter ADDR=4;
reg [6:0] count;
reg [ADDR-1:0] fifo_count;
reg [5:0]payloadlength ; 
reg [7:0]headerbyte ; 
reg [1:0]fifolocaton ;
reg [7:0]paritybyte;  
reg [WIDTH-1:0]mem[DEPTH-1:0];
reg [ADDR-1:0]rd_ptr,wr_ptr;                        
integer i;  

always@(posedge clock )
begin 
 if(~soft_reset && wr_ptr ==0 && rd_ptr==0 )
begin
data_out <=8'b00000000; 
end 
end

always@(posedge clock ) 
if(~resetn)
begin 
data_out<=8'b00000000;

for(i=0;i<DEPTH;i=i+1)
begin 
mem[i]<=0;
end 
wr_ptr<=0;
rd_ptr<=0;
count<=0;					    				
fifo_count<=0;
payloadlength <=0;
headerbyte <=0;
fifolocaton <= 0 ;
paritybyte <=0;

end 

else if(soft_reset)
begin 
for(i=0;i<DEPTH;i=i+1)
begin 
mem[i]<=0;
end 
wr_ptr<=0;
rd_ptr<=0;
count<=0;
fifo_count<=0;
payloadlength <=0;
headerbyte <=0;
fifolocaton <=0; 
paritybyte <=0; 
data_out<=8'bzzzzzzzz;
end

else if(write_enb && ~full && (wr_ptr<=payloadlength))
begin
if (lfd_state ==1) 
begin 
{headerbyte,payloadlength,fifolocaton} <={data_in[7:0],data_in[7:2],data_in[1:0]};
end 

else 
begin 
{mem[wr_ptr[3:0]][8],mem[wr_ptr[3:0]][7:0]}<={lfd_state,data_in};
wr_ptr<=wr_ptr+1'b1;	
{paritybyte} <= {mem[payloadlength-1][7:0]};
end 

//if (mem [4]  > 0 )



end 				

else if(read_enb && ~empty && (rd_ptr<=payloadlength) )
begin
data_out<=mem[rd_ptr[3:0]][7:0];
rd_ptr<=rd_ptr+1'b1;

end 


always@(posedge clock ) 
begin 
//if (~resetn)
//fifo_count<=0 ; 
//else 
begin 
case ({write_enb,read_enb }) 
2'b00 :fifo_count <= fifo_count ;
2'b01 :fifo_count <= (fifo_count ==0)?0:fifo_count -1 ; 
2'b10 :fifo_count <= (fifo_count ==16)?16:fifo_count +1 ;
2'b11 :fifo_count<= fifo_count ;
default :fifo_count<=fifo_count ; 
endcase 
end 
end 

always@(posedge clock)
begin
full=(fifo_count==15);
empty=(fifo_count==0);
    
end  

endmodule */

          