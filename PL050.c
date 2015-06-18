
// Primecell PL050 Keyboard/Mouse Controller
#include "FreeRTOS.h"
#include "semphr.h"

#define KBD_MOUSE_IF0_BASE			( 0x10006000 )
#define KBD_MOUSE_IF0_INTR			52
#define KBD_MOUSE_IF0_INTR_PRIO		(27 << 3)

#define KBD_MOUSE_IF0_CTRL			*((volatile unsigned int *)(KBD_MOUSE_IF0_BASE))
#define KBD_MOUSE_IF0_STAT			*((volatile unsigned int *)(KBD_MOUSE_IF0_BASE + 0x4))
#define KBD_MOUSE_IF0_RXD			*((volatile unsigned int *)(KBD_MOUSE_IF0_BASE + 0x8))
#define KBD_MOUSE_IF0_CDIV			*((volatile unsigned int *)(KBD_MOUSE_IF0_BASE + 0xc))
#define KBD_MOUSE_IF0_INT_STAT		*((volatile unsigned int *)(KBD_MOUSE_IF0_BASE + 0x10))

#define RX_BUFFER_SZ					16
#define portUNMASK_VALUE				( 0xFFUL )
#define portPRIORITY_SHIFT 				3

/* Interrupt controller access addresses. */


/* Macro to unmask all interrupt priorities. */
#define portCLEAR_INTERRUPT_MASK()											\
{																			\
	__disable_irq();														\
	portICCPMR_PRIORITY_MASK_REGISTER = portUNMASK_VALUE;					\
	__asm(	"DSB		\n"													\
			"ISB		\n" );												\
	__enable_irq();															\
}

extern void INTC_RegistIntFunc(unsigned short  int_id, void (* func)(), int prio);
void PL050_IRQ_Handler(void);


#ifdef PROCESS_KBD_DATA
volatile char received_data[RX_BUFFER_SZ];
static unsigned int rx_index = 0;
#endif

SemaphoreHandle_t xKeyboardSem;

enum {
	STATE_DATA0 = 0,
	STATE_DATA1,
	STATE_DATA2,

	MAX_STATES
}KBD_STATE_MACHINE;

void PL050_Init(void)
{
	INTC_RegistIntFunc(KBD_MOUSE_IF0_INTR, PL050_IRQ_Handler, KBD_MOUSE_IF0_INTR_PRIO);
	KBD_MOUSE_IF0_CTRL = 0x14;
}

int PL050_RxData(void)
{
	return KBD_MOUSE_IF0_RXD;
}

int PL050_InterruptStatus(void)
{
	return KBD_MOUSE_IF0_INT_STAT;
}

#ifdef PROCESS_KBD_DATA
void PL050_IRQ_Handler(void)
{
	static BaseType_t xHigherPriorityTaskWoken = pdFALSE;
	static int nstate = STATE_DATA0;
	volatile char regUnusedData;

	switch(nstate) {
		case STATE_DATA0:
			// Scan Code of the Key gets read. NOT ASCII CODE !!
			// However, I was expecting the DS-5 debugger to give me the ASCII Code...
			received_data[rx_index] = KBD_MOUSE_IF0_RXD;
			__asm(	"DSB		\n"
					"ISB		\n" );
			nstate = STATE_DATA1;
			break;

		case STATE_DATA1:
			// ignore read: Byte 0xF0, Status Byte ? Shift Key State ?
			regUnusedData = KBD_MOUSE_IF0_RXD;
			nstate = STATE_DATA2;
			break;

		case STATE_DATA2:
			// ignore read, re-sent data, or whatever it is
			regUnusedData = KBD_MOUSE_IF0_RXD;
			++rx_index;
			if(rx_index >= RX_BUFFER_SZ) {
				rx_index = 0;
				nstate = STATE_DATA0;

				xSemaphoreGiveFromISR( xKeyboardSem, &xHigherPriorityTaskWoken );
				portYIELD_FROM_ISR( xHigherPriorityTaskWoken );

			}else {
				// Buffer not full
				nstate = STATE_DATA0;
			}

			break;

		default:
			break;
	}

}
#else
void PL050_IRQ_Handler(void)
{
	static BaseType_t xHigherPriorityTaskWoken = pdFALSE;
	static int nstate = STATE_DATA0;
	volatile char regUnusedData;

	// For a single keypress 3 Interrupts are generated.
	// The KMIDATA register Must be read to clear interrupt

	// Wakes up the Keboard task which is waiting on the semaphore
	switch(nstate) {
		case STATE_DATA0:
			regUnusedData = KBD_MOUSE_IF0_RXD;
			nstate = STATE_DATA1;
			break;

		case STATE_DATA1:
			regUnusedData = KBD_MOUSE_IF0_RXD;
			nstate = STATE_DATA2;
			break;

		case STATE_DATA2:
			regUnusedData = KBD_MOUSE_IF0_RXD;
			nstate = STATE_DATA0;

			xSemaphoreGiveFromISR( xKeyboardSem, &xHigherPriorityTaskWoken );
			portYIELD_FROM_ISR( xHigherPriorityTaskWoken );
			break;

		default:
			break;
	}
}
#endif /* PROCESS_KBD_DATA */
