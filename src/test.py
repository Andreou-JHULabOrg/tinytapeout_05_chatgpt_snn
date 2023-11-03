import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


segments = [ 63, 6, 91, 79, 102, 109, 125, 7, 127, 111 ]

SCK_P = 160
CLK_P = 20

def int2bin(x, nbits=8):
    string = '{0:0' + str(nbits) + 'b}'
    return string.format(x)

async def apply_reset(dut):
    await Timer(100, units="ns")
    dut.rst_n.value = 1

async def spi_write_byte(dut, addr, data):
    dut.spi_cs_n.value = 0;
    tx_data = '0' + int2bin(addr, 4) + int2bin(data, 8) + '000'
    # tx_data = '000' + int2bin(data, 8) + int2bin(addr, 4) + '0'
    await Timer(SCK_P/2, units="ns")
    
    for i, val in enumerate(tx_data):
        dut.spi_sck.value = 0
        dut.spi_copi.value = int(tx_data[i])
        await Timer(SCK_P/2, units="ns")
        dut.spi_sck.value = 1
        await Timer(SCK_P/2, units="ns")

    dut.spi_sck.value = 0
    await Timer(SCK_P/2, units="ns")
    dut.spi_cs_n.value = 1;
    await Timer(SCK_P/2, units="ns")

async def apply_spikes(dut, mask, ncycles):
    dut.spikes_in.value = mask
    await Timer(CLK_P*ncycles, units="ns")
    dut.spikes_in.value = 0

@cocotb.test()
async def test_7seg(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 20, units="ns")

    cocotb.start_soon(clock.start())

    dut._log.info("reset")
    dut.rst_n.value = 0
    dut.spi_sck.value = 0
    dut.spi_copi.value = 0
    dut.spi_cs_n.value = 1
    dut.spikes_in.value = 0
    dut.ena.value = 1

    await apply_reset(dut)
    await spi_write_byte(dut, 1, 1)
    await spi_write_byte(dut, 0, 150)
    await spi_write_byte(dut, 1, 3)
    await spi_write_byte(dut, 2, 5)
    await spi_write_byte(dut, 3, 4)
    await spi_write_byte(dut, 4, 5)
    await spi_write_byte(dut, 5, 6)
    await spi_write_byte(dut, 6, 100)
    await spi_write_byte(dut, 7, 75)
    await spi_write_byte(dut, 8, 50)
    await spi_write_byte(dut, 9, 14)
    await spi_write_byte(dut, 10, 15)
    await spi_write_byte(dut, 11, 16)
    await spi_write_byte(dut, 12, 17)
    await spi_write_byte(dut, 13, 18)
    await spi_write_byte(dut, 14, 19)

    await apply_spikes(dut, 7, 100)

    await spi_write_byte(dut, 3, 100);
    await apply_spikes(dut, 1, 100)

    await ClockCycles(dut.clk, 100)
    