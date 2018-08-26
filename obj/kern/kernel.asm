
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

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
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 19 31 00 00       	call   f0103176 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// 在此之前无法调用cprintf
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 36 10 f0       	push   $0xf0103620
f010006f:	e8 99 25 00 00       	call   f010260d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 15 0f 00 00       	call   f0100f8e <mem_init>
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
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

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
f01000b0:	68 3b 36 10 f0       	push   $0xf010363b
f01000b5:	e8 53 25 00 00       	call   f010260d <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 23 25 00 00       	call   f01025e7 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 dd 3d 10 f0 	movl   $0xf0103ddd,(%esp)
f01000cb:	e8 3d 25 00 00       	call   f010260d <cprintf>
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
f01000f2:	68 53 36 10 f0       	push   $0xf0103653
f01000f7:	e8 11 25 00 00       	call   f010260d <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 df 24 00 00       	call   f01025e7 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 dd 3d 10 f0 	movl   $0xf0103ddd,(%esp)
f010010f:	e8 f9 24 00 00       	call   f010260d <cprintf>
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
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
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
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
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
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 c0 37 10 f0 	movzbl -0xfefc840(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 c0 37 10 f0 	movzbl -0xfefc840(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a c0 36 10 f0 	movzbl -0xfefc940(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d a0 36 10 f0 	mov    -0xfefc960(,%ecx,4),%ecx
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
f0100260:	68 6d 36 10 f0       	push   $0xf010366d
f0100265:	e8 a3 23 00 00       	call   f010260d <cprintf>
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
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
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
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 b0 2d 00 00       	call   f01031c3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
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
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
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
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
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
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
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
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
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
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
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
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
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
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
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
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
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
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
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
f01005dd:	68 79 36 10 f0       	push   $0xf0103679
f01005e2:	e8 26 20 00 00       	call   f010260d <cprintf>
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
f0100623:	68 c0 38 10 f0       	push   $0xf01038c0
f0100628:	68 de 38 10 f0       	push   $0xf01038de
f010062d:	68 e3 38 10 f0       	push   $0xf01038e3
f0100632:	e8 d6 1f 00 00       	call   f010260d <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 78 39 10 f0       	push   $0xf0103978
f010063f:	68 ec 38 10 f0       	push   $0xf01038ec
f0100644:	68 e3 38 10 f0       	push   $0xf01038e3
f0100649:	e8 bf 1f 00 00       	call   f010260d <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 a0 39 10 f0       	push   $0xf01039a0
f0100656:	68 f5 38 10 f0       	push   $0xf01038f5
f010065b:	68 e3 38 10 f0       	push   $0xf01038e3
f0100660:	e8 a8 1f 00 00       	call   f010260d <cprintf>
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
f0100672:	68 ff 38 10 f0       	push   $0xf01038ff
f0100677:	e8 91 1f 00 00       	call   f010260d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 d0 39 10 f0       	push   $0xf01039d0
f0100689:	e8 7f 1f 00 00       	call   f010260d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 f8 39 10 f0       	push   $0xf01039f8
f01006a0:	e8 68 1f 00 00       	call   f010260d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 01 36 10 00       	push   $0x103601
f01006ad:	68 01 36 10 f0       	push   $0xf0103601
f01006b2:	68 1c 3a 10 f0       	push   $0xf0103a1c
f01006b7:	e8 51 1f 00 00       	call   f010260d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 63 11 00       	push   $0x116300
f01006c4:	68 00 63 11 f0       	push   $0xf0116300
f01006c9:	68 40 3a 10 f0       	push   $0xf0103a40
f01006ce:	e8 3a 1f 00 00       	call   f010260d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 70 69 11 00       	push   $0x116970
f01006db:	68 70 69 11 f0       	push   $0xf0116970
f01006e0:	68 64 3a 10 f0       	push   $0xf0103a64
f01006e5:	e8 23 1f 00 00       	call   f010260d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
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
f010070b:	68 88 3a 10 f0       	push   $0xf0103a88
f0100710:	e8 f8 1e 00 00       	call   f010260d <cprintf>
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
f0100727:	68 18 39 10 f0       	push   $0xf0103918
f010072c:	e8 dc 1e 00 00       	call   f010260d <cprintf>
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
f010074c:	68 b4 3a 10 f0       	push   $0xf0103ab4
f0100751:	e8 b7 1e 00 00       	call   f010260d <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f0100756:	83 c4 18             	add    $0x18,%esp
f0100759:	56                   	push   %esi
f010075a:	ff 73 04             	pushl  0x4(%ebx)
f010075d:	e8 b5 1f 00 00       	call   f0102717 <debuginfo_eip>

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
f010079a:	68 2a 39 10 f0       	push   $0xf010392a
f010079f:	e8 69 1e 00 00       	call   f010260d <cprintf>
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
f01007c3:	68 e8 3a 10 f0       	push   $0xf0103ae8
f01007c8:	e8 40 1e 00 00       	call   f010260d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cd:	c7 04 24 0c 3b 10 f0 	movl   $0xf0103b0c,(%esp)
f01007d4:	e8 34 1e 00 00       	call   f010260d <cprintf>
f01007d9:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f01007dc:	83 ec 0c             	sub    $0xc,%esp
f01007df:	68 39 39 10 f0       	push   $0xf0103939
f01007e4:	e8 36 27 00 00       	call   f0102f1f <readline>
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
f0100818:	68 3d 39 10 f0       	push   $0xf010393d
f010081d:	e8 17 29 00 00       	call   f0103139 <strchr>
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
f0100838:	68 42 39 10 f0       	push   $0xf0103942
f010083d:	e8 cb 1d 00 00       	call   f010260d <cprintf>
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
f0100861:	68 3d 39 10 f0       	push   $0xf010393d
f0100866:	e8 ce 28 00 00       	call   f0103139 <strchr>
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
f010088f:	ff 34 85 40 3b 10 f0 	pushl  -0xfefc4c0(,%eax,4)
f0100896:	ff 75 a8             	pushl  -0x58(%ebp)
f0100899:	e8 3d 28 00 00       	call   f01030db <strcmp>
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
f01008b3:	ff 14 85 48 3b 10 f0 	call   *-0xfefc4b8(,%eax,4)

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
f01008d4:	68 5f 39 10 f0       	push   $0xf010395f
f01008d9:	e8 2f 1d 00 00       	call   f010260d <cprintf>
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
f01008f5:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008fc:	75 11                	jne    f010090f <boot_alloc+0x21>
	{
		extern char end[];
		nextfree = ROUNDUP((char *)end, PGSIZE);
f01008fe:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f0100903:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100909:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010090f:	8b 1d 38 65 11 f0    	mov    0xf0116538,%ebx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100915:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f010091c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100922:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	if ((int)nextfree - KERNBASE > npages * PGSIZE)
f0100928:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010092e:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0100934:	c1 e1 0c             	shl    $0xc,%ecx
f0100937:	39 ca                	cmp    %ecx,%edx
f0100939:	76 14                	jbe    f010094f <boot_alloc+0x61>
	{
		panic("Out of memory!\n");
f010093b:	83 ec 04             	sub    $0x4,%esp
f010093e:	68 64 3b 10 f0       	push   $0xf0103b64
f0100943:	6a 68                	push   $0x68
f0100945:	68 74 3b 10 f0       	push   $0xf0103b74
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
f010096c:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
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
f010097b:	68 10 3e 10 f0       	push   $0xf0103e10
f0100980:	68 e5 02 00 00       	push   $0x2e5
f0100985:	68 74 3b 10 f0       	push   $0xf0103b74
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
f01009d3:	68 34 3e 10 f0       	push   $0xf0103e34
f01009d8:	68 22 02 00 00       	push   $0x222
f01009dd:	68 74 3b 10 f0       	push   $0xf0103b74
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
f01009f5:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
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
f0100a2b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0100a35:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a3b:	eb 53                	jmp    f0100a90 <check_page_free_list+0xd6>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100a3d:	89 d8                	mov    %ebx,%eax
f0100a3f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
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
f0100a59:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a5f:	72 12                	jb     f0100a73 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a61:	50                   	push   %eax
f0100a62:	68 10 3e 10 f0       	push   $0xf0103e10
f0100a67:	6a 57                	push   $0x57
f0100a69:	68 80 3b 10 f0       	push   $0xf0103b80
f0100a6e:	e8 18 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a73:	83 ec 04             	sub    $0x4,%esp
f0100a76:	68 80 00 00 00       	push   $0x80
f0100a7b:	68 97 00 00 00       	push   $0x97
f0100a80:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a85:	50                   	push   %eax
f0100a86:	e8 eb 26 00 00       	call   f0103176 <memset>
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
f0100aa1:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa7:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100aad:	a1 64 69 11 f0       	mov    0xf0116964,%eax
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
f0100acc:	68 8e 3b 10 f0       	push   $0xf0103b8e
f0100ad1:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100ad6:	68 3f 02 00 00       	push   $0x23f
f0100adb:	68 74 3b 10 f0       	push   $0xf0103b74
f0100ae0:	e8 a6 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ae5:	39 fa                	cmp    %edi,%edx
f0100ae7:	72 19                	jb     f0100b02 <check_page_free_list+0x148>
f0100ae9:	68 af 3b 10 f0       	push   $0xf0103baf
f0100aee:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100af3:	68 40 02 00 00       	push   $0x240
f0100af8:	68 74 3b 10 f0       	push   $0xf0103b74
f0100afd:	e8 89 f5 ff ff       	call   f010008b <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100b02:	89 d0                	mov    %edx,%eax
f0100b04:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b07:	a8 07                	test   $0x7,%al
f0100b09:	74 19                	je     f0100b24 <check_page_free_list+0x16a>
f0100b0b:	68 58 3e 10 f0       	push   $0xf0103e58
f0100b10:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100b15:	68 41 02 00 00       	push   $0x241
f0100b1a:	68 74 3b 10 f0       	push   $0xf0103b74
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
f0100b2e:	68 c3 3b 10 f0       	push   $0xf0103bc3
f0100b33:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100b38:	68 44 02 00 00       	push   $0x244
f0100b3d:	68 74 3b 10 f0       	push   $0xf0103b74
f0100b42:	e8 44 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b47:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b4c:	75 19                	jne    f0100b67 <check_page_free_list+0x1ad>
f0100b4e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b53:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100b58:	68 45 02 00 00       	push   $0x245
f0100b5d:	68 74 3b 10 f0       	push   $0xf0103b74
f0100b62:	e8 24 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b67:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b6c:	75 19                	jne    f0100b87 <check_page_free_list+0x1cd>
f0100b6e:	68 88 3e 10 f0       	push   $0xf0103e88
f0100b73:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100b78:	68 46 02 00 00       	push   $0x246
f0100b7d:	68 74 3b 10 f0       	push   $0xf0103b74
f0100b82:	e8 04 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b87:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b8c:	75 19                	jne    f0100ba7 <check_page_free_list+0x1ed>
f0100b8e:	68 ed 3b 10 f0       	push   $0xf0103bed
f0100b93:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100b98:	68 47 02 00 00       	push   $0x247
f0100b9d:	68 74 3b 10 f0       	push   $0xf0103b74
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
f0100bb9:	68 10 3e 10 f0       	push   $0xf0103e10
f0100bbe:	6a 57                	push   $0x57
f0100bc0:	68 80 3b 10 f0       	push   $0xf0103b80
f0100bc5:	e8 c1 f4 ff ff       	call   f010008b <_panic>
f0100bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bd2:	76 1e                	jbe    f0100bf2 <check_page_free_list+0x238>
f0100bd4:	68 ac 3e 10 f0       	push   $0xf0103eac
f0100bd9:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100bde:	68 48 02 00 00       	push   $0x248
f0100be3:	68 74 3b 10 f0       	push   $0xf0103b74
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
f0100c07:	68 07 3c 10 f0       	push   $0xf0103c07
f0100c0c:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100c11:	68 50 02 00 00       	push   $0x250
f0100c16:	68 74 3b 10 f0       	push   $0xf0103b74
f0100c1b:	e8 6b f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c20:	85 db                	test   %ebx,%ebx
f0100c22:	7f 42                	jg     f0100c66 <check_page_free_list+0x2ac>
f0100c24:	68 19 3c 10 f0       	push   $0xf0103c19
f0100c29:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0100c2e:	68 51 02 00 00       	push   $0x251
f0100c33:	68 74 3b 10 f0       	push   $0xf0103b74
f0100c38:	e8 4e f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c3d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c42:	85 c0                	test   %eax,%eax
f0100c44:	0f 85 9d fd ff ff    	jne    f01009e7 <check_page_free_list+0x2d>
f0100c4a:	e9 81 fd ff ff       	jmp    f01009d0 <check_page_free_list+0x16>
f0100c4f:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
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
//
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
f0100c83:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c88:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c8e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100c94:	eb 7c                	jmp    f0100d12 <page_init+0xa4>
		}
		else if (i > npages_basemem - 1 && i < PADDR(boot_alloc(0)) / PGSIZE)
f0100c96:	a1 40 65 11 f0       	mov    0xf0116540,%eax
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
f0100cb4:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0100cb9:	68 10 01 00 00       	push   $0x110
f0100cbe:	68 74 3b 10 f0       	push   $0xf0103b74
f0100cc3:	e8 c3 f3 ff ff       	call   f010008b <_panic>
f0100cc8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ccd:	c1 e8 0c             	shr    $0xc,%eax
f0100cd0:	39 c3                	cmp    %eax,%ebx
f0100cd2:	73 16                	jae    f0100cea <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100cd4:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
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
f0100cf3:	03 15 6c 69 11 f0    	add    0xf011696c,%edx
f0100cf9:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100cff:	8b 0d 3c 65 11 f0    	mov    0xf011653c,%ecx
f0100d05:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100d07:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d0d:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100d12:	83 c3 01             	add    $0x1,%ebx
f0100d15:	3b 1d 64 69 11 f0    	cmp    0xf0116964,%ebx
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
f0100d2d:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d33:	85 db                	test   %ebx,%ebx
f0100d35:	74 58                	je     f0100d8f <page_alloc+0x69>
		return NULL;

	p = page_free_list;
	page_free_list = p->pp_link;
f0100d37:	8b 03                	mov    (%ebx),%eax
f0100d39:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0100d4c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d52:	c1 f8 03             	sar    $0x3,%eax
f0100d55:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d58:	89 c2                	mov    %eax,%edx
f0100d5a:	c1 ea 0c             	shr    $0xc,%edx
f0100d5d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d63:	72 12                	jb     f0100d77 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d65:	50                   	push   %eax
f0100d66:	68 10 3e 10 f0       	push   $0xf0103e10
f0100d6b:	6a 57                	push   $0x57
f0100d6d:	68 80 3b 10 f0       	push   $0xf0103b80
f0100d72:	e8 14 f3 ff ff       	call   f010008b <_panic>
	{
		memset(page2kva(p), 0, PGSIZE);
f0100d77:	83 ec 04             	sub    $0x4,%esp
f0100d7a:	68 00 10 00 00       	push   $0x1000
f0100d7f:	6a 00                	push   $0x0
f0100d81:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d86:	50                   	push   %eax
f0100d87:	e8 ea 23 00 00       	call   f0103176 <memset>
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
f0100dae:	68 2a 3c 10 f0       	push   $0xf0103c2a
f0100db3:	68 4a 01 00 00       	push   $0x14a
f0100db8:	68 74 3b 10 f0       	push   $0xf0103b74
f0100dbd:	e8 c9 f2 ff ff       	call   f010008b <_panic>
	}
	else
	{
		pp->pp_link = page_free_list;
f0100dc2:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100dc8:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100dca:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0100e2d:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100e33:	c1 f8 03             	sar    $0x3,%eax
f0100e36:	c1 e0 0c             	shl    $0xc,%eax
f0100e39:	83 c8 07             	or     $0x7,%eax
f0100e3c:	89 03                	mov    %eax,(%ebx)
	}
	// 返回的页表项的虚拟地址
	
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
f0100e4a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100e50:	72 15                	jb     f0100e67 <pgdir_walk+0x6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e52:	50                   	push   %eax
f0100e53:	68 10 3e 10 f0       	push   $0xf0103e10
f0100e58:	68 87 01 00 00       	push   $0x187
f0100e5d:	68 74 3b 10 f0       	push   $0xf0103b74
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
	
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);

	return pte;
}
f0100e85:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e88:	5b                   	pop    %ebx
f0100e89:	5e                   	pop    %esi
f0100e8a:	5d                   	pop    %ebp
f0100e8b:	c3                   	ret    

f0100e8c <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//
// 双重指针，为了改变指针指向的值
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e8c:	55                   	push   %ebp
f0100e8d:	89 e5                	mov    %esp,%ebp
f0100e8f:	53                   	push   %ebx
f0100e90:	83 ec 08             	sub    $0x8,%esp
f0100e93:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
f0100e96:	6a 00                	push   $0x0
f0100e98:	ff 75 0c             	pushl  0xc(%ebp)
f0100e9b:	ff 75 08             	pushl  0x8(%ebp)
f0100e9e:	e8 55 ff ff ff       	call   f0100df8 <pgdir_walk>
	if (p == NULL)
f0100ea3:	83 c4 10             	add    $0x10,%esp
f0100ea6:	85 c0                	test   %eax,%eax
f0100ea8:	74 32                	je     f0100edc <page_lookup+0x50>
		return NULL;
	if (pte_store != NULL)
f0100eaa:	85 db                	test   %ebx,%ebx
f0100eac:	74 02                	je     f0100eb0 <page_lookup+0x24>
		*pte_store = p;
f0100eae:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb0:	8b 00                	mov    (%eax),%eax
f0100eb2:	c1 e8 0c             	shr    $0xc,%eax
f0100eb5:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100ebb:	72 14                	jb     f0100ed1 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100ebd:	83 ec 04             	sub    $0x4,%esp
f0100ec0:	68 14 3f 10 f0       	push   $0xf0103f14
f0100ec5:	6a 50                	push   $0x50
f0100ec7:	68 80 3b 10 f0       	push   $0xf0103b80
f0100ecc:	e8 ba f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100ed1:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100ed7:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*p));
f0100eda:	eb 05                	jmp    f0100ee1 <page_lookup+0x55>
{
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
	if (p == NULL)
		return NULL;
f0100edc:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != NULL)
		*pte_store = p;

	return pa2page(PTE_ADDR(*p));
}
f0100ee1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ee4:	c9                   	leave  
f0100ee5:	c3                   	ret    

f0100ee6 <page_remove>:
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void page_remove(pde_t *pgdir, void *va)
{
f0100ee6:	55                   	push   %ebp
f0100ee7:	89 e5                	mov    %esp,%ebp
f0100ee9:	53                   	push   %ebx
f0100eea:	83 ec 18             	sub    $0x18,%esp
f0100eed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *p = NULL;
f0100ef0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &p);
f0100ef7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100efa:	50                   	push   %eax
f0100efb:	53                   	push   %ebx
f0100efc:	ff 75 08             	pushl  0x8(%ebp)
f0100eff:	e8 88 ff ff ff       	call   f0100e8c <page_lookup>
	if (page != NULL)
f0100f04:	83 c4 10             	add    $0x10,%esp
f0100f07:	85 c0                	test   %eax,%eax
f0100f09:	74 18                	je     f0100f23 <page_remove+0x3d>
	{
		*p = 0;
f0100f0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f0e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		page_decref(page);
f0100f14:	83 ec 0c             	sub    $0xc,%esp
f0100f17:	50                   	push   %eax
f0100f18:	e8 b4 fe ff ff       	call   f0100dd1 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f1d:	0f 01 3b             	invlpg (%ebx)
f0100f20:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0100f23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f26:	c9                   	leave  
f0100f27:	c3                   	ret    

f0100f28 <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f28:	55                   	push   %ebp
f0100f29:	89 e5                	mov    %esp,%ebp
f0100f2b:	57                   	push   %edi
f0100f2c:	56                   	push   %esi
f0100f2d:	53                   	push   %ebx
f0100f2e:	83 ec 10             	sub    $0x10,%esp
f0100f31:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f34:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *p = pgdir_walk(pgdir, va, 1);
f0100f37:	6a 01                	push   $0x1
f0100f39:	57                   	push   %edi
f0100f3a:	ff 75 08             	pushl  0x8(%ebp)
f0100f3d:	e8 b6 fe ff ff       	call   f0100df8 <pgdir_walk>
	if (p == NULL)
f0100f42:	83 c4 10             	add    $0x10,%esp
f0100f45:	85 c0                	test   %eax,%eax
f0100f47:	74 38                	je     f0100f81 <page_insert+0x59>
f0100f49:	89 c6                	mov    %eax,%esi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100f4b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*p & PTE_P)
f0100f50:	f6 00 01             	testb  $0x1,(%eax)
f0100f53:	74 0f                	je     f0100f64 <page_insert+0x3c>
	{
		page_remove(pgdir,va);
f0100f55:	83 ec 08             	sub    $0x8,%esp
f0100f58:	57                   	push   %edi
f0100f59:	ff 75 08             	pushl  0x8(%ebp)
f0100f5c:	e8 85 ff ff ff       	call   f0100ee6 <page_remove>
f0100f61:	83 c4 10             	add    $0x10,%esp
	}
	*p = page2pa(pp) | perm | PTE_P;
f0100f64:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100f6a:	c1 fb 03             	sar    $0x3,%ebx
f0100f6d:	c1 e3 0c             	shl    $0xc,%ebx
f0100f70:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f73:	83 c8 01             	or     $0x1,%eax
f0100f76:	09 c3                	or     %eax,%ebx
f0100f78:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100f7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f7f:	eb 05                	jmp    f0100f86 <page_insert+0x5e>
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *p = pgdir_walk(pgdir, va, 1);
	if (p == NULL)
	{
		return -E_NO_MEM;
f0100f81:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	{
		page_remove(pgdir,va);
	}
	*p = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0100f86:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f89:	5b                   	pop    %ebx
f0100f8a:	5e                   	pop    %esi
f0100f8b:	5f                   	pop    %edi
f0100f8c:	5d                   	pop    %ebp
f0100f8d:	c3                   	ret    

f0100f8e <mem_init>:
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
// 二级页表

void mem_init(void)
{
f0100f8e:	55                   	push   %ebp
f0100f8f:	89 e5                	mov    %esp,%ebp
f0100f91:	57                   	push   %edi
f0100f92:	56                   	push   %esi
f0100f93:	53                   	push   %ebx
f0100f94:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100f97:	6a 15                	push   $0x15
f0100f99:	e8 08 16 00 00       	call   f01025a6 <mc146818_read>
f0100f9e:	89 c3                	mov    %eax,%ebx
f0100fa0:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100fa7:	e8 fa 15 00 00       	call   f01025a6 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100fac:	c1 e0 08             	shl    $0x8,%eax
f0100faf:	09 d8                	or     %ebx,%eax
f0100fb1:	c1 e0 0a             	shl    $0xa,%eax
f0100fb4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100fba:	85 c0                	test   %eax,%eax
f0100fbc:	0f 48 c2             	cmovs  %edx,%eax
f0100fbf:	c1 f8 0c             	sar    $0xc,%eax
f0100fc2:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fc7:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100fce:	e8 d3 15 00 00       	call   f01025a6 <mc146818_read>
f0100fd3:	89 c3                	mov    %eax,%ebx
f0100fd5:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100fdc:	e8 c5 15 00 00       	call   f01025a6 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100fe1:	c1 e0 08             	shl    $0x8,%eax
f0100fe4:	09 d8                	or     %ebx,%eax
f0100fe6:	c1 e0 0a             	shl    $0xa,%eax
f0100fe9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100fef:	83 c4 10             	add    $0x10,%esp
f0100ff2:	85 c0                	test   %eax,%eax
f0100ff4:	0f 48 c2             	cmovs  %edx,%eax
f0100ff7:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100ffa:	85 c0                	test   %eax,%eax
f0100ffc:	74 0e                	je     f010100c <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100ffe:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101004:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f010100a:	eb 0c                	jmp    f0101018 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010100c:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f0101012:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101018:	c1 e0 0c             	shl    $0xc,%eax
f010101b:	c1 e8 0a             	shr    $0xa,%eax
f010101e:	50                   	push   %eax
f010101f:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101024:	c1 e0 0c             	shl    $0xc,%eax
f0101027:	c1 e8 0a             	shr    $0xa,%eax
f010102a:	50                   	push   %eax
f010102b:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101030:	c1 e0 0c             	shl    $0xc,%eax
f0101033:	c1 e8 0a             	shr    $0xa,%eax
f0101036:	50                   	push   %eax
f0101037:	68 34 3f 10 f0       	push   $0xf0103f34
f010103c:	e8 cc 15 00 00       	call   f010260d <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	// 创建一个初始化的页目录表
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f0101041:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101046:	e8 a3 f8 ff ff       	call   f01008ee <boot_alloc>
f010104b:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f0101050:	83 c4 0c             	add    $0xc,%esp
f0101053:	68 00 10 00 00       	push   $0x1000
f0101058:	6a 00                	push   $0x0
f010105a:	50                   	push   %eax
f010105b:	e8 16 21 00 00       	call   f0103176 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101060:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101065:	83 c4 10             	add    $0x10,%esp
f0101068:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010106d:	77 15                	ja     f0101084 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010106f:	50                   	push   %eax
f0101070:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101075:	68 91 00 00 00       	push   $0x91
f010107a:	68 74 3b 10 f0       	push   $0xf0103b74
f010107f:	e8 07 f0 ff ff       	call   f010008b <_panic>
f0101084:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010108a:	83 ca 05             	or     $0x5,%edx
f010108d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f0101093:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101098:	c1 e0 03             	shl    $0x3,%eax
f010109b:	e8 4e f8 ff ff       	call   f01008ee <boot_alloc>
f01010a0:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f01010a5:	83 ec 04             	sub    $0x4,%esp
f01010a8:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f01010ae:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01010b5:	52                   	push   %edx
f01010b6:	6a 00                	push   $0x0
f01010b8:	50                   	push   %eax
f01010b9:	e8 b8 20 00 00       	call   f0103176 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010be:	e8 ab fb ff ff       	call   f0100c6e <page_init>

	check_page_free_list(1);
f01010c3:	b8 01 00 00 00       	mov    $0x1,%eax
f01010c8:	e8 ed f8 ff ff       	call   f01009ba <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01010cd:	83 c4 10             	add    $0x10,%esp
f01010d0:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f01010d7:	75 17                	jne    f01010f0 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01010d9:	83 ec 04             	sub    $0x4,%esp
f01010dc:	68 39 3c 10 f0       	push   $0xf0103c39
f01010e1:	68 62 02 00 00       	push   $0x262
f01010e6:	68 74 3b 10 f0       	push   $0xf0103b74
f01010eb:	e8 9b ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010f0:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01010f5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010fa:	eb 05                	jmp    f0101101 <mem_init+0x173>
		++nfree;
f01010fc:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010ff:	8b 00                	mov    (%eax),%eax
f0101101:	85 c0                	test   %eax,%eax
f0101103:	75 f7                	jne    f01010fc <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101105:	83 ec 0c             	sub    $0xc,%esp
f0101108:	6a 00                	push   $0x0
f010110a:	e8 17 fc ff ff       	call   f0100d26 <page_alloc>
f010110f:	89 c7                	mov    %eax,%edi
f0101111:	83 c4 10             	add    $0x10,%esp
f0101114:	85 c0                	test   %eax,%eax
f0101116:	75 19                	jne    f0101131 <mem_init+0x1a3>
f0101118:	68 54 3c 10 f0       	push   $0xf0103c54
f010111d:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101122:	68 6a 02 00 00       	push   $0x26a
f0101127:	68 74 3b 10 f0       	push   $0xf0103b74
f010112c:	e8 5a ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101131:	83 ec 0c             	sub    $0xc,%esp
f0101134:	6a 00                	push   $0x0
f0101136:	e8 eb fb ff ff       	call   f0100d26 <page_alloc>
f010113b:	89 c6                	mov    %eax,%esi
f010113d:	83 c4 10             	add    $0x10,%esp
f0101140:	85 c0                	test   %eax,%eax
f0101142:	75 19                	jne    f010115d <mem_init+0x1cf>
f0101144:	68 6a 3c 10 f0       	push   $0xf0103c6a
f0101149:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010114e:	68 6b 02 00 00       	push   $0x26b
f0101153:	68 74 3b 10 f0       	push   $0xf0103b74
f0101158:	e8 2e ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010115d:	83 ec 0c             	sub    $0xc,%esp
f0101160:	6a 00                	push   $0x0
f0101162:	e8 bf fb ff ff       	call   f0100d26 <page_alloc>
f0101167:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010116a:	83 c4 10             	add    $0x10,%esp
f010116d:	85 c0                	test   %eax,%eax
f010116f:	75 19                	jne    f010118a <mem_init+0x1fc>
f0101171:	68 80 3c 10 f0       	push   $0xf0103c80
f0101176:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010117b:	68 6c 02 00 00       	push   $0x26c
f0101180:	68 74 3b 10 f0       	push   $0xf0103b74
f0101185:	e8 01 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010118a:	39 f7                	cmp    %esi,%edi
f010118c:	75 19                	jne    f01011a7 <mem_init+0x219>
f010118e:	68 96 3c 10 f0       	push   $0xf0103c96
f0101193:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101198:	68 6f 02 00 00       	push   $0x26f
f010119d:	68 74 3b 10 f0       	push   $0xf0103b74
f01011a2:	e8 e4 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011aa:	39 c6                	cmp    %eax,%esi
f01011ac:	74 04                	je     f01011b2 <mem_init+0x224>
f01011ae:	39 c7                	cmp    %eax,%edi
f01011b0:	75 19                	jne    f01011cb <mem_init+0x23d>
f01011b2:	68 70 3f 10 f0       	push   $0xf0103f70
f01011b7:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01011bc:	68 70 02 00 00       	push   $0x270
f01011c1:	68 74 3b 10 f0       	push   $0xf0103b74
f01011c6:	e8 c0 ee ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01011cb:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f01011d1:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f01011d7:	c1 e2 0c             	shl    $0xc,%edx
f01011da:	89 f8                	mov    %edi,%eax
f01011dc:	29 c8                	sub    %ecx,%eax
f01011de:	c1 f8 03             	sar    $0x3,%eax
f01011e1:	c1 e0 0c             	shl    $0xc,%eax
f01011e4:	39 d0                	cmp    %edx,%eax
f01011e6:	72 19                	jb     f0101201 <mem_init+0x273>
f01011e8:	68 90 3f 10 f0       	push   $0xf0103f90
f01011ed:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01011f2:	68 71 02 00 00       	push   $0x271
f01011f7:	68 74 3b 10 f0       	push   $0xf0103b74
f01011fc:	e8 8a ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f0101201:	89 f0                	mov    %esi,%eax
f0101203:	29 c8                	sub    %ecx,%eax
f0101205:	c1 f8 03             	sar    $0x3,%eax
f0101208:	c1 e0 0c             	shl    $0xc,%eax
f010120b:	39 c2                	cmp    %eax,%edx
f010120d:	77 19                	ja     f0101228 <mem_init+0x29a>
f010120f:	68 b0 3f 10 f0       	push   $0xf0103fb0
f0101214:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101219:	68 72 02 00 00       	push   $0x272
f010121e:	68 74 3b 10 f0       	push   $0xf0103b74
f0101223:	e8 63 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f0101228:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010122b:	29 c8                	sub    %ecx,%eax
f010122d:	c1 f8 03             	sar    $0x3,%eax
f0101230:	c1 e0 0c             	shl    $0xc,%eax
f0101233:	39 c2                	cmp    %eax,%edx
f0101235:	77 19                	ja     f0101250 <mem_init+0x2c2>
f0101237:	68 d0 3f 10 f0       	push   $0xf0103fd0
f010123c:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101241:	68 73 02 00 00       	push   $0x273
f0101246:	68 74 3b 10 f0       	push   $0xf0103b74
f010124b:	e8 3b ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101250:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101255:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101258:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010125f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101262:	83 ec 0c             	sub    $0xc,%esp
f0101265:	6a 00                	push   $0x0
f0101267:	e8 ba fa ff ff       	call   f0100d26 <page_alloc>
f010126c:	83 c4 10             	add    $0x10,%esp
f010126f:	85 c0                	test   %eax,%eax
f0101271:	74 19                	je     f010128c <mem_init+0x2fe>
f0101273:	68 a8 3c 10 f0       	push   $0xf0103ca8
f0101278:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010127d:	68 7a 02 00 00       	push   $0x27a
f0101282:	68 74 3b 10 f0       	push   $0xf0103b74
f0101287:	e8 ff ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010128c:	83 ec 0c             	sub    $0xc,%esp
f010128f:	57                   	push   %edi
f0101290:	e8 01 fb ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f0101295:	89 34 24             	mov    %esi,(%esp)
f0101298:	e8 f9 fa ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f010129d:	83 c4 04             	add    $0x4,%esp
f01012a0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012a3:	e8 ee fa ff ff       	call   f0100d96 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012af:	e8 72 fa ff ff       	call   f0100d26 <page_alloc>
f01012b4:	89 c6                	mov    %eax,%esi
f01012b6:	83 c4 10             	add    $0x10,%esp
f01012b9:	85 c0                	test   %eax,%eax
f01012bb:	75 19                	jne    f01012d6 <mem_init+0x348>
f01012bd:	68 54 3c 10 f0       	push   $0xf0103c54
f01012c2:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01012c7:	68 81 02 00 00       	push   $0x281
f01012cc:	68 74 3b 10 f0       	push   $0xf0103b74
f01012d1:	e8 b5 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012d6:	83 ec 0c             	sub    $0xc,%esp
f01012d9:	6a 00                	push   $0x0
f01012db:	e8 46 fa ff ff       	call   f0100d26 <page_alloc>
f01012e0:	89 c7                	mov    %eax,%edi
f01012e2:	83 c4 10             	add    $0x10,%esp
f01012e5:	85 c0                	test   %eax,%eax
f01012e7:	75 19                	jne    f0101302 <mem_init+0x374>
f01012e9:	68 6a 3c 10 f0       	push   $0xf0103c6a
f01012ee:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01012f3:	68 82 02 00 00       	push   $0x282
f01012f8:	68 74 3b 10 f0       	push   $0xf0103b74
f01012fd:	e8 89 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101302:	83 ec 0c             	sub    $0xc,%esp
f0101305:	6a 00                	push   $0x0
f0101307:	e8 1a fa ff ff       	call   f0100d26 <page_alloc>
f010130c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010130f:	83 c4 10             	add    $0x10,%esp
f0101312:	85 c0                	test   %eax,%eax
f0101314:	75 19                	jne    f010132f <mem_init+0x3a1>
f0101316:	68 80 3c 10 f0       	push   $0xf0103c80
f010131b:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101320:	68 83 02 00 00       	push   $0x283
f0101325:	68 74 3b 10 f0       	push   $0xf0103b74
f010132a:	e8 5c ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010132f:	39 fe                	cmp    %edi,%esi
f0101331:	75 19                	jne    f010134c <mem_init+0x3be>
f0101333:	68 96 3c 10 f0       	push   $0xf0103c96
f0101338:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010133d:	68 85 02 00 00       	push   $0x285
f0101342:	68 74 3b 10 f0       	push   $0xf0103b74
f0101347:	e8 3f ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010134c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010134f:	39 c7                	cmp    %eax,%edi
f0101351:	74 04                	je     f0101357 <mem_init+0x3c9>
f0101353:	39 c6                	cmp    %eax,%esi
f0101355:	75 19                	jne    f0101370 <mem_init+0x3e2>
f0101357:	68 70 3f 10 f0       	push   $0xf0103f70
f010135c:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101361:	68 86 02 00 00       	push   $0x286
f0101366:	68 74 3b 10 f0       	push   $0xf0103b74
f010136b:	e8 1b ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101370:	83 ec 0c             	sub    $0xc,%esp
f0101373:	6a 00                	push   $0x0
f0101375:	e8 ac f9 ff ff       	call   f0100d26 <page_alloc>
f010137a:	83 c4 10             	add    $0x10,%esp
f010137d:	85 c0                	test   %eax,%eax
f010137f:	74 19                	je     f010139a <mem_init+0x40c>
f0101381:	68 a8 3c 10 f0       	push   $0xf0103ca8
f0101386:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010138b:	68 87 02 00 00       	push   $0x287
f0101390:	68 74 3b 10 f0       	push   $0xf0103b74
f0101395:	e8 f1 ec ff ff       	call   f010008b <_panic>
f010139a:	89 f0                	mov    %esi,%eax
f010139c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01013a2:	c1 f8 03             	sar    $0x3,%eax
f01013a5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013a8:	89 c2                	mov    %eax,%edx
f01013aa:	c1 ea 0c             	shr    $0xc,%edx
f01013ad:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01013b3:	72 12                	jb     f01013c7 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013b5:	50                   	push   %eax
f01013b6:	68 10 3e 10 f0       	push   $0xf0103e10
f01013bb:	6a 57                	push   $0x57
f01013bd:	68 80 3b 10 f0       	push   $0xf0103b80
f01013c2:	e8 c4 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013c7:	83 ec 04             	sub    $0x4,%esp
f01013ca:	68 00 10 00 00       	push   $0x1000
f01013cf:	6a 01                	push   $0x1
f01013d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013d6:	50                   	push   %eax
f01013d7:	e8 9a 1d 00 00       	call   f0103176 <memset>
	page_free(pp0);
f01013dc:	89 34 24             	mov    %esi,(%esp)
f01013df:	e8 b2 f9 ff ff       	call   f0100d96 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013e4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013eb:	e8 36 f9 ff ff       	call   f0100d26 <page_alloc>
f01013f0:	83 c4 10             	add    $0x10,%esp
f01013f3:	85 c0                	test   %eax,%eax
f01013f5:	75 19                	jne    f0101410 <mem_init+0x482>
f01013f7:	68 b7 3c 10 f0       	push   $0xf0103cb7
f01013fc:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101401:	68 8c 02 00 00       	push   $0x28c
f0101406:	68 74 3b 10 f0       	push   $0xf0103b74
f010140b:	e8 7b ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101410:	39 c6                	cmp    %eax,%esi
f0101412:	74 19                	je     f010142d <mem_init+0x49f>
f0101414:	68 d5 3c 10 f0       	push   $0xf0103cd5
f0101419:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010141e:	68 8d 02 00 00       	push   $0x28d
f0101423:	68 74 3b 10 f0       	push   $0xf0103b74
f0101428:	e8 5e ec ff ff       	call   f010008b <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010142d:	89 f0                	mov    %esi,%eax
f010142f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101435:	c1 f8 03             	sar    $0x3,%eax
f0101438:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010143b:	89 c2                	mov    %eax,%edx
f010143d:	c1 ea 0c             	shr    $0xc,%edx
f0101440:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101446:	72 12                	jb     f010145a <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101448:	50                   	push   %eax
f0101449:	68 10 3e 10 f0       	push   $0xf0103e10
f010144e:	6a 57                	push   $0x57
f0101450:	68 80 3b 10 f0       	push   $0xf0103b80
f0101455:	e8 31 ec ff ff       	call   f010008b <_panic>
f010145a:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101460:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101466:	80 38 00             	cmpb   $0x0,(%eax)
f0101469:	74 19                	je     f0101484 <mem_init+0x4f6>
f010146b:	68 e5 3c 10 f0       	push   $0xf0103ce5
f0101470:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101475:	68 90 02 00 00       	push   $0x290
f010147a:	68 74 3b 10 f0       	push   $0xf0103b74
f010147f:	e8 07 ec ff ff       	call   f010008b <_panic>
f0101484:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101487:	39 d0                	cmp    %edx,%eax
f0101489:	75 db                	jne    f0101466 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010148b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010148e:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101493:	83 ec 0c             	sub    $0xc,%esp
f0101496:	56                   	push   %esi
f0101497:	e8 fa f8 ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f010149c:	89 3c 24             	mov    %edi,(%esp)
f010149f:	e8 f2 f8 ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f01014a4:	83 c4 04             	add    $0x4,%esp
f01014a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014aa:	e8 e7 f8 ff ff       	call   f0100d96 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014af:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01014b4:	83 c4 10             	add    $0x10,%esp
f01014b7:	eb 05                	jmp    f01014be <mem_init+0x530>
		--nfree;
f01014b9:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014bc:	8b 00                	mov    (%eax),%eax
f01014be:	85 c0                	test   %eax,%eax
f01014c0:	75 f7                	jne    f01014b9 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01014c2:	85 db                	test   %ebx,%ebx
f01014c4:	74 19                	je     f01014df <mem_init+0x551>
f01014c6:	68 ef 3c 10 f0       	push   $0xf0103cef
f01014cb:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01014d0:	68 9d 02 00 00       	push   $0x29d
f01014d5:	68 74 3b 10 f0       	push   $0xf0103b74
f01014da:	e8 ac eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014df:	83 ec 0c             	sub    $0xc,%esp
f01014e2:	68 f0 3f 10 f0       	push   $0xf0103ff0
f01014e7:	e8 21 11 00 00       	call   f010260d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f3:	e8 2e f8 ff ff       	call   f0100d26 <page_alloc>
f01014f8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014fb:	83 c4 10             	add    $0x10,%esp
f01014fe:	85 c0                	test   %eax,%eax
f0101500:	75 19                	jne    f010151b <mem_init+0x58d>
f0101502:	68 54 3c 10 f0       	push   $0xf0103c54
f0101507:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010150c:	68 f8 02 00 00       	push   $0x2f8
f0101511:	68 74 3b 10 f0       	push   $0xf0103b74
f0101516:	e8 70 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010151b:	83 ec 0c             	sub    $0xc,%esp
f010151e:	6a 00                	push   $0x0
f0101520:	e8 01 f8 ff ff       	call   f0100d26 <page_alloc>
f0101525:	89 c3                	mov    %eax,%ebx
f0101527:	83 c4 10             	add    $0x10,%esp
f010152a:	85 c0                	test   %eax,%eax
f010152c:	75 19                	jne    f0101547 <mem_init+0x5b9>
f010152e:	68 6a 3c 10 f0       	push   $0xf0103c6a
f0101533:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101538:	68 f9 02 00 00       	push   $0x2f9
f010153d:	68 74 3b 10 f0       	push   $0xf0103b74
f0101542:	e8 44 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101547:	83 ec 0c             	sub    $0xc,%esp
f010154a:	6a 00                	push   $0x0
f010154c:	e8 d5 f7 ff ff       	call   f0100d26 <page_alloc>
f0101551:	89 c6                	mov    %eax,%esi
f0101553:	83 c4 10             	add    $0x10,%esp
f0101556:	85 c0                	test   %eax,%eax
f0101558:	75 19                	jne    f0101573 <mem_init+0x5e5>
f010155a:	68 80 3c 10 f0       	push   $0xf0103c80
f010155f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101564:	68 fa 02 00 00       	push   $0x2fa
f0101569:	68 74 3b 10 f0       	push   $0xf0103b74
f010156e:	e8 18 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101573:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101576:	75 19                	jne    f0101591 <mem_init+0x603>
f0101578:	68 96 3c 10 f0       	push   $0xf0103c96
f010157d:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101582:	68 fd 02 00 00       	push   $0x2fd
f0101587:	68 74 3b 10 f0       	push   $0xf0103b74
f010158c:	e8 fa ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101591:	39 c3                	cmp    %eax,%ebx
f0101593:	74 05                	je     f010159a <mem_init+0x60c>
f0101595:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101598:	75 19                	jne    f01015b3 <mem_init+0x625>
f010159a:	68 70 3f 10 f0       	push   $0xf0103f70
f010159f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01015a4:	68 fe 02 00 00       	push   $0x2fe
f01015a9:	68 74 3b 10 f0       	push   $0xf0103b74
f01015ae:	e8 d8 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015b3:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01015b8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015bb:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01015c2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 57 f7 ff ff       	call   f0100d26 <page_alloc>
f01015cf:	83 c4 10             	add    $0x10,%esp
f01015d2:	85 c0                	test   %eax,%eax
f01015d4:	74 19                	je     f01015ef <mem_init+0x661>
f01015d6:	68 a8 3c 10 f0       	push   $0xf0103ca8
f01015db:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01015e0:	68 05 03 00 00       	push   $0x305
f01015e5:	68 74 3b 10 f0       	push   $0xf0103b74
f01015ea:	e8 9c ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f01015ef:	83 ec 04             	sub    $0x4,%esp
f01015f2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015f5:	50                   	push   %eax
f01015f6:	6a 00                	push   $0x0
f01015f8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01015fe:	e8 89 f8 ff ff       	call   f0100e8c <page_lookup>
f0101603:	83 c4 10             	add    $0x10,%esp
f0101606:	85 c0                	test   %eax,%eax
f0101608:	74 19                	je     f0101623 <mem_init+0x695>
f010160a:	68 10 40 10 f0       	push   $0xf0104010
f010160f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101614:	68 08 03 00 00       	push   $0x308
f0101619:	68 74 3b 10 f0       	push   $0xf0103b74
f010161e:	e8 68 ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101623:	6a 02                	push   $0x2
f0101625:	6a 00                	push   $0x0
f0101627:	53                   	push   %ebx
f0101628:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010162e:	e8 f5 f8 ff ff       	call   f0100f28 <page_insert>
f0101633:	83 c4 10             	add    $0x10,%esp
f0101636:	85 c0                	test   %eax,%eax
f0101638:	78 19                	js     f0101653 <mem_init+0x6c5>
f010163a:	68 44 40 10 f0       	push   $0xf0104044
f010163f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101644:	68 0b 03 00 00       	push   $0x30b
f0101649:	68 74 3b 10 f0       	push   $0xf0103b74
f010164e:	e8 38 ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101653:	83 ec 0c             	sub    $0xc,%esp
f0101656:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101659:	e8 38 f7 ff ff       	call   f0100d96 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010165e:	6a 02                	push   $0x2
f0101660:	6a 00                	push   $0x0
f0101662:	53                   	push   %ebx
f0101663:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101669:	e8 ba f8 ff ff       	call   f0100f28 <page_insert>
f010166e:	83 c4 20             	add    $0x20,%esp
f0101671:	85 c0                	test   %eax,%eax
f0101673:	74 19                	je     f010168e <mem_init+0x700>
f0101675:	68 74 40 10 f0       	push   $0xf0104074
f010167a:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010167f:	68 0f 03 00 00       	push   $0x30f
f0101684:	68 74 3b 10 f0       	push   $0xf0103b74
f0101689:	e8 fd e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010168e:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101694:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101699:	89 c1                	mov    %eax,%ecx
f010169b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010169e:	8b 17                	mov    (%edi),%edx
f01016a0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a9:	29 c8                	sub    %ecx,%eax
f01016ab:	c1 f8 03             	sar    $0x3,%eax
f01016ae:	c1 e0 0c             	shl    $0xc,%eax
f01016b1:	39 c2                	cmp    %eax,%edx
f01016b3:	74 19                	je     f01016ce <mem_init+0x740>
f01016b5:	68 a4 40 10 f0       	push   $0xf01040a4
f01016ba:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01016bf:	68 10 03 00 00       	push   $0x310
f01016c4:	68 74 3b 10 f0       	push   $0xf0103b74
f01016c9:	e8 bd e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01016ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01016d3:	89 f8                	mov    %edi,%eax
f01016d5:	e8 7c f2 ff ff       	call   f0100956 <check_va2pa>
f01016da:	89 da                	mov    %ebx,%edx
f01016dc:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016df:	c1 fa 03             	sar    $0x3,%edx
f01016e2:	c1 e2 0c             	shl    $0xc,%edx
f01016e5:	39 d0                	cmp    %edx,%eax
f01016e7:	74 19                	je     f0101702 <mem_init+0x774>
f01016e9:	68 cc 40 10 f0       	push   $0xf01040cc
f01016ee:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01016f3:	68 11 03 00 00       	push   $0x311
f01016f8:	68 74 3b 10 f0       	push   $0xf0103b74
f01016fd:	e8 89 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101702:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101707:	74 19                	je     f0101722 <mem_init+0x794>
f0101709:	68 fa 3c 10 f0       	push   $0xf0103cfa
f010170e:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101713:	68 12 03 00 00       	push   $0x312
f0101718:	68 74 3b 10 f0       	push   $0xf0103b74
f010171d:	e8 69 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101722:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101725:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010172a:	74 19                	je     f0101745 <mem_init+0x7b7>
f010172c:	68 0b 3d 10 f0       	push   $0xf0103d0b
f0101731:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101736:	68 13 03 00 00       	push   $0x313
f010173b:	68 74 3b 10 f0       	push   $0xf0103b74
f0101740:	e8 46 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101745:	6a 02                	push   $0x2
f0101747:	68 00 10 00 00       	push   $0x1000
f010174c:	56                   	push   %esi
f010174d:	57                   	push   %edi
f010174e:	e8 d5 f7 ff ff       	call   f0100f28 <page_insert>
f0101753:	83 c4 10             	add    $0x10,%esp
f0101756:	85 c0                	test   %eax,%eax
f0101758:	74 19                	je     f0101773 <mem_init+0x7e5>
f010175a:	68 fc 40 10 f0       	push   $0xf01040fc
f010175f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101764:	68 16 03 00 00       	push   $0x316
f0101769:	68 74 3b 10 f0       	push   $0xf0103b74
f010176e:	e8 18 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101773:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101778:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010177d:	e8 d4 f1 ff ff       	call   f0100956 <check_va2pa>
f0101782:	89 f2                	mov    %esi,%edx
f0101784:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010178a:	c1 fa 03             	sar    $0x3,%edx
f010178d:	c1 e2 0c             	shl    $0xc,%edx
f0101790:	39 d0                	cmp    %edx,%eax
f0101792:	74 19                	je     f01017ad <mem_init+0x81f>
f0101794:	68 38 41 10 f0       	push   $0xf0104138
f0101799:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010179e:	68 17 03 00 00       	push   $0x317
f01017a3:	68 74 3b 10 f0       	push   $0xf0103b74
f01017a8:	e8 de e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017ad:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017b2:	74 19                	je     f01017cd <mem_init+0x83f>
f01017b4:	68 1c 3d 10 f0       	push   $0xf0103d1c
f01017b9:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01017be:	68 18 03 00 00       	push   $0x318
f01017c3:	68 74 3b 10 f0       	push   $0xf0103b74
f01017c8:	e8 be e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01017cd:	83 ec 0c             	sub    $0xc,%esp
f01017d0:	6a 00                	push   $0x0
f01017d2:	e8 4f f5 ff ff       	call   f0100d26 <page_alloc>
f01017d7:	83 c4 10             	add    $0x10,%esp
f01017da:	85 c0                	test   %eax,%eax
f01017dc:	74 19                	je     f01017f7 <mem_init+0x869>
f01017de:	68 a8 3c 10 f0       	push   $0xf0103ca8
f01017e3:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01017e8:	68 1b 03 00 00       	push   $0x31b
f01017ed:	68 74 3b 10 f0       	push   $0xf0103b74
f01017f2:	e8 94 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01017f7:	6a 02                	push   $0x2
f01017f9:	68 00 10 00 00       	push   $0x1000
f01017fe:	56                   	push   %esi
f01017ff:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101805:	e8 1e f7 ff ff       	call   f0100f28 <page_insert>
f010180a:	83 c4 10             	add    $0x10,%esp
f010180d:	85 c0                	test   %eax,%eax
f010180f:	74 19                	je     f010182a <mem_init+0x89c>
f0101811:	68 fc 40 10 f0       	push   $0xf01040fc
f0101816:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010181b:	68 1e 03 00 00       	push   $0x31e
f0101820:	68 74 3b 10 f0       	push   $0xf0103b74
f0101825:	e8 61 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010182a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010182f:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101834:	e8 1d f1 ff ff       	call   f0100956 <check_va2pa>
f0101839:	89 f2                	mov    %esi,%edx
f010183b:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101841:	c1 fa 03             	sar    $0x3,%edx
f0101844:	c1 e2 0c             	shl    $0xc,%edx
f0101847:	39 d0                	cmp    %edx,%eax
f0101849:	74 19                	je     f0101864 <mem_init+0x8d6>
f010184b:	68 38 41 10 f0       	push   $0xf0104138
f0101850:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101855:	68 1f 03 00 00       	push   $0x31f
f010185a:	68 74 3b 10 f0       	push   $0xf0103b74
f010185f:	e8 27 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101864:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101869:	74 19                	je     f0101884 <mem_init+0x8f6>
f010186b:	68 1c 3d 10 f0       	push   $0xf0103d1c
f0101870:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101875:	68 20 03 00 00       	push   $0x320
f010187a:	68 74 3b 10 f0       	push   $0xf0103b74
f010187f:	e8 07 e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101884:	83 ec 0c             	sub    $0xc,%esp
f0101887:	6a 00                	push   $0x0
f0101889:	e8 98 f4 ff ff       	call   f0100d26 <page_alloc>
f010188e:	83 c4 10             	add    $0x10,%esp
f0101891:	85 c0                	test   %eax,%eax
f0101893:	74 19                	je     f01018ae <mem_init+0x920>
f0101895:	68 a8 3c 10 f0       	push   $0xf0103ca8
f010189a:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010189f:	68 24 03 00 00       	push   $0x324
f01018a4:	68 74 3b 10 f0       	push   $0xf0103b74
f01018a9:	e8 dd e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018ae:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f01018b4:	8b 02                	mov    (%edx),%eax
f01018b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018bb:	89 c1                	mov    %eax,%ecx
f01018bd:	c1 e9 0c             	shr    $0xc,%ecx
f01018c0:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01018c6:	72 15                	jb     f01018dd <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018c8:	50                   	push   %eax
f01018c9:	68 10 3e 10 f0       	push   $0xf0103e10
f01018ce:	68 27 03 00 00       	push   $0x327
f01018d3:	68 74 3b 10 f0       	push   $0xf0103b74
f01018d8:	e8 ae e7 ff ff       	call   f010008b <_panic>
f01018dd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f01018e5:	83 ec 04             	sub    $0x4,%esp
f01018e8:	6a 00                	push   $0x0
f01018ea:	68 00 10 00 00       	push   $0x1000
f01018ef:	52                   	push   %edx
f01018f0:	e8 03 f5 ff ff       	call   f0100df8 <pgdir_walk>
f01018f5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01018f8:	8d 51 04             	lea    0x4(%ecx),%edx
f01018fb:	83 c4 10             	add    $0x10,%esp
f01018fe:	39 d0                	cmp    %edx,%eax
f0101900:	74 19                	je     f010191b <mem_init+0x98d>
f0101902:	68 68 41 10 f0       	push   $0xf0104168
f0101907:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010190c:	68 28 03 00 00       	push   $0x328
f0101911:	68 74 3b 10 f0       	push   $0xf0103b74
f0101916:	e8 70 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f010191b:	6a 06                	push   $0x6
f010191d:	68 00 10 00 00       	push   $0x1000
f0101922:	56                   	push   %esi
f0101923:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101929:	e8 fa f5 ff ff       	call   f0100f28 <page_insert>
f010192e:	83 c4 10             	add    $0x10,%esp
f0101931:	85 c0                	test   %eax,%eax
f0101933:	74 19                	je     f010194e <mem_init+0x9c0>
f0101935:	68 a8 41 10 f0       	push   $0xf01041a8
f010193a:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010193f:	68 2b 03 00 00       	push   $0x32b
f0101944:	68 74 3b 10 f0       	push   $0xf0103b74
f0101949:	e8 3d e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010194e:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101954:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101959:	89 f8                	mov    %edi,%eax
f010195b:	e8 f6 ef ff ff       	call   f0100956 <check_va2pa>
f0101960:	89 f2                	mov    %esi,%edx
f0101962:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101968:	c1 fa 03             	sar    $0x3,%edx
f010196b:	c1 e2 0c             	shl    $0xc,%edx
f010196e:	39 d0                	cmp    %edx,%eax
f0101970:	74 19                	je     f010198b <mem_init+0x9fd>
f0101972:	68 38 41 10 f0       	push   $0xf0104138
f0101977:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010197c:	68 2c 03 00 00       	push   $0x32c
f0101981:	68 74 3b 10 f0       	push   $0xf0103b74
f0101986:	e8 00 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010198b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101990:	74 19                	je     f01019ab <mem_init+0xa1d>
f0101992:	68 1c 3d 10 f0       	push   $0xf0103d1c
f0101997:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010199c:	68 2d 03 00 00       	push   $0x32d
f01019a1:	68 74 3b 10 f0       	push   $0xf0103b74
f01019a6:	e8 e0 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f01019ab:	83 ec 04             	sub    $0x4,%esp
f01019ae:	6a 00                	push   $0x0
f01019b0:	68 00 10 00 00       	push   $0x1000
f01019b5:	57                   	push   %edi
f01019b6:	e8 3d f4 ff ff       	call   f0100df8 <pgdir_walk>
f01019bb:	83 c4 10             	add    $0x10,%esp
f01019be:	f6 00 04             	testb  $0x4,(%eax)
f01019c1:	75 19                	jne    f01019dc <mem_init+0xa4e>
f01019c3:	68 ec 41 10 f0       	push   $0xf01041ec
f01019c8:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01019cd:	68 2e 03 00 00       	push   $0x32e
f01019d2:	68 74 3b 10 f0       	push   $0xf0103b74
f01019d7:	e8 af e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019dc:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01019e1:	f6 00 04             	testb  $0x4,(%eax)
f01019e4:	75 19                	jne    f01019ff <mem_init+0xa71>
f01019e6:	68 2d 3d 10 f0       	push   $0xf0103d2d
f01019eb:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01019f0:	68 2f 03 00 00       	push   $0x32f
f01019f5:	68 74 3b 10 f0       	push   $0xf0103b74
f01019fa:	e8 8c e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01019ff:	6a 02                	push   $0x2
f0101a01:	68 00 10 00 00       	push   $0x1000
f0101a06:	56                   	push   %esi
f0101a07:	50                   	push   %eax
f0101a08:	e8 1b f5 ff ff       	call   f0100f28 <page_insert>
f0101a0d:	83 c4 10             	add    $0x10,%esp
f0101a10:	85 c0                	test   %eax,%eax
f0101a12:	74 19                	je     f0101a2d <mem_init+0xa9f>
f0101a14:	68 fc 40 10 f0       	push   $0xf01040fc
f0101a19:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101a1e:	68 32 03 00 00       	push   $0x332
f0101a23:	68 74 3b 10 f0       	push   $0xf0103b74
f0101a28:	e8 5e e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101a2d:	83 ec 04             	sub    $0x4,%esp
f0101a30:	6a 00                	push   $0x0
f0101a32:	68 00 10 00 00       	push   $0x1000
f0101a37:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a3d:	e8 b6 f3 ff ff       	call   f0100df8 <pgdir_walk>
f0101a42:	83 c4 10             	add    $0x10,%esp
f0101a45:	f6 00 02             	testb  $0x2,(%eax)
f0101a48:	75 19                	jne    f0101a63 <mem_init+0xad5>
f0101a4a:	68 20 42 10 f0       	push   $0xf0104220
f0101a4f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101a54:	68 33 03 00 00       	push   $0x333
f0101a59:	68 74 3b 10 f0       	push   $0xf0103b74
f0101a5e:	e8 28 e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101a63:	83 ec 04             	sub    $0x4,%esp
f0101a66:	6a 00                	push   $0x0
f0101a68:	68 00 10 00 00       	push   $0x1000
f0101a6d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a73:	e8 80 f3 ff ff       	call   f0100df8 <pgdir_walk>
f0101a78:	83 c4 10             	add    $0x10,%esp
f0101a7b:	f6 00 04             	testb  $0x4,(%eax)
f0101a7e:	74 19                	je     f0101a99 <mem_init+0xb0b>
f0101a80:	68 54 42 10 f0       	push   $0xf0104254
f0101a85:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101a8a:	68 34 03 00 00       	push   $0x334
f0101a8f:	68 74 3b 10 f0       	push   $0xf0103b74
f0101a94:	e8 f2 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101a99:	6a 02                	push   $0x2
f0101a9b:	68 00 00 40 00       	push   $0x400000
f0101aa0:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101aa3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101aa9:	e8 7a f4 ff ff       	call   f0100f28 <page_insert>
f0101aae:	83 c4 10             	add    $0x10,%esp
f0101ab1:	85 c0                	test   %eax,%eax
f0101ab3:	78 19                	js     f0101ace <mem_init+0xb40>
f0101ab5:	68 8c 42 10 f0       	push   $0xf010428c
f0101aba:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101abf:	68 37 03 00 00       	push   $0x337
f0101ac4:	68 74 3b 10 f0       	push   $0xf0103b74
f0101ac9:	e8 bd e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101ace:	6a 02                	push   $0x2
f0101ad0:	68 00 10 00 00       	push   $0x1000
f0101ad5:	53                   	push   %ebx
f0101ad6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101adc:	e8 47 f4 ff ff       	call   f0100f28 <page_insert>
f0101ae1:	83 c4 10             	add    $0x10,%esp
f0101ae4:	85 c0                	test   %eax,%eax
f0101ae6:	74 19                	je     f0101b01 <mem_init+0xb73>
f0101ae8:	68 c4 42 10 f0       	push   $0xf01042c4
f0101aed:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101af2:	68 3a 03 00 00       	push   $0x33a
f0101af7:	68 74 3b 10 f0       	push   $0xf0103b74
f0101afc:	e8 8a e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101b01:	83 ec 04             	sub    $0x4,%esp
f0101b04:	6a 00                	push   $0x0
f0101b06:	68 00 10 00 00       	push   $0x1000
f0101b0b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b11:	e8 e2 f2 ff ff       	call   f0100df8 <pgdir_walk>
f0101b16:	83 c4 10             	add    $0x10,%esp
f0101b19:	f6 00 04             	testb  $0x4,(%eax)
f0101b1c:	74 19                	je     f0101b37 <mem_init+0xba9>
f0101b1e:	68 54 42 10 f0       	push   $0xf0104254
f0101b23:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101b28:	68 3b 03 00 00       	push   $0x33b
f0101b2d:	68 74 3b 10 f0       	push   $0xf0103b74
f0101b32:	e8 54 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b37:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101b3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b42:	89 f8                	mov    %edi,%eax
f0101b44:	e8 0d ee ff ff       	call   f0100956 <check_va2pa>
f0101b49:	89 c1                	mov    %eax,%ecx
f0101b4b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b4e:	89 d8                	mov    %ebx,%eax
f0101b50:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101b56:	c1 f8 03             	sar    $0x3,%eax
f0101b59:	c1 e0 0c             	shl    $0xc,%eax
f0101b5c:	39 c1                	cmp    %eax,%ecx
f0101b5e:	74 19                	je     f0101b79 <mem_init+0xbeb>
f0101b60:	68 00 43 10 f0       	push   $0xf0104300
f0101b65:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101b6a:	68 3e 03 00 00       	push   $0x33e
f0101b6f:	68 74 3b 10 f0       	push   $0xf0103b74
f0101b74:	e8 12 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b79:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b7e:	89 f8                	mov    %edi,%eax
f0101b80:	e8 d1 ed ff ff       	call   f0100956 <check_va2pa>
f0101b85:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b88:	74 19                	je     f0101ba3 <mem_init+0xc15>
f0101b8a:	68 2c 43 10 f0       	push   $0xf010432c
f0101b8f:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101b94:	68 3f 03 00 00       	push   $0x33f
f0101b99:	68 74 3b 10 f0       	push   $0xf0103b74
f0101b9e:	e8 e8 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ba3:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ba8:	74 19                	je     f0101bc3 <mem_init+0xc35>
f0101baa:	68 43 3d 10 f0       	push   $0xf0103d43
f0101baf:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101bb4:	68 41 03 00 00       	push   $0x341
f0101bb9:	68 74 3b 10 f0       	push   $0xf0103b74
f0101bbe:	e8 c8 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101bc3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101bc8:	74 19                	je     f0101be3 <mem_init+0xc55>
f0101bca:	68 54 3d 10 f0       	push   $0xf0103d54
f0101bcf:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101bd4:	68 42 03 00 00       	push   $0x342
f0101bd9:	68 74 3b 10 f0       	push   $0xf0103b74
f0101bde:	e8 a8 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101be3:	83 ec 0c             	sub    $0xc,%esp
f0101be6:	6a 00                	push   $0x0
f0101be8:	e8 39 f1 ff ff       	call   f0100d26 <page_alloc>
f0101bed:	83 c4 10             	add    $0x10,%esp
f0101bf0:	85 c0                	test   %eax,%eax
f0101bf2:	74 04                	je     f0101bf8 <mem_init+0xc6a>
f0101bf4:	39 c6                	cmp    %eax,%esi
f0101bf6:	74 19                	je     f0101c11 <mem_init+0xc83>
f0101bf8:	68 5c 43 10 f0       	push   $0xf010435c
f0101bfd:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101c02:	68 45 03 00 00       	push   $0x345
f0101c07:	68 74 3b 10 f0       	push   $0xf0103b74
f0101c0c:	e8 7a e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c11:	83 ec 08             	sub    $0x8,%esp
f0101c14:	6a 00                	push   $0x0
f0101c16:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c1c:	e8 c5 f2 ff ff       	call   f0100ee6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c21:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c27:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c2c:	89 f8                	mov    %edi,%eax
f0101c2e:	e8 23 ed ff ff       	call   f0100956 <check_va2pa>
f0101c33:	83 c4 10             	add    $0x10,%esp
f0101c36:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c39:	74 19                	je     f0101c54 <mem_init+0xcc6>
f0101c3b:	68 80 43 10 f0       	push   $0xf0104380
f0101c40:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101c45:	68 49 03 00 00       	push   $0x349
f0101c4a:	68 74 3b 10 f0       	push   $0xf0103b74
f0101c4f:	e8 37 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c54:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c59:	89 f8                	mov    %edi,%eax
f0101c5b:	e8 f6 ec ff ff       	call   f0100956 <check_va2pa>
f0101c60:	89 da                	mov    %ebx,%edx
f0101c62:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101c68:	c1 fa 03             	sar    $0x3,%edx
f0101c6b:	c1 e2 0c             	shl    $0xc,%edx
f0101c6e:	39 d0                	cmp    %edx,%eax
f0101c70:	74 19                	je     f0101c8b <mem_init+0xcfd>
f0101c72:	68 2c 43 10 f0       	push   $0xf010432c
f0101c77:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101c7c:	68 4a 03 00 00       	push   $0x34a
f0101c81:	68 74 3b 10 f0       	push   $0xf0103b74
f0101c86:	e8 00 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101c8b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c90:	74 19                	je     f0101cab <mem_init+0xd1d>
f0101c92:	68 fa 3c 10 f0       	push   $0xf0103cfa
f0101c97:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101c9c:	68 4b 03 00 00       	push   $0x34b
f0101ca1:	68 74 3b 10 f0       	push   $0xf0103b74
f0101ca6:	e8 e0 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cab:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cb0:	74 19                	je     f0101ccb <mem_init+0xd3d>
f0101cb2:	68 54 3d 10 f0       	push   $0xf0103d54
f0101cb7:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101cbc:	68 4c 03 00 00       	push   $0x34c
f0101cc1:	68 74 3b 10 f0       	push   $0xf0103b74
f0101cc6:	e8 c0 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101ccb:	6a 00                	push   $0x0
f0101ccd:	68 00 10 00 00       	push   $0x1000
f0101cd2:	53                   	push   %ebx
f0101cd3:	57                   	push   %edi
f0101cd4:	e8 4f f2 ff ff       	call   f0100f28 <page_insert>
f0101cd9:	83 c4 10             	add    $0x10,%esp
f0101cdc:	85 c0                	test   %eax,%eax
f0101cde:	74 19                	je     f0101cf9 <mem_init+0xd6b>
f0101ce0:	68 a4 43 10 f0       	push   $0xf01043a4
f0101ce5:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101cea:	68 4f 03 00 00       	push   $0x34f
f0101cef:	68 74 3b 10 f0       	push   $0xf0103b74
f0101cf4:	e8 92 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101cf9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cfe:	75 19                	jne    f0101d19 <mem_init+0xd8b>
f0101d00:	68 65 3d 10 f0       	push   $0xf0103d65
f0101d05:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101d0a:	68 50 03 00 00       	push   $0x350
f0101d0f:	68 74 3b 10 f0       	push   $0xf0103b74
f0101d14:	e8 72 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d19:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d1c:	74 19                	je     f0101d37 <mem_init+0xda9>
f0101d1e:	68 71 3d 10 f0       	push   $0xf0103d71
f0101d23:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101d28:	68 51 03 00 00       	push   $0x351
f0101d2d:	68 74 3b 10 f0       	push   $0xf0103b74
f0101d32:	e8 54 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101d37:	83 ec 08             	sub    $0x8,%esp
f0101d3a:	68 00 10 00 00       	push   $0x1000
f0101d3f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101d45:	e8 9c f1 ff ff       	call   f0100ee6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d4a:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101d50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d55:	89 f8                	mov    %edi,%eax
f0101d57:	e8 fa eb ff ff       	call   f0100956 <check_va2pa>
f0101d5c:	83 c4 10             	add    $0x10,%esp
f0101d5f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d62:	74 19                	je     f0101d7d <mem_init+0xdef>
f0101d64:	68 80 43 10 f0       	push   $0xf0104380
f0101d69:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101d6e:	68 55 03 00 00       	push   $0x355
f0101d73:	68 74 3b 10 f0       	push   $0xf0103b74
f0101d78:	e8 0e e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d7d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d82:	89 f8                	mov    %edi,%eax
f0101d84:	e8 cd eb ff ff       	call   f0100956 <check_va2pa>
f0101d89:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d8c:	74 19                	je     f0101da7 <mem_init+0xe19>
f0101d8e:	68 dc 43 10 f0       	push   $0xf01043dc
f0101d93:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101d98:	68 56 03 00 00       	push   $0x356
f0101d9d:	68 74 3b 10 f0       	push   $0xf0103b74
f0101da2:	e8 e4 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101da7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dac:	74 19                	je     f0101dc7 <mem_init+0xe39>
f0101dae:	68 86 3d 10 f0       	push   $0xf0103d86
f0101db3:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101db8:	68 57 03 00 00       	push   $0x357
f0101dbd:	68 74 3b 10 f0       	push   $0xf0103b74
f0101dc2:	e8 c4 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101dc7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dcc:	74 19                	je     f0101de7 <mem_init+0xe59>
f0101dce:	68 54 3d 10 f0       	push   $0xf0103d54
f0101dd3:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101dd8:	68 58 03 00 00       	push   $0x358
f0101ddd:	68 74 3b 10 f0       	push   $0xf0103b74
f0101de2:	e8 a4 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101de7:	83 ec 0c             	sub    $0xc,%esp
f0101dea:	6a 00                	push   $0x0
f0101dec:	e8 35 ef ff ff       	call   f0100d26 <page_alloc>
f0101df1:	83 c4 10             	add    $0x10,%esp
f0101df4:	39 c3                	cmp    %eax,%ebx
f0101df6:	75 04                	jne    f0101dfc <mem_init+0xe6e>
f0101df8:	85 c0                	test   %eax,%eax
f0101dfa:	75 19                	jne    f0101e15 <mem_init+0xe87>
f0101dfc:	68 04 44 10 f0       	push   $0xf0104404
f0101e01:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101e06:	68 5b 03 00 00       	push   $0x35b
f0101e0b:	68 74 3b 10 f0       	push   $0xf0103b74
f0101e10:	e8 76 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e15:	83 ec 0c             	sub    $0xc,%esp
f0101e18:	6a 00                	push   $0x0
f0101e1a:	e8 07 ef ff ff       	call   f0100d26 <page_alloc>
f0101e1f:	83 c4 10             	add    $0x10,%esp
f0101e22:	85 c0                	test   %eax,%eax
f0101e24:	74 19                	je     f0101e3f <mem_init+0xeb1>
f0101e26:	68 a8 3c 10 f0       	push   $0xf0103ca8
f0101e2b:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101e30:	68 5e 03 00 00       	push   $0x35e
f0101e35:	68 74 3b 10 f0       	push   $0xf0103b74
f0101e3a:	e8 4c e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e3f:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101e45:	8b 11                	mov    (%ecx),%edx
f0101e47:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e50:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101e56:	c1 f8 03             	sar    $0x3,%eax
f0101e59:	c1 e0 0c             	shl    $0xc,%eax
f0101e5c:	39 c2                	cmp    %eax,%edx
f0101e5e:	74 19                	je     f0101e79 <mem_init+0xeeb>
f0101e60:	68 a4 40 10 f0       	push   $0xf01040a4
f0101e65:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101e6a:	68 61 03 00 00       	push   $0x361
f0101e6f:	68 74 3b 10 f0       	push   $0xf0103b74
f0101e74:	e8 12 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101e79:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e82:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e87:	74 19                	je     f0101ea2 <mem_init+0xf14>
f0101e89:	68 0b 3d 10 f0       	push   $0xf0103d0b
f0101e8e:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101e93:	68 63 03 00 00       	push   $0x363
f0101e98:	68 74 3b 10 f0       	push   $0xf0103b74
f0101e9d:	e8 e9 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101ea2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101eab:	83 ec 0c             	sub    $0xc,%esp
f0101eae:	50                   	push   %eax
f0101eaf:	e8 e2 ee ff ff       	call   f0100d96 <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101eb4:	83 c4 0c             	add    $0xc,%esp
f0101eb7:	6a 01                	push   $0x1
f0101eb9:	68 00 10 40 00       	push   $0x401000
f0101ebe:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ec4:	e8 2f ef ff ff       	call   f0100df8 <pgdir_walk>
f0101ec9:	89 c7                	mov    %eax,%edi
f0101ecb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101ece:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101ed3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ed6:	8b 40 04             	mov    0x4(%eax),%eax
f0101ed9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ede:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101ee4:	89 c2                	mov    %eax,%edx
f0101ee6:	c1 ea 0c             	shr    $0xc,%edx
f0101ee9:	83 c4 10             	add    $0x10,%esp
f0101eec:	39 ca                	cmp    %ecx,%edx
f0101eee:	72 15                	jb     f0101f05 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ef0:	50                   	push   %eax
f0101ef1:	68 10 3e 10 f0       	push   $0xf0103e10
f0101ef6:	68 6a 03 00 00       	push   $0x36a
f0101efb:	68 74 3b 10 f0       	push   $0xf0103b74
f0101f00:	e8 86 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f05:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f0a:	39 c7                	cmp    %eax,%edi
f0101f0c:	74 19                	je     f0101f27 <mem_init+0xf99>
f0101f0e:	68 97 3d 10 f0       	push   $0xf0103d97
f0101f13:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101f18:	68 6b 03 00 00       	push   $0x36b
f0101f1d:	68 74 3b 10 f0       	push   $0xf0103b74
f0101f22:	e8 64 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f27:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f2a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f34:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101f3a:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101f40:	c1 f8 03             	sar    $0x3,%eax
f0101f43:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f46:	89 c2                	mov    %eax,%edx
f0101f48:	c1 ea 0c             	shr    $0xc,%edx
f0101f4b:	39 d1                	cmp    %edx,%ecx
f0101f4d:	77 12                	ja     f0101f61 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f4f:	50                   	push   %eax
f0101f50:	68 10 3e 10 f0       	push   $0xf0103e10
f0101f55:	6a 57                	push   $0x57
f0101f57:	68 80 3b 10 f0       	push   $0xf0103b80
f0101f5c:	e8 2a e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f61:	83 ec 04             	sub    $0x4,%esp
f0101f64:	68 00 10 00 00       	push   $0x1000
f0101f69:	68 ff 00 00 00       	push   $0xff
f0101f6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f73:	50                   	push   %eax
f0101f74:	e8 fd 11 00 00       	call   f0103176 <memset>
	page_free(pp0);
f0101f79:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f7c:	89 3c 24             	mov    %edi,(%esp)
f0101f7f:	e8 12 ee ff ff       	call   f0100d96 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f84:	83 c4 0c             	add    $0xc,%esp
f0101f87:	6a 01                	push   $0x1
f0101f89:	6a 00                	push   $0x0
f0101f8b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f91:	e8 62 ee ff ff       	call   f0100df8 <pgdir_walk>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101f96:	89 fa                	mov    %edi,%edx
f0101f98:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101f9e:	c1 fa 03             	sar    $0x3,%edx
f0101fa1:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fa4:	89 d0                	mov    %edx,%eax
f0101fa6:	c1 e8 0c             	shr    $0xc,%eax
f0101fa9:	83 c4 10             	add    $0x10,%esp
f0101fac:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0101fb2:	72 12                	jb     f0101fc6 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fb4:	52                   	push   %edx
f0101fb5:	68 10 3e 10 f0       	push   $0xf0103e10
f0101fba:	6a 57                	push   $0x57
f0101fbc:	68 80 3b 10 f0       	push   $0xf0103b80
f0101fc1:	e8 c5 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101fc6:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f0101fcc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fcf:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fd5:	f6 00 01             	testb  $0x1,(%eax)
f0101fd8:	74 19                	je     f0101ff3 <mem_init+0x1065>
f0101fda:	68 af 3d 10 f0       	push   $0xf0103daf
f0101fdf:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0101fe4:	68 75 03 00 00       	push   $0x375
f0101fe9:	68 74 3b 10 f0       	push   $0xf0103b74
f0101fee:	e8 98 e0 ff ff       	call   f010008b <_panic>
f0101ff3:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f0101ff6:	39 d0                	cmp    %edx,%eax
f0101ff8:	75 db                	jne    f0101fd5 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101ffa:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101fff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102005:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102008:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010200e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102011:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102017:	83 ec 0c             	sub    $0xc,%esp
f010201a:	50                   	push   %eax
f010201b:	e8 76 ed ff ff       	call   f0100d96 <page_free>
	page_free(pp1);
f0102020:	89 1c 24             	mov    %ebx,(%esp)
f0102023:	e8 6e ed ff ff       	call   f0100d96 <page_free>
	page_free(pp2);
f0102028:	89 34 24             	mov    %esi,(%esp)
f010202b:	e8 66 ed ff ff       	call   f0100d96 <page_free>

	cprintf("check_page() succeeded!\n");
f0102030:	c7 04 24 c6 3d 10 f0 	movl   $0xf0103dc6,(%esp)
f0102037:	e8 d1 05 00 00       	call   f010260d <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010203c:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f0102042:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102047:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010204a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102051:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102056:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102059:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010205f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102062:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102065:	bb 00 00 00 00       	mov    $0x0,%ebx
f010206a:	eb 55                	jmp    f01020c1 <mem_init+0x1133>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010206c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102072:	89 f0                	mov    %esi,%eax
f0102074:	e8 dd e8 ff ff       	call   f0100956 <check_va2pa>
f0102079:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102080:	77 15                	ja     f0102097 <mem_init+0x1109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102082:	57                   	push   %edi
f0102083:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0102088:	68 b5 02 00 00       	push   $0x2b5
f010208d:	68 74 3b 10 f0       	push   $0xf0103b74
f0102092:	e8 f4 df ff ff       	call   f010008b <_panic>
f0102097:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010209e:	39 d0                	cmp    %edx,%eax
f01020a0:	74 19                	je     f01020bb <mem_init+0x112d>
f01020a2:	68 28 44 10 f0       	push   $0xf0104428
f01020a7:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01020ac:	68 b5 02 00 00       	push   $0x2b5
f01020b1:	68 74 3b 10 f0       	push   $0xf0103b74
f01020b6:	e8 d0 df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020bb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01020c1:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01020c4:	77 a6                	ja     f010206c <mem_init+0x10de>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01020c6:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01020c9:	c1 e7 0c             	shl    $0xc,%edi
f01020cc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020d1:	eb 30                	jmp    f0102103 <mem_init+0x1175>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01020d3:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01020d9:	89 f0                	mov    %esi,%eax
f01020db:	e8 76 e8 ff ff       	call   f0100956 <check_va2pa>
f01020e0:	39 c3                	cmp    %eax,%ebx
f01020e2:	74 19                	je     f01020fd <mem_init+0x116f>
f01020e4:	68 5c 44 10 f0       	push   $0xf010445c
f01020e9:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01020ee:	68 b9 02 00 00       	push   $0x2b9
f01020f3:	68 74 3b 10 f0       	push   $0xf0103b74
f01020f8:	e8 8e df ff ff       	call   f010008b <_panic>
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01020fd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102103:	39 fb                	cmp    %edi,%ebx
f0102105:	72 cc                	jb     f01020d3 <mem_init+0x1145>
f0102107:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210c:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102111:	89 da                	mov    %ebx,%edx
f0102113:	89 f0                	mov    %esi,%eax
f0102115:	e8 3c e8 ff ff       	call   f0100956 <check_va2pa>
f010211a:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102120:	77 19                	ja     f010213b <mem_init+0x11ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102122:	68 00 c0 10 f0       	push   $0xf010c000
f0102127:	68 f0 3e 10 f0       	push   $0xf0103ef0
f010212c:	68 bd 02 00 00       	push   $0x2bd
f0102131:	68 74 3b 10 f0       	push   $0xf0103b74
f0102136:	e8 50 df ff ff       	call   f010008b <_panic>
f010213b:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102141:	39 d0                	cmp    %edx,%eax
f0102143:	74 19                	je     f010215e <mem_init+0x11d0>
f0102145:	68 84 44 10 f0       	push   $0xf0104484
f010214a:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010214f:	68 bd 02 00 00       	push   $0x2bd
f0102154:	68 74 3b 10 f0       	push   $0xf0103b74
f0102159:	e8 2d df ff ff       	call   f010008b <_panic>
f010215e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102164:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f010216a:	75 a5                	jne    f0102111 <mem_init+0x1183>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010216c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102171:	89 f0                	mov    %esi,%eax
f0102173:	e8 de e7 ff ff       	call   f0100956 <check_va2pa>
f0102178:	83 f8 ff             	cmp    $0xffffffff,%eax
f010217b:	74 51                	je     f01021ce <mem_init+0x1240>
f010217d:	68 cc 44 10 f0       	push   $0xf01044cc
f0102182:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102187:	68 be 02 00 00       	push   $0x2be
f010218c:	68 74 3b 10 f0       	push   $0xf0103b74
f0102191:	e8 f5 de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f0102196:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010219b:	72 36                	jb     f01021d3 <mem_init+0x1245>
f010219d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01021a2:	76 07                	jbe    f01021ab <mem_init+0x121d>
f01021a4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021a9:	75 28                	jne    f01021d3 <mem_init+0x1245>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01021ab:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01021af:	0f 85 83 00 00 00    	jne    f0102238 <mem_init+0x12aa>
f01021b5:	68 df 3d 10 f0       	push   $0xf0103ddf
f01021ba:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01021bf:	68 c8 02 00 00       	push   $0x2c8
f01021c4:	68 74 3b 10 f0       	push   $0xf0103b74
f01021c9:	e8 bd de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021ce:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE))
f01021d3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021d8:	76 3f                	jbe    f0102219 <mem_init+0x128b>
			{
				assert(pgdir[i] & PTE_P);
f01021da:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01021dd:	f6 c2 01             	test   $0x1,%dl
f01021e0:	75 19                	jne    f01021fb <mem_init+0x126d>
f01021e2:	68 df 3d 10 f0       	push   $0xf0103ddf
f01021e7:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01021ec:	68 cd 02 00 00       	push   $0x2cd
f01021f1:	68 74 3b 10 f0       	push   $0xf0103b74
f01021f6:	e8 90 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01021fb:	f6 c2 02             	test   $0x2,%dl
f01021fe:	75 38                	jne    f0102238 <mem_init+0x12aa>
f0102200:	68 f0 3d 10 f0       	push   $0xf0103df0
f0102205:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010220a:	68 ce 02 00 00       	push   $0x2ce
f010220f:	68 74 3b 10 f0       	push   $0xf0103b74
f0102214:	e8 72 de ff ff       	call   f010008b <_panic>
			}
			else
				assert(pgdir[i] == 0);
f0102219:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010221d:	74 19                	je     f0102238 <mem_init+0x12aa>
f010221f:	68 01 3e 10 f0       	push   $0xf0103e01
f0102224:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102229:	68 d1 02 00 00       	push   $0x2d1
f010222e:	68 74 3b 10 f0       	push   $0xf0103b74
f0102233:	e8 53 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102238:	83 c0 01             	add    $0x1,%eax
f010223b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102240:	0f 86 50 ff ff ff    	jbe    f0102196 <mem_init+0x1208>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102246:	83 ec 0c             	sub    $0xc,%esp
f0102249:	68 fc 44 10 f0       	push   $0xf01044fc
f010224e:	e8 ba 03 00 00       	call   f010260d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102253:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102258:	83 c4 10             	add    $0x10,%esp
f010225b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102260:	77 15                	ja     f0102277 <mem_init+0x12e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102262:	50                   	push   %eax
f0102263:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0102268:	68 d4 00 00 00       	push   $0xd4
f010226d:	68 74 3b 10 f0       	push   $0xf0103b74
f0102272:	e8 14 de ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102277:	05 00 00 00 10       	add    $0x10000000,%eax
f010227c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010227f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102284:	e8 31 e7 ff ff       	call   f01009ba <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102289:	0f 20 c0             	mov    %cr0,%eax
f010228c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010228f:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102294:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102297:	83 ec 0c             	sub    $0xc,%esp
f010229a:	6a 00                	push   $0x0
f010229c:	e8 85 ea ff ff       	call   f0100d26 <page_alloc>
f01022a1:	89 c3                	mov    %eax,%ebx
f01022a3:	83 c4 10             	add    $0x10,%esp
f01022a6:	85 c0                	test   %eax,%eax
f01022a8:	75 19                	jne    f01022c3 <mem_init+0x1335>
f01022aa:	68 54 3c 10 f0       	push   $0xf0103c54
f01022af:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01022b4:	68 90 03 00 00       	push   $0x390
f01022b9:	68 74 3b 10 f0       	push   $0xf0103b74
f01022be:	e8 c8 dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01022c3:	83 ec 0c             	sub    $0xc,%esp
f01022c6:	6a 00                	push   $0x0
f01022c8:	e8 59 ea ff ff       	call   f0100d26 <page_alloc>
f01022cd:	89 c7                	mov    %eax,%edi
f01022cf:	83 c4 10             	add    $0x10,%esp
f01022d2:	85 c0                	test   %eax,%eax
f01022d4:	75 19                	jne    f01022ef <mem_init+0x1361>
f01022d6:	68 6a 3c 10 f0       	push   $0xf0103c6a
f01022db:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01022e0:	68 91 03 00 00       	push   $0x391
f01022e5:	68 74 3b 10 f0       	push   $0xf0103b74
f01022ea:	e8 9c dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01022ef:	83 ec 0c             	sub    $0xc,%esp
f01022f2:	6a 00                	push   $0x0
f01022f4:	e8 2d ea ff ff       	call   f0100d26 <page_alloc>
f01022f9:	89 c6                	mov    %eax,%esi
f01022fb:	83 c4 10             	add    $0x10,%esp
f01022fe:	85 c0                	test   %eax,%eax
f0102300:	75 19                	jne    f010231b <mem_init+0x138d>
f0102302:	68 80 3c 10 f0       	push   $0xf0103c80
f0102307:	68 9a 3b 10 f0       	push   $0xf0103b9a
f010230c:	68 92 03 00 00       	push   $0x392
f0102311:	68 74 3b 10 f0       	push   $0xf0103b74
f0102316:	e8 70 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010231b:	83 ec 0c             	sub    $0xc,%esp
f010231e:	53                   	push   %ebx
f010231f:	e8 72 ea ff ff       	call   f0100d96 <page_free>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102324:	89 f8                	mov    %edi,%eax
f0102326:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010232c:	c1 f8 03             	sar    $0x3,%eax
f010232f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102332:	89 c2                	mov    %eax,%edx
f0102334:	c1 ea 0c             	shr    $0xc,%edx
f0102337:	83 c4 10             	add    $0x10,%esp
f010233a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102340:	72 12                	jb     f0102354 <mem_init+0x13c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102342:	50                   	push   %eax
f0102343:	68 10 3e 10 f0       	push   $0xf0103e10
f0102348:	6a 57                	push   $0x57
f010234a:	68 80 3b 10 f0       	push   $0xf0103b80
f010234f:	e8 37 dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102354:	83 ec 04             	sub    $0x4,%esp
f0102357:	68 00 10 00 00       	push   $0x1000
f010235c:	6a 01                	push   $0x1
f010235e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102363:	50                   	push   %eax
f0102364:	e8 0d 0e 00 00       	call   f0103176 <memset>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102369:	89 f0                	mov    %esi,%eax
f010236b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102371:	c1 f8 03             	sar    $0x3,%eax
f0102374:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102377:	89 c2                	mov    %eax,%edx
f0102379:	c1 ea 0c             	shr    $0xc,%edx
f010237c:	83 c4 10             	add    $0x10,%esp
f010237f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102385:	72 12                	jb     f0102399 <mem_init+0x140b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102387:	50                   	push   %eax
f0102388:	68 10 3e 10 f0       	push   $0xf0103e10
f010238d:	6a 57                	push   $0x57
f010238f:	68 80 3b 10 f0       	push   $0xf0103b80
f0102394:	e8 f2 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102399:	83 ec 04             	sub    $0x4,%esp
f010239c:	68 00 10 00 00       	push   $0x1000
f01023a1:	6a 02                	push   $0x2
f01023a3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023a8:	50                   	push   %eax
f01023a9:	e8 c8 0d 00 00       	call   f0103176 <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f01023ae:	6a 02                	push   $0x2
f01023b0:	68 00 10 00 00       	push   $0x1000
f01023b5:	57                   	push   %edi
f01023b6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01023bc:	e8 67 eb ff ff       	call   f0100f28 <page_insert>
	assert(pp1->pp_ref == 1);
f01023c1:	83 c4 20             	add    $0x20,%esp
f01023c4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023c9:	74 19                	je     f01023e4 <mem_init+0x1456>
f01023cb:	68 fa 3c 10 f0       	push   $0xf0103cfa
f01023d0:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01023d5:	68 97 03 00 00       	push   $0x397
f01023da:	68 74 3b 10 f0       	push   $0xf0103b74
f01023df:	e8 a7 dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01023e4:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01023eb:	01 01 01 
f01023ee:	74 19                	je     f0102409 <mem_init+0x147b>
f01023f0:	68 1c 45 10 f0       	push   $0xf010451c
f01023f5:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01023fa:	68 98 03 00 00       	push   $0x398
f01023ff:	68 74 3b 10 f0       	push   $0xf0103b74
f0102404:	e8 82 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102409:	6a 02                	push   $0x2
f010240b:	68 00 10 00 00       	push   $0x1000
f0102410:	56                   	push   %esi
f0102411:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102417:	e8 0c eb ff ff       	call   f0100f28 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010241c:	83 c4 10             	add    $0x10,%esp
f010241f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102426:	02 02 02 
f0102429:	74 19                	je     f0102444 <mem_init+0x14b6>
f010242b:	68 40 45 10 f0       	push   $0xf0104540
f0102430:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102435:	68 9a 03 00 00       	push   $0x39a
f010243a:	68 74 3b 10 f0       	push   $0xf0103b74
f010243f:	e8 47 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102444:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102449:	74 19                	je     f0102464 <mem_init+0x14d6>
f010244b:	68 1c 3d 10 f0       	push   $0xf0103d1c
f0102450:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102455:	68 9b 03 00 00       	push   $0x39b
f010245a:	68 74 3b 10 f0       	push   $0xf0103b74
f010245f:	e8 27 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102464:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102469:	74 19                	je     f0102484 <mem_init+0x14f6>
f010246b:	68 86 3d 10 f0       	push   $0xf0103d86
f0102470:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102475:	68 9c 03 00 00       	push   $0x39c
f010247a:	68 74 3b 10 f0       	push   $0xf0103b74
f010247f:	e8 07 dc ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102484:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010248b:	03 03 03 

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010248e:	89 f0                	mov    %esi,%eax
f0102490:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102496:	c1 f8 03             	sar    $0x3,%eax
f0102499:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010249c:	89 c2                	mov    %eax,%edx
f010249e:	c1 ea 0c             	shr    $0xc,%edx
f01024a1:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01024a7:	72 12                	jb     f01024bb <mem_init+0x152d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024a9:	50                   	push   %eax
f01024aa:	68 10 3e 10 f0       	push   $0xf0103e10
f01024af:	6a 57                	push   $0x57
f01024b1:	68 80 3b 10 f0       	push   $0xf0103b80
f01024b6:	e8 d0 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024bb:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01024c2:	03 03 03 
f01024c5:	74 19                	je     f01024e0 <mem_init+0x1552>
f01024c7:	68 64 45 10 f0       	push   $0xf0104564
f01024cc:	68 9a 3b 10 f0       	push   $0xf0103b9a
f01024d1:	68 9e 03 00 00       	push   $0x39e
f01024d6:	68 74 3b 10 f0       	push   $0xf0103b74
f01024db:	e8 ab db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f01024e0:	83 ec 08             	sub    $0x8,%esp
f01024e3:	68 00 10 00 00       	push   $0x1000
f01024e8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024ee:	e8 f3 e9 ff ff       	call   f0100ee6 <page_remove>
	assert(pp2->pp_ref == 0);
f01024f3:	83 c4 10             	add    $0x10,%esp
f01024f6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01024fb:	74 19                	je     f0102516 <mem_init+0x1588>
f01024fd:	68 54 3d 10 f0       	push   $0xf0103d54
f0102502:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102507:	68 a0 03 00 00       	push   $0x3a0
f010250c:	68 74 3b 10 f0       	push   $0xf0103b74
f0102511:	e8 75 db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102516:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f010251c:	8b 11                	mov    (%ecx),%edx
f010251e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102524:	89 d8                	mov    %ebx,%eax
f0102526:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010252c:	c1 f8 03             	sar    $0x3,%eax
f010252f:	c1 e0 0c             	shl    $0xc,%eax
f0102532:	39 c2                	cmp    %eax,%edx
f0102534:	74 19                	je     f010254f <mem_init+0x15c1>
f0102536:	68 a4 40 10 f0       	push   $0xf01040a4
f010253b:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102540:	68 a3 03 00 00       	push   $0x3a3
f0102545:	68 74 3b 10 f0       	push   $0xf0103b74
f010254a:	e8 3c db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010254f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102555:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010255a:	74 19                	je     f0102575 <mem_init+0x15e7>
f010255c:	68 0b 3d 10 f0       	push   $0xf0103d0b
f0102561:	68 9a 3b 10 f0       	push   $0xf0103b9a
f0102566:	68 a5 03 00 00       	push   $0x3a5
f010256b:	68 74 3b 10 f0       	push   $0xf0103b74
f0102570:	e8 16 db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102575:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010257b:	83 ec 0c             	sub    $0xc,%esp
f010257e:	53                   	push   %ebx
f010257f:	e8 12 e8 ff ff       	call   f0100d96 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102584:	c7 04 24 90 45 10 f0 	movl   $0xf0104590,(%esp)
f010258b:	e8 7d 00 00 00       	call   f010260d <cprintf>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102590:	83 c4 10             	add    $0x10,%esp
f0102593:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102596:	5b                   	pop    %ebx
f0102597:	5e                   	pop    %esi
f0102598:	5f                   	pop    %edi
f0102599:	5d                   	pop    %ebp
f010259a:	c3                   	ret    

f010259b <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f010259b:	55                   	push   %ebp
f010259c:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010259e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025a1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01025a4:	5d                   	pop    %ebp
f01025a5:	c3                   	ret    

f01025a6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01025a6:	55                   	push   %ebp
f01025a7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025a9:	ba 70 00 00 00       	mov    $0x70,%edx
f01025ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01025b1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01025b2:	ba 71 00 00 00       	mov    $0x71,%edx
f01025b7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01025b8:	0f b6 c0             	movzbl %al,%eax
}
f01025bb:	5d                   	pop    %ebp
f01025bc:	c3                   	ret    

f01025bd <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01025bd:	55                   	push   %ebp
f01025be:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025c0:	ba 70 00 00 00       	mov    $0x70,%edx
f01025c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01025c8:	ee                   	out    %al,(%dx)
f01025c9:	ba 71 00 00 00       	mov    $0x71,%edx
f01025ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025d1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01025d2:	5d                   	pop    %ebp
f01025d3:	c3                   	ret    

f01025d4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01025d4:	55                   	push   %ebp
f01025d5:	89 e5                	mov    %esp,%ebp
f01025d7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01025da:	ff 75 08             	pushl  0x8(%ebp)
f01025dd:	e8 10 e0 ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01025e2:	83 c4 10             	add    $0x10,%esp
f01025e5:	c9                   	leave  
f01025e6:	c3                   	ret    

f01025e7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01025e7:	55                   	push   %ebp
f01025e8:	89 e5                	mov    %esp,%ebp
f01025ea:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01025ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01025f4:	ff 75 0c             	pushl  0xc(%ebp)
f01025f7:	ff 75 08             	pushl  0x8(%ebp)
f01025fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01025fd:	50                   	push   %eax
f01025fe:	68 d4 25 10 f0       	push   $0xf01025d4
f0102603:	e8 21 04 00 00       	call   f0102a29 <vprintfmt>
	return cnt;
}
f0102608:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010260b:	c9                   	leave  
f010260c:	c3                   	ret    

f010260d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010260d:	55                   	push   %ebp
f010260e:	89 e5                	mov    %esp,%ebp
f0102610:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102613:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102616:	50                   	push   %eax
f0102617:	ff 75 08             	pushl  0x8(%ebp)
f010261a:	e8 c8 ff ff ff       	call   f01025e7 <vcprintf>
	va_end(ap);

	return cnt;
}
f010261f:	c9                   	leave  
f0102620:	c3                   	ret    

f0102621 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102621:	55                   	push   %ebp
f0102622:	89 e5                	mov    %esp,%ebp
f0102624:	57                   	push   %edi
f0102625:	56                   	push   %esi
f0102626:	53                   	push   %ebx
f0102627:	83 ec 14             	sub    $0x14,%esp
f010262a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010262d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102630:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102633:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102636:	8b 1a                	mov    (%edx),%ebx
f0102638:	8b 01                	mov    (%ecx),%eax
f010263a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010263d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102644:	eb 7f                	jmp    f01026c5 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102646:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102649:	01 d8                	add    %ebx,%eax
f010264b:	89 c6                	mov    %eax,%esi
f010264d:	c1 ee 1f             	shr    $0x1f,%esi
f0102650:	01 c6                	add    %eax,%esi
f0102652:	d1 fe                	sar    %esi
f0102654:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102657:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010265a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010265d:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010265f:	eb 03                	jmp    f0102664 <stab_binsearch+0x43>
			m--;
f0102661:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102664:	39 c3                	cmp    %eax,%ebx
f0102666:	7f 0d                	jg     f0102675 <stab_binsearch+0x54>
f0102668:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010266c:	83 ea 0c             	sub    $0xc,%edx
f010266f:	39 f9                	cmp    %edi,%ecx
f0102671:	75 ee                	jne    f0102661 <stab_binsearch+0x40>
f0102673:	eb 05                	jmp    f010267a <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102675:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102678:	eb 4b                	jmp    f01026c5 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010267a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010267d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102680:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102684:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102687:	76 11                	jbe    f010269a <stab_binsearch+0x79>
			*region_left = m;
f0102689:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010268c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010268e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102691:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102698:	eb 2b                	jmp    f01026c5 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010269a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010269d:	73 14                	jae    f01026b3 <stab_binsearch+0x92>
			*region_right = m - 1;
f010269f:	83 e8 01             	sub    $0x1,%eax
f01026a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026a5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026a8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026aa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026b1:	eb 12                	jmp    f01026c5 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01026b3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026b6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026b8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026bc:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026be:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01026c5:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01026c8:	0f 8e 78 ff ff ff    	jle    f0102646 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01026ce:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01026d2:	75 0f                	jne    f01026e3 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01026d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01026d7:	8b 00                	mov    (%eax),%eax
f01026d9:	83 e8 01             	sub    $0x1,%eax
f01026dc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026df:	89 06                	mov    %eax,(%esi)
f01026e1:	eb 2c                	jmp    f010270f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01026e6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01026e8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026eb:	8b 0e                	mov    (%esi),%ecx
f01026ed:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026f0:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01026f3:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026f6:	eb 03                	jmp    f01026fb <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01026f8:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026fb:	39 c8                	cmp    %ecx,%eax
f01026fd:	7e 0b                	jle    f010270a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01026ff:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102703:	83 ea 0c             	sub    $0xc,%edx
f0102706:	39 df                	cmp    %ebx,%edi
f0102708:	75 ee                	jne    f01026f8 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010270a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010270d:	89 06                	mov    %eax,(%esi)
	}
}
f010270f:	83 c4 14             	add    $0x14,%esp
f0102712:	5b                   	pop    %ebx
f0102713:	5e                   	pop    %esi
f0102714:	5f                   	pop    %edi
f0102715:	5d                   	pop    %ebp
f0102716:	c3                   	ret    

f0102717 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102717:	55                   	push   %ebp
f0102718:	89 e5                	mov    %esp,%ebp
f010271a:	57                   	push   %edi
f010271b:	56                   	push   %esi
f010271c:	53                   	push   %ebx
f010271d:	83 ec 3c             	sub    $0x3c,%esp
f0102720:	8b 75 08             	mov    0x8(%ebp),%esi
f0102723:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102726:	c7 03 bc 45 10 f0    	movl   $0xf01045bc,(%ebx)
	info->eip_line = 0;
f010272c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102733:	c7 43 08 bc 45 10 f0 	movl   $0xf01045bc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010273a:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102741:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102744:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010274b:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102751:	76 11                	jbe    f0102764 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102753:	b8 9c bd 10 f0       	mov    $0xf010bd9c,%eax
f0102758:	3d 31 a0 10 f0       	cmp    $0xf010a031,%eax
f010275d:	77 19                	ja     f0102778 <debuginfo_eip+0x61>
f010275f:	e9 ba 01 00 00       	jmp    f010291e <debuginfo_eip+0x207>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102764:	83 ec 04             	sub    $0x4,%esp
f0102767:	68 c6 45 10 f0       	push   $0xf01045c6
f010276c:	6a 7f                	push   $0x7f
f010276e:	68 d3 45 10 f0       	push   $0xf01045d3
f0102773:	e8 13 d9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102778:	80 3d 9b bd 10 f0 00 	cmpb   $0x0,0xf010bd9b
f010277f:	0f 85 a0 01 00 00    	jne    f0102925 <debuginfo_eip+0x20e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102785:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010278c:	b8 30 a0 10 f0       	mov    $0xf010a030,%eax
f0102791:	2d 10 48 10 f0       	sub    $0xf0104810,%eax
f0102796:	c1 f8 02             	sar    $0x2,%eax
f0102799:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010279f:	83 e8 01             	sub    $0x1,%eax
f01027a2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01027a5:	83 ec 08             	sub    $0x8,%esp
f01027a8:	56                   	push   %esi
f01027a9:	6a 64                	push   $0x64
f01027ab:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01027ae:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01027b1:	b8 10 48 10 f0       	mov    $0xf0104810,%eax
f01027b6:	e8 66 fe ff ff       	call   f0102621 <stab_binsearch>
	if (lfile == 0)
f01027bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027be:	83 c4 10             	add    $0x10,%esp
f01027c1:	85 c0                	test   %eax,%eax
f01027c3:	0f 84 63 01 00 00    	je     f010292c <debuginfo_eip+0x215>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01027c9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01027cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01027d2:	83 ec 08             	sub    $0x8,%esp
f01027d5:	56                   	push   %esi
f01027d6:	6a 24                	push   $0x24
f01027d8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01027db:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01027de:	b8 10 48 10 f0       	mov    $0xf0104810,%eax
f01027e3:	e8 39 fe ff ff       	call   f0102621 <stab_binsearch>

	if (lfun <= rfun) {
f01027e8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027eb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01027ee:	83 c4 10             	add    $0x10,%esp
f01027f1:	39 d0                	cmp    %edx,%eax
f01027f3:	7f 40                	jg     f0102835 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01027f5:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01027f8:	c1 e1 02             	shl    $0x2,%ecx
f01027fb:	8d b9 10 48 10 f0    	lea    -0xfefb7f0(%ecx),%edi
f0102801:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102804:	8b b9 10 48 10 f0    	mov    -0xfefb7f0(%ecx),%edi
f010280a:	b9 9c bd 10 f0       	mov    $0xf010bd9c,%ecx
f010280f:	81 e9 31 a0 10 f0    	sub    $0xf010a031,%ecx
f0102815:	39 cf                	cmp    %ecx,%edi
f0102817:	73 09                	jae    f0102822 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102819:	81 c7 31 a0 10 f0    	add    $0xf010a031,%edi
f010281f:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102822:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102825:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102828:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010282b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010282d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102830:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102833:	eb 0f                	jmp    f0102844 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102835:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102838:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010283b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010283e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102841:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102844:	83 ec 08             	sub    $0x8,%esp
f0102847:	6a 3a                	push   $0x3a
f0102849:	ff 73 08             	pushl  0x8(%ebx)
f010284c:	e8 09 09 00 00       	call   f010315a <strfind>
f0102851:	2b 43 08             	sub    0x8(%ebx),%eax
f0102854:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102857:	83 c4 08             	add    $0x8,%esp
f010285a:	56                   	push   %esi
f010285b:	6a 44                	push   $0x44
f010285d:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102860:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102863:	b8 10 48 10 f0       	mov    $0xf0104810,%eax
f0102868:	e8 b4 fd ff ff       	call   f0102621 <stab_binsearch>
    if(lline <= rline){
f010286d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102870:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102873:	83 c4 10             	add    $0x10,%esp
f0102876:	39 d0                	cmp    %edx,%eax
f0102878:	7f 10                	jg     f010288a <debuginfo_eip+0x173>
        info->eip_line = stabs[rline].n_desc;
f010287a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010287d:	0f b7 14 95 16 48 10 	movzwl -0xfefb7ea(,%edx,4),%edx
f0102884:	f0 
f0102885:	89 53 04             	mov    %edx,0x4(%ebx)
f0102888:	eb 07                	jmp    f0102891 <debuginfo_eip+0x17a>
    }
    else
        info->eip_line = -1;
f010288a:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102891:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102894:	89 c2                	mov    %eax,%edx
f0102896:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102899:	8d 04 85 10 48 10 f0 	lea    -0xfefb7f0(,%eax,4),%eax
f01028a0:	eb 06                	jmp    f01028a8 <debuginfo_eip+0x191>
f01028a2:	83 ea 01             	sub    $0x1,%edx
f01028a5:	83 e8 0c             	sub    $0xc,%eax
f01028a8:	39 d7                	cmp    %edx,%edi
f01028aa:	7f 34                	jg     f01028e0 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f01028ac:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01028b0:	80 f9 84             	cmp    $0x84,%cl
f01028b3:	74 0b                	je     f01028c0 <debuginfo_eip+0x1a9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01028b5:	80 f9 64             	cmp    $0x64,%cl
f01028b8:	75 e8                	jne    f01028a2 <debuginfo_eip+0x18b>
f01028ba:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01028be:	74 e2                	je     f01028a2 <debuginfo_eip+0x18b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01028c0:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01028c3:	8b 14 85 10 48 10 f0 	mov    -0xfefb7f0(,%eax,4),%edx
f01028ca:	b8 9c bd 10 f0       	mov    $0xf010bd9c,%eax
f01028cf:	2d 31 a0 10 f0       	sub    $0xf010a031,%eax
f01028d4:	39 c2                	cmp    %eax,%edx
f01028d6:	73 08                	jae    f01028e0 <debuginfo_eip+0x1c9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01028d8:	81 c2 31 a0 10 f0    	add    $0xf010a031,%edx
f01028de:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028e0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01028e3:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028e6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028eb:	39 f2                	cmp    %esi,%edx
f01028ed:	7d 49                	jge    f0102938 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
f01028ef:	83 c2 01             	add    $0x1,%edx
f01028f2:	89 d0                	mov    %edx,%eax
f01028f4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01028f7:	8d 14 95 10 48 10 f0 	lea    -0xfefb7f0(,%edx,4),%edx
f01028fe:	eb 04                	jmp    f0102904 <debuginfo_eip+0x1ed>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102900:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102904:	39 c6                	cmp    %eax,%esi
f0102906:	7e 2b                	jle    f0102933 <debuginfo_eip+0x21c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102908:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010290c:	83 c0 01             	add    $0x1,%eax
f010290f:	83 c2 0c             	add    $0xc,%edx
f0102912:	80 f9 a0             	cmp    $0xa0,%cl
f0102915:	74 e9                	je     f0102900 <debuginfo_eip+0x1e9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102917:	b8 00 00 00 00       	mov    $0x0,%eax
f010291c:	eb 1a                	jmp    f0102938 <debuginfo_eip+0x221>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010291e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102923:	eb 13                	jmp    f0102938 <debuginfo_eip+0x221>
f0102925:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010292a:	eb 0c                	jmp    f0102938 <debuginfo_eip+0x221>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010292c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102931:	eb 05                	jmp    f0102938 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102933:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102938:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010293b:	5b                   	pop    %ebx
f010293c:	5e                   	pop    %esi
f010293d:	5f                   	pop    %edi
f010293e:	5d                   	pop    %ebp
f010293f:	c3                   	ret    

f0102940 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102940:	55                   	push   %ebp
f0102941:	89 e5                	mov    %esp,%ebp
f0102943:	57                   	push   %edi
f0102944:	56                   	push   %esi
f0102945:	53                   	push   %ebx
f0102946:	83 ec 1c             	sub    $0x1c,%esp
f0102949:	89 c7                	mov    %eax,%edi
f010294b:	89 d6                	mov    %edx,%esi
f010294d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102950:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102953:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102956:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102959:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010295c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102961:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102964:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102967:	39 d3                	cmp    %edx,%ebx
f0102969:	72 05                	jb     f0102970 <printnum+0x30>
f010296b:	39 45 10             	cmp    %eax,0x10(%ebp)
f010296e:	77 45                	ja     f01029b5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102970:	83 ec 0c             	sub    $0xc,%esp
f0102973:	ff 75 18             	pushl  0x18(%ebp)
f0102976:	8b 45 14             	mov    0x14(%ebp),%eax
f0102979:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010297c:	53                   	push   %ebx
f010297d:	ff 75 10             	pushl  0x10(%ebp)
f0102980:	83 ec 08             	sub    $0x8,%esp
f0102983:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102986:	ff 75 e0             	pushl  -0x20(%ebp)
f0102989:	ff 75 dc             	pushl  -0x24(%ebp)
f010298c:	ff 75 d8             	pushl  -0x28(%ebp)
f010298f:	e8 ec 09 00 00       	call   f0103380 <__udivdi3>
f0102994:	83 c4 18             	add    $0x18,%esp
f0102997:	52                   	push   %edx
f0102998:	50                   	push   %eax
f0102999:	89 f2                	mov    %esi,%edx
f010299b:	89 f8                	mov    %edi,%eax
f010299d:	e8 9e ff ff ff       	call   f0102940 <printnum>
f01029a2:	83 c4 20             	add    $0x20,%esp
f01029a5:	eb 18                	jmp    f01029bf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01029a7:	83 ec 08             	sub    $0x8,%esp
f01029aa:	56                   	push   %esi
f01029ab:	ff 75 18             	pushl  0x18(%ebp)
f01029ae:	ff d7                	call   *%edi
f01029b0:	83 c4 10             	add    $0x10,%esp
f01029b3:	eb 03                	jmp    f01029b8 <printnum+0x78>
f01029b5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01029b8:	83 eb 01             	sub    $0x1,%ebx
f01029bb:	85 db                	test   %ebx,%ebx
f01029bd:	7f e8                	jg     f01029a7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01029bf:	83 ec 08             	sub    $0x8,%esp
f01029c2:	56                   	push   %esi
f01029c3:	83 ec 04             	sub    $0x4,%esp
f01029c6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029c9:	ff 75 e0             	pushl  -0x20(%ebp)
f01029cc:	ff 75 dc             	pushl  -0x24(%ebp)
f01029cf:	ff 75 d8             	pushl  -0x28(%ebp)
f01029d2:	e8 d9 0a 00 00       	call   f01034b0 <__umoddi3>
f01029d7:	83 c4 14             	add    $0x14,%esp
f01029da:	0f be 80 e1 45 10 f0 	movsbl -0xfefba1f(%eax),%eax
f01029e1:	50                   	push   %eax
f01029e2:	ff d7                	call   *%edi
}
f01029e4:	83 c4 10             	add    $0x10,%esp
f01029e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029ea:	5b                   	pop    %ebx
f01029eb:	5e                   	pop    %esi
f01029ec:	5f                   	pop    %edi
f01029ed:	5d                   	pop    %ebp
f01029ee:	c3                   	ret    

f01029ef <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01029ef:	55                   	push   %ebp
f01029f0:	89 e5                	mov    %esp,%ebp
f01029f2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01029f5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01029f9:	8b 10                	mov    (%eax),%edx
f01029fb:	3b 50 04             	cmp    0x4(%eax),%edx
f01029fe:	73 0a                	jae    f0102a0a <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a00:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a03:	89 08                	mov    %ecx,(%eax)
f0102a05:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a08:	88 02                	mov    %al,(%edx)
}
f0102a0a:	5d                   	pop    %ebp
f0102a0b:	c3                   	ret    

f0102a0c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a0c:	55                   	push   %ebp
f0102a0d:	89 e5                	mov    %esp,%ebp
f0102a0f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102a12:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102a15:	50                   	push   %eax
f0102a16:	ff 75 10             	pushl  0x10(%ebp)
f0102a19:	ff 75 0c             	pushl  0xc(%ebp)
f0102a1c:	ff 75 08             	pushl  0x8(%ebp)
f0102a1f:	e8 05 00 00 00       	call   f0102a29 <vprintfmt>
	va_end(ap);
}
f0102a24:	83 c4 10             	add    $0x10,%esp
f0102a27:	c9                   	leave  
f0102a28:	c3                   	ret    

f0102a29 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a29:	55                   	push   %ebp
f0102a2a:	89 e5                	mov    %esp,%ebp
f0102a2c:	57                   	push   %edi
f0102a2d:	56                   	push   %esi
f0102a2e:	53                   	push   %ebx
f0102a2f:	83 ec 2c             	sub    $0x2c,%esp
f0102a32:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a35:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a38:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102a3b:	eb 12                	jmp    f0102a4f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0102a3d:	85 c0                	test   %eax,%eax
f0102a3f:	0f 84 6a 04 00 00    	je     f0102eaf <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0102a45:	83 ec 08             	sub    $0x8,%esp
f0102a48:	53                   	push   %ebx
f0102a49:	50                   	push   %eax
f0102a4a:	ff d6                	call   *%esi
f0102a4c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0102a4f:	83 c7 01             	add    $0x1,%edi
f0102a52:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102a56:	83 f8 25             	cmp    $0x25,%eax
f0102a59:	75 e2                	jne    f0102a3d <vprintfmt+0x14>
f0102a5b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102a5f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102a66:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102a6d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102a74:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102a79:	eb 07                	jmp    f0102a82 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102a7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f0102a7e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102a82:	8d 47 01             	lea    0x1(%edi),%eax
f0102a85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a88:	0f b6 07             	movzbl (%edi),%eax
f0102a8b:	0f b6 d0             	movzbl %al,%edx
f0102a8e:	83 e8 23             	sub    $0x23,%eax
f0102a91:	3c 55                	cmp    $0x55,%al
f0102a93:	0f 87 fb 03 00 00    	ja     f0102e94 <vprintfmt+0x46b>
f0102a99:	0f b6 c0             	movzbl %al,%eax
f0102a9c:	ff 24 85 80 46 10 f0 	jmp    *-0xfefb980(,%eax,4)
f0102aa3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f0102aa6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102aaa:	eb d6                	jmp    f0102a82 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102aac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102aaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ab4:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0102ab7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102aba:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102abe:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102ac1:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102ac4:	83 f9 09             	cmp    $0x9,%ecx
f0102ac7:	77 3f                	ja     f0102b08 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0102ac9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102acc:	eb e9                	jmp    f0102ab7 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f0102ace:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ad1:	8b 00                	mov    (%eax),%eax
f0102ad3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102ad6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ad9:	8d 40 04             	lea    0x4(%eax),%eax
f0102adc:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102adf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0102ae2:	eb 2a                	jmp    f0102b0e <vprintfmt+0xe5>
f0102ae4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ae7:	85 c0                	test   %eax,%eax
f0102ae9:	ba 00 00 00 00       	mov    $0x0,%edx
f0102aee:	0f 49 d0             	cmovns %eax,%edx
f0102af1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102af4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102af7:	eb 89                	jmp    f0102a82 <vprintfmt+0x59>
f0102af9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102afc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b03:	e9 7a ff ff ff       	jmp    f0102a82 <vprintfmt+0x59>
f0102b08:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102b0b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f0102b0e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b12:	0f 89 6a ff ff ff    	jns    f0102a82 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102b18:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b1e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b25:	e9 58 ff ff ff       	jmp    f0102a82 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f0102b2a:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f0102b30:	e9 4d ff ff ff       	jmp    f0102a82 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102b35:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b38:	8d 78 04             	lea    0x4(%eax),%edi
f0102b3b:	83 ec 08             	sub    $0x8,%esp
f0102b3e:	53                   	push   %ebx
f0102b3f:	ff 30                	pushl  (%eax)
f0102b41:	ff d6                	call   *%esi
			break;
f0102b43:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0102b46:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f0102b4c:	e9 fe fe ff ff       	jmp    f0102a4f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b51:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b54:	8d 78 04             	lea    0x4(%eax),%edi
f0102b57:	8b 00                	mov    (%eax),%eax
f0102b59:	99                   	cltd   
f0102b5a:	31 d0                	xor    %edx,%eax
f0102b5c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102b5e:	83 f8 07             	cmp    $0x7,%eax
f0102b61:	7f 0b                	jg     f0102b6e <vprintfmt+0x145>
f0102b63:	8b 14 85 e0 47 10 f0 	mov    -0xfefb820(,%eax,4),%edx
f0102b6a:	85 d2                	test   %edx,%edx
f0102b6c:	75 1b                	jne    f0102b89 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102b6e:	50                   	push   %eax
f0102b6f:	68 f9 45 10 f0       	push   $0xf01045f9
f0102b74:	53                   	push   %ebx
f0102b75:	56                   	push   %esi
f0102b76:	e8 91 fe ff ff       	call   f0102a0c <printfmt>
f0102b7b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b7e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102b84:	e9 c6 fe ff ff       	jmp    f0102a4f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102b89:	52                   	push   %edx
f0102b8a:	68 ac 3b 10 f0       	push   $0xf0103bac
f0102b8f:	53                   	push   %ebx
f0102b90:	56                   	push   %esi
f0102b91:	e8 76 fe ff ff       	call   f0102a0c <printfmt>
f0102b96:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b99:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102b9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b9f:	e9 ab fe ff ff       	jmp    f0102a4f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ba4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ba7:	83 c0 04             	add    $0x4,%eax
f0102baa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102bad:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bb0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102bb2:	85 ff                	test   %edi,%edi
f0102bb4:	b8 f2 45 10 f0       	mov    $0xf01045f2,%eax
f0102bb9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102bbc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102bc0:	0f 8e 94 00 00 00    	jle    f0102c5a <vprintfmt+0x231>
f0102bc6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102bca:	0f 84 98 00 00 00    	je     f0102c68 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bd0:	83 ec 08             	sub    $0x8,%esp
f0102bd3:	ff 75 d0             	pushl  -0x30(%ebp)
f0102bd6:	57                   	push   %edi
f0102bd7:	e8 34 04 00 00       	call   f0103010 <strnlen>
f0102bdc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102bdf:	29 c1                	sub    %eax,%ecx
f0102be1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102be4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102be7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102beb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bee:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102bf1:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bf3:	eb 0f                	jmp    f0102c04 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102bf5:	83 ec 08             	sub    $0x8,%esp
f0102bf8:	53                   	push   %ebx
f0102bf9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bfc:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bfe:	83 ef 01             	sub    $0x1,%edi
f0102c01:	83 c4 10             	add    $0x10,%esp
f0102c04:	85 ff                	test   %edi,%edi
f0102c06:	7f ed                	jg     f0102bf5 <vprintfmt+0x1cc>
f0102c08:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c0b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102c0e:	85 c9                	test   %ecx,%ecx
f0102c10:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c15:	0f 49 c1             	cmovns %ecx,%eax
f0102c18:	29 c1                	sub    %eax,%ecx
f0102c1a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c1d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c20:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c23:	89 cb                	mov    %ecx,%ebx
f0102c25:	eb 4d                	jmp    f0102c74 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c27:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c2b:	74 1b                	je     f0102c48 <vprintfmt+0x21f>
f0102c2d:	0f be c0             	movsbl %al,%eax
f0102c30:	83 e8 20             	sub    $0x20,%eax
f0102c33:	83 f8 5e             	cmp    $0x5e,%eax
f0102c36:	76 10                	jbe    f0102c48 <vprintfmt+0x21f>
					putch('?', putdat);
f0102c38:	83 ec 08             	sub    $0x8,%esp
f0102c3b:	ff 75 0c             	pushl  0xc(%ebp)
f0102c3e:	6a 3f                	push   $0x3f
f0102c40:	ff 55 08             	call   *0x8(%ebp)
f0102c43:	83 c4 10             	add    $0x10,%esp
f0102c46:	eb 0d                	jmp    f0102c55 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102c48:	83 ec 08             	sub    $0x8,%esp
f0102c4b:	ff 75 0c             	pushl  0xc(%ebp)
f0102c4e:	52                   	push   %edx
f0102c4f:	ff 55 08             	call   *0x8(%ebp)
f0102c52:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c55:	83 eb 01             	sub    $0x1,%ebx
f0102c58:	eb 1a                	jmp    f0102c74 <vprintfmt+0x24b>
f0102c5a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c5d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c60:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c63:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c66:	eb 0c                	jmp    f0102c74 <vprintfmt+0x24b>
f0102c68:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c6b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c6e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c71:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c74:	83 c7 01             	add    $0x1,%edi
f0102c77:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c7b:	0f be d0             	movsbl %al,%edx
f0102c7e:	85 d2                	test   %edx,%edx
f0102c80:	74 23                	je     f0102ca5 <vprintfmt+0x27c>
f0102c82:	85 f6                	test   %esi,%esi
f0102c84:	78 a1                	js     f0102c27 <vprintfmt+0x1fe>
f0102c86:	83 ee 01             	sub    $0x1,%esi
f0102c89:	79 9c                	jns    f0102c27 <vprintfmt+0x1fe>
f0102c8b:	89 df                	mov    %ebx,%edi
f0102c8d:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c90:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c93:	eb 18                	jmp    f0102cad <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102c95:	83 ec 08             	sub    $0x8,%esp
f0102c98:	53                   	push   %ebx
f0102c99:	6a 20                	push   $0x20
f0102c9b:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102c9d:	83 ef 01             	sub    $0x1,%edi
f0102ca0:	83 c4 10             	add    $0x10,%esp
f0102ca3:	eb 08                	jmp    f0102cad <vprintfmt+0x284>
f0102ca5:	89 df                	mov    %ebx,%edi
f0102ca7:	8b 75 08             	mov    0x8(%ebp),%esi
f0102caa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cad:	85 ff                	test   %edi,%edi
f0102caf:	7f e4                	jg     f0102c95 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cb1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102cb4:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102cb7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cba:	e9 90 fd ff ff       	jmp    f0102a4f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102cbf:	83 f9 01             	cmp    $0x1,%ecx
f0102cc2:	7e 19                	jle    f0102cdd <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102cc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc7:	8b 50 04             	mov    0x4(%eax),%edx
f0102cca:	8b 00                	mov    (%eax),%eax
f0102ccc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ccf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102cd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd5:	8d 40 08             	lea    0x8(%eax),%eax
f0102cd8:	89 45 14             	mov    %eax,0x14(%ebp)
f0102cdb:	eb 38                	jmp    f0102d15 <vprintfmt+0x2ec>
	else if (lflag)
f0102cdd:	85 c9                	test   %ecx,%ecx
f0102cdf:	74 1b                	je     f0102cfc <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102ce1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ce4:	8b 00                	mov    (%eax),%eax
f0102ce6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ce9:	89 c1                	mov    %eax,%ecx
f0102ceb:	c1 f9 1f             	sar    $0x1f,%ecx
f0102cee:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102cf1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf4:	8d 40 04             	lea    0x4(%eax),%eax
f0102cf7:	89 45 14             	mov    %eax,0x14(%ebp)
f0102cfa:	eb 19                	jmp    f0102d15 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102cfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cff:	8b 00                	mov    (%eax),%eax
f0102d01:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d04:	89 c1                	mov    %eax,%ecx
f0102d06:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d09:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d0c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0f:	8d 40 04             	lea    0x4(%eax),%eax
f0102d12:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102d15:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d18:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d1b:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d20:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d24:	0f 89 36 01 00 00    	jns    f0102e60 <vprintfmt+0x437>
				putch('-', putdat);
f0102d2a:	83 ec 08             	sub    $0x8,%esp
f0102d2d:	53                   	push   %ebx
f0102d2e:	6a 2d                	push   $0x2d
f0102d30:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d32:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d35:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102d38:	f7 da                	neg    %edx
f0102d3a:	83 d1 00             	adc    $0x0,%ecx
f0102d3d:	f7 d9                	neg    %ecx
f0102d3f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d42:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d47:	e9 14 01 00 00       	jmp    f0102e60 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d4c:	83 f9 01             	cmp    $0x1,%ecx
f0102d4f:	7e 18                	jle    f0102d69 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102d51:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d54:	8b 10                	mov    (%eax),%edx
f0102d56:	8b 48 04             	mov    0x4(%eax),%ecx
f0102d59:	8d 40 08             	lea    0x8(%eax),%eax
f0102d5c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d5f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d64:	e9 f7 00 00 00       	jmp    f0102e60 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102d69:	85 c9                	test   %ecx,%ecx
f0102d6b:	74 1a                	je     f0102d87 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102d6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d70:	8b 10                	mov    (%eax),%edx
f0102d72:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d77:	8d 40 04             	lea    0x4(%eax),%eax
f0102d7a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d7d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d82:	e9 d9 00 00 00       	jmp    f0102e60 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102d87:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d8a:	8b 10                	mov    (%eax),%edx
f0102d8c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d91:	8d 40 04             	lea    0x4(%eax),%eax
f0102d94:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d97:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d9c:	e9 bf 00 00 00       	jmp    f0102e60 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102da1:	83 f9 01             	cmp    $0x1,%ecx
f0102da4:	7e 13                	jle    f0102db9 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f0102da6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da9:	8b 50 04             	mov    0x4(%eax),%edx
f0102dac:	8b 00                	mov    (%eax),%eax
f0102dae:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102db1:	8d 49 08             	lea    0x8(%ecx),%ecx
f0102db4:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102db7:	eb 28                	jmp    f0102de1 <vprintfmt+0x3b8>
	else if (lflag)
f0102db9:	85 c9                	test   %ecx,%ecx
f0102dbb:	74 13                	je     f0102dd0 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f0102dbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc0:	8b 10                	mov    (%eax),%edx
f0102dc2:	89 d0                	mov    %edx,%eax
f0102dc4:	99                   	cltd   
f0102dc5:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102dc8:	8d 49 04             	lea    0x4(%ecx),%ecx
f0102dcb:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102dce:	eb 11                	jmp    f0102de1 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f0102dd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd3:	8b 10                	mov    (%eax),%edx
f0102dd5:	89 d0                	mov    %edx,%eax
f0102dd7:	99                   	cltd   
f0102dd8:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0102ddb:	8d 49 04             	lea    0x4(%ecx),%ecx
f0102dde:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f0102de1:	89 d1                	mov    %edx,%ecx
f0102de3:	89 c2                	mov    %eax,%edx
			base = 8;
f0102de5:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102dea:	eb 74                	jmp    f0102e60 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f0102dec:	83 ec 08             	sub    $0x8,%esp
f0102def:	53                   	push   %ebx
f0102df0:	6a 30                	push   $0x30
f0102df2:	ff d6                	call   *%esi
			putch('x', putdat);
f0102df4:	83 c4 08             	add    $0x8,%esp
f0102df7:	53                   	push   %ebx
f0102df8:	6a 78                	push   $0x78
f0102dfa:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102dfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dff:	8b 10                	mov    (%eax),%edx
f0102e01:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e06:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e09:	8d 40 04             	lea    0x4(%eax),%eax
f0102e0c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102e0f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102e14:	eb 4a                	jmp    f0102e60 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e16:	83 f9 01             	cmp    $0x1,%ecx
f0102e19:	7e 15                	jle    f0102e30 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f0102e1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1e:	8b 10                	mov    (%eax),%edx
f0102e20:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e23:	8d 40 08             	lea    0x8(%eax),%eax
f0102e26:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e29:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e2e:	eb 30                	jmp    f0102e60 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e30:	85 c9                	test   %ecx,%ecx
f0102e32:	74 17                	je     f0102e4b <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f0102e34:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e37:	8b 10                	mov    (%eax),%edx
f0102e39:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e3e:	8d 40 04             	lea    0x4(%eax),%eax
f0102e41:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e44:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e49:	eb 15                	jmp    f0102e60 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e4e:	8b 10                	mov    (%eax),%edx
f0102e50:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e55:	8d 40 04             	lea    0x4(%eax),%eax
f0102e58:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e5b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e60:	83 ec 0c             	sub    $0xc,%esp
f0102e63:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e67:	57                   	push   %edi
f0102e68:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e6b:	50                   	push   %eax
f0102e6c:	51                   	push   %ecx
f0102e6d:	52                   	push   %edx
f0102e6e:	89 da                	mov    %ebx,%edx
f0102e70:	89 f0                	mov    %esi,%eax
f0102e72:	e8 c9 fa ff ff       	call   f0102940 <printnum>
			break;
f0102e77:	83 c4 20             	add    $0x20,%esp
f0102e7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e7d:	e9 cd fb ff ff       	jmp    f0102a4f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e82:	83 ec 08             	sub    $0x8,%esp
f0102e85:	53                   	push   %ebx
f0102e86:	52                   	push   %edx
f0102e87:	ff d6                	call   *%esi
			break;
f0102e89:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0102e8c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e8f:	e9 bb fb ff ff       	jmp    f0102a4f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e94:	83 ec 08             	sub    $0x8,%esp
f0102e97:	53                   	push   %ebx
f0102e98:	6a 25                	push   $0x25
f0102e9a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e9c:	83 c4 10             	add    $0x10,%esp
f0102e9f:	eb 03                	jmp    f0102ea4 <vprintfmt+0x47b>
f0102ea1:	83 ef 01             	sub    $0x1,%edi
f0102ea4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ea8:	75 f7                	jne    f0102ea1 <vprintfmt+0x478>
f0102eaa:	e9 a0 fb ff ff       	jmp    f0102a4f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102eaf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eb2:	5b                   	pop    %ebx
f0102eb3:	5e                   	pop    %esi
f0102eb4:	5f                   	pop    %edi
f0102eb5:	5d                   	pop    %ebp
f0102eb6:	c3                   	ret    

f0102eb7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102eb7:	55                   	push   %ebp
f0102eb8:	89 e5                	mov    %esp,%ebp
f0102eba:	83 ec 18             	sub    $0x18,%esp
f0102ebd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102ec3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102ec6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102eca:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102ecd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102ed4:	85 c0                	test   %eax,%eax
f0102ed6:	74 26                	je     f0102efe <vsnprintf+0x47>
f0102ed8:	85 d2                	test   %edx,%edx
f0102eda:	7e 22                	jle    f0102efe <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102edc:	ff 75 14             	pushl  0x14(%ebp)
f0102edf:	ff 75 10             	pushl  0x10(%ebp)
f0102ee2:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102ee5:	50                   	push   %eax
f0102ee6:	68 ef 29 10 f0       	push   $0xf01029ef
f0102eeb:	e8 39 fb ff ff       	call   f0102a29 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102ef0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102ef3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ef9:	83 c4 10             	add    $0x10,%esp
f0102efc:	eb 05                	jmp    f0102f03 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102efe:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f03:	c9                   	leave  
f0102f04:	c3                   	ret    

f0102f05 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f05:	55                   	push   %ebp
f0102f06:	89 e5                	mov    %esp,%ebp
f0102f08:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f0b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f0e:	50                   	push   %eax
f0102f0f:	ff 75 10             	pushl  0x10(%ebp)
f0102f12:	ff 75 0c             	pushl  0xc(%ebp)
f0102f15:	ff 75 08             	pushl  0x8(%ebp)
f0102f18:	e8 9a ff ff ff       	call   f0102eb7 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f1d:	c9                   	leave  
f0102f1e:	c3                   	ret    

f0102f1f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f1f:	55                   	push   %ebp
f0102f20:	89 e5                	mov    %esp,%ebp
f0102f22:	57                   	push   %edi
f0102f23:	56                   	push   %esi
f0102f24:	53                   	push   %ebx
f0102f25:	83 ec 0c             	sub    $0xc,%esp
f0102f28:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f2b:	85 c0                	test   %eax,%eax
f0102f2d:	74 11                	je     f0102f40 <readline+0x21>
		cprintf("%s", prompt);
f0102f2f:	83 ec 08             	sub    $0x8,%esp
f0102f32:	50                   	push   %eax
f0102f33:	68 ac 3b 10 f0       	push   $0xf0103bac
f0102f38:	e8 d0 f6 ff ff       	call   f010260d <cprintf>
f0102f3d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f40:	83 ec 0c             	sub    $0xc,%esp
f0102f43:	6a 00                	push   $0x0
f0102f45:	e8 c9 d6 ff ff       	call   f0100613 <iscons>
f0102f4a:	89 c7                	mov    %eax,%edi
f0102f4c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f4f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f54:	e8 a9 d6 ff ff       	call   f0100602 <getchar>
f0102f59:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f5b:	85 c0                	test   %eax,%eax
f0102f5d:	79 18                	jns    f0102f77 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f5f:	83 ec 08             	sub    $0x8,%esp
f0102f62:	50                   	push   %eax
f0102f63:	68 00 48 10 f0       	push   $0xf0104800
f0102f68:	e8 a0 f6 ff ff       	call   f010260d <cprintf>
			return NULL;
f0102f6d:	83 c4 10             	add    $0x10,%esp
f0102f70:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f75:	eb 79                	jmp    f0102ff0 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f77:	83 f8 08             	cmp    $0x8,%eax
f0102f7a:	0f 94 c2             	sete   %dl
f0102f7d:	83 f8 7f             	cmp    $0x7f,%eax
f0102f80:	0f 94 c0             	sete   %al
f0102f83:	08 c2                	or     %al,%dl
f0102f85:	74 1a                	je     f0102fa1 <readline+0x82>
f0102f87:	85 f6                	test   %esi,%esi
f0102f89:	7e 16                	jle    f0102fa1 <readline+0x82>
			if (echoing)
f0102f8b:	85 ff                	test   %edi,%edi
f0102f8d:	74 0d                	je     f0102f9c <readline+0x7d>
				cputchar('\b');
f0102f8f:	83 ec 0c             	sub    $0xc,%esp
f0102f92:	6a 08                	push   $0x8
f0102f94:	e8 59 d6 ff ff       	call   f01005f2 <cputchar>
f0102f99:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f9c:	83 ee 01             	sub    $0x1,%esi
f0102f9f:	eb b3                	jmp    f0102f54 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fa1:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fa4:	7e 23                	jle    f0102fc9 <readline+0xaa>
f0102fa6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102fac:	7f 1b                	jg     f0102fc9 <readline+0xaa>
			if (echoing)
f0102fae:	85 ff                	test   %edi,%edi
f0102fb0:	74 0c                	je     f0102fbe <readline+0x9f>
				cputchar(c);
f0102fb2:	83 ec 0c             	sub    $0xc,%esp
f0102fb5:	53                   	push   %ebx
f0102fb6:	e8 37 d6 ff ff       	call   f01005f2 <cputchar>
f0102fbb:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102fbe:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0102fc4:	8d 76 01             	lea    0x1(%esi),%esi
f0102fc7:	eb 8b                	jmp    f0102f54 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fc9:	83 fb 0a             	cmp    $0xa,%ebx
f0102fcc:	74 05                	je     f0102fd3 <readline+0xb4>
f0102fce:	83 fb 0d             	cmp    $0xd,%ebx
f0102fd1:	75 81                	jne    f0102f54 <readline+0x35>
			if (echoing)
f0102fd3:	85 ff                	test   %edi,%edi
f0102fd5:	74 0d                	je     f0102fe4 <readline+0xc5>
				cputchar('\n');
f0102fd7:	83 ec 0c             	sub    $0xc,%esp
f0102fda:	6a 0a                	push   $0xa
f0102fdc:	e8 11 d6 ff ff       	call   f01005f2 <cputchar>
f0102fe1:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102fe4:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0102feb:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0102ff0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ff3:	5b                   	pop    %ebx
f0102ff4:	5e                   	pop    %esi
f0102ff5:	5f                   	pop    %edi
f0102ff6:	5d                   	pop    %ebp
f0102ff7:	c3                   	ret    

f0102ff8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102ff8:	55                   	push   %ebp
f0102ff9:	89 e5                	mov    %esp,%ebp
f0102ffb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102ffe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103003:	eb 03                	jmp    f0103008 <strlen+0x10>
		n++;
f0103005:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103008:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010300c:	75 f7                	jne    f0103005 <strlen+0xd>
		n++;
	return n;
}
f010300e:	5d                   	pop    %ebp
f010300f:	c3                   	ret    

f0103010 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103010:	55                   	push   %ebp
f0103011:	89 e5                	mov    %esp,%ebp
f0103013:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103016:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103019:	ba 00 00 00 00       	mov    $0x0,%edx
f010301e:	eb 03                	jmp    f0103023 <strnlen+0x13>
		n++;
f0103020:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103023:	39 c2                	cmp    %eax,%edx
f0103025:	74 08                	je     f010302f <strnlen+0x1f>
f0103027:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010302b:	75 f3                	jne    f0103020 <strnlen+0x10>
f010302d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010302f:	5d                   	pop    %ebp
f0103030:	c3                   	ret    

f0103031 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103031:	55                   	push   %ebp
f0103032:	89 e5                	mov    %esp,%ebp
f0103034:	53                   	push   %ebx
f0103035:	8b 45 08             	mov    0x8(%ebp),%eax
f0103038:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010303b:	89 c2                	mov    %eax,%edx
f010303d:	83 c2 01             	add    $0x1,%edx
f0103040:	83 c1 01             	add    $0x1,%ecx
f0103043:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103047:	88 5a ff             	mov    %bl,-0x1(%edx)
f010304a:	84 db                	test   %bl,%bl
f010304c:	75 ef                	jne    f010303d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010304e:	5b                   	pop    %ebx
f010304f:	5d                   	pop    %ebp
f0103050:	c3                   	ret    

f0103051 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103051:	55                   	push   %ebp
f0103052:	89 e5                	mov    %esp,%ebp
f0103054:	53                   	push   %ebx
f0103055:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103058:	53                   	push   %ebx
f0103059:	e8 9a ff ff ff       	call   f0102ff8 <strlen>
f010305e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103061:	ff 75 0c             	pushl  0xc(%ebp)
f0103064:	01 d8                	add    %ebx,%eax
f0103066:	50                   	push   %eax
f0103067:	e8 c5 ff ff ff       	call   f0103031 <strcpy>
	return dst;
}
f010306c:	89 d8                	mov    %ebx,%eax
f010306e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103071:	c9                   	leave  
f0103072:	c3                   	ret    

f0103073 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103073:	55                   	push   %ebp
f0103074:	89 e5                	mov    %esp,%ebp
f0103076:	56                   	push   %esi
f0103077:	53                   	push   %ebx
f0103078:	8b 75 08             	mov    0x8(%ebp),%esi
f010307b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010307e:	89 f3                	mov    %esi,%ebx
f0103080:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103083:	89 f2                	mov    %esi,%edx
f0103085:	eb 0f                	jmp    f0103096 <strncpy+0x23>
		*dst++ = *src;
f0103087:	83 c2 01             	add    $0x1,%edx
f010308a:	0f b6 01             	movzbl (%ecx),%eax
f010308d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103090:	80 39 01             	cmpb   $0x1,(%ecx)
f0103093:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103096:	39 da                	cmp    %ebx,%edx
f0103098:	75 ed                	jne    f0103087 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010309a:	89 f0                	mov    %esi,%eax
f010309c:	5b                   	pop    %ebx
f010309d:	5e                   	pop    %esi
f010309e:	5d                   	pop    %ebp
f010309f:	c3                   	ret    

f01030a0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
f01030a3:	56                   	push   %esi
f01030a4:	53                   	push   %ebx
f01030a5:	8b 75 08             	mov    0x8(%ebp),%esi
f01030a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030ab:	8b 55 10             	mov    0x10(%ebp),%edx
f01030ae:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030b0:	85 d2                	test   %edx,%edx
f01030b2:	74 21                	je     f01030d5 <strlcpy+0x35>
f01030b4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030b8:	89 f2                	mov    %esi,%edx
f01030ba:	eb 09                	jmp    f01030c5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030bc:	83 c2 01             	add    $0x1,%edx
f01030bf:	83 c1 01             	add    $0x1,%ecx
f01030c2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030c5:	39 c2                	cmp    %eax,%edx
f01030c7:	74 09                	je     f01030d2 <strlcpy+0x32>
f01030c9:	0f b6 19             	movzbl (%ecx),%ebx
f01030cc:	84 db                	test   %bl,%bl
f01030ce:	75 ec                	jne    f01030bc <strlcpy+0x1c>
f01030d0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01030d2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01030d5:	29 f0                	sub    %esi,%eax
}
f01030d7:	5b                   	pop    %ebx
f01030d8:	5e                   	pop    %esi
f01030d9:	5d                   	pop    %ebp
f01030da:	c3                   	ret    

f01030db <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01030db:	55                   	push   %ebp
f01030dc:	89 e5                	mov    %esp,%ebp
f01030de:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030e1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01030e4:	eb 06                	jmp    f01030ec <strcmp+0x11>
		p++, q++;
f01030e6:	83 c1 01             	add    $0x1,%ecx
f01030e9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01030ec:	0f b6 01             	movzbl (%ecx),%eax
f01030ef:	84 c0                	test   %al,%al
f01030f1:	74 04                	je     f01030f7 <strcmp+0x1c>
f01030f3:	3a 02                	cmp    (%edx),%al
f01030f5:	74 ef                	je     f01030e6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01030f7:	0f b6 c0             	movzbl %al,%eax
f01030fa:	0f b6 12             	movzbl (%edx),%edx
f01030fd:	29 d0                	sub    %edx,%eax
}
f01030ff:	5d                   	pop    %ebp
f0103100:	c3                   	ret    

f0103101 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103101:	55                   	push   %ebp
f0103102:	89 e5                	mov    %esp,%ebp
f0103104:	53                   	push   %ebx
f0103105:	8b 45 08             	mov    0x8(%ebp),%eax
f0103108:	8b 55 0c             	mov    0xc(%ebp),%edx
f010310b:	89 c3                	mov    %eax,%ebx
f010310d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103110:	eb 06                	jmp    f0103118 <strncmp+0x17>
		n--, p++, q++;
f0103112:	83 c0 01             	add    $0x1,%eax
f0103115:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103118:	39 d8                	cmp    %ebx,%eax
f010311a:	74 15                	je     f0103131 <strncmp+0x30>
f010311c:	0f b6 08             	movzbl (%eax),%ecx
f010311f:	84 c9                	test   %cl,%cl
f0103121:	74 04                	je     f0103127 <strncmp+0x26>
f0103123:	3a 0a                	cmp    (%edx),%cl
f0103125:	74 eb                	je     f0103112 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103127:	0f b6 00             	movzbl (%eax),%eax
f010312a:	0f b6 12             	movzbl (%edx),%edx
f010312d:	29 d0                	sub    %edx,%eax
f010312f:	eb 05                	jmp    f0103136 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103131:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103136:	5b                   	pop    %ebx
f0103137:	5d                   	pop    %ebp
f0103138:	c3                   	ret    

f0103139 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103139:	55                   	push   %ebp
f010313a:	89 e5                	mov    %esp,%ebp
f010313c:	8b 45 08             	mov    0x8(%ebp),%eax
f010313f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103143:	eb 07                	jmp    f010314c <strchr+0x13>
		if (*s == c)
f0103145:	38 ca                	cmp    %cl,%dl
f0103147:	74 0f                	je     f0103158 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103149:	83 c0 01             	add    $0x1,%eax
f010314c:	0f b6 10             	movzbl (%eax),%edx
f010314f:	84 d2                	test   %dl,%dl
f0103151:	75 f2                	jne    f0103145 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103153:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103158:	5d                   	pop    %ebp
f0103159:	c3                   	ret    

f010315a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010315a:	55                   	push   %ebp
f010315b:	89 e5                	mov    %esp,%ebp
f010315d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103160:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103164:	eb 03                	jmp    f0103169 <strfind+0xf>
f0103166:	83 c0 01             	add    $0x1,%eax
f0103169:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010316c:	38 ca                	cmp    %cl,%dl
f010316e:	74 04                	je     f0103174 <strfind+0x1a>
f0103170:	84 d2                	test   %dl,%dl
f0103172:	75 f2                	jne    f0103166 <strfind+0xc>
			break;
	return (char *) s;
}
f0103174:	5d                   	pop    %ebp
f0103175:	c3                   	ret    

f0103176 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103176:	55                   	push   %ebp
f0103177:	89 e5                	mov    %esp,%ebp
f0103179:	57                   	push   %edi
f010317a:	56                   	push   %esi
f010317b:	53                   	push   %ebx
f010317c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010317f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103182:	85 c9                	test   %ecx,%ecx
f0103184:	74 36                	je     f01031bc <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103186:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010318c:	75 28                	jne    f01031b6 <memset+0x40>
f010318e:	f6 c1 03             	test   $0x3,%cl
f0103191:	75 23                	jne    f01031b6 <memset+0x40>
		c &= 0xFF;
f0103193:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103197:	89 d3                	mov    %edx,%ebx
f0103199:	c1 e3 08             	shl    $0x8,%ebx
f010319c:	89 d6                	mov    %edx,%esi
f010319e:	c1 e6 18             	shl    $0x18,%esi
f01031a1:	89 d0                	mov    %edx,%eax
f01031a3:	c1 e0 10             	shl    $0x10,%eax
f01031a6:	09 f0                	or     %esi,%eax
f01031a8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031aa:	89 d8                	mov    %ebx,%eax
f01031ac:	09 d0                	or     %edx,%eax
f01031ae:	c1 e9 02             	shr    $0x2,%ecx
f01031b1:	fc                   	cld    
f01031b2:	f3 ab                	rep stos %eax,%es:(%edi)
f01031b4:	eb 06                	jmp    f01031bc <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031b9:	fc                   	cld    
f01031ba:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031bc:	89 f8                	mov    %edi,%eax
f01031be:	5b                   	pop    %ebx
f01031bf:	5e                   	pop    %esi
f01031c0:	5f                   	pop    %edi
f01031c1:	5d                   	pop    %ebp
f01031c2:	c3                   	ret    

f01031c3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031c3:	55                   	push   %ebp
f01031c4:	89 e5                	mov    %esp,%ebp
f01031c6:	57                   	push   %edi
f01031c7:	56                   	push   %esi
f01031c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031cb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031ce:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01031d1:	39 c6                	cmp    %eax,%esi
f01031d3:	73 35                	jae    f010320a <memmove+0x47>
f01031d5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01031d8:	39 d0                	cmp    %edx,%eax
f01031da:	73 2e                	jae    f010320a <memmove+0x47>
		s += n;
		d += n;
f01031dc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031df:	89 d6                	mov    %edx,%esi
f01031e1:	09 fe                	or     %edi,%esi
f01031e3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01031e9:	75 13                	jne    f01031fe <memmove+0x3b>
f01031eb:	f6 c1 03             	test   $0x3,%cl
f01031ee:	75 0e                	jne    f01031fe <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01031f0:	83 ef 04             	sub    $0x4,%edi
f01031f3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01031f6:	c1 e9 02             	shr    $0x2,%ecx
f01031f9:	fd                   	std    
f01031fa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031fc:	eb 09                	jmp    f0103207 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01031fe:	83 ef 01             	sub    $0x1,%edi
f0103201:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103204:	fd                   	std    
f0103205:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103207:	fc                   	cld    
f0103208:	eb 1d                	jmp    f0103227 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010320a:	89 f2                	mov    %esi,%edx
f010320c:	09 c2                	or     %eax,%edx
f010320e:	f6 c2 03             	test   $0x3,%dl
f0103211:	75 0f                	jne    f0103222 <memmove+0x5f>
f0103213:	f6 c1 03             	test   $0x3,%cl
f0103216:	75 0a                	jne    f0103222 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103218:	c1 e9 02             	shr    $0x2,%ecx
f010321b:	89 c7                	mov    %eax,%edi
f010321d:	fc                   	cld    
f010321e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103220:	eb 05                	jmp    f0103227 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103222:	89 c7                	mov    %eax,%edi
f0103224:	fc                   	cld    
f0103225:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103227:	5e                   	pop    %esi
f0103228:	5f                   	pop    %edi
f0103229:	5d                   	pop    %ebp
f010322a:	c3                   	ret    

f010322b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010322b:	55                   	push   %ebp
f010322c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010322e:	ff 75 10             	pushl  0x10(%ebp)
f0103231:	ff 75 0c             	pushl  0xc(%ebp)
f0103234:	ff 75 08             	pushl  0x8(%ebp)
f0103237:	e8 87 ff ff ff       	call   f01031c3 <memmove>
}
f010323c:	c9                   	leave  
f010323d:	c3                   	ret    

f010323e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010323e:	55                   	push   %ebp
f010323f:	89 e5                	mov    %esp,%ebp
f0103241:	56                   	push   %esi
f0103242:	53                   	push   %ebx
f0103243:	8b 45 08             	mov    0x8(%ebp),%eax
f0103246:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103249:	89 c6                	mov    %eax,%esi
f010324b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010324e:	eb 1a                	jmp    f010326a <memcmp+0x2c>
		if (*s1 != *s2)
f0103250:	0f b6 08             	movzbl (%eax),%ecx
f0103253:	0f b6 1a             	movzbl (%edx),%ebx
f0103256:	38 d9                	cmp    %bl,%cl
f0103258:	74 0a                	je     f0103264 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010325a:	0f b6 c1             	movzbl %cl,%eax
f010325d:	0f b6 db             	movzbl %bl,%ebx
f0103260:	29 d8                	sub    %ebx,%eax
f0103262:	eb 0f                	jmp    f0103273 <memcmp+0x35>
		s1++, s2++;
f0103264:	83 c0 01             	add    $0x1,%eax
f0103267:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010326a:	39 f0                	cmp    %esi,%eax
f010326c:	75 e2                	jne    f0103250 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010326e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103273:	5b                   	pop    %ebx
f0103274:	5e                   	pop    %esi
f0103275:	5d                   	pop    %ebp
f0103276:	c3                   	ret    

f0103277 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103277:	55                   	push   %ebp
f0103278:	89 e5                	mov    %esp,%ebp
f010327a:	53                   	push   %ebx
f010327b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010327e:	89 c1                	mov    %eax,%ecx
f0103280:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103283:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103287:	eb 0a                	jmp    f0103293 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103289:	0f b6 10             	movzbl (%eax),%edx
f010328c:	39 da                	cmp    %ebx,%edx
f010328e:	74 07                	je     f0103297 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103290:	83 c0 01             	add    $0x1,%eax
f0103293:	39 c8                	cmp    %ecx,%eax
f0103295:	72 f2                	jb     f0103289 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103297:	5b                   	pop    %ebx
f0103298:	5d                   	pop    %ebp
f0103299:	c3                   	ret    

f010329a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010329a:	55                   	push   %ebp
f010329b:	89 e5                	mov    %esp,%ebp
f010329d:	57                   	push   %edi
f010329e:	56                   	push   %esi
f010329f:	53                   	push   %ebx
f01032a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032a3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032a6:	eb 03                	jmp    f01032ab <strtol+0x11>
		s++;
f01032a8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032ab:	0f b6 01             	movzbl (%ecx),%eax
f01032ae:	3c 20                	cmp    $0x20,%al
f01032b0:	74 f6                	je     f01032a8 <strtol+0xe>
f01032b2:	3c 09                	cmp    $0x9,%al
f01032b4:	74 f2                	je     f01032a8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032b6:	3c 2b                	cmp    $0x2b,%al
f01032b8:	75 0a                	jne    f01032c4 <strtol+0x2a>
		s++;
f01032ba:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032bd:	bf 00 00 00 00       	mov    $0x0,%edi
f01032c2:	eb 11                	jmp    f01032d5 <strtol+0x3b>
f01032c4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032c9:	3c 2d                	cmp    $0x2d,%al
f01032cb:	75 08                	jne    f01032d5 <strtol+0x3b>
		s++, neg = 1;
f01032cd:	83 c1 01             	add    $0x1,%ecx
f01032d0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01032d5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01032db:	75 15                	jne    f01032f2 <strtol+0x58>
f01032dd:	80 39 30             	cmpb   $0x30,(%ecx)
f01032e0:	75 10                	jne    f01032f2 <strtol+0x58>
f01032e2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01032e6:	75 7c                	jne    f0103364 <strtol+0xca>
		s += 2, base = 16;
f01032e8:	83 c1 02             	add    $0x2,%ecx
f01032eb:	bb 10 00 00 00       	mov    $0x10,%ebx
f01032f0:	eb 16                	jmp    f0103308 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01032f2:	85 db                	test   %ebx,%ebx
f01032f4:	75 12                	jne    f0103308 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01032f6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032fb:	80 39 30             	cmpb   $0x30,(%ecx)
f01032fe:	75 08                	jne    f0103308 <strtol+0x6e>
		s++, base = 8;
f0103300:	83 c1 01             	add    $0x1,%ecx
f0103303:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103308:	b8 00 00 00 00       	mov    $0x0,%eax
f010330d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103310:	0f b6 11             	movzbl (%ecx),%edx
f0103313:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103316:	89 f3                	mov    %esi,%ebx
f0103318:	80 fb 09             	cmp    $0x9,%bl
f010331b:	77 08                	ja     f0103325 <strtol+0x8b>
			dig = *s - '0';
f010331d:	0f be d2             	movsbl %dl,%edx
f0103320:	83 ea 30             	sub    $0x30,%edx
f0103323:	eb 22                	jmp    f0103347 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103325:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103328:	89 f3                	mov    %esi,%ebx
f010332a:	80 fb 19             	cmp    $0x19,%bl
f010332d:	77 08                	ja     f0103337 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010332f:	0f be d2             	movsbl %dl,%edx
f0103332:	83 ea 57             	sub    $0x57,%edx
f0103335:	eb 10                	jmp    f0103347 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103337:	8d 72 bf             	lea    -0x41(%edx),%esi
f010333a:	89 f3                	mov    %esi,%ebx
f010333c:	80 fb 19             	cmp    $0x19,%bl
f010333f:	77 16                	ja     f0103357 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103341:	0f be d2             	movsbl %dl,%edx
f0103344:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103347:	3b 55 10             	cmp    0x10(%ebp),%edx
f010334a:	7d 0b                	jge    f0103357 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010334c:	83 c1 01             	add    $0x1,%ecx
f010334f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103353:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103355:	eb b9                	jmp    f0103310 <strtol+0x76>

	if (endptr)
f0103357:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010335b:	74 0d                	je     f010336a <strtol+0xd0>
		*endptr = (char *) s;
f010335d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103360:	89 0e                	mov    %ecx,(%esi)
f0103362:	eb 06                	jmp    f010336a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103364:	85 db                	test   %ebx,%ebx
f0103366:	74 98                	je     f0103300 <strtol+0x66>
f0103368:	eb 9e                	jmp    f0103308 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010336a:	89 c2                	mov    %eax,%edx
f010336c:	f7 da                	neg    %edx
f010336e:	85 ff                	test   %edi,%edi
f0103370:	0f 45 c2             	cmovne %edx,%eax
}
f0103373:	5b                   	pop    %ebx
f0103374:	5e                   	pop    %esi
f0103375:	5f                   	pop    %edi
f0103376:	5d                   	pop    %ebp
f0103377:	c3                   	ret    
f0103378:	66 90                	xchg   %ax,%ax
f010337a:	66 90                	xchg   %ax,%ax
f010337c:	66 90                	xchg   %ax,%ax
f010337e:	66 90                	xchg   %ax,%ax

f0103380 <__udivdi3>:
f0103380:	55                   	push   %ebp
f0103381:	57                   	push   %edi
f0103382:	56                   	push   %esi
f0103383:	53                   	push   %ebx
f0103384:	83 ec 1c             	sub    $0x1c,%esp
f0103387:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010338b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010338f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103393:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103397:	85 f6                	test   %esi,%esi
f0103399:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010339d:	89 ca                	mov    %ecx,%edx
f010339f:	89 f8                	mov    %edi,%eax
f01033a1:	75 3d                	jne    f01033e0 <__udivdi3+0x60>
f01033a3:	39 cf                	cmp    %ecx,%edi
f01033a5:	0f 87 c5 00 00 00    	ja     f0103470 <__udivdi3+0xf0>
f01033ab:	85 ff                	test   %edi,%edi
f01033ad:	89 fd                	mov    %edi,%ebp
f01033af:	75 0b                	jne    f01033bc <__udivdi3+0x3c>
f01033b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033b6:	31 d2                	xor    %edx,%edx
f01033b8:	f7 f7                	div    %edi
f01033ba:	89 c5                	mov    %eax,%ebp
f01033bc:	89 c8                	mov    %ecx,%eax
f01033be:	31 d2                	xor    %edx,%edx
f01033c0:	f7 f5                	div    %ebp
f01033c2:	89 c1                	mov    %eax,%ecx
f01033c4:	89 d8                	mov    %ebx,%eax
f01033c6:	89 cf                	mov    %ecx,%edi
f01033c8:	f7 f5                	div    %ebp
f01033ca:	89 c3                	mov    %eax,%ebx
f01033cc:	89 d8                	mov    %ebx,%eax
f01033ce:	89 fa                	mov    %edi,%edx
f01033d0:	83 c4 1c             	add    $0x1c,%esp
f01033d3:	5b                   	pop    %ebx
f01033d4:	5e                   	pop    %esi
f01033d5:	5f                   	pop    %edi
f01033d6:	5d                   	pop    %ebp
f01033d7:	c3                   	ret    
f01033d8:	90                   	nop
f01033d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033e0:	39 ce                	cmp    %ecx,%esi
f01033e2:	77 74                	ja     f0103458 <__udivdi3+0xd8>
f01033e4:	0f bd fe             	bsr    %esi,%edi
f01033e7:	83 f7 1f             	xor    $0x1f,%edi
f01033ea:	0f 84 98 00 00 00    	je     f0103488 <__udivdi3+0x108>
f01033f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01033f5:	89 f9                	mov    %edi,%ecx
f01033f7:	89 c5                	mov    %eax,%ebp
f01033f9:	29 fb                	sub    %edi,%ebx
f01033fb:	d3 e6                	shl    %cl,%esi
f01033fd:	89 d9                	mov    %ebx,%ecx
f01033ff:	d3 ed                	shr    %cl,%ebp
f0103401:	89 f9                	mov    %edi,%ecx
f0103403:	d3 e0                	shl    %cl,%eax
f0103405:	09 ee                	or     %ebp,%esi
f0103407:	89 d9                	mov    %ebx,%ecx
f0103409:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010340d:	89 d5                	mov    %edx,%ebp
f010340f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103413:	d3 ed                	shr    %cl,%ebp
f0103415:	89 f9                	mov    %edi,%ecx
f0103417:	d3 e2                	shl    %cl,%edx
f0103419:	89 d9                	mov    %ebx,%ecx
f010341b:	d3 e8                	shr    %cl,%eax
f010341d:	09 c2                	or     %eax,%edx
f010341f:	89 d0                	mov    %edx,%eax
f0103421:	89 ea                	mov    %ebp,%edx
f0103423:	f7 f6                	div    %esi
f0103425:	89 d5                	mov    %edx,%ebp
f0103427:	89 c3                	mov    %eax,%ebx
f0103429:	f7 64 24 0c          	mull   0xc(%esp)
f010342d:	39 d5                	cmp    %edx,%ebp
f010342f:	72 10                	jb     f0103441 <__udivdi3+0xc1>
f0103431:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103435:	89 f9                	mov    %edi,%ecx
f0103437:	d3 e6                	shl    %cl,%esi
f0103439:	39 c6                	cmp    %eax,%esi
f010343b:	73 07                	jae    f0103444 <__udivdi3+0xc4>
f010343d:	39 d5                	cmp    %edx,%ebp
f010343f:	75 03                	jne    f0103444 <__udivdi3+0xc4>
f0103441:	83 eb 01             	sub    $0x1,%ebx
f0103444:	31 ff                	xor    %edi,%edi
f0103446:	89 d8                	mov    %ebx,%eax
f0103448:	89 fa                	mov    %edi,%edx
f010344a:	83 c4 1c             	add    $0x1c,%esp
f010344d:	5b                   	pop    %ebx
f010344e:	5e                   	pop    %esi
f010344f:	5f                   	pop    %edi
f0103450:	5d                   	pop    %ebp
f0103451:	c3                   	ret    
f0103452:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103458:	31 ff                	xor    %edi,%edi
f010345a:	31 db                	xor    %ebx,%ebx
f010345c:	89 d8                	mov    %ebx,%eax
f010345e:	89 fa                	mov    %edi,%edx
f0103460:	83 c4 1c             	add    $0x1c,%esp
f0103463:	5b                   	pop    %ebx
f0103464:	5e                   	pop    %esi
f0103465:	5f                   	pop    %edi
f0103466:	5d                   	pop    %ebp
f0103467:	c3                   	ret    
f0103468:	90                   	nop
f0103469:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103470:	89 d8                	mov    %ebx,%eax
f0103472:	f7 f7                	div    %edi
f0103474:	31 ff                	xor    %edi,%edi
f0103476:	89 c3                	mov    %eax,%ebx
f0103478:	89 d8                	mov    %ebx,%eax
f010347a:	89 fa                	mov    %edi,%edx
f010347c:	83 c4 1c             	add    $0x1c,%esp
f010347f:	5b                   	pop    %ebx
f0103480:	5e                   	pop    %esi
f0103481:	5f                   	pop    %edi
f0103482:	5d                   	pop    %ebp
f0103483:	c3                   	ret    
f0103484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103488:	39 ce                	cmp    %ecx,%esi
f010348a:	72 0c                	jb     f0103498 <__udivdi3+0x118>
f010348c:	31 db                	xor    %ebx,%ebx
f010348e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103492:	0f 87 34 ff ff ff    	ja     f01033cc <__udivdi3+0x4c>
f0103498:	bb 01 00 00 00       	mov    $0x1,%ebx
f010349d:	e9 2a ff ff ff       	jmp    f01033cc <__udivdi3+0x4c>
f01034a2:	66 90                	xchg   %ax,%ax
f01034a4:	66 90                	xchg   %ax,%ax
f01034a6:	66 90                	xchg   %ax,%ax
f01034a8:	66 90                	xchg   %ax,%ax
f01034aa:	66 90                	xchg   %ax,%ax
f01034ac:	66 90                	xchg   %ax,%ax
f01034ae:	66 90                	xchg   %ax,%ax

f01034b0 <__umoddi3>:
f01034b0:	55                   	push   %ebp
f01034b1:	57                   	push   %edi
f01034b2:	56                   	push   %esi
f01034b3:	53                   	push   %ebx
f01034b4:	83 ec 1c             	sub    $0x1c,%esp
f01034b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034c7:	85 d2                	test   %edx,%edx
f01034c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034d1:	89 f3                	mov    %esi,%ebx
f01034d3:	89 3c 24             	mov    %edi,(%esp)
f01034d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034da:	75 1c                	jne    f01034f8 <__umoddi3+0x48>
f01034dc:	39 f7                	cmp    %esi,%edi
f01034de:	76 50                	jbe    f0103530 <__umoddi3+0x80>
f01034e0:	89 c8                	mov    %ecx,%eax
f01034e2:	89 f2                	mov    %esi,%edx
f01034e4:	f7 f7                	div    %edi
f01034e6:	89 d0                	mov    %edx,%eax
f01034e8:	31 d2                	xor    %edx,%edx
f01034ea:	83 c4 1c             	add    $0x1c,%esp
f01034ed:	5b                   	pop    %ebx
f01034ee:	5e                   	pop    %esi
f01034ef:	5f                   	pop    %edi
f01034f0:	5d                   	pop    %ebp
f01034f1:	c3                   	ret    
f01034f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034f8:	39 f2                	cmp    %esi,%edx
f01034fa:	89 d0                	mov    %edx,%eax
f01034fc:	77 52                	ja     f0103550 <__umoddi3+0xa0>
f01034fe:	0f bd ea             	bsr    %edx,%ebp
f0103501:	83 f5 1f             	xor    $0x1f,%ebp
f0103504:	75 5a                	jne    f0103560 <__umoddi3+0xb0>
f0103506:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010350a:	0f 82 e0 00 00 00    	jb     f01035f0 <__umoddi3+0x140>
f0103510:	39 0c 24             	cmp    %ecx,(%esp)
f0103513:	0f 86 d7 00 00 00    	jbe    f01035f0 <__umoddi3+0x140>
f0103519:	8b 44 24 08          	mov    0x8(%esp),%eax
f010351d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103521:	83 c4 1c             	add    $0x1c,%esp
f0103524:	5b                   	pop    %ebx
f0103525:	5e                   	pop    %esi
f0103526:	5f                   	pop    %edi
f0103527:	5d                   	pop    %ebp
f0103528:	c3                   	ret    
f0103529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103530:	85 ff                	test   %edi,%edi
f0103532:	89 fd                	mov    %edi,%ebp
f0103534:	75 0b                	jne    f0103541 <__umoddi3+0x91>
f0103536:	b8 01 00 00 00       	mov    $0x1,%eax
f010353b:	31 d2                	xor    %edx,%edx
f010353d:	f7 f7                	div    %edi
f010353f:	89 c5                	mov    %eax,%ebp
f0103541:	89 f0                	mov    %esi,%eax
f0103543:	31 d2                	xor    %edx,%edx
f0103545:	f7 f5                	div    %ebp
f0103547:	89 c8                	mov    %ecx,%eax
f0103549:	f7 f5                	div    %ebp
f010354b:	89 d0                	mov    %edx,%eax
f010354d:	eb 99                	jmp    f01034e8 <__umoddi3+0x38>
f010354f:	90                   	nop
f0103550:	89 c8                	mov    %ecx,%eax
f0103552:	89 f2                	mov    %esi,%edx
f0103554:	83 c4 1c             	add    $0x1c,%esp
f0103557:	5b                   	pop    %ebx
f0103558:	5e                   	pop    %esi
f0103559:	5f                   	pop    %edi
f010355a:	5d                   	pop    %ebp
f010355b:	c3                   	ret    
f010355c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103560:	8b 34 24             	mov    (%esp),%esi
f0103563:	bf 20 00 00 00       	mov    $0x20,%edi
f0103568:	89 e9                	mov    %ebp,%ecx
f010356a:	29 ef                	sub    %ebp,%edi
f010356c:	d3 e0                	shl    %cl,%eax
f010356e:	89 f9                	mov    %edi,%ecx
f0103570:	89 f2                	mov    %esi,%edx
f0103572:	d3 ea                	shr    %cl,%edx
f0103574:	89 e9                	mov    %ebp,%ecx
f0103576:	09 c2                	or     %eax,%edx
f0103578:	89 d8                	mov    %ebx,%eax
f010357a:	89 14 24             	mov    %edx,(%esp)
f010357d:	89 f2                	mov    %esi,%edx
f010357f:	d3 e2                	shl    %cl,%edx
f0103581:	89 f9                	mov    %edi,%ecx
f0103583:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103587:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010358b:	d3 e8                	shr    %cl,%eax
f010358d:	89 e9                	mov    %ebp,%ecx
f010358f:	89 c6                	mov    %eax,%esi
f0103591:	d3 e3                	shl    %cl,%ebx
f0103593:	89 f9                	mov    %edi,%ecx
f0103595:	89 d0                	mov    %edx,%eax
f0103597:	d3 e8                	shr    %cl,%eax
f0103599:	89 e9                	mov    %ebp,%ecx
f010359b:	09 d8                	or     %ebx,%eax
f010359d:	89 d3                	mov    %edx,%ebx
f010359f:	89 f2                	mov    %esi,%edx
f01035a1:	f7 34 24             	divl   (%esp)
f01035a4:	89 d6                	mov    %edx,%esi
f01035a6:	d3 e3                	shl    %cl,%ebx
f01035a8:	f7 64 24 04          	mull   0x4(%esp)
f01035ac:	39 d6                	cmp    %edx,%esi
f01035ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035b2:	89 d1                	mov    %edx,%ecx
f01035b4:	89 c3                	mov    %eax,%ebx
f01035b6:	72 08                	jb     f01035c0 <__umoddi3+0x110>
f01035b8:	75 11                	jne    f01035cb <__umoddi3+0x11b>
f01035ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035be:	73 0b                	jae    f01035cb <__umoddi3+0x11b>
f01035c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035c4:	1b 14 24             	sbb    (%esp),%edx
f01035c7:	89 d1                	mov    %edx,%ecx
f01035c9:	89 c3                	mov    %eax,%ebx
f01035cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035cf:	29 da                	sub    %ebx,%edx
f01035d1:	19 ce                	sbb    %ecx,%esi
f01035d3:	89 f9                	mov    %edi,%ecx
f01035d5:	89 f0                	mov    %esi,%eax
f01035d7:	d3 e0                	shl    %cl,%eax
f01035d9:	89 e9                	mov    %ebp,%ecx
f01035db:	d3 ea                	shr    %cl,%edx
f01035dd:	89 e9                	mov    %ebp,%ecx
f01035df:	d3 ee                	shr    %cl,%esi
f01035e1:	09 d0                	or     %edx,%eax
f01035e3:	89 f2                	mov    %esi,%edx
f01035e5:	83 c4 1c             	add    $0x1c,%esp
f01035e8:	5b                   	pop    %ebx
f01035e9:	5e                   	pop    %esi
f01035ea:	5f                   	pop    %edi
f01035eb:	5d                   	pop    %ebp
f01035ec:	c3                   	ret    
f01035ed:	8d 76 00             	lea    0x0(%esi),%esi
f01035f0:	29 f9                	sub    %edi,%ecx
f01035f2:	19 d6                	sbb    %edx,%esi
f01035f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035fc:	e9 18 ff ff ff       	jmp    f0103519 <__umoddi3+0x69>
