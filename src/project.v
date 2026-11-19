`default_nettype none

module tt_um_traffic_light_controller (
    input  wire [7:0] ui_in,    // Entradas dedicadas
    output wire [7:0] uo_out,   // Salidas dedicadas (luces de semáforo)
    input  wire [7:0] uio_in,   // Bidireccionales: entrada
    output wire [7:0] uio_out,  // Bidireccionales: salida
    output wire [7:0] uio_oe,   // Bidireccionales: enable (0=entrada, 1=salida)
    input  wire       ena,      // Siempre 1 cuando el diseño está activo
    input  wire       clk,      // Reloj (50 MHz)
    input  wire       rst_n     // Reset activo en bajo
);

    // Estados de la FSM
    localparam [1:0] HGRE_FRED = 2'b00, // Autopista Verde, Rural Rojo
                     HYEL_FRED = 2'b01, // Autopista Amarillo, Rural Rojo
                     HRED_FGRE = 2'b10, // Autopista Rojo, Rural Verde
                     HRED_FYEL = 2'b11; // Autopista Rojo, Rural Amarillo

    // Divisor para 1 segundo con reloj de 50 MHz (50,000,000 ciclos)
    localparam [25:0] ONE_SEC_MAX = 26'd49_999_999;

    reg [25:0] count;
    reg [3:0]  count_delay;
    reg        delay10s_hw, delay3s_hw, delay10s_farm, delay3s_farm;
    reg        en_HG, en_HY, en_FG, en_FY;
    reg [1:0]  state, next_state;
    reg [2:0]  light_highway, light_farm;

    wire clk_enable = (count == ONE_SEC_MAX);

    // Mapeo de salidas a los pines de Tiny Tapeout
    assign uo_out  = {2'b00, light_farm, light_highway};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Silenciar advertencias de pines no usados
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

    // FSM: Registro de estado
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= HGRE_FRED;
        else
            state <= next_state;
    end

    // FSM: Lógica combinacional (Luces y Transiciones)
    always @(*) begin
        en_HG = 1'b0;
        en_HY = 1'b0;
        en_FG = 1'b0;
        en_FY = 1'b0;
        light_highway = 3'b001;
        light_farm    = 3'b100;
        next_state    = HGRE_FRED;

        case (state)
            HGRE_FRED: begin
                light_highway = 3'b001; // Autopista Verde
                light_farm    = 3'b100; // Rural Rojo
                en_HG = 1'b1;
                next_state = delay10s_hw ? HYEL_FRED : HGRE_FRED;
            end
            HYEL_FRED: begin
                light_highway = 3'b010; // Autopista Amarillo
                light_farm    = 3'b100; // Rural Rojo
                en_HY = 1'b1;
                next_state = delay3s_hw ? HRED_FGRE : HYEL_FRED;
            end
            HRED_FGRE: begin
                light_highway = 3'b100; // Autopista Rojo
                light_farm    = 3'b001; // Rural Verde
                en_FG = 1'b1;
                next_state = delay10s_farm ? HRED_FYEL : HRED_FGRE;
            end
            HRED_FYEL: begin
                light_highway = 3'b100; // Autopista Rojo
                light_farm    = 3'b010; // Rural Amarillo
                en_FY = 1'b1;
                next_state = delay3s_farm ? HGRE_FRED : HRED_FYEL;
            end
            default: begin
                next_state = HGRE_FRED;
            end
        endcase
    end

    // Temporizadores de las luces (con reset asíncrono para ASIC)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_delay   <= 4'd0;
            delay10s_hw   <= 1'b0;
            delay3s_hw    <= 1'b0;
            delay10s_farm <= 1'b0;
            delay3s_farm  <= 1'b0;
        end else if (clk_enable) begin
            if ((count_delay == 4'd9) && en_HG) begin
                delay10s_hw <= 1'b1; delay3s_hw <= 1'b0; delay10s_farm <= 1'b0; delay3s_farm <= 1'b0;
                count_delay <= 4'd0;
            end else if ((count_delay == 4'd2) && en_HY) begin
                delay10s_hw <= 1'b0; delay3s_hw <= 1'b1; delay10s_farm <= 1'b0; delay3s_farm <= 1'b0;
                count_delay <= 4'd0;
            end else if ((count_delay == 4'd9) && en_FG) begin
                delay10s_hw <= 1'b0; delay3s_hw <= 1'b0; delay10s_farm <= 1'b1; delay3s_farm <= 1'b0;
                count_delay <= 4'd0;
            end else if ((count_delay == 4'd2) && en_FY) begin
                delay10s_hw <= 1'b0; delay3s_hw <= 1'b0; delay10s_farm <= 1'b0; delay3s_farm <= 1'b1;
                count_delay <= 4'd0;
            end else begin
                delay10s_hw <= 1'b0; delay3s_hw <= 1'b0; delay10s_farm <= 1'b0; delay3s_farm <= 1'b0;
                if (en_HG || en_HY || en_FG || en_FY)
                    count_delay <= count_delay + 4'd1;
            end
        end
    end

    // Generador de pulso de 1 segundo (con reset para ASIC)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 26'd0;
        else if (count == ONE_SEC_MAX)
            count <= 26'd0;
        else
            count <= count + 26'd1;
    end

endmodule
