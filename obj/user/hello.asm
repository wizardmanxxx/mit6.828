
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 20 0e 80 00       	push   $0x800e20
  80003e:	e8 f6 00 00 00       	call   800139 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 2e 0e 80 00       	push   $0x800e2e
  800054:	e8 e0 00 00 00       	call   800139 <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	83 ec 08             	sub    $0x8,%esp
  800064:	8b 45 08             	mov    0x8(%ebp),%eax
  800067:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800071:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 c0                	test   %eax,%eax
  800076:	7e 08                	jle    800080 <libmain+0x22>
		binaryname = argv[0];
  800078:	8b 0a                	mov    (%edx),%ecx
  80007a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800080:	83 ec 08             	sub    $0x8,%esp
  800083:	52                   	push   %edx
  800084:	50                   	push   %eax
  800085:	e8 a9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008a:	e8 05 00 00 00       	call   800094 <exit>
}
  80008f:	83 c4 10             	add    $0x10,%esp
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009a:	6a 00                	push   $0x0
  80009c:	e8 48 0a 00 00       	call   800ae9 <sys_env_destroy>
}
  8000a1:	83 c4 10             	add    $0x10,%esp
  8000a4:	c9                   	leave  
  8000a5:	c3                   	ret    

008000a6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a6:	55                   	push   %ebp
  8000a7:	89 e5                	mov    %esp,%ebp
  8000a9:	53                   	push   %ebx
  8000aa:	83 ec 04             	sub    $0x4,%esp
  8000ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b0:	8b 13                	mov    (%ebx),%edx
  8000b2:	8d 42 01             	lea    0x1(%edx),%eax
  8000b5:	89 03                	mov    %eax,(%ebx)
  8000b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ba:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000be:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c3:	75 1a                	jne    8000df <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c5:	83 ec 08             	sub    $0x8,%esp
  8000c8:	68 ff 00 00 00       	push   $0xff
  8000cd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d0:	50                   	push   %eax
  8000d1:	e8 d6 09 00 00       	call   800aac <sys_cputs>
		b->idx = 0;
  8000d6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000dc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000df:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e6:	c9                   	leave  
  8000e7:	c3                   	ret    

008000e8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e8:	55                   	push   %ebp
  8000e9:	89 e5                	mov    %esp,%ebp
  8000eb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f8:	00 00 00 
	b.cnt = 0;
  8000fb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800102:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800105:	ff 75 0c             	pushl  0xc(%ebp)
  800108:	ff 75 08             	pushl  0x8(%ebp)
  80010b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800111:	50                   	push   %eax
  800112:	68 a6 00 80 00       	push   $0x8000a6
  800117:	e8 1a 01 00 00       	call   800236 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011c:	83 c4 08             	add    $0x8,%esp
  80011f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800125:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012b:	50                   	push   %eax
  80012c:	e8 7b 09 00 00       	call   800aac <sys_cputs>

	return b.cnt;
}
  800131:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800137:	c9                   	leave  
  800138:	c3                   	ret    

00800139 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800139:	55                   	push   %ebp
  80013a:	89 e5                	mov    %esp,%ebp
  80013c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80013f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800142:	50                   	push   %eax
  800143:	ff 75 08             	pushl  0x8(%ebp)
  800146:	e8 9d ff ff ff       	call   8000e8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80014b:	c9                   	leave  
  80014c:	c3                   	ret    

0080014d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014d:	55                   	push   %ebp
  80014e:	89 e5                	mov    %esp,%ebp
  800150:	57                   	push   %edi
  800151:	56                   	push   %esi
  800152:	53                   	push   %ebx
  800153:	83 ec 1c             	sub    $0x1c,%esp
  800156:	89 c7                	mov    %eax,%edi
  800158:	89 d6                	mov    %edx,%esi
  80015a:	8b 45 08             	mov    0x8(%ebp),%eax
  80015d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800160:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800163:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800166:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800169:	bb 00 00 00 00       	mov    $0x0,%ebx
  80016e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800171:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800174:	39 d3                	cmp    %edx,%ebx
  800176:	72 05                	jb     80017d <printnum+0x30>
  800178:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017b:	77 45                	ja     8001c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017d:	83 ec 0c             	sub    $0xc,%esp
  800180:	ff 75 18             	pushl  0x18(%ebp)
  800183:	8b 45 14             	mov    0x14(%ebp),%eax
  800186:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800189:	53                   	push   %ebx
  80018a:	ff 75 10             	pushl  0x10(%ebp)
  80018d:	83 ec 08             	sub    $0x8,%esp
  800190:	ff 75 e4             	pushl  -0x1c(%ebp)
  800193:	ff 75 e0             	pushl  -0x20(%ebp)
  800196:	ff 75 dc             	pushl  -0x24(%ebp)
  800199:	ff 75 d8             	pushl  -0x28(%ebp)
  80019c:	e8 ef 09 00 00       	call   800b90 <__udivdi3>
  8001a1:	83 c4 18             	add    $0x18,%esp
  8001a4:	52                   	push   %edx
  8001a5:	50                   	push   %eax
  8001a6:	89 f2                	mov    %esi,%edx
  8001a8:	89 f8                	mov    %edi,%eax
  8001aa:	e8 9e ff ff ff       	call   80014d <printnum>
  8001af:	83 c4 20             	add    $0x20,%esp
  8001b2:	eb 18                	jmp    8001cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b4:	83 ec 08             	sub    $0x8,%esp
  8001b7:	56                   	push   %esi
  8001b8:	ff 75 18             	pushl  0x18(%ebp)
  8001bb:	ff d7                	call   *%edi
  8001bd:	83 c4 10             	add    $0x10,%esp
  8001c0:	eb 03                	jmp    8001c5 <printnum+0x78>
  8001c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c5:	83 eb 01             	sub    $0x1,%ebx
  8001c8:	85 db                	test   %ebx,%ebx
  8001ca:	7f e8                	jg     8001b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001cc:	83 ec 08             	sub    $0x8,%esp
  8001cf:	56                   	push   %esi
  8001d0:	83 ec 04             	sub    $0x4,%esp
  8001d3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001d9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001dc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001df:	e8 dc 0a 00 00       	call   800cc0 <__umoddi3>
  8001e4:	83 c4 14             	add    $0x14,%esp
  8001e7:	0f be 80 4f 0e 80 00 	movsbl 0x800e4f(%eax),%eax
  8001ee:	50                   	push   %eax
  8001ef:	ff d7                	call   *%edi
}
  8001f1:	83 c4 10             	add    $0x10,%esp
  8001f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f7:	5b                   	pop    %ebx
  8001f8:	5e                   	pop    %esi
  8001f9:	5f                   	pop    %edi
  8001fa:	5d                   	pop    %ebp
  8001fb:	c3                   	ret    

008001fc <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
  8001ff:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800202:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800206:	8b 10                	mov    (%eax),%edx
  800208:	3b 50 04             	cmp    0x4(%eax),%edx
  80020b:	73 0a                	jae    800217 <sprintputch+0x1b>
		*b->buf++ = ch;
  80020d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800210:	89 08                	mov    %ecx,(%eax)
  800212:	8b 45 08             	mov    0x8(%ebp),%eax
  800215:	88 02                	mov    %al,(%edx)
}
  800217:	5d                   	pop    %ebp
  800218:	c3                   	ret    

00800219 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800219:	55                   	push   %ebp
  80021a:	89 e5                	mov    %esp,%ebp
  80021c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80021f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800222:	50                   	push   %eax
  800223:	ff 75 10             	pushl  0x10(%ebp)
  800226:	ff 75 0c             	pushl  0xc(%ebp)
  800229:	ff 75 08             	pushl  0x8(%ebp)
  80022c:	e8 05 00 00 00       	call   800236 <vprintfmt>
	va_end(ap);
}
  800231:	83 c4 10             	add    $0x10,%esp
  800234:	c9                   	leave  
  800235:	c3                   	ret    

00800236 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800236:	55                   	push   %ebp
  800237:	89 e5                	mov    %esp,%ebp
  800239:	57                   	push   %edi
  80023a:	56                   	push   %esi
  80023b:	53                   	push   %ebx
  80023c:	83 ec 2c             	sub    $0x2c,%esp
  80023f:	8b 75 08             	mov    0x8(%ebp),%esi
  800242:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800245:	8b 7d 10             	mov    0x10(%ebp),%edi
  800248:	eb 12                	jmp    80025c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80024a:	85 c0                	test   %eax,%eax
  80024c:	0f 84 6a 04 00 00    	je     8006bc <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800252:	83 ec 08             	sub    $0x8,%esp
  800255:	53                   	push   %ebx
  800256:	50                   	push   %eax
  800257:	ff d6                	call   *%esi
  800259:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80025c:	83 c7 01             	add    $0x1,%edi
  80025f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800263:	83 f8 25             	cmp    $0x25,%eax
  800266:	75 e2                	jne    80024a <vprintfmt+0x14>
  800268:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80026c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800273:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80027a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800281:	b9 00 00 00 00       	mov    $0x0,%ecx
  800286:	eb 07                	jmp    80028f <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800288:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80028b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80028f:	8d 47 01             	lea    0x1(%edi),%eax
  800292:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800295:	0f b6 07             	movzbl (%edi),%eax
  800298:	0f b6 d0             	movzbl %al,%edx
  80029b:	83 e8 23             	sub    $0x23,%eax
  80029e:	3c 55                	cmp    $0x55,%al
  8002a0:	0f 87 fb 03 00 00    	ja     8006a1 <vprintfmt+0x46b>
  8002a6:	0f b6 c0             	movzbl %al,%eax
  8002a9:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  8002b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  8002b3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002b7:	eb d6                	jmp    80028f <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8002c1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  8002c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002c7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002cb:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002ce:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002d1:	83 f9 09             	cmp    $0x9,%ecx
  8002d4:	77 3f                	ja     800315 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  8002d6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002d9:	eb e9                	jmp    8002c4 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  8002db:	8b 45 14             	mov    0x14(%ebp),%eax
  8002de:	8b 00                	mov    (%eax),%eax
  8002e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e6:	8d 40 04             	lea    0x4(%eax),%eax
  8002e9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8002ef:	eb 2a                	jmp    80031b <vprintfmt+0xe5>
  8002f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fb:	0f 49 d0             	cmovns %eax,%edx
  8002fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800301:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800304:	eb 89                	jmp    80028f <vprintfmt+0x59>
  800306:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800309:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800310:	e9 7a ff ff ff       	jmp    80028f <vprintfmt+0x59>
  800315:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800318:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  80031b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80031f:	0f 89 6a ff ff ff    	jns    80028f <vprintfmt+0x59>
				width = precision, precision = -1;
  800325:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800328:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80032b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800332:	e9 58 ff ff ff       	jmp    80028f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  800337:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80033a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  80033d:	e9 4d ff ff ff       	jmp    80028f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800342:	8b 45 14             	mov    0x14(%ebp),%eax
  800345:	8d 78 04             	lea    0x4(%eax),%edi
  800348:	83 ec 08             	sub    $0x8,%esp
  80034b:	53                   	push   %ebx
  80034c:	ff 30                	pushl  (%eax)
  80034e:	ff d6                	call   *%esi
			break;
  800350:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800353:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800356:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  800359:	e9 fe fe ff ff       	jmp    80025c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80035e:	8b 45 14             	mov    0x14(%ebp),%eax
  800361:	8d 78 04             	lea    0x4(%eax),%edi
  800364:	8b 00                	mov    (%eax),%eax
  800366:	99                   	cltd   
  800367:	31 d0                	xor    %edx,%eax
  800369:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80036b:	83 f8 07             	cmp    $0x7,%eax
  80036e:	7f 0b                	jg     80037b <vprintfmt+0x145>
  800370:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  800377:	85 d2                	test   %edx,%edx
  800379:	75 1b                	jne    800396 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80037b:	50                   	push   %eax
  80037c:	68 67 0e 80 00       	push   $0x800e67
  800381:	53                   	push   %ebx
  800382:	56                   	push   %esi
  800383:	e8 91 fe ff ff       	call   800219 <printfmt>
  800388:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80038b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80038e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800391:	e9 c6 fe ff ff       	jmp    80025c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800396:	52                   	push   %edx
  800397:	68 70 0e 80 00       	push   $0x800e70
  80039c:	53                   	push   %ebx
  80039d:	56                   	push   %esi
  80039e:	e8 76 fe ff ff       	call   800219 <printfmt>
  8003a3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ac:	e9 ab fe ff ff       	jmp    80025c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b4:	83 c0 04             	add    $0x4,%eax
  8003b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003bf:	85 ff                	test   %edi,%edi
  8003c1:	b8 60 0e 80 00       	mov    $0x800e60,%eax
  8003c6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003c9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003cd:	0f 8e 94 00 00 00    	jle    800467 <vprintfmt+0x231>
  8003d3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003d7:	0f 84 98 00 00 00    	je     800475 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003dd:	83 ec 08             	sub    $0x8,%esp
  8003e0:	ff 75 d0             	pushl  -0x30(%ebp)
  8003e3:	57                   	push   %edi
  8003e4:	e8 5b 03 00 00       	call   800744 <strnlen>
  8003e9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003ec:	29 c1                	sub    %eax,%ecx
  8003ee:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003f1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003f4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8003f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003fb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8003fe:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800400:	eb 0f                	jmp    800411 <vprintfmt+0x1db>
					putch(padc, putdat);
  800402:	83 ec 08             	sub    $0x8,%esp
  800405:	53                   	push   %ebx
  800406:	ff 75 e0             	pushl  -0x20(%ebp)
  800409:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80040b:	83 ef 01             	sub    $0x1,%edi
  80040e:	83 c4 10             	add    $0x10,%esp
  800411:	85 ff                	test   %edi,%edi
  800413:	7f ed                	jg     800402 <vprintfmt+0x1cc>
  800415:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800418:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80041b:	85 c9                	test   %ecx,%ecx
  80041d:	b8 00 00 00 00       	mov    $0x0,%eax
  800422:	0f 49 c1             	cmovns %ecx,%eax
  800425:	29 c1                	sub    %eax,%ecx
  800427:	89 75 08             	mov    %esi,0x8(%ebp)
  80042a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80042d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800430:	89 cb                	mov    %ecx,%ebx
  800432:	eb 4d                	jmp    800481 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800434:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800438:	74 1b                	je     800455 <vprintfmt+0x21f>
  80043a:	0f be c0             	movsbl %al,%eax
  80043d:	83 e8 20             	sub    $0x20,%eax
  800440:	83 f8 5e             	cmp    $0x5e,%eax
  800443:	76 10                	jbe    800455 <vprintfmt+0x21f>
					putch('?', putdat);
  800445:	83 ec 08             	sub    $0x8,%esp
  800448:	ff 75 0c             	pushl  0xc(%ebp)
  80044b:	6a 3f                	push   $0x3f
  80044d:	ff 55 08             	call   *0x8(%ebp)
  800450:	83 c4 10             	add    $0x10,%esp
  800453:	eb 0d                	jmp    800462 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800455:	83 ec 08             	sub    $0x8,%esp
  800458:	ff 75 0c             	pushl  0xc(%ebp)
  80045b:	52                   	push   %edx
  80045c:	ff 55 08             	call   *0x8(%ebp)
  80045f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800462:	83 eb 01             	sub    $0x1,%ebx
  800465:	eb 1a                	jmp    800481 <vprintfmt+0x24b>
  800467:	89 75 08             	mov    %esi,0x8(%ebp)
  80046a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80046d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800470:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800473:	eb 0c                	jmp    800481 <vprintfmt+0x24b>
  800475:	89 75 08             	mov    %esi,0x8(%ebp)
  800478:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80047e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800481:	83 c7 01             	add    $0x1,%edi
  800484:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800488:	0f be d0             	movsbl %al,%edx
  80048b:	85 d2                	test   %edx,%edx
  80048d:	74 23                	je     8004b2 <vprintfmt+0x27c>
  80048f:	85 f6                	test   %esi,%esi
  800491:	78 a1                	js     800434 <vprintfmt+0x1fe>
  800493:	83 ee 01             	sub    $0x1,%esi
  800496:	79 9c                	jns    800434 <vprintfmt+0x1fe>
  800498:	89 df                	mov    %ebx,%edi
  80049a:	8b 75 08             	mov    0x8(%ebp),%esi
  80049d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004a0:	eb 18                	jmp    8004ba <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004a2:	83 ec 08             	sub    $0x8,%esp
  8004a5:	53                   	push   %ebx
  8004a6:	6a 20                	push   $0x20
  8004a8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004aa:	83 ef 01             	sub    $0x1,%edi
  8004ad:	83 c4 10             	add    $0x10,%esp
  8004b0:	eb 08                	jmp    8004ba <vprintfmt+0x284>
  8004b2:	89 df                	mov    %ebx,%edi
  8004b4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004ba:	85 ff                	test   %edi,%edi
  8004bc:	7f e4                	jg     8004a2 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004be:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004c1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8004c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004c7:	e9 90 fd ff ff       	jmp    80025c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004cc:	83 f9 01             	cmp    $0x1,%ecx
  8004cf:	7e 19                	jle    8004ea <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d4:	8b 50 04             	mov    0x4(%eax),%edx
  8004d7:	8b 00                	mov    (%eax),%eax
  8004d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004dc:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004df:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e2:	8d 40 08             	lea    0x8(%eax),%eax
  8004e5:	89 45 14             	mov    %eax,0x14(%ebp)
  8004e8:	eb 38                	jmp    800522 <vprintfmt+0x2ec>
	else if (lflag)
  8004ea:	85 c9                	test   %ecx,%ecx
  8004ec:	74 1b                	je     800509 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f1:	8b 00                	mov    (%eax),%eax
  8004f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004f6:	89 c1                	mov    %eax,%ecx
  8004f8:	c1 f9 1f             	sar    $0x1f,%ecx
  8004fb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004fe:	8b 45 14             	mov    0x14(%ebp),%eax
  800501:	8d 40 04             	lea    0x4(%eax),%eax
  800504:	89 45 14             	mov    %eax,0x14(%ebp)
  800507:	eb 19                	jmp    800522 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800509:	8b 45 14             	mov    0x14(%ebp),%eax
  80050c:	8b 00                	mov    (%eax),%eax
  80050e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800511:	89 c1                	mov    %eax,%ecx
  800513:	c1 f9 1f             	sar    $0x1f,%ecx
  800516:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800519:	8b 45 14             	mov    0x14(%ebp),%eax
  80051c:	8d 40 04             	lea    0x4(%eax),%eax
  80051f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800522:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800525:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800528:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80052d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800531:	0f 89 36 01 00 00    	jns    80066d <vprintfmt+0x437>
				putch('-', putdat);
  800537:	83 ec 08             	sub    $0x8,%esp
  80053a:	53                   	push   %ebx
  80053b:	6a 2d                	push   $0x2d
  80053d:	ff d6                	call   *%esi
				num = -(long long) num;
  80053f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800542:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800545:	f7 da                	neg    %edx
  800547:	83 d1 00             	adc    $0x0,%ecx
  80054a:	f7 d9                	neg    %ecx
  80054c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80054f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800554:	e9 14 01 00 00       	jmp    80066d <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800559:	83 f9 01             	cmp    $0x1,%ecx
  80055c:	7e 18                	jle    800576 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80055e:	8b 45 14             	mov    0x14(%ebp),%eax
  800561:	8b 10                	mov    (%eax),%edx
  800563:	8b 48 04             	mov    0x4(%eax),%ecx
  800566:	8d 40 08             	lea    0x8(%eax),%eax
  800569:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80056c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800571:	e9 f7 00 00 00       	jmp    80066d <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800576:	85 c9                	test   %ecx,%ecx
  800578:	74 1a                	je     800594 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80057a:	8b 45 14             	mov    0x14(%ebp),%eax
  80057d:	8b 10                	mov    (%eax),%edx
  80057f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800584:	8d 40 04             	lea    0x4(%eax),%eax
  800587:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80058a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80058f:	e9 d9 00 00 00       	jmp    80066d <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800594:	8b 45 14             	mov    0x14(%ebp),%eax
  800597:	8b 10                	mov    (%eax),%edx
  800599:	b9 00 00 00 00       	mov    $0x0,%ecx
  80059e:	8d 40 04             	lea    0x4(%eax),%eax
  8005a1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005a4:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a9:	e9 bf 00 00 00       	jmp    80066d <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005ae:	83 f9 01             	cmp    $0x1,%ecx
  8005b1:	7e 13                	jle    8005c6 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  8005b3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b6:	8b 50 04             	mov    0x4(%eax),%edx
  8005b9:	8b 00                	mov    (%eax),%eax
  8005bb:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005be:	8d 49 08             	lea    0x8(%ecx),%ecx
  8005c1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005c4:	eb 28                	jmp    8005ee <vprintfmt+0x3b8>
	else if (lflag)
  8005c6:	85 c9                	test   %ecx,%ecx
  8005c8:	74 13                	je     8005dd <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  8005ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cd:	8b 10                	mov    (%eax),%edx
  8005cf:	89 d0                	mov    %edx,%eax
  8005d1:	99                   	cltd   
  8005d2:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005d5:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005d8:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005db:	eb 11                	jmp    8005ee <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8005dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e0:	8b 10                	mov    (%eax),%edx
  8005e2:	89 d0                	mov    %edx,%eax
  8005e4:	99                   	cltd   
  8005e5:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005e8:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005eb:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8005ee:	89 d1                	mov    %edx,%ecx
  8005f0:	89 c2                	mov    %eax,%edx
			base = 8;
  8005f2:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8005f7:	eb 74                	jmp    80066d <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8005f9:	83 ec 08             	sub    $0x8,%esp
  8005fc:	53                   	push   %ebx
  8005fd:	6a 30                	push   $0x30
  8005ff:	ff d6                	call   *%esi
			putch('x', putdat);
  800601:	83 c4 08             	add    $0x8,%esp
  800604:	53                   	push   %ebx
  800605:	6a 78                	push   $0x78
  800607:	ff d6                	call   *%esi
			num = (unsigned long long)
  800609:	8b 45 14             	mov    0x14(%ebp),%eax
  80060c:	8b 10                	mov    (%eax),%edx
  80060e:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800613:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800616:	8d 40 04             	lea    0x4(%eax),%eax
  800619:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80061c:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800621:	eb 4a                	jmp    80066d <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800623:	83 f9 01             	cmp    $0x1,%ecx
  800626:	7e 15                	jle    80063d <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  800628:	8b 45 14             	mov    0x14(%ebp),%eax
  80062b:	8b 10                	mov    (%eax),%edx
  80062d:	8b 48 04             	mov    0x4(%eax),%ecx
  800630:	8d 40 08             	lea    0x8(%eax),%eax
  800633:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800636:	b8 10 00 00 00       	mov    $0x10,%eax
  80063b:	eb 30                	jmp    80066d <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80063d:	85 c9                	test   %ecx,%ecx
  80063f:	74 17                	je     800658 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800641:	8b 45 14             	mov    0x14(%ebp),%eax
  800644:	8b 10                	mov    (%eax),%edx
  800646:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064b:	8d 40 04             	lea    0x4(%eax),%eax
  80064e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800651:	b8 10 00 00 00       	mov    $0x10,%eax
  800656:	eb 15                	jmp    80066d <vprintfmt+0x437>
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

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800668:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80066d:	83 ec 0c             	sub    $0xc,%esp
  800670:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800674:	57                   	push   %edi
  800675:	ff 75 e0             	pushl  -0x20(%ebp)
  800678:	50                   	push   %eax
  800679:	51                   	push   %ecx
  80067a:	52                   	push   %edx
  80067b:	89 da                	mov    %ebx,%edx
  80067d:	89 f0                	mov    %esi,%eax
  80067f:	e8 c9 fa ff ff       	call   80014d <printnum>
			break;
  800684:	83 c4 20             	add    $0x20,%esp
  800687:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80068a:	e9 cd fb ff ff       	jmp    80025c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80068f:	83 ec 08             	sub    $0x8,%esp
  800692:	53                   	push   %ebx
  800693:	52                   	push   %edx
  800694:	ff d6                	call   *%esi
			break;
  800696:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800699:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80069c:	e9 bb fb ff ff       	jmp    80025c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006a1:	83 ec 08             	sub    $0x8,%esp
  8006a4:	53                   	push   %ebx
  8006a5:	6a 25                	push   $0x25
  8006a7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006a9:	83 c4 10             	add    $0x10,%esp
  8006ac:	eb 03                	jmp    8006b1 <vprintfmt+0x47b>
  8006ae:	83 ef 01             	sub    $0x1,%edi
  8006b1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006b5:	75 f7                	jne    8006ae <vprintfmt+0x478>
  8006b7:	e9 a0 fb ff ff       	jmp    80025c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006bf:	5b                   	pop    %ebx
  8006c0:	5e                   	pop    %esi
  8006c1:	5f                   	pop    %edi
  8006c2:	5d                   	pop    %ebp
  8006c3:	c3                   	ret    

008006c4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006c4:	55                   	push   %ebp
  8006c5:	89 e5                	mov    %esp,%ebp
  8006c7:	83 ec 18             	sub    $0x18,%esp
  8006ca:	8b 45 08             	mov    0x8(%ebp),%eax
  8006cd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006d3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006d7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006e1:	85 c0                	test   %eax,%eax
  8006e3:	74 26                	je     80070b <vsnprintf+0x47>
  8006e5:	85 d2                	test   %edx,%edx
  8006e7:	7e 22                	jle    80070b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006e9:	ff 75 14             	pushl  0x14(%ebp)
  8006ec:	ff 75 10             	pushl  0x10(%ebp)
  8006ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006f2:	50                   	push   %eax
  8006f3:	68 fc 01 80 00       	push   $0x8001fc
  8006f8:	e8 39 fb ff ff       	call   800236 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006fd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800700:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800703:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800706:	83 c4 10             	add    $0x10,%esp
  800709:	eb 05                	jmp    800710 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80070b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800710:	c9                   	leave  
  800711:	c3                   	ret    

00800712 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800712:	55                   	push   %ebp
  800713:	89 e5                	mov    %esp,%ebp
  800715:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800718:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80071b:	50                   	push   %eax
  80071c:	ff 75 10             	pushl  0x10(%ebp)
  80071f:	ff 75 0c             	pushl  0xc(%ebp)
  800722:	ff 75 08             	pushl  0x8(%ebp)
  800725:	e8 9a ff ff ff       	call   8006c4 <vsnprintf>
	va_end(ap);

	return rc;
}
  80072a:	c9                   	leave  
  80072b:	c3                   	ret    

0080072c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80072c:	55                   	push   %ebp
  80072d:	89 e5                	mov    %esp,%ebp
  80072f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800732:	b8 00 00 00 00       	mov    $0x0,%eax
  800737:	eb 03                	jmp    80073c <strlen+0x10>
		n++;
  800739:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80073c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800740:	75 f7                	jne    800739 <strlen+0xd>
		n++;
	return n;
}
  800742:	5d                   	pop    %ebp
  800743:	c3                   	ret    

00800744 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800744:	55                   	push   %ebp
  800745:	89 e5                	mov    %esp,%ebp
  800747:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80074a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80074d:	ba 00 00 00 00       	mov    $0x0,%edx
  800752:	eb 03                	jmp    800757 <strnlen+0x13>
		n++;
  800754:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800757:	39 c2                	cmp    %eax,%edx
  800759:	74 08                	je     800763 <strnlen+0x1f>
  80075b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80075f:	75 f3                	jne    800754 <strnlen+0x10>
  800761:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800763:	5d                   	pop    %ebp
  800764:	c3                   	ret    

00800765 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800765:	55                   	push   %ebp
  800766:	89 e5                	mov    %esp,%ebp
  800768:	53                   	push   %ebx
  800769:	8b 45 08             	mov    0x8(%ebp),%eax
  80076c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80076f:	89 c2                	mov    %eax,%edx
  800771:	83 c2 01             	add    $0x1,%edx
  800774:	83 c1 01             	add    $0x1,%ecx
  800777:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80077b:	88 5a ff             	mov    %bl,-0x1(%edx)
  80077e:	84 db                	test   %bl,%bl
  800780:	75 ef                	jne    800771 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800782:	5b                   	pop    %ebx
  800783:	5d                   	pop    %ebp
  800784:	c3                   	ret    

00800785 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800785:	55                   	push   %ebp
  800786:	89 e5                	mov    %esp,%ebp
  800788:	53                   	push   %ebx
  800789:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80078c:	53                   	push   %ebx
  80078d:	e8 9a ff ff ff       	call   80072c <strlen>
  800792:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800795:	ff 75 0c             	pushl  0xc(%ebp)
  800798:	01 d8                	add    %ebx,%eax
  80079a:	50                   	push   %eax
  80079b:	e8 c5 ff ff ff       	call   800765 <strcpy>
	return dst;
}
  8007a0:	89 d8                	mov    %ebx,%eax
  8007a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007a5:	c9                   	leave  
  8007a6:	c3                   	ret    

008007a7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007a7:	55                   	push   %ebp
  8007a8:	89 e5                	mov    %esp,%ebp
  8007aa:	56                   	push   %esi
  8007ab:	53                   	push   %ebx
  8007ac:	8b 75 08             	mov    0x8(%ebp),%esi
  8007af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007b2:	89 f3                	mov    %esi,%ebx
  8007b4:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b7:	89 f2                	mov    %esi,%edx
  8007b9:	eb 0f                	jmp    8007ca <strncpy+0x23>
		*dst++ = *src;
  8007bb:	83 c2 01             	add    $0x1,%edx
  8007be:	0f b6 01             	movzbl (%ecx),%eax
  8007c1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007c4:	80 39 01             	cmpb   $0x1,(%ecx)
  8007c7:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ca:	39 da                	cmp    %ebx,%edx
  8007cc:	75 ed                	jne    8007bb <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ce:	89 f0                	mov    %esi,%eax
  8007d0:	5b                   	pop    %ebx
  8007d1:	5e                   	pop    %esi
  8007d2:	5d                   	pop    %ebp
  8007d3:	c3                   	ret    

008007d4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007d4:	55                   	push   %ebp
  8007d5:	89 e5                	mov    %esp,%ebp
  8007d7:	56                   	push   %esi
  8007d8:	53                   	push   %ebx
  8007d9:	8b 75 08             	mov    0x8(%ebp),%esi
  8007dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007df:	8b 55 10             	mov    0x10(%ebp),%edx
  8007e2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007e4:	85 d2                	test   %edx,%edx
  8007e6:	74 21                	je     800809 <strlcpy+0x35>
  8007e8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007ec:	89 f2                	mov    %esi,%edx
  8007ee:	eb 09                	jmp    8007f9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007f0:	83 c2 01             	add    $0x1,%edx
  8007f3:	83 c1 01             	add    $0x1,%ecx
  8007f6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007f9:	39 c2                	cmp    %eax,%edx
  8007fb:	74 09                	je     800806 <strlcpy+0x32>
  8007fd:	0f b6 19             	movzbl (%ecx),%ebx
  800800:	84 db                	test   %bl,%bl
  800802:	75 ec                	jne    8007f0 <strlcpy+0x1c>
  800804:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800806:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800809:	29 f0                	sub    %esi,%eax
}
  80080b:	5b                   	pop    %ebx
  80080c:	5e                   	pop    %esi
  80080d:	5d                   	pop    %ebp
  80080e:	c3                   	ret    

0080080f <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80080f:	55                   	push   %ebp
  800810:	89 e5                	mov    %esp,%ebp
  800812:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800815:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800818:	eb 06                	jmp    800820 <strcmp+0x11>
		p++, q++;
  80081a:	83 c1 01             	add    $0x1,%ecx
  80081d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800820:	0f b6 01             	movzbl (%ecx),%eax
  800823:	84 c0                	test   %al,%al
  800825:	74 04                	je     80082b <strcmp+0x1c>
  800827:	3a 02                	cmp    (%edx),%al
  800829:	74 ef                	je     80081a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80082b:	0f b6 c0             	movzbl %al,%eax
  80082e:	0f b6 12             	movzbl (%edx),%edx
  800831:	29 d0                	sub    %edx,%eax
}
  800833:	5d                   	pop    %ebp
  800834:	c3                   	ret    

00800835 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800835:	55                   	push   %ebp
  800836:	89 e5                	mov    %esp,%ebp
  800838:	53                   	push   %ebx
  800839:	8b 45 08             	mov    0x8(%ebp),%eax
  80083c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80083f:	89 c3                	mov    %eax,%ebx
  800841:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800844:	eb 06                	jmp    80084c <strncmp+0x17>
		n--, p++, q++;
  800846:	83 c0 01             	add    $0x1,%eax
  800849:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80084c:	39 d8                	cmp    %ebx,%eax
  80084e:	74 15                	je     800865 <strncmp+0x30>
  800850:	0f b6 08             	movzbl (%eax),%ecx
  800853:	84 c9                	test   %cl,%cl
  800855:	74 04                	je     80085b <strncmp+0x26>
  800857:	3a 0a                	cmp    (%edx),%cl
  800859:	74 eb                	je     800846 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80085b:	0f b6 00             	movzbl (%eax),%eax
  80085e:	0f b6 12             	movzbl (%edx),%edx
  800861:	29 d0                	sub    %edx,%eax
  800863:	eb 05                	jmp    80086a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800865:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80086a:	5b                   	pop    %ebx
  80086b:	5d                   	pop    %ebp
  80086c:	c3                   	ret    

0080086d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80086d:	55                   	push   %ebp
  80086e:	89 e5                	mov    %esp,%ebp
  800870:	8b 45 08             	mov    0x8(%ebp),%eax
  800873:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800877:	eb 07                	jmp    800880 <strchr+0x13>
		if (*s == c)
  800879:	38 ca                	cmp    %cl,%dl
  80087b:	74 0f                	je     80088c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80087d:	83 c0 01             	add    $0x1,%eax
  800880:	0f b6 10             	movzbl (%eax),%edx
  800883:	84 d2                	test   %dl,%dl
  800885:	75 f2                	jne    800879 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800887:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80088c:	5d                   	pop    %ebp
  80088d:	c3                   	ret    

0080088e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80088e:	55                   	push   %ebp
  80088f:	89 e5                	mov    %esp,%ebp
  800891:	8b 45 08             	mov    0x8(%ebp),%eax
  800894:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800898:	eb 03                	jmp    80089d <strfind+0xf>
  80089a:	83 c0 01             	add    $0x1,%eax
  80089d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008a0:	38 ca                	cmp    %cl,%dl
  8008a2:	74 04                	je     8008a8 <strfind+0x1a>
  8008a4:	84 d2                	test   %dl,%dl
  8008a6:	75 f2                	jne    80089a <strfind+0xc>
			break;
	return (char *) s;
}
  8008a8:	5d                   	pop    %ebp
  8008a9:	c3                   	ret    

008008aa <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008aa:	55                   	push   %ebp
  8008ab:	89 e5                	mov    %esp,%ebp
  8008ad:	57                   	push   %edi
  8008ae:	56                   	push   %esi
  8008af:	53                   	push   %ebx
  8008b0:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008b3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008b6:	85 c9                	test   %ecx,%ecx
  8008b8:	74 36                	je     8008f0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008ba:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008c0:	75 28                	jne    8008ea <memset+0x40>
  8008c2:	f6 c1 03             	test   $0x3,%cl
  8008c5:	75 23                	jne    8008ea <memset+0x40>
		c &= 0xFF;
  8008c7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008cb:	89 d3                	mov    %edx,%ebx
  8008cd:	c1 e3 08             	shl    $0x8,%ebx
  8008d0:	89 d6                	mov    %edx,%esi
  8008d2:	c1 e6 18             	shl    $0x18,%esi
  8008d5:	89 d0                	mov    %edx,%eax
  8008d7:	c1 e0 10             	shl    $0x10,%eax
  8008da:	09 f0                	or     %esi,%eax
  8008dc:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008de:	89 d8                	mov    %ebx,%eax
  8008e0:	09 d0                	or     %edx,%eax
  8008e2:	c1 e9 02             	shr    $0x2,%ecx
  8008e5:	fc                   	cld    
  8008e6:	f3 ab                	rep stos %eax,%es:(%edi)
  8008e8:	eb 06                	jmp    8008f0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008ed:	fc                   	cld    
  8008ee:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008f0:	89 f8                	mov    %edi,%eax
  8008f2:	5b                   	pop    %ebx
  8008f3:	5e                   	pop    %esi
  8008f4:	5f                   	pop    %edi
  8008f5:	5d                   	pop    %ebp
  8008f6:	c3                   	ret    

008008f7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008f7:	55                   	push   %ebp
  8008f8:	89 e5                	mov    %esp,%ebp
  8008fa:	57                   	push   %edi
  8008fb:	56                   	push   %esi
  8008fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ff:	8b 75 0c             	mov    0xc(%ebp),%esi
  800902:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800905:	39 c6                	cmp    %eax,%esi
  800907:	73 35                	jae    80093e <memmove+0x47>
  800909:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80090c:	39 d0                	cmp    %edx,%eax
  80090e:	73 2e                	jae    80093e <memmove+0x47>
		s += n;
		d += n;
  800910:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800913:	89 d6                	mov    %edx,%esi
  800915:	09 fe                	or     %edi,%esi
  800917:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80091d:	75 13                	jne    800932 <memmove+0x3b>
  80091f:	f6 c1 03             	test   $0x3,%cl
  800922:	75 0e                	jne    800932 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800924:	83 ef 04             	sub    $0x4,%edi
  800927:	8d 72 fc             	lea    -0x4(%edx),%esi
  80092a:	c1 e9 02             	shr    $0x2,%ecx
  80092d:	fd                   	std    
  80092e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800930:	eb 09                	jmp    80093b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800932:	83 ef 01             	sub    $0x1,%edi
  800935:	8d 72 ff             	lea    -0x1(%edx),%esi
  800938:	fd                   	std    
  800939:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80093b:	fc                   	cld    
  80093c:	eb 1d                	jmp    80095b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093e:	89 f2                	mov    %esi,%edx
  800940:	09 c2                	or     %eax,%edx
  800942:	f6 c2 03             	test   $0x3,%dl
  800945:	75 0f                	jne    800956 <memmove+0x5f>
  800947:	f6 c1 03             	test   $0x3,%cl
  80094a:	75 0a                	jne    800956 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80094c:	c1 e9 02             	shr    $0x2,%ecx
  80094f:	89 c7                	mov    %eax,%edi
  800951:	fc                   	cld    
  800952:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800954:	eb 05                	jmp    80095b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800956:	89 c7                	mov    %eax,%edi
  800958:	fc                   	cld    
  800959:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80095b:	5e                   	pop    %esi
  80095c:	5f                   	pop    %edi
  80095d:	5d                   	pop    %ebp
  80095e:	c3                   	ret    

0080095f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80095f:	55                   	push   %ebp
  800960:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800962:	ff 75 10             	pushl  0x10(%ebp)
  800965:	ff 75 0c             	pushl  0xc(%ebp)
  800968:	ff 75 08             	pushl  0x8(%ebp)
  80096b:	e8 87 ff ff ff       	call   8008f7 <memmove>
}
  800970:	c9                   	leave  
  800971:	c3                   	ret    

00800972 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800972:	55                   	push   %ebp
  800973:	89 e5                	mov    %esp,%ebp
  800975:	56                   	push   %esi
  800976:	53                   	push   %ebx
  800977:	8b 45 08             	mov    0x8(%ebp),%eax
  80097a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80097d:	89 c6                	mov    %eax,%esi
  80097f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800982:	eb 1a                	jmp    80099e <memcmp+0x2c>
		if (*s1 != *s2)
  800984:	0f b6 08             	movzbl (%eax),%ecx
  800987:	0f b6 1a             	movzbl (%edx),%ebx
  80098a:	38 d9                	cmp    %bl,%cl
  80098c:	74 0a                	je     800998 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80098e:	0f b6 c1             	movzbl %cl,%eax
  800991:	0f b6 db             	movzbl %bl,%ebx
  800994:	29 d8                	sub    %ebx,%eax
  800996:	eb 0f                	jmp    8009a7 <memcmp+0x35>
		s1++, s2++;
  800998:	83 c0 01             	add    $0x1,%eax
  80099b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80099e:	39 f0                	cmp    %esi,%eax
  8009a0:	75 e2                	jne    800984 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a7:	5b                   	pop    %ebx
  8009a8:	5e                   	pop    %esi
  8009a9:	5d                   	pop    %ebp
  8009aa:	c3                   	ret    

008009ab <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ab:	55                   	push   %ebp
  8009ac:	89 e5                	mov    %esp,%ebp
  8009ae:	53                   	push   %ebx
  8009af:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009b2:	89 c1                	mov    %eax,%ecx
  8009b4:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009b7:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009bb:	eb 0a                	jmp    8009c7 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009bd:	0f b6 10             	movzbl (%eax),%edx
  8009c0:	39 da                	cmp    %ebx,%edx
  8009c2:	74 07                	je     8009cb <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009c4:	83 c0 01             	add    $0x1,%eax
  8009c7:	39 c8                	cmp    %ecx,%eax
  8009c9:	72 f2                	jb     8009bd <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009cb:	5b                   	pop    %ebx
  8009cc:	5d                   	pop    %ebp
  8009cd:	c3                   	ret    

008009ce <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009ce:	55                   	push   %ebp
  8009cf:	89 e5                	mov    %esp,%ebp
  8009d1:	57                   	push   %edi
  8009d2:	56                   	push   %esi
  8009d3:	53                   	push   %ebx
  8009d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009da:	eb 03                	jmp    8009df <strtol+0x11>
		s++;
  8009dc:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009df:	0f b6 01             	movzbl (%ecx),%eax
  8009e2:	3c 20                	cmp    $0x20,%al
  8009e4:	74 f6                	je     8009dc <strtol+0xe>
  8009e6:	3c 09                	cmp    $0x9,%al
  8009e8:	74 f2                	je     8009dc <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ea:	3c 2b                	cmp    $0x2b,%al
  8009ec:	75 0a                	jne    8009f8 <strtol+0x2a>
		s++;
  8009ee:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009f1:	bf 00 00 00 00       	mov    $0x0,%edi
  8009f6:	eb 11                	jmp    800a09 <strtol+0x3b>
  8009f8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009fd:	3c 2d                	cmp    $0x2d,%al
  8009ff:	75 08                	jne    800a09 <strtol+0x3b>
		s++, neg = 1;
  800a01:	83 c1 01             	add    $0x1,%ecx
  800a04:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a09:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a0f:	75 15                	jne    800a26 <strtol+0x58>
  800a11:	80 39 30             	cmpb   $0x30,(%ecx)
  800a14:	75 10                	jne    800a26 <strtol+0x58>
  800a16:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a1a:	75 7c                	jne    800a98 <strtol+0xca>
		s += 2, base = 16;
  800a1c:	83 c1 02             	add    $0x2,%ecx
  800a1f:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a24:	eb 16                	jmp    800a3c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a26:	85 db                	test   %ebx,%ebx
  800a28:	75 12                	jne    800a3c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a2a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a2f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a32:	75 08                	jne    800a3c <strtol+0x6e>
		s++, base = 8;
  800a34:	83 c1 01             	add    $0x1,%ecx
  800a37:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a3c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a41:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a44:	0f b6 11             	movzbl (%ecx),%edx
  800a47:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a4a:	89 f3                	mov    %esi,%ebx
  800a4c:	80 fb 09             	cmp    $0x9,%bl
  800a4f:	77 08                	ja     800a59 <strtol+0x8b>
			dig = *s - '0';
  800a51:	0f be d2             	movsbl %dl,%edx
  800a54:	83 ea 30             	sub    $0x30,%edx
  800a57:	eb 22                	jmp    800a7b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a59:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a5c:	89 f3                	mov    %esi,%ebx
  800a5e:	80 fb 19             	cmp    $0x19,%bl
  800a61:	77 08                	ja     800a6b <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a63:	0f be d2             	movsbl %dl,%edx
  800a66:	83 ea 57             	sub    $0x57,%edx
  800a69:	eb 10                	jmp    800a7b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a6b:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a6e:	89 f3                	mov    %esi,%ebx
  800a70:	80 fb 19             	cmp    $0x19,%bl
  800a73:	77 16                	ja     800a8b <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a75:	0f be d2             	movsbl %dl,%edx
  800a78:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a7b:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a7e:	7d 0b                	jge    800a8b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a80:	83 c1 01             	add    $0x1,%ecx
  800a83:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a87:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a89:	eb b9                	jmp    800a44 <strtol+0x76>

	if (endptr)
  800a8b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a8f:	74 0d                	je     800a9e <strtol+0xd0>
		*endptr = (char *) s;
  800a91:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a94:	89 0e                	mov    %ecx,(%esi)
  800a96:	eb 06                	jmp    800a9e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a98:	85 db                	test   %ebx,%ebx
  800a9a:	74 98                	je     800a34 <strtol+0x66>
  800a9c:	eb 9e                	jmp    800a3c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a9e:	89 c2                	mov    %eax,%edx
  800aa0:	f7 da                	neg    %edx
  800aa2:	85 ff                	test   %edi,%edi
  800aa4:	0f 45 c2             	cmovne %edx,%eax
}
  800aa7:	5b                   	pop    %ebx
  800aa8:	5e                   	pop    %esi
  800aa9:	5f                   	pop    %edi
  800aaa:	5d                   	pop    %ebp
  800aab:	c3                   	ret    

00800aac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800aac:	55                   	push   %ebp
  800aad:	89 e5                	mov    %esp,%ebp
  800aaf:	57                   	push   %edi
  800ab0:	56                   	push   %esi
  800ab1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab2:	b8 00 00 00 00       	mov    $0x0,%eax
  800ab7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aba:	8b 55 08             	mov    0x8(%ebp),%edx
  800abd:	89 c3                	mov    %eax,%ebx
  800abf:	89 c7                	mov    %eax,%edi
  800ac1:	89 c6                	mov    %eax,%esi
  800ac3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ac5:	5b                   	pop    %ebx
  800ac6:	5e                   	pop    %esi
  800ac7:	5f                   	pop    %edi
  800ac8:	5d                   	pop    %ebp
  800ac9:	c3                   	ret    

00800aca <sys_cgetc>:

int
sys_cgetc(void)
{
  800aca:	55                   	push   %ebp
  800acb:	89 e5                	mov    %esp,%ebp
  800acd:	57                   	push   %edi
  800ace:	56                   	push   %esi
  800acf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad0:	ba 00 00 00 00       	mov    $0x0,%edx
  800ad5:	b8 01 00 00 00       	mov    $0x1,%eax
  800ada:	89 d1                	mov    %edx,%ecx
  800adc:	89 d3                	mov    %edx,%ebx
  800ade:	89 d7                	mov    %edx,%edi
  800ae0:	89 d6                	mov    %edx,%esi
  800ae2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ae4:	5b                   	pop    %ebx
  800ae5:	5e                   	pop    %esi
  800ae6:	5f                   	pop    %edi
  800ae7:	5d                   	pop    %ebp
  800ae8:	c3                   	ret    

00800ae9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ae9:	55                   	push   %ebp
  800aea:	89 e5                	mov    %esp,%ebp
  800aec:	57                   	push   %edi
  800aed:	56                   	push   %esi
  800aee:	53                   	push   %ebx
  800aef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800af2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800af7:	b8 03 00 00 00       	mov    $0x3,%eax
  800afc:	8b 55 08             	mov    0x8(%ebp),%edx
  800aff:	89 cb                	mov    %ecx,%ebx
  800b01:	89 cf                	mov    %ecx,%edi
  800b03:	89 ce                	mov    %ecx,%esi
  800b05:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b07:	85 c0                	test   %eax,%eax
  800b09:	7e 17                	jle    800b22 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b0b:	83 ec 0c             	sub    $0xc,%esp
  800b0e:	50                   	push   %eax
  800b0f:	6a 03                	push   $0x3
  800b11:	68 60 10 80 00       	push   $0x801060
  800b16:	6a 23                	push   $0x23
  800b18:	68 7d 10 80 00       	push   $0x80107d
  800b1d:	e8 27 00 00 00       	call   800b49 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b22:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b25:	5b                   	pop    %ebx
  800b26:	5e                   	pop    %esi
  800b27:	5f                   	pop    %edi
  800b28:	5d                   	pop    %ebp
  800b29:	c3                   	ret    

00800b2a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b2a:	55                   	push   %ebp
  800b2b:	89 e5                	mov    %esp,%ebp
  800b2d:	57                   	push   %edi
  800b2e:	56                   	push   %esi
  800b2f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b30:	ba 00 00 00 00       	mov    $0x0,%edx
  800b35:	b8 02 00 00 00       	mov    $0x2,%eax
  800b3a:	89 d1                	mov    %edx,%ecx
  800b3c:	89 d3                	mov    %edx,%ebx
  800b3e:	89 d7                	mov    %edx,%edi
  800b40:	89 d6                	mov    %edx,%esi
  800b42:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b44:	5b                   	pop    %ebx
  800b45:	5e                   	pop    %esi
  800b46:	5f                   	pop    %edi
  800b47:	5d                   	pop    %ebp
  800b48:	c3                   	ret    

00800b49 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b49:	55                   	push   %ebp
  800b4a:	89 e5                	mov    %esp,%ebp
  800b4c:	56                   	push   %esi
  800b4d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b4e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b51:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b57:	e8 ce ff ff ff       	call   800b2a <sys_getenvid>
  800b5c:	83 ec 0c             	sub    $0xc,%esp
  800b5f:	ff 75 0c             	pushl  0xc(%ebp)
  800b62:	ff 75 08             	pushl  0x8(%ebp)
  800b65:	56                   	push   %esi
  800b66:	50                   	push   %eax
  800b67:	68 8c 10 80 00       	push   $0x80108c
  800b6c:	e8 c8 f5 ff ff       	call   800139 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b71:	83 c4 18             	add    $0x18,%esp
  800b74:	53                   	push   %ebx
  800b75:	ff 75 10             	pushl  0x10(%ebp)
  800b78:	e8 6b f5 ff ff       	call   8000e8 <vcprintf>
	cprintf("\n");
  800b7d:	c7 04 24 2c 0e 80 00 	movl   $0x800e2c,(%esp)
  800b84:	e8 b0 f5 ff ff       	call   800139 <cprintf>
  800b89:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b8c:	cc                   	int3   
  800b8d:	eb fd                	jmp    800b8c <_panic+0x43>
  800b8f:	90                   	nop

00800b90 <__udivdi3>:
  800b90:	55                   	push   %ebp
  800b91:	57                   	push   %edi
  800b92:	56                   	push   %esi
  800b93:	53                   	push   %ebx
  800b94:	83 ec 1c             	sub    $0x1c,%esp
  800b97:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b9b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b9f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800ba3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ba7:	85 f6                	test   %esi,%esi
  800ba9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bad:	89 ca                	mov    %ecx,%edx
  800baf:	89 f8                	mov    %edi,%eax
  800bb1:	75 3d                	jne    800bf0 <__udivdi3+0x60>
  800bb3:	39 cf                	cmp    %ecx,%edi
  800bb5:	0f 87 c5 00 00 00    	ja     800c80 <__udivdi3+0xf0>
  800bbb:	85 ff                	test   %edi,%edi
  800bbd:	89 fd                	mov    %edi,%ebp
  800bbf:	75 0b                	jne    800bcc <__udivdi3+0x3c>
  800bc1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bc6:	31 d2                	xor    %edx,%edx
  800bc8:	f7 f7                	div    %edi
  800bca:	89 c5                	mov    %eax,%ebp
  800bcc:	89 c8                	mov    %ecx,%eax
  800bce:	31 d2                	xor    %edx,%edx
  800bd0:	f7 f5                	div    %ebp
  800bd2:	89 c1                	mov    %eax,%ecx
  800bd4:	89 d8                	mov    %ebx,%eax
  800bd6:	89 cf                	mov    %ecx,%edi
  800bd8:	f7 f5                	div    %ebp
  800bda:	89 c3                	mov    %eax,%ebx
  800bdc:	89 d8                	mov    %ebx,%eax
  800bde:	89 fa                	mov    %edi,%edx
  800be0:	83 c4 1c             	add    $0x1c,%esp
  800be3:	5b                   	pop    %ebx
  800be4:	5e                   	pop    %esi
  800be5:	5f                   	pop    %edi
  800be6:	5d                   	pop    %ebp
  800be7:	c3                   	ret    
  800be8:	90                   	nop
  800be9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bf0:	39 ce                	cmp    %ecx,%esi
  800bf2:	77 74                	ja     800c68 <__udivdi3+0xd8>
  800bf4:	0f bd fe             	bsr    %esi,%edi
  800bf7:	83 f7 1f             	xor    $0x1f,%edi
  800bfa:	0f 84 98 00 00 00    	je     800c98 <__udivdi3+0x108>
  800c00:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	89 c5                	mov    %eax,%ebp
  800c09:	29 fb                	sub    %edi,%ebx
  800c0b:	d3 e6                	shl    %cl,%esi
  800c0d:	89 d9                	mov    %ebx,%ecx
  800c0f:	d3 ed                	shr    %cl,%ebp
  800c11:	89 f9                	mov    %edi,%ecx
  800c13:	d3 e0                	shl    %cl,%eax
  800c15:	09 ee                	or     %ebp,%esi
  800c17:	89 d9                	mov    %ebx,%ecx
  800c19:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c1d:	89 d5                	mov    %edx,%ebp
  800c1f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c23:	d3 ed                	shr    %cl,%ebp
  800c25:	89 f9                	mov    %edi,%ecx
  800c27:	d3 e2                	shl    %cl,%edx
  800c29:	89 d9                	mov    %ebx,%ecx
  800c2b:	d3 e8                	shr    %cl,%eax
  800c2d:	09 c2                	or     %eax,%edx
  800c2f:	89 d0                	mov    %edx,%eax
  800c31:	89 ea                	mov    %ebp,%edx
  800c33:	f7 f6                	div    %esi
  800c35:	89 d5                	mov    %edx,%ebp
  800c37:	89 c3                	mov    %eax,%ebx
  800c39:	f7 64 24 0c          	mull   0xc(%esp)
  800c3d:	39 d5                	cmp    %edx,%ebp
  800c3f:	72 10                	jb     800c51 <__udivdi3+0xc1>
  800c41:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c45:	89 f9                	mov    %edi,%ecx
  800c47:	d3 e6                	shl    %cl,%esi
  800c49:	39 c6                	cmp    %eax,%esi
  800c4b:	73 07                	jae    800c54 <__udivdi3+0xc4>
  800c4d:	39 d5                	cmp    %edx,%ebp
  800c4f:	75 03                	jne    800c54 <__udivdi3+0xc4>
  800c51:	83 eb 01             	sub    $0x1,%ebx
  800c54:	31 ff                	xor    %edi,%edi
  800c56:	89 d8                	mov    %ebx,%eax
  800c58:	89 fa                	mov    %edi,%edx
  800c5a:	83 c4 1c             	add    $0x1c,%esp
  800c5d:	5b                   	pop    %ebx
  800c5e:	5e                   	pop    %esi
  800c5f:	5f                   	pop    %edi
  800c60:	5d                   	pop    %ebp
  800c61:	c3                   	ret    
  800c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c68:	31 ff                	xor    %edi,%edi
  800c6a:	31 db                	xor    %ebx,%ebx
  800c6c:	89 d8                	mov    %ebx,%eax
  800c6e:	89 fa                	mov    %edi,%edx
  800c70:	83 c4 1c             	add    $0x1c,%esp
  800c73:	5b                   	pop    %ebx
  800c74:	5e                   	pop    %esi
  800c75:	5f                   	pop    %edi
  800c76:	5d                   	pop    %ebp
  800c77:	c3                   	ret    
  800c78:	90                   	nop
  800c79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c80:	89 d8                	mov    %ebx,%eax
  800c82:	f7 f7                	div    %edi
  800c84:	31 ff                	xor    %edi,%edi
  800c86:	89 c3                	mov    %eax,%ebx
  800c88:	89 d8                	mov    %ebx,%eax
  800c8a:	89 fa                	mov    %edi,%edx
  800c8c:	83 c4 1c             	add    $0x1c,%esp
  800c8f:	5b                   	pop    %ebx
  800c90:	5e                   	pop    %esi
  800c91:	5f                   	pop    %edi
  800c92:	5d                   	pop    %ebp
  800c93:	c3                   	ret    
  800c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c98:	39 ce                	cmp    %ecx,%esi
  800c9a:	72 0c                	jb     800ca8 <__udivdi3+0x118>
  800c9c:	31 db                	xor    %ebx,%ebx
  800c9e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800ca2:	0f 87 34 ff ff ff    	ja     800bdc <__udivdi3+0x4c>
  800ca8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800cad:	e9 2a ff ff ff       	jmp    800bdc <__udivdi3+0x4c>
  800cb2:	66 90                	xchg   %ax,%ax
  800cb4:	66 90                	xchg   %ax,%ax
  800cb6:	66 90                	xchg   %ax,%ax
  800cb8:	66 90                	xchg   %ax,%ax
  800cba:	66 90                	xchg   %ax,%ax
  800cbc:	66 90                	xchg   %ax,%ax
  800cbe:	66 90                	xchg   %ax,%ax

00800cc0 <__umoddi3>:
  800cc0:	55                   	push   %ebp
  800cc1:	57                   	push   %edi
  800cc2:	56                   	push   %esi
  800cc3:	53                   	push   %ebx
  800cc4:	83 ec 1c             	sub    $0x1c,%esp
  800cc7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800ccb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800ccf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cd7:	85 d2                	test   %edx,%edx
  800cd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ce1:	89 f3                	mov    %esi,%ebx
  800ce3:	89 3c 24             	mov    %edi,(%esp)
  800ce6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cea:	75 1c                	jne    800d08 <__umoddi3+0x48>
  800cec:	39 f7                	cmp    %esi,%edi
  800cee:	76 50                	jbe    800d40 <__umoddi3+0x80>
  800cf0:	89 c8                	mov    %ecx,%eax
  800cf2:	89 f2                	mov    %esi,%edx
  800cf4:	f7 f7                	div    %edi
  800cf6:	89 d0                	mov    %edx,%eax
  800cf8:	31 d2                	xor    %edx,%edx
  800cfa:	83 c4 1c             	add    $0x1c,%esp
  800cfd:	5b                   	pop    %ebx
  800cfe:	5e                   	pop    %esi
  800cff:	5f                   	pop    %edi
  800d00:	5d                   	pop    %ebp
  800d01:	c3                   	ret    
  800d02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d08:	39 f2                	cmp    %esi,%edx
  800d0a:	89 d0                	mov    %edx,%eax
  800d0c:	77 52                	ja     800d60 <__umoddi3+0xa0>
  800d0e:	0f bd ea             	bsr    %edx,%ebp
  800d11:	83 f5 1f             	xor    $0x1f,%ebp
  800d14:	75 5a                	jne    800d70 <__umoddi3+0xb0>
  800d16:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d1a:	0f 82 e0 00 00 00    	jb     800e00 <__umoddi3+0x140>
  800d20:	39 0c 24             	cmp    %ecx,(%esp)
  800d23:	0f 86 d7 00 00 00    	jbe    800e00 <__umoddi3+0x140>
  800d29:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d2d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d31:	83 c4 1c             	add    $0x1c,%esp
  800d34:	5b                   	pop    %ebx
  800d35:	5e                   	pop    %esi
  800d36:	5f                   	pop    %edi
  800d37:	5d                   	pop    %ebp
  800d38:	c3                   	ret    
  800d39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d40:	85 ff                	test   %edi,%edi
  800d42:	89 fd                	mov    %edi,%ebp
  800d44:	75 0b                	jne    800d51 <__umoddi3+0x91>
  800d46:	b8 01 00 00 00       	mov    $0x1,%eax
  800d4b:	31 d2                	xor    %edx,%edx
  800d4d:	f7 f7                	div    %edi
  800d4f:	89 c5                	mov    %eax,%ebp
  800d51:	89 f0                	mov    %esi,%eax
  800d53:	31 d2                	xor    %edx,%edx
  800d55:	f7 f5                	div    %ebp
  800d57:	89 c8                	mov    %ecx,%eax
  800d59:	f7 f5                	div    %ebp
  800d5b:	89 d0                	mov    %edx,%eax
  800d5d:	eb 99                	jmp    800cf8 <__umoddi3+0x38>
  800d5f:	90                   	nop
  800d60:	89 c8                	mov    %ecx,%eax
  800d62:	89 f2                	mov    %esi,%edx
  800d64:	83 c4 1c             	add    $0x1c,%esp
  800d67:	5b                   	pop    %ebx
  800d68:	5e                   	pop    %esi
  800d69:	5f                   	pop    %edi
  800d6a:	5d                   	pop    %ebp
  800d6b:	c3                   	ret    
  800d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d70:	8b 34 24             	mov    (%esp),%esi
  800d73:	bf 20 00 00 00       	mov    $0x20,%edi
  800d78:	89 e9                	mov    %ebp,%ecx
  800d7a:	29 ef                	sub    %ebp,%edi
  800d7c:	d3 e0                	shl    %cl,%eax
  800d7e:	89 f9                	mov    %edi,%ecx
  800d80:	89 f2                	mov    %esi,%edx
  800d82:	d3 ea                	shr    %cl,%edx
  800d84:	89 e9                	mov    %ebp,%ecx
  800d86:	09 c2                	or     %eax,%edx
  800d88:	89 d8                	mov    %ebx,%eax
  800d8a:	89 14 24             	mov    %edx,(%esp)
  800d8d:	89 f2                	mov    %esi,%edx
  800d8f:	d3 e2                	shl    %cl,%edx
  800d91:	89 f9                	mov    %edi,%ecx
  800d93:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d97:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d9b:	d3 e8                	shr    %cl,%eax
  800d9d:	89 e9                	mov    %ebp,%ecx
  800d9f:	89 c6                	mov    %eax,%esi
  800da1:	d3 e3                	shl    %cl,%ebx
  800da3:	89 f9                	mov    %edi,%ecx
  800da5:	89 d0                	mov    %edx,%eax
  800da7:	d3 e8                	shr    %cl,%eax
  800da9:	89 e9                	mov    %ebp,%ecx
  800dab:	09 d8                	or     %ebx,%eax
  800dad:	89 d3                	mov    %edx,%ebx
  800daf:	89 f2                	mov    %esi,%edx
  800db1:	f7 34 24             	divl   (%esp)
  800db4:	89 d6                	mov    %edx,%esi
  800db6:	d3 e3                	shl    %cl,%ebx
  800db8:	f7 64 24 04          	mull   0x4(%esp)
  800dbc:	39 d6                	cmp    %edx,%esi
  800dbe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800dc2:	89 d1                	mov    %edx,%ecx
  800dc4:	89 c3                	mov    %eax,%ebx
  800dc6:	72 08                	jb     800dd0 <__umoddi3+0x110>
  800dc8:	75 11                	jne    800ddb <__umoddi3+0x11b>
  800dca:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dce:	73 0b                	jae    800ddb <__umoddi3+0x11b>
  800dd0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800dd4:	1b 14 24             	sbb    (%esp),%edx
  800dd7:	89 d1                	mov    %edx,%ecx
  800dd9:	89 c3                	mov    %eax,%ebx
  800ddb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800ddf:	29 da                	sub    %ebx,%edx
  800de1:	19 ce                	sbb    %ecx,%esi
  800de3:	89 f9                	mov    %edi,%ecx
  800de5:	89 f0                	mov    %esi,%eax
  800de7:	d3 e0                	shl    %cl,%eax
  800de9:	89 e9                	mov    %ebp,%ecx
  800deb:	d3 ea                	shr    %cl,%edx
  800ded:	89 e9                	mov    %ebp,%ecx
  800def:	d3 ee                	shr    %cl,%esi
  800df1:	09 d0                	or     %edx,%eax
  800df3:	89 f2                	mov    %esi,%edx
  800df5:	83 c4 1c             	add    $0x1c,%esp
  800df8:	5b                   	pop    %ebx
  800df9:	5e                   	pop    %esi
  800dfa:	5f                   	pop    %edi
  800dfb:	5d                   	pop    %ebp
  800dfc:	c3                   	ret    
  800dfd:	8d 76 00             	lea    0x0(%esi),%esi
  800e00:	29 f9                	sub    %edi,%ecx
  800e02:	19 d6                	sbb    %edx,%esi
  800e04:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e08:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e0c:	e9 18 ff ff ff       	jmp    800d29 <__umoddi3+0x69>
