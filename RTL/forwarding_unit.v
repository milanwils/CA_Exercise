module forwarding_unit
    #(
   parameter integer DATA_W = 5
   )(
      input  wire [DATA_W-1:0] Rs,
      input  wire [DATA_W-1:0] Rt,
      input  wire [DATA_W-1:0] Rd_EX_MEM,
      input  wire [DATA_W-1:0] Rd_MEM_WB,
      output reg  [1:0] forward_a,
      output reg  [1:0] forward_b
   );

   always @(*) begin // Forwarding for Rs
      if (Rs == Rd_EX_MEM) begin
         forward_a = 2'b10;
      end else if (Rs == Rd_MEM_WB) begin
         forward_a = 2'b11;
      end else begin // No forwarding
         forward_a = 2'b00;
      end
   end

   always @(*) begin // Forwarding for Rt
      if (Rt == Rd_EX_MEM) begin
         forward_b = 2'b10;
      end else if (Rt == Rd_MEM_WB) begin
         forward_b = 2'b11;
      end else begin // No forwarding
         forward_b = 2'b00;
      end
   end

endmodule