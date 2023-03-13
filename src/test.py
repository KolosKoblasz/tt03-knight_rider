import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from random import randrange
from itertools import cycle

CLK_FREQ = 6000

@cocotb.test()
async def test_knight_rider(dut):
    dut._log.info("Define constants")
    ERRORS = 0
    dut._log.info("start simulation")

    # Get initial speed
    speed_levels = get_speed_levels()
    speeds = cycle(speed_levels)
    dut._log.info("speed_levels [HEX]: {}".format([hex(bl) for bl in speed_levels] ))
    dut._log.info("speed_levels [DEC]: {}".format(speed_levels ))

    # Get initial brightness
    brightness_levels = get_brightness_levels()
    brightnesses = cycle(brightness_levels)
    dut._log.info("brightness_levels [HEX]: {}".format([hex(bl) for bl in brightness_levels] ))
    dut._log.info("brightness_levels [DEC]: {}".format(brightness_levels ))

    clock = Clock(dut.clk, int((1/CLK_FREQ)*1e6), units="us")
    cocotb.start_soon(clock.start())

    dut._log.info("reset")
    dut.rst.value = 1
    dut.rate_ctrl.value = 0
    dut.brightness_ctrl.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    dut._log.info("reset deasserted")

    # Get initial speed
    for i in range(len(speed_levels)):
        if next(speeds) == get_act_speed(dut) :
            break

    # Get initial brightness
    for i in range(len(brightness_levels)):
        if next(brightnesses) == get_act_brightness(dut) :
            break

    for brightness in range(5):
        for speed in range(7):
            await ClockCycles(dut.clk, 7000*6 // 4)

            exp_speed = next(speeds)
            dut._log.info("Change speed from: {} to: {}".format(get_act_speed(dut), exp_speed))

            # Change Speed
            dut.rate_ctrl.value = 1
            await ClockCycles(dut.clk, randrange(1,10))
            dut.rate_ctrl.value = 0
            await ClockCycles(dut.clk, 30)

            # Check Speed
            try :
                assert exp_speed == get_act_speed(dut), "Incorrect speed level value!"

            except AssertionError as e:
                ERRORS += 1
                dut._log.error("Exp speed: {} Act speed: {}".format(exp_speed, get_act_speed(dut)))

        exp_brightness = next(brightnesses)
        dut._log.info("Change brightness from: {} to: {}".format(get_act_brightness(dut), exp_brightness))

        # Change brightness
        dut._log.info("Change brightness")
        dut.brightness_ctrl.value = 1
        await ClockCycles(dut.clk, randrange(1,10))
        dut.brightness_ctrl.value = 0
        await ClockCycles(dut.clk, 30)


        # Check brightness
        try :
            assert exp_brightness == get_act_brightness(dut), "Incorrect brightness level value!"

        except AssertionError as e:
            ERRORS += 1
            dut._log.error("Exp brightness: {} Act brightness: {}".format(exp_brightness, get_act_brightness(dut)))

    assert ERRORS == 0 , "Encountered {} errors. Simulation FAILED".format(ERRORS)


def get_speed_levels():
    speed_list = []

    speed_list.append(int(CLK_FREQ / 0.5) - 1 )
    speed_list.append(int(CLK_FREQ / 1  ) - 1 )
    speed_list.append(int(CLK_FREQ / 2  ) - 1 )
    speed_list.append(int(CLK_FREQ / 4  ) - 1 )
    speed_list.append(int(CLK_FREQ / 8  ) - 1 )

    return speed_list

def get_act_speed(dut):

    return dut.knight_rider_KolosKoblasz_inst.rate_ctrl_inst.rc_max_value.value.integer

def get_brightness_levels():
    brightness_list = []
    PWM_RATE = (CLK_FREQ // 50) - 1

    brightness_list.append(PWM_RATE * 1 // 4)
    brightness_list.append(PWM_RATE * 2 // 4)
    brightness_list.append(PWM_RATE * 3 // 4)
    brightness_list.append(PWM_RATE * 4 // 4)

    return brightness_list

def get_act_brightness(dut):

    return dut.knight_rider_KolosKoblasz_inst.brightness_ctrl_inst.brightness_level.value.integer