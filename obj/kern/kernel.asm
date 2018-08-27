
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
f0100058:	e8 61 33 00 00       	call   f01033be <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// 在此之前无法调用cprintf
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 38 10 f0       	push   $0xf0103860
f010006f:	e8 e1 27 00 00       	call   f0102855 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 e3 10 00 00       	call   f010115c <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 a2 08 00 00       	call   f0100928 <monitor>
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
f01000b0:	68 7b 38 10 f0       	push   $0xf010387b
f01000b5:	e8 9b 27 00 00       	call   f0102855 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 6b 27 00 00       	call   f010282f <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 49 41 10 f0 	movl   $0xf0104149,(%esp)
f01000cb:	e8 85 27 00 00       	call   f0102855 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 4b 08 00 00       	call   f0100928 <monitor>
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
f01000f2:	68 93 38 10 f0       	push   $0xf0103893
f01000f7:	e8 59 27 00 00       	call   f0102855 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 27 27 00 00       	call   f010282f <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 49 41 10 f0 	movl   $0xf0104149,(%esp)
f010010f:	e8 41 27 00 00       	call   f0102855 <cprintf>
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
f01001c6:	0f b6 82 00 3a 10 f0 	movzbl -0xfefc600(%edx),%eax
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
f0100202:	0f b6 82 00 3a 10 f0 	movzbl -0xfefc600(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a 00 39 10 f0 	movzbl -0xfefc700(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d e0 38 10 f0 	mov    -0xfefc720(,%ecx,4),%ecx
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
f0100260:	68 ad 38 10 f0       	push   $0xf01038ad
f0100265:	e8 eb 25 00 00       	call   f0102855 <cprintf>
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
f010040e:	e8 f8 2f 00 00       	call   f010340b <memmove>
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
f01005dd:	68 b9 38 10 f0       	push   $0xf01038b9
f01005e2:	e8 6e 22 00 00       	call   f0102855 <cprintf>
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
f0100620:	56                   	push   %esi
f0100621:	53                   	push   %ebx
f0100622:	bb a0 3e 10 f0       	mov    $0xf0103ea0,%ebx
f0100627:	be d0 3e 10 f0       	mov    $0xf0103ed0,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010062c:	83 ec 04             	sub    $0x4,%esp
f010062f:	ff 73 04             	pushl  0x4(%ebx)
f0100632:	ff 33                	pushl  (%ebx)
f0100634:	68 00 3b 10 f0       	push   $0xf0103b00
f0100639:	e8 17 22 00 00       	call   f0102855 <cprintf>
f010063e:	83 c3 0c             	add    $0xc,%ebx

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100641:	83 c4 10             	add    $0x10,%esp
f0100644:	39 f3                	cmp    %esi,%ebx
f0100646:	75 e4                	jne    f010062c <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100648:	b8 00 00 00 00       	mov    $0x0,%eax
f010064d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100650:	5b                   	pop    %ebx
f0100651:	5e                   	pop    %esi
f0100652:	5d                   	pop    %ebp
f0100653:	c3                   	ret    

f0100654 <mon_kerninfo>:

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100654:	55                   	push   %ebp
f0100655:	89 e5                	mov    %esp,%ebp
f0100657:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065a:	68 09 3b 10 f0       	push   $0xf0103b09
f010065f:	e8 f1 21 00 00       	call   f0102855 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100664:	83 c4 08             	add    $0x8,%esp
f0100667:	68 0c 00 10 00       	push   $0x10000c
f010066c:	68 f0 3b 10 f0       	push   $0xf0103bf0
f0100671:	e8 df 21 00 00       	call   f0102855 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100676:	83 c4 0c             	add    $0xc,%esp
f0100679:	68 0c 00 10 00       	push   $0x10000c
f010067e:	68 0c 00 10 f0       	push   $0xf010000c
f0100683:	68 18 3c 10 f0       	push   $0xf0103c18
f0100688:	e8 c8 21 00 00       	call   f0102855 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068d:	83 c4 0c             	add    $0xc,%esp
f0100690:	68 41 38 10 00       	push   $0x103841
f0100695:	68 41 38 10 f0       	push   $0xf0103841
f010069a:	68 3c 3c 10 f0       	push   $0xf0103c3c
f010069f:	e8 b1 21 00 00       	call   f0102855 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a4:	83 c4 0c             	add    $0xc,%esp
f01006a7:	68 00 73 11 00       	push   $0x117300
f01006ac:	68 00 73 11 f0       	push   $0xf0117300
f01006b1:	68 60 3c 10 f0       	push   $0xf0103c60
f01006b6:	e8 9a 21 00 00       	call   f0102855 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bb:	83 c4 0c             	add    $0xc,%esp
f01006be:	68 70 79 11 00       	push   $0x117970
f01006c3:	68 70 79 11 f0       	push   $0xf0117970
f01006c8:	68 84 3c 10 f0       	push   $0xf0103c84
f01006cd:	e8 83 21 00 00       	call   f0102855 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
f01006d2:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006d7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dc:	83 c4 08             	add    $0x8,%esp
f01006df:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e4:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006ea:	85 c0                	test   %eax,%eax
f01006ec:	0f 48 c2             	cmovs  %edx,%eax
f01006ef:	c1 f8 0a             	sar    $0xa,%eax
f01006f2:	50                   	push   %eax
f01006f3:	68 a8 3c 10 f0       	push   $0xf0103ca8
f01006f8:	e8 58 21 00 00       	call   f0102855 <cprintf>
			ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100702:	c9                   	leave  
f0100703:	c3                   	ret    

f0100704 <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100704:	55                   	push   %ebp
f0100705:	89 e5                	mov    %esp,%ebp
f0100707:	57                   	push   %edi
f0100708:	56                   	push   %esi
f0100709:	53                   	push   %ebx
f010070a:	83 ec 58             	sub    $0x58,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010070d:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
f010070f:	68 22 3b 10 f0       	push   $0xf0103b22
f0100714:	e8 3c 21 00 00       	call   f0102855 <cprintf>
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f0100719:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);
f010071c:	8d 75 d0             	lea    -0x30(%ebp),%esi
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f010071f:	eb 70                	jmp    f0100791 <mon_backtrace+0x8d>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
f0100721:	ff 73 18             	pushl  0x18(%ebx)
f0100724:	ff 73 14             	pushl  0x14(%ebx)
f0100727:	ff 73 10             	pushl  0x10(%ebx)
f010072a:	ff 73 0c             	pushl  0xc(%ebx)
f010072d:	ff 73 08             	pushl  0x8(%ebx)
f0100730:	ff 73 04             	pushl  0x4(%ebx)
f0100733:	53                   	push   %ebx
f0100734:	68 d4 3c 10 f0       	push   $0xf0103cd4
f0100739:	e8 17 21 00 00       	call   f0102855 <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f010073e:	83 c4 18             	add    $0x18,%esp
f0100741:	56                   	push   %esi
f0100742:	ff 73 04             	pushl  0x4(%ebx)
f0100745:	e8 15 22 00 00       	call   f010295f <debuginfo_eip>

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f010074a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			fn_name[i]=info.eip_fn_name[i];
f010074d:	8b 7d d8             	mov    -0x28(%ebp),%edi
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100750:	83 c4 10             	add    $0x10,%esp
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	eb 0b                	jmp    f0100765 <mon_backtrace+0x61>
			fn_name[i]=info.eip_fn_name[i];
f010075a:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
f010075e:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100762:	83 c0 01             	add    $0x1,%eax
f0100765:	39 c8                	cmp    %ecx,%eax
f0100767:	7c f1                	jl     f010075a <mon_backtrace+0x56>
			fn_name[i]=info.eip_fn_name[i];
		}
		fn_name[info.eip_fn_namelen]=0;
f0100769:	c6 44 0d b2 00       	movb   $0x0,-0x4e(%ebp,%ecx,1)
		int off = ebp[1]-info.eip_fn_addr;
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
f010076e:	83 ec 0c             	sub    $0xc,%esp
f0100771:	8b 43 04             	mov    0x4(%ebx),%eax
f0100774:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100777:	50                   	push   %eax
f0100778:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f010077b:	50                   	push   %eax
f010077c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010077f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100782:	68 34 3b 10 f0       	push   $0xf0103b34
f0100787:	e8 c9 20 00 00       	call   f0102855 <cprintf>
		ebp = (int*)(*ebp);
f010078c:	8b 1b                	mov    (%ebx),%ebx
f010078e:	83 c4 20             	add    $0x20,%esp
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f0100791:	85 db                	test   %ebx,%ebx
f0100793:	75 8c                	jne    f0100721 <mon_backtrace+0x1d>
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
		ebp = (int*)(*ebp);
	}

	return 0;
}
f0100795:	b8 00 00 00 00       	mov    $0x0,%eax
f010079a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010079d:	5b                   	pop    %ebx
f010079e:	5e                   	pop    %esi
f010079f:	5f                   	pop    %edi
f01007a0:	5d                   	pop    %ebp
f01007a1:	c3                   	ret    

f01007a2 <mon_showmappings>:

// 显示虚拟地址映射命令
int mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	57                   	push   %edi
f01007a6:	56                   	push   %esi
f01007a7:	53                   	push   %ebx
f01007a8:	83 ec 1c             	sub    $0x1c,%esp
f01007ab:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Your code here.
	if (argc != 3) {
f01007ae:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f01007b2:	74 1a                	je     f01007ce <mon_showmappings+0x2c>
		cprintf("Requir 2 virtual address as arguments.\n");
f01007b4:	83 ec 0c             	sub    $0xc,%esp
f01007b7:	68 08 3d 10 f0       	push   $0xf0103d08
f01007bc:	e8 94 20 00 00       	call   f0102855 <cprintf>
		return -1;
f01007c1:	83 c4 10             	add    $0x10,%esp
f01007c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01007c9:	e9 52 01 00 00       	jmp    f0100920 <mon_showmappings+0x17e>
	}
	char *errChar;
	uint32_t s = strtol(argv[1],&errChar,16);
f01007ce:	83 ec 04             	sub    $0x4,%esp
f01007d1:	6a 10                	push   $0x10
f01007d3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01007d6:	50                   	push   %eax
f01007d7:	ff 76 04             	pushl  0x4(%esi)
f01007da:	e8 03 2d 00 00       	call   f01034e2 <strtol>
f01007df:	89 c3                	mov    %eax,%ebx
	if (*errChar) {
f01007e1:	83 c4 10             	add    $0x10,%esp
f01007e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007e7:	80 38 00             	cmpb   $0x0,(%eax)
f01007ea:	74 1d                	je     f0100809 <mon_showmappings+0x67>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f01007ec:	83 ec 08             	sub    $0x8,%esp
f01007ef:	ff 76 04             	pushl  0x4(%esi)
f01007f2:	68 43 3b 10 f0       	push   $0xf0103b43
f01007f7:	e8 59 20 00 00       	call   f0102855 <cprintf>
		return -1;
f01007fc:	83 c4 10             	add    $0x10,%esp
f01007ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100804:	e9 17 01 00 00       	jmp    f0100920 <mon_showmappings+0x17e>
	}
	uint32_t e = strtol(argv[2],&errChar,16);
f0100809:	83 ec 04             	sub    $0x4,%esp
f010080c:	6a 10                	push   $0x10
f010080e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100811:	50                   	push   %eax
f0100812:	ff 76 08             	pushl  0x8(%esi)
f0100815:	e8 c8 2c 00 00       	call   f01034e2 <strtol>
	if(*errChar){
f010081a:	83 c4 10             	add    $0x10,%esp
f010081d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100820:	80 3a 00             	cmpb   $0x0,(%edx)
f0100823:	74 1d                	je     f0100842 <mon_showmappings+0xa0>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f0100825:	83 ec 08             	sub    $0x8,%esp
f0100828:	ff 76 04             	pushl  0x4(%esi)
f010082b:	68 43 3b 10 f0       	push   $0xf0103b43
f0100830:	e8 20 20 00 00       	call   f0102855 <cprintf>
		return -1;
f0100835:	83 c4 10             	add    $0x10,%esp
f0100838:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010083d:	e9 de 00 00 00       	jmp    f0100920 <mon_showmappings+0x17e>
	}
	if (s > e) {
f0100842:	39 c3                	cmp    %eax,%ebx
f0100844:	76 1a                	jbe    f0100860 <mon_showmappings+0xbe>
		cprintf("Address 1 must be lower than address 2\n");
f0100846:	83 ec 0c             	sub    $0xc,%esp
f0100849:	68 30 3d 10 f0       	push   $0xf0103d30
f010084e:	e8 02 20 00 00       	call   f0102855 <cprintf>
		return -1;
f0100853:	83 c4 10             	add    $0x10,%esp
f0100856:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010085b:	e9 c0 00 00 00       	jmp    f0100920 <mon_showmappings+0x17e>
	}
	s = ROUNDDOWN(s,PGSIZE);
f0100860:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	e = ROUNDUP(e,PGSIZE);
f0100866:	8d b8 ff 0f 00 00    	lea    0xfff(%eax),%edi
f010086c:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for(uint32_t i = s;i<=e;i+=PGSIZE){
f0100872:	e9 9c 00 00 00       	jmp    f0100913 <mon_showmappings+0x171>
		uint32_t *entry = pgdir_walk(kern_pgdir,(uint32_t*)i,0);
f0100877:	83 ec 04             	sub    $0x4,%esp
f010087a:	6a 00                	push   $0x0
f010087c:	53                   	push   %ebx
f010087d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0100883:	e8 de 06 00 00       	call   f0100f66 <pgdir_walk>
f0100888:	89 c6                	mov    %eax,%esi
		if(entry==NULL||!(*entry&PTE_P)){
f010088a:	83 c4 10             	add    $0x10,%esp
f010088d:	85 c0                	test   %eax,%eax
f010088f:	74 06                	je     f0100897 <mon_showmappings+0xf5>
f0100891:	8b 00                	mov    (%eax),%eax
f0100893:	a8 01                	test   $0x1,%al
f0100895:	75 13                	jne    f01008aa <mon_showmappings+0x108>
			cprintf( "Virtual address [%08x] - not mapped\n", i);
f0100897:	83 ec 08             	sub    $0x8,%esp
f010089a:	53                   	push   %ebx
f010089b:	68 58 3d 10 f0       	push   $0xf0103d58
f01008a0:	e8 b0 1f 00 00       	call   f0102855 <cprintf>
			continue;
f01008a5:	83 c4 10             	add    $0x10,%esp
f01008a8:	eb 63                	jmp    f010090d <mon_showmappings+0x16b>
		}
		cprintf( "Virtual address [%08x] - physical address [%08x], permission: ", entry, PTE_ADDR(*entry));
f01008aa:	83 ec 04             	sub    $0x4,%esp
f01008ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008b2:	50                   	push   %eax
f01008b3:	56                   	push   %esi
f01008b4:	68 80 3d 10 f0       	push   $0xf0103d80
f01008b9:	e8 97 1f 00 00       	call   f0102855 <cprintf>
		char perm_PS = (*entry & PTE_PS) ? 'S':'-';
f01008be:	8b 06                	mov    (%esi),%eax
f01008c0:	83 c4 10             	add    $0x10,%esp
f01008c3:	89 c2                	mov    %eax,%edx
f01008c5:	81 e2 80 00 00 00    	and    $0x80,%edx
f01008cb:	83 fa 01             	cmp    $0x1,%edx
f01008ce:	19 d2                	sbb    %edx,%edx
f01008d0:	83 e2 da             	and    $0xffffffda,%edx
f01008d3:	83 c2 53             	add    $0x53,%edx
		char perm_W = (*entry & PTE_W) ? 'W':'-';
f01008d6:	89 c1                	mov    %eax,%ecx
f01008d8:	83 e1 02             	and    $0x2,%ecx
f01008db:	83 f9 01             	cmp    $0x1,%ecx
f01008de:	19 c9                	sbb    %ecx,%ecx
f01008e0:	83 e1 d6             	and    $0xffffffd6,%ecx
f01008e3:	83 c1 57             	add    $0x57,%ecx
		char perm_U = (*entry & PTE_U) ? 'U':'-';
f01008e6:	83 e0 04             	and    $0x4,%eax
f01008e9:	83 f8 01             	cmp    $0x1,%eax
f01008ec:	19 c0                	sbb    %eax,%eax
f01008ee:	83 e0 d8             	and    $0xffffffd8,%eax
f01008f1:	83 c0 55             	add    $0x55,%eax
		// 进入 else 分支说明 PTE_P 肯定为真了
		cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
f01008f4:	0f be c9             	movsbl %cl,%ecx
f01008f7:	51                   	push   %ecx
f01008f8:	0f be c0             	movsbl %al,%eax
f01008fb:	50                   	push   %eax
f01008fc:	0f be d2             	movsbl %dl,%edx
f01008ff:	52                   	push   %edx
f0100900:	68 61 3b 10 f0       	push   $0xf0103b61
f0100905:	e8 4b 1f 00 00       	call   f0102855 <cprintf>
f010090a:	83 c4 10             	add    $0x10,%esp
		cprintf("Address 1 must be lower than address 2\n");
		return -1;
	}
	s = ROUNDDOWN(s,PGSIZE);
	e = ROUNDUP(e,PGSIZE);
	for(uint32_t i = s;i<=e;i+=PGSIZE){
f010090d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100913:	39 fb                	cmp    %edi,%ebx
f0100915:	0f 86 5c ff ff ff    	jbe    f0100877 <mon_showmappings+0xd5>
		char perm_U = (*entry & PTE_U) ? 'U':'-';
		// 进入 else 分支说明 PTE_P 肯定为真了
		cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
	}

	return 0;
f010091b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100920:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100923:	5b                   	pop    %ebx
f0100924:	5e                   	pop    %esi
f0100925:	5f                   	pop    %edi
f0100926:	5d                   	pop    %ebp
f0100927:	c3                   	ret    

f0100928 <monitor>:
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
f0100928:	55                   	push   %ebp
f0100929:	89 e5                	mov    %esp,%ebp
f010092b:	57                   	push   %edi
f010092c:	56                   	push   %esi
f010092d:	53                   	push   %ebx
f010092e:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100931:	68 c0 3d 10 f0       	push   $0xf0103dc0
f0100936:	e8 1a 1f 00 00       	call   f0102855 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010093b:	c7 04 24 e4 3d 10 f0 	movl   $0xf0103de4,(%esp)
f0100942:	e8 0e 1f 00 00       	call   f0102855 <cprintf>
f0100947:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f010094a:	83 ec 0c             	sub    $0xc,%esp
f010094d:	68 6f 3b 10 f0       	push   $0xf0103b6f
f0100952:	e8 10 28 00 00       	call   f0103167 <readline>
f0100957:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100959:	83 c4 10             	add    $0x10,%esp
f010095c:	85 c0                	test   %eax,%eax
f010095e:	74 ea                	je     f010094a <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100960:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100967:	be 00 00 00 00       	mov    $0x0,%esi
f010096c:	eb 0a                	jmp    f0100978 <monitor+0x50>
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010096e:	c6 03 00             	movb   $0x0,(%ebx)
f0100971:	89 f7                	mov    %esi,%edi
f0100973:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100976:	89 fe                	mov    %edi,%esi
	argc = 0;
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100978:	0f b6 03             	movzbl (%ebx),%eax
f010097b:	84 c0                	test   %al,%al
f010097d:	74 63                	je     f01009e2 <monitor+0xba>
f010097f:	83 ec 08             	sub    $0x8,%esp
f0100982:	0f be c0             	movsbl %al,%eax
f0100985:	50                   	push   %eax
f0100986:	68 73 3b 10 f0       	push   $0xf0103b73
f010098b:	e8 f1 29 00 00       	call   f0103381 <strchr>
f0100990:	83 c4 10             	add    $0x10,%esp
f0100993:	85 c0                	test   %eax,%eax
f0100995:	75 d7                	jne    f010096e <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100997:	80 3b 00             	cmpb   $0x0,(%ebx)
f010099a:	74 46                	je     f01009e2 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1)
f010099c:	83 fe 0f             	cmp    $0xf,%esi
f010099f:	75 14                	jne    f01009b5 <monitor+0x8d>
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009a1:	83 ec 08             	sub    $0x8,%esp
f01009a4:	6a 10                	push   $0x10
f01009a6:	68 78 3b 10 f0       	push   $0xf0103b78
f01009ab:	e8 a5 1e 00 00       	call   f0102855 <cprintf>
f01009b0:	83 c4 10             	add    $0x10,%esp
f01009b3:	eb 95                	jmp    f010094a <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01009b5:	8d 7e 01             	lea    0x1(%esi),%edi
f01009b8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009bc:	eb 03                	jmp    f01009c1 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009be:	83 c3 01             	add    $0x1,%ebx
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009c1:	0f b6 03             	movzbl (%ebx),%eax
f01009c4:	84 c0                	test   %al,%al
f01009c6:	74 ae                	je     f0100976 <monitor+0x4e>
f01009c8:	83 ec 08             	sub    $0x8,%esp
f01009cb:	0f be c0             	movsbl %al,%eax
f01009ce:	50                   	push   %eax
f01009cf:	68 73 3b 10 f0       	push   $0xf0103b73
f01009d4:	e8 a8 29 00 00       	call   f0103381 <strchr>
f01009d9:	83 c4 10             	add    $0x10,%esp
f01009dc:	85 c0                	test   %eax,%eax
f01009de:	74 de                	je     f01009be <monitor+0x96>
f01009e0:	eb 94                	jmp    f0100976 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01009e2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009e9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009ea:	85 f6                	test   %esi,%esi
f01009ec:	0f 84 58 ff ff ff    	je     f010094a <monitor+0x22>
f01009f2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
	{
		if (strcmp(argv[0], commands[i].name) == 0)
f01009f7:	83 ec 08             	sub    $0x8,%esp
f01009fa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009fd:	ff 34 85 a0 3e 10 f0 	pushl  -0xfefc160(,%eax,4)
f0100a04:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a07:	e8 17 29 00 00       	call   f0103323 <strcmp>
f0100a0c:	83 c4 10             	add    $0x10,%esp
f0100a0f:	85 c0                	test   %eax,%eax
f0100a11:	75 21                	jne    f0100a34 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100a13:	83 ec 04             	sub    $0x4,%esp
f0100a16:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a19:	ff 75 08             	pushl  0x8(%ebp)
f0100a1c:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a1f:	52                   	push   %edx
f0100a20:	56                   	push   %esi
f0100a21:	ff 14 85 a8 3e 10 f0 	call   *-0xfefc158(,%eax,4)

	while (1)
	{
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a28:	83 c4 10             	add    $0x10,%esp
f0100a2b:	85 c0                	test   %eax,%eax
f0100a2d:	78 25                	js     f0100a54 <monitor+0x12c>
f0100a2f:	e9 16 ff ff ff       	jmp    f010094a <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
f0100a34:	83 c3 01             	add    $0x1,%ebx
f0100a37:	83 fb 04             	cmp    $0x4,%ebx
f0100a3a:	75 bb                	jne    f01009f7 <monitor+0xcf>
	{
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a3c:	83 ec 08             	sub    $0x8,%esp
f0100a3f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a42:	68 95 3b 10 f0       	push   $0xf0103b95
f0100a47:	e8 09 1e 00 00       	call   f0102855 <cprintf>
f0100a4c:	83 c4 10             	add    $0x10,%esp
f0100a4f:	e9 f6 fe ff ff       	jmp    f010094a <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a54:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a57:	5b                   	pop    %ebx
f0100a58:	5e                   	pop    %esi
f0100a59:	5f                   	pop    %edi
f0100a5a:	5d                   	pop    %ebp
f0100a5b:	c3                   	ret    

f0100a5c <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a5c:	55                   	push   %ebp
f0100a5d:	89 e5                	mov    %esp,%ebp
f0100a5f:	53                   	push   %ebx
f0100a60:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f0100a63:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100a6a:	75 11                	jne    f0100a7d <boot_alloc+0x21>
	{
		extern char end[];
		nextfree = ROUNDUP((char *)end, PGSIZE);
f0100a6c:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100a71:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a77:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a7d:	8b 1d 38 75 11 f0    	mov    0xf0117538,%ebx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100a83:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f0100a8a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a90:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	if ((int)nextfree - KERNBASE > npages * PGSIZE)
f0100a96:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100a9c:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0100aa2:	c1 e1 0c             	shl    $0xc,%ecx
f0100aa5:	39 ca                	cmp    %ecx,%edx
f0100aa7:	76 14                	jbe    f0100abd <boot_alloc+0x61>
	{
		panic("Out of memory!\n");
f0100aa9:	83 ec 04             	sub    $0x4,%esp
f0100aac:	68 d0 3e 10 f0       	push   $0xf0103ed0
f0100ab1:	6a 68                	push   $0x68
f0100ab3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100ab8:	e8 ce f5 ff ff       	call   f010008b <_panic>
	}

	return result;
}
f0100abd:	89 d8                	mov    %ebx,%eax
f0100abf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ac2:	c9                   	leave  
f0100ac3:	c3                   	ret    

f0100ac4 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ac4:	89 d1                	mov    %edx,%ecx
f0100ac6:	c1 e9 16             	shr    $0x16,%ecx
f0100ac9:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100acc:	a8 01                	test   $0x1,%al
f0100ace:	74 52                	je     f0100b22 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100ad0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad5:	89 c1                	mov    %eax,%ecx
f0100ad7:	c1 e9 0c             	shr    $0xc,%ecx
f0100ada:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100ae0:	72 1b                	jb     f0100afd <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ae2:	55                   	push   %ebp
f0100ae3:	89 e5                	mov    %esp,%ebp
f0100ae5:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae8:	50                   	push   %eax
f0100ae9:	68 7c 41 10 f0       	push   $0xf010417c
f0100aee:	68 ea 02 00 00       	push   $0x2ea
f0100af3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100af8:	e8 8e f5 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100afd:	c1 ea 0c             	shr    $0xc,%edx
f0100b00:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b06:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b0d:	89 c2                	mov    %eax,%edx
f0100b0f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b17:	85 d2                	test   %edx,%edx
f0100b19:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b1e:	0f 44 c2             	cmove  %edx,%eax
f0100b21:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b27:	c3                   	ret    

f0100b28 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b28:	55                   	push   %ebp
f0100b29:	89 e5                	mov    %esp,%ebp
f0100b2b:	57                   	push   %edi
f0100b2c:	56                   	push   %esi
f0100b2d:	53                   	push   %ebx
f0100b2e:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b31:	84 c0                	test   %al,%al
f0100b33:	0f 85 72 02 00 00    	jne    f0100dab <check_page_free_list+0x283>
f0100b39:	e9 7f 02 00 00       	jmp    f0100dbd <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b3e:	83 ec 04             	sub    $0x4,%esp
f0100b41:	68 a0 41 10 f0       	push   $0xf01041a0
f0100b46:	68 27 02 00 00       	push   $0x227
f0100b4b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100b50:	e8 36 f5 ff ff       	call   f010008b <_panic>
	if (only_low_memory)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100b55:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b58:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b5b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b5e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link)
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b61:	89 c2                	mov    %eax,%edx
f0100b63:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100b69:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b6f:	0f 95 c2             	setne  %dl
f0100b72:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b75:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b79:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b7b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b7f:	8b 00                	mov    (%eax),%eax
f0100b81:	85 c0                	test   %eax,%eax
f0100b83:	75 dc                	jne    f0100b61 <check_page_free_list+0x39>
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b91:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b94:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b96:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b99:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b9e:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba3:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ba9:	eb 53                	jmp    f0100bfe <check_page_free_list+0xd6>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100bab:	89 d8                	mov    %ebx,%eax
f0100bad:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100bb3:	c1 f8 03             	sar    $0x3,%eax
f0100bb6:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bb9:	89 c2                	mov    %eax,%edx
f0100bbb:	c1 ea 16             	shr    $0x16,%edx
f0100bbe:	39 f2                	cmp    %esi,%edx
f0100bc0:	73 3a                	jae    f0100bfc <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bc2:	89 c2                	mov    %eax,%edx
f0100bc4:	c1 ea 0c             	shr    $0xc,%edx
f0100bc7:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100bcd:	72 12                	jb     f0100be1 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bcf:	50                   	push   %eax
f0100bd0:	68 7c 41 10 f0       	push   $0xf010417c
f0100bd5:	6a 57                	push   $0x57
f0100bd7:	68 ec 3e 10 f0       	push   $0xf0103eec
f0100bdc:	e8 aa f4 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100be1:	83 ec 04             	sub    $0x4,%esp
f0100be4:	68 80 00 00 00       	push   $0x80
f0100be9:	68 97 00 00 00       	push   $0x97
f0100bee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bf3:	50                   	push   %eax
f0100bf4:	e8 c5 27 00 00       	call   f01033be <memset>
f0100bf9:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bfc:	8b 1b                	mov    (%ebx),%ebx
f0100bfe:	85 db                	test   %ebx,%ebx
f0100c00:	75 a9                	jne    f0100bab <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
f0100c02:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c07:	e8 50 fe ff ff       	call   f0100a5c <boot_alloc>
f0100c0c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c0f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c15:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100c1b:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100c20:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c23:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c26:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c29:	be 00 00 00 00       	mov    $0x0,%esi
f0100c2e:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c31:	e9 30 01 00 00       	jmp    f0100d66 <check_page_free_list+0x23e>
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c36:	39 ca                	cmp    %ecx,%edx
f0100c38:	73 19                	jae    f0100c53 <check_page_free_list+0x12b>
f0100c3a:	68 fa 3e 10 f0       	push   $0xf0103efa
f0100c3f:	68 06 3f 10 f0       	push   $0xf0103f06
f0100c44:	68 44 02 00 00       	push   $0x244
f0100c49:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100c4e:	e8 38 f4 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100c53:	39 fa                	cmp    %edi,%edx
f0100c55:	72 19                	jb     f0100c70 <check_page_free_list+0x148>
f0100c57:	68 1b 3f 10 f0       	push   $0xf0103f1b
f0100c5c:	68 06 3f 10 f0       	push   $0xf0103f06
f0100c61:	68 45 02 00 00       	push   $0x245
f0100c66:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100c6b:	e8 1b f4 ff ff       	call   f010008b <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c70:	89 d0                	mov    %edx,%eax
f0100c72:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c75:	a8 07                	test   $0x7,%al
f0100c77:	74 19                	je     f0100c92 <check_page_free_list+0x16a>
f0100c79:	68 c4 41 10 f0       	push   $0xf01041c4
f0100c7e:	68 06 3f 10 f0       	push   $0xf0103f06
f0100c83:	68 46 02 00 00       	push   $0x246
f0100c88:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100c8d:	e8 f9 f3 ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100c92:	c1 f8 03             	sar    $0x3,%eax
f0100c95:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c98:	85 c0                	test   %eax,%eax
f0100c9a:	75 19                	jne    f0100cb5 <check_page_free_list+0x18d>
f0100c9c:	68 2f 3f 10 f0       	push   $0xf0103f2f
f0100ca1:	68 06 3f 10 f0       	push   $0xf0103f06
f0100ca6:	68 49 02 00 00       	push   $0x249
f0100cab:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100cb0:	e8 d6 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cb5:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cba:	75 19                	jne    f0100cd5 <check_page_free_list+0x1ad>
f0100cbc:	68 40 3f 10 f0       	push   $0xf0103f40
f0100cc1:	68 06 3f 10 f0       	push   $0xf0103f06
f0100cc6:	68 4a 02 00 00       	push   $0x24a
f0100ccb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100cd0:	e8 b6 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cd5:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cda:	75 19                	jne    f0100cf5 <check_page_free_list+0x1cd>
f0100cdc:	68 f4 41 10 f0       	push   $0xf01041f4
f0100ce1:	68 06 3f 10 f0       	push   $0xf0103f06
f0100ce6:	68 4b 02 00 00       	push   $0x24b
f0100ceb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100cf0:	e8 96 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cf5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cfa:	75 19                	jne    f0100d15 <check_page_free_list+0x1ed>
f0100cfc:	68 59 3f 10 f0       	push   $0xf0103f59
f0100d01:	68 06 3f 10 f0       	push   $0xf0103f06
f0100d06:	68 4c 02 00 00       	push   $0x24c
f0100d0b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100d10:	e8 76 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100d15:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d1a:	76 3f                	jbe    f0100d5b <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d1c:	89 c3                	mov    %eax,%ebx
f0100d1e:	c1 eb 0c             	shr    $0xc,%ebx
f0100d21:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d24:	77 12                	ja     f0100d38 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d26:	50                   	push   %eax
f0100d27:	68 7c 41 10 f0       	push   $0xf010417c
f0100d2c:	6a 57                	push   $0x57
f0100d2e:	68 ec 3e 10 f0       	push   $0xf0103eec
f0100d33:	e8 53 f3 ff ff       	call   f010008b <_panic>
f0100d38:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d3d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d40:	76 1e                	jbe    f0100d60 <check_page_free_list+0x238>
f0100d42:	68 18 42 10 f0       	push   $0xf0104218
f0100d47:	68 06 3f 10 f0       	push   $0xf0103f06
f0100d4c:	68 4d 02 00 00       	push   $0x24d
f0100d51:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100d56:	e8 30 f3 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d5b:	83 c6 01             	add    $0x1,%esi
f0100d5e:	eb 04                	jmp    f0100d64 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100d60:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d64:	8b 12                	mov    (%edx),%edx
f0100d66:	85 d2                	test   %edx,%edx
f0100d68:	0f 85 c8 fe ff ff    	jne    f0100c36 <check_page_free_list+0x10e>
f0100d6e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d71:	85 f6                	test   %esi,%esi
f0100d73:	7f 19                	jg     f0100d8e <check_page_free_list+0x266>
f0100d75:	68 73 3f 10 f0       	push   $0xf0103f73
f0100d7a:	68 06 3f 10 f0       	push   $0xf0103f06
f0100d7f:	68 55 02 00 00       	push   $0x255
f0100d84:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100d89:	e8 fd f2 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100d8e:	85 db                	test   %ebx,%ebx
f0100d90:	7f 42                	jg     f0100dd4 <check_page_free_list+0x2ac>
f0100d92:	68 85 3f 10 f0       	push   $0xf0103f85
f0100d97:	68 06 3f 10 f0       	push   $0xf0103f06
f0100d9c:	68 56 02 00 00       	push   $0x256
f0100da1:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100da6:	e8 e0 f2 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dab:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100db0:	85 c0                	test   %eax,%eax
f0100db2:	0f 85 9d fd ff ff    	jne    f0100b55 <check_page_free_list+0x2d>
f0100db8:	e9 81 fd ff ff       	jmp    f0100b3e <check_page_free_list+0x16>
f0100dbd:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100dc4:	0f 84 74 fd ff ff    	je     f0100b3e <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dca:	be 00 04 00 00       	mov    $0x400,%esi
f0100dcf:	e9 cf fd ff ff       	jmp    f0100ba3 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dd7:	5b                   	pop    %ebx
f0100dd8:	5e                   	pop    %esi
f0100dd9:	5f                   	pop    %edi
f0100dda:	5d                   	pop    %ebp
f0100ddb:	c3                   	ret    

f0100ddc <page_init>:
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
// 初始化该系统内所有页信息，报错在数组pages内，并形成空闲链表
void page_init(void)
{
f0100ddc:	55                   	push   %ebp
f0100ddd:	89 e5                	mov    %esp,%ebp
f0100ddf:	53                   	push   %ebx
f0100de0:	83 ec 04             	sub    $0x4,%esp
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100de3:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100de8:	e9 96 00 00 00       	jmp    f0100e83 <page_init+0xa7>
	{

		if (i == 0)
f0100ded:	85 db                	test   %ebx,%ebx
f0100def:	75 13                	jne    f0100e04 <page_init+0x28>
		{
			pages[i].pp_ref = 1;
f0100df1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100df6:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100dfc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100e02:	eb 7c                	jmp    f0100e80 <page_init+0xa4>
		}
		else if (i > npages_basemem - 1 && i < PADDR(boot_alloc(0)) / PGSIZE)
f0100e04:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0100e09:	83 e8 01             	sub    $0x1,%eax
f0100e0c:	39 c3                	cmp    %eax,%ebx
f0100e0e:	76 48                	jbe    f0100e58 <page_init+0x7c>
f0100e10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e15:	e8 42 fc ff ff       	call   f0100a5c <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e1a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e1f:	77 15                	ja     f0100e36 <page_init+0x5a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e21:	50                   	push   %eax
f0100e22:	68 5c 42 10 f0       	push   $0xf010425c
f0100e27:	68 12 01 00 00       	push   $0x112
f0100e2c:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100e31:	e8 55 f2 ff ff       	call   f010008b <_panic>
f0100e36:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e3b:	c1 e8 0c             	shr    $0xc,%eax
f0100e3e:	39 c3                	cmp    %eax,%ebx
f0100e40:	73 16                	jae    f0100e58 <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100e42:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e47:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100e4a:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e50:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100e56:	eb 28                	jmp    f0100e80 <page_init+0xa4>
f0100e58:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}
		else
		{
			pages[i].pp_ref = 0;
f0100e5f:	89 c2                	mov    %eax,%edx
f0100e61:	03 15 6c 79 11 f0    	add    0xf011796c,%edx
f0100e67:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100e6d:	8b 0d 3c 75 11 f0    	mov    0xf011753c,%ecx
f0100e73:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100e75:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e7b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100e80:	83 c3 01             	add    $0x1,%ebx
f0100e83:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100e89:	0f 82 5e ff ff ff    	jb     f0100ded <page_init+0x11>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100e8f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e92:	c9                   	leave  
f0100e93:	c3                   	ret    

f0100e94 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e94:	55                   	push   %ebp
f0100e95:	89 e5                	mov    %esp,%ebp
f0100e97:	53                   	push   %ebx
f0100e98:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *p = NULL;
	if (page_free_list == NULL)
f0100e9b:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ea1:	85 db                	test   %ebx,%ebx
f0100ea3:	74 58                	je     f0100efd <page_alloc+0x69>
		return NULL;

	p = page_free_list;
	page_free_list = p->pp_link;
f0100ea5:	8b 03                	mov    (%ebx),%eax
f0100ea7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	p->pp_link = NULL;
f0100eac:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
f0100eb2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100eb6:	74 45                	je     f0100efd <page_alloc+0x69>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100eb8:	89 d8                	mov    %ebx,%eax
f0100eba:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ec0:	c1 f8 03             	sar    $0x3,%eax
f0100ec3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec6:	89 c2                	mov    %eax,%edx
f0100ec8:	c1 ea 0c             	shr    $0xc,%edx
f0100ecb:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ed1:	72 12                	jb     f0100ee5 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed3:	50                   	push   %eax
f0100ed4:	68 7c 41 10 f0       	push   $0xf010417c
f0100ed9:	6a 57                	push   $0x57
f0100edb:	68 ec 3e 10 f0       	push   $0xf0103eec
f0100ee0:	e8 a6 f1 ff ff       	call   f010008b <_panic>
	{
		memset(page2kva(p), 0, PGSIZE);
f0100ee5:	83 ec 04             	sub    $0x4,%esp
f0100ee8:	68 00 10 00 00       	push   $0x1000
f0100eed:	6a 00                	push   $0x0
f0100eef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ef4:	50                   	push   %eax
f0100ef5:	e8 c4 24 00 00       	call   f01033be <memset>
f0100efa:	83 c4 10             	add    $0x10,%esp
	}

	return p;
}
f0100efd:	89 d8                	mov    %ebx,%eax
f0100eff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f02:	c9                   	leave  
f0100f03:	c3                   	ret    

f0100f04 <page_free>:
//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void page_free(struct PageInfo *pp)
{
f0100f04:	55                   	push   %ebp
f0100f05:	89 e5                	mov    %esp,%ebp
f0100f07:	83 ec 08             	sub    $0x8,%esp
f0100f0a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	if (pp->pp_ref != 0 || pp->pp_link != NULL)
f0100f0d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f12:	75 05                	jne    f0100f19 <page_free+0x15>
f0100f14:	83 38 00             	cmpl   $0x0,(%eax)
f0100f17:	74 17                	je     f0100f30 <page_free+0x2c>
	{
		panic("still in used!");
f0100f19:	83 ec 04             	sub    $0x4,%esp
f0100f1c:	68 96 3f 10 f0       	push   $0xf0103f96
f0100f21:	68 4c 01 00 00       	push   $0x14c
f0100f26:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100f2b:	e8 5b f1 ff ff       	call   f010008b <_panic>
	}
	else
	{
		pp->pp_link = page_free_list;
f0100f30:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100f36:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100f38:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	}
}
f0100f3d:	c9                   	leave  
f0100f3e:	c3                   	ret    

f0100f3f <page_decref>:
//
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void page_decref(struct PageInfo *pp)
{
f0100f3f:	55                   	push   %ebp
f0100f40:	89 e5                	mov    %esp,%ebp
f0100f42:	83 ec 08             	sub    $0x8,%esp
f0100f45:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f48:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f4c:	83 e8 01             	sub    $0x1,%eax
f0100f4f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f53:	66 85 c0             	test   %ax,%ax
f0100f56:	75 0c                	jne    f0100f64 <page_decref+0x25>
		page_free(pp);
f0100f58:	83 ec 0c             	sub    $0xc,%esp
f0100f5b:	52                   	push   %edx
f0100f5c:	e8 a3 ff ff ff       	call   f0100f04 <page_free>
f0100f61:	83 c4 10             	add    $0x10,%esp
}
f0100f64:	c9                   	leave  
f0100f65:	c3                   	ret    

f0100f66 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f66:	55                   	push   %ebp
f0100f67:	89 e5                	mov    %esp,%ebp
f0100f69:	56                   	push   %esi
f0100f6a:	53                   	push   %ebx
f0100f6b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
f0100f6e:	89 f3                	mov    %esi,%ebx
f0100f70:	c1 eb 16             	shr    $0x16,%ebx
f0100f73:	c1 e3 02             	shl    $0x2,%ebx
f0100f76:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f79:	f6 03 01             	testb  $0x1,(%ebx)
f0100f7c:	75 2e                	jne    f0100fac <pgdir_walk+0x46>
	{
		if (create == 0)
f0100f7e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f82:	74 63                	je     f0100fe7 <pgdir_walk+0x81>
			return NULL;
		struct PageInfo *p = page_alloc(1);
f0100f84:	83 ec 0c             	sub    $0xc,%esp
f0100f87:	6a 01                	push   $0x1
f0100f89:	e8 06 ff ff ff       	call   f0100e94 <page_alloc>
		if (p == NULL)
f0100f8e:	83 c4 10             	add    $0x10,%esp
f0100f91:	85 c0                	test   %eax,%eax
f0100f93:	74 59                	je     f0100fee <pgdir_walk+0x88>
			return NULL;
		p->pp_ref = 1;
f0100f95:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

		// 页目录项存储的是页表项的物理地址
		// 操作系统直接转换的所以自然是物理地址
		pgdir[index] = page2pa(p) | PTE_P | PTE_U | PTE_W;
f0100f9b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100fa1:	c1 f8 03             	sar    $0x3,%eax
f0100fa4:	c1 e0 0c             	shl    $0xc,%eax
f0100fa7:	83 c8 07             	or     $0x7,%eax
f0100faa:	89 03                	mov    %eax,(%ebx)
	}
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);
f0100fac:	8b 03                	mov    (%ebx),%eax
f0100fae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb3:	89 c2                	mov    %eax,%edx
f0100fb5:	c1 ea 0c             	shr    $0xc,%edx
f0100fb8:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100fbe:	72 15                	jb     f0100fd5 <pgdir_walk+0x6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc0:	50                   	push   %eax
f0100fc1:	68 7c 41 10 f0       	push   $0xf010417c
f0100fc6:	68 89 01 00 00       	push   $0x189
f0100fcb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100fd0:	e8 b6 f0 ff ff       	call   f010008b <_panic>
f0100fd5:	c1 ee 0a             	shr    $0xa,%esi
f0100fd8:	81 e6 fc 0f 00 00    	and    $0xffc,%esi

	return pte;
f0100fde:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100fe5:	eb 0c                	jmp    f0100ff3 <pgdir_walk+0x8d>
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
	{
		if (create == 0)
			return NULL;
f0100fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fec:	eb 05                	jmp    f0100ff3 <pgdir_walk+0x8d>
		struct PageInfo *p = page_alloc(1);
		if (p == NULL)
			return NULL;
f0100fee:	b8 00 00 00 00       	mov    $0x0,%eax
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);

	return pte;
}
f0100ff3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ff6:	5b                   	pop    %ebx
f0100ff7:	5e                   	pop    %esi
f0100ff8:	5d                   	pop    %ebp
f0100ff9:	c3                   	ret    

f0100ffa <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ffa:	55                   	push   %ebp
f0100ffb:	89 e5                	mov    %esp,%ebp
f0100ffd:	57                   	push   %edi
f0100ffe:	56                   	push   %esi
f0100fff:	53                   	push   %ebx
f0101000:	83 ec 1c             	sub    $0x1c,%esp
f0101003:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101006:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
f0101009:	c1 e9 0c             	shr    $0xc,%ecx
f010100c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i=0; i<pg_num; i++) {
f010100f:	89 c3                	mov    %eax,%ebx
f0101011:	be 00 00 00 00       	mov    $0x0,%esi
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0101016:	89 d7                	mov    %edx,%edi
f0101018:	29 c7                	sub    %eax,%edi
		if (!pgtab) {
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f010101a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010101d:	83 c8 01             	or     $0x1,%eax
f0101020:	89 45 dc             	mov    %eax,-0x24(%ebp)
{
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i=0; i<pg_num; i++) {
f0101023:	eb 28                	jmp    f010104d <boot_map_region+0x53>
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f0101025:	83 ec 04             	sub    $0x4,%esp
f0101028:	6a 01                	push   $0x1
f010102a:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f010102d:	50                   	push   %eax
f010102e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101031:	e8 30 ff ff ff       	call   f0100f66 <pgdir_walk>
		if (!pgtab) {
f0101036:	83 c4 10             	add    $0x10,%esp
f0101039:	85 c0                	test   %eax,%eax
f010103b:	74 15                	je     f0101052 <boot_map_region+0x58>
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f010103d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101040:	09 da                	or     %ebx,%edx
f0101042:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f0101044:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i=0; i<pg_num; i++) {
f010104a:	83 c6 01             	add    $0x1,%esi
f010104d:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101050:	75 d3                	jne    f0101025 <boot_map_region+0x2b>
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0101052:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101055:	5b                   	pop    %ebx
f0101056:	5e                   	pop    %esi
f0101057:	5f                   	pop    %edi
f0101058:	5d                   	pop    %ebp
f0101059:	c3                   	ret    

f010105a <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//
// 双重指针，为了改变指针指向的值
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010105a:	55                   	push   %ebp
f010105b:	89 e5                	mov    %esp,%ebp
f010105d:	53                   	push   %ebx
f010105e:	83 ec 08             	sub    $0x8,%esp
f0101061:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
f0101064:	6a 00                	push   $0x0
f0101066:	ff 75 0c             	pushl  0xc(%ebp)
f0101069:	ff 75 08             	pushl  0x8(%ebp)
f010106c:	e8 f5 fe ff ff       	call   f0100f66 <pgdir_walk>
	if (p == NULL)
f0101071:	83 c4 10             	add    $0x10,%esp
f0101074:	85 c0                	test   %eax,%eax
f0101076:	74 32                	je     f01010aa <page_lookup+0x50>
		return NULL;
	if (pte_store != NULL)
f0101078:	85 db                	test   %ebx,%ebx
f010107a:	74 02                	je     f010107e <page_lookup+0x24>
		*pte_store = p;
f010107c:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010107e:	8b 00                	mov    (%eax),%eax
f0101080:	c1 e8 0c             	shr    $0xc,%eax
f0101083:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101089:	72 14                	jb     f010109f <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f010108b:	83 ec 04             	sub    $0x4,%esp
f010108e:	68 80 42 10 f0       	push   $0xf0104280
f0101093:	6a 50                	push   $0x50
f0101095:	68 ec 3e 10 f0       	push   $0xf0103eec
f010109a:	e8 ec ef ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f010109f:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f01010a5:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*p));
f01010a8:	eb 05                	jmp    f01010af <page_lookup+0x55>
{
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
	if (p == NULL)
		return NULL;
f01010aa:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != NULL)
		*pte_store = p;

	return pa2page(PTE_ADDR(*p));
}
f01010af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010b2:	c9                   	leave  
f01010b3:	c3                   	ret    

f01010b4 <page_remove>:
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void page_remove(pde_t *pgdir, void *va)
{
f01010b4:	55                   	push   %ebp
f01010b5:	89 e5                	mov    %esp,%ebp
f01010b7:	53                   	push   %ebx
f01010b8:	83 ec 18             	sub    $0x18,%esp
f01010bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *p = NULL;
f01010be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &p);
f01010c5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010c8:	50                   	push   %eax
f01010c9:	53                   	push   %ebx
f01010ca:	ff 75 08             	pushl  0x8(%ebp)
f01010cd:	e8 88 ff ff ff       	call   f010105a <page_lookup>
	if (page != NULL)
f01010d2:	83 c4 10             	add    $0x10,%esp
f01010d5:	85 c0                	test   %eax,%eax
f01010d7:	74 18                	je     f01010f1 <page_remove+0x3d>
	{
		*p = 0;
f01010d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010dc:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		page_decref(page);
f01010e2:	83 ec 0c             	sub    $0xc,%esp
f01010e5:	50                   	push   %eax
f01010e6:	e8 54 fe ff ff       	call   f0100f3f <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010eb:	0f 01 3b             	invlpg (%ebx)
f01010ee:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f01010f1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010f4:	c9                   	leave  
f01010f5:	c3                   	ret    

f01010f6 <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010f6:	55                   	push   %ebp
f01010f7:	89 e5                	mov    %esp,%ebp
f01010f9:	57                   	push   %edi
f01010fa:	56                   	push   %esi
f01010fb:	53                   	push   %ebx
f01010fc:	83 ec 10             	sub    $0x10,%esp
f01010ff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101102:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *p = pgdir_walk(pgdir, va, 1);
f0101105:	6a 01                	push   $0x1
f0101107:	57                   	push   %edi
f0101108:	ff 75 08             	pushl  0x8(%ebp)
f010110b:	e8 56 fe ff ff       	call   f0100f66 <pgdir_walk>
	if (p == NULL)
f0101110:	83 c4 10             	add    $0x10,%esp
f0101113:	85 c0                	test   %eax,%eax
f0101115:	74 38                	je     f010114f <page_insert+0x59>
f0101117:	89 c6                	mov    %eax,%esi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0101119:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*p & PTE_P)
f010111e:	f6 00 01             	testb  $0x1,(%eax)
f0101121:	74 0f                	je     f0101132 <page_insert+0x3c>
	{
		page_remove(pgdir, va);
f0101123:	83 ec 08             	sub    $0x8,%esp
f0101126:	57                   	push   %edi
f0101127:	ff 75 08             	pushl  0x8(%ebp)
f010112a:	e8 85 ff ff ff       	call   f01010b4 <page_remove>
f010112f:	83 c4 10             	add    $0x10,%esp
	}
	*p = page2pa(pp) | perm | PTE_P;
f0101132:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f0101138:	c1 fb 03             	sar    $0x3,%ebx
f010113b:	c1 e3 0c             	shl    $0xc,%ebx
f010113e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101141:	83 c8 01             	or     $0x1,%eax
f0101144:	09 c3                	or     %eax,%ebx
f0101146:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101148:	b8 00 00 00 00       	mov    $0x0,%eax
f010114d:	eb 05                	jmp    f0101154 <page_insert+0x5e>
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *p = pgdir_walk(pgdir, va, 1);
	if (p == NULL)
	{
		return -E_NO_MEM;
f010114f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	{
		page_remove(pgdir, va);
	}
	*p = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101154:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101157:	5b                   	pop    %ebx
f0101158:	5e                   	pop    %esi
f0101159:	5f                   	pop    %edi
f010115a:	5d                   	pop    %ebp
f010115b:	c3                   	ret    

f010115c <mem_init>:
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
// 二级页表

void mem_init(void)
{
f010115c:	55                   	push   %ebp
f010115d:	89 e5                	mov    %esp,%ebp
f010115f:	57                   	push   %edi
f0101160:	56                   	push   %esi
f0101161:	53                   	push   %ebx
f0101162:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101165:	6a 15                	push   $0x15
f0101167:	e8 82 16 00 00       	call   f01027ee <mc146818_read>
f010116c:	89 c3                	mov    %eax,%ebx
f010116e:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101175:	e8 74 16 00 00       	call   f01027ee <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010117a:	c1 e0 08             	shl    $0x8,%eax
f010117d:	09 d8                	or     %ebx,%eax
f010117f:	c1 e0 0a             	shl    $0xa,%eax
f0101182:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101188:	85 c0                	test   %eax,%eax
f010118a:	0f 48 c2             	cmovs  %edx,%eax
f010118d:	c1 f8 0c             	sar    $0xc,%eax
f0101190:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101195:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010119c:	e8 4d 16 00 00       	call   f01027ee <mc146818_read>
f01011a1:	89 c3                	mov    %eax,%ebx
f01011a3:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011aa:	e8 3f 16 00 00       	call   f01027ee <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011af:	c1 e0 08             	shl    $0x8,%eax
f01011b2:	09 d8                	or     %ebx,%eax
f01011b4:	c1 e0 0a             	shl    $0xa,%eax
f01011b7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011bd:	83 c4 10             	add    $0x10,%esp
f01011c0:	85 c0                	test   %eax,%eax
f01011c2:	0f 48 c2             	cmovs  %edx,%eax
f01011c5:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	74 0e                	je     f01011da <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01011cc:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01011d2:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f01011d8:	eb 0c                	jmp    f01011e6 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01011da:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f01011e0:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011e6:	c1 e0 0c             	shl    $0xc,%eax
f01011e9:	c1 e8 0a             	shr    $0xa,%eax
f01011ec:	50                   	push   %eax
f01011ed:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01011f2:	c1 e0 0c             	shl    $0xc,%eax
f01011f5:	c1 e8 0a             	shr    $0xa,%eax
f01011f8:	50                   	push   %eax
f01011f9:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01011fe:	c1 e0 0c             	shl    $0xc,%eax
f0101201:	c1 e8 0a             	shr    $0xa,%eax
f0101204:	50                   	push   %eax
f0101205:	68 a0 42 10 f0       	push   $0xf01042a0
f010120a:	e8 46 16 00 00       	call   f0102855 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	// 创建一个初始化的页目录表
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f010120f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101214:	e8 43 f8 ff ff       	call   f0100a5c <boot_alloc>
f0101219:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f010121e:	83 c4 0c             	add    $0xc,%esp
f0101221:	68 00 10 00 00       	push   $0x1000
f0101226:	6a 00                	push   $0x0
f0101228:	50                   	push   %eax
f0101229:	e8 90 21 00 00       	call   f01033be <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010122e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101233:	83 c4 10             	add    $0x10,%esp
f0101236:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010123b:	77 15                	ja     f0101252 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010123d:	50                   	push   %eax
f010123e:	68 5c 42 10 f0       	push   $0xf010425c
f0101243:	68 91 00 00 00       	push   $0x91
f0101248:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010124d:	e8 39 ee ff ff       	call   f010008b <_panic>
f0101252:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101258:	83 ca 05             	or     $0x5,%edx
f010125b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f0101261:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101266:	c1 e0 03             	shl    $0x3,%eax
f0101269:	e8 ee f7 ff ff       	call   f0100a5c <boot_alloc>
f010126e:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f0101273:	83 ec 04             	sub    $0x4,%esp
f0101276:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010127c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101283:	52                   	push   %edx
f0101284:	6a 00                	push   $0x0
f0101286:	50                   	push   %eax
f0101287:	e8 32 21 00 00       	call   f01033be <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010128c:	e8 4b fb ff ff       	call   f0100ddc <page_init>

	check_page_free_list(1);
f0101291:	b8 01 00 00 00       	mov    $0x1,%eax
f0101296:	e8 8d f8 ff ff       	call   f0100b28 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010129b:	83 c4 10             	add    $0x10,%esp
f010129e:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01012a5:	75 17                	jne    f01012be <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01012a7:	83 ec 04             	sub    $0x4,%esp
f01012aa:	68 a5 3f 10 f0       	push   $0xf0103fa5
f01012af:	68 67 02 00 00       	push   $0x267
f01012b4:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01012b9:	e8 cd ed ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012be:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012c3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012c8:	eb 05                	jmp    f01012cf <mem_init+0x173>
		++nfree;
f01012ca:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012cd:	8b 00                	mov    (%eax),%eax
f01012cf:	85 c0                	test   %eax,%eax
f01012d1:	75 f7                	jne    f01012ca <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012d3:	83 ec 0c             	sub    $0xc,%esp
f01012d6:	6a 00                	push   $0x0
f01012d8:	e8 b7 fb ff ff       	call   f0100e94 <page_alloc>
f01012dd:	89 c7                	mov    %eax,%edi
f01012df:	83 c4 10             	add    $0x10,%esp
f01012e2:	85 c0                	test   %eax,%eax
f01012e4:	75 19                	jne    f01012ff <mem_init+0x1a3>
f01012e6:	68 c0 3f 10 f0       	push   $0xf0103fc0
f01012eb:	68 06 3f 10 f0       	push   $0xf0103f06
f01012f0:	68 6f 02 00 00       	push   $0x26f
f01012f5:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01012fa:	e8 8c ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012ff:	83 ec 0c             	sub    $0xc,%esp
f0101302:	6a 00                	push   $0x0
f0101304:	e8 8b fb ff ff       	call   f0100e94 <page_alloc>
f0101309:	89 c6                	mov    %eax,%esi
f010130b:	83 c4 10             	add    $0x10,%esp
f010130e:	85 c0                	test   %eax,%eax
f0101310:	75 19                	jne    f010132b <mem_init+0x1cf>
f0101312:	68 d6 3f 10 f0       	push   $0xf0103fd6
f0101317:	68 06 3f 10 f0       	push   $0xf0103f06
f010131c:	68 70 02 00 00       	push   $0x270
f0101321:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101326:	e8 60 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010132b:	83 ec 0c             	sub    $0xc,%esp
f010132e:	6a 00                	push   $0x0
f0101330:	e8 5f fb ff ff       	call   f0100e94 <page_alloc>
f0101335:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101338:	83 c4 10             	add    $0x10,%esp
f010133b:	85 c0                	test   %eax,%eax
f010133d:	75 19                	jne    f0101358 <mem_init+0x1fc>
f010133f:	68 ec 3f 10 f0       	push   $0xf0103fec
f0101344:	68 06 3f 10 f0       	push   $0xf0103f06
f0101349:	68 71 02 00 00       	push   $0x271
f010134e:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101353:	e8 33 ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101358:	39 f7                	cmp    %esi,%edi
f010135a:	75 19                	jne    f0101375 <mem_init+0x219>
f010135c:	68 02 40 10 f0       	push   $0xf0104002
f0101361:	68 06 3f 10 f0       	push   $0xf0103f06
f0101366:	68 74 02 00 00       	push   $0x274
f010136b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101370:	e8 16 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101375:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101378:	39 c6                	cmp    %eax,%esi
f010137a:	74 04                	je     f0101380 <mem_init+0x224>
f010137c:	39 c7                	cmp    %eax,%edi
f010137e:	75 19                	jne    f0101399 <mem_init+0x23d>
f0101380:	68 dc 42 10 f0       	push   $0xf01042dc
f0101385:	68 06 3f 10 f0       	push   $0xf0103f06
f010138a:	68 75 02 00 00       	push   $0x275
f010138f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101394:	e8 f2 ec ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101399:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f010139f:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01013a5:	c1 e2 0c             	shl    $0xc,%edx
f01013a8:	89 f8                	mov    %edi,%eax
f01013aa:	29 c8                	sub    %ecx,%eax
f01013ac:	c1 f8 03             	sar    $0x3,%eax
f01013af:	c1 e0 0c             	shl    $0xc,%eax
f01013b2:	39 d0                	cmp    %edx,%eax
f01013b4:	72 19                	jb     f01013cf <mem_init+0x273>
f01013b6:	68 fc 42 10 f0       	push   $0xf01042fc
f01013bb:	68 06 3f 10 f0       	push   $0xf0103f06
f01013c0:	68 76 02 00 00       	push   $0x276
f01013c5:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01013ca:	e8 bc ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f01013cf:	89 f0                	mov    %esi,%eax
f01013d1:	29 c8                	sub    %ecx,%eax
f01013d3:	c1 f8 03             	sar    $0x3,%eax
f01013d6:	c1 e0 0c             	shl    $0xc,%eax
f01013d9:	39 c2                	cmp    %eax,%edx
f01013db:	77 19                	ja     f01013f6 <mem_init+0x29a>
f01013dd:	68 1c 43 10 f0       	push   $0xf010431c
f01013e2:	68 06 3f 10 f0       	push   $0xf0103f06
f01013e7:	68 77 02 00 00       	push   $0x277
f01013ec:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01013f1:	e8 95 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f01013f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013f9:	29 c8                	sub    %ecx,%eax
f01013fb:	c1 f8 03             	sar    $0x3,%eax
f01013fe:	c1 e0 0c             	shl    $0xc,%eax
f0101401:	39 c2                	cmp    %eax,%edx
f0101403:	77 19                	ja     f010141e <mem_init+0x2c2>
f0101405:	68 3c 43 10 f0       	push   $0xf010433c
f010140a:	68 06 3f 10 f0       	push   $0xf0103f06
f010140f:	68 78 02 00 00       	push   $0x278
f0101414:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101419:	e8 6d ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010141e:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101423:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101426:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010142d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101430:	83 ec 0c             	sub    $0xc,%esp
f0101433:	6a 00                	push   $0x0
f0101435:	e8 5a fa ff ff       	call   f0100e94 <page_alloc>
f010143a:	83 c4 10             	add    $0x10,%esp
f010143d:	85 c0                	test   %eax,%eax
f010143f:	74 19                	je     f010145a <mem_init+0x2fe>
f0101441:	68 14 40 10 f0       	push   $0xf0104014
f0101446:	68 06 3f 10 f0       	push   $0xf0103f06
f010144b:	68 7f 02 00 00       	push   $0x27f
f0101450:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101455:	e8 31 ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010145a:	83 ec 0c             	sub    $0xc,%esp
f010145d:	57                   	push   %edi
f010145e:	e8 a1 fa ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f0101463:	89 34 24             	mov    %esi,(%esp)
f0101466:	e8 99 fa ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f010146b:	83 c4 04             	add    $0x4,%esp
f010146e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101471:	e8 8e fa ff ff       	call   f0100f04 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101476:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010147d:	e8 12 fa ff ff       	call   f0100e94 <page_alloc>
f0101482:	89 c6                	mov    %eax,%esi
f0101484:	83 c4 10             	add    $0x10,%esp
f0101487:	85 c0                	test   %eax,%eax
f0101489:	75 19                	jne    f01014a4 <mem_init+0x348>
f010148b:	68 c0 3f 10 f0       	push   $0xf0103fc0
f0101490:	68 06 3f 10 f0       	push   $0xf0103f06
f0101495:	68 86 02 00 00       	push   $0x286
f010149a:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010149f:	e8 e7 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014a4:	83 ec 0c             	sub    $0xc,%esp
f01014a7:	6a 00                	push   $0x0
f01014a9:	e8 e6 f9 ff ff       	call   f0100e94 <page_alloc>
f01014ae:	89 c7                	mov    %eax,%edi
f01014b0:	83 c4 10             	add    $0x10,%esp
f01014b3:	85 c0                	test   %eax,%eax
f01014b5:	75 19                	jne    f01014d0 <mem_init+0x374>
f01014b7:	68 d6 3f 10 f0       	push   $0xf0103fd6
f01014bc:	68 06 3f 10 f0       	push   $0xf0103f06
f01014c1:	68 87 02 00 00       	push   $0x287
f01014c6:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01014cb:	e8 bb eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014d0:	83 ec 0c             	sub    $0xc,%esp
f01014d3:	6a 00                	push   $0x0
f01014d5:	e8 ba f9 ff ff       	call   f0100e94 <page_alloc>
f01014da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014dd:	83 c4 10             	add    $0x10,%esp
f01014e0:	85 c0                	test   %eax,%eax
f01014e2:	75 19                	jne    f01014fd <mem_init+0x3a1>
f01014e4:	68 ec 3f 10 f0       	push   $0xf0103fec
f01014e9:	68 06 3f 10 f0       	push   $0xf0103f06
f01014ee:	68 88 02 00 00       	push   $0x288
f01014f3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01014f8:	e8 8e eb ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014fd:	39 fe                	cmp    %edi,%esi
f01014ff:	75 19                	jne    f010151a <mem_init+0x3be>
f0101501:	68 02 40 10 f0       	push   $0xf0104002
f0101506:	68 06 3f 10 f0       	push   $0xf0103f06
f010150b:	68 8a 02 00 00       	push   $0x28a
f0101510:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101515:	e8 71 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010151a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010151d:	39 c7                	cmp    %eax,%edi
f010151f:	74 04                	je     f0101525 <mem_init+0x3c9>
f0101521:	39 c6                	cmp    %eax,%esi
f0101523:	75 19                	jne    f010153e <mem_init+0x3e2>
f0101525:	68 dc 42 10 f0       	push   $0xf01042dc
f010152a:	68 06 3f 10 f0       	push   $0xf0103f06
f010152f:	68 8b 02 00 00       	push   $0x28b
f0101534:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101539:	e8 4d eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010153e:	83 ec 0c             	sub    $0xc,%esp
f0101541:	6a 00                	push   $0x0
f0101543:	e8 4c f9 ff ff       	call   f0100e94 <page_alloc>
f0101548:	83 c4 10             	add    $0x10,%esp
f010154b:	85 c0                	test   %eax,%eax
f010154d:	74 19                	je     f0101568 <mem_init+0x40c>
f010154f:	68 14 40 10 f0       	push   $0xf0104014
f0101554:	68 06 3f 10 f0       	push   $0xf0103f06
f0101559:	68 8c 02 00 00       	push   $0x28c
f010155e:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101563:	e8 23 eb ff ff       	call   f010008b <_panic>
f0101568:	89 f0                	mov    %esi,%eax
f010156a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101570:	c1 f8 03             	sar    $0x3,%eax
f0101573:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101576:	89 c2                	mov    %eax,%edx
f0101578:	c1 ea 0c             	shr    $0xc,%edx
f010157b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101581:	72 12                	jb     f0101595 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101583:	50                   	push   %eax
f0101584:	68 7c 41 10 f0       	push   $0xf010417c
f0101589:	6a 57                	push   $0x57
f010158b:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101590:	e8 f6 ea ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101595:	83 ec 04             	sub    $0x4,%esp
f0101598:	68 00 10 00 00       	push   $0x1000
f010159d:	6a 01                	push   $0x1
f010159f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015a4:	50                   	push   %eax
f01015a5:	e8 14 1e 00 00       	call   f01033be <memset>
	page_free(pp0);
f01015aa:	89 34 24             	mov    %esi,(%esp)
f01015ad:	e8 52 f9 ff ff       	call   f0100f04 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015b2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015b9:	e8 d6 f8 ff ff       	call   f0100e94 <page_alloc>
f01015be:	83 c4 10             	add    $0x10,%esp
f01015c1:	85 c0                	test   %eax,%eax
f01015c3:	75 19                	jne    f01015de <mem_init+0x482>
f01015c5:	68 23 40 10 f0       	push   $0xf0104023
f01015ca:	68 06 3f 10 f0       	push   $0xf0103f06
f01015cf:	68 91 02 00 00       	push   $0x291
f01015d4:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01015d9:	e8 ad ea ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01015de:	39 c6                	cmp    %eax,%esi
f01015e0:	74 19                	je     f01015fb <mem_init+0x49f>
f01015e2:	68 41 40 10 f0       	push   $0xf0104041
f01015e7:	68 06 3f 10 f0       	push   $0xf0103f06
f01015ec:	68 92 02 00 00       	push   $0x292
f01015f1:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01015f6:	e8 90 ea ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01015fb:	89 f0                	mov    %esi,%eax
f01015fd:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101603:	c1 f8 03             	sar    $0x3,%eax
f0101606:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101609:	89 c2                	mov    %eax,%edx
f010160b:	c1 ea 0c             	shr    $0xc,%edx
f010160e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101614:	72 12                	jb     f0101628 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101616:	50                   	push   %eax
f0101617:	68 7c 41 10 f0       	push   $0xf010417c
f010161c:	6a 57                	push   $0x57
f010161e:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101623:	e8 63 ea ff ff       	call   f010008b <_panic>
f0101628:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010162e:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101634:	80 38 00             	cmpb   $0x0,(%eax)
f0101637:	74 19                	je     f0101652 <mem_init+0x4f6>
f0101639:	68 51 40 10 f0       	push   $0xf0104051
f010163e:	68 06 3f 10 f0       	push   $0xf0103f06
f0101643:	68 95 02 00 00       	push   $0x295
f0101648:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010164d:	e8 39 ea ff ff       	call   f010008b <_panic>
f0101652:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101655:	39 d0                	cmp    %edx,%eax
f0101657:	75 db                	jne    f0101634 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101659:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010165c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101661:	83 ec 0c             	sub    $0xc,%esp
f0101664:	56                   	push   %esi
f0101665:	e8 9a f8 ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f010166a:	89 3c 24             	mov    %edi,(%esp)
f010166d:	e8 92 f8 ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f0101672:	83 c4 04             	add    $0x4,%esp
f0101675:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101678:	e8 87 f8 ff ff       	call   f0100f04 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010167d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101682:	83 c4 10             	add    $0x10,%esp
f0101685:	eb 05                	jmp    f010168c <mem_init+0x530>
		--nfree;
f0101687:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010168a:	8b 00                	mov    (%eax),%eax
f010168c:	85 c0                	test   %eax,%eax
f010168e:	75 f7                	jne    f0101687 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101690:	85 db                	test   %ebx,%ebx
f0101692:	74 19                	je     f01016ad <mem_init+0x551>
f0101694:	68 5b 40 10 f0       	push   $0xf010405b
f0101699:	68 06 3f 10 f0       	push   $0xf0103f06
f010169e:	68 a2 02 00 00       	push   $0x2a2
f01016a3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01016a8:	e8 de e9 ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016ad:	83 ec 0c             	sub    $0xc,%esp
f01016b0:	68 5c 43 10 f0       	push   $0xf010435c
f01016b5:	e8 9b 11 00 00       	call   f0102855 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016c1:	e8 ce f7 ff ff       	call   f0100e94 <page_alloc>
f01016c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016c9:	83 c4 10             	add    $0x10,%esp
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	75 19                	jne    f01016e9 <mem_init+0x58d>
f01016d0:	68 c0 3f 10 f0       	push   $0xf0103fc0
f01016d5:	68 06 3f 10 f0       	push   $0xf0103f06
f01016da:	68 fd 02 00 00       	push   $0x2fd
f01016df:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01016e4:	e8 a2 e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01016e9:	83 ec 0c             	sub    $0xc,%esp
f01016ec:	6a 00                	push   $0x0
f01016ee:	e8 a1 f7 ff ff       	call   f0100e94 <page_alloc>
f01016f3:	89 c3                	mov    %eax,%ebx
f01016f5:	83 c4 10             	add    $0x10,%esp
f01016f8:	85 c0                	test   %eax,%eax
f01016fa:	75 19                	jne    f0101715 <mem_init+0x5b9>
f01016fc:	68 d6 3f 10 f0       	push   $0xf0103fd6
f0101701:	68 06 3f 10 f0       	push   $0xf0103f06
f0101706:	68 fe 02 00 00       	push   $0x2fe
f010170b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101710:	e8 76 e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101715:	83 ec 0c             	sub    $0xc,%esp
f0101718:	6a 00                	push   $0x0
f010171a:	e8 75 f7 ff ff       	call   f0100e94 <page_alloc>
f010171f:	89 c6                	mov    %eax,%esi
f0101721:	83 c4 10             	add    $0x10,%esp
f0101724:	85 c0                	test   %eax,%eax
f0101726:	75 19                	jne    f0101741 <mem_init+0x5e5>
f0101728:	68 ec 3f 10 f0       	push   $0xf0103fec
f010172d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101732:	68 ff 02 00 00       	push   $0x2ff
f0101737:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010173c:	e8 4a e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101741:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101744:	75 19                	jne    f010175f <mem_init+0x603>
f0101746:	68 02 40 10 f0       	push   $0xf0104002
f010174b:	68 06 3f 10 f0       	push   $0xf0103f06
f0101750:	68 02 03 00 00       	push   $0x302
f0101755:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010175a:	e8 2c e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010175f:	39 c3                	cmp    %eax,%ebx
f0101761:	74 05                	je     f0101768 <mem_init+0x60c>
f0101763:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101766:	75 19                	jne    f0101781 <mem_init+0x625>
f0101768:	68 dc 42 10 f0       	push   $0xf01042dc
f010176d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101772:	68 03 03 00 00       	push   $0x303
f0101777:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010177c:	e8 0a e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101781:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101786:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101789:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101790:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101793:	83 ec 0c             	sub    $0xc,%esp
f0101796:	6a 00                	push   $0x0
f0101798:	e8 f7 f6 ff ff       	call   f0100e94 <page_alloc>
f010179d:	83 c4 10             	add    $0x10,%esp
f01017a0:	85 c0                	test   %eax,%eax
f01017a2:	74 19                	je     f01017bd <mem_init+0x661>
f01017a4:	68 14 40 10 f0       	push   $0xf0104014
f01017a9:	68 06 3f 10 f0       	push   $0xf0103f06
f01017ae:	68 0a 03 00 00       	push   $0x30a
f01017b3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01017b8:	e8 ce e8 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f01017bd:	83 ec 04             	sub    $0x4,%esp
f01017c0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01017c3:	50                   	push   %eax
f01017c4:	6a 00                	push   $0x0
f01017c6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017cc:	e8 89 f8 ff ff       	call   f010105a <page_lookup>
f01017d1:	83 c4 10             	add    $0x10,%esp
f01017d4:	85 c0                	test   %eax,%eax
f01017d6:	74 19                	je     f01017f1 <mem_init+0x695>
f01017d8:	68 7c 43 10 f0       	push   $0xf010437c
f01017dd:	68 06 3f 10 f0       	push   $0xf0103f06
f01017e2:	68 0d 03 00 00       	push   $0x30d
f01017e7:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01017ec:	e8 9a e8 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017f1:	6a 02                	push   $0x2
f01017f3:	6a 00                	push   $0x0
f01017f5:	53                   	push   %ebx
f01017f6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017fc:	e8 f5 f8 ff ff       	call   f01010f6 <page_insert>
f0101801:	83 c4 10             	add    $0x10,%esp
f0101804:	85 c0                	test   %eax,%eax
f0101806:	78 19                	js     f0101821 <mem_init+0x6c5>
f0101808:	68 b0 43 10 f0       	push   $0xf01043b0
f010180d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101812:	68 10 03 00 00       	push   $0x310
f0101817:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010181c:	e8 6a e8 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101821:	83 ec 0c             	sub    $0xc,%esp
f0101824:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101827:	e8 d8 f6 ff ff       	call   f0100f04 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010182c:	6a 02                	push   $0x2
f010182e:	6a 00                	push   $0x0
f0101830:	53                   	push   %ebx
f0101831:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101837:	e8 ba f8 ff ff       	call   f01010f6 <page_insert>
f010183c:	83 c4 20             	add    $0x20,%esp
f010183f:	85 c0                	test   %eax,%eax
f0101841:	74 19                	je     f010185c <mem_init+0x700>
f0101843:	68 e0 43 10 f0       	push   $0xf01043e0
f0101848:	68 06 3f 10 f0       	push   $0xf0103f06
f010184d:	68 14 03 00 00       	push   $0x314
f0101852:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101857:	e8 2f e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010185c:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101862:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101867:	89 c1                	mov    %eax,%ecx
f0101869:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010186c:	8b 17                	mov    (%edi),%edx
f010186e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101874:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101877:	29 c8                	sub    %ecx,%eax
f0101879:	c1 f8 03             	sar    $0x3,%eax
f010187c:	c1 e0 0c             	shl    $0xc,%eax
f010187f:	39 c2                	cmp    %eax,%edx
f0101881:	74 19                	je     f010189c <mem_init+0x740>
f0101883:	68 10 44 10 f0       	push   $0xf0104410
f0101888:	68 06 3f 10 f0       	push   $0xf0103f06
f010188d:	68 15 03 00 00       	push   $0x315
f0101892:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101897:	e8 ef e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010189c:	ba 00 00 00 00       	mov    $0x0,%edx
f01018a1:	89 f8                	mov    %edi,%eax
f01018a3:	e8 1c f2 ff ff       	call   f0100ac4 <check_va2pa>
f01018a8:	89 da                	mov    %ebx,%edx
f01018aa:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01018ad:	c1 fa 03             	sar    $0x3,%edx
f01018b0:	c1 e2 0c             	shl    $0xc,%edx
f01018b3:	39 d0                	cmp    %edx,%eax
f01018b5:	74 19                	je     f01018d0 <mem_init+0x774>
f01018b7:	68 38 44 10 f0       	push   $0xf0104438
f01018bc:	68 06 3f 10 f0       	push   $0xf0103f06
f01018c1:	68 16 03 00 00       	push   $0x316
f01018c6:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01018cb:	e8 bb e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01018d0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018d5:	74 19                	je     f01018f0 <mem_init+0x794>
f01018d7:	68 66 40 10 f0       	push   $0xf0104066
f01018dc:	68 06 3f 10 f0       	push   $0xf0103f06
f01018e1:	68 17 03 00 00       	push   $0x317
f01018e6:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01018eb:	e8 9b e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01018f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018f3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01018f8:	74 19                	je     f0101913 <mem_init+0x7b7>
f01018fa:	68 77 40 10 f0       	push   $0xf0104077
f01018ff:	68 06 3f 10 f0       	push   $0xf0103f06
f0101904:	68 18 03 00 00       	push   $0x318
f0101909:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010190e:	e8 78 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101913:	6a 02                	push   $0x2
f0101915:	68 00 10 00 00       	push   $0x1000
f010191a:	56                   	push   %esi
f010191b:	57                   	push   %edi
f010191c:	e8 d5 f7 ff ff       	call   f01010f6 <page_insert>
f0101921:	83 c4 10             	add    $0x10,%esp
f0101924:	85 c0                	test   %eax,%eax
f0101926:	74 19                	je     f0101941 <mem_init+0x7e5>
f0101928:	68 68 44 10 f0       	push   $0xf0104468
f010192d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101932:	68 1b 03 00 00       	push   $0x31b
f0101937:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010193c:	e8 4a e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101941:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101946:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010194b:	e8 74 f1 ff ff       	call   f0100ac4 <check_va2pa>
f0101950:	89 f2                	mov    %esi,%edx
f0101952:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101958:	c1 fa 03             	sar    $0x3,%edx
f010195b:	c1 e2 0c             	shl    $0xc,%edx
f010195e:	39 d0                	cmp    %edx,%eax
f0101960:	74 19                	je     f010197b <mem_init+0x81f>
f0101962:	68 a4 44 10 f0       	push   $0xf01044a4
f0101967:	68 06 3f 10 f0       	push   $0xf0103f06
f010196c:	68 1c 03 00 00       	push   $0x31c
f0101971:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101976:	e8 10 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010197b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101980:	74 19                	je     f010199b <mem_init+0x83f>
f0101982:	68 88 40 10 f0       	push   $0xf0104088
f0101987:	68 06 3f 10 f0       	push   $0xf0103f06
f010198c:	68 1d 03 00 00       	push   $0x31d
f0101991:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101996:	e8 f0 e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010199b:	83 ec 0c             	sub    $0xc,%esp
f010199e:	6a 00                	push   $0x0
f01019a0:	e8 ef f4 ff ff       	call   f0100e94 <page_alloc>
f01019a5:	83 c4 10             	add    $0x10,%esp
f01019a8:	85 c0                	test   %eax,%eax
f01019aa:	74 19                	je     f01019c5 <mem_init+0x869>
f01019ac:	68 14 40 10 f0       	push   $0xf0104014
f01019b1:	68 06 3f 10 f0       	push   $0xf0103f06
f01019b6:	68 20 03 00 00       	push   $0x320
f01019bb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01019c0:	e8 c6 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01019c5:	6a 02                	push   $0x2
f01019c7:	68 00 10 00 00       	push   $0x1000
f01019cc:	56                   	push   %esi
f01019cd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01019d3:	e8 1e f7 ff ff       	call   f01010f6 <page_insert>
f01019d8:	83 c4 10             	add    $0x10,%esp
f01019db:	85 c0                	test   %eax,%eax
f01019dd:	74 19                	je     f01019f8 <mem_init+0x89c>
f01019df:	68 68 44 10 f0       	push   $0xf0104468
f01019e4:	68 06 3f 10 f0       	push   $0xf0103f06
f01019e9:	68 23 03 00 00       	push   $0x323
f01019ee:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01019f3:	e8 93 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019f8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019fd:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a02:	e8 bd f0 ff ff       	call   f0100ac4 <check_va2pa>
f0101a07:	89 f2                	mov    %esi,%edx
f0101a09:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a0f:	c1 fa 03             	sar    $0x3,%edx
f0101a12:	c1 e2 0c             	shl    $0xc,%edx
f0101a15:	39 d0                	cmp    %edx,%eax
f0101a17:	74 19                	je     f0101a32 <mem_init+0x8d6>
f0101a19:	68 a4 44 10 f0       	push   $0xf01044a4
f0101a1e:	68 06 3f 10 f0       	push   $0xf0103f06
f0101a23:	68 24 03 00 00       	push   $0x324
f0101a28:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101a2d:	e8 59 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a32:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a37:	74 19                	je     f0101a52 <mem_init+0x8f6>
f0101a39:	68 88 40 10 f0       	push   $0xf0104088
f0101a3e:	68 06 3f 10 f0       	push   $0xf0103f06
f0101a43:	68 25 03 00 00       	push   $0x325
f0101a48:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101a4d:	e8 39 e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a52:	83 ec 0c             	sub    $0xc,%esp
f0101a55:	6a 00                	push   $0x0
f0101a57:	e8 38 f4 ff ff       	call   f0100e94 <page_alloc>
f0101a5c:	83 c4 10             	add    $0x10,%esp
f0101a5f:	85 c0                	test   %eax,%eax
f0101a61:	74 19                	je     f0101a7c <mem_init+0x920>
f0101a63:	68 14 40 10 f0       	push   $0xf0104014
f0101a68:	68 06 3f 10 f0       	push   $0xf0103f06
f0101a6d:	68 29 03 00 00       	push   $0x329
f0101a72:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101a77:	e8 0f e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a7c:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101a82:	8b 02                	mov    (%edx),%eax
f0101a84:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a89:	89 c1                	mov    %eax,%ecx
f0101a8b:	c1 e9 0c             	shr    $0xc,%ecx
f0101a8e:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101a94:	72 15                	jb     f0101aab <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a96:	50                   	push   %eax
f0101a97:	68 7c 41 10 f0       	push   $0xf010417c
f0101a9c:	68 2c 03 00 00       	push   $0x32c
f0101aa1:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101aa6:	e8 e0 e5 ff ff       	call   f010008b <_panic>
f0101aab:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ab0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101ab3:	83 ec 04             	sub    $0x4,%esp
f0101ab6:	6a 00                	push   $0x0
f0101ab8:	68 00 10 00 00       	push   $0x1000
f0101abd:	52                   	push   %edx
f0101abe:	e8 a3 f4 ff ff       	call   f0100f66 <pgdir_walk>
f0101ac3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101ac6:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ac9:	83 c4 10             	add    $0x10,%esp
f0101acc:	39 d0                	cmp    %edx,%eax
f0101ace:	74 19                	je     f0101ae9 <mem_init+0x98d>
f0101ad0:	68 d4 44 10 f0       	push   $0xf01044d4
f0101ad5:	68 06 3f 10 f0       	push   $0xf0103f06
f0101ada:	68 2d 03 00 00       	push   $0x32d
f0101adf:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101ae4:	e8 a2 e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101ae9:	6a 06                	push   $0x6
f0101aeb:	68 00 10 00 00       	push   $0x1000
f0101af0:	56                   	push   %esi
f0101af1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101af7:	e8 fa f5 ff ff       	call   f01010f6 <page_insert>
f0101afc:	83 c4 10             	add    $0x10,%esp
f0101aff:	85 c0                	test   %eax,%eax
f0101b01:	74 19                	je     f0101b1c <mem_init+0x9c0>
f0101b03:	68 14 45 10 f0       	push   $0xf0104514
f0101b08:	68 06 3f 10 f0       	push   $0xf0103f06
f0101b0d:	68 30 03 00 00       	push   $0x330
f0101b12:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101b17:	e8 6f e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b1c:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101b22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b27:	89 f8                	mov    %edi,%eax
f0101b29:	e8 96 ef ff ff       	call   f0100ac4 <check_va2pa>
f0101b2e:	89 f2                	mov    %esi,%edx
f0101b30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101b36:	c1 fa 03             	sar    $0x3,%edx
f0101b39:	c1 e2 0c             	shl    $0xc,%edx
f0101b3c:	39 d0                	cmp    %edx,%eax
f0101b3e:	74 19                	je     f0101b59 <mem_init+0x9fd>
f0101b40:	68 a4 44 10 f0       	push   $0xf01044a4
f0101b45:	68 06 3f 10 f0       	push   $0xf0103f06
f0101b4a:	68 31 03 00 00       	push   $0x331
f0101b4f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101b54:	e8 32 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b59:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b5e:	74 19                	je     f0101b79 <mem_init+0xa1d>
f0101b60:	68 88 40 10 f0       	push   $0xf0104088
f0101b65:	68 06 3f 10 f0       	push   $0xf0103f06
f0101b6a:	68 32 03 00 00       	push   $0x332
f0101b6f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101b74:	e8 12 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101b79:	83 ec 04             	sub    $0x4,%esp
f0101b7c:	6a 00                	push   $0x0
f0101b7e:	68 00 10 00 00       	push   $0x1000
f0101b83:	57                   	push   %edi
f0101b84:	e8 dd f3 ff ff       	call   f0100f66 <pgdir_walk>
f0101b89:	83 c4 10             	add    $0x10,%esp
f0101b8c:	f6 00 04             	testb  $0x4,(%eax)
f0101b8f:	75 19                	jne    f0101baa <mem_init+0xa4e>
f0101b91:	68 58 45 10 f0       	push   $0xf0104558
f0101b96:	68 06 3f 10 f0       	push   $0xf0103f06
f0101b9b:	68 33 03 00 00       	push   $0x333
f0101ba0:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101ba5:	e8 e1 e4 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101baa:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101baf:	f6 00 04             	testb  $0x4,(%eax)
f0101bb2:	75 19                	jne    f0101bcd <mem_init+0xa71>
f0101bb4:	68 99 40 10 f0       	push   $0xf0104099
f0101bb9:	68 06 3f 10 f0       	push   $0xf0103f06
f0101bbe:	68 34 03 00 00       	push   $0x334
f0101bc3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101bc8:	e8 be e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101bcd:	6a 02                	push   $0x2
f0101bcf:	68 00 10 00 00       	push   $0x1000
f0101bd4:	56                   	push   %esi
f0101bd5:	50                   	push   %eax
f0101bd6:	e8 1b f5 ff ff       	call   f01010f6 <page_insert>
f0101bdb:	83 c4 10             	add    $0x10,%esp
f0101bde:	85 c0                	test   %eax,%eax
f0101be0:	74 19                	je     f0101bfb <mem_init+0xa9f>
f0101be2:	68 68 44 10 f0       	push   $0xf0104468
f0101be7:	68 06 3f 10 f0       	push   $0xf0103f06
f0101bec:	68 37 03 00 00       	push   $0x337
f0101bf1:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101bf6:	e8 90 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101bfb:	83 ec 04             	sub    $0x4,%esp
f0101bfe:	6a 00                	push   $0x0
f0101c00:	68 00 10 00 00       	push   $0x1000
f0101c05:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c0b:	e8 56 f3 ff ff       	call   f0100f66 <pgdir_walk>
f0101c10:	83 c4 10             	add    $0x10,%esp
f0101c13:	f6 00 02             	testb  $0x2,(%eax)
f0101c16:	75 19                	jne    f0101c31 <mem_init+0xad5>
f0101c18:	68 8c 45 10 f0       	push   $0xf010458c
f0101c1d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101c22:	68 38 03 00 00       	push   $0x338
f0101c27:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101c2c:	e8 5a e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101c31:	83 ec 04             	sub    $0x4,%esp
f0101c34:	6a 00                	push   $0x0
f0101c36:	68 00 10 00 00       	push   $0x1000
f0101c3b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c41:	e8 20 f3 ff ff       	call   f0100f66 <pgdir_walk>
f0101c46:	83 c4 10             	add    $0x10,%esp
f0101c49:	f6 00 04             	testb  $0x4,(%eax)
f0101c4c:	74 19                	je     f0101c67 <mem_init+0xb0b>
f0101c4e:	68 c0 45 10 f0       	push   $0xf01045c0
f0101c53:	68 06 3f 10 f0       	push   $0xf0103f06
f0101c58:	68 39 03 00 00       	push   $0x339
f0101c5d:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101c62:	e8 24 e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101c67:	6a 02                	push   $0x2
f0101c69:	68 00 00 40 00       	push   $0x400000
f0101c6e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c71:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c77:	e8 7a f4 ff ff       	call   f01010f6 <page_insert>
f0101c7c:	83 c4 10             	add    $0x10,%esp
f0101c7f:	85 c0                	test   %eax,%eax
f0101c81:	78 19                	js     f0101c9c <mem_init+0xb40>
f0101c83:	68 f8 45 10 f0       	push   $0xf01045f8
f0101c88:	68 06 3f 10 f0       	push   $0xf0103f06
f0101c8d:	68 3c 03 00 00       	push   $0x33c
f0101c92:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101c97:	e8 ef e3 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101c9c:	6a 02                	push   $0x2
f0101c9e:	68 00 10 00 00       	push   $0x1000
f0101ca3:	53                   	push   %ebx
f0101ca4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101caa:	e8 47 f4 ff ff       	call   f01010f6 <page_insert>
f0101caf:	83 c4 10             	add    $0x10,%esp
f0101cb2:	85 c0                	test   %eax,%eax
f0101cb4:	74 19                	je     f0101ccf <mem_init+0xb73>
f0101cb6:	68 30 46 10 f0       	push   $0xf0104630
f0101cbb:	68 06 3f 10 f0       	push   $0xf0103f06
f0101cc0:	68 3f 03 00 00       	push   $0x33f
f0101cc5:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101cca:	e8 bc e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101ccf:	83 ec 04             	sub    $0x4,%esp
f0101cd2:	6a 00                	push   $0x0
f0101cd4:	68 00 10 00 00       	push   $0x1000
f0101cd9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101cdf:	e8 82 f2 ff ff       	call   f0100f66 <pgdir_walk>
f0101ce4:	83 c4 10             	add    $0x10,%esp
f0101ce7:	f6 00 04             	testb  $0x4,(%eax)
f0101cea:	74 19                	je     f0101d05 <mem_init+0xba9>
f0101cec:	68 c0 45 10 f0       	push   $0xf01045c0
f0101cf1:	68 06 3f 10 f0       	push   $0xf0103f06
f0101cf6:	68 40 03 00 00       	push   $0x340
f0101cfb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101d00:	e8 86 e3 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d05:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d0b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d10:	89 f8                	mov    %edi,%eax
f0101d12:	e8 ad ed ff ff       	call   f0100ac4 <check_va2pa>
f0101d17:	89 c1                	mov    %eax,%ecx
f0101d19:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d1c:	89 d8                	mov    %ebx,%eax
f0101d1e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101d24:	c1 f8 03             	sar    $0x3,%eax
f0101d27:	c1 e0 0c             	shl    $0xc,%eax
f0101d2a:	39 c1                	cmp    %eax,%ecx
f0101d2c:	74 19                	je     f0101d47 <mem_init+0xbeb>
f0101d2e:	68 6c 46 10 f0       	push   $0xf010466c
f0101d33:	68 06 3f 10 f0       	push   $0xf0103f06
f0101d38:	68 43 03 00 00       	push   $0x343
f0101d3d:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101d42:	e8 44 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d47:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d4c:	89 f8                	mov    %edi,%eax
f0101d4e:	e8 71 ed ff ff       	call   f0100ac4 <check_va2pa>
f0101d53:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d56:	74 19                	je     f0101d71 <mem_init+0xc15>
f0101d58:	68 98 46 10 f0       	push   $0xf0104698
f0101d5d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101d62:	68 44 03 00 00       	push   $0x344
f0101d67:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101d6c:	e8 1a e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d71:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d76:	74 19                	je     f0101d91 <mem_init+0xc35>
f0101d78:	68 af 40 10 f0       	push   $0xf01040af
f0101d7d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101d82:	68 46 03 00 00       	push   $0x346
f0101d87:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101d8c:	e8 fa e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d91:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d96:	74 19                	je     f0101db1 <mem_init+0xc55>
f0101d98:	68 c0 40 10 f0       	push   $0xf01040c0
f0101d9d:	68 06 3f 10 f0       	push   $0xf0103f06
f0101da2:	68 47 03 00 00       	push   $0x347
f0101da7:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101dac:	e8 da e2 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101db1:	83 ec 0c             	sub    $0xc,%esp
f0101db4:	6a 00                	push   $0x0
f0101db6:	e8 d9 f0 ff ff       	call   f0100e94 <page_alloc>
f0101dbb:	83 c4 10             	add    $0x10,%esp
f0101dbe:	85 c0                	test   %eax,%eax
f0101dc0:	74 04                	je     f0101dc6 <mem_init+0xc6a>
f0101dc2:	39 c6                	cmp    %eax,%esi
f0101dc4:	74 19                	je     f0101ddf <mem_init+0xc83>
f0101dc6:	68 c8 46 10 f0       	push   $0xf01046c8
f0101dcb:	68 06 3f 10 f0       	push   $0xf0103f06
f0101dd0:	68 4a 03 00 00       	push   $0x34a
f0101dd5:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101dda:	e8 ac e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ddf:	83 ec 08             	sub    $0x8,%esp
f0101de2:	6a 00                	push   $0x0
f0101de4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101dea:	e8 c5 f2 ff ff       	call   f01010b4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101def:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101df5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dfa:	89 f8                	mov    %edi,%eax
f0101dfc:	e8 c3 ec ff ff       	call   f0100ac4 <check_va2pa>
f0101e01:	83 c4 10             	add    $0x10,%esp
f0101e04:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e07:	74 19                	je     f0101e22 <mem_init+0xcc6>
f0101e09:	68 ec 46 10 f0       	push   $0xf01046ec
f0101e0e:	68 06 3f 10 f0       	push   $0xf0103f06
f0101e13:	68 4e 03 00 00       	push   $0x34e
f0101e18:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101e1d:	e8 69 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e27:	89 f8                	mov    %edi,%eax
f0101e29:	e8 96 ec ff ff       	call   f0100ac4 <check_va2pa>
f0101e2e:	89 da                	mov    %ebx,%edx
f0101e30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101e36:	c1 fa 03             	sar    $0x3,%edx
f0101e39:	c1 e2 0c             	shl    $0xc,%edx
f0101e3c:	39 d0                	cmp    %edx,%eax
f0101e3e:	74 19                	je     f0101e59 <mem_init+0xcfd>
f0101e40:	68 98 46 10 f0       	push   $0xf0104698
f0101e45:	68 06 3f 10 f0       	push   $0xf0103f06
f0101e4a:	68 4f 03 00 00       	push   $0x34f
f0101e4f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101e54:	e8 32 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101e59:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e5e:	74 19                	je     f0101e79 <mem_init+0xd1d>
f0101e60:	68 66 40 10 f0       	push   $0xf0104066
f0101e65:	68 06 3f 10 f0       	push   $0xf0103f06
f0101e6a:	68 50 03 00 00       	push   $0x350
f0101e6f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101e74:	e8 12 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e79:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e7e:	74 19                	je     f0101e99 <mem_init+0xd3d>
f0101e80:	68 c0 40 10 f0       	push   $0xf01040c0
f0101e85:	68 06 3f 10 f0       	push   $0xf0103f06
f0101e8a:	68 51 03 00 00       	push   $0x351
f0101e8f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101e94:	e8 f2 e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101e99:	6a 00                	push   $0x0
f0101e9b:	68 00 10 00 00       	push   $0x1000
f0101ea0:	53                   	push   %ebx
f0101ea1:	57                   	push   %edi
f0101ea2:	e8 4f f2 ff ff       	call   f01010f6 <page_insert>
f0101ea7:	83 c4 10             	add    $0x10,%esp
f0101eaa:	85 c0                	test   %eax,%eax
f0101eac:	74 19                	je     f0101ec7 <mem_init+0xd6b>
f0101eae:	68 10 47 10 f0       	push   $0xf0104710
f0101eb3:	68 06 3f 10 f0       	push   $0xf0103f06
f0101eb8:	68 54 03 00 00       	push   $0x354
f0101ebd:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101ec2:	e8 c4 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101ec7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ecc:	75 19                	jne    f0101ee7 <mem_init+0xd8b>
f0101ece:	68 d1 40 10 f0       	push   $0xf01040d1
f0101ed3:	68 06 3f 10 f0       	push   $0xf0103f06
f0101ed8:	68 55 03 00 00       	push   $0x355
f0101edd:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101ee2:	e8 a4 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101ee7:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101eea:	74 19                	je     f0101f05 <mem_init+0xda9>
f0101eec:	68 dd 40 10 f0       	push   $0xf01040dd
f0101ef1:	68 06 3f 10 f0       	push   $0xf0103f06
f0101ef6:	68 56 03 00 00       	push   $0x356
f0101efb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101f00:	e8 86 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101f05:	83 ec 08             	sub    $0x8,%esp
f0101f08:	68 00 10 00 00       	push   $0x1000
f0101f0d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101f13:	e8 9c f1 ff ff       	call   f01010b4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f18:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101f1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f23:	89 f8                	mov    %edi,%eax
f0101f25:	e8 9a eb ff ff       	call   f0100ac4 <check_va2pa>
f0101f2a:	83 c4 10             	add    $0x10,%esp
f0101f2d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f30:	74 19                	je     f0101f4b <mem_init+0xdef>
f0101f32:	68 ec 46 10 f0       	push   $0xf01046ec
f0101f37:	68 06 3f 10 f0       	push   $0xf0103f06
f0101f3c:	68 5a 03 00 00       	push   $0x35a
f0101f41:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101f46:	e8 40 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f50:	89 f8                	mov    %edi,%eax
f0101f52:	e8 6d eb ff ff       	call   f0100ac4 <check_va2pa>
f0101f57:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f5a:	74 19                	je     f0101f75 <mem_init+0xe19>
f0101f5c:	68 48 47 10 f0       	push   $0xf0104748
f0101f61:	68 06 3f 10 f0       	push   $0xf0103f06
f0101f66:	68 5b 03 00 00       	push   $0x35b
f0101f6b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101f70:	e8 16 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101f75:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f7a:	74 19                	je     f0101f95 <mem_init+0xe39>
f0101f7c:	68 f2 40 10 f0       	push   $0xf01040f2
f0101f81:	68 06 3f 10 f0       	push   $0xf0103f06
f0101f86:	68 5c 03 00 00       	push   $0x35c
f0101f8b:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101f90:	e8 f6 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f95:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f9a:	74 19                	je     f0101fb5 <mem_init+0xe59>
f0101f9c:	68 c0 40 10 f0       	push   $0xf01040c0
f0101fa1:	68 06 3f 10 f0       	push   $0xf0103f06
f0101fa6:	68 5d 03 00 00       	push   $0x35d
f0101fab:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101fb0:	e8 d6 e0 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101fb5:	83 ec 0c             	sub    $0xc,%esp
f0101fb8:	6a 00                	push   $0x0
f0101fba:	e8 d5 ee ff ff       	call   f0100e94 <page_alloc>
f0101fbf:	83 c4 10             	add    $0x10,%esp
f0101fc2:	39 c3                	cmp    %eax,%ebx
f0101fc4:	75 04                	jne    f0101fca <mem_init+0xe6e>
f0101fc6:	85 c0                	test   %eax,%eax
f0101fc8:	75 19                	jne    f0101fe3 <mem_init+0xe87>
f0101fca:	68 70 47 10 f0       	push   $0xf0104770
f0101fcf:	68 06 3f 10 f0       	push   $0xf0103f06
f0101fd4:	68 60 03 00 00       	push   $0x360
f0101fd9:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101fde:	e8 a8 e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101fe3:	83 ec 0c             	sub    $0xc,%esp
f0101fe6:	6a 00                	push   $0x0
f0101fe8:	e8 a7 ee ff ff       	call   f0100e94 <page_alloc>
f0101fed:	83 c4 10             	add    $0x10,%esp
f0101ff0:	85 c0                	test   %eax,%eax
f0101ff2:	74 19                	je     f010200d <mem_init+0xeb1>
f0101ff4:	68 14 40 10 f0       	push   $0xf0104014
f0101ff9:	68 06 3f 10 f0       	push   $0xf0103f06
f0101ffe:	68 63 03 00 00       	push   $0x363
f0102003:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102008:	e8 7e e0 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010200d:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102013:	8b 11                	mov    (%ecx),%edx
f0102015:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010201b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010201e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102024:	c1 f8 03             	sar    $0x3,%eax
f0102027:	c1 e0 0c             	shl    $0xc,%eax
f010202a:	39 c2                	cmp    %eax,%edx
f010202c:	74 19                	je     f0102047 <mem_init+0xeeb>
f010202e:	68 10 44 10 f0       	push   $0xf0104410
f0102033:	68 06 3f 10 f0       	push   $0xf0103f06
f0102038:	68 66 03 00 00       	push   $0x366
f010203d:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102042:	e8 44 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102047:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010204d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102050:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102055:	74 19                	je     f0102070 <mem_init+0xf14>
f0102057:	68 77 40 10 f0       	push   $0xf0104077
f010205c:	68 06 3f 10 f0       	push   $0xf0103f06
f0102061:	68 68 03 00 00       	push   $0x368
f0102066:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010206b:	e8 1b e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102070:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102073:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102079:	83 ec 0c             	sub    $0xc,%esp
f010207c:	50                   	push   %eax
f010207d:	e8 82 ee ff ff       	call   f0100f04 <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102082:	83 c4 0c             	add    $0xc,%esp
f0102085:	6a 01                	push   $0x1
f0102087:	68 00 10 40 00       	push   $0x401000
f010208c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102092:	e8 cf ee ff ff       	call   f0100f66 <pgdir_walk>
f0102097:	89 c7                	mov    %eax,%edi
f0102099:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010209c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020a1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020a4:	8b 40 04             	mov    0x4(%eax),%eax
f01020a7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020ac:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01020b2:	89 c2                	mov    %eax,%edx
f01020b4:	c1 ea 0c             	shr    $0xc,%edx
f01020b7:	83 c4 10             	add    $0x10,%esp
f01020ba:	39 ca                	cmp    %ecx,%edx
f01020bc:	72 15                	jb     f01020d3 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020be:	50                   	push   %eax
f01020bf:	68 7c 41 10 f0       	push   $0xf010417c
f01020c4:	68 6f 03 00 00       	push   $0x36f
f01020c9:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01020ce:	e8 b8 df ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f01020d3:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01020d8:	39 c7                	cmp    %eax,%edi
f01020da:	74 19                	je     f01020f5 <mem_init+0xf99>
f01020dc:	68 03 41 10 f0       	push   $0xf0104103
f01020e1:	68 06 3f 10 f0       	push   $0xf0103f06
f01020e6:	68 70 03 00 00       	push   $0x370
f01020eb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01020f0:	e8 96 df ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f01020f5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020f8:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01020ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102102:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102108:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010210e:	c1 f8 03             	sar    $0x3,%eax
f0102111:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102114:	89 c2                	mov    %eax,%edx
f0102116:	c1 ea 0c             	shr    $0xc,%edx
f0102119:	39 d1                	cmp    %edx,%ecx
f010211b:	77 12                	ja     f010212f <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010211d:	50                   	push   %eax
f010211e:	68 7c 41 10 f0       	push   $0xf010417c
f0102123:	6a 57                	push   $0x57
f0102125:	68 ec 3e 10 f0       	push   $0xf0103eec
f010212a:	e8 5c df ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010212f:	83 ec 04             	sub    $0x4,%esp
f0102132:	68 00 10 00 00       	push   $0x1000
f0102137:	68 ff 00 00 00       	push   $0xff
f010213c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102141:	50                   	push   %eax
f0102142:	e8 77 12 00 00       	call   f01033be <memset>
	page_free(pp0);
f0102147:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010214a:	89 3c 24             	mov    %edi,(%esp)
f010214d:	e8 b2 ed ff ff       	call   f0100f04 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102152:	83 c4 0c             	add    $0xc,%esp
f0102155:	6a 01                	push   $0x1
f0102157:	6a 00                	push   $0x0
f0102159:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010215f:	e8 02 ee ff ff       	call   f0100f66 <pgdir_walk>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102164:	89 fa                	mov    %edi,%edx
f0102166:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010216c:	c1 fa 03             	sar    $0x3,%edx
f010216f:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102172:	89 d0                	mov    %edx,%eax
f0102174:	c1 e8 0c             	shr    $0xc,%eax
f0102177:	83 c4 10             	add    $0x10,%esp
f010217a:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102180:	72 12                	jb     f0102194 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102182:	52                   	push   %edx
f0102183:	68 7c 41 10 f0       	push   $0xf010417c
f0102188:	6a 57                	push   $0x57
f010218a:	68 ec 3e 10 f0       	push   $0xf0103eec
f010218f:	e8 f7 de ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102194:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f010219a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010219d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021a3:	f6 00 01             	testb  $0x1,(%eax)
f01021a6:	74 19                	je     f01021c1 <mem_init+0x1065>
f01021a8:	68 1b 41 10 f0       	push   $0xf010411b
f01021ad:	68 06 3f 10 f0       	push   $0xf0103f06
f01021b2:	68 7a 03 00 00       	push   $0x37a
f01021b7:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01021bc:	e8 ca de ff ff       	call   f010008b <_panic>
f01021c1:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f01021c4:	39 d0                	cmp    %edx,%eax
f01021c6:	75 db                	jne    f01021a3 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01021c8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021d6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021dc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01021df:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01021e5:	83 ec 0c             	sub    $0xc,%esp
f01021e8:	50                   	push   %eax
f01021e9:	e8 16 ed ff ff       	call   f0100f04 <page_free>
	page_free(pp1);
f01021ee:	89 1c 24             	mov    %ebx,(%esp)
f01021f1:	e8 0e ed ff ff       	call   f0100f04 <page_free>
	page_free(pp2);
f01021f6:	89 34 24             	mov    %esi,(%esp)
f01021f9:	e8 06 ed ff ff       	call   f0100f04 <page_free>

	cprintf("check_page() succeeded!\n");
f01021fe:	c7 04 24 32 41 10 f0 	movl   $0xf0104132,(%esp)
f0102205:	e8 4b 06 00 00       	call   f0102855 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	// 映射 upages,upages+ptsize 到pages，pages+ptsize上
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f010220a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010220f:	83 c4 10             	add    $0x10,%esp
f0102212:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102217:	77 15                	ja     f010222e <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102219:	50                   	push   %eax
f010221a:	68 5c 42 10 f0       	push   $0xf010425c
f010221f:	68 b5 00 00 00       	push   $0xb5
f0102224:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102229:	e8 5d de ff ff       	call   f010008b <_panic>
f010222e:	83 ec 08             	sub    $0x8,%esp
f0102231:	6a 04                	push   $0x4
f0102233:	05 00 00 00 10       	add    $0x10000000,%eax
f0102238:	50                   	push   %eax
f0102239:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010223e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102243:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102248:	e8 ad ed ff ff       	call   f0100ffa <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010224d:	83 c4 10             	add    $0x10,%esp
f0102250:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102255:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010225a:	77 15                	ja     f0102271 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010225c:	50                   	push   %eax
f010225d:	68 5c 42 10 f0       	push   $0xf010425c
f0102262:	68 c2 00 00 00       	push   $0xc2
f0102267:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010226c:	e8 1a de ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102271:	83 ec 08             	sub    $0x8,%esp
f0102274:	6a 02                	push   $0x2
f0102276:	68 00 d0 10 00       	push   $0x10d000
f010227b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102280:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102285:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010228a:	e8 6b ed ff ff       	call   f0100ffa <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0,PTE_W);
f010228f:	83 c4 08             	add    $0x8,%esp
f0102292:	6a 02                	push   $0x2
f0102294:	6a 00                	push   $0x0
f0102296:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010229b:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022a0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01022a5:	e8 50 ed ff ff       	call   f0100ffa <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01022aa:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f01022b0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01022b5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022b8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022c7:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022cd:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01022d0:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022d3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01022d8:	eb 55                	jmp    f010232f <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022da:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01022e0:	89 f0                	mov    %esi,%eax
f01022e2:	e8 dd e7 ff ff       	call   f0100ac4 <check_va2pa>
f01022e7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022ee:	77 15                	ja     f0102305 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022f0:	57                   	push   %edi
f01022f1:	68 5c 42 10 f0       	push   $0xf010425c
f01022f6:	68 ba 02 00 00       	push   $0x2ba
f01022fb:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102300:	e8 86 dd ff ff       	call   f010008b <_panic>
f0102305:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010230c:	39 c2                	cmp    %eax,%edx
f010230e:	74 19                	je     f0102329 <mem_init+0x11cd>
f0102310:	68 94 47 10 f0       	push   $0xf0104794
f0102315:	68 06 3f 10 f0       	push   $0xf0103f06
f010231a:	68 ba 02 00 00       	push   $0x2ba
f010231f:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102324:	e8 62 dd ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102329:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010232f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102332:	77 a6                	ja     f01022da <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102334:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102337:	c1 e7 0c             	shl    $0xc,%edi
f010233a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010233f:	eb 30                	jmp    f0102371 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102341:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102347:	89 f0                	mov    %esi,%eax
f0102349:	e8 76 e7 ff ff       	call   f0100ac4 <check_va2pa>
f010234e:	39 c3                	cmp    %eax,%ebx
f0102350:	74 19                	je     f010236b <mem_init+0x120f>
f0102352:	68 c8 47 10 f0       	push   $0xf01047c8
f0102357:	68 06 3f 10 f0       	push   $0xf0103f06
f010235c:	68 be 02 00 00       	push   $0x2be
f0102361:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102366:	e8 20 dd ff ff       	call   f010008b <_panic>
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010236b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102371:	39 fb                	cmp    %edi,%ebx
f0102373:	72 cc                	jb     f0102341 <mem_init+0x11e5>
f0102375:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010237a:	89 da                	mov    %ebx,%edx
f010237c:	89 f0                	mov    %esi,%eax
f010237e:	e8 41 e7 ff ff       	call   f0100ac4 <check_va2pa>
f0102383:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102389:	39 c2                	cmp    %eax,%edx
f010238b:	74 19                	je     f01023a6 <mem_init+0x124a>
f010238d:	68 f0 47 10 f0       	push   $0xf01047f0
f0102392:	68 06 3f 10 f0       	push   $0xf0103f06
f0102397:	68 c2 02 00 00       	push   $0x2c2
f010239c:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01023a1:	e8 e5 dc ff ff       	call   f010008b <_panic>
f01023a6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023ac:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01023b2:	75 c6                	jne    f010237a <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023b4:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023b9:	89 f0                	mov    %esi,%eax
f01023bb:	e8 04 e7 ff ff       	call   f0100ac4 <check_va2pa>
f01023c0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023c3:	74 51                	je     f0102416 <mem_init+0x12ba>
f01023c5:	68 38 48 10 f0       	push   $0xf0104838
f01023ca:	68 06 3f 10 f0       	push   $0xf0103f06
f01023cf:	68 c3 02 00 00       	push   $0x2c3
f01023d4:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01023d9:	e8 ad dc ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f01023de:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01023e3:	72 36                	jb     f010241b <mem_init+0x12bf>
f01023e5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023ea:	76 07                	jbe    f01023f3 <mem_init+0x1297>
f01023ec:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023f1:	75 28                	jne    f010241b <mem_init+0x12bf>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01023f3:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01023f7:	0f 85 83 00 00 00    	jne    f0102480 <mem_init+0x1324>
f01023fd:	68 4b 41 10 f0       	push   $0xf010414b
f0102402:	68 06 3f 10 f0       	push   $0xf0103f06
f0102407:	68 cd 02 00 00       	push   $0x2cd
f010240c:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102411:	e8 75 dc ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102416:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE))
f010241b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102420:	76 3f                	jbe    f0102461 <mem_init+0x1305>
			{
				assert(pgdir[i] & PTE_P);
f0102422:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102425:	f6 c2 01             	test   $0x1,%dl
f0102428:	75 19                	jne    f0102443 <mem_init+0x12e7>
f010242a:	68 4b 41 10 f0       	push   $0xf010414b
f010242f:	68 06 3f 10 f0       	push   $0xf0103f06
f0102434:	68 d2 02 00 00       	push   $0x2d2
f0102439:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010243e:	e8 48 dc ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102443:	f6 c2 02             	test   $0x2,%dl
f0102446:	75 38                	jne    f0102480 <mem_init+0x1324>
f0102448:	68 5c 41 10 f0       	push   $0xf010415c
f010244d:	68 06 3f 10 f0       	push   $0xf0103f06
f0102452:	68 d3 02 00 00       	push   $0x2d3
f0102457:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010245c:	e8 2a dc ff ff       	call   f010008b <_panic>
			}
			else
				assert(pgdir[i] == 0);
f0102461:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102465:	74 19                	je     f0102480 <mem_init+0x1324>
f0102467:	68 6d 41 10 f0       	push   $0xf010416d
f010246c:	68 06 3f 10 f0       	push   $0xf0103f06
f0102471:	68 d6 02 00 00       	push   $0x2d6
f0102476:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010247b:	e8 0b dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102480:	83 c0 01             	add    $0x1,%eax
f0102483:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102488:	0f 86 50 ff ff ff    	jbe    f01023de <mem_init+0x1282>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010248e:	83 ec 0c             	sub    $0xc,%esp
f0102491:	68 68 48 10 f0       	push   $0xf0104868
f0102496:	e8 ba 03 00 00       	call   f0102855 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010249b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024a0:	83 c4 10             	add    $0x10,%esp
f01024a3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024a8:	77 15                	ja     f01024bf <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024aa:	50                   	push   %eax
f01024ab:	68 5c 42 10 f0       	push   $0xf010425c
f01024b0:	68 d6 00 00 00       	push   $0xd6
f01024b5:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01024ba:	e8 cc db ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024bf:	05 00 00 00 10       	add    $0x10000000,%eax
f01024c4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01024cc:	e8 57 e6 ff ff       	call   f0100b28 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024d1:	0f 20 c0             	mov    %cr0,%eax
f01024d4:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024d7:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024dc:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024df:	83 ec 0c             	sub    $0xc,%esp
f01024e2:	6a 00                	push   $0x0
f01024e4:	e8 ab e9 ff ff       	call   f0100e94 <page_alloc>
f01024e9:	89 c3                	mov    %eax,%ebx
f01024eb:	83 c4 10             	add    $0x10,%esp
f01024ee:	85 c0                	test   %eax,%eax
f01024f0:	75 19                	jne    f010250b <mem_init+0x13af>
f01024f2:	68 c0 3f 10 f0       	push   $0xf0103fc0
f01024f7:	68 06 3f 10 f0       	push   $0xf0103f06
f01024fc:	68 95 03 00 00       	push   $0x395
f0102501:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102506:	e8 80 db ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010250b:	83 ec 0c             	sub    $0xc,%esp
f010250e:	6a 00                	push   $0x0
f0102510:	e8 7f e9 ff ff       	call   f0100e94 <page_alloc>
f0102515:	89 c7                	mov    %eax,%edi
f0102517:	83 c4 10             	add    $0x10,%esp
f010251a:	85 c0                	test   %eax,%eax
f010251c:	75 19                	jne    f0102537 <mem_init+0x13db>
f010251e:	68 d6 3f 10 f0       	push   $0xf0103fd6
f0102523:	68 06 3f 10 f0       	push   $0xf0103f06
f0102528:	68 96 03 00 00       	push   $0x396
f010252d:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102532:	e8 54 db ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102537:	83 ec 0c             	sub    $0xc,%esp
f010253a:	6a 00                	push   $0x0
f010253c:	e8 53 e9 ff ff       	call   f0100e94 <page_alloc>
f0102541:	89 c6                	mov    %eax,%esi
f0102543:	83 c4 10             	add    $0x10,%esp
f0102546:	85 c0                	test   %eax,%eax
f0102548:	75 19                	jne    f0102563 <mem_init+0x1407>
f010254a:	68 ec 3f 10 f0       	push   $0xf0103fec
f010254f:	68 06 3f 10 f0       	push   $0xf0103f06
f0102554:	68 97 03 00 00       	push   $0x397
f0102559:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010255e:	e8 28 db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102563:	83 ec 0c             	sub    $0xc,%esp
f0102566:	53                   	push   %ebx
f0102567:	e8 98 e9 ff ff       	call   f0100f04 <page_free>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010256c:	89 f8                	mov    %edi,%eax
f010256e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102574:	c1 f8 03             	sar    $0x3,%eax
f0102577:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010257a:	89 c2                	mov    %eax,%edx
f010257c:	c1 ea 0c             	shr    $0xc,%edx
f010257f:	83 c4 10             	add    $0x10,%esp
f0102582:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102588:	72 12                	jb     f010259c <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010258a:	50                   	push   %eax
f010258b:	68 7c 41 10 f0       	push   $0xf010417c
f0102590:	6a 57                	push   $0x57
f0102592:	68 ec 3e 10 f0       	push   $0xf0103eec
f0102597:	e8 ef da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010259c:	83 ec 04             	sub    $0x4,%esp
f010259f:	68 00 10 00 00       	push   $0x1000
f01025a4:	6a 01                	push   $0x1
f01025a6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025ab:	50                   	push   %eax
f01025ac:	e8 0d 0e 00 00       	call   f01033be <memset>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01025b1:	89 f0                	mov    %esi,%eax
f01025b3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01025b9:	c1 f8 03             	sar    $0x3,%eax
f01025bc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025bf:	89 c2                	mov    %eax,%edx
f01025c1:	c1 ea 0c             	shr    $0xc,%edx
f01025c4:	83 c4 10             	add    $0x10,%esp
f01025c7:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01025cd:	72 12                	jb     f01025e1 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025cf:	50                   	push   %eax
f01025d0:	68 7c 41 10 f0       	push   $0xf010417c
f01025d5:	6a 57                	push   $0x57
f01025d7:	68 ec 3e 10 f0       	push   $0xf0103eec
f01025dc:	e8 aa da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025e1:	83 ec 04             	sub    $0x4,%esp
f01025e4:	68 00 10 00 00       	push   $0x1000
f01025e9:	6a 02                	push   $0x2
f01025eb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025f0:	50                   	push   %eax
f01025f1:	e8 c8 0d 00 00       	call   f01033be <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f01025f6:	6a 02                	push   $0x2
f01025f8:	68 00 10 00 00       	push   $0x1000
f01025fd:	57                   	push   %edi
f01025fe:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102604:	e8 ed ea ff ff       	call   f01010f6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102609:	83 c4 20             	add    $0x20,%esp
f010260c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102611:	74 19                	je     f010262c <mem_init+0x14d0>
f0102613:	68 66 40 10 f0       	push   $0xf0104066
f0102618:	68 06 3f 10 f0       	push   $0xf0103f06
f010261d:	68 9c 03 00 00       	push   $0x39c
f0102622:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102627:	e8 5f da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010262c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102633:	01 01 01 
f0102636:	74 19                	je     f0102651 <mem_init+0x14f5>
f0102638:	68 88 48 10 f0       	push   $0xf0104888
f010263d:	68 06 3f 10 f0       	push   $0xf0103f06
f0102642:	68 9d 03 00 00       	push   $0x39d
f0102647:	68 e0 3e 10 f0       	push   $0xf0103ee0
f010264c:	e8 3a da ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102651:	6a 02                	push   $0x2
f0102653:	68 00 10 00 00       	push   $0x1000
f0102658:	56                   	push   %esi
f0102659:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010265f:	e8 92 ea ff ff       	call   f01010f6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102664:	83 c4 10             	add    $0x10,%esp
f0102667:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010266e:	02 02 02 
f0102671:	74 19                	je     f010268c <mem_init+0x1530>
f0102673:	68 ac 48 10 f0       	push   $0xf01048ac
f0102678:	68 06 3f 10 f0       	push   $0xf0103f06
f010267d:	68 9f 03 00 00       	push   $0x39f
f0102682:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102687:	e8 ff d9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010268c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102691:	74 19                	je     f01026ac <mem_init+0x1550>
f0102693:	68 88 40 10 f0       	push   $0xf0104088
f0102698:	68 06 3f 10 f0       	push   $0xf0103f06
f010269d:	68 a0 03 00 00       	push   $0x3a0
f01026a2:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01026a7:	e8 df d9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01026ac:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026b1:	74 19                	je     f01026cc <mem_init+0x1570>
f01026b3:	68 f2 40 10 f0       	push   $0xf01040f2
f01026b8:	68 06 3f 10 f0       	push   $0xf0103f06
f01026bd:	68 a1 03 00 00       	push   $0x3a1
f01026c2:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01026c7:	e8 bf d9 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026cc:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026d3:	03 03 03 

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01026d6:	89 f0                	mov    %esi,%eax
f01026d8:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026de:	c1 f8 03             	sar    $0x3,%eax
f01026e1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026e4:	89 c2                	mov    %eax,%edx
f01026e6:	c1 ea 0c             	shr    $0xc,%edx
f01026e9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01026ef:	72 12                	jb     f0102703 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026f1:	50                   	push   %eax
f01026f2:	68 7c 41 10 f0       	push   $0xf010417c
f01026f7:	6a 57                	push   $0x57
f01026f9:	68 ec 3e 10 f0       	push   $0xf0103eec
f01026fe:	e8 88 d9 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102703:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010270a:	03 03 03 
f010270d:	74 19                	je     f0102728 <mem_init+0x15cc>
f010270f:	68 d0 48 10 f0       	push   $0xf01048d0
f0102714:	68 06 3f 10 f0       	push   $0xf0103f06
f0102719:	68 a3 03 00 00       	push   $0x3a3
f010271e:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102723:	e8 63 d9 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f0102728:	83 ec 08             	sub    $0x8,%esp
f010272b:	68 00 10 00 00       	push   $0x1000
f0102730:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102736:	e8 79 e9 ff ff       	call   f01010b4 <page_remove>
	assert(pp2->pp_ref == 0);
f010273b:	83 c4 10             	add    $0x10,%esp
f010273e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102743:	74 19                	je     f010275e <mem_init+0x1602>
f0102745:	68 c0 40 10 f0       	push   $0xf01040c0
f010274a:	68 06 3f 10 f0       	push   $0xf0103f06
f010274f:	68 a5 03 00 00       	push   $0x3a5
f0102754:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102759:	e8 2d d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010275e:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102764:	8b 11                	mov    (%ecx),%edx
f0102766:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010276c:	89 d8                	mov    %ebx,%eax
f010276e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102774:	c1 f8 03             	sar    $0x3,%eax
f0102777:	c1 e0 0c             	shl    $0xc,%eax
f010277a:	39 c2                	cmp    %eax,%edx
f010277c:	74 19                	je     f0102797 <mem_init+0x163b>
f010277e:	68 10 44 10 f0       	push   $0xf0104410
f0102783:	68 06 3f 10 f0       	push   $0xf0103f06
f0102788:	68 a8 03 00 00       	push   $0x3a8
f010278d:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0102792:	e8 f4 d8 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102797:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010279d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027a2:	74 19                	je     f01027bd <mem_init+0x1661>
f01027a4:	68 77 40 10 f0       	push   $0xf0104077
f01027a9:	68 06 3f 10 f0       	push   $0xf0103f06
f01027ae:	68 aa 03 00 00       	push   $0x3aa
f01027b3:	68 e0 3e 10 f0       	push   $0xf0103ee0
f01027b8:	e8 ce d8 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01027bd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027c3:	83 ec 0c             	sub    $0xc,%esp
f01027c6:	53                   	push   %ebx
f01027c7:	e8 38 e7 ff ff       	call   f0100f04 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027cc:	c7 04 24 fc 48 10 f0 	movl   $0xf01048fc,(%esp)
f01027d3:	e8 7d 00 00 00       	call   f0102855 <cprintf>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027d8:	83 c4 10             	add    $0x10,%esp
f01027db:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027de:	5b                   	pop    %ebx
f01027df:	5e                   	pop    %esi
f01027e0:	5f                   	pop    %edi
f01027e1:	5d                   	pop    %ebp
f01027e2:	c3                   	ret    

f01027e3 <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f01027e3:	55                   	push   %ebp
f01027e4:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027e9:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027ec:	5d                   	pop    %ebp
f01027ed:	c3                   	ret    

f01027ee <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01027ee:	55                   	push   %ebp
f01027ef:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027f1:	ba 70 00 00 00       	mov    $0x70,%edx
f01027f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01027f9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01027fa:	ba 71 00 00 00       	mov    $0x71,%edx
f01027ff:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102800:	0f b6 c0             	movzbl %al,%eax
}
f0102803:	5d                   	pop    %ebp
f0102804:	c3                   	ret    

f0102805 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102805:	55                   	push   %ebp
f0102806:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102808:	ba 70 00 00 00       	mov    $0x70,%edx
f010280d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102810:	ee                   	out    %al,(%dx)
f0102811:	ba 71 00 00 00       	mov    $0x71,%edx
f0102816:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102819:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010281a:	5d                   	pop    %ebp
f010281b:	c3                   	ret    

f010281c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010281c:	55                   	push   %ebp
f010281d:	89 e5                	mov    %esp,%ebp
f010281f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102822:	ff 75 08             	pushl  0x8(%ebp)
f0102825:	e8 c8 dd ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f010282a:	83 c4 10             	add    $0x10,%esp
f010282d:	c9                   	leave  
f010282e:	c3                   	ret    

f010282f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010282f:	55                   	push   %ebp
f0102830:	89 e5                	mov    %esp,%ebp
f0102832:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102835:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010283c:	ff 75 0c             	pushl  0xc(%ebp)
f010283f:	ff 75 08             	pushl  0x8(%ebp)
f0102842:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102845:	50                   	push   %eax
f0102846:	68 1c 28 10 f0       	push   $0xf010281c
f010284b:	e8 21 04 00 00       	call   f0102c71 <vprintfmt>
	return cnt;
}
f0102850:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102853:	c9                   	leave  
f0102854:	c3                   	ret    

f0102855 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102855:	55                   	push   %ebp
f0102856:	89 e5                	mov    %esp,%ebp
f0102858:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010285b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010285e:	50                   	push   %eax
f010285f:	ff 75 08             	pushl  0x8(%ebp)
f0102862:	e8 c8 ff ff ff       	call   f010282f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102867:	c9                   	leave  
f0102868:	c3                   	ret    

f0102869 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102869:	55                   	push   %ebp
f010286a:	89 e5                	mov    %esp,%ebp
f010286c:	57                   	push   %edi
f010286d:	56                   	push   %esi
f010286e:	53                   	push   %ebx
f010286f:	83 ec 14             	sub    $0x14,%esp
f0102872:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102875:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102878:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010287b:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010287e:	8b 1a                	mov    (%edx),%ebx
f0102880:	8b 01                	mov    (%ecx),%eax
f0102882:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102885:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010288c:	eb 7f                	jmp    f010290d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010288e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102891:	01 d8                	add    %ebx,%eax
f0102893:	89 c6                	mov    %eax,%esi
f0102895:	c1 ee 1f             	shr    $0x1f,%esi
f0102898:	01 c6                	add    %eax,%esi
f010289a:	d1 fe                	sar    %esi
f010289c:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010289f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028a2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01028a5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028a7:	eb 03                	jmp    f01028ac <stab_binsearch+0x43>
			m--;
f01028a9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028ac:	39 c3                	cmp    %eax,%ebx
f01028ae:	7f 0d                	jg     f01028bd <stab_binsearch+0x54>
f01028b0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01028b4:	83 ea 0c             	sub    $0xc,%edx
f01028b7:	39 f9                	cmp    %edi,%ecx
f01028b9:	75 ee                	jne    f01028a9 <stab_binsearch+0x40>
f01028bb:	eb 05                	jmp    f01028c2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01028bd:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01028c0:	eb 4b                	jmp    f010290d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01028c2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01028c5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028c8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01028cc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01028cf:	76 11                	jbe    f01028e2 <stab_binsearch+0x79>
			*region_left = m;
f01028d1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01028d4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01028d6:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028d9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028e0:	eb 2b                	jmp    f010290d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01028e2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01028e5:	73 14                	jae    f01028fb <stab_binsearch+0x92>
			*region_right = m - 1;
f01028e7:	83 e8 01             	sub    $0x1,%eax
f01028ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028f0:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028f2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028f9:	eb 12                	jmp    f010290d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01028fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028fe:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102900:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102904:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102906:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010290d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102910:	0f 8e 78 ff ff ff    	jle    f010288e <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102916:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010291a:	75 0f                	jne    f010292b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010291c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010291f:	8b 00                	mov    (%eax),%eax
f0102921:	83 e8 01             	sub    $0x1,%eax
f0102924:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102927:	89 06                	mov    %eax,(%esi)
f0102929:	eb 2c                	jmp    f0102957 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010292b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010292e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102930:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102933:	8b 0e                	mov    (%esi),%ecx
f0102935:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102938:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010293b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010293e:	eb 03                	jmp    f0102943 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102940:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102943:	39 c8                	cmp    %ecx,%eax
f0102945:	7e 0b                	jle    f0102952 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102947:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010294b:	83 ea 0c             	sub    $0xc,%edx
f010294e:	39 df                	cmp    %ebx,%edi
f0102950:	75 ee                	jne    f0102940 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102952:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102955:	89 06                	mov    %eax,(%esi)
	}
}
f0102957:	83 c4 14             	add    $0x14,%esp
f010295a:	5b                   	pop    %ebx
f010295b:	5e                   	pop    %esi
f010295c:	5f                   	pop    %edi
f010295d:	5d                   	pop    %ebp
f010295e:	c3                   	ret    

f010295f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010295f:	55                   	push   %ebp
f0102960:	89 e5                	mov    %esp,%ebp
f0102962:	57                   	push   %edi
f0102963:	56                   	push   %esi
f0102964:	53                   	push   %ebx
f0102965:	83 ec 3c             	sub    $0x3c,%esp
f0102968:	8b 75 08             	mov    0x8(%ebp),%esi
f010296b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010296e:	c7 03 28 49 10 f0    	movl   $0xf0104928,(%ebx)
	info->eip_line = 0;
f0102974:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010297b:	c7 43 08 28 49 10 f0 	movl   $0xf0104928,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102982:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102989:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010298c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102993:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102999:	76 11                	jbe    f01029ac <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010299b:	b8 f8 c5 10 f0       	mov    $0xf010c5f8,%eax
f01029a0:	3d b1 a7 10 f0       	cmp    $0xf010a7b1,%eax
f01029a5:	77 19                	ja     f01029c0 <debuginfo_eip+0x61>
f01029a7:	e9 ba 01 00 00       	jmp    f0102b66 <debuginfo_eip+0x207>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01029ac:	83 ec 04             	sub    $0x4,%esp
f01029af:	68 32 49 10 f0       	push   $0xf0104932
f01029b4:	6a 7f                	push   $0x7f
f01029b6:	68 3f 49 10 f0       	push   $0xf010493f
f01029bb:	e8 cb d6 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01029c0:	80 3d f7 c5 10 f0 00 	cmpb   $0x0,0xf010c5f7
f01029c7:	0f 85 a0 01 00 00    	jne    f0102b6d <debuginfo_eip+0x20e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01029cd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01029d4:	b8 b0 a7 10 f0       	mov    $0xf010a7b0,%eax
f01029d9:	2d 70 4b 10 f0       	sub    $0xf0104b70,%eax
f01029de:	c1 f8 02             	sar    $0x2,%eax
f01029e1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01029e7:	83 e8 01             	sub    $0x1,%eax
f01029ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01029ed:	83 ec 08             	sub    $0x8,%esp
f01029f0:	56                   	push   %esi
f01029f1:	6a 64                	push   $0x64
f01029f3:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01029f6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01029f9:	b8 70 4b 10 f0       	mov    $0xf0104b70,%eax
f01029fe:	e8 66 fe ff ff       	call   f0102869 <stab_binsearch>
	if (lfile == 0)
f0102a03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a06:	83 c4 10             	add    $0x10,%esp
f0102a09:	85 c0                	test   %eax,%eax
f0102a0b:	0f 84 63 01 00 00    	je     f0102b74 <debuginfo_eip+0x215>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102a11:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102a14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a17:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102a1a:	83 ec 08             	sub    $0x8,%esp
f0102a1d:	56                   	push   %esi
f0102a1e:	6a 24                	push   $0x24
f0102a20:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102a23:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102a26:	b8 70 4b 10 f0       	mov    $0xf0104b70,%eax
f0102a2b:	e8 39 fe ff ff       	call   f0102869 <stab_binsearch>

	if (lfun <= rfun) {
f0102a30:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a33:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a36:	83 c4 10             	add    $0x10,%esp
f0102a39:	39 d0                	cmp    %edx,%eax
f0102a3b:	7f 40                	jg     f0102a7d <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102a3d:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102a40:	c1 e1 02             	shl    $0x2,%ecx
f0102a43:	8d b9 70 4b 10 f0    	lea    -0xfefb490(%ecx),%edi
f0102a49:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102a4c:	8b b9 70 4b 10 f0    	mov    -0xfefb490(%ecx),%edi
f0102a52:	b9 f8 c5 10 f0       	mov    $0xf010c5f8,%ecx
f0102a57:	81 e9 b1 a7 10 f0    	sub    $0xf010a7b1,%ecx
f0102a5d:	39 cf                	cmp    %ecx,%edi
f0102a5f:	73 09                	jae    f0102a6a <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102a61:	81 c7 b1 a7 10 f0    	add    $0xf010a7b1,%edi
f0102a67:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102a6a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a6d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102a70:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102a73:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102a75:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102a78:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a7b:	eb 0f                	jmp    f0102a8c <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102a7d:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102a80:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102a86:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a89:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102a8c:	83 ec 08             	sub    $0x8,%esp
f0102a8f:	6a 3a                	push   $0x3a
f0102a91:	ff 73 08             	pushl  0x8(%ebx)
f0102a94:	e8 09 09 00 00       	call   f01033a2 <strfind>
f0102a99:	2b 43 08             	sub    0x8(%ebx),%eax
f0102a9c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102a9f:	83 c4 08             	add    $0x8,%esp
f0102aa2:	56                   	push   %esi
f0102aa3:	6a 44                	push   $0x44
f0102aa5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102aa8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102aab:	b8 70 4b 10 f0       	mov    $0xf0104b70,%eax
f0102ab0:	e8 b4 fd ff ff       	call   f0102869 <stab_binsearch>
    if(lline <= rline){
f0102ab5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ab8:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102abb:	83 c4 10             	add    $0x10,%esp
f0102abe:	39 d0                	cmp    %edx,%eax
f0102ac0:	7f 10                	jg     f0102ad2 <debuginfo_eip+0x173>
        info->eip_line = stabs[rline].n_desc;
f0102ac2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102ac5:	0f b7 14 95 76 4b 10 	movzwl -0xfefb48a(,%edx,4),%edx
f0102acc:	f0 
f0102acd:	89 53 04             	mov    %edx,0x4(%ebx)
f0102ad0:	eb 07                	jmp    f0102ad9 <debuginfo_eip+0x17a>
    }
    else
        info->eip_line = -1;
f0102ad2:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102ad9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102adc:	89 c2                	mov    %eax,%edx
f0102ade:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102ae1:	8d 04 85 70 4b 10 f0 	lea    -0xfefb490(,%eax,4),%eax
f0102ae8:	eb 06                	jmp    f0102af0 <debuginfo_eip+0x191>
f0102aea:	83 ea 01             	sub    $0x1,%edx
f0102aed:	83 e8 0c             	sub    $0xc,%eax
f0102af0:	39 d7                	cmp    %edx,%edi
f0102af2:	7f 34                	jg     f0102b28 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0102af4:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102af8:	80 f9 84             	cmp    $0x84,%cl
f0102afb:	74 0b                	je     f0102b08 <debuginfo_eip+0x1a9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102afd:	80 f9 64             	cmp    $0x64,%cl
f0102b00:	75 e8                	jne    f0102aea <debuginfo_eip+0x18b>
f0102b02:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102b06:	74 e2                	je     f0102aea <debuginfo_eip+0x18b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102b08:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102b0b:	8b 14 85 70 4b 10 f0 	mov    -0xfefb490(,%eax,4),%edx
f0102b12:	b8 f8 c5 10 f0       	mov    $0xf010c5f8,%eax
f0102b17:	2d b1 a7 10 f0       	sub    $0xf010a7b1,%eax
f0102b1c:	39 c2                	cmp    %eax,%edx
f0102b1e:	73 08                	jae    f0102b28 <debuginfo_eip+0x1c9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102b20:	81 c2 b1 a7 10 f0    	add    $0xf010a7b1,%edx
f0102b26:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b28:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b2b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b2e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b33:	39 f2                	cmp    %esi,%edx
f0102b35:	7d 49                	jge    f0102b80 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
f0102b37:	83 c2 01             	add    $0x1,%edx
f0102b3a:	89 d0                	mov    %edx,%eax
f0102b3c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102b3f:	8d 14 95 70 4b 10 f0 	lea    -0xfefb490(,%edx,4),%edx
f0102b46:	eb 04                	jmp    f0102b4c <debuginfo_eip+0x1ed>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102b48:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102b4c:	39 c6                	cmp    %eax,%esi
f0102b4e:	7e 2b                	jle    f0102b7b <debuginfo_eip+0x21c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102b50:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102b54:	83 c0 01             	add    $0x1,%eax
f0102b57:	83 c2 0c             	add    $0xc,%edx
f0102b5a:	80 f9 a0             	cmp    $0xa0,%cl
f0102b5d:	74 e9                	je     f0102b48 <debuginfo_eip+0x1e9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b64:	eb 1a                	jmp    f0102b80 <debuginfo_eip+0x221>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102b66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b6b:	eb 13                	jmp    f0102b80 <debuginfo_eip+0x221>
f0102b6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b72:	eb 0c                	jmp    f0102b80 <debuginfo_eip+0x221>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b79:	eb 05                	jmp    f0102b80 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b83:	5b                   	pop    %ebx
f0102b84:	5e                   	pop    %esi
f0102b85:	5f                   	pop    %edi
f0102b86:	5d                   	pop    %ebp
f0102b87:	c3                   	ret    

f0102b88 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102b88:	55                   	push   %ebp
f0102b89:	89 e5                	mov    %esp,%ebp
f0102b8b:	57                   	push   %edi
f0102b8c:	56                   	push   %esi
f0102b8d:	53                   	push   %ebx
f0102b8e:	83 ec 1c             	sub    $0x1c,%esp
f0102b91:	89 c7                	mov    %eax,%edi
f0102b93:	89 d6                	mov    %edx,%esi
f0102b95:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b98:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b9b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b9e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102ba1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102ba4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ba9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102bac:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102baf:	39 d3                	cmp    %edx,%ebx
f0102bb1:	72 05                	jb     f0102bb8 <printnum+0x30>
f0102bb3:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102bb6:	77 45                	ja     f0102bfd <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102bb8:	83 ec 0c             	sub    $0xc,%esp
f0102bbb:	ff 75 18             	pushl  0x18(%ebp)
f0102bbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bc1:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102bc4:	53                   	push   %ebx
f0102bc5:	ff 75 10             	pushl  0x10(%ebp)
f0102bc8:	83 ec 08             	sub    $0x8,%esp
f0102bcb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102bce:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bd1:	ff 75 dc             	pushl  -0x24(%ebp)
f0102bd4:	ff 75 d8             	pushl  -0x28(%ebp)
f0102bd7:	e8 e4 09 00 00       	call   f01035c0 <__udivdi3>
f0102bdc:	83 c4 18             	add    $0x18,%esp
f0102bdf:	52                   	push   %edx
f0102be0:	50                   	push   %eax
f0102be1:	89 f2                	mov    %esi,%edx
f0102be3:	89 f8                	mov    %edi,%eax
f0102be5:	e8 9e ff ff ff       	call   f0102b88 <printnum>
f0102bea:	83 c4 20             	add    $0x20,%esp
f0102bed:	eb 18                	jmp    f0102c07 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102bef:	83 ec 08             	sub    $0x8,%esp
f0102bf2:	56                   	push   %esi
f0102bf3:	ff 75 18             	pushl  0x18(%ebp)
f0102bf6:	ff d7                	call   *%edi
f0102bf8:	83 c4 10             	add    $0x10,%esp
f0102bfb:	eb 03                	jmp    f0102c00 <printnum+0x78>
f0102bfd:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102c00:	83 eb 01             	sub    $0x1,%ebx
f0102c03:	85 db                	test   %ebx,%ebx
f0102c05:	7f e8                	jg     f0102bef <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102c07:	83 ec 08             	sub    $0x8,%esp
f0102c0a:	56                   	push   %esi
f0102c0b:	83 ec 04             	sub    $0x4,%esp
f0102c0e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c11:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c14:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c17:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c1a:	e8 d1 0a 00 00       	call   f01036f0 <__umoddi3>
f0102c1f:	83 c4 14             	add    $0x14,%esp
f0102c22:	0f be 80 4d 49 10 f0 	movsbl -0xfefb6b3(%eax),%eax
f0102c29:	50                   	push   %eax
f0102c2a:	ff d7                	call   *%edi
}
f0102c2c:	83 c4 10             	add    $0x10,%esp
f0102c2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c32:	5b                   	pop    %ebx
f0102c33:	5e                   	pop    %esi
f0102c34:	5f                   	pop    %edi
f0102c35:	5d                   	pop    %ebp
f0102c36:	c3                   	ret    

f0102c37 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c37:	55                   	push   %ebp
f0102c38:	89 e5                	mov    %esp,%ebp
f0102c3a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c3d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102c41:	8b 10                	mov    (%eax),%edx
f0102c43:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c46:	73 0a                	jae    f0102c52 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102c48:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c4b:	89 08                	mov    %ecx,(%eax)
f0102c4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c50:	88 02                	mov    %al,(%edx)
}
f0102c52:	5d                   	pop    %ebp
f0102c53:	c3                   	ret    

f0102c54 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102c54:	55                   	push   %ebp
f0102c55:	89 e5                	mov    %esp,%ebp
f0102c57:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102c5a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102c5d:	50                   	push   %eax
f0102c5e:	ff 75 10             	pushl  0x10(%ebp)
f0102c61:	ff 75 0c             	pushl  0xc(%ebp)
f0102c64:	ff 75 08             	pushl  0x8(%ebp)
f0102c67:	e8 05 00 00 00       	call   f0102c71 <vprintfmt>
	va_end(ap);
}
f0102c6c:	83 c4 10             	add    $0x10,%esp
f0102c6f:	c9                   	leave  
f0102c70:	c3                   	ret    

f0102c71 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c71:	55                   	push   %ebp
f0102c72:	89 e5                	mov    %esp,%ebp
f0102c74:	57                   	push   %edi
f0102c75:	56                   	push   %esi
f0102c76:	53                   	push   %ebx
f0102c77:	83 ec 2c             	sub    $0x2c,%esp
f0102c7a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c80:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c83:	eb 12                	jmp    f0102c97 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0102c85:	85 c0                	test   %eax,%eax
f0102c87:	0f 84 6a 04 00 00    	je     f01030f7 <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0102c8d:	83 ec 08             	sub    $0x8,%esp
f0102c90:	53                   	push   %ebx
f0102c91:	50                   	push   %eax
f0102c92:	ff d6                	call   *%esi
f0102c94:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0102c97:	83 c7 01             	add    $0x1,%edi
f0102c9a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c9e:	83 f8 25             	cmp    $0x25,%eax
f0102ca1:	75 e2                	jne    f0102c85 <vprintfmt+0x14>
f0102ca3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102ca7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102cae:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cb5:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102cbc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102cc1:	eb 07                	jmp    f0102cca <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102cc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f0102cc6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102cca:	8d 47 01             	lea    0x1(%edi),%eax
f0102ccd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102cd0:	0f b6 07             	movzbl (%edi),%eax
f0102cd3:	0f b6 d0             	movzbl %al,%edx
f0102cd6:	83 e8 23             	sub    $0x23,%eax
f0102cd9:	3c 55                	cmp    $0x55,%al
f0102cdb:	0f 87 fb 03 00 00    	ja     f01030dc <vprintfmt+0x46b>
f0102ce1:	0f b6 c0             	movzbl %al,%eax
f0102ce4:	ff 24 85 e0 49 10 f0 	jmp    *-0xfefb620(,%eax,4)
f0102ceb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f0102cee:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102cf2:	eb d6                	jmp    f0102cca <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102cf4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cf7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cfc:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0102cff:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102d02:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102d06:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102d09:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102d0c:	83 f9 09             	cmp    $0x9,%ecx
f0102d0f:	77 3f                	ja     f0102d50 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0102d11:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102d14:	eb e9                	jmp    f0102cff <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f0102d16:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d19:	8b 00                	mov    (%eax),%eax
f0102d1b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d21:	8d 40 04             	lea    0x4(%eax),%eax
f0102d24:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102d27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0102d2a:	eb 2a                	jmp    f0102d56 <vprintfmt+0xe5>
f0102d2c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d2f:	85 c0                	test   %eax,%eax
f0102d31:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d36:	0f 49 d0             	cmovns %eax,%edx
f0102d39:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102d3c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d3f:	eb 89                	jmp    f0102cca <vprintfmt+0x59>
f0102d41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d44:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d4b:	e9 7a ff ff ff       	jmp    f0102cca <vprintfmt+0x59>
f0102d50:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d53:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f0102d56:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d5a:	0f 89 6a ff ff ff    	jns    f0102cca <vprintfmt+0x59>
				width = precision, precision = -1;
f0102d60:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d63:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d66:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d6d:	e9 58 ff ff ff       	jmp    f0102cca <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f0102d72:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102d75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f0102d78:	e9 4d ff ff ff       	jmp    f0102cca <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102d7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d80:	8d 78 04             	lea    0x4(%eax),%edi
f0102d83:	83 ec 08             	sub    $0x8,%esp
f0102d86:	53                   	push   %ebx
f0102d87:	ff 30                	pushl  (%eax)
f0102d89:	ff d6                	call   *%esi
			break;
f0102d8b:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102d8e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102d91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f0102d94:	e9 fe fe ff ff       	jmp    f0102c97 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d99:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d9c:	8d 78 04             	lea    0x4(%eax),%edi
f0102d9f:	8b 00                	mov    (%eax),%eax
f0102da1:	99                   	cltd   
f0102da2:	31 d0                	xor    %edx,%eax
f0102da4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102da6:	83 f8 07             	cmp    $0x7,%eax
f0102da9:	7f 0b                	jg     f0102db6 <vprintfmt+0x145>
f0102dab:	8b 14 85 40 4b 10 f0 	mov    -0xfefb4c0(,%eax,4),%edx
f0102db2:	85 d2                	test   %edx,%edx
f0102db4:	75 1b                	jne    f0102dd1 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102db6:	50                   	push   %eax
f0102db7:	68 65 49 10 f0       	push   $0xf0104965
f0102dbc:	53                   	push   %ebx
f0102dbd:	56                   	push   %esi
f0102dbe:	e8 91 fe ff ff       	call   f0102c54 <printfmt>
f0102dc3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102dc6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102dc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102dcc:	e9 c6 fe ff ff       	jmp    f0102c97 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102dd1:	52                   	push   %edx
f0102dd2:	68 18 3f 10 f0       	push   $0xf0103f18
f0102dd7:	53                   	push   %ebx
f0102dd8:	56                   	push   %esi
f0102dd9:	e8 76 fe ff ff       	call   f0102c54 <printfmt>
f0102dde:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102de1:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102de4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102de7:	e9 ab fe ff ff       	jmp    f0102c97 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dec:	8b 45 14             	mov    0x14(%ebp),%eax
f0102def:	83 c0 04             	add    $0x4,%eax
f0102df2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102df5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df8:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102dfa:	85 ff                	test   %edi,%edi
f0102dfc:	b8 5e 49 10 f0       	mov    $0xf010495e,%eax
f0102e01:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102e04:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102e08:	0f 8e 94 00 00 00    	jle    f0102ea2 <vprintfmt+0x231>
f0102e0e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102e12:	0f 84 98 00 00 00    	je     f0102eb0 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e18:	83 ec 08             	sub    $0x8,%esp
f0102e1b:	ff 75 d0             	pushl  -0x30(%ebp)
f0102e1e:	57                   	push   %edi
f0102e1f:	e8 34 04 00 00       	call   f0103258 <strnlen>
f0102e24:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102e27:	29 c1                	sub    %eax,%ecx
f0102e29:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102e2c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102e2f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e33:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e36:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e39:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e3b:	eb 0f                	jmp    f0102e4c <vprintfmt+0x1db>
					putch(padc, putdat);
f0102e3d:	83 ec 08             	sub    $0x8,%esp
f0102e40:	53                   	push   %ebx
f0102e41:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e44:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e46:	83 ef 01             	sub    $0x1,%edi
f0102e49:	83 c4 10             	add    $0x10,%esp
f0102e4c:	85 ff                	test   %edi,%edi
f0102e4e:	7f ed                	jg     f0102e3d <vprintfmt+0x1cc>
f0102e50:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e53:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102e56:	85 c9                	test   %ecx,%ecx
f0102e58:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e5d:	0f 49 c1             	cmovns %ecx,%eax
f0102e60:	29 c1                	sub    %eax,%ecx
f0102e62:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e65:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e68:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e6b:	89 cb                	mov    %ecx,%ebx
f0102e6d:	eb 4d                	jmp    f0102ebc <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102e6f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102e73:	74 1b                	je     f0102e90 <vprintfmt+0x21f>
f0102e75:	0f be c0             	movsbl %al,%eax
f0102e78:	83 e8 20             	sub    $0x20,%eax
f0102e7b:	83 f8 5e             	cmp    $0x5e,%eax
f0102e7e:	76 10                	jbe    f0102e90 <vprintfmt+0x21f>
					putch('?', putdat);
f0102e80:	83 ec 08             	sub    $0x8,%esp
f0102e83:	ff 75 0c             	pushl  0xc(%ebp)
f0102e86:	6a 3f                	push   $0x3f
f0102e88:	ff 55 08             	call   *0x8(%ebp)
f0102e8b:	83 c4 10             	add    $0x10,%esp
f0102e8e:	eb 0d                	jmp    f0102e9d <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102e90:	83 ec 08             	sub    $0x8,%esp
f0102e93:	ff 75 0c             	pushl  0xc(%ebp)
f0102e96:	52                   	push   %edx
f0102e97:	ff 55 08             	call   *0x8(%ebp)
f0102e9a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e9d:	83 eb 01             	sub    $0x1,%ebx
f0102ea0:	eb 1a                	jmp    f0102ebc <vprintfmt+0x24b>
f0102ea2:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ea5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ea8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102eab:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102eae:	eb 0c                	jmp    f0102ebc <vprintfmt+0x24b>
f0102eb0:	89 75 08             	mov    %esi,0x8(%ebp)
f0102eb3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102eb6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102eb9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ebc:	83 c7 01             	add    $0x1,%edi
f0102ebf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ec3:	0f be d0             	movsbl %al,%edx
f0102ec6:	85 d2                	test   %edx,%edx
f0102ec8:	74 23                	je     f0102eed <vprintfmt+0x27c>
f0102eca:	85 f6                	test   %esi,%esi
f0102ecc:	78 a1                	js     f0102e6f <vprintfmt+0x1fe>
f0102ece:	83 ee 01             	sub    $0x1,%esi
f0102ed1:	79 9c                	jns    f0102e6f <vprintfmt+0x1fe>
f0102ed3:	89 df                	mov    %ebx,%edi
f0102ed5:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ed8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102edb:	eb 18                	jmp    f0102ef5 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102edd:	83 ec 08             	sub    $0x8,%esp
f0102ee0:	53                   	push   %ebx
f0102ee1:	6a 20                	push   $0x20
f0102ee3:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102ee5:	83 ef 01             	sub    $0x1,%edi
f0102ee8:	83 c4 10             	add    $0x10,%esp
f0102eeb:	eb 08                	jmp    f0102ef5 <vprintfmt+0x284>
f0102eed:	89 df                	mov    %ebx,%edi
f0102eef:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ef2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ef5:	85 ff                	test   %edi,%edi
f0102ef7:	7f e4                	jg     f0102edd <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ef9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102efc:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102eff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f02:	e9 90 fd ff ff       	jmp    f0102c97 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f07:	83 f9 01             	cmp    $0x1,%ecx
f0102f0a:	7e 19                	jle    f0102f25 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102f0c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f0f:	8b 50 04             	mov    0x4(%eax),%edx
f0102f12:	8b 00                	mov    (%eax),%eax
f0102f14:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f17:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102f1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f1d:	8d 40 08             	lea    0x8(%eax),%eax
f0102f20:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f23:	eb 38                	jmp    f0102f5d <vprintfmt+0x2ec>
	else if (lflag)
f0102f25:	85 c9                	test   %ecx,%ecx
f0102f27:	74 1b                	je     f0102f44 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102f29:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f2c:	8b 00                	mov    (%eax),%eax
f0102f2e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f31:	89 c1                	mov    %eax,%ecx
f0102f33:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f36:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f39:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f3c:	8d 40 04             	lea    0x4(%eax),%eax
f0102f3f:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f42:	eb 19                	jmp    f0102f5d <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102f44:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f47:	8b 00                	mov    (%eax),%eax
f0102f49:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f4c:	89 c1                	mov    %eax,%ecx
f0102f4e:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f51:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f57:	8d 40 04             	lea    0x4(%eax),%eax
f0102f5a:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102f5d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f60:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102f63:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102f68:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102f6c:	0f 89 36 01 00 00    	jns    f01030a8 <vprintfmt+0x437>
				putch('-', putdat);
f0102f72:	83 ec 08             	sub    $0x8,%esp
f0102f75:	53                   	push   %ebx
f0102f76:	6a 2d                	push   $0x2d
f0102f78:	ff d6                	call   *%esi
				num = -(long long) num;
f0102f7a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f7d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102f80:	f7 da                	neg    %edx
f0102f82:	83 d1 00             	adc    $0x0,%ecx
f0102f85:	f7 d9                	neg    %ecx
f0102f87:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102f8a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f8f:	e9 14 01 00 00       	jmp    f01030a8 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f94:	83 f9 01             	cmp    $0x1,%ecx
f0102f97:	7e 18                	jle    f0102fb1 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102f99:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f9c:	8b 10                	mov    (%eax),%edx
f0102f9e:	8b 48 04             	mov    0x4(%eax),%ecx
f0102fa1:	8d 40 08             	lea    0x8(%eax),%eax
f0102fa4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102fa7:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fac:	e9 f7 00 00 00       	jmp    f01030a8 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102fb1:	85 c9                	test   %ecx,%ecx
f0102fb3:	74 1a                	je     f0102fcf <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102fb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fb8:	8b 10                	mov    (%eax),%edx
f0102fba:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102fbf:	8d 40 04             	lea    0x4(%eax),%eax
f0102fc2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102fc5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fca:	e9 d9 00 00 00       	jmp    f01030a8 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102fcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fd2:	8b 10                	mov    (%eax),%edx
f0102fd4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102fd9:	8d 40 04             	lea    0x4(%eax),%eax
f0102fdc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102fdf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fe4:	e9 bf 00 00 00       	jmp    f01030a8 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102fe9:	83 f9 01             	cmp    $0x1,%ecx
f0102fec:	7e 13                	jle    f0103001 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f0102fee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ff1:	8b 50 04             	mov    0x4(%eax),%edx
f0102ff4:	8b 00                	mov    (%eax),%eax
f0102ff6:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102ff9:	8d 49 08             	lea    0x8(%ecx),%ecx
f0102ffc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102fff:	eb 28                	jmp    f0103029 <vprintfmt+0x3b8>
	else if (lflag)
f0103001:	85 c9                	test   %ecx,%ecx
f0103003:	74 13                	je     f0103018 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f0103005:	8b 45 14             	mov    0x14(%ebp),%eax
f0103008:	8b 10                	mov    (%eax),%edx
f010300a:	89 d0                	mov    %edx,%eax
f010300c:	99                   	cltd   
f010300d:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0103010:	8d 49 04             	lea    0x4(%ecx),%ecx
f0103013:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103016:	eb 11                	jmp    f0103029 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f0103018:	8b 45 14             	mov    0x14(%ebp),%eax
f010301b:	8b 10                	mov    (%eax),%edx
f010301d:	89 d0                	mov    %edx,%eax
f010301f:	99                   	cltd   
f0103020:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0103023:	8d 49 04             	lea    0x4(%ecx),%ecx
f0103026:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f0103029:	89 d1                	mov    %edx,%ecx
f010302b:	89 c2                	mov    %eax,%edx
			base = 8;
f010302d:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103032:	eb 74                	jmp    f01030a8 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f0103034:	83 ec 08             	sub    $0x8,%esp
f0103037:	53                   	push   %ebx
f0103038:	6a 30                	push   $0x30
f010303a:	ff d6                	call   *%esi
			putch('x', putdat);
f010303c:	83 c4 08             	add    $0x8,%esp
f010303f:	53                   	push   %ebx
f0103040:	6a 78                	push   $0x78
f0103042:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103044:	8b 45 14             	mov    0x14(%ebp),%eax
f0103047:	8b 10                	mov    (%eax),%edx
f0103049:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010304e:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103051:	8d 40 04             	lea    0x4(%eax),%eax
f0103054:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103057:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010305c:	eb 4a                	jmp    f01030a8 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010305e:	83 f9 01             	cmp    $0x1,%ecx
f0103061:	7e 15                	jle    f0103078 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f0103063:	8b 45 14             	mov    0x14(%ebp),%eax
f0103066:	8b 10                	mov    (%eax),%edx
f0103068:	8b 48 04             	mov    0x4(%eax),%ecx
f010306b:	8d 40 08             	lea    0x8(%eax),%eax
f010306e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103071:	b8 10 00 00 00       	mov    $0x10,%eax
f0103076:	eb 30                	jmp    f01030a8 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103078:	85 c9                	test   %ecx,%ecx
f010307a:	74 17                	je     f0103093 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f010307c:	8b 45 14             	mov    0x14(%ebp),%eax
f010307f:	8b 10                	mov    (%eax),%edx
f0103081:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103086:	8d 40 04             	lea    0x4(%eax),%eax
f0103089:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010308c:	b8 10 00 00 00       	mov    $0x10,%eax
f0103091:	eb 15                	jmp    f01030a8 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103093:	8b 45 14             	mov    0x14(%ebp),%eax
f0103096:	8b 10                	mov    (%eax),%edx
f0103098:	b9 00 00 00 00       	mov    $0x0,%ecx
f010309d:	8d 40 04             	lea    0x4(%eax),%eax
f01030a0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01030a3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01030a8:	83 ec 0c             	sub    $0xc,%esp
f01030ab:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01030af:	57                   	push   %edi
f01030b0:	ff 75 e0             	pushl  -0x20(%ebp)
f01030b3:	50                   	push   %eax
f01030b4:	51                   	push   %ecx
f01030b5:	52                   	push   %edx
f01030b6:	89 da                	mov    %ebx,%edx
f01030b8:	89 f0                	mov    %esi,%eax
f01030ba:	e8 c9 fa ff ff       	call   f0102b88 <printnum>
			break;
f01030bf:	83 c4 20             	add    $0x20,%esp
f01030c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01030c5:	e9 cd fb ff ff       	jmp    f0102c97 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01030ca:	83 ec 08             	sub    $0x8,%esp
f01030cd:	53                   	push   %ebx
f01030ce:	52                   	push   %edx
f01030cf:	ff d6                	call   *%esi
			break;
f01030d1:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01030d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01030d7:	e9 bb fb ff ff       	jmp    f0102c97 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01030dc:	83 ec 08             	sub    $0x8,%esp
f01030df:	53                   	push   %ebx
f01030e0:	6a 25                	push   $0x25
f01030e2:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01030e4:	83 c4 10             	add    $0x10,%esp
f01030e7:	eb 03                	jmp    f01030ec <vprintfmt+0x47b>
f01030e9:	83 ef 01             	sub    $0x1,%edi
f01030ec:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01030f0:	75 f7                	jne    f01030e9 <vprintfmt+0x478>
f01030f2:	e9 a0 fb ff ff       	jmp    f0102c97 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01030f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030fa:	5b                   	pop    %ebx
f01030fb:	5e                   	pop    %esi
f01030fc:	5f                   	pop    %edi
f01030fd:	5d                   	pop    %ebp
f01030fe:	c3                   	ret    

f01030ff <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01030ff:	55                   	push   %ebp
f0103100:	89 e5                	mov    %esp,%ebp
f0103102:	83 ec 18             	sub    $0x18,%esp
f0103105:	8b 45 08             	mov    0x8(%ebp),%eax
f0103108:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010310b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010310e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103112:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103115:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010311c:	85 c0                	test   %eax,%eax
f010311e:	74 26                	je     f0103146 <vsnprintf+0x47>
f0103120:	85 d2                	test   %edx,%edx
f0103122:	7e 22                	jle    f0103146 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103124:	ff 75 14             	pushl  0x14(%ebp)
f0103127:	ff 75 10             	pushl  0x10(%ebp)
f010312a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010312d:	50                   	push   %eax
f010312e:	68 37 2c 10 f0       	push   $0xf0102c37
f0103133:	e8 39 fb ff ff       	call   f0102c71 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103138:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010313b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010313e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103141:	83 c4 10             	add    $0x10,%esp
f0103144:	eb 05                	jmp    f010314b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103146:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010314b:	c9                   	leave  
f010314c:	c3                   	ret    

f010314d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010314d:	55                   	push   %ebp
f010314e:	89 e5                	mov    %esp,%ebp
f0103150:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103153:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103156:	50                   	push   %eax
f0103157:	ff 75 10             	pushl  0x10(%ebp)
f010315a:	ff 75 0c             	pushl  0xc(%ebp)
f010315d:	ff 75 08             	pushl  0x8(%ebp)
f0103160:	e8 9a ff ff ff       	call   f01030ff <vsnprintf>
	va_end(ap);

	return rc;
}
f0103165:	c9                   	leave  
f0103166:	c3                   	ret    

f0103167 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103167:	55                   	push   %ebp
f0103168:	89 e5                	mov    %esp,%ebp
f010316a:	57                   	push   %edi
f010316b:	56                   	push   %esi
f010316c:	53                   	push   %ebx
f010316d:	83 ec 0c             	sub    $0xc,%esp
f0103170:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103173:	85 c0                	test   %eax,%eax
f0103175:	74 11                	je     f0103188 <readline+0x21>
		cprintf("%s", prompt);
f0103177:	83 ec 08             	sub    $0x8,%esp
f010317a:	50                   	push   %eax
f010317b:	68 18 3f 10 f0       	push   $0xf0103f18
f0103180:	e8 d0 f6 ff ff       	call   f0102855 <cprintf>
f0103185:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103188:	83 ec 0c             	sub    $0xc,%esp
f010318b:	6a 00                	push   $0x0
f010318d:	e8 81 d4 ff ff       	call   f0100613 <iscons>
f0103192:	89 c7                	mov    %eax,%edi
f0103194:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103197:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010319c:	e8 61 d4 ff ff       	call   f0100602 <getchar>
f01031a1:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01031a3:	85 c0                	test   %eax,%eax
f01031a5:	79 18                	jns    f01031bf <readline+0x58>
			cprintf("read error: %e\n", c);
f01031a7:	83 ec 08             	sub    $0x8,%esp
f01031aa:	50                   	push   %eax
f01031ab:	68 60 4b 10 f0       	push   $0xf0104b60
f01031b0:	e8 a0 f6 ff ff       	call   f0102855 <cprintf>
			return NULL;
f01031b5:	83 c4 10             	add    $0x10,%esp
f01031b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01031bd:	eb 79                	jmp    f0103238 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01031bf:	83 f8 08             	cmp    $0x8,%eax
f01031c2:	0f 94 c2             	sete   %dl
f01031c5:	83 f8 7f             	cmp    $0x7f,%eax
f01031c8:	0f 94 c0             	sete   %al
f01031cb:	08 c2                	or     %al,%dl
f01031cd:	74 1a                	je     f01031e9 <readline+0x82>
f01031cf:	85 f6                	test   %esi,%esi
f01031d1:	7e 16                	jle    f01031e9 <readline+0x82>
			if (echoing)
f01031d3:	85 ff                	test   %edi,%edi
f01031d5:	74 0d                	je     f01031e4 <readline+0x7d>
				cputchar('\b');
f01031d7:	83 ec 0c             	sub    $0xc,%esp
f01031da:	6a 08                	push   $0x8
f01031dc:	e8 11 d4 ff ff       	call   f01005f2 <cputchar>
f01031e1:	83 c4 10             	add    $0x10,%esp
			i--;
f01031e4:	83 ee 01             	sub    $0x1,%esi
f01031e7:	eb b3                	jmp    f010319c <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01031e9:	83 fb 1f             	cmp    $0x1f,%ebx
f01031ec:	7e 23                	jle    f0103211 <readline+0xaa>
f01031ee:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01031f4:	7f 1b                	jg     f0103211 <readline+0xaa>
			if (echoing)
f01031f6:	85 ff                	test   %edi,%edi
f01031f8:	74 0c                	je     f0103206 <readline+0x9f>
				cputchar(c);
f01031fa:	83 ec 0c             	sub    $0xc,%esp
f01031fd:	53                   	push   %ebx
f01031fe:	e8 ef d3 ff ff       	call   f01005f2 <cputchar>
f0103203:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103206:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f010320c:	8d 76 01             	lea    0x1(%esi),%esi
f010320f:	eb 8b                	jmp    f010319c <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103211:	83 fb 0a             	cmp    $0xa,%ebx
f0103214:	74 05                	je     f010321b <readline+0xb4>
f0103216:	83 fb 0d             	cmp    $0xd,%ebx
f0103219:	75 81                	jne    f010319c <readline+0x35>
			if (echoing)
f010321b:	85 ff                	test   %edi,%edi
f010321d:	74 0d                	je     f010322c <readline+0xc5>
				cputchar('\n');
f010321f:	83 ec 0c             	sub    $0xc,%esp
f0103222:	6a 0a                	push   $0xa
f0103224:	e8 c9 d3 ff ff       	call   f01005f2 <cputchar>
f0103229:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010322c:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f0103233:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103238:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010323b:	5b                   	pop    %ebx
f010323c:	5e                   	pop    %esi
f010323d:	5f                   	pop    %edi
f010323e:	5d                   	pop    %ebp
f010323f:	c3                   	ret    

f0103240 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103240:	55                   	push   %ebp
f0103241:	89 e5                	mov    %esp,%ebp
f0103243:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103246:	b8 00 00 00 00       	mov    $0x0,%eax
f010324b:	eb 03                	jmp    f0103250 <strlen+0x10>
		n++;
f010324d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103250:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103254:	75 f7                	jne    f010324d <strlen+0xd>
		n++;
	return n;
}
f0103256:	5d                   	pop    %ebp
f0103257:	c3                   	ret    

f0103258 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103258:	55                   	push   %ebp
f0103259:	89 e5                	mov    %esp,%ebp
f010325b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010325e:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103261:	ba 00 00 00 00       	mov    $0x0,%edx
f0103266:	eb 03                	jmp    f010326b <strnlen+0x13>
		n++;
f0103268:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010326b:	39 c2                	cmp    %eax,%edx
f010326d:	74 08                	je     f0103277 <strnlen+0x1f>
f010326f:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103273:	75 f3                	jne    f0103268 <strnlen+0x10>
f0103275:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103277:	5d                   	pop    %ebp
f0103278:	c3                   	ret    

f0103279 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103279:	55                   	push   %ebp
f010327a:	89 e5                	mov    %esp,%ebp
f010327c:	53                   	push   %ebx
f010327d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103280:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103283:	89 c2                	mov    %eax,%edx
f0103285:	83 c2 01             	add    $0x1,%edx
f0103288:	83 c1 01             	add    $0x1,%ecx
f010328b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010328f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103292:	84 db                	test   %bl,%bl
f0103294:	75 ef                	jne    f0103285 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103296:	5b                   	pop    %ebx
f0103297:	5d                   	pop    %ebp
f0103298:	c3                   	ret    

f0103299 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103299:	55                   	push   %ebp
f010329a:	89 e5                	mov    %esp,%ebp
f010329c:	53                   	push   %ebx
f010329d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01032a0:	53                   	push   %ebx
f01032a1:	e8 9a ff ff ff       	call   f0103240 <strlen>
f01032a6:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01032a9:	ff 75 0c             	pushl  0xc(%ebp)
f01032ac:	01 d8                	add    %ebx,%eax
f01032ae:	50                   	push   %eax
f01032af:	e8 c5 ff ff ff       	call   f0103279 <strcpy>
	return dst;
}
f01032b4:	89 d8                	mov    %ebx,%eax
f01032b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032b9:	c9                   	leave  
f01032ba:	c3                   	ret    

f01032bb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01032bb:	55                   	push   %ebp
f01032bc:	89 e5                	mov    %esp,%ebp
f01032be:	56                   	push   %esi
f01032bf:	53                   	push   %ebx
f01032c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01032c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032c6:	89 f3                	mov    %esi,%ebx
f01032c8:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01032cb:	89 f2                	mov    %esi,%edx
f01032cd:	eb 0f                	jmp    f01032de <strncpy+0x23>
		*dst++ = *src;
f01032cf:	83 c2 01             	add    $0x1,%edx
f01032d2:	0f b6 01             	movzbl (%ecx),%eax
f01032d5:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01032d8:	80 39 01             	cmpb   $0x1,(%ecx)
f01032db:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01032de:	39 da                	cmp    %ebx,%edx
f01032e0:	75 ed                	jne    f01032cf <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01032e2:	89 f0                	mov    %esi,%eax
f01032e4:	5b                   	pop    %ebx
f01032e5:	5e                   	pop    %esi
f01032e6:	5d                   	pop    %ebp
f01032e7:	c3                   	ret    

f01032e8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01032e8:	55                   	push   %ebp
f01032e9:	89 e5                	mov    %esp,%ebp
f01032eb:	56                   	push   %esi
f01032ec:	53                   	push   %ebx
f01032ed:	8b 75 08             	mov    0x8(%ebp),%esi
f01032f0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01032f3:	8b 55 10             	mov    0x10(%ebp),%edx
f01032f6:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01032f8:	85 d2                	test   %edx,%edx
f01032fa:	74 21                	je     f010331d <strlcpy+0x35>
f01032fc:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103300:	89 f2                	mov    %esi,%edx
f0103302:	eb 09                	jmp    f010330d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103304:	83 c2 01             	add    $0x1,%edx
f0103307:	83 c1 01             	add    $0x1,%ecx
f010330a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010330d:	39 c2                	cmp    %eax,%edx
f010330f:	74 09                	je     f010331a <strlcpy+0x32>
f0103311:	0f b6 19             	movzbl (%ecx),%ebx
f0103314:	84 db                	test   %bl,%bl
f0103316:	75 ec                	jne    f0103304 <strlcpy+0x1c>
f0103318:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010331a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010331d:	29 f0                	sub    %esi,%eax
}
f010331f:	5b                   	pop    %ebx
f0103320:	5e                   	pop    %esi
f0103321:	5d                   	pop    %ebp
f0103322:	c3                   	ret    

f0103323 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103323:	55                   	push   %ebp
f0103324:	89 e5                	mov    %esp,%ebp
f0103326:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103329:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010332c:	eb 06                	jmp    f0103334 <strcmp+0x11>
		p++, q++;
f010332e:	83 c1 01             	add    $0x1,%ecx
f0103331:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103334:	0f b6 01             	movzbl (%ecx),%eax
f0103337:	84 c0                	test   %al,%al
f0103339:	74 04                	je     f010333f <strcmp+0x1c>
f010333b:	3a 02                	cmp    (%edx),%al
f010333d:	74 ef                	je     f010332e <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010333f:	0f b6 c0             	movzbl %al,%eax
f0103342:	0f b6 12             	movzbl (%edx),%edx
f0103345:	29 d0                	sub    %edx,%eax
}
f0103347:	5d                   	pop    %ebp
f0103348:	c3                   	ret    

f0103349 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103349:	55                   	push   %ebp
f010334a:	89 e5                	mov    %esp,%ebp
f010334c:	53                   	push   %ebx
f010334d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103350:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103353:	89 c3                	mov    %eax,%ebx
f0103355:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103358:	eb 06                	jmp    f0103360 <strncmp+0x17>
		n--, p++, q++;
f010335a:	83 c0 01             	add    $0x1,%eax
f010335d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103360:	39 d8                	cmp    %ebx,%eax
f0103362:	74 15                	je     f0103379 <strncmp+0x30>
f0103364:	0f b6 08             	movzbl (%eax),%ecx
f0103367:	84 c9                	test   %cl,%cl
f0103369:	74 04                	je     f010336f <strncmp+0x26>
f010336b:	3a 0a                	cmp    (%edx),%cl
f010336d:	74 eb                	je     f010335a <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010336f:	0f b6 00             	movzbl (%eax),%eax
f0103372:	0f b6 12             	movzbl (%edx),%edx
f0103375:	29 d0                	sub    %edx,%eax
f0103377:	eb 05                	jmp    f010337e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103379:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010337e:	5b                   	pop    %ebx
f010337f:	5d                   	pop    %ebp
f0103380:	c3                   	ret    

f0103381 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103381:	55                   	push   %ebp
f0103382:	89 e5                	mov    %esp,%ebp
f0103384:	8b 45 08             	mov    0x8(%ebp),%eax
f0103387:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010338b:	eb 07                	jmp    f0103394 <strchr+0x13>
		if (*s == c)
f010338d:	38 ca                	cmp    %cl,%dl
f010338f:	74 0f                	je     f01033a0 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103391:	83 c0 01             	add    $0x1,%eax
f0103394:	0f b6 10             	movzbl (%eax),%edx
f0103397:	84 d2                	test   %dl,%dl
f0103399:	75 f2                	jne    f010338d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010339b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033a0:	5d                   	pop    %ebp
f01033a1:	c3                   	ret    

f01033a2 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01033a2:	55                   	push   %ebp
f01033a3:	89 e5                	mov    %esp,%ebp
f01033a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01033ac:	eb 03                	jmp    f01033b1 <strfind+0xf>
f01033ae:	83 c0 01             	add    $0x1,%eax
f01033b1:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01033b4:	38 ca                	cmp    %cl,%dl
f01033b6:	74 04                	je     f01033bc <strfind+0x1a>
f01033b8:	84 d2                	test   %dl,%dl
f01033ba:	75 f2                	jne    f01033ae <strfind+0xc>
			break;
	return (char *) s;
}
f01033bc:	5d                   	pop    %ebp
f01033bd:	c3                   	ret    

f01033be <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01033be:	55                   	push   %ebp
f01033bf:	89 e5                	mov    %esp,%ebp
f01033c1:	57                   	push   %edi
f01033c2:	56                   	push   %esi
f01033c3:	53                   	push   %ebx
f01033c4:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033c7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01033ca:	85 c9                	test   %ecx,%ecx
f01033cc:	74 36                	je     f0103404 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01033ce:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01033d4:	75 28                	jne    f01033fe <memset+0x40>
f01033d6:	f6 c1 03             	test   $0x3,%cl
f01033d9:	75 23                	jne    f01033fe <memset+0x40>
		c &= 0xFF;
f01033db:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01033df:	89 d3                	mov    %edx,%ebx
f01033e1:	c1 e3 08             	shl    $0x8,%ebx
f01033e4:	89 d6                	mov    %edx,%esi
f01033e6:	c1 e6 18             	shl    $0x18,%esi
f01033e9:	89 d0                	mov    %edx,%eax
f01033eb:	c1 e0 10             	shl    $0x10,%eax
f01033ee:	09 f0                	or     %esi,%eax
f01033f0:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01033f2:	89 d8                	mov    %ebx,%eax
f01033f4:	09 d0                	or     %edx,%eax
f01033f6:	c1 e9 02             	shr    $0x2,%ecx
f01033f9:	fc                   	cld    
f01033fa:	f3 ab                	rep stos %eax,%es:(%edi)
f01033fc:	eb 06                	jmp    f0103404 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01033fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103401:	fc                   	cld    
f0103402:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103404:	89 f8                	mov    %edi,%eax
f0103406:	5b                   	pop    %ebx
f0103407:	5e                   	pop    %esi
f0103408:	5f                   	pop    %edi
f0103409:	5d                   	pop    %ebp
f010340a:	c3                   	ret    

f010340b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010340b:	55                   	push   %ebp
f010340c:	89 e5                	mov    %esp,%ebp
f010340e:	57                   	push   %edi
f010340f:	56                   	push   %esi
f0103410:	8b 45 08             	mov    0x8(%ebp),%eax
f0103413:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103416:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103419:	39 c6                	cmp    %eax,%esi
f010341b:	73 35                	jae    f0103452 <memmove+0x47>
f010341d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103420:	39 d0                	cmp    %edx,%eax
f0103422:	73 2e                	jae    f0103452 <memmove+0x47>
		s += n;
		d += n;
f0103424:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103427:	89 d6                	mov    %edx,%esi
f0103429:	09 fe                	or     %edi,%esi
f010342b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103431:	75 13                	jne    f0103446 <memmove+0x3b>
f0103433:	f6 c1 03             	test   $0x3,%cl
f0103436:	75 0e                	jne    f0103446 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103438:	83 ef 04             	sub    $0x4,%edi
f010343b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010343e:	c1 e9 02             	shr    $0x2,%ecx
f0103441:	fd                   	std    
f0103442:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103444:	eb 09                	jmp    f010344f <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103446:	83 ef 01             	sub    $0x1,%edi
f0103449:	8d 72 ff             	lea    -0x1(%edx),%esi
f010344c:	fd                   	std    
f010344d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010344f:	fc                   	cld    
f0103450:	eb 1d                	jmp    f010346f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103452:	89 f2                	mov    %esi,%edx
f0103454:	09 c2                	or     %eax,%edx
f0103456:	f6 c2 03             	test   $0x3,%dl
f0103459:	75 0f                	jne    f010346a <memmove+0x5f>
f010345b:	f6 c1 03             	test   $0x3,%cl
f010345e:	75 0a                	jne    f010346a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103460:	c1 e9 02             	shr    $0x2,%ecx
f0103463:	89 c7                	mov    %eax,%edi
f0103465:	fc                   	cld    
f0103466:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103468:	eb 05                	jmp    f010346f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010346a:	89 c7                	mov    %eax,%edi
f010346c:	fc                   	cld    
f010346d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010346f:	5e                   	pop    %esi
f0103470:	5f                   	pop    %edi
f0103471:	5d                   	pop    %ebp
f0103472:	c3                   	ret    

f0103473 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103473:	55                   	push   %ebp
f0103474:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103476:	ff 75 10             	pushl  0x10(%ebp)
f0103479:	ff 75 0c             	pushl  0xc(%ebp)
f010347c:	ff 75 08             	pushl  0x8(%ebp)
f010347f:	e8 87 ff ff ff       	call   f010340b <memmove>
}
f0103484:	c9                   	leave  
f0103485:	c3                   	ret    

f0103486 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103486:	55                   	push   %ebp
f0103487:	89 e5                	mov    %esp,%ebp
f0103489:	56                   	push   %esi
f010348a:	53                   	push   %ebx
f010348b:	8b 45 08             	mov    0x8(%ebp),%eax
f010348e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103491:	89 c6                	mov    %eax,%esi
f0103493:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103496:	eb 1a                	jmp    f01034b2 <memcmp+0x2c>
		if (*s1 != *s2)
f0103498:	0f b6 08             	movzbl (%eax),%ecx
f010349b:	0f b6 1a             	movzbl (%edx),%ebx
f010349e:	38 d9                	cmp    %bl,%cl
f01034a0:	74 0a                	je     f01034ac <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01034a2:	0f b6 c1             	movzbl %cl,%eax
f01034a5:	0f b6 db             	movzbl %bl,%ebx
f01034a8:	29 d8                	sub    %ebx,%eax
f01034aa:	eb 0f                	jmp    f01034bb <memcmp+0x35>
		s1++, s2++;
f01034ac:	83 c0 01             	add    $0x1,%eax
f01034af:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01034b2:	39 f0                	cmp    %esi,%eax
f01034b4:	75 e2                	jne    f0103498 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01034b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034bb:	5b                   	pop    %ebx
f01034bc:	5e                   	pop    %esi
f01034bd:	5d                   	pop    %ebp
f01034be:	c3                   	ret    

f01034bf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01034bf:	55                   	push   %ebp
f01034c0:	89 e5                	mov    %esp,%ebp
f01034c2:	53                   	push   %ebx
f01034c3:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01034c6:	89 c1                	mov    %eax,%ecx
f01034c8:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01034cb:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034cf:	eb 0a                	jmp    f01034db <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01034d1:	0f b6 10             	movzbl (%eax),%edx
f01034d4:	39 da                	cmp    %ebx,%edx
f01034d6:	74 07                	je     f01034df <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01034d8:	83 c0 01             	add    $0x1,%eax
f01034db:	39 c8                	cmp    %ecx,%eax
f01034dd:	72 f2                	jb     f01034d1 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01034df:	5b                   	pop    %ebx
f01034e0:	5d                   	pop    %ebp
f01034e1:	c3                   	ret    

f01034e2 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01034e2:	55                   	push   %ebp
f01034e3:	89 e5                	mov    %esp,%ebp
f01034e5:	57                   	push   %edi
f01034e6:	56                   	push   %esi
f01034e7:	53                   	push   %ebx
f01034e8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01034eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01034ee:	eb 03                	jmp    f01034f3 <strtol+0x11>
		s++;
f01034f0:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01034f3:	0f b6 01             	movzbl (%ecx),%eax
f01034f6:	3c 20                	cmp    $0x20,%al
f01034f8:	74 f6                	je     f01034f0 <strtol+0xe>
f01034fa:	3c 09                	cmp    $0x9,%al
f01034fc:	74 f2                	je     f01034f0 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01034fe:	3c 2b                	cmp    $0x2b,%al
f0103500:	75 0a                	jne    f010350c <strtol+0x2a>
		s++;
f0103502:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103505:	bf 00 00 00 00       	mov    $0x0,%edi
f010350a:	eb 11                	jmp    f010351d <strtol+0x3b>
f010350c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103511:	3c 2d                	cmp    $0x2d,%al
f0103513:	75 08                	jne    f010351d <strtol+0x3b>
		s++, neg = 1;
f0103515:	83 c1 01             	add    $0x1,%ecx
f0103518:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010351d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103523:	75 15                	jne    f010353a <strtol+0x58>
f0103525:	80 39 30             	cmpb   $0x30,(%ecx)
f0103528:	75 10                	jne    f010353a <strtol+0x58>
f010352a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010352e:	75 7c                	jne    f01035ac <strtol+0xca>
		s += 2, base = 16;
f0103530:	83 c1 02             	add    $0x2,%ecx
f0103533:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103538:	eb 16                	jmp    f0103550 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010353a:	85 db                	test   %ebx,%ebx
f010353c:	75 12                	jne    f0103550 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010353e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103543:	80 39 30             	cmpb   $0x30,(%ecx)
f0103546:	75 08                	jne    f0103550 <strtol+0x6e>
		s++, base = 8;
f0103548:	83 c1 01             	add    $0x1,%ecx
f010354b:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103550:	b8 00 00 00 00       	mov    $0x0,%eax
f0103555:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103558:	0f b6 11             	movzbl (%ecx),%edx
f010355b:	8d 72 d0             	lea    -0x30(%edx),%esi
f010355e:	89 f3                	mov    %esi,%ebx
f0103560:	80 fb 09             	cmp    $0x9,%bl
f0103563:	77 08                	ja     f010356d <strtol+0x8b>
			dig = *s - '0';
f0103565:	0f be d2             	movsbl %dl,%edx
f0103568:	83 ea 30             	sub    $0x30,%edx
f010356b:	eb 22                	jmp    f010358f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010356d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103570:	89 f3                	mov    %esi,%ebx
f0103572:	80 fb 19             	cmp    $0x19,%bl
f0103575:	77 08                	ja     f010357f <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103577:	0f be d2             	movsbl %dl,%edx
f010357a:	83 ea 57             	sub    $0x57,%edx
f010357d:	eb 10                	jmp    f010358f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010357f:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103582:	89 f3                	mov    %esi,%ebx
f0103584:	80 fb 19             	cmp    $0x19,%bl
f0103587:	77 16                	ja     f010359f <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103589:	0f be d2             	movsbl %dl,%edx
f010358c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010358f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103592:	7d 0b                	jge    f010359f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103594:	83 c1 01             	add    $0x1,%ecx
f0103597:	0f af 45 10          	imul   0x10(%ebp),%eax
f010359b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010359d:	eb b9                	jmp    f0103558 <strtol+0x76>

	if (endptr)
f010359f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01035a3:	74 0d                	je     f01035b2 <strtol+0xd0>
		*endptr = (char *) s;
f01035a5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01035a8:	89 0e                	mov    %ecx,(%esi)
f01035aa:	eb 06                	jmp    f01035b2 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01035ac:	85 db                	test   %ebx,%ebx
f01035ae:	74 98                	je     f0103548 <strtol+0x66>
f01035b0:	eb 9e                	jmp    f0103550 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01035b2:	89 c2                	mov    %eax,%edx
f01035b4:	f7 da                	neg    %edx
f01035b6:	85 ff                	test   %edi,%edi
f01035b8:	0f 45 c2             	cmovne %edx,%eax
}
f01035bb:	5b                   	pop    %ebx
f01035bc:	5e                   	pop    %esi
f01035bd:	5f                   	pop    %edi
f01035be:	5d                   	pop    %ebp
f01035bf:	c3                   	ret    

f01035c0 <__udivdi3>:
f01035c0:	55                   	push   %ebp
f01035c1:	57                   	push   %edi
f01035c2:	56                   	push   %esi
f01035c3:	53                   	push   %ebx
f01035c4:	83 ec 1c             	sub    $0x1c,%esp
f01035c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01035cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01035cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01035d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035d7:	85 f6                	test   %esi,%esi
f01035d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035dd:	89 ca                	mov    %ecx,%edx
f01035df:	89 f8                	mov    %edi,%eax
f01035e1:	75 3d                	jne    f0103620 <__udivdi3+0x60>
f01035e3:	39 cf                	cmp    %ecx,%edi
f01035e5:	0f 87 c5 00 00 00    	ja     f01036b0 <__udivdi3+0xf0>
f01035eb:	85 ff                	test   %edi,%edi
f01035ed:	89 fd                	mov    %edi,%ebp
f01035ef:	75 0b                	jne    f01035fc <__udivdi3+0x3c>
f01035f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01035f6:	31 d2                	xor    %edx,%edx
f01035f8:	f7 f7                	div    %edi
f01035fa:	89 c5                	mov    %eax,%ebp
f01035fc:	89 c8                	mov    %ecx,%eax
f01035fe:	31 d2                	xor    %edx,%edx
f0103600:	f7 f5                	div    %ebp
f0103602:	89 c1                	mov    %eax,%ecx
f0103604:	89 d8                	mov    %ebx,%eax
f0103606:	89 cf                	mov    %ecx,%edi
f0103608:	f7 f5                	div    %ebp
f010360a:	89 c3                	mov    %eax,%ebx
f010360c:	89 d8                	mov    %ebx,%eax
f010360e:	89 fa                	mov    %edi,%edx
f0103610:	83 c4 1c             	add    $0x1c,%esp
f0103613:	5b                   	pop    %ebx
f0103614:	5e                   	pop    %esi
f0103615:	5f                   	pop    %edi
f0103616:	5d                   	pop    %ebp
f0103617:	c3                   	ret    
f0103618:	90                   	nop
f0103619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103620:	39 ce                	cmp    %ecx,%esi
f0103622:	77 74                	ja     f0103698 <__udivdi3+0xd8>
f0103624:	0f bd fe             	bsr    %esi,%edi
f0103627:	83 f7 1f             	xor    $0x1f,%edi
f010362a:	0f 84 98 00 00 00    	je     f01036c8 <__udivdi3+0x108>
f0103630:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103635:	89 f9                	mov    %edi,%ecx
f0103637:	89 c5                	mov    %eax,%ebp
f0103639:	29 fb                	sub    %edi,%ebx
f010363b:	d3 e6                	shl    %cl,%esi
f010363d:	89 d9                	mov    %ebx,%ecx
f010363f:	d3 ed                	shr    %cl,%ebp
f0103641:	89 f9                	mov    %edi,%ecx
f0103643:	d3 e0                	shl    %cl,%eax
f0103645:	09 ee                	or     %ebp,%esi
f0103647:	89 d9                	mov    %ebx,%ecx
f0103649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010364d:	89 d5                	mov    %edx,%ebp
f010364f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103653:	d3 ed                	shr    %cl,%ebp
f0103655:	89 f9                	mov    %edi,%ecx
f0103657:	d3 e2                	shl    %cl,%edx
f0103659:	89 d9                	mov    %ebx,%ecx
f010365b:	d3 e8                	shr    %cl,%eax
f010365d:	09 c2                	or     %eax,%edx
f010365f:	89 d0                	mov    %edx,%eax
f0103661:	89 ea                	mov    %ebp,%edx
f0103663:	f7 f6                	div    %esi
f0103665:	89 d5                	mov    %edx,%ebp
f0103667:	89 c3                	mov    %eax,%ebx
f0103669:	f7 64 24 0c          	mull   0xc(%esp)
f010366d:	39 d5                	cmp    %edx,%ebp
f010366f:	72 10                	jb     f0103681 <__udivdi3+0xc1>
f0103671:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103675:	89 f9                	mov    %edi,%ecx
f0103677:	d3 e6                	shl    %cl,%esi
f0103679:	39 c6                	cmp    %eax,%esi
f010367b:	73 07                	jae    f0103684 <__udivdi3+0xc4>
f010367d:	39 d5                	cmp    %edx,%ebp
f010367f:	75 03                	jne    f0103684 <__udivdi3+0xc4>
f0103681:	83 eb 01             	sub    $0x1,%ebx
f0103684:	31 ff                	xor    %edi,%edi
f0103686:	89 d8                	mov    %ebx,%eax
f0103688:	89 fa                	mov    %edi,%edx
f010368a:	83 c4 1c             	add    $0x1c,%esp
f010368d:	5b                   	pop    %ebx
f010368e:	5e                   	pop    %esi
f010368f:	5f                   	pop    %edi
f0103690:	5d                   	pop    %ebp
f0103691:	c3                   	ret    
f0103692:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103698:	31 ff                	xor    %edi,%edi
f010369a:	31 db                	xor    %ebx,%ebx
f010369c:	89 d8                	mov    %ebx,%eax
f010369e:	89 fa                	mov    %edi,%edx
f01036a0:	83 c4 1c             	add    $0x1c,%esp
f01036a3:	5b                   	pop    %ebx
f01036a4:	5e                   	pop    %esi
f01036a5:	5f                   	pop    %edi
f01036a6:	5d                   	pop    %ebp
f01036a7:	c3                   	ret    
f01036a8:	90                   	nop
f01036a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01036b0:	89 d8                	mov    %ebx,%eax
f01036b2:	f7 f7                	div    %edi
f01036b4:	31 ff                	xor    %edi,%edi
f01036b6:	89 c3                	mov    %eax,%ebx
f01036b8:	89 d8                	mov    %ebx,%eax
f01036ba:	89 fa                	mov    %edi,%edx
f01036bc:	83 c4 1c             	add    $0x1c,%esp
f01036bf:	5b                   	pop    %ebx
f01036c0:	5e                   	pop    %esi
f01036c1:	5f                   	pop    %edi
f01036c2:	5d                   	pop    %ebp
f01036c3:	c3                   	ret    
f01036c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036c8:	39 ce                	cmp    %ecx,%esi
f01036ca:	72 0c                	jb     f01036d8 <__udivdi3+0x118>
f01036cc:	31 db                	xor    %ebx,%ebx
f01036ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01036d2:	0f 87 34 ff ff ff    	ja     f010360c <__udivdi3+0x4c>
f01036d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01036dd:	e9 2a ff ff ff       	jmp    f010360c <__udivdi3+0x4c>
f01036e2:	66 90                	xchg   %ax,%ax
f01036e4:	66 90                	xchg   %ax,%ax
f01036e6:	66 90                	xchg   %ax,%ax
f01036e8:	66 90                	xchg   %ax,%ax
f01036ea:	66 90                	xchg   %ax,%ax
f01036ec:	66 90                	xchg   %ax,%ax
f01036ee:	66 90                	xchg   %ax,%ax

f01036f0 <__umoddi3>:
f01036f0:	55                   	push   %ebp
f01036f1:	57                   	push   %edi
f01036f2:	56                   	push   %esi
f01036f3:	53                   	push   %ebx
f01036f4:	83 ec 1c             	sub    $0x1c,%esp
f01036f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01036fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01036ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103707:	85 d2                	test   %edx,%edx
f0103709:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010370d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103711:	89 f3                	mov    %esi,%ebx
f0103713:	89 3c 24             	mov    %edi,(%esp)
f0103716:	89 74 24 04          	mov    %esi,0x4(%esp)
f010371a:	75 1c                	jne    f0103738 <__umoddi3+0x48>
f010371c:	39 f7                	cmp    %esi,%edi
f010371e:	76 50                	jbe    f0103770 <__umoddi3+0x80>
f0103720:	89 c8                	mov    %ecx,%eax
f0103722:	89 f2                	mov    %esi,%edx
f0103724:	f7 f7                	div    %edi
f0103726:	89 d0                	mov    %edx,%eax
f0103728:	31 d2                	xor    %edx,%edx
f010372a:	83 c4 1c             	add    $0x1c,%esp
f010372d:	5b                   	pop    %ebx
f010372e:	5e                   	pop    %esi
f010372f:	5f                   	pop    %edi
f0103730:	5d                   	pop    %ebp
f0103731:	c3                   	ret    
f0103732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103738:	39 f2                	cmp    %esi,%edx
f010373a:	89 d0                	mov    %edx,%eax
f010373c:	77 52                	ja     f0103790 <__umoddi3+0xa0>
f010373e:	0f bd ea             	bsr    %edx,%ebp
f0103741:	83 f5 1f             	xor    $0x1f,%ebp
f0103744:	75 5a                	jne    f01037a0 <__umoddi3+0xb0>
f0103746:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010374a:	0f 82 e0 00 00 00    	jb     f0103830 <__umoddi3+0x140>
f0103750:	39 0c 24             	cmp    %ecx,(%esp)
f0103753:	0f 86 d7 00 00 00    	jbe    f0103830 <__umoddi3+0x140>
f0103759:	8b 44 24 08          	mov    0x8(%esp),%eax
f010375d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103761:	83 c4 1c             	add    $0x1c,%esp
f0103764:	5b                   	pop    %ebx
f0103765:	5e                   	pop    %esi
f0103766:	5f                   	pop    %edi
f0103767:	5d                   	pop    %ebp
f0103768:	c3                   	ret    
f0103769:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103770:	85 ff                	test   %edi,%edi
f0103772:	89 fd                	mov    %edi,%ebp
f0103774:	75 0b                	jne    f0103781 <__umoddi3+0x91>
f0103776:	b8 01 00 00 00       	mov    $0x1,%eax
f010377b:	31 d2                	xor    %edx,%edx
f010377d:	f7 f7                	div    %edi
f010377f:	89 c5                	mov    %eax,%ebp
f0103781:	89 f0                	mov    %esi,%eax
f0103783:	31 d2                	xor    %edx,%edx
f0103785:	f7 f5                	div    %ebp
f0103787:	89 c8                	mov    %ecx,%eax
f0103789:	f7 f5                	div    %ebp
f010378b:	89 d0                	mov    %edx,%eax
f010378d:	eb 99                	jmp    f0103728 <__umoddi3+0x38>
f010378f:	90                   	nop
f0103790:	89 c8                	mov    %ecx,%eax
f0103792:	89 f2                	mov    %esi,%edx
f0103794:	83 c4 1c             	add    $0x1c,%esp
f0103797:	5b                   	pop    %ebx
f0103798:	5e                   	pop    %esi
f0103799:	5f                   	pop    %edi
f010379a:	5d                   	pop    %ebp
f010379b:	c3                   	ret    
f010379c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01037a0:	8b 34 24             	mov    (%esp),%esi
f01037a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01037a8:	89 e9                	mov    %ebp,%ecx
f01037aa:	29 ef                	sub    %ebp,%edi
f01037ac:	d3 e0                	shl    %cl,%eax
f01037ae:	89 f9                	mov    %edi,%ecx
f01037b0:	89 f2                	mov    %esi,%edx
f01037b2:	d3 ea                	shr    %cl,%edx
f01037b4:	89 e9                	mov    %ebp,%ecx
f01037b6:	09 c2                	or     %eax,%edx
f01037b8:	89 d8                	mov    %ebx,%eax
f01037ba:	89 14 24             	mov    %edx,(%esp)
f01037bd:	89 f2                	mov    %esi,%edx
f01037bf:	d3 e2                	shl    %cl,%edx
f01037c1:	89 f9                	mov    %edi,%ecx
f01037c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01037cb:	d3 e8                	shr    %cl,%eax
f01037cd:	89 e9                	mov    %ebp,%ecx
f01037cf:	89 c6                	mov    %eax,%esi
f01037d1:	d3 e3                	shl    %cl,%ebx
f01037d3:	89 f9                	mov    %edi,%ecx
f01037d5:	89 d0                	mov    %edx,%eax
f01037d7:	d3 e8                	shr    %cl,%eax
f01037d9:	89 e9                	mov    %ebp,%ecx
f01037db:	09 d8                	or     %ebx,%eax
f01037dd:	89 d3                	mov    %edx,%ebx
f01037df:	89 f2                	mov    %esi,%edx
f01037e1:	f7 34 24             	divl   (%esp)
f01037e4:	89 d6                	mov    %edx,%esi
f01037e6:	d3 e3                	shl    %cl,%ebx
f01037e8:	f7 64 24 04          	mull   0x4(%esp)
f01037ec:	39 d6                	cmp    %edx,%esi
f01037ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037f2:	89 d1                	mov    %edx,%ecx
f01037f4:	89 c3                	mov    %eax,%ebx
f01037f6:	72 08                	jb     f0103800 <__umoddi3+0x110>
f01037f8:	75 11                	jne    f010380b <__umoddi3+0x11b>
f01037fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01037fe:	73 0b                	jae    f010380b <__umoddi3+0x11b>
f0103800:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103804:	1b 14 24             	sbb    (%esp),%edx
f0103807:	89 d1                	mov    %edx,%ecx
f0103809:	89 c3                	mov    %eax,%ebx
f010380b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010380f:	29 da                	sub    %ebx,%edx
f0103811:	19 ce                	sbb    %ecx,%esi
f0103813:	89 f9                	mov    %edi,%ecx
f0103815:	89 f0                	mov    %esi,%eax
f0103817:	d3 e0                	shl    %cl,%eax
f0103819:	89 e9                	mov    %ebp,%ecx
f010381b:	d3 ea                	shr    %cl,%edx
f010381d:	89 e9                	mov    %ebp,%ecx
f010381f:	d3 ee                	shr    %cl,%esi
f0103821:	09 d0                	or     %edx,%eax
f0103823:	89 f2                	mov    %esi,%edx
f0103825:	83 c4 1c             	add    $0x1c,%esp
f0103828:	5b                   	pop    %ebx
f0103829:	5e                   	pop    %esi
f010382a:	5f                   	pop    %edi
f010382b:	5d                   	pop    %ebp
f010382c:	c3                   	ret    
f010382d:	8d 76 00             	lea    0x0(%esi),%esi
f0103830:	29 f9                	sub    %edi,%ecx
f0103832:	19 d6                	sbb    %edx,%esi
f0103834:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103838:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010383c:	e9 18 ff ff ff       	jmp    f0103759 <__umoddi3+0x69>
