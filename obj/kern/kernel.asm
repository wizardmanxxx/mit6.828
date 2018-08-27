
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.
	
	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# cr3存放页表地址
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	# cr0 保护模式寄存器
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	# 现在可以跳转到虚拟地址
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	# EBP设置为零，这样在debug模式下找到可以终止的时刻。
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	# 栈的地址
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[],  end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 f3 31 00 00       	call   f0103250 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// 在此之前无法调用cprintf
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 37 10 f0       	push   $0xf0103700
f010006f:	e8 73 26 00 00       	call   f01026e7 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 75 0f 00 00       	call   f0100fee <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 34 07 00 00       	call   f01007ba <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 1b 37 10 f0       	push   $0xf010371b
f01000b5:	e8 2d 26 00 00       	call   f01026e7 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 fd 25 00 00       	call   f01026c1 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 bd 3e 10 f0 	movl   $0xf0103ebd,(%esp)
f01000cb:	e8 17 26 00 00       	call   f01026e7 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 dd 06 00 00       	call   f01007ba <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 33 37 10 f0       	push   $0xf0103733
f01000f7:	e8 eb 25 00 00       	call   f01026e7 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 b9 25 00 00       	call   f01026c1 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 bd 3e 10 f0 	movl   $0xf0103ebd,(%esp)
f010010f:	e8 d3 25 00 00       	call   f01026e7 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 a0 38 10 f0 	movzbl -0xfefc760(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a a0 37 10 f0 	movzbl -0xfefc860(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 80 37 10 f0 	mov    -0xfefc880(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 4d 37 10 f0       	push   $0xf010374d
f0100265:	e8 7d 24 00 00       	call   f01026e7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 8a 2e 00 00       	call   f010329d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004b5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004c6:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 59 37 10 f0       	push   $0xf0103759
f01005e2:	e8 00 21 00 00       	call   f01026e7 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:
#define NCOMMANDS (sizeof(commands) / sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 a0 39 10 f0       	push   $0xf01039a0
f0100628:	68 be 39 10 f0       	push   $0xf01039be
f010062d:	68 c3 39 10 f0       	push   $0xf01039c3
f0100632:	e8 b0 20 00 00       	call   f01026e7 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 58 3a 10 f0       	push   $0xf0103a58
f010063f:	68 cc 39 10 f0       	push   $0xf01039cc
f0100644:	68 c3 39 10 f0       	push   $0xf01039c3
f0100649:	e8 99 20 00 00       	call   f01026e7 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 80 3a 10 f0       	push   $0xf0103a80
f0100656:	68 d5 39 10 f0       	push   $0xf01039d5
f010065b:	68 c3 39 10 f0       	push   $0xf01039c3
f0100660:	e8 82 20 00 00       	call   f01026e7 <cprintf>
	return 0;
}
f0100665:	b8 00 00 00 00       	mov    $0x0,%eax
f010066a:	c9                   	leave  
f010066b:	c3                   	ret    

f010066c <mon_kerninfo>:

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066c:	55                   	push   %ebp
f010066d:	89 e5                	mov    %esp,%ebp
f010066f:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100672:	68 df 39 10 f0       	push   $0xf01039df
f0100677:	e8 6b 20 00 00       	call   f01026e7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 b0 3a 10 f0       	push   $0xf0103ab0
f0100689:	e8 59 20 00 00       	call   f01026e7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 d8 3a 10 f0       	push   $0xf0103ad8
f01006a0:	e8 42 20 00 00       	call   f01026e7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 e1 36 10 00       	push   $0x1036e1
f01006ad:	68 e1 36 10 f0       	push   $0xf01036e1
f01006b2:	68 fc 3a 10 f0       	push   $0xf0103afc
f01006b7:	e8 2b 20 00 00       	call   f01026e7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 73 11 00       	push   $0x117300
f01006c4:	68 00 73 11 f0       	push   $0xf0117300
f01006c9:	68 20 3b 10 f0       	push   $0xf0103b20
f01006ce:	e8 14 20 00 00       	call   f01026e7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 70 79 11 00       	push   $0x117970
f01006db:	68 70 79 11 f0       	push   $0xf0117970
f01006e0:	68 44 3b 10 f0       	push   $0xf0103b44
f01006e5:	e8 fd 1f 00 00       	call   f01026e7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006ef:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f4:	83 c4 08             	add    $0x8,%esp
f01006f7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100702:	85 c0                	test   %eax,%eax
f0100704:	0f 48 c2             	cmovs  %edx,%eax
f0100707:	c1 f8 0a             	sar    $0xa,%eax
f010070a:	50                   	push   %eax
f010070b:	68 68 3b 10 f0       	push   $0xf0103b68
f0100710:	e8 d2 1f 00 00       	call   f01026e7 <cprintf>
			ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100715:	b8 00 00 00 00       	mov    $0x0,%eax
f010071a:	c9                   	leave  
f010071b:	c3                   	ret    

f010071c <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071c:	55                   	push   %ebp
f010071d:	89 e5                	mov    %esp,%ebp
f010071f:	57                   	push   %edi
f0100720:	56                   	push   %esi
f0100721:	53                   	push   %ebx
f0100722:	83 ec 58             	sub    $0x58,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100725:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
f0100727:	68 f8 39 10 f0       	push   $0xf01039f8
f010072c:	e8 b6 1f 00 00       	call   f01026e7 <cprintf>
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f0100731:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);
f0100734:	8d 75 d0             	lea    -0x30(%ebp),%esi
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f0100737:	eb 70                	jmp    f01007a9 <mon_backtrace+0x8d>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
f0100739:	ff 73 18             	pushl  0x18(%ebx)
f010073c:	ff 73 14             	pushl  0x14(%ebx)
f010073f:	ff 73 10             	pushl  0x10(%ebx)
f0100742:	ff 73 0c             	pushl  0xc(%ebx)
f0100745:	ff 73 08             	pushl  0x8(%ebx)
f0100748:	ff 73 04             	pushl  0x4(%ebx)
f010074b:	53                   	push   %ebx
f010074c:	68 94 3b 10 f0       	push   $0xf0103b94
f0100751:	e8 91 1f 00 00       	call   f01026e7 <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f0100756:	83 c4 18             	add    $0x18,%esp
f0100759:	56                   	push   %esi
f010075a:	ff 73 04             	pushl  0x4(%ebx)
f010075d:	e8 8f 20 00 00       	call   f01027f1 <debuginfo_eip>

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100762:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			fn_name[i]=info.eip_fn_name[i];
f0100765:	8b 7d d8             	mov    -0x28(%ebp),%edi
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100768:	83 c4 10             	add    $0x10,%esp
f010076b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100770:	eb 0b                	jmp    f010077d <mon_backtrace+0x61>
			fn_name[i]=info.eip_fn_name[i];
f0100772:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
f0100776:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f010077a:	83 c0 01             	add    $0x1,%eax
f010077d:	39 c8                	cmp    %ecx,%eax
f010077f:	7c f1                	jl     f0100772 <mon_backtrace+0x56>
			fn_name[i]=info.eip_fn_name[i];
		}
		fn_name[info.eip_fn_namelen]=0;
f0100781:	c6 44 0d b2 00       	movb   $0x0,-0x4e(%ebp,%ecx,1)
		int off = ebp[1]-info.eip_fn_addr;
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
f0100786:	83 ec 0c             	sub    $0xc,%esp
f0100789:	8b 43 04             	mov    0x4(%ebx),%eax
f010078c:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010078f:	50                   	push   %eax
f0100790:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100793:	50                   	push   %eax
f0100794:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100797:	ff 75 d0             	pushl  -0x30(%ebp)
f010079a:	68 0a 3a 10 f0       	push   $0xf0103a0a
f010079f:	e8 43 1f 00 00       	call   f01026e7 <cprintf>
		ebp = (int*)(*ebp);
f01007a4:	8b 1b                	mov    (%ebx),%ebx
f01007a6:	83 c4 20             	add    $0x20,%esp
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f01007a9:	85 db                	test   %ebx,%ebx
f01007ab:	75 8c                	jne    f0100739 <mon_backtrace+0x1d>
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
		ebp = (int*)(*ebp);
	}

	return 0;
}
f01007ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b5:	5b                   	pop    %ebx
f01007b6:	5e                   	pop    %esi
f01007b7:	5f                   	pop    %edi
f01007b8:	5d                   	pop    %ebp
f01007b9:	c3                   	ret    

f01007ba <monitor>:
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
f01007ba:	55                   	push   %ebp
f01007bb:	89 e5                	mov    %esp,%ebp
f01007bd:	57                   	push   %edi
f01007be:	56                   	push   %esi
f01007bf:	53                   	push   %ebx
f01007c0:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c3:	68 c8 3b 10 f0       	push   $0xf0103bc8
f01007c8:	e8 1a 1f 00 00       	call   f01026e7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cd:	c7 04 24 ec 3b 10 f0 	movl   $0xf0103bec,(%esp)
f01007d4:	e8 0e 1f 00 00       	call   f01026e7 <cprintf>
f01007d9:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f01007dc:	83 ec 0c             	sub    $0xc,%esp
f01007df:	68 19 3a 10 f0       	push   $0xf0103a19
f01007e4:	e8 10 28 00 00       	call   f0102ff9 <readline>
f01007e9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007eb:	83 c4 10             	add    $0x10,%esp
f01007ee:	85 c0                	test   %eax,%eax
f01007f0:	74 ea                	je     f01007dc <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f9:	be 00 00 00 00       	mov    $0x0,%esi
f01007fe:	eb 0a                	jmp    f010080a <monitor+0x50>
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100800:	c6 03 00             	movb   $0x0,(%ebx)
f0100803:	89 f7                	mov    %esi,%edi
f0100805:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100808:	89 fe                	mov    %edi,%esi
	argc = 0;
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080a:	0f b6 03             	movzbl (%ebx),%eax
f010080d:	84 c0                	test   %al,%al
f010080f:	74 63                	je     f0100874 <monitor+0xba>
f0100811:	83 ec 08             	sub    $0x8,%esp
f0100814:	0f be c0             	movsbl %al,%eax
f0100817:	50                   	push   %eax
f0100818:	68 1d 3a 10 f0       	push   $0xf0103a1d
f010081d:	e8 f1 29 00 00       	call   f0103213 <strchr>
f0100822:	83 c4 10             	add    $0x10,%esp
f0100825:	85 c0                	test   %eax,%eax
f0100827:	75 d7                	jne    f0100800 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100829:	80 3b 00             	cmpb   $0x0,(%ebx)
f010082c:	74 46                	je     f0100874 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1)
f010082e:	83 fe 0f             	cmp    $0xf,%esi
f0100831:	75 14                	jne    f0100847 <monitor+0x8d>
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100833:	83 ec 08             	sub    $0x8,%esp
f0100836:	6a 10                	push   $0x10
f0100838:	68 22 3a 10 f0       	push   $0xf0103a22
f010083d:	e8 a5 1e 00 00       	call   f01026e7 <cprintf>
f0100842:	83 c4 10             	add    $0x10,%esp
f0100845:	eb 95                	jmp    f01007dc <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100847:	8d 7e 01             	lea    0x1(%esi),%edi
f010084a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084e:	eb 03                	jmp    f0100853 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100850:	83 c3 01             	add    $0x1,%ebx
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100853:	0f b6 03             	movzbl (%ebx),%eax
f0100856:	84 c0                	test   %al,%al
f0100858:	74 ae                	je     f0100808 <monitor+0x4e>
f010085a:	83 ec 08             	sub    $0x8,%esp
f010085d:	0f be c0             	movsbl %al,%eax
f0100860:	50                   	push   %eax
f0100861:	68 1d 3a 10 f0       	push   $0xf0103a1d
f0100866:	e8 a8 29 00 00       	call   f0103213 <strchr>
f010086b:	83 c4 10             	add    $0x10,%esp
f010086e:	85 c0                	test   %eax,%eax
f0100870:	74 de                	je     f0100850 <monitor+0x96>
f0100872:	eb 94                	jmp    f0100808 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100874:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010087b:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010087c:	85 f6                	test   %esi,%esi
f010087e:	0f 84 58 ff ff ff    	je     f01007dc <monitor+0x22>
f0100884:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
	{
		if (strcmp(argv[0], commands[i].name) == 0)
f0100889:	83 ec 08             	sub    $0x8,%esp
f010088c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010088f:	ff 34 85 20 3c 10 f0 	pushl  -0xfefc3e0(,%eax,4)
f0100896:	ff 75 a8             	pushl  -0x58(%ebp)
f0100899:	e8 17 29 00 00       	call   f01031b5 <strcmp>
f010089e:	83 c4 10             	add    $0x10,%esp
f01008a1:	85 c0                	test   %eax,%eax
f01008a3:	75 21                	jne    f01008c6 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008a5:	83 ec 04             	sub    $0x4,%esp
f01008a8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ab:	ff 75 08             	pushl  0x8(%ebp)
f01008ae:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b1:	52                   	push   %edx
f01008b2:	56                   	push   %esi
f01008b3:	ff 14 85 28 3c 10 f0 	call   *-0xfefc3d8(,%eax,4)

	while (1)
	{
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	85 c0                	test   %eax,%eax
f01008bf:	78 25                	js     f01008e6 <monitor+0x12c>
f01008c1:	e9 16 ff ff ff       	jmp    f01007dc <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
f01008c6:	83 c3 01             	add    $0x1,%ebx
f01008c9:	83 fb 03             	cmp    $0x3,%ebx
f01008cc:	75 bb                	jne    f0100889 <monitor+0xcf>
	{
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ce:	83 ec 08             	sub    $0x8,%esp
f01008d1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d4:	68 3f 3a 10 f0       	push   $0xf0103a3f
f01008d9:	e8 09 1e 00 00       	call   f01026e7 <cprintf>
f01008de:	83 c4 10             	add    $0x10,%esp
f01008e1:	e9 f6 fe ff ff       	jmp    f01007dc <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008e9:	5b                   	pop    %ebx
f01008ea:	5e                   	pop    %esi
f01008eb:	5f                   	pop    %edi
f01008ec:	5d                   	pop    %ebp
f01008ed:	c3                   	ret    

f01008ee <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008ee:	55                   	push   %ebp
f01008ef:	89 e5                	mov    %esp,%ebp
f01008f1:	53                   	push   %ebx
f01008f2:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f01008f5:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01008fc:	75 11                	jne    f010090f <boot_alloc+0x21>
	{
		extern char end[];
		nextfree = ROUNDUP((char *)end, PGSIZE);
f01008fe:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100903:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100909:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010090f:	8b 1d 38 75 11 f0    	mov    0xf0117538,%ebx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100915:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f010091c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100922:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	if ((int)nextfree - KERNBASE > npages * PGSIZE)
f0100928:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010092e:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0100934:	c1 e1 0c             	shl    $0xc,%ecx
f0100937:	39 ca                	cmp    %ecx,%edx
f0100939:	76 14                	jbe    f010094f <boot_alloc+0x61>
	{
		panic("Out of memory!\n");
f010093b:	83 ec 04             	sub    $0x4,%esp
f010093e:	68 44 3c 10 f0       	push   $0xf0103c44
f0100943:	6a 68                	push   $0x68
f0100945:	68 54 3c 10 f0       	push   $0xf0103c54
f010094a:	e8 3c f7 ff ff       	call   f010008b <_panic>
	}

	return result;
}
f010094f:	89 d8                	mov    %ebx,%eax
f0100951:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100954:	c9                   	leave  
f0100955:	c3                   	ret    

f0100956 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100956:	89 d1                	mov    %edx,%ecx
f0100958:	c1 e9 16             	shr    $0x16,%ecx
f010095b:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010095e:	a8 01                	test   $0x1,%al
f0100960:	74 52                	je     f01009b4 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100962:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100967:	89 c1                	mov    %eax,%ecx
f0100969:	c1 e9 0c             	shr    $0xc,%ecx
f010096c:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100972:	72 1b                	jb     f010098f <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100974:	55                   	push   %ebp
f0100975:	89 e5                	mov    %esp,%ebp
f0100977:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010097a:	50                   	push   %eax
f010097b:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100980:	68 e9 02 00 00       	push   $0x2e9
f0100985:	68 54 3c 10 f0       	push   $0xf0103c54
f010098a:	e8 fc f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010098f:	c1 ea 0c             	shr    $0xc,%edx
f0100992:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100998:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010099f:	89 c2                	mov    %eax,%edx
f01009a1:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009a9:	85 d2                	test   %edx,%edx
f01009ab:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009b0:	0f 44 c2             	cmove  %edx,%eax
f01009b3:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009b9:	c3                   	ret    

f01009ba <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009ba:	55                   	push   %ebp
f01009bb:	89 e5                	mov    %esp,%ebp
f01009bd:	57                   	push   %edi
f01009be:	56                   	push   %esi
f01009bf:	53                   	push   %ebx
f01009c0:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009c3:	84 c0                	test   %al,%al
f01009c5:	0f 85 72 02 00 00    	jne    f0100c3d <check_page_free_list+0x283>
f01009cb:	e9 7f 02 00 00       	jmp    f0100c4f <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009d0:	83 ec 04             	sub    $0x4,%esp
f01009d3:	68 14 3f 10 f0       	push   $0xf0103f14
f01009d8:	68 26 02 00 00       	push   $0x226
f01009dd:	68 54 3c 10 f0       	push   $0xf0103c54
f01009e2:	e8 a4 f6 ff ff       	call   f010008b <_panic>
	if (only_low_memory)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
f01009e7:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009ea:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009ed:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link)
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009f3:	89 c2                	mov    %eax,%edx
f01009f5:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01009fb:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a01:	0f 95 c2             	setne  %dl
f0100a04:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a07:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a0b:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a0d:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a11:	8b 00                	mov    (%eax),%eax
f0100a13:	85 c0                	test   %eax,%eax
f0100a15:	75 dc                	jne    f01009f3 <check_page_free_list+0x39>
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a20:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a23:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a26:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a28:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a2b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a30:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a35:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a3b:	eb 53                	jmp    f0100a90 <check_page_free_list+0xd6>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100a3d:	89 d8                	mov    %ebx,%eax
f0100a3f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a45:	c1 f8 03             	sar    $0x3,%eax
f0100a48:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a4b:	89 c2                	mov    %eax,%edx
f0100a4d:	c1 ea 16             	shr    $0x16,%edx
f0100a50:	39 f2                	cmp    %esi,%edx
f0100a52:	73 3a                	jae    f0100a8e <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a54:	89 c2                	mov    %eax,%edx
f0100a56:	c1 ea 0c             	shr    $0xc,%edx
f0100a59:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a5f:	72 12                	jb     f0100a73 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a61:	50                   	push   %eax
f0100a62:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100a67:	6a 57                	push   $0x57
f0100a69:	68 60 3c 10 f0       	push   $0xf0103c60
f0100a6e:	e8 18 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a73:	83 ec 04             	sub    $0x4,%esp
f0100a76:	68 80 00 00 00       	push   $0x80
f0100a7b:	68 97 00 00 00       	push   $0x97
f0100a80:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a85:	50                   	push   %eax
f0100a86:	e8 c5 27 00 00       	call   f0103250 <memset>
f0100a8b:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a8e:	8b 1b                	mov    (%ebx),%ebx
f0100a90:	85 db                	test   %ebx,%ebx
f0100a92:	75 a9                	jne    f0100a3d <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
f0100a94:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a99:	e8 50 fe ff ff       	call   f01008ee <boot_alloc>
f0100a9e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aa1:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa7:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100aad:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100ab2:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ab5:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100ab8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100abb:	be 00 00 00 00       	mov    $0x0,%esi
f0100ac0:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac3:	e9 30 01 00 00       	jmp    f0100bf8 <check_page_free_list+0x23e>
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ac8:	39 ca                	cmp    %ecx,%edx
f0100aca:	73 19                	jae    f0100ae5 <check_page_free_list+0x12b>
f0100acc:	68 6e 3c 10 f0       	push   $0xf0103c6e
f0100ad1:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100ad6:	68 43 02 00 00       	push   $0x243
f0100adb:	68 54 3c 10 f0       	push   $0xf0103c54
f0100ae0:	e8 a6 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ae5:	39 fa                	cmp    %edi,%edx
f0100ae7:	72 19                	jb     f0100b02 <check_page_free_list+0x148>
f0100ae9:	68 8f 3c 10 f0       	push   $0xf0103c8f
f0100aee:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100af3:	68 44 02 00 00       	push   $0x244
f0100af8:	68 54 3c 10 f0       	push   $0xf0103c54
f0100afd:	e8 89 f5 ff ff       	call   f010008b <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100b02:	89 d0                	mov    %edx,%eax
f0100b04:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b07:	a8 07                	test   $0x7,%al
f0100b09:	74 19                	je     f0100b24 <check_page_free_list+0x16a>
f0100b0b:	68 38 3f 10 f0       	push   $0xf0103f38
f0100b10:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100b15:	68 45 02 00 00       	push   $0x245
f0100b1a:	68 54 3c 10 f0       	push   $0xf0103c54
f0100b1f:	e8 67 f5 ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100b24:	c1 f8 03             	sar    $0x3,%eax
f0100b27:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b2a:	85 c0                	test   %eax,%eax
f0100b2c:	75 19                	jne    f0100b47 <check_page_free_list+0x18d>
f0100b2e:	68 a3 3c 10 f0       	push   $0xf0103ca3
f0100b33:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100b38:	68 48 02 00 00       	push   $0x248
f0100b3d:	68 54 3c 10 f0       	push   $0xf0103c54
f0100b42:	e8 44 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b47:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b4c:	75 19                	jne    f0100b67 <check_page_free_list+0x1ad>
f0100b4e:	68 b4 3c 10 f0       	push   $0xf0103cb4
f0100b53:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100b58:	68 49 02 00 00       	push   $0x249
f0100b5d:	68 54 3c 10 f0       	push   $0xf0103c54
f0100b62:	e8 24 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b67:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b6c:	75 19                	jne    f0100b87 <check_page_free_list+0x1cd>
f0100b6e:	68 68 3f 10 f0       	push   $0xf0103f68
f0100b73:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100b78:	68 4a 02 00 00       	push   $0x24a
f0100b7d:	68 54 3c 10 f0       	push   $0xf0103c54
f0100b82:	e8 04 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b87:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b8c:	75 19                	jne    f0100ba7 <check_page_free_list+0x1ed>
f0100b8e:	68 cd 3c 10 f0       	push   $0xf0103ccd
f0100b93:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100b98:	68 4b 02 00 00       	push   $0x24b
f0100b9d:	68 54 3c 10 f0       	push   $0xf0103c54
f0100ba2:	e8 e4 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100ba7:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bac:	76 3f                	jbe    f0100bed <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bae:	89 c3                	mov    %eax,%ebx
f0100bb0:	c1 eb 0c             	shr    $0xc,%ebx
f0100bb3:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bb6:	77 12                	ja     f0100bca <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bb8:	50                   	push   %eax
f0100bb9:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100bbe:	6a 57                	push   $0x57
f0100bc0:	68 60 3c 10 f0       	push   $0xf0103c60
f0100bc5:	e8 c1 f4 ff ff       	call   f010008b <_panic>
f0100bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bd2:	76 1e                	jbe    f0100bf2 <check_page_free_list+0x238>
f0100bd4:	68 8c 3f 10 f0       	push   $0xf0103f8c
f0100bd9:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100bde:	68 4c 02 00 00       	push   $0x24c
f0100be3:	68 54 3c 10 f0       	push   $0xf0103c54
f0100be8:	e8 9e f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bed:	83 c6 01             	add    $0x1,%esi
f0100bf0:	eb 04                	jmp    f0100bf6 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bf2:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bf6:	8b 12                	mov    (%edx),%edx
f0100bf8:	85 d2                	test   %edx,%edx
f0100bfa:	0f 85 c8 fe ff ff    	jne    f0100ac8 <check_page_free_list+0x10e>
f0100c00:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c03:	85 f6                	test   %esi,%esi
f0100c05:	7f 19                	jg     f0100c20 <check_page_free_list+0x266>
f0100c07:	68 e7 3c 10 f0       	push   $0xf0103ce7
f0100c0c:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100c11:	68 54 02 00 00       	push   $0x254
f0100c16:	68 54 3c 10 f0       	push   $0xf0103c54
f0100c1b:	e8 6b f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c20:	85 db                	test   %ebx,%ebx
f0100c22:	7f 42                	jg     f0100c66 <check_page_free_list+0x2ac>
f0100c24:	68 f9 3c 10 f0       	push   $0xf0103cf9
f0100c29:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0100c2e:	68 55 02 00 00       	push   $0x255
f0100c33:	68 54 3c 10 f0       	push   $0xf0103c54
f0100c38:	e8 4e f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c3d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c42:	85 c0                	test   %eax,%eax
f0100c44:	0f 85 9d fd ff ff    	jne    f01009e7 <check_page_free_list+0x2d>
f0100c4a:	e9 81 fd ff ff       	jmp    f01009d0 <check_page_free_list+0x16>
f0100c4f:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c56:	0f 84 74 fd ff ff    	je     f01009d0 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c5c:	be 00 04 00 00       	mov    $0x400,%esi
f0100c61:	e9 cf fd ff ff       	jmp    f0100a35 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c69:	5b                   	pop    %ebx
f0100c6a:	5e                   	pop    %esi
f0100c6b:	5f                   	pop    %edi
f0100c6c:	5d                   	pop    %ebp
f0100c6d:	c3                   	ret    

f0100c6e <page_init>:
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
// 初始化该系统内所有页信息，报错在数组pages内，并形成空闲链表
void page_init(void)
{
f0100c6e:	55                   	push   %ebp
f0100c6f:	89 e5                	mov    %esp,%ebp
f0100c71:	53                   	push   %ebx
f0100c72:	83 ec 04             	sub    $0x4,%esp
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100c75:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c7a:	e9 96 00 00 00       	jmp    f0100d15 <page_init+0xa7>
	{

		if (i == 0)
f0100c7f:	85 db                	test   %ebx,%ebx
f0100c81:	75 13                	jne    f0100c96 <page_init+0x28>
		{
			pages[i].pp_ref = 1;
f0100c83:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100c88:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c8e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100c94:	eb 7c                	jmp    f0100d12 <page_init+0xa4>
		}
		else if (i > npages_basemem - 1 && i < PADDR(boot_alloc(0)) / PGSIZE)
f0100c96:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0100c9b:	83 e8 01             	sub    $0x1,%eax
f0100c9e:	39 c3                	cmp    %eax,%ebx
f0100ca0:	76 48                	jbe    f0100cea <page_init+0x7c>
f0100ca2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ca7:	e8 42 fc ff ff       	call   f01008ee <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cb1:	77 15                	ja     f0100cc8 <page_init+0x5a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cb3:	50                   	push   %eax
f0100cb4:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0100cb9:	68 12 01 00 00       	push   $0x112
f0100cbe:	68 54 3c 10 f0       	push   $0xf0103c54
f0100cc3:	e8 c3 f3 ff ff       	call   f010008b <_panic>
f0100cc8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ccd:	c1 e8 0c             	shr    $0xc,%eax
f0100cd0:	39 c3                	cmp    %eax,%ebx
f0100cd2:	73 16                	jae    f0100cea <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100cd4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100cd9:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100cdc:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100ce2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100ce8:	eb 28                	jmp    f0100d12 <page_init+0xa4>
f0100cea:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}
		else
		{
			pages[i].pp_ref = 0;
f0100cf1:	89 c2                	mov    %eax,%edx
f0100cf3:	03 15 6c 79 11 f0    	add    0xf011796c,%edx
f0100cf9:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100cff:	8b 0d 3c 75 11 f0    	mov    0xf011753c,%ecx
f0100d05:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100d07:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d0d:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100d12:	83 c3 01             	add    $0x1,%ebx
f0100d15:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100d1b:	0f 82 5e ff ff ff    	jb     f0100c7f <page_init+0x11>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d21:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d24:	c9                   	leave  
f0100d25:	c3                   	ret    

f0100d26 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d26:	55                   	push   %ebp
f0100d27:	89 e5                	mov    %esp,%ebp
f0100d29:	53                   	push   %ebx
f0100d2a:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *p = NULL;
	if (page_free_list == NULL)
f0100d2d:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d33:	85 db                	test   %ebx,%ebx
f0100d35:	74 58                	je     f0100d8f <page_alloc+0x69>
		return NULL;

	p = page_free_list;
	page_free_list = p->pp_link;
f0100d37:	8b 03                	mov    (%ebx),%eax
f0100d39:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	p->pp_link = NULL;
f0100d3e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
f0100d44:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d48:	74 45                	je     f0100d8f <page_alloc+0x69>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100d4a:	89 d8                	mov    %ebx,%eax
f0100d4c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d52:	c1 f8 03             	sar    $0x3,%eax
f0100d55:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d58:	89 c2                	mov    %eax,%edx
f0100d5a:	c1 ea 0c             	shr    $0xc,%edx
f0100d5d:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100d63:	72 12                	jb     f0100d77 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d65:	50                   	push   %eax
f0100d66:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100d6b:	6a 57                	push   $0x57
f0100d6d:	68 60 3c 10 f0       	push   $0xf0103c60
f0100d72:	e8 14 f3 ff ff       	call   f010008b <_panic>
	{
		memset(page2kva(p), 0, PGSIZE);
f0100d77:	83 ec 04             	sub    $0x4,%esp
f0100d7a:	68 00 10 00 00       	push   $0x1000
f0100d7f:	6a 00                	push   $0x0
f0100d81:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d86:	50                   	push   %eax
f0100d87:	e8 c4 24 00 00       	call   f0103250 <memset>
f0100d8c:	83 c4 10             	add    $0x10,%esp
	}

	return p;
}
f0100d8f:	89 d8                	mov    %ebx,%eax
f0100d91:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d94:	c9                   	leave  
f0100d95:	c3                   	ret    

f0100d96 <page_free>:
//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void page_free(struct PageInfo *pp)
{
f0100d96:	55                   	push   %ebp
f0100d97:	89 e5                	mov    %esp,%ebp
f0100d99:	83 ec 08             	sub    $0x8,%esp
f0100d9c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	if (pp->pp_ref != 0 || pp->pp_link != NULL)
f0100d9f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100da4:	75 05                	jne    f0100dab <page_free+0x15>
f0100da6:	83 38 00             	cmpl   $0x0,(%eax)
f0100da9:	74 17                	je     f0100dc2 <page_free+0x2c>
	{
		panic("still in used!");
f0100dab:	83 ec 04             	sub    $0x4,%esp
f0100dae:	68 0a 3d 10 f0       	push   $0xf0103d0a
f0100db3:	68 4c 01 00 00       	push   $0x14c
f0100db8:	68 54 3c 10 f0       	push   $0xf0103c54
f0100dbd:	e8 c9 f2 ff ff       	call   f010008b <_panic>
	}
	else
	{
		pp->pp_link = page_free_list;
f0100dc2:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100dc8:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100dca:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	}
}
f0100dcf:	c9                   	leave  
f0100dd0:	c3                   	ret    

f0100dd1 <page_decref>:
//
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void page_decref(struct PageInfo *pp)
{
f0100dd1:	55                   	push   %ebp
f0100dd2:	89 e5                	mov    %esp,%ebp
f0100dd4:	83 ec 08             	sub    $0x8,%esp
f0100dd7:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100dda:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100dde:	83 e8 01             	sub    $0x1,%eax
f0100de1:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100de5:	66 85 c0             	test   %ax,%ax
f0100de8:	75 0c                	jne    f0100df6 <page_decref+0x25>
		page_free(pp);
f0100dea:	83 ec 0c             	sub    $0xc,%esp
f0100ded:	52                   	push   %edx
f0100dee:	e8 a3 ff ff ff       	call   f0100d96 <page_free>
f0100df3:	83 c4 10             	add    $0x10,%esp
}
f0100df6:	c9                   	leave  
f0100df7:	c3                   	ret    

f0100df8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100df8:	55                   	push   %ebp
f0100df9:	89 e5                	mov    %esp,%ebp
f0100dfb:	56                   	push   %esi
f0100dfc:	53                   	push   %ebx
f0100dfd:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
f0100e00:	89 f3                	mov    %esi,%ebx
f0100e02:	c1 eb 16             	shr    $0x16,%ebx
f0100e05:	c1 e3 02             	shl    $0x2,%ebx
f0100e08:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e0b:	f6 03 01             	testb  $0x1,(%ebx)
f0100e0e:	75 2e                	jne    f0100e3e <pgdir_walk+0x46>
	{
		if (create == 0)
f0100e10:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e14:	74 63                	je     f0100e79 <pgdir_walk+0x81>
			return NULL;
		struct PageInfo *p = page_alloc(1);
f0100e16:	83 ec 0c             	sub    $0xc,%esp
f0100e19:	6a 01                	push   $0x1
f0100e1b:	e8 06 ff ff ff       	call   f0100d26 <page_alloc>
		if (p == NULL)
f0100e20:	83 c4 10             	add    $0x10,%esp
f0100e23:	85 c0                	test   %eax,%eax
f0100e25:	74 59                	je     f0100e80 <pgdir_walk+0x88>
			return NULL;
		p->pp_ref = 1;
f0100e27:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

		// 页目录项存储的是页表项的物理地址
		// 操作系统直接转换的所以自然是物理地址
		pgdir[index] = page2pa(p) | PTE_P | PTE_U | PTE_W;
f0100e2d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e33:	c1 f8 03             	sar    $0x3,%eax
f0100e36:	c1 e0 0c             	shl    $0xc,%eax
f0100e39:	83 c8 07             	or     $0x7,%eax
f0100e3c:	89 03                	mov    %eax,(%ebx)
	}
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);
f0100e3e:	8b 03                	mov    (%ebx),%eax
f0100e40:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e45:	89 c2                	mov    %eax,%edx
f0100e47:	c1 ea 0c             	shr    $0xc,%edx
f0100e4a:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e50:	72 15                	jb     f0100e67 <pgdir_walk+0x6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e52:	50                   	push   %eax
f0100e53:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100e58:	68 89 01 00 00       	push   $0x189
f0100e5d:	68 54 3c 10 f0       	push   $0xf0103c54
f0100e62:	e8 24 f2 ff ff       	call   f010008b <_panic>
f0100e67:	c1 ee 0a             	shr    $0xa,%esi
f0100e6a:	81 e6 fc 0f 00 00    	and    $0xffc,%esi

	return pte;
f0100e70:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100e77:	eb 0c                	jmp    f0100e85 <pgdir_walk+0x8d>
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
	{
		if (create == 0)
			return NULL;
f0100e79:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e7e:	eb 05                	jmp    f0100e85 <pgdir_walk+0x8d>
		struct PageInfo *p = page_alloc(1);
		if (p == NULL)
			return NULL;
f0100e80:	b8 00 00 00 00       	mov    $0x0,%eax
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);

	return pte;
}
f0100e85:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e88:	5b                   	pop    %ebx
f0100e89:	5e                   	pop    %esi
f0100e8a:	5d                   	pop    %ebp
f0100e8b:	c3                   	ret    

f0100e8c <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e8c:	55                   	push   %ebp
f0100e8d:	89 e5                	mov    %esp,%ebp
f0100e8f:	57                   	push   %edi
f0100e90:	56                   	push   %esi
f0100e91:	53                   	push   %ebx
f0100e92:	83 ec 1c             	sub    $0x1c,%esp
f0100e95:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e98:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
f0100e9b:	c1 e9 0c             	shr    $0xc,%ecx
f0100e9e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i=0; i<pg_num; i++) {
f0100ea1:	89 c3                	mov    %eax,%ebx
f0100ea3:	be 00 00 00 00       	mov    $0x0,%esi
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100ea8:	89 d7                	mov    %edx,%edi
f0100eaa:	29 c7                	sub    %eax,%edi
		if (!pgtab) {
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f0100eac:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eaf:	83 c8 01             	or     $0x1,%eax
f0100eb2:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i=0; i<pg_num; i++) {
f0100eb5:	eb 28                	jmp    f0100edf <boot_map_region+0x53>
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0100eb7:	83 ec 04             	sub    $0x4,%esp
f0100eba:	6a 01                	push   $0x1
f0100ebc:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100ebf:	50                   	push   %eax
f0100ec0:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ec3:	e8 30 ff ff ff       	call   f0100df8 <pgdir_walk>
		if (!pgtab) {
f0100ec8:	83 c4 10             	add    $0x10,%esp
f0100ecb:	85 c0                	test   %eax,%eax
f0100ecd:	74 15                	je     f0100ee4 <boot_map_region+0x58>
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f0100ecf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ed2:	09 da                	or     %ebx,%edx
f0100ed4:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f0100ed6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i=0; i<pg_num; i++) {
f0100edc:	83 c6 01             	add    $0x1,%esi
f0100edf:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100ee2:	75 d3                	jne    f0100eb7 <boot_map_region+0x2b>
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100ee4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ee7:	5b                   	pop    %ebx
f0100ee8:	5e                   	pop    %esi
f0100ee9:	5f                   	pop    %edi
f0100eea:	5d                   	pop    %ebp
f0100eeb:	c3                   	ret    

f0100eec <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//
// 双重指针，为了改变指针指向的值
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100eec:	55                   	push   %ebp
f0100eed:	89 e5                	mov    %esp,%ebp
f0100eef:	53                   	push   %ebx
f0100ef0:	83 ec 08             	sub    $0x8,%esp
f0100ef3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
f0100ef6:	6a 00                	push   $0x0
f0100ef8:	ff 75 0c             	pushl  0xc(%ebp)
f0100efb:	ff 75 08             	pushl  0x8(%ebp)
f0100efe:	e8 f5 fe ff ff       	call   f0100df8 <pgdir_walk>
	if (p == NULL)
f0100f03:	83 c4 10             	add    $0x10,%esp
f0100f06:	85 c0                	test   %eax,%eax
f0100f08:	74 32                	je     f0100f3c <page_lookup+0x50>
		return NULL;
	if (pte_store != NULL)
f0100f0a:	85 db                	test   %ebx,%ebx
f0100f0c:	74 02                	je     f0100f10 <page_lookup+0x24>
		*pte_store = p;
f0100f0e:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f10:	8b 00                	mov    (%eax),%eax
f0100f12:	c1 e8 0c             	shr    $0xc,%eax
f0100f15:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100f1b:	72 14                	jb     f0100f31 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f1d:	83 ec 04             	sub    $0x4,%esp
f0100f20:	68 f4 3f 10 f0       	push   $0xf0103ff4
f0100f25:	6a 50                	push   $0x50
f0100f27:	68 60 3c 10 f0       	push   $0xf0103c60
f0100f2c:	e8 5a f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f31:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100f37:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*p));
f0100f3a:	eb 05                	jmp    f0100f41 <page_lookup+0x55>
{
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
	if (p == NULL)
		return NULL;
f0100f3c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != NULL)
		*pte_store = p;

	return pa2page(PTE_ADDR(*p));
}
f0100f41:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f44:	c9                   	leave  
f0100f45:	c3                   	ret    

f0100f46 <page_remove>:
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void page_remove(pde_t *pgdir, void *va)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	53                   	push   %ebx
f0100f4a:	83 ec 18             	sub    $0x18,%esp
f0100f4d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *p = NULL;
f0100f50:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &p);
f0100f57:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f5a:	50                   	push   %eax
f0100f5b:	53                   	push   %ebx
f0100f5c:	ff 75 08             	pushl  0x8(%ebp)
f0100f5f:	e8 88 ff ff ff       	call   f0100eec <page_lookup>
	if (page != NULL)
f0100f64:	83 c4 10             	add    $0x10,%esp
f0100f67:	85 c0                	test   %eax,%eax
f0100f69:	74 18                	je     f0100f83 <page_remove+0x3d>
	{
		*p = 0;
f0100f6b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f6e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		page_decref(page);
f0100f74:	83 ec 0c             	sub    $0xc,%esp
f0100f77:	50                   	push   %eax
f0100f78:	e8 54 fe ff ff       	call   f0100dd1 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f7d:	0f 01 3b             	invlpg (%ebx)
f0100f80:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0100f83:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f86:	c9                   	leave  
f0100f87:	c3                   	ret    

f0100f88 <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f88:	55                   	push   %ebp
f0100f89:	89 e5                	mov    %esp,%ebp
f0100f8b:	57                   	push   %edi
f0100f8c:	56                   	push   %esi
f0100f8d:	53                   	push   %ebx
f0100f8e:	83 ec 10             	sub    $0x10,%esp
f0100f91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f94:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *p = pgdir_walk(pgdir, va, 1);
f0100f97:	6a 01                	push   $0x1
f0100f99:	57                   	push   %edi
f0100f9a:	ff 75 08             	pushl  0x8(%ebp)
f0100f9d:	e8 56 fe ff ff       	call   f0100df8 <pgdir_walk>
	if (p == NULL)
f0100fa2:	83 c4 10             	add    $0x10,%esp
f0100fa5:	85 c0                	test   %eax,%eax
f0100fa7:	74 38                	je     f0100fe1 <page_insert+0x59>
f0100fa9:	89 c6                	mov    %eax,%esi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100fab:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*p & PTE_P)
f0100fb0:	f6 00 01             	testb  $0x1,(%eax)
f0100fb3:	74 0f                	je     f0100fc4 <page_insert+0x3c>
	{
		page_remove(pgdir, va);
f0100fb5:	83 ec 08             	sub    $0x8,%esp
f0100fb8:	57                   	push   %edi
f0100fb9:	ff 75 08             	pushl  0x8(%ebp)
f0100fbc:	e8 85 ff ff ff       	call   f0100f46 <page_remove>
f0100fc1:	83 c4 10             	add    $0x10,%esp
	}
	*p = page2pa(pp) | perm | PTE_P;
f0100fc4:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f0100fca:	c1 fb 03             	sar    $0x3,%ebx
f0100fcd:	c1 e3 0c             	shl    $0xc,%ebx
f0100fd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd3:	83 c8 01             	or     $0x1,%eax
f0100fd6:	09 c3                	or     %eax,%ebx
f0100fd8:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100fda:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fdf:	eb 05                	jmp    f0100fe6 <page_insert+0x5e>
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *p = pgdir_walk(pgdir, va, 1);
	if (p == NULL)
	{
		return -E_NO_MEM;
f0100fe1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	{
		page_remove(pgdir, va);
	}
	*p = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0100fe6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fe9:	5b                   	pop    %ebx
f0100fea:	5e                   	pop    %esi
f0100feb:	5f                   	pop    %edi
f0100fec:	5d                   	pop    %ebp
f0100fed:	c3                   	ret    

f0100fee <mem_init>:
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
// 二级页表

void mem_init(void)
{
f0100fee:	55                   	push   %ebp
f0100fef:	89 e5                	mov    %esp,%ebp
f0100ff1:	57                   	push   %edi
f0100ff2:	56                   	push   %esi
f0100ff3:	53                   	push   %ebx
f0100ff4:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ff7:	6a 15                	push   $0x15
f0100ff9:	e8 82 16 00 00       	call   f0102680 <mc146818_read>
f0100ffe:	89 c3                	mov    %eax,%ebx
f0101000:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101007:	e8 74 16 00 00       	call   f0102680 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010100c:	c1 e0 08             	shl    $0x8,%eax
f010100f:	09 d8                	or     %ebx,%eax
f0101011:	c1 e0 0a             	shl    $0xa,%eax
f0101014:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010101a:	85 c0                	test   %eax,%eax
f010101c:	0f 48 c2             	cmovs  %edx,%eax
f010101f:	c1 f8 0c             	sar    $0xc,%eax
f0101022:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101027:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010102e:	e8 4d 16 00 00       	call   f0102680 <mc146818_read>
f0101033:	89 c3                	mov    %eax,%ebx
f0101035:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010103c:	e8 3f 16 00 00       	call   f0102680 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101041:	c1 e0 08             	shl    $0x8,%eax
f0101044:	09 d8                	or     %ebx,%eax
f0101046:	c1 e0 0a             	shl    $0xa,%eax
f0101049:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010104f:	83 c4 10             	add    $0x10,%esp
f0101052:	85 c0                	test   %eax,%eax
f0101054:	0f 48 c2             	cmovs  %edx,%eax
f0101057:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010105a:	85 c0                	test   %eax,%eax
f010105c:	74 0e                	je     f010106c <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010105e:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101064:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f010106a:	eb 0c                	jmp    f0101078 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010106c:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0101072:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101078:	c1 e0 0c             	shl    $0xc,%eax
f010107b:	c1 e8 0a             	shr    $0xa,%eax
f010107e:	50                   	push   %eax
f010107f:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101084:	c1 e0 0c             	shl    $0xc,%eax
f0101087:	c1 e8 0a             	shr    $0xa,%eax
f010108a:	50                   	push   %eax
f010108b:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101090:	c1 e0 0c             	shl    $0xc,%eax
f0101093:	c1 e8 0a             	shr    $0xa,%eax
f0101096:	50                   	push   %eax
f0101097:	68 14 40 10 f0       	push   $0xf0104014
f010109c:	e8 46 16 00 00       	call   f01026e7 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	// 创建一个初始化的页目录表
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f01010a1:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010a6:	e8 43 f8 ff ff       	call   f01008ee <boot_alloc>
f01010ab:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01010b0:	83 c4 0c             	add    $0xc,%esp
f01010b3:	68 00 10 00 00       	push   $0x1000
f01010b8:	6a 00                	push   $0x0
f01010ba:	50                   	push   %eax
f01010bb:	e8 90 21 00 00       	call   f0103250 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010c0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010c5:	83 c4 10             	add    $0x10,%esp
f01010c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010cd:	77 15                	ja     f01010e4 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010cf:	50                   	push   %eax
f01010d0:	68 d0 3f 10 f0       	push   $0xf0103fd0
f01010d5:	68 91 00 00 00       	push   $0x91
f01010da:	68 54 3c 10 f0       	push   $0xf0103c54
f01010df:	e8 a7 ef ff ff       	call   f010008b <_panic>
f01010e4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010ea:	83 ca 05             	or     $0x5,%edx
f01010ed:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f01010f3:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01010f8:	c1 e0 03             	shl    $0x3,%eax
f01010fb:	e8 ee f7 ff ff       	call   f01008ee <boot_alloc>
f0101100:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f0101105:	83 ec 04             	sub    $0x4,%esp
f0101108:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010110e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101115:	52                   	push   %edx
f0101116:	6a 00                	push   $0x0
f0101118:	50                   	push   %eax
f0101119:	e8 32 21 00 00       	call   f0103250 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010111e:	e8 4b fb ff ff       	call   f0100c6e <page_init>

	check_page_free_list(1);
f0101123:	b8 01 00 00 00       	mov    $0x1,%eax
f0101128:	e8 8d f8 ff ff       	call   f01009ba <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010112d:	83 c4 10             	add    $0x10,%esp
f0101130:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f0101137:	75 17                	jne    f0101150 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101139:	83 ec 04             	sub    $0x4,%esp
f010113c:	68 19 3d 10 f0       	push   $0xf0103d19
f0101141:	68 66 02 00 00       	push   $0x266
f0101146:	68 54 3c 10 f0       	push   $0xf0103c54
f010114b:	e8 3b ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101150:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101155:	bb 00 00 00 00       	mov    $0x0,%ebx
f010115a:	eb 05                	jmp    f0101161 <mem_init+0x173>
		++nfree;
f010115c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115f:	8b 00                	mov    (%eax),%eax
f0101161:	85 c0                	test   %eax,%eax
f0101163:	75 f7                	jne    f010115c <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101165:	83 ec 0c             	sub    $0xc,%esp
f0101168:	6a 00                	push   $0x0
f010116a:	e8 b7 fb ff ff       	call   f0100d26 <page_alloc>
f010116f:	89 c7                	mov    %eax,%edi
f0101171:	83 c4 10             	add    $0x10,%esp
f0101174:	85 c0                	test   %eax,%eax
f0101176:	75 19                	jne    f0101191 <mem_init+0x1a3>
f0101178:	68 34 3d 10 f0       	push   $0xf0103d34
f010117d:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101182:	68 6e 02 00 00       	push   $0x26e
f0101187:	68 54 3c 10 f0       	push   $0xf0103c54
f010118c:	e8 fa ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101191:	83 ec 0c             	sub    $0xc,%esp
f0101194:	6a 00                	push   $0x0
f0101196:	e8 8b fb ff ff       	call   f0100d26 <page_alloc>
f010119b:	89 c6                	mov    %eax,%esi
f010119d:	83 c4 10             	add    $0x10,%esp
f01011a0:	85 c0                	test   %eax,%eax
f01011a2:	75 19                	jne    f01011bd <mem_init+0x1cf>
f01011a4:	68 4a 3d 10 f0       	push   $0xf0103d4a
f01011a9:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01011ae:	68 6f 02 00 00       	push   $0x26f
f01011b3:	68 54 3c 10 f0       	push   $0xf0103c54
f01011b8:	e8 ce ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011bd:	83 ec 0c             	sub    $0xc,%esp
f01011c0:	6a 00                	push   $0x0
f01011c2:	e8 5f fb ff ff       	call   f0100d26 <page_alloc>
f01011c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011ca:	83 c4 10             	add    $0x10,%esp
f01011cd:	85 c0                	test   %eax,%eax
f01011cf:	75 19                	jne    f01011ea <mem_init+0x1fc>
f01011d1:	68 60 3d 10 f0       	push   $0xf0103d60
f01011d6:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01011db:	68 70 02 00 00       	push   $0x270
f01011e0:	68 54 3c 10 f0       	push   $0xf0103c54
f01011e5:	e8 a1 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011ea:	39 f7                	cmp    %esi,%edi
f01011ec:	75 19                	jne    f0101207 <mem_init+0x219>
f01011ee:	68 76 3d 10 f0       	push   $0xf0103d76
f01011f3:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01011f8:	68 73 02 00 00       	push   $0x273
f01011fd:	68 54 3c 10 f0       	push   $0xf0103c54
f0101202:	e8 84 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101207:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010120a:	39 c6                	cmp    %eax,%esi
f010120c:	74 04                	je     f0101212 <mem_init+0x224>
f010120e:	39 c7                	cmp    %eax,%edi
f0101210:	75 19                	jne    f010122b <mem_init+0x23d>
f0101212:	68 50 40 10 f0       	push   $0xf0104050
f0101217:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010121c:	68 74 02 00 00       	push   $0x274
f0101221:	68 54 3c 10 f0       	push   $0xf0103c54
f0101226:	e8 60 ee ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010122b:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f0101231:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0101237:	c1 e2 0c             	shl    $0xc,%edx
f010123a:	89 f8                	mov    %edi,%eax
f010123c:	29 c8                	sub    %ecx,%eax
f010123e:	c1 f8 03             	sar    $0x3,%eax
f0101241:	c1 e0 0c             	shl    $0xc,%eax
f0101244:	39 d0                	cmp    %edx,%eax
f0101246:	72 19                	jb     f0101261 <mem_init+0x273>
f0101248:	68 70 40 10 f0       	push   $0xf0104070
f010124d:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101252:	68 75 02 00 00       	push   $0x275
f0101257:	68 54 3c 10 f0       	push   $0xf0103c54
f010125c:	e8 2a ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f0101261:	89 f0                	mov    %esi,%eax
f0101263:	29 c8                	sub    %ecx,%eax
f0101265:	c1 f8 03             	sar    $0x3,%eax
f0101268:	c1 e0 0c             	shl    $0xc,%eax
f010126b:	39 c2                	cmp    %eax,%edx
f010126d:	77 19                	ja     f0101288 <mem_init+0x29a>
f010126f:	68 90 40 10 f0       	push   $0xf0104090
f0101274:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101279:	68 76 02 00 00       	push   $0x276
f010127e:	68 54 3c 10 f0       	push   $0xf0103c54
f0101283:	e8 03 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f0101288:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010128b:	29 c8                	sub    %ecx,%eax
f010128d:	c1 f8 03             	sar    $0x3,%eax
f0101290:	c1 e0 0c             	shl    $0xc,%eax
f0101293:	39 c2                	cmp    %eax,%edx
f0101295:	77 19                	ja     f01012b0 <mem_init+0x2c2>
f0101297:	68 b0 40 10 f0       	push   $0xf01040b0
f010129c:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01012a1:	68 77 02 00 00       	push   $0x277
f01012a6:	68 54 3c 10 f0       	push   $0xf0103c54
f01012ab:	e8 db ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012b0:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012b5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012b8:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01012bf:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012c2:	83 ec 0c             	sub    $0xc,%esp
f01012c5:	6a 00                	push   $0x0
f01012c7:	e8 5a fa ff ff       	call   f0100d26 <page_alloc>
f01012cc:	83 c4 10             	add    $0x10,%esp
f01012cf:	85 c0                	test   %eax,%eax
f01012d1:	74 19                	je     f01012ec <mem_init+0x2fe>
f01012d3:	68 88 3d 10 f0       	push   $0xf0103d88
f01012d8:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01012dd:	68 7e 02 00 00       	push   $0x27e
f01012e2:	68 54 3c 10 f0       	push   $0xf0103c54
f01012e7:	e8 9f ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012ec:	83 ec 0c             	sub    $0xc,%esp
f01012ef:	57                   	push   %edi
f01012f0:	e8 a1 fa ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f01012f5:	89 34 24             	mov    %esi,(%esp)
f01012f8:	e8 99 fa ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f01012fd:	83 c4 04             	add    $0x4,%esp
f0101300:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101303:	e8 8e fa ff ff       	call   f0100d96 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101308:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010130f:	e8 12 fa ff ff       	call   f0100d26 <page_alloc>
f0101314:	89 c6                	mov    %eax,%esi
f0101316:	83 c4 10             	add    $0x10,%esp
f0101319:	85 c0                	test   %eax,%eax
f010131b:	75 19                	jne    f0101336 <mem_init+0x348>
f010131d:	68 34 3d 10 f0       	push   $0xf0103d34
f0101322:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101327:	68 85 02 00 00       	push   $0x285
f010132c:	68 54 3c 10 f0       	push   $0xf0103c54
f0101331:	e8 55 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101336:	83 ec 0c             	sub    $0xc,%esp
f0101339:	6a 00                	push   $0x0
f010133b:	e8 e6 f9 ff ff       	call   f0100d26 <page_alloc>
f0101340:	89 c7                	mov    %eax,%edi
f0101342:	83 c4 10             	add    $0x10,%esp
f0101345:	85 c0                	test   %eax,%eax
f0101347:	75 19                	jne    f0101362 <mem_init+0x374>
f0101349:	68 4a 3d 10 f0       	push   $0xf0103d4a
f010134e:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101353:	68 86 02 00 00       	push   $0x286
f0101358:	68 54 3c 10 f0       	push   $0xf0103c54
f010135d:	e8 29 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101362:	83 ec 0c             	sub    $0xc,%esp
f0101365:	6a 00                	push   $0x0
f0101367:	e8 ba f9 ff ff       	call   f0100d26 <page_alloc>
f010136c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010136f:	83 c4 10             	add    $0x10,%esp
f0101372:	85 c0                	test   %eax,%eax
f0101374:	75 19                	jne    f010138f <mem_init+0x3a1>
f0101376:	68 60 3d 10 f0       	push   $0xf0103d60
f010137b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101380:	68 87 02 00 00       	push   $0x287
f0101385:	68 54 3c 10 f0       	push   $0xf0103c54
f010138a:	e8 fc ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010138f:	39 fe                	cmp    %edi,%esi
f0101391:	75 19                	jne    f01013ac <mem_init+0x3be>
f0101393:	68 76 3d 10 f0       	push   $0xf0103d76
f0101398:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010139d:	68 89 02 00 00       	push   $0x289
f01013a2:	68 54 3c 10 f0       	push   $0xf0103c54
f01013a7:	e8 df ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013af:	39 c7                	cmp    %eax,%edi
f01013b1:	74 04                	je     f01013b7 <mem_init+0x3c9>
f01013b3:	39 c6                	cmp    %eax,%esi
f01013b5:	75 19                	jne    f01013d0 <mem_init+0x3e2>
f01013b7:	68 50 40 10 f0       	push   $0xf0104050
f01013bc:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01013c1:	68 8a 02 00 00       	push   $0x28a
f01013c6:	68 54 3c 10 f0       	push   $0xf0103c54
f01013cb:	e8 bb ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013d0:	83 ec 0c             	sub    $0xc,%esp
f01013d3:	6a 00                	push   $0x0
f01013d5:	e8 4c f9 ff ff       	call   f0100d26 <page_alloc>
f01013da:	83 c4 10             	add    $0x10,%esp
f01013dd:	85 c0                	test   %eax,%eax
f01013df:	74 19                	je     f01013fa <mem_init+0x40c>
f01013e1:	68 88 3d 10 f0       	push   $0xf0103d88
f01013e6:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01013eb:	68 8b 02 00 00       	push   $0x28b
f01013f0:	68 54 3c 10 f0       	push   $0xf0103c54
f01013f5:	e8 91 ec ff ff       	call   f010008b <_panic>
f01013fa:	89 f0                	mov    %esi,%eax
f01013fc:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101402:	c1 f8 03             	sar    $0x3,%eax
f0101405:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101408:	89 c2                	mov    %eax,%edx
f010140a:	c1 ea 0c             	shr    $0xc,%edx
f010140d:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101413:	72 12                	jb     f0101427 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101415:	50                   	push   %eax
f0101416:	68 f0 3e 10 f0       	push   $0xf0103ef0
f010141b:	6a 57                	push   $0x57
f010141d:	68 60 3c 10 f0       	push   $0xf0103c60
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101427:	83 ec 04             	sub    $0x4,%esp
f010142a:	68 00 10 00 00       	push   $0x1000
f010142f:	6a 01                	push   $0x1
f0101431:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101436:	50                   	push   %eax
f0101437:	e8 14 1e 00 00       	call   f0103250 <memset>
	page_free(pp0);
f010143c:	89 34 24             	mov    %esi,(%esp)
f010143f:	e8 52 f9 ff ff       	call   f0100d96 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101444:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010144b:	e8 d6 f8 ff ff       	call   f0100d26 <page_alloc>
f0101450:	83 c4 10             	add    $0x10,%esp
f0101453:	85 c0                	test   %eax,%eax
f0101455:	75 19                	jne    f0101470 <mem_init+0x482>
f0101457:	68 97 3d 10 f0       	push   $0xf0103d97
f010145c:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101461:	68 90 02 00 00       	push   $0x290
f0101466:	68 54 3c 10 f0       	push   $0xf0103c54
f010146b:	e8 1b ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101470:	39 c6                	cmp    %eax,%esi
f0101472:	74 19                	je     f010148d <mem_init+0x49f>
f0101474:	68 b5 3d 10 f0       	push   $0xf0103db5
f0101479:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010147e:	68 91 02 00 00       	push   $0x291
f0101483:	68 54 3c 10 f0       	push   $0xf0103c54
f0101488:	e8 fe eb ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010148d:	89 f0                	mov    %esi,%eax
f010148f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101495:	c1 f8 03             	sar    $0x3,%eax
f0101498:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149b:	89 c2                	mov    %eax,%edx
f010149d:	c1 ea 0c             	shr    $0xc,%edx
f01014a0:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014a6:	72 12                	jb     f01014ba <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014a8:	50                   	push   %eax
f01014a9:	68 f0 3e 10 f0       	push   $0xf0103ef0
f01014ae:	6a 57                	push   $0x57
f01014b0:	68 60 3c 10 f0       	push   $0xf0103c60
f01014b5:	e8 d1 eb ff ff       	call   f010008b <_panic>
f01014ba:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014c0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014c6:	80 38 00             	cmpb   $0x0,(%eax)
f01014c9:	74 19                	je     f01014e4 <mem_init+0x4f6>
f01014cb:	68 c5 3d 10 f0       	push   $0xf0103dc5
f01014d0:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01014d5:	68 94 02 00 00       	push   $0x294
f01014da:	68 54 3c 10 f0       	push   $0xf0103c54
f01014df:	e8 a7 eb ff ff       	call   f010008b <_panic>
f01014e4:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014e7:	39 d0                	cmp    %edx,%eax
f01014e9:	75 db                	jne    f01014c6 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014eb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014ee:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01014f3:	83 ec 0c             	sub    $0xc,%esp
f01014f6:	56                   	push   %esi
f01014f7:	e8 9a f8 ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f01014fc:	89 3c 24             	mov    %edi,(%esp)
f01014ff:	e8 92 f8 ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f0101504:	83 c4 04             	add    $0x4,%esp
f0101507:	ff 75 d4             	pushl  -0x2c(%ebp)
f010150a:	e8 87 f8 ff ff       	call   f0100d96 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010150f:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101514:	83 c4 10             	add    $0x10,%esp
f0101517:	eb 05                	jmp    f010151e <mem_init+0x530>
		--nfree;
f0101519:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151c:	8b 00                	mov    (%eax),%eax
f010151e:	85 c0                	test   %eax,%eax
f0101520:	75 f7                	jne    f0101519 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101522:	85 db                	test   %ebx,%ebx
f0101524:	74 19                	je     f010153f <mem_init+0x551>
f0101526:	68 cf 3d 10 f0       	push   $0xf0103dcf
f010152b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101530:	68 a1 02 00 00       	push   $0x2a1
f0101535:	68 54 3c 10 f0       	push   $0xf0103c54
f010153a:	e8 4c eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010153f:	83 ec 0c             	sub    $0xc,%esp
f0101542:	68 d0 40 10 f0       	push   $0xf01040d0
f0101547:	e8 9b 11 00 00       	call   f01026e7 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101553:	e8 ce f7 ff ff       	call   f0100d26 <page_alloc>
f0101558:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010155b:	83 c4 10             	add    $0x10,%esp
f010155e:	85 c0                	test   %eax,%eax
f0101560:	75 19                	jne    f010157b <mem_init+0x58d>
f0101562:	68 34 3d 10 f0       	push   $0xf0103d34
f0101567:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010156c:	68 fc 02 00 00       	push   $0x2fc
f0101571:	68 54 3c 10 f0       	push   $0xf0103c54
f0101576:	e8 10 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010157b:	83 ec 0c             	sub    $0xc,%esp
f010157e:	6a 00                	push   $0x0
f0101580:	e8 a1 f7 ff ff       	call   f0100d26 <page_alloc>
f0101585:	89 c3                	mov    %eax,%ebx
f0101587:	83 c4 10             	add    $0x10,%esp
f010158a:	85 c0                	test   %eax,%eax
f010158c:	75 19                	jne    f01015a7 <mem_init+0x5b9>
f010158e:	68 4a 3d 10 f0       	push   $0xf0103d4a
f0101593:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101598:	68 fd 02 00 00       	push   $0x2fd
f010159d:	68 54 3c 10 f0       	push   $0xf0103c54
f01015a2:	e8 e4 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	6a 00                	push   $0x0
f01015ac:	e8 75 f7 ff ff       	call   f0100d26 <page_alloc>
f01015b1:	89 c6                	mov    %eax,%esi
f01015b3:	83 c4 10             	add    $0x10,%esp
f01015b6:	85 c0                	test   %eax,%eax
f01015b8:	75 19                	jne    f01015d3 <mem_init+0x5e5>
f01015ba:	68 60 3d 10 f0       	push   $0xf0103d60
f01015bf:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01015c4:	68 fe 02 00 00       	push   $0x2fe
f01015c9:	68 54 3c 10 f0       	push   $0xf0103c54
f01015ce:	e8 b8 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d3:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015d6:	75 19                	jne    f01015f1 <mem_init+0x603>
f01015d8:	68 76 3d 10 f0       	push   $0xf0103d76
f01015dd:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01015e2:	68 01 03 00 00       	push   $0x301
f01015e7:	68 54 3c 10 f0       	push   $0xf0103c54
f01015ec:	e8 9a ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f1:	39 c3                	cmp    %eax,%ebx
f01015f3:	74 05                	je     f01015fa <mem_init+0x60c>
f01015f5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015f8:	75 19                	jne    f0101613 <mem_init+0x625>
f01015fa:	68 50 40 10 f0       	push   $0xf0104050
f01015ff:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101604:	68 02 03 00 00       	push   $0x302
f0101609:	68 54 3c 10 f0       	push   $0xf0103c54
f010160e:	e8 78 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101613:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101618:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010161b:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101622:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 f7 f6 ff ff       	call   f0100d26 <page_alloc>
f010162f:	83 c4 10             	add    $0x10,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	74 19                	je     f010164f <mem_init+0x661>
f0101636:	68 88 3d 10 f0       	push   $0xf0103d88
f010163b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101640:	68 09 03 00 00       	push   $0x309
f0101645:	68 54 3c 10 f0       	push   $0xf0103c54
f010164a:	e8 3c ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f010164f:	83 ec 04             	sub    $0x4,%esp
f0101652:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101655:	50                   	push   %eax
f0101656:	6a 00                	push   $0x0
f0101658:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010165e:	e8 89 f8 ff ff       	call   f0100eec <page_lookup>
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	85 c0                	test   %eax,%eax
f0101668:	74 19                	je     f0101683 <mem_init+0x695>
f010166a:	68 f0 40 10 f0       	push   $0xf01040f0
f010166f:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101674:	68 0c 03 00 00       	push   $0x30c
f0101679:	68 54 3c 10 f0       	push   $0xf0103c54
f010167e:	e8 08 ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101683:	6a 02                	push   $0x2
f0101685:	6a 00                	push   $0x0
f0101687:	53                   	push   %ebx
f0101688:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010168e:	e8 f5 f8 ff ff       	call   f0100f88 <page_insert>
f0101693:	83 c4 10             	add    $0x10,%esp
f0101696:	85 c0                	test   %eax,%eax
f0101698:	78 19                	js     f01016b3 <mem_init+0x6c5>
f010169a:	68 24 41 10 f0       	push   $0xf0104124
f010169f:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01016a4:	68 0f 03 00 00       	push   $0x30f
f01016a9:	68 54 3c 10 f0       	push   $0xf0103c54
f01016ae:	e8 d8 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016b3:	83 ec 0c             	sub    $0xc,%esp
f01016b6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016b9:	e8 d8 f6 ff ff       	call   f0100d96 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016be:	6a 02                	push   $0x2
f01016c0:	6a 00                	push   $0x0
f01016c2:	53                   	push   %ebx
f01016c3:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016c9:	e8 ba f8 ff ff       	call   f0100f88 <page_insert>
f01016ce:	83 c4 20             	add    $0x20,%esp
f01016d1:	85 c0                	test   %eax,%eax
f01016d3:	74 19                	je     f01016ee <mem_init+0x700>
f01016d5:	68 54 41 10 f0       	push   $0xf0104154
f01016da:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01016df:	68 13 03 00 00       	push   $0x313
f01016e4:	68 54 3c 10 f0       	push   $0xf0103c54
f01016e9:	e8 9d e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016ee:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01016f4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01016f9:	89 c1                	mov    %eax,%ecx
f01016fb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016fe:	8b 17                	mov    (%edi),%edx
f0101700:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101706:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101709:	29 c8                	sub    %ecx,%eax
f010170b:	c1 f8 03             	sar    $0x3,%eax
f010170e:	c1 e0 0c             	shl    $0xc,%eax
f0101711:	39 c2                	cmp    %eax,%edx
f0101713:	74 19                	je     f010172e <mem_init+0x740>
f0101715:	68 84 41 10 f0       	push   $0xf0104184
f010171a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010171f:	68 14 03 00 00       	push   $0x314
f0101724:	68 54 3c 10 f0       	push   $0xf0103c54
f0101729:	e8 5d e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010172e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101733:	89 f8                	mov    %edi,%eax
f0101735:	e8 1c f2 ff ff       	call   f0100956 <check_va2pa>
f010173a:	89 da                	mov    %ebx,%edx
f010173c:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010173f:	c1 fa 03             	sar    $0x3,%edx
f0101742:	c1 e2 0c             	shl    $0xc,%edx
f0101745:	39 d0                	cmp    %edx,%eax
f0101747:	74 19                	je     f0101762 <mem_init+0x774>
f0101749:	68 ac 41 10 f0       	push   $0xf01041ac
f010174e:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101753:	68 15 03 00 00       	push   $0x315
f0101758:	68 54 3c 10 f0       	push   $0xf0103c54
f010175d:	e8 29 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101762:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101767:	74 19                	je     f0101782 <mem_init+0x794>
f0101769:	68 da 3d 10 f0       	push   $0xf0103dda
f010176e:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101773:	68 16 03 00 00       	push   $0x316
f0101778:	68 54 3c 10 f0       	push   $0xf0103c54
f010177d:	e8 09 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101782:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101785:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010178a:	74 19                	je     f01017a5 <mem_init+0x7b7>
f010178c:	68 eb 3d 10 f0       	push   $0xf0103deb
f0101791:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101796:	68 17 03 00 00       	push   $0x317
f010179b:	68 54 3c 10 f0       	push   $0xf0103c54
f01017a0:	e8 e6 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01017a5:	6a 02                	push   $0x2
f01017a7:	68 00 10 00 00       	push   $0x1000
f01017ac:	56                   	push   %esi
f01017ad:	57                   	push   %edi
f01017ae:	e8 d5 f7 ff ff       	call   f0100f88 <page_insert>
f01017b3:	83 c4 10             	add    $0x10,%esp
f01017b6:	85 c0                	test   %eax,%eax
f01017b8:	74 19                	je     f01017d3 <mem_init+0x7e5>
f01017ba:	68 dc 41 10 f0       	push   $0xf01041dc
f01017bf:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01017c4:	68 1a 03 00 00       	push   $0x31a
f01017c9:	68 54 3c 10 f0       	push   $0xf0103c54
f01017ce:	e8 b8 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017d3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017d8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01017dd:	e8 74 f1 ff ff       	call   f0100956 <check_va2pa>
f01017e2:	89 f2                	mov    %esi,%edx
f01017e4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01017ea:	c1 fa 03             	sar    $0x3,%edx
f01017ed:	c1 e2 0c             	shl    $0xc,%edx
f01017f0:	39 d0                	cmp    %edx,%eax
f01017f2:	74 19                	je     f010180d <mem_init+0x81f>
f01017f4:	68 18 42 10 f0       	push   $0xf0104218
f01017f9:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01017fe:	68 1b 03 00 00       	push   $0x31b
f0101803:	68 54 3c 10 f0       	push   $0xf0103c54
f0101808:	e8 7e e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010180d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101812:	74 19                	je     f010182d <mem_init+0x83f>
f0101814:	68 fc 3d 10 f0       	push   $0xf0103dfc
f0101819:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010181e:	68 1c 03 00 00       	push   $0x31c
f0101823:	68 54 3c 10 f0       	push   $0xf0103c54
f0101828:	e8 5e e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010182d:	83 ec 0c             	sub    $0xc,%esp
f0101830:	6a 00                	push   $0x0
f0101832:	e8 ef f4 ff ff       	call   f0100d26 <page_alloc>
f0101837:	83 c4 10             	add    $0x10,%esp
f010183a:	85 c0                	test   %eax,%eax
f010183c:	74 19                	je     f0101857 <mem_init+0x869>
f010183e:	68 88 3d 10 f0       	push   $0xf0103d88
f0101843:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101848:	68 1f 03 00 00       	push   $0x31f
f010184d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101852:	e8 34 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101857:	6a 02                	push   $0x2
f0101859:	68 00 10 00 00       	push   $0x1000
f010185e:	56                   	push   %esi
f010185f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101865:	e8 1e f7 ff ff       	call   f0100f88 <page_insert>
f010186a:	83 c4 10             	add    $0x10,%esp
f010186d:	85 c0                	test   %eax,%eax
f010186f:	74 19                	je     f010188a <mem_init+0x89c>
f0101871:	68 dc 41 10 f0       	push   $0xf01041dc
f0101876:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010187b:	68 22 03 00 00       	push   $0x322
f0101880:	68 54 3c 10 f0       	push   $0xf0103c54
f0101885:	e8 01 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010188a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010188f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101894:	e8 bd f0 ff ff       	call   f0100956 <check_va2pa>
f0101899:	89 f2                	mov    %esi,%edx
f010189b:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01018a1:	c1 fa 03             	sar    $0x3,%edx
f01018a4:	c1 e2 0c             	shl    $0xc,%edx
f01018a7:	39 d0                	cmp    %edx,%eax
f01018a9:	74 19                	je     f01018c4 <mem_init+0x8d6>
f01018ab:	68 18 42 10 f0       	push   $0xf0104218
f01018b0:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01018b5:	68 23 03 00 00       	push   $0x323
f01018ba:	68 54 3c 10 f0       	push   $0xf0103c54
f01018bf:	e8 c7 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018c4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018c9:	74 19                	je     f01018e4 <mem_init+0x8f6>
f01018cb:	68 fc 3d 10 f0       	push   $0xf0103dfc
f01018d0:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01018d5:	68 24 03 00 00       	push   $0x324
f01018da:	68 54 3c 10 f0       	push   $0xf0103c54
f01018df:	e8 a7 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018e4:	83 ec 0c             	sub    $0xc,%esp
f01018e7:	6a 00                	push   $0x0
f01018e9:	e8 38 f4 ff ff       	call   f0100d26 <page_alloc>
f01018ee:	83 c4 10             	add    $0x10,%esp
f01018f1:	85 c0                	test   %eax,%eax
f01018f3:	74 19                	je     f010190e <mem_init+0x920>
f01018f5:	68 88 3d 10 f0       	push   $0xf0103d88
f01018fa:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01018ff:	68 28 03 00 00       	push   $0x328
f0101904:	68 54 3c 10 f0       	push   $0xf0103c54
f0101909:	e8 7d e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010190e:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101914:	8b 02                	mov    (%edx),%eax
f0101916:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010191b:	89 c1                	mov    %eax,%ecx
f010191d:	c1 e9 0c             	shr    $0xc,%ecx
f0101920:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101926:	72 15                	jb     f010193d <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101928:	50                   	push   %eax
f0101929:	68 f0 3e 10 f0       	push   $0xf0103ef0
f010192e:	68 2b 03 00 00       	push   $0x32b
f0101933:	68 54 3c 10 f0       	push   $0xf0103c54
f0101938:	e8 4e e7 ff ff       	call   f010008b <_panic>
f010193d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101942:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101945:	83 ec 04             	sub    $0x4,%esp
f0101948:	6a 00                	push   $0x0
f010194a:	68 00 10 00 00       	push   $0x1000
f010194f:	52                   	push   %edx
f0101950:	e8 a3 f4 ff ff       	call   f0100df8 <pgdir_walk>
f0101955:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101958:	8d 51 04             	lea    0x4(%ecx),%edx
f010195b:	83 c4 10             	add    $0x10,%esp
f010195e:	39 d0                	cmp    %edx,%eax
f0101960:	74 19                	je     f010197b <mem_init+0x98d>
f0101962:	68 48 42 10 f0       	push   $0xf0104248
f0101967:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010196c:	68 2c 03 00 00       	push   $0x32c
f0101971:	68 54 3c 10 f0       	push   $0xf0103c54
f0101976:	e8 10 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f010197b:	6a 06                	push   $0x6
f010197d:	68 00 10 00 00       	push   $0x1000
f0101982:	56                   	push   %esi
f0101983:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101989:	e8 fa f5 ff ff       	call   f0100f88 <page_insert>
f010198e:	83 c4 10             	add    $0x10,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	74 19                	je     f01019ae <mem_init+0x9c0>
f0101995:	68 88 42 10 f0       	push   $0xf0104288
f010199a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010199f:	68 2f 03 00 00       	push   $0x32f
f01019a4:	68 54 3c 10 f0       	push   $0xf0103c54
f01019a9:	e8 dd e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019ae:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01019b4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019b9:	89 f8                	mov    %edi,%eax
f01019bb:	e8 96 ef ff ff       	call   f0100956 <check_va2pa>
f01019c0:	89 f2                	mov    %esi,%edx
f01019c2:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019c8:	c1 fa 03             	sar    $0x3,%edx
f01019cb:	c1 e2 0c             	shl    $0xc,%edx
f01019ce:	39 d0                	cmp    %edx,%eax
f01019d0:	74 19                	je     f01019eb <mem_init+0x9fd>
f01019d2:	68 18 42 10 f0       	push   $0xf0104218
f01019d7:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01019dc:	68 30 03 00 00       	push   $0x330
f01019e1:	68 54 3c 10 f0       	push   $0xf0103c54
f01019e6:	e8 a0 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019eb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019f0:	74 19                	je     f0101a0b <mem_init+0xa1d>
f01019f2:	68 fc 3d 10 f0       	push   $0xf0103dfc
f01019f7:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01019fc:	68 31 03 00 00       	push   $0x331
f0101a01:	68 54 3c 10 f0       	push   $0xf0103c54
f0101a06:	e8 80 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101a0b:	83 ec 04             	sub    $0x4,%esp
f0101a0e:	6a 00                	push   $0x0
f0101a10:	68 00 10 00 00       	push   $0x1000
f0101a15:	57                   	push   %edi
f0101a16:	e8 dd f3 ff ff       	call   f0100df8 <pgdir_walk>
f0101a1b:	83 c4 10             	add    $0x10,%esp
f0101a1e:	f6 00 04             	testb  $0x4,(%eax)
f0101a21:	75 19                	jne    f0101a3c <mem_init+0xa4e>
f0101a23:	68 cc 42 10 f0       	push   $0xf01042cc
f0101a28:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101a2d:	68 32 03 00 00       	push   $0x332
f0101a32:	68 54 3c 10 f0       	push   $0xf0103c54
f0101a37:	e8 4f e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a3c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a41:	f6 00 04             	testb  $0x4,(%eax)
f0101a44:	75 19                	jne    f0101a5f <mem_init+0xa71>
f0101a46:	68 0d 3e 10 f0       	push   $0xf0103e0d
f0101a4b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101a50:	68 33 03 00 00       	push   $0x333
f0101a55:	68 54 3c 10 f0       	push   $0xf0103c54
f0101a5a:	e8 2c e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101a5f:	6a 02                	push   $0x2
f0101a61:	68 00 10 00 00       	push   $0x1000
f0101a66:	56                   	push   %esi
f0101a67:	50                   	push   %eax
f0101a68:	e8 1b f5 ff ff       	call   f0100f88 <page_insert>
f0101a6d:	83 c4 10             	add    $0x10,%esp
f0101a70:	85 c0                	test   %eax,%eax
f0101a72:	74 19                	je     f0101a8d <mem_init+0xa9f>
f0101a74:	68 dc 41 10 f0       	push   $0xf01041dc
f0101a79:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101a7e:	68 36 03 00 00       	push   $0x336
f0101a83:	68 54 3c 10 f0       	push   $0xf0103c54
f0101a88:	e8 fe e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101a8d:	83 ec 04             	sub    $0x4,%esp
f0101a90:	6a 00                	push   $0x0
f0101a92:	68 00 10 00 00       	push   $0x1000
f0101a97:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a9d:	e8 56 f3 ff ff       	call   f0100df8 <pgdir_walk>
f0101aa2:	83 c4 10             	add    $0x10,%esp
f0101aa5:	f6 00 02             	testb  $0x2,(%eax)
f0101aa8:	75 19                	jne    f0101ac3 <mem_init+0xad5>
f0101aaa:	68 00 43 10 f0       	push   $0xf0104300
f0101aaf:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101ab4:	68 37 03 00 00       	push   $0x337
f0101ab9:	68 54 3c 10 f0       	push   $0xf0103c54
f0101abe:	e8 c8 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101ac3:	83 ec 04             	sub    $0x4,%esp
f0101ac6:	6a 00                	push   $0x0
f0101ac8:	68 00 10 00 00       	push   $0x1000
f0101acd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ad3:	e8 20 f3 ff ff       	call   f0100df8 <pgdir_walk>
f0101ad8:	83 c4 10             	add    $0x10,%esp
f0101adb:	f6 00 04             	testb  $0x4,(%eax)
f0101ade:	74 19                	je     f0101af9 <mem_init+0xb0b>
f0101ae0:	68 34 43 10 f0       	push   $0xf0104334
f0101ae5:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101aea:	68 38 03 00 00       	push   $0x338
f0101aef:	68 54 3c 10 f0       	push   $0xf0103c54
f0101af4:	e8 92 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101af9:	6a 02                	push   $0x2
f0101afb:	68 00 00 40 00       	push   $0x400000
f0101b00:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b03:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b09:	e8 7a f4 ff ff       	call   f0100f88 <page_insert>
f0101b0e:	83 c4 10             	add    $0x10,%esp
f0101b11:	85 c0                	test   %eax,%eax
f0101b13:	78 19                	js     f0101b2e <mem_init+0xb40>
f0101b15:	68 6c 43 10 f0       	push   $0xf010436c
f0101b1a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101b1f:	68 3b 03 00 00       	push   $0x33b
f0101b24:	68 54 3c 10 f0       	push   $0xf0103c54
f0101b29:	e8 5d e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101b2e:	6a 02                	push   $0x2
f0101b30:	68 00 10 00 00       	push   $0x1000
f0101b35:	53                   	push   %ebx
f0101b36:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b3c:	e8 47 f4 ff ff       	call   f0100f88 <page_insert>
f0101b41:	83 c4 10             	add    $0x10,%esp
f0101b44:	85 c0                	test   %eax,%eax
f0101b46:	74 19                	je     f0101b61 <mem_init+0xb73>
f0101b48:	68 a4 43 10 f0       	push   $0xf01043a4
f0101b4d:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101b52:	68 3e 03 00 00       	push   $0x33e
f0101b57:	68 54 3c 10 f0       	push   $0xf0103c54
f0101b5c:	e8 2a e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101b61:	83 ec 04             	sub    $0x4,%esp
f0101b64:	6a 00                	push   $0x0
f0101b66:	68 00 10 00 00       	push   $0x1000
f0101b6b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b71:	e8 82 f2 ff ff       	call   f0100df8 <pgdir_walk>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	f6 00 04             	testb  $0x4,(%eax)
f0101b7c:	74 19                	je     f0101b97 <mem_init+0xba9>
f0101b7e:	68 34 43 10 f0       	push   $0xf0104334
f0101b83:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101b88:	68 3f 03 00 00       	push   $0x33f
f0101b8d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101b92:	e8 f4 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b97:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101b9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ba2:	89 f8                	mov    %edi,%eax
f0101ba4:	e8 ad ed ff ff       	call   f0100956 <check_va2pa>
f0101ba9:	89 c1                	mov    %eax,%ecx
f0101bab:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bae:	89 d8                	mov    %ebx,%eax
f0101bb0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101bb6:	c1 f8 03             	sar    $0x3,%eax
f0101bb9:	c1 e0 0c             	shl    $0xc,%eax
f0101bbc:	39 c1                	cmp    %eax,%ecx
f0101bbe:	74 19                	je     f0101bd9 <mem_init+0xbeb>
f0101bc0:	68 e0 43 10 f0       	push   $0xf01043e0
f0101bc5:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101bca:	68 42 03 00 00       	push   $0x342
f0101bcf:	68 54 3c 10 f0       	push   $0xf0103c54
f0101bd4:	e8 b2 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bd9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bde:	89 f8                	mov    %edi,%eax
f0101be0:	e8 71 ed ff ff       	call   f0100956 <check_va2pa>
f0101be5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101be8:	74 19                	je     f0101c03 <mem_init+0xc15>
f0101bea:	68 0c 44 10 f0       	push   $0xf010440c
f0101bef:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101bf4:	68 43 03 00 00       	push   $0x343
f0101bf9:	68 54 3c 10 f0       	push   $0xf0103c54
f0101bfe:	e8 88 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c03:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c08:	74 19                	je     f0101c23 <mem_init+0xc35>
f0101c0a:	68 23 3e 10 f0       	push   $0xf0103e23
f0101c0f:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101c14:	68 45 03 00 00       	push   $0x345
f0101c19:	68 54 3c 10 f0       	push   $0xf0103c54
f0101c1e:	e8 68 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c23:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c28:	74 19                	je     f0101c43 <mem_init+0xc55>
f0101c2a:	68 34 3e 10 f0       	push   $0xf0103e34
f0101c2f:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101c34:	68 46 03 00 00       	push   $0x346
f0101c39:	68 54 3c 10 f0       	push   $0xf0103c54
f0101c3e:	e8 48 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c43:	83 ec 0c             	sub    $0xc,%esp
f0101c46:	6a 00                	push   $0x0
f0101c48:	e8 d9 f0 ff ff       	call   f0100d26 <page_alloc>
f0101c4d:	83 c4 10             	add    $0x10,%esp
f0101c50:	85 c0                	test   %eax,%eax
f0101c52:	74 04                	je     f0101c58 <mem_init+0xc6a>
f0101c54:	39 c6                	cmp    %eax,%esi
f0101c56:	74 19                	je     f0101c71 <mem_init+0xc83>
f0101c58:	68 3c 44 10 f0       	push   $0xf010443c
f0101c5d:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101c62:	68 49 03 00 00       	push   $0x349
f0101c67:	68 54 3c 10 f0       	push   $0xf0103c54
f0101c6c:	e8 1a e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c71:	83 ec 08             	sub    $0x8,%esp
f0101c74:	6a 00                	push   $0x0
f0101c76:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c7c:	e8 c5 f2 ff ff       	call   f0100f46 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c81:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c87:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c8c:	89 f8                	mov    %edi,%eax
f0101c8e:	e8 c3 ec ff ff       	call   f0100956 <check_va2pa>
f0101c93:	83 c4 10             	add    $0x10,%esp
f0101c96:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c99:	74 19                	je     f0101cb4 <mem_init+0xcc6>
f0101c9b:	68 60 44 10 f0       	push   $0xf0104460
f0101ca0:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101ca5:	68 4d 03 00 00       	push   $0x34d
f0101caa:	68 54 3c 10 f0       	push   $0xf0103c54
f0101caf:	e8 d7 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cb9:	89 f8                	mov    %edi,%eax
f0101cbb:	e8 96 ec ff ff       	call   f0100956 <check_va2pa>
f0101cc0:	89 da                	mov    %ebx,%edx
f0101cc2:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101cc8:	c1 fa 03             	sar    $0x3,%edx
f0101ccb:	c1 e2 0c             	shl    $0xc,%edx
f0101cce:	39 d0                	cmp    %edx,%eax
f0101cd0:	74 19                	je     f0101ceb <mem_init+0xcfd>
f0101cd2:	68 0c 44 10 f0       	push   $0xf010440c
f0101cd7:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101cdc:	68 4e 03 00 00       	push   $0x34e
f0101ce1:	68 54 3c 10 f0       	push   $0xf0103c54
f0101ce6:	e8 a0 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ceb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cf0:	74 19                	je     f0101d0b <mem_init+0xd1d>
f0101cf2:	68 da 3d 10 f0       	push   $0xf0103dda
f0101cf7:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101cfc:	68 4f 03 00 00       	push   $0x34f
f0101d01:	68 54 3c 10 f0       	push   $0xf0103c54
f0101d06:	e8 80 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d0b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d10:	74 19                	je     f0101d2b <mem_init+0xd3d>
f0101d12:	68 34 3e 10 f0       	push   $0xf0103e34
f0101d17:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101d1c:	68 50 03 00 00       	push   $0x350
f0101d21:	68 54 3c 10 f0       	push   $0xf0103c54
f0101d26:	e8 60 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101d2b:	6a 00                	push   $0x0
f0101d2d:	68 00 10 00 00       	push   $0x1000
f0101d32:	53                   	push   %ebx
f0101d33:	57                   	push   %edi
f0101d34:	e8 4f f2 ff ff       	call   f0100f88 <page_insert>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	85 c0                	test   %eax,%eax
f0101d3e:	74 19                	je     f0101d59 <mem_init+0xd6b>
f0101d40:	68 84 44 10 f0       	push   $0xf0104484
f0101d45:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101d4a:	68 53 03 00 00       	push   $0x353
f0101d4f:	68 54 3c 10 f0       	push   $0xf0103c54
f0101d54:	e8 32 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d59:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d5e:	75 19                	jne    f0101d79 <mem_init+0xd8b>
f0101d60:	68 45 3e 10 f0       	push   $0xf0103e45
f0101d65:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101d6a:	68 54 03 00 00       	push   $0x354
f0101d6f:	68 54 3c 10 f0       	push   $0xf0103c54
f0101d74:	e8 12 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d79:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d7c:	74 19                	je     f0101d97 <mem_init+0xda9>
f0101d7e:	68 51 3e 10 f0       	push   $0xf0103e51
f0101d83:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101d88:	68 55 03 00 00       	push   $0x355
f0101d8d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101d92:	e8 f4 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101d97:	83 ec 08             	sub    $0x8,%esp
f0101d9a:	68 00 10 00 00       	push   $0x1000
f0101d9f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101da5:	e8 9c f1 ff ff       	call   f0100f46 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101daa:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101db0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101db5:	89 f8                	mov    %edi,%eax
f0101db7:	e8 9a eb ff ff       	call   f0100956 <check_va2pa>
f0101dbc:	83 c4 10             	add    $0x10,%esp
f0101dbf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dc2:	74 19                	je     f0101ddd <mem_init+0xdef>
f0101dc4:	68 60 44 10 f0       	push   $0xf0104460
f0101dc9:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101dce:	68 59 03 00 00       	push   $0x359
f0101dd3:	68 54 3c 10 f0       	push   $0xf0103c54
f0101dd8:	e8 ae e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ddd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101de2:	89 f8                	mov    %edi,%eax
f0101de4:	e8 6d eb ff ff       	call   f0100956 <check_va2pa>
f0101de9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dec:	74 19                	je     f0101e07 <mem_init+0xe19>
f0101dee:	68 bc 44 10 f0       	push   $0xf01044bc
f0101df3:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101df8:	68 5a 03 00 00       	push   $0x35a
f0101dfd:	68 54 3c 10 f0       	push   $0xf0103c54
f0101e02:	e8 84 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e07:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e0c:	74 19                	je     f0101e27 <mem_init+0xe39>
f0101e0e:	68 66 3e 10 f0       	push   $0xf0103e66
f0101e13:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101e18:	68 5b 03 00 00       	push   $0x35b
f0101e1d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101e22:	e8 64 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e27:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e2c:	74 19                	je     f0101e47 <mem_init+0xe59>
f0101e2e:	68 34 3e 10 f0       	push   $0xf0103e34
f0101e33:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101e38:	68 5c 03 00 00       	push   $0x35c
f0101e3d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101e42:	e8 44 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e47:	83 ec 0c             	sub    $0xc,%esp
f0101e4a:	6a 00                	push   $0x0
f0101e4c:	e8 d5 ee ff ff       	call   f0100d26 <page_alloc>
f0101e51:	83 c4 10             	add    $0x10,%esp
f0101e54:	39 c3                	cmp    %eax,%ebx
f0101e56:	75 04                	jne    f0101e5c <mem_init+0xe6e>
f0101e58:	85 c0                	test   %eax,%eax
f0101e5a:	75 19                	jne    f0101e75 <mem_init+0xe87>
f0101e5c:	68 e4 44 10 f0       	push   $0xf01044e4
f0101e61:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101e66:	68 5f 03 00 00       	push   $0x35f
f0101e6b:	68 54 3c 10 f0       	push   $0xf0103c54
f0101e70:	e8 16 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e75:	83 ec 0c             	sub    $0xc,%esp
f0101e78:	6a 00                	push   $0x0
f0101e7a:	e8 a7 ee ff ff       	call   f0100d26 <page_alloc>
f0101e7f:	83 c4 10             	add    $0x10,%esp
f0101e82:	85 c0                	test   %eax,%eax
f0101e84:	74 19                	je     f0101e9f <mem_init+0xeb1>
f0101e86:	68 88 3d 10 f0       	push   $0xf0103d88
f0101e8b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101e90:	68 62 03 00 00       	push   $0x362
f0101e95:	68 54 3c 10 f0       	push   $0xf0103c54
f0101e9a:	e8 ec e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e9f:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101ea5:	8b 11                	mov    (%ecx),%edx
f0101ea7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ead:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101eb6:	c1 f8 03             	sar    $0x3,%eax
f0101eb9:	c1 e0 0c             	shl    $0xc,%eax
f0101ebc:	39 c2                	cmp    %eax,%edx
f0101ebe:	74 19                	je     f0101ed9 <mem_init+0xeeb>
f0101ec0:	68 84 41 10 f0       	push   $0xf0104184
f0101ec5:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101eca:	68 65 03 00 00       	push   $0x365
f0101ecf:	68 54 3c 10 f0       	push   $0xf0103c54
f0101ed4:	e8 b2 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ed9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101edf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ee7:	74 19                	je     f0101f02 <mem_init+0xf14>
f0101ee9:	68 eb 3d 10 f0       	push   $0xf0103deb
f0101eee:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101ef3:	68 67 03 00 00       	push   $0x367
f0101ef8:	68 54 3c 10 f0       	push   $0xf0103c54
f0101efd:	e8 89 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f05:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f0b:	83 ec 0c             	sub    $0xc,%esp
f0101f0e:	50                   	push   %eax
f0101f0f:	e8 82 ee ff ff       	call   f0100d96 <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f14:	83 c4 0c             	add    $0xc,%esp
f0101f17:	6a 01                	push   $0x1
f0101f19:	68 00 10 40 00       	push   $0x401000
f0101f1e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101f24:	e8 cf ee ff ff       	call   f0100df8 <pgdir_walk>
f0101f29:	89 c7                	mov    %eax,%edi
f0101f2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f2e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f33:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f36:	8b 40 04             	mov    0x4(%eax),%eax
f0101f39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f3e:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101f44:	89 c2                	mov    %eax,%edx
f0101f46:	c1 ea 0c             	shr    $0xc,%edx
f0101f49:	83 c4 10             	add    $0x10,%esp
f0101f4c:	39 ca                	cmp    %ecx,%edx
f0101f4e:	72 15                	jb     f0101f65 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f50:	50                   	push   %eax
f0101f51:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101f56:	68 6e 03 00 00       	push   $0x36e
f0101f5b:	68 54 3c 10 f0       	push   $0xf0103c54
f0101f60:	e8 26 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f65:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f6a:	39 c7                	cmp    %eax,%edi
f0101f6c:	74 19                	je     f0101f87 <mem_init+0xf99>
f0101f6e:	68 77 3e 10 f0       	push   $0xf0103e77
f0101f73:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0101f78:	68 6f 03 00 00       	push   $0x36f
f0101f7d:	68 54 3c 10 f0       	push   $0xf0103c54
f0101f82:	e8 04 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f87:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f8a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f94:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101f9a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101fa0:	c1 f8 03             	sar    $0x3,%eax
f0101fa3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fa6:	89 c2                	mov    %eax,%edx
f0101fa8:	c1 ea 0c             	shr    $0xc,%edx
f0101fab:	39 d1                	cmp    %edx,%ecx
f0101fad:	77 12                	ja     f0101fc1 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101faf:	50                   	push   %eax
f0101fb0:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101fb5:	6a 57                	push   $0x57
f0101fb7:	68 60 3c 10 f0       	push   $0xf0103c60
f0101fbc:	e8 ca e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fc1:	83 ec 04             	sub    $0x4,%esp
f0101fc4:	68 00 10 00 00       	push   $0x1000
f0101fc9:	68 ff 00 00 00       	push   $0xff
f0101fce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fd3:	50                   	push   %eax
f0101fd4:	e8 77 12 00 00       	call   f0103250 <memset>
	page_free(pp0);
f0101fd9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fdc:	89 3c 24             	mov    %edi,(%esp)
f0101fdf:	e8 b2 ed ff ff       	call   f0100d96 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fe4:	83 c4 0c             	add    $0xc,%esp
f0101fe7:	6a 01                	push   $0x1
f0101fe9:	6a 00                	push   $0x0
f0101feb:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ff1:	e8 02 ee ff ff       	call   f0100df8 <pgdir_walk>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101ff6:	89 fa                	mov    %edi,%edx
f0101ff8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101ffe:	c1 fa 03             	sar    $0x3,%edx
f0102001:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102004:	89 d0                	mov    %edx,%eax
f0102006:	c1 e8 0c             	shr    $0xc,%eax
f0102009:	83 c4 10             	add    $0x10,%esp
f010200c:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102012:	72 12                	jb     f0102026 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102014:	52                   	push   %edx
f0102015:	68 f0 3e 10 f0       	push   $0xf0103ef0
f010201a:	6a 57                	push   $0x57
f010201c:	68 60 3c 10 f0       	push   $0xf0103c60
f0102021:	e8 65 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102026:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f010202c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010202f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102035:	f6 00 01             	testb  $0x1,(%eax)
f0102038:	74 19                	je     f0102053 <mem_init+0x1065>
f010203a:	68 8f 3e 10 f0       	push   $0xf0103e8f
f010203f:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102044:	68 79 03 00 00       	push   $0x379
f0102049:	68 54 3c 10 f0       	push   $0xf0103c54
f010204e:	e8 38 e0 ff ff       	call   f010008b <_panic>
f0102053:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f0102056:	39 d0                	cmp    %edx,%eax
f0102058:	75 db                	jne    f0102035 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010205a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010205f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102065:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102068:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010206e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102071:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102077:	83 ec 0c             	sub    $0xc,%esp
f010207a:	50                   	push   %eax
f010207b:	e8 16 ed ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f0102080:	89 1c 24             	mov    %ebx,(%esp)
f0102083:	e8 0e ed ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f0102088:	89 34 24             	mov    %esi,(%esp)
f010208b:	e8 06 ed ff ff       	call   f0100d96 <page_free>

	cprintf("check_page() succeeded!\n");
f0102090:	c7 04 24 a6 3e 10 f0 	movl   $0xf0103ea6,(%esp)
f0102097:	e8 4b 06 00 00       	call   f01026e7 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	// 映射 upages,upages+ptsize 到pages，pages+ptsize上
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f010209c:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020a1:	83 c4 10             	add    $0x10,%esp
f01020a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020a9:	77 15                	ja     f01020c0 <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ab:	50                   	push   %eax
f01020ac:	68 d0 3f 10 f0       	push   $0xf0103fd0
f01020b1:	68 b5 00 00 00       	push   $0xb5
f01020b6:	68 54 3c 10 f0       	push   $0xf0103c54
f01020bb:	e8 cb df ff ff       	call   f010008b <_panic>
f01020c0:	83 ec 08             	sub    $0x8,%esp
f01020c3:	6a 04                	push   $0x4
f01020c5:	05 00 00 00 10       	add    $0x10000000,%eax
f01020ca:	50                   	push   %eax
f01020cb:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020d0:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020d5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020da:	e8 ad ed ff ff       	call   f0100e8c <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020df:	83 c4 10             	add    $0x10,%esp
f01020e2:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01020e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020ec:	77 15                	ja     f0102103 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ee:	50                   	push   %eax
f01020ef:	68 d0 3f 10 f0       	push   $0xf0103fd0
f01020f4:	68 c2 00 00 00       	push   $0xc2
f01020f9:	68 54 3c 10 f0       	push   $0xf0103c54
f01020fe:	e8 88 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102103:	83 ec 08             	sub    $0x8,%esp
f0102106:	6a 02                	push   $0x2
f0102108:	68 00 d0 10 00       	push   $0x10d000
f010210d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102112:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102117:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010211c:	e8 6b ed ff ff       	call   f0100e8c <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0,PTE_W);
f0102121:	83 c4 08             	add    $0x8,%esp
f0102124:	6a 02                	push   $0x2
f0102126:	6a 00                	push   $0x0
f0102128:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010212d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102132:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102137:	e8 50 ed ff ff       	call   f0100e8c <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010213c:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f0102142:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102147:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010214a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102151:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102156:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102159:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010215f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102162:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102165:	bb 00 00 00 00       	mov    $0x0,%ebx
f010216a:	eb 55                	jmp    f01021c1 <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010216c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102172:	89 f0                	mov    %esi,%eax
f0102174:	e8 dd e7 ff ff       	call   f0100956 <check_va2pa>
f0102179:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102180:	77 15                	ja     f0102197 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102182:	57                   	push   %edi
f0102183:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0102188:	68 b9 02 00 00       	push   $0x2b9
f010218d:	68 54 3c 10 f0       	push   $0xf0103c54
f0102192:	e8 f4 de ff ff       	call   f010008b <_panic>
f0102197:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010219e:	39 c2                	cmp    %eax,%edx
f01021a0:	74 19                	je     f01021bb <mem_init+0x11cd>
f01021a2:	68 08 45 10 f0       	push   $0xf0104508
f01021a7:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01021ac:	68 b9 02 00 00       	push   $0x2b9
f01021b1:	68 54 3c 10 f0       	push   $0xf0103c54
f01021b6:	e8 d0 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021bb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021c1:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021c4:	77 a6                	ja     f010216c <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021c6:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021c9:	c1 e7 0c             	shl    $0xc,%edi
f01021cc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021d1:	eb 30                	jmp    f0102203 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021d3:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021d9:	89 f0                	mov    %esi,%eax
f01021db:	e8 76 e7 ff ff       	call   f0100956 <check_va2pa>
f01021e0:	39 c3                	cmp    %eax,%ebx
f01021e2:	74 19                	je     f01021fd <mem_init+0x120f>
f01021e4:	68 3c 45 10 f0       	push   $0xf010453c
f01021e9:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01021ee:	68 bd 02 00 00       	push   $0x2bd
f01021f3:	68 54 3c 10 f0       	push   $0xf0103c54
f01021f8:	e8 8e de ff ff       	call   f010008b <_panic>
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021fd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102203:	39 fb                	cmp    %edi,%ebx
f0102205:	72 cc                	jb     f01021d3 <mem_init+0x11e5>
f0102207:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010220c:	89 da                	mov    %ebx,%edx
f010220e:	89 f0                	mov    %esi,%eax
f0102210:	e8 41 e7 ff ff       	call   f0100956 <check_va2pa>
f0102215:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f010221b:	39 c2                	cmp    %eax,%edx
f010221d:	74 19                	je     f0102238 <mem_init+0x124a>
f010221f:	68 64 45 10 f0       	push   $0xf0104564
f0102224:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102229:	68 c1 02 00 00       	push   $0x2c1
f010222e:	68 54 3c 10 f0       	push   $0xf0103c54
f0102233:	e8 53 de ff ff       	call   f010008b <_panic>
f0102238:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010223e:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102244:	75 c6                	jne    f010220c <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102246:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010224b:	89 f0                	mov    %esi,%eax
f010224d:	e8 04 e7 ff ff       	call   f0100956 <check_va2pa>
f0102252:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102255:	74 51                	je     f01022a8 <mem_init+0x12ba>
f0102257:	68 ac 45 10 f0       	push   $0xf01045ac
f010225c:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102261:	68 c2 02 00 00       	push   $0x2c2
f0102266:	68 54 3c 10 f0       	push   $0xf0103c54
f010226b:	e8 1b de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f0102270:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102275:	72 36                	jb     f01022ad <mem_init+0x12bf>
f0102277:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010227c:	76 07                	jbe    f0102285 <mem_init+0x1297>
f010227e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102283:	75 28                	jne    f01022ad <mem_init+0x12bf>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102285:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102289:	0f 85 83 00 00 00    	jne    f0102312 <mem_init+0x1324>
f010228f:	68 bf 3e 10 f0       	push   $0xf0103ebf
f0102294:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102299:	68 cc 02 00 00       	push   $0x2cc
f010229e:	68 54 3c 10 f0       	push   $0xf0103c54
f01022a3:	e8 e3 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022a8:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE))
f01022ad:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022b2:	76 3f                	jbe    f01022f3 <mem_init+0x1305>
			{
				assert(pgdir[i] & PTE_P);
f01022b4:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022b7:	f6 c2 01             	test   $0x1,%dl
f01022ba:	75 19                	jne    f01022d5 <mem_init+0x12e7>
f01022bc:	68 bf 3e 10 f0       	push   $0xf0103ebf
f01022c1:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01022c6:	68 d1 02 00 00       	push   $0x2d1
f01022cb:	68 54 3c 10 f0       	push   $0xf0103c54
f01022d0:	e8 b6 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022d5:	f6 c2 02             	test   $0x2,%dl
f01022d8:	75 38                	jne    f0102312 <mem_init+0x1324>
f01022da:	68 d0 3e 10 f0       	push   $0xf0103ed0
f01022df:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01022e4:	68 d2 02 00 00       	push   $0x2d2
f01022e9:	68 54 3c 10 f0       	push   $0xf0103c54
f01022ee:	e8 98 dd ff ff       	call   f010008b <_panic>
			}
			else
				assert(pgdir[i] == 0);
f01022f3:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01022f7:	74 19                	je     f0102312 <mem_init+0x1324>
f01022f9:	68 e1 3e 10 f0       	push   $0xf0103ee1
f01022fe:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102303:	68 d5 02 00 00       	push   $0x2d5
f0102308:	68 54 3c 10 f0       	push   $0xf0103c54
f010230d:	e8 79 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102312:	83 c0 01             	add    $0x1,%eax
f0102315:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010231a:	0f 86 50 ff ff ff    	jbe    f0102270 <mem_init+0x1282>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102320:	83 ec 0c             	sub    $0xc,%esp
f0102323:	68 dc 45 10 f0       	push   $0xf01045dc
f0102328:	e8 ba 03 00 00       	call   f01026e7 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010232d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102332:	83 c4 10             	add    $0x10,%esp
f0102335:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010233a:	77 15                	ja     f0102351 <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010233c:	50                   	push   %eax
f010233d:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0102342:	68 d6 00 00 00       	push   $0xd6
f0102347:	68 54 3c 10 f0       	push   $0xf0103c54
f010234c:	e8 3a dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102351:	05 00 00 00 10       	add    $0x10000000,%eax
f0102356:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102359:	b8 00 00 00 00       	mov    $0x0,%eax
f010235e:	e8 57 e6 ff ff       	call   f01009ba <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102363:	0f 20 c0             	mov    %cr0,%eax
f0102366:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102369:	0d 23 00 05 80       	or     $0x80050023,%eax
f010236e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102371:	83 ec 0c             	sub    $0xc,%esp
f0102374:	6a 00                	push   $0x0
f0102376:	e8 ab e9 ff ff       	call   f0100d26 <page_alloc>
f010237b:	89 c3                	mov    %eax,%ebx
f010237d:	83 c4 10             	add    $0x10,%esp
f0102380:	85 c0                	test   %eax,%eax
f0102382:	75 19                	jne    f010239d <mem_init+0x13af>
f0102384:	68 34 3d 10 f0       	push   $0xf0103d34
f0102389:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010238e:	68 94 03 00 00       	push   $0x394
f0102393:	68 54 3c 10 f0       	push   $0xf0103c54
f0102398:	e8 ee dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010239d:	83 ec 0c             	sub    $0xc,%esp
f01023a0:	6a 00                	push   $0x0
f01023a2:	e8 7f e9 ff ff       	call   f0100d26 <page_alloc>
f01023a7:	89 c7                	mov    %eax,%edi
f01023a9:	83 c4 10             	add    $0x10,%esp
f01023ac:	85 c0                	test   %eax,%eax
f01023ae:	75 19                	jne    f01023c9 <mem_init+0x13db>
f01023b0:	68 4a 3d 10 f0       	push   $0xf0103d4a
f01023b5:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01023ba:	68 95 03 00 00       	push   $0x395
f01023bf:	68 54 3c 10 f0       	push   $0xf0103c54
f01023c4:	e8 c2 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023c9:	83 ec 0c             	sub    $0xc,%esp
f01023cc:	6a 00                	push   $0x0
f01023ce:	e8 53 e9 ff ff       	call   f0100d26 <page_alloc>
f01023d3:	89 c6                	mov    %eax,%esi
f01023d5:	83 c4 10             	add    $0x10,%esp
f01023d8:	85 c0                	test   %eax,%eax
f01023da:	75 19                	jne    f01023f5 <mem_init+0x1407>
f01023dc:	68 60 3d 10 f0       	push   $0xf0103d60
f01023e1:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01023e6:	68 96 03 00 00       	push   $0x396
f01023eb:	68 54 3c 10 f0       	push   $0xf0103c54
f01023f0:	e8 96 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01023f5:	83 ec 0c             	sub    $0xc,%esp
f01023f8:	53                   	push   %ebx
f01023f9:	e8 98 e9 ff ff       	call   f0100d96 <page_free>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01023fe:	89 f8                	mov    %edi,%eax
f0102400:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102406:	c1 f8 03             	sar    $0x3,%eax
f0102409:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010240c:	89 c2                	mov    %eax,%edx
f010240e:	c1 ea 0c             	shr    $0xc,%edx
f0102411:	83 c4 10             	add    $0x10,%esp
f0102414:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010241a:	72 12                	jb     f010242e <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010241c:	50                   	push   %eax
f010241d:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0102422:	6a 57                	push   $0x57
f0102424:	68 60 3c 10 f0       	push   $0xf0103c60
f0102429:	e8 5d dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010242e:	83 ec 04             	sub    $0x4,%esp
f0102431:	68 00 10 00 00       	push   $0x1000
f0102436:	6a 01                	push   $0x1
f0102438:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010243d:	50                   	push   %eax
f010243e:	e8 0d 0e 00 00       	call   f0103250 <memset>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102443:	89 f0                	mov    %esi,%eax
f0102445:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010244b:	c1 f8 03             	sar    $0x3,%eax
f010244e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102451:	89 c2                	mov    %eax,%edx
f0102453:	c1 ea 0c             	shr    $0xc,%edx
f0102456:	83 c4 10             	add    $0x10,%esp
f0102459:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010245f:	72 12                	jb     f0102473 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102461:	50                   	push   %eax
f0102462:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0102467:	6a 57                	push   $0x57
f0102469:	68 60 3c 10 f0       	push   $0xf0103c60
f010246e:	e8 18 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102473:	83 ec 04             	sub    $0x4,%esp
f0102476:	68 00 10 00 00       	push   $0x1000
f010247b:	6a 02                	push   $0x2
f010247d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102482:	50                   	push   %eax
f0102483:	e8 c8 0d 00 00       	call   f0103250 <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f0102488:	6a 02                	push   $0x2
f010248a:	68 00 10 00 00       	push   $0x1000
f010248f:	57                   	push   %edi
f0102490:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102496:	e8 ed ea ff ff       	call   f0100f88 <page_insert>
	assert(pp1->pp_ref == 1);
f010249b:	83 c4 20             	add    $0x20,%esp
f010249e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024a3:	74 19                	je     f01024be <mem_init+0x14d0>
f01024a5:	68 da 3d 10 f0       	push   $0xf0103dda
f01024aa:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01024af:	68 9b 03 00 00       	push   $0x39b
f01024b4:	68 54 3c 10 f0       	push   $0xf0103c54
f01024b9:	e8 cd db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024be:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024c5:	01 01 01 
f01024c8:	74 19                	je     f01024e3 <mem_init+0x14f5>
f01024ca:	68 fc 45 10 f0       	push   $0xf01045fc
f01024cf:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01024d4:	68 9c 03 00 00       	push   $0x39c
f01024d9:	68 54 3c 10 f0       	push   $0xf0103c54
f01024de:	e8 a8 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f01024e3:	6a 02                	push   $0x2
f01024e5:	68 00 10 00 00       	push   $0x1000
f01024ea:	56                   	push   %esi
f01024eb:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01024f1:	e8 92 ea ff ff       	call   f0100f88 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01024f6:	83 c4 10             	add    $0x10,%esp
f01024f9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102500:	02 02 02 
f0102503:	74 19                	je     f010251e <mem_init+0x1530>
f0102505:	68 20 46 10 f0       	push   $0xf0104620
f010250a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010250f:	68 9e 03 00 00       	push   $0x39e
f0102514:	68 54 3c 10 f0       	push   $0xf0103c54
f0102519:	e8 6d db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010251e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102523:	74 19                	je     f010253e <mem_init+0x1550>
f0102525:	68 fc 3d 10 f0       	push   $0xf0103dfc
f010252a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010252f:	68 9f 03 00 00       	push   $0x39f
f0102534:	68 54 3c 10 f0       	push   $0xf0103c54
f0102539:	e8 4d db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010253e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102543:	74 19                	je     f010255e <mem_init+0x1570>
f0102545:	68 66 3e 10 f0       	push   $0xf0103e66
f010254a:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010254f:	68 a0 03 00 00       	push   $0x3a0
f0102554:	68 54 3c 10 f0       	push   $0xf0103c54
f0102559:	e8 2d db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010255e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102565:	03 03 03 

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102568:	89 f0                	mov    %esi,%eax
f010256a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102570:	c1 f8 03             	sar    $0x3,%eax
f0102573:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102576:	89 c2                	mov    %eax,%edx
f0102578:	c1 ea 0c             	shr    $0xc,%edx
f010257b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102581:	72 12                	jb     f0102595 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102583:	50                   	push   %eax
f0102584:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0102589:	6a 57                	push   $0x57
f010258b:	68 60 3c 10 f0       	push   $0xf0103c60
f0102590:	e8 f6 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102595:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010259c:	03 03 03 
f010259f:	74 19                	je     f01025ba <mem_init+0x15cc>
f01025a1:	68 44 46 10 f0       	push   $0xf0104644
f01025a6:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01025ab:	68 a2 03 00 00       	push   $0x3a2
f01025b0:	68 54 3c 10 f0       	push   $0xf0103c54
f01025b5:	e8 d1 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f01025ba:	83 ec 08             	sub    $0x8,%esp
f01025bd:	68 00 10 00 00       	push   $0x1000
f01025c2:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025c8:	e8 79 e9 ff ff       	call   f0100f46 <page_remove>
	assert(pp2->pp_ref == 0);
f01025cd:	83 c4 10             	add    $0x10,%esp
f01025d0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025d5:	74 19                	je     f01025f0 <mem_init+0x1602>
f01025d7:	68 34 3e 10 f0       	push   $0xf0103e34
f01025dc:	68 7a 3c 10 f0       	push   $0xf0103c7a
f01025e1:	68 a4 03 00 00       	push   $0x3a4
f01025e6:	68 54 3c 10 f0       	push   $0xf0103c54
f01025eb:	e8 9b da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025f0:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01025f6:	8b 11                	mov    (%ecx),%edx
f01025f8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01025fe:	89 d8                	mov    %ebx,%eax
f0102600:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102606:	c1 f8 03             	sar    $0x3,%eax
f0102609:	c1 e0 0c             	shl    $0xc,%eax
f010260c:	39 c2                	cmp    %eax,%edx
f010260e:	74 19                	je     f0102629 <mem_init+0x163b>
f0102610:	68 84 41 10 f0       	push   $0xf0104184
f0102615:	68 7a 3c 10 f0       	push   $0xf0103c7a
f010261a:	68 a7 03 00 00       	push   $0x3a7
f010261f:	68 54 3c 10 f0       	push   $0xf0103c54
f0102624:	e8 62 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102629:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010262f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102634:	74 19                	je     f010264f <mem_init+0x1661>
f0102636:	68 eb 3d 10 f0       	push   $0xf0103deb
f010263b:	68 7a 3c 10 f0       	push   $0xf0103c7a
f0102640:	68 a9 03 00 00       	push   $0x3a9
f0102645:	68 54 3c 10 f0       	push   $0xf0103c54
f010264a:	e8 3c da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010264f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102655:	83 ec 0c             	sub    $0xc,%esp
f0102658:	53                   	push   %ebx
f0102659:	e8 38 e7 ff ff       	call   f0100d96 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010265e:	c7 04 24 70 46 10 f0 	movl   $0xf0104670,(%esp)
f0102665:	e8 7d 00 00 00       	call   f01026e7 <cprintf>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010266a:	83 c4 10             	add    $0x10,%esp
f010266d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102670:	5b                   	pop    %ebx
f0102671:	5e                   	pop    %esi
f0102672:	5f                   	pop    %edi
f0102673:	5d                   	pop    %ebp
f0102674:	c3                   	ret    

f0102675 <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f0102675:	55                   	push   %ebp
f0102676:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102678:	8b 45 0c             	mov    0xc(%ebp),%eax
f010267b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010267e:	5d                   	pop    %ebp
f010267f:	c3                   	ret    

f0102680 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102680:	55                   	push   %ebp
f0102681:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102683:	ba 70 00 00 00       	mov    $0x70,%edx
f0102688:	8b 45 08             	mov    0x8(%ebp),%eax
f010268b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010268c:	ba 71 00 00 00       	mov    $0x71,%edx
f0102691:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102692:	0f b6 c0             	movzbl %al,%eax
}
f0102695:	5d                   	pop    %ebp
f0102696:	c3                   	ret    

f0102697 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102697:	55                   	push   %ebp
f0102698:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010269a:	ba 70 00 00 00       	mov    $0x70,%edx
f010269f:	8b 45 08             	mov    0x8(%ebp),%eax
f01026a2:	ee                   	out    %al,(%dx)
f01026a3:	ba 71 00 00 00       	mov    $0x71,%edx
f01026a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026ab:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026ac:	5d                   	pop    %ebp
f01026ad:	c3                   	ret    

f01026ae <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026ae:	55                   	push   %ebp
f01026af:	89 e5                	mov    %esp,%ebp
f01026b1:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026b4:	ff 75 08             	pushl  0x8(%ebp)
f01026b7:	e8 36 df ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01026bc:	83 c4 10             	add    $0x10,%esp
f01026bf:	c9                   	leave  
f01026c0:	c3                   	ret    

f01026c1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026c1:	55                   	push   %ebp
f01026c2:	89 e5                	mov    %esp,%ebp
f01026c4:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026ce:	ff 75 0c             	pushl  0xc(%ebp)
f01026d1:	ff 75 08             	pushl  0x8(%ebp)
f01026d4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026d7:	50                   	push   %eax
f01026d8:	68 ae 26 10 f0       	push   $0xf01026ae
f01026dd:	e8 21 04 00 00       	call   f0102b03 <vprintfmt>
	return cnt;
}
f01026e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026e5:	c9                   	leave  
f01026e6:	c3                   	ret    

f01026e7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026e7:	55                   	push   %ebp
f01026e8:	89 e5                	mov    %esp,%ebp
f01026ea:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026ed:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026f0:	50                   	push   %eax
f01026f1:	ff 75 08             	pushl  0x8(%ebp)
f01026f4:	e8 c8 ff ff ff       	call   f01026c1 <vcprintf>
	va_end(ap);

	return cnt;
}
f01026f9:	c9                   	leave  
f01026fa:	c3                   	ret    

f01026fb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01026fb:	55                   	push   %ebp
f01026fc:	89 e5                	mov    %esp,%ebp
f01026fe:	57                   	push   %edi
f01026ff:	56                   	push   %esi
f0102700:	53                   	push   %ebx
f0102701:	83 ec 14             	sub    $0x14,%esp
f0102704:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102707:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010270a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010270d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102710:	8b 1a                	mov    (%edx),%ebx
f0102712:	8b 01                	mov    (%ecx),%eax
f0102714:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102717:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010271e:	eb 7f                	jmp    f010279f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102720:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102723:	01 d8                	add    %ebx,%eax
f0102725:	89 c6                	mov    %eax,%esi
f0102727:	c1 ee 1f             	shr    $0x1f,%esi
f010272a:	01 c6                	add    %eax,%esi
f010272c:	d1 fe                	sar    %esi
f010272e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102731:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102734:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102737:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102739:	eb 03                	jmp    f010273e <stab_binsearch+0x43>
			m--;
f010273b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010273e:	39 c3                	cmp    %eax,%ebx
f0102740:	7f 0d                	jg     f010274f <stab_binsearch+0x54>
f0102742:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102746:	83 ea 0c             	sub    $0xc,%edx
f0102749:	39 f9                	cmp    %edi,%ecx
f010274b:	75 ee                	jne    f010273b <stab_binsearch+0x40>
f010274d:	eb 05                	jmp    f0102754 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010274f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102752:	eb 4b                	jmp    f010279f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102754:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102757:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010275a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010275e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102761:	76 11                	jbe    f0102774 <stab_binsearch+0x79>
			*region_left = m;
f0102763:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102766:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102768:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010276b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102772:	eb 2b                	jmp    f010279f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102774:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102777:	73 14                	jae    f010278d <stab_binsearch+0x92>
			*region_right = m - 1;
f0102779:	83 e8 01             	sub    $0x1,%eax
f010277c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010277f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102782:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102784:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010278b:	eb 12                	jmp    f010279f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010278d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102790:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102792:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102796:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102798:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010279f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027a2:	0f 8e 78 ff ff ff    	jle    f0102720 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027a8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027ac:	75 0f                	jne    f01027bd <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027b1:	8b 00                	mov    (%eax),%eax
f01027b3:	83 e8 01             	sub    $0x1,%eax
f01027b6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027b9:	89 06                	mov    %eax,(%esi)
f01027bb:	eb 2c                	jmp    f01027e9 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027c0:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027c2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027c5:	8b 0e                	mov    (%esi),%ecx
f01027c7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027ca:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027cd:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027d0:	eb 03                	jmp    f01027d5 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027d2:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027d5:	39 c8                	cmp    %ecx,%eax
f01027d7:	7e 0b                	jle    f01027e4 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027d9:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027dd:	83 ea 0c             	sub    $0xc,%edx
f01027e0:	39 df                	cmp    %ebx,%edi
f01027e2:	75 ee                	jne    f01027d2 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027e4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027e7:	89 06                	mov    %eax,(%esi)
	}
}
f01027e9:	83 c4 14             	add    $0x14,%esp
f01027ec:	5b                   	pop    %ebx
f01027ed:	5e                   	pop    %esi
f01027ee:	5f                   	pop    %edi
f01027ef:	5d                   	pop    %ebp
f01027f0:	c3                   	ret    

f01027f1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027f1:	55                   	push   %ebp
f01027f2:	89 e5                	mov    %esp,%ebp
f01027f4:	57                   	push   %edi
f01027f5:	56                   	push   %esi
f01027f6:	53                   	push   %ebx
f01027f7:	83 ec 3c             	sub    $0x3c,%esp
f01027fa:	8b 75 08             	mov    0x8(%ebp),%esi
f01027fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102800:	c7 03 9c 46 10 f0    	movl   $0xf010469c,(%ebx)
	info->eip_line = 0;
f0102806:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010280d:	c7 43 08 9c 46 10 f0 	movl   $0xf010469c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102814:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010281b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010281e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102825:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010282b:	76 11                	jbe    f010283e <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010282d:	b8 3b c0 10 f0       	mov    $0xf010c03b,%eax
f0102832:	3d 79 a2 10 f0       	cmp    $0xf010a279,%eax
f0102837:	77 19                	ja     f0102852 <debuginfo_eip+0x61>
f0102839:	e9 ba 01 00 00       	jmp    f01029f8 <debuginfo_eip+0x207>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010283e:	83 ec 04             	sub    $0x4,%esp
f0102841:	68 a6 46 10 f0       	push   $0xf01046a6
f0102846:	6a 7f                	push   $0x7f
f0102848:	68 b3 46 10 f0       	push   $0xf01046b3
f010284d:	e8 39 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102852:	80 3d 3a c0 10 f0 00 	cmpb   $0x0,0xf010c03a
f0102859:	0f 85 a0 01 00 00    	jne    f01029ff <debuginfo_eip+0x20e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010285f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102866:	b8 78 a2 10 f0       	mov    $0xf010a278,%eax
f010286b:	2d f0 48 10 f0       	sub    $0xf01048f0,%eax
f0102870:	c1 f8 02             	sar    $0x2,%eax
f0102873:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102879:	83 e8 01             	sub    $0x1,%eax
f010287c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010287f:	83 ec 08             	sub    $0x8,%esp
f0102882:	56                   	push   %esi
f0102883:	6a 64                	push   $0x64
f0102885:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102888:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010288b:	b8 f0 48 10 f0       	mov    $0xf01048f0,%eax
f0102890:	e8 66 fe ff ff       	call   f01026fb <stab_binsearch>
	if (lfile == 0)
f0102895:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102898:	83 c4 10             	add    $0x10,%esp
f010289b:	85 c0                	test   %eax,%eax
f010289d:	0f 84 63 01 00 00    	je     f0102a06 <debuginfo_eip+0x215>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028ac:	83 ec 08             	sub    $0x8,%esp
f01028af:	56                   	push   %esi
f01028b0:	6a 24                	push   $0x24
f01028b2:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028b5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028b8:	b8 f0 48 10 f0       	mov    $0xf01048f0,%eax
f01028bd:	e8 39 fe ff ff       	call   f01026fb <stab_binsearch>

	if (lfun <= rfun) {
f01028c2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028c5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028c8:	83 c4 10             	add    $0x10,%esp
f01028cb:	39 d0                	cmp    %edx,%eax
f01028cd:	7f 40                	jg     f010290f <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028cf:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028d2:	c1 e1 02             	shl    $0x2,%ecx
f01028d5:	8d b9 f0 48 10 f0    	lea    -0xfefb710(%ecx),%edi
f01028db:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028de:	8b b9 f0 48 10 f0    	mov    -0xfefb710(%ecx),%edi
f01028e4:	b9 3b c0 10 f0       	mov    $0xf010c03b,%ecx
f01028e9:	81 e9 79 a2 10 f0    	sub    $0xf010a279,%ecx
f01028ef:	39 cf                	cmp    %ecx,%edi
f01028f1:	73 09                	jae    f01028fc <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028f3:	81 c7 79 a2 10 f0    	add    $0xf010a279,%edi
f01028f9:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01028fc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01028ff:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102902:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102905:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102907:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010290a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010290d:	eb 0f                	jmp    f010291e <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010290f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102912:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102915:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102918:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010291b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010291e:	83 ec 08             	sub    $0x8,%esp
f0102921:	6a 3a                	push   $0x3a
f0102923:	ff 73 08             	pushl  0x8(%ebx)
f0102926:	e8 09 09 00 00       	call   f0103234 <strfind>
f010292b:	2b 43 08             	sub    0x8(%ebx),%eax
f010292e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102931:	83 c4 08             	add    $0x8,%esp
f0102934:	56                   	push   %esi
f0102935:	6a 44                	push   $0x44
f0102937:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010293a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010293d:	b8 f0 48 10 f0       	mov    $0xf01048f0,%eax
f0102942:	e8 b4 fd ff ff       	call   f01026fb <stab_binsearch>
    if(lline <= rline){
f0102947:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010294a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010294d:	83 c4 10             	add    $0x10,%esp
f0102950:	39 d0                	cmp    %edx,%eax
f0102952:	7f 10                	jg     f0102964 <debuginfo_eip+0x173>
        info->eip_line = stabs[rline].n_desc;
f0102954:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102957:	0f b7 14 95 f6 48 10 	movzwl -0xfefb70a(,%edx,4),%edx
f010295e:	f0 
f010295f:	89 53 04             	mov    %edx,0x4(%ebx)
f0102962:	eb 07                	jmp    f010296b <debuginfo_eip+0x17a>
    }
    else
        info->eip_line = -1;
f0102964:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010296b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010296e:	89 c2                	mov    %eax,%edx
f0102970:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102973:	8d 04 85 f0 48 10 f0 	lea    -0xfefb710(,%eax,4),%eax
f010297a:	eb 06                	jmp    f0102982 <debuginfo_eip+0x191>
f010297c:	83 ea 01             	sub    $0x1,%edx
f010297f:	83 e8 0c             	sub    $0xc,%eax
f0102982:	39 d7                	cmp    %edx,%edi
f0102984:	7f 34                	jg     f01029ba <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0102986:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f010298a:	80 f9 84             	cmp    $0x84,%cl
f010298d:	74 0b                	je     f010299a <debuginfo_eip+0x1a9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010298f:	80 f9 64             	cmp    $0x64,%cl
f0102992:	75 e8                	jne    f010297c <debuginfo_eip+0x18b>
f0102994:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102998:	74 e2                	je     f010297c <debuginfo_eip+0x18b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010299a:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010299d:	8b 14 85 f0 48 10 f0 	mov    -0xfefb710(,%eax,4),%edx
f01029a4:	b8 3b c0 10 f0       	mov    $0xf010c03b,%eax
f01029a9:	2d 79 a2 10 f0       	sub    $0xf010a279,%eax
f01029ae:	39 c2                	cmp    %eax,%edx
f01029b0:	73 08                	jae    f01029ba <debuginfo_eip+0x1c9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029b2:	81 c2 79 a2 10 f0    	add    $0xf010a279,%edx
f01029b8:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029ba:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029bd:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029c0:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029c5:	39 f2                	cmp    %esi,%edx
f01029c7:	7d 49                	jge    f0102a12 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
f01029c9:	83 c2 01             	add    $0x1,%edx
f01029cc:	89 d0                	mov    %edx,%eax
f01029ce:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029d1:	8d 14 95 f0 48 10 f0 	lea    -0xfefb710(,%edx,4),%edx
f01029d8:	eb 04                	jmp    f01029de <debuginfo_eip+0x1ed>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029da:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029de:	39 c6                	cmp    %eax,%esi
f01029e0:	7e 2b                	jle    f0102a0d <debuginfo_eip+0x21c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029e2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029e6:	83 c0 01             	add    $0x1,%eax
f01029e9:	83 c2 0c             	add    $0xc,%edx
f01029ec:	80 f9 a0             	cmp    $0xa0,%cl
f01029ef:	74 e9                	je     f01029da <debuginfo_eip+0x1e9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f6:	eb 1a                	jmp    f0102a12 <debuginfo_eip+0x221>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029fd:	eb 13                	jmp    f0102a12 <debuginfo_eip+0x221>
f01029ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a04:	eb 0c                	jmp    f0102a12 <debuginfo_eip+0x221>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0b:	eb 05                	jmp    f0102a12 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a15:	5b                   	pop    %ebx
f0102a16:	5e                   	pop    %esi
f0102a17:	5f                   	pop    %edi
f0102a18:	5d                   	pop    %ebp
f0102a19:	c3                   	ret    

f0102a1a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a1a:	55                   	push   %ebp
f0102a1b:	89 e5                	mov    %esp,%ebp
f0102a1d:	57                   	push   %edi
f0102a1e:	56                   	push   %esi
f0102a1f:	53                   	push   %ebx
f0102a20:	83 ec 1c             	sub    $0x1c,%esp
f0102a23:	89 c7                	mov    %eax,%edi
f0102a25:	89 d6                	mov    %edx,%esi
f0102a27:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a2a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a2d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a30:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a33:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a36:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a3b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a3e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a41:	39 d3                	cmp    %edx,%ebx
f0102a43:	72 05                	jb     f0102a4a <printnum+0x30>
f0102a45:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a48:	77 45                	ja     f0102a8f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a4a:	83 ec 0c             	sub    $0xc,%esp
f0102a4d:	ff 75 18             	pushl  0x18(%ebp)
f0102a50:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a53:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a56:	53                   	push   %ebx
f0102a57:	ff 75 10             	pushl  0x10(%ebp)
f0102a5a:	83 ec 08             	sub    $0x8,%esp
f0102a5d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a60:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a63:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a66:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a69:	e8 f2 09 00 00       	call   f0103460 <__udivdi3>
f0102a6e:	83 c4 18             	add    $0x18,%esp
f0102a71:	52                   	push   %edx
f0102a72:	50                   	push   %eax
f0102a73:	89 f2                	mov    %esi,%edx
f0102a75:	89 f8                	mov    %edi,%eax
f0102a77:	e8 9e ff ff ff       	call   f0102a1a <printnum>
f0102a7c:	83 c4 20             	add    $0x20,%esp
f0102a7f:	eb 18                	jmp    f0102a99 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a81:	83 ec 08             	sub    $0x8,%esp
f0102a84:	56                   	push   %esi
f0102a85:	ff 75 18             	pushl  0x18(%ebp)
f0102a88:	ff d7                	call   *%edi
f0102a8a:	83 c4 10             	add    $0x10,%esp
f0102a8d:	eb 03                	jmp    f0102a92 <printnum+0x78>
f0102a8f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a92:	83 eb 01             	sub    $0x1,%ebx
f0102a95:	85 db                	test   %ebx,%ebx
f0102a97:	7f e8                	jg     f0102a81 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a99:	83 ec 08             	sub    $0x8,%esp
f0102a9c:	56                   	push   %esi
f0102a9d:	83 ec 04             	sub    $0x4,%esp
f0102aa0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aa3:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aa6:	ff 75 dc             	pushl  -0x24(%ebp)
f0102aa9:	ff 75 d8             	pushl  -0x28(%ebp)
f0102aac:	e8 df 0a 00 00       	call   f0103590 <__umoddi3>
f0102ab1:	83 c4 14             	add    $0x14,%esp
f0102ab4:	0f be 80 c1 46 10 f0 	movsbl -0xfefb93f(%eax),%eax
f0102abb:	50                   	push   %eax
f0102abc:	ff d7                	call   *%edi
}
f0102abe:	83 c4 10             	add    $0x10,%esp
f0102ac1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ac4:	5b                   	pop    %ebx
f0102ac5:	5e                   	pop    %esi
f0102ac6:	5f                   	pop    %edi
f0102ac7:	5d                   	pop    %ebp
f0102ac8:	c3                   	ret    

f0102ac9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102ac9:	55                   	push   %ebp
f0102aca:	89 e5                	mov    %esp,%ebp
f0102acc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102acf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102ad3:	8b 10                	mov    (%eax),%edx
f0102ad5:	3b 50 04             	cmp    0x4(%eax),%edx
f0102ad8:	73 0a                	jae    f0102ae4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102ada:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102add:	89 08                	mov    %ecx,(%eax)
f0102adf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ae2:	88 02                	mov    %al,(%edx)
}
f0102ae4:	5d                   	pop    %ebp
f0102ae5:	c3                   	ret    

f0102ae6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102ae6:	55                   	push   %ebp
f0102ae7:	89 e5                	mov    %esp,%ebp
f0102ae9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102aec:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102aef:	50                   	push   %eax
f0102af0:	ff 75 10             	pushl  0x10(%ebp)
f0102af3:	ff 75 0c             	pushl  0xc(%ebp)
f0102af6:	ff 75 08             	pushl  0x8(%ebp)
f0102af9:	e8 05 00 00 00       	call   f0102b03 <vprintfmt>
	va_end(ap);
}
f0102afe:	83 c4 10             	add    $0x10,%esp
f0102b01:	c9                   	leave  
f0102b02:	c3                   	ret    

f0102b03 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b03:	55                   	push   %ebp
f0102b04:	89 e5                	mov    %esp,%ebp
f0102b06:	57                   	push   %edi
f0102b07:	56                   	push   %esi
f0102b08:	53                   	push   %ebx
f0102b09:	83 ec 2c             	sub    $0x2c,%esp
f0102b0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b12:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b15:	eb 12                	jmp    f0102b29 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0102b17:	85 c0                	test   %eax,%eax
f0102b19:	0f 84 6a 04 00 00    	je     f0102f89 <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0102b1f:	83 ec 08             	sub    $0x8,%esp
f0102b22:	53                   	push   %ebx
f0102b23:	50                   	push   %eax
f0102b24:	ff d6                	call   *%esi
f0102b26:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0102b29:	83 c7 01             	add    $0x1,%edi
f0102b2c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b30:	83 f8 25             	cmp    $0x25,%eax
f0102b33:	75 e2                	jne    f0102b17 <vprintfmt+0x14>
f0102b35:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b39:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b40:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b47:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b4e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b53:	eb 07                	jmp    f0102b5c <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b55:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f0102b58:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b5c:	8d 47 01             	lea    0x1(%edi),%eax
f0102b5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b62:	0f b6 07             	movzbl (%edi),%eax
f0102b65:	0f b6 d0             	movzbl %al,%edx
f0102b68:	83 e8 23             	sub    $0x23,%eax
f0102b6b:	3c 55                	cmp    $0x55,%al
f0102b6d:	0f 87 fb 03 00 00    	ja     f0102f6e <vprintfmt+0x46b>
f0102b73:	0f b6 c0             	movzbl %al,%eax
f0102b76:	ff 24 85 60 47 10 f0 	jmp    *-0xfefb8a0(,%eax,4)
f0102b7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f0102b80:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102b84:	eb d6                	jmp    f0102b5c <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b86:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b89:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b8e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0102b91:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b94:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102b98:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102b9b:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102b9e:	83 f9 09             	cmp    $0x9,%ecx
f0102ba1:	77 3f                	ja     f0102be2 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0102ba3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102ba6:	eb e9                	jmp    f0102b91 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f0102ba8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bab:	8b 00                	mov    (%eax),%eax
f0102bad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bb0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bb3:	8d 40 04             	lea    0x4(%eax),%eax
f0102bb6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102bb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0102bbc:	eb 2a                	jmp    f0102be8 <vprintfmt+0xe5>
f0102bbe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bc1:	85 c0                	test   %eax,%eax
f0102bc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bc8:	0f 49 d0             	cmovns %eax,%edx
f0102bcb:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd1:	eb 89                	jmp    f0102b5c <vprintfmt+0x59>
f0102bd3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102bd6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102bdd:	e9 7a ff ff ff       	jmp    f0102b5c <vprintfmt+0x59>
f0102be2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102be5:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f0102be8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102bec:	0f 89 6a ff ff ff    	jns    f0102b5c <vprintfmt+0x59>
				width = precision, precision = -1;
f0102bf2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102bf5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bf8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bff:	e9 58 ff ff ff       	jmp    f0102b5c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f0102c04:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102c07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f0102c0a:	e9 4d ff ff ff       	jmp    f0102b5c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102c0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c12:	8d 78 04             	lea    0x4(%eax),%edi
f0102c15:	83 ec 08             	sub    $0x8,%esp
f0102c18:	53                   	push   %ebx
f0102c19:	ff 30                	pushl  (%eax)
f0102c1b:	ff d6                	call   *%esi
			break;
f0102c1d:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102c20:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102c23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f0102c26:	e9 fe fe ff ff       	jmp    f0102b29 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c2e:	8d 78 04             	lea    0x4(%eax),%edi
f0102c31:	8b 00                	mov    (%eax),%eax
f0102c33:	99                   	cltd   
f0102c34:	31 d0                	xor    %edx,%eax
f0102c36:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c38:	83 f8 07             	cmp    $0x7,%eax
f0102c3b:	7f 0b                	jg     f0102c48 <vprintfmt+0x145>
f0102c3d:	8b 14 85 c0 48 10 f0 	mov    -0xfefb740(,%eax,4),%edx
f0102c44:	85 d2                	test   %edx,%edx
f0102c46:	75 1b                	jne    f0102c63 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102c48:	50                   	push   %eax
f0102c49:	68 d9 46 10 f0       	push   $0xf01046d9
f0102c4e:	53                   	push   %ebx
f0102c4f:	56                   	push   %esi
f0102c50:	e8 91 fe ff ff       	call   f0102ae6 <printfmt>
f0102c55:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c58:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102c5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c5e:	e9 c6 fe ff ff       	jmp    f0102b29 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c63:	52                   	push   %edx
f0102c64:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0102c69:	53                   	push   %ebx
f0102c6a:	56                   	push   %esi
f0102c6b:	e8 76 fe ff ff       	call   f0102ae6 <printfmt>
f0102c70:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c73:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102c76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c79:	e9 ab fe ff ff       	jmp    f0102b29 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c81:	83 c0 04             	add    $0x4,%eax
f0102c84:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102c87:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c8a:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102c8c:	85 ff                	test   %edi,%edi
f0102c8e:	b8 d2 46 10 f0       	mov    $0xf01046d2,%eax
f0102c93:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102c96:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c9a:	0f 8e 94 00 00 00    	jle    f0102d34 <vprintfmt+0x231>
f0102ca0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ca4:	0f 84 98 00 00 00    	je     f0102d42 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102caa:	83 ec 08             	sub    $0x8,%esp
f0102cad:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cb0:	57                   	push   %edi
f0102cb1:	e8 34 04 00 00       	call   f01030ea <strnlen>
f0102cb6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cb9:	29 c1                	sub    %eax,%ecx
f0102cbb:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102cbe:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cc1:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102cc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cc8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ccb:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ccd:	eb 0f                	jmp    f0102cde <vprintfmt+0x1db>
					putch(padc, putdat);
f0102ccf:	83 ec 08             	sub    $0x8,%esp
f0102cd2:	53                   	push   %ebx
f0102cd3:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cd6:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cd8:	83 ef 01             	sub    $0x1,%edi
f0102cdb:	83 c4 10             	add    $0x10,%esp
f0102cde:	85 ff                	test   %edi,%edi
f0102ce0:	7f ed                	jg     f0102ccf <vprintfmt+0x1cc>
f0102ce2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ce5:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102ce8:	85 c9                	test   %ecx,%ecx
f0102cea:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cef:	0f 49 c1             	cmovns %ecx,%eax
f0102cf2:	29 c1                	sub    %eax,%ecx
f0102cf4:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cf7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cfa:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cfd:	89 cb                	mov    %ecx,%ebx
f0102cff:	eb 4d                	jmp    f0102d4e <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d01:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d05:	74 1b                	je     f0102d22 <vprintfmt+0x21f>
f0102d07:	0f be c0             	movsbl %al,%eax
f0102d0a:	83 e8 20             	sub    $0x20,%eax
f0102d0d:	83 f8 5e             	cmp    $0x5e,%eax
f0102d10:	76 10                	jbe    f0102d22 <vprintfmt+0x21f>
					putch('?', putdat);
f0102d12:	83 ec 08             	sub    $0x8,%esp
f0102d15:	ff 75 0c             	pushl  0xc(%ebp)
f0102d18:	6a 3f                	push   $0x3f
f0102d1a:	ff 55 08             	call   *0x8(%ebp)
f0102d1d:	83 c4 10             	add    $0x10,%esp
f0102d20:	eb 0d                	jmp    f0102d2f <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d22:	83 ec 08             	sub    $0x8,%esp
f0102d25:	ff 75 0c             	pushl  0xc(%ebp)
f0102d28:	52                   	push   %edx
f0102d29:	ff 55 08             	call   *0x8(%ebp)
f0102d2c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d2f:	83 eb 01             	sub    $0x1,%ebx
f0102d32:	eb 1a                	jmp    f0102d4e <vprintfmt+0x24b>
f0102d34:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d37:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d3a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d3d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d40:	eb 0c                	jmp    f0102d4e <vprintfmt+0x24b>
f0102d42:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d45:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d48:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d4b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d4e:	83 c7 01             	add    $0x1,%edi
f0102d51:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d55:	0f be d0             	movsbl %al,%edx
f0102d58:	85 d2                	test   %edx,%edx
f0102d5a:	74 23                	je     f0102d7f <vprintfmt+0x27c>
f0102d5c:	85 f6                	test   %esi,%esi
f0102d5e:	78 a1                	js     f0102d01 <vprintfmt+0x1fe>
f0102d60:	83 ee 01             	sub    $0x1,%esi
f0102d63:	79 9c                	jns    f0102d01 <vprintfmt+0x1fe>
f0102d65:	89 df                	mov    %ebx,%edi
f0102d67:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d6d:	eb 18                	jmp    f0102d87 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d6f:	83 ec 08             	sub    $0x8,%esp
f0102d72:	53                   	push   %ebx
f0102d73:	6a 20                	push   $0x20
f0102d75:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d77:	83 ef 01             	sub    $0x1,%edi
f0102d7a:	83 c4 10             	add    $0x10,%esp
f0102d7d:	eb 08                	jmp    f0102d87 <vprintfmt+0x284>
f0102d7f:	89 df                	mov    %ebx,%edi
f0102d81:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d87:	85 ff                	test   %edi,%edi
f0102d89:	7f e4                	jg     f0102d6f <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d8b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102d8e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102d91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d94:	e9 90 fd ff ff       	jmp    f0102b29 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d99:	83 f9 01             	cmp    $0x1,%ecx
f0102d9c:	7e 19                	jle    f0102db7 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da1:	8b 50 04             	mov    0x4(%eax),%edx
f0102da4:	8b 00                	mov    (%eax),%eax
f0102da6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102da9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102dac:	8b 45 14             	mov    0x14(%ebp),%eax
f0102daf:	8d 40 08             	lea    0x8(%eax),%eax
f0102db2:	89 45 14             	mov    %eax,0x14(%ebp)
f0102db5:	eb 38                	jmp    f0102def <vprintfmt+0x2ec>
	else if (lflag)
f0102db7:	85 c9                	test   %ecx,%ecx
f0102db9:	74 1b                	je     f0102dd6 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102dbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dbe:	8b 00                	mov    (%eax),%eax
f0102dc0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dc3:	89 c1                	mov    %eax,%ecx
f0102dc5:	c1 f9 1f             	sar    $0x1f,%ecx
f0102dc8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102dcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dce:	8d 40 04             	lea    0x4(%eax),%eax
f0102dd1:	89 45 14             	mov    %eax,0x14(%ebp)
f0102dd4:	eb 19                	jmp    f0102def <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102dd6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd9:	8b 00                	mov    (%eax),%eax
f0102ddb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dde:	89 c1                	mov    %eax,%ecx
f0102de0:	c1 f9 1f             	sar    $0x1f,%ecx
f0102de3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102de6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de9:	8d 40 04             	lea    0x4(%eax),%eax
f0102dec:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102def:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102df2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102df5:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102dfa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102dfe:	0f 89 36 01 00 00    	jns    f0102f3a <vprintfmt+0x437>
				putch('-', putdat);
f0102e04:	83 ec 08             	sub    $0x8,%esp
f0102e07:	53                   	push   %ebx
f0102e08:	6a 2d                	push   $0x2d
f0102e0a:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e0c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e0f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e12:	f7 da                	neg    %edx
f0102e14:	83 d1 00             	adc    $0x0,%ecx
f0102e17:	f7 d9                	neg    %ecx
f0102e19:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e1c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e21:	e9 14 01 00 00       	jmp    f0102f3a <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e26:	83 f9 01             	cmp    $0x1,%ecx
f0102e29:	7e 18                	jle    f0102e43 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e2e:	8b 10                	mov    (%eax),%edx
f0102e30:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e33:	8d 40 08             	lea    0x8(%eax),%eax
f0102e36:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e39:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e3e:	e9 f7 00 00 00       	jmp    f0102f3a <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e43:	85 c9                	test   %ecx,%ecx
f0102e45:	74 1a                	je     f0102e61 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102e47:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e4a:	8b 10                	mov    (%eax),%edx
f0102e4c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e51:	8d 40 04             	lea    0x4(%eax),%eax
f0102e54:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e57:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e5c:	e9 d9 00 00 00       	jmp    f0102f3a <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e64:	8b 10                	mov    (%eax),%edx
f0102e66:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e6b:	8d 40 04             	lea    0x4(%eax),%eax
f0102e6e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e71:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e76:	e9 bf 00 00 00       	jmp    f0102f3a <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e7b:	83 f9 01             	cmp    $0x1,%ecx
f0102e7e:	7e 13                	jle    f0102e93 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f0102e80:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e83:	8b 50 04             	mov    0x4(%eax),%edx
f0102e86:	8b 00                	mov    (%eax),%eax
f0102e88:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102e8b:	8d 49 08             	lea    0x8(%ecx),%ecx
f0102e8e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102e91:	eb 28                	jmp    f0102ebb <vprintfmt+0x3b8>
	else if (lflag)
f0102e93:	85 c9                	test   %ecx,%ecx
f0102e95:	74 13                	je     f0102eaa <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f0102e97:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e9a:	8b 10                	mov    (%eax),%edx
f0102e9c:	89 d0                	mov    %edx,%eax
f0102e9e:	99                   	cltd   
f0102e9f:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102ea2:	8d 49 04             	lea    0x4(%ecx),%ecx
f0102ea5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102ea8:	eb 11                	jmp    f0102ebb <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f0102eaa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ead:	8b 10                	mov    (%eax),%edx
f0102eaf:	89 d0                	mov    %edx,%eax
f0102eb1:	99                   	cltd   
f0102eb2:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102eb5:	8d 49 04             	lea    0x4(%ecx),%ecx
f0102eb8:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f0102ebb:	89 d1                	mov    %edx,%ecx
f0102ebd:	89 c2                	mov    %eax,%edx
			base = 8;
f0102ebf:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102ec4:	eb 74                	jmp    f0102f3a <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f0102ec6:	83 ec 08             	sub    $0x8,%esp
f0102ec9:	53                   	push   %ebx
f0102eca:	6a 30                	push   $0x30
f0102ecc:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ece:	83 c4 08             	add    $0x8,%esp
f0102ed1:	53                   	push   %ebx
f0102ed2:	6a 78                	push   $0x78
f0102ed4:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ed9:	8b 10                	mov    (%eax),%edx
f0102edb:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ee0:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ee3:	8d 40 04             	lea    0x4(%eax),%eax
f0102ee6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102ee9:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102eee:	eb 4a                	jmp    f0102f3a <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ef0:	83 f9 01             	cmp    $0x1,%ecx
f0102ef3:	7e 15                	jle    f0102f0a <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f0102ef5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef8:	8b 10                	mov    (%eax),%edx
f0102efa:	8b 48 04             	mov    0x4(%eax),%ecx
f0102efd:	8d 40 08             	lea    0x8(%eax),%eax
f0102f00:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f03:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f08:	eb 30                	jmp    f0102f3a <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f0a:	85 c9                	test   %ecx,%ecx
f0102f0c:	74 17                	je     f0102f25 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f0102f0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f11:	8b 10                	mov    (%eax),%edx
f0102f13:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f18:	8d 40 04             	lea    0x4(%eax),%eax
f0102f1b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f1e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f23:	eb 15                	jmp    f0102f3a <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f25:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f28:	8b 10                	mov    (%eax),%edx
f0102f2a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f2f:	8d 40 04             	lea    0x4(%eax),%eax
f0102f32:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f35:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f3a:	83 ec 0c             	sub    $0xc,%esp
f0102f3d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f41:	57                   	push   %edi
f0102f42:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f45:	50                   	push   %eax
f0102f46:	51                   	push   %ecx
f0102f47:	52                   	push   %edx
f0102f48:	89 da                	mov    %ebx,%edx
f0102f4a:	89 f0                	mov    %esi,%eax
f0102f4c:	e8 c9 fa ff ff       	call   f0102a1a <printnum>
			break;
f0102f51:	83 c4 20             	add    $0x20,%esp
f0102f54:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f57:	e9 cd fb ff ff       	jmp    f0102b29 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f5c:	83 ec 08             	sub    $0x8,%esp
f0102f5f:	53                   	push   %ebx
f0102f60:	52                   	push   %edx
f0102f61:	ff d6                	call   *%esi
			break;
f0102f63:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102f66:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f69:	e9 bb fb ff ff       	jmp    f0102b29 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f6e:	83 ec 08             	sub    $0x8,%esp
f0102f71:	53                   	push   %ebx
f0102f72:	6a 25                	push   $0x25
f0102f74:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f76:	83 c4 10             	add    $0x10,%esp
f0102f79:	eb 03                	jmp    f0102f7e <vprintfmt+0x47b>
f0102f7b:	83 ef 01             	sub    $0x1,%edi
f0102f7e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f82:	75 f7                	jne    f0102f7b <vprintfmt+0x478>
f0102f84:	e9 a0 fb ff ff       	jmp    f0102b29 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f89:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f8c:	5b                   	pop    %ebx
f0102f8d:	5e                   	pop    %esi
f0102f8e:	5f                   	pop    %edi
f0102f8f:	5d                   	pop    %ebp
f0102f90:	c3                   	ret    

f0102f91 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f91:	55                   	push   %ebp
f0102f92:	89 e5                	mov    %esp,%ebp
f0102f94:	83 ec 18             	sub    $0x18,%esp
f0102f97:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f9a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f9d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fa0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fa4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fa7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fae:	85 c0                	test   %eax,%eax
f0102fb0:	74 26                	je     f0102fd8 <vsnprintf+0x47>
f0102fb2:	85 d2                	test   %edx,%edx
f0102fb4:	7e 22                	jle    f0102fd8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fb6:	ff 75 14             	pushl  0x14(%ebp)
f0102fb9:	ff 75 10             	pushl  0x10(%ebp)
f0102fbc:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fbf:	50                   	push   %eax
f0102fc0:	68 c9 2a 10 f0       	push   $0xf0102ac9
f0102fc5:	e8 39 fb ff ff       	call   f0102b03 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fca:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fcd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fd3:	83 c4 10             	add    $0x10,%esp
f0102fd6:	eb 05                	jmp    f0102fdd <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fd8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fdd:	c9                   	leave  
f0102fde:	c3                   	ret    

f0102fdf <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fdf:	55                   	push   %ebp
f0102fe0:	89 e5                	mov    %esp,%ebp
f0102fe2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fe5:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fe8:	50                   	push   %eax
f0102fe9:	ff 75 10             	pushl  0x10(%ebp)
f0102fec:	ff 75 0c             	pushl  0xc(%ebp)
f0102fef:	ff 75 08             	pushl  0x8(%ebp)
f0102ff2:	e8 9a ff ff ff       	call   f0102f91 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102ff7:	c9                   	leave  
f0102ff8:	c3                   	ret    

f0102ff9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102ff9:	55                   	push   %ebp
f0102ffa:	89 e5                	mov    %esp,%ebp
f0102ffc:	57                   	push   %edi
f0102ffd:	56                   	push   %esi
f0102ffe:	53                   	push   %ebx
f0102fff:	83 ec 0c             	sub    $0xc,%esp
f0103002:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103005:	85 c0                	test   %eax,%eax
f0103007:	74 11                	je     f010301a <readline+0x21>
		cprintf("%s", prompt);
f0103009:	83 ec 08             	sub    $0x8,%esp
f010300c:	50                   	push   %eax
f010300d:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0103012:	e8 d0 f6 ff ff       	call   f01026e7 <cprintf>
f0103017:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010301a:	83 ec 0c             	sub    $0xc,%esp
f010301d:	6a 00                	push   $0x0
f010301f:	e8 ef d5 ff ff       	call   f0100613 <iscons>
f0103024:	89 c7                	mov    %eax,%edi
f0103026:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103029:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010302e:	e8 cf d5 ff ff       	call   f0100602 <getchar>
f0103033:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103035:	85 c0                	test   %eax,%eax
f0103037:	79 18                	jns    f0103051 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103039:	83 ec 08             	sub    $0x8,%esp
f010303c:	50                   	push   %eax
f010303d:	68 e0 48 10 f0       	push   $0xf01048e0
f0103042:	e8 a0 f6 ff ff       	call   f01026e7 <cprintf>
			return NULL;
f0103047:	83 c4 10             	add    $0x10,%esp
f010304a:	b8 00 00 00 00       	mov    $0x0,%eax
f010304f:	eb 79                	jmp    f01030ca <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103051:	83 f8 08             	cmp    $0x8,%eax
f0103054:	0f 94 c2             	sete   %dl
f0103057:	83 f8 7f             	cmp    $0x7f,%eax
f010305a:	0f 94 c0             	sete   %al
f010305d:	08 c2                	or     %al,%dl
f010305f:	74 1a                	je     f010307b <readline+0x82>
f0103061:	85 f6                	test   %esi,%esi
f0103063:	7e 16                	jle    f010307b <readline+0x82>
			if (echoing)
f0103065:	85 ff                	test   %edi,%edi
f0103067:	74 0d                	je     f0103076 <readline+0x7d>
				cputchar('\b');
f0103069:	83 ec 0c             	sub    $0xc,%esp
f010306c:	6a 08                	push   $0x8
f010306e:	e8 7f d5 ff ff       	call   f01005f2 <cputchar>
f0103073:	83 c4 10             	add    $0x10,%esp
			i--;
f0103076:	83 ee 01             	sub    $0x1,%esi
f0103079:	eb b3                	jmp    f010302e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010307b:	83 fb 1f             	cmp    $0x1f,%ebx
f010307e:	7e 23                	jle    f01030a3 <readline+0xaa>
f0103080:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103086:	7f 1b                	jg     f01030a3 <readline+0xaa>
			if (echoing)
f0103088:	85 ff                	test   %edi,%edi
f010308a:	74 0c                	je     f0103098 <readline+0x9f>
				cputchar(c);
f010308c:	83 ec 0c             	sub    $0xc,%esp
f010308f:	53                   	push   %ebx
f0103090:	e8 5d d5 ff ff       	call   f01005f2 <cputchar>
f0103095:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103098:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f010309e:	8d 76 01             	lea    0x1(%esi),%esi
f01030a1:	eb 8b                	jmp    f010302e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030a3:	83 fb 0a             	cmp    $0xa,%ebx
f01030a6:	74 05                	je     f01030ad <readline+0xb4>
f01030a8:	83 fb 0d             	cmp    $0xd,%ebx
f01030ab:	75 81                	jne    f010302e <readline+0x35>
			if (echoing)
f01030ad:	85 ff                	test   %edi,%edi
f01030af:	74 0d                	je     f01030be <readline+0xc5>
				cputchar('\n');
f01030b1:	83 ec 0c             	sub    $0xc,%esp
f01030b4:	6a 0a                	push   $0xa
f01030b6:	e8 37 d5 ff ff       	call   f01005f2 <cputchar>
f01030bb:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030be:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01030c5:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01030ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030cd:	5b                   	pop    %ebx
f01030ce:	5e                   	pop    %esi
f01030cf:	5f                   	pop    %edi
f01030d0:	5d                   	pop    %ebp
f01030d1:	c3                   	ret    

f01030d2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030d2:	55                   	push   %ebp
f01030d3:	89 e5                	mov    %esp,%ebp
f01030d5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01030dd:	eb 03                	jmp    f01030e2 <strlen+0x10>
		n++;
f01030df:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030e2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030e6:	75 f7                	jne    f01030df <strlen+0xd>
		n++;
	return n;
}
f01030e8:	5d                   	pop    %ebp
f01030e9:	c3                   	ret    

f01030ea <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030ea:	55                   	push   %ebp
f01030eb:	89 e5                	mov    %esp,%ebp
f01030ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030f0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030f3:	ba 00 00 00 00       	mov    $0x0,%edx
f01030f8:	eb 03                	jmp    f01030fd <strnlen+0x13>
		n++;
f01030fa:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030fd:	39 c2                	cmp    %eax,%edx
f01030ff:	74 08                	je     f0103109 <strnlen+0x1f>
f0103101:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103105:	75 f3                	jne    f01030fa <strnlen+0x10>
f0103107:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103109:	5d                   	pop    %ebp
f010310a:	c3                   	ret    

f010310b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010310b:	55                   	push   %ebp
f010310c:	89 e5                	mov    %esp,%ebp
f010310e:	53                   	push   %ebx
f010310f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103112:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103115:	89 c2                	mov    %eax,%edx
f0103117:	83 c2 01             	add    $0x1,%edx
f010311a:	83 c1 01             	add    $0x1,%ecx
f010311d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103121:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103124:	84 db                	test   %bl,%bl
f0103126:	75 ef                	jne    f0103117 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103128:	5b                   	pop    %ebx
f0103129:	5d                   	pop    %ebp
f010312a:	c3                   	ret    

f010312b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010312b:	55                   	push   %ebp
f010312c:	89 e5                	mov    %esp,%ebp
f010312e:	53                   	push   %ebx
f010312f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103132:	53                   	push   %ebx
f0103133:	e8 9a ff ff ff       	call   f01030d2 <strlen>
f0103138:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010313b:	ff 75 0c             	pushl  0xc(%ebp)
f010313e:	01 d8                	add    %ebx,%eax
f0103140:	50                   	push   %eax
f0103141:	e8 c5 ff ff ff       	call   f010310b <strcpy>
	return dst;
}
f0103146:	89 d8                	mov    %ebx,%eax
f0103148:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010314b:	c9                   	leave  
f010314c:	c3                   	ret    

f010314d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010314d:	55                   	push   %ebp
f010314e:	89 e5                	mov    %esp,%ebp
f0103150:	56                   	push   %esi
f0103151:	53                   	push   %ebx
f0103152:	8b 75 08             	mov    0x8(%ebp),%esi
f0103155:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103158:	89 f3                	mov    %esi,%ebx
f010315a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010315d:	89 f2                	mov    %esi,%edx
f010315f:	eb 0f                	jmp    f0103170 <strncpy+0x23>
		*dst++ = *src;
f0103161:	83 c2 01             	add    $0x1,%edx
f0103164:	0f b6 01             	movzbl (%ecx),%eax
f0103167:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010316a:	80 39 01             	cmpb   $0x1,(%ecx)
f010316d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103170:	39 da                	cmp    %ebx,%edx
f0103172:	75 ed                	jne    f0103161 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103174:	89 f0                	mov    %esi,%eax
f0103176:	5b                   	pop    %ebx
f0103177:	5e                   	pop    %esi
f0103178:	5d                   	pop    %ebp
f0103179:	c3                   	ret    

f010317a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010317a:	55                   	push   %ebp
f010317b:	89 e5                	mov    %esp,%ebp
f010317d:	56                   	push   %esi
f010317e:	53                   	push   %ebx
f010317f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103182:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103185:	8b 55 10             	mov    0x10(%ebp),%edx
f0103188:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010318a:	85 d2                	test   %edx,%edx
f010318c:	74 21                	je     f01031af <strlcpy+0x35>
f010318e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103192:	89 f2                	mov    %esi,%edx
f0103194:	eb 09                	jmp    f010319f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103196:	83 c2 01             	add    $0x1,%edx
f0103199:	83 c1 01             	add    $0x1,%ecx
f010319c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010319f:	39 c2                	cmp    %eax,%edx
f01031a1:	74 09                	je     f01031ac <strlcpy+0x32>
f01031a3:	0f b6 19             	movzbl (%ecx),%ebx
f01031a6:	84 db                	test   %bl,%bl
f01031a8:	75 ec                	jne    f0103196 <strlcpy+0x1c>
f01031aa:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031ac:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031af:	29 f0                	sub    %esi,%eax
}
f01031b1:	5b                   	pop    %ebx
f01031b2:	5e                   	pop    %esi
f01031b3:	5d                   	pop    %ebp
f01031b4:	c3                   	ret    

f01031b5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031b5:	55                   	push   %ebp
f01031b6:	89 e5                	mov    %esp,%ebp
f01031b8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031be:	eb 06                	jmp    f01031c6 <strcmp+0x11>
		p++, q++;
f01031c0:	83 c1 01             	add    $0x1,%ecx
f01031c3:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031c6:	0f b6 01             	movzbl (%ecx),%eax
f01031c9:	84 c0                	test   %al,%al
f01031cb:	74 04                	je     f01031d1 <strcmp+0x1c>
f01031cd:	3a 02                	cmp    (%edx),%al
f01031cf:	74 ef                	je     f01031c0 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031d1:	0f b6 c0             	movzbl %al,%eax
f01031d4:	0f b6 12             	movzbl (%edx),%edx
f01031d7:	29 d0                	sub    %edx,%eax
}
f01031d9:	5d                   	pop    %ebp
f01031da:	c3                   	ret    

f01031db <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031db:	55                   	push   %ebp
f01031dc:	89 e5                	mov    %esp,%ebp
f01031de:	53                   	push   %ebx
f01031df:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031e5:	89 c3                	mov    %eax,%ebx
f01031e7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031ea:	eb 06                	jmp    f01031f2 <strncmp+0x17>
		n--, p++, q++;
f01031ec:	83 c0 01             	add    $0x1,%eax
f01031ef:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031f2:	39 d8                	cmp    %ebx,%eax
f01031f4:	74 15                	je     f010320b <strncmp+0x30>
f01031f6:	0f b6 08             	movzbl (%eax),%ecx
f01031f9:	84 c9                	test   %cl,%cl
f01031fb:	74 04                	je     f0103201 <strncmp+0x26>
f01031fd:	3a 0a                	cmp    (%edx),%cl
f01031ff:	74 eb                	je     f01031ec <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103201:	0f b6 00             	movzbl (%eax),%eax
f0103204:	0f b6 12             	movzbl (%edx),%edx
f0103207:	29 d0                	sub    %edx,%eax
f0103209:	eb 05                	jmp    f0103210 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010320b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103210:	5b                   	pop    %ebx
f0103211:	5d                   	pop    %ebp
f0103212:	c3                   	ret    

f0103213 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103213:	55                   	push   %ebp
f0103214:	89 e5                	mov    %esp,%ebp
f0103216:	8b 45 08             	mov    0x8(%ebp),%eax
f0103219:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010321d:	eb 07                	jmp    f0103226 <strchr+0x13>
		if (*s == c)
f010321f:	38 ca                	cmp    %cl,%dl
f0103221:	74 0f                	je     f0103232 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103223:	83 c0 01             	add    $0x1,%eax
f0103226:	0f b6 10             	movzbl (%eax),%edx
f0103229:	84 d2                	test   %dl,%dl
f010322b:	75 f2                	jne    f010321f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010322d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103232:	5d                   	pop    %ebp
f0103233:	c3                   	ret    

f0103234 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103234:	55                   	push   %ebp
f0103235:	89 e5                	mov    %esp,%ebp
f0103237:	8b 45 08             	mov    0x8(%ebp),%eax
f010323a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010323e:	eb 03                	jmp    f0103243 <strfind+0xf>
f0103240:	83 c0 01             	add    $0x1,%eax
f0103243:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103246:	38 ca                	cmp    %cl,%dl
f0103248:	74 04                	je     f010324e <strfind+0x1a>
f010324a:	84 d2                	test   %dl,%dl
f010324c:	75 f2                	jne    f0103240 <strfind+0xc>
			break;
	return (char *) s;
}
f010324e:	5d                   	pop    %ebp
f010324f:	c3                   	ret    

f0103250 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103250:	55                   	push   %ebp
f0103251:	89 e5                	mov    %esp,%ebp
f0103253:	57                   	push   %edi
f0103254:	56                   	push   %esi
f0103255:	53                   	push   %ebx
f0103256:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103259:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010325c:	85 c9                	test   %ecx,%ecx
f010325e:	74 36                	je     f0103296 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103260:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103266:	75 28                	jne    f0103290 <memset+0x40>
f0103268:	f6 c1 03             	test   $0x3,%cl
f010326b:	75 23                	jne    f0103290 <memset+0x40>
		c &= 0xFF;
f010326d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103271:	89 d3                	mov    %edx,%ebx
f0103273:	c1 e3 08             	shl    $0x8,%ebx
f0103276:	89 d6                	mov    %edx,%esi
f0103278:	c1 e6 18             	shl    $0x18,%esi
f010327b:	89 d0                	mov    %edx,%eax
f010327d:	c1 e0 10             	shl    $0x10,%eax
f0103280:	09 f0                	or     %esi,%eax
f0103282:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103284:	89 d8                	mov    %ebx,%eax
f0103286:	09 d0                	or     %edx,%eax
f0103288:	c1 e9 02             	shr    $0x2,%ecx
f010328b:	fc                   	cld    
f010328c:	f3 ab                	rep stos %eax,%es:(%edi)
f010328e:	eb 06                	jmp    f0103296 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103290:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103293:	fc                   	cld    
f0103294:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103296:	89 f8                	mov    %edi,%eax
f0103298:	5b                   	pop    %ebx
f0103299:	5e                   	pop    %esi
f010329a:	5f                   	pop    %edi
f010329b:	5d                   	pop    %ebp
f010329c:	c3                   	ret    

f010329d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010329d:	55                   	push   %ebp
f010329e:	89 e5                	mov    %esp,%ebp
f01032a0:	57                   	push   %edi
f01032a1:	56                   	push   %esi
f01032a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032ab:	39 c6                	cmp    %eax,%esi
f01032ad:	73 35                	jae    f01032e4 <memmove+0x47>
f01032af:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032b2:	39 d0                	cmp    %edx,%eax
f01032b4:	73 2e                	jae    f01032e4 <memmove+0x47>
		s += n;
		d += n;
f01032b6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032b9:	89 d6                	mov    %edx,%esi
f01032bb:	09 fe                	or     %edi,%esi
f01032bd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032c3:	75 13                	jne    f01032d8 <memmove+0x3b>
f01032c5:	f6 c1 03             	test   $0x3,%cl
f01032c8:	75 0e                	jne    f01032d8 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032ca:	83 ef 04             	sub    $0x4,%edi
f01032cd:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032d0:	c1 e9 02             	shr    $0x2,%ecx
f01032d3:	fd                   	std    
f01032d4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032d6:	eb 09                	jmp    f01032e1 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032d8:	83 ef 01             	sub    $0x1,%edi
f01032db:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032de:	fd                   	std    
f01032df:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032e1:	fc                   	cld    
f01032e2:	eb 1d                	jmp    f0103301 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032e4:	89 f2                	mov    %esi,%edx
f01032e6:	09 c2                	or     %eax,%edx
f01032e8:	f6 c2 03             	test   $0x3,%dl
f01032eb:	75 0f                	jne    f01032fc <memmove+0x5f>
f01032ed:	f6 c1 03             	test   $0x3,%cl
f01032f0:	75 0a                	jne    f01032fc <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032f2:	c1 e9 02             	shr    $0x2,%ecx
f01032f5:	89 c7                	mov    %eax,%edi
f01032f7:	fc                   	cld    
f01032f8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032fa:	eb 05                	jmp    f0103301 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032fc:	89 c7                	mov    %eax,%edi
f01032fe:	fc                   	cld    
f01032ff:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103301:	5e                   	pop    %esi
f0103302:	5f                   	pop    %edi
f0103303:	5d                   	pop    %ebp
f0103304:	c3                   	ret    

f0103305 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103305:	55                   	push   %ebp
f0103306:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103308:	ff 75 10             	pushl  0x10(%ebp)
f010330b:	ff 75 0c             	pushl  0xc(%ebp)
f010330e:	ff 75 08             	pushl  0x8(%ebp)
f0103311:	e8 87 ff ff ff       	call   f010329d <memmove>
}
f0103316:	c9                   	leave  
f0103317:	c3                   	ret    

f0103318 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103318:	55                   	push   %ebp
f0103319:	89 e5                	mov    %esp,%ebp
f010331b:	56                   	push   %esi
f010331c:	53                   	push   %ebx
f010331d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103320:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103323:	89 c6                	mov    %eax,%esi
f0103325:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103328:	eb 1a                	jmp    f0103344 <memcmp+0x2c>
		if (*s1 != *s2)
f010332a:	0f b6 08             	movzbl (%eax),%ecx
f010332d:	0f b6 1a             	movzbl (%edx),%ebx
f0103330:	38 d9                	cmp    %bl,%cl
f0103332:	74 0a                	je     f010333e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103334:	0f b6 c1             	movzbl %cl,%eax
f0103337:	0f b6 db             	movzbl %bl,%ebx
f010333a:	29 d8                	sub    %ebx,%eax
f010333c:	eb 0f                	jmp    f010334d <memcmp+0x35>
		s1++, s2++;
f010333e:	83 c0 01             	add    $0x1,%eax
f0103341:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103344:	39 f0                	cmp    %esi,%eax
f0103346:	75 e2                	jne    f010332a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103348:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010334d:	5b                   	pop    %ebx
f010334e:	5e                   	pop    %esi
f010334f:	5d                   	pop    %ebp
f0103350:	c3                   	ret    

f0103351 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103351:	55                   	push   %ebp
f0103352:	89 e5                	mov    %esp,%ebp
f0103354:	53                   	push   %ebx
f0103355:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103358:	89 c1                	mov    %eax,%ecx
f010335a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010335d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103361:	eb 0a                	jmp    f010336d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103363:	0f b6 10             	movzbl (%eax),%edx
f0103366:	39 da                	cmp    %ebx,%edx
f0103368:	74 07                	je     f0103371 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010336a:	83 c0 01             	add    $0x1,%eax
f010336d:	39 c8                	cmp    %ecx,%eax
f010336f:	72 f2                	jb     f0103363 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103371:	5b                   	pop    %ebx
f0103372:	5d                   	pop    %ebp
f0103373:	c3                   	ret    

f0103374 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103374:	55                   	push   %ebp
f0103375:	89 e5                	mov    %esp,%ebp
f0103377:	57                   	push   %edi
f0103378:	56                   	push   %esi
f0103379:	53                   	push   %ebx
f010337a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010337d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103380:	eb 03                	jmp    f0103385 <strtol+0x11>
		s++;
f0103382:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103385:	0f b6 01             	movzbl (%ecx),%eax
f0103388:	3c 20                	cmp    $0x20,%al
f010338a:	74 f6                	je     f0103382 <strtol+0xe>
f010338c:	3c 09                	cmp    $0x9,%al
f010338e:	74 f2                	je     f0103382 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103390:	3c 2b                	cmp    $0x2b,%al
f0103392:	75 0a                	jne    f010339e <strtol+0x2a>
		s++;
f0103394:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103397:	bf 00 00 00 00       	mov    $0x0,%edi
f010339c:	eb 11                	jmp    f01033af <strtol+0x3b>
f010339e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033a3:	3c 2d                	cmp    $0x2d,%al
f01033a5:	75 08                	jne    f01033af <strtol+0x3b>
		s++, neg = 1;
f01033a7:	83 c1 01             	add    $0x1,%ecx
f01033aa:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033af:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033b5:	75 15                	jne    f01033cc <strtol+0x58>
f01033b7:	80 39 30             	cmpb   $0x30,(%ecx)
f01033ba:	75 10                	jne    f01033cc <strtol+0x58>
f01033bc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033c0:	75 7c                	jne    f010343e <strtol+0xca>
		s += 2, base = 16;
f01033c2:	83 c1 02             	add    $0x2,%ecx
f01033c5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033ca:	eb 16                	jmp    f01033e2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033cc:	85 db                	test   %ebx,%ebx
f01033ce:	75 12                	jne    f01033e2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033d0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033d5:	80 39 30             	cmpb   $0x30,(%ecx)
f01033d8:	75 08                	jne    f01033e2 <strtol+0x6e>
		s++, base = 8;
f01033da:	83 c1 01             	add    $0x1,%ecx
f01033dd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01033e7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033ea:	0f b6 11             	movzbl (%ecx),%edx
f01033ed:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033f0:	89 f3                	mov    %esi,%ebx
f01033f2:	80 fb 09             	cmp    $0x9,%bl
f01033f5:	77 08                	ja     f01033ff <strtol+0x8b>
			dig = *s - '0';
f01033f7:	0f be d2             	movsbl %dl,%edx
f01033fa:	83 ea 30             	sub    $0x30,%edx
f01033fd:	eb 22                	jmp    f0103421 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033ff:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103402:	89 f3                	mov    %esi,%ebx
f0103404:	80 fb 19             	cmp    $0x19,%bl
f0103407:	77 08                	ja     f0103411 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103409:	0f be d2             	movsbl %dl,%edx
f010340c:	83 ea 57             	sub    $0x57,%edx
f010340f:	eb 10                	jmp    f0103421 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103411:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103414:	89 f3                	mov    %esi,%ebx
f0103416:	80 fb 19             	cmp    $0x19,%bl
f0103419:	77 16                	ja     f0103431 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010341b:	0f be d2             	movsbl %dl,%edx
f010341e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103421:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103424:	7d 0b                	jge    f0103431 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103426:	83 c1 01             	add    $0x1,%ecx
f0103429:	0f af 45 10          	imul   0x10(%ebp),%eax
f010342d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010342f:	eb b9                	jmp    f01033ea <strtol+0x76>

	if (endptr)
f0103431:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103435:	74 0d                	je     f0103444 <strtol+0xd0>
		*endptr = (char *) s;
f0103437:	8b 75 0c             	mov    0xc(%ebp),%esi
f010343a:	89 0e                	mov    %ecx,(%esi)
f010343c:	eb 06                	jmp    f0103444 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010343e:	85 db                	test   %ebx,%ebx
f0103440:	74 98                	je     f01033da <strtol+0x66>
f0103442:	eb 9e                	jmp    f01033e2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103444:	89 c2                	mov    %eax,%edx
f0103446:	f7 da                	neg    %edx
f0103448:	85 ff                	test   %edi,%edi
f010344a:	0f 45 c2             	cmovne %edx,%eax
}
f010344d:	5b                   	pop    %ebx
f010344e:	5e                   	pop    %esi
f010344f:	5f                   	pop    %edi
f0103450:	5d                   	pop    %ebp
f0103451:	c3                   	ret    
f0103452:	66 90                	xchg   %ax,%ax
f0103454:	66 90                	xchg   %ax,%ax
f0103456:	66 90                	xchg   %ax,%ax
f0103458:	66 90                	xchg   %ax,%ax
f010345a:	66 90                	xchg   %ax,%ax
f010345c:	66 90                	xchg   %ax,%ax
f010345e:	66 90                	xchg   %ax,%ax

f0103460 <__udivdi3>:
f0103460:	55                   	push   %ebp
f0103461:	57                   	push   %edi
f0103462:	56                   	push   %esi
f0103463:	53                   	push   %ebx
f0103464:	83 ec 1c             	sub    $0x1c,%esp
f0103467:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010346b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010346f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103473:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103477:	85 f6                	test   %esi,%esi
f0103479:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010347d:	89 ca                	mov    %ecx,%edx
f010347f:	89 f8                	mov    %edi,%eax
f0103481:	75 3d                	jne    f01034c0 <__udivdi3+0x60>
f0103483:	39 cf                	cmp    %ecx,%edi
f0103485:	0f 87 c5 00 00 00    	ja     f0103550 <__udivdi3+0xf0>
f010348b:	85 ff                	test   %edi,%edi
f010348d:	89 fd                	mov    %edi,%ebp
f010348f:	75 0b                	jne    f010349c <__udivdi3+0x3c>
f0103491:	b8 01 00 00 00       	mov    $0x1,%eax
f0103496:	31 d2                	xor    %edx,%edx
f0103498:	f7 f7                	div    %edi
f010349a:	89 c5                	mov    %eax,%ebp
f010349c:	89 c8                	mov    %ecx,%eax
f010349e:	31 d2                	xor    %edx,%edx
f01034a0:	f7 f5                	div    %ebp
f01034a2:	89 c1                	mov    %eax,%ecx
f01034a4:	89 d8                	mov    %ebx,%eax
f01034a6:	89 cf                	mov    %ecx,%edi
f01034a8:	f7 f5                	div    %ebp
f01034aa:	89 c3                	mov    %eax,%ebx
f01034ac:	89 d8                	mov    %ebx,%eax
f01034ae:	89 fa                	mov    %edi,%edx
f01034b0:	83 c4 1c             	add    $0x1c,%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	90                   	nop
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	39 ce                	cmp    %ecx,%esi
f01034c2:	77 74                	ja     f0103538 <__udivdi3+0xd8>
f01034c4:	0f bd fe             	bsr    %esi,%edi
f01034c7:	83 f7 1f             	xor    $0x1f,%edi
f01034ca:	0f 84 98 00 00 00    	je     f0103568 <__udivdi3+0x108>
f01034d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034d5:	89 f9                	mov    %edi,%ecx
f01034d7:	89 c5                	mov    %eax,%ebp
f01034d9:	29 fb                	sub    %edi,%ebx
f01034db:	d3 e6                	shl    %cl,%esi
f01034dd:	89 d9                	mov    %ebx,%ecx
f01034df:	d3 ed                	shr    %cl,%ebp
f01034e1:	89 f9                	mov    %edi,%ecx
f01034e3:	d3 e0                	shl    %cl,%eax
f01034e5:	09 ee                	or     %ebp,%esi
f01034e7:	89 d9                	mov    %ebx,%ecx
f01034e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034ed:	89 d5                	mov    %edx,%ebp
f01034ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034f3:	d3 ed                	shr    %cl,%ebp
f01034f5:	89 f9                	mov    %edi,%ecx
f01034f7:	d3 e2                	shl    %cl,%edx
f01034f9:	89 d9                	mov    %ebx,%ecx
f01034fb:	d3 e8                	shr    %cl,%eax
f01034fd:	09 c2                	or     %eax,%edx
f01034ff:	89 d0                	mov    %edx,%eax
f0103501:	89 ea                	mov    %ebp,%edx
f0103503:	f7 f6                	div    %esi
f0103505:	89 d5                	mov    %edx,%ebp
f0103507:	89 c3                	mov    %eax,%ebx
f0103509:	f7 64 24 0c          	mull   0xc(%esp)
f010350d:	39 d5                	cmp    %edx,%ebp
f010350f:	72 10                	jb     f0103521 <__udivdi3+0xc1>
f0103511:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	d3 e6                	shl    %cl,%esi
f0103519:	39 c6                	cmp    %eax,%esi
f010351b:	73 07                	jae    f0103524 <__udivdi3+0xc4>
f010351d:	39 d5                	cmp    %edx,%ebp
f010351f:	75 03                	jne    f0103524 <__udivdi3+0xc4>
f0103521:	83 eb 01             	sub    $0x1,%ebx
f0103524:	31 ff                	xor    %edi,%edi
f0103526:	89 d8                	mov    %ebx,%eax
f0103528:	89 fa                	mov    %edi,%edx
f010352a:	83 c4 1c             	add    $0x1c,%esp
f010352d:	5b                   	pop    %ebx
f010352e:	5e                   	pop    %esi
f010352f:	5f                   	pop    %edi
f0103530:	5d                   	pop    %ebp
f0103531:	c3                   	ret    
f0103532:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103538:	31 ff                	xor    %edi,%edi
f010353a:	31 db                	xor    %ebx,%ebx
f010353c:	89 d8                	mov    %ebx,%eax
f010353e:	89 fa                	mov    %edi,%edx
f0103540:	83 c4 1c             	add    $0x1c,%esp
f0103543:	5b                   	pop    %ebx
f0103544:	5e                   	pop    %esi
f0103545:	5f                   	pop    %edi
f0103546:	5d                   	pop    %ebp
f0103547:	c3                   	ret    
f0103548:	90                   	nop
f0103549:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103550:	89 d8                	mov    %ebx,%eax
f0103552:	f7 f7                	div    %edi
f0103554:	31 ff                	xor    %edi,%edi
f0103556:	89 c3                	mov    %eax,%ebx
f0103558:	89 d8                	mov    %ebx,%eax
f010355a:	89 fa                	mov    %edi,%edx
f010355c:	83 c4 1c             	add    $0x1c,%esp
f010355f:	5b                   	pop    %ebx
f0103560:	5e                   	pop    %esi
f0103561:	5f                   	pop    %edi
f0103562:	5d                   	pop    %ebp
f0103563:	c3                   	ret    
f0103564:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103568:	39 ce                	cmp    %ecx,%esi
f010356a:	72 0c                	jb     f0103578 <__udivdi3+0x118>
f010356c:	31 db                	xor    %ebx,%ebx
f010356e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103572:	0f 87 34 ff ff ff    	ja     f01034ac <__udivdi3+0x4c>
f0103578:	bb 01 00 00 00       	mov    $0x1,%ebx
f010357d:	e9 2a ff ff ff       	jmp    f01034ac <__udivdi3+0x4c>
f0103582:	66 90                	xchg   %ax,%ax
f0103584:	66 90                	xchg   %ax,%ax
f0103586:	66 90                	xchg   %ax,%ax
f0103588:	66 90                	xchg   %ax,%ax
f010358a:	66 90                	xchg   %ax,%ax
f010358c:	66 90                	xchg   %ax,%ax
f010358e:	66 90                	xchg   %ax,%ax

f0103590 <__umoddi3>:
f0103590:	55                   	push   %ebp
f0103591:	57                   	push   %edi
f0103592:	56                   	push   %esi
f0103593:	53                   	push   %ebx
f0103594:	83 ec 1c             	sub    $0x1c,%esp
f0103597:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010359b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010359f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035a7:	85 d2                	test   %edx,%edx
f01035a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035b1:	89 f3                	mov    %esi,%ebx
f01035b3:	89 3c 24             	mov    %edi,(%esp)
f01035b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035ba:	75 1c                	jne    f01035d8 <__umoddi3+0x48>
f01035bc:	39 f7                	cmp    %esi,%edi
f01035be:	76 50                	jbe    f0103610 <__umoddi3+0x80>
f01035c0:	89 c8                	mov    %ecx,%eax
f01035c2:	89 f2                	mov    %esi,%edx
f01035c4:	f7 f7                	div    %edi
f01035c6:	89 d0                	mov    %edx,%eax
f01035c8:	31 d2                	xor    %edx,%edx
f01035ca:	83 c4 1c             	add    $0x1c,%esp
f01035cd:	5b                   	pop    %ebx
f01035ce:	5e                   	pop    %esi
f01035cf:	5f                   	pop    %edi
f01035d0:	5d                   	pop    %ebp
f01035d1:	c3                   	ret    
f01035d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035d8:	39 f2                	cmp    %esi,%edx
f01035da:	89 d0                	mov    %edx,%eax
f01035dc:	77 52                	ja     f0103630 <__umoddi3+0xa0>
f01035de:	0f bd ea             	bsr    %edx,%ebp
f01035e1:	83 f5 1f             	xor    $0x1f,%ebp
f01035e4:	75 5a                	jne    f0103640 <__umoddi3+0xb0>
f01035e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035ea:	0f 82 e0 00 00 00    	jb     f01036d0 <__umoddi3+0x140>
f01035f0:	39 0c 24             	cmp    %ecx,(%esp)
f01035f3:	0f 86 d7 00 00 00    	jbe    f01036d0 <__umoddi3+0x140>
f01035f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103601:	83 c4 1c             	add    $0x1c,%esp
f0103604:	5b                   	pop    %ebx
f0103605:	5e                   	pop    %esi
f0103606:	5f                   	pop    %edi
f0103607:	5d                   	pop    %ebp
f0103608:	c3                   	ret    
f0103609:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103610:	85 ff                	test   %edi,%edi
f0103612:	89 fd                	mov    %edi,%ebp
f0103614:	75 0b                	jne    f0103621 <__umoddi3+0x91>
f0103616:	b8 01 00 00 00       	mov    $0x1,%eax
f010361b:	31 d2                	xor    %edx,%edx
f010361d:	f7 f7                	div    %edi
f010361f:	89 c5                	mov    %eax,%ebp
f0103621:	89 f0                	mov    %esi,%eax
f0103623:	31 d2                	xor    %edx,%edx
f0103625:	f7 f5                	div    %ebp
f0103627:	89 c8                	mov    %ecx,%eax
f0103629:	f7 f5                	div    %ebp
f010362b:	89 d0                	mov    %edx,%eax
f010362d:	eb 99                	jmp    f01035c8 <__umoddi3+0x38>
f010362f:	90                   	nop
f0103630:	89 c8                	mov    %ecx,%eax
f0103632:	89 f2                	mov    %esi,%edx
f0103634:	83 c4 1c             	add    $0x1c,%esp
f0103637:	5b                   	pop    %ebx
f0103638:	5e                   	pop    %esi
f0103639:	5f                   	pop    %edi
f010363a:	5d                   	pop    %ebp
f010363b:	c3                   	ret    
f010363c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103640:	8b 34 24             	mov    (%esp),%esi
f0103643:	bf 20 00 00 00       	mov    $0x20,%edi
f0103648:	89 e9                	mov    %ebp,%ecx
f010364a:	29 ef                	sub    %ebp,%edi
f010364c:	d3 e0                	shl    %cl,%eax
f010364e:	89 f9                	mov    %edi,%ecx
f0103650:	89 f2                	mov    %esi,%edx
f0103652:	d3 ea                	shr    %cl,%edx
f0103654:	89 e9                	mov    %ebp,%ecx
f0103656:	09 c2                	or     %eax,%edx
f0103658:	89 d8                	mov    %ebx,%eax
f010365a:	89 14 24             	mov    %edx,(%esp)
f010365d:	89 f2                	mov    %esi,%edx
f010365f:	d3 e2                	shl    %cl,%edx
f0103661:	89 f9                	mov    %edi,%ecx
f0103663:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103667:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010366b:	d3 e8                	shr    %cl,%eax
f010366d:	89 e9                	mov    %ebp,%ecx
f010366f:	89 c6                	mov    %eax,%esi
f0103671:	d3 e3                	shl    %cl,%ebx
f0103673:	89 f9                	mov    %edi,%ecx
f0103675:	89 d0                	mov    %edx,%eax
f0103677:	d3 e8                	shr    %cl,%eax
f0103679:	89 e9                	mov    %ebp,%ecx
f010367b:	09 d8                	or     %ebx,%eax
f010367d:	89 d3                	mov    %edx,%ebx
f010367f:	89 f2                	mov    %esi,%edx
f0103681:	f7 34 24             	divl   (%esp)
f0103684:	89 d6                	mov    %edx,%esi
f0103686:	d3 e3                	shl    %cl,%ebx
f0103688:	f7 64 24 04          	mull   0x4(%esp)
f010368c:	39 d6                	cmp    %edx,%esi
f010368e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103692:	89 d1                	mov    %edx,%ecx
f0103694:	89 c3                	mov    %eax,%ebx
f0103696:	72 08                	jb     f01036a0 <__umoddi3+0x110>
f0103698:	75 11                	jne    f01036ab <__umoddi3+0x11b>
f010369a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010369e:	73 0b                	jae    f01036ab <__umoddi3+0x11b>
f01036a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036a4:	1b 14 24             	sbb    (%esp),%edx
f01036a7:	89 d1                	mov    %edx,%ecx
f01036a9:	89 c3                	mov    %eax,%ebx
f01036ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036af:	29 da                	sub    %ebx,%edx
f01036b1:	19 ce                	sbb    %ecx,%esi
f01036b3:	89 f9                	mov    %edi,%ecx
f01036b5:	89 f0                	mov    %esi,%eax
f01036b7:	d3 e0                	shl    %cl,%eax
f01036b9:	89 e9                	mov    %ebp,%ecx
f01036bb:	d3 ea                	shr    %cl,%edx
f01036bd:	89 e9                	mov    %ebp,%ecx
f01036bf:	d3 ee                	shr    %cl,%esi
f01036c1:	09 d0                	or     %edx,%eax
f01036c3:	89 f2                	mov    %esi,%edx
f01036c5:	83 c4 1c             	add    $0x1c,%esp
f01036c8:	5b                   	pop    %ebx
f01036c9:	5e                   	pop    %esi
f01036ca:	5f                   	pop    %edi
f01036cb:	5d                   	pop    %ebp
f01036cc:	c3                   	ret    
f01036cd:	8d 76 00             	lea    0x0(%esi),%esi
f01036d0:	29 f9                	sub    %edi,%ecx
f01036d2:	19 d6                	sbb    %edx,%esi
f01036d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036dc:	e9 18 ff ff ff       	jmp    f01035f9 <__umoddi3+0x69>
