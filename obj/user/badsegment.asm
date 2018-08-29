
obj/user/badsegment:     file format elf32-i386


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
  80002c:	e8 0d 00 00 00       	call   80003e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800036:	66 b8 28 00          	mov    $0x28,%ax
  80003a:	8e d8                	mov    %eax,%ds
}
  80003c:	5d                   	pop    %ebp
  80003d:	c3                   	ret    

0080003e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003e:	55                   	push   %ebp
  80003f:	89 e5                	mov    %esp,%ebp
  800041:	83 ec 08             	sub    $0x8,%esp
  800044:	8b 45 08             	mov    0x8(%ebp),%eax
  800047:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800051:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800054:	85 c0                	test   %eax,%eax
  800056:	7e 08                	jle    800060 <libmain+0x22>
		binaryname = argv[0];
  800058:	8b 0a                	mov    (%edx),%ecx
  80005a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800060:	83 ec 08             	sub    $0x8,%esp
  800063:	52                   	push   %edx
  800064:	50                   	push   %eax
  800065:	e8 c9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006a:	e8 05 00 00 00       	call   800074 <exit>
}
  80006f:	83 c4 10             	add    $0x10,%esp
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80007a:	6a 00                	push   $0x0
  80007c:	e8 42 00 00 00       	call   8000c3 <sys_env_destroy>
}
  800081:	83 c4 10             	add    $0x10,%esp
  800084:	c9                   	leave  
  800085:	c3                   	ret    

00800086 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800086:	55                   	push   %ebp
  800087:	89 e5                	mov    %esp,%ebp
  800089:	57                   	push   %edi
  80008a:	56                   	push   %esi
  80008b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80008c:	b8 00 00 00 00       	mov    $0x0,%eax
  800091:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800094:	8b 55 08             	mov    0x8(%ebp),%edx
  800097:	89 c3                	mov    %eax,%ebx
  800099:	89 c7                	mov    %eax,%edi
  80009b:	89 c6                	mov    %eax,%esi
  80009d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009f:	5b                   	pop    %ebx
  8000a0:	5e                   	pop    %esi
  8000a1:	5f                   	pop    %edi
  8000a2:	5d                   	pop    %ebp
  8000a3:	c3                   	ret    

008000a4 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a4:	55                   	push   %ebp
  8000a5:	89 e5                	mov    %esp,%ebp
  8000a7:	57                   	push   %edi
  8000a8:	56                   	push   %esi
  8000a9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000aa:	ba 00 00 00 00       	mov    $0x0,%edx
  8000af:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b4:	89 d1                	mov    %edx,%ecx
  8000b6:	89 d3                	mov    %edx,%ebx
  8000b8:	89 d7                	mov    %edx,%edi
  8000ba:	89 d6                	mov    %edx,%esi
  8000bc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000be:	5b                   	pop    %ebx
  8000bf:	5e                   	pop    %esi
  8000c0:	5f                   	pop    %edi
  8000c1:	5d                   	pop    %ebp
  8000c2:	c3                   	ret    

008000c3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000c3:	55                   	push   %ebp
  8000c4:	89 e5                	mov    %esp,%ebp
  8000c6:	57                   	push   %edi
  8000c7:	56                   	push   %esi
  8000c8:	53                   	push   %ebx
  8000c9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000d1:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d9:	89 cb                	mov    %ecx,%ebx
  8000db:	89 cf                	mov    %ecx,%edi
  8000dd:	89 ce                	mov    %ecx,%esi
  8000df:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000e1:	85 c0                	test   %eax,%eax
  8000e3:	7e 17                	jle    8000fc <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e5:	83 ec 0c             	sub    $0xc,%esp
  8000e8:	50                   	push   %eax
  8000e9:	6a 03                	push   $0x3
  8000eb:	68 0a 0e 80 00       	push   $0x800e0a
  8000f0:	6a 23                	push   $0x23
  8000f2:	68 27 0e 80 00       	push   $0x800e27
  8000f7:	e8 27 00 00 00       	call   800123 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000ff:	5b                   	pop    %ebx
  800100:	5e                   	pop    %esi
  800101:	5f                   	pop    %edi
  800102:	5d                   	pop    %ebp
  800103:	c3                   	ret    

00800104 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800104:	55                   	push   %ebp
  800105:	89 e5                	mov    %esp,%ebp
  800107:	57                   	push   %edi
  800108:	56                   	push   %esi
  800109:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80010a:	ba 00 00 00 00       	mov    $0x0,%edx
  80010f:	b8 02 00 00 00       	mov    $0x2,%eax
  800114:	89 d1                	mov    %edx,%ecx
  800116:	89 d3                	mov    %edx,%ebx
  800118:	89 d7                	mov    %edx,%edi
  80011a:	89 d6                	mov    %edx,%esi
  80011c:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80011e:	5b                   	pop    %ebx
  80011f:	5e                   	pop    %esi
  800120:	5f                   	pop    %edi
  800121:	5d                   	pop    %ebp
  800122:	c3                   	ret    

00800123 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800123:	55                   	push   %ebp
  800124:	89 e5                	mov    %esp,%ebp
  800126:	56                   	push   %esi
  800127:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800128:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80012b:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800131:	e8 ce ff ff ff       	call   800104 <sys_getenvid>
  800136:	83 ec 0c             	sub    $0xc,%esp
  800139:	ff 75 0c             	pushl  0xc(%ebp)
  80013c:	ff 75 08             	pushl  0x8(%ebp)
  80013f:	56                   	push   %esi
  800140:	50                   	push   %eax
  800141:	68 38 0e 80 00       	push   $0x800e38
  800146:	e8 b1 00 00 00       	call   8001fc <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80014b:	83 c4 18             	add    $0x18,%esp
  80014e:	53                   	push   %ebx
  80014f:	ff 75 10             	pushl  0x10(%ebp)
  800152:	e8 54 00 00 00       	call   8001ab <vcprintf>
	cprintf("\n");
  800157:	c7 04 24 5c 0e 80 00 	movl   $0x800e5c,(%esp)
  80015e:	e8 99 00 00 00       	call   8001fc <cprintf>
  800163:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800166:	cc                   	int3   
  800167:	eb fd                	jmp    800166 <_panic+0x43>

00800169 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800169:	55                   	push   %ebp
  80016a:	89 e5                	mov    %esp,%ebp
  80016c:	53                   	push   %ebx
  80016d:	83 ec 04             	sub    $0x4,%esp
  800170:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800173:	8b 13                	mov    (%ebx),%edx
  800175:	8d 42 01             	lea    0x1(%edx),%eax
  800178:	89 03                	mov    %eax,(%ebx)
  80017a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80017d:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800181:	3d ff 00 00 00       	cmp    $0xff,%eax
  800186:	75 1a                	jne    8001a2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800188:	83 ec 08             	sub    $0x8,%esp
  80018b:	68 ff 00 00 00       	push   $0xff
  800190:	8d 43 08             	lea    0x8(%ebx),%eax
  800193:	50                   	push   %eax
  800194:	e8 ed fe ff ff       	call   800086 <sys_cputs>
		b->idx = 0;
  800199:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019f:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001a2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a9:	c9                   	leave  
  8001aa:	c3                   	ret    

008001ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001bb:	00 00 00 
	b.cnt = 0;
  8001be:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c8:	ff 75 0c             	pushl  0xc(%ebp)
  8001cb:	ff 75 08             	pushl  0x8(%ebp)
  8001ce:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d4:	50                   	push   %eax
  8001d5:	68 69 01 80 00       	push   $0x800169
  8001da:	e8 1a 01 00 00       	call   8002f9 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001df:	83 c4 08             	add    $0x8,%esp
  8001e2:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e8:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ee:	50                   	push   %eax
  8001ef:	e8 92 fe ff ff       	call   800086 <sys_cputs>

	return b.cnt;
}
  8001f4:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001fa:	c9                   	leave  
  8001fb:	c3                   	ret    

008001fc <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
  8001ff:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800202:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800205:	50                   	push   %eax
  800206:	ff 75 08             	pushl  0x8(%ebp)
  800209:	e8 9d ff ff ff       	call   8001ab <vcprintf>
	va_end(ap);

	return cnt;
}
  80020e:	c9                   	leave  
  80020f:	c3                   	ret    

00800210 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	57                   	push   %edi
  800214:	56                   	push   %esi
  800215:	53                   	push   %ebx
  800216:	83 ec 1c             	sub    $0x1c,%esp
  800219:	89 c7                	mov    %eax,%edi
  80021b:	89 d6                	mov    %edx,%esi
  80021d:	8b 45 08             	mov    0x8(%ebp),%eax
  800220:	8b 55 0c             	mov    0xc(%ebp),%edx
  800223:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800226:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800229:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80022c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800231:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800234:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800237:	39 d3                	cmp    %edx,%ebx
  800239:	72 05                	jb     800240 <printnum+0x30>
  80023b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023e:	77 45                	ja     800285 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800240:	83 ec 0c             	sub    $0xc,%esp
  800243:	ff 75 18             	pushl  0x18(%ebp)
  800246:	8b 45 14             	mov    0x14(%ebp),%eax
  800249:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80024c:	53                   	push   %ebx
  80024d:	ff 75 10             	pushl  0x10(%ebp)
  800250:	83 ec 08             	sub    $0x8,%esp
  800253:	ff 75 e4             	pushl  -0x1c(%ebp)
  800256:	ff 75 e0             	pushl  -0x20(%ebp)
  800259:	ff 75 dc             	pushl  -0x24(%ebp)
  80025c:	ff 75 d8             	pushl  -0x28(%ebp)
  80025f:	e8 0c 09 00 00       	call   800b70 <__udivdi3>
  800264:	83 c4 18             	add    $0x18,%esp
  800267:	52                   	push   %edx
  800268:	50                   	push   %eax
  800269:	89 f2                	mov    %esi,%edx
  80026b:	89 f8                	mov    %edi,%eax
  80026d:	e8 9e ff ff ff       	call   800210 <printnum>
  800272:	83 c4 20             	add    $0x20,%esp
  800275:	eb 18                	jmp    80028f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800277:	83 ec 08             	sub    $0x8,%esp
  80027a:	56                   	push   %esi
  80027b:	ff 75 18             	pushl  0x18(%ebp)
  80027e:	ff d7                	call   *%edi
  800280:	83 c4 10             	add    $0x10,%esp
  800283:	eb 03                	jmp    800288 <printnum+0x78>
  800285:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800288:	83 eb 01             	sub    $0x1,%ebx
  80028b:	85 db                	test   %ebx,%ebx
  80028d:	7f e8                	jg     800277 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028f:	83 ec 08             	sub    $0x8,%esp
  800292:	56                   	push   %esi
  800293:	83 ec 04             	sub    $0x4,%esp
  800296:	ff 75 e4             	pushl  -0x1c(%ebp)
  800299:	ff 75 e0             	pushl  -0x20(%ebp)
  80029c:	ff 75 dc             	pushl  -0x24(%ebp)
  80029f:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a2:	e8 f9 09 00 00       	call   800ca0 <__umoddi3>
  8002a7:	83 c4 14             	add    $0x14,%esp
  8002aa:	0f be 80 5e 0e 80 00 	movsbl 0x800e5e(%eax),%eax
  8002b1:	50                   	push   %eax
  8002b2:	ff d7                	call   *%edi
}
  8002b4:	83 c4 10             	add    $0x10,%esp
  8002b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ba:	5b                   	pop    %ebx
  8002bb:	5e                   	pop    %esi
  8002bc:	5f                   	pop    %edi
  8002bd:	5d                   	pop    %ebp
  8002be:	c3                   	ret    

008002bf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002bf:	55                   	push   %ebp
  8002c0:	89 e5                	mov    %esp,%ebp
  8002c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002c9:	8b 10                	mov    (%eax),%edx
  8002cb:	3b 50 04             	cmp    0x4(%eax),%edx
  8002ce:	73 0a                	jae    8002da <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002d3:	89 08                	mov    %ecx,(%eax)
  8002d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d8:	88 02                	mov    %al,(%edx)
}
  8002da:	5d                   	pop    %ebp
  8002db:	c3                   	ret    

008002dc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002dc:	55                   	push   %ebp
  8002dd:	89 e5                	mov    %esp,%ebp
  8002df:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002e2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e5:	50                   	push   %eax
  8002e6:	ff 75 10             	pushl  0x10(%ebp)
  8002e9:	ff 75 0c             	pushl  0xc(%ebp)
  8002ec:	ff 75 08             	pushl  0x8(%ebp)
  8002ef:	e8 05 00 00 00       	call   8002f9 <vprintfmt>
	va_end(ap);
}
  8002f4:	83 c4 10             	add    $0x10,%esp
  8002f7:	c9                   	leave  
  8002f8:	c3                   	ret    

008002f9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002f9:	55                   	push   %ebp
  8002fa:	89 e5                	mov    %esp,%ebp
  8002fc:	57                   	push   %edi
  8002fd:	56                   	push   %esi
  8002fe:	53                   	push   %ebx
  8002ff:	83 ec 2c             	sub    $0x2c,%esp
  800302:	8b 75 08             	mov    0x8(%ebp),%esi
  800305:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800308:	8b 7d 10             	mov    0x10(%ebp),%edi
  80030b:	eb 12                	jmp    80031f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80030d:	85 c0                	test   %eax,%eax
  80030f:	0f 84 6a 04 00 00    	je     80077f <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800315:	83 ec 08             	sub    $0x8,%esp
  800318:	53                   	push   %ebx
  800319:	50                   	push   %eax
  80031a:	ff d6                	call   *%esi
  80031c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80031f:	83 c7 01             	add    $0x1,%edi
  800322:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800326:	83 f8 25             	cmp    $0x25,%eax
  800329:	75 e2                	jne    80030d <vprintfmt+0x14>
  80032b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80032f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800336:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80033d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800344:	b9 00 00 00 00       	mov    $0x0,%ecx
  800349:	eb 07                	jmp    800352 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80034b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80034e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800352:	8d 47 01             	lea    0x1(%edi),%eax
  800355:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800358:	0f b6 07             	movzbl (%edi),%eax
  80035b:	0f b6 d0             	movzbl %al,%edx
  80035e:	83 e8 23             	sub    $0x23,%eax
  800361:	3c 55                	cmp    $0x55,%al
  800363:	0f 87 fb 03 00 00    	ja     800764 <vprintfmt+0x46b>
  800369:	0f b6 c0             	movzbl %al,%eax
  80036c:	ff 24 85 00 0f 80 00 	jmp    *0x800f00(,%eax,4)
  800373:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  800376:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80037a:	eb d6                	jmp    800352 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80037c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80037f:	b8 00 00 00 00       	mov    $0x0,%eax
  800384:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800387:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80038a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80038e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800391:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800394:	83 f9 09             	cmp    $0x9,%ecx
  800397:	77 3f                	ja     8003d8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800399:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80039c:	eb e9                	jmp    800387 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80039e:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a1:	8b 00                	mov    (%eax),%eax
  8003a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a9:	8d 40 04             	lea    0x4(%eax),%eax
  8003ac:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003b2:	eb 2a                	jmp    8003de <vprintfmt+0xe5>
  8003b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b7:	85 c0                	test   %eax,%eax
  8003b9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003be:	0f 49 d0             	cmovns %eax,%edx
  8003c1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c7:	eb 89                	jmp    800352 <vprintfmt+0x59>
  8003c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003cc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003d3:	e9 7a ff ff ff       	jmp    800352 <vprintfmt+0x59>
  8003d8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003db:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003e2:	0f 89 6a ff ff ff    	jns    800352 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003eb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003ee:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f5:	e9 58 ff ff ff       	jmp    800352 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  8003fa:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  800400:	e9 4d ff ff ff       	jmp    800352 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800405:	8b 45 14             	mov    0x14(%ebp),%eax
  800408:	8d 78 04             	lea    0x4(%eax),%edi
  80040b:	83 ec 08             	sub    $0x8,%esp
  80040e:	53                   	push   %ebx
  80040f:	ff 30                	pushl  (%eax)
  800411:	ff d6                	call   *%esi
			break;
  800413:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800416:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800419:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  80041c:	e9 fe fe ff ff       	jmp    80031f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800421:	8b 45 14             	mov    0x14(%ebp),%eax
  800424:	8d 78 04             	lea    0x4(%eax),%edi
  800427:	8b 00                	mov    (%eax),%eax
  800429:	99                   	cltd   
  80042a:	31 d0                	xor    %edx,%eax
  80042c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042e:	83 f8 07             	cmp    $0x7,%eax
  800431:	7f 0b                	jg     80043e <vprintfmt+0x145>
  800433:	8b 14 85 60 10 80 00 	mov    0x801060(,%eax,4),%edx
  80043a:	85 d2                	test   %edx,%edx
  80043c:	75 1b                	jne    800459 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80043e:	50                   	push   %eax
  80043f:	68 76 0e 80 00       	push   $0x800e76
  800444:	53                   	push   %ebx
  800445:	56                   	push   %esi
  800446:	e8 91 fe ff ff       	call   8002dc <printfmt>
  80044b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80044e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800451:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800454:	e9 c6 fe ff ff       	jmp    80031f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800459:	52                   	push   %edx
  80045a:	68 7f 0e 80 00       	push   $0x800e7f
  80045f:	53                   	push   %ebx
  800460:	56                   	push   %esi
  800461:	e8 76 fe ff ff       	call   8002dc <printfmt>
  800466:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800469:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80046c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80046f:	e9 ab fe ff ff       	jmp    80031f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800474:	8b 45 14             	mov    0x14(%ebp),%eax
  800477:	83 c0 04             	add    $0x4,%eax
  80047a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80047d:	8b 45 14             	mov    0x14(%ebp),%eax
  800480:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800482:	85 ff                	test   %edi,%edi
  800484:	b8 6f 0e 80 00       	mov    $0x800e6f,%eax
  800489:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80048c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800490:	0f 8e 94 00 00 00    	jle    80052a <vprintfmt+0x231>
  800496:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80049a:	0f 84 98 00 00 00    	je     800538 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a0:	83 ec 08             	sub    $0x8,%esp
  8004a3:	ff 75 d0             	pushl  -0x30(%ebp)
  8004a6:	57                   	push   %edi
  8004a7:	e8 5b 03 00 00       	call   800807 <strnlen>
  8004ac:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004af:	29 c1                	sub    %eax,%ecx
  8004b1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004b4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004b7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004bb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004be:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004c1:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c3:	eb 0f                	jmp    8004d4 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c5:	83 ec 08             	sub    $0x8,%esp
  8004c8:	53                   	push   %ebx
  8004c9:	ff 75 e0             	pushl  -0x20(%ebp)
  8004cc:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ce:	83 ef 01             	sub    $0x1,%edi
  8004d1:	83 c4 10             	add    $0x10,%esp
  8004d4:	85 ff                	test   %edi,%edi
  8004d6:	7f ed                	jg     8004c5 <vprintfmt+0x1cc>
  8004d8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004db:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004de:	85 c9                	test   %ecx,%ecx
  8004e0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e5:	0f 49 c1             	cmovns %ecx,%eax
  8004e8:	29 c1                	sub    %eax,%ecx
  8004ea:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ed:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004f3:	89 cb                	mov    %ecx,%ebx
  8004f5:	eb 4d                	jmp    800544 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004fb:	74 1b                	je     800518 <vprintfmt+0x21f>
  8004fd:	0f be c0             	movsbl %al,%eax
  800500:	83 e8 20             	sub    $0x20,%eax
  800503:	83 f8 5e             	cmp    $0x5e,%eax
  800506:	76 10                	jbe    800518 <vprintfmt+0x21f>
					putch('?', putdat);
  800508:	83 ec 08             	sub    $0x8,%esp
  80050b:	ff 75 0c             	pushl  0xc(%ebp)
  80050e:	6a 3f                	push   $0x3f
  800510:	ff 55 08             	call   *0x8(%ebp)
  800513:	83 c4 10             	add    $0x10,%esp
  800516:	eb 0d                	jmp    800525 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800518:	83 ec 08             	sub    $0x8,%esp
  80051b:	ff 75 0c             	pushl  0xc(%ebp)
  80051e:	52                   	push   %edx
  80051f:	ff 55 08             	call   *0x8(%ebp)
  800522:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800525:	83 eb 01             	sub    $0x1,%ebx
  800528:	eb 1a                	jmp    800544 <vprintfmt+0x24b>
  80052a:	89 75 08             	mov    %esi,0x8(%ebp)
  80052d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800530:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800533:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800536:	eb 0c                	jmp    800544 <vprintfmt+0x24b>
  800538:	89 75 08             	mov    %esi,0x8(%ebp)
  80053b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800541:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800544:	83 c7 01             	add    $0x1,%edi
  800547:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80054b:	0f be d0             	movsbl %al,%edx
  80054e:	85 d2                	test   %edx,%edx
  800550:	74 23                	je     800575 <vprintfmt+0x27c>
  800552:	85 f6                	test   %esi,%esi
  800554:	78 a1                	js     8004f7 <vprintfmt+0x1fe>
  800556:	83 ee 01             	sub    $0x1,%esi
  800559:	79 9c                	jns    8004f7 <vprintfmt+0x1fe>
  80055b:	89 df                	mov    %ebx,%edi
  80055d:	8b 75 08             	mov    0x8(%ebp),%esi
  800560:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800563:	eb 18                	jmp    80057d <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800565:	83 ec 08             	sub    $0x8,%esp
  800568:	53                   	push   %ebx
  800569:	6a 20                	push   $0x20
  80056b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80056d:	83 ef 01             	sub    $0x1,%edi
  800570:	83 c4 10             	add    $0x10,%esp
  800573:	eb 08                	jmp    80057d <vprintfmt+0x284>
  800575:	89 df                	mov    %ebx,%edi
  800577:	8b 75 08             	mov    0x8(%ebp),%esi
  80057a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80057d:	85 ff                	test   %edi,%edi
  80057f:	7f e4                	jg     800565 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800581:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800584:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800587:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80058a:	e9 90 fd ff ff       	jmp    80031f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80058f:	83 f9 01             	cmp    $0x1,%ecx
  800592:	7e 19                	jle    8005ad <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800594:	8b 45 14             	mov    0x14(%ebp),%eax
  800597:	8b 50 04             	mov    0x4(%eax),%edx
  80059a:	8b 00                	mov    (%eax),%eax
  80059c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80059f:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a5:	8d 40 08             	lea    0x8(%eax),%eax
  8005a8:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ab:	eb 38                	jmp    8005e5 <vprintfmt+0x2ec>
	else if (lflag)
  8005ad:	85 c9                	test   %ecx,%ecx
  8005af:	74 1b                	je     8005cc <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b4:	8b 00                	mov    (%eax),%eax
  8005b6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b9:	89 c1                	mov    %eax,%ecx
  8005bb:	c1 f9 1f             	sar    $0x1f,%ecx
  8005be:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c4:	8d 40 04             	lea    0x4(%eax),%eax
  8005c7:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ca:	eb 19                	jmp    8005e5 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cf:	8b 00                	mov    (%eax),%eax
  8005d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d4:	89 c1                	mov    %eax,%ecx
  8005d6:	c1 f9 1f             	sar    $0x1f,%ecx
  8005d9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005df:	8d 40 04             	lea    0x4(%eax),%eax
  8005e2:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e5:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005e8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005eb:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005f4:	0f 89 36 01 00 00    	jns    800730 <vprintfmt+0x437>
				putch('-', putdat);
  8005fa:	83 ec 08             	sub    $0x8,%esp
  8005fd:	53                   	push   %ebx
  8005fe:	6a 2d                	push   $0x2d
  800600:	ff d6                	call   *%esi
				num = -(long long) num;
  800602:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800605:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800608:	f7 da                	neg    %edx
  80060a:	83 d1 00             	adc    $0x0,%ecx
  80060d:	f7 d9                	neg    %ecx
  80060f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800612:	b8 0a 00 00 00       	mov    $0xa,%eax
  800617:	e9 14 01 00 00       	jmp    800730 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80061c:	83 f9 01             	cmp    $0x1,%ecx
  80061f:	7e 18                	jle    800639 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800621:	8b 45 14             	mov    0x14(%ebp),%eax
  800624:	8b 10                	mov    (%eax),%edx
  800626:	8b 48 04             	mov    0x4(%eax),%ecx
  800629:	8d 40 08             	lea    0x8(%eax),%eax
  80062c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80062f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800634:	e9 f7 00 00 00       	jmp    800730 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800639:	85 c9                	test   %ecx,%ecx
  80063b:	74 1a                	je     800657 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80063d:	8b 45 14             	mov    0x14(%ebp),%eax
  800640:	8b 10                	mov    (%eax),%edx
  800642:	b9 00 00 00 00       	mov    $0x0,%ecx
  800647:	8d 40 04             	lea    0x4(%eax),%eax
  80064a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80064d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800652:	e9 d9 00 00 00       	jmp    800730 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800657:	8b 45 14             	mov    0x14(%ebp),%eax
  80065a:	8b 10                	mov    (%eax),%edx
  80065c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800661:	8d 40 04             	lea    0x4(%eax),%eax
  800664:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800667:	b8 0a 00 00 00       	mov    $0xa,%eax
  80066c:	e9 bf 00 00 00       	jmp    800730 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800671:	83 f9 01             	cmp    $0x1,%ecx
  800674:	7e 13                	jle    800689 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  800676:	8b 45 14             	mov    0x14(%ebp),%eax
  800679:	8b 50 04             	mov    0x4(%eax),%edx
  80067c:	8b 00                	mov    (%eax),%eax
  80067e:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800681:	8d 49 08             	lea    0x8(%ecx),%ecx
  800684:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800687:	eb 28                	jmp    8006b1 <vprintfmt+0x3b8>
	else if (lflag)
  800689:	85 c9                	test   %ecx,%ecx
  80068b:	74 13                	je     8006a0 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  80068d:	8b 45 14             	mov    0x14(%ebp),%eax
  800690:	8b 10                	mov    (%eax),%edx
  800692:	89 d0                	mov    %edx,%eax
  800694:	99                   	cltd   
  800695:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800698:	8d 49 04             	lea    0x4(%ecx),%ecx
  80069b:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80069e:	eb 11                	jmp    8006b1 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8006a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a3:	8b 10                	mov    (%eax),%edx
  8006a5:	89 d0                	mov    %edx,%eax
  8006a7:	99                   	cltd   
  8006a8:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006ab:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006ae:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8006b1:	89 d1                	mov    %edx,%ecx
  8006b3:	89 c2                	mov    %eax,%edx
			base = 8;
  8006b5:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006ba:	eb 74                	jmp    800730 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8006bc:	83 ec 08             	sub    $0x8,%esp
  8006bf:	53                   	push   %ebx
  8006c0:	6a 30                	push   $0x30
  8006c2:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c4:	83 c4 08             	add    $0x8,%esp
  8006c7:	53                   	push   %ebx
  8006c8:	6a 78                	push   $0x78
  8006ca:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8006cf:	8b 10                	mov    (%eax),%edx
  8006d1:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d6:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d9:	8d 40 04             	lea    0x4(%eax),%eax
  8006dc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006df:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e4:	eb 4a                	jmp    800730 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e6:	83 f9 01             	cmp    $0x1,%ecx
  8006e9:	7e 15                	jle    800700 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  8006eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ee:	8b 10                	mov    (%eax),%edx
  8006f0:	8b 48 04             	mov    0x4(%eax),%ecx
  8006f3:	8d 40 08             	lea    0x8(%eax),%eax
  8006f6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f9:	b8 10 00 00 00       	mov    $0x10,%eax
  8006fe:	eb 30                	jmp    800730 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800700:	85 c9                	test   %ecx,%ecx
  800702:	74 17                	je     80071b <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800704:	8b 45 14             	mov    0x14(%ebp),%eax
  800707:	8b 10                	mov    (%eax),%edx
  800709:	b9 00 00 00 00       	mov    $0x0,%ecx
  80070e:	8d 40 04             	lea    0x4(%eax),%eax
  800711:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800714:	b8 10 00 00 00       	mov    $0x10,%eax
  800719:	eb 15                	jmp    800730 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80071b:	8b 45 14             	mov    0x14(%ebp),%eax
  80071e:	8b 10                	mov    (%eax),%edx
  800720:	b9 00 00 00 00       	mov    $0x0,%ecx
  800725:	8d 40 04             	lea    0x4(%eax),%eax
  800728:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80072b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800730:	83 ec 0c             	sub    $0xc,%esp
  800733:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800737:	57                   	push   %edi
  800738:	ff 75 e0             	pushl  -0x20(%ebp)
  80073b:	50                   	push   %eax
  80073c:	51                   	push   %ecx
  80073d:	52                   	push   %edx
  80073e:	89 da                	mov    %ebx,%edx
  800740:	89 f0                	mov    %esi,%eax
  800742:	e8 c9 fa ff ff       	call   800210 <printnum>
			break;
  800747:	83 c4 20             	add    $0x20,%esp
  80074a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80074d:	e9 cd fb ff ff       	jmp    80031f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800752:	83 ec 08             	sub    $0x8,%esp
  800755:	53                   	push   %ebx
  800756:	52                   	push   %edx
  800757:	ff d6                	call   *%esi
			break;
  800759:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80075c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80075f:	e9 bb fb ff ff       	jmp    80031f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800764:	83 ec 08             	sub    $0x8,%esp
  800767:	53                   	push   %ebx
  800768:	6a 25                	push   $0x25
  80076a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80076c:	83 c4 10             	add    $0x10,%esp
  80076f:	eb 03                	jmp    800774 <vprintfmt+0x47b>
  800771:	83 ef 01             	sub    $0x1,%edi
  800774:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800778:	75 f7                	jne    800771 <vprintfmt+0x478>
  80077a:	e9 a0 fb ff ff       	jmp    80031f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80077f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800782:	5b                   	pop    %ebx
  800783:	5e                   	pop    %esi
  800784:	5f                   	pop    %edi
  800785:	5d                   	pop    %ebp
  800786:	c3                   	ret    

00800787 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	83 ec 18             	sub    $0x18,%esp
  80078d:	8b 45 08             	mov    0x8(%ebp),%eax
  800790:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800793:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800796:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80079a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80079d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a4:	85 c0                	test   %eax,%eax
  8007a6:	74 26                	je     8007ce <vsnprintf+0x47>
  8007a8:	85 d2                	test   %edx,%edx
  8007aa:	7e 22                	jle    8007ce <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007ac:	ff 75 14             	pushl  0x14(%ebp)
  8007af:	ff 75 10             	pushl  0x10(%ebp)
  8007b2:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b5:	50                   	push   %eax
  8007b6:	68 bf 02 80 00       	push   $0x8002bf
  8007bb:	e8 39 fb ff ff       	call   8002f9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007c3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007c9:	83 c4 10             	add    $0x10,%esp
  8007cc:	eb 05                	jmp    8007d3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007ce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d3:	c9                   	leave  
  8007d4:	c3                   	ret    

008007d5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d5:	55                   	push   %ebp
  8007d6:	89 e5                	mov    %esp,%ebp
  8007d8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007db:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007de:	50                   	push   %eax
  8007df:	ff 75 10             	pushl  0x10(%ebp)
  8007e2:	ff 75 0c             	pushl  0xc(%ebp)
  8007e5:	ff 75 08             	pushl  0x8(%ebp)
  8007e8:	e8 9a ff ff ff       	call   800787 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ed:	c9                   	leave  
  8007ee:	c3                   	ret    

008007ef <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007ef:	55                   	push   %ebp
  8007f0:	89 e5                	mov    %esp,%ebp
  8007f2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f5:	b8 00 00 00 00       	mov    $0x0,%eax
  8007fa:	eb 03                	jmp    8007ff <strlen+0x10>
		n++;
  8007fc:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007ff:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800803:	75 f7                	jne    8007fc <strlen+0xd>
		n++;
	return n;
}
  800805:	5d                   	pop    %ebp
  800806:	c3                   	ret    

00800807 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800807:	55                   	push   %ebp
  800808:	89 e5                	mov    %esp,%ebp
  80080a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800810:	ba 00 00 00 00       	mov    $0x0,%edx
  800815:	eb 03                	jmp    80081a <strnlen+0x13>
		n++;
  800817:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081a:	39 c2                	cmp    %eax,%edx
  80081c:	74 08                	je     800826 <strnlen+0x1f>
  80081e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800822:	75 f3                	jne    800817 <strnlen+0x10>
  800824:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800826:	5d                   	pop    %ebp
  800827:	c3                   	ret    

00800828 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800828:	55                   	push   %ebp
  800829:	89 e5                	mov    %esp,%ebp
  80082b:	53                   	push   %ebx
  80082c:	8b 45 08             	mov    0x8(%ebp),%eax
  80082f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800832:	89 c2                	mov    %eax,%edx
  800834:	83 c2 01             	add    $0x1,%edx
  800837:	83 c1 01             	add    $0x1,%ecx
  80083a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083e:	88 5a ff             	mov    %bl,-0x1(%edx)
  800841:	84 db                	test   %bl,%bl
  800843:	75 ef                	jne    800834 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800845:	5b                   	pop    %ebx
  800846:	5d                   	pop    %ebp
  800847:	c3                   	ret    

00800848 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800848:	55                   	push   %ebp
  800849:	89 e5                	mov    %esp,%ebp
  80084b:	53                   	push   %ebx
  80084c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80084f:	53                   	push   %ebx
  800850:	e8 9a ff ff ff       	call   8007ef <strlen>
  800855:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800858:	ff 75 0c             	pushl  0xc(%ebp)
  80085b:	01 d8                	add    %ebx,%eax
  80085d:	50                   	push   %eax
  80085e:	e8 c5 ff ff ff       	call   800828 <strcpy>
	return dst;
}
  800863:	89 d8                	mov    %ebx,%eax
  800865:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800868:	c9                   	leave  
  800869:	c3                   	ret    

0080086a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80086a:	55                   	push   %ebp
  80086b:	89 e5                	mov    %esp,%ebp
  80086d:	56                   	push   %esi
  80086e:	53                   	push   %ebx
  80086f:	8b 75 08             	mov    0x8(%ebp),%esi
  800872:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800875:	89 f3                	mov    %esi,%ebx
  800877:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80087a:	89 f2                	mov    %esi,%edx
  80087c:	eb 0f                	jmp    80088d <strncpy+0x23>
		*dst++ = *src;
  80087e:	83 c2 01             	add    $0x1,%edx
  800881:	0f b6 01             	movzbl (%ecx),%eax
  800884:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800887:	80 39 01             	cmpb   $0x1,(%ecx)
  80088a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088d:	39 da                	cmp    %ebx,%edx
  80088f:	75 ed                	jne    80087e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800891:	89 f0                	mov    %esi,%eax
  800893:	5b                   	pop    %ebx
  800894:	5e                   	pop    %esi
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	56                   	push   %esi
  80089b:	53                   	push   %ebx
  80089c:	8b 75 08             	mov    0x8(%ebp),%esi
  80089f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008a2:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a5:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a7:	85 d2                	test   %edx,%edx
  8008a9:	74 21                	je     8008cc <strlcpy+0x35>
  8008ab:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008af:	89 f2                	mov    %esi,%edx
  8008b1:	eb 09                	jmp    8008bc <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b3:	83 c2 01             	add    $0x1,%edx
  8008b6:	83 c1 01             	add    $0x1,%ecx
  8008b9:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008bc:	39 c2                	cmp    %eax,%edx
  8008be:	74 09                	je     8008c9 <strlcpy+0x32>
  8008c0:	0f b6 19             	movzbl (%ecx),%ebx
  8008c3:	84 db                	test   %bl,%bl
  8008c5:	75 ec                	jne    8008b3 <strlcpy+0x1c>
  8008c7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008cc:	29 f0                	sub    %esi,%eax
}
  8008ce:	5b                   	pop    %ebx
  8008cf:	5e                   	pop    %esi
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008db:	eb 06                	jmp    8008e3 <strcmp+0x11>
		p++, q++;
  8008dd:	83 c1 01             	add    $0x1,%ecx
  8008e0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008e3:	0f b6 01             	movzbl (%ecx),%eax
  8008e6:	84 c0                	test   %al,%al
  8008e8:	74 04                	je     8008ee <strcmp+0x1c>
  8008ea:	3a 02                	cmp    (%edx),%al
  8008ec:	74 ef                	je     8008dd <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ee:	0f b6 c0             	movzbl %al,%eax
  8008f1:	0f b6 12             	movzbl (%edx),%edx
  8008f4:	29 d0                	sub    %edx,%eax
}
  8008f6:	5d                   	pop    %ebp
  8008f7:	c3                   	ret    

008008f8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f8:	55                   	push   %ebp
  8008f9:	89 e5                	mov    %esp,%ebp
  8008fb:	53                   	push   %ebx
  8008fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ff:	8b 55 0c             	mov    0xc(%ebp),%edx
  800902:	89 c3                	mov    %eax,%ebx
  800904:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800907:	eb 06                	jmp    80090f <strncmp+0x17>
		n--, p++, q++;
  800909:	83 c0 01             	add    $0x1,%eax
  80090c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80090f:	39 d8                	cmp    %ebx,%eax
  800911:	74 15                	je     800928 <strncmp+0x30>
  800913:	0f b6 08             	movzbl (%eax),%ecx
  800916:	84 c9                	test   %cl,%cl
  800918:	74 04                	je     80091e <strncmp+0x26>
  80091a:	3a 0a                	cmp    (%edx),%cl
  80091c:	74 eb                	je     800909 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80091e:	0f b6 00             	movzbl (%eax),%eax
  800921:	0f b6 12             	movzbl (%edx),%edx
  800924:	29 d0                	sub    %edx,%eax
  800926:	eb 05                	jmp    80092d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800928:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80092d:	5b                   	pop    %ebx
  80092e:	5d                   	pop    %ebp
  80092f:	c3                   	ret    

00800930 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800930:	55                   	push   %ebp
  800931:	89 e5                	mov    %esp,%ebp
  800933:	8b 45 08             	mov    0x8(%ebp),%eax
  800936:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093a:	eb 07                	jmp    800943 <strchr+0x13>
		if (*s == c)
  80093c:	38 ca                	cmp    %cl,%dl
  80093e:	74 0f                	je     80094f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800940:	83 c0 01             	add    $0x1,%eax
  800943:	0f b6 10             	movzbl (%eax),%edx
  800946:	84 d2                	test   %dl,%dl
  800948:	75 f2                	jne    80093c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80094a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094f:	5d                   	pop    %ebp
  800950:	c3                   	ret    

00800951 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800951:	55                   	push   %ebp
  800952:	89 e5                	mov    %esp,%ebp
  800954:	8b 45 08             	mov    0x8(%ebp),%eax
  800957:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80095b:	eb 03                	jmp    800960 <strfind+0xf>
  80095d:	83 c0 01             	add    $0x1,%eax
  800960:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800963:	38 ca                	cmp    %cl,%dl
  800965:	74 04                	je     80096b <strfind+0x1a>
  800967:	84 d2                	test   %dl,%dl
  800969:	75 f2                	jne    80095d <strfind+0xc>
			break;
	return (char *) s;
}
  80096b:	5d                   	pop    %ebp
  80096c:	c3                   	ret    

0080096d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80096d:	55                   	push   %ebp
  80096e:	89 e5                	mov    %esp,%ebp
  800970:	57                   	push   %edi
  800971:	56                   	push   %esi
  800972:	53                   	push   %ebx
  800973:	8b 7d 08             	mov    0x8(%ebp),%edi
  800976:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800979:	85 c9                	test   %ecx,%ecx
  80097b:	74 36                	je     8009b3 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80097d:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800983:	75 28                	jne    8009ad <memset+0x40>
  800985:	f6 c1 03             	test   $0x3,%cl
  800988:	75 23                	jne    8009ad <memset+0x40>
		c &= 0xFF;
  80098a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098e:	89 d3                	mov    %edx,%ebx
  800990:	c1 e3 08             	shl    $0x8,%ebx
  800993:	89 d6                	mov    %edx,%esi
  800995:	c1 e6 18             	shl    $0x18,%esi
  800998:	89 d0                	mov    %edx,%eax
  80099a:	c1 e0 10             	shl    $0x10,%eax
  80099d:	09 f0                	or     %esi,%eax
  80099f:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009a1:	89 d8                	mov    %ebx,%eax
  8009a3:	09 d0                	or     %edx,%eax
  8009a5:	c1 e9 02             	shr    $0x2,%ecx
  8009a8:	fc                   	cld    
  8009a9:	f3 ab                	rep stos %eax,%es:(%edi)
  8009ab:	eb 06                	jmp    8009b3 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009b0:	fc                   	cld    
  8009b1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b3:	89 f8                	mov    %edi,%eax
  8009b5:	5b                   	pop    %ebx
  8009b6:	5e                   	pop    %esi
  8009b7:	5f                   	pop    %edi
  8009b8:	5d                   	pop    %ebp
  8009b9:	c3                   	ret    

008009ba <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009ba:	55                   	push   %ebp
  8009bb:	89 e5                	mov    %esp,%ebp
  8009bd:	57                   	push   %edi
  8009be:	56                   	push   %esi
  8009bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c8:	39 c6                	cmp    %eax,%esi
  8009ca:	73 35                	jae    800a01 <memmove+0x47>
  8009cc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009cf:	39 d0                	cmp    %edx,%eax
  8009d1:	73 2e                	jae    800a01 <memmove+0x47>
		s += n;
		d += n;
  8009d3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d6:	89 d6                	mov    %edx,%esi
  8009d8:	09 fe                	or     %edi,%esi
  8009da:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009e0:	75 13                	jne    8009f5 <memmove+0x3b>
  8009e2:	f6 c1 03             	test   $0x3,%cl
  8009e5:	75 0e                	jne    8009f5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e7:	83 ef 04             	sub    $0x4,%edi
  8009ea:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009ed:	c1 e9 02             	shr    $0x2,%ecx
  8009f0:	fd                   	std    
  8009f1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f3:	eb 09                	jmp    8009fe <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f5:	83 ef 01             	sub    $0x1,%edi
  8009f8:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009fb:	fd                   	std    
  8009fc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009fe:	fc                   	cld    
  8009ff:	eb 1d                	jmp    800a1e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a01:	89 f2                	mov    %esi,%edx
  800a03:	09 c2                	or     %eax,%edx
  800a05:	f6 c2 03             	test   $0x3,%dl
  800a08:	75 0f                	jne    800a19 <memmove+0x5f>
  800a0a:	f6 c1 03             	test   $0x3,%cl
  800a0d:	75 0a                	jne    800a19 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a0f:	c1 e9 02             	shr    $0x2,%ecx
  800a12:	89 c7                	mov    %eax,%edi
  800a14:	fc                   	cld    
  800a15:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a17:	eb 05                	jmp    800a1e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a19:	89 c7                	mov    %eax,%edi
  800a1b:	fc                   	cld    
  800a1c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1e:	5e                   	pop    %esi
  800a1f:	5f                   	pop    %edi
  800a20:	5d                   	pop    %ebp
  800a21:	c3                   	ret    

00800a22 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a22:	55                   	push   %ebp
  800a23:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a25:	ff 75 10             	pushl  0x10(%ebp)
  800a28:	ff 75 0c             	pushl  0xc(%ebp)
  800a2b:	ff 75 08             	pushl  0x8(%ebp)
  800a2e:	e8 87 ff ff ff       	call   8009ba <memmove>
}
  800a33:	c9                   	leave  
  800a34:	c3                   	ret    

00800a35 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a35:	55                   	push   %ebp
  800a36:	89 e5                	mov    %esp,%ebp
  800a38:	56                   	push   %esi
  800a39:	53                   	push   %ebx
  800a3a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a40:	89 c6                	mov    %eax,%esi
  800a42:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a45:	eb 1a                	jmp    800a61 <memcmp+0x2c>
		if (*s1 != *s2)
  800a47:	0f b6 08             	movzbl (%eax),%ecx
  800a4a:	0f b6 1a             	movzbl (%edx),%ebx
  800a4d:	38 d9                	cmp    %bl,%cl
  800a4f:	74 0a                	je     800a5b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a51:	0f b6 c1             	movzbl %cl,%eax
  800a54:	0f b6 db             	movzbl %bl,%ebx
  800a57:	29 d8                	sub    %ebx,%eax
  800a59:	eb 0f                	jmp    800a6a <memcmp+0x35>
		s1++, s2++;
  800a5b:	83 c0 01             	add    $0x1,%eax
  800a5e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a61:	39 f0                	cmp    %esi,%eax
  800a63:	75 e2                	jne    800a47 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a65:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a6a:	5b                   	pop    %ebx
  800a6b:	5e                   	pop    %esi
  800a6c:	5d                   	pop    %ebp
  800a6d:	c3                   	ret    

00800a6e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a6e:	55                   	push   %ebp
  800a6f:	89 e5                	mov    %esp,%ebp
  800a71:	53                   	push   %ebx
  800a72:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a75:	89 c1                	mov    %eax,%ecx
  800a77:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a7e:	eb 0a                	jmp    800a8a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a80:	0f b6 10             	movzbl (%eax),%edx
  800a83:	39 da                	cmp    %ebx,%edx
  800a85:	74 07                	je     800a8e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a87:	83 c0 01             	add    $0x1,%eax
  800a8a:	39 c8                	cmp    %ecx,%eax
  800a8c:	72 f2                	jb     800a80 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a8e:	5b                   	pop    %ebx
  800a8f:	5d                   	pop    %ebp
  800a90:	c3                   	ret    

00800a91 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a91:	55                   	push   %ebp
  800a92:	89 e5                	mov    %esp,%ebp
  800a94:	57                   	push   %edi
  800a95:	56                   	push   %esi
  800a96:	53                   	push   %ebx
  800a97:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a9a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9d:	eb 03                	jmp    800aa2 <strtol+0x11>
		s++;
  800a9f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa2:	0f b6 01             	movzbl (%ecx),%eax
  800aa5:	3c 20                	cmp    $0x20,%al
  800aa7:	74 f6                	je     800a9f <strtol+0xe>
  800aa9:	3c 09                	cmp    $0x9,%al
  800aab:	74 f2                	je     800a9f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aad:	3c 2b                	cmp    $0x2b,%al
  800aaf:	75 0a                	jne    800abb <strtol+0x2a>
		s++;
  800ab1:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab4:	bf 00 00 00 00       	mov    $0x0,%edi
  800ab9:	eb 11                	jmp    800acc <strtol+0x3b>
  800abb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ac0:	3c 2d                	cmp    $0x2d,%al
  800ac2:	75 08                	jne    800acc <strtol+0x3b>
		s++, neg = 1;
  800ac4:	83 c1 01             	add    $0x1,%ecx
  800ac7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800acc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ad2:	75 15                	jne    800ae9 <strtol+0x58>
  800ad4:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad7:	75 10                	jne    800ae9 <strtol+0x58>
  800ad9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800add:	75 7c                	jne    800b5b <strtol+0xca>
		s += 2, base = 16;
  800adf:	83 c1 02             	add    $0x2,%ecx
  800ae2:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae7:	eb 16                	jmp    800aff <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ae9:	85 db                	test   %ebx,%ebx
  800aeb:	75 12                	jne    800aff <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800aed:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800af2:	80 39 30             	cmpb   $0x30,(%ecx)
  800af5:	75 08                	jne    800aff <strtol+0x6e>
		s++, base = 8;
  800af7:	83 c1 01             	add    $0x1,%ecx
  800afa:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800aff:	b8 00 00 00 00       	mov    $0x0,%eax
  800b04:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b07:	0f b6 11             	movzbl (%ecx),%edx
  800b0a:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b0d:	89 f3                	mov    %esi,%ebx
  800b0f:	80 fb 09             	cmp    $0x9,%bl
  800b12:	77 08                	ja     800b1c <strtol+0x8b>
			dig = *s - '0';
  800b14:	0f be d2             	movsbl %dl,%edx
  800b17:	83 ea 30             	sub    $0x30,%edx
  800b1a:	eb 22                	jmp    800b3e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b1c:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b1f:	89 f3                	mov    %esi,%ebx
  800b21:	80 fb 19             	cmp    $0x19,%bl
  800b24:	77 08                	ja     800b2e <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b26:	0f be d2             	movsbl %dl,%edx
  800b29:	83 ea 57             	sub    $0x57,%edx
  800b2c:	eb 10                	jmp    800b3e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b2e:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b31:	89 f3                	mov    %esi,%ebx
  800b33:	80 fb 19             	cmp    $0x19,%bl
  800b36:	77 16                	ja     800b4e <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b38:	0f be d2             	movsbl %dl,%edx
  800b3b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b3e:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b41:	7d 0b                	jge    800b4e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b43:	83 c1 01             	add    $0x1,%ecx
  800b46:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b4a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b4c:	eb b9                	jmp    800b07 <strtol+0x76>

	if (endptr)
  800b4e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b52:	74 0d                	je     800b61 <strtol+0xd0>
		*endptr = (char *) s;
  800b54:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b57:	89 0e                	mov    %ecx,(%esi)
  800b59:	eb 06                	jmp    800b61 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b5b:	85 db                	test   %ebx,%ebx
  800b5d:	74 98                	je     800af7 <strtol+0x66>
  800b5f:	eb 9e                	jmp    800aff <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b61:	89 c2                	mov    %eax,%edx
  800b63:	f7 da                	neg    %edx
  800b65:	85 ff                	test   %edi,%edi
  800b67:	0f 45 c2             	cmovne %edx,%eax
}
  800b6a:	5b                   	pop    %ebx
  800b6b:	5e                   	pop    %esi
  800b6c:	5f                   	pop    %edi
  800b6d:	5d                   	pop    %ebp
  800b6e:	c3                   	ret    
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
