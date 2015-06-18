/* Scheduler includes. */
#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"

static void Unused_Dummy_Interrupt(unsigned int int_sense);
#define EB_MAX_INTS           (64)

extern void GIC_Enable_int(int, int, int);

/* Based on EB Model - <http://infocenter.arm.com/help/topic/com.arm.doc.dui0424j/DUI0424J_eb_model_ug.pdf> */
static void (* intc_func_table[EB_MAX_INTS])(unsigned int int_sense) =
{
    Unused_Dummy_Interrupt,        /* 0   : SGI0          */
    Unused_Dummy_Interrupt,        /* 1   : SGI1          */
    Unused_Dummy_Interrupt,        /* 2   : SGI2          */
    Unused_Dummy_Interrupt,        /* 3   : SGI3          */
    Unused_Dummy_Interrupt,        /* 4   : SGI4          */
    Unused_Dummy_Interrupt,        /* 5   : SGI5          */
    Unused_Dummy_Interrupt,        /* 6   : SGI6          */
    Unused_Dummy_Interrupt,        /* 7   : SGI7          */
    Unused_Dummy_Interrupt,        /* 8   : SGI8          */
    Unused_Dummy_Interrupt,        /* 9   : SGI9          */
    Unused_Dummy_Interrupt,        /* 10  : SGI0          */
    Unused_Dummy_Interrupt,        /* 11  : SGI1          */
    Unused_Dummy_Interrupt,        /* 12  : SGI2          */
    Unused_Dummy_Interrupt,        /* 13  : SGI3          */
    Unused_Dummy_Interrupt,        /* 14  : SGI4          */
    Unused_Dummy_Interrupt,        /* 15  : SGI5          */
    Unused_Dummy_Interrupt,        /* 16  : <NA>          */
    Unused_Dummy_Interrupt,        /* 17  : <NA>          */
    Unused_Dummy_Interrupt,        /* 18  : <NA>          */
    Unused_Dummy_Interrupt,        /* 19  : <NA>          */
    Unused_Dummy_Interrupt,        /* 20  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 21  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 22  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 23  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 24  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 25  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 26  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 27  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 28  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 29  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 30  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 31  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 32  : SP805         */
    Unused_Dummy_Interrupt,        /* 33  : <NA>          */
    Unused_Dummy_Interrupt,        /* 34  : <NA>          */
    Unused_Dummy_Interrupt,        /* 35  : <NA>          */
    Unused_Dummy_Interrupt,        /* 36  : SP804-1       */
    Unused_Dummy_Interrupt,        /* 37  : SP804-2       */
    Unused_Dummy_Interrupt,        /* 38  : GPIO0         */
    Unused_Dummy_Interrupt,        /* 39  : GPIO1         */
    Unused_Dummy_Interrupt,        /* 40  : GPIO2    	  */
    Unused_Dummy_Interrupt,        /* 41  : DOC       	  */
    Unused_Dummy_Interrupt,        /* 42  : <NA>       	  */
    Unused_Dummy_Interrupt,        /* 43  : SSPI       	  */
    Unused_Dummy_Interrupt,        /* 44  : UART0         */
    Unused_Dummy_Interrupt,        /* 45  : UART1         */
    Unused_Dummy_Interrupt,        /* 46  : UART2         */
    Unused_Dummy_Interrupt,        /* 47  : UART3         */
    Unused_Dummy_Interrupt,        /* 48  : <NA>       	  */
    Unused_Dummy_Interrupt,        /* 49  : MCI       	  */
    Unused_Dummy_Interrupt,        /* 50  : MCI       	  */
    Unused_Dummy_Interrupt,        /* 51  : AACI      	  */
    Unused_Dummy_Interrupt,        /* 52  : PL0500     	  */
    Unused_Dummy_Interrupt,        /* 53  : PL0501        */
    Unused_Dummy_Interrupt,        /* 54  : DMAINT13      */
    Unused_Dummy_Interrupt,        /* 55  : CHAR-LCD      */
    Unused_Dummy_Interrupt,        /* 56  : DMAINT15      */
    Unused_Dummy_Interrupt,        /* 57  : DMAERR        */
    Unused_Dummy_Interrupt,        /* 58  : PSMO    	  */
    Unused_Dummy_Interrupt,        /* 59  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 60  : ETH    		  */
    Unused_Dummy_Interrupt,        /* 61  : <NA>    	  */
    Unused_Dummy_Interrupt,        /* 62  : SMARTCARD     */
    Unused_Dummy_Interrupt,        /* 63  : <NA>    	  */
};


void INTC_RegistIntFunc(unsigned short  int_id, void (* func)(unsigned int int_sense), int prio)
{
	if(int_id >= 16 && int_id < EB_MAX_INTS)
	{
		intc_func_table[int_id] = func;
		GIC_Enable_int(int_id, prio, 1);
	}
	else {
		configASSERT(1);
	}
}

void UserDef_UndefId(unsigned short int_id)
{
    while (1)
    {
        /* Do Nothing */
    }
}

static void Unused_Dummy_Interrupt(unsigned int int_sense)
{
    /* Do Nothing */
}


void UserFIQ_HandlerExe(void)
{

}

/* The function called by the RTOS port layer after it has managed interrupt
entry. */

void vApplicationIRQHandler( unsigned int ulICCIAR )
{
unsigned int ulInterruptID;

	/* Re-enable interrupts. */
    __enable_irq();

	/* The ID of the interrupt can be obtained by bitwise anding the ICCIAR value
	with 0x3FF. */
	ulInterruptID = ulICCIAR & 0x3FFUL;

	/* Call the function installed in the array of installed handler functions. */
	intc_func_table[ ulInterruptID ]( 0 );
}


/* END of File */

