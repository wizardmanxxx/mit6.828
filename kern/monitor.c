// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <pmap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE 80 // enough for one VGA text line

struct Command
{
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char **argv, struct Trapframe *tf);
};

static struct Command commands[] = {
	{"help", "Display this list of commands", mon_help},
	{"kerninfo", "Display information about the kernel", mon_kerninfo},
	{"backtrace","Display the list of called function and stack",mon_backtrace},
	{"showmappings","Display physcial address to virtual address",mon_showmappings}
};
#define NCOMMANDS (sizeof(commands) / sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
			fn_name[i]=info.eip_fn_name[i];
		}
		fn_name[info.eip_fn_namelen]=0;
		int off = ebp[1]-info.eip_fn_addr;
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
		ebp = (int*)(*ebp);
	}

	return 0;
}

// 显示虚拟地址映射命令
int mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	if (argc != 3) {
		cprintf("Requir 2 virtual address as arguments.\n");
		return -1;
	}
	char *errChar;
	uint32_t s = strtol(argv[1],&errChar,16);
	if (*errChar) {
		cprintf("Invalid virtual address: %s.\n", argv[1]);
		return -1;
	}
	uint32_t e = strtol(argv[2],&errChar,16);
	if(*errChar){
		cprintf("Invalid virtual address: %s.\n", argv[1]);
		return -1;
	}
	if (s > e) {
		cprintf("Address 1 must be lower than address 2\n");
		return -1;
	}
	s = ROUNDDOWN(s,PGSIZE);
	e = ROUNDUP(s,PGSIZE);
	for(uint32_t i = s;i<=e;i+=PGSIZE){
		uint32_t *entry = pgdir_walk(kern_pgdir,(uint32_t*)i,0);
		if(entry==NULL||!(*entry&PTE_P))
			cprintf( "Virtual address [%08x] - not mapped\n", i);
		cprintf( "Virtual address [%08x] - physical address [%08x], permission: ", entry, PTE_ADDR(*entry));
		char perm_PS = (*entry & PTE_PS) ? 'S':'-';
		char perm_W = (*entry & PTE_W) ? 'W':'-';
		char perm_U = (*entry & PTE_U) ? 'U':'-';
		// 进入 else 分支说明 PTE_P 肯定为真了
		cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
	}

	return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1)
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
	{
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	while (1)
	{
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
