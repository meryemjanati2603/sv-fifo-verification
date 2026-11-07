// Version d'origine (pointeurs de 3 bits), gardee pour montrer que le banc de test detecte son defaut.
module fifo (
    input  logic       clk, reset, wn, rn,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic       full, empty
);
    logic [7:0] memory [0:7];
    logic [2:0] wptr, rptr;
    always_ff @(posedge clk) begin
        if (reset) begin wptr <= 0; rptr <= 0; data_out <= 0; end
        else begin
            if (wn && !full) begin memory[wptr] <= data_in; wptr <= wptr + 1; end
            if (rn && !empty) begin data_out <= memory[rptr]; rptr <= rptr + 1; end
        end
    end
    assign empty = (wptr == rptr);
    assign full  = (wptr[2:1] == rptr[2:1]) && (wptr[0] != rptr[0]);
endmodule
