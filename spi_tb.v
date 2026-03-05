 `timescale 1ns / 1ps

module tb_spi_master_all_modes();

    // ==========================================
    // 1. Signal Declarations (Verilog Style)
    // ==========================================
    // Inputs to DUT (Registers in testbench)
    reg clk;
    reg rst;
    reg start;
    reg cpol;
    reg cpha;
    reg [7:0] data_in;
    reg MISO;

    // Outputs from DUT (Wires in testbench)
    wire MOSI;
    wire ss;
    wire finish;
    wire SCLK;
    wire [7:0] data_out;

    // ==========================================
    // 2. DUT Instantiation
    // ==========================================
    top uut (
        .clk(clk), 
        .rst(rst), 
        .start(start),
        .cpol(cpol),
        .cpha(cpha),
        .data_in(data_in), 
        .MOSI(MOSI), 
        .ss(ss), 
        .finish(finish), 
        .SCLK(SCLK), 
        .MISO(MISO), 
        .data_out(data_out)
    );

    // ==========================================
    // 3. System Clock Generation
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // ==========================================
    // 4. The "Smart" Mock Slave Logic
    // ==========================================
    // This slave adapts to CPOL and CPHA settings.
    reg [7:0] slave_tx_data;
    reg [7:0] slave_rx_data;

    // Determine the edges dynamically based on CPOL
    wire leading_edge  = (cpol == 0) ? SCLK : ~SCLK;
    wire trailing_edge = (cpol == 0) ? ~SCLK : SCLK;

    // Edge detection logic for the slave
    reg prev_leading_edge;
    reg prev_trailing_edge;
    reg prev_ss;

    always @(posedge clk) begin
        prev_leading_edge <= leading_edge;
        prev_trailing_edge <= trailing_edge;
        prev_ss <= ss;
    end

    wire rising_leading = (leading_edge == 1'b1 && prev_leading_edge == 1'b0);
    wire rising_trailing = (trailing_edge == 1'b1 && prev_trailing_edge == 1'b0);
    wire falling_ss = (ss == 1'b0 && prev_ss == 1'b1);

    always @(posedge clk) begin
        if (rst) begin
             MISO <= 1'b0;
             slave_tx_data <= 8'hA5; // Data the slave sends
             slave_rx_data <= 8'h00;
        end else if (ss) begin
             MISO <= 1'b0; // High-Z ideally, but 0 is fine for simulation
             // Reset the data we want to send back for the next test
             slave_tx_data <= 8'hA5; 
        end else begin
            // --- Mode 0 and 2 (CPHA = 0) ---
            if (cpha == 0) begin
                if (falling_ss || rising_trailing) begin
                    // Shift out immediately on SS falling, or on the trailing edge
                    MISO <= slave_tx_data[7];
                    if (rising_trailing) begin
                        slave_tx_data <= {slave_tx_data[6:0], 1'b0};
                    end
                end
                if (rising_leading) begin
                    // Sample on leading edge
                    slave_rx_data <= {slave_rx_data[6:0], MOSI};
                end
            end 
            // --- Mode 1 and 3 (CPHA = 1) ---
            else begin
                if (rising_leading) begin
                    // Shift out on leading edge
                    MISO <= slave_tx_data[7];
                    slave_tx_data <= {slave_tx_data[6:0], 1'b0};
                end
                if (rising_trailing) begin
                     // Sample on trailing edge
                     slave_rx_data <= {slave_rx_data[6:0], MOSI};
                end
            end
        end
    end

    // ==========================================
    // 5. Verification Task
    // ==========================================
    // Reusable block to run a transmission and check the result
    task run_test;
        input [7:0] test_tx_data;
        input [7:0] expected_rx_data;
        begin
            // Setup data and pulse start
            data_in = test_tx_data;
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for the SPI state machine to assert finish
            wait(finish == 1);
            
            // Wait a few cycles to ensure data_out has latched
            repeat(5) @(posedge clk);

            // Check the result
            if (data_out == expected_rx_data) begin
                $display("[%0t] SUCCESS: Sent %h, Master Received %h.", $time, test_tx_data, data_out);
            end else begin
                $display("[%0t] FAILURE: Sent %h, Expected Master to Receive %h, Got %h.", $time, test_tx_data, expected_rx_data, data_out);
            end
        end
    endtask

    // ==========================================
    // 6. Main Test Sequence
    // ==========================================
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        cpol = 0;
        cpha = 0;
        data_in = 8'h00;

        // Wait for reset to finish
        #100;
        rst = 0;
        #50;

        // --------------------------------------------------
        // Test Mode 0 (CPOL=0, CPHA=0)
        // --------------------------------------------------
        $display("==== STARTING MODE 0 TESTS ====");
        cpol = 0; cpha = 0; 
        #50; // Give the clock gen time to settle if CPOL changes
        run_test(8'hC3, 8'hA5); // Expecting to receive the slave's default 0xA5
        #50;

        // --------------------------------------------------
        // Test Mode 1 (CPOL=0, CPHA=1)
        // --------------------------------------------------
        $display("==== STARTING MODE 1 TESTS ====");
        cpol = 0; cpha = 1; 
        #50;
        run_test(8'h55, 8'hA5);
        #50;

        // --------------------------------------------------
        // Test Mode 2 (CPOL=1, CPHA=0)
        // --------------------------------------------------
        $display("==== STARTING MODE 2 TESTS ====");
        cpol = 1; cpha = 0; 
        #50;
        run_test(8'hF0, 8'hA5);
        #50;

        // --------------------------------------------------
        // Test Mode 3 (CPOL=1, CPHA=1)
        // --------------------------------------------------
        $display("==== STARTING MODE 3 TESTS ====");
        cpol = 1; cpha = 1; 
        #50;
        run_test(8'h0F, 8'hA5);
        #50;

        $display("==== ALL SIMULATIONS COMPLETE ====");
        $finish;
    end

endmodule