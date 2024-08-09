package cache_def;
    // data structure for cache tag and data

    parameter int TAGMSB = 31; // tag msb
    parameter int TAGLSB = 7; // tag lsb
    parameter int INDEX = 2; // No of block bits
    parameter int DEPTH = 4; // No of blocks
    parameter int WAYS = 8; // No of ways
    parameter int DATA_WIDTH = 32; // No bits of cache line data
    parameter int INDEX_WAY = 3; // No bit of way address

    // data structure for cache tag
    typedef struct packed {
        logic [WAYS-1:0] valid; // valid bit
        logic [WAYS-1:0] dirty; // dirty bit
        logic [WAYS*TAGMSB:(WAYS-1)*TAGLSB] tag; // tag bits
    } cache_tag_type;

    // data structure for cache memory request 
    typedef struct {
        logic [INDEX_WAY+INDEX-1:0] index;
        logic we; // write enable
    } cache_req_type;

    // 128-bit cache line data
    //typedef logic [127:0] cache_data_type;
    typedef logic [WAYS*DATA_WIDTH-1:0] cache_data_type;

    //--------------------------
    // data structures for CPU <=> Cache constroller interface

    // CPU request (CPU -> cache controller)
    typedef struct {
        logic [31:0] addr; // 32-bit request addr
        logic [31:0] data; // 32-bit request data (used when write)
        logic rw; // request type : 0 = read, 1 = write
        logic valid;
    } cpu_req_type;

    // Cache result (cache controller -> CPU)
    typedef struct {
        logic [31:0] data; // 32-bit data
        logic ready; // result is ready
    } cpu_result_type;

    //-----------------------------------
    // data structures for cache controller <-> memory interface
    
    // memory request (cache controller -> memory)
    typedef struct {
        logic [31:0] addr; // request byte addr
        cache_data_type data; // 128-bit request data (used when write)
        logic rw; // request type : 0 = read, 1 = write
        logic valid; // request is valid
    } mem_req_type;

    // memory response (memory -> cache controller)
    typedef struct {
        cache_data_type data; // 128-bit read back data
        logic ready; // data is ready
    } mem_data_type;

endpackage
