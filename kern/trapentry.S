/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 * traphandler 为一个中断定义一个全局可见的函数。
 * push 一个trap num到栈中，并跳到_alltraps
 * 使用tarphandler处理trap ，cpu会自动push错误码
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */

#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' 外部也可以使用*/	\
	.type name, @function;	/* symbol type is function 指明name是一个函数*/	\
	.align 2;		/* align function definition 2字节对齐*/		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 * 没有error code就push 0
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	TRAPHANDLER_NOEC(handler0, T_DIVIDE)
	TRAPHANDLER_NOEC(handler1, T_DEBUG)
	TRAPHANDLER_NOEC(handler2, T_NMI)
	TRAPHANDLER_NOEC(handler3, T_BRKPT)
	TRAPHANDLER_NOEC(handler4, T_OFLOW)
	TRAPHANDLER_NOEC(handler5, T_BOUND)
	TRAPHANDLER_NOEC(handler6, T_ILLOP)
	TRAPHANDLER_NOEC(handler7, T_DEVICE)
	TRAPHANDLER(handler8, T_DBLFLT)
	// 9 deprecated since 386
	TRAPHANDLER(handler10, T_TSS)
	TRAPHANDLER(handler11, T_SEGNP)
	TRAPHANDLER(handler12, T_STACK)
	TRAPHANDLER(handler13, T_GPFLT)
	TRAPHANDLER(handler14, T_PGFLT)
	// 15 reserved by intel
	TRAPHANDLER_NOEC(handler16, T_FPERR)
	TRAPHANDLER(handler17, T_ALIGN)
	TRAPHANDLER_NOEC(handler18, T_MCHK)
	TRAPHANDLER_NOEC(handler19, T_SIMDERR)
	// system call (interrupt)
	TRAPHANDLER_NOEC(handler48, T_SYSCALL)

/*
 * Lab 3: Your code here for _alltraps
 * 把所有Trapframe 入栈
 */

_alltraps:
	pushl %ds
	pushl %es
	pushal

	movw $GD_KD, %ax
	movw %ax, %ds
	movw %ax, %es
	pushl %esp
	call trap
