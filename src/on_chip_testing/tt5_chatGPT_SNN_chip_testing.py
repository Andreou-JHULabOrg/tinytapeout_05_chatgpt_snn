from machine import Pin
from ttboard.mode import RPMode
from ttboard.demoboard import DemoBoard
THRESHOLD_ADDR = 0
LEAK_RATE_ADDR = 1
REFRAC_PERIOD_ADDR = 2
FIRST_LAYER_WEIGHTS0_ADDR = 3
FIRST_LAYER_WEIGHTS1_ADDR = 4
SECOND_LAYER_WEIGHTS00_ADDR = 6
SECOND_LAYER_WEIGHTS01_ADDR = 7
SECOND_LAYER_WEIGHTS02_ADDR = 8
SECOND_LAYER_WEIGHTS10_ADDR = 9
SECOND_LAYER_WEIGHTS11_ADDR = 10
SECOND_LAYER_WEIGHTS12_ADDR = 11
SECOND_LAYER_WEIGHTS20_ADDR = 12
SECOND_LAYER_WEIGHTS21_ADDR = 13
SECOND_LAYER_WEIGHTS22_ADDR = 14

def int2bin(x, nbits=8):
    string = '{0:0' + str(nbits) + 'b}'
    return string.format(x)

def spi_write_byte (addr, data):
    tt.in1(0) # spi_cs_n.value = 0;
    tx_data = '0' + int2bin(addr, 4) + int2bin(data, 8) + '000'
    print(f'tx_data = {tx_data}')
    time.sleep_ms(1) # SCK_P/2=1 us ->  SCK=500 kHz
    for i, val in enumerate(tx_data):
        tt.in0(0) #dut.spi_sck.value = 0
        tt.in2(int(tx_data[i])) #dut.spi_copi.value = int(tx_data[i])   
        time.sleep_ms(1) 
        tt.in0(1) #dut.spi_sck.value = 1
        time.sleep_ms(1) 
        print(f'iteration {i}: input is now {tt.input_byte:08b}')
        print(f'iteration {i}: tt.in2 value = {tt.in2()}')
        print(f'iteration {i}: tx_data[i] value = {tx_data[i]}')
    tt.in0(0) #dut.spi_sck.value = 0
    time.sleep_ms(1)
    tt.in1(1)#dut.spi_cs_n.value = 1;
    time.sleep_ms(1)
    print(f'input is now {tt.input_byte:08b}')
    print(f'Output is now {tt.output_byte:08b}')

def apply_spikes(spikes, spike_time_ms): 
    tt.in3(spikes[0])
    tt.in4(spikes[1])
    tt.in5(spikes[2])
    time.sleep_ms(spike_time_ms)
    print(f'input is now {tt.input_byte:08b}')
    print(f'Output is now {tt.output_byte:08b}')

def apply_5spike_patterns(spikes_pattern_1, spike_time_ms_pattern_1,
                           spikes_pattern_2, spike_time_ms_pattern_2,
                           spikes_pattern_3, spike_time_ms_pattern_3,
                           spikes_pattern_4, spike_time_ms_pattern_4,
                           spikes_pattern_5, spike_time_ms_pattern_5):
    apply_spikes( spikes_pattern_1, spike_time_ms_pattern_1)
    apply_spikes( spikes_pattern_2, spike_time_ms_pattern_2)
    apply_spikes( spikes_pattern_3, spike_time_ms_pattern_3)
    apply_spikes( spikes_pattern_4, spike_time_ms_pattern_4)
    apply_spikes( spikes_pattern_5, spike_time_ms_pattern_5)

def apply_5spike_patterns_for_i_times(i_times, spikes_pattern_1, spike_time_ms_pattern_1,
                           spikes_pattern_2, spike_time_ms_pattern_2,
                           spikes_pattern_3, spike_time_ms_pattern_3,
                           spikes_pattern_4, spike_time_ms_pattern_4,
                           spikes_pattern_5, spike_time_ms_pattern_5):
    for i in range (i_times): 
        apply_5spike_patterns(spikes_pattern_1, spike_time_ms_pattern_1,
                           spikes_pattern_2, spike_time_ms_pattern_2,
                           spikes_pattern_3, spike_time_ms_pattern_3,
                           spikes_pattern_4, spike_time_ms_pattern_4,
                           spikes_pattern_5, spike_time_ms_pattern_5)


#debug SPI writing
def spi_writing_test(spi_writings_num, addr, data):
    for i in range (spi_writings_num):
        spi_write_byte( addr, data)

# get a handle to the board
tt = DemoBoard()

# reset
tt.reset_project(True)
time.sleep_ms(1000)
tt.reset_project(False)

# enable the chatgpt_snn_mtomlin5 project
tt.shuttle.tt_um_chatgpt_snn_mtomlin5.enable()

print(f'Project {tt.shuttle.enabled.name} running ({tt.shuttle.enabled.repo})')

tt.in0(0) #dut.spi_sck.value = 0
tt.in2(0) #dut.spi_copi.value = 0
tt.in1(1) #dut.spi_cs_n.value = 1
tt.in3(0) #dut.spikes_in.value = 0
tt.in4(0) #dut.spikes_in.value = 0
tt.in5(0) #dut.spikes_in.value = 0

print(f'input is now {tt.input_byte:08b}')
print(f'Output is now {tt.output_byte:08b}')
print(f'Bidirs is now {tt.bidir_byte:08b}')

tt.dump()

# start automatic project clocking
tt.clock_project_PWM(35e6) # clocking projects @ 50MHz - 20 ns -> measurements demonstrate a maximum clock frequency of 41.7 MHz and the design works up to 35 kHz

apply_spikes( [0,0,0], 50) #(spikes, spike_time_ms)

spi_write_byte( THRESHOLD_ADDR, 15) #THRESHOLD_ADDR = 0
spi_write_byte( LEAK_RATE_ADDR, 4) #LEAK_RATE_ADDR = 1
spi_write_byte( REFRAC_PERIOD_ADDR, 2) #REFRAC_PERIOD_ADDR = 2

spi_write_byte( FIRST_LAYER_WEIGHTS0_ADDR, 7) #FIRST_LAYER_WEIGHTS0_ADDR = 3
spi_write_byte( FIRST_LAYER_WEIGHTS1_ADDR, 14) #FIRST_LAYER_WEIGHTS1_ADDR = 4
spi_write_byte( FIRST_LAYER_WEIGHTS2_ADDR, 18) #FIRST_LAYER_WEIGHTS2_ADDR = 5

spi_write_byte( SECOND_LAYER_WEIGHTS00_ADDR, 21) #SECOND_LAYER_WEIGHTS00_ADDR = 6
spi_write_byte( SECOND_LAYER_WEIGHTS01_ADDR, 25) #SECOND_LAYER_WEIGHTS01_ADDR = 7
spi_write_byte( SECOND_LAYER_WEIGHTS02_ADDR, 11) #SECOND_LAYER_WEIGHTS02_ADDR = 8

spi_write_byte( SECOND_LAYER_WEIGHTS10_ADDR, 12) #SECOND_LAYER_WEIGHTS10_ADDR = 9
spi_write_byte( SECOND_LAYER_WEIGHTS11_ADDR, 16) #SECOND_LAYER_WEIGHTS11_ADDR = 10
spi_write_byte( SECOND_LAYER_WEIGHTS12_ADDR, 17) #SECOND_LAYER_WEIGHTS12_ADDR = 11

spi_write_byte( SECOND_LAYER_WEIGHTS20_ADDR, 13) #SECOND_LAYER_WEIGHTS20_ADDR = 12
spi_write_byte( SECOND_LAYER_WEIGHTS21_ADDR, 19) #SECOND_LAYER_WEIGHTS21_ADDR = 13
spi_write_byte( SECOND_LAYER_WEIGHTS22_ADDR, 24) #SECOND_LAYER_WEIGHTS22_ADDR = 14

apply_5spike_patterns_for_i_times(10, [1,0,0],  5, #(i_times, spikes, spike_time_ms)
    [0,1,0], 10,
    [1,0,1], 12,
    [0,0,0], 5,
    [1,0,1], 10)

apply_5spike_patterns_for_i_times(10, [1,1,0],  10, #(i_times, spikes, spike_time_ms)
    [0,0,1], 12,
    [1,1,1], 14,
    [0,0,0], 10,
    [1,1,1], 11)

apply_5spike_patterns_for_i_times(10, [0,1,0],  10, #(i_times, spikes, spike_time_ms)
    [1,1,1], 10,
    [1,0,1], 20,
    [0,1,0], 15,
    [0,1,1], 21)

apply_5spike_patterns_for_i_times(10, [1,1,1],  10, #(i_times, spikes, spike_time_ms)
    [0,0,1], 7,
    [0,1,1], 6,
    [1,1,0], 8,
    [1,0,0], 9)

apply_5spike_patterns_for_i_times(10, [1,0,1],  6, #(i_times, spikes, spike_time_ms)
    [0,1,0], 7,
    [0,1,1], 9,
    [1,1,0], 11,
    [1,1,1], 15)

apply_spikes( [0,0,0], 50) #(spikes, spike_time_ms)

############################################################################################################
############################################################################################################
# test clock frequency 
tt.clock_project_PWM(40e6) # the design works up to 35 MHz
apply_5spike_patterns_for_i_times(20, [0,0,0],  100, #(i_times, spikes, spike_time_ms)
    [1,1,1], 200,
    [0,0,0], 200,
    [1,1,1], 200,
    [0,0,0], 100)
    
############################################################################################################
############################################################################################################
# test only SPI
spi_writing_test(20, THRESHOLD_ADDR, 13)#(spi_writings_num, addr, data)
 
############################################################################################################
############################################################################################################
# all weights=1
apply_spikes( [0,0,0], 500) #(spikes, spike_time_ms)

spi_write_byte( THRESHOLD_ADDR, 1) #THRESHOLD_ADDR = 0
spi_write_byte( LEAK_RATE_ADDR, 0) #LEAK_RATE_ADDR = 1
spi_write_byte( REFRAC_PERIOD_ADDR, 0) #REFRAC_PERIOD_ADDR = 2

spi_write_byte( FIRST_LAYER_WEIGHTS0_ADDR, 1) #FIRST_LAYER_WEIGHTS0_ADDR = 3
spi_write_byte( FIRST_LAYER_WEIGHTS1_ADDR, 1) #FIRST_LAYER_WEIGHTS1_ADDR = 4
spi_write_byte( FIRST_LAYER_WEIGHTS2_ADDR, 1) #FIRST_LAYER_WEIGHTS2_ADDR = 5

spi_write_byte( SECOND_LAYER_WEIGHTS00_ADDR, 1) #SECOND_LAYER_WEIGHTS00_ADDR = 6
spi_write_byte( SECOND_LAYER_WEIGHTS01_ADDR, 1) #SECOND_LAYER_WEIGHTS01_ADDR = 7
spi_write_byte( SECOND_LAYER_WEIGHTS02_ADDR, 1) #SECOND_LAYER_WEIGHTS02_ADDR = 8

spi_write_byte( SECOND_LAYER_WEIGHTS10_ADDR, 1) #SECOND_LAYER_WEIGHTS10_ADDR = 9
spi_write_byte( SECOND_LAYER_WEIGHTS11_ADDR, 1) #SECOND_LAYER_WEIGHTS11_ADDR = 10
spi_write_byte( SECOND_LAYER_WEIGHTS12_ADDR, 1) #SECOND_LAYER_WEIGHTS12_ADDR = 11

spi_write_byte( SECOND_LAYER_WEIGHTS20_ADDR, 1) #SECOND_LAYER_WEIGHTS20_ADDR = 12
spi_write_byte( SECOND_LAYER_WEIGHTS21_ADDR, 1) #SECOND_LAYER_WEIGHTS21_ADDR = 13
spi_write_byte( SECOND_LAYER_WEIGHTS22_ADDR, 1) #SECOND_LAYER_WEIGHTS22_ADDR = 14

apply_spikes( [1,1,1], 500) #(spikes, spike_time_ms)

# set a PWM on some pin (output to RP2040/input to ASIC)
#tt.in0.pwm(6250000) # set sclk to 6.25 MHz # 160 ns