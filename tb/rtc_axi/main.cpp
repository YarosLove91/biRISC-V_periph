#include "rtc.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    uint32_t rtc_base_addr = 0x1000;
    RTC rtc(VM_TRACE, rtc_base_addr);

    rtc.reset();

    // uint32_t timer_period = 0x96;
    // rtc.set_timer(timer_period);

    // uint32_t alarm_date = 0x20241215;
    // uint32_t alarm_time = 0x12559;
    // uint32_t alarm_flags = 0x0;
    // rtc.set_alarm(alarm_date, alarm_time, alarm_flags);

    uint32_t calibration_value = 9;
    rtc.calibrate(calibration_value);

    uint32_t initial_time = 0x12345;
    uint32_t initial_date = 0x20241215;
    rtc.set_time(initial_time);
    rtc.set_date(initial_date);
    rtc.print_time(); 

    uint32_t start_time = rtc.get_time();
    std::cout << "start_time raw: 0x" << start_time << std::hex << std::endl;

    uint32_t wait_cycles = 1000;
    rtc.wait_clk(wait_cycles);

    uint32_t end_time = rtc.get_time();
    std::cout << "end_time raw: 0x" << end_time << std::hex << std::endl;


    start_time = rtc.time_to_sec(start_time);
    end_time = rtc.time_to_sec(end_time);
    

    //checking the time account
    if (end_time == start_time + (wait_cycles/(calibration_value + 1)))
    {
        std::cout << "Check [0] - OK" << std::endl;
    }
    else
    {
        std::cout << "Check [0] - FAIL" << std::endl;
        std::cout << "Time is not correct:" << std::endl;
        std::cout << "start_time: 0x" << start_time << std::hex << " end_time: 0x" << end_time << std::hex << " expected time: 0x" << start_time + (wait_cycles/(calibration_value + 1)) << std::hex<< std::endl;
        rtc.wait_clk(10);
        return 1;
    }

    // //alarm check
    // if (rtc.wait_alarm(alarm_date, alarm_time) == true)
    // {
    //     std::cout << "Check [1] - OK" << std::endl;
    // }
    // else
    // {
    //     std::cout << "Check [1] - FAIL" << std::endl;
    //     std::cout << "Alarm is not correct:" << std::endl;
    //     rtc.wait_clk(10);
    //     return 1;
    // }

    // //timer check
    // if (rtc.wait_timer(timer_period) == true)
    // {
    //     std::cout << "Check [2] - OK" << std::endl;
    // }
    // else
    // {
    //     std::cout << "Check [2] - FAIL" << std::endl;
    //     std::cout << "Timer is not correct:" << std::endl;
    //     rtc.wait_clk(10);
    //     return 1;
    // }

    rtc.print_time(); 

    #ifdef ENABLE_COVERAGE
    Verilated::threadContextp()->coveragep()->write("logs/coverage.dat");
    #endif
    return 0;
}