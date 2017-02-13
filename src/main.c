/*
 *  blinky.c for the Teensy 3.1 board (K20 MCU, 16 MHz crystal)
 *
 *  This code will blink the Teensy's LED.  Each "blink" is
 *  really a set of eight pulses.  These pulses give the actual
 *  system clock in Mhz, starting with the MSB.  A pulse is
 *  narrow for a 0-bit and wide for a 1-bit.
 *
 *  For a system clock of 72 MHz, blinks will read 0x48.
 *  For a system clock of 48 MHz, blinks will read 0x30.
 */

/*////////////////////////////////////////////////////////////////
 * LED  (Pin 13) is PC5
 * DOUT (Pin 11) is PC6
 *
 ****************************************************************/

#include <time.h>

#include "aliases.h"
#include "common.h"

#define LED  PORTC_PCR5
#define DOUT PORTC_PCR6

static const u8 LED_PC_PIN  = 5;
static const u8 DOUT_PC_PIN = 6;

#define make_output(pc_pin)	GPIOC_PDDR |= 1 << pc_pin 
#define set_gpio(pc_pin)	pc_pin = PORT_PCR_MUX(0x01)
#define clear_gpio			GPIOC_PDDR = 0x00

/* PIN STATES */
#define LED_ON				GPIOC_PSOR = LED_PC_PIN
#define LED_OFF				GPIOC_PCOR = LED_PC_PIN
#define DOUT_ON				GPIOC_PSOR = DOUT_PC_PIN
#define DOUT_OFF			GPIOC_PCOR = DOUT_PC_PIN

static void setup(void)
{
	clear_gpio;
	set_gpio(LED);
	make_output(LED_PC_PIN);
	LED_OFF; // ~~~~~~~~~~~~~ LED init LOW.

	set_gpio(DOUT);
	make_output(LED_PC_PIN);
	DOUT_ON; // ~~~~~~~~~~~~~ DOUT init LOW.	
}

int main(void)
{
    volatile u32       n;
    u32                v;
    u8                 mask;

	setup();

    v = (u32) mcg_clk_hz;
    v = v / 1000000;

    for (;;) {
        DOUT_ON;
        for (n=0; n<8000000; n++)  ;	// dumb delay
        mask = 0x80;
        while (mask != 0) {
            LED_ON;
            for (n=0; n<1000; n++)  ;
            if ((v & mask) == 0)  LED_OFF;	// for 0 bit, all done
            for (n=0; n<2000; n++)  ;		// (for 1 bit, LED is still on)
            LED_OFF;
            for (n=0; n<1000; n++)  ;
            mask = mask >> 1;
        }
    }

	return 666;
}
