#include <stdint.h>
#include <stddef.h>
#include "bsp.h"
#include "orca_exceptions.h"
#include "orca_interrupts.h"
#include "orca_printf.h"

#if ORCA_ENABLE_EXCEPTIONS
static orca_illegal_instruction_handler illegal_instruction_handler = NULL;
static void *illegal_instruction_context                  = NULL;
static orca_exception_handler timer_handler = NULL;
static void* timer_context=NULL;
static orca_exception_handler ecall_handler = NULL;
static void* ecall_context=NULL;

#if ORCA_INTERRUPT_HANDLERS

static orca_interrupt_handler interrupt_handler_table[ORCA_INTERRUPT_HANDLERS] = {NULL};
static void *interrupt_context_table[ORCA_INTERRUPT_HANDLERS]                  = {NULL};
static uint32_t registered_interrupt_handlers = 0x00000000;

#endif //#if ORCA_INTERRUPT_HANDLERS


orca_exception_handler orca_register_timer_handler(orca_exception_handler the_handler,void** the_context){
	orca_exception_handler old=timer_handler;
	void* old_context=timer_context;
	timer_handler = the_handler;
	if(the_context){
		timer_context = *the_context;
		*the_context = old_context;
	}
	return old;
}
orca_exception_handler orca_register_ecall_handler(orca_exception_handler the_handler,void** the_context){
	orca_exception_handler old=ecall_handler;
	void* old_context=ecall_context;
	ecall_handler = the_handler;
	if(the_context){
		ecall_context = *the_context;
		*the_context = old_context;
	}
	return old;
}

//Register an illegal instruction
int register_orca_illegal_instruction_handler(orca_illegal_instruction_handler the_handler, void *the_context){
	int return_code = 0;
	if(illegal_instruction_handler){
		return_code |= ORCA_EXCEPTION_ALREADY_REGISTERED;
	}
	illegal_instruction_handler = the_handler;
	illegal_instruction_context = the_context;
	return return_code;
}

//Register an interrupt handler.  The interrupt mask specifies which
//interrupt(s) will use this handler.  See orca_exceptions.h for
//return codes.
int orca_register_interrupt_handler(uint32_t interrupt_mask, orca_interrupt_handler the_handler, void *the_context){
	int return_code = 0;
	if((1<<(ORCA_INTERRUPT_HANDLERS-1)) < interrupt_mask){
		//if interrupt mask tries to register a interrupt that doesn't exist return an error
		return ORCA_UNSUPPORTED_EXCEPTION_REGISTRATION;
	}

	for(int interrupt_number = 0; interrupt_number < ORCA_INTERRUPT_HANDLERS; interrupt_number++){
		if(interrupt_mask & (1 << interrupt_number)){
			if(registered_interrupt_handlers & (1 << interrupt_number)){
				return_code |= ORCA_EXCEPTION_ALREADY_REGISTERED;
			}
			interrupt_handler_table[interrupt_number] = the_handler;
			interrupt_context_table[interrupt_number] = the_context;
			registered_interrupt_handlers |= (1 << interrupt_number);
		}
	}

	return return_code;
}

static void call_interrupt_handler(){
	uint32_t pending_interrupts= get_pending_interrupts();
	while(pending_interrupts){
		for(int int_num = 0; int_num<31; int_num++){
			//call the handler if it is regisered and pending
			if((1<<int_num) & registered_interrupt_handlers  & pending_interrupts){
				(*interrupt_handler_table[int_num])(int_num, interrupt_context_table[int_num]);
			}
			pending_interrupts = get_pending_interrupts();
		}
	}
}

//Handle an exception.  Illegal instructions and interrupts can be
//passed to handlers set using the
//register_orca_illegal_instruction_handler() and
//register_orca_interrupt_handler() calls respectively.
int handle_exception(int cause, int epc, int regs[32]){
	switch(cause){
	case 0x8000000B://external interrupt
		call_interrupt_handler();
		break;
	case 0x80000007://timer
		if(timer_handler){
			timer_handler(timer_context);
			break;
		}else{ while(1); }

	case 0x2 ://illegal instruction
		if(illegal_instruction_handler){
			epc=illegal_instruction_handler(cause,epc,regs,illegal_instruction_context);
			break;
		}else{while(1);}
	case 0xB://ECALL
		if(ecall_handler){
			ecall_handler(ecall_context);
			epc+=4;
			break;
		}else{ while(1); }

	default:
		while(1);

	}
	return epc;
}

#endif //ORCA_ENABLE_EXCEPTIONS
