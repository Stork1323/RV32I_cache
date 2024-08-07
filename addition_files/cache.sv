module cache(
   //input
	input logic        clk_i,
	input logic        rst_ni,
	input logic [31:0] address_i,
	input logic [31:0] data_i,
	input logic [31:0] data_mem,
	input logic        data_sel,
	input logic        rd_request,
	input logic        wr_request,
	input logic        mem_ready,
	//output
	output logic        flushE_en,
	output logic        stall_processor,
	output logic        wren_lsu,
	output logic [31:0] data_wb_mem,
	output logic [31:0] data_o,
	output logic [31:0] address_lsu_o,

	/* counter */
	output logic [31:0] no_acc_cache_o,
	output logic [31:0] no_hit_cache_o,
	output logic [31:0] no_miss_cache_o
	/* ------------- */
);
  
  logic [1:0]  index;
  logic [2:0]  block_sel;
  logic [24:0] tag;
  logic [31:0] data;
  logic [24:0] tag_out;
  logic [31:0] data_out;
  logic [31:0] data_cache;
  logic [31:0] address_write;
  logic [31:0] address_read;
  logic [31:0] address_mem;
  logic [31:0] data_lsu;
  logic [31:0] add_lsu;
  //logic        stall_signal;
  //logic        stall;
  //logic        stall_wire;
  logic        dirty;
  logic        valid;
  logic        hit_addr;
  logic        tag_equal;
  logic        wr_cache_en;
 // logic        lsu_en;
  logic        write_hit;
  logic        write_en;
  logic        check_en;
  logic        data_sel_mem;
  logic        hit_final;
  logic        cache_ready;

  
  Input_ff access_reg(
      //input
		.enable_ni (check_en),
		.rst_ni    (rst_ni),
		.address_i (address_i),
		.data_i    (data_i),
		.data_sel_i(data_sel),
		/*
		.rd_i      (rd_request),
		.wr_i      (wr_request),
		.rd_o      (rd_request),
		.wr_o      (wr_request),
		*/
	       //output
	       //
		.index_o   (index),
	        .block_sel_o (block_sel),
		.tag_o     (tag),
		.data_o    (data),
		.data_sel_o(data_sel_mem)
	);
	assign data_wb_mem = data_out;
  cache_table Table(
    //input
    .clk_i       (clk_i),
	 .rst_ni      (rst_ni),
	 .enable_i    (write_en),
	 .dirty_i     (write_hit),
	 .index_i     (index),
	 .block_sel_i (block_sel),
	 .tag_i       (tag),
	 .data_i      (data_cache),
	 //output
	 .cache_ready (cache_ready),
	 .tag_o       (tag_out),
	 .data_o      (data_lsu),
	 .dirty_o     (dirty),
	 .valid_o     (valid)
  );

  tag_cache tag_check(
    .read_tag_i  (address_i[31:7]),
	 .current_tag (tag_out),
	 .equal_o     (tag_equal)
  );
  and_2 andgate(
    .a_i      (valid),
	 .b_i      (tag_equal),
	 .result_o (hit_addr)
  );
  /*
  nand_2 andstall(
    .a_i      (rd_request),
	 .b_i      (hit_addr),
	 .result_o (stall_signal)
  );*/
  and_2 andgate2(
   	 .a_i      (data_sel_mem),
	 .b_i      (hit_addr),
	 .result_o (write_hit)
  );
  or_2 orgate(
   	 .a_i      (data_sel_mem),
	 .b_i      (wr_cache_en),
	 .result_o (write_en)
  );
 
  cache_controller controller(
    //input
   	 .clk_i      (clk_i),
	 .rst_ni     (rst_ni),
	 .dirty_i    (dirty),
	 .hit_i      (hit_addr),

	 .rd_i       (rd_request),
	 .wr_i       (wr_request),
	 .mem_ready  (mem_ready),
	 .cache_ready(cache_ready),
	 .flushE_en  (flushE_en),
   	 .stall_signal    (stall_processor),
	 .check_en        (check_en),
	 .write_cache_en  (wr_cache_en),
	 .write_lsu_en    (wren_lsu),

	 /* connect counter var */
	 .no_acc_o(no_acc_cache_o),
	 .no_hit_o(no_hit_cache_o),
	 .no_miss_o(no_miss_cache_o)
	 /*-----------------*/
  );
 /*
  register control_register(
      //input
		.clk_i        (clk_i),
		.rst_ni       (rst_ni),
		.lsu_wren_i   (wr_lsu_en),
		.cache_wren_i (wr_cache_en),
		.stall_i      (stall_signal),
		.stall_o      (stall_processor),
		.lsu_wren_o   (wren_lsu),
		.cache_wren_o (cache_en)
	);
   */
	
	/*
	nand_2 stall_final(
    .a_i      (stall_wire),
	 .b_i      (stall_signal),
	 .result_o (stall_processor)
  );*/
  mux2_1 muxdata(
   	 .a_i      (data_mem),
	 .b_i      (data_i),
	 .sel      (data_sel_mem),
	 .result_o (data_cache)
  );
  mux2_1 muxdatawb(
   	 .a_i      (data_mem),
	 .b_i      (data_out),
	 .sel      (hit_final),
	 .result_o (data_o)
  );
  fulladder add_write(
	      .a_i   ({tag_out,7'b0}),
			.b_i   ({25'b0,index,block_sel,2'b0}),
			.cin_i (1'b0),
			.cout_o(),
			.s_o   (address_write)
	);
	
	fulladder add_read(
	      .a_i   ({tag,7'b0}),
			.b_i   ({25'b0,index,block_sel,2'b0}),
			.cin_i (1'b0),
			.cout_o(),
			.s_o   (address_read)
	);
	
	mux2_1 address_lsu(
    .a_i      (address_read),
	 .b_i      (add_lsu),
	 .sel      (data_sel_mem),
	 .result_o (address_lsu_o)
  );

   output_ff access_lsu(
	   .enable_ni  (check_en),
		.rst_ni     (rst_ni),
		.hit_i      (hit_addr),
		.address_i  (address_write),
		.data_i     (data_lsu),
		//output
		.hit_o      (hit_final),
		.address_o  (add_lsu),
		.data_o     (data_out)
	);
  
endmodule 
	
	
