## How it works

Este proyecto implementa un controlador de semáforo sincronizado para dos vías (Autopista y Camino Rural) utilizando una máquina de estados finitos (FSM) de 4 estados en Verilog.

Cuenta con un divisor de frecuencia configurado para un reloj de 50 MHz que genera un pulso cada segundo, alternando el paso automáticamente con ciclos de 10 segundos en verde y 3 segundos en amarillo para cada vía.

## How to test

1. Aplica un pulso de reset poniendo `rst_n` en bajo (`0`) y después en alto (`1`).
2. Verifica que las salidas inicien en Autopista Verde (`uo[0] = 1`) y Camino Rural Rojo (`uo[5] = 1`).
3. Mantén el reloj corriendo a 50 MHz para observar la transición automática entre los 4 estados del semáforo.

## External hardware

6 LEDs con sus respectivas resistencias limitadoras conectados a los pines de salida dedicados `uo[0]` a `uo[5]`.
