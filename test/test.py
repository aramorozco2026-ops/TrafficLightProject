import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Reloj de 50 MHz (periodo de 20 ns)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Aplicar reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Verificar estado inicial tras reset")
    await ClockCycles(dut.clk, 2)

    # Autopista Verde (001) en uo[2:0] y Rural Rojo (100) en uo[5:3] -> 0b00100001
    assert dut.uo_out.value == 0b00100001
