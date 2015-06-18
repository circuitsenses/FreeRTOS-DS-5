

; Primecell SP804 Timer Interface 0
TMR0_BASE_ADDR			EQU	0x10011000
TMR0_PERIPHERAL_ID_0	EQU	0xfe0
TMR0_LOAD_REG			EQU 0x00
TMR0_CURR_VALUE_REG		EQU	0x04
TMR0_CTRL_REG			EQU	0x08
TMR0_INT_CLR_REG		EQU	0x0c
TMR0_RAWINT_STAT_REG	EQU	0x10
TMR0_MSKINT_STAT_REG	EQU	0x14
TIMER0_INTERRUPT_ID		EQU	0x24

; Timer interrupt Prio = (configUNIQUE_INTERRUPT_PRIORITIES - 1) << 3
TIMER0_INTERRUPT_PRIO	EQU	0xF0

; GIC DIST, CPU INTERFACE & Registers
GIC1_DIST_INTERFACE_BASE	EQU	0x10041000
GIC1_CPU_INTERFACE_BASE		EQU	0x10040000

GIC1_GICD_CTLR				EQU	0x000
GIC1_GICD_TYPER				EQU	0x004
GIC1_ISENABLER0				EQU 0x100
GIC1_ISENABLER1				EQU (GIC1_ISENABLER0 + 4)
GIC1_ISACTIVER0				EQU 0x300
GIC1_ISACTIVER1				EQU (GIC1_ISACTIVER0 + 4)

GIC1_IPRIORITYR0			EQU	0x400
GIC1_IPRIORITYR9			EQU (GIC1_IPRIORITYR0 + 0x24)

GIC1_ICFGR0					EQU	0xC00
GIC1_ICFGR2					EQU (GIC1_ICFGR0 + 8)

GIC1_GICC_CTLR				EQU 0x0000
GIC1_GICC_PMR				EQU 0x0004
GIC1_GICC_BPR				EQU 0x0008
GIC1_GICC_IAR				EQU 0x000C
GIC1_GICC_EOIR				EQU	0x0010

; BOOTSW Switches 
SYS_SW_REG_BASE				EQU	0x10000004

	END