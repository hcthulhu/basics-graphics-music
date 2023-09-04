    `define ENABLE_TM1638

module board_specific_top
# (
    parameter   clk_mhz = 27,
                w_key   = 5,  // The last key is used for a reset
                w_sw    = 5,
                w_led   = 6,
                w_digit = 0,
                w_gpio  = 32
)
(
    input                       CLK,

    input  [w_key       - 1:0]  KEY,
    input  [w_sw        - 1:0]  SW,

    input                       UART_RX,
    output                      UART_TX,

    output [w_led       - 1:0]  LED,

    inout  [w_gpio / 4  - 1:0]  GPIO_0,
    inout  [w_gpio / 4  - 1:0]  GPIO_1,
    inout  [w_gpio / 4  - 1:0]  GPIO_2,
    inout  [w_gpio / 4  - 1:0]  GPIO_3
);

    //------------------------------------------------------------------------

    localparam w_tm_key    = 8,
               w_tm_led    = 8,
               w_tm_digit  = 8;

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        localparam w_top_key   = w_tm_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_tm_led,
                   w_top_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_top_key   = w_key,
                   w_top_sw    = w_sw,
                   w_top_led   = w_led,
                   w_top_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_top_key   - 1:0] top_key;
    logic [w_top_sw    - 1:0] top_sw;
    wire  [w_top_led   - 1:0] top_led;
    wire  [w_top_digit - 1:0] top_digit;

    wire                      rst;
    wire  [              7:0] abcdefgh;
    wire  [             23:0] mic;

    //------------------------------------------------------------------------

    `ifdef ENABLE_TM1638    // TM1638 module is connected

        assign rst      = tm_key [w_tm_key - 1];
        assign top_key  = tm_key [w_tm_key - 1:0];
        assign top_sw   = ~ SW;

        assign tm_led   = top_led;
        assign tm_digit = top_digit;

    `else                   // TM1638 module is not connected

        assign rst      = ~ KEY [w_key - 1];
        assign top_key  = ~ KEY [w_key - 1:0];
        assign top_sw   = ~ SW;

        assign LED      = ~ top_led;

    `endif

    //------------------------------------------------------------------------

    top
    # (
        .clk_mhz ( clk_mhz      ),
        .w_key   ( w_top_key    ),  // The last key is used for a reset
        .w_sw    ( w_top_sw     ),
        .w_led   ( w_top_led    ),
        .w_digit ( w_top_digit  ),
        .w_gpio  ( w_gpio       )
    )
    i_top
    (
        .clk      (  CLK        ),
        .rst      (  rst        ),

        .key      (  top_key    ),
        .sw       (  top_sw     ),

        .led      (  top_led    ),

        .abcdefgh (  abcdefgh   ),
        .digit    (  top_digit  ),

        .vsync    (             ),
        .hsync    (             ),

        .red      (             ),
        .green    (             ),
        .blue     (             ),

        .mic      (  mic        ),
        .gpio     (             )
    );

    //------------------------------------------------------------------------

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    tm1638_board_controller
    # (
        .w_digit ( w_tm_digit )
    )
    i_tm1638
    (
        .clk      ( CLK       ),
        .rst      ( rst       ),
        .hgfedcba ( hgfedcba  ),
        .digit    ( tm_digit  ),
        .ledr     ( tm_led    ),
        .keys     ( tm_key    ),
        .sio_clk  ( GPIO_0[2] ),
        .sio_stb  ( GPIO_0[3] ),
        .sio_data ( GPIO_0[1] )
    );

endmodule