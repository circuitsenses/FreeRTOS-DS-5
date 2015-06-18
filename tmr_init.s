;==================================================================
; SP804 Timer Minimal API
; Author: rishi franklin
; Date: 15th June 2015
;==================================================================

	PRESERVE8
	AREA INIT, CODE, READONLY
	ARM

	IMPORT GIC_Enable_int
	INCLUDE address.inc

	EXPORT init
	; void init(void)
init

	ldr r0, =TMR0_BASE_ADDR

	; get the timer id
	ldr r1, [r0, #TMR0_PERIPHERAL_ID_0]

	; set count value in load register
	ldr r1, =0x000003e8
	str r1, [r0, #TMR0_LOAD_REG]

	; enable the timer
	; periodic mode
	mov r1, #0xe6
	str r1, [r0, #TMR0_CTRL_REG]


	BX lr

	EXPORT	Timer_Clear_INT
	; void Timer_Clear_INT(void)
Timer_Clear_INT FUNCTION {}
	push {r0-r1, lr}
	ldr r0, =TMR0_BASE_ADDR
	eor r1, r1, r1
	str r1, [r0, #TMR0_INT_CLR_REG]
	pop {r0-r1, lr}

	BX lr
	ENDFUNC

	END
