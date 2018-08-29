
obj/user/divzero:     file format elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 40 0e 80 00       	push   $0x800e40
  800056:	e8 e0 00 00 00       	call   80013b <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	83 ec 08             	sub    $0x8,%esp
  800066:	8b 45 08             	mov    0x8(%ebp),%eax
  800069:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006c:	c7 05 08 20 80 00 00 	movl   $0x0,0x802008
  800073:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 c0                	test   %eax,%eax
  800078:	7e 08                	jle    800082 <libmain+0x22>
		binaryname = argv[0];
  80007a:	8b 0a                	mov    (%edx),%ecx
  80007c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800082:	83 ec 08             	sub    $0x8,%esp
  800085:	52                   	push   %edx
  800086:	50                   	push   %eax
  800087:	e8 a7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008c:	e8 05 00 00 00       	call   800096 <exit>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009c:	6a 00                	push   $0x0
  80009e:	e8 48 0a 00 00       	call   800aeb <sys_env_destroy>
}
  8000a3:	83 c4 10             	add    $0x10,%esp
  8000a6:	c9                   	leave  
  8000a7:	c3                   	ret    

008000a8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a8:	55                   	push   %ebp
  8000a9:	89 e5                	mov    %esp,%ebp
  8000ab:	53                   	push   %ebx
  8000ac:	83 ec 04             	sub    $0x4,%esp
  8000af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b2:	8b 13                	mov    (%ebx),%edx
  8000b4:	8d 42 01             	lea    0x1(%edx),%eax
  8000b7:	89 03                	mov    %eax,(%ebx)
  8000b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c5:	75 1a                	jne    8000e1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c7:	83 ec 08             	sub    $0x8,%esp
  8000ca:	68 ff 00 00 00       	push   $0xff
  8000cf:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d2:	50                   	push   %eax
  8000d3:	e8 d6 09 00 00       	call   800aae <sys_cputs>
		b->idx = 0;
  8000d8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000de:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e8:	c9                   	leave  
  8000e9:	c3                   	ret    

008000ea <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ea:	55                   	push   %ebp
  8000eb:	89 e5                	mov    %esp,%ebp
  8000ed:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fa:	00 00 00 
	b.cnt = 0;
  8000fd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800104:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800107:	ff 75 0c             	pushl  0xc(%ebp)
  80010a:	ff 75 08             	pushl  0x8(%ebp)
  80010d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800113:	50                   	push   %eax
  800114:	68 a8 00 80 00       	push   $0x8000a8
  800119:	e8 1a 01 00 00       	call   800238 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011e:	83 c4 08             	add    $0x8,%esp
  800121:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800127:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012d:	50                   	push   %eax
  80012e:	e8 7b 09 00 00       	call   800aae <sys_cputs>

	return b.cnt;
}
  800133:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800139:	c9                   	leave  
  80013a:	c3                   	ret    

0080013b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800141:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800144:	50                   	push   %eax
  800145:	ff 75 08             	pushl  0x8(%ebp)
  800148:	e8 9d ff ff ff       	call   8000ea <vcprintf>
	va_end(ap);

	return cnt;
}
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	57                   	push   %edi
  800153:	56                   	push   %esi
  800154:	53                   	push   %ebx
  800155:	83 ec 1c             	sub    $0x1c,%esp
  800158:	89 c7                	mov    %eax,%edi
  80015a:	89 d6                	mov    %edx,%esi
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800162:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800165:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800168:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800170:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800173:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800176:	39 d3                	cmp    %edx,%ebx
  800178:	72 05                	jb     80017f <printnum+0x30>
  80017a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017d:	77 45                	ja     8001c4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017f:	83 ec 0c             	sub    $0xc,%esp
  800182:	ff 75 18             	pushl  0x18(%ebp)
  800185:	8b 45 14             	mov    0x14(%ebp),%eax
  800188:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018b:	53                   	push   %ebx
  80018c:	ff 75 10             	pushl  0x10(%ebp)
  80018f:	83 ec 08             	sub    $0x8,%esp
  800192:	ff 75 e4             	pushl  -0x1c(%ebp)
  800195:	ff 75 e0             	pushl  -0x20(%ebp)
  800198:	ff 75 dc             	pushl  -0x24(%ebp)
  80019b:	ff 75 d8             	pushl  -0x28(%ebp)
  80019e:	e8 fd 09 00 00       	call   800ba0 <__udivdi3>
  8001a3:	83 c4 18             	add    $0x18,%esp
  8001a6:	52                   	push   %edx
  8001a7:	50                   	push   %eax
  8001a8:	89 f2                	mov    %esi,%edx
  8001aa:	89 f8                	mov    %edi,%eax
  8001ac:	e8 9e ff ff ff       	call   80014f <printnum>
  8001b1:	83 c4 20             	add    $0x20,%esp
  8001b4:	eb 18                	jmp    8001ce <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b6:	83 ec 08             	sub    $0x8,%esp
  8001b9:	56                   	push   %esi
  8001ba:	ff 75 18             	pushl  0x18(%ebp)
  8001bd:	ff d7                	call   *%edi
  8001bf:	83 c4 10             	add    $0x10,%esp
  8001c2:	eb 03                	jmp    8001c7 <printnum+0x78>
  8001c4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c7:	83 eb 01             	sub    $0x1,%ebx
  8001ca:	85 db                	test   %ebx,%ebx
  8001cc:	7f e8                	jg     8001b6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001ce:	83 ec 08             	sub    $0x8,%esp
  8001d1:	56                   	push   %esi
  8001d2:	83 ec 04             	sub    $0x4,%esp
  8001d5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001db:	ff 75 dc             	pushl  -0x24(%ebp)
  8001de:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e1:	e8 ea 0a 00 00       	call   800cd0 <__umoddi3>
  8001e6:	83 c4 14             	add    $0x14,%esp
  8001e9:	0f be 80 58 0e 80 00 	movsbl 0x800e58(%eax),%eax
  8001f0:	50                   	push   %eax
  8001f1:	ff d7                	call   *%edi
}
  8001f3:	83 c4 10             	add    $0x10,%esp
  8001f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f9:	5b                   	pop    %ebx
  8001fa:	5e                   	pop    %esi
  8001fb:	5f                   	pop    %edi
  8001fc:	5d                   	pop    %ebp
  8001fd:	c3                   	ret    

008001fe <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8001fe:	55                   	push   %ebp
  8001ff:	89 e5                	mov    %esp,%ebp
  800201:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800204:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800208:	8b 10                	mov    (%eax),%edx
  80020a:	3b 50 04             	cmp    0x4(%eax),%edx
  80020d:	73 0a                	jae    800219 <sprintputch+0x1b>
		*b->buf++ = ch;
  80020f:	8d 4a 01             	lea    0x1(%edx),%ecx
  800212:	89 08                	mov    %ecx,(%eax)
  800214:	8b 45 08             	mov    0x8(%ebp),%eax
  800217:	88 02                	mov    %al,(%edx)
}
  800219:	5d                   	pop    %ebp
  80021a:	c3                   	ret    

0080021b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80021b:	55                   	push   %ebp
  80021c:	89 e5                	mov    %esp,%ebp
  80021e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800221:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800224:	50                   	push   %eax
  800225:	ff 75 10             	pushl  0x10(%ebp)
  800228:	ff 75 0c             	pushl  0xc(%ebp)
  80022b:	ff 75 08             	pushl  0x8(%ebp)
  80022e:	e8 05 00 00 00       	call   800238 <vprintfmt>
	va_end(ap);
}
  800233:	83 c4 10             	add    $0x10,%esp
  800236:	c9                   	leave  
  800237:	c3                   	ret    

00800238 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800238:	55                   	push   %ebp
  800239:	89 e5                	mov    %esp,%ebp
  80023b:	57                   	push   %edi
  80023c:	56                   	push   %esi
  80023d:	53                   	push   %ebx
  80023e:	83 ec 2c             	sub    $0x2c,%esp
  800241:	8b 75 08             	mov    0x8(%ebp),%esi
  800244:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800247:	8b 7d 10             	mov    0x10(%ebp),%edi
  80024a:	eb 12                	jmp    80025e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80024c:	85 c0                	test   %eax,%eax
  80024e:	0f 84 6a 04 00 00    	je     8006be <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800254:	83 ec 08             	sub    $0x8,%esp
  800257:	53                   	push   %ebx
  800258:	50                   	push   %eax
  800259:	ff d6                	call   *%esi
  80025b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80025e:	83 c7 01             	add    $0x1,%edi
  800261:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800265:	83 f8 25             	cmp    $0x25,%eax
  800268:	75 e2                	jne    80024c <vprintfmt+0x14>
  80026a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80026e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800275:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80027c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800283:	b9 00 00 00 00       	mov    $0x0,%ecx
  800288:	eb 07                	jmp    800291 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80028a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80028d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800291:	8d 47 01             	lea    0x1(%edi),%eax
  800294:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800297:	0f b6 07             	movzbl (%edi),%eax
  80029a:	0f b6 d0             	movzbl %al,%edx
  80029d:	83 e8 23             	sub    $0x23,%eax
  8002a0:	3c 55                	cmp    $0x55,%al
  8002a2:	0f 87 fb 03 00 00    	ja     8006a3 <vprintfmt+0x46b>
  8002a8:	0f b6 c0             	movzbl %al,%eax
  8002ab:	ff 24 85 00 0f 80 00 	jmp    *0x800f00(,%eax,4)
  8002b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  8002b5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002b9:	eb d6                	jmp    800291 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002be:	b8 00 00 00 00       	mov    $0x0,%eax
  8002c3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  8002c6:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002c9:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002cd:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002d0:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002d3:	83 f9 09             	cmp    $0x9,%ecx
  8002d6:	77 3f                	ja     800317 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  8002d8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002db:	eb e9                	jmp    8002c6 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  8002dd:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e0:	8b 00                	mov    (%eax),%eax
  8002e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e8:	8d 40 04             	lea    0x4(%eax),%eax
  8002eb:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8002f1:	eb 2a                	jmp    80031d <vprintfmt+0xe5>
  8002f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002f6:	85 c0                	test   %eax,%eax
  8002f8:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fd:	0f 49 d0             	cmovns %eax,%edx
  800300:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800303:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800306:	eb 89                	jmp    800291 <vprintfmt+0x59>
  800308:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80030b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800312:	e9 7a ff ff ff       	jmp    800291 <vprintfmt+0x59>
  800317:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80031a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  80031d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800321:	0f 89 6a ff ff ff    	jns    800291 <vprintfmt+0x59>
				width = precision, precision = -1;
  800327:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80032a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80032d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800334:	e9 58 ff ff ff       	jmp    800291 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  800339:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80033c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  80033f:	e9 4d ff ff ff       	jmp    800291 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800344:	8b 45 14             	mov    0x14(%ebp),%eax
  800347:	8d 78 04             	lea    0x4(%eax),%edi
  80034a:	83 ec 08             	sub    $0x8,%esp
  80034d:	53                   	push   %ebx
  80034e:	ff 30                	pushl  (%eax)
  800350:	ff d6                	call   *%esi
			break;
  800352:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800355:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800358:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  80035b:	e9 fe fe ff ff       	jmp    80025e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800360:	8b 45 14             	mov    0x14(%ebp),%eax
  800363:	8d 78 04             	lea    0x4(%eax),%edi
  800366:	8b 00                	mov    (%eax),%eax
  800368:	99                   	cltd   
  800369:	31 d0                	xor    %edx,%eax
  80036b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80036d:	83 f8 07             	cmp    $0x7,%eax
  800370:	7f 0b                	jg     80037d <vprintfmt+0x145>
  800372:	8b 14 85 60 10 80 00 	mov    0x801060(,%eax,4),%edx
  800379:	85 d2                	test   %edx,%edx
  80037b:	75 1b                	jne    800398 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80037d:	50                   	push   %eax
  80037e:	68 70 0e 80 00       	push   $0x800e70
  800383:	53                   	push   %ebx
  800384:	56                   	push   %esi
  800385:	e8 91 fe ff ff       	call   80021b <printfmt>
  80038a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80038d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800390:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800393:	e9 c6 fe ff ff       	jmp    80025e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800398:	52                   	push   %edx
  800399:	68 79 0e 80 00       	push   $0x800e79
  80039e:	53                   	push   %ebx
  80039f:	56                   	push   %esi
  8003a0:	e8 76 fe ff ff       	call   80021b <printfmt>
  8003a5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8003ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ae:	e9 ab fe ff ff       	jmp    80025e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003b3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b6:	83 c0 04             	add    $0x4,%eax
  8003b9:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bf:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003c1:	85 ff                	test   %edi,%edi
  8003c3:	b8 69 0e 80 00       	mov    $0x800e69,%eax
  8003c8:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003cb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003cf:	0f 8e 94 00 00 00    	jle    800469 <vprintfmt+0x231>
  8003d5:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003d9:	0f 84 98 00 00 00    	je     800477 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003df:	83 ec 08             	sub    $0x8,%esp
  8003e2:	ff 75 d0             	pushl  -0x30(%ebp)
  8003e5:	57                   	push   %edi
  8003e6:	e8 5b 03 00 00       	call   800746 <strnlen>
  8003eb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003ee:	29 c1                	sub    %eax,%ecx
  8003f0:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003f3:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003f6:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8003fa:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003fd:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800400:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800402:	eb 0f                	jmp    800413 <vprintfmt+0x1db>
					putch(padc, putdat);
  800404:	83 ec 08             	sub    $0x8,%esp
  800407:	53                   	push   %ebx
  800408:	ff 75 e0             	pushl  -0x20(%ebp)
  80040b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80040d:	83 ef 01             	sub    $0x1,%edi
  800410:	83 c4 10             	add    $0x10,%esp
  800413:	85 ff                	test   %edi,%edi
  800415:	7f ed                	jg     800404 <vprintfmt+0x1cc>
  800417:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80041a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80041d:	85 c9                	test   %ecx,%ecx
  80041f:	b8 00 00 00 00       	mov    $0x0,%eax
  800424:	0f 49 c1             	cmovns %ecx,%eax
  800427:	29 c1                	sub    %eax,%ecx
  800429:	89 75 08             	mov    %esi,0x8(%ebp)
  80042c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80042f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800432:	89 cb                	mov    %ecx,%ebx
  800434:	eb 4d                	jmp    800483 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800436:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80043a:	74 1b                	je     800457 <vprintfmt+0x21f>
  80043c:	0f be c0             	movsbl %al,%eax
  80043f:	83 e8 20             	sub    $0x20,%eax
  800442:	83 f8 5e             	cmp    $0x5e,%eax
  800445:	76 10                	jbe    800457 <vprintfmt+0x21f>
					putch('?', putdat);
  800447:	83 ec 08             	sub    $0x8,%esp
  80044a:	ff 75 0c             	pushl  0xc(%ebp)
  80044d:	6a 3f                	push   $0x3f
  80044f:	ff 55 08             	call   *0x8(%ebp)
  800452:	83 c4 10             	add    $0x10,%esp
  800455:	eb 0d                	jmp    800464 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800457:	83 ec 08             	sub    $0x8,%esp
  80045a:	ff 75 0c             	pushl  0xc(%ebp)
  80045d:	52                   	push   %edx
  80045e:	ff 55 08             	call   *0x8(%ebp)
  800461:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800464:	83 eb 01             	sub    $0x1,%ebx
  800467:	eb 1a                	jmp    800483 <vprintfmt+0x24b>
  800469:	89 75 08             	mov    %esi,0x8(%ebp)
  80046c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80046f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800472:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800475:	eb 0c                	jmp    800483 <vprintfmt+0x24b>
  800477:	89 75 08             	mov    %esi,0x8(%ebp)
  80047a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800480:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800483:	83 c7 01             	add    $0x1,%edi
  800486:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80048a:	0f be d0             	movsbl %al,%edx
  80048d:	85 d2                	test   %edx,%edx
  80048f:	74 23                	je     8004b4 <vprintfmt+0x27c>
  800491:	85 f6                	test   %esi,%esi
  800493:	78 a1                	js     800436 <vprintfmt+0x1fe>
  800495:	83 ee 01             	sub    $0x1,%esi
  800498:	79 9c                	jns    800436 <vprintfmt+0x1fe>
  80049a:	89 df                	mov    %ebx,%edi
  80049c:	8b 75 08             	mov    0x8(%ebp),%esi
  80049f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004a2:	eb 18                	jmp    8004bc <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004a4:	83 ec 08             	sub    $0x8,%esp
  8004a7:	53                   	push   %ebx
  8004a8:	6a 20                	push   $0x20
  8004aa:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004ac:	83 ef 01             	sub    $0x1,%edi
  8004af:	83 c4 10             	add    $0x10,%esp
  8004b2:	eb 08                	jmp    8004bc <vprintfmt+0x284>
  8004b4:	89 df                	mov    %ebx,%edi
  8004b6:	8b 75 08             	mov    0x8(%ebp),%esi
  8004b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004bc:	85 ff                	test   %edi,%edi
  8004be:	7f e4                	jg     8004a4 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c0:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004c3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8004c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004c9:	e9 90 fd ff ff       	jmp    80025e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004ce:	83 f9 01             	cmp    $0x1,%ecx
  8004d1:	7e 19                	jle    8004ec <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d6:	8b 50 04             	mov    0x4(%eax),%edx
  8004d9:	8b 00                	mov    (%eax),%eax
  8004db:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004de:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e4:	8d 40 08             	lea    0x8(%eax),%eax
  8004e7:	89 45 14             	mov    %eax,0x14(%ebp)
  8004ea:	eb 38                	jmp    800524 <vprintfmt+0x2ec>
	else if (lflag)
  8004ec:	85 c9                	test   %ecx,%ecx
  8004ee:	74 1b                	je     80050b <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f3:	8b 00                	mov    (%eax),%eax
  8004f5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004f8:	89 c1                	mov    %eax,%ecx
  8004fa:	c1 f9 1f             	sar    $0x1f,%ecx
  8004fd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800500:	8b 45 14             	mov    0x14(%ebp),%eax
  800503:	8d 40 04             	lea    0x4(%eax),%eax
  800506:	89 45 14             	mov    %eax,0x14(%ebp)
  800509:	eb 19                	jmp    800524 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80050b:	8b 45 14             	mov    0x14(%ebp),%eax
  80050e:	8b 00                	mov    (%eax),%eax
  800510:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800513:	89 c1                	mov    %eax,%ecx
  800515:	c1 f9 1f             	sar    $0x1f,%ecx
  800518:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80051b:	8b 45 14             	mov    0x14(%ebp),%eax
  80051e:	8d 40 04             	lea    0x4(%eax),%eax
  800521:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800524:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800527:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80052a:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80052f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800533:	0f 89 36 01 00 00    	jns    80066f <vprintfmt+0x437>
				putch('-', putdat);
  800539:	83 ec 08             	sub    $0x8,%esp
  80053c:	53                   	push   %ebx
  80053d:	6a 2d                	push   $0x2d
  80053f:	ff d6                	call   *%esi
				num = -(long long) num;
  800541:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800544:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800547:	f7 da                	neg    %edx
  800549:	83 d1 00             	adc    $0x0,%ecx
  80054c:	f7 d9                	neg    %ecx
  80054e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800551:	b8 0a 00 00 00       	mov    $0xa,%eax
  800556:	e9 14 01 00 00       	jmp    80066f <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80055b:	83 f9 01             	cmp    $0x1,%ecx
  80055e:	7e 18                	jle    800578 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800560:	8b 45 14             	mov    0x14(%ebp),%eax
  800563:	8b 10                	mov    (%eax),%edx
  800565:	8b 48 04             	mov    0x4(%eax),%ecx
  800568:	8d 40 08             	lea    0x8(%eax),%eax
  80056b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80056e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800573:	e9 f7 00 00 00       	jmp    80066f <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800578:	85 c9                	test   %ecx,%ecx
  80057a:	74 1a                	je     800596 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80057c:	8b 45 14             	mov    0x14(%ebp),%eax
  80057f:	8b 10                	mov    (%eax),%edx
  800581:	b9 00 00 00 00       	mov    $0x0,%ecx
  800586:	8d 40 04             	lea    0x4(%eax),%eax
  800589:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80058c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800591:	e9 d9 00 00 00       	jmp    80066f <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800596:	8b 45 14             	mov    0x14(%ebp),%eax
  800599:	8b 10                	mov    (%eax),%edx
  80059b:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a0:	8d 40 04             	lea    0x4(%eax),%eax
  8005a3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005a6:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005ab:	e9 bf 00 00 00       	jmp    80066f <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b0:	83 f9 01             	cmp    $0x1,%ecx
  8005b3:	7e 13                	jle    8005c8 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  8005b5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b8:	8b 50 04             	mov    0x4(%eax),%edx
  8005bb:	8b 00                	mov    (%eax),%eax
  8005bd:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005c0:	8d 49 08             	lea    0x8(%ecx),%ecx
  8005c3:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005c6:	eb 28                	jmp    8005f0 <vprintfmt+0x3b8>
	else if (lflag)
  8005c8:	85 c9                	test   %ecx,%ecx
  8005ca:	74 13                	je     8005df <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  8005cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cf:	8b 10                	mov    (%eax),%edx
  8005d1:	89 d0                	mov    %edx,%eax
  8005d3:	99                   	cltd   
  8005d4:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005d7:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005da:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005dd:	eb 11                	jmp    8005f0 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8005df:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e2:	8b 10                	mov    (%eax),%edx
  8005e4:	89 d0                	mov    %edx,%eax
  8005e6:	99                   	cltd   
  8005e7:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005ea:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005ed:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8005f0:	89 d1                	mov    %edx,%ecx
  8005f2:	89 c2                	mov    %eax,%edx
			base = 8;
  8005f4:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8005f9:	eb 74                	jmp    80066f <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8005fb:	83 ec 08             	sub    $0x8,%esp
  8005fe:	53                   	push   %ebx
  8005ff:	6a 30                	push   $0x30
  800601:	ff d6                	call   *%esi
			putch('x', putdat);
  800603:	83 c4 08             	add    $0x8,%esp
  800606:	53                   	push   %ebx
  800607:	6a 78                	push   $0x78
  800609:	ff d6                	call   *%esi
			num = (unsigned long long)
  80060b:	8b 45 14             	mov    0x14(%ebp),%eax
  80060e:	8b 10                	mov    (%eax),%edx
  800610:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800615:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800618:	8d 40 04             	lea    0x4(%eax),%eax
  80061b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80061e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800623:	eb 4a                	jmp    80066f <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800625:	83 f9 01             	cmp    $0x1,%ecx
  800628:	7e 15                	jle    80063f <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  80062a:	8b 45 14             	mov    0x14(%ebp),%eax
  80062d:	8b 10                	mov    (%eax),%edx
  80062f:	8b 48 04             	mov    0x4(%eax),%ecx
  800632:	8d 40 08             	lea    0x8(%eax),%eax
  800635:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800638:	b8 10 00 00 00       	mov    $0x10,%eax
  80063d:	eb 30                	jmp    80066f <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80063f:	85 c9                	test   %ecx,%ecx
  800641:	74 17                	je     80065a <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800643:	8b 45 14             	mov    0x14(%ebp),%eax
  800646:	8b 10                	mov    (%eax),%edx
  800648:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064d:	8d 40 04             	lea    0x4(%eax),%eax
  800650:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800653:	b8 10 00 00 00       	mov    $0x10,%eax
  800658:	eb 15                	jmp    80066f <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80065a:	8b 45 14             	mov    0x14(%ebp),%eax
  80065d:	8b 10                	mov    (%eax),%edx
  80065f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800664:	8d 40 04             	lea    0x4(%eax),%eax
  800667:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80066a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80066f:	83 ec 0c             	sub    $0xc,%esp
  800672:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800676:	57                   	push   %edi
  800677:	ff 75 e0             	pushl  -0x20(%ebp)
  80067a:	50                   	push   %eax
  80067b:	51                   	push   %ecx
  80067c:	52                   	push   %edx
  80067d:	89 da                	mov    %ebx,%edx
  80067f:	89 f0                	mov    %esi,%eax
  800681:	e8 c9 fa ff ff       	call   80014f <printnum>
			break;
  800686:	83 c4 20             	add    $0x20,%esp
  800689:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80068c:	e9 cd fb ff ff       	jmp    80025e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800691:	83 ec 08             	sub    $0x8,%esp
  800694:	53                   	push   %ebx
  800695:	52                   	push   %edx
  800696:	ff d6                	call   *%esi
			break;
  800698:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80069b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80069e:	e9 bb fb ff ff       	jmp    80025e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006a3:	83 ec 08             	sub    $0x8,%esp
  8006a6:	53                   	push   %ebx
  8006a7:	6a 25                	push   $0x25
  8006a9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006ab:	83 c4 10             	add    $0x10,%esp
  8006ae:	eb 03                	jmp    8006b3 <vprintfmt+0x47b>
  8006b0:	83 ef 01             	sub    $0x1,%edi
  8006b3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006b7:	75 f7                	jne    8006b0 <vprintfmt+0x478>
  8006b9:	e9 a0 fb ff ff       	jmp    80025e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006be:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006c1:	5b                   	pop    %ebx
  8006c2:	5e                   	pop    %esi
  8006c3:	5f                   	pop    %edi
  8006c4:	5d                   	pop    %ebp
  8006c5:	c3                   	ret    

008006c6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006c6:	55                   	push   %ebp
  8006c7:	89 e5                	mov    %esp,%ebp
  8006c9:	83 ec 18             	sub    $0x18,%esp
  8006cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8006cf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006d5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006d9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006e3:	85 c0                	test   %eax,%eax
  8006e5:	74 26                	je     80070d <vsnprintf+0x47>
  8006e7:	85 d2                	test   %edx,%edx
  8006e9:	7e 22                	jle    80070d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006eb:	ff 75 14             	pushl  0x14(%ebp)
  8006ee:	ff 75 10             	pushl  0x10(%ebp)
  8006f1:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006f4:	50                   	push   %eax
  8006f5:	68 fe 01 80 00       	push   $0x8001fe
  8006fa:	e8 39 fb ff ff       	call   800238 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800702:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800705:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800708:	83 c4 10             	add    $0x10,%esp
  80070b:	eb 05                	jmp    800712 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80070d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800712:	c9                   	leave  
  800713:	c3                   	ret    

00800714 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800714:	55                   	push   %ebp
  800715:	89 e5                	mov    %esp,%ebp
  800717:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80071a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80071d:	50                   	push   %eax
  80071e:	ff 75 10             	pushl  0x10(%ebp)
  800721:	ff 75 0c             	pushl  0xc(%ebp)
  800724:	ff 75 08             	pushl  0x8(%ebp)
  800727:	e8 9a ff ff ff       	call   8006c6 <vsnprintf>
	va_end(ap);

	return rc;
}
  80072c:	c9                   	leave  
  80072d:	c3                   	ret    

0080072e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80072e:	55                   	push   %ebp
  80072f:	89 e5                	mov    %esp,%ebp
  800731:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800734:	b8 00 00 00 00       	mov    $0x0,%eax
  800739:	eb 03                	jmp    80073e <strlen+0x10>
		n++;
  80073b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80073e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800742:	75 f7                	jne    80073b <strlen+0xd>
		n++;
	return n;
}
  800744:	5d                   	pop    %ebp
  800745:	c3                   	ret    

00800746 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800746:	55                   	push   %ebp
  800747:	89 e5                	mov    %esp,%ebp
  800749:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80074c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80074f:	ba 00 00 00 00       	mov    $0x0,%edx
  800754:	eb 03                	jmp    800759 <strnlen+0x13>
		n++;
  800756:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800759:	39 c2                	cmp    %eax,%edx
  80075b:	74 08                	je     800765 <strnlen+0x1f>
  80075d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800761:	75 f3                	jne    800756 <strnlen+0x10>
  800763:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	53                   	push   %ebx
  80076b:	8b 45 08             	mov    0x8(%ebp),%eax
  80076e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800771:	89 c2                	mov    %eax,%edx
  800773:	83 c2 01             	add    $0x1,%edx
  800776:	83 c1 01             	add    $0x1,%ecx
  800779:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80077d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800780:	84 db                	test   %bl,%bl
  800782:	75 ef                	jne    800773 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800784:	5b                   	pop    %ebx
  800785:	5d                   	pop    %ebp
  800786:	c3                   	ret    

00800787 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	53                   	push   %ebx
  80078b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80078e:	53                   	push   %ebx
  80078f:	e8 9a ff ff ff       	call   80072e <strlen>
  800794:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800797:	ff 75 0c             	pushl  0xc(%ebp)
  80079a:	01 d8                	add    %ebx,%eax
  80079c:	50                   	push   %eax
  80079d:	e8 c5 ff ff ff       	call   800767 <strcpy>
	return dst;
}
  8007a2:	89 d8                	mov    %ebx,%eax
  8007a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007a7:	c9                   	leave  
  8007a8:	c3                   	ret    

008007a9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007a9:	55                   	push   %ebp
  8007aa:	89 e5                	mov    %esp,%ebp
  8007ac:	56                   	push   %esi
  8007ad:	53                   	push   %ebx
  8007ae:	8b 75 08             	mov    0x8(%ebp),%esi
  8007b1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007b4:	89 f3                	mov    %esi,%ebx
  8007b6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b9:	89 f2                	mov    %esi,%edx
  8007bb:	eb 0f                	jmp    8007cc <strncpy+0x23>
		*dst++ = *src;
  8007bd:	83 c2 01             	add    $0x1,%edx
  8007c0:	0f b6 01             	movzbl (%ecx),%eax
  8007c3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007c6:	80 39 01             	cmpb   $0x1,(%ecx)
  8007c9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007cc:	39 da                	cmp    %ebx,%edx
  8007ce:	75 ed                	jne    8007bd <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007d0:	89 f0                	mov    %esi,%eax
  8007d2:	5b                   	pop    %ebx
  8007d3:	5e                   	pop    %esi
  8007d4:	5d                   	pop    %ebp
  8007d5:	c3                   	ret    

008007d6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007d6:	55                   	push   %ebp
  8007d7:	89 e5                	mov    %esp,%ebp
  8007d9:	56                   	push   %esi
  8007da:	53                   	push   %ebx
  8007db:	8b 75 08             	mov    0x8(%ebp),%esi
  8007de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007e1:	8b 55 10             	mov    0x10(%ebp),%edx
  8007e4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007e6:	85 d2                	test   %edx,%edx
  8007e8:	74 21                	je     80080b <strlcpy+0x35>
  8007ea:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007ee:	89 f2                	mov    %esi,%edx
  8007f0:	eb 09                	jmp    8007fb <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007f2:	83 c2 01             	add    $0x1,%edx
  8007f5:	83 c1 01             	add    $0x1,%ecx
  8007f8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007fb:	39 c2                	cmp    %eax,%edx
  8007fd:	74 09                	je     800808 <strlcpy+0x32>
  8007ff:	0f b6 19             	movzbl (%ecx),%ebx
  800802:	84 db                	test   %bl,%bl
  800804:	75 ec                	jne    8007f2 <strlcpy+0x1c>
  800806:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800808:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80080b:	29 f0                	sub    %esi,%eax
}
  80080d:	5b                   	pop    %ebx
  80080e:	5e                   	pop    %esi
  80080f:	5d                   	pop    %ebp
  800810:	c3                   	ret    

00800811 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800811:	55                   	push   %ebp
  800812:	89 e5                	mov    %esp,%ebp
  800814:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800817:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80081a:	eb 06                	jmp    800822 <strcmp+0x11>
		p++, q++;
  80081c:	83 c1 01             	add    $0x1,%ecx
  80081f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800822:	0f b6 01             	movzbl (%ecx),%eax
  800825:	84 c0                	test   %al,%al
  800827:	74 04                	je     80082d <strcmp+0x1c>
  800829:	3a 02                	cmp    (%edx),%al
  80082b:	74 ef                	je     80081c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80082d:	0f b6 c0             	movzbl %al,%eax
  800830:	0f b6 12             	movzbl (%edx),%edx
  800833:	29 d0                	sub    %edx,%eax
}
  800835:	5d                   	pop    %ebp
  800836:	c3                   	ret    

00800837 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800837:	55                   	push   %ebp
  800838:	89 e5                	mov    %esp,%ebp
  80083a:	53                   	push   %ebx
  80083b:	8b 45 08             	mov    0x8(%ebp),%eax
  80083e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800841:	89 c3                	mov    %eax,%ebx
  800843:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800846:	eb 06                	jmp    80084e <strncmp+0x17>
		n--, p++, q++;
  800848:	83 c0 01             	add    $0x1,%eax
  80084b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80084e:	39 d8                	cmp    %ebx,%eax
  800850:	74 15                	je     800867 <strncmp+0x30>
  800852:	0f b6 08             	movzbl (%eax),%ecx
  800855:	84 c9                	test   %cl,%cl
  800857:	74 04                	je     80085d <strncmp+0x26>
  800859:	3a 0a                	cmp    (%edx),%cl
  80085b:	74 eb                	je     800848 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80085d:	0f b6 00             	movzbl (%eax),%eax
  800860:	0f b6 12             	movzbl (%edx),%edx
  800863:	29 d0                	sub    %edx,%eax
  800865:	eb 05                	jmp    80086c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800867:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80086c:	5b                   	pop    %ebx
  80086d:	5d                   	pop    %ebp
  80086e:	c3                   	ret    

0080086f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80086f:	55                   	push   %ebp
  800870:	89 e5                	mov    %esp,%ebp
  800872:	8b 45 08             	mov    0x8(%ebp),%eax
  800875:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800879:	eb 07                	jmp    800882 <strchr+0x13>
		if (*s == c)
  80087b:	38 ca                	cmp    %cl,%dl
  80087d:	74 0f                	je     80088e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80087f:	83 c0 01             	add    $0x1,%eax
  800882:	0f b6 10             	movzbl (%eax),%edx
  800885:	84 d2                	test   %dl,%dl
  800887:	75 f2                	jne    80087b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800889:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80088e:	5d                   	pop    %ebp
  80088f:	c3                   	ret    

00800890 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800890:	55                   	push   %ebp
  800891:	89 e5                	mov    %esp,%ebp
  800893:	8b 45 08             	mov    0x8(%ebp),%eax
  800896:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80089a:	eb 03                	jmp    80089f <strfind+0xf>
  80089c:	83 c0 01             	add    $0x1,%eax
  80089f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008a2:	38 ca                	cmp    %cl,%dl
  8008a4:	74 04                	je     8008aa <strfind+0x1a>
  8008a6:	84 d2                	test   %dl,%dl
  8008a8:	75 f2                	jne    80089c <strfind+0xc>
			break;
	return (char *) s;
}
  8008aa:	5d                   	pop    %ebp
  8008ab:	c3                   	ret    

008008ac <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008ac:	55                   	push   %ebp
  8008ad:	89 e5                	mov    %esp,%ebp
  8008af:	57                   	push   %edi
  8008b0:	56                   	push   %esi
  8008b1:	53                   	push   %ebx
  8008b2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008b8:	85 c9                	test   %ecx,%ecx
  8008ba:	74 36                	je     8008f2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008bc:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008c2:	75 28                	jne    8008ec <memset+0x40>
  8008c4:	f6 c1 03             	test   $0x3,%cl
  8008c7:	75 23                	jne    8008ec <memset+0x40>
		c &= 0xFF;
  8008c9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008cd:	89 d3                	mov    %edx,%ebx
  8008cf:	c1 e3 08             	shl    $0x8,%ebx
  8008d2:	89 d6                	mov    %edx,%esi
  8008d4:	c1 e6 18             	shl    $0x18,%esi
  8008d7:	89 d0                	mov    %edx,%eax
  8008d9:	c1 e0 10             	shl    $0x10,%eax
  8008dc:	09 f0                	or     %esi,%eax
  8008de:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008e0:	89 d8                	mov    %ebx,%eax
  8008e2:	09 d0                	or     %edx,%eax
  8008e4:	c1 e9 02             	shr    $0x2,%ecx
  8008e7:	fc                   	cld    
  8008e8:	f3 ab                	rep stos %eax,%es:(%edi)
  8008ea:	eb 06                	jmp    8008f2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008ef:	fc                   	cld    
  8008f0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008f2:	89 f8                	mov    %edi,%eax
  8008f4:	5b                   	pop    %ebx
  8008f5:	5e                   	pop    %esi
  8008f6:	5f                   	pop    %edi
  8008f7:	5d                   	pop    %ebp
  8008f8:	c3                   	ret    

008008f9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008f9:	55                   	push   %ebp
  8008fa:	89 e5                	mov    %esp,%ebp
  8008fc:	57                   	push   %edi
  8008fd:	56                   	push   %esi
  8008fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800901:	8b 75 0c             	mov    0xc(%ebp),%esi
  800904:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800907:	39 c6                	cmp    %eax,%esi
  800909:	73 35                	jae    800940 <memmove+0x47>
  80090b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80090e:	39 d0                	cmp    %edx,%eax
  800910:	73 2e                	jae    800940 <memmove+0x47>
		s += n;
		d += n;
  800912:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800915:	89 d6                	mov    %edx,%esi
  800917:	09 fe                	or     %edi,%esi
  800919:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80091f:	75 13                	jne    800934 <memmove+0x3b>
  800921:	f6 c1 03             	test   $0x3,%cl
  800924:	75 0e                	jne    800934 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800926:	83 ef 04             	sub    $0x4,%edi
  800929:	8d 72 fc             	lea    -0x4(%edx),%esi
  80092c:	c1 e9 02             	shr    $0x2,%ecx
  80092f:	fd                   	std    
  800930:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800932:	eb 09                	jmp    80093d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800934:	83 ef 01             	sub    $0x1,%edi
  800937:	8d 72 ff             	lea    -0x1(%edx),%esi
  80093a:	fd                   	std    
  80093b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80093d:	fc                   	cld    
  80093e:	eb 1d                	jmp    80095d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800940:	89 f2                	mov    %esi,%edx
  800942:	09 c2                	or     %eax,%edx
  800944:	f6 c2 03             	test   $0x3,%dl
  800947:	75 0f                	jne    800958 <memmove+0x5f>
  800949:	f6 c1 03             	test   $0x3,%cl
  80094c:	75 0a                	jne    800958 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80094e:	c1 e9 02             	shr    $0x2,%ecx
  800951:	89 c7                	mov    %eax,%edi
  800953:	fc                   	cld    
  800954:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800956:	eb 05                	jmp    80095d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800958:	89 c7                	mov    %eax,%edi
  80095a:	fc                   	cld    
  80095b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80095d:	5e                   	pop    %esi
  80095e:	5f                   	pop    %edi
  80095f:	5d                   	pop    %ebp
  800960:	c3                   	ret    

00800961 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800961:	55                   	push   %ebp
  800962:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800964:	ff 75 10             	pushl  0x10(%ebp)
  800967:	ff 75 0c             	pushl  0xc(%ebp)
  80096a:	ff 75 08             	pushl  0x8(%ebp)
  80096d:	e8 87 ff ff ff       	call   8008f9 <memmove>
}
  800972:	c9                   	leave  
  800973:	c3                   	ret    

00800974 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800974:	55                   	push   %ebp
  800975:	89 e5                	mov    %esp,%ebp
  800977:	56                   	push   %esi
  800978:	53                   	push   %ebx
  800979:	8b 45 08             	mov    0x8(%ebp),%eax
  80097c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80097f:	89 c6                	mov    %eax,%esi
  800981:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800984:	eb 1a                	jmp    8009a0 <memcmp+0x2c>
		if (*s1 != *s2)
  800986:	0f b6 08             	movzbl (%eax),%ecx
  800989:	0f b6 1a             	movzbl (%edx),%ebx
  80098c:	38 d9                	cmp    %bl,%cl
  80098e:	74 0a                	je     80099a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800990:	0f b6 c1             	movzbl %cl,%eax
  800993:	0f b6 db             	movzbl %bl,%ebx
  800996:	29 d8                	sub    %ebx,%eax
  800998:	eb 0f                	jmp    8009a9 <memcmp+0x35>
		s1++, s2++;
  80099a:	83 c0 01             	add    $0x1,%eax
  80099d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009a0:	39 f0                	cmp    %esi,%eax
  8009a2:	75 e2                	jne    800986 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a9:	5b                   	pop    %ebx
  8009aa:	5e                   	pop    %esi
  8009ab:	5d                   	pop    %ebp
  8009ac:	c3                   	ret    

008009ad <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ad:	55                   	push   %ebp
  8009ae:	89 e5                	mov    %esp,%ebp
  8009b0:	53                   	push   %ebx
  8009b1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009b4:	89 c1                	mov    %eax,%ecx
  8009b6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009b9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009bd:	eb 0a                	jmp    8009c9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009bf:	0f b6 10             	movzbl (%eax),%edx
  8009c2:	39 da                	cmp    %ebx,%edx
  8009c4:	74 07                	je     8009cd <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009c6:	83 c0 01             	add    $0x1,%eax
  8009c9:	39 c8                	cmp    %ecx,%eax
  8009cb:	72 f2                	jb     8009bf <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009cd:	5b                   	pop    %ebx
  8009ce:	5d                   	pop    %ebp
  8009cf:	c3                   	ret    

008009d0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009d0:	55                   	push   %ebp
  8009d1:	89 e5                	mov    %esp,%ebp
  8009d3:	57                   	push   %edi
  8009d4:	56                   	push   %esi
  8009d5:	53                   	push   %ebx
  8009d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009dc:	eb 03                	jmp    8009e1 <strtol+0x11>
		s++;
  8009de:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009e1:	0f b6 01             	movzbl (%ecx),%eax
  8009e4:	3c 20                	cmp    $0x20,%al
  8009e6:	74 f6                	je     8009de <strtol+0xe>
  8009e8:	3c 09                	cmp    $0x9,%al
  8009ea:	74 f2                	je     8009de <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ec:	3c 2b                	cmp    $0x2b,%al
  8009ee:	75 0a                	jne    8009fa <strtol+0x2a>
		s++;
  8009f0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009f3:	bf 00 00 00 00       	mov    $0x0,%edi
  8009f8:	eb 11                	jmp    800a0b <strtol+0x3b>
  8009fa:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009ff:	3c 2d                	cmp    $0x2d,%al
  800a01:	75 08                	jne    800a0b <strtol+0x3b>
		s++, neg = 1;
  800a03:	83 c1 01             	add    $0x1,%ecx
  800a06:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a0b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a11:	75 15                	jne    800a28 <strtol+0x58>
  800a13:	80 39 30             	cmpb   $0x30,(%ecx)
  800a16:	75 10                	jne    800a28 <strtol+0x58>
  800a18:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a1c:	75 7c                	jne    800a9a <strtol+0xca>
		s += 2, base = 16;
  800a1e:	83 c1 02             	add    $0x2,%ecx
  800a21:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a26:	eb 16                	jmp    800a3e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a28:	85 db                	test   %ebx,%ebx
  800a2a:	75 12                	jne    800a3e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a2c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a31:	80 39 30             	cmpb   $0x30,(%ecx)
  800a34:	75 08                	jne    800a3e <strtol+0x6e>
		s++, base = 8;
  800a36:	83 c1 01             	add    $0x1,%ecx
  800a39:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a3e:	b8 00 00 00 00       	mov    $0x0,%eax
  800a43:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a46:	0f b6 11             	movzbl (%ecx),%edx
  800a49:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a4c:	89 f3                	mov    %esi,%ebx
  800a4e:	80 fb 09             	cmp    $0x9,%bl
  800a51:	77 08                	ja     800a5b <strtol+0x8b>
			dig = *s - '0';
  800a53:	0f be d2             	movsbl %dl,%edx
  800a56:	83 ea 30             	sub    $0x30,%edx
  800a59:	eb 22                	jmp    800a7d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a5b:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a5e:	89 f3                	mov    %esi,%ebx
  800a60:	80 fb 19             	cmp    $0x19,%bl
  800a63:	77 08                	ja     800a6d <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a65:	0f be d2             	movsbl %dl,%edx
  800a68:	83 ea 57             	sub    $0x57,%edx
  800a6b:	eb 10                	jmp    800a7d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a6d:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a70:	89 f3                	mov    %esi,%ebx
  800a72:	80 fb 19             	cmp    $0x19,%bl
  800a75:	77 16                	ja     800a8d <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a77:	0f be d2             	movsbl %dl,%edx
  800a7a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a7d:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a80:	7d 0b                	jge    800a8d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a82:	83 c1 01             	add    $0x1,%ecx
  800a85:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a89:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a8b:	eb b9                	jmp    800a46 <strtol+0x76>

	if (endptr)
  800a8d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a91:	74 0d                	je     800aa0 <strtol+0xd0>
		*endptr = (char *) s;
  800a93:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a96:	89 0e                	mov    %ecx,(%esi)
  800a98:	eb 06                	jmp    800aa0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a9a:	85 db                	test   %ebx,%ebx
  800a9c:	74 98                	je     800a36 <strtol+0x66>
  800a9e:	eb 9e                	jmp    800a3e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aa0:	89 c2                	mov    %eax,%edx
  800aa2:	f7 da                	neg    %edx
  800aa4:	85 ff                	test   %edi,%edi
  800aa6:	0f 45 c2             	cmovne %edx,%eax
}
  800aa9:	5b                   	pop    %ebx
  800aaa:	5e                   	pop    %esi
  800aab:	5f                   	pop    %edi
  800aac:	5d                   	pop    %ebp
  800aad:	c3                   	ret    

00800aae <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800aae:	55                   	push   %ebp
  800aaf:	89 e5                	mov    %esp,%ebp
  800ab1:	57                   	push   %edi
  800ab2:	56                   	push   %esi
  800ab3:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab4:	b8 00 00 00 00       	mov    $0x0,%eax
  800ab9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800abc:	8b 55 08             	mov    0x8(%ebp),%edx
  800abf:	89 c3                	mov    %eax,%ebx
  800ac1:	89 c7                	mov    %eax,%edi
  800ac3:	89 c6                	mov    %eax,%esi
  800ac5:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ac7:	5b                   	pop    %ebx
  800ac8:	5e                   	pop    %esi
  800ac9:	5f                   	pop    %edi
  800aca:	5d                   	pop    %ebp
  800acb:	c3                   	ret    

00800acc <sys_cgetc>:

int
sys_cgetc(void)
{
  800acc:	55                   	push   %ebp
  800acd:	89 e5                	mov    %esp,%ebp
  800acf:	57                   	push   %edi
  800ad0:	56                   	push   %esi
  800ad1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad2:	ba 00 00 00 00       	mov    $0x0,%edx
  800ad7:	b8 01 00 00 00       	mov    $0x1,%eax
  800adc:	89 d1                	mov    %edx,%ecx
  800ade:	89 d3                	mov    %edx,%ebx
  800ae0:	89 d7                	mov    %edx,%edi
  800ae2:	89 d6                	mov    %edx,%esi
  800ae4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ae6:	5b                   	pop    %ebx
  800ae7:	5e                   	pop    %esi
  800ae8:	5f                   	pop    %edi
  800ae9:	5d                   	pop    %ebp
  800aea:	c3                   	ret    

00800aeb <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800aeb:	55                   	push   %ebp
  800aec:	89 e5                	mov    %esp,%ebp
  800aee:	57                   	push   %edi
  800aef:	56                   	push   %esi
  800af0:	53                   	push   %ebx
  800af1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800af4:	b9 00 00 00 00       	mov    $0x0,%ecx
  800af9:	b8 03 00 00 00       	mov    $0x3,%eax
  800afe:	8b 55 08             	mov    0x8(%ebp),%edx
  800b01:	89 cb                	mov    %ecx,%ebx
  800b03:	89 cf                	mov    %ecx,%edi
  800b05:	89 ce                	mov    %ecx,%esi
  800b07:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b09:	85 c0                	test   %eax,%eax
  800b0b:	7e 17                	jle    800b24 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b0d:	83 ec 0c             	sub    $0xc,%esp
  800b10:	50                   	push   %eax
  800b11:	6a 03                	push   $0x3
  800b13:	68 80 10 80 00       	push   $0x801080
  800b18:	6a 23                	push   $0x23
  800b1a:	68 9d 10 80 00       	push   $0x80109d
  800b1f:	e8 27 00 00 00       	call   800b4b <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b24:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b27:	5b                   	pop    %ebx
  800b28:	5e                   	pop    %esi
  800b29:	5f                   	pop    %edi
  800b2a:	5d                   	pop    %ebp
  800b2b:	c3                   	ret    

00800b2c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b2c:	55                   	push   %ebp
  800b2d:	89 e5                	mov    %esp,%ebp
  800b2f:	57                   	push   %edi
  800b30:	56                   	push   %esi
  800b31:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b32:	ba 00 00 00 00       	mov    $0x0,%edx
  800b37:	b8 02 00 00 00       	mov    $0x2,%eax
  800b3c:	89 d1                	mov    %edx,%ecx
  800b3e:	89 d3                	mov    %edx,%ebx
  800b40:	89 d7                	mov    %edx,%edi
  800b42:	89 d6                	mov    %edx,%esi
  800b44:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b46:	5b                   	pop    %ebx
  800b47:	5e                   	pop    %esi
  800b48:	5f                   	pop    %edi
  800b49:	5d                   	pop    %ebp
  800b4a:	c3                   	ret    

00800b4b <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b4b:	55                   	push   %ebp
  800b4c:	89 e5                	mov    %esp,%ebp
  800b4e:	56                   	push   %esi
  800b4f:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b50:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b53:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b59:	e8 ce ff ff ff       	call   800b2c <sys_getenvid>
  800b5e:	83 ec 0c             	sub    $0xc,%esp
  800b61:	ff 75 0c             	pushl  0xc(%ebp)
  800b64:	ff 75 08             	pushl  0x8(%ebp)
  800b67:	56                   	push   %esi
  800b68:	50                   	push   %eax
  800b69:	68 ac 10 80 00       	push   $0x8010ac
  800b6e:	e8 c8 f5 ff ff       	call   80013b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b73:	83 c4 18             	add    $0x18,%esp
  800b76:	53                   	push   %ebx
  800b77:	ff 75 10             	pushl  0x10(%ebp)
  800b7a:	e8 6b f5 ff ff       	call   8000ea <vcprintf>
	cprintf("\n");
  800b7f:	c7 04 24 4c 0e 80 00 	movl   $0x800e4c,(%esp)
  800b86:	e8 b0 f5 ff ff       	call   80013b <cprintf>
  800b8b:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b8e:	cc                   	int3   
  800b8f:	eb fd                	jmp    800b8e <_panic+0x43>
  800b91:	66 90                	xchg   %ax,%ax
  800b93:	66 90                	xchg   %ax,%ax
  800b95:	66 90                	xchg   %ax,%ax
  800b97:	66 90                	xchg   %ax,%ax
  800b99:	66 90                	xchg   %ax,%ax
  800b9b:	66 90                	xchg   %ax,%ax
  800b9d:	66 90                	xchg   %ax,%ax
  800b9f:	90                   	nop

00800ba0 <__udivdi3>:
  800ba0:	55                   	push   %ebp
  800ba1:	57                   	push   %edi
  800ba2:	56                   	push   %esi
  800ba3:	53                   	push   %ebx
  800ba4:	83 ec 1c             	sub    $0x1c,%esp
  800ba7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800bab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800baf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800bb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800bb7:	85 f6                	test   %esi,%esi
  800bb9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bbd:	89 ca                	mov    %ecx,%edx
  800bbf:	89 f8                	mov    %edi,%eax
  800bc1:	75 3d                	jne    800c00 <__udivdi3+0x60>
  800bc3:	39 cf                	cmp    %ecx,%edi
  800bc5:	0f 87 c5 00 00 00    	ja     800c90 <__udivdi3+0xf0>
  800bcb:	85 ff                	test   %edi,%edi
  800bcd:	89 fd                	mov    %edi,%ebp
  800bcf:	75 0b                	jne    800bdc <__udivdi3+0x3c>
  800bd1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bd6:	31 d2                	xor    %edx,%edx
  800bd8:	f7 f7                	div    %edi
  800bda:	89 c5                	mov    %eax,%ebp
  800bdc:	89 c8                	mov    %ecx,%eax
  800bde:	31 d2                	xor    %edx,%edx
  800be0:	f7 f5                	div    %ebp
  800be2:	89 c1                	mov    %eax,%ecx
  800be4:	89 d8                	mov    %ebx,%eax
  800be6:	89 cf                	mov    %ecx,%edi
  800be8:	f7 f5                	div    %ebp
  800bea:	89 c3                	mov    %eax,%ebx
  800bec:	89 d8                	mov    %ebx,%eax
  800bee:	89 fa                	mov    %edi,%edx
  800bf0:	83 c4 1c             	add    $0x1c,%esp
  800bf3:	5b                   	pop    %ebx
  800bf4:	5e                   	pop    %esi
  800bf5:	5f                   	pop    %edi
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    
  800bf8:	90                   	nop
  800bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c00:	39 ce                	cmp    %ecx,%esi
  800c02:	77 74                	ja     800c78 <__udivdi3+0xd8>
  800c04:	0f bd fe             	bsr    %esi,%edi
  800c07:	83 f7 1f             	xor    $0x1f,%edi
  800c0a:	0f 84 98 00 00 00    	je     800ca8 <__udivdi3+0x108>
  800c10:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	89 c5                	mov    %eax,%ebp
  800c19:	29 fb                	sub    %edi,%ebx
  800c1b:	d3 e6                	shl    %cl,%esi
  800c1d:	89 d9                	mov    %ebx,%ecx
  800c1f:	d3 ed                	shr    %cl,%ebp
  800c21:	89 f9                	mov    %edi,%ecx
  800c23:	d3 e0                	shl    %cl,%eax
  800c25:	09 ee                	or     %ebp,%esi
  800c27:	89 d9                	mov    %ebx,%ecx
  800c29:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c2d:	89 d5                	mov    %edx,%ebp
  800c2f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c33:	d3 ed                	shr    %cl,%ebp
  800c35:	89 f9                	mov    %edi,%ecx
  800c37:	d3 e2                	shl    %cl,%edx
  800c39:	89 d9                	mov    %ebx,%ecx
  800c3b:	d3 e8                	shr    %cl,%eax
  800c3d:	09 c2                	or     %eax,%edx
  800c3f:	89 d0                	mov    %edx,%eax
  800c41:	89 ea                	mov    %ebp,%edx
  800c43:	f7 f6                	div    %esi
  800c45:	89 d5                	mov    %edx,%ebp
  800c47:	89 c3                	mov    %eax,%ebx
  800c49:	f7 64 24 0c          	mull   0xc(%esp)
  800c4d:	39 d5                	cmp    %edx,%ebp
  800c4f:	72 10                	jb     800c61 <__udivdi3+0xc1>
  800c51:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c55:	89 f9                	mov    %edi,%ecx
  800c57:	d3 e6                	shl    %cl,%esi
  800c59:	39 c6                	cmp    %eax,%esi
  800c5b:	73 07                	jae    800c64 <__udivdi3+0xc4>
  800c5d:	39 d5                	cmp    %edx,%ebp
  800c5f:	75 03                	jne    800c64 <__udivdi3+0xc4>
  800c61:	83 eb 01             	sub    $0x1,%ebx
  800c64:	31 ff                	xor    %edi,%edi
  800c66:	89 d8                	mov    %ebx,%eax
  800c68:	89 fa                	mov    %edi,%edx
  800c6a:	83 c4 1c             	add    $0x1c,%esp
  800c6d:	5b                   	pop    %ebx
  800c6e:	5e                   	pop    %esi
  800c6f:	5f                   	pop    %edi
  800c70:	5d                   	pop    %ebp
  800c71:	c3                   	ret    
  800c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c78:	31 ff                	xor    %edi,%edi
  800c7a:	31 db                	xor    %ebx,%ebx
  800c7c:	89 d8                	mov    %ebx,%eax
  800c7e:	89 fa                	mov    %edi,%edx
  800c80:	83 c4 1c             	add    $0x1c,%esp
  800c83:	5b                   	pop    %ebx
  800c84:	5e                   	pop    %esi
  800c85:	5f                   	pop    %edi
  800c86:	5d                   	pop    %ebp
  800c87:	c3                   	ret    
  800c88:	90                   	nop
  800c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c90:	89 d8                	mov    %ebx,%eax
  800c92:	f7 f7                	div    %edi
  800c94:	31 ff                	xor    %edi,%edi
  800c96:	89 c3                	mov    %eax,%ebx
  800c98:	89 d8                	mov    %ebx,%eax
  800c9a:	89 fa                	mov    %edi,%edx
  800c9c:	83 c4 1c             	add    $0x1c,%esp
  800c9f:	5b                   	pop    %ebx
  800ca0:	5e                   	pop    %esi
  800ca1:	5f                   	pop    %edi
  800ca2:	5d                   	pop    %ebp
  800ca3:	c3                   	ret    
  800ca4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ca8:	39 ce                	cmp    %ecx,%esi
  800caa:	72 0c                	jb     800cb8 <__udivdi3+0x118>
  800cac:	31 db                	xor    %ebx,%ebx
  800cae:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800cb2:	0f 87 34 ff ff ff    	ja     800bec <__udivdi3+0x4c>
  800cb8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800cbd:	e9 2a ff ff ff       	jmp    800bec <__udivdi3+0x4c>
  800cc2:	66 90                	xchg   %ax,%ax
  800cc4:	66 90                	xchg   %ax,%ax
  800cc6:	66 90                	xchg   %ax,%ax
  800cc8:	66 90                	xchg   %ax,%ax
  800cca:	66 90                	xchg   %ax,%ax
  800ccc:	66 90                	xchg   %ax,%ax
  800cce:	66 90                	xchg   %ax,%ax

00800cd0 <__umoddi3>:
  800cd0:	55                   	push   %ebp
  800cd1:	57                   	push   %edi
  800cd2:	56                   	push   %esi
  800cd3:	53                   	push   %ebx
  800cd4:	83 ec 1c             	sub    $0x1c,%esp
  800cd7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cdb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800cdf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ce3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ce7:	85 d2                	test   %edx,%edx
  800ce9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ced:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cf1:	89 f3                	mov    %esi,%ebx
  800cf3:	89 3c 24             	mov    %edi,(%esp)
  800cf6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cfa:	75 1c                	jne    800d18 <__umoddi3+0x48>
  800cfc:	39 f7                	cmp    %esi,%edi
  800cfe:	76 50                	jbe    800d50 <__umoddi3+0x80>
  800d00:	89 c8                	mov    %ecx,%eax
  800d02:	89 f2                	mov    %esi,%edx
  800d04:	f7 f7                	div    %edi
  800d06:	89 d0                	mov    %edx,%eax
  800d08:	31 d2                	xor    %edx,%edx
  800d0a:	83 c4 1c             	add    $0x1c,%esp
  800d0d:	5b                   	pop    %ebx
  800d0e:	5e                   	pop    %esi
  800d0f:	5f                   	pop    %edi
  800d10:	5d                   	pop    %ebp
  800d11:	c3                   	ret    
  800d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d18:	39 f2                	cmp    %esi,%edx
  800d1a:	89 d0                	mov    %edx,%eax
  800d1c:	77 52                	ja     800d70 <__umoddi3+0xa0>
  800d1e:	0f bd ea             	bsr    %edx,%ebp
  800d21:	83 f5 1f             	xor    $0x1f,%ebp
  800d24:	75 5a                	jne    800d80 <__umoddi3+0xb0>
  800d26:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d2a:	0f 82 e0 00 00 00    	jb     800e10 <__umoddi3+0x140>
  800d30:	39 0c 24             	cmp    %ecx,(%esp)
  800d33:	0f 86 d7 00 00 00    	jbe    800e10 <__umoddi3+0x140>
  800d39:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d3d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d41:	83 c4 1c             	add    $0x1c,%esp
  800d44:	5b                   	pop    %ebx
  800d45:	5e                   	pop    %esi
  800d46:	5f                   	pop    %edi
  800d47:	5d                   	pop    %ebp
  800d48:	c3                   	ret    
  800d49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d50:	85 ff                	test   %edi,%edi
  800d52:	89 fd                	mov    %edi,%ebp
  800d54:	75 0b                	jne    800d61 <__umoddi3+0x91>
  800d56:	b8 01 00 00 00       	mov    $0x1,%eax
  800d5b:	31 d2                	xor    %edx,%edx
  800d5d:	f7 f7                	div    %edi
  800d5f:	89 c5                	mov    %eax,%ebp
  800d61:	89 f0                	mov    %esi,%eax
  800d63:	31 d2                	xor    %edx,%edx
  800d65:	f7 f5                	div    %ebp
  800d67:	89 c8                	mov    %ecx,%eax
  800d69:	f7 f5                	div    %ebp
  800d6b:	89 d0                	mov    %edx,%eax
  800d6d:	eb 99                	jmp    800d08 <__umoddi3+0x38>
  800d6f:	90                   	nop
  800d70:	89 c8                	mov    %ecx,%eax
  800d72:	89 f2                	mov    %esi,%edx
  800d74:	83 c4 1c             	add    $0x1c,%esp
  800d77:	5b                   	pop    %ebx
  800d78:	5e                   	pop    %esi
  800d79:	5f                   	pop    %edi
  800d7a:	5d                   	pop    %ebp
  800d7b:	c3                   	ret    
  800d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d80:	8b 34 24             	mov    (%esp),%esi
  800d83:	bf 20 00 00 00       	mov    $0x20,%edi
  800d88:	89 e9                	mov    %ebp,%ecx
  800d8a:	29 ef                	sub    %ebp,%edi
  800d8c:	d3 e0                	shl    %cl,%eax
  800d8e:	89 f9                	mov    %edi,%ecx
  800d90:	89 f2                	mov    %esi,%edx
  800d92:	d3 ea                	shr    %cl,%edx
  800d94:	89 e9                	mov    %ebp,%ecx
  800d96:	09 c2                	or     %eax,%edx
  800d98:	89 d8                	mov    %ebx,%eax
  800d9a:	89 14 24             	mov    %edx,(%esp)
  800d9d:	89 f2                	mov    %esi,%edx
  800d9f:	d3 e2                	shl    %cl,%edx
  800da1:	89 f9                	mov    %edi,%ecx
  800da3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800da7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800dab:	d3 e8                	shr    %cl,%eax
  800dad:	89 e9                	mov    %ebp,%ecx
  800daf:	89 c6                	mov    %eax,%esi
  800db1:	d3 e3                	shl    %cl,%ebx
  800db3:	89 f9                	mov    %edi,%ecx
  800db5:	89 d0                	mov    %edx,%eax
  800db7:	d3 e8                	shr    %cl,%eax
  800db9:	89 e9                	mov    %ebp,%ecx
  800dbb:	09 d8                	or     %ebx,%eax
  800dbd:	89 d3                	mov    %edx,%ebx
  800dbf:	89 f2                	mov    %esi,%edx
  800dc1:	f7 34 24             	divl   (%esp)
  800dc4:	89 d6                	mov    %edx,%esi
  800dc6:	d3 e3                	shl    %cl,%ebx
  800dc8:	f7 64 24 04          	mull   0x4(%esp)
  800dcc:	39 d6                	cmp    %edx,%esi
  800dce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800dd2:	89 d1                	mov    %edx,%ecx
  800dd4:	89 c3                	mov    %eax,%ebx
  800dd6:	72 08                	jb     800de0 <__umoddi3+0x110>
  800dd8:	75 11                	jne    800deb <__umoddi3+0x11b>
  800dda:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dde:	73 0b                	jae    800deb <__umoddi3+0x11b>
  800de0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800de4:	1b 14 24             	sbb    (%esp),%edx
  800de7:	89 d1                	mov    %edx,%ecx
  800de9:	89 c3                	mov    %eax,%ebx
  800deb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800def:	29 da                	sub    %ebx,%edx
  800df1:	19 ce                	sbb    %ecx,%esi
  800df3:	89 f9                	mov    %edi,%ecx
  800df5:	89 f0                	mov    %esi,%eax
  800df7:	d3 e0                	shl    %cl,%eax
  800df9:	89 e9                	mov    %ebp,%ecx
  800dfb:	d3 ea                	shr    %cl,%edx
  800dfd:	89 e9                	mov    %ebp,%ecx
  800dff:	d3 ee                	shr    %cl,%esi
  800e01:	09 d0                	or     %edx,%eax
  800e03:	89 f2                	mov    %esi,%edx
  800e05:	83 c4 1c             	add    $0x1c,%esp
  800e08:	5b                   	pop    %ebx
  800e09:	5e                   	pop    %esi
  800e0a:	5f                   	pop    %edi
  800e0b:	5d                   	pop    %ebp
  800e0c:	c3                   	ret    
  800e0d:	8d 76 00             	lea    0x0(%esi),%esi
  800e10:	29 f9                	sub    %edi,%ecx
  800e12:	19 d6                	sbb    %edx,%esi
  800e14:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e1c:	e9 18 ff ff ff       	jmp    800d39 <__umoddi3+0x69>
