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
    b       main_loop                                          @ Infinite lo 

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

@ Subroutine that sets up the button inter
setup_button_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)               @ Load vector table address into r2 
    ldr     r1, [r2]                                           @ Load value at vector table address into r1
    movs    r2, #GPIO_ISR_OFFSET                               @ Load button offset into r2
    add     r2, r1                                             @ Add button offset to r1
    ldr     r0, =button_isr                                    @ Load address of button ISR into r0
    str     r0, [r2]                                           @ Store the address of the button ISR into the vector tab 
    movs    r0, #1                                             @ Load 1 into r0 for clearing and setting interrupts
    movs    r0, r0, LSL #13                                    @ Shift interrupt enable bit into correct position
    ldr     r1, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)          @ Load offsetted NVIC Interrupt Clear Pending register address into r1            
    str     r0, [r1]                                           @ Clear any pending interrupts for the button
    ldr     r1, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)          @ Load offsetted NVIC Interrupt Set Enable register address into r1
    str     r0, [r1]                                           @ Enable interrupts for the butt 
    bx  lr                                                     @ Return from the subroutine

@ Subroutine that triggers the timer alarm after the interval specified in r0
set_alarm:
    ldr     r2, =(TIMER_BASE + TIMER_INTE_OFFSET)              @ Load offsetted address of timer interrupt enable register into r2
    movs    r1, #1                                             @ Set r1 to 1 to enable timer interrupt
    str     r1, [r2]                                           @ Enable the timer inter
    ldr     r2, =(TIMER_BASE + TIMER_TIMELR_OFFSET)            @ Load offsetted address of timer value register into r2
    ldr     r1, [r2]                                           @ Load current timer value into r1
    add     r1, r0                                             @ Add desired interval to current timer value to get timer value at which alarm should be trigge
    ldr     r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)            @ Load offsetted address of timer alarm register into r2
    str     r1, [r2]                                           @ Store calculated time value into timer alaram regis
    bx  lr                                                     @ Return from the subroutine

@ Interrupt Service Routine for Alarm
.thumb_func                                                    @ Required for interrupt handling
alarm_isr:
    push    {lr}                                               @ Store link register to the stack as we call nested subroutines
    ldr     r0, =alarm_message                                 @ Load alarm message string into r0
    bl      printf                                             @ Print mes
    ldr     r2, =(TIMER_BASE + TIMER_INTR_OFFSET)              @ Load offsetted address of timer interrupt register into r2
    movs    r1, #1                                             @ Set r1 to 1 to acknowledge the timer interrupt
    str     r1, [r2]                                           @ Store r1 back int
    ldr     r1, =lstate                                        @ Load address of the LED's state into r1       
    ldr     r1, [r1]                                           @ Load value of the LED's state into r1    
    cmp     r1, DFLT_STATE_STOP                                @ Compare value of LED state with the stop state
    beq     no_toggle                                          @ If LED state is equal to the stop state, don't toggle LED
    bl      toggle_led                                         @ Else, call toggle_led subroutine to toggle the state of the

no_toggle:
    ldr     r0, =ltimer                                        @ Load address of alarm timer interval into r0
    ldr     r0, [r0]                                           @ Load value of alarm timer interval into r0           
    bl      set_alarm                                          @ Call set_alarm subroutine to set a new alarm timer inter
    pop     {pc}                                               @ Restore return address and return to main pro

toggle_led:
    push    {lr}                                               @ Store the link register to the stack as we will call nested subroutines
    movs    r0, #GPIO_LED_PIN                                  @ Set the LED GPIO pin number to r0 for use by asm_gpio_get
    bl      asm_gpio_get                                       @ Get current the value of the LED GPIO pin (returns to r0)
    cmp     r0, #LED_VAL_OFF                                   @ Check if the LED GPIO pin value is "off"
    beq     led_set_on                                         @ If it is "off" then then jump code to to turn it on
led_set_off:                       
    movs    r1, #LED_VAL_OFF                                   @ The LED is currently "on" so we want to turn it "off"
    b       led_set_state                                      @ Jump to portion of code where we set the state of the LED
led_set_on:                    
    movs    r1, #LED_VAL_ON                                    @ The LED is currently "off" so we want to turn it "on"
led_set_state:                     
    movs    r0, #GPIO_LED_PIN                                  @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
    bl      asm_gpio_put                                       @ Update the the value of the LED GPIO pin (based on value in 
    pop     {pc}                                               @ Pop the link register from the stack to the program cou

@ Interrupt Service Routine for B
.thumb_func                                                    @ Required for interrupt handling
button_isr:
    push    {lr}                                               @ Save the link register onto the stack                   
    @ Check which button was pr
    ldr     r1, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET) @ Load offsetted address of GPIO interrupt status register into r1              
    ldr     r2, [r1]                                           @ Load value at offsetted address into
    ldr     r3, =GPIO_BTN_UP_MSK                               @ Load r3 with the "up" button mask          
    ands    r3, r2                                             @ AND value in r2 with r3, leaving only the relevant bit for up button
    cmp     r3, #0                                             @ Compare r3 with 0 
    bne     up_button_triggered                                @ Branch to up_button_triggered subrouint if r3 is not equal 
    ldr     r3, =GPIO_BTN_DN_MSK                               @ Load r3 with the "down" button mask               
    ands    r3, r2                                             @ AND the value in r2 with r3, leaving only the relevant bit for down button    
    cmp     r3, #0                                             @ Compare r3 with 0
    bne     down_button_triggered                              @ Branch to down_button_triggered subroutine if r3 is not equal t
    b       enter_button_triggered                             @ If execution reaches here, then enter button must have been triggered
                                                               @ Branch to enter_button_trigg
up_button_triggered:
    ldr     r5, =GPIO_BTN_UP_MSK                               @ Load r5 with Up button mask
    ldr     r0, =up_button_message                             @ Load r0 with up_button_message string
    bl      printf                                             @ Print up_button_mes
    ldr     r3, =lstate 	                                   @ Load r3 with address of LED state	             
    ldr     r3, [r3]                                           @ Load r3 with value of LED state
    cmp     r3, #DFLT_STATE_STRT                               @ Comapre r3 with start state
    beq     double_flash_rate                                  @ Branch to double_flash_rate subroutine if LED state is equal to start state
    ldr     r3, =ltimer                                        @ Else, load r3 with alarm timer interval
    ldr     r4, =DFLT_ALARM_TIME                               @ Reset the alarm timer interval
    str     r4, [r3]                                           @ Store resetted interval into ltimer vari
    b       button_finished                                    @ Branch to the button_finsihed label     

double_flash_rate:             
    ldr     r5, =GPIO_BTN_UP_MSK                               @ Load r5 with up button mask          
    ldr     r3, =ltimer                                        @ Load r3 with address of alaram timer interval
    ldr     r4, [r3]                                           @ Load value at alarm timer interval into r4
    lsrs    r4, #1                                             @ Shfit r4 right by 1 bit (which halves value in r4)
    str     r4, [r3]                                           @ Store r4 as new alarm timer interval into ltimer vari
    b       button_finished                                    @ Branch to button_finished labe

down_button_triggered:             
    ldr     r5, =GPIO_BTN_DN_MSK                               @ Load address of down button mask into r5                              
    ldr     r0, =down_button_message                           @ Load address of string down_button_message into r0
    bl      printf                                             @ Print the down_button_message st
    ldr     r3, =lstate                                        @ Load address of LED state into r3
    ldr     r3, [r3]                                           @ Load value of LED state into r3          
    cmp     r3, #DFLT_STATE_STRT                               @ Compare LED state with start state
    beq     halve_flash_rate                                   @ If LED state is equal to start state branch to halve_flash_rate 
    ldr     r3, =ltimer                                        @ Else, load alarm timer interval from ltimer variable into r3
    ldr     r4, =DFLT_ALARM_TIME                               @ Load default alarm time interval into r4
    str     r4, [r3]                                           @ Reset interval by writing default alarm time interval into lt
    b       button_finished                                    @ Branch to the button_finished l

halve_flash_rate:              
    ldr     r5, =GPIO_BTN_DN_MSK                               @ Load address of down button mask into r5
    ldr     r3, =ltimer                                        @ Load address of alarm timer interval into r3
    ldr     r4, [r3]                                           @ Load value of interval into r4
    lsls    r4, #1                                             @ Shift interval left by 1 (multiply interval by 2)
    str     r4, [r3]                                           @ Store new alarm timer interval into ltimer vari
    b       button_finished                                    @ Branch to button_finished label         

enter_button_triggered:            
    ldr     r5, =GPIO_BTN_EN_MSK                               @ Load address of enter button mask into r5
    ldr     r0, =enter_button_message                          @ Load address of enter_button_message into r0
    bl      printf                                             @ Print the enter_button_message st
    ldr     r3, =lstate                                        @ Load address of LED state into r3               
    ldr     r4, [r3]                                           @ Load value of LED state into r4
    movs    r2, #1                                             @ Move the value 1 into r2 
    eors    r4, r2                                             @ XOR value in r4 with value in r2 (invert the LED state)
    str     r4, [r3]                                           @ Store value of r4 as new LED state (lstate varia
    b       button_finished                                    @ Branch to button_finished_label

button_finished:
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)       @ Load offsetted address of button interrupt register into r2                               
    str     r5, [r2]                                           @ Write mask into button interrupt register to clear interrupt

    pop     {pc}                                                @ Pop the value of the program counter and return 

.align 4
start_message:          .asciz "Initialisation completed successfully!\n"
alarm_message:          .asciz "Alarm Interrupt Triggered!\n"
led_on_message:         .asciz "Turning LED on!\n"
led_off_message:        .asciz "Turning LED off!\n"
led_toggle_message:     .asciz "Successfully toggles LED state!\n" 
up_button_message:      .asciz "Up Button Triggered! [double rate/reset rate]\n"
down_button_message:    .asciz "Down Button Triggered! [halve rate/reset rate]\n"
enter_button_message:   .asciz "Enter Button Triggerd! [toggle LED]\n"

.data
lstate: .word DFLT_STATE_STRT
ltimer: .word DFLT_ALARM_TIME