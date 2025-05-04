#include "rtc.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <atomic>
#include <thread>
#include <chrono>
#include <iostream>
#define assertm(exp, msg) assert((void(msg), exp))

RTC::RTC(bool enable_vcd, uint32_t rtc_base_addr) : clk_running(false), sim_time(0), _base_addr(rtc_base_addr) {
    top = new Vtb();
    top->clk_i = 0;
    top->rst_ni = 0;
    std::atomic<bool> clk;

    if (enable_vcd) {
        Verilated::traceEverOn(true);            
        vcd = new VerilatedVcdC();
        top->trace(vcd, 99);                    
        vcd->open("vcd/rtc_axi.vcd");             
    } else {
        vcd = nullptr;
    }

      clk_running.store(true);
    clk_thread = std::thread(&RTC::clock_generator, this);
}

RTC::~RTC() {
    clk_running.store(false); 
    std::cout << "sim time " << sim_time << std::endl;
    if (clk_thread.joinable()) {
        clk_thread.join();
    }

    if (vcd) {
        vcd->close(); 
        delete vcd;
    }
    delete top;
}

void RTC::clock_generator() {
    while (clk_running.load()) {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        top->clk_i = !top->clk_i;
        clk.store(top->clk_i);
        top->eval();
        if (vcd) vcd->dump(sim_time); 
        sim_time++;
    }
}

void RTC::wait_clk_posedge() {
    while (true) {
        if (clk.load() == 0) { 
            break;
        }
    }
    while (true) {
        if ( clk.load() == 1) { 
            break;
        }
    }
}

void RTC::wait_clk(uint32_t cycles) {
    for (uint32_t i = 0; i < cycles; i++) {
        wait_clk_posedge();
    }
}

void RTC::reset() {
    wait_clk_posedge();
    top->rst_ni = 0;
    wait_clk(10);
    top->rst_ni = 1;
}

void RTC::axi_write(uint32_t addr, uint32_t value) {
    
    wait_clk_posedge();
    top->axi_awaddr = addr + 0x1000;
    top->axi_awvalid = 1;
    top->axi_wdata = value;
    top->axi_wvalid = 1;
    top->axi_wstrb = 0xF;
    wait_clk_posedge();

    for (int i = 0; i < 10; ++i) {
        if (top->axi_awready && top->axi_wready) break;
        wait_clk_posedge();
    }

    top->axi_awvalid = 0;
    top->axi_wvalid = 0;
    top->axi_bready = 1;
    wait_clk_posedge();

    for (int i = 0; i < 10; ++i) {
        if (top->axi_bvalid) {
            top->axi_bready = 0;
            wait_clk_posedge();
            break;
        }
        
        wait_clk_posedge();
    }

}
uint32_t RTC::axi_read(uint32_t addr) {
    std::cout << "Read transaction | addr: " << std::hex << addr << std::endl;
    wait_clk_posedge();
    top->axi_arprot = 0;
    top->axi_araddr = addr + 0x1000;
    top->axi_arvalid = 1;
    top->axi_rready = 1;
    wait_clk_posedge();

    uint32_t cnt = 0;
    while (!top->axi_arready) {
        wait_clk_posedge();
        if (++cnt >= 5) {
            std::cerr << "AXI Lite read address phase timeout! | addr: " << std::hex << addr << std::endl;
            break;
        }
    }

    top->axi_arvalid = 0;
    wait_clk_posedge();

    cnt = 0;
    while (!top->axi_rvalid) {
        wait_clk_posedge();
        if (++cnt >= 5) {
            std::cerr << "AXI Lite read data phase timeout! | addr: " << std::hex << addr << std::endl;
            break;
        }
    }

    uint32_t data = top->axi_rdata;
    top->axi_rready = 0;
    
    return data;
}

void RTC::set_time(uint32_t time) {
    axi_write(INIT_CLOCK_ADDR, time);
    axi_write(UPDATE_ADDR, UPDATE_CLOCK_MASK);
}

void RTC::set_date(uint32_t date) {
    axi_write(INIT_DATE_ADDR, date);
    axi_write(UPDATE_ADDR, UPDATE_DATE_MASK);
}

void RTC::calibrate(uint16_t seconds) {
    axi_write(CALIBRE_ADDR, (uint32_t)seconds);
    axi_write(UPDATE_ADDR, UPDATE_CALIBRE_MASK);
}

void RTC::set_alarm(uint32_t date, uint32_t time, uint32_t mask) {
    uint32_t alarm_clock_val = (ALARM_CLOCK_EN_MASK | 
                              ((time << ALARM_CLOCK_DATA_POS) & ALARM_CLOCK_DATA_MASK) |
                              ((mask << ALARM_CLOCK_MATCH_MSK_POS) & ALARM_CLOCK_MATCH_MSK_MASK));
    
    axi_write(ALARM_CLOCK_ADDR, alarm_clock_val);
    axi_write(ALARM_DATE_ADDR, date);
    axi_write(UPDATE_ADDR, (UPDATE_ALARM_CLOCK_MASK | UPDATE_ALARM_DATE_MASK));
}

uint32_t RTC::get_time() {
    return axi_read(CLOCK_ADDR);
}

uint32_t RTC::get_date() {
    return axi_read(DATE_ADDR);
}

void RTC::print_status() {
    std::cout << "Current Time: 0x" << std::hex << get_time() << std::endl;
    std::cout << "Current Date: 0x" << std::hex << get_date() << std::endl;
}

void RTC::run_cycles(int cycles) {
    wait_clk(cycles);
}

uint32_t RTC::time_to_sec(uint32_t time) {
    int decimal_sec = ((time & 0xff) / 0x10) * 10 + ((time & 0xff) % 0x10);
    int decimal_min = (((time >> 8) & 0xff) / 0x10) * 10 + (((time >> 8) & 0xff) % 0x10);
    int decimal_hour = (((time >> 16) & 0xff) / 0x10) * 10 + (((time >> 16) & 0xff) % 0x10);

    return decimal_hour * 3600 + decimal_min * 60 + decimal_sec;
}

bool RTC::wait_alarm(uint32_t date, uint32_t time) {
    while (true) {
        wait_clk_posedge();
        if ((get_date() == date) && (get_time() == time)) {
            uint32_t event_flags = axi_read(EVENT_FLAG_ADDR);
            if (event_flags & EVENT_FLAG_ALARM_MASK) {
                return true;
            }
            return false;
        }
    }
}

void RTC::set_timer(uint32_t time) {
    uint32_t timer_cfg = TIMER_CFG_EN_MASK | TIMER_CFG_RETRIG_MASK | 
                        ((time << TIMER_CFG_TARGET_POS) & TIMER_CFG_TARGET_MASK);
    axi_write(TIMER_CFG_ADDR, timer_cfg);
    axi_write(UPDATE_ADDR, UPDATE_TIMER_MASK);
}

bool RTC::wait_timer(uint32_t time) {
    uint32_t cnt = 0;
    axi_write(EVENT_FLAG_ADDR, EVENT_FLAG_TIMER_MASK);
    
    while (true) {
        if (axi_read(EVENT_FLAG_ADDR) & EVENT_FLAG_TIMER_MASK) {
            axi_write(EVENT_FLAG_ADDR, EVENT_FLAG_TIMER_MASK);
            break;
        }
    }
    
    while (true) {
        if (axi_read(EVENT_FLAG_ADDR) & EVENT_FLAG_TIMER_MASK) {
            if (cnt <= time + 10 && cnt >= time - 10) {
                return true;
            }   
            return false; 
        }
        cnt += 3;
    }
}

void RTC::print_time() {
    uint32_t time = get_time();
    uint32_t date = get_date();
    int hour = (time >> 16) & 0xFF;
    int minute = (time >> 8) & 0xFF;
    int second = time & 0xFF;

    int year = (date >> 16) & 0xFFFF;
    int month = (date >> 8) & 0xFF;
    int day = date & 0xFF;

    std::cout << "Date: " << std::hex << year << "-" << month << "-" << day
              << " Time: " << hour << ":" << minute << ":" << second << std::endl;
}