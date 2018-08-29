
obj/user/buggyhello:     file format elf32-i386


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
  80002c:	e8 16 00 00 00       	call   800047 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)1, 1);
  800039:	6a 01                	push   $0x1
  80003b:	6a 01                	push   $0x1
  80003d:	e8 4d 00 00 00       	call   80008f <sys_cputs>
}
  800042:	83 c4 10             	add    $0x10,%esp
  800045:	c9                   	leave  
  800046:	c3                   	ret    

00800047 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800047:	55                   	push   %ebp
  800048:	89 e5                	mov    %esp,%ebp
  80004a:	83 ec 08             	sub    $0x8,%esp
  80004d:	8b 45 08             	mov    0x8(%ebp),%eax
  800050:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800053:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  80005a:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005d:	85 c0                	test   %eax,%eax
  80005f:	7e 08                	jle    800069 <libmain+0x22>
		binaryname = argv[0];
  800061:	8b 0a                	mov    (%edx),%ecx
  800063:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800069:	83 ec 08             	sub    $0x8,%esp
  80006c:	52                   	push   %edx
  80006d:	50                   	push   %eax
  80006e:	e8 c0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800073:	e8 05 00 00 00       	call   80007d <exit>
}
  800078:	83 c4 10             	add    $0x10,%esp
  80007b:	c9                   	leave  
  80007c:	c3                   	ret    

0080007d <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80007d:	55                   	push   %ebp
  80007e:	89 e5                	mov    %esp,%ebp
  800080:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800083:	6a 00                	push   $0x0
  800085:	e8 42 00 00 00       	call   8000cc <sys_env_destroy>
}
  80008a:	83 c4 10             	add    $0x10,%esp
  80008d:	c9                   	leave  
  80008e:	c3                   	ret    

0080008f <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80008f:	55                   	push   %ebp
  800090:	89 e5                	mov    %esp,%ebp
  800092:	57                   	push   %edi
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800095:	b8 00 00 00 00       	mov    $0x0,%eax
  80009a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80009d:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a0:	89 c3                	mov    %eax,%ebx
  8000a2:	89 c7                	mov    %eax,%edi
  8000a4:	89 c6                	mov    %eax,%esi
  8000a6:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000a8:	5b                   	pop    %ebx
  8000a9:	5e                   	pop    %esi
  8000aa:	5f                   	pop    %edi
  8000ab:	5d                   	pop    %ebp
  8000ac:	c3                   	ret    

008000ad <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ad:	55                   	push   %ebp
  8000ae:	89 e5                	mov    %esp,%ebp
  8000b0:	57                   	push   %edi
  8000b1:	56                   	push   %esi
  8000b2:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b3:	ba 00 00 00 00       	mov    $0x0,%edx
  8000b8:	b8 01 00 00 00       	mov    $0x1,%eax
  8000bd:	89 d1                	mov    %edx,%ecx
  8000bf:	89 d3                	mov    %edx,%ebx
  8000c1:	89 d7                	mov    %edx,%edi
  8000c3:	89 d6                	mov    %edx,%esi
  8000c5:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000c7:	5b                   	pop    %ebx
  8000c8:	5e                   	pop    %esi
  8000c9:	5f                   	pop    %edi
  8000ca:	5d                   	pop    %ebp
  8000cb:	c3                   	ret    

008000cc <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000cc:	55                   	push   %ebp
  8000cd:	89 e5                	mov    %esp,%ebp
  8000cf:	57                   	push   %edi
  8000d0:	56                   	push   %esi
  8000d1:	53                   	push   %ebx
  8000d2:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000da:	b8 03 00 00 00       	mov    $0x3,%eax
  8000df:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e2:	89 cb                	mov    %ecx,%ebx
  8000e4:	89 cf                	mov    %ecx,%edi
  8000e6:	89 ce                	mov    %ecx,%esi
  8000e8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000ea:	85 c0                	test   %eax,%eax
  8000ec:	7e 17                	jle    800105 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ee:	83 ec 0c             	sub    $0xc,%esp
  8000f1:	50                   	push   %eax
  8000f2:	6a 03                	push   $0x3
  8000f4:	68 2a 0e 80 00       	push   $0x800e2a
  8000f9:	6a 23                	push   $0x23
  8000fb:	68 47 0e 80 00       	push   $0x800e47
  800100:	e8 27 00 00 00       	call   80012c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800105:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800108:	5b                   	pop    %ebx
  800109:	5e                   	pop    %esi
  80010a:	5f                   	pop    %edi
  80010b:	5d                   	pop    %ebp
  80010c:	c3                   	ret    

0080010d <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80010d:	55                   	push   %ebp
  80010e:	89 e5                	mov    %esp,%ebp
  800110:	57                   	push   %edi
  800111:	56                   	push   %esi
  800112:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800113:	ba 00 00 00 00       	mov    $0x0,%edx
  800118:	b8 02 00 00 00       	mov    $0x2,%eax
  80011d:	89 d1                	mov    %edx,%ecx
  80011f:	89 d3                	mov    %edx,%ebx
  800121:	89 d7                	mov    %edx,%edi
  800123:	89 d6                	mov    %edx,%esi
  800125:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800127:	5b                   	pop    %ebx
  800128:	5e                   	pop    %esi
  800129:	5f                   	pop    %edi
  80012a:	5d                   	pop    %ebp
  80012b:	c3                   	ret    

0080012c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80012c:	55                   	push   %ebp
  80012d:	89 e5                	mov    %esp,%ebp
  80012f:	56                   	push   %esi
  800130:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800131:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800134:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80013a:	e8 ce ff ff ff       	call   80010d <sys_getenvid>
  80013f:	83 ec 0c             	sub    $0xc,%esp
  800142:	ff 75 0c             	pushl  0xc(%ebp)
  800145:	ff 75 08             	pushl  0x8(%ebp)
  800148:	56                   	push   %esi
  800149:	50                   	push   %eax
  80014a:	68 58 0e 80 00       	push   $0x800e58
  80014f:	e8 b1 00 00 00       	call   800205 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800154:	83 c4 18             	add    $0x18,%esp
  800157:	53                   	push   %ebx
  800158:	ff 75 10             	pushl  0x10(%ebp)
  80015b:	e8 54 00 00 00       	call   8001b4 <vcprintf>
	cprintf("\n");
  800160:	c7 04 24 7c 0e 80 00 	movl   $0x800e7c,(%esp)
  800167:	e8 99 00 00 00       	call   800205 <cprintf>
  80016c:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80016f:	cc                   	int3   
  800170:	eb fd                	jmp    80016f <_panic+0x43>

00800172 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800172:	55                   	push   %ebp
  800173:	89 e5                	mov    %esp,%ebp
  800175:	53                   	push   %ebx
  800176:	83 ec 04             	sub    $0x4,%esp
  800179:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80017c:	8b 13                	mov    (%ebx),%edx
  80017e:	8d 42 01             	lea    0x1(%edx),%eax
  800181:	89 03                	mov    %eax,(%ebx)
  800183:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800186:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018a:	3d ff 00 00 00       	cmp    $0xff,%eax
  80018f:	75 1a                	jne    8001ab <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800191:	83 ec 08             	sub    $0x8,%esp
  800194:	68 ff 00 00 00       	push   $0xff
  800199:	8d 43 08             	lea    0x8(%ebx),%eax
  80019c:	50                   	push   %eax
  80019d:	e8 ed fe ff ff       	call   80008f <sys_cputs>
		b->idx = 0;
  8001a2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a8:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001ab:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b2:	c9                   	leave  
  8001b3:	c3                   	ret    

008001b4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b4:	55                   	push   %ebp
  8001b5:	89 e5                	mov    %esp,%ebp
  8001b7:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001bd:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c4:	00 00 00 
	b.cnt = 0;
  8001c7:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001ce:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d1:	ff 75 0c             	pushl  0xc(%ebp)
  8001d4:	ff 75 08             	pushl  0x8(%ebp)
  8001d7:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001dd:	50                   	push   %eax
  8001de:	68 72 01 80 00       	push   $0x800172
  8001e3:	e8 1a 01 00 00       	call   800302 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e8:	83 c4 08             	add    $0x8,%esp
  8001eb:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f1:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001f7:	50                   	push   %eax
  8001f8:	e8 92 fe ff ff       	call   80008f <sys_cputs>

	return b.cnt;
}
  8001fd:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800203:	c9                   	leave  
  800204:	c3                   	ret    

00800205 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800205:	55                   	push   %ebp
  800206:	89 e5                	mov    %esp,%ebp
  800208:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80020b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80020e:	50                   	push   %eax
  80020f:	ff 75 08             	pushl  0x8(%ebp)
  800212:	e8 9d ff ff ff       	call   8001b4 <vcprintf>
	va_end(ap);

	return cnt;
}
  800217:	c9                   	leave  
  800218:	c3                   	ret    

00800219 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800219:	55                   	push   %ebp
  80021a:	89 e5                	mov    %esp,%ebp
  80021c:	57                   	push   %edi
  80021d:	56                   	push   %esi
  80021e:	53                   	push   %ebx
  80021f:	83 ec 1c             	sub    $0x1c,%esp
  800222:	89 c7                	mov    %eax,%edi
  800224:	89 d6                	mov    %edx,%esi
  800226:	8b 45 08             	mov    0x8(%ebp),%eax
  800229:	8b 55 0c             	mov    0xc(%ebp),%edx
  80022c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80022f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800232:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800235:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80023d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800240:	39 d3                	cmp    %edx,%ebx
  800242:	72 05                	jb     800249 <printnum+0x30>
  800244:	39 45 10             	cmp    %eax,0x10(%ebp)
  800247:	77 45                	ja     80028e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800249:	83 ec 0c             	sub    $0xc,%esp
  80024c:	ff 75 18             	pushl  0x18(%ebp)
  80024f:	8b 45 14             	mov    0x14(%ebp),%eax
  800252:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800255:	53                   	push   %ebx
  800256:	ff 75 10             	pushl  0x10(%ebp)
  800259:	83 ec 08             	sub    $0x8,%esp
  80025c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80025f:	ff 75 e0             	pushl  -0x20(%ebp)
  800262:	ff 75 dc             	pushl  -0x24(%ebp)
  800265:	ff 75 d8             	pushl  -0x28(%ebp)
  800268:	e8 13 09 00 00       	call   800b80 <__udivdi3>
  80026d:	83 c4 18             	add    $0x18,%esp
  800270:	52                   	push   %edx
  800271:	50                   	push   %eax
  800272:	89 f2                	mov    %esi,%edx
  800274:	89 f8                	mov    %edi,%eax
  800276:	e8 9e ff ff ff       	call   800219 <printnum>
  80027b:	83 c4 20             	add    $0x20,%esp
  80027e:	eb 18                	jmp    800298 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800280:	83 ec 08             	sub    $0x8,%esp
  800283:	56                   	push   %esi
  800284:	ff 75 18             	pushl  0x18(%ebp)
  800287:	ff d7                	call   *%edi
  800289:	83 c4 10             	add    $0x10,%esp
  80028c:	eb 03                	jmp    800291 <printnum+0x78>
  80028e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800291:	83 eb 01             	sub    $0x1,%ebx
  800294:	85 db                	test   %ebx,%ebx
  800296:	7f e8                	jg     800280 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800298:	83 ec 08             	sub    $0x8,%esp
  80029b:	56                   	push   %esi
  80029c:	83 ec 04             	sub    $0x4,%esp
  80029f:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a2:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a5:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a8:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ab:	e8 00 0a 00 00       	call   800cb0 <__umoddi3>
  8002b0:	83 c4 14             	add    $0x14,%esp
  8002b3:	0f be 80 7e 0e 80 00 	movsbl 0x800e7e(%eax),%eax
  8002ba:	50                   	push   %eax
  8002bb:	ff d7                	call   *%edi
}
  8002bd:	83 c4 10             	add    $0x10,%esp
  8002c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c3:	5b                   	pop    %ebx
  8002c4:	5e                   	pop    %esi
  8002c5:	5f                   	pop    %edi
  8002c6:	5d                   	pop    %ebp
  8002c7:	c3                   	ret    

008002c8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002c8:	55                   	push   %ebp
  8002c9:	89 e5                	mov    %esp,%ebp
  8002cb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ce:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002d2:	8b 10                	mov    (%eax),%edx
  8002d4:	3b 50 04             	cmp    0x4(%eax),%edx
  8002d7:	73 0a                	jae    8002e3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d9:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002dc:	89 08                	mov    %ecx,(%eax)
  8002de:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e1:	88 02                	mov    %al,(%edx)
}
  8002e3:	5d                   	pop    %ebp
  8002e4:	c3                   	ret    

008002e5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002e5:	55                   	push   %ebp
  8002e6:	89 e5                	mov    %esp,%ebp
  8002e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002eb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002ee:	50                   	push   %eax
  8002ef:	ff 75 10             	pushl  0x10(%ebp)
  8002f2:	ff 75 0c             	pushl  0xc(%ebp)
  8002f5:	ff 75 08             	pushl  0x8(%ebp)
  8002f8:	e8 05 00 00 00       	call   800302 <vprintfmt>
	va_end(ap);
}
  8002fd:	83 c4 10             	add    $0x10,%esp
  800300:	c9                   	leave  
  800301:	c3                   	ret    

00800302 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800302:	55                   	push   %ebp
  800303:	89 e5                	mov    %esp,%ebp
  800305:	57                   	push   %edi
  800306:	56                   	push   %esi
  800307:	53                   	push   %ebx
  800308:	83 ec 2c             	sub    $0x2c,%esp
  80030b:	8b 75 08             	mov    0x8(%ebp),%esi
  80030e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800311:	8b 7d 10             	mov    0x10(%ebp),%edi
  800314:	eb 12                	jmp    800328 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  800316:	85 c0                	test   %eax,%eax
  800318:	0f 84 6a 04 00 00    	je     800788 <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  80031e:	83 ec 08             	sub    $0x8,%esp
  800321:	53                   	push   %ebx
  800322:	50                   	push   %eax
  800323:	ff d6                	call   *%esi
  800325:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  800328:	83 c7 01             	add    $0x1,%edi
  80032b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80032f:	83 f8 25             	cmp    $0x25,%eax
  800332:	75 e2                	jne    800316 <vprintfmt+0x14>
  800334:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800338:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80033f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800346:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80034d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800352:	eb 07                	jmp    80035b <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800354:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  800357:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80035b:	8d 47 01             	lea    0x1(%edi),%eax
  80035e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800361:	0f b6 07             	movzbl (%edi),%eax
  800364:	0f b6 d0             	movzbl %al,%edx
  800367:	83 e8 23             	sub    $0x23,%eax
  80036a:	3c 55                	cmp    $0x55,%al
  80036c:	0f 87 fb 03 00 00    	ja     80076d <vprintfmt+0x46b>
  800372:	0f b6 c0             	movzbl %al,%eax
  800375:	ff 24 85 20 0f 80 00 	jmp    *0x800f20(,%eax,4)
  80037c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  80037f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800383:	eb d6                	jmp    80035b <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800385:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800388:	b8 00 00 00 00       	mov    $0x0,%eax
  80038d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800390:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800393:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800397:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  80039a:	8d 4a d0             	lea    -0x30(%edx),%ecx
  80039d:	83 f9 09             	cmp    $0x9,%ecx
  8003a0:	77 3f                	ja     8003e1 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  8003a2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003a5:	eb e9                	jmp    800390 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8b 00                	mov    (%eax),%eax
  8003ac:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003af:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b2:	8d 40 04             	lea    0x4(%eax),%eax
  8003b5:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003bb:	eb 2a                	jmp    8003e7 <vprintfmt+0xe5>
  8003bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003c0:	85 c0                	test   %eax,%eax
  8003c2:	ba 00 00 00 00       	mov    $0x0,%edx
  8003c7:	0f 49 d0             	cmovns %eax,%edx
  8003ca:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d0:	eb 89                	jmp    80035b <vprintfmt+0x59>
  8003d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003d5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003dc:	e9 7a ff ff ff       	jmp    80035b <vprintfmt+0x59>
  8003e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003e4:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003eb:	0f 89 6a ff ff ff    	jns    80035b <vprintfmt+0x59>
				width = precision, precision = -1;
  8003f1:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003f7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003fe:	e9 58 ff ff ff       	jmp    80035b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  800403:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800406:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  800409:	e9 4d ff ff ff       	jmp    80035b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  80040e:	8b 45 14             	mov    0x14(%ebp),%eax
  800411:	8d 78 04             	lea    0x4(%eax),%edi
  800414:	83 ec 08             	sub    $0x8,%esp
  800417:	53                   	push   %ebx
  800418:	ff 30                	pushl  (%eax)
  80041a:	ff d6                	call   *%esi
			break;
  80041c:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  80041f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800422:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  800425:	e9 fe fe ff ff       	jmp    800328 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80042a:	8b 45 14             	mov    0x14(%ebp),%eax
  80042d:	8d 78 04             	lea    0x4(%eax),%edi
  800430:	8b 00                	mov    (%eax),%eax
  800432:	99                   	cltd   
  800433:	31 d0                	xor    %edx,%eax
  800435:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800437:	83 f8 07             	cmp    $0x7,%eax
  80043a:	7f 0b                	jg     800447 <vprintfmt+0x145>
  80043c:	8b 14 85 80 10 80 00 	mov    0x801080(,%eax,4),%edx
  800443:	85 d2                	test   %edx,%edx
  800445:	75 1b                	jne    800462 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800447:	50                   	push   %eax
  800448:	68 96 0e 80 00       	push   $0x800e96
  80044d:	53                   	push   %ebx
  80044e:	56                   	push   %esi
  80044f:	e8 91 fe ff ff       	call   8002e5 <printfmt>
  800454:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800457:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80045a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80045d:	e9 c6 fe ff ff       	jmp    800328 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800462:	52                   	push   %edx
  800463:	68 9f 0e 80 00       	push   $0x800e9f
  800468:	53                   	push   %ebx
  800469:	56                   	push   %esi
  80046a:	e8 76 fe ff ff       	call   8002e5 <printfmt>
  80046f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800472:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800475:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800478:	e9 ab fe ff ff       	jmp    800328 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80047d:	8b 45 14             	mov    0x14(%ebp),%eax
  800480:	83 c0 04             	add    $0x4,%eax
  800483:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800486:	8b 45 14             	mov    0x14(%ebp),%eax
  800489:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80048b:	85 ff                	test   %edi,%edi
  80048d:	b8 8f 0e 80 00       	mov    $0x800e8f,%eax
  800492:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800495:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800499:	0f 8e 94 00 00 00    	jle    800533 <vprintfmt+0x231>
  80049f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004a3:	0f 84 98 00 00 00    	je     800541 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a9:	83 ec 08             	sub    $0x8,%esp
  8004ac:	ff 75 d0             	pushl  -0x30(%ebp)
  8004af:	57                   	push   %edi
  8004b0:	e8 5b 03 00 00       	call   800810 <strnlen>
  8004b5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004b8:	29 c1                	sub    %eax,%ecx
  8004ba:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004bd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004c0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004c4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004c7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ca:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cc:	eb 0f                	jmp    8004dd <vprintfmt+0x1db>
					putch(padc, putdat);
  8004ce:	83 ec 08             	sub    $0x8,%esp
  8004d1:	53                   	push   %ebx
  8004d2:	ff 75 e0             	pushl  -0x20(%ebp)
  8004d5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d7:	83 ef 01             	sub    $0x1,%edi
  8004da:	83 c4 10             	add    $0x10,%esp
  8004dd:	85 ff                	test   %edi,%edi
  8004df:	7f ed                	jg     8004ce <vprintfmt+0x1cc>
  8004e1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004e4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004e7:	85 c9                	test   %ecx,%ecx
  8004e9:	b8 00 00 00 00       	mov    $0x0,%eax
  8004ee:	0f 49 c1             	cmovns %ecx,%eax
  8004f1:	29 c1                	sub    %eax,%ecx
  8004f3:	89 75 08             	mov    %esi,0x8(%ebp)
  8004f6:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004fc:	89 cb                	mov    %ecx,%ebx
  8004fe:	eb 4d                	jmp    80054d <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800500:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800504:	74 1b                	je     800521 <vprintfmt+0x21f>
  800506:	0f be c0             	movsbl %al,%eax
  800509:	83 e8 20             	sub    $0x20,%eax
  80050c:	83 f8 5e             	cmp    $0x5e,%eax
  80050f:	76 10                	jbe    800521 <vprintfmt+0x21f>
					putch('?', putdat);
  800511:	83 ec 08             	sub    $0x8,%esp
  800514:	ff 75 0c             	pushl  0xc(%ebp)
  800517:	6a 3f                	push   $0x3f
  800519:	ff 55 08             	call   *0x8(%ebp)
  80051c:	83 c4 10             	add    $0x10,%esp
  80051f:	eb 0d                	jmp    80052e <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800521:	83 ec 08             	sub    $0x8,%esp
  800524:	ff 75 0c             	pushl  0xc(%ebp)
  800527:	52                   	push   %edx
  800528:	ff 55 08             	call   *0x8(%ebp)
  80052b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80052e:	83 eb 01             	sub    $0x1,%ebx
  800531:	eb 1a                	jmp    80054d <vprintfmt+0x24b>
  800533:	89 75 08             	mov    %esi,0x8(%ebp)
  800536:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800539:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80053f:	eb 0c                	jmp    80054d <vprintfmt+0x24b>
  800541:	89 75 08             	mov    %esi,0x8(%ebp)
  800544:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800547:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80054a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80054d:	83 c7 01             	add    $0x1,%edi
  800550:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800554:	0f be d0             	movsbl %al,%edx
  800557:	85 d2                	test   %edx,%edx
  800559:	74 23                	je     80057e <vprintfmt+0x27c>
  80055b:	85 f6                	test   %esi,%esi
  80055d:	78 a1                	js     800500 <vprintfmt+0x1fe>
  80055f:	83 ee 01             	sub    $0x1,%esi
  800562:	79 9c                	jns    800500 <vprintfmt+0x1fe>
  800564:	89 df                	mov    %ebx,%edi
  800566:	8b 75 08             	mov    0x8(%ebp),%esi
  800569:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80056c:	eb 18                	jmp    800586 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80056e:	83 ec 08             	sub    $0x8,%esp
  800571:	53                   	push   %ebx
  800572:	6a 20                	push   $0x20
  800574:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800576:	83 ef 01             	sub    $0x1,%edi
  800579:	83 c4 10             	add    $0x10,%esp
  80057c:	eb 08                	jmp    800586 <vprintfmt+0x284>
  80057e:	89 df                	mov    %ebx,%edi
  800580:	8b 75 08             	mov    0x8(%ebp),%esi
  800583:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800586:	85 ff                	test   %edi,%edi
  800588:	7f e4                	jg     80056e <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80058a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  80058d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800590:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800593:	e9 90 fd ff ff       	jmp    800328 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800598:	83 f9 01             	cmp    $0x1,%ecx
  80059b:	7e 19                	jle    8005b6 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  80059d:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a0:	8b 50 04             	mov    0x4(%eax),%edx
  8005a3:	8b 00                	mov    (%eax),%eax
  8005a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005ab:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ae:	8d 40 08             	lea    0x8(%eax),%eax
  8005b1:	89 45 14             	mov    %eax,0x14(%ebp)
  8005b4:	eb 38                	jmp    8005ee <vprintfmt+0x2ec>
	else if (lflag)
  8005b6:	85 c9                	test   %ecx,%ecx
  8005b8:	74 1b                	je     8005d5 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bd:	8b 00                	mov    (%eax),%eax
  8005bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c2:	89 c1                	mov    %eax,%ecx
  8005c4:	c1 f9 1f             	sar    $0x1f,%ecx
  8005c7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cd:	8d 40 04             	lea    0x4(%eax),%eax
  8005d0:	89 45 14             	mov    %eax,0x14(%ebp)
  8005d3:	eb 19                	jmp    8005ee <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d8:	8b 00                	mov    (%eax),%eax
  8005da:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005dd:	89 c1                	mov    %eax,%ecx
  8005df:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e8:	8d 40 04             	lea    0x4(%eax),%eax
  8005eb:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ee:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005f1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f4:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005fd:	0f 89 36 01 00 00    	jns    800739 <vprintfmt+0x437>
				putch('-', putdat);
  800603:	83 ec 08             	sub    $0x8,%esp
  800606:	53                   	push   %ebx
  800607:	6a 2d                	push   $0x2d
  800609:	ff d6                	call   *%esi
				num = -(long long) num;
  80060b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800611:	f7 da                	neg    %edx
  800613:	83 d1 00             	adc    $0x0,%ecx
  800616:	f7 d9                	neg    %ecx
  800618:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80061b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800620:	e9 14 01 00 00       	jmp    800739 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800625:	83 f9 01             	cmp    $0x1,%ecx
  800628:	7e 18                	jle    800642 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80062a:	8b 45 14             	mov    0x14(%ebp),%eax
  80062d:	8b 10                	mov    (%eax),%edx
  80062f:	8b 48 04             	mov    0x4(%eax),%ecx
  800632:	8d 40 08             	lea    0x8(%eax),%eax
  800635:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800638:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063d:	e9 f7 00 00 00       	jmp    800739 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800642:	85 c9                	test   %ecx,%ecx
  800644:	74 1a                	je     800660 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800646:	8b 45 14             	mov    0x14(%ebp),%eax
  800649:	8b 10                	mov    (%eax),%edx
  80064b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800650:	8d 40 04             	lea    0x4(%eax),%eax
  800653:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800656:	b8 0a 00 00 00       	mov    $0xa,%eax
  80065b:	e9 d9 00 00 00       	jmp    800739 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800660:	8b 45 14             	mov    0x14(%ebp),%eax
  800663:	8b 10                	mov    (%eax),%edx
  800665:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066a:	8d 40 04             	lea    0x4(%eax),%eax
  80066d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800670:	b8 0a 00 00 00       	mov    $0xa,%eax
  800675:	e9 bf 00 00 00       	jmp    800739 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80067a:	83 f9 01             	cmp    $0x1,%ecx
  80067d:	7e 13                	jle    800692 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  80067f:	8b 45 14             	mov    0x14(%ebp),%eax
  800682:	8b 50 04             	mov    0x4(%eax),%edx
  800685:	8b 00                	mov    (%eax),%eax
  800687:	8b 4d 14             	mov    0x14(%ebp),%ecx
  80068a:	8d 49 08             	lea    0x8(%ecx),%ecx
  80068d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800690:	eb 28                	jmp    8006ba <vprintfmt+0x3b8>
	else if (lflag)
  800692:	85 c9                	test   %ecx,%ecx
  800694:	74 13                	je     8006a9 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  800696:	8b 45 14             	mov    0x14(%ebp),%eax
  800699:	8b 10                	mov    (%eax),%edx
  80069b:	89 d0                	mov    %edx,%eax
  80069d:	99                   	cltd   
  80069e:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006a1:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006a4:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8006a7:	eb 11                	jmp    8006ba <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8006a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ac:	8b 10                	mov    (%eax),%edx
  8006ae:	89 d0                	mov    %edx,%eax
  8006b0:	99                   	cltd   
  8006b1:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006b4:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006b7:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8006ba:	89 d1                	mov    %edx,%ecx
  8006bc:	89 c2                	mov    %eax,%edx
			base = 8;
  8006be:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006c3:	eb 74                	jmp    800739 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8006c5:	83 ec 08             	sub    $0x8,%esp
  8006c8:	53                   	push   %ebx
  8006c9:	6a 30                	push   $0x30
  8006cb:	ff d6                	call   *%esi
			putch('x', putdat);
  8006cd:	83 c4 08             	add    $0x8,%esp
  8006d0:	53                   	push   %ebx
  8006d1:	6a 78                	push   $0x78
  8006d3:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d8:	8b 10                	mov    (%eax),%edx
  8006da:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006df:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006e2:	8d 40 04             	lea    0x4(%eax),%eax
  8006e5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006e8:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006ed:	eb 4a                	jmp    800739 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006ef:	83 f9 01             	cmp    $0x1,%ecx
  8006f2:	7e 15                	jle    800709 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  8006f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f7:	8b 10                	mov    (%eax),%edx
  8006f9:	8b 48 04             	mov    0x4(%eax),%ecx
  8006fc:	8d 40 08             	lea    0x8(%eax),%eax
  8006ff:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800702:	b8 10 00 00 00       	mov    $0x10,%eax
  800707:	eb 30                	jmp    800739 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800709:	85 c9                	test   %ecx,%ecx
  80070b:	74 17                	je     800724 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  80070d:	8b 45 14             	mov    0x14(%ebp),%eax
  800710:	8b 10                	mov    (%eax),%edx
  800712:	b9 00 00 00 00       	mov    $0x0,%ecx
  800717:	8d 40 04             	lea    0x4(%eax),%eax
  80071a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80071d:	b8 10 00 00 00       	mov    $0x10,%eax
  800722:	eb 15                	jmp    800739 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800724:	8b 45 14             	mov    0x14(%ebp),%eax
  800727:	8b 10                	mov    (%eax),%edx
  800729:	b9 00 00 00 00       	mov    $0x0,%ecx
  80072e:	8d 40 04             	lea    0x4(%eax),%eax
  800731:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800734:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800739:	83 ec 0c             	sub    $0xc,%esp
  80073c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800740:	57                   	push   %edi
  800741:	ff 75 e0             	pushl  -0x20(%ebp)
  800744:	50                   	push   %eax
  800745:	51                   	push   %ecx
  800746:	52                   	push   %edx
  800747:	89 da                	mov    %ebx,%edx
  800749:	89 f0                	mov    %esi,%eax
  80074b:	e8 c9 fa ff ff       	call   800219 <printnum>
			break;
  800750:	83 c4 20             	add    $0x20,%esp
  800753:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800756:	e9 cd fb ff ff       	jmp    800328 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80075b:	83 ec 08             	sub    $0x8,%esp
  80075e:	53                   	push   %ebx
  80075f:	52                   	push   %edx
  800760:	ff d6                	call   *%esi
			break;
  800762:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800765:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800768:	e9 bb fb ff ff       	jmp    800328 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80076d:	83 ec 08             	sub    $0x8,%esp
  800770:	53                   	push   %ebx
  800771:	6a 25                	push   $0x25
  800773:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800775:	83 c4 10             	add    $0x10,%esp
  800778:	eb 03                	jmp    80077d <vprintfmt+0x47b>
  80077a:	83 ef 01             	sub    $0x1,%edi
  80077d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800781:	75 f7                	jne    80077a <vprintfmt+0x478>
  800783:	e9 a0 fb ff ff       	jmp    800328 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800788:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80078b:	5b                   	pop    %ebx
  80078c:	5e                   	pop    %esi
  80078d:	5f                   	pop    %edi
  80078e:	5d                   	pop    %ebp
  80078f:	c3                   	ret    

00800790 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800790:	55                   	push   %ebp
  800791:	89 e5                	mov    %esp,%ebp
  800793:	83 ec 18             	sub    $0x18,%esp
  800796:	8b 45 08             	mov    0x8(%ebp),%eax
  800799:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80079c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80079f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007a3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007a6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007ad:	85 c0                	test   %eax,%eax
  8007af:	74 26                	je     8007d7 <vsnprintf+0x47>
  8007b1:	85 d2                	test   %edx,%edx
  8007b3:	7e 22                	jle    8007d7 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007b5:	ff 75 14             	pushl  0x14(%ebp)
  8007b8:	ff 75 10             	pushl  0x10(%ebp)
  8007bb:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007be:	50                   	push   %eax
  8007bf:	68 c8 02 80 00       	push   $0x8002c8
  8007c4:	e8 39 fb ff ff       	call   800302 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007cc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007d2:	83 c4 10             	add    $0x10,%esp
  8007d5:	eb 05                	jmp    8007dc <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007d7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007dc:	c9                   	leave  
  8007dd:	c3                   	ret    

008007de <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007de:	55                   	push   %ebp
  8007df:	89 e5                	mov    %esp,%ebp
  8007e1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007e4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007e7:	50                   	push   %eax
  8007e8:	ff 75 10             	pushl  0x10(%ebp)
  8007eb:	ff 75 0c             	pushl  0xc(%ebp)
  8007ee:	ff 75 08             	pushl  0x8(%ebp)
  8007f1:	e8 9a ff ff ff       	call   800790 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007f6:	c9                   	leave  
  8007f7:	c3                   	ret    

008007f8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007f8:	55                   	push   %ebp
  8007f9:	89 e5                	mov    %esp,%ebp
  8007fb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fe:	b8 00 00 00 00       	mov    $0x0,%eax
  800803:	eb 03                	jmp    800808 <strlen+0x10>
		n++;
  800805:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800808:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80080c:	75 f7                	jne    800805 <strlen+0xd>
		n++;
	return n;
}
  80080e:	5d                   	pop    %ebp
  80080f:	c3                   	ret    

00800810 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800810:	55                   	push   %ebp
  800811:	89 e5                	mov    %esp,%ebp
  800813:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800816:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800819:	ba 00 00 00 00       	mov    $0x0,%edx
  80081e:	eb 03                	jmp    800823 <strnlen+0x13>
		n++;
  800820:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800823:	39 c2                	cmp    %eax,%edx
  800825:	74 08                	je     80082f <strnlen+0x1f>
  800827:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80082b:	75 f3                	jne    800820 <strnlen+0x10>
  80082d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80082f:	5d                   	pop    %ebp
  800830:	c3                   	ret    

00800831 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800831:	55                   	push   %ebp
  800832:	89 e5                	mov    %esp,%ebp
  800834:	53                   	push   %ebx
  800835:	8b 45 08             	mov    0x8(%ebp),%eax
  800838:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80083b:	89 c2                	mov    %eax,%edx
  80083d:	83 c2 01             	add    $0x1,%edx
  800840:	83 c1 01             	add    $0x1,%ecx
  800843:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800847:	88 5a ff             	mov    %bl,-0x1(%edx)
  80084a:	84 db                	test   %bl,%bl
  80084c:	75 ef                	jne    80083d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80084e:	5b                   	pop    %ebx
  80084f:	5d                   	pop    %ebp
  800850:	c3                   	ret    

00800851 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800851:	55                   	push   %ebp
  800852:	89 e5                	mov    %esp,%ebp
  800854:	53                   	push   %ebx
  800855:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800858:	53                   	push   %ebx
  800859:	e8 9a ff ff ff       	call   8007f8 <strlen>
  80085e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800861:	ff 75 0c             	pushl  0xc(%ebp)
  800864:	01 d8                	add    %ebx,%eax
  800866:	50                   	push   %eax
  800867:	e8 c5 ff ff ff       	call   800831 <strcpy>
	return dst;
}
  80086c:	89 d8                	mov    %ebx,%eax
  80086e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800871:	c9                   	leave  
  800872:	c3                   	ret    

00800873 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800873:	55                   	push   %ebp
  800874:	89 e5                	mov    %esp,%ebp
  800876:	56                   	push   %esi
  800877:	53                   	push   %ebx
  800878:	8b 75 08             	mov    0x8(%ebp),%esi
  80087b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80087e:	89 f3                	mov    %esi,%ebx
  800880:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800883:	89 f2                	mov    %esi,%edx
  800885:	eb 0f                	jmp    800896 <strncpy+0x23>
		*dst++ = *src;
  800887:	83 c2 01             	add    $0x1,%edx
  80088a:	0f b6 01             	movzbl (%ecx),%eax
  80088d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800890:	80 39 01             	cmpb   $0x1,(%ecx)
  800893:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800896:	39 da                	cmp    %ebx,%edx
  800898:	75 ed                	jne    800887 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80089a:	89 f0                	mov    %esi,%eax
  80089c:	5b                   	pop    %ebx
  80089d:	5e                   	pop    %esi
  80089e:	5d                   	pop    %ebp
  80089f:	c3                   	ret    

008008a0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008a0:	55                   	push   %ebp
  8008a1:	89 e5                	mov    %esp,%ebp
  8008a3:	56                   	push   %esi
  8008a4:	53                   	push   %ebx
  8008a5:	8b 75 08             	mov    0x8(%ebp),%esi
  8008a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008ab:	8b 55 10             	mov    0x10(%ebp),%edx
  8008ae:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008b0:	85 d2                	test   %edx,%edx
  8008b2:	74 21                	je     8008d5 <strlcpy+0x35>
  8008b4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008b8:	89 f2                	mov    %esi,%edx
  8008ba:	eb 09                	jmp    8008c5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008bc:	83 c2 01             	add    $0x1,%edx
  8008bf:	83 c1 01             	add    $0x1,%ecx
  8008c2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008c5:	39 c2                	cmp    %eax,%edx
  8008c7:	74 09                	je     8008d2 <strlcpy+0x32>
  8008c9:	0f b6 19             	movzbl (%ecx),%ebx
  8008cc:	84 db                	test   %bl,%bl
  8008ce:	75 ec                	jne    8008bc <strlcpy+0x1c>
  8008d0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008d2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008d5:	29 f0                	sub    %esi,%eax
}
  8008d7:	5b                   	pop    %ebx
  8008d8:	5e                   	pop    %esi
  8008d9:	5d                   	pop    %ebp
  8008da:	c3                   	ret    

008008db <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008db:	55                   	push   %ebp
  8008dc:	89 e5                	mov    %esp,%ebp
  8008de:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008e4:	eb 06                	jmp    8008ec <strcmp+0x11>
		p++, q++;
  8008e6:	83 c1 01             	add    $0x1,%ecx
  8008e9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008ec:	0f b6 01             	movzbl (%ecx),%eax
  8008ef:	84 c0                	test   %al,%al
  8008f1:	74 04                	je     8008f7 <strcmp+0x1c>
  8008f3:	3a 02                	cmp    (%edx),%al
  8008f5:	74 ef                	je     8008e6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008f7:	0f b6 c0             	movzbl %al,%eax
  8008fa:	0f b6 12             	movzbl (%edx),%edx
  8008fd:	29 d0                	sub    %edx,%eax
}
  8008ff:	5d                   	pop    %ebp
  800900:	c3                   	ret    

00800901 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800901:	55                   	push   %ebp
  800902:	89 e5                	mov    %esp,%ebp
  800904:	53                   	push   %ebx
  800905:	8b 45 08             	mov    0x8(%ebp),%eax
  800908:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090b:	89 c3                	mov    %eax,%ebx
  80090d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800910:	eb 06                	jmp    800918 <strncmp+0x17>
		n--, p++, q++;
  800912:	83 c0 01             	add    $0x1,%eax
  800915:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800918:	39 d8                	cmp    %ebx,%eax
  80091a:	74 15                	je     800931 <strncmp+0x30>
  80091c:	0f b6 08             	movzbl (%eax),%ecx
  80091f:	84 c9                	test   %cl,%cl
  800921:	74 04                	je     800927 <strncmp+0x26>
  800923:	3a 0a                	cmp    (%edx),%cl
  800925:	74 eb                	je     800912 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800927:	0f b6 00             	movzbl (%eax),%eax
  80092a:	0f b6 12             	movzbl (%edx),%edx
  80092d:	29 d0                	sub    %edx,%eax
  80092f:	eb 05                	jmp    800936 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800931:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800936:	5b                   	pop    %ebx
  800937:	5d                   	pop    %ebp
  800938:	c3                   	ret    

00800939 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800939:	55                   	push   %ebp
  80093a:	89 e5                	mov    %esp,%ebp
  80093c:	8b 45 08             	mov    0x8(%ebp),%eax
  80093f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800943:	eb 07                	jmp    80094c <strchr+0x13>
		if (*s == c)
  800945:	38 ca                	cmp    %cl,%dl
  800947:	74 0f                	je     800958 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800949:	83 c0 01             	add    $0x1,%eax
  80094c:	0f b6 10             	movzbl (%eax),%edx
  80094f:	84 d2                	test   %dl,%dl
  800951:	75 f2                	jne    800945 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800953:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800958:	5d                   	pop    %ebp
  800959:	c3                   	ret    

0080095a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80095a:	55                   	push   %ebp
  80095b:	89 e5                	mov    %esp,%ebp
  80095d:	8b 45 08             	mov    0x8(%ebp),%eax
  800960:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800964:	eb 03                	jmp    800969 <strfind+0xf>
  800966:	83 c0 01             	add    $0x1,%eax
  800969:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80096c:	38 ca                	cmp    %cl,%dl
  80096e:	74 04                	je     800974 <strfind+0x1a>
  800970:	84 d2                	test   %dl,%dl
  800972:	75 f2                	jne    800966 <strfind+0xc>
			break;
	return (char *) s;
}
  800974:	5d                   	pop    %ebp
  800975:	c3                   	ret    

00800976 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800976:	55                   	push   %ebp
  800977:	89 e5                	mov    %esp,%ebp
  800979:	57                   	push   %edi
  80097a:	56                   	push   %esi
  80097b:	53                   	push   %ebx
  80097c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80097f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800982:	85 c9                	test   %ecx,%ecx
  800984:	74 36                	je     8009bc <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800986:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80098c:	75 28                	jne    8009b6 <memset+0x40>
  80098e:	f6 c1 03             	test   $0x3,%cl
  800991:	75 23                	jne    8009b6 <memset+0x40>
		c &= 0xFF;
  800993:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800997:	89 d3                	mov    %edx,%ebx
  800999:	c1 e3 08             	shl    $0x8,%ebx
  80099c:	89 d6                	mov    %edx,%esi
  80099e:	c1 e6 18             	shl    $0x18,%esi
  8009a1:	89 d0                	mov    %edx,%eax
  8009a3:	c1 e0 10             	shl    $0x10,%eax
  8009a6:	09 f0                	or     %esi,%eax
  8009a8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009aa:	89 d8                	mov    %ebx,%eax
  8009ac:	09 d0                	or     %edx,%eax
  8009ae:	c1 e9 02             	shr    $0x2,%ecx
  8009b1:	fc                   	cld    
  8009b2:	f3 ab                	rep stos %eax,%es:(%edi)
  8009b4:	eb 06                	jmp    8009bc <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009b9:	fc                   	cld    
  8009ba:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009bc:	89 f8                	mov    %edi,%eax
  8009be:	5b                   	pop    %ebx
  8009bf:	5e                   	pop    %esi
  8009c0:	5f                   	pop    %edi
  8009c1:	5d                   	pop    %ebp
  8009c2:	c3                   	ret    

008009c3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009c3:	55                   	push   %ebp
  8009c4:	89 e5                	mov    %esp,%ebp
  8009c6:	57                   	push   %edi
  8009c7:	56                   	push   %esi
  8009c8:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cb:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009ce:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009d1:	39 c6                	cmp    %eax,%esi
  8009d3:	73 35                	jae    800a0a <memmove+0x47>
  8009d5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009d8:	39 d0                	cmp    %edx,%eax
  8009da:	73 2e                	jae    800a0a <memmove+0x47>
		s += n;
		d += n;
  8009dc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009df:	89 d6                	mov    %edx,%esi
  8009e1:	09 fe                	or     %edi,%esi
  8009e3:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009e9:	75 13                	jne    8009fe <memmove+0x3b>
  8009eb:	f6 c1 03             	test   $0x3,%cl
  8009ee:	75 0e                	jne    8009fe <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009f0:	83 ef 04             	sub    $0x4,%edi
  8009f3:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009f6:	c1 e9 02             	shr    $0x2,%ecx
  8009f9:	fd                   	std    
  8009fa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009fc:	eb 09                	jmp    800a07 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009fe:	83 ef 01             	sub    $0x1,%edi
  800a01:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a04:	fd                   	std    
  800a05:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a07:	fc                   	cld    
  800a08:	eb 1d                	jmp    800a27 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a0a:	89 f2                	mov    %esi,%edx
  800a0c:	09 c2                	or     %eax,%edx
  800a0e:	f6 c2 03             	test   $0x3,%dl
  800a11:	75 0f                	jne    800a22 <memmove+0x5f>
  800a13:	f6 c1 03             	test   $0x3,%cl
  800a16:	75 0a                	jne    800a22 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a18:	c1 e9 02             	shr    $0x2,%ecx
  800a1b:	89 c7                	mov    %eax,%edi
  800a1d:	fc                   	cld    
  800a1e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a20:	eb 05                	jmp    800a27 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a22:	89 c7                	mov    %eax,%edi
  800a24:	fc                   	cld    
  800a25:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a27:	5e                   	pop    %esi
  800a28:	5f                   	pop    %edi
  800a29:	5d                   	pop    %ebp
  800a2a:	c3                   	ret    

00800a2b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a2b:	55                   	push   %ebp
  800a2c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a2e:	ff 75 10             	pushl  0x10(%ebp)
  800a31:	ff 75 0c             	pushl  0xc(%ebp)
  800a34:	ff 75 08             	pushl  0x8(%ebp)
  800a37:	e8 87 ff ff ff       	call   8009c3 <memmove>
}
  800a3c:	c9                   	leave  
  800a3d:	c3                   	ret    

00800a3e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a3e:	55                   	push   %ebp
  800a3f:	89 e5                	mov    %esp,%ebp
  800a41:	56                   	push   %esi
  800a42:	53                   	push   %ebx
  800a43:	8b 45 08             	mov    0x8(%ebp),%eax
  800a46:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a49:	89 c6                	mov    %eax,%esi
  800a4b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a4e:	eb 1a                	jmp    800a6a <memcmp+0x2c>
		if (*s1 != *s2)
  800a50:	0f b6 08             	movzbl (%eax),%ecx
  800a53:	0f b6 1a             	movzbl (%edx),%ebx
  800a56:	38 d9                	cmp    %bl,%cl
  800a58:	74 0a                	je     800a64 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a5a:	0f b6 c1             	movzbl %cl,%eax
  800a5d:	0f b6 db             	movzbl %bl,%ebx
  800a60:	29 d8                	sub    %ebx,%eax
  800a62:	eb 0f                	jmp    800a73 <memcmp+0x35>
		s1++, s2++;
  800a64:	83 c0 01             	add    $0x1,%eax
  800a67:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a6a:	39 f0                	cmp    %esi,%eax
  800a6c:	75 e2                	jne    800a50 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a73:	5b                   	pop    %ebx
  800a74:	5e                   	pop    %esi
  800a75:	5d                   	pop    %ebp
  800a76:	c3                   	ret    

00800a77 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a77:	55                   	push   %ebp
  800a78:	89 e5                	mov    %esp,%ebp
  800a7a:	53                   	push   %ebx
  800a7b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a7e:	89 c1                	mov    %eax,%ecx
  800a80:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a83:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a87:	eb 0a                	jmp    800a93 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a89:	0f b6 10             	movzbl (%eax),%edx
  800a8c:	39 da                	cmp    %ebx,%edx
  800a8e:	74 07                	je     800a97 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a90:	83 c0 01             	add    $0x1,%eax
  800a93:	39 c8                	cmp    %ecx,%eax
  800a95:	72 f2                	jb     800a89 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a97:	5b                   	pop    %ebx
  800a98:	5d                   	pop    %ebp
  800a99:	c3                   	ret    

00800a9a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a9a:	55                   	push   %ebp
  800a9b:	89 e5                	mov    %esp,%ebp
  800a9d:	57                   	push   %edi
  800a9e:	56                   	push   %esi
  800a9f:	53                   	push   %ebx
  800aa0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800aa3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa6:	eb 03                	jmp    800aab <strtol+0x11>
		s++;
  800aa8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aab:	0f b6 01             	movzbl (%ecx),%eax
  800aae:	3c 20                	cmp    $0x20,%al
  800ab0:	74 f6                	je     800aa8 <strtol+0xe>
  800ab2:	3c 09                	cmp    $0x9,%al
  800ab4:	74 f2                	je     800aa8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ab6:	3c 2b                	cmp    $0x2b,%al
  800ab8:	75 0a                	jne    800ac4 <strtol+0x2a>
		s++;
  800aba:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800abd:	bf 00 00 00 00       	mov    $0x0,%edi
  800ac2:	eb 11                	jmp    800ad5 <strtol+0x3b>
  800ac4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ac9:	3c 2d                	cmp    $0x2d,%al
  800acb:	75 08                	jne    800ad5 <strtol+0x3b>
		s++, neg = 1;
  800acd:	83 c1 01             	add    $0x1,%ecx
  800ad0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ad5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800adb:	75 15                	jne    800af2 <strtol+0x58>
  800add:	80 39 30             	cmpb   $0x30,(%ecx)
  800ae0:	75 10                	jne    800af2 <strtol+0x58>
  800ae2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ae6:	75 7c                	jne    800b64 <strtol+0xca>
		s += 2, base = 16;
  800ae8:	83 c1 02             	add    $0x2,%ecx
  800aeb:	bb 10 00 00 00       	mov    $0x10,%ebx
  800af0:	eb 16                	jmp    800b08 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800af2:	85 db                	test   %ebx,%ebx
  800af4:	75 12                	jne    800b08 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800af6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800afb:	80 39 30             	cmpb   $0x30,(%ecx)
  800afe:	75 08                	jne    800b08 <strtol+0x6e>
		s++, base = 8;
  800b00:	83 c1 01             	add    $0x1,%ecx
  800b03:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b08:	b8 00 00 00 00       	mov    $0x0,%eax
  800b0d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b10:	0f b6 11             	movzbl (%ecx),%edx
  800b13:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b16:	89 f3                	mov    %esi,%ebx
  800b18:	80 fb 09             	cmp    $0x9,%bl
  800b1b:	77 08                	ja     800b25 <strtol+0x8b>
			dig = *s - '0';
  800b1d:	0f be d2             	movsbl %dl,%edx
  800b20:	83 ea 30             	sub    $0x30,%edx
  800b23:	eb 22                	jmp    800b47 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b25:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b28:	89 f3                	mov    %esi,%ebx
  800b2a:	80 fb 19             	cmp    $0x19,%bl
  800b2d:	77 08                	ja     800b37 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b2f:	0f be d2             	movsbl %dl,%edx
  800b32:	83 ea 57             	sub    $0x57,%edx
  800b35:	eb 10                	jmp    800b47 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b37:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b3a:	89 f3                	mov    %esi,%ebx
  800b3c:	80 fb 19             	cmp    $0x19,%bl
  800b3f:	77 16                	ja     800b57 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b41:	0f be d2             	movsbl %dl,%edx
  800b44:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b47:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b4a:	7d 0b                	jge    800b57 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b4c:	83 c1 01             	add    $0x1,%ecx
  800b4f:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b53:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b55:	eb b9                	jmp    800b10 <strtol+0x76>

	if (endptr)
  800b57:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b5b:	74 0d                	je     800b6a <strtol+0xd0>
		*endptr = (char *) s;
  800b5d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b60:	89 0e                	mov    %ecx,(%esi)
  800b62:	eb 06                	jmp    800b6a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b64:	85 db                	test   %ebx,%ebx
  800b66:	74 98                	je     800b00 <strtol+0x66>
  800b68:	eb 9e                	jmp    800b08 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b6a:	89 c2                	mov    %eax,%edx
  800b6c:	f7 da                	neg    %edx
  800b6e:	85 ff                	test   %edi,%edi
  800b70:	0f 45 c2             	cmovne %edx,%eax
}
  800b73:	5b                   	pop    %ebx
  800b74:	5e                   	pop    %esi
  800b75:	5f                   	pop    %edi
  800b76:	5d                   	pop    %ebp
  800b77:	c3                   	ret    
  800b78:	66 90                	xchg   %ax,%ax
  800b7a:	66 90                	xchg   %ax,%ax
  800b7c:	66 90                	xchg   %ax,%ax
  800b7e:	66 90                	xchg   %ax,%ax

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
