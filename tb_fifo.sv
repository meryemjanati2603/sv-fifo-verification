`timescale 1ns/1ps
// Banc de test auto-verifiant du FIFO.
//  1) tests diriges : reset, lecture sur FIFO vide, remplissage jusqu'a "plein", ecriture sur FIFO plein, vidage
//  2) test aleatoire : 5000 cycles d'ecritures et de lectures aleatoires, compares a un modele de reference
//  3) couverture : on compte les situations importantes qui se sont reellement produites
module tb_fifo;
    localparam int DEPTH = 8;

    logic       clk = 0;
    logic       reset = 1;
    logic       wn = 0, rn = 0;
    logic [7:0] data_in = 0;
    logic [7:0] data_out;
    logic       full, empty;

    fifo dut (.*);

    always #5 clk = ~clk;

    // ---------------- modele de reference ----------------
    logic [7:0] model [$];          // file d'attente : ce que le FIFO devrait contenir
    logic [7:0] exp_out = 0;        // valeur attendue sur data_out
    int errors = 0;

    // ---------------- couverture ----------------
    int cov_full = 0, cov_empty = 0, cov_simul = 0, cov_write_full = 0, cov_read_empty = 0;
    int cov_wrap = 0, n_writes = 0, n_reads = 0;

    // A chaque front : on predit l'effet de (wn, rn) avec les drapeaux AVANT le front,
    // puis on verifie les sorties juste apres.
    logic was_full, was_empty;
    always @(posedge clk) begin
        was_full  = (model.size() == DEPTH);
        was_empty = (model.size() == 0);
        if (reset) begin
            model.delete();
            exp_out = 0;
        end else begin
            if (wn && !was_full)  begin model.push_back(data_in); n_writes++; end
            if (rn && !was_empty) begin exp_out = model.pop_front(); n_reads++; end
            if (wn && was_full)   cov_write_full++;
            if (rn && was_empty)  cov_read_empty++;
            if (wn && rn && !was_full && !was_empty) cov_simul++;
        end
    end

    // verification juste apres le front (les sorties du DUT sont stabilisees)
    always @(negedge clk) begin
        if (data_out !== exp_out) begin
            errors++; $display("ERREUR t=%0t data_out=%0d attendu %0d", $time, data_out, exp_out);
        end
        if (empty !== (model.size() == 0)) begin
            errors++; $display("ERREUR t=%0t empty=%0b attendu %0b (contenu %0d)", $time, empty, (model.size() == 0), model.size());
        end
        if (full !== (model.size() == DEPTH)) begin
            errors++; $display("ERREUR t=%0t full=%0b attendu %0b (contenu %0d)", $time, full, (model.size() == DEPTH), model.size());
        end
        if (!reset) begin
            if (full)  cov_full++;
            if (empty) cov_empty++;
        end
    end

    task automatic cycle(input logic w, input logic r, input logic [7:0] d);
        @(negedge clk);
        wn = w; rn = r; data_in = d;
        @(posedge clk);
    endtask

    initial begin
        // ---- reset ----
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;

        // ---- 1) tests diriges ----
        cycle(0, 1, 8'h00);                                  // lecture sur FIFO vide : rien ne doit changer
        for (int i = 1; i <= DEPTH; i++) cycle(1, 0, 8'(i * 11));   // remplit les 8 cases
        cycle(1, 0, 8'hEE);                                  // ecriture sur FIFO plein : ignoree
        for (int i = 1; i <= DEPTH; i++) cycle(0, 1, 8'h00); // vide les 8 cases (ordre premier entre, premier sorti)
        cycle(0, 1, 8'h00);                                  // lecture sur FIFO vide

        // ---- 2) test aleatoire ----
        for (int i = 0; i < 5000; i++) cycle($urandom_range(0, 1), $urandom_range(0, 1), $urandom_range(0, 255));
        cycle(0, 0, 8'h00);

        // ---- reset au milieu du test ----
        cycle(1, 0, 8'hAB); cycle(1, 0, 8'hCD);
        @(negedge clk) reset = 1; wn = 0; rn = 0;
        @(posedge clk); @(negedge clk) reset = 0;
        cycle(0, 0, 8'h00);

        @(negedge clk);
        $display("--------------------------------------------------");
        $display("Ecritures acceptees : %0d, lectures acceptees : %0d", n_writes, n_reads);
        $display("Couverture : plein atteint %0d cycles, vide atteint %0d cycles", cov_full, cov_empty);
        $display("             ecriture sur plein %0d fois, lecture sur vide %0d fois, lecture et ecriture simultanees %0d fois",
                 cov_write_full, cov_read_empty, cov_simul);
        if (cov_full == 0 || cov_empty == 0 || cov_write_full == 0 || cov_read_empty == 0 || cov_simul == 0)
            $display("ATTENTION : une situation importante n'a jamais ete testee");
        if (errors == 0) $display("PASS : 0 erreur");
        else             $display("FAIL : %0d erreur(s)", errors);
        $display("--------------------------------------------------");
        $finish;
    end
endmodule
