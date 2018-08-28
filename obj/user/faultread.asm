
obj/user/faultread:     file format elf32-i386


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

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	ff 35 00 00 00 00    	pushl  0x0
  80003f:	68 20 0e 80 00       	push   $0x800e20
  800044:	e8 e0 00 00 00       	call   800129 <cprintf>
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
  80005a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

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
  80008c:	e8 48 0a 00 00       	call   800ad9 <sys_env_destroy>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	53                   	push   %ebx
  80009a:	83 ec 04             	sub    $0x4,%esp
  80009d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a0:	8b 13                	mov    (%ebx),%edx
  8000a2:	8d 42 01             	lea    0x1(%edx),%eax
  8000a5:	89 03                	mov    %eax,(%ebx)
  8000a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000aa:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000ae:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000b3:	75 1a                	jne    8000cf <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000b5:	83 ec 08             	sub    $0x8,%esp
  8000b8:	68 ff 00 00 00       	push   $0xff
  8000bd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c0:	50                   	push   %eax
  8000c1:	e8 d6 09 00 00       	call   800a9c <sys_cputs>
		b->idx = 0;
  8000c6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000cc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000cf:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000d6:	c9                   	leave  
  8000d7:	c3                   	ret    

008000d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000d8:	55                   	push   %ebp
  8000d9:	89 e5                	mov    %esp,%ebp
  8000db:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000e1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000e8:	00 00 00 
	b.cnt = 0;
  8000eb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000f2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000f5:	ff 75 0c             	pushl  0xc(%ebp)
  8000f8:	ff 75 08             	pushl  0x8(%ebp)
  8000fb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800101:	50                   	push   %eax
  800102:	68 96 00 80 00       	push   $0x800096
  800107:	e8 1a 01 00 00       	call   800226 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80010c:	83 c4 08             	add    $0x8,%esp
  80010f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800115:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80011b:	50                   	push   %eax
  80011c:	e8 7b 09 00 00       	call   800a9c <sys_cputs>

	return b.cnt;
}
  800121:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800127:	c9                   	leave  
  800128:	c3                   	ret    

00800129 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800129:	55                   	push   %ebp
  80012a:	89 e5                	mov    %esp,%ebp
  80012c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80012f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800132:	50                   	push   %eax
  800133:	ff 75 08             	pushl  0x8(%ebp)
  800136:	e8 9d ff ff ff       	call   8000d8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80013b:	c9                   	leave  
  80013c:	c3                   	ret    

0080013d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80013d:	55                   	push   %ebp
  80013e:	89 e5                	mov    %esp,%ebp
  800140:	57                   	push   %edi
  800141:	56                   	push   %esi
  800142:	53                   	push   %ebx
  800143:	83 ec 1c             	sub    $0x1c,%esp
  800146:	89 c7                	mov    %eax,%edi
  800148:	89 d6                	mov    %edx,%esi
  80014a:	8b 45 08             	mov    0x8(%ebp),%eax
  80014d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800150:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800153:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800156:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800159:	bb 00 00 00 00       	mov    $0x0,%ebx
  80015e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800161:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800164:	39 d3                	cmp    %edx,%ebx
  800166:	72 05                	jb     80016d <printnum+0x30>
  800168:	39 45 10             	cmp    %eax,0x10(%ebp)
  80016b:	77 45                	ja     8001b2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80016d:	83 ec 0c             	sub    $0xc,%esp
  800170:	ff 75 18             	pushl  0x18(%ebp)
  800173:	8b 45 14             	mov    0x14(%ebp),%eax
  800176:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800179:	53                   	push   %ebx
  80017a:	ff 75 10             	pushl  0x10(%ebp)
  80017d:	83 ec 08             	sub    $0x8,%esp
  800180:	ff 75 e4             	pushl  -0x1c(%ebp)
  800183:	ff 75 e0             	pushl  -0x20(%ebp)
  800186:	ff 75 dc             	pushl  -0x24(%ebp)
  800189:	ff 75 d8             	pushl  -0x28(%ebp)
  80018c:	e8 ef 09 00 00       	call   800b80 <__udivdi3>
  800191:	83 c4 18             	add    $0x18,%esp
  800194:	52                   	push   %edx
  800195:	50                   	push   %eax
  800196:	89 f2                	mov    %esi,%edx
  800198:	89 f8                	mov    %edi,%eax
  80019a:	e8 9e ff ff ff       	call   80013d <printnum>
  80019f:	83 c4 20             	add    $0x20,%esp
  8001a2:	eb 18                	jmp    8001bc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001a4:	83 ec 08             	sub    $0x8,%esp
  8001a7:	56                   	push   %esi
  8001a8:	ff 75 18             	pushl  0x18(%ebp)
  8001ab:	ff d7                	call   *%edi
  8001ad:	83 c4 10             	add    $0x10,%esp
  8001b0:	eb 03                	jmp    8001b5 <printnum+0x78>
  8001b2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001b5:	83 eb 01             	sub    $0x1,%ebx
  8001b8:	85 db                	test   %ebx,%ebx
  8001ba:	7f e8                	jg     8001a4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001bc:	83 ec 08             	sub    $0x8,%esp
  8001bf:	56                   	push   %esi
  8001c0:	83 ec 04             	sub    $0x4,%esp
  8001c3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001c6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001c9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001cc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001cf:	e8 dc 0a 00 00       	call   800cb0 <__umoddi3>
  8001d4:	83 c4 14             	add    $0x14,%esp
  8001d7:	0f be 80 48 0e 80 00 	movsbl 0x800e48(%eax),%eax
  8001de:	50                   	push   %eax
  8001df:	ff d7                	call   *%edi
}
  8001e1:	83 c4 10             	add    $0x10,%esp
  8001e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e7:	5b                   	pop    %ebx
  8001e8:	5e                   	pop    %esi
  8001e9:	5f                   	pop    %edi
  8001ea:	5d                   	pop    %ebp
  8001eb:	c3                   	ret    

008001ec <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8001ec:	55                   	push   %ebp
  8001ed:	89 e5                	mov    %esp,%ebp
  8001ef:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8001f2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8001f6:	8b 10                	mov    (%eax),%edx
  8001f8:	3b 50 04             	cmp    0x4(%eax),%edx
  8001fb:	73 0a                	jae    800207 <sprintputch+0x1b>
		*b->buf++ = ch;
  8001fd:	8d 4a 01             	lea    0x1(%edx),%ecx
  800200:	89 08                	mov    %ecx,(%eax)
  800202:	8b 45 08             	mov    0x8(%ebp),%eax
  800205:	88 02                	mov    %al,(%edx)
}
  800207:	5d                   	pop    %ebp
  800208:	c3                   	ret    

00800209 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800209:	55                   	push   %ebp
  80020a:	89 e5                	mov    %esp,%ebp
  80020c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80020f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800212:	50                   	push   %eax
  800213:	ff 75 10             	pushl  0x10(%ebp)
  800216:	ff 75 0c             	pushl  0xc(%ebp)
  800219:	ff 75 08             	pushl  0x8(%ebp)
  80021c:	e8 05 00 00 00       	call   800226 <vprintfmt>
	va_end(ap);
}
  800221:	83 c4 10             	add    $0x10,%esp
  800224:	c9                   	leave  
  800225:	c3                   	ret    

00800226 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800226:	55                   	push   %ebp
  800227:	89 e5                	mov    %esp,%ebp
  800229:	57                   	push   %edi
  80022a:	56                   	push   %esi
  80022b:	53                   	push   %ebx
  80022c:	83 ec 2c             	sub    $0x2c,%esp
  80022f:	8b 75 08             	mov    0x8(%ebp),%esi
  800232:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800235:	8b 7d 10             	mov    0x10(%ebp),%edi
  800238:	eb 12                	jmp    80024c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
  80023a:	85 c0                	test   %eax,%eax
  80023c:	0f 84 6a 04 00 00    	je     8006ac <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800242:	83 ec 08             	sub    $0x8,%esp
  800245:	53                   	push   %ebx
  800246:	50                   	push   %eax
  800247:	ff d6                	call   *%esi
  800249:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  80024c:	83 c7 01             	add    $0x1,%edi
  80024f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800253:	83 f8 25             	cmp    $0x25,%eax
  800256:	75 e2                	jne    80023a <vprintfmt+0x14>
  800258:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80025c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800263:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80026a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800271:	b9 00 00 00 00       	mov    $0x0,%ecx
  800276:	eb 07                	jmp    80027f <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800278:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  80027b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80027f:	8d 47 01             	lea    0x1(%edi),%eax
  800282:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800285:	0f b6 07             	movzbl (%edi),%eax
  800288:	0f b6 d0             	movzbl %al,%edx
  80028b:	83 e8 23             	sub    $0x23,%eax
  80028e:	3c 55                	cmp    $0x55,%al
  800290:	0f 87 fb 03 00 00    	ja     800691 <vprintfmt+0x46b>
  800296:	0f b6 c0             	movzbl %al,%eax
  800299:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  8002a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
  8002a3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002a7:	eb d6                	jmp    80027f <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002ac:	b8 00 00 00 00       	mov    $0x0,%eax
  8002b1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  8002b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002b7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002bb:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002be:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002c1:	83 f9 09             	cmp    $0x9,%ecx
  8002c4:	77 3f                	ja     800305 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  8002c6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002c9:	eb e9                	jmp    8002b4 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  8002cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8002ce:	8b 00                	mov    (%eax),%eax
  8002d0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8002d6:	8d 40 04             	lea    0x4(%eax),%eax
  8002d9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8002df:	eb 2a                	jmp    80030b <vprintfmt+0xe5>
  8002e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002e4:	85 c0                	test   %eax,%eax
  8002e6:	ba 00 00 00 00       	mov    $0x0,%edx
  8002eb:	0f 49 d0             	cmovns %eax,%edx
  8002ee:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8002f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002f4:	eb 89                	jmp    80027f <vprintfmt+0x59>
  8002f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8002f9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800300:	e9 7a ff ff ff       	jmp    80027f <vprintfmt+0x59>
  800305:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800308:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  80030b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80030f:	0f 89 6a ff ff ff    	jns    80027f <vprintfmt+0x59>
				width = precision, precision = -1;
  800315:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800318:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80031b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800322:	e9 58 ff ff ff       	jmp    80027f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
  800327:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80032a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
  80032d:	e9 4d ff ff ff       	jmp    80027f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800332:	8b 45 14             	mov    0x14(%ebp),%eax
  800335:	8d 78 04             	lea    0x4(%eax),%edi
  800338:	83 ec 08             	sub    $0x8,%esp
  80033b:	53                   	push   %ebx
  80033c:	ff 30                	pushl  (%eax)
  80033e:	ff d6                	call   *%esi
			break;
  800340:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
  800343:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800346:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
  800349:	e9 fe fe ff ff       	jmp    80024c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80034e:	8b 45 14             	mov    0x14(%ebp),%eax
  800351:	8d 78 04             	lea    0x4(%eax),%edi
  800354:	8b 00                	mov    (%eax),%eax
  800356:	99                   	cltd   
  800357:	31 d0                	xor    %edx,%eax
  800359:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80035b:	83 f8 07             	cmp    $0x7,%eax
  80035e:	7f 0b                	jg     80036b <vprintfmt+0x145>
  800360:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  800367:	85 d2                	test   %edx,%edx
  800369:	75 1b                	jne    800386 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80036b:	50                   	push   %eax
  80036c:	68 60 0e 80 00       	push   $0x800e60
  800371:	53                   	push   %ebx
  800372:	56                   	push   %esi
  800373:	e8 91 fe ff ff       	call   800209 <printfmt>
  800378:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80037b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  80037e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800381:	e9 c6 fe ff ff       	jmp    80024c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800386:	52                   	push   %edx
  800387:	68 69 0e 80 00       	push   $0x800e69
  80038c:	53                   	push   %ebx
  80038d:	56                   	push   %esi
  80038e:	e8 76 fe ff ff       	call   800209 <printfmt>
  800393:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800396:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80039c:	e9 ab fe ff ff       	jmp    80024c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a4:	83 c0 04             	add    $0x4,%eax
  8003a7:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ad:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003af:	85 ff                	test   %edi,%edi
  8003b1:	b8 59 0e 80 00       	mov    $0x800e59,%eax
  8003b6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003b9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003bd:	0f 8e 94 00 00 00    	jle    800457 <vprintfmt+0x231>
  8003c3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003c7:	0f 84 98 00 00 00    	je     800465 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003cd:	83 ec 08             	sub    $0x8,%esp
  8003d0:	ff 75 d0             	pushl  -0x30(%ebp)
  8003d3:	57                   	push   %edi
  8003d4:	e8 5b 03 00 00       	call   800734 <strnlen>
  8003d9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003dc:	29 c1                	sub    %eax,%ecx
  8003de:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003e1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003e4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8003e8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003eb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8003ee:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8003f0:	eb 0f                	jmp    800401 <vprintfmt+0x1db>
					putch(padc, putdat);
  8003f2:	83 ec 08             	sub    $0x8,%esp
  8003f5:	53                   	push   %ebx
  8003f6:	ff 75 e0             	pushl  -0x20(%ebp)
  8003f9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8003fb:	83 ef 01             	sub    $0x1,%edi
  8003fe:	83 c4 10             	add    $0x10,%esp
  800401:	85 ff                	test   %edi,%edi
  800403:	7f ed                	jg     8003f2 <vprintfmt+0x1cc>
  800405:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800408:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80040b:	85 c9                	test   %ecx,%ecx
  80040d:	b8 00 00 00 00       	mov    $0x0,%eax
  800412:	0f 49 c1             	cmovns %ecx,%eax
  800415:	29 c1                	sub    %eax,%ecx
  800417:	89 75 08             	mov    %esi,0x8(%ebp)
  80041a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80041d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800420:	89 cb                	mov    %ecx,%ebx
  800422:	eb 4d                	jmp    800471 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800424:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800428:	74 1b                	je     800445 <vprintfmt+0x21f>
  80042a:	0f be c0             	movsbl %al,%eax
  80042d:	83 e8 20             	sub    $0x20,%eax
  800430:	83 f8 5e             	cmp    $0x5e,%eax
  800433:	76 10                	jbe    800445 <vprintfmt+0x21f>
					putch('?', putdat);
  800435:	83 ec 08             	sub    $0x8,%esp
  800438:	ff 75 0c             	pushl  0xc(%ebp)
  80043b:	6a 3f                	push   $0x3f
  80043d:	ff 55 08             	call   *0x8(%ebp)
  800440:	83 c4 10             	add    $0x10,%esp
  800443:	eb 0d                	jmp    800452 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800445:	83 ec 08             	sub    $0x8,%esp
  800448:	ff 75 0c             	pushl  0xc(%ebp)
  80044b:	52                   	push   %edx
  80044c:	ff 55 08             	call   *0x8(%ebp)
  80044f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800452:	83 eb 01             	sub    $0x1,%ebx
  800455:	eb 1a                	jmp    800471 <vprintfmt+0x24b>
  800457:	89 75 08             	mov    %esi,0x8(%ebp)
  80045a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80045d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800460:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800463:	eb 0c                	jmp    800471 <vprintfmt+0x24b>
  800465:	89 75 08             	mov    %esi,0x8(%ebp)
  800468:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80046b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80046e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800471:	83 c7 01             	add    $0x1,%edi
  800474:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800478:	0f be d0             	movsbl %al,%edx
  80047b:	85 d2                	test   %edx,%edx
  80047d:	74 23                	je     8004a2 <vprintfmt+0x27c>
  80047f:	85 f6                	test   %esi,%esi
  800481:	78 a1                	js     800424 <vprintfmt+0x1fe>
  800483:	83 ee 01             	sub    $0x1,%esi
  800486:	79 9c                	jns    800424 <vprintfmt+0x1fe>
  800488:	89 df                	mov    %ebx,%edi
  80048a:	8b 75 08             	mov    0x8(%ebp),%esi
  80048d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800490:	eb 18                	jmp    8004aa <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800492:	83 ec 08             	sub    $0x8,%esp
  800495:	53                   	push   %ebx
  800496:	6a 20                	push   $0x20
  800498:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80049a:	83 ef 01             	sub    $0x1,%edi
  80049d:	83 c4 10             	add    $0x10,%esp
  8004a0:	eb 08                	jmp    8004aa <vprintfmt+0x284>
  8004a2:	89 df                	mov    %ebx,%edi
  8004a4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004aa:	85 ff                	test   %edi,%edi
  8004ac:	7f e4                	jg     800492 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004b1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  8004b4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004b7:	e9 90 fd ff ff       	jmp    80024c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004bc:	83 f9 01             	cmp    $0x1,%ecx
  8004bf:	7e 19                	jle    8004da <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c4:	8b 50 04             	mov    0x4(%eax),%edx
  8004c7:	8b 00                	mov    (%eax),%eax
  8004c9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004cc:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d2:	8d 40 08             	lea    0x8(%eax),%eax
  8004d5:	89 45 14             	mov    %eax,0x14(%ebp)
  8004d8:	eb 38                	jmp    800512 <vprintfmt+0x2ec>
	else if (lflag)
  8004da:	85 c9                	test   %ecx,%ecx
  8004dc:	74 1b                	je     8004f9 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004de:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e1:	8b 00                	mov    (%eax),%eax
  8004e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004e6:	89 c1                	mov    %eax,%ecx
  8004e8:	c1 f9 1f             	sar    $0x1f,%ecx
  8004eb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f1:	8d 40 04             	lea    0x4(%eax),%eax
  8004f4:	89 45 14             	mov    %eax,0x14(%ebp)
  8004f7:	eb 19                	jmp    800512 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8004f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004fc:	8b 00                	mov    (%eax),%eax
  8004fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800501:	89 c1                	mov    %eax,%ecx
  800503:	c1 f9 1f             	sar    $0x1f,%ecx
  800506:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800509:	8b 45 14             	mov    0x14(%ebp),%eax
  80050c:	8d 40 04             	lea    0x4(%eax),%eax
  80050f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800512:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800515:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800518:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80051d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800521:	0f 89 36 01 00 00    	jns    80065d <vprintfmt+0x437>
				putch('-', putdat);
  800527:	83 ec 08             	sub    $0x8,%esp
  80052a:	53                   	push   %ebx
  80052b:	6a 2d                	push   $0x2d
  80052d:	ff d6                	call   *%esi
				num = -(long long) num;
  80052f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800532:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800535:	f7 da                	neg    %edx
  800537:	83 d1 00             	adc    $0x0,%ecx
  80053a:	f7 d9                	neg    %ecx
  80053c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80053f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800544:	e9 14 01 00 00       	jmp    80065d <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800549:	83 f9 01             	cmp    $0x1,%ecx
  80054c:	7e 18                	jle    800566 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80054e:	8b 45 14             	mov    0x14(%ebp),%eax
  800551:	8b 10                	mov    (%eax),%edx
  800553:	8b 48 04             	mov    0x4(%eax),%ecx
  800556:	8d 40 08             	lea    0x8(%eax),%eax
  800559:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80055c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800561:	e9 f7 00 00 00       	jmp    80065d <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800566:	85 c9                	test   %ecx,%ecx
  800568:	74 1a                	je     800584 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80056a:	8b 45 14             	mov    0x14(%ebp),%eax
  80056d:	8b 10                	mov    (%eax),%edx
  80056f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800574:	8d 40 04             	lea    0x4(%eax),%eax
  800577:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80057a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80057f:	e9 d9 00 00 00       	jmp    80065d <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800584:	8b 45 14             	mov    0x14(%ebp),%eax
  800587:	8b 10                	mov    (%eax),%edx
  800589:	b9 00 00 00 00       	mov    $0x0,%ecx
  80058e:	8d 40 04             	lea    0x4(%eax),%eax
  800591:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800594:	b8 0a 00 00 00       	mov    $0xa,%eax
  800599:	e9 bf 00 00 00       	jmp    80065d <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80059e:	83 f9 01             	cmp    $0x1,%ecx
  8005a1:	7e 13                	jle    8005b6 <vprintfmt+0x390>
		return va_arg(*ap, long long);
  8005a3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a6:	8b 50 04             	mov    0x4(%eax),%edx
  8005a9:	8b 00                	mov    (%eax),%eax
  8005ab:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005ae:	8d 49 08             	lea    0x8(%ecx),%ecx
  8005b1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005b4:	eb 28                	jmp    8005de <vprintfmt+0x3b8>
	else if (lflag)
  8005b6:	85 c9                	test   %ecx,%ecx
  8005b8:	74 13                	je     8005cd <vprintfmt+0x3a7>
		return va_arg(*ap, long);
  8005ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bd:	8b 10                	mov    (%eax),%edx
  8005bf:	89 d0                	mov    %edx,%eax
  8005c1:	99                   	cltd   
  8005c2:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005c5:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005c8:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005cb:	eb 11                	jmp    8005de <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
  8005cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d0:	8b 10                	mov    (%eax),%edx
  8005d2:	89 d0                	mov    %edx,%eax
  8005d4:	99                   	cltd   
  8005d5:	8b 4d 14             	mov    0x14(%ebp),%ecx
  8005d8:	8d 49 04             	lea    0x4(%ecx),%ecx
  8005db:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
  8005de:	89 d1                	mov    %edx,%ecx
  8005e0:	89 c2                	mov    %eax,%edx
			base = 8;
  8005e2:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8005e7:	eb 74                	jmp    80065d <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e9:	83 ec 08             	sub    $0x8,%esp
  8005ec:	53                   	push   %ebx
  8005ed:	6a 30                	push   $0x30
  8005ef:	ff d6                	call   *%esi
			putch('x', putdat);
  8005f1:	83 c4 08             	add    $0x8,%esp
  8005f4:	53                   	push   %ebx
  8005f5:	6a 78                	push   $0x78
  8005f7:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fc:	8b 10                	mov    (%eax),%edx
  8005fe:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800603:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800606:	8d 40 04             	lea    0x4(%eax),%eax
  800609:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  80060c:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800611:	eb 4a                	jmp    80065d <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800613:	83 f9 01             	cmp    $0x1,%ecx
  800616:	7e 15                	jle    80062d <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
  800618:	8b 45 14             	mov    0x14(%ebp),%eax
  80061b:	8b 10                	mov    (%eax),%edx
  80061d:	8b 48 04             	mov    0x4(%eax),%ecx
  800620:	8d 40 08             	lea    0x8(%eax),%eax
  800623:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800626:	b8 10 00 00 00       	mov    $0x10,%eax
  80062b:	eb 30                	jmp    80065d <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80062d:	85 c9                	test   %ecx,%ecx
  80062f:	74 17                	je     800648 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
  800631:	8b 45 14             	mov    0x14(%ebp),%eax
  800634:	8b 10                	mov    (%eax),%edx
  800636:	b9 00 00 00 00       	mov    $0x0,%ecx
  80063b:	8d 40 04             	lea    0x4(%eax),%eax
  80063e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800641:	b8 10 00 00 00       	mov    $0x10,%eax
  800646:	eb 15                	jmp    80065d <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800648:	8b 45 14             	mov    0x14(%ebp),%eax
  80064b:	8b 10                	mov    (%eax),%edx
  80064d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800652:	8d 40 04             	lea    0x4(%eax),%eax
  800655:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800658:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80065d:	83 ec 0c             	sub    $0xc,%esp
  800660:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800664:	57                   	push   %edi
  800665:	ff 75 e0             	pushl  -0x20(%ebp)
  800668:	50                   	push   %eax
  800669:	51                   	push   %ecx
  80066a:	52                   	push   %edx
  80066b:	89 da                	mov    %ebx,%edx
  80066d:	89 f0                	mov    %esi,%eax
  80066f:	e8 c9 fa ff ff       	call   80013d <printnum>
			break;
  800674:	83 c4 20             	add    $0x20,%esp
  800677:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80067a:	e9 cd fb ff ff       	jmp    80024c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80067f:	83 ec 08             	sub    $0x8,%esp
  800682:	53                   	push   %ebx
  800683:	52                   	push   %edx
  800684:	ff d6                	call   *%esi
			break;
  800686:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
  800689:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80068c:	e9 bb fb ff ff       	jmp    80024c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800691:	83 ec 08             	sub    $0x8,%esp
  800694:	53                   	push   %ebx
  800695:	6a 25                	push   $0x25
  800697:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800699:	83 c4 10             	add    $0x10,%esp
  80069c:	eb 03                	jmp    8006a1 <vprintfmt+0x47b>
  80069e:	83 ef 01             	sub    $0x1,%edi
  8006a1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006a5:	75 f7                	jne    80069e <vprintfmt+0x478>
  8006a7:	e9 a0 fb ff ff       	jmp    80024c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006af:	5b                   	pop    %ebx
  8006b0:	5e                   	pop    %esi
  8006b1:	5f                   	pop    %edi
  8006b2:	5d                   	pop    %ebp
  8006b3:	c3                   	ret    

008006b4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006b4:	55                   	push   %ebp
  8006b5:	89 e5                	mov    %esp,%ebp
  8006b7:	83 ec 18             	sub    $0x18,%esp
  8006ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8006bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006c3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006c7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006d1:	85 c0                	test   %eax,%eax
  8006d3:	74 26                	je     8006fb <vsnprintf+0x47>
  8006d5:	85 d2                	test   %edx,%edx
  8006d7:	7e 22                	jle    8006fb <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d9:	ff 75 14             	pushl  0x14(%ebp)
  8006dc:	ff 75 10             	pushl  0x10(%ebp)
  8006df:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006e2:	50                   	push   %eax
  8006e3:	68 ec 01 80 00       	push   $0x8001ec
  8006e8:	e8 39 fb ff ff       	call   800226 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006f0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006f6:	83 c4 10             	add    $0x10,%esp
  8006f9:	eb 05                	jmp    800700 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800700:	c9                   	leave  
  800701:	c3                   	ret    

00800702 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800702:	55                   	push   %ebp
  800703:	89 e5                	mov    %esp,%ebp
  800705:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800708:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80070b:	50                   	push   %eax
  80070c:	ff 75 10             	pushl  0x10(%ebp)
  80070f:	ff 75 0c             	pushl  0xc(%ebp)
  800712:	ff 75 08             	pushl  0x8(%ebp)
  800715:	e8 9a ff ff ff       	call   8006b4 <vsnprintf>
	va_end(ap);

	return rc;
}
  80071a:	c9                   	leave  
  80071b:	c3                   	ret    

0080071c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80071c:	55                   	push   %ebp
  80071d:	89 e5                	mov    %esp,%ebp
  80071f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800722:	b8 00 00 00 00       	mov    $0x0,%eax
  800727:	eb 03                	jmp    80072c <strlen+0x10>
		n++;
  800729:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80072c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800730:	75 f7                	jne    800729 <strlen+0xd>
		n++;
	return n;
}
  800732:	5d                   	pop    %ebp
  800733:	c3                   	ret    

00800734 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800734:	55                   	push   %ebp
  800735:	89 e5                	mov    %esp,%ebp
  800737:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80073a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80073d:	ba 00 00 00 00       	mov    $0x0,%edx
  800742:	eb 03                	jmp    800747 <strnlen+0x13>
		n++;
  800744:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800747:	39 c2                	cmp    %eax,%edx
  800749:	74 08                	je     800753 <strnlen+0x1f>
  80074b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80074f:	75 f3                	jne    800744 <strnlen+0x10>
  800751:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800753:	5d                   	pop    %ebp
  800754:	c3                   	ret    

00800755 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800755:	55                   	push   %ebp
  800756:	89 e5                	mov    %esp,%ebp
  800758:	53                   	push   %ebx
  800759:	8b 45 08             	mov    0x8(%ebp),%eax
  80075c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80075f:	89 c2                	mov    %eax,%edx
  800761:	83 c2 01             	add    $0x1,%edx
  800764:	83 c1 01             	add    $0x1,%ecx
  800767:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80076b:	88 5a ff             	mov    %bl,-0x1(%edx)
  80076e:	84 db                	test   %bl,%bl
  800770:	75 ef                	jne    800761 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800772:	5b                   	pop    %ebx
  800773:	5d                   	pop    %ebp
  800774:	c3                   	ret    

00800775 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800775:	55                   	push   %ebp
  800776:	89 e5                	mov    %esp,%ebp
  800778:	53                   	push   %ebx
  800779:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80077c:	53                   	push   %ebx
  80077d:	e8 9a ff ff ff       	call   80071c <strlen>
  800782:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800785:	ff 75 0c             	pushl  0xc(%ebp)
  800788:	01 d8                	add    %ebx,%eax
  80078a:	50                   	push   %eax
  80078b:	e8 c5 ff ff ff       	call   800755 <strcpy>
	return dst;
}
  800790:	89 d8                	mov    %ebx,%eax
  800792:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800795:	c9                   	leave  
  800796:	c3                   	ret    

00800797 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800797:	55                   	push   %ebp
  800798:	89 e5                	mov    %esp,%ebp
  80079a:	56                   	push   %esi
  80079b:	53                   	push   %ebx
  80079c:	8b 75 08             	mov    0x8(%ebp),%esi
  80079f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007a2:	89 f3                	mov    %esi,%ebx
  8007a4:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a7:	89 f2                	mov    %esi,%edx
  8007a9:	eb 0f                	jmp    8007ba <strncpy+0x23>
		*dst++ = *src;
  8007ab:	83 c2 01             	add    $0x1,%edx
  8007ae:	0f b6 01             	movzbl (%ecx),%eax
  8007b1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007b4:	80 39 01             	cmpb   $0x1,(%ecx)
  8007b7:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ba:	39 da                	cmp    %ebx,%edx
  8007bc:	75 ed                	jne    8007ab <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007be:	89 f0                	mov    %esi,%eax
  8007c0:	5b                   	pop    %ebx
  8007c1:	5e                   	pop    %esi
  8007c2:	5d                   	pop    %ebp
  8007c3:	c3                   	ret    

008007c4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007c4:	55                   	push   %ebp
  8007c5:	89 e5                	mov    %esp,%ebp
  8007c7:	56                   	push   %esi
  8007c8:	53                   	push   %ebx
  8007c9:	8b 75 08             	mov    0x8(%ebp),%esi
  8007cc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007cf:	8b 55 10             	mov    0x10(%ebp),%edx
  8007d2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007d4:	85 d2                	test   %edx,%edx
  8007d6:	74 21                	je     8007f9 <strlcpy+0x35>
  8007d8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007dc:	89 f2                	mov    %esi,%edx
  8007de:	eb 09                	jmp    8007e9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007e0:	83 c2 01             	add    $0x1,%edx
  8007e3:	83 c1 01             	add    $0x1,%ecx
  8007e6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e9:	39 c2                	cmp    %eax,%edx
  8007eb:	74 09                	je     8007f6 <strlcpy+0x32>
  8007ed:	0f b6 19             	movzbl (%ecx),%ebx
  8007f0:	84 db                	test   %bl,%bl
  8007f2:	75 ec                	jne    8007e0 <strlcpy+0x1c>
  8007f4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007f6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007f9:	29 f0                	sub    %esi,%eax
}
  8007fb:	5b                   	pop    %ebx
  8007fc:	5e                   	pop    %esi
  8007fd:	5d                   	pop    %ebp
  8007fe:	c3                   	ret    

008007ff <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800805:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800808:	eb 06                	jmp    800810 <strcmp+0x11>
		p++, q++;
  80080a:	83 c1 01             	add    $0x1,%ecx
  80080d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800810:	0f b6 01             	movzbl (%ecx),%eax
  800813:	84 c0                	test   %al,%al
  800815:	74 04                	je     80081b <strcmp+0x1c>
  800817:	3a 02                	cmp    (%edx),%al
  800819:	74 ef                	je     80080a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80081b:	0f b6 c0             	movzbl %al,%eax
  80081e:	0f b6 12             	movzbl (%edx),%edx
  800821:	29 d0                	sub    %edx,%eax
}
  800823:	5d                   	pop    %ebp
  800824:	c3                   	ret    

00800825 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800825:	55                   	push   %ebp
  800826:	89 e5                	mov    %esp,%ebp
  800828:	53                   	push   %ebx
  800829:	8b 45 08             	mov    0x8(%ebp),%eax
  80082c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80082f:	89 c3                	mov    %eax,%ebx
  800831:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800834:	eb 06                	jmp    80083c <strncmp+0x17>
		n--, p++, q++;
  800836:	83 c0 01             	add    $0x1,%eax
  800839:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80083c:	39 d8                	cmp    %ebx,%eax
  80083e:	74 15                	je     800855 <strncmp+0x30>
  800840:	0f b6 08             	movzbl (%eax),%ecx
  800843:	84 c9                	test   %cl,%cl
  800845:	74 04                	je     80084b <strncmp+0x26>
  800847:	3a 0a                	cmp    (%edx),%cl
  800849:	74 eb                	je     800836 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80084b:	0f b6 00             	movzbl (%eax),%eax
  80084e:	0f b6 12             	movzbl (%edx),%edx
  800851:	29 d0                	sub    %edx,%eax
  800853:	eb 05                	jmp    80085a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800855:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  80085a:	5b                   	pop    %ebx
  80085b:	5d                   	pop    %ebp
  80085c:	c3                   	ret    

0080085d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80085d:	55                   	push   %ebp
  80085e:	89 e5                	mov    %esp,%ebp
  800860:	8b 45 08             	mov    0x8(%ebp),%eax
  800863:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800867:	eb 07                	jmp    800870 <strchr+0x13>
		if (*s == c)
  800869:	38 ca                	cmp    %cl,%dl
  80086b:	74 0f                	je     80087c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80086d:	83 c0 01             	add    $0x1,%eax
  800870:	0f b6 10             	movzbl (%eax),%edx
  800873:	84 d2                	test   %dl,%dl
  800875:	75 f2                	jne    800869 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800877:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80087c:	5d                   	pop    %ebp
  80087d:	c3                   	ret    

0080087e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80087e:	55                   	push   %ebp
  80087f:	89 e5                	mov    %esp,%ebp
  800881:	8b 45 08             	mov    0x8(%ebp),%eax
  800884:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800888:	eb 03                	jmp    80088d <strfind+0xf>
  80088a:	83 c0 01             	add    $0x1,%eax
  80088d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800890:	38 ca                	cmp    %cl,%dl
  800892:	74 04                	je     800898 <strfind+0x1a>
  800894:	84 d2                	test   %dl,%dl
  800896:	75 f2                	jne    80088a <strfind+0xc>
			break;
	return (char *) s;
}
  800898:	5d                   	pop    %ebp
  800899:	c3                   	ret    

0080089a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  80089a:	55                   	push   %ebp
  80089b:	89 e5                	mov    %esp,%ebp
  80089d:	57                   	push   %edi
  80089e:	56                   	push   %esi
  80089f:	53                   	push   %ebx
  8008a0:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008a6:	85 c9                	test   %ecx,%ecx
  8008a8:	74 36                	je     8008e0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008aa:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008b0:	75 28                	jne    8008da <memset+0x40>
  8008b2:	f6 c1 03             	test   $0x3,%cl
  8008b5:	75 23                	jne    8008da <memset+0x40>
		c &= 0xFF;
  8008b7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008bb:	89 d3                	mov    %edx,%ebx
  8008bd:	c1 e3 08             	shl    $0x8,%ebx
  8008c0:	89 d6                	mov    %edx,%esi
  8008c2:	c1 e6 18             	shl    $0x18,%esi
  8008c5:	89 d0                	mov    %edx,%eax
  8008c7:	c1 e0 10             	shl    $0x10,%eax
  8008ca:	09 f0                	or     %esi,%eax
  8008cc:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008ce:	89 d8                	mov    %ebx,%eax
  8008d0:	09 d0                	or     %edx,%eax
  8008d2:	c1 e9 02             	shr    $0x2,%ecx
  8008d5:	fc                   	cld    
  8008d6:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d8:	eb 06                	jmp    8008e0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008da:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008dd:	fc                   	cld    
  8008de:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008e0:	89 f8                	mov    %edi,%eax
  8008e2:	5b                   	pop    %ebx
  8008e3:	5e                   	pop    %esi
  8008e4:	5f                   	pop    %edi
  8008e5:	5d                   	pop    %ebp
  8008e6:	c3                   	ret    

008008e7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008e7:	55                   	push   %ebp
  8008e8:	89 e5                	mov    %esp,%ebp
  8008ea:	57                   	push   %edi
  8008eb:	56                   	push   %esi
  8008ec:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ef:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008f2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008f5:	39 c6                	cmp    %eax,%esi
  8008f7:	73 35                	jae    80092e <memmove+0x47>
  8008f9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008fc:	39 d0                	cmp    %edx,%eax
  8008fe:	73 2e                	jae    80092e <memmove+0x47>
		s += n;
		d += n;
  800900:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800903:	89 d6                	mov    %edx,%esi
  800905:	09 fe                	or     %edi,%esi
  800907:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80090d:	75 13                	jne    800922 <memmove+0x3b>
  80090f:	f6 c1 03             	test   $0x3,%cl
  800912:	75 0e                	jne    800922 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800914:	83 ef 04             	sub    $0x4,%edi
  800917:	8d 72 fc             	lea    -0x4(%edx),%esi
  80091a:	c1 e9 02             	shr    $0x2,%ecx
  80091d:	fd                   	std    
  80091e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800920:	eb 09                	jmp    80092b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800922:	83 ef 01             	sub    $0x1,%edi
  800925:	8d 72 ff             	lea    -0x1(%edx),%esi
  800928:	fd                   	std    
  800929:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80092b:	fc                   	cld    
  80092c:	eb 1d                	jmp    80094b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80092e:	89 f2                	mov    %esi,%edx
  800930:	09 c2                	or     %eax,%edx
  800932:	f6 c2 03             	test   $0x3,%dl
  800935:	75 0f                	jne    800946 <memmove+0x5f>
  800937:	f6 c1 03             	test   $0x3,%cl
  80093a:	75 0a                	jne    800946 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80093c:	c1 e9 02             	shr    $0x2,%ecx
  80093f:	89 c7                	mov    %eax,%edi
  800941:	fc                   	cld    
  800942:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800944:	eb 05                	jmp    80094b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800946:	89 c7                	mov    %eax,%edi
  800948:	fc                   	cld    
  800949:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80094b:	5e                   	pop    %esi
  80094c:	5f                   	pop    %edi
  80094d:	5d                   	pop    %ebp
  80094e:	c3                   	ret    

0080094f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80094f:	55                   	push   %ebp
  800950:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800952:	ff 75 10             	pushl  0x10(%ebp)
  800955:	ff 75 0c             	pushl  0xc(%ebp)
  800958:	ff 75 08             	pushl  0x8(%ebp)
  80095b:	e8 87 ff ff ff       	call   8008e7 <memmove>
}
  800960:	c9                   	leave  
  800961:	c3                   	ret    

00800962 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800962:	55                   	push   %ebp
  800963:	89 e5                	mov    %esp,%ebp
  800965:	56                   	push   %esi
  800966:	53                   	push   %ebx
  800967:	8b 45 08             	mov    0x8(%ebp),%eax
  80096a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096d:	89 c6                	mov    %eax,%esi
  80096f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800972:	eb 1a                	jmp    80098e <memcmp+0x2c>
		if (*s1 != *s2)
  800974:	0f b6 08             	movzbl (%eax),%ecx
  800977:	0f b6 1a             	movzbl (%edx),%ebx
  80097a:	38 d9                	cmp    %bl,%cl
  80097c:	74 0a                	je     800988 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80097e:	0f b6 c1             	movzbl %cl,%eax
  800981:	0f b6 db             	movzbl %bl,%ebx
  800984:	29 d8                	sub    %ebx,%eax
  800986:	eb 0f                	jmp    800997 <memcmp+0x35>
		s1++, s2++;
  800988:	83 c0 01             	add    $0x1,%eax
  80098b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80098e:	39 f0                	cmp    %esi,%eax
  800990:	75 e2                	jne    800974 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800992:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800997:	5b                   	pop    %ebx
  800998:	5e                   	pop    %esi
  800999:	5d                   	pop    %ebp
  80099a:	c3                   	ret    

0080099b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80099b:	55                   	push   %ebp
  80099c:	89 e5                	mov    %esp,%ebp
  80099e:	53                   	push   %ebx
  80099f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009a2:	89 c1                	mov    %eax,%ecx
  8009a4:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a7:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ab:	eb 0a                	jmp    8009b7 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009ad:	0f b6 10             	movzbl (%eax),%edx
  8009b0:	39 da                	cmp    %ebx,%edx
  8009b2:	74 07                	je     8009bb <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009b4:	83 c0 01             	add    $0x1,%eax
  8009b7:	39 c8                	cmp    %ecx,%eax
  8009b9:	72 f2                	jb     8009ad <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009bb:	5b                   	pop    %ebx
  8009bc:	5d                   	pop    %ebp
  8009bd:	c3                   	ret    

008009be <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009be:	55                   	push   %ebp
  8009bf:	89 e5                	mov    %esp,%ebp
  8009c1:	57                   	push   %edi
  8009c2:	56                   	push   %esi
  8009c3:	53                   	push   %ebx
  8009c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ca:	eb 03                	jmp    8009cf <strtol+0x11>
		s++;
  8009cc:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009cf:	0f b6 01             	movzbl (%ecx),%eax
  8009d2:	3c 20                	cmp    $0x20,%al
  8009d4:	74 f6                	je     8009cc <strtol+0xe>
  8009d6:	3c 09                	cmp    $0x9,%al
  8009d8:	74 f2                	je     8009cc <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009da:	3c 2b                	cmp    $0x2b,%al
  8009dc:	75 0a                	jne    8009e8 <strtol+0x2a>
		s++;
  8009de:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009e1:	bf 00 00 00 00       	mov    $0x0,%edi
  8009e6:	eb 11                	jmp    8009f9 <strtol+0x3b>
  8009e8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009ed:	3c 2d                	cmp    $0x2d,%al
  8009ef:	75 08                	jne    8009f9 <strtol+0x3b>
		s++, neg = 1;
  8009f1:	83 c1 01             	add    $0x1,%ecx
  8009f4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009f9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009ff:	75 15                	jne    800a16 <strtol+0x58>
  800a01:	80 39 30             	cmpb   $0x30,(%ecx)
  800a04:	75 10                	jne    800a16 <strtol+0x58>
  800a06:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a0a:	75 7c                	jne    800a88 <strtol+0xca>
		s += 2, base = 16;
  800a0c:	83 c1 02             	add    $0x2,%ecx
  800a0f:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a14:	eb 16                	jmp    800a2c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a16:	85 db                	test   %ebx,%ebx
  800a18:	75 12                	jne    800a2c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a1a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a1f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a22:	75 08                	jne    800a2c <strtol+0x6e>
		s++, base = 8;
  800a24:	83 c1 01             	add    $0x1,%ecx
  800a27:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a2c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a31:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a34:	0f b6 11             	movzbl (%ecx),%edx
  800a37:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a3a:	89 f3                	mov    %esi,%ebx
  800a3c:	80 fb 09             	cmp    $0x9,%bl
  800a3f:	77 08                	ja     800a49 <strtol+0x8b>
			dig = *s - '0';
  800a41:	0f be d2             	movsbl %dl,%edx
  800a44:	83 ea 30             	sub    $0x30,%edx
  800a47:	eb 22                	jmp    800a6b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a49:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a4c:	89 f3                	mov    %esi,%ebx
  800a4e:	80 fb 19             	cmp    $0x19,%bl
  800a51:	77 08                	ja     800a5b <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a53:	0f be d2             	movsbl %dl,%edx
  800a56:	83 ea 57             	sub    $0x57,%edx
  800a59:	eb 10                	jmp    800a6b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a5b:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a5e:	89 f3                	mov    %esi,%ebx
  800a60:	80 fb 19             	cmp    $0x19,%bl
  800a63:	77 16                	ja     800a7b <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a65:	0f be d2             	movsbl %dl,%edx
  800a68:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a6b:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a6e:	7d 0b                	jge    800a7b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a70:	83 c1 01             	add    $0x1,%ecx
  800a73:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a77:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a79:	eb b9                	jmp    800a34 <strtol+0x76>

	if (endptr)
  800a7b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a7f:	74 0d                	je     800a8e <strtol+0xd0>
		*endptr = (char *) s;
  800a81:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a84:	89 0e                	mov    %ecx,(%esi)
  800a86:	eb 06                	jmp    800a8e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a88:	85 db                	test   %ebx,%ebx
  800a8a:	74 98                	je     800a24 <strtol+0x66>
  800a8c:	eb 9e                	jmp    800a2c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a8e:	89 c2                	mov    %eax,%edx
  800a90:	f7 da                	neg    %edx
  800a92:	85 ff                	test   %edi,%edi
  800a94:	0f 45 c2             	cmovne %edx,%eax
}
  800a97:	5b                   	pop    %ebx
  800a98:	5e                   	pop    %esi
  800a99:	5f                   	pop    %edi
  800a9a:	5d                   	pop    %ebp
  800a9b:	c3                   	ret    

00800a9c <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a9c:	55                   	push   %ebp
  800a9d:	89 e5                	mov    %esp,%ebp
  800a9f:	57                   	push   %edi
  800aa0:	56                   	push   %esi
  800aa1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aa2:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aaa:	8b 55 08             	mov    0x8(%ebp),%edx
  800aad:	89 c3                	mov    %eax,%ebx
  800aaf:	89 c7                	mov    %eax,%edi
  800ab1:	89 c6                	mov    %eax,%esi
  800ab3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ab5:	5b                   	pop    %ebx
  800ab6:	5e                   	pop    %esi
  800ab7:	5f                   	pop    %edi
  800ab8:	5d                   	pop    %ebp
  800ab9:	c3                   	ret    

00800aba <sys_cgetc>:

int
sys_cgetc(void)
{
  800aba:	55                   	push   %ebp
  800abb:	89 e5                	mov    %esp,%ebp
  800abd:	57                   	push   %edi
  800abe:	56                   	push   %esi
  800abf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ac0:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac5:	b8 01 00 00 00       	mov    $0x1,%eax
  800aca:	89 d1                	mov    %edx,%ecx
  800acc:	89 d3                	mov    %edx,%ebx
  800ace:	89 d7                	mov    %edx,%edi
  800ad0:	89 d6                	mov    %edx,%esi
  800ad2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ad4:	5b                   	pop    %ebx
  800ad5:	5e                   	pop    %esi
  800ad6:	5f                   	pop    %edi
  800ad7:	5d                   	pop    %ebp
  800ad8:	c3                   	ret    

00800ad9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ad9:	55                   	push   %ebp
  800ada:	89 e5                	mov    %esp,%ebp
  800adc:	57                   	push   %edi
  800add:	56                   	push   %esi
  800ade:	53                   	push   %ebx
  800adf:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ae2:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ae7:	b8 03 00 00 00       	mov    $0x3,%eax
  800aec:	8b 55 08             	mov    0x8(%ebp),%edx
  800aef:	89 cb                	mov    %ecx,%ebx
  800af1:	89 cf                	mov    %ecx,%edi
  800af3:	89 ce                	mov    %ecx,%esi
  800af5:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800af7:	85 c0                	test   %eax,%eax
  800af9:	7e 17                	jle    800b12 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800afb:	83 ec 0c             	sub    $0xc,%esp
  800afe:	50                   	push   %eax
  800aff:	6a 03                	push   $0x3
  800b01:	68 60 10 80 00       	push   $0x801060
  800b06:	6a 23                	push   $0x23
  800b08:	68 7d 10 80 00       	push   $0x80107d
  800b0d:	e8 27 00 00 00       	call   800b39 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b12:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b15:	5b                   	pop    %ebx
  800b16:	5e                   	pop    %esi
  800b17:	5f                   	pop    %edi
  800b18:	5d                   	pop    %ebp
  800b19:	c3                   	ret    

00800b1a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b1a:	55                   	push   %ebp
  800b1b:	89 e5                	mov    %esp,%ebp
  800b1d:	57                   	push   %edi
  800b1e:	56                   	push   %esi
  800b1f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b20:	ba 00 00 00 00       	mov    $0x0,%edx
  800b25:	b8 02 00 00 00       	mov    $0x2,%eax
  800b2a:	89 d1                	mov    %edx,%ecx
  800b2c:	89 d3                	mov    %edx,%ebx
  800b2e:	89 d7                	mov    %edx,%edi
  800b30:	89 d6                	mov    %edx,%esi
  800b32:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b34:	5b                   	pop    %ebx
  800b35:	5e                   	pop    %esi
  800b36:	5f                   	pop    %edi
  800b37:	5d                   	pop    %ebp
  800b38:	c3                   	ret    

00800b39 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b39:	55                   	push   %ebp
  800b3a:	89 e5                	mov    %esp,%ebp
  800b3c:	56                   	push   %esi
  800b3d:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b3e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b41:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b47:	e8 ce ff ff ff       	call   800b1a <sys_getenvid>
  800b4c:	83 ec 0c             	sub    $0xc,%esp
  800b4f:	ff 75 0c             	pushl  0xc(%ebp)
  800b52:	ff 75 08             	pushl  0x8(%ebp)
  800b55:	56                   	push   %esi
  800b56:	50                   	push   %eax
  800b57:	68 8c 10 80 00       	push   $0x80108c
  800b5c:	e8 c8 f5 ff ff       	call   800129 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b61:	83 c4 18             	add    $0x18,%esp
  800b64:	53                   	push   %ebx
  800b65:	ff 75 10             	pushl  0x10(%ebp)
  800b68:	e8 6b f5 ff ff       	call   8000d8 <vcprintf>
	cprintf("\n");
  800b6d:	c7 04 24 3c 0e 80 00 	movl   $0x800e3c,(%esp)
  800b74:	e8 b0 f5 ff ff       	call   800129 <cprintf>
  800b79:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b7c:	cc                   	int3   
  800b7d:	eb fd                	jmp    800b7c <_panic+0x43>
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
