;==================================================================
; Copyright ARM Ltd 2005-2011. All rights reserved.
;
; Cortex-A8 Embedded example - Startup Code
;==================================================================


; Standard definitions of mode bits and interrupt (I & F) flags in PSRs

Mode_USR        EQU     0x10
Mode_FIQ        EQU     0x11
Mode_IRQ        EQU     0x12
Mode_SVC        EQU     0x13
Mode_ABT        EQU     0x17
Mode_UND        EQU     0x1B
Mode_SYS        EQU     0x1F

I_Bit           EQU     0x80               ; When I bit is set, IRQ is disabled
F_Bit           EQU     0x40               ; When F bit is set, FIQ is disabled

	IMPORT	FreeRTOS_IRQ_Handler
	IMPORT	FreeRTOS_SWI_Handler
	IMPORT	GIC_Enable


	INCLUDE address.inc

        PRESERVE8
        AREA   VECTORS, CODE, READONLY     ; Name this block of code

        ENTRY

;==================================================================
; Entry point for the Reset handler
;==================================================================

        EXPORT Start

Start

;==================================================================
; Exception Vector Table
;==================================================================
; Note: LDR PC instructions are used here, though branch (B) instructions
; could also be used, unless the exception handlers are >32MB away.

Vectors
        LDR PC, Reset_Addr
        LDR PC, Undefined_Addr
        LDR PC, SVC_Addr
        LDR PC, Prefetch_Addr
        LDR PC, Abort_Addr
        NOP                                ; Reserved vector
        LDR PC, IRQ_Addr
        LDR PC, FIQ_Addr



Reset_Addr      DCD     Reset_Handler
Undefined_Addr  DCD     Undefined_Handler
SVC_Addr        DCD     SVC_Handler
Prefetch_Addr   DCD     Prefetch_Handler
Abort_Addr      DCD     Abort_Handler
IRQ_Addr        DCD     IRQ_Handler
FIQ_Addr        DCD     FIQ_Handler

;==================================================================
; Exception Handlers
;==================================================================

Undefined_Handler
        B   Undefined_Handler
SVC_Handler
        b 	FreeRTOS_SWI_Handler
Prefetch_Handler
        B   Prefetch_Handler
Abort_Handler
        B   Abort_Handler
IRQ_Handler
        B   FreeRTOS_IRQ_Handler
FIQ_Handler
        B   FIQ_Handler

;==================================================================
; Reset Handler
;==================================================================
Reset_Handler   FUNCTION {}

;==================================================================
; Disable cache and MMU in case it was left enabled from an earlier run
; This does not need to be done from a cold reset
;==================================================================

    MRC     p15, 0, r0, c1, c0, 0       ; Read CP15 System Control register
    BIC     r0, r0, #(0x1 << 12)        ; Clear I bit 12 to disable I Cache
    BIC     r0, r0, #(0x1 <<  2)        ; Clear C bit  2 to disable D Cache
    BIC     r0, r0, #0x1                ; Clear M bit  0 to disable MMU
    MCR     p15, 0, r0, c1, c0, 0       ; Write value back to CP15 System Control register

;==================================================================
; Initialize Supervisor Mode Stack
; Note stack must be 8 byte aligned.
;==================================================================

        IMPORT  ||Image$$ARM_LIB_STACK$$ZI$$Limit|| ; Linker symbol from scatter file
        LDR     SP, =||Image$$ARM_LIB_STACK$$ZI$$Limit||

;==================================================================
; Initialize Stacks
; Note stack must be 8 byte aligned.
;==================================================================
		IMPORT  ||Image$$IRQ_STACK$$ZI$$Limit|| ; Linker symbol from scatter file
		CPS #Mode_IRQ
		LDR SP, =||Image$$IRQ_STACK$$ZI$$Limit||

		IMPORT	||Image$$SYS_STACK$$ZI$$Limit||
		CPS #Mode_SYS
		LDR SP, =||Image$$SYS_STACK$$ZI$$Limit||

		IMPORT	||Image$$ABT_STACK$$ZI$$Limit||
		CPS #Mode_ABT
		LDR SP, =||Image$$ABT_STACK$$ZI$$Limit||

		CPS #Mode_SVC

;==================================================================
; TLB maintenance, Invalidate Data and Instruction TLBs
;==================================================================

        MOV     r0,#0
        MCR     p15, 0, r0, c8, c7, 0      ; Cortex-A8 I-TLB and D-TLB invalidation

;===================================================================
; Invalidate instruction cache, also flushes BTAC
;===================================================================

        MOV     r0, #0                     ; SBZ
        MCR     p15, 0, r0, c7, c5, 0      ; ICIALLU - Invalidate entire I Cache, and flushes branch target cache

;===================================================================
; Set Vector Base Address Register (VBAR) to point to this application's vector table
;===================================================================

        LDR     r0, =Vectors
        MCR     p15, 0, r0, c12, c0, 0

;==================================================================
; Cache Invalidation code for Cortex-A8
;==================================================================

        ; Invalidate L1 Instruction Cache

        MRC     p15, 1, r0, c0, c0, 1      ; Read Cache Level ID Register (CLIDR)
        TST     r0, #0x3                   ; Harvard Cache?
        MOV     r0, #0
        MCRNE   p15, 0, r0, c7, c5, 0      ; Invalidate Instruction Cache

        ; Invalidate Data/Unified Caches

        MRC     p15, 1, r0, c0, c0, 1      ; Read CLIDR
        ANDS    r3, r0, #0x07000000        ; Extract coherency level
        MOV     r3, r3, LSR #23            ; Total cache levels << 1
        BEQ     Finished                   ; If 0, no need to clean

        MOV     r10, #0                    ; R10 holds current cache level << 1
Loop1   ADD     r2, r10, r10, LSR #1       ; R2 holds cache "Set" position
        MOV     r1, r0, LSR r2             ; Bottom 3 bits are the Cache-type for this level
        AND     r1, r1, #7                 ; Isolate those lower 3 bits
        CMP     r1, #2
        BLT     Skip                       ; No cache or only instruction cache at this level

        MCR     p15, 2, r10, c0, c0, 0     ; Write the Cache Size selection register
        ISB                                ; ISB to sync the change to the CacheSizeID reg
        MRC     p15, 1, r1, c0, c0, 0      ; Reads current Cache Size ID register
        AND     r2, r1, #7                 ; Extract the line length field
        ADD     r2, r2, #4                 ; Add 4 for the line length offset (log2 16 bytes)
        LDR     r4, =0x3FF
        ANDS    r4, r4, r1, LSR #3         ; R4 is the max number on the way size (right aligned)
        CLZ     r5, r4                     ; R5 is the bit position of the way size increment
        LDR     r7, =0x7FFF
        ANDS    r7, r7, r1, LSR #13        ; R7 is the max number of the index size (right aligned)

Loop2   MOV     r9, r4                     ; R9 working copy of the max way size (right aligned)

Loop3   ORR     r11, r10, r9, LSL r5       ; Factor in the Way number and cache number into R11
        ORR     r11, r11, r7, LSL r2       ; Factor in the Set number
        MCR     p15, 0, r11, c7, c6, 2     ; Invalidate by Set/Way
        SUBS    r9, r9, #1                 ; Decrement the Way number
        BGE     Loop3
        SUBS    r7, r7, #1                 ; Decrement the Set number
        BGE     Loop2
Skip    ADD     r10, r10, #2               ; increment the cache number
        CMP     r3, r10
        BGT     Loop1

Finished
;===================================================================
; Cortex-A8 MMU Configuration
; Set translation table base
;===================================================================
        IMPORT ||Image$$APP_CODE$$Base|| ; from scatter file
        IMPORT ||Image$$TTB$$ZI$$Base||    ; From scatter file

        ; Cortex-A8 supports two translation tables
        ; Configure translation table base (TTB) control register cp15,c2
        ; to a value of all zeros, indicates we are using TTB register 0.

        MOV     r0,#0x0
        MCR     p15, 0, r0, c2, c0, 2


        ; write the address of our page table base to TTB register 0

        LDR     r0,=||Image$$TTB$$ZI$$Base||
        MCR     p15, 0, r0, c2, c0, 0

;===================================================================
; PAGE TABLE generation

; Generate the page tables
; Build a flat translation table for the whole address space.
; ie: Create 4096 1MB sections from 0x000xxxxx to 0xFFFxxxxx


; 31                 20 19  18  17  16 15  14   12 11 10  9  8     5   4    3 2   1 0
; |section base address| 0  0  |nG| S |AP2|  TEX  |  AP | P | Domain | XN | C B | 1 0|
;
; Bits[31:20]   - Top 12 bits of VA is pointer into table
; nG[17]=0      - Non global, enables matching against ASID in the TLB when set.
; S[16]=0       - Indicates normal memory is shared when set.
; AP2[15]=0
; AP[11:10]=11  - Configure for full read/write access in all modes
; TEX[14:12]=000
; CB[3:2]= 00   - Set attributes to Strongly-ordered memory.
;                 (except for the descriptor where code segment is based, see below)
; IMPP[9]=0     - Ignored
; Domain[5:8]=1111   - Set all pages to use domain 15
; XN[4]=0       - Execute never disabled
; Bits[1:0]=10  - Indicate entry is a 1MB section
;===================================================================

        LDR     r1,=0xfff                  ; Loop counter
        LDR     r2, =2_00000000000000000000110111100010

CODE_REGION_PERM EQU 2_00000000000000000000110111101110

        ; r0 contains the address of the translation table base
        ; r1 is loop counter
        ; r2 is level1 descriptor (bits 19:0)

        ; Use loop counter to create 4096 individual table entries.
        ; This writes from address 'Image$$TTB$$ZI$$Base' +
        ; Offset 0x3FFC down to offset 0x0 in word steps (4 bytes)

init_ttb_1

        ORR     r3, r2, r1, LSL#20         ; R3 now contains full level1 descriptor to write
        STR     r3, [r0, r1, LSL#2]        ; Str table entry at TTB base + loopcount*4
        SUBS    r1, r1, #1                 ; Decrement loop counter
        BPL     init_ttb_1

        ; In this example, the 1MB section based at '||Image$$APP_CODE$$Base||' is setup specially as cacheable (write back mode).
        ; TEX[14:12]=000 and CB[3:2]= 11, Outer and inner write back, no Write-allocate normal memory.

        LDR     r1,=||Image$$APP_CODE$$Base|| ; Base physical address of code segment
        LSR     r1,#20                     ; Shift right to align to 1MB boundaries
        ORR     r3, r2, r1, LSL#20         ; Setup the initial level1 descriptor again

        LDR 	r4, =CODE_REGION_PERM

        ORR     r3,r3,r4			       ; Set CB bits
        STR     r3, [r0, r1, LSL#2]        ; str table entry

;===================================================================
; Setup domain control register - Enable all domains to client mode
;===================================================================

        MRC     p15, 0, r0, c3, c0, 0     ; Read Domain Access Control Register
        LDR     r0, =0x55555555           ; Initialize every domain entry to b01 (client)
        MCR     p15, 0, r0, c3, c0, 0     ; Write Domain Access Control Register

;===================================================================
; Setup L2 Cache - L2 Cache Auxiliary Control
;===================================================================

        MOV     r0, #0
        MCR     p15, 1, r0, c9, c0, 2     ; Write L2 Auxilary Control Register


    IF {TARGET_FEATURE_NEON} || {TARGET_FPU_VFP}
;==================================================================
; Enable access to NEON/VFP by enabling access to Coprocessors 10 and 11.
; Enables Full Access i.e. in both privileged and non privileged modes
;==================================================================

        MRC     p15, 0, r0, c1, c0, 2      ; Read Coprocessor Access Control Register (CPACR)
        ORR     r0, r0, #(0xF << 20)       ; Enable access to CP 10 & 11
        MCR     p15, 0, r0, c1, c0, 2      ; Write Coprocessor Access Control Register (CPACR)
        ISB

;==================================================================
; Switch on the VFP and NEON hardware
;=================================================================

        MOV     r0, #0x40000000
        VMSR    FPEXC, r0                  ; Write FPEXC register, EN bit set
    ENDIF


;===================================================================
; Enable MMU and Branch to __main
; Leaving the caches disabled until after scatter loading.
;===================================================================

        IMPORT  __main                     ; Before MMU enabled import label to __main
        LDR     r12,=__main         ; Save this in register for possible long jump


        MRC     p15, 0, r0, c1, c0, 0      ; Read CP15 System Control register
        BIC     r0, r0, #(0x1 << 12)       ; Clear I bit 12 to disable I Cache
        BIC     r0, r0, #(0x1 <<  2)       ; Clear C bit  2 to disable D Cache
        BIC     r0, r0, #0x2               ; Clear A bit  1 to disable strict alignment fault checking
        ORR     r0, r0, #0x1               ; Set M bit 0 to enable MMU before scatter loading
        MCR     p15, 0, r0, c1, c0, 0      ; Write CP15 System Control register


; Now the MMU is enabled, virtual to physical address translations will occur.
; This will affect the next instruction fetches.
;
; The two instructions currently in the ARM pipeline will have been fetched
; before the MMU was enabled. This property is useful because the next two
; instructions are safe even if new instruction fetches fail. If this routine
; was mapped out of the new virtual memory map, the branch to __main would still succeed.

        BX      r12                        ; Branch to __main() C library entry point

     ENDFUNC



     EXPORT core_init

core_init FUNCTION
;==================================================================
; Enable caches
; Caches are controlled by the System Control Register:
;==================================================================
        ; I-cache is controlled by bit 12
        ; D-cache is controlled by bit 2

        MRC     p15, 0, r0, c1, c0, 0      ; Read CP15 register 1
        ORR     r0, r0, #(0x1 << 12)       ; Enable I Cache
        ORR     r0, r0, #(0x1 << 2)        ; Enable D Cache
        MCR     p15, 0, r0, c1, c0, 0      ; Write CP15 register 1

;==================================================================
; Enable Program Flow Prediction
;
; Branch prediction is controlled by the System Control Register:
; Set Bit 11 to enable branch prediction and return stack
;==================================================================
        ; Turning on branch prediction requires a general enable
        ; CP15, c1. Control Register

        ; Bit 11 [Z] bit Program flow prediction:
        ; 0 = Program flow prediction disabled
        ; 1 = Program flow prediction enabled.

        MRC     p15, 0, r0, c1, c0, 0      ; Read CP15 register 1
        ORR     r0, r0, #(0x1 << 11)       ; Enable all forms of branch prediction
        MCR     p15, 0, r0, c1, c0, 0      ; Write CP15 register 1

;==================================================================
; Enable Cortex-A8 Level2 Unified Cache
;==================================================================

        MRC     p15, 0, r0, c1, c0, 1      ; Read Auxiliary Control Register
        ORR     r0, #2                     ; L2EN bit, enable L2 cache
        MCR     p15, 0, r0, c1, c0, 1      ; Write Auxiliary Control Register

;==================================================================

		PUSH {lr}
		BL	GIC_Enable
		POP	{lr}

		MOV		r1, lr
	    BX      r1

        ENDFUNC

        END
