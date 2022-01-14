module router_top_tb();


reg pkt_valid,clock,resetn,read_enb_0,read_enb_1,read_enb_2;
             reg [7:0]data_in;
 			wire [7:0] data_out_0,data_out_1,data_out_2;
			wire vld_out_0,vld_out_1,vld_out_2,err,busy;



router_top  T1( pkt_valid,clock,resetn,read_enb_0,read_enb_1,read_enb_2,
                  data_in,data_out_0,data_out_1,data_out_2, vld_out_0,vld_out_1,vld_out_2,err,busy);


 					
parameter cycle=20;


//clock generation

always
begin
#(cycle/2);
clock=1'b0;
#(cycle/2);
clock=~clock;
end

//reset

task rst();
begin
@(negedge clock);
resetn=1'b0;
@(negedge clock);
resetn=1'b1;
end
endtask




//packet generation
task good(input [1:0]m,input [5:0]s);


reg[7:0]payload_data,parity,header;
reg[5:0] payload_length;
reg[1:0] addr;
integer i;
begin
@(negedge clock);
wait(~busy)
@(negedge clock);
payload_length=s;
pkt_valid = 1'b1;

addr=m;
header={payload_length,addr};
parity  = 0;
data_in = header;
parity = parity^header;
@(negedge clock);
wait(~busy)
for(i=0;i<payload_length;i=i+1)
begin
@(negedge clock);
wait(~busy)
payload_data={$random}%256;
data_in=payload_data;
parity=parity^payload_data;
end
@(negedge clock);
wait(~busy)
pkt_valid=0;
data_in=parity;
end
endtask

//badpacket scenario
task bad(input [1:0]n,input [5:0] s);


reg[7:0]payload_data,parity,header;
reg[5:0] payload_length;
reg[1:0] addr;
integer i;
begin
@(negedge clock);
wait(~busy)
@(negedge clock);
payload_length=s;
pkt_valid = 1'b1;

addr=n;
header={payload_length,addr};
parity  = 0;
data_in = header;
parity = parity^header;
@(negedge clock);
wait(~busy)
for(i=0;i<payload_length;i=i+1)
begin
@(negedge clock);
wait(~busy)
payload_data={$random}%256;
data_in=payload_data;
parity=parity^payload_data;
end
@(negedge clock);
wait(~busy)
pkt_valid=0;
data_in=~parity;
end
endtask










initial
begin
rst();
good(2'b00,6'd14);
repeat(2)
@(negedge clock);

read_enb_0=1'b1;
wait(~vld_out_0)
@(negedge clock);
read_enb_0=1'b0;
#100;

rst();
bad(2'b00,6'd14);
repeat(2)
@(negedge clock);

read_enb_0=1'b0;
wait(~vld_out_0)
@(negedge clock);
read_enb_0=1'b0;
#100;

rst();
good(2'b01,6'd16);
repeat(2)
@(negedge clock);

read_enb_1=1'b1;
wait(~vld_out_1)
@(negedge clock);
read_enb_1=1'b0;
#100;

rst();
bad(2'b01,6'd16);
repeat(2)
@(negedge clock);
read_enb_1=1'b0;
wait(~vld_out_1)
@(negedge clock);
read_enb_1=1'b0;
#100;

rst();
good(2'b10,6'd17);
repeat(2)
@(negedge clock);

read_enb_2=1'b1;
wait(~vld_out_2)
@(negedge clock);
read_enb_2=1'b0;
#100;

rst();
bad(2'b10,6'd17);
repeat(2)
@(negedge clock);

read_enb_2=1'b0;
wait(~vld_out_2)
@(negedge clock);
read_enb_2=1'b0;
#100;

rst();
good(2'b00,6'd17);
#100;

rst();
good(2'b00,$random%15);
#100;

rst();
bad(2'b00,$random%15);

repeat(2)
@(negedge clock);

read_enb_0=1'b0;
wait(~vld_out_0)
@(negedge clock);
read_enb_0=1'b0;
#100;

rst();
good(2'b00,$random%14);

rst();
good(2'b10,6'd17);
repeat(2)
@(negedge clock);

read_enb_2=1'b0;
wait(~vld_out_2)
@(negedge clock);
read_enb_2=1'b0;
#1000;



rst();
good(2'b11,6'd17);

/*repeat(2)
@(negedge clock);
read_enb_0=1'b1;
wait(~vld_out_0)
@(negedge clock);
read_enb_0=1'b0;*/
#100;


rst();
bad(2'b11,6'd17);
/*repeat(2)
@(negedge clock);
read_enb_0=1'b0;
wait(~vld_out_0)
@(negedge clock);
read_enb_0=1'b0;*/





end
initial $monitor ("pkt_valid=%b,clock=%b,resetn=%b,read_enb_0=%b,read_enb_1=%b,read_enb_2=%b,data_in=%b,data_out_0=%b,data_out_1=%b,data_out_2=%b, vld_out_0=%b,vld_out_1=%b,vld_out_2=%b,err=%b,busy=%b",pkt_valid,clock,resetn,read_enb_0,read_enb_1,read_enb_2,data_in,data_out_0,data_out_1,data_out_2, vld_out_0,vld_out_1,vld_out_2,err,busy);

initial #12000 $finish;

endmodule

