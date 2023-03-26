#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified
.cpu cortex-m0plus
.thumb
.global main_asm
.align 4

.equ DFLT_STATE_STRT, 1                                        @ Specify the value to start flashing
.equ DFLT_STATE_STOP, 0                                        @ Specify the value to stop flashing
.equ DFLT_ALARM_TIME, 1000000                                  @ Specify the default alarm timeo 
.equ GPIO_BTN_DN_MSK, 0x00040000                               @ Bit-18 for falling-edge event on GP20
.equ GPIO_BTN_EN_MSK, 0x00400000                               @ Bit-22 for falling-edge event on GP21
.equ GPIO_BTN_UP_MSK, 0x04000000                               @ Bit-26 for falling-edge event on GP 
.equ GPIO_BTN_DN, 20                                           @ Specify pin for the "down" button
.equ GPIO_BTN_EN, 21                                           @ Specify pin for the "enter" button
.equ GPIO_BTN_UP, 22                                           @ Specify pin for the "up" button
.equ GPIO_LED_PIN, 25                                          @ Specify pin for the built-in LED
.equ GPIO_DIR_IN, 0                                            @ Specify input direction for a GPIO pin
.equ GPIO_DIR_OUT, 1                                           @ Specify output direction for a GPIO p 
.equ LED_VAL_ON, 1                                             @ Specify value that turns the LED "on"
.equ LED_VAL_OFF, 0                                            @ Specify value that turns the LED "of 
.equ GPIO_ISR_OFFSET, 0x74                                     @ GPIO is int #13 (vector table entry 29)
.equ ALRM_ISR_OFFSET, 0x40                                     @ ALARM0 is int #0 (vector table entry 1 

@ Entry point to the ASM portion of the pr
main_asm:
    movs    r0, #GPIO_LED_PIN                                  @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init                                      @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_LED_PIN                                  @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #GPIO_DIR_OUT                                  @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir                                   @ Call the subroutine to set the GPIO pin specified by r0 to state specified by  
    movs    r0, #GPIO_BTN_UP                                   @ Load the "up" button into r0
    bl      asm_gpio_set_irq                                   @ Set up interrupt handling for "up" button
    movs    r0, #GPIO_BTN_DN                                   @ Load the "down" button into r0    
    bl      asm_gpio_set_irq                                   @ Set up interrupt handling for "down" button
    movs    r0, #GPIO_BTN_EN                                   @ Load the "enter" button into r0
    bl      asm_gpio_set_irq                                   @ Set up interrupt handling for "enter" butt 
    bl      setup_alarm_isr                                    @ Set up the alarm interrupt     
    bl      setup_button_isr                                   @ Set up the button interrupt
    ldr     r0, =ltimer                                        @ Load addresss of the alarm time into r0
    ldr     r0, [r0]                                           @ Load value of the alarm time into r 
    bl      set_alarm                                          @ Call subroutine to set the timer alarm
    ldr     r0, =start_message                                 @ Load start message into r0
    bl      printf                                             @ Print start messag 

main_loop:
    b   main_loop

@ Subroutine to set up the alarm inter
setup_alarm_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)               @ Load vector table address into r2
    ldr     r1, [r2]                                           @ Load value at vector table address into r1
    movs    r2, #ALRM_ISR_OFFSET                               @ Load alarm offset into r2
    add     r2, r1                                             @ Add alarm offset to r1 to get address of the alarm ISR
    ldr     r0, =alarm_isr                                     @ Load alarm ISR address into r0
    str     r0, [r2]                                           @ Save alarm ISR address into vector tab 
    movs    r0, #1                                             @ Load 1 into r0 for clearing and setting interrupt
    ldr     r1, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)          @ Load 1 into r0 for clearing and setting interrupt
    str     r0, [r1]                                           @ Clear the pending interrupt 
    ldr     r1, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)          @ Clear the pending interrupt 
    str     r0, [r1]                                           @ Enable the interrru 
    bx  lr                                                     @ Return from the subrouti 

    
.align 4
msg: .asciz "Hello World!\n"
.data
lstate: .word DFLT_STATE_STRT ltimer: .word DFLT_ALARM_TIME