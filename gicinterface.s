;==================================================================
; GIC Minimal API
; Author: rishi franklin
; Date: 15th June 2015
;==================================================================

	PRESERVE8
	AREA GICCODE, CODE, READONLY
	ARM

	EXPORT GIC_Enable_int
	EXPORT GIC_Enable
	INCLUDE address.inc

GIC_Enable_int FUNCTION {}
	; r0 - interrupt number
	; r1 - priority
	; r2 - interrupt type  (edge / level trig.)
	PUSH {r4-r12, lr}

	CPSID if

	ldr r7, =GIC1_CPU_INTERFACE_BASE

	ldr r7, =GIC1_DIST_INTERFACE_BASE

	; enable the interrupt in isenable register
	mov r4, #GIC1_ISENABLER0	; ISEN REG offset base
	mov r5, r0, LSR #5			; Interrupt_Number DIV 5
	add r4, r4, r5, LSL #2		; final offset from GIC DIST BASE
	and r5, r0, #31				; bit number
	mov r8, #1


	ldr r6, [r7, r4]
	orr r6, r6, r8, LSL r5
	str r6, [r7, r4]

	; setup priority
	mov r4, #GIC1_IPRIORITYR0
	mov r5, r0, LSR #2			; Interrupt_Number DIV 2
	add r4, r4, r5, LSL #2		; final offset from GIC DIST BASE
	and r5, r0, #3				; Int_Num MOD 4
	lsl r5, #3
	lsl r1, r5

	ldr r6, [r7, r4]
	orr r1, r6, r1
	str r1, [r7, r4]

	; set up interrupt type
	mov r4, #GIC1_ICFGR0
	mov r5, r0, LSR #4
	add r4, r4, r5, LSL #2	; offset from base

	; field
	and r5, r0, #15
	lsl r5, #1
	lsl r2, r5

	ldr r6, [r7, r4]
	orr r2, r6, r2
	str r8, [r7, r4]

	ldr r2, =GIC1_CPU_INTERFACE_BASE

	; set the interrupt id prio mask
	; Max Priorities = 32.
	; mask = (configUNIQUE_INTERRUPT_PRIORITIES - 1) << 3
	mov r3, #0xF8
	str r3, [r2, #GIC1_GICC_PMR]

	CPSIE if

	POP {r4-r12, lr}
	bx lr

	ENDFUNC

;	Called from Startup.s
GIC_Enable	FUNCTION {}

	PUSH {r4-r12, lr}

	ldr r2, =GIC1_CPU_INTERFACE_BASE
	ldr r7, =GIC1_DIST_INTERFACE_BASE

	; Enable GIC
	mov r3, #0x1
	str r3, [r2, #GIC1_GICC_CTLR]

	; Enable GIC forwarding
	str r3, [r7, #GIC1_GICD_CTLR]

	; Set Binary Point Register to 0
	; <http://www.freertos.org/Using-FreeRTOS-on-Cortex-A-Embedded-Processors.html#interrupt-priorities>
	eor r3, r3, r3
	str r3, [r2, #GIC1_GICC_BPR]

	POP {r4-r12, lr}
	bx lr

	; At this point GIC is enabled
	; All INTS are disabled / not configured

	ENDFUNC

	END
