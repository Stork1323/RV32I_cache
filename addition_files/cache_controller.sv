module cache_controller(
   //input 
        input logic clk_i,
        input logic rst_ni,
        input logic dirty_i,
        input logic hit_i,
        input logic rd_i,
        input logic wr_i,
        input logic mem_ready,
	input logic cache_ready,
        //input logic mem_ready,
        //output
	output logic flushE_en,
        output logic stall_signal,
        output logic check_en,
        output logic write_cache_en,
        output logic write_lsu_en,

        /* output counter */
        output logic [31:0] no_acc_o,
        output logic [31:0] no_hit_o,
        output logic [31:0] no_miss_o
        /* --------------*/
        );
        
        typedef enum logic [1:0] {idle ,check, write_dirty, write_clean} state;
        state current_state, next_state;
        
        //state register
                //logic rd_cache_en;
        logic wr_cache_en;
        logic wr_lsu_en;
        logic stall;
        logic check_tb; 
        //logic rd_cache_en;

        /* var of counter */
        logic [31:0] no_acc_old_w;
        logic [31:0] no_hit_old_w;
        logic [31:0] no_miss_old_w;

        logic [31:0] no_acc_new_w;
        logic [31:0] no_hit_new_w;
        logic [31:0] no_miss_new_w;

        logic [31:0] no_acc_r;
        logic [31:0] no_hit_r;
        logic [31:0] no_miss_r;

        logic acc1_w; // if access (load or store) acc1_w = 1 otherwise 0
        logic hit1_w; // if cache hit hit1_w = 1 otherwise 0
        logic miss1_w; // if cache miss miss1_w = 1 otherwise 0
        /* -------------------*/

        /* count for additional variables */
        fulladder A_access (
                .a_i(no_acc_old_w),
                .b_i({31'b0, acc1_w}),
                .cin_i(1'b0),
                .cout_o(),
                .s_o(no_acc_new_w)
        );
        fulladder A_hit (
                .a_i(no_hit_old_w),
                .b_i({31'b0, hit1_w}),
                .cin_i(1'b0),
                .cout_o(),
                .s_o(no_hit_new_w)
        );
        fulladder A_miss (
                .a_i(no_miss_old_w),
                .b_i({31'b0, miss1_w}),
                .cin_i(1'b0),
                .cout_o(),
                .s_o(no_miss_new_w)
        );
        always_ff @(posedge clk_i) begin
                if (!rst_ni) begin
                        no_acc_r <= 32'b0;
                        no_hit_r <= 32'b0;
                        no_miss_r <= 32'b0;
                end
                else begin
                        no_acc_r <= no_acc_new_w;
                        no_hit_r <= no_hit_new_w;
                        no_miss_r <= no_miss_new_w;
                end
        end

        assign acc1_w = ((rd_i || wr_i) & (current_state == idle)) ? 1'b1 : 1'b0;
        assign hit1_w = ((rd_i || wr_i) & (current_state == check) & (hit_i)) ? 1'b1 : 1'b0;
        assign miss1_w = ((rd_i || wr_i) & (current_state == check) & (hit_i == 1'b0)) ? 1'b1 : 1'b0;

        assign no_acc_old_w = no_acc_r; // update old value
        assign no_hit_old_w = no_hit_r;
        assign no_miss_old_w = no_miss_r;

        assign no_acc_o = no_acc_r; // update output
        assign no_hit_o = no_hit_r;
        assign no_miss_o = no_miss_r;

        /* --------------- */

        always_ff @(posedge clk_i)
        begin
                if(!rst_ni) 
                current_state <= idle;
                
                else
                current_state <= next_state;
                
        end
        always @(posedge clk_i)
        begin
                if(!rst_ni) begin
                wr_cache_en  <= 1'b0;
                wr_lsu_en    <= 1'b0;
                stall        <= 1'b0;
                check_tb        <=  1'b1;
		flushE_en    <= 1'b0;
                end
        end

        //logic rd_cache_en;

        /*
        initial begin
           wr_cache_en  <= 1'b0;
                wr_lsu_en    <= 1'b0;
                stall        <= 1'b0;
                check_en     <= 1'b1; 
        end*/

        //controller
        always@(*) begin
        case(current_state)
           idle: begin
                      //rd_cache_en  = 1'b0;
                        
                                wr_cache_en  = 1'b0;
                      wr_lsu_en    = 1'b0;
                                stall        = 1'b0;
                                check_tb       = 1'b1; 
				flushE_en    = 1'b0;
                                if(!rd_i && !wr_i) 
                                begin 
                                   next_state = idle;
                                end
                                else if(rd_i || wr_i) begin 
                                next_state = check;
                                end
                                end
                check:
                      begin
                           wr_cache_en  = 1'b1;
                      wr_lsu_en    = 1'b0;
                                stall        = 1'b1;
                                check_tb     = 1'b0;
			    	flushE_en    = 1'b1;	
                                if(hit_i) begin
                                   next_state = idle;
                                end
                                else begin
                                   if(dirty_i) begin
                                                next_state = write_dirty;
                                        end
                                        else begin
                                           next_state = write_clean;
                                   end
                                end
                      end
                write_dirty:
                      begin
                
                      wr_cache_en   = 1'b1;
                      wr_lsu_en     = 1'b1;
                                stall         = 1'b1;
                                check_tb      = 1'b1;
			        flushE_en     = 1'b1;	
                
                                if(mem_ready) begin
                                   next_state = idle;
                                end
                                else begin

                                next_state = write_dirty;
                                end
                                end
                write_clean:
                      begin
                            //rd_cache_en   = 1'b0;
                      		wr_cache_en   = 1'b1;
                                wr_lsu_en     = 1'b0;
                                stall         = 1'b1;
                                check_tb      = 1'b1;
				flushE_en     = 1'b1;
				if(cache_ready)
                                next_state    = idle;
				else next_state = write_clean;
                                end 

        endcase 
        end
	assign check_en   = check_tb;
   assign stall_signal     = stall;
        assign write_cache_en   = wr_cache_en;
        assign write_lsu_en     = wr_lsu_en;
endmodule: cache_controller
                      
                       
                                 
                                
           
        
