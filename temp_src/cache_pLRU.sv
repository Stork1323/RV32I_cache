import cache_def::*;

module cache_pLRU(
    input logic clk_i,
    input logic rst_ni,
    input logic valid_i,
    input logic [INDEX-1:0] index_i,
    input logic [INDEX_WAY-1:0] address_i,
    output logic [INDEX_WAY-1:0] address_o
);

    /* pseudo LRU tree 8 ways
            L0
          /    \
        L1      L2
       /  \    /  \
     L3    L4 L5   L6

                |   | 0
                 ---
            L3  |   | 1
          /      ---
        L1      |   | 2
       /  \      ---
      /     L4  |   | 3
     /           ---
    L0          |   | 4
     \           ---
      \     L5  |   | 5
       \  /      ---
        L2      |   | 6
          \      ---
            L6  |   | 7
                 ---
    Convention: 0->Up, 1->Down

    ex: address = 3'b100 => L0 = 1 -> L2 = 0 -> L5 = 0
    -------------------- */

    logic L0[0:DEPTH-1], L1[0:DEPTH-1], L2[0:DEPTH-1], L3[0:DEPTH-1], L4[0:DEPTH-1], L5[0:DEPTH-1], L6[0:DEPTH-1];
    logic L0_w[0:DEPTH-1], L1_w[0:DEPTH-1], L2_w[0:DEPTH-1], L3_w[0:DEPTH-1], L4_w[0:DEPTH-1], L5_w[0:DEPTH-1], L6_w[0:DEPTH-1];
    logic [INDEX_WAY-1:0] pLRU;

    always_comb begin
        if (valid_i) L0_w[index_i] = address_i[2];
        else L0_w[index_i] = L0[index_i];
        if ((valid_i) && (address_i[2] == 1'b0)) L1_w[index_i] = address_i[1];
        else L1_w[index_i] = L1[index_i];
        if ((valid_i) && (address_i[2] == 1'b1)) L2_w[index_i] = address_i[1];
        else L2_w[index_i] = L2[index_i];
        if ((valid_i) && (address_i[2] == 1'b0) && (address_i[1] == 1'b0)) L3_w[index_i] = address_i[0];
        else L3_w[index_i] = L3[index_i];
        if ((valid_i) && (address_i[2] == 1'b0) && (address_i[1] == 1'b1)) L4_w[index_i] = address_i[0];
        else L4_w[index_i] = L4[index_i];
        if ((valid_i) && (address_i[2] == 1'b1) && (address_i[1] == 1'b0)) L5_w[index_i] = address_i[0];
        else L5_w[index_i] = L5[index_i];
        if ((valid_i) && (address_i[2] == 1'b1) && (address_i[1] == 1'b1)) L6_w[index_i] = address_i[0];
        else L6_w[index_i] = L6[index_i];
    end


    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (~rst_ni) begin
            L0[0:DEPTH-1] <= {DEPTH{1'b1}};
            L1[0:DEPTH-1] <= {DEPTH{1'b1}};
            L2[0:DEPTH-1] <= {DEPTH{1'b1}};
            L3[0:DEPTH-1] <= {DEPTH{1'b1}};
            L4[0:DEPTH-1] <= {DEPTH{1'b1}};
            L5[0:DEPTH-1] <= {DEPTH{1'b1}};
            L6[0:DEPTH-1] <= {DEPTH{1'b1}};
        end
        else begin
            L0[index_i] <= L0_w[index_i];
            L1[index_i] <= L1_w[index_i];
            L2[index_i] <= L2_w[index_i];
            L3[index_i] <= L3_w[index_i];
            L4[index_i] <= L4_w[index_i];
            L5[index_i] <= L5_w[index_i];
            L6[index_i] <= L6_w[index_i];
        end
    end

    always_comb begin
        pLRU[2] = (~L0[index_i]);
        if (~pLRU[2]) pLRU[1] = (~L1[index_i]);
        else pLRU[1] = (~L2[index_i])
        case ({pLRU[2],pLRU[1]})
            2'b00: pLRU[0] = (~L3[index_i]);
            2'b01: pLRU[0] = (~L4[index_i]);
            2'b10: pLRU[0] = (~L5[index_i]);
            2'b11: pLRU[0] = (~L6[index_i]);
            default: pLRU[0] = 1'b0;
        endcase
    end

    assign address_o = pLRU;

endmodule
