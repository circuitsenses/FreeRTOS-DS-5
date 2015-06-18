#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "task.h"
#include "semphr.h"

#include <stdio.h>

static void RollingLEDSTask( void *pvParameters );
static void PrintHelloTask( void *pvParameters );
static void PrintKeyboardTask(void *pvParameters );

#define SYS_SW_BASE 0x10000008
volatile unsigned int *ptr = (volatile unsigned int *)SYS_SW_BASE;

#define RollingLEDSTask_TASK_PRIORITY			( tskIDLE_PRIORITY + 2 )
#define PrintHelloTask_TASK_PRIORITY			( tskIDLE_PRIORITY + 3 )
#define PrintKeyboardTask_TASK_PRIORITY			( tskIDLE_PRIORITY + 4 )

extern void core_init(void);
extern void PL050_Init(void);
extern void $Super$$main(void);

extern SemaphoreHandle_t xKeyboardSem;

#ifdef PROCESS_KBD_DATA
extern char received_data[];
#endif

void vApplicationIdleHook( void )
{
	return;
}


void vAssertCalled( const char *s, unsigned long l )
{
	printf("\n\r %s, You didn't say the magic word at %d.", s, l);
	while(1);
}


void vApplicationTickHook( void )
{
	return;
}


void vApplicationStackOverflowHook(void)
{
	return;
}

void $Sub$$main(void)
{
	core_init();
	PL050_Init();
	$Super$$main();
}

__attribute__((noreturn)) int main(void)
{

	xTaskCreate( RollingLEDSTask,					/* The function that implements the task. */
				 "RollingLEDs", 					/* The text name assigned to the task - for debug only as it is not used by the kernel. */
				 configMINIMAL_STACK_SIZE, 			/* The size of the stack to allocate to the task. */
				 NULL, 								/* The parameter passed to the task - not used in this case. */
				 RollingLEDSTask_TASK_PRIORITY, 	/* The priority assigned to the task. */
				 NULL );							/* The task handle is not required, so NULL is passed. */


	xTaskCreate( PrintHelloTask,
				 "Hello",
				 configMINIMAL_STACK_SIZE,
				 NULL,
				 PrintHelloTask_TASK_PRIORITY,
				 NULL );

	xTaskCreate( PrintKeyboardTask,
				 "Keyboard",
				 configMINIMAL_STACK_SIZE,
				 NULL,
				 PrintKeyboardTask_TASK_PRIORITY,
				 NULL );

	/* Start the tasks and timer running. */
	vTaskStartScheduler();

	while(1);

}

static void RollingLEDSTask( void *pvParameters )
{
	static int count = 0;
	static unsigned int LED = 0x01;

	while(1) {
		*ptr = LED;
		LED = LED << 1;

		if(LED > 0x80)
		{
			LED = 0x01;
		}

		printf("\n\rTask LED: Call #%d", count++);
		vTaskDelay(1);
	}

}

static void PrintHelloTask( void *pvParameters )
{
	static int count = 0;

	while(1) {

		printf("\n\rTask Hello World: Call #%d", count++);
		vTaskDelay(5);

	}

}

static void PrintKeyboardTask( void *pvParameters )
{
#ifdef PROCESS_KBD_DATA
	int i = 0;
#endif

	xKeyboardSem = xSemaphoreCreateBinary();
	for( ;; )
	{
		if( xSemaphoreTake( xKeyboardSem, 0xffff ) == pdTRUE )	{
			taskDISABLE_INTERRUPTS();
#ifdef PROCESS_KBD_DATA
			printf("\n");
			// Process Rx Buffer: Test Code
			for(i = 0; i < 16; i++) {
				printf("%c,", received_data[i]);
			}
			printf("\n");
#else
			printf("\nKeyboard Trigger Generated\n\r");
#endif /* PROCESS_KBD_DATA */
			taskENABLE_INTERRUPTS();
		}
	}

}

