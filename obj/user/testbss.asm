
obj/user/testbss:     file format elf32-i386


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
  80002c:	e8 ab 00 00 00       	call   8000dc <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	68 a0 0e 80 00       	push   $0x800ea0
  80003e:	e8 ba 01 00 00       	call   8001fd <cprintf>
  800043:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 12                	je     800067 <umain+0x34>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	50                   	push   %eax
  800056:	68 1b 0f 80 00       	push   $0x800f1b
  80005b:	6a 11                	push   $0x11
  80005d:	68 38 0f 80 00       	push   $0x800f38
  800062:	e8 bd 00 00 00       	call   800124 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800067:	83 c0 01             	add    $0x1,%eax
  80006a:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80006f:	75 da                	jne    80004b <umain+0x18>
  800071:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800076:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80007d:	83 c0 01             	add    $0x1,%eax
  800080:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800085:	75 ef                	jne    800076 <umain+0x43>
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  80008c:	3b 04 85 20 20 80 00 	cmp    0x802020(,%eax,4),%eax
  800093:	74 12                	je     8000a7 <umain+0x74>
			panic("bigarray[%d] didn't hold its value!\n", i);
  800095:	50                   	push   %eax
  800096:	68 c0 0e 80 00       	push   $0x800ec0
  80009b:	6a 16                	push   $0x16
  80009d:	68 38 0f 80 00       	push   $0x800f38
  8000a2:	e8 7d 00 00 00       	call   800124 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000a7:	83 c0 01             	add    $0x1,%eax
  8000aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000af:	75 db                	jne    80008c <umain+0x59>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000b1:	83 ec 0c             	sub    $0xc,%esp
  8000b4:	68 e8 0e 80 00       	push   $0x800ee8
  8000b9:	e8 3f 01 00 00       	call   8001fd <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000be:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000c5:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000c8:	83 c4 0c             	add    $0xc,%esp
  8000cb:	68 47 0f 80 00       	push   $0x800f47
  8000d0:	6a 1a                	push   $0x1a
  8000d2:	68 38 0f 80 00       	push   $0x800f38
  8000d7:	e8 48 00 00 00       	call   800124 <_panic>

008000dc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	83 ec 08             	sub    $0x8,%esp
  8000e2:	8b 45 08             	mov    0x8(%ebp),%eax
  8000e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  8000e8:	c7 05 20 20 c0 00 00 	movl   $0x0,0xc02020
  8000ef:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000f2:	85 c0                	test   %eax,%eax
  8000f4:	7e 08                	jle    8000fe <libmain+0x22>
		binaryname = argv[0];
  8000f6:	8b 0a                	mov    (%edx),%ecx
  8000f8:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  8000fe:	83 ec 08             	sub    $0x8,%esp
  800101:	52                   	push   %edx
  800102:	50                   	push   %eax
  800103:	e8 2b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800108:	e8 05 00 00 00       	call   800112 <exit>
}
  80010d:	83 c4 10             	add    $0x10,%esp
  800110:	c9                   	leave  
  800111:	c3                   	ret    

00800112 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800118:	6a 00                	push   $0x0
  80011a:	e8 8e 0a 00 00       	call   800bad <sys_env_destroy>
}
  80011f:	83 c4 10             	add    $0x10,%esp
  800122:	c9                   	leave  
  800123:	c3                   	ret    

00800124 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800124:	55                   	push   %ebp
  800125:	89 e5                	mov    %esp,%ebp
  800127:	56                   	push   %esi
  800128:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800129:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80012c:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800132:	e8 b7 0a 00 00       	call   800bee <sys_getenvid>
  800137:	83 ec 0c             	sub    $0xc,%esp
  80013a:	ff 75 0c             	pushl  0xc(%ebp)
  80013d:	ff 75 08             	pushl  0x8(%ebp)
  800140:	56                   	push   %esi
  800141:	50                   	push   %eax
  800142:	68 68 0f 80 00       	push   $0x800f68
  800147:	e8 b1 00 00 00       	call   8001fd <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80014c:	83 c4 18             	add    $0x18,%esp
  80014f:	53                   	push   %ebx
  800150:	ff 75 10             	pushl  0x10(%ebp)
  800153:	e8 54 00 00 00       	call   8001ac <vcprintf>
	cprintf("\n");
  800158:	c7 04 24 36 0f 80 00 	movl   $0x800f36,(%esp)
  80015f:	e8 99 00 00 00       	call   8001fd <cprintf>
  800164:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800167:	cc                   	int3   
  800168:	eb fd                	jmp    800167 <_panic+0x43>

0080016a <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80016a:	55                   	push   %ebp
  80016b:	89 e5                	mov    %esp,%ebp
  80016d:	53                   	push   %ebx
  80016e:	83 ec 04             	sub    $0x4,%esp
  800171:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800174:	8b 13                	mov    (%ebx),%edx
  800176:	8d 42 01             	lea    0x1(%edx),%eax
  800179:	89 03                	mov    %eax,(%ebx)
  80017b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80017e:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800182:	3d ff 00 00 00       	cmp    $0xff,%eax
  800187:	75 1a                	jne    8001a3 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800189:	83 ec 08             	sub    $0x8,%esp
  80018c:	68 ff 00 00 00       	push   $0xff
  800191:	8d 43 08             	lea    0x8(%ebx),%eax
  800194:	50                   	push   %eax
  800195:	e8 d6 09 00 00       	call   800b70 <sys_cputs>
		b->idx = 0;
  80019a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a0:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001a3:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001aa:	c9                   	leave  
  8001ab:	c3                   	ret    

008001ac <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ac:	55                   	push   %ebp
  8001ad:	89 e5                	mov    %esp,%ebp
  8001af:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001bc:	00 00 00 
	b.cnt = 0;
  8001bf:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c6:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c9:	ff 75 0c             	pushl  0xc(%ebp)
  8001cc:	ff 75 08             	pushl  0x8(%ebp)
  8001cf:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d5:	50                   	push   %eax
  8001d6:	68 6a 01 80 00       	push   $0x80016a
  8001db:	e8 1a 01 00 00       	call   8002fa <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e0:	83 c4 08             	add    $0x8,%esp
  8001e3:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e9:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ef:	50                   	push   %eax
  8001f0:	e8 7b 09 00 00       	call   800b70 <sys_cputs>

	return b.cnt;
}
  8001f5:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001fb:	c9                   	leave  
  8001fc:	c3                   	ret    

008001fd <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001fd:	55                   	push   %ebp
  8001fe:	89 e5                	mov    %esp,%ebp
  800200:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800203:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800206:	50                   	push   %eax
  800207:	ff 75 08             	pushl  0x8(%ebp)
  80020a:	e8 9d ff ff ff       	call   8001ac <vcprintf>
	va_end(ap);

	return cnt;
}
  80020f:	c9                   	leave  
  800210:	c3                   	ret    

00800211 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
  800214:	57                   	push   %edi
  800215:	56                   	push   %esi
  800216:	53                   	push   %ebx
  800217:	83 ec 1c             	sub    $0x1c,%esp
  80021a:	89 c7                	mov    %eax,%edi
  80021c:	89 d6                	mov    %edx,%esi
  80021e:	8b 45 08             	mov    0x8(%ebp),%eax
  800221:	8b 55 0c             	mov    0xc(%ebp),%edx
  800224:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800227:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80022a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80022d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800232:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800235:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800238:	39 d3                	cmp    %edx,%ebx
  80023a:	72 05                	jb     800241 <printnum+0x30>
  80023c:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023f:	77 45                	ja     800286 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800241:	83 ec 0c             	sub    $0xc,%esp
  800244:	ff 75 18             	pushl  0x18(%ebp)
  800247:	8b 45 14             	mov    0x14(%ebp),%eax
  80024a:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80024d:	53                   	push   %ebx
  80024e:	ff 75 10             	pushl  0x10(%ebp)
  800251:	83 ec 08             	sub    $0x8,%esp
  800254:	ff 75 e4             	pushl  -0x1c(%ebp)
  800257:	ff 75 e0             	pushl  -0x20(%ebp)
  80025a:	ff 75 dc             	pushl  -0x24(%ebp)
  80025d:	ff 75 d8             	pushl  -0x28(%ebp)
  800260:	e8 ab 09 00 00       	call   800c10 <__udivdi3>
  800265:	83 c4 18             	add    $0x18,%esp
  800268:	52                   	push   %edx
  800269:	50                   	push   %eax
  80026a:	89 f2                	mov    %esi,%edx
  80026c:	89 f8                	mov    %edi,%eax
  80026e:	e8 9e ff ff ff       	call   800211 <printnum>
  800273:	83 c4 20             	add    $0x20,%esp
  800276:	eb 18                	jmp    800290 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800278:	83 ec 08             	sub    $0x8,%esp
  80027b:	56                   	push   %esi
  80027c:	ff 75 18             	pushl  0x18(%ebp)
  80027f:	ff d7                	call   *%edi
  800281:	83 c4 10             	add    $0x10,%esp
  800284:	eb 03                	jmp    800289 <printnum+0x78>
  800286:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800289:	83 eb 01             	sub    $0x1,%ebx
  80028c:	85 db                	test   %ebx,%ebx
  80028e:	7f e8                	jg     800278 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800290:	83 ec 08             	sub    $0x8,%esp
  800293:	56                   	push   %esi
  800294:	83 ec 04             	sub    $0x4,%esp
  800297:	ff 75 e4             	pushl  -0x1c(%ebp)
  80029a:	ff 75 e0             	pushl  -0x20(%ebp)
  80029d:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a0:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a3:	e8 98 0a 00 00       	call   800d40 <__umoddi3>
  8002a8:	83 c4 14             	add    $0x14,%esp
  8002ab:	0f be 80 8c 0f 80 00 	movsbl 0x800f8c(%eax),%eax
  8002b2:	50                   	push   %eax
  8002b3:	ff d7                	call   *%edi
}
  8002b5:	83 c4 10             	add    $0x10,%esp
  8002b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002bb:	5b                   	pop    %ebx
  8002bc:	5e                   	pop    %esi
  8002bd:	5f                   	pop    %edi
  8002be:	5d                   	pop    %ebp
  8002bf:	c3                   	ret    

008002c0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002c0:	55                   	push   %ebp
  8002c1:	89 e5                	mov    %esp,%ebp
  8002c3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002c6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002ca:	8b 10                	mov    (%eax),%edx
  8002cc:	3b 50 04             	cmp    0x4(%eax),%edx
  8002cf:	73 0a                	jae    8002db <sprintputch+0x1b>
		*b->buf++ = ch;
  8002d1:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002d4:	89 08                	mov    %ecx,(%eax)
  8002d6:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d9:	88 02                	mov    %al,(%edx)
}
  8002db:	5d                   	pop    %ebp
  8002dc:	c3                   	ret    

008002dd <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002dd:	55                   	push   %ebp
  8002de:	89 e5                	mov    %esp,%ebp
  8002e0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002e3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002e6:	50                   	push   %eax
  8002e7:	ff 75 10             	pushl  0x10(%ebp)
  8002ea:	ff 75 0c             	pushl  0xc(%ebp)
  8002ed:	ff 75 08             	pushl  0x8(%ebp)
  8002f0:	e8 05 00 00 00       	call   8002fa <vprintfmt>
	va_end(ap);
}
  8002f5:	83 c4 10             	add    $0x10,%esp
  8002f8:	c9                   	leave  
  8002f9:	c3                   	ret    

008002fa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002fa:	55                   	push   %ebp
  8002fb:	89 e5                	mov    %esp,%ebp
  8002fd:	57                   	push   %edi
  8002fe:	56                   	push   %esi
  8002ff:	53                   	push   %ebx
  800300:	83 ec 2c             	sub    $0x2c,%esp
  800303:	8b 75 08             	mov    0x8(%ebp),%esi
  800306:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800309:	8b 7d 10             	mov    0x10(%ebp),%edi
  80030c:	eb 12                	jmp    800320 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80030e:	85 c0                	test   %eax,%eax
  800310:	0f 84 6a 04 00 00    	je     800780 <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800316:	83 ec 08             	sub    $0x8,%esp
  800319:	53                   	push   %ebx
  80031a:	50                   	push   %eax
  80031b:	ff d6                	call   *%esi
  80031d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  800320:	83 c7 01             	add    $0x1,%edi
  800323:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800327:	83 f8 25             	cmp    $0x25,%eax
  80032a:	75 e2                	jne    80030e <vprintfmt+0x14>
  80032c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800330:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800337:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80033e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800345:	b9 00 00 00 00       	mov    $0x0,%ecx
  80034a:	eb 07                	jmp    800353 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80034c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80034f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800353:	8d 47 01             	lea    0x1(%edi),%eax
  800356:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800359:	0f b6 07             	movzbl (%edi),%eax
  80035c:	0f b6 d0             	movzbl %al,%edx
  80035f:	83 e8 23             	sub    $0x23,%eax
  800362:	3c 55                	cmp    $0x55,%al
  800364:	0f 87 fb 03 00 00    	ja     800765 <vprintfmt+0x46b>
  80036a:	0f b6 c0             	movzbl %al,%eax
  80036d:	ff 24 85 20 10 80 00 	jmp    *0x801020(,%eax,4)
  800374:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  800377:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80037b:	eb d6                	jmp    800353 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80037d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800380:	b8 00 00 00 00       	mov    $0x0,%eax
  800385:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800388:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80038b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80038f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800392:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800395:	83 f9 09             	cmp    $0x9,%ecx
  800398:	77 3f                	ja     8003d9 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  80039a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80039d:	eb e9                	jmp    800388 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80039f:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a2:	8b 00                	mov    (%eax),%eax
  8003a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8d 40 04             	lea    0x4(%eax),%eax
  8003ad:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003b3:	eb 2a                	jmp    8003df <vprintfmt+0xe5>
  8003b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003b8:	85 c0                	test   %eax,%eax
  8003ba:	ba 00 00 00 00       	mov    $0x0,%edx
  8003bf:	0f 49 d0             	cmovns %eax,%edx
  8003c2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c8:	eb 89                	jmp    800353 <vprintfmt+0x59>
  8003ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003cd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003d4:	e9 7a ff ff ff       	jmp    800353 <vprintfmt+0x59>
  8003d9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003dc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003df:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003e3:	0f 89 6a ff ff ff    	jns    800353 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003e9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003ec:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003ef:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003f6:	e9 58 ff ff ff       	jmp    800353 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  8003fb:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  800401:	e9 4d ff ff ff       	jmp    800353 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800406:	8b 45 14             	mov    0x14(%ebp),%eax
  800409:	8d 78 04             	lea    0x4(%eax),%edi
  80040c:	83 ec 08             	sub    $0x8,%esp
  80040f:	53                   	push   %ebx
  800410:	ff 30                	pushl  (%eax)
  800412:	ff d6                	call   *%esi
			break;
  800414:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800417:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80041a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  80041d:	e9 fe fe ff ff       	jmp    800320 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800422:	8b 45 14             	mov    0x14(%ebp),%eax
  800425:	8d 78 04             	lea    0x4(%eax),%edi
  800428:	8b 00                	mov    (%eax),%eax
  80042a:	99                   	cltd   
  80042b:	31 d0                	xor    %edx,%eax
  80042d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80042f:	83 f8 07             	cmp    $0x7,%eax
  800432:	7f 0b                	jg     80043f <vprintfmt+0x145>
  800434:	8b 14 85 80 11 80 00 	mov    0x801180(,%eax,4),%edx
  80043b:	85 d2                	test   %edx,%edx
  80043d:	75 1b                	jne    80045a <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80043f:	50                   	push   %eax
  800440:	68 a4 0f 80 00       	push   $0x800fa4
  800445:	53                   	push   %ebx
  800446:	56                   	push   %esi
  800447:	e8 91 fe ff ff       	call   8002dd <printfmt>
  80044c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80044f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800452:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800455:	e9 c6 fe ff ff       	jmp    800320 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80045a:	52                   	push   %edx
  80045b:	68 ad 0f 80 00       	push   $0x800fad
  800460:	53                   	push   %ebx
  800461:	56                   	push   %esi
  800462:	e8 76 fe ff ff       	call   8002dd <printfmt>
  800467:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80046a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80046d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800470:	e9 ab fe ff ff       	jmp    800320 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800475:	8b 45 14             	mov    0x14(%ebp),%eax
  800478:	83 c0 04             	add    $0x4,%eax
  80047b:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80047e:	8b 45 14             	mov    0x14(%ebp),%eax
  800481:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800483:	85 ff                	test   %edi,%edi
  800485:	b8 9d 0f 80 00       	mov    $0x800f9d,%eax
  80048a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80048d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800491:	0f 8e 94 00 00 00    	jle    80052b <vprintfmt+0x231>
  800497:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80049b:	0f 84 98 00 00 00    	je     800539 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a1:	83 ec 08             	sub    $0x8,%esp
  8004a4:	ff 75 d0             	pushl  -0x30(%ebp)
  8004a7:	57                   	push   %edi
  8004a8:	e8 5b 03 00 00       	call   800808 <strnlen>
  8004ad:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004b0:	29 c1                	sub    %eax,%ecx
  8004b2:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004b5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004b8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004bc:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004bf:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004c2:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c4:	eb 0f                	jmp    8004d5 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004c6:	83 ec 08             	sub    $0x8,%esp
  8004c9:	53                   	push   %ebx
  8004ca:	ff 75 e0             	pushl  -0x20(%ebp)
  8004cd:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cf:	83 ef 01             	sub    $0x1,%edi
  8004d2:	83 c4 10             	add    $0x10,%esp
  8004d5:	85 ff                	test   %edi,%edi
  8004d7:	7f ed                	jg     8004c6 <vprintfmt+0x1cc>
  8004d9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004dc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004df:	85 c9                	test   %ecx,%ecx
  8004e1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e6:	0f 49 c1             	cmovns %ecx,%eax
  8004e9:	29 c1                	sub    %eax,%ecx
  8004eb:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ee:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004f1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004f4:	89 cb                	mov    %ecx,%ebx
  8004f6:	eb 4d                	jmp    800545 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8004fc:	74 1b                	je     800519 <vprintfmt+0x21f>
  8004fe:	0f be c0             	movsbl %al,%eax
  800501:	83 e8 20             	sub    $0x20,%eax
  800504:	83 f8 5e             	cmp    $0x5e,%eax
  800507:	76 10                	jbe    800519 <vprintfmt+0x21f>
					putch('?', putdat);
  800509:	83 ec 08             	sub    $0x8,%esp
  80050c:	ff 75 0c             	pushl  0xc(%ebp)
  80050f:	6a 3f                	push   $0x3f
  800511:	ff 55 08             	call   *0x8(%ebp)
  800514:	83 c4 10             	add    $0x10,%esp
  800517:	eb 0d                	jmp    800526 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800519:	83 ec 08             	sub    $0x8,%esp
  80051c:	ff 75 0c             	pushl  0xc(%ebp)
  80051f:	52                   	push   %edx
  800520:	ff 55 08             	call   *0x8(%ebp)
  800523:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800526:	83 eb 01             	sub    $0x1,%ebx
  800529:	eb 1a                	jmp    800545 <vprintfmt+0x24b>
  80052b:	89 75 08             	mov    %esi,0x8(%ebp)
  80052e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800531:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800534:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800537:	eb 0c                	jmp    800545 <vprintfmt+0x24b>
  800539:	89 75 08             	mov    %esi,0x8(%ebp)
  80053c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800542:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800545:	83 c7 01             	add    $0x1,%edi
  800548:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80054c:	0f be d0             	movsbl %al,%edx
  80054f:	85 d2                	test   %edx,%edx
  800551:	74 23                	je     800576 <vprintfmt+0x27c>
  800553:	85 f6                	test   %esi,%esi
  800555:	78 a1                	js     8004f8 <vprintfmt+0x1fe>
  800557:	83 ee 01             	sub    $0x1,%esi
  80055a:	79 9c                	jns    8004f8 <vprintfmt+0x1fe>
  80055c:	89 df                	mov    %ebx,%edi
  80055e:	8b 75 08             	mov    0x8(%ebp),%esi
  800561:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800564:	eb 18                	jmp    80057e <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800566:	83 ec 08             	sub    $0x8,%esp
  800569:	53                   	push   %ebx
  80056a:	6a 20                	push   $0x20
  80056c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80056e:	83 ef 01             	sub    $0x1,%edi
  800571:	83 c4 10             	add    $0x10,%esp
  800574:	eb 08                	jmp    80057e <vprintfmt+0x284>
  800576:	89 df                	mov    %ebx,%edi
  800578:	8b 75 08             	mov    0x8(%ebp),%esi
  80057b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80057e:	85 ff                	test   %edi,%edi
  800580:	7f e4                	jg     800566 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800582:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800585:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800588:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80058b:	e9 90 fd ff ff       	jmp    800320 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800590:	83 f9 01             	cmp    $0x1,%ecx
  800593:	7e 19                	jle    8005ae <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800595:	8b 45 14             	mov    0x14(%ebp),%eax
  800598:	8b 50 04             	mov    0x4(%eax),%edx
  80059b:	8b 00                	mov    (%eax),%eax
  80059d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005a0:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a6:	8d 40 08             	lea    0x8(%eax),%eax
  8005a9:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ac:	eb 38                	jmp    8005e6 <vprintfmt+0x2ec>
	else if (lflag)
  8005ae:	85 c9                	test   %ecx,%ecx
  8005b0:	74 1b                	je     8005cd <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b5:	8b 00                	mov    (%eax),%eax
  8005b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005ba:	89 c1                	mov    %eax,%ecx
  8005bc:	c1 f9 1f             	sar    $0x1f,%ecx
  8005bf:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c5:	8d 40 04             	lea    0x4(%eax),%eax
  8005c8:	89 45 14             	mov    %eax,0x14(%ebp)
  8005cb:	eb 19                	jmp    8005e6 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d0:	8b 00                	mov    (%eax),%eax
  8005d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d5:	89 c1                	mov    %eax,%ecx
  8005d7:	c1 f9 1f             	sar    $0x1f,%ecx
  8005da:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e0:	8d 40 04             	lea    0x4(%eax),%eax
  8005e3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005e9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005ec:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005f1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005f5:	0f 89 36 01 00 00    	jns    800731 <vprintfmt+0x437>
				putch('-', putdat);
  8005fb:	83 ec 08             	sub    $0x8,%esp
  8005fe:	53                   	push   %ebx
  8005ff:	6a 2d                	push   $0x2d
  800601:	ff d6                	call   *%esi
				num = -(long long) num;
  800603:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800606:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800609:	f7 da                	neg    %edx
  80060b:	83 d1 00             	adc    $0x0,%ecx
  80060e:	f7 d9                	neg    %ecx
  800610:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800613:	b8 0a 00 00 00       	mov    $0xa,%eax
  800618:	e9 14 01 00 00       	jmp    800731 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80061d:	83 f9 01             	cmp    $0x1,%ecx
  800620:	7e 18                	jle    80063a <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800622:	8b 45 14             	mov    0x14(%ebp),%eax
  800625:	8b 10                	mov    (%eax),%edx
  800627:	8b 48 04             	mov    0x4(%eax),%ecx
  80062a:	8d 40 08             	lea    0x8(%eax),%eax
  80062d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800630:	b8 0a 00 00 00       	mov    $0xa,%eax
  800635:	e9 f7 00 00 00       	jmp    800731 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80063a:	85 c9                	test   %ecx,%ecx
  80063c:	74 1a                	je     800658 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80063e:	8b 45 14             	mov    0x14(%ebp),%eax
  800641:	8b 10                	mov    (%eax),%edx
  800643:	b9 00 00 00 00       	mov    $0x0,%ecx
  800648:	8d 40 04             	lea    0x4(%eax),%eax
  80064b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80064e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800653:	e9 d9 00 00 00       	jmp    800731 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800658:	8b 45 14             	mov    0x14(%ebp),%eax
  80065b:	8b 10                	mov    (%eax),%edx
  80065d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800662:	8d 40 04             	lea    0x4(%eax),%eax
  800665:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800668:	b8 0a 00 00 00       	mov    $0xa,%eax
  80066d:	e9 bf 00 00 00       	jmp    800731 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800672:	83 f9 01             	cmp    $0x1,%ecx
  800675:	7e 13                	jle    80068a <vprintfmt+0x390>
		return va_arg(*ap, long long);
  800677:	8b 45 14             	mov    0x14(%ebp),%eax
  80067a:	8b 50 04             	mov    0x4(%eax),%edx
  80067d:	8b 00                	mov    (%eax),%eax
  80067f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800682:	8d 49 08             	lea    0x8(%ecx),%ecx
  800685:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800688:	eb 28                	jmp    8006b2 <vprintfmt+0x3b8>
	else if (lflag)
  80068a:	85 c9                	test   %ecx,%ecx
  80068c:	74 13                	je     8006a1 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  80068e:	8b 45 14             	mov    0x14(%ebp),%eax
  800691:	8b 10                	mov    (%eax),%edx
  800693:	89 d0                	mov    %edx,%eax
  800695:	99                   	cltd   
  800696:	8b 4d 14             	mov    0x14(%ebp),%ecx
  800699:	8d 49 04             	lea    0x4(%ecx),%ecx
  80069c:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80069f:	eb 11                	jmp    8006b2 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8006a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a4:	8b 10                	mov    (%eax),%edx
  8006a6:	89 d0                	mov    %edx,%eax
  8006a8:	99                   	cltd   
  8006a9:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8006ac:	8d 49 04             	lea    0x4(%ecx),%ecx
  8006af:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8006b2:	89 d1                	mov    %edx,%ecx
  8006b4:	89 c2                	mov    %eax,%edx
			base = 8;
  8006b6:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006bb:	eb 74                	jmp    800731 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8006bd:	83 ec 08             	sub    $0x8,%esp
  8006c0:	53                   	push   %ebx
  8006c1:	6a 30                	push   $0x30
  8006c3:	ff d6                	call   *%esi
			putch('x', putdat);
  8006c5:	83 c4 08             	add    $0x8,%esp
  8006c8:	53                   	push   %ebx
  8006c9:	6a 78                	push   $0x78
  8006cb:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d0:	8b 10                	mov    (%eax),%edx
  8006d2:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d7:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006da:	8d 40 04             	lea    0x4(%eax),%eax
  8006dd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006e0:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006e5:	eb 4a                	jmp    800731 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e7:	83 f9 01             	cmp    $0x1,%ecx
  8006ea:	7e 15                	jle    800701 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  8006ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ef:	8b 10                	mov    (%eax),%edx
  8006f1:	8b 48 04             	mov    0x4(%eax),%ecx
  8006f4:	8d 40 08             	lea    0x8(%eax),%eax
  8006f7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006fa:	b8 10 00 00 00       	mov    $0x10,%eax
  8006ff:	eb 30                	jmp    800731 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800701:	85 c9                	test   %ecx,%ecx
  800703:	74 17                	je     80071c <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800705:	8b 45 14             	mov    0x14(%ebp),%eax
  800708:	8b 10                	mov    (%eax),%edx
  80070a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80070f:	8d 40 04             	lea    0x4(%eax),%eax
  800712:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800715:	b8 10 00 00 00       	mov    $0x10,%eax
  80071a:	eb 15                	jmp    800731 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80071c:	8b 45 14             	mov    0x14(%ebp),%eax
  80071f:	8b 10                	mov    (%eax),%edx
  800721:	b9 00 00 00 00       	mov    $0x0,%ecx
  800726:	8d 40 04             	lea    0x4(%eax),%eax
  800729:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80072c:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800731:	83 ec 0c             	sub    $0xc,%esp
  800734:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800738:	57                   	push   %edi
  800739:	ff 75 e0             	pushl  -0x20(%ebp)
  80073c:	50                   	push   %eax
  80073d:	51                   	push   %ecx
  80073e:	52                   	push   %edx
  80073f:	89 da                	mov    %ebx,%edx
  800741:	89 f0                	mov    %esi,%eax
  800743:	e8 c9 fa ff ff       	call   800211 <printnum>
			break;
  800748:	83 c4 20             	add    $0x20,%esp
  80074b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80074e:	e9 cd fb ff ff       	jmp    800320 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800753:	83 ec 08             	sub    $0x8,%esp
  800756:	53                   	push   %ebx
  800757:	52                   	push   %edx
  800758:	ff d6                	call   *%esi
			break;
  80075a:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80075d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800760:	e9 bb fb ff ff       	jmp    800320 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800765:	83 ec 08             	sub    $0x8,%esp
  800768:	53                   	push   %ebx
  800769:	6a 25                	push   $0x25
  80076b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  80076d:	83 c4 10             	add    $0x10,%esp
  800770:	eb 03                	jmp    800775 <vprintfmt+0x47b>
  800772:	83 ef 01             	sub    $0x1,%edi
  800775:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800779:	75 f7                	jne    800772 <vprintfmt+0x478>
  80077b:	e9 a0 fb ff ff       	jmp    800320 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800780:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800783:	5b                   	pop    %ebx
  800784:	5e                   	pop    %esi
  800785:	5f                   	pop    %edi
  800786:	5d                   	pop    %ebp
  800787:	c3                   	ret    

00800788 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800788:	55                   	push   %ebp
  800789:	89 e5                	mov    %esp,%ebp
  80078b:	83 ec 18             	sub    $0x18,%esp
  80078e:	8b 45 08             	mov    0x8(%ebp),%eax
  800791:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800794:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800797:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80079b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80079e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a5:	85 c0                	test   %eax,%eax
  8007a7:	74 26                	je     8007cf <vsnprintf+0x47>
  8007a9:	85 d2                	test   %edx,%edx
  8007ab:	7e 22                	jle    8007cf <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007ad:	ff 75 14             	pushl  0x14(%ebp)
  8007b0:	ff 75 10             	pushl  0x10(%ebp)
  8007b3:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b6:	50                   	push   %eax
  8007b7:	68 c0 02 80 00       	push   $0x8002c0
  8007bc:	e8 39 fb ff ff       	call   8002fa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007c4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007ca:	83 c4 10             	add    $0x10,%esp
  8007cd:	eb 05                	jmp    8007d4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007cf:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007d4:	c9                   	leave  
  8007d5:	c3                   	ret    

008007d6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d6:	55                   	push   %ebp
  8007d7:	89 e5                	mov    %esp,%ebp
  8007d9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007dc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007df:	50                   	push   %eax
  8007e0:	ff 75 10             	pushl  0x10(%ebp)
  8007e3:	ff 75 0c             	pushl  0xc(%ebp)
  8007e6:	ff 75 08             	pushl  0x8(%ebp)
  8007e9:	e8 9a ff ff ff       	call   800788 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007ee:	c9                   	leave  
  8007ef:	c3                   	ret    

008007f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007fb:	eb 03                	jmp    800800 <strlen+0x10>
		n++;
  8007fd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800800:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800804:	75 f7                	jne    8007fd <strlen+0xd>
		n++;
	return n;
}
  800806:	5d                   	pop    %ebp
  800807:	c3                   	ret    

00800808 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800808:	55                   	push   %ebp
  800809:	89 e5                	mov    %esp,%ebp
  80080b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080e:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800811:	ba 00 00 00 00       	mov    $0x0,%edx
  800816:	eb 03                	jmp    80081b <strnlen+0x13>
		n++;
  800818:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80081b:	39 c2                	cmp    %eax,%edx
  80081d:	74 08                	je     800827 <strnlen+0x1f>
  80081f:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800823:	75 f3                	jne    800818 <strnlen+0x10>
  800825:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800827:	5d                   	pop    %ebp
  800828:	c3                   	ret    

00800829 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800829:	55                   	push   %ebp
  80082a:	89 e5                	mov    %esp,%ebp
  80082c:	53                   	push   %ebx
  80082d:	8b 45 08             	mov    0x8(%ebp),%eax
  800830:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800833:	89 c2                	mov    %eax,%edx
  800835:	83 c2 01             	add    $0x1,%edx
  800838:	83 c1 01             	add    $0x1,%ecx
  80083b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80083f:	88 5a ff             	mov    %bl,-0x1(%edx)
  800842:	84 db                	test   %bl,%bl
  800844:	75 ef                	jne    800835 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800846:	5b                   	pop    %ebx
  800847:	5d                   	pop    %ebp
  800848:	c3                   	ret    

00800849 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800849:	55                   	push   %ebp
  80084a:	89 e5                	mov    %esp,%ebp
  80084c:	53                   	push   %ebx
  80084d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800850:	53                   	push   %ebx
  800851:	e8 9a ff ff ff       	call   8007f0 <strlen>
  800856:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800859:	ff 75 0c             	pushl  0xc(%ebp)
  80085c:	01 d8                	add    %ebx,%eax
  80085e:	50                   	push   %eax
  80085f:	e8 c5 ff ff ff       	call   800829 <strcpy>
	return dst;
}
  800864:	89 d8                	mov    %ebx,%eax
  800866:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800869:	c9                   	leave  
  80086a:	c3                   	ret    

0080086b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80086b:	55                   	push   %ebp
  80086c:	89 e5                	mov    %esp,%ebp
  80086e:	56                   	push   %esi
  80086f:	53                   	push   %ebx
  800870:	8b 75 08             	mov    0x8(%ebp),%esi
  800873:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800876:	89 f3                	mov    %esi,%ebx
  800878:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80087b:	89 f2                	mov    %esi,%edx
  80087d:	eb 0f                	jmp    80088e <strncpy+0x23>
		*dst++ = *src;
  80087f:	83 c2 01             	add    $0x1,%edx
  800882:	0f b6 01             	movzbl (%ecx),%eax
  800885:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800888:	80 39 01             	cmpb   $0x1,(%ecx)
  80088b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80088e:	39 da                	cmp    %ebx,%edx
  800890:	75 ed                	jne    80087f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800892:	89 f0                	mov    %esi,%eax
  800894:	5b                   	pop    %ebx
  800895:	5e                   	pop    %esi
  800896:	5d                   	pop    %ebp
  800897:	c3                   	ret    

00800898 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800898:	55                   	push   %ebp
  800899:	89 e5                	mov    %esp,%ebp
  80089b:	56                   	push   %esi
  80089c:	53                   	push   %ebx
  80089d:	8b 75 08             	mov    0x8(%ebp),%esi
  8008a0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008a3:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a6:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a8:	85 d2                	test   %edx,%edx
  8008aa:	74 21                	je     8008cd <strlcpy+0x35>
  8008ac:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008b0:	89 f2                	mov    %esi,%edx
  8008b2:	eb 09                	jmp    8008bd <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008b4:	83 c2 01             	add    $0x1,%edx
  8008b7:	83 c1 01             	add    $0x1,%ecx
  8008ba:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008bd:	39 c2                	cmp    %eax,%edx
  8008bf:	74 09                	je     8008ca <strlcpy+0x32>
  8008c1:	0f b6 19             	movzbl (%ecx),%ebx
  8008c4:	84 db                	test   %bl,%bl
  8008c6:	75 ec                	jne    8008b4 <strlcpy+0x1c>
  8008c8:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008ca:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008cd:	29 f0                	sub    %esi,%eax
}
  8008cf:	5b                   	pop    %ebx
  8008d0:	5e                   	pop    %esi
  8008d1:	5d                   	pop    %ebp
  8008d2:	c3                   	ret    

008008d3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008d3:	55                   	push   %ebp
  8008d4:	89 e5                	mov    %esp,%ebp
  8008d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008dc:	eb 06                	jmp    8008e4 <strcmp+0x11>
		p++, q++;
  8008de:	83 c1 01             	add    $0x1,%ecx
  8008e1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008e4:	0f b6 01             	movzbl (%ecx),%eax
  8008e7:	84 c0                	test   %al,%al
  8008e9:	74 04                	je     8008ef <strcmp+0x1c>
  8008eb:	3a 02                	cmp    (%edx),%al
  8008ed:	74 ef                	je     8008de <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ef:	0f b6 c0             	movzbl %al,%eax
  8008f2:	0f b6 12             	movzbl (%edx),%edx
  8008f5:	29 d0                	sub    %edx,%eax
}
  8008f7:	5d                   	pop    %ebp
  8008f8:	c3                   	ret    

008008f9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f9:	55                   	push   %ebp
  8008fa:	89 e5                	mov    %esp,%ebp
  8008fc:	53                   	push   %ebx
  8008fd:	8b 45 08             	mov    0x8(%ebp),%eax
  800900:	8b 55 0c             	mov    0xc(%ebp),%edx
  800903:	89 c3                	mov    %eax,%ebx
  800905:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800908:	eb 06                	jmp    800910 <strncmp+0x17>
		n--, p++, q++;
  80090a:	83 c0 01             	add    $0x1,%eax
  80090d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800910:	39 d8                	cmp    %ebx,%eax
  800912:	74 15                	je     800929 <strncmp+0x30>
  800914:	0f b6 08             	movzbl (%eax),%ecx
  800917:	84 c9                	test   %cl,%cl
  800919:	74 04                	je     80091f <strncmp+0x26>
  80091b:	3a 0a                	cmp    (%edx),%cl
  80091d:	74 eb                	je     80090a <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80091f:	0f b6 00             	movzbl (%eax),%eax
  800922:	0f b6 12             	movzbl (%edx),%edx
  800925:	29 d0                	sub    %edx,%eax
  800927:	eb 05                	jmp    80092e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800929:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80092e:	5b                   	pop    %ebx
  80092f:	5d                   	pop    %ebp
  800930:	c3                   	ret    

00800931 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800931:	55                   	push   %ebp
  800932:	89 e5                	mov    %esp,%ebp
  800934:	8b 45 08             	mov    0x8(%ebp),%eax
  800937:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80093b:	eb 07                	jmp    800944 <strchr+0x13>
		if (*s == c)
  80093d:	38 ca                	cmp    %cl,%dl
  80093f:	74 0f                	je     800950 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800941:	83 c0 01             	add    $0x1,%eax
  800944:	0f b6 10             	movzbl (%eax),%edx
  800947:	84 d2                	test   %dl,%dl
  800949:	75 f2                	jne    80093d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80094b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800950:	5d                   	pop    %ebp
  800951:	c3                   	ret    

00800952 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800952:	55                   	push   %ebp
  800953:	89 e5                	mov    %esp,%ebp
  800955:	8b 45 08             	mov    0x8(%ebp),%eax
  800958:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80095c:	eb 03                	jmp    800961 <strfind+0xf>
  80095e:	83 c0 01             	add    $0x1,%eax
  800961:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800964:	38 ca                	cmp    %cl,%dl
  800966:	74 04                	je     80096c <strfind+0x1a>
  800968:	84 d2                	test   %dl,%dl
  80096a:	75 f2                	jne    80095e <strfind+0xc>
			break;
	return (char *) s;
}
  80096c:	5d                   	pop    %ebp
  80096d:	c3                   	ret    

0080096e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80096e:	55                   	push   %ebp
  80096f:	89 e5                	mov    %esp,%ebp
  800971:	57                   	push   %edi
  800972:	56                   	push   %esi
  800973:	53                   	push   %ebx
  800974:	8b 7d 08             	mov    0x8(%ebp),%edi
  800977:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80097a:	85 c9                	test   %ecx,%ecx
  80097c:	74 36                	je     8009b4 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80097e:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800984:	75 28                	jne    8009ae <memset+0x40>
  800986:	f6 c1 03             	test   $0x3,%cl
  800989:	75 23                	jne    8009ae <memset+0x40>
		c &= 0xFF;
  80098b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80098f:	89 d3                	mov    %edx,%ebx
  800991:	c1 e3 08             	shl    $0x8,%ebx
  800994:	89 d6                	mov    %edx,%esi
  800996:	c1 e6 18             	shl    $0x18,%esi
  800999:	89 d0                	mov    %edx,%eax
  80099b:	c1 e0 10             	shl    $0x10,%eax
  80099e:	09 f0                	or     %esi,%eax
  8009a0:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8009a2:	89 d8                	mov    %ebx,%eax
  8009a4:	09 d0                	or     %edx,%eax
  8009a6:	c1 e9 02             	shr    $0x2,%ecx
  8009a9:	fc                   	cld    
  8009aa:	f3 ab                	rep stos %eax,%es:(%edi)
  8009ac:	eb 06                	jmp    8009b4 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009b1:	fc                   	cld    
  8009b2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009b4:	89 f8                	mov    %edi,%eax
  8009b6:	5b                   	pop    %ebx
  8009b7:	5e                   	pop    %esi
  8009b8:	5f                   	pop    %edi
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	57                   	push   %edi
  8009bf:	56                   	push   %esi
  8009c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c3:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c9:	39 c6                	cmp    %eax,%esi
  8009cb:	73 35                	jae    800a02 <memmove+0x47>
  8009cd:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009d0:	39 d0                	cmp    %edx,%eax
  8009d2:	73 2e                	jae    800a02 <memmove+0x47>
		s += n;
		d += n;
  8009d4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d7:	89 d6                	mov    %edx,%esi
  8009d9:	09 fe                	or     %edi,%esi
  8009db:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009e1:	75 13                	jne    8009f6 <memmove+0x3b>
  8009e3:	f6 c1 03             	test   $0x3,%cl
  8009e6:	75 0e                	jne    8009f6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e8:	83 ef 04             	sub    $0x4,%edi
  8009eb:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009ee:	c1 e9 02             	shr    $0x2,%ecx
  8009f1:	fd                   	std    
  8009f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009f4:	eb 09                	jmp    8009ff <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f6:	83 ef 01             	sub    $0x1,%edi
  8009f9:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009fc:	fd                   	std    
  8009fd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009ff:	fc                   	cld    
  800a00:	eb 1d                	jmp    800a1f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a02:	89 f2                	mov    %esi,%edx
  800a04:	09 c2                	or     %eax,%edx
  800a06:	f6 c2 03             	test   $0x3,%dl
  800a09:	75 0f                	jne    800a1a <memmove+0x5f>
  800a0b:	f6 c1 03             	test   $0x3,%cl
  800a0e:	75 0a                	jne    800a1a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a10:	c1 e9 02             	shr    $0x2,%ecx
  800a13:	89 c7                	mov    %eax,%edi
  800a15:	fc                   	cld    
  800a16:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a18:	eb 05                	jmp    800a1f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a1a:	89 c7                	mov    %eax,%edi
  800a1c:	fc                   	cld    
  800a1d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a1f:	5e                   	pop    %esi
  800a20:	5f                   	pop    %edi
  800a21:	5d                   	pop    %ebp
  800a22:	c3                   	ret    

00800a23 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a23:	55                   	push   %ebp
  800a24:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a26:	ff 75 10             	pushl  0x10(%ebp)
  800a29:	ff 75 0c             	pushl  0xc(%ebp)
  800a2c:	ff 75 08             	pushl  0x8(%ebp)
  800a2f:	e8 87 ff ff ff       	call   8009bb <memmove>
}
  800a34:	c9                   	leave  
  800a35:	c3                   	ret    

00800a36 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a36:	55                   	push   %ebp
  800a37:	89 e5                	mov    %esp,%ebp
  800a39:	56                   	push   %esi
  800a3a:	53                   	push   %ebx
  800a3b:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a41:	89 c6                	mov    %eax,%esi
  800a43:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a46:	eb 1a                	jmp    800a62 <memcmp+0x2c>
		if (*s1 != *s2)
  800a48:	0f b6 08             	movzbl (%eax),%ecx
  800a4b:	0f b6 1a             	movzbl (%edx),%ebx
  800a4e:	38 d9                	cmp    %bl,%cl
  800a50:	74 0a                	je     800a5c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a52:	0f b6 c1             	movzbl %cl,%eax
  800a55:	0f b6 db             	movzbl %bl,%ebx
  800a58:	29 d8                	sub    %ebx,%eax
  800a5a:	eb 0f                	jmp    800a6b <memcmp+0x35>
		s1++, s2++;
  800a5c:	83 c0 01             	add    $0x1,%eax
  800a5f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a62:	39 f0                	cmp    %esi,%eax
  800a64:	75 e2                	jne    800a48 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a66:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a6b:	5b                   	pop    %ebx
  800a6c:	5e                   	pop    %esi
  800a6d:	5d                   	pop    %ebp
  800a6e:	c3                   	ret    

00800a6f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a6f:	55                   	push   %ebp
  800a70:	89 e5                	mov    %esp,%ebp
  800a72:	53                   	push   %ebx
  800a73:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a76:	89 c1                	mov    %eax,%ecx
  800a78:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a7f:	eb 0a                	jmp    800a8b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a81:	0f b6 10             	movzbl (%eax),%edx
  800a84:	39 da                	cmp    %ebx,%edx
  800a86:	74 07                	je     800a8f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a88:	83 c0 01             	add    $0x1,%eax
  800a8b:	39 c8                	cmp    %ecx,%eax
  800a8d:	72 f2                	jb     800a81 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a8f:	5b                   	pop    %ebx
  800a90:	5d                   	pop    %ebp
  800a91:	c3                   	ret    

00800a92 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a92:	55                   	push   %ebp
  800a93:	89 e5                	mov    %esp,%ebp
  800a95:	57                   	push   %edi
  800a96:	56                   	push   %esi
  800a97:	53                   	push   %ebx
  800a98:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a9b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9e:	eb 03                	jmp    800aa3 <strtol+0x11>
		s++;
  800aa0:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa3:	0f b6 01             	movzbl (%ecx),%eax
  800aa6:	3c 20                	cmp    $0x20,%al
  800aa8:	74 f6                	je     800aa0 <strtol+0xe>
  800aaa:	3c 09                	cmp    $0x9,%al
  800aac:	74 f2                	je     800aa0 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aae:	3c 2b                	cmp    $0x2b,%al
  800ab0:	75 0a                	jne    800abc <strtol+0x2a>
		s++;
  800ab2:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab5:	bf 00 00 00 00       	mov    $0x0,%edi
  800aba:	eb 11                	jmp    800acd <strtol+0x3b>
  800abc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ac1:	3c 2d                	cmp    $0x2d,%al
  800ac3:	75 08                	jne    800acd <strtol+0x3b>
		s++, neg = 1;
  800ac5:	83 c1 01             	add    $0x1,%ecx
  800ac8:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800acd:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ad3:	75 15                	jne    800aea <strtol+0x58>
  800ad5:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad8:	75 10                	jne    800aea <strtol+0x58>
  800ada:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ade:	75 7c                	jne    800b5c <strtol+0xca>
		s += 2, base = 16;
  800ae0:	83 c1 02             	add    $0x2,%ecx
  800ae3:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae8:	eb 16                	jmp    800b00 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800aea:	85 db                	test   %ebx,%ebx
  800aec:	75 12                	jne    800b00 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800aee:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800af3:	80 39 30             	cmpb   $0x30,(%ecx)
  800af6:	75 08                	jne    800b00 <strtol+0x6e>
		s++, base = 8;
  800af8:	83 c1 01             	add    $0x1,%ecx
  800afb:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b00:	b8 00 00 00 00       	mov    $0x0,%eax
  800b05:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b08:	0f b6 11             	movzbl (%ecx),%edx
  800b0b:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b0e:	89 f3                	mov    %esi,%ebx
  800b10:	80 fb 09             	cmp    $0x9,%bl
  800b13:	77 08                	ja     800b1d <strtol+0x8b>
			dig = *s - '0';
  800b15:	0f be d2             	movsbl %dl,%edx
  800b18:	83 ea 30             	sub    $0x30,%edx
  800b1b:	eb 22                	jmp    800b3f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b1d:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b20:	89 f3                	mov    %esi,%ebx
  800b22:	80 fb 19             	cmp    $0x19,%bl
  800b25:	77 08                	ja     800b2f <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b27:	0f be d2             	movsbl %dl,%edx
  800b2a:	83 ea 57             	sub    $0x57,%edx
  800b2d:	eb 10                	jmp    800b3f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b2f:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b32:	89 f3                	mov    %esi,%ebx
  800b34:	80 fb 19             	cmp    $0x19,%bl
  800b37:	77 16                	ja     800b4f <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b39:	0f be d2             	movsbl %dl,%edx
  800b3c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b3f:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b42:	7d 0b                	jge    800b4f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b44:	83 c1 01             	add    $0x1,%ecx
  800b47:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b4b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b4d:	eb b9                	jmp    800b08 <strtol+0x76>

	if (endptr)
  800b4f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b53:	74 0d                	je     800b62 <strtol+0xd0>
		*endptr = (char *) s;
  800b55:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b58:	89 0e                	mov    %ecx,(%esi)
  800b5a:	eb 06                	jmp    800b62 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b5c:	85 db                	test   %ebx,%ebx
  800b5e:	74 98                	je     800af8 <strtol+0x66>
  800b60:	eb 9e                	jmp    800b00 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b62:	89 c2                	mov    %eax,%edx
  800b64:	f7 da                	neg    %edx
  800b66:	85 ff                	test   %edi,%edi
  800b68:	0f 45 c2             	cmovne %edx,%eax
}
  800b6b:	5b                   	pop    %ebx
  800b6c:	5e                   	pop    %esi
  800b6d:	5f                   	pop    %edi
  800b6e:	5d                   	pop    %ebp
  800b6f:	c3                   	ret    

00800b70 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b70:	55                   	push   %ebp
  800b71:	89 e5                	mov    %esp,%ebp
  800b73:	57                   	push   %edi
  800b74:	56                   	push   %esi
  800b75:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b76:	b8 00 00 00 00       	mov    $0x0,%eax
  800b7b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b7e:	8b 55 08             	mov    0x8(%ebp),%edx
  800b81:	89 c3                	mov    %eax,%ebx
  800b83:	89 c7                	mov    %eax,%edi
  800b85:	89 c6                	mov    %eax,%esi
  800b87:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b89:	5b                   	pop    %ebx
  800b8a:	5e                   	pop    %esi
  800b8b:	5f                   	pop    %edi
  800b8c:	5d                   	pop    %ebp
  800b8d:	c3                   	ret    

00800b8e <sys_cgetc>:

int
sys_cgetc(void)
{
  800b8e:	55                   	push   %ebp
  800b8f:	89 e5                	mov    %esp,%ebp
  800b91:	57                   	push   %edi
  800b92:	56                   	push   %esi
  800b93:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b94:	ba 00 00 00 00       	mov    $0x0,%edx
  800b99:	b8 01 00 00 00       	mov    $0x1,%eax
  800b9e:	89 d1                	mov    %edx,%ecx
  800ba0:	89 d3                	mov    %edx,%ebx
  800ba2:	89 d7                	mov    %edx,%edi
  800ba4:	89 d6                	mov    %edx,%esi
  800ba6:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ba8:	5b                   	pop    %ebx
  800ba9:	5e                   	pop    %esi
  800baa:	5f                   	pop    %edi
  800bab:	5d                   	pop    %ebp
  800bac:	c3                   	ret    

00800bad <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800bad:	55                   	push   %ebp
  800bae:	89 e5                	mov    %esp,%ebp
  800bb0:	57                   	push   %edi
  800bb1:	56                   	push   %esi
  800bb2:	53                   	push   %ebx
  800bb3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bb6:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bbb:	b8 03 00 00 00       	mov    $0x3,%eax
  800bc0:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc3:	89 cb                	mov    %ecx,%ebx
  800bc5:	89 cf                	mov    %ecx,%edi
  800bc7:	89 ce                	mov    %ecx,%esi
  800bc9:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bcb:	85 c0                	test   %eax,%eax
  800bcd:	7e 17                	jle    800be6 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bcf:	83 ec 0c             	sub    $0xc,%esp
  800bd2:	50                   	push   %eax
  800bd3:	6a 03                	push   $0x3
  800bd5:	68 a0 11 80 00       	push   $0x8011a0
  800bda:	6a 23                	push   $0x23
  800bdc:	68 bd 11 80 00       	push   $0x8011bd
  800be1:	e8 3e f5 ff ff       	call   800124 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800be6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800be9:	5b                   	pop    %ebx
  800bea:	5e                   	pop    %esi
  800beb:	5f                   	pop    %edi
  800bec:	5d                   	pop    %ebp
  800bed:	c3                   	ret    

00800bee <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bee:	55                   	push   %ebp
  800bef:	89 e5                	mov    %esp,%ebp
  800bf1:	57                   	push   %edi
  800bf2:	56                   	push   %esi
  800bf3:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf4:	ba 00 00 00 00       	mov    $0x0,%edx
  800bf9:	b8 02 00 00 00       	mov    $0x2,%eax
  800bfe:	89 d1                	mov    %edx,%ecx
  800c00:	89 d3                	mov    %edx,%ebx
  800c02:	89 d7                	mov    %edx,%edi
  800c04:	89 d6                	mov    %edx,%esi
  800c06:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c08:	5b                   	pop    %ebx
  800c09:	5e                   	pop    %esi
  800c0a:	5f                   	pop    %edi
  800c0b:	5d                   	pop    %ebp
  800c0c:	c3                   	ret    
  800c0d:	66 90                	xchg   %ax,%ax
  800c0f:	90                   	nop

00800c10 <__udivdi3>:
  800c10:	55                   	push   %ebp
  800c11:	57                   	push   %edi
  800c12:	56                   	push   %esi
  800c13:	53                   	push   %ebx
  800c14:	83 ec 1c             	sub    $0x1c,%esp
  800c17:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c1b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c1f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c23:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c27:	85 f6                	test   %esi,%esi
  800c29:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c2d:	89 ca                	mov    %ecx,%edx
  800c2f:	89 f8                	mov    %edi,%eax
  800c31:	75 3d                	jne    800c70 <__udivdi3+0x60>
  800c33:	39 cf                	cmp    %ecx,%edi
  800c35:	0f 87 c5 00 00 00    	ja     800d00 <__udivdi3+0xf0>
  800c3b:	85 ff                	test   %edi,%edi
  800c3d:	89 fd                	mov    %edi,%ebp
  800c3f:	75 0b                	jne    800c4c <__udivdi3+0x3c>
  800c41:	b8 01 00 00 00       	mov    $0x1,%eax
  800c46:	31 d2                	xor    %edx,%edx
  800c48:	f7 f7                	div    %edi
  800c4a:	89 c5                	mov    %eax,%ebp
  800c4c:	89 c8                	mov    %ecx,%eax
  800c4e:	31 d2                	xor    %edx,%edx
  800c50:	f7 f5                	div    %ebp
  800c52:	89 c1                	mov    %eax,%ecx
  800c54:	89 d8                	mov    %ebx,%eax
  800c56:	89 cf                	mov    %ecx,%edi
  800c58:	f7 f5                	div    %ebp
  800c5a:	89 c3                	mov    %eax,%ebx
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
  800c70:	39 ce                	cmp    %ecx,%esi
  800c72:	77 74                	ja     800ce8 <__udivdi3+0xd8>
  800c74:	0f bd fe             	bsr    %esi,%edi
  800c77:	83 f7 1f             	xor    $0x1f,%edi
  800c7a:	0f 84 98 00 00 00    	je     800d18 <__udivdi3+0x108>
  800c80:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c85:	89 f9                	mov    %edi,%ecx
  800c87:	89 c5                	mov    %eax,%ebp
  800c89:	29 fb                	sub    %edi,%ebx
  800c8b:	d3 e6                	shl    %cl,%esi
  800c8d:	89 d9                	mov    %ebx,%ecx
  800c8f:	d3 ed                	shr    %cl,%ebp
  800c91:	89 f9                	mov    %edi,%ecx
  800c93:	d3 e0                	shl    %cl,%eax
  800c95:	09 ee                	or     %ebp,%esi
  800c97:	89 d9                	mov    %ebx,%ecx
  800c99:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c9d:	89 d5                	mov    %edx,%ebp
  800c9f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ca3:	d3 ed                	shr    %cl,%ebp
  800ca5:	89 f9                	mov    %edi,%ecx
  800ca7:	d3 e2                	shl    %cl,%edx
  800ca9:	89 d9                	mov    %ebx,%ecx
  800cab:	d3 e8                	shr    %cl,%eax
  800cad:	09 c2                	or     %eax,%edx
  800caf:	89 d0                	mov    %edx,%eax
  800cb1:	89 ea                	mov    %ebp,%edx
  800cb3:	f7 f6                	div    %esi
  800cb5:	89 d5                	mov    %edx,%ebp
  800cb7:	89 c3                	mov    %eax,%ebx
  800cb9:	f7 64 24 0c          	mull   0xc(%esp)
  800cbd:	39 d5                	cmp    %edx,%ebp
  800cbf:	72 10                	jb     800cd1 <__udivdi3+0xc1>
  800cc1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cc5:	89 f9                	mov    %edi,%ecx
  800cc7:	d3 e6                	shl    %cl,%esi
  800cc9:	39 c6                	cmp    %eax,%esi
  800ccb:	73 07                	jae    800cd4 <__udivdi3+0xc4>
  800ccd:	39 d5                	cmp    %edx,%ebp
  800ccf:	75 03                	jne    800cd4 <__udivdi3+0xc4>
  800cd1:	83 eb 01             	sub    $0x1,%ebx
  800cd4:	31 ff                	xor    %edi,%edi
  800cd6:	89 d8                	mov    %ebx,%eax
  800cd8:	89 fa                	mov    %edi,%edx
  800cda:	83 c4 1c             	add    $0x1c,%esp
  800cdd:	5b                   	pop    %ebx
  800cde:	5e                   	pop    %esi
  800cdf:	5f                   	pop    %edi
  800ce0:	5d                   	pop    %ebp
  800ce1:	c3                   	ret    
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	31 ff                	xor    %edi,%edi
  800cea:	31 db                	xor    %ebx,%ebx
  800cec:	89 d8                	mov    %ebx,%eax
  800cee:	89 fa                	mov    %edi,%edx
  800cf0:	83 c4 1c             	add    $0x1c,%esp
  800cf3:	5b                   	pop    %ebx
  800cf4:	5e                   	pop    %esi
  800cf5:	5f                   	pop    %edi
  800cf6:	5d                   	pop    %ebp
  800cf7:	c3                   	ret    
  800cf8:	90                   	nop
  800cf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d00:	89 d8                	mov    %ebx,%eax
  800d02:	f7 f7                	div    %edi
  800d04:	31 ff                	xor    %edi,%edi
  800d06:	89 c3                	mov    %eax,%ebx
  800d08:	89 d8                	mov    %ebx,%eax
  800d0a:	89 fa                	mov    %edi,%edx
  800d0c:	83 c4 1c             	add    $0x1c,%esp
  800d0f:	5b                   	pop    %ebx
  800d10:	5e                   	pop    %esi
  800d11:	5f                   	pop    %edi
  800d12:	5d                   	pop    %ebp
  800d13:	c3                   	ret    
  800d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d18:	39 ce                	cmp    %ecx,%esi
  800d1a:	72 0c                	jb     800d28 <__udivdi3+0x118>
  800d1c:	31 db                	xor    %ebx,%ebx
  800d1e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d22:	0f 87 34 ff ff ff    	ja     800c5c <__udivdi3+0x4c>
  800d28:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d2d:	e9 2a ff ff ff       	jmp    800c5c <__udivdi3+0x4c>
  800d32:	66 90                	xchg   %ax,%ax
  800d34:	66 90                	xchg   %ax,%ax
  800d36:	66 90                	xchg   %ax,%ax
  800d38:	66 90                	xchg   %ax,%ax
  800d3a:	66 90                	xchg   %ax,%ax
  800d3c:	66 90                	xchg   %ax,%ax
  800d3e:	66 90                	xchg   %ax,%ax

00800d40 <__umoddi3>:
  800d40:	55                   	push   %ebp
  800d41:	57                   	push   %edi
  800d42:	56                   	push   %esi
  800d43:	53                   	push   %ebx
  800d44:	83 ec 1c             	sub    $0x1c,%esp
  800d47:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d4b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d4f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d53:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d57:	85 d2                	test   %edx,%edx
  800d59:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d61:	89 f3                	mov    %esi,%ebx
  800d63:	89 3c 24             	mov    %edi,(%esp)
  800d66:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d6a:	75 1c                	jne    800d88 <__umoddi3+0x48>
  800d6c:	39 f7                	cmp    %esi,%edi
  800d6e:	76 50                	jbe    800dc0 <__umoddi3+0x80>
  800d70:	89 c8                	mov    %ecx,%eax
  800d72:	89 f2                	mov    %esi,%edx
  800d74:	f7 f7                	div    %edi
  800d76:	89 d0                	mov    %edx,%eax
  800d78:	31 d2                	xor    %edx,%edx
  800d7a:	83 c4 1c             	add    $0x1c,%esp
  800d7d:	5b                   	pop    %ebx
  800d7e:	5e                   	pop    %esi
  800d7f:	5f                   	pop    %edi
  800d80:	5d                   	pop    %ebp
  800d81:	c3                   	ret    
  800d82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d88:	39 f2                	cmp    %esi,%edx
  800d8a:	89 d0                	mov    %edx,%eax
  800d8c:	77 52                	ja     800de0 <__umoddi3+0xa0>
  800d8e:	0f bd ea             	bsr    %edx,%ebp
  800d91:	83 f5 1f             	xor    $0x1f,%ebp
  800d94:	75 5a                	jne    800df0 <__umoddi3+0xb0>
  800d96:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d9a:	0f 82 e0 00 00 00    	jb     800e80 <__umoddi3+0x140>
  800da0:	39 0c 24             	cmp    %ecx,(%esp)
  800da3:	0f 86 d7 00 00 00    	jbe    800e80 <__umoddi3+0x140>
  800da9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dad:	8b 54 24 04          	mov    0x4(%esp),%edx
  800db1:	83 c4 1c             	add    $0x1c,%esp
  800db4:	5b                   	pop    %ebx
  800db5:	5e                   	pop    %esi
  800db6:	5f                   	pop    %edi
  800db7:	5d                   	pop    %ebp
  800db8:	c3                   	ret    
  800db9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800dc0:	85 ff                	test   %edi,%edi
  800dc2:	89 fd                	mov    %edi,%ebp
  800dc4:	75 0b                	jne    800dd1 <__umoddi3+0x91>
  800dc6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dcb:	31 d2                	xor    %edx,%edx
  800dcd:	f7 f7                	div    %edi
  800dcf:	89 c5                	mov    %eax,%ebp
  800dd1:	89 f0                	mov    %esi,%eax
  800dd3:	31 d2                	xor    %edx,%edx
  800dd5:	f7 f5                	div    %ebp
  800dd7:	89 c8                	mov    %ecx,%eax
  800dd9:	f7 f5                	div    %ebp
  800ddb:	89 d0                	mov    %edx,%eax
  800ddd:	eb 99                	jmp    800d78 <__umoddi3+0x38>
  800ddf:	90                   	nop
  800de0:	89 c8                	mov    %ecx,%eax
  800de2:	89 f2                	mov    %esi,%edx
  800de4:	83 c4 1c             	add    $0x1c,%esp
  800de7:	5b                   	pop    %ebx
  800de8:	5e                   	pop    %esi
  800de9:	5f                   	pop    %edi
  800dea:	5d                   	pop    %ebp
  800deb:	c3                   	ret    
  800dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800df0:	8b 34 24             	mov    (%esp),%esi
  800df3:	bf 20 00 00 00       	mov    $0x20,%edi
  800df8:	89 e9                	mov    %ebp,%ecx
  800dfa:	29 ef                	sub    %ebp,%edi
  800dfc:	d3 e0                	shl    %cl,%eax
  800dfe:	89 f9                	mov    %edi,%ecx
  800e00:	89 f2                	mov    %esi,%edx
  800e02:	d3 ea                	shr    %cl,%edx
  800e04:	89 e9                	mov    %ebp,%ecx
  800e06:	09 c2                	or     %eax,%edx
  800e08:	89 d8                	mov    %ebx,%eax
  800e0a:	89 14 24             	mov    %edx,(%esp)
  800e0d:	89 f2                	mov    %esi,%edx
  800e0f:	d3 e2                	shl    %cl,%edx
  800e11:	89 f9                	mov    %edi,%ecx
  800e13:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e17:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e1b:	d3 e8                	shr    %cl,%eax
  800e1d:	89 e9                	mov    %ebp,%ecx
  800e1f:	89 c6                	mov    %eax,%esi
  800e21:	d3 e3                	shl    %cl,%ebx
  800e23:	89 f9                	mov    %edi,%ecx
  800e25:	89 d0                	mov    %edx,%eax
  800e27:	d3 e8                	shr    %cl,%eax
  800e29:	89 e9                	mov    %ebp,%ecx
  800e2b:	09 d8                	or     %ebx,%eax
  800e2d:	89 d3                	mov    %edx,%ebx
  800e2f:	89 f2                	mov    %esi,%edx
  800e31:	f7 34 24             	divl   (%esp)
  800e34:	89 d6                	mov    %edx,%esi
  800e36:	d3 e3                	shl    %cl,%ebx
  800e38:	f7 64 24 04          	mull   0x4(%esp)
  800e3c:	39 d6                	cmp    %edx,%esi
  800e3e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e42:	89 d1                	mov    %edx,%ecx
  800e44:	89 c3                	mov    %eax,%ebx
  800e46:	72 08                	jb     800e50 <__umoddi3+0x110>
  800e48:	75 11                	jne    800e5b <__umoddi3+0x11b>
  800e4a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e4e:	73 0b                	jae    800e5b <__umoddi3+0x11b>
  800e50:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e54:	1b 14 24             	sbb    (%esp),%edx
  800e57:	89 d1                	mov    %edx,%ecx
  800e59:	89 c3                	mov    %eax,%ebx
  800e5b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e5f:	29 da                	sub    %ebx,%edx
  800e61:	19 ce                	sbb    %ecx,%esi
  800e63:	89 f9                	mov    %edi,%ecx
  800e65:	89 f0                	mov    %esi,%eax
  800e67:	d3 e0                	shl    %cl,%eax
  800e69:	89 e9                	mov    %ebp,%ecx
  800e6b:	d3 ea                	shr    %cl,%edx
  800e6d:	89 e9                	mov    %ebp,%ecx
  800e6f:	d3 ee                	shr    %cl,%esi
  800e71:	09 d0                	or     %edx,%eax
  800e73:	89 f2                	mov    %esi,%edx
  800e75:	83 c4 1c             	add    $0x1c,%esp
  800e78:	5b                   	pop    %ebx
  800e79:	5e                   	pop    %esi
  800e7a:	5f                   	pop    %edi
  800e7b:	5d                   	pop    %ebp
  800e7c:	c3                   	ret    
  800e7d:	8d 76 00             	lea    0x0(%esi),%esi
  800e80:	29 f9                	sub    %edi,%ecx
  800e82:	19 d6                	sbb    %edx,%esi
  800e84:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e88:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e8c:	e9 18 ff ff ff       	jmp    800da9 <__umoddi3+0x69>
