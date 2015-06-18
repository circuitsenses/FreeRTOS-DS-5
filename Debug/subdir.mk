################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../FreeRTOS_tick_config.c \
../PL050.c \
../croutine.c \
../event_groups.c \
../heap_2.c \
../intc.c \
../list.c \
../main.c \
../port.c \
../queue.c \
../tasks.c \
../timers.c 

S_SRCS += \
../gicinterface.s \
../portASM.s \
../startup.s \
../tmr_init.s 

OBJS += \
./FreeRTOS_tick_config.o \
./PL050.o \
./croutine.o \
./event_groups.o \
./gicinterface.o \
./heap_2.o \
./intc.o \
./list.o \
./main.o \
./port.o \
./portASM.o \
./queue.o \
./startup.o \
./tasks.o \
./timers.o \
./tmr_init.o 

C_DEPS += \
./FreeRTOS_tick_config.d \
./PL050.d \
./croutine.d \
./event_groups.d \
./heap_2.d \
./intc.d \
./list.d \
./main.d \
./port.d \
./queue.d \
./tasks.d \
./timers.d 

S_DEPS += \
./gicinterface.d \
./portASM.d \
./startup.d \
./tmr_init.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM C Compiler 5'
	armcc --cpu=Cortex-A8 --apcs=/interwork -O0 -g -DportREMOVE_STATIC_QUALIFIER -DINCLUDE_xTaskGetIdleTaskHandle=1 -DconfigQUEUE_REGISTRY_SIZE=8 --md --depend_format=unix_escaped --no_depend_system_headers -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

gicinterface.o: ../gicinterface.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM Assembler 5'
	armasm --cpu=Cortex-A8 --apcs=/interwork -g --md --depend_format=unix_escaped -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

portASM.o: ../portASM.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM Assembler 5'
	armasm --cpu=Cortex-A8 --apcs=/interwork -g --md --depend_format=unix_escaped -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

startup.o: ../startup.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM Assembler 5'
	armasm --cpu=Cortex-A8 --apcs=/interwork -g --md --depend_format=unix_escaped -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

tmr_init.o: ../tmr_init.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM Assembler 5'
	armasm --cpu=Cortex-A8 --apcs=/interwork -g --md --depend_format=unix_escaped -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


