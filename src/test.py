import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


segments = [ 63, 6, 91, 79, 102, 109, 125, 7, 127, 111 ]

SCK_P = 160
CLK_P = 20

def int2bin(x, nbits=8):
    string = '{0:0' + str(8) + 'b}'
    return string.format(x)

async def apply_reset(dut):
    await Timer(100, units="ns")
    dut.rst_n.value = 1

async def apply_input(dut):
    await Timer(100, units="ns")
    dut.ui_in.value = 100
    await Timer(100, units="ns")

async def spi_write_byte(dut, addr, data):
    dut.spi_cs_n.value = 0;
    tx_data = '0' + int2bin(addr) + int2bin(data) + '000'
    await Timer(SCK_P/2, units="ns")
    
    for val in tx_data:
        dut.spi_sck.value = 0
        dut.spi_copi.value = tx_data[15-i]
        await Timer(SCK_P/2, units="ns")
        dut.spi_sck.value = 1
        await Timer(SCK_P/2, units="ns")

    dut.spi_sck.value = 0
    await Timer(SCK_P/2, units="ns")
    dut.spi_cs_n.value = 1;
    await Timer(SCK_P/2, units="ns")

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
    dut.ena.value = 1


    await apply_reset(dut)
    await spi_write_byte(dut, 1, 1)

    await ClockCycles(dut.clk, 100)


    # dut.ui_in.value = 1
    
    # dut.rst_n.value = 1

    # # the compare value is shifted 10 bits inside the design to allow slower counting
    # max_count = dut.ui_in.value << 10
    # dut._log.info(f"check all segments with MAX_COUNT set to {max_count}")
    # # check all segments and roll over
    # for i in range(15):
    #     dut._log.info("check segment {}".format(i))
    #     await ClockCycles(dut.clk, max_count)
    #     # assert int(dut.segments.value) == segments[i % 10]

    #     # all bidirectionals are set to output
    #     assert dut.uio_oe == 0xFF

    # # reset
    # dut.rst_n.value = 0
    # # set a different compare value
    # dut.ui_in.value = 3
    # await ClockCycles(dut.clk, 10)
    # dut.rst_n.value = 1

    # max_count = dut.ui_in.value << 10
    # dut._log.info(f"check all segments with MAX_COUNT set to {max_count}")
    # # check all segments and roll over
    # for i in range(15):
    #     dut._log.info("check segment {}".format(i))
    #     await ClockCycles(dut.clk, max_count)
    #     # assert int(dut.segments.value) == segments[i % 10]

