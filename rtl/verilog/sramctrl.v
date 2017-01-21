/*

module sramctrl
	(
		input wire clk_in,
		input wire rst_in,
		input wire trig_in,
		input wire rw_in,
		input wire [18:0] addr_in,
		input wire [7:0] w_data_in,
		
		output reg [7:0] r_data_out,
		output reg done_out,
		output reg we_n_out,
		output reg ce_n_out,
		output reg oe_n_out,
		output reg lb_n_out,
		output reg ub_n_out,
		output reg [17:0] addr_out,
		inout  wire [15:0] data_io
	);
	
	reg[4:0] count;
	reg [15:0]  data_io_reg;
	assign data_io=!rw_in?data_io_reg:16'bz;
	reg state;
	localparam IDLE = 0,
				  START= 1;
	
	
	
	always@(posedge clk_in)
	begin
		if(!rst_in)
		begin
			state<=IDLE;
			done_out<=1'b1;
		end
		else
		begin
			case (state)
			IDLE:
			begin
				ce_n_out<=1'b1;
				if(trig_in)
				begin
					count<=4;
					state<=START;
				end
			end
			START:
			begin
				if(count>0)
				begin
					done_out<=1'b0;
					if(!rw_in)
					begin
						addr_out<=addr_in[18:1];
						if(addr_in[0])
						begin
							data_io_reg[15:8]<=w_data_in;
							data_io_reg[7:0]<=8'b0;
						end
						else
						begin
							data_io_reg[15:8]<=8'b0;
							data_io_reg[7:0]<=w_data_in;
						end
						we_n_out<=1'b0;
						oe_n_out<=1'b1;
						ce_n_out<=1'b0;
						ub_n_out<=addr_in[0];
						lb_n_out<=!addr_in[0];
					end
					else
					begin
						addr_out<=addr_in[18:1];
						if(addr_in[0])
						begin
							r_data_out<=data_io[7:0];
						end
						else
						begin
							r_data_out<=data_io[15:8];
						end
						//data_io_reg<=16'bz;
						we_n_out<=1'b1;
						oe_n_out<=1'b0;
						ce_n_out<=1'b0;
						ub_n_out<=0;
						lb_n_out<=0;
					end
					count<=count-1;
				end
				else
				begin
					done_out<=1'b1;
					state<=IDLE;
				end
			end
			endcase
		end
		
	end
	
	endmodule


*/








module sramctrl
	(
		input wire clk_in,
		input wire rst_in,
		input wire trig_in,
		input wire rw_in,
		input wire [18:0] addr_in,
		input wire [7:0] w_data_in,
		
		output reg [7:0] r_data_out,
		output reg done_out,
		output reg we_n_out,
		output reg ce_n_out,
		output reg oe_n_out,
		output reg lb_n_out,
		output reg ub_n_out,
		output reg [17:0] addr_out,
		inout  wire [15:0] data_io
	);
	
		reg [2:0] state;
		localparam 	init=3'b000,
						idle=3'b001,
						read=3'b010,
						write=3'b011,
						latch=3'b100;
		reg [15:0] data_io_reg;
		reg trig_buf;
		reg [15:0] r_data,w_data;
		assign data_io=data_io_reg;
		  
		always@(posedge clk_in,negedge rst_in)
		begin
			if(!rst_in)
			begin
				state<=init;
			end
			else
			begin
				case(state)
					init:
					begin
						oe_n_out	<=	1'b1;
						ce_n_out	<=	1'b1;
						we_n_out	<=	1'b1;
						addr_out	<=	18'b0;
						data_io_reg<=16'b0;
						state		<=	idle;
					end
					idle:
					begin
						we_n_out	<=	1'b1;
						if(trig_in)
						begin
							if(rw_in)
							begin
								oe_n_out	<=	1'b0;
								
								addr_out	<=addr_in[18:1];
								data_io_reg		<=16'bz;
								done_out		<=1;
								state		<=read;
							end
							else
							begin
								
								oe_n_out	<=	1'b1;
								addr_out	<=addr_in[18:1];
								data_io_reg		<=w_data;
								done_out		<=1;
								state		<=write;
							end
						end
						else
						begin
							oe_n_out	<=	1'b1;
							ce_n_out	<=	1'b0;
							we_n_out	<=	1'b1;
							done_out	<=	1'b1;
							addr_out	<=	18'b0;
							state		<=	idle;
						end
					end
					read:
					begin
						ce_n_out	<=	1'b0;
						oe_n_out	<=	1'b0;
						we_n_out	<=	1'b1;
						r_data	<=	data_io;
						done_out	<=	1'b0;
						state		<=	latch;
					end
					write:
					begin
						ce_n_out	<=	1'b0;
						oe_n_out	<=	1'b1;
						we_n_out	<=	1'b0;
						done_out	<=	1'b0;
						state		<=latch;
					end
					latch:
					begin
						//oe_n_out	<=	1'b1;
						//we_n_out	<=	1'b1;
						r_data	<=	data_io;
						state<=idle;
					end
					default:
					begin
						state<=init;
					end
				endcase
			end
		end
	
	always@*
	begin
		if(!rw_in)
		begin
		if(addr_in[0])
		begin
			ub_n_out<=1'b1;
			lb_n_out<=1'b0;
			w_data[15:8]<=w_data_in;
			w_data[7:0]<=8'b0;
			r_data_out<=r_data[7:0];
		end
		else
		begin
			ub_n_out<=1'b0;
			lb_n_out<=1'b1;
			w_data[15:8]<=8'b0;
			w_data[7:0]<=w_data_in;
			r_data_out<=r_data[15:8];
		end
		end
		else
		begin
		if(addr_in[0])
		begin
			ub_n_out<=1'b0;
			lb_n_out<=1'b0;
			w_data[15:8]<=w_data_in;
			w_data[7:0]<=8'b0;
			r_data_out<=r_data[7:0];
		end
		else
		begin
			ub_n_out<=1'b0;
			lb_n_out<=1'b0;
			w_data[15:8]<=8'b0;
			w_data[7:0]<=w_data_in;
			r_data_out<=r_data[15:8];
		end
		end
	end
	
	
	
endmodule





/*



module sramctrl
	(
		input wire clk_in,
		input wire rst_in,
		input wire trig_in,
		input wire rw_in,
		input wire [18:0] addr_in,
		input wire [7:0] w_data_in,
		
		output reg [7:0] r_data_out,
		output reg done_out,
		output reg we_n_out,
		output reg ce_n_out,
		output reg oe_n_out,
		output reg lb_n_out,
		output reg ub_n_out,
		output reg [17:0] addr_out,
		inout  wire [15:0] data_io
	);
	
		reg [2:0] state;
		localparam 	init=3'b000,
						idle=3'b001,
						read=3'b010,
						write=3'b011,
						latch=3'b100;
		reg [15:0] data_io_reg;
		reg trig_buf;
		reg [15:0] r_data,w_data;
		assign data_io=data_io_reg;
		  
		always@(posedge clk_in,negedge rst_in)
		begin
			if(!rst_in)
			begin
				state<=init;
			end
			else
			begin
				case(state)
					init:
					begin
						oe_n_out	<=	1'b1;
						ce_n_out	<=	1'b1;
						we_n_out	<=	1'b1;
						addr_out	<=	18'b0;
						//data_io_reg<=16'b0;
						state		<=	idle;
					end
					idle:
					begin
						we_n_out	<=	1'b1;
						if(trig_in)
						begin
							if(rw_in)
							begin
								oe_n_out	<=	1'b0;
								
								addr_out	<=addr_in[18:1];
								//data_io_reg		<=16'bz;
								done_out		<=1;
								state		<=read;
							end
							else
							begin
								
								oe_n_out	<=	1'b1;
								addr_out	<=addr_in[18:1];
								//data_io_reg		<=w_data;
								done_out		<=1;
								state		<=write;
							end
						end
						else
						begin
							oe_n_out	<=	1'b1;
							ce_n_out	<=	1'b0;
							we_n_out	<=	1'b1;
							done_out	<=	1'b1;
							addr_out	<=	18'b0;
							state		<=	idle;
						end
					end
					read:
					begin
						ce_n_out	<=	1'b0;
						oe_n_out	<=	1'b0;
						we_n_out	<=	1'b1;
						r_data	<=	data_io;
						done_out	<=	1'b0;
						state		<=	latch;
					end
					write:
					begin
						ce_n_out	<=	1'b0;
						oe_n_out	<=	1'b1;
						we_n_out	<=	1'b0;
						done_out	<=	1'b0;
						state		<=latch;
					end
					latch:
					begin
						//oe_n_out	<=	1'b1;
						//we_n_out	<=	1'b1;
						r_data	<=	data_io;
						state<=idle;
					end
					default:
					begin
						state<=init;
					end
				endcase
			end
		end
	
	always@*
	begin
		if(!rw_in)
		begin
			if(addr_in[0])
			begin
				data_io_reg[15:8]<=w_data_in;
				data_io_reg[7:0]<=8'b0;
				r_data_out<=r_data[7:0];
			end
			else
			begin
				data_io_reg[15:8]<=8'b0;
				data_io_reg[7:0]<=w_data_in;
				r_data_out<=r_data[15:8];
			end
			ub_n_out<=addr_in[0];
			lb_n_out<=!addr_in[0];
		end
		else
		begin
			if(addr_in[0])
			begin
				data_io_reg[15:8]<=8'bz;
				data_io_reg[7:0]<=8'bz;
				r_data_out<=r_data[7:0];
			end
			else
			begin
				data_io_reg[15:8]<=8'bz;
				data_io_reg[7:0]<=8'bz;
				r_data_out=r_data[15:8];
			end
			ub_n_out=1'b0;
			lb_n_out=1'b0;
		end
	end
	
	
	
endmodule
*/


