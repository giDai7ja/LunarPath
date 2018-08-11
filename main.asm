; H=0xFF,L=0x7B
; hall_led.asm
;
; Created: 12.07.2016 19:52:25
; Author : Маша
;

.device	ATtiny13A
.include "tn13Adef.inc"

.def		COUNT	= r19
.def		PWM		= r17
.def		Razr0	= r21
.def		Razr1	= r22

.equ		LED		= PINB0
.equ		SENSOR	= PINB1
.equ		SP_ON	= 2
.equ		SP_OFF	= 20
.equ		MAX_LED = 255-64

; EEPROM
.eseg

.dseg
.org	SRAM_START

.cseg

.org 0
; Таблица векторов прерываний
			rjmp	RESET				; Reset Handler
			rjmp	EXT_INT0			; IRQ0 Handler
			reti ;			rjmp	PCINT0				; PCINT0 Handler
			reti ;										; Timer0 Overflow Handler
			reti ;			rjmp	EE_RDY				; EEPROM Ready Handler
			reti ;			rjmp	ANA_COMP			; Analog Comparator Handler
			reti ;			rjmp	TIM0_COMPA			; Timer0 CompareA Handler
			reti ;			rjmp	TIM0_COMPB			; Timer0 CompareB Handler
			reti ;			rjmp	WATCHDOG			; Watchdog Interrupt Handler
			reti ;			rjmp	ADC					; ADC Conversion Handler


.org	INT_VECTORS_SIZE

RESET:		
			cli							; Запрещаем прерывания

			ldi		r16, low(RAMEND)	; Установить указатель стэка в конец оперативной памяти
			out		SPL, r16	

			sei							; Разрешаем прерывания

			ldi		r16, (1<<PRADC)
			out		PRR, r16

			ldi		r16, (1<<LED)
			out		DDRB, r16

			ldi		PWM, 255
			out		OCR0A, PWM

			ldi		r16, 1<<CS00
			out		TCCR0B, r16
			
			ldi		r16, (1<<COM0A0)|(1<<COM0A1)|(1<<WGM01)|(1<<WGM00)
			out		TCCR0A, r16

			ldi		r16, (1<<TOIE0)
			out		TIMSK0, r16

; Начало основной программы

POWER_DOWN:
			ldi		r16, (1<<SM1)|(1<<SE)
			out		MCUCR, r16

			ldi		r16, (1<<INT0)
			out		GIMSK, r16

			sleep

MAIN:
			ldi		COUNT, SP_ON
LED_ON:
			cpi		PWM, MAX_LED
			breq	END_ON

NEXT_ON:
			rcall	IDLE
			dec		COUNT
			brne	NEXT_ON

			dec		PWM
			out		OCR0A, PWM

			rjmp	MAIN

END_ON:
; Инициализация счётчика на 20 секунд (0x2710 прерываний таймера)
			ldi		Razr0, 0x10
			ldi		Razr1, 0x27

DELAY:		
			rcall	IDLE

			sbis	PINB, SENSOR
			rjmp	LED_ON

			subi	Razr0,1
			sbci	Razr1,0
			brcs	OFF
			rjmp	DELAY

OFF:
			ldi		COUNT, SP_OFF
LED_DOWN:
			cpi		PWM, 255
			breq	POWER_DOWN

NEXT_DOWN:
			rcall	IDLE

			sbis	PINB, SENSOR
			rjmp	LED_ON

			dec		COUNT
			brne	NEXT_DOWN

			inc		PWM
			out		OCR0A, PWM

			rjmp	OFF


IDLE:
			ldi		r16, (1<<SE)
			out		MCUCR, r16
			sleep

			ret


;################	Обработка прерываний	################

; Обработчик прерывания INT0
EXT_INT0:
			clr		r18
			out		GIMSK, r18
			
			reti
