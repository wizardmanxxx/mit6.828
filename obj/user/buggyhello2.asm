
obj/user/buggyhello2:     file format elf32-i386


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
  80002c:	e8 1d 00 00 00       	call   80004e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs(hello, 1024*1024);
  800039:	68 00 00 10 00       	push   $0x100000
  80003e:	ff 35 00 20 80 00    	pushl  0x802000
  800044:	e8 4d 00 00 00       	call   800096 <sys_cputs>
}
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	c9                   	leave  
  80004d:	c3                   	ret    

0080004e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004e:	55                   	push   %ebp
  80004f:	89 e5                	mov    %esp,%ebp
  800051:	83 ec 08             	sub    $0x8,%esp
  800054:	8b 45 08             	mov    0x8(%ebp),%eax
  800057:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005a:	c7 05 08 20 80 00 00 	movl   $0x0,0x802008
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 04 20 80 00    	mov    %ecx,0x802004

	// call user main routine
	umain(argc, argv);
  800070:	83 ec 08             	sub    $0x8,%esp
  800073:	52                   	push   %edx
  800074:	50                   	push   %eax
  800075:	e8 b9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007a:	e8 05 00 00 00       	call   800084 <exit>
}
  80007f:	83 c4 10             	add    $0x10,%esp
  800082:	c9                   	leave  
  800083:	c3                   	ret    

00800084 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800084:	55                   	push   %ebp
  800085:	89 e5                	mov    %esp,%ebp
  800087:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008a:	6a 00                	push   $0x0
  80008c:	e8 42 00 00 00       	call   8000d3 <sys_env_destroy>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	57                   	push   %edi
  80009a:	56                   	push   %esi
  80009b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009c:	b8 00 00 00 00       	mov    $0x0,%eax
  8000a1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a4:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a7:	89 c3                	mov    %eax,%ebx
  8000a9:	89 c7                	mov    %eax,%edi
  8000ab:	89 c6                	mov    %eax,%esi
  8000ad:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000af:	5b                   	pop    %ebx
  8000b0:	5e                   	pop    %esi
  8000b1:	5f                   	pop    %edi
  8000b2:	5d                   	pop    %ebp
  8000b3:	c3                   	ret    

008000b4 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b4:	55                   	push   %ebp
  8000b5:	89 e5                	mov    %esp,%ebp
  8000b7:	57                   	push   %edi
  8000b8:	56                   	push   %esi
  8000b9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ba:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bf:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c4:	89 d1                	mov    %edx,%ecx
  8000c6:	89 d3                	mov    %edx,%ebx
  8000c8:	89 d7                	mov    %edx,%edi
  8000ca:	89 d6                	mov    %edx,%esi
  8000cc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ce:	5b                   	pop    %ebx
  8000cf:	5e                   	pop    %esi
  8000d0:	5f                   	pop    %edi
  8000d1:	5d                   	pop    %ebp
  8000d2:	c3                   	ret    

008000d3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d3:	55                   	push   %ebp
  8000d4:	89 e5                	mov    %esp,%ebp
  8000d6:	57                   	push   %edi
  8000d7:	56                   	push   %esi
  8000d8:	53                   	push   %ebx
  8000d9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000dc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000e1:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e9:	89 cb                	mov    %ecx,%ebx
  8000eb:	89 cf                	mov    %ecx,%edi
  8000ed:	89 ce                	mov    %ecx,%esi
  8000ef:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000f1:	85 c0                	test   %eax,%eax
  8000f3:	7e 17                	jle    80010c <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f5:	83 ec 0c             	sub    $0xc,%esp
  8000f8:	50                   	push   %eax
  8000f9:	6a 03                	push   $0x3
  8000fb:	68 38 0e 80 00       	push   $0x800e38
  800100:	6a 23                	push   $0x23
  800102:	68 55 0e 80 00       	push   $0x800e55
  800107:	e8 27 00 00 00       	call   800133 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80010c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010f:	5b                   	pop    %ebx
  800110:	5e                   	pop    %esi
  800111:	5f                   	pop    %edi
  800112:	5d                   	pop    %ebp
  800113:	c3                   	ret    

00800114 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800114:	55                   	push   %ebp
  800115:	89 e5                	mov    %esp,%ebp
  800117:	57                   	push   %edi
  800118:	56                   	push   %esi
  800119:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80011a:	ba 00 00 00 00       	mov    $0x0,%edx
  80011f:	b8 02 00 00 00       	mov    $0x2,%eax
  800124:	89 d1                	mov    %edx,%ecx
  800126:	89 d3                	mov    %edx,%ebx
  800128:	89 d7                	mov    %edx,%edi
  80012a:	89 d6                	mov    %edx,%esi
  80012c:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012e:	5b                   	pop    %ebx
  80012f:	5e                   	pop    %esi
  800130:	5f                   	pop    %edi
  800131:	5d                   	pop    %ebp
  800132:	c3                   	ret    

00800133 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800133:	55                   	push   %ebp
  800134:	89 e5                	mov    %esp,%ebp
  800136:	56                   	push   %esi
  800137:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800138:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80013b:	8b 35 04 20 80 00    	mov    0x802004,%esi
  800141:	e8 ce ff ff ff       	call   800114 <sys_getenvid>
  800146:	83 ec 0c             	sub    $0xc,%esp
  800149:	ff 75 0c             	pushl  0xc(%ebp)
  80014c:	ff 75 08             	pushl  0x8(%ebp)
  80014f:	56                   	push   %esi
  800150:	50                   	push   %eax
  800151:	68 64 0e 80 00       	push   $0x800e64
  800156:	e8 b1 00 00 00       	call   80020c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80015b:	83 c4 18             	add    $0x18,%esp
  80015e:	53                   	push   %ebx
  80015f:	ff 75 10             	pushl  0x10(%ebp)
  800162:	e8 54 00 00 00       	call   8001bb <vcprintf>
	cprintf("\n");
  800167:	c7 04 24 2c 0e 80 00 	movl   $0x800e2c,(%esp)
  80016e:	e8 99 00 00 00       	call   80020c <cprintf>
  800173:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800176:	cc                   	int3   
  800177:	eb fd                	jmp    800176 <_panic+0x43>

00800179 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800179:	55                   	push   %ebp
  80017a:	89 e5                	mov    %esp,%ebp
  80017c:	53                   	push   %ebx
  80017d:	83 ec 04             	sub    $0x4,%esp
  800180:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800183:	8b 13                	mov    (%ebx),%edx
  800185:	8d 42 01             	lea    0x1(%edx),%eax
  800188:	89 03                	mov    %eax,(%ebx)
  80018a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80018d:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800191:	3d ff 00 00 00       	cmp    $0xff,%eax
  800196:	75 1a                	jne    8001b2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800198:	83 ec 08             	sub    $0x8,%esp
  80019b:	68 ff 00 00 00       	push   $0xff
  8001a0:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a3:	50                   	push   %eax
  8001a4:	e8 ed fe ff ff       	call   800096 <sys_cputs>
		b->idx = 0;
  8001a9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001af:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b9:	c9                   	leave  
  8001ba:	c3                   	ret    

008001bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001bb:	55                   	push   %ebp
  8001bc:	89 e5                	mov    %esp,%ebp
  8001be:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001cb:	00 00 00 
	b.cnt = 0;
  8001ce:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d8:	ff 75 0c             	pushl  0xc(%ebp)
  8001db:	ff 75 08             	pushl  0x8(%ebp)
  8001de:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e4:	50                   	push   %eax
  8001e5:	68 79 01 80 00       	push   $0x800179
  8001ea:	e8 1a 01 00 00       	call   800309 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001ef:	83 c4 08             	add    $0x8,%esp
  8001f2:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f8:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fe:	50                   	push   %eax
  8001ff:	e8 92 fe ff ff       	call   800096 <sys_cputs>

	return b.cnt;
}
  800204:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80020a:	c9                   	leave  
  80020b:	c3                   	ret    

0080020c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800212:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800215:	50                   	push   %eax
  800216:	ff 75 08             	pushl  0x8(%ebp)
  800219:	e8 9d ff ff ff       	call   8001bb <vcprintf>
	va_end(ap);

	return cnt;
}
  80021e:	c9                   	leave  
  80021f:	c3                   	ret    

00800220 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800220:	55                   	push   %ebp
  800221:	89 e5                	mov    %esp,%ebp
  800223:	57                   	push   %edi
  800224:	56                   	push   %esi
  800225:	53                   	push   %ebx
  800226:	83 ec 1c             	sub    $0x1c,%esp
  800229:	89 c7                	mov    %eax,%edi
  80022b:	89 d6                	mov    %edx,%esi
  80022d:	8b 45 08             	mov    0x8(%ebp),%eax
  800230:	8b 55 0c             	mov    0xc(%ebp),%edx
  800233:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800236:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800239:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80023c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800241:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800244:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800247:	39 d3                	cmp    %edx,%ebx
  800249:	72 05                	jb     800250 <printnum+0x30>
  80024b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024e:	77 45                	ja     800295 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800250:	83 ec 0c             	sub    $0xc,%esp
  800253:	ff 75 18             	pushl  0x18(%ebp)
  800256:	8b 45 14             	mov    0x14(%ebp),%eax
  800259:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80025c:	53                   	push   %ebx
  80025d:	ff 75 10             	pushl  0x10(%ebp)
  800260:	83 ec 08             	sub    $0x8,%esp
  800263:	ff 75 e4             	pushl  -0x1c(%ebp)
  800266:	ff 75 e0             	pushl  -0x20(%ebp)
  800269:	ff 75 dc             	pushl  -0x24(%ebp)
  80026c:	ff 75 d8             	pushl  -0x28(%ebp)
  80026f:	e8 0c 09 00 00       	call   800b80 <__udivdi3>
  800274:	83 c4 18             	add    $0x18,%esp
  800277:	52                   	push   %edx
  800278:	50                   	push   %eax
  800279:	89 f2                	mov    %esi,%edx
  80027b:	89 f8                	mov    %edi,%eax
  80027d:	e8 9e ff ff ff       	call   800220 <printnum>
  800282:	83 c4 20             	add    $0x20,%esp
  800285:	eb 18                	jmp    80029f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800287:	83 ec 08             	sub    $0x8,%esp
  80028a:	56                   	push   %esi
  80028b:	ff 75 18             	pushl  0x18(%ebp)
  80028e:	ff d7                	call   *%edi
  800290:	83 c4 10             	add    $0x10,%esp
  800293:	eb 03                	jmp    800298 <printnum+0x78>
  800295:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800298:	83 eb 01             	sub    $0x1,%ebx
  80029b:	85 db                	test   %ebx,%ebx
  80029d:	7f e8                	jg     800287 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029f:	83 ec 08             	sub    $0x8,%esp
  8002a2:	56                   	push   %esi
  8002a3:	83 ec 04             	sub    $0x4,%esp
  8002a6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a9:	ff 75 e0             	pushl  -0x20(%ebp)
  8002ac:	ff 75 dc             	pushl  -0x24(%ebp)
  8002af:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b2:	e8 f9 09 00 00       	call   800cb0 <__umoddi3>
  8002b7:	83 c4 14             	add    $0x14,%esp
  8002ba:	0f be 80 88 0e 80 00 	movsbl 0x800e88(%eax),%eax
  8002c1:	50                   	push   %eax
  8002c2:	ff d7                	call   *%edi
}
  8002c4:	83 c4 10             	add    $0x10,%esp
  8002c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ca:	5b                   	pop    %ebx
  8002cb:	5e                   	pop    %esi
  8002cc:	5f                   	pop    %edi
  8002cd:	5d                   	pop    %ebp
  8002ce:	c3                   	ret    

008002cf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002cf:	55                   	push   %ebp
  8002d0:	89 e5                	mov    %esp,%ebp
  8002d2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002d5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d9:	8b 10                	mov    (%eax),%edx
  8002db:	3b 50 04             	cmp    0x4(%eax),%edx
  8002de:	73 0a                	jae    8002ea <sprintputch+0x1b>
		*b->buf++ = ch;
  8002e0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002e3:	89 08                	mov    %ecx,(%eax)
  8002e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e8:	88 02                	mov    %al,(%edx)
}
  8002ea:	5d                   	pop    %ebp
  8002eb:	c3                   	ret    

008002ec <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002ec:	55                   	push   %ebp
  8002ed:	89 e5                	mov    %esp,%ebp
  8002ef:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002f2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002f5:	50                   	push   %eax
  8002f6:	ff 75 10             	pushl  0x10(%ebp)
  8002f9:	ff 75 0c             	pushl  0xc(%ebp)
  8002fc:	ff 75 08             	pushl  0x8(%ebp)
  8002ff:	e8 05 00 00 00       	call   800309 <vprintfmt>
	va_end(ap);
}
  800304:	83 c4 10             	add    $0x10,%esp
  800307:	c9                   	leave  
  800308:	c3                   	ret    

00800309 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800309:	55                   	push   %ebp
  80030a:	89 e5                	mov    %esp,%ebp
  80030c:	57                   	push   %edi
  80030d:	56                   	push   %esi
  80030e:	53                   	push   %ebx
  80030f:	83 ec 2c             	sub    $0x2c,%esp
  800312:	8b 75 08             	mov    0x8(%ebp),%esi
  800315:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800318:	8b 7d 10             	mov    0x10(%ebp),%edi
  80031b:	eb 12                	jmp    80032f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80031d:	85 c0                	test   %eax,%eax
  80031f:	0f 84 6a 04 00 00    	je     80078f <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800325:	83 ec 08             	sub    $0x8,%esp
  800328:	53                   	push   %ebx
  800329:	50                   	push   %eax
  80032a:	ff d6                	call   *%esi
  80032c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80032f:	83 c7 01             	add    $0x1,%edi
  800332:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800336:	83 f8 25             	cmp    $0x25,%eax
  800339:	75 e2                	jne    80031d <vprintfmt+0x14>
  80033b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80033f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800346:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80034d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800354:	b9 00 00 00 00       	mov    $0x0,%ecx
  800359:	eb 07                	jmp    800362 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80035b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80035e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800362:	8d 47 01             	lea    0x1(%edi),%eax
  800365:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800368:	0f b6 07             	movzbl (%edi),%eax
  80036b:	0f b6 d0             	movzbl %al,%edx
  80036e:	83 e8 23             	sub    $0x23,%eax
  800371:	3c 55                	cmp    $0x55,%al
  800373:	0f 87 fb 03 00 00    	ja     800774 <vprintfmt+0x46b>
  800379:	0f b6 c0             	movzbl %al,%eax
  80037c:	ff 24 85 20 0f 80 00 	jmp    *0x800f20(,%eax,4)
  800383:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  800386:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80038a:	eb d6                	jmp    800362 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80038c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80038f:	b8 00 00 00 00       	mov    $0x0,%eax
  800394:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800397:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80039a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80039e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003a1:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003a4:	83 f9 09             	cmp    $0x9,%ecx
  8003a7:	77 3f                	ja     8003e8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  8003a9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003ac:	eb e9                	jmp    800397 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  8003ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b1:	8b 00                	mov    (%eax),%eax
  8003b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b9:	8d 40 04             	lea    0x4(%eax),%eax
  8003bc:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003c2:	eb 2a                	jmp    8003ee <vprintfmt+0xe5>
  8003c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003c7:	85 c0                	test   %eax,%eax
  8003c9:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ce:	0f 49 d0             	cmovns %eax,%edx
  8003d1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d7:	eb 89                	jmp    800362 <vprintfmt+0x59>
  8003d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003dc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003e3:	e9 7a ff ff ff       	jmp    800362 <vprintfmt+0x59>
  8003e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003eb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003ee:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003f2:	0f 89 6a ff ff ff    	jns    800362 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003fe:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800405:	e9 58 ff ff ff       	jmp    800362 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  80040a:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80040d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  800410:	e9 4d ff ff ff       	jmp    800362 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800415:	8b 45 14             	mov    0x14(%ebp),%eax
  800418:	8d 78 04             	lea    0x4(%eax),%edi
  80041b:	83 ec 08             	sub    $0x8,%esp
  80041e:	53                   	push   %ebx
  80041f:	ff 30                	pushl  (%eax)
  800421:	ff d6                	call   *%esi
			break;
  800423:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800426:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800429:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  80042c:	e9 fe fe ff ff       	jmp    80032f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800431:	8b 45 14             	mov    0x14(%ebp),%eax
  800434:	8d 78 04             	lea    0x4(%eax),%edi
  800437:	8b 00                	mov    (%eax),%eax
  800439:	99                   	cltd   
  80043a:	31 d0                	xor    %edx,%eax
  80043c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80043e:	83 f8 07             	cmp    $0x7,%eax
  800441:	7f 0b                	jg     80044e <vprintfmt+0x145>
  800443:	8b 14 85 80 10 80 00 	mov    0x801080(,%eax,4),%edx
  80044a:	85 d2                	test   %edx,%edx
  80044c:	75 1b                	jne    800469 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80044e:	50                   	push   %eax
  80044f:	68 a0 0e 80 00       	push   $0x800ea0
  800454:	53                   	push   %ebx
  800455:	56                   	push   %esi
  800456:	e8 91 fe ff ff       	call   8002ec <printfmt>
  80045b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80045e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800461:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800464:	e9 c6 fe ff ff       	jmp    80032f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800469:	52                   	push   %edx
  80046a:	68 a9 0e 80 00       	push   $0x800ea9
  80046f:	53                   	push   %ebx
  800470:	56                   	push   %esi
  800471:	e8 76 fe ff ff       	call   8002ec <printfmt>
  800476:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800479:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80047c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80047f:	e9 ab fe ff ff       	jmp    80032f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800484:	8b 45 14             	mov    0x14(%ebp),%eax
  800487:	83 c0 04             	add    $0x4,%eax
  80048a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80048d:	8b 45 14             	mov    0x14(%ebp),%eax
  800490:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800492:	85 ff                	test   %edi,%edi
  800494:	b8 99 0e 80 00       	mov    $0x800e99,%eax
  800499:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80049c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004a0:	0f 8e 94 00 00 00    	jle    80053a <vprintfmt+0x231>
  8004a6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004aa:	0f 84 98 00 00 00    	je     800548 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b0:	83 ec 08             	sub    $0x8,%esp
  8004b3:	ff 75 d0             	pushl  -0x30(%ebp)
  8004b6:	57                   	push   %edi
  8004b7:	e8 5b 03 00 00       	call   800817 <strnlen>
  8004bc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004bf:	29 c1                	sub    %eax,%ecx
  8004c1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004c4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004c7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004cb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ce:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004d1:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d3:	eb 0f                	jmp    8004e4 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004d5:	83 ec 08             	sub    $0x8,%esp
  8004d8:	53                   	push   %ebx
  8004d9:	ff 75 e0             	pushl  -0x20(%ebp)
  8004dc:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004de:	83 ef 01             	sub    $0x1,%edi
  8004e1:	83 c4 10             	add    $0x10,%esp
  8004e4:	85 ff                	test   %edi,%edi
  8004e6:	7f ed                	jg     8004d5 <vprintfmt+0x1cc>
  8004e8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004eb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004ee:	85 c9                	test   %ecx,%ecx
  8004f0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004f5:	0f 49 c1             	cmovns %ecx,%eax
  8004f8:	29 c1                	sub    %eax,%ecx
  8004fa:	89 75 08             	mov    %esi,0x8(%ebp)
  8004fd:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800500:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800503:	89 cb                	mov    %ecx,%ebx
  800505:	eb 4d                	jmp    800554 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800507:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80050b:	74 1b                	je     800528 <vprintfmt+0x21f>
  80050d:	0f be c0             	movsbl %al,%eax
  800510:	83 e8 20             	sub    $0x20,%eax
  800513:	83 f8 5e             	cmp    $0x5e,%eax
  800516:	76 10                	jbe    800528 <vprintfmt+0x21f>
					putch('?', putdat);
  800518:	83 ec 08             	sub    $0x8,%esp
  80051b:	ff 75 0c             	pushl  0xc(%ebp)
  80051e:	6a 3f                	push   $0x3f
  800520:	ff 55 08             	call   *0x8(%ebp)
  800523:	83 c4 10             	add    $0x10,%esp
  800526:	eb 0d                	jmp    800535 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800528:	83 ec 08             	sub    $0x8,%esp
  80052b:	ff 75 0c             	pushl  0xc(%ebp)
  80052e:	52                   	push   %edx
  80052f:	ff 55 08             	call   *0x8(%ebp)
  800532:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800535:	83 eb 01             	sub    $0x1,%ebx
  800538:	eb 1a                	jmp    800554 <vprintfmt+0x24b>
  80053a:	89 75 08             	mov    %esi,0x8(%ebp)
  80053d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800540:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800543:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800546:	eb 0c                	jmp    800554 <vprintfmt+0x24b>
  800548:	89 75 08             	mov    %esi,0x8(%ebp)
  80054b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80054e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800551:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800554:	83 c7 01             	add    $0x1,%edi
  800557:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80055b:	0f be d0             	movsbl %al,%edx
  80055e:	85 d2                	test   %edx,%edx
  800560:	74 23                	je     800585 <vprintfmt+0x27c>
  800562:	85 f6                	test   %esi,%esi
  800564:	78 a1                	js     800507 <vprintfmt+0x1fe>
  800566:	83 ee 01             	sub    $0x1,%esi
  800569:	79 9c                	jns    800507 <vprintfmt+0x1fe>
  80056b:	89 df                	mov    %ebx,%edi
  80056d:	8b 75 08             	mov    0x8(%ebp),%esi
  800570:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800573:	eb 18                	jmp    80058d <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800575:	83 ec 08             	sub    $0x8,%esp
  800578:	53                   	push   %ebx
  800579:	6a 20                	push   $0x20
  80057b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80057d:	83 ef 01             	sub    $0x1,%edi
  800580:	83 c4 10             	add    $0x10,%esp
  800583:	eb 08                	jmp    80058d <vprintfmt+0x284>
  800585:	89 df                	mov    %ebx,%edi
  800587:	8b 75 08             	mov    0x8(%ebp),%esi
  80058a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80058d:	85 ff                	test   %edi,%edi
  80058f:	7f e4                	jg     800575 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800591:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800594:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800597:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80059a:	e9 90 fd ff ff       	jmp    80032f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80059f:	83 f9 01             	cmp    $0x1,%ecx
  8005a2:	7e 19                	jle    8005bd <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a7:	8b 50 04             	mov    0x4(%eax),%edx
  8005aa:	8b 00                	mov    (%eax),%eax
  8005ac:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005af:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b5:	8d 40 08             	lea    0x8(%eax),%eax
  8005b8:	89 45 14             	mov    %eax,0x14(%ebp)
  8005bb:	eb 38                	jmp    8005f5 <vprintfmt+0x2ec>
	else if (lflag)
  8005bd:	85 c9                	test   %ecx,%ecx
  8005bf:	74 1b                	je     8005dc <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c4:	8b 00                	mov    (%eax),%eax
  8005c6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c9:	89 c1                	mov    %eax,%ecx
  8005cb:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ce:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d4:	8d 40 04             	lea    0x4(%eax),%eax
  8005d7:	89 45 14             	mov    %eax,0x14(%ebp)
  8005da:	eb 19                	jmp    8005f5 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005df:	8b 00                	mov    (%eax),%eax
  8005e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e4:	89 c1                	mov    %eax,%ecx
  8005e6:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ef:	8d 40 04             	lea    0x4(%eax),%eax
  8005f2:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005f5:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005fb:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800600:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800604:	0f 89 36 01 00 00    	jns    800740 <vprintfmt+0x437>
				putch('-', putdat);
  80060a:	83 ec 08             	sub    $0x8,%esp
  80060d:	53                   	push   %ebx
  80060e:	6a 2d                	push   $0x2d
  800610:	ff d6                	call   *%esi
				num = -(long long) num;
  800612:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800615:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800618:	f7 da                	neg    %edx
  80061a:	83 d1 00             	adc    $0x0,%ecx
  80061d:	f7 d9                	neg    %ecx
  80061f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800622:	b8 0a 00 00 00       	mov    $0xa,%eax
  800627:	e9 14 01 00 00       	jmp    800740 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80062c:	83 f9 01             	cmp    $0x1,%ecx
  80062f:	7e 18                	jle    800649 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800631:	8b 45 14             	mov    0x14(%ebp),%eax
  800634:	8b 10                	mov    (%eax),%edx
  800636:	8b 48 04             	mov    0x4(%eax),%ecx
  800639:	8d 40 08             	lea    0x8(%eax),%eax
  80063c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80063f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800644:	e9 f7 00 00 00       	jmp    800740 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800649:	85 c9                	test   %ecx,%ecx
  80064b:	74 1a                	je     800667 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80064d:	8b 45 14             	mov    0x14(%ebp),%eax
  800650:	8b 10                	mov    (%eax),%edx
  800652:	b9 00 00 00 00       	mov    $0x0,%ecx
  800657:	8d 40 04             	lea    0x4(%eax),%eax
  80065a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80065d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800662:	e9 d9 00 00 00       	jmp    800740 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800667:	8b 45 14             	mov    0x14(%ebp),%eax
  80066a:	8b 10                	mov    (%eax),%edx
  80066c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800671:	8d 40 04             	lea    0x4(%eax),%eax
  800674:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800677:	b8 0a 00 00 00       	mov    $0xa,%eax
  80067c:	e9 bf 00 00 00       	jmp    800740 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800681:	83 f9 01             	cmp    $0x1,%ecx
  800684:	7e 13                	jle    800699 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  800686:	8b 45 14             	mov    0x14(%ebp),%eax
  800689:	8b 50 04             	mov    0x4(%eax),%edx
  80068c:	8b 00                	mov    (%eax),%eax
  80068e:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800691:	8d 49 08             	lea    0x8(%ecx),%ecx
  800694:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800697:	eb 28                	jmp    8006c1 <vprintfmt+0x3b8>
	else if (lflag)
  800699:	85 c9                	test   %ecx,%ecx
  80069b:	74 13                	je     8006b0 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  80069d:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a0:	8b 10                	mov    (%eax),%edx
  8006a2:	89 d0                	mov    %edx,%eax
  8006a4:	99                   	cltd   
  8006a5:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006a8:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006ab:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8006ae:	eb 11                	jmp    8006c1 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8006b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b3:	8b 10                	mov    (%eax),%edx
  8006b5:	89 d0                	mov    %edx,%eax
  8006b7:	99                   	cltd   
  8006b8:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006bb:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006be:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8006c1:	89 d1                	mov    %edx,%ecx
  8006c3:	89 c2                	mov    %eax,%edx
			base = 8;
  8006c5:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006ca:	eb 74                	jmp    800740 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8006cc:	83 ec 08             	sub    $0x8,%esp
  8006cf:	53                   	push   %ebx
  8006d0:	6a 30                	push   $0x30
  8006d2:	ff d6                	call   *%esi
			putch('x', putdat);
  8006d4:	83 c4 08             	add    $0x8,%esp
  8006d7:	53                   	push   %ebx
  8006d8:	6a 78                	push   $0x78
  8006da:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006dc:	8b 45 14             	mov    0x14(%ebp),%eax
  8006df:	8b 10                	mov    (%eax),%edx
  8006e1:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006e6:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006e9:	8d 40 04             	lea    0x4(%eax),%eax
  8006ec:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006ef:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006f4:	eb 4a                	jmp    800740 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006f6:	83 f9 01             	cmp    $0x1,%ecx
  8006f9:	7e 15                	jle    800710 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  8006fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fe:	8b 10                	mov    (%eax),%edx
  800700:	8b 48 04             	mov    0x4(%eax),%ecx
  800703:	8d 40 08             	lea    0x8(%eax),%eax
  800706:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800709:	b8 10 00 00 00       	mov    $0x10,%eax
  80070e:	eb 30                	jmp    800740 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800710:	85 c9                	test   %ecx,%ecx
  800712:	74 17                	je     80072b <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800714:	8b 45 14             	mov    0x14(%ebp),%eax
  800717:	8b 10                	mov    (%eax),%edx
  800719:	b9 00 00 00 00       	mov    $0x0,%ecx
  80071e:	8d 40 04             	lea    0x4(%eax),%eax
  800721:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800724:	b8 10 00 00 00       	mov    $0x10,%eax
  800729:	eb 15                	jmp    800740 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80072b:	8b 45 14             	mov    0x14(%ebp),%eax
  80072e:	8b 10                	mov    (%eax),%edx
  800730:	b9 00 00 00 00       	mov    $0x0,%ecx
  800735:	8d 40 04             	lea    0x4(%eax),%eax
  800738:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80073b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800740:	83 ec 0c             	sub    $0xc,%esp
  800743:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800747:	57                   	push   %edi
  800748:	ff 75 e0             	pushl  -0x20(%ebp)
  80074b:	50                   	push   %eax
  80074c:	51                   	push   %ecx
  80074d:	52                   	push   %edx
  80074e:	89 da                	mov    %ebx,%edx
  800750:	89 f0                	mov    %esi,%eax
  800752:	e8 c9 fa ff ff       	call   800220 <printnum>
			break;
  800757:	83 c4 20             	add    $0x20,%esp
  80075a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80075d:	e9 cd fb ff ff       	jmp    80032f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800762:	83 ec 08             	sub    $0x8,%esp
  800765:	53                   	push   %ebx
  800766:	52                   	push   %edx
  800767:	ff d6                	call   *%esi
			break;
  800769:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80076c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80076f:	e9 bb fb ff ff       	jmp    80032f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800774:	83 ec 08             	sub    $0x8,%esp
  800777:	53                   	push   %ebx
  800778:	6a 25                	push   $0x25
  80077a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80077c:	83 c4 10             	add    $0x10,%esp
  80077f:	eb 03                	jmp    800784 <vprintfmt+0x47b>
  800781:	83 ef 01             	sub    $0x1,%edi
  800784:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800788:	75 f7                	jne    800781 <vprintfmt+0x478>
  80078a:	e9 a0 fb ff ff       	jmp    80032f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80078f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800792:	5b                   	pop    %ebx
  800793:	5e                   	pop    %esi
  800794:	5f                   	pop    %edi
  800795:	5d                   	pop    %ebp
  800796:	c3                   	ret    

00800797 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800797:	55                   	push   %ebp
  800798:	89 e5                	mov    %esp,%ebp
  80079a:	83 ec 18             	sub    $0x18,%esp
  80079d:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007a3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007a6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007aa:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007b4:	85 c0                	test   %eax,%eax
  8007b6:	74 26                	je     8007de <vsnprintf+0x47>
  8007b8:	85 d2                	test   %edx,%edx
  8007ba:	7e 22                	jle    8007de <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007bc:	ff 75 14             	pushl  0x14(%ebp)
  8007bf:	ff 75 10             	pushl  0x10(%ebp)
  8007c2:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007c5:	50                   	push   %eax
  8007c6:	68 cf 02 80 00       	push   $0x8002cf
  8007cb:	e8 39 fb ff ff       	call   800309 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007d3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007d9:	83 c4 10             	add    $0x10,%esp
  8007dc:	eb 05                	jmp    8007e3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007de:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007e3:	c9                   	leave  
  8007e4:	c3                   	ret    

008007e5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007e5:	55                   	push   %ebp
  8007e6:	89 e5                	mov    %esp,%ebp
  8007e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007eb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007ee:	50                   	push   %eax
  8007ef:	ff 75 10             	pushl  0x10(%ebp)
  8007f2:	ff 75 0c             	pushl  0xc(%ebp)
  8007f5:	ff 75 08             	pushl  0x8(%ebp)
  8007f8:	e8 9a ff ff ff       	call   800797 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007fd:	c9                   	leave  
  8007fe:	c3                   	ret    

008007ff <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800805:	b8 00 00 00 00       	mov    $0x0,%eax
  80080a:	eb 03                	jmp    80080f <strlen+0x10>
		n++;
  80080c:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80080f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800813:	75 f7                	jne    80080c <strlen+0xd>
		n++;
	return n;
}
  800815:	5d                   	pop    %ebp
  800816:	c3                   	ret    

00800817 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800817:	55                   	push   %ebp
  800818:	89 e5                	mov    %esp,%ebp
  80081a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80081d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800820:	ba 00 00 00 00       	mov    $0x0,%edx
  800825:	eb 03                	jmp    80082a <strnlen+0x13>
		n++;
  800827:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80082a:	39 c2                	cmp    %eax,%edx
  80082c:	74 08                	je     800836 <strnlen+0x1f>
  80082e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800832:	75 f3                	jne    800827 <strnlen+0x10>
  800834:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800836:	5d                   	pop    %ebp
  800837:	c3                   	ret    

00800838 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800838:	55                   	push   %ebp
  800839:	89 e5                	mov    %esp,%ebp
  80083b:	53                   	push   %ebx
  80083c:	8b 45 08             	mov    0x8(%ebp),%eax
  80083f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800842:	89 c2                	mov    %eax,%edx
  800844:	83 c2 01             	add    $0x1,%edx
  800847:	83 c1 01             	add    $0x1,%ecx
  80084a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80084e:	88 5a ff             	mov    %bl,-0x1(%edx)
  800851:	84 db                	test   %bl,%bl
  800853:	75 ef                	jne    800844 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800855:	5b                   	pop    %ebx
  800856:	5d                   	pop    %ebp
  800857:	c3                   	ret    

00800858 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800858:	55                   	push   %ebp
  800859:	89 e5                	mov    %esp,%ebp
  80085b:	53                   	push   %ebx
  80085c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80085f:	53                   	push   %ebx
  800860:	e8 9a ff ff ff       	call   8007ff <strlen>
  800865:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800868:	ff 75 0c             	pushl  0xc(%ebp)
  80086b:	01 d8                	add    %ebx,%eax
  80086d:	50                   	push   %eax
  80086e:	e8 c5 ff ff ff       	call   800838 <strcpy>
	return dst;
}
  800873:	89 d8                	mov    %ebx,%eax
  800875:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800878:	c9                   	leave  
  800879:	c3                   	ret    

0080087a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80087a:	55                   	push   %ebp
  80087b:	89 e5                	mov    %esp,%ebp
  80087d:	56                   	push   %esi
  80087e:	53                   	push   %ebx
  80087f:	8b 75 08             	mov    0x8(%ebp),%esi
  800882:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800885:	89 f3                	mov    %esi,%ebx
  800887:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088a:	89 f2                	mov    %esi,%edx
  80088c:	eb 0f                	jmp    80089d <strncpy+0x23>
		*dst++ = *src;
  80088e:	83 c2 01             	add    $0x1,%edx
  800891:	0f b6 01             	movzbl (%ecx),%eax
  800894:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800897:	80 39 01             	cmpb   $0x1,(%ecx)
  80089a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80089d:	39 da                	cmp    %ebx,%edx
  80089f:	75 ed                	jne    80088e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008a1:	89 f0                	mov    %esi,%eax
  8008a3:	5b                   	pop    %ebx
  8008a4:	5e                   	pop    %esi
  8008a5:	5d                   	pop    %ebp
  8008a6:	c3                   	ret    

008008a7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	56                   	push   %esi
  8008ab:	53                   	push   %ebx
  8008ac:	8b 75 08             	mov    0x8(%ebp),%esi
  8008af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008b2:	8b 55 10             	mov    0x10(%ebp),%edx
  8008b5:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008b7:	85 d2                	test   %edx,%edx
  8008b9:	74 21                	je     8008dc <strlcpy+0x35>
  8008bb:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008bf:	89 f2                	mov    %esi,%edx
  8008c1:	eb 09                	jmp    8008cc <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008c3:	83 c2 01             	add    $0x1,%edx
  8008c6:	83 c1 01             	add    $0x1,%ecx
  8008c9:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008cc:	39 c2                	cmp    %eax,%edx
  8008ce:	74 09                	je     8008d9 <strlcpy+0x32>
  8008d0:	0f b6 19             	movzbl (%ecx),%ebx
  8008d3:	84 db                	test   %bl,%bl
  8008d5:	75 ec                	jne    8008c3 <strlcpy+0x1c>
  8008d7:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008d9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008dc:	29 f0                	sub    %esi,%eax
}
  8008de:	5b                   	pop    %ebx
  8008df:	5e                   	pop    %esi
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008e8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008eb:	eb 06                	jmp    8008f3 <strcmp+0x11>
		p++, q++;
  8008ed:	83 c1 01             	add    $0x1,%ecx
  8008f0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008f3:	0f b6 01             	movzbl (%ecx),%eax
  8008f6:	84 c0                	test   %al,%al
  8008f8:	74 04                	je     8008fe <strcmp+0x1c>
  8008fa:	3a 02                	cmp    (%edx),%al
  8008fc:	74 ef                	je     8008ed <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008fe:	0f b6 c0             	movzbl %al,%eax
  800901:	0f b6 12             	movzbl (%edx),%edx
  800904:	29 d0                	sub    %edx,%eax
}
  800906:	5d                   	pop    %ebp
  800907:	c3                   	ret    

00800908 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800908:	55                   	push   %ebp
  800909:	89 e5                	mov    %esp,%ebp
  80090b:	53                   	push   %ebx
  80090c:	8b 45 08             	mov    0x8(%ebp),%eax
  80090f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800912:	89 c3                	mov    %eax,%ebx
  800914:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800917:	eb 06                	jmp    80091f <strncmp+0x17>
		n--, p++, q++;
  800919:	83 c0 01             	add    $0x1,%eax
  80091c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80091f:	39 d8                	cmp    %ebx,%eax
  800921:	74 15                	je     800938 <strncmp+0x30>
  800923:	0f b6 08             	movzbl (%eax),%ecx
  800926:	84 c9                	test   %cl,%cl
  800928:	74 04                	je     80092e <strncmp+0x26>
  80092a:	3a 0a                	cmp    (%edx),%cl
  80092c:	74 eb                	je     800919 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80092e:	0f b6 00             	movzbl (%eax),%eax
  800931:	0f b6 12             	movzbl (%edx),%edx
  800934:	29 d0                	sub    %edx,%eax
  800936:	eb 05                	jmp    80093d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800938:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80093d:	5b                   	pop    %ebx
  80093e:	5d                   	pop    %ebp
  80093f:	c3                   	ret    

00800940 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800940:	55                   	push   %ebp
  800941:	89 e5                	mov    %esp,%ebp
  800943:	8b 45 08             	mov    0x8(%ebp),%eax
  800946:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80094a:	eb 07                	jmp    800953 <strchr+0x13>
		if (*s == c)
  80094c:	38 ca                	cmp    %cl,%dl
  80094e:	74 0f                	je     80095f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800950:	83 c0 01             	add    $0x1,%eax
  800953:	0f b6 10             	movzbl (%eax),%edx
  800956:	84 d2                	test   %dl,%dl
  800958:	75 f2                	jne    80094c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80095a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80095f:	5d                   	pop    %ebp
  800960:	c3                   	ret    

00800961 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800961:	55                   	push   %ebp
  800962:	89 e5                	mov    %esp,%ebp
  800964:	8b 45 08             	mov    0x8(%ebp),%eax
  800967:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80096b:	eb 03                	jmp    800970 <strfind+0xf>
  80096d:	83 c0 01             	add    $0x1,%eax
  800970:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800973:	38 ca                	cmp    %cl,%dl
  800975:	74 04                	je     80097b <strfind+0x1a>
  800977:	84 d2                	test   %dl,%dl
  800979:	75 f2                	jne    80096d <strfind+0xc>
			break;
	return (char *) s;
}
  80097b:	5d                   	pop    %ebp
  80097c:	c3                   	ret    

0080097d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80097d:	55                   	push   %ebp
  80097e:	89 e5                	mov    %esp,%ebp
  800980:	57                   	push   %edi
  800981:	56                   	push   %esi
  800982:	53                   	push   %ebx
  800983:	8b 7d 08             	mov    0x8(%ebp),%edi
  800986:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800989:	85 c9                	test   %ecx,%ecx
  80098b:	74 36                	je     8009c3 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80098d:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800993:	75 28                	jne    8009bd <memset+0x40>
  800995:	f6 c1 03             	test   $0x3,%cl
  800998:	75 23                	jne    8009bd <memset+0x40>
		c &= 0xFF;
  80099a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80099e:	89 d3                	mov    %edx,%ebx
  8009a0:	c1 e3 08             	shl    $0x8,%ebx
  8009a3:	89 d6                	mov    %edx,%esi
  8009a5:	c1 e6 18             	shl    $0x18,%esi
  8009a8:	89 d0                	mov    %edx,%eax
  8009aa:	c1 e0 10             	shl    $0x10,%eax
  8009ad:	09 f0                	or     %esi,%eax
  8009af:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009b1:	89 d8                	mov    %ebx,%eax
  8009b3:	09 d0                	or     %edx,%eax
  8009b5:	c1 e9 02             	shr    $0x2,%ecx
  8009b8:	fc                   	cld    
  8009b9:	f3 ab                	rep stos %eax,%es:(%edi)
  8009bb:	eb 06                	jmp    8009c3 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009c0:	fc                   	cld    
  8009c1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009c3:	89 f8                	mov    %edi,%eax
  8009c5:	5b                   	pop    %ebx
  8009c6:	5e                   	pop    %esi
  8009c7:	5f                   	pop    %edi
  8009c8:	5d                   	pop    %ebp
  8009c9:	c3                   	ret    

008009ca <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009ca:	55                   	push   %ebp
  8009cb:	89 e5                	mov    %esp,%ebp
  8009cd:	57                   	push   %edi
  8009ce:	56                   	push   %esi
  8009cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d2:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009d8:	39 c6                	cmp    %eax,%esi
  8009da:	73 35                	jae    800a11 <memmove+0x47>
  8009dc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009df:	39 d0                	cmp    %edx,%eax
  8009e1:	73 2e                	jae    800a11 <memmove+0x47>
		s += n;
		d += n;
  8009e3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009e6:	89 d6                	mov    %edx,%esi
  8009e8:	09 fe                	or     %edi,%esi
  8009ea:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009f0:	75 13                	jne    800a05 <memmove+0x3b>
  8009f2:	f6 c1 03             	test   $0x3,%cl
  8009f5:	75 0e                	jne    800a05 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009f7:	83 ef 04             	sub    $0x4,%edi
  8009fa:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009fd:	c1 e9 02             	shr    $0x2,%ecx
  800a00:	fd                   	std    
  800a01:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a03:	eb 09                	jmp    800a0e <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a05:	83 ef 01             	sub    $0x1,%edi
  800a08:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a0b:	fd                   	std    
  800a0c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a0e:	fc                   	cld    
  800a0f:	eb 1d                	jmp    800a2e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a11:	89 f2                	mov    %esi,%edx
  800a13:	09 c2                	or     %eax,%edx
  800a15:	f6 c2 03             	test   $0x3,%dl
  800a18:	75 0f                	jne    800a29 <memmove+0x5f>
  800a1a:	f6 c1 03             	test   $0x3,%cl
  800a1d:	75 0a                	jne    800a29 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a1f:	c1 e9 02             	shr    $0x2,%ecx
  800a22:	89 c7                	mov    %eax,%edi
  800a24:	fc                   	cld    
  800a25:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a27:	eb 05                	jmp    800a2e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a29:	89 c7                	mov    %eax,%edi
  800a2b:	fc                   	cld    
  800a2c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a2e:	5e                   	pop    %esi
  800a2f:	5f                   	pop    %edi
  800a30:	5d                   	pop    %ebp
  800a31:	c3                   	ret    

00800a32 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a32:	55                   	push   %ebp
  800a33:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a35:	ff 75 10             	pushl  0x10(%ebp)
  800a38:	ff 75 0c             	pushl  0xc(%ebp)
  800a3b:	ff 75 08             	pushl  0x8(%ebp)
  800a3e:	e8 87 ff ff ff       	call   8009ca <memmove>
}
  800a43:	c9                   	leave  
  800a44:	c3                   	ret    

00800a45 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a45:	55                   	push   %ebp
  800a46:	89 e5                	mov    %esp,%ebp
  800a48:	56                   	push   %esi
  800a49:	53                   	push   %ebx
  800a4a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a4d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a50:	89 c6                	mov    %eax,%esi
  800a52:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a55:	eb 1a                	jmp    800a71 <memcmp+0x2c>
		if (*s1 != *s2)
  800a57:	0f b6 08             	movzbl (%eax),%ecx
  800a5a:	0f b6 1a             	movzbl (%edx),%ebx
  800a5d:	38 d9                	cmp    %bl,%cl
  800a5f:	74 0a                	je     800a6b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a61:	0f b6 c1             	movzbl %cl,%eax
  800a64:	0f b6 db             	movzbl %bl,%ebx
  800a67:	29 d8                	sub    %ebx,%eax
  800a69:	eb 0f                	jmp    800a7a <memcmp+0x35>
		s1++, s2++;
  800a6b:	83 c0 01             	add    $0x1,%eax
  800a6e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a71:	39 f0                	cmp    %esi,%eax
  800a73:	75 e2                	jne    800a57 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a75:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a7a:	5b                   	pop    %ebx
  800a7b:	5e                   	pop    %esi
  800a7c:	5d                   	pop    %ebp
  800a7d:	c3                   	ret    

00800a7e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a7e:	55                   	push   %ebp
  800a7f:	89 e5                	mov    %esp,%ebp
  800a81:	53                   	push   %ebx
  800a82:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a85:	89 c1                	mov    %eax,%ecx
  800a87:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a8a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a8e:	eb 0a                	jmp    800a9a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a90:	0f b6 10             	movzbl (%eax),%edx
  800a93:	39 da                	cmp    %ebx,%edx
  800a95:	74 07                	je     800a9e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a97:	83 c0 01             	add    $0x1,%eax
  800a9a:	39 c8                	cmp    %ecx,%eax
  800a9c:	72 f2                	jb     800a90 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a9e:	5b                   	pop    %ebx
  800a9f:	5d                   	pop    %ebp
  800aa0:	c3                   	ret    

00800aa1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800aa1:	55                   	push   %ebp
  800aa2:	89 e5                	mov    %esp,%ebp
  800aa4:	57                   	push   %edi
  800aa5:	56                   	push   %esi
  800aa6:	53                   	push   %ebx
  800aa7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aaa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aad:	eb 03                	jmp    800ab2 <strtol+0x11>
		s++;
  800aaf:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ab2:	0f b6 01             	movzbl (%ecx),%eax
  800ab5:	3c 20                	cmp    $0x20,%al
  800ab7:	74 f6                	je     800aaf <strtol+0xe>
  800ab9:	3c 09                	cmp    $0x9,%al
  800abb:	74 f2                	je     800aaf <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800abd:	3c 2b                	cmp    $0x2b,%al
  800abf:	75 0a                	jne    800acb <strtol+0x2a>
		s++;
  800ac1:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ac4:	bf 00 00 00 00       	mov    $0x0,%edi
  800ac9:	eb 11                	jmp    800adc <strtol+0x3b>
  800acb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ad0:	3c 2d                	cmp    $0x2d,%al
  800ad2:	75 08                	jne    800adc <strtol+0x3b>
		s++, neg = 1;
  800ad4:	83 c1 01             	add    $0x1,%ecx
  800ad7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800adc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ae2:	75 15                	jne    800af9 <strtol+0x58>
  800ae4:	80 39 30             	cmpb   $0x30,(%ecx)
  800ae7:	75 10                	jne    800af9 <strtol+0x58>
  800ae9:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800aed:	75 7c                	jne    800b6b <strtol+0xca>
		s += 2, base = 16;
  800aef:	83 c1 02             	add    $0x2,%ecx
  800af2:	bb 10 00 00 00       	mov    $0x10,%ebx
  800af7:	eb 16                	jmp    800b0f <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800af9:	85 db                	test   %ebx,%ebx
  800afb:	75 12                	jne    800b0f <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800afd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b02:	80 39 30             	cmpb   $0x30,(%ecx)
  800b05:	75 08                	jne    800b0f <strtol+0x6e>
		s++, base = 8;
  800b07:	83 c1 01             	add    $0x1,%ecx
  800b0a:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b0f:	b8 00 00 00 00       	mov    $0x0,%eax
  800b14:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b17:	0f b6 11             	movzbl (%ecx),%edx
  800b1a:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b1d:	89 f3                	mov    %esi,%ebx
  800b1f:	80 fb 09             	cmp    $0x9,%bl
  800b22:	77 08                	ja     800b2c <strtol+0x8b>
			dig = *s - '0';
  800b24:	0f be d2             	movsbl %dl,%edx
  800b27:	83 ea 30             	sub    $0x30,%edx
  800b2a:	eb 22                	jmp    800b4e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b2c:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b2f:	89 f3                	mov    %esi,%ebx
  800b31:	80 fb 19             	cmp    $0x19,%bl
  800b34:	77 08                	ja     800b3e <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b36:	0f be d2             	movsbl %dl,%edx
  800b39:	83 ea 57             	sub    $0x57,%edx
  800b3c:	eb 10                	jmp    800b4e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b3e:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b41:	89 f3                	mov    %esi,%ebx
  800b43:	80 fb 19             	cmp    $0x19,%bl
  800b46:	77 16                	ja     800b5e <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b48:	0f be d2             	movsbl %dl,%edx
  800b4b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b4e:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b51:	7d 0b                	jge    800b5e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b53:	83 c1 01             	add    $0x1,%ecx
  800b56:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b5a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b5c:	eb b9                	jmp    800b17 <strtol+0x76>

	if (endptr)
  800b5e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b62:	74 0d                	je     800b71 <strtol+0xd0>
		*endptr = (char *) s;
  800b64:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b67:	89 0e                	mov    %ecx,(%esi)
  800b69:	eb 06                	jmp    800b71 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b6b:	85 db                	test   %ebx,%ebx
  800b6d:	74 98                	je     800b07 <strtol+0x66>
  800b6f:	eb 9e                	jmp    800b0f <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b71:	89 c2                	mov    %eax,%edx
  800b73:	f7 da                	neg    %edx
  800b75:	85 ff                	test   %edi,%edi
  800b77:	0f 45 c2             	cmovne %edx,%eax
}
  800b7a:	5b                   	pop    %ebx
  800b7b:	5e                   	pop    %esi
  800b7c:	5f                   	pop    %edi
  800b7d:	5d                   	pop    %ebp
  800b7e:	c3                   	ret    
  800b7f:	90                   	nop

00800b80 <__udivdi3>:
  800b80:	55                   	push   %ebp
  800b81:	57                   	push   %edi
  800b82:	56                   	push   %esi
  800b83:	53                   	push   %ebx
  800b84:	83 ec 1c             	sub    $0x1c,%esp
  800b87:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b8b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b8f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b97:	85 f6                	test   %esi,%esi
  800b99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b9d:	89 ca                	mov    %ecx,%edx
  800b9f:	89 f8                	mov    %edi,%eax
  800ba1:	75 3d                	jne    800be0 <__udivdi3+0x60>
  800ba3:	39 cf                	cmp    %ecx,%edi
  800ba5:	0f 87 c5 00 00 00    	ja     800c70 <__udivdi3+0xf0>
  800bab:	85 ff                	test   %edi,%edi
  800bad:	89 fd                	mov    %edi,%ebp
  800baf:	75 0b                	jne    800bbc <__udivdi3+0x3c>
  800bb1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bb6:	31 d2                	xor    %edx,%edx
  800bb8:	f7 f7                	div    %edi
  800bba:	89 c5                	mov    %eax,%ebp
  800bbc:	89 c8                	mov    %ecx,%eax
  800bbe:	31 d2                	xor    %edx,%edx
  800bc0:	f7 f5                	div    %ebp
  800bc2:	89 c1                	mov    %eax,%ecx
  800bc4:	89 d8                	mov    %ebx,%eax
  800bc6:	89 cf                	mov    %ecx,%edi
  800bc8:	f7 f5                	div    %ebp
  800bca:	89 c3                	mov    %eax,%ebx
  800bcc:	89 d8                	mov    %ebx,%eax
  800bce:	89 fa                	mov    %edi,%edx
  800bd0:	83 c4 1c             	add    $0x1c,%esp
  800bd3:	5b                   	pop    %ebx
  800bd4:	5e                   	pop    %esi
  800bd5:	5f                   	pop    %edi
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    
  800bd8:	90                   	nop
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	39 ce                	cmp    %ecx,%esi
  800be2:	77 74                	ja     800c58 <__udivdi3+0xd8>
  800be4:	0f bd fe             	bsr    %esi,%edi
  800be7:	83 f7 1f             	xor    $0x1f,%edi
  800bea:	0f 84 98 00 00 00    	je     800c88 <__udivdi3+0x108>
  800bf0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bf5:	89 f9                	mov    %edi,%ecx
  800bf7:	89 c5                	mov    %eax,%ebp
  800bf9:	29 fb                	sub    %edi,%ebx
  800bfb:	d3 e6                	shl    %cl,%esi
  800bfd:	89 d9                	mov    %ebx,%ecx
  800bff:	d3 ed                	shr    %cl,%ebp
  800c01:	89 f9                	mov    %edi,%ecx
  800c03:	d3 e0                	shl    %cl,%eax
  800c05:	09 ee                	or     %ebp,%esi
  800c07:	89 d9                	mov    %ebx,%ecx
  800c09:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c0d:	89 d5                	mov    %edx,%ebp
  800c0f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c13:	d3 ed                	shr    %cl,%ebp
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	d3 e2                	shl    %cl,%edx
  800c19:	89 d9                	mov    %ebx,%ecx
  800c1b:	d3 e8                	shr    %cl,%eax
  800c1d:	09 c2                	or     %eax,%edx
  800c1f:	89 d0                	mov    %edx,%eax
  800c21:	89 ea                	mov    %ebp,%edx
  800c23:	f7 f6                	div    %esi
  800c25:	89 d5                	mov    %edx,%ebp
  800c27:	89 c3                	mov    %eax,%ebx
  800c29:	f7 64 24 0c          	mull   0xc(%esp)
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	72 10                	jb     800c41 <__udivdi3+0xc1>
  800c31:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c35:	89 f9                	mov    %edi,%ecx
  800c37:	d3 e6                	shl    %cl,%esi
  800c39:	39 c6                	cmp    %eax,%esi
  800c3b:	73 07                	jae    800c44 <__udivdi3+0xc4>
  800c3d:	39 d5                	cmp    %edx,%ebp
  800c3f:	75 03                	jne    800c44 <__udivdi3+0xc4>
  800c41:	83 eb 01             	sub    $0x1,%ebx
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 d8                	mov    %ebx,%eax
  800c48:	89 fa                	mov    %edi,%edx
  800c4a:	83 c4 1c             	add    $0x1c,%esp
  800c4d:	5b                   	pop    %ebx
  800c4e:	5e                   	pop    %esi
  800c4f:	5f                   	pop    %edi
  800c50:	5d                   	pop    %ebp
  800c51:	c3                   	ret    
  800c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c58:	31 ff                	xor    %edi,%edi
  800c5a:	31 db                	xor    %ebx,%ebx
  800c5c:	89 d8                	mov    %ebx,%eax
  800c5e:	89 fa                	mov    %edi,%edx
  800c60:	83 c4 1c             	add    $0x1c,%esp
  800c63:	5b                   	pop    %ebx
  800c64:	5e                   	pop    %esi
  800c65:	5f                   	pop    %edi
  800c66:	5d                   	pop    %ebp
  800c67:	c3                   	ret    
  800c68:	90                   	nop
  800c69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c70:	89 d8                	mov    %ebx,%eax
  800c72:	f7 f7                	div    %edi
  800c74:	31 ff                	xor    %edi,%edi
  800c76:	89 c3                	mov    %eax,%ebx
  800c78:	89 d8                	mov    %ebx,%eax
  800c7a:	89 fa                	mov    %edi,%edx
  800c7c:	83 c4 1c             	add    $0x1c,%esp
  800c7f:	5b                   	pop    %ebx
  800c80:	5e                   	pop    %esi
  800c81:	5f                   	pop    %edi
  800c82:	5d                   	pop    %ebp
  800c83:	c3                   	ret    
  800c84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c88:	39 ce                	cmp    %ecx,%esi
  800c8a:	72 0c                	jb     800c98 <__udivdi3+0x118>
  800c8c:	31 db                	xor    %ebx,%ebx
  800c8e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c92:	0f 87 34 ff ff ff    	ja     800bcc <__udivdi3+0x4c>
  800c98:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c9d:	e9 2a ff ff ff       	jmp    800bcc <__udivdi3+0x4c>
  800ca2:	66 90                	xchg   %ax,%ax
  800ca4:	66 90                	xchg   %ax,%ax
  800ca6:	66 90                	xchg   %ax,%ax
  800ca8:	66 90                	xchg   %ax,%ax
  800caa:	66 90                	xchg   %ax,%ax
  800cac:	66 90                	xchg   %ax,%ax
  800cae:	66 90                	xchg   %ax,%ax

00800cb0 <__umoddi3>:
  800cb0:	55                   	push   %ebp
  800cb1:	57                   	push   %edi
  800cb2:	56                   	push   %esi
  800cb3:	53                   	push   %ebx
  800cb4:	83 ec 1c             	sub    $0x1c,%esp
  800cb7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cbb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800cbf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cc3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cc7:	85 d2                	test   %edx,%edx
  800cc9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ccd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cd1:	89 f3                	mov    %esi,%ebx
  800cd3:	89 3c 24             	mov    %edi,(%esp)
  800cd6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cda:	75 1c                	jne    800cf8 <__umoddi3+0x48>
  800cdc:	39 f7                	cmp    %esi,%edi
  800cde:	76 50                	jbe    800d30 <__umoddi3+0x80>
  800ce0:	89 c8                	mov    %ecx,%eax
  800ce2:	89 f2                	mov    %esi,%edx
  800ce4:	f7 f7                	div    %edi
  800ce6:	89 d0                	mov    %edx,%eax
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	83 c4 1c             	add    $0x1c,%esp
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5f                   	pop    %edi
  800cf0:	5d                   	pop    %ebp
  800cf1:	c3                   	ret    
  800cf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cf8:	39 f2                	cmp    %esi,%edx
  800cfa:	89 d0                	mov    %edx,%eax
  800cfc:	77 52                	ja     800d50 <__umoddi3+0xa0>
  800cfe:	0f bd ea             	bsr    %edx,%ebp
  800d01:	83 f5 1f             	xor    $0x1f,%ebp
  800d04:	75 5a                	jne    800d60 <__umoddi3+0xb0>
  800d06:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d0a:	0f 82 e0 00 00 00    	jb     800df0 <__umoddi3+0x140>
  800d10:	39 0c 24             	cmp    %ecx,(%esp)
  800d13:	0f 86 d7 00 00 00    	jbe    800df0 <__umoddi3+0x140>
  800d19:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d1d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d21:	83 c4 1c             	add    $0x1c,%esp
  800d24:	5b                   	pop    %ebx
  800d25:	5e                   	pop    %esi
  800d26:	5f                   	pop    %edi
  800d27:	5d                   	pop    %ebp
  800d28:	c3                   	ret    
  800d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d30:	85 ff                	test   %edi,%edi
  800d32:	89 fd                	mov    %edi,%ebp
  800d34:	75 0b                	jne    800d41 <__umoddi3+0x91>
  800d36:	b8 01 00 00 00       	mov    $0x1,%eax
  800d3b:	31 d2                	xor    %edx,%edx
  800d3d:	f7 f7                	div    %edi
  800d3f:	89 c5                	mov    %eax,%ebp
  800d41:	89 f0                	mov    %esi,%eax
  800d43:	31 d2                	xor    %edx,%edx
  800d45:	f7 f5                	div    %ebp
  800d47:	89 c8                	mov    %ecx,%eax
  800d49:	f7 f5                	div    %ebp
  800d4b:	89 d0                	mov    %edx,%eax
  800d4d:	eb 99                	jmp    800ce8 <__umoddi3+0x38>
  800d4f:	90                   	nop
  800d50:	89 c8                	mov    %ecx,%eax
  800d52:	89 f2                	mov    %esi,%edx
  800d54:	83 c4 1c             	add    $0x1c,%esp
  800d57:	5b                   	pop    %ebx
  800d58:	5e                   	pop    %esi
  800d59:	5f                   	pop    %edi
  800d5a:	5d                   	pop    %ebp
  800d5b:	c3                   	ret    
  800d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d60:	8b 34 24             	mov    (%esp),%esi
  800d63:	bf 20 00 00 00       	mov    $0x20,%edi
  800d68:	89 e9                	mov    %ebp,%ecx
  800d6a:	29 ef                	sub    %ebp,%edi
  800d6c:	d3 e0                	shl    %cl,%eax
  800d6e:	89 f9                	mov    %edi,%ecx
  800d70:	89 f2                	mov    %esi,%edx
  800d72:	d3 ea                	shr    %cl,%edx
  800d74:	89 e9                	mov    %ebp,%ecx
  800d76:	09 c2                	or     %eax,%edx
  800d78:	89 d8                	mov    %ebx,%eax
  800d7a:	89 14 24             	mov    %edx,(%esp)
  800d7d:	89 f2                	mov    %esi,%edx
  800d7f:	d3 e2                	shl    %cl,%edx
  800d81:	89 f9                	mov    %edi,%ecx
  800d83:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d87:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d8b:	d3 e8                	shr    %cl,%eax
  800d8d:	89 e9                	mov    %ebp,%ecx
  800d8f:	89 c6                	mov    %eax,%esi
  800d91:	d3 e3                	shl    %cl,%ebx
  800d93:	89 f9                	mov    %edi,%ecx
  800d95:	89 d0                	mov    %edx,%eax
  800d97:	d3 e8                	shr    %cl,%eax
  800d99:	89 e9                	mov    %ebp,%ecx
  800d9b:	09 d8                	or     %ebx,%eax
  800d9d:	89 d3                	mov    %edx,%ebx
  800d9f:	89 f2                	mov    %esi,%edx
  800da1:	f7 34 24             	divl   (%esp)
  800da4:	89 d6                	mov    %edx,%esi
  800da6:	d3 e3                	shl    %cl,%ebx
  800da8:	f7 64 24 04          	mull   0x4(%esp)
  800dac:	39 d6                	cmp    %edx,%esi
  800dae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800db2:	89 d1                	mov    %edx,%ecx
  800db4:	89 c3                	mov    %eax,%ebx
  800db6:	72 08                	jb     800dc0 <__umoddi3+0x110>
  800db8:	75 11                	jne    800dcb <__umoddi3+0x11b>
  800dba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dbe:	73 0b                	jae    800dcb <__umoddi3+0x11b>
  800dc0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800dc4:	1b 14 24             	sbb    (%esp),%edx
  800dc7:	89 d1                	mov    %edx,%ecx
  800dc9:	89 c3                	mov    %eax,%ebx
  800dcb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dcf:	29 da                	sub    %ebx,%edx
  800dd1:	19 ce                	sbb    %ecx,%esi
  800dd3:	89 f9                	mov    %edi,%ecx
  800dd5:	89 f0                	mov    %esi,%eax
  800dd7:	d3 e0                	shl    %cl,%eax
  800dd9:	89 e9                	mov    %ebp,%ecx
  800ddb:	d3 ea                	shr    %cl,%edx
  800ddd:	89 e9                	mov    %ebp,%ecx
  800ddf:	d3 ee                	shr    %cl,%esi
  800de1:	09 d0                	or     %edx,%eax
  800de3:	89 f2                	mov    %esi,%edx
  800de5:	83 c4 1c             	add    $0x1c,%esp
  800de8:	5b                   	pop    %ebx
  800de9:	5e                   	pop    %esi
  800dea:	5f                   	pop    %edi
  800deb:	5d                   	pop    %ebp
  800dec:	c3                   	ret    
  800ded:	8d 76 00             	lea    0x0(%esi),%esi
  800df0:	29 f9                	sub    %edi,%ecx
  800df2:	19 d6                	sbb    %edx,%esi
  800df4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800df8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dfc:	e9 18 ff ff ff       	jmp    800d19 <__umoddi3+0x69>
