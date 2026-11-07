// FIFO synchrone de 8 mots de 8 bits.
// Les pointeurs d'ecriture et de lecture ont 4 bits : les 3 bits du bas adressent la memoire (8 cases),
// le bit du haut compte les "tours". Il permet de distinguer :
//   - vide : les deux pointeurs sont identiques
//   - plein : memes adresses, mais pas le meme nombre de tours
// La donnee lue sort sur data_out au front d'horloge suivant la lecture (sortie registree).
module fifo (
    input  logic       clk,
    input  logic       reset,
    input  logic       wn,        // demande d'ecriture
    input  logic       rn,        // demande de lecture
    input  logic [7:0] data_in,

    output logic [7:0] data_out,
    output logic       full,
    output logic       empty
);

    logic [7:0] memory [0:7];

    logic [3:0] wptr;
    logic [3:0] rptr;

    always_ff @(posedge clk) begin
        if (reset) begin
            wptr     <= 4'd0;
            rptr     <= 4'd0;
            data_out <= 8'd0;
        end else begin
            if (wn && !full) begin
                memory[wptr[2:0]] <= data_in;
                wptr <= wptr + 4'd1;
            end
            if (rn && !empty) begin
                data_out <= memory[rptr[2:0]];
                rptr <= rptr + 4'd1;
            end
        end
    end

    assign empty = (wptr == rptr);
    assign full  = (wptr[2:0] == rptr[2:0]) && (wptr[3] != rptr[3]);

endmodule
