
obj/user/softint:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 09 00 00 00       	call   80003a <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $14");	// page fault
  800036:	cd 0e                	int    $0xe
}
  800038:	5d                   	pop    %ebp
  800039:	c3                   	ret    

0080003a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003a:	55                   	push   %ebp
  80003b:	89 e5                	mov    %esp,%ebp
  80003d:	83 ec 08             	sub    $0x8,%esp
  800040:	8b 45 08             	mov    0x8(%ebp),%eax
  800043:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800046:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80004d:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800050:	85 c0                	test   %eax,%eax
  800052:	7e 08                	jle    80005c <libmain+0x22>
		binaryname = argv[0];
  800054:	8b 0a                	mov    (%edx),%ecx
  800056:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  80005c:	83 ec 08             	sub    $0x8,%esp
  80005f:	52                   	push   %edx
  800060:	50                   	push   %eax
  800061:	e8 cd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800066:	e8 05 00 00 00       	call   800070 <exit>
}
  80006b:	83 c4 10             	add    $0x10,%esp
  80006e:	c9                   	leave  
  80006f:	c3                   	ret    

00800070 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800070:	55                   	push   %ebp
  800071:	89 e5                	mov    %esp,%ebp
  800073:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800076:	6a 00                	push   $0x0
  800078:	e8 42 00 00 00       	call   8000bf <sys_env_destroy>
}
  80007d:	83 c4 10             	add    $0x10,%esp
  800080:	c9                   	leave  
  800081:	c3                   	ret    

00800082 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	57                   	push   %edi
  800086:	56                   	push   %esi
  800087:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800088:	b8 00 00 00 00       	mov    $0x0,%eax
  80008d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800090:	8b 55 08             	mov    0x8(%ebp),%edx
  800093:	89 c3                	mov    %eax,%ebx
  800095:	89 c7                	mov    %eax,%edi
  800097:	89 c6                	mov    %eax,%esi
  800099:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009b:	5b                   	pop    %ebx
  80009c:	5e                   	pop    %esi
  80009d:	5f                   	pop    %edi
  80009e:	5d                   	pop    %ebp
  80009f:	c3                   	ret    

008000a0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a0:	55                   	push   %ebp
  8000a1:	89 e5                	mov    %esp,%ebp
  8000a3:	57                   	push   %edi
  8000a4:	56                   	push   %esi
  8000a5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ab:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b0:	89 d1                	mov    %edx,%ecx
  8000b2:	89 d3                	mov    %edx,%ebx
  8000b4:	89 d7                	mov    %edx,%edi
  8000b6:	89 d6                	mov    %edx,%esi
  8000b8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ba:	5b                   	pop    %ebx
  8000bb:	5e                   	pop    %esi
  8000bc:	5f                   	pop    %edi
  8000bd:	5d                   	pop    %ebp
  8000be:	c3                   	ret    

008000bf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000bf:	55                   	push   %ebp
  8000c0:	89 e5                	mov    %esp,%ebp
  8000c2:	57                   	push   %edi
  8000c3:	56                   	push   %esi
  8000c4:	53                   	push   %ebx
  8000c5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000cd:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d5:	89 cb                	mov    %ecx,%ebx
  8000d7:	89 cf                	mov    %ecx,%edi
  8000d9:	89 ce                	mov    %ecx,%esi
  8000db:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000dd:	85 c0                	test   %eax,%eax
  8000df:	7e 17                	jle    8000f8 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e1:	83 ec 0c             	sub    $0xc,%esp
  8000e4:	50                   	push   %eax
  8000e5:	6a 03                	push   $0x3
  8000e7:	68 0a 0e 80 00       	push   $0x800e0a
  8000ec:	6a 23                	push   $0x23
  8000ee:	68 27 0e 80 00       	push   $0x800e27
  8000f3:	e8 27 00 00 00       	call   80011f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000fb:	5b                   	pop    %ebx
  8000fc:	5e                   	pop    %esi
  8000fd:	5f                   	pop    %edi
  8000fe:	5d                   	pop    %ebp
  8000ff:	c3                   	ret    

00800100 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800100:	55                   	push   %ebp
  800101:	89 e5                	mov    %esp,%ebp
  800103:	57                   	push   %edi
  800104:	56                   	push   %esi
  800105:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800106:	ba 00 00 00 00       	mov    $0x0,%edx
  80010b:	b8 02 00 00 00       	mov    $0x2,%eax
  800110:	89 d1                	mov    %edx,%ecx
  800112:	89 d3                	mov    %edx,%ebx
  800114:	89 d7                	mov    %edx,%edi
  800116:	89 d6                	mov    %edx,%esi
  800118:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80011a:	5b                   	pop    %ebx
  80011b:	5e                   	pop    %esi
  80011c:	5f                   	pop    %edi
  80011d:	5d                   	pop    %ebp
  80011e:	c3                   	ret    

0080011f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80011f:	55                   	push   %ebp
  800120:	89 e5                	mov    %esp,%ebp
  800122:	56                   	push   %esi
  800123:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800124:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800127:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80012d:	e8 ce ff ff ff       	call   800100 <sys_getenvid>
  800132:	83 ec 0c             	sub    $0xc,%esp
  800135:	ff 75 0c             	pushl  0xc(%ebp)
  800138:	ff 75 08             	pushl  0x8(%ebp)
  80013b:	56                   	push   %esi
  80013c:	50                   	push   %eax
  80013d:	68 38 0e 80 00       	push   $0x800e38
  800142:	e8 b1 00 00 00       	call   8001f8 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800147:	83 c4 18             	add    $0x18,%esp
  80014a:	53                   	push   %ebx
  80014b:	ff 75 10             	pushl  0x10(%ebp)
  80014e:	e8 54 00 00 00       	call   8001a7 <vcprintf>
	cprintf("\n");
  800153:	c7 04 24 5c 0e 80 00 	movl   $0x800e5c,(%esp)
  80015a:	e8 99 00 00 00       	call   8001f8 <cprintf>
  80015f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800162:	cc                   	int3   
  800163:	eb fd                	jmp    800162 <_panic+0x43>

00800165 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800165:	55                   	push   %ebp
  800166:	89 e5                	mov    %esp,%ebp
  800168:	53                   	push   %ebx
  800169:	83 ec 04             	sub    $0x4,%esp
  80016c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80016f:	8b 13                	mov    (%ebx),%edx
  800171:	8d 42 01             	lea    0x1(%edx),%eax
  800174:	89 03                	mov    %eax,(%ebx)
  800176:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800179:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80017d:	3d ff 00 00 00       	cmp    $0xff,%eax
  800182:	75 1a                	jne    80019e <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800184:	83 ec 08             	sub    $0x8,%esp
  800187:	68 ff 00 00 00       	push   $0xff
  80018c:	8d 43 08             	lea    0x8(%ebx),%eax
  80018f:	50                   	push   %eax
  800190:	e8 ed fe ff ff       	call   800082 <sys_cputs>
		b->idx = 0;
  800195:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019b:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80019e:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a5:	c9                   	leave  
  8001a6:	c3                   	ret    

008001a7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001a7:	55                   	push   %ebp
  8001a8:	89 e5                	mov    %esp,%ebp
  8001aa:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001b7:	00 00 00 
	b.cnt = 0;
  8001ba:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c1:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c4:	ff 75 0c             	pushl  0xc(%ebp)
  8001c7:	ff 75 08             	pushl  0x8(%ebp)
  8001ca:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d0:	50                   	push   %eax
  8001d1:	68 65 01 80 00       	push   $0x800165
  8001d6:	e8 1a 01 00 00       	call   8002f5 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001db:	83 c4 08             	add    $0x8,%esp
  8001de:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ea:	50                   	push   %eax
  8001eb:	e8 92 fe ff ff       	call   800082 <sys_cputs>

	return b.cnt;
}
  8001f0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f6:	c9                   	leave  
  8001f7:	c3                   	ret    

008001f8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001f8:	55                   	push   %ebp
  8001f9:	89 e5                	mov    %esp,%ebp
  8001fb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001fe:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800201:	50                   	push   %eax
  800202:	ff 75 08             	pushl  0x8(%ebp)
  800205:	e8 9d ff ff ff       	call   8001a7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80020a:	c9                   	leave  
  80020b:	c3                   	ret    

0080020c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	57                   	push   %edi
  800210:	56                   	push   %esi
  800211:	53                   	push   %ebx
  800212:	83 ec 1c             	sub    $0x1c,%esp
  800215:	89 c7                	mov    %eax,%edi
  800217:	89 d6                	mov    %edx,%esi
  800219:	8b 45 08             	mov    0x8(%ebp),%eax
  80021c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80021f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800222:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800225:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800228:	bb 00 00 00 00       	mov    $0x0,%ebx
  80022d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800230:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800233:	39 d3                	cmp    %edx,%ebx
  800235:	72 05                	jb     80023c <printnum+0x30>
  800237:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023a:	77 45                	ja     800281 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80023c:	83 ec 0c             	sub    $0xc,%esp
  80023f:	ff 75 18             	pushl  0x18(%ebp)
  800242:	8b 45 14             	mov    0x14(%ebp),%eax
  800245:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800248:	53                   	push   %ebx
  800249:	ff 75 10             	pushl  0x10(%ebp)
  80024c:	83 ec 08             	sub    $0x8,%esp
  80024f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800252:	ff 75 e0             	pushl  -0x20(%ebp)
  800255:	ff 75 dc             	pushl  -0x24(%ebp)
  800258:	ff 75 d8             	pushl  -0x28(%ebp)
  80025b:	e8 10 09 00 00       	call   800b70 <__udivdi3>
  800260:	83 c4 18             	add    $0x18,%esp
  800263:	52                   	push   %edx
  800264:	50                   	push   %eax
  800265:	89 f2                	mov    %esi,%edx
  800267:	89 f8                	mov    %edi,%eax
  800269:	e8 9e ff ff ff       	call   80020c <printnum>
  80026e:	83 c4 20             	add    $0x20,%esp
  800271:	eb 18                	jmp    80028b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800273:	83 ec 08             	sub    $0x8,%esp
  800276:	56                   	push   %esi
  800277:	ff 75 18             	pushl  0x18(%ebp)
  80027a:	ff d7                	call   *%edi
  80027c:	83 c4 10             	add    $0x10,%esp
  80027f:	eb 03                	jmp    800284 <printnum+0x78>
  800281:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800284:	83 eb 01             	sub    $0x1,%ebx
  800287:	85 db                	test   %ebx,%ebx
  800289:	7f e8                	jg     800273 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028b:	83 ec 08             	sub    $0x8,%esp
  80028e:	56                   	push   %esi
  80028f:	83 ec 04             	sub    $0x4,%esp
  800292:	ff 75 e4             	pushl  -0x1c(%ebp)
  800295:	ff 75 e0             	pushl  -0x20(%ebp)
  800298:	ff 75 dc             	pushl  -0x24(%ebp)
  80029b:	ff 75 d8             	pushl  -0x28(%ebp)
  80029e:	e8 fd 09 00 00       	call   800ca0 <__umoddi3>
  8002a3:	83 c4 14             	add    $0x14,%esp
  8002a6:	0f be 80 5e 0e 80 00 	movsbl 0x800e5e(%eax),%eax
  8002ad:	50                   	push   %eax
  8002ae:	ff d7                	call   *%edi
}
  8002b0:	83 c4 10             	add    $0x10,%esp
  8002b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002b6:	5b                   	pop    %ebx
  8002b7:	5e                   	pop    %esi
  8002b8:	5f                   	pop    %edi
  8002b9:	5d                   	pop    %ebp
  8002ba:	c3                   	ret    

008002bb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002bb:	55                   	push   %ebp
  8002bc:	89 e5                	mov    %esp,%ebp
  8002be:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c5:	8b 10                	mov    (%eax),%edx
  8002c7:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ca:	73 0a                	jae    8002d6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002cc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002cf:	89 08                	mov    %ecx,(%eax)
  8002d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d4:	88 02                	mov    %al,(%edx)
}
  8002d6:	5d                   	pop    %ebp
  8002d7:	c3                   	ret    

008002d8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002d8:	55                   	push   %ebp
  8002d9:	89 e5                	mov    %esp,%ebp
  8002db:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002de:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e1:	50                   	push   %eax
  8002e2:	ff 75 10             	pushl  0x10(%ebp)
  8002e5:	ff 75 0c             	pushl  0xc(%ebp)
  8002e8:	ff 75 08             	pushl  0x8(%ebp)
  8002eb:	e8 05 00 00 00       	call   8002f5 <vprintfmt>
	va_end(ap);
}
  8002f0:	83 c4 10             	add    $0x10,%esp
  8002f3:	c9                   	leave  
  8002f4:	c3                   	ret    

008002f5 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f5:	55                   	push   %ebp
  8002f6:	89 e5                	mov    %esp,%ebp
  8002f8:	57                   	push   %edi
  8002f9:	56                   	push   %esi
  8002fa:	53                   	push   %ebx
  8002fb:	83 ec 2c             	sub    $0x2c,%esp
  8002fe:	8b 75 08             	mov    0x8(%ebp),%esi
  800301:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800304:	8b 7d 10             	mov    0x10(%ebp),%edi
  800307:	eb 12                	jmp    80031b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  800309:	85 c0                	test   %eax,%eax
  80030b:	0f 84 6a 04 00 00    	je     80077b <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800311:	83 ec 08             	sub    $0x8,%esp
  800314:	53                   	push   %ebx
  800315:	50                   	push   %eax
  800316:	ff d6                	call   *%esi
  800318:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80031b:	83 c7 01             	add    $0x1,%edi
  80031e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800322:	83 f8 25             	cmp    $0x25,%eax
  800325:	75 e2                	jne    800309 <vprintfmt+0x14>
  800327:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80032b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800332:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800339:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800340:	b9 00 00 00 00       	mov    $0x0,%ecx
  800345:	eb 07                	jmp    80034e <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800347:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80034a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80034e:	8d 47 01             	lea    0x1(%edi),%eax
  800351:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800354:	0f b6 07             	movzbl (%edi),%eax
  800357:	0f b6 d0             	movzbl %al,%edx
  80035a:	83 e8 23             	sub    $0x23,%eax
  80035d:	3c 55                	cmp    $0x55,%al
  80035f:	0f 87 fb 03 00 00    	ja     800760 <vprintfmt+0x46b>
  800365:	0f b6 c0             	movzbl %al,%eax
  800368:	ff 24 85 00 0f 80 00 	jmp    *0x800f00(,%eax,4)
  80036f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  800372:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800376:	eb d6                	jmp    80034e <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800378:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80037b:	b8 00 00 00 00       	mov    $0x0,%eax
  800380:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800383:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800386:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80038a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80038d:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800390:	83 f9 09             	cmp    $0x9,%ecx
  800393:	77 3f                	ja     8003d4 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800395:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800398:	eb e9                	jmp    800383 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80039a:	8b 45 14             	mov    0x14(%ebp),%eax
  80039d:	8b 00                	mov    (%eax),%eax
  80039f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a5:	8d 40 04             	lea    0x4(%eax),%eax
  8003a8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003ae:	eb 2a                	jmp    8003da <vprintfmt+0xe5>
  8003b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b3:	85 c0                	test   %eax,%eax
  8003b5:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ba:	0f 49 d0             	cmovns %eax,%edx
  8003bd:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c3:	eb 89                	jmp    80034e <vprintfmt+0x59>
  8003c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003c8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003cf:	e9 7a ff ff ff       	jmp    80034e <vprintfmt+0x59>
  8003d4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003d7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003da:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003de:	0f 89 6a ff ff ff    	jns    80034e <vprintfmt+0x59>
				width = precision, precision = -1;
  8003e4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003ea:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f1:	e9 58 ff ff ff       	jmp    80034e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  8003f6:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  8003fc:	e9 4d ff ff ff       	jmp    80034e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800401:	8b 45 14             	mov    0x14(%ebp),%eax
  800404:	8d 78 04             	lea    0x4(%eax),%edi
  800407:	83 ec 08             	sub    $0x8,%esp
  80040a:	53                   	push   %ebx
  80040b:	ff 30                	pushl  (%eax)
  80040d:	ff d6                	call   *%esi
			break;
  80040f:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800412:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800415:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  800418:	e9 fe fe ff ff       	jmp    80031b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80041d:	8b 45 14             	mov    0x14(%ebp),%eax
  800420:	8d 78 04             	lea    0x4(%eax),%edi
  800423:	8b 00                	mov    (%eax),%eax
  800425:	99                   	cltd   
  800426:	31 d0                	xor    %edx,%eax
  800428:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042a:	83 f8 07             	cmp    $0x7,%eax
  80042d:	7f 0b                	jg     80043a <vprintfmt+0x145>
  80042f:	8b 14 85 60 10 80 00 	mov    0x801060(,%eax,4),%edx
  800436:	85 d2                	test   %edx,%edx
  800438:	75 1b                	jne    800455 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80043a:	50                   	push   %eax
  80043b:	68 76 0e 80 00       	push   $0x800e76
  800440:	53                   	push   %ebx
  800441:	56                   	push   %esi
  800442:	e8 91 fe ff ff       	call   8002d8 <printfmt>
  800447:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80044a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80044d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800450:	e9 c6 fe ff ff       	jmp    80031b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800455:	52                   	push   %edx
  800456:	68 7f 0e 80 00       	push   $0x800e7f
  80045b:	53                   	push   %ebx
  80045c:	56                   	push   %esi
  80045d:	e8 76 fe ff ff       	call   8002d8 <printfmt>
  800462:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800465:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800468:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80046b:	e9 ab fe ff ff       	jmp    80031b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800470:	8b 45 14             	mov    0x14(%ebp),%eax
  800473:	83 c0 04             	add    $0x4,%eax
  800476:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800479:	8b 45 14             	mov    0x14(%ebp),%eax
  80047c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80047e:	85 ff                	test   %edi,%edi
  800480:	b8 6f 0e 80 00       	mov    $0x800e6f,%eax
  800485:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800488:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80048c:	0f 8e 94 00 00 00    	jle    800526 <vprintfmt+0x231>
  800492:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800496:	0f 84 98 00 00 00    	je     800534 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  80049c:	83 ec 08             	sub    $0x8,%esp
  80049f:	ff 75 d0             	pushl  -0x30(%ebp)
  8004a2:	57                   	push   %edi
  8004a3:	e8 5b 03 00 00       	call   800803 <strnlen>
  8004a8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004ab:	29 c1                	sub    %eax,%ecx
  8004ad:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004b0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004b3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ba:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004bd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bf:	eb 0f                	jmp    8004d0 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c1:	83 ec 08             	sub    $0x8,%esp
  8004c4:	53                   	push   %ebx
  8004c5:	ff 75 e0             	pushl  -0x20(%ebp)
  8004c8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ca:	83 ef 01             	sub    $0x1,%edi
  8004cd:	83 c4 10             	add    $0x10,%esp
  8004d0:	85 ff                	test   %edi,%edi
  8004d2:	7f ed                	jg     8004c1 <vprintfmt+0x1cc>
  8004d4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004d7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004da:	85 c9                	test   %ecx,%ecx
  8004dc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e1:	0f 49 c1             	cmovns %ecx,%eax
  8004e4:	29 c1                	sub    %eax,%ecx
  8004e6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004e9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ec:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ef:	89 cb                	mov    %ecx,%ebx
  8004f1:	eb 4d                	jmp    800540 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004f7:	74 1b                	je     800514 <vprintfmt+0x21f>
  8004f9:	0f be c0             	movsbl %al,%eax
  8004fc:	83 e8 20             	sub    $0x20,%eax
  8004ff:	83 f8 5e             	cmp    $0x5e,%eax
  800502:	76 10                	jbe    800514 <vprintfmt+0x21f>
					putch('?', putdat);
  800504:	83 ec 08             	sub    $0x8,%esp
  800507:	ff 75 0c             	pushl  0xc(%ebp)
  80050a:	6a 3f                	push   $0x3f
  80050c:	ff 55 08             	call   *0x8(%ebp)
  80050f:	83 c4 10             	add    $0x10,%esp
  800512:	eb 0d                	jmp    800521 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800514:	83 ec 08             	sub    $0x8,%esp
  800517:	ff 75 0c             	pushl  0xc(%ebp)
  80051a:	52                   	push   %edx
  80051b:	ff 55 08             	call   *0x8(%ebp)
  80051e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800521:	83 eb 01             	sub    $0x1,%ebx
  800524:	eb 1a                	jmp    800540 <vprintfmt+0x24b>
  800526:	89 75 08             	mov    %esi,0x8(%ebp)
  800529:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800532:	eb 0c                	jmp    800540 <vprintfmt+0x24b>
  800534:	89 75 08             	mov    %esi,0x8(%ebp)
  800537:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800540:	83 c7 01             	add    $0x1,%edi
  800543:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800547:	0f be d0             	movsbl %al,%edx
  80054a:	85 d2                	test   %edx,%edx
  80054c:	74 23                	je     800571 <vprintfmt+0x27c>
  80054e:	85 f6                	test   %esi,%esi
  800550:	78 a1                	js     8004f3 <vprintfmt+0x1fe>
  800552:	83 ee 01             	sub    $0x1,%esi
  800555:	79 9c                	jns    8004f3 <vprintfmt+0x1fe>
  800557:	89 df                	mov    %ebx,%edi
  800559:	8b 75 08             	mov    0x8(%ebp),%esi
  80055c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80055f:	eb 18                	jmp    800579 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800561:	83 ec 08             	sub    $0x8,%esp
  800564:	53                   	push   %ebx
  800565:	6a 20                	push   $0x20
  800567:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800569:	83 ef 01             	sub    $0x1,%edi
  80056c:	83 c4 10             	add    $0x10,%esp
  80056f:	eb 08                	jmp    800579 <vprintfmt+0x284>
  800571:	89 df                	mov    %ebx,%edi
  800573:	8b 75 08             	mov    0x8(%ebp),%esi
  800576:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800579:	85 ff                	test   %edi,%edi
  80057b:	7f e4                	jg     800561 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80057d:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800580:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800583:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800586:	e9 90 fd ff ff       	jmp    80031b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058b:	83 f9 01             	cmp    $0x1,%ecx
  80058e:	7e 19                	jle    8005a9 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8b 50 04             	mov    0x4(%eax),%edx
  800596:	8b 00                	mov    (%eax),%eax
  800598:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80059b:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80059e:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a1:	8d 40 08             	lea    0x8(%eax),%eax
  8005a4:	89 45 14             	mov    %eax,0x14(%ebp)
  8005a7:	eb 38                	jmp    8005e1 <vprintfmt+0x2ec>
	else if (lflag)
  8005a9:	85 c9                	test   %ecx,%ecx
  8005ab:	74 1b                	je     8005c8 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ad:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b0:	8b 00                	mov    (%eax),%eax
  8005b2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b5:	89 c1                	mov    %eax,%ecx
  8005b7:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c0:	8d 40 04             	lea    0x4(%eax),%eax
  8005c3:	89 45 14             	mov    %eax,0x14(%ebp)
  8005c6:	eb 19                	jmp    8005e1 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cb:	8b 00                	mov    (%eax),%eax
  8005cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d0:	89 c1                	mov    %eax,%ecx
  8005d2:	c1 f9 1f             	sar    $0x1f,%ecx
  8005d5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8d 40 04             	lea    0x4(%eax),%eax
  8005de:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005e7:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005ec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005f0:	0f 89 36 01 00 00    	jns    80072c <vprintfmt+0x437>
				putch('-', putdat);
  8005f6:	83 ec 08             	sub    $0x8,%esp
  8005f9:	53                   	push   %ebx
  8005fa:	6a 2d                	push   $0x2d
  8005fc:	ff d6                	call   *%esi
				num = -(long long) num;
  8005fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800601:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800604:	f7 da                	neg    %edx
  800606:	83 d1 00             	adc    $0x0,%ecx
  800609:	f7 d9                	neg    %ecx
  80060b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80060e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800613:	e9 14 01 00 00       	jmp    80072c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800618:	83 f9 01             	cmp    $0x1,%ecx
  80061b:	7e 18                	jle    800635 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80061d:	8b 45 14             	mov    0x14(%ebp),%eax
  800620:	8b 10                	mov    (%eax),%edx
  800622:	8b 48 04             	mov    0x4(%eax),%ecx
  800625:	8d 40 08             	lea    0x8(%eax),%eax
  800628:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80062b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800630:	e9 f7 00 00 00       	jmp    80072c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800635:	85 c9                	test   %ecx,%ecx
  800637:	74 1a                	je     800653 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800639:	8b 45 14             	mov    0x14(%ebp),%eax
  80063c:	8b 10                	mov    (%eax),%edx
  80063e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800643:	8d 40 04             	lea    0x4(%eax),%eax
  800646:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800649:	b8 0a 00 00 00       	mov    $0xa,%eax
  80064e:	e9 d9 00 00 00       	jmp    80072c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8b 10                	mov    (%eax),%edx
  800658:	b9 00 00 00 00       	mov    $0x0,%ecx
  80065d:	8d 40 04             	lea    0x4(%eax),%eax
  800660:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800663:	b8 0a 00 00 00       	mov    $0xa,%eax
  800668:	e9 bf 00 00 00       	jmp    80072c <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80066d:	83 f9 01             	cmp    $0x1,%ecx
  800670:	7e 13                	jle    800685 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  800672:	8b 45 14             	mov    0x14(%ebp),%eax
  800675:	8b 50 04             	mov    0x4(%eax),%edx
  800678:	8b 00                	mov    (%eax),%eax
  80067a:	8b 4d 14             	mov    0x14(%ebp),%ecx
  80067d:	8d 49 08             	lea    0x8(%ecx),%ecx
  800680:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800683:	eb 28                	jmp    8006ad <vprintfmt+0x3b8>
	else if (lflag)
  800685:	85 c9                	test   %ecx,%ecx
  800687:	74 13                	je     80069c <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  800689:	8b 45 14             	mov    0x14(%ebp),%eax
  80068c:	8b 10                	mov    (%eax),%edx
  80068e:	89 d0                	mov    %edx,%eax
  800690:	99                   	cltd   
  800691:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800694:	8d 49 04             	lea    0x4(%ecx),%ecx
  800697:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80069a:	eb 11                	jmp    8006ad <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  80069c:	8b 45 14             	mov    0x14(%ebp),%eax
  80069f:	8b 10                	mov    (%eax),%edx
  8006a1:	89 d0                	mov    %edx,%eax
  8006a3:	99                   	cltd   
  8006a4:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006a7:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006aa:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8006ad:	89 d1                	mov    %edx,%ecx
  8006af:	89 c2                	mov    %eax,%edx
			base = 8;
  8006b1:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006b6:	eb 74                	jmp    80072c <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8006b8:	83 ec 08             	sub    $0x8,%esp
  8006bb:	53                   	push   %ebx
  8006bc:	6a 30                	push   $0x30
  8006be:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c0:	83 c4 08             	add    $0x8,%esp
  8006c3:	53                   	push   %ebx
  8006c4:	6a 78                	push   $0x78
  8006c6:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cb:	8b 10                	mov    (%eax),%edx
  8006cd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d5:	8d 40 04             	lea    0x4(%eax),%eax
  8006d8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006db:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e0:	eb 4a                	jmp    80072c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e2:	83 f9 01             	cmp    $0x1,%ecx
  8006e5:	7e 15                	jle    8006fc <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  8006e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ea:	8b 10                	mov    (%eax),%edx
  8006ec:	8b 48 04             	mov    0x4(%eax),%ecx
  8006ef:	8d 40 08             	lea    0x8(%eax),%eax
  8006f2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f5:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fa:	eb 30                	jmp    80072c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006fc:	85 c9                	test   %ecx,%ecx
  8006fe:	74 17                	je     800717 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800700:	8b 45 14             	mov    0x14(%ebp),%eax
  800703:	8b 10                	mov    (%eax),%edx
  800705:	b9 00 00 00 00       	mov    $0x0,%ecx
  80070a:	8d 40 04             	lea    0x4(%eax),%eax
  80070d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800710:	b8 10 00 00 00       	mov    $0x10,%eax
  800715:	eb 15                	jmp    80072c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800717:	8b 45 14             	mov    0x14(%ebp),%eax
  80071a:	8b 10                	mov    (%eax),%edx
  80071c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800721:	8d 40 04             	lea    0x4(%eax),%eax
  800724:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800727:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80072c:	83 ec 0c             	sub    $0xc,%esp
  80072f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800733:	57                   	push   %edi
  800734:	ff 75 e0             	pushl  -0x20(%ebp)
  800737:	50                   	push   %eax
  800738:	51                   	push   %ecx
  800739:	52                   	push   %edx
  80073a:	89 da                	mov    %ebx,%edx
  80073c:	89 f0                	mov    %esi,%eax
  80073e:	e8 c9 fa ff ff       	call   80020c <printnum>
			break;
  800743:	83 c4 20             	add    $0x20,%esp
  800746:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800749:	e9 cd fb ff ff       	jmp    80031b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80074e:	83 ec 08             	sub    $0x8,%esp
  800751:	53                   	push   %ebx
  800752:	52                   	push   %edx
  800753:	ff d6                	call   *%esi
			break;
  800755:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800758:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80075b:	e9 bb fb ff ff       	jmp    80031b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800760:	83 ec 08             	sub    $0x8,%esp
  800763:	53                   	push   %ebx
  800764:	6a 25                	push   $0x25
  800766:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800768:	83 c4 10             	add    $0x10,%esp
  80076b:	eb 03                	jmp    800770 <vprintfmt+0x47b>
  80076d:	83 ef 01             	sub    $0x1,%edi
  800770:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800774:	75 f7                	jne    80076d <vprintfmt+0x478>
  800776:	e9 a0 fb ff ff       	jmp    80031b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80077b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80077e:	5b                   	pop    %ebx
  80077f:	5e                   	pop    %esi
  800780:	5f                   	pop    %edi
  800781:	5d                   	pop    %ebp
  800782:	c3                   	ret    

00800783 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800783:	55                   	push   %ebp
  800784:	89 e5                	mov    %esp,%ebp
  800786:	83 ec 18             	sub    $0x18,%esp
  800789:	8b 45 08             	mov    0x8(%ebp),%eax
  80078c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80078f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800792:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800796:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800799:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a0:	85 c0                	test   %eax,%eax
  8007a2:	74 26                	je     8007ca <vsnprintf+0x47>
  8007a4:	85 d2                	test   %edx,%edx
  8007a6:	7e 22                	jle    8007ca <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007a8:	ff 75 14             	pushl  0x14(%ebp)
  8007ab:	ff 75 10             	pushl  0x10(%ebp)
  8007ae:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b1:	50                   	push   %eax
  8007b2:	68 bb 02 80 00       	push   $0x8002bb
  8007b7:	e8 39 fb ff ff       	call   8002f5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007bf:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007c5:	83 c4 10             	add    $0x10,%esp
  8007c8:	eb 05                	jmp    8007cf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007ca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007cf:	c9                   	leave  
  8007d0:	c3                   	ret    

008007d1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d1:	55                   	push   %ebp
  8007d2:	89 e5                	mov    %esp,%ebp
  8007d4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007d7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007da:	50                   	push   %eax
  8007db:	ff 75 10             	pushl  0x10(%ebp)
  8007de:	ff 75 0c             	pushl  0xc(%ebp)
  8007e1:	ff 75 08             	pushl  0x8(%ebp)
  8007e4:	e8 9a ff ff ff       	call   800783 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007e9:	c9                   	leave  
  8007ea:	c3                   	ret    

008007eb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007eb:	55                   	push   %ebp
  8007ec:	89 e5                	mov    %esp,%ebp
  8007ee:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f1:	b8 00 00 00 00       	mov    $0x0,%eax
  8007f6:	eb 03                	jmp    8007fb <strlen+0x10>
		n++;
  8007f8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007ff:	75 f7                	jne    8007f8 <strlen+0xd>
		n++;
	return n;
}
  800801:	5d                   	pop    %ebp
  800802:	c3                   	ret    

00800803 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800803:	55                   	push   %ebp
  800804:	89 e5                	mov    %esp,%ebp
  800806:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800809:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080c:	ba 00 00 00 00       	mov    $0x0,%edx
  800811:	eb 03                	jmp    800816 <strnlen+0x13>
		n++;
  800813:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800816:	39 c2                	cmp    %eax,%edx
  800818:	74 08                	je     800822 <strnlen+0x1f>
  80081a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80081e:	75 f3                	jne    800813 <strnlen+0x10>
  800820:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800822:	5d                   	pop    %ebp
  800823:	c3                   	ret    

00800824 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800824:	55                   	push   %ebp
  800825:	89 e5                	mov    %esp,%ebp
  800827:	53                   	push   %ebx
  800828:	8b 45 08             	mov    0x8(%ebp),%eax
  80082b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80082e:	89 c2                	mov    %eax,%edx
  800830:	83 c2 01             	add    $0x1,%edx
  800833:	83 c1 01             	add    $0x1,%ecx
  800836:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083a:	88 5a ff             	mov    %bl,-0x1(%edx)
  80083d:	84 db                	test   %bl,%bl
  80083f:	75 ef                	jne    800830 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800841:	5b                   	pop    %ebx
  800842:	5d                   	pop    %ebp
  800843:	c3                   	ret    

00800844 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800844:	55                   	push   %ebp
  800845:	89 e5                	mov    %esp,%ebp
  800847:	53                   	push   %ebx
  800848:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80084b:	53                   	push   %ebx
  80084c:	e8 9a ff ff ff       	call   8007eb <strlen>
  800851:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800854:	ff 75 0c             	pushl  0xc(%ebp)
  800857:	01 d8                	add    %ebx,%eax
  800859:	50                   	push   %eax
  80085a:	e8 c5 ff ff ff       	call   800824 <strcpy>
	return dst;
}
  80085f:	89 d8                	mov    %ebx,%eax
  800861:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800864:	c9                   	leave  
  800865:	c3                   	ret    

00800866 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800866:	55                   	push   %ebp
  800867:	89 e5                	mov    %esp,%ebp
  800869:	56                   	push   %esi
  80086a:	53                   	push   %ebx
  80086b:	8b 75 08             	mov    0x8(%ebp),%esi
  80086e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800871:	89 f3                	mov    %esi,%ebx
  800873:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800876:	89 f2                	mov    %esi,%edx
  800878:	eb 0f                	jmp    800889 <strncpy+0x23>
		*dst++ = *src;
  80087a:	83 c2 01             	add    $0x1,%edx
  80087d:	0f b6 01             	movzbl (%ecx),%eax
  800880:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800883:	80 39 01             	cmpb   $0x1,(%ecx)
  800886:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800889:	39 da                	cmp    %ebx,%edx
  80088b:	75 ed                	jne    80087a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80088d:	89 f0                	mov    %esi,%eax
  80088f:	5b                   	pop    %ebx
  800890:	5e                   	pop    %esi
  800891:	5d                   	pop    %ebp
  800892:	c3                   	ret    

00800893 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800893:	55                   	push   %ebp
  800894:	89 e5                	mov    %esp,%ebp
  800896:	56                   	push   %esi
  800897:	53                   	push   %ebx
  800898:	8b 75 08             	mov    0x8(%ebp),%esi
  80089b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80089e:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a3:	85 d2                	test   %edx,%edx
  8008a5:	74 21                	je     8008c8 <strlcpy+0x35>
  8008a7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008ab:	89 f2                	mov    %esi,%edx
  8008ad:	eb 09                	jmp    8008b8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008af:	83 c2 01             	add    $0x1,%edx
  8008b2:	83 c1 01             	add    $0x1,%ecx
  8008b5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008b8:	39 c2                	cmp    %eax,%edx
  8008ba:	74 09                	je     8008c5 <strlcpy+0x32>
  8008bc:	0f b6 19             	movzbl (%ecx),%ebx
  8008bf:	84 db                	test   %bl,%bl
  8008c1:	75 ec                	jne    8008af <strlcpy+0x1c>
  8008c3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008c8:	29 f0                	sub    %esi,%eax
}
  8008ca:	5b                   	pop    %ebx
  8008cb:	5e                   	pop    %esi
  8008cc:	5d                   	pop    %ebp
  8008cd:	c3                   	ret    

008008ce <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008ce:	55                   	push   %ebp
  8008cf:	89 e5                	mov    %esp,%ebp
  8008d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008d7:	eb 06                	jmp    8008df <strcmp+0x11>
		p++, q++;
  8008d9:	83 c1 01             	add    $0x1,%ecx
  8008dc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008df:	0f b6 01             	movzbl (%ecx),%eax
  8008e2:	84 c0                	test   %al,%al
  8008e4:	74 04                	je     8008ea <strcmp+0x1c>
  8008e6:	3a 02                	cmp    (%edx),%al
  8008e8:	74 ef                	je     8008d9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ea:	0f b6 c0             	movzbl %al,%eax
  8008ed:	0f b6 12             	movzbl (%edx),%edx
  8008f0:	29 d0                	sub    %edx,%eax
}
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	53                   	push   %ebx
  8008f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fe:	89 c3                	mov    %eax,%ebx
  800900:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800903:	eb 06                	jmp    80090b <strncmp+0x17>
		n--, p++, q++;
  800905:	83 c0 01             	add    $0x1,%eax
  800908:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80090b:	39 d8                	cmp    %ebx,%eax
  80090d:	74 15                	je     800924 <strncmp+0x30>
  80090f:	0f b6 08             	movzbl (%eax),%ecx
  800912:	84 c9                	test   %cl,%cl
  800914:	74 04                	je     80091a <strncmp+0x26>
  800916:	3a 0a                	cmp    (%edx),%cl
  800918:	74 eb                	je     800905 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80091a:	0f b6 00             	movzbl (%eax),%eax
  80091d:	0f b6 12             	movzbl (%edx),%edx
  800920:	29 d0                	sub    %edx,%eax
  800922:	eb 05                	jmp    800929 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800924:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800929:	5b                   	pop    %ebx
  80092a:	5d                   	pop    %ebp
  80092b:	c3                   	ret    

0080092c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80092c:	55                   	push   %ebp
  80092d:	89 e5                	mov    %esp,%ebp
  80092f:	8b 45 08             	mov    0x8(%ebp),%eax
  800932:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800936:	eb 07                	jmp    80093f <strchr+0x13>
		if (*s == c)
  800938:	38 ca                	cmp    %cl,%dl
  80093a:	74 0f                	je     80094b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80093c:	83 c0 01             	add    $0x1,%eax
  80093f:	0f b6 10             	movzbl (%eax),%edx
  800942:	84 d2                	test   %dl,%dl
  800944:	75 f2                	jne    800938 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800946:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094b:	5d                   	pop    %ebp
  80094c:	c3                   	ret    

0080094d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094d:	55                   	push   %ebp
  80094e:	89 e5                	mov    %esp,%ebp
  800950:	8b 45 08             	mov    0x8(%ebp),%eax
  800953:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800957:	eb 03                	jmp    80095c <strfind+0xf>
  800959:	83 c0 01             	add    $0x1,%eax
  80095c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80095f:	38 ca                	cmp    %cl,%dl
  800961:	74 04                	je     800967 <strfind+0x1a>
  800963:	84 d2                	test   %dl,%dl
  800965:	75 f2                	jne    800959 <strfind+0xc>
			break;
	return (char *) s;
}
  800967:	5d                   	pop    %ebp
  800968:	c3                   	ret    

00800969 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800969:	55                   	push   %ebp
  80096a:	89 e5                	mov    %esp,%ebp
  80096c:	57                   	push   %edi
  80096d:	56                   	push   %esi
  80096e:	53                   	push   %ebx
  80096f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800972:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800975:	85 c9                	test   %ecx,%ecx
  800977:	74 36                	je     8009af <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800979:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80097f:	75 28                	jne    8009a9 <memset+0x40>
  800981:	f6 c1 03             	test   $0x3,%cl
  800984:	75 23                	jne    8009a9 <memset+0x40>
		c &= 0xFF;
  800986:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098a:	89 d3                	mov    %edx,%ebx
  80098c:	c1 e3 08             	shl    $0x8,%ebx
  80098f:	89 d6                	mov    %edx,%esi
  800991:	c1 e6 18             	shl    $0x18,%esi
  800994:	89 d0                	mov    %edx,%eax
  800996:	c1 e0 10             	shl    $0x10,%eax
  800999:	09 f0                	or     %esi,%eax
  80099b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80099d:	89 d8                	mov    %ebx,%eax
  80099f:	09 d0                	or     %edx,%eax
  8009a1:	c1 e9 02             	shr    $0x2,%ecx
  8009a4:	fc                   	cld    
  8009a5:	f3 ab                	rep stos %eax,%es:(%edi)
  8009a7:	eb 06                	jmp    8009af <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ac:	fc                   	cld    
  8009ad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009af:	89 f8                	mov    %edi,%eax
  8009b1:	5b                   	pop    %ebx
  8009b2:	5e                   	pop    %esi
  8009b3:	5f                   	pop    %edi
  8009b4:	5d                   	pop    %ebp
  8009b5:	c3                   	ret    

008009b6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b6:	55                   	push   %ebp
  8009b7:	89 e5                	mov    %esp,%ebp
  8009b9:	57                   	push   %edi
  8009ba:	56                   	push   %esi
  8009bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009be:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c4:	39 c6                	cmp    %eax,%esi
  8009c6:	73 35                	jae    8009fd <memmove+0x47>
  8009c8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009cb:	39 d0                	cmp    %edx,%eax
  8009cd:	73 2e                	jae    8009fd <memmove+0x47>
		s += n;
		d += n;
  8009cf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d2:	89 d6                	mov    %edx,%esi
  8009d4:	09 fe                	or     %edi,%esi
  8009d6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009dc:	75 13                	jne    8009f1 <memmove+0x3b>
  8009de:	f6 c1 03             	test   $0x3,%cl
  8009e1:	75 0e                	jne    8009f1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e3:	83 ef 04             	sub    $0x4,%edi
  8009e6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009e9:	c1 e9 02             	shr    $0x2,%ecx
  8009ec:	fd                   	std    
  8009ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ef:	eb 09                	jmp    8009fa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f1:	83 ef 01             	sub    $0x1,%edi
  8009f4:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009f7:	fd                   	std    
  8009f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009fa:	fc                   	cld    
  8009fb:	eb 1d                	jmp    800a1a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009fd:	89 f2                	mov    %esi,%edx
  8009ff:	09 c2                	or     %eax,%edx
  800a01:	f6 c2 03             	test   $0x3,%dl
  800a04:	75 0f                	jne    800a15 <memmove+0x5f>
  800a06:	f6 c1 03             	test   $0x3,%cl
  800a09:	75 0a                	jne    800a15 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a0b:	c1 e9 02             	shr    $0x2,%ecx
  800a0e:	89 c7                	mov    %eax,%edi
  800a10:	fc                   	cld    
  800a11:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a13:	eb 05                	jmp    800a1a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a15:	89 c7                	mov    %eax,%edi
  800a17:	fc                   	cld    
  800a18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1a:	5e                   	pop    %esi
  800a1b:	5f                   	pop    %edi
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a21:	ff 75 10             	pushl  0x10(%ebp)
  800a24:	ff 75 0c             	pushl  0xc(%ebp)
  800a27:	ff 75 08             	pushl  0x8(%ebp)
  800a2a:	e8 87 ff ff ff       	call   8009b6 <memmove>
}
  800a2f:	c9                   	leave  
  800a30:	c3                   	ret    

00800a31 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a31:	55                   	push   %ebp
  800a32:	89 e5                	mov    %esp,%ebp
  800a34:	56                   	push   %esi
  800a35:	53                   	push   %ebx
  800a36:	8b 45 08             	mov    0x8(%ebp),%eax
  800a39:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a3c:	89 c6                	mov    %eax,%esi
  800a3e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a41:	eb 1a                	jmp    800a5d <memcmp+0x2c>
		if (*s1 != *s2)
  800a43:	0f b6 08             	movzbl (%eax),%ecx
  800a46:	0f b6 1a             	movzbl (%edx),%ebx
  800a49:	38 d9                	cmp    %bl,%cl
  800a4b:	74 0a                	je     800a57 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a4d:	0f b6 c1             	movzbl %cl,%eax
  800a50:	0f b6 db             	movzbl %bl,%ebx
  800a53:	29 d8                	sub    %ebx,%eax
  800a55:	eb 0f                	jmp    800a66 <memcmp+0x35>
		s1++, s2++;
  800a57:	83 c0 01             	add    $0x1,%eax
  800a5a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a5d:	39 f0                	cmp    %esi,%eax
  800a5f:	75 e2                	jne    800a43 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a61:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a66:	5b                   	pop    %ebx
  800a67:	5e                   	pop    %esi
  800a68:	5d                   	pop    %ebp
  800a69:	c3                   	ret    

00800a6a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a6a:	55                   	push   %ebp
  800a6b:	89 e5                	mov    %esp,%ebp
  800a6d:	53                   	push   %ebx
  800a6e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a71:	89 c1                	mov    %eax,%ecx
  800a73:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a76:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a7a:	eb 0a                	jmp    800a86 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7c:	0f b6 10             	movzbl (%eax),%edx
  800a7f:	39 da                	cmp    %ebx,%edx
  800a81:	74 07                	je     800a8a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a83:	83 c0 01             	add    $0x1,%eax
  800a86:	39 c8                	cmp    %ecx,%eax
  800a88:	72 f2                	jb     800a7c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a8a:	5b                   	pop    %ebx
  800a8b:	5d                   	pop    %ebp
  800a8c:	c3                   	ret    

00800a8d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a8d:	55                   	push   %ebp
  800a8e:	89 e5                	mov    %esp,%ebp
  800a90:	57                   	push   %edi
  800a91:	56                   	push   %esi
  800a92:	53                   	push   %ebx
  800a93:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a96:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a99:	eb 03                	jmp    800a9e <strtol+0x11>
		s++;
  800a9b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9e:	0f b6 01             	movzbl (%ecx),%eax
  800aa1:	3c 20                	cmp    $0x20,%al
  800aa3:	74 f6                	je     800a9b <strtol+0xe>
  800aa5:	3c 09                	cmp    $0x9,%al
  800aa7:	74 f2                	je     800a9b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aa9:	3c 2b                	cmp    $0x2b,%al
  800aab:	75 0a                	jne    800ab7 <strtol+0x2a>
		s++;
  800aad:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab0:	bf 00 00 00 00       	mov    $0x0,%edi
  800ab5:	eb 11                	jmp    800ac8 <strtol+0x3b>
  800ab7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800abc:	3c 2d                	cmp    $0x2d,%al
  800abe:	75 08                	jne    800ac8 <strtol+0x3b>
		s++, neg = 1;
  800ac0:	83 c1 01             	add    $0x1,%ecx
  800ac3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ac8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ace:	75 15                	jne    800ae5 <strtol+0x58>
  800ad0:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad3:	75 10                	jne    800ae5 <strtol+0x58>
  800ad5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ad9:	75 7c                	jne    800b57 <strtol+0xca>
		s += 2, base = 16;
  800adb:	83 c1 02             	add    $0x2,%ecx
  800ade:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae3:	eb 16                	jmp    800afb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ae5:	85 db                	test   %ebx,%ebx
  800ae7:	75 12                	jne    800afb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ae9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800aee:	80 39 30             	cmpb   $0x30,(%ecx)
  800af1:	75 08                	jne    800afb <strtol+0x6e>
		s++, base = 8;
  800af3:	83 c1 01             	add    $0x1,%ecx
  800af6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800afb:	b8 00 00 00 00       	mov    $0x0,%eax
  800b00:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b03:	0f b6 11             	movzbl (%ecx),%edx
  800b06:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b09:	89 f3                	mov    %esi,%ebx
  800b0b:	80 fb 09             	cmp    $0x9,%bl
  800b0e:	77 08                	ja     800b18 <strtol+0x8b>
			dig = *s - '0';
  800b10:	0f be d2             	movsbl %dl,%edx
  800b13:	83 ea 30             	sub    $0x30,%edx
  800b16:	eb 22                	jmp    800b3a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b18:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b1b:	89 f3                	mov    %esi,%ebx
  800b1d:	80 fb 19             	cmp    $0x19,%bl
  800b20:	77 08                	ja     800b2a <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b22:	0f be d2             	movsbl %dl,%edx
  800b25:	83 ea 57             	sub    $0x57,%edx
  800b28:	eb 10                	jmp    800b3a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b2a:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b2d:	89 f3                	mov    %esi,%ebx
  800b2f:	80 fb 19             	cmp    $0x19,%bl
  800b32:	77 16                	ja     800b4a <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b34:	0f be d2             	movsbl %dl,%edx
  800b37:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b3a:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b3d:	7d 0b                	jge    800b4a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b3f:	83 c1 01             	add    $0x1,%ecx
  800b42:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b46:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b48:	eb b9                	jmp    800b03 <strtol+0x76>

	if (endptr)
  800b4a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b4e:	74 0d                	je     800b5d <strtol+0xd0>
		*endptr = (char *) s;
  800b50:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b53:	89 0e                	mov    %ecx,(%esi)
  800b55:	eb 06                	jmp    800b5d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b57:	85 db                	test   %ebx,%ebx
  800b59:	74 98                	je     800af3 <strtol+0x66>
  800b5b:	eb 9e                	jmp    800afb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b5d:	89 c2                	mov    %eax,%edx
  800b5f:	f7 da                	neg    %edx
  800b61:	85 ff                	test   %edi,%edi
  800b63:	0f 45 c2             	cmovne %edx,%eax
}
  800b66:	5b                   	pop    %ebx
  800b67:	5e                   	pop    %esi
  800b68:	5f                   	pop    %edi
  800b69:	5d                   	pop    %ebp
  800b6a:	c3                   	ret    
  800b6b:	66 90                	xchg   %ax,%ax
  800b6d:	66 90                	xchg   %ax,%ax
  800b6f:	90                   	nop

00800b70 <__udivdi3>:
  800b70:	55                   	push   %ebp
  800b71:	57                   	push   %edi
  800b72:	56                   	push   %esi
  800b73:	53                   	push   %ebx
  800b74:	83 ec 1c             	sub    $0x1c,%esp
  800b77:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b7b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b7f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b87:	85 f6                	test   %esi,%esi
  800b89:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b8d:	89 ca                	mov    %ecx,%edx
  800b8f:	89 f8                	mov    %edi,%eax
  800b91:	75 3d                	jne    800bd0 <__udivdi3+0x60>
  800b93:	39 cf                	cmp    %ecx,%edi
  800b95:	0f 87 c5 00 00 00    	ja     800c60 <__udivdi3+0xf0>
  800b9b:	85 ff                	test   %edi,%edi
  800b9d:	89 fd                	mov    %edi,%ebp
  800b9f:	75 0b                	jne    800bac <__udivdi3+0x3c>
  800ba1:	b8 01 00 00 00       	mov    $0x1,%eax
  800ba6:	31 d2                	xor    %edx,%edx
  800ba8:	f7 f7                	div    %edi
  800baa:	89 c5                	mov    %eax,%ebp
  800bac:	89 c8                	mov    %ecx,%eax
  800bae:	31 d2                	xor    %edx,%edx
  800bb0:	f7 f5                	div    %ebp
  800bb2:	89 c1                	mov    %eax,%ecx
  800bb4:	89 d8                	mov    %ebx,%eax
  800bb6:	89 cf                	mov    %ecx,%edi
  800bb8:	f7 f5                	div    %ebp
  800bba:	89 c3                	mov    %eax,%ebx
  800bbc:	89 d8                	mov    %ebx,%eax
  800bbe:	89 fa                	mov    %edi,%edx
  800bc0:	83 c4 1c             	add    $0x1c,%esp
  800bc3:	5b                   	pop    %ebx
  800bc4:	5e                   	pop    %esi
  800bc5:	5f                   	pop    %edi
  800bc6:	5d                   	pop    %ebp
  800bc7:	c3                   	ret    
  800bc8:	90                   	nop
  800bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bd0:	39 ce                	cmp    %ecx,%esi
  800bd2:	77 74                	ja     800c48 <__udivdi3+0xd8>
  800bd4:	0f bd fe             	bsr    %esi,%edi
  800bd7:	83 f7 1f             	xor    $0x1f,%edi
  800bda:	0f 84 98 00 00 00    	je     800c78 <__udivdi3+0x108>
  800be0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	89 c5                	mov    %eax,%ebp
  800be9:	29 fb                	sub    %edi,%ebx
  800beb:	d3 e6                	shl    %cl,%esi
  800bed:	89 d9                	mov    %ebx,%ecx
  800bef:	d3 ed                	shr    %cl,%ebp
  800bf1:	89 f9                	mov    %edi,%ecx
  800bf3:	d3 e0                	shl    %cl,%eax
  800bf5:	09 ee                	or     %ebp,%esi
  800bf7:	89 d9                	mov    %ebx,%ecx
  800bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bfd:	89 d5                	mov    %edx,%ebp
  800bff:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c03:	d3 ed                	shr    %cl,%ebp
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e2                	shl    %cl,%edx
  800c09:	89 d9                	mov    %ebx,%ecx
  800c0b:	d3 e8                	shr    %cl,%eax
  800c0d:	09 c2                	or     %eax,%edx
  800c0f:	89 d0                	mov    %edx,%eax
  800c11:	89 ea                	mov    %ebp,%edx
  800c13:	f7 f6                	div    %esi
  800c15:	89 d5                	mov    %edx,%ebp
  800c17:	89 c3                	mov    %eax,%ebx
  800c19:	f7 64 24 0c          	mull   0xc(%esp)
  800c1d:	39 d5                	cmp    %edx,%ebp
  800c1f:	72 10                	jb     800c31 <__udivdi3+0xc1>
  800c21:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c25:	89 f9                	mov    %edi,%ecx
  800c27:	d3 e6                	shl    %cl,%esi
  800c29:	39 c6                	cmp    %eax,%esi
  800c2b:	73 07                	jae    800c34 <__udivdi3+0xc4>
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	75 03                	jne    800c34 <__udivdi3+0xc4>
  800c31:	83 eb 01             	sub    $0x1,%ebx
  800c34:	31 ff                	xor    %edi,%edi
  800c36:	89 d8                	mov    %ebx,%eax
  800c38:	89 fa                	mov    %edi,%edx
  800c3a:	83 c4 1c             	add    $0x1c,%esp
  800c3d:	5b                   	pop    %ebx
  800c3e:	5e                   	pop    %esi
  800c3f:	5f                   	pop    %edi
  800c40:	5d                   	pop    %ebp
  800c41:	c3                   	ret    
  800c42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c48:	31 ff                	xor    %edi,%edi
  800c4a:	31 db                	xor    %ebx,%ebx
  800c4c:	89 d8                	mov    %ebx,%eax
  800c4e:	89 fa                	mov    %edi,%edx
  800c50:	83 c4 1c             	add    $0x1c,%esp
  800c53:	5b                   	pop    %ebx
  800c54:	5e                   	pop    %esi
  800c55:	5f                   	pop    %edi
  800c56:	5d                   	pop    %ebp
  800c57:	c3                   	ret    
  800c58:	90                   	nop
  800c59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c60:	89 d8                	mov    %ebx,%eax
  800c62:	f7 f7                	div    %edi
  800c64:	31 ff                	xor    %edi,%edi
  800c66:	89 c3                	mov    %eax,%ebx
  800c68:	89 d8                	mov    %ebx,%eax
  800c6a:	89 fa                	mov    %edi,%edx
  800c6c:	83 c4 1c             	add    $0x1c,%esp
  800c6f:	5b                   	pop    %ebx
  800c70:	5e                   	pop    %esi
  800c71:	5f                   	pop    %edi
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    
  800c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c78:	39 ce                	cmp    %ecx,%esi
  800c7a:	72 0c                	jb     800c88 <__udivdi3+0x118>
  800c7c:	31 db                	xor    %ebx,%ebx
  800c7e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c82:	0f 87 34 ff ff ff    	ja     800bbc <__udivdi3+0x4c>
  800c88:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c8d:	e9 2a ff ff ff       	jmp    800bbc <__udivdi3+0x4c>
  800c92:	66 90                	xchg   %ax,%ax
  800c94:	66 90                	xchg   %ax,%ax
  800c96:	66 90                	xchg   %ax,%ax
  800c98:	66 90                	xchg   %ax,%ax
  800c9a:	66 90                	xchg   %ax,%ax
  800c9c:	66 90                	xchg   %ax,%ax
  800c9e:	66 90                	xchg   %ax,%ax

00800ca0 <__umoddi3>:
  800ca0:	55                   	push   %ebp
  800ca1:	57                   	push   %edi
  800ca2:	56                   	push   %esi
  800ca3:	53                   	push   %ebx
  800ca4:	83 ec 1c             	sub    $0x1c,%esp
  800ca7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800caf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cb7:	85 d2                	test   %edx,%edx
  800cb9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cbd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cc1:	89 f3                	mov    %esi,%ebx
  800cc3:	89 3c 24             	mov    %edi,(%esp)
  800cc6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cca:	75 1c                	jne    800ce8 <__umoddi3+0x48>
  800ccc:	39 f7                	cmp    %esi,%edi
  800cce:	76 50                	jbe    800d20 <__umoddi3+0x80>
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	f7 f7                	div    %edi
  800cd6:	89 d0                	mov    %edx,%eax
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	83 c4 1c             	add    $0x1c,%esp
  800cdd:	5b                   	pop    %ebx
  800cde:	5e                   	pop    %esi
  800cdf:	5f                   	pop    %edi
  800ce0:	5d                   	pop    %ebp
  800ce1:	c3                   	ret    
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	39 f2                	cmp    %esi,%edx
  800cea:	89 d0                	mov    %edx,%eax
  800cec:	77 52                	ja     800d40 <__umoddi3+0xa0>
  800cee:	0f bd ea             	bsr    %edx,%ebp
  800cf1:	83 f5 1f             	xor    $0x1f,%ebp
  800cf4:	75 5a                	jne    800d50 <__umoddi3+0xb0>
  800cf6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cfa:	0f 82 e0 00 00 00    	jb     800de0 <__umoddi3+0x140>
  800d00:	39 0c 24             	cmp    %ecx,(%esp)
  800d03:	0f 86 d7 00 00 00    	jbe    800de0 <__umoddi3+0x140>
  800d09:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d0d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d11:	83 c4 1c             	add    $0x1c,%esp
  800d14:	5b                   	pop    %ebx
  800d15:	5e                   	pop    %esi
  800d16:	5f                   	pop    %edi
  800d17:	5d                   	pop    %ebp
  800d18:	c3                   	ret    
  800d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d20:	85 ff                	test   %edi,%edi
  800d22:	89 fd                	mov    %edi,%ebp
  800d24:	75 0b                	jne    800d31 <__umoddi3+0x91>
  800d26:	b8 01 00 00 00       	mov    $0x1,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	f7 f7                	div    %edi
  800d2f:	89 c5                	mov    %eax,%ebp
  800d31:	89 f0                	mov    %esi,%eax
  800d33:	31 d2                	xor    %edx,%edx
  800d35:	f7 f5                	div    %ebp
  800d37:	89 c8                	mov    %ecx,%eax
  800d39:	f7 f5                	div    %ebp
  800d3b:	89 d0                	mov    %edx,%eax
  800d3d:	eb 99                	jmp    800cd8 <__umoddi3+0x38>
  800d3f:	90                   	nop
  800d40:	89 c8                	mov    %ecx,%eax
  800d42:	89 f2                	mov    %esi,%edx
  800d44:	83 c4 1c             	add    $0x1c,%esp
  800d47:	5b                   	pop    %ebx
  800d48:	5e                   	pop    %esi
  800d49:	5f                   	pop    %edi
  800d4a:	5d                   	pop    %ebp
  800d4b:	c3                   	ret    
  800d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d50:	8b 34 24             	mov    (%esp),%esi
  800d53:	bf 20 00 00 00       	mov    $0x20,%edi
  800d58:	89 e9                	mov    %ebp,%ecx
  800d5a:	29 ef                	sub    %ebp,%edi
  800d5c:	d3 e0                	shl    %cl,%eax
  800d5e:	89 f9                	mov    %edi,%ecx
  800d60:	89 f2                	mov    %esi,%edx
  800d62:	d3 ea                	shr    %cl,%edx
  800d64:	89 e9                	mov    %ebp,%ecx
  800d66:	09 c2                	or     %eax,%edx
  800d68:	89 d8                	mov    %ebx,%eax
  800d6a:	89 14 24             	mov    %edx,(%esp)
  800d6d:	89 f2                	mov    %esi,%edx
  800d6f:	d3 e2                	shl    %cl,%edx
  800d71:	89 f9                	mov    %edi,%ecx
  800d73:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d77:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d7b:	d3 e8                	shr    %cl,%eax
  800d7d:	89 e9                	mov    %ebp,%ecx
  800d7f:	89 c6                	mov    %eax,%esi
  800d81:	d3 e3                	shl    %cl,%ebx
  800d83:	89 f9                	mov    %edi,%ecx
  800d85:	89 d0                	mov    %edx,%eax
  800d87:	d3 e8                	shr    %cl,%eax
  800d89:	89 e9                	mov    %ebp,%ecx
  800d8b:	09 d8                	or     %ebx,%eax
  800d8d:	89 d3                	mov    %edx,%ebx
  800d8f:	89 f2                	mov    %esi,%edx
  800d91:	f7 34 24             	divl   (%esp)
  800d94:	89 d6                	mov    %edx,%esi
  800d96:	d3 e3                	shl    %cl,%ebx
  800d98:	f7 64 24 04          	mull   0x4(%esp)
  800d9c:	39 d6                	cmp    %edx,%esi
  800d9e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800da2:	89 d1                	mov    %edx,%ecx
  800da4:	89 c3                	mov    %eax,%ebx
  800da6:	72 08                	jb     800db0 <__umoddi3+0x110>
  800da8:	75 11                	jne    800dbb <__umoddi3+0x11b>
  800daa:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dae:	73 0b                	jae    800dbb <__umoddi3+0x11b>
  800db0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800db4:	1b 14 24             	sbb    (%esp),%edx
  800db7:	89 d1                	mov    %edx,%ecx
  800db9:	89 c3                	mov    %eax,%ebx
  800dbb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dbf:	29 da                	sub    %ebx,%edx
  800dc1:	19 ce                	sbb    %ecx,%esi
  800dc3:	89 f9                	mov    %edi,%ecx
  800dc5:	89 f0                	mov    %esi,%eax
  800dc7:	d3 e0                	shl    %cl,%eax
  800dc9:	89 e9                	mov    %ebp,%ecx
  800dcb:	d3 ea                	shr    %cl,%edx
  800dcd:	89 e9                	mov    %ebp,%ecx
  800dcf:	d3 ee                	shr    %cl,%esi
  800dd1:	09 d0                	or     %edx,%eax
  800dd3:	89 f2                	mov    %esi,%edx
  800dd5:	83 c4 1c             	add    $0x1c,%esp
  800dd8:	5b                   	pop    %ebx
  800dd9:	5e                   	pop    %esi
  800dda:	5f                   	pop    %edi
  800ddb:	5d                   	pop    %ebp
  800ddc:	c3                   	ret    
  800ddd:	8d 76 00             	lea    0x0(%esi),%esi
  800de0:	29 f9                	sub    %edi,%ecx
  800de2:	19 d6                	sbb    %edx,%esi
  800de4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800de8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dec:	e9 18 ff ff ff       	jmp    800d09 <__umoddi3+0x69>
