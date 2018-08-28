
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 10 cb 17 f0       	mov    $0xf017cb10,%eax
f010004b:	2d ee bb 17 f0       	sub    $0xf017bbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee bb 17 f0       	push   $0xf017bbee
f0100058:	e8 25 3c 00 00       	call   f0103c82 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// 在此之前无法调用cprintf
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 41 10 f0       	push   $0xf0104120
f010006f:	e8 da 2c 00 00       	call   f0102d4e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 0c 11 00 00       	call   f0101185 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 ef 28 00 00       	call   f010296d <env_init>
	trap_init();
f010007e:	e8 3c 2d 00 00       	call   f0102dbf <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 2a 2a 00 00       	call   f0102abc <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 be 17 f0    	pushl  0xf017be48
f010009b:	e8 2d 2c 00 00       	call   f0102ccd <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 cb 17 f0 00 	cmpl   $0x0,0xf017cb00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 cb 17 f0    	mov    %esi,0xf017cb00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 3b 41 10 f0       	push   $0xf010413b
f01000ca:	e8 7f 2c 00 00       	call   f0102d4e <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 4f 2c 00 00       	call   f0102d28 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 09 4a 10 f0 	movl   $0xf0104a09,(%esp)
f01000e0:	e8 69 2c 00 00       	call   f0102d4e <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 4b 08 00 00       	call   f010093d <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 53 41 10 f0       	push   $0xf0104153
f010010c:	e8 3d 2c 00 00       	call   f0102d4e <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 0b 2c 00 00       	call   f0102d28 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 09 4a 10 f0 	movl   $0xf0104a09,(%esp)
f0100124:	e8 25 2c 00 00       	call   f0102d4e <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 be 17 f0    	mov    0xf017be24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 be 17 f0    	mov    %edx,0xf017be24
f010016e:	88 81 20 bc 17 f0    	mov    %al,-0xfe843e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 be 17 f0 00 	movl   $0x0,0xf017be24
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 00 bc 17 f0 40 	orl    $0x40,0xf017bc00
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 c0 42 10 f0 	movzbl -0xfefbd40(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 00 bc 17 f0    	mov    %ecx,0xf017bc00
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 c0 42 10 f0 	movzbl -0xfefbd40(%edx),%eax
f010021e:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f0100224:	0f b6 8a c0 41 10 f0 	movzbl -0xfefbe40(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d a0 41 10 f0 	mov    -0xfefbe60(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 6d 41 10 f0       	push   $0xf010416d
f010027a:	e8 cf 2a 00 00       	call   f0102d4e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 28 be 17 f0 	addw   $0x50,0xf017be28
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 28 be 17 f0 	mov    %dx,0xf017be28
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 28 be 17 f0 	cmpw   $0x7cf,0xf017be28
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c be 17 f0       	mov    0xf017be2c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 a7 38 00 00       	call   f0103ccf <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 be 17 f0 	subw   $0x50,0xf017be28
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 be 17 f0    	mov    0xf017be30,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 be 17 f0 	movzwl 0xf017be28,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 be 17 f0 00 	cmpb   $0x0,0xf017be34
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 be 17 f0       	mov    0xf017be20,%eax
f01004ca:	3b 05 24 be 17 f0    	cmp    0xf017be24,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 be 17 f0    	mov    %edx,0xf017be20
f01004db:	0f b6 88 20 bc 17 f0 	movzbl -0xfe843e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 be 17 f0 00 	movl   $0x0,0xf017be20
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 be 17 f0 b4 	movl   $0x3b4,0xf017be30
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 be 17 f0 d4 	movl   $0x3d4,0xf017be30
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 30 be 17 f0    	mov    0xf017be30,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 2c be 17 f0    	mov    %esi,0xf017be2c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 34 be 17 f0 	setne  0xf017be34
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 79 41 10 f0       	push   $0xf0104179
f01005f7:	e8 52 27 00 00       	call   f0102d4e <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:
#define NCOMMANDS (sizeof(commands) / sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	56                   	push   %esi
f0100636:	53                   	push   %ebx
f0100637:	bb 60 47 10 f0       	mov    $0xf0104760,%ebx
f010063c:	be 90 47 10 f0       	mov    $0xf0104790,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100641:	83 ec 04             	sub    $0x4,%esp
f0100644:	ff 73 04             	pushl  0x4(%ebx)
f0100647:	ff 33                	pushl  (%ebx)
f0100649:	68 c0 43 10 f0       	push   $0xf01043c0
f010064e:	e8 fb 26 00 00       	call   f0102d4e <cprintf>
f0100653:	83 c3 0c             	add    $0xc,%ebx

int mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100656:	83 c4 10             	add    $0x10,%esp
f0100659:	39 f3                	cmp    %esi,%ebx
f010065b:	75 e4                	jne    f0100641 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010065d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100662:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100665:	5b                   	pop    %ebx
f0100666:	5e                   	pop    %esi
f0100667:	5d                   	pop    %ebp
f0100668:	c3                   	ret    

f0100669 <mon_kerninfo>:

int mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100669:	55                   	push   %ebp
f010066a:	89 e5                	mov    %esp,%ebp
f010066c:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010066f:	68 c9 43 10 f0       	push   $0xf01043c9
f0100674:	e8 d5 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100679:	83 c4 08             	add    $0x8,%esp
f010067c:	68 0c 00 10 00       	push   $0x10000c
f0100681:	68 b0 44 10 f0       	push   $0xf01044b0
f0100686:	e8 c3 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068b:	83 c4 0c             	add    $0xc,%esp
f010068e:	68 0c 00 10 00       	push   $0x10000c
f0100693:	68 0c 00 10 f0       	push   $0xf010000c
f0100698:	68 d8 44 10 f0       	push   $0xf01044d8
f010069d:	e8 ac 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a2:	83 c4 0c             	add    $0xc,%esp
f01006a5:	68 11 41 10 00       	push   $0x104111
f01006aa:	68 11 41 10 f0       	push   $0xf0104111
f01006af:	68 fc 44 10 f0       	push   $0xf01044fc
f01006b4:	e8 95 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b9:	83 c4 0c             	add    $0xc,%esp
f01006bc:	68 ee bb 17 00       	push   $0x17bbee
f01006c1:	68 ee bb 17 f0       	push   $0xf017bbee
f01006c6:	68 20 45 10 f0       	push   $0xf0104520
f01006cb:	e8 7e 26 00 00       	call   f0102d4e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d0:	83 c4 0c             	add    $0xc,%esp
f01006d3:	68 10 cb 17 00       	push   $0x17cb10
f01006d8:	68 10 cb 17 f0       	push   $0xf017cb10
f01006dd:	68 44 45 10 f0       	push   $0xf0104544
f01006e2:	e8 67 26 00 00       	call   f0102d4e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
f01006e7:	b8 0f cf 17 f0       	mov    $0xf017cf0f,%eax
f01006ec:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f1:	83 c4 08             	add    $0x8,%esp
f01006f4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f9:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006ff:	85 c0                	test   %eax,%eax
f0100701:	0f 48 c2             	cmovs  %edx,%eax
f0100704:	c1 f8 0a             	sar    $0xa,%eax
f0100707:	50                   	push   %eax
f0100708:	68 68 45 10 f0       	push   $0xf0104568
f010070d:	e8 3c 26 00 00       	call   f0102d4e <cprintf>
			ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100712:	b8 00 00 00 00       	mov    $0x0,%eax
f0100717:	c9                   	leave  
f0100718:	c3                   	ret    

f0100719 <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100719:	55                   	push   %ebp
f010071a:	89 e5                	mov    %esp,%ebp
f010071c:	57                   	push   %edi
f010071d:	56                   	push   %esi
f010071e:	53                   	push   %ebx
f010071f:	83 ec 58             	sub    $0x58,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100722:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
f0100724:	68 e2 43 10 f0       	push   $0xf01043e2
f0100729:	e8 20 26 00 00       	call   f0102d4e <cprintf>
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f010072e:	83 c4 10             	add    $0x10,%esp
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);
f0100731:	8d 75 d0             	lea    -0x30(%ebp),%esi
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f0100734:	eb 70                	jmp    f01007a6 <mon_backtrace+0x8d>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
f0100736:	ff 73 18             	pushl  0x18(%ebx)
f0100739:	ff 73 14             	pushl  0x14(%ebx)
f010073c:	ff 73 10             	pushl  0x10(%ebx)
f010073f:	ff 73 0c             	pushl  0xc(%ebx)
f0100742:	ff 73 08             	pushl  0x8(%ebx)
f0100745:	ff 73 04             	pushl  0x4(%ebx)
f0100748:	53                   	push   %ebx
f0100749:	68 94 45 10 f0       	push   $0xf0104594
f010074e:	e8 fb 25 00 00       	call   f0102d4e <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f0100753:	83 c4 18             	add    $0x18,%esp
f0100756:	56                   	push   %esi
f0100757:	ff 73 04             	pushl  0x4(%ebx)
f010075a:	e8 a3 2a 00 00       	call   f0103202 <debuginfo_eip>

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f010075f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			fn_name[i]=info.eip_fn_name[i];
f0100762:	8b 7d d8             	mov    -0x28(%ebp),%edi
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100765:	83 c4 10             	add    $0x10,%esp
f0100768:	b8 00 00 00 00       	mov    $0x0,%eax
f010076d:	eb 0b                	jmp    f010077a <mon_backtrace+0x61>
			fn_name[i]=info.eip_fn_name[i];
f010076f:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
f0100773:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,ebp[1],ebp[2],ebp[3],ebp[4],ebp[5],ebp[6]);
		
		debuginfo_eip(ebp[1],&info);

		char fn_name[30];
		for(int i=0;i<info.eip_fn_namelen;i++){
f0100777:	83 c0 01             	add    $0x1,%eax
f010077a:	39 c8                	cmp    %ecx,%eax
f010077c:	7c f1                	jl     f010076f <mon_backtrace+0x56>
			fn_name[i]=info.eip_fn_name[i];
		}
		fn_name[info.eip_fn_namelen]=0;
f010077e:	c6 44 0d b2 00       	movb   $0x0,-0x4e(%ebp,%ecx,1)
		int off = ebp[1]-info.eip_fn_addr;
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
f0100783:	83 ec 0c             	sub    $0xc,%esp
f0100786:	8b 43 04             	mov    0x4(%ebx),%eax
f0100789:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010078c:	50                   	push   %eax
f010078d:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f0100790:	50                   	push   %eax
f0100791:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100794:	ff 75 d0             	pushl  -0x30(%ebp)
f0100797:	68 f4 43 10 f0       	push   $0xf01043f4
f010079c:	e8 ad 25 00 00       	call   f0102d4e <cprintf>
		ebp = (int*)(*ebp);
f01007a1:	8b 1b                	mov    (%ebx),%ebx
f01007a3:	83 c4 20             	add    $0x20,%esp
	// Your code here.
	uint32_t nebp = read_ebp();
	int *ebp = (int*)nebp;
	cprintf("Stack backtrace:\n");
	struct Eipdebuginfo info;
	while((int)ebp!=0){
f01007a6:	85 db                	test   %ebx,%ebx
f01007a8:	75 8c                	jne    f0100736 <mon_backtrace+0x1d>
		cprintf("%s: %d: %s+%d\n",info.eip_file,info.eip_line,fn_name,off);
		ebp = (int*)(*ebp);
	}

	return 0;
}
f01007aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01007af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b2:	5b                   	pop    %ebx
f01007b3:	5e                   	pop    %esi
f01007b4:	5f                   	pop    %edi
f01007b5:	5d                   	pop    %ebp
f01007b6:	c3                   	ret    

f01007b7 <mon_showmappings>:

// 显示虚拟地址映射命令
int mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f01007b7:	55                   	push   %ebp
f01007b8:	89 e5                	mov    %esp,%ebp
f01007ba:	57                   	push   %edi
f01007bb:	56                   	push   %esi
f01007bc:	53                   	push   %ebx
f01007bd:	83 ec 1c             	sub    $0x1c,%esp
f01007c0:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Your code here.
	if (argc != 3) {
f01007c3:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f01007c7:	74 1a                	je     f01007e3 <mon_showmappings+0x2c>
		cprintf("Requir 2 virtual address as arguments.\n");
f01007c9:	83 ec 0c             	sub    $0xc,%esp
f01007cc:	68 c8 45 10 f0       	push   $0xf01045c8
f01007d1:	e8 78 25 00 00       	call   f0102d4e <cprintf>
		return -1;
f01007d6:	83 c4 10             	add    $0x10,%esp
f01007d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01007de:	e9 52 01 00 00       	jmp    f0100935 <mon_showmappings+0x17e>
	}
	char *errChar;
	uint32_t s = strtol(argv[1],&errChar,16);
f01007e3:	83 ec 04             	sub    $0x4,%esp
f01007e6:	6a 10                	push   $0x10
f01007e8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01007eb:	50                   	push   %eax
f01007ec:	ff 76 04             	pushl  0x4(%esi)
f01007ef:	e8 b2 35 00 00       	call   f0103da6 <strtol>
f01007f4:	89 c3                	mov    %eax,%ebx
	if (*errChar) {
f01007f6:	83 c4 10             	add    $0x10,%esp
f01007f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007fc:	80 38 00             	cmpb   $0x0,(%eax)
f01007ff:	74 1d                	je     f010081e <mon_showmappings+0x67>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f0100801:	83 ec 08             	sub    $0x8,%esp
f0100804:	ff 76 04             	pushl  0x4(%esi)
f0100807:	68 03 44 10 f0       	push   $0xf0104403
f010080c:	e8 3d 25 00 00       	call   f0102d4e <cprintf>
		return -1;
f0100811:	83 c4 10             	add    $0x10,%esp
f0100814:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100819:	e9 17 01 00 00       	jmp    f0100935 <mon_showmappings+0x17e>
	}
	uint32_t e = strtol(argv[2],&errChar,16);
f010081e:	83 ec 04             	sub    $0x4,%esp
f0100821:	6a 10                	push   $0x10
f0100823:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100826:	50                   	push   %eax
f0100827:	ff 76 08             	pushl  0x8(%esi)
f010082a:	e8 77 35 00 00       	call   f0103da6 <strtol>
	if(*errChar){
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100835:	80 3a 00             	cmpb   $0x0,(%edx)
f0100838:	74 1d                	je     f0100857 <mon_showmappings+0xa0>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f010083a:	83 ec 08             	sub    $0x8,%esp
f010083d:	ff 76 04             	pushl  0x4(%esi)
f0100840:	68 03 44 10 f0       	push   $0xf0104403
f0100845:	e8 04 25 00 00       	call   f0102d4e <cprintf>
		return -1;
f010084a:	83 c4 10             	add    $0x10,%esp
f010084d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100852:	e9 de 00 00 00       	jmp    f0100935 <mon_showmappings+0x17e>
	}
	if (s > e) {
f0100857:	39 c3                	cmp    %eax,%ebx
f0100859:	76 1a                	jbe    f0100875 <mon_showmappings+0xbe>
		cprintf("Address 1 must be lower than address 2\n");
f010085b:	83 ec 0c             	sub    $0xc,%esp
f010085e:	68 f0 45 10 f0       	push   $0xf01045f0
f0100863:	e8 e6 24 00 00       	call   f0102d4e <cprintf>
		return -1;
f0100868:	83 c4 10             	add    $0x10,%esp
f010086b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100870:	e9 c0 00 00 00       	jmp    f0100935 <mon_showmappings+0x17e>
	}
	s = ROUNDDOWN(s,PGSIZE);
f0100875:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	e = ROUNDUP(e,PGSIZE);
f010087b:	8d b8 ff 0f 00 00    	lea    0xfff(%eax),%edi
f0100881:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for(uint32_t i = s;i<=e;i+=PGSIZE){
f0100887:	e9 9c 00 00 00       	jmp    f0100928 <mon_showmappings+0x171>
		uint32_t *entry = pgdir_walk(kern_pgdir,(uint32_t*)i,0);
f010088c:	83 ec 04             	sub    $0x4,%esp
f010088f:	6a 00                	push   $0x0
f0100891:	53                   	push   %ebx
f0100892:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0100898:	e8 f2 06 00 00       	call   f0100f8f <pgdir_walk>
f010089d:	89 c6                	mov    %eax,%esi
		if(entry==NULL||!(*entry&PTE_P)){
f010089f:	83 c4 10             	add    $0x10,%esp
f01008a2:	85 c0                	test   %eax,%eax
f01008a4:	74 06                	je     f01008ac <mon_showmappings+0xf5>
f01008a6:	8b 00                	mov    (%eax),%eax
f01008a8:	a8 01                	test   $0x1,%al
f01008aa:	75 13                	jne    f01008bf <mon_showmappings+0x108>
			cprintf( "Virtual address [%08x] - not mapped\n", i);
f01008ac:	83 ec 08             	sub    $0x8,%esp
f01008af:	53                   	push   %ebx
f01008b0:	68 18 46 10 f0       	push   $0xf0104618
f01008b5:	e8 94 24 00 00       	call   f0102d4e <cprintf>
			continue;
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	eb 63                	jmp    f0100922 <mon_showmappings+0x16b>
		}
		cprintf( "Virtual address [%08x] - physical address [%08x], permission: ", entry, PTE_ADDR(*entry));
f01008bf:	83 ec 04             	sub    $0x4,%esp
f01008c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008c7:	50                   	push   %eax
f01008c8:	56                   	push   %esi
f01008c9:	68 40 46 10 f0       	push   $0xf0104640
f01008ce:	e8 7b 24 00 00       	call   f0102d4e <cprintf>
		char perm_PS = (*entry & PTE_PS) ? 'S':'-';
f01008d3:	8b 06                	mov    (%esi),%eax
f01008d5:	83 c4 10             	add    $0x10,%esp
f01008d8:	89 c2                	mov    %eax,%edx
f01008da:	81 e2 80 00 00 00    	and    $0x80,%edx
f01008e0:	83 fa 01             	cmp    $0x1,%edx
f01008e3:	19 d2                	sbb    %edx,%edx
f01008e5:	83 e2 da             	and    $0xffffffda,%edx
f01008e8:	83 c2 53             	add    $0x53,%edx
		char perm_W = (*entry & PTE_W) ? 'W':'-';
f01008eb:	89 c1                	mov    %eax,%ecx
f01008ed:	83 e1 02             	and    $0x2,%ecx
f01008f0:	83 f9 01             	cmp    $0x1,%ecx
f01008f3:	19 c9                	sbb    %ecx,%ecx
f01008f5:	83 e1 d6             	and    $0xffffffd6,%ecx
f01008f8:	83 c1 57             	add    $0x57,%ecx
		char perm_U = (*entry & PTE_U) ? 'U':'-';
f01008fb:	83 e0 04             	and    $0x4,%eax
f01008fe:	83 f8 01             	cmp    $0x1,%eax
f0100901:	19 c0                	sbb    %eax,%eax
f0100903:	83 e0 d8             	and    $0xffffffd8,%eax
f0100906:	83 c0 55             	add    $0x55,%eax
		// 进入 else 分支说明 PTE_P 肯定为真了
		cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
f0100909:	0f be c9             	movsbl %cl,%ecx
f010090c:	51                   	push   %ecx
f010090d:	0f be c0             	movsbl %al,%eax
f0100910:	50                   	push   %eax
f0100911:	0f be d2             	movsbl %dl,%edx
f0100914:	52                   	push   %edx
f0100915:	68 21 44 10 f0       	push   $0xf0104421
f010091a:	e8 2f 24 00 00       	call   f0102d4e <cprintf>
f010091f:	83 c4 10             	add    $0x10,%esp
		cprintf("Address 1 must be lower than address 2\n");
		return -1;
	}
	s = ROUNDDOWN(s,PGSIZE);
	e = ROUNDUP(e,PGSIZE);
	for(uint32_t i = s;i<=e;i+=PGSIZE){
f0100922:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100928:	39 fb                	cmp    %edi,%ebx
f010092a:	0f 86 5c ff ff ff    	jbe    f010088c <mon_showmappings+0xd5>
		char perm_U = (*entry & PTE_U) ? 'U':'-';
		// 进入 else 分支说明 PTE_P 肯定为真了
		cprintf( "-%c----%c%cP\n", perm_PS, perm_U, perm_W);
	}

	return 0;
f0100930:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100935:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5e                   	pop    %esi
f010093a:	5f                   	pop    %edi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    

f010093d <monitor>:
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void monitor(struct Trapframe *tf)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	57                   	push   %edi
f0100941:	56                   	push   %esi
f0100942:	53                   	push   %ebx
f0100943:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100946:	68 80 46 10 f0       	push   $0xf0104680
f010094b:	e8 fe 23 00 00       	call   f0102d4e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100950:	c7 04 24 a4 46 10 f0 	movl   $0xf01046a4,(%esp)
f0100957:	e8 f2 23 00 00       	call   f0102d4e <cprintf>

	if (tf != NULL)
f010095c:	83 c4 10             	add    $0x10,%esp
f010095f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100963:	74 0e                	je     f0100973 <monitor+0x36>
		print_trapframe(tf);
f0100965:	83 ec 0c             	sub    $0xc,%esp
f0100968:	ff 75 08             	pushl  0x8(%ebp)
f010096b:	e8 e7 24 00 00       	call   f0102e57 <print_trapframe>
f0100970:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100973:	83 ec 0c             	sub    $0xc,%esp
f0100976:	68 2f 44 10 f0       	push   $0xf010442f
f010097b:	e8 ab 30 00 00       	call   f0103a2b <readline>
f0100980:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100982:	83 c4 10             	add    $0x10,%esp
f0100985:	85 c0                	test   %eax,%eax
f0100987:	74 ea                	je     f0100973 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100989:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100990:	be 00 00 00 00       	mov    $0x0,%esi
f0100995:	eb 0a                	jmp    f01009a1 <monitor+0x64>
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100997:	c6 03 00             	movb   $0x0,(%ebx)
f010099a:	89 f7                	mov    %esi,%edi
f010099c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010099f:	89 fe                	mov    %edi,%esi
	argc = 0;
	argv[argc] = 0;
	while (1)
	{
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009a1:	0f b6 03             	movzbl (%ebx),%eax
f01009a4:	84 c0                	test   %al,%al
f01009a6:	74 63                	je     f0100a0b <monitor+0xce>
f01009a8:	83 ec 08             	sub    $0x8,%esp
f01009ab:	0f be c0             	movsbl %al,%eax
f01009ae:	50                   	push   %eax
f01009af:	68 33 44 10 f0       	push   $0xf0104433
f01009b4:	e8 8c 32 00 00       	call   f0103c45 <strchr>
f01009b9:	83 c4 10             	add    $0x10,%esp
f01009bc:	85 c0                	test   %eax,%eax
f01009be:	75 d7                	jne    f0100997 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009c0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009c3:	74 46                	je     f0100a0b <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1)
f01009c5:	83 fe 0f             	cmp    $0xf,%esi
f01009c8:	75 14                	jne    f01009de <monitor+0xa1>
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009ca:	83 ec 08             	sub    $0x8,%esp
f01009cd:	6a 10                	push   $0x10
f01009cf:	68 38 44 10 f0       	push   $0xf0104438
f01009d4:	e8 75 23 00 00       	call   f0102d4e <cprintf>
f01009d9:	83 c4 10             	add    $0x10,%esp
f01009dc:	eb 95                	jmp    f0100973 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009de:	8d 7e 01             	lea    0x1(%esi),%edi
f01009e1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009e5:	eb 03                	jmp    f01009ea <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009e7:	83 c3 01             	add    $0x1,%ebx
		{
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ea:	0f b6 03             	movzbl (%ebx),%eax
f01009ed:	84 c0                	test   %al,%al
f01009ef:	74 ae                	je     f010099f <monitor+0x62>
f01009f1:	83 ec 08             	sub    $0x8,%esp
f01009f4:	0f be c0             	movsbl %al,%eax
f01009f7:	50                   	push   %eax
f01009f8:	68 33 44 10 f0       	push   $0xf0104433
f01009fd:	e8 43 32 00 00       	call   f0103c45 <strchr>
f0100a02:	83 c4 10             	add    $0x10,%esp
f0100a05:	85 c0                	test   %eax,%eax
f0100a07:	74 de                	je     f01009e7 <monitor+0xaa>
f0100a09:	eb 94                	jmp    f010099f <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100a0b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a12:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a13:	85 f6                	test   %esi,%esi
f0100a15:	0f 84 58 ff ff ff    	je     f0100973 <monitor+0x36>
f0100a1b:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
	{
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a20:	83 ec 08             	sub    $0x8,%esp
f0100a23:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a26:	ff 34 85 60 47 10 f0 	pushl  -0xfefb8a0(,%eax,4)
f0100a2d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a30:	e8 b2 31 00 00       	call   f0103be7 <strcmp>
f0100a35:	83 c4 10             	add    $0x10,%esp
f0100a38:	85 c0                	test   %eax,%eax
f0100a3a:	75 21                	jne    f0100a5d <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a3c:	83 ec 04             	sub    $0x4,%esp
f0100a3f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a42:	ff 75 08             	pushl  0x8(%ebp)
f0100a45:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a48:	52                   	push   %edx
f0100a49:	56                   	push   %esi
f0100a4a:	ff 14 85 68 47 10 f0 	call   *-0xfefb898(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a51:	83 c4 10             	add    $0x10,%esp
f0100a54:	85 c0                	test   %eax,%eax
f0100a56:	78 25                	js     f0100a7d <monitor+0x140>
f0100a58:	e9 16 ff ff ff       	jmp    f0100973 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++)
f0100a5d:	83 c3 01             	add    $0x1,%ebx
f0100a60:	83 fb 04             	cmp    $0x4,%ebx
f0100a63:	75 bb                	jne    f0100a20 <monitor+0xe3>
	{
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a65:	83 ec 08             	sub    $0x8,%esp
f0100a68:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a6b:	68 55 44 10 f0       	push   $0xf0104455
f0100a70:	e8 d9 22 00 00       	call   f0102d4e <cprintf>
f0100a75:	83 c4 10             	add    $0x10,%esp
f0100a78:	e9 f6 fe ff ff       	jmp    f0100973 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a80:	5b                   	pop    %ebx
f0100a81:	5e                   	pop    %esi
f0100a82:	5f                   	pop    %edi
f0100a83:	5d                   	pop    %ebp
f0100a84:	c3                   	ret    

f0100a85 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a85:	55                   	push   %ebp
f0100a86:	89 e5                	mov    %esp,%ebp
f0100a88:	53                   	push   %ebx
f0100a89:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree)
f0100a8c:	83 3d 38 be 17 f0 00 	cmpl   $0x0,0xf017be38
f0100a93:	75 11                	jne    f0100aa6 <boot_alloc+0x21>
	{
		extern char end[];
		nextfree = ROUNDUP((char *)end, PGSIZE);
f0100a95:	ba 0f db 17 f0       	mov    $0xf017db0f,%edx
f0100a9a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100aa0:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100aa6:	8b 1d 38 be 17 f0    	mov    0xf017be38,%ebx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100aac:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f0100ab3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ab9:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
	if ((int)nextfree - KERNBASE > npages * PGSIZE)
f0100abf:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100ac5:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0100acb:	c1 e1 0c             	shl    $0xc,%ecx
f0100ace:	39 ca                	cmp    %ecx,%edx
f0100ad0:	76 14                	jbe    f0100ae6 <boot_alloc+0x61>
	{
		panic("Out of memory!\n");
f0100ad2:	83 ec 04             	sub    $0x4,%esp
f0100ad5:	68 90 47 10 f0       	push   $0xf0104790
f0100ada:	6a 69                	push   $0x69
f0100adc:	68 a0 47 10 f0       	push   $0xf01047a0
f0100ae1:	e8 ba f5 ff ff       	call   f01000a0 <_panic>
	}

	return result;
}
f0100ae6:	89 d8                	mov    %ebx,%eax
f0100ae8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aeb:	c9                   	leave  
f0100aec:	c3                   	ret    

f0100aed <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100aed:	89 d1                	mov    %edx,%ecx
f0100aef:	c1 e9 16             	shr    $0x16,%ecx
f0100af2:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100af5:	a8 01                	test   $0x1,%al
f0100af7:	74 52                	je     f0100b4b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
f0100af9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100afe:	89 c1                	mov    %eax,%ecx
f0100b00:	c1 e9 0c             	shr    $0xc,%ecx
f0100b03:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0100b09:	72 1b                	jb     f0100b26 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b0b:	55                   	push   %ebp
f0100b0c:	89 e5                	mov    %esp,%ebp
f0100b0e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b11:	50                   	push   %eax
f0100b12:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0100b17:	68 2e 03 00 00       	push   $0x32e
f0100b1c:	68 a0 47 10 f0       	push   $0xf01047a0
f0100b21:	e8 7a f5 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b26:	c1 ea 0c             	shr    $0xc,%edx
f0100b29:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b2f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b36:	89 c2                	mov    %eax,%edx
f0100b38:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b40:	85 d2                	test   %edx,%edx
f0100b42:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b47:	0f 44 c2             	cmove  %edx,%eax
f0100b4a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t *)KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b50:	c3                   	ret    

f0100b51 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b51:	55                   	push   %ebp
f0100b52:	89 e5                	mov    %esp,%ebp
f0100b54:	57                   	push   %edi
f0100b55:	56                   	push   %esi
f0100b56:	53                   	push   %ebx
f0100b57:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b5a:	84 c0                	test   %al,%al
f0100b5c:	0f 85 72 02 00 00    	jne    f0100dd4 <check_page_free_list+0x283>
f0100b62:	e9 7f 02 00 00       	jmp    f0100de6 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b67:	83 ec 04             	sub    $0x4,%esp
f0100b6a:	68 60 4a 10 f0       	push   $0xf0104a60
f0100b6f:	68 65 02 00 00       	push   $0x265
f0100b74:	68 a0 47 10 f0       	push   $0xf01047a0
f0100b79:	e8 22 f5 ff ff       	call   f01000a0 <_panic>
	if (only_low_memory)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
f0100b7e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b81:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b84:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b87:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link)
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b8a:	89 c2                	mov    %eax,%edx
f0100b8c:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0100b92:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b98:	0f 95 c2             	setne  %dl
f0100b9b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b9e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ba2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ba4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	{
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = {&pp1, &pp2};
		for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba8:	8b 00                	mov    (%eax),%eax
f0100baa:	85 c0                	test   %eax,%eax
f0100bac:	75 dc                	jne    f0100b8a <check_page_free_list+0x39>
		{
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bb7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bba:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bbd:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100bbf:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bc2:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bc7:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bcc:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100bd2:	eb 53                	jmp    f0100c27 <check_page_free_list+0xd6>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100bd4:	89 d8                	mov    %ebx,%eax
f0100bd6:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100bdc:	c1 f8 03             	sar    $0x3,%eax
f0100bdf:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100be2:	89 c2                	mov    %eax,%edx
f0100be4:	c1 ea 16             	shr    $0x16,%edx
f0100be7:	39 f2                	cmp    %esi,%edx
f0100be9:	73 3a                	jae    f0100c25 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100beb:	89 c2                	mov    %eax,%edx
f0100bed:	c1 ea 0c             	shr    $0xc,%edx
f0100bf0:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100bf6:	72 12                	jb     f0100c0a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bf8:	50                   	push   %eax
f0100bf9:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0100bfe:	6a 5b                	push   $0x5b
f0100c00:	68 ac 47 10 f0       	push   $0xf01047ac
f0100c05:	e8 96 f4 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c0a:	83 ec 04             	sub    $0x4,%esp
f0100c0d:	68 80 00 00 00       	push   $0x80
f0100c12:	68 97 00 00 00       	push   $0x97
f0100c17:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c1c:	50                   	push   %eax
f0100c1d:	e8 60 30 00 00       	call   f0103c82 <memset>
f0100c22:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c25:	8b 1b                	mov    (%ebx),%ebx
f0100c27:	85 db                	test   %ebx,%ebx
f0100c29:	75 a9                	jne    f0100bd4 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
f0100c2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c30:	e8 50 fe ff ff       	call   f0100a85 <boot_alloc>
f0100c35:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c38:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c3e:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
		assert(pp < pages + npages);
f0100c44:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0100c49:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c4c:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c4f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c52:	be 00 00 00 00       	mov    $0x0,%esi
f0100c57:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c5a:	e9 30 01 00 00       	jmp    f0100d8f <check_page_free_list+0x23e>
	{
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c5f:	39 ca                	cmp    %ecx,%edx
f0100c61:	73 19                	jae    f0100c7c <check_page_free_list+0x12b>
f0100c63:	68 ba 47 10 f0       	push   $0xf01047ba
f0100c68:	68 c6 47 10 f0       	push   $0xf01047c6
f0100c6d:	68 82 02 00 00       	push   $0x282
f0100c72:	68 a0 47 10 f0       	push   $0xf01047a0
f0100c77:	e8 24 f4 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100c7c:	39 fa                	cmp    %edi,%edx
f0100c7e:	72 19                	jb     f0100c99 <check_page_free_list+0x148>
f0100c80:	68 db 47 10 f0       	push   $0xf01047db
f0100c85:	68 c6 47 10 f0       	push   $0xf01047c6
f0100c8a:	68 83 02 00 00       	push   $0x283
f0100c8f:	68 a0 47 10 f0       	push   $0xf01047a0
f0100c94:	e8 07 f4 ff ff       	call   f01000a0 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c99:	89 d0                	mov    %edx,%eax
f0100c9b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c9e:	a8 07                	test   $0x7,%al
f0100ca0:	74 19                	je     f0100cbb <check_page_free_list+0x16a>
f0100ca2:	68 84 4a 10 f0       	push   $0xf0104a84
f0100ca7:	68 c6 47 10 f0       	push   $0xf01047c6
f0100cac:	68 84 02 00 00       	push   $0x284
f0100cb1:	68 a0 47 10 f0       	push   $0xf01047a0
f0100cb6:	e8 e5 f3 ff ff       	call   f01000a0 <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100cbb:	c1 f8 03             	sar    $0x3,%eax
f0100cbe:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cc1:	85 c0                	test   %eax,%eax
f0100cc3:	75 19                	jne    f0100cde <check_page_free_list+0x18d>
f0100cc5:	68 ef 47 10 f0       	push   $0xf01047ef
f0100cca:	68 c6 47 10 f0       	push   $0xf01047c6
f0100ccf:	68 87 02 00 00       	push   $0x287
f0100cd4:	68 a0 47 10 f0       	push   $0xf01047a0
f0100cd9:	e8 c2 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cde:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ce3:	75 19                	jne    f0100cfe <check_page_free_list+0x1ad>
f0100ce5:	68 00 48 10 f0       	push   $0xf0104800
f0100cea:	68 c6 47 10 f0       	push   $0xf01047c6
f0100cef:	68 88 02 00 00       	push   $0x288
f0100cf4:	68 a0 47 10 f0       	push   $0xf01047a0
f0100cf9:	e8 a2 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cfe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d03:	75 19                	jne    f0100d1e <check_page_free_list+0x1cd>
f0100d05:	68 b4 4a 10 f0       	push   $0xf0104ab4
f0100d0a:	68 c6 47 10 f0       	push   $0xf01047c6
f0100d0f:	68 89 02 00 00       	push   $0x289
f0100d14:	68 a0 47 10 f0       	push   $0xf01047a0
f0100d19:	e8 82 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d1e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d23:	75 19                	jne    f0100d3e <check_page_free_list+0x1ed>
f0100d25:	68 19 48 10 f0       	push   $0xf0104819
f0100d2a:	68 c6 47 10 f0       	push   $0xf01047c6
f0100d2f:	68 8a 02 00 00       	push   $0x28a
f0100d34:	68 a0 47 10 f0       	push   $0xf01047a0
f0100d39:	e8 62 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *)page2kva(pp) >= first_free_page);
f0100d3e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d43:	76 3f                	jbe    f0100d84 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d45:	89 c3                	mov    %eax,%ebx
f0100d47:	c1 eb 0c             	shr    $0xc,%ebx
f0100d4a:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d4d:	77 12                	ja     f0100d61 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d4f:	50                   	push   %eax
f0100d50:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0100d55:	6a 5b                	push   $0x5b
f0100d57:	68 ac 47 10 f0       	push   $0xf01047ac
f0100d5c:	e8 3f f3 ff ff       	call   f01000a0 <_panic>
f0100d61:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d66:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d69:	76 1e                	jbe    f0100d89 <check_page_free_list+0x238>
f0100d6b:	68 d8 4a 10 f0       	push   $0xf0104ad8
f0100d70:	68 c6 47 10 f0       	push   $0xf01047c6
f0100d75:	68 8b 02 00 00       	push   $0x28b
f0100d7a:	68 a0 47 10 f0       	push   $0xf01047a0
f0100d7f:	e8 1c f3 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d84:	83 c6 01             	add    $0x1,%esi
f0100d87:	eb 04                	jmp    f0100d8d <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100d89:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *)boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d8d:	8b 12                	mov    (%edx),%edx
f0100d8f:	85 d2                	test   %edx,%edx
f0100d91:	0f 85 c8 fe ff ff    	jne    f0100c5f <check_page_free_list+0x10e>
f0100d97:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d9a:	85 f6                	test   %esi,%esi
f0100d9c:	7f 19                	jg     f0100db7 <check_page_free_list+0x266>
f0100d9e:	68 33 48 10 f0       	push   $0xf0104833
f0100da3:	68 c6 47 10 f0       	push   $0xf01047c6
f0100da8:	68 93 02 00 00       	push   $0x293
f0100dad:	68 a0 47 10 f0       	push   $0xf01047a0
f0100db2:	e8 e9 f2 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100db7:	85 db                	test   %ebx,%ebx
f0100db9:	7f 42                	jg     f0100dfd <check_page_free_list+0x2ac>
f0100dbb:	68 45 48 10 f0       	push   $0xf0104845
f0100dc0:	68 c6 47 10 f0       	push   $0xf01047c6
f0100dc5:	68 94 02 00 00       	push   $0x294
f0100dca:	68 a0 47 10 f0       	push   $0xf01047a0
f0100dcf:	e8 cc f2 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dd4:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0100dd9:	85 c0                	test   %eax,%eax
f0100ddb:	0f 85 9d fd ff ff    	jne    f0100b7e <check_page_free_list+0x2d>
f0100de1:	e9 81 fd ff ff       	jmp    f0100b67 <check_page_free_list+0x16>
f0100de6:	83 3d 3c be 17 f0 00 	cmpl   $0x0,0xf017be3c
f0100ded:	0f 84 74 fd ff ff    	je     f0100b67 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100df3:	be 00 04 00 00       	mov    $0x400,%esi
f0100df8:	e9 cf fd ff ff       	jmp    f0100bcc <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dfd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e00:	5b                   	pop    %ebx
f0100e01:	5e                   	pop    %esi
f0100e02:	5f                   	pop    %edi
f0100e03:	5d                   	pop    %ebp
f0100e04:	c3                   	ret    

f0100e05 <page_init>:
// After this is done, NEVER use boot_alloc again.  ONLY use the page
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
// 初始化该系统内所有页信息，报错在数组pages内，并形成空闲链表
void page_init(void)
{
f0100e05:	55                   	push   %ebp
f0100e06:	89 e5                	mov    %esp,%ebp
f0100e08:	53                   	push   %ebx
f0100e09:	83 ec 04             	sub    $0x4,%esp
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100e0c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e11:	e9 96 00 00 00       	jmp    f0100eac <page_init+0xa7>
	{

		if (i == 0)
f0100e16:	85 db                	test   %ebx,%ebx
f0100e18:	75 13                	jne    f0100e2d <page_init+0x28>
		{
			pages[i].pp_ref = 1;
f0100e1a:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0100e1f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e25:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100e2b:	eb 7c                	jmp    f0100ea9 <page_init+0xa4>
		}
		else if (i > npages_basemem - 1 && i < PADDR(boot_alloc(0)) / PGSIZE)
f0100e2d:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0100e32:	83 e8 01             	sub    $0x1,%eax
f0100e35:	39 c3                	cmp    %eax,%ebx
f0100e37:	76 48                	jbe    f0100e81 <page_init+0x7c>
f0100e39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3e:	e8 42 fc ff ff       	call   f0100a85 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e43:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e48:	77 15                	ja     f0100e5f <page_init+0x5a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e4a:	50                   	push   %eax
f0100e4b:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0100e50:	68 21 01 00 00       	push   $0x121
f0100e55:	68 a0 47 10 f0       	push   $0xf01047a0
f0100e5a:	e8 41 f2 ff ff       	call   f01000a0 <_panic>
f0100e5f:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e64:	c1 e8 0c             	shr    $0xc,%eax
f0100e67:	39 c3                	cmp    %eax,%ebx
f0100e69:	73 16                	jae    f0100e81 <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100e6b:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0100e70:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100e73:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e79:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			continue;
f0100e7f:	eb 28                	jmp    f0100ea9 <page_init+0xa4>
f0100e81:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}
		else
		{
			pages[i].pp_ref = 0;
f0100e88:	89 c2                	mov    %eax,%edx
f0100e8a:	03 15 0c cb 17 f0    	add    0xf017cb0c,%edx
f0100e90:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100e96:	8b 0d 3c be 17 f0    	mov    0xf017be3c,%ecx
f0100e9c:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100e9e:	03 05 0c cb 17 f0    	add    0xf017cb0c,%eax
f0100ea4:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
	// free pages!
	size_t i;

	// IDT|xxx

	for (i = 0; i < npages; i++)
f0100ea9:	83 c3 01             	add    $0x1,%ebx
f0100eac:	3b 1d 04 cb 17 f0    	cmp    0xf017cb04,%ebx
f0100eb2:	0f 82 5e ff ff ff    	jb     f0100e16 <page_init+0x11>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100eb8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ebb:	c9                   	leave  
f0100ebc:	c3                   	ret    

f0100ebd <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ebd:	55                   	push   %ebp
f0100ebe:	89 e5                	mov    %esp,%ebp
f0100ec0:	53                   	push   %ebx
f0100ec1:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *p = NULL;
	if (page_free_list == NULL)
f0100ec4:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100eca:	85 db                	test   %ebx,%ebx
f0100ecc:	74 58                	je     f0100f26 <page_alloc+0x69>
		return NULL;

	p = page_free_list;
	page_free_list = p->pp_link;
f0100ece:	8b 03                	mov    (%ebx),%eax
f0100ed0:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
	p->pp_link = NULL;
f0100ed5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
f0100edb:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100edf:	74 45                	je     f0100f26 <page_alloc+0x69>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0100ee1:	89 d8                	mov    %ebx,%eax
f0100ee3:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100ee9:	c1 f8 03             	sar    $0x3,%eax
f0100eec:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eef:	89 c2                	mov    %eax,%edx
f0100ef1:	c1 ea 0c             	shr    $0xc,%edx
f0100ef4:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100efa:	72 12                	jb     f0100f0e <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100efc:	50                   	push   %eax
f0100efd:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0100f02:	6a 5b                	push   $0x5b
f0100f04:	68 ac 47 10 f0       	push   $0xf01047ac
f0100f09:	e8 92 f1 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(p), 0, PGSIZE);
f0100f0e:	83 ec 04             	sub    $0x4,%esp
f0100f11:	68 00 10 00 00       	push   $0x1000
f0100f16:	6a 00                	push   $0x0
f0100f18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f1d:	50                   	push   %eax
f0100f1e:	e8 5f 2d 00 00       	call   f0103c82 <memset>
f0100f23:	83 c4 10             	add    $0x10,%esp
	}

	return p;
}
f0100f26:	89 d8                	mov    %ebx,%eax
f0100f28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f2b:	c9                   	leave  
f0100f2c:	c3                   	ret    

f0100f2d <page_free>:
//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void page_free(struct PageInfo *pp)
{
f0100f2d:	55                   	push   %ebp
f0100f2e:	89 e5                	mov    %esp,%ebp
f0100f30:	83 ec 08             	sub    $0x8,%esp
f0100f33:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	if (pp->pp_ref != 0 || pp->pp_link != NULL)
f0100f36:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f3b:	75 05                	jne    f0100f42 <page_free+0x15>
f0100f3d:	83 38 00             	cmpl   $0x0,(%eax)
f0100f40:	74 17                	je     f0100f59 <page_free+0x2c>
	{
		panic("still in used!");
f0100f42:	83 ec 04             	sub    $0x4,%esp
f0100f45:	68 56 48 10 f0       	push   $0xf0104856
f0100f4a:	68 5b 01 00 00       	push   $0x15b
f0100f4f:	68 a0 47 10 f0       	push   $0xf01047a0
f0100f54:	e8 47 f1 ff ff       	call   f01000a0 <_panic>
	}
	else
	{
		pp->pp_link = page_free_list;
f0100f59:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
f0100f5f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100f61:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
	}
}
f0100f66:	c9                   	leave  
f0100f67:	c3                   	ret    

f0100f68 <page_decref>:
//
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void page_decref(struct PageInfo *pp)
{
f0100f68:	55                   	push   %ebp
f0100f69:	89 e5                	mov    %esp,%ebp
f0100f6b:	83 ec 08             	sub    $0x8,%esp
f0100f6e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f71:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f75:	83 e8 01             	sub    $0x1,%eax
f0100f78:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f7c:	66 85 c0             	test   %ax,%ax
f0100f7f:	75 0c                	jne    f0100f8d <page_decref+0x25>
		page_free(pp);
f0100f81:	83 ec 0c             	sub    $0xc,%esp
f0100f84:	52                   	push   %edx
f0100f85:	e8 a3 ff ff ff       	call   f0100f2d <page_free>
f0100f8a:	83 c4 10             	add    $0x10,%esp
}
f0100f8d:	c9                   	leave  
f0100f8e:	c3                   	ret    

f0100f8f <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f8f:	55                   	push   %ebp
f0100f90:	89 e5                	mov    %esp,%ebp
f0100f92:	56                   	push   %esi
f0100f93:	53                   	push   %ebx
f0100f94:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
f0100f97:	89 f3                	mov    %esi,%ebx
f0100f99:	c1 eb 16             	shr    $0x16,%ebx
f0100f9c:	c1 e3 02             	shl    $0x2,%ebx
f0100f9f:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fa2:	f6 03 01             	testb  $0x1,(%ebx)
f0100fa5:	75 2e                	jne    f0100fd5 <pgdir_walk+0x46>
	{
		if (create == 0)
f0100fa7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fab:	74 63                	je     f0101010 <pgdir_walk+0x81>
			return NULL;
		struct PageInfo *p = page_alloc(1);
f0100fad:	83 ec 0c             	sub    $0xc,%esp
f0100fb0:	6a 01                	push   $0x1
f0100fb2:	e8 06 ff ff ff       	call   f0100ebd <page_alloc>
		if (p == NULL)
f0100fb7:	83 c4 10             	add    $0x10,%esp
f0100fba:	85 c0                	test   %eax,%eax
f0100fbc:	74 59                	je     f0101017 <pgdir_walk+0x88>
			return NULL;
		p->pp_ref = 1;
f0100fbe:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

		// 页目录项存储的是页表项的物理地址
		// 操作系统直接转换的所以自然是物理地址
		pgdir[index] = page2pa(p) | PTE_P | PTE_U | PTE_W;
f0100fc4:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100fca:	c1 f8 03             	sar    $0x3,%eax
f0100fcd:	c1 e0 0c             	shl    $0xc,%eax
f0100fd0:	83 c8 07             	or     $0x7,%eax
f0100fd3:	89 03                	mov    %eax,(%ebx)
	}
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);
f0100fd5:	8b 03                	mov    (%ebx),%eax
f0100fd7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fdc:	89 c2                	mov    %eax,%edx
f0100fde:	c1 ea 0c             	shr    $0xc,%edx
f0100fe1:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100fe7:	72 15                	jb     f0100ffe <pgdir_walk+0x6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fe9:	50                   	push   %eax
f0100fea:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0100fef:	68 98 01 00 00       	push   $0x198
f0100ff4:	68 a0 47 10 f0       	push   $0xf01047a0
f0100ff9:	e8 a2 f0 ff ff       	call   f01000a0 <_panic>
f0100ffe:	c1 ee 0a             	shr    $0xa,%esi
f0101001:	81 e6 fc 0f 00 00    	and    $0xffc,%esi

	return pte;
f0101007:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010100e:	eb 0c                	jmp    f010101c <pgdir_walk+0x8d>
	// Fill this function in
	int index = PDX(va);
	if (!(pgdir[index] & PTE_P))
	{
		if (create == 0)
			return NULL;
f0101010:	b8 00 00 00 00       	mov    $0x0,%eax
f0101015:	eb 05                	jmp    f010101c <pgdir_walk+0x8d>
		struct PageInfo *p = page_alloc(1);
		if (p == NULL)
			return NULL;
f0101017:	b8 00 00 00 00       	mov    $0x0,%eax
	// 返回的页表项的虚拟地址
	// 之前错在没有把数字转成指针，导致非地址相加
	pte_t *pte = (pte_t *)KADDR(PTE_ADDR(pgdir[index])) + PTX(va);

	return pte;
}
f010101c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010101f:	5b                   	pop    %ebx
f0101020:	5e                   	pop    %esi
f0101021:	5d                   	pop    %ebp
f0101022:	c3                   	ret    

f0101023 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101023:	55                   	push   %ebp
f0101024:	89 e5                	mov    %esp,%ebp
f0101026:	57                   	push   %edi
f0101027:	56                   	push   %esi
f0101028:	53                   	push   %ebx
f0101029:	83 ec 1c             	sub    $0x1c,%esp
f010102c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010102f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
f0101032:	c1 e9 0c             	shr    $0xc,%ecx
f0101035:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i = 0; i < pg_num; i++)
f0101038:	89 c3                	mov    %eax,%ebx
f010103a:	be 00 00 00 00       	mov    $0x0,%esi
	{
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f010103f:	89 d7                	mov    %edx,%edi
f0101041:	29 c7                	sub    %eax,%edi
		if (!pgtab)
		{
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f0101043:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101046:	83 c8 01             	or     $0x1,%eax
f0101049:	89 45 dc             	mov    %eax,-0x24(%ebp)
{
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i = 0; i < pg_num; i++)
f010104c:	eb 28                	jmp    f0101076 <boot_map_region+0x53>
	{
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f010104e:	83 ec 04             	sub    $0x4,%esp
f0101051:	6a 01                	push   $0x1
f0101053:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101056:	50                   	push   %eax
f0101057:	ff 75 e0             	pushl  -0x20(%ebp)
f010105a:	e8 30 ff ff ff       	call   f0100f8f <pgdir_walk>
		if (!pgtab)
f010105f:	83 c4 10             	add    $0x10,%esp
f0101062:	85 c0                	test   %eax,%eax
f0101064:	74 15                	je     f010107b <boot_map_region+0x58>
		{
			return;
		}
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
f0101066:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101069:	09 da                	or     %ebx,%edx
f010106b:	89 10                	mov    %edx,(%eax)
		va += PGSIZE;
		pa += PGSIZE;
f010106d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// Fill this function in
	// 不用块个数，va<va+size   0xf0000000+0x10000000 = 0x00000000 则无法进入循环
	pte_t *pgtab;
	size_t pg_num = PGNUM(size);
	for (size_t i = 0; i < pg_num; i++)
f0101073:	83 c6 01             	add    $0x1,%esi
f0101076:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101079:	75 d3                	jne    f010104e <boot_map_region+0x2b>
		//cprintf("va = %p\n", va);
		*pgtab = pa | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f010107b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010107e:	5b                   	pop    %ebx
f010107f:	5e                   	pop    %esi
f0101080:	5f                   	pop    %edi
f0101081:	5d                   	pop    %ebp
f0101082:	c3                   	ret    

f0101083 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//
// 双重指针，为了改变指针指向的值
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101083:	55                   	push   %ebp
f0101084:	89 e5                	mov    %esp,%ebp
f0101086:	53                   	push   %ebx
f0101087:	83 ec 08             	sub    $0x8,%esp
f010108a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
f010108d:	6a 00                	push   $0x0
f010108f:	ff 75 0c             	pushl  0xc(%ebp)
f0101092:	ff 75 08             	pushl  0x8(%ebp)
f0101095:	e8 f5 fe ff ff       	call   f0100f8f <pgdir_walk>
	if (p == NULL)
f010109a:	83 c4 10             	add    $0x10,%esp
f010109d:	85 c0                	test   %eax,%eax
f010109f:	74 32                	je     f01010d3 <page_lookup+0x50>
		return NULL;
	if (pte_store != NULL)
f01010a1:	85 db                	test   %ebx,%ebx
f01010a3:	74 02                	je     f01010a7 <page_lookup+0x24>
		*pte_store = p;
f01010a5:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010a7:	8b 00                	mov    (%eax),%eax
f01010a9:	c1 e8 0c             	shr    $0xc,%eax
f01010ac:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f01010b2:	72 14                	jb     f01010c8 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010b4:	83 ec 04             	sub    $0x4,%esp
f01010b7:	68 40 4b 10 f0       	push   $0xf0104b40
f01010bc:	6a 54                	push   $0x54
f01010be:	68 ac 47 10 f0       	push   $0xf01047ac
f01010c3:	e8 d8 ef ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f01010c8:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f01010ce:	8d 04 c2             	lea    (%edx,%eax,8),%eax

	return pa2page(PTE_ADDR(*p));
f01010d1:	eb 05                	jmp    f01010d8 <page_lookup+0x55>
{
	// Fill this function in

	pte_t *p = pgdir_walk(pgdir, va, 0);
	if (p == NULL)
		return NULL;
f01010d3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != NULL)
		*pte_store = p;

	return pa2page(PTE_ADDR(*p));
}
f01010d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010db:	c9                   	leave  
f01010dc:	c3                   	ret    

f01010dd <page_remove>:
//
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void page_remove(pde_t *pgdir, void *va)
{
f01010dd:	55                   	push   %ebp
f01010de:	89 e5                	mov    %esp,%ebp
f01010e0:	53                   	push   %ebx
f01010e1:	83 ec 18             	sub    $0x18,%esp
f01010e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *p = NULL;
f01010e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &p);
f01010ee:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010f1:	50                   	push   %eax
f01010f2:	53                   	push   %ebx
f01010f3:	ff 75 08             	pushl  0x8(%ebp)
f01010f6:	e8 88 ff ff ff       	call   f0101083 <page_lookup>
	if (page != NULL)
f01010fb:	83 c4 10             	add    $0x10,%esp
f01010fe:	85 c0                	test   %eax,%eax
f0101100:	74 18                	je     f010111a <page_remove+0x3d>
	{
		*p = 0;
f0101102:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101105:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
		page_decref(page);
f010110b:	83 ec 0c             	sub    $0xc,%esp
f010110e:	50                   	push   %eax
f010110f:	e8 54 fe ff ff       	call   f0100f68 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101114:	0f 01 3b             	invlpg (%ebx)
f0101117:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f010111a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010111d:	c9                   	leave  
f010111e:	c3                   	ret    

f010111f <page_insert>:
//
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010111f:	55                   	push   %ebp
f0101120:	89 e5                	mov    %esp,%ebp
f0101122:	57                   	push   %edi
f0101123:	56                   	push   %esi
f0101124:	53                   	push   %ebx
f0101125:	83 ec 10             	sub    $0x10,%esp
f0101128:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010112b:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *p = pgdir_walk(pgdir, va, 1);
f010112e:	6a 01                	push   $0x1
f0101130:	57                   	push   %edi
f0101131:	ff 75 08             	pushl  0x8(%ebp)
f0101134:	e8 56 fe ff ff       	call   f0100f8f <pgdir_walk>
	if (p == NULL)
f0101139:	83 c4 10             	add    $0x10,%esp
f010113c:	85 c0                	test   %eax,%eax
f010113e:	74 38                	je     f0101178 <page_insert+0x59>
f0101140:	89 c6                	mov    %eax,%esi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0101142:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*p & PTE_P)
f0101147:	f6 00 01             	testb  $0x1,(%eax)
f010114a:	74 0f                	je     f010115b <page_insert+0x3c>
	{
		page_remove(pgdir, va);
f010114c:	83 ec 08             	sub    $0x8,%esp
f010114f:	57                   	push   %edi
f0101150:	ff 75 08             	pushl  0x8(%ebp)
f0101153:	e8 85 ff ff ff       	call   f01010dd <page_remove>
f0101158:	83 c4 10             	add    $0x10,%esp
	}
	*p = page2pa(pp) | perm | PTE_P;
f010115b:	2b 1d 0c cb 17 f0    	sub    0xf017cb0c,%ebx
f0101161:	c1 fb 03             	sar    $0x3,%ebx
f0101164:	c1 e3 0c             	shl    $0xc,%ebx
f0101167:	8b 45 14             	mov    0x14(%ebp),%eax
f010116a:	83 c8 01             	or     $0x1,%eax
f010116d:	09 c3                	or     %eax,%ebx
f010116f:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101171:	b8 00 00 00 00       	mov    $0x0,%eax
f0101176:	eb 05                	jmp    f010117d <page_insert+0x5e>
int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *p = pgdir_walk(pgdir, va, 1);
	if (p == NULL)
	{
		return -E_NO_MEM;
f0101178:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	{
		page_remove(pgdir, va);
	}
	*p = page2pa(pp) | perm | PTE_P;
	return 0;
}
f010117d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101180:	5b                   	pop    %ebx
f0101181:	5e                   	pop    %esi
f0101182:	5f                   	pop    %edi
f0101183:	5d                   	pop    %ebp
f0101184:	c3                   	ret    

f0101185 <mem_init>:
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
// 二级页表

void mem_init(void)
{
f0101185:	55                   	push   %ebp
f0101186:	89 e5                	mov    %esp,%ebp
f0101188:	57                   	push   %edi
f0101189:	56                   	push   %esi
f010118a:	53                   	push   %ebx
f010118b:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010118e:	6a 15                	push   $0x15
f0101190:	e8 52 1b 00 00       	call   f0102ce7 <mc146818_read>
f0101195:	89 c3                	mov    %eax,%ebx
f0101197:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010119e:	e8 44 1b 00 00       	call   f0102ce7 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011a3:	c1 e0 08             	shl    $0x8,%eax
f01011a6:	09 d8                	or     %ebx,%eax
f01011a8:	c1 e0 0a             	shl    $0xa,%eax
f01011ab:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011b1:	85 c0                	test   %eax,%eax
f01011b3:	0f 48 c2             	cmovs  %edx,%eax
f01011b6:	c1 f8 0c             	sar    $0xc,%eax
f01011b9:	a3 40 be 17 f0       	mov    %eax,0xf017be40
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011be:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01011c5:	e8 1d 1b 00 00       	call   f0102ce7 <mc146818_read>
f01011ca:	89 c3                	mov    %eax,%ebx
f01011cc:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011d3:	e8 0f 1b 00 00       	call   f0102ce7 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011d8:	c1 e0 08             	shl    $0x8,%eax
f01011db:	09 d8                	or     %ebx,%eax
f01011dd:	c1 e0 0a             	shl    $0xa,%eax
f01011e0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011e6:	83 c4 10             	add    $0x10,%esp
f01011e9:	85 c0                	test   %eax,%eax
f01011eb:	0f 48 c2             	cmovs  %edx,%eax
f01011ee:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01011f1:	85 c0                	test   %eax,%eax
f01011f3:	74 0e                	je     f0101203 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01011f5:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01011fb:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04
f0101201:	eb 0c                	jmp    f010120f <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101203:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0101209:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010120f:	c1 e0 0c             	shl    $0xc,%eax
f0101212:	c1 e8 0a             	shr    $0xa,%eax
f0101215:	50                   	push   %eax
f0101216:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f010121b:	c1 e0 0c             	shl    $0xc,%eax
f010121e:	c1 e8 0a             	shr    $0xa,%eax
f0101221:	50                   	push   %eax
f0101222:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0101227:	c1 e0 0c             	shl    $0xc,%eax
f010122a:	c1 e8 0a             	shr    $0xa,%eax
f010122d:	50                   	push   %eax
f010122e:	68 60 4b 10 f0       	push   $0xf0104b60
f0101233:	e8 16 1b 00 00       	call   f0102d4e <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	// 创建一个初始化的页目录表
	kern_pgdir = (pde_t *)boot_alloc(PGSIZE);
f0101238:	b8 00 10 00 00       	mov    $0x1000,%eax
f010123d:	e8 43 f8 ff ff       	call   f0100a85 <boot_alloc>
f0101242:	a3 08 cb 17 f0       	mov    %eax,0xf017cb08
	memset(kern_pgdir, 0, PGSIZE);
f0101247:	83 c4 0c             	add    $0xc,%esp
f010124a:	68 00 10 00 00       	push   $0x1000
f010124f:	6a 00                	push   $0x0
f0101251:	50                   	push   %eax
f0101252:	e8 2b 2a 00 00       	call   f0103c82 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101257:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010125c:	83 c4 10             	add    $0x10,%esp
f010125f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101264:	77 15                	ja     f010127b <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101266:	50                   	push   %eax
f0101267:	68 1c 4b 10 f0       	push   $0xf0104b1c
f010126c:	68 92 00 00 00       	push   $0x92
f0101271:	68 a0 47 10 f0       	push   $0xf01047a0
f0101276:	e8 25 ee ff ff       	call   f01000a0 <_panic>
f010127b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101281:	83 ca 05             	or     $0x5,%edx
f0101284:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f010128a:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f010128f:	c1 e0 03             	shl    $0x3,%eax
f0101292:	e8 ee f7 ff ff       	call   f0100a85 <boot_alloc>
f0101297:	a3 0c cb 17 f0       	mov    %eax,0xf017cb0c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f010129c:	83 ec 04             	sub    $0x4,%esp
f010129f:	8b 3d 04 cb 17 f0    	mov    0xf017cb04,%edi
f01012a5:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01012ac:	52                   	push   %edx
f01012ad:	6a 00                	push   $0x0
f01012af:	50                   	push   %eax
f01012b0:	e8 cd 29 00 00       	call   f0103c82 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = (struct Env *)boot_alloc(sizeof(struct Env) * NENV);
f01012b5:	b8 00 80 01 00       	mov    $0x18000,%eax
f01012ba:	e8 c6 f7 ff ff       	call   f0100a85 <boot_alloc>
f01012bf:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	memset(envs, 0, sizeof(struct Env) * NENV);
f01012c4:	83 c4 0c             	add    $0xc,%esp
f01012c7:	68 00 80 01 00       	push   $0x18000
f01012cc:	6a 00                	push   $0x0
f01012ce:	50                   	push   %eax
f01012cf:	e8 ae 29 00 00       	call   f0103c82 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012d4:	e8 2c fb ff ff       	call   f0100e05 <page_init>

	check_page_free_list(1);
f01012d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01012de:	e8 6e f8 ff ff       	call   f0100b51 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012e3:	83 c4 10             	add    $0x10,%esp
f01012e6:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01012ed:	75 17                	jne    f0101306 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01012ef:	83 ec 04             	sub    $0x4,%esp
f01012f2:	68 65 48 10 f0       	push   $0xf0104865
f01012f7:	68 a5 02 00 00       	push   $0x2a5
f01012fc:	68 a0 47 10 f0       	push   $0xf01047a0
f0101301:	e8 9a ed ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101306:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f010130b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101310:	eb 05                	jmp    f0101317 <mem_init+0x192>
		++nfree;
f0101312:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101315:	8b 00                	mov    (%eax),%eax
f0101317:	85 c0                	test   %eax,%eax
f0101319:	75 f7                	jne    f0101312 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010131b:	83 ec 0c             	sub    $0xc,%esp
f010131e:	6a 00                	push   $0x0
f0101320:	e8 98 fb ff ff       	call   f0100ebd <page_alloc>
f0101325:	89 c7                	mov    %eax,%edi
f0101327:	83 c4 10             	add    $0x10,%esp
f010132a:	85 c0                	test   %eax,%eax
f010132c:	75 19                	jne    f0101347 <mem_init+0x1c2>
f010132e:	68 80 48 10 f0       	push   $0xf0104880
f0101333:	68 c6 47 10 f0       	push   $0xf01047c6
f0101338:	68 ad 02 00 00       	push   $0x2ad
f010133d:	68 a0 47 10 f0       	push   $0xf01047a0
f0101342:	e8 59 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101347:	83 ec 0c             	sub    $0xc,%esp
f010134a:	6a 00                	push   $0x0
f010134c:	e8 6c fb ff ff       	call   f0100ebd <page_alloc>
f0101351:	89 c6                	mov    %eax,%esi
f0101353:	83 c4 10             	add    $0x10,%esp
f0101356:	85 c0                	test   %eax,%eax
f0101358:	75 19                	jne    f0101373 <mem_init+0x1ee>
f010135a:	68 96 48 10 f0       	push   $0xf0104896
f010135f:	68 c6 47 10 f0       	push   $0xf01047c6
f0101364:	68 ae 02 00 00       	push   $0x2ae
f0101369:	68 a0 47 10 f0       	push   $0xf01047a0
f010136e:	e8 2d ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101373:	83 ec 0c             	sub    $0xc,%esp
f0101376:	6a 00                	push   $0x0
f0101378:	e8 40 fb ff ff       	call   f0100ebd <page_alloc>
f010137d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101380:	83 c4 10             	add    $0x10,%esp
f0101383:	85 c0                	test   %eax,%eax
f0101385:	75 19                	jne    f01013a0 <mem_init+0x21b>
f0101387:	68 ac 48 10 f0       	push   $0xf01048ac
f010138c:	68 c6 47 10 f0       	push   $0xf01047c6
f0101391:	68 af 02 00 00       	push   $0x2af
f0101396:	68 a0 47 10 f0       	push   $0xf01047a0
f010139b:	e8 00 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013a0:	39 f7                	cmp    %esi,%edi
f01013a2:	75 19                	jne    f01013bd <mem_init+0x238>
f01013a4:	68 c2 48 10 f0       	push   $0xf01048c2
f01013a9:	68 c6 47 10 f0       	push   $0xf01047c6
f01013ae:	68 b2 02 00 00       	push   $0x2b2
f01013b3:	68 a0 47 10 f0       	push   $0xf01047a0
f01013b8:	e8 e3 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013c0:	39 c6                	cmp    %eax,%esi
f01013c2:	74 04                	je     f01013c8 <mem_init+0x243>
f01013c4:	39 c7                	cmp    %eax,%edi
f01013c6:	75 19                	jne    f01013e1 <mem_init+0x25c>
f01013c8:	68 9c 4b 10 f0       	push   $0xf0104b9c
f01013cd:	68 c6 47 10 f0       	push   $0xf01047c6
f01013d2:	68 b3 02 00 00       	push   $0x2b3
f01013d7:	68 a0 47 10 f0       	push   $0xf01047a0
f01013dc:	e8 bf ec ff ff       	call   f01000a0 <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01013e1:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f01013e7:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01013ed:	c1 e2 0c             	shl    $0xc,%edx
f01013f0:	89 f8                	mov    %edi,%eax
f01013f2:	29 c8                	sub    %ecx,%eax
f01013f4:	c1 f8 03             	sar    $0x3,%eax
f01013f7:	c1 e0 0c             	shl    $0xc,%eax
f01013fa:	39 d0                	cmp    %edx,%eax
f01013fc:	72 19                	jb     f0101417 <mem_init+0x292>
f01013fe:	68 bc 4b 10 f0       	push   $0xf0104bbc
f0101403:	68 c6 47 10 f0       	push   $0xf01047c6
f0101408:	68 b4 02 00 00       	push   $0x2b4
f010140d:	68 a0 47 10 f0       	push   $0xf01047a0
f0101412:	e8 89 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f0101417:	89 f0                	mov    %esi,%eax
f0101419:	29 c8                	sub    %ecx,%eax
f010141b:	c1 f8 03             	sar    $0x3,%eax
f010141e:	c1 e0 0c             	shl    $0xc,%eax
f0101421:	39 c2                	cmp    %eax,%edx
f0101423:	77 19                	ja     f010143e <mem_init+0x2b9>
f0101425:	68 dc 4b 10 f0       	push   $0xf0104bdc
f010142a:	68 c6 47 10 f0       	push   $0xf01047c6
f010142f:	68 b5 02 00 00       	push   $0x2b5
f0101434:	68 a0 47 10 f0       	push   $0xf01047a0
f0101439:	e8 62 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f010143e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101441:	29 c8                	sub    %ecx,%eax
f0101443:	c1 f8 03             	sar    $0x3,%eax
f0101446:	c1 e0 0c             	shl    $0xc,%eax
f0101449:	39 c2                	cmp    %eax,%edx
f010144b:	77 19                	ja     f0101466 <mem_init+0x2e1>
f010144d:	68 fc 4b 10 f0       	push   $0xf0104bfc
f0101452:	68 c6 47 10 f0       	push   $0xf01047c6
f0101457:	68 b6 02 00 00       	push   $0x2b6
f010145c:	68 a0 47 10 f0       	push   $0xf01047a0
f0101461:	e8 3a ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101466:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f010146b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010146e:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0101475:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101478:	83 ec 0c             	sub    $0xc,%esp
f010147b:	6a 00                	push   $0x0
f010147d:	e8 3b fa ff ff       	call   f0100ebd <page_alloc>
f0101482:	83 c4 10             	add    $0x10,%esp
f0101485:	85 c0                	test   %eax,%eax
f0101487:	74 19                	je     f01014a2 <mem_init+0x31d>
f0101489:	68 d4 48 10 f0       	push   $0xf01048d4
f010148e:	68 c6 47 10 f0       	push   $0xf01047c6
f0101493:	68 bd 02 00 00       	push   $0x2bd
f0101498:	68 a0 47 10 f0       	push   $0xf01047a0
f010149d:	e8 fe eb ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014a2:	83 ec 0c             	sub    $0xc,%esp
f01014a5:	57                   	push   %edi
f01014a6:	e8 82 fa ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f01014ab:	89 34 24             	mov    %esi,(%esp)
f01014ae:	e8 7a fa ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f01014b3:	83 c4 04             	add    $0x4,%esp
f01014b6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014b9:	e8 6f fa ff ff       	call   f0100f2d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014c5:	e8 f3 f9 ff ff       	call   f0100ebd <page_alloc>
f01014ca:	89 c6                	mov    %eax,%esi
f01014cc:	83 c4 10             	add    $0x10,%esp
f01014cf:	85 c0                	test   %eax,%eax
f01014d1:	75 19                	jne    f01014ec <mem_init+0x367>
f01014d3:	68 80 48 10 f0       	push   $0xf0104880
f01014d8:	68 c6 47 10 f0       	push   $0xf01047c6
f01014dd:	68 c4 02 00 00       	push   $0x2c4
f01014e2:	68 a0 47 10 f0       	push   $0xf01047a0
f01014e7:	e8 b4 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014ec:	83 ec 0c             	sub    $0xc,%esp
f01014ef:	6a 00                	push   $0x0
f01014f1:	e8 c7 f9 ff ff       	call   f0100ebd <page_alloc>
f01014f6:	89 c7                	mov    %eax,%edi
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	85 c0                	test   %eax,%eax
f01014fd:	75 19                	jne    f0101518 <mem_init+0x393>
f01014ff:	68 96 48 10 f0       	push   $0xf0104896
f0101504:	68 c6 47 10 f0       	push   $0xf01047c6
f0101509:	68 c5 02 00 00       	push   $0x2c5
f010150e:	68 a0 47 10 f0       	push   $0xf01047a0
f0101513:	e8 88 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101518:	83 ec 0c             	sub    $0xc,%esp
f010151b:	6a 00                	push   $0x0
f010151d:	e8 9b f9 ff ff       	call   f0100ebd <page_alloc>
f0101522:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101525:	83 c4 10             	add    $0x10,%esp
f0101528:	85 c0                	test   %eax,%eax
f010152a:	75 19                	jne    f0101545 <mem_init+0x3c0>
f010152c:	68 ac 48 10 f0       	push   $0xf01048ac
f0101531:	68 c6 47 10 f0       	push   $0xf01047c6
f0101536:	68 c6 02 00 00       	push   $0x2c6
f010153b:	68 a0 47 10 f0       	push   $0xf01047a0
f0101540:	e8 5b eb ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101545:	39 fe                	cmp    %edi,%esi
f0101547:	75 19                	jne    f0101562 <mem_init+0x3dd>
f0101549:	68 c2 48 10 f0       	push   $0xf01048c2
f010154e:	68 c6 47 10 f0       	push   $0xf01047c6
f0101553:	68 c8 02 00 00       	push   $0x2c8
f0101558:	68 a0 47 10 f0       	push   $0xf01047a0
f010155d:	e8 3e eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101562:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101565:	39 c7                	cmp    %eax,%edi
f0101567:	74 04                	je     f010156d <mem_init+0x3e8>
f0101569:	39 c6                	cmp    %eax,%esi
f010156b:	75 19                	jne    f0101586 <mem_init+0x401>
f010156d:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0101572:	68 c6 47 10 f0       	push   $0xf01047c6
f0101577:	68 c9 02 00 00       	push   $0x2c9
f010157c:	68 a0 47 10 f0       	push   $0xf01047a0
f0101581:	e8 1a eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	6a 00                	push   $0x0
f010158b:	e8 2d f9 ff ff       	call   f0100ebd <page_alloc>
f0101590:	83 c4 10             	add    $0x10,%esp
f0101593:	85 c0                	test   %eax,%eax
f0101595:	74 19                	je     f01015b0 <mem_init+0x42b>
f0101597:	68 d4 48 10 f0       	push   $0xf01048d4
f010159c:	68 c6 47 10 f0       	push   $0xf01047c6
f01015a1:	68 ca 02 00 00       	push   $0x2ca
f01015a6:	68 a0 47 10 f0       	push   $0xf01047a0
f01015ab:	e8 f0 ea ff ff       	call   f01000a0 <_panic>
f01015b0:	89 f0                	mov    %esi,%eax
f01015b2:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01015b8:	c1 f8 03             	sar    $0x3,%eax
f01015bb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015be:	89 c2                	mov    %eax,%edx
f01015c0:	c1 ea 0c             	shr    $0xc,%edx
f01015c3:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01015c9:	72 12                	jb     f01015dd <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015cb:	50                   	push   %eax
f01015cc:	68 3c 4a 10 f0       	push   $0xf0104a3c
f01015d1:	6a 5b                	push   $0x5b
f01015d3:	68 ac 47 10 f0       	push   $0xf01047ac
f01015d8:	e8 c3 ea ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01015dd:	83 ec 04             	sub    $0x4,%esp
f01015e0:	68 00 10 00 00       	push   $0x1000
f01015e5:	6a 01                	push   $0x1
f01015e7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015ec:	50                   	push   %eax
f01015ed:	e8 90 26 00 00       	call   f0103c82 <memset>
	page_free(pp0);
f01015f2:	89 34 24             	mov    %esi,(%esp)
f01015f5:	e8 33 f9 ff ff       	call   f0100f2d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015fa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101601:	e8 b7 f8 ff ff       	call   f0100ebd <page_alloc>
f0101606:	83 c4 10             	add    $0x10,%esp
f0101609:	85 c0                	test   %eax,%eax
f010160b:	75 19                	jne    f0101626 <mem_init+0x4a1>
f010160d:	68 e3 48 10 f0       	push   $0xf01048e3
f0101612:	68 c6 47 10 f0       	push   $0xf01047c6
f0101617:	68 cf 02 00 00       	push   $0x2cf
f010161c:	68 a0 47 10 f0       	push   $0xf01047a0
f0101621:	e8 7a ea ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101626:	39 c6                	cmp    %eax,%esi
f0101628:	74 19                	je     f0101643 <mem_init+0x4be>
f010162a:	68 01 49 10 f0       	push   $0xf0104901
f010162f:	68 c6 47 10 f0       	push   $0xf01047c6
f0101634:	68 d0 02 00 00       	push   $0x2d0
f0101639:	68 a0 47 10 f0       	push   $0xf01047a0
f010163e:	e8 5d ea ff ff       	call   f01000a0 <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101643:	89 f0                	mov    %esi,%eax
f0101645:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010164b:	c1 f8 03             	sar    $0x3,%eax
f010164e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101651:	89 c2                	mov    %eax,%edx
f0101653:	c1 ea 0c             	shr    $0xc,%edx
f0101656:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010165c:	72 12                	jb     f0101670 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010165e:	50                   	push   %eax
f010165f:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0101664:	6a 5b                	push   $0x5b
f0101666:	68 ac 47 10 f0       	push   $0xf01047ac
f010166b:	e8 30 ea ff ff       	call   f01000a0 <_panic>
f0101670:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101676:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010167c:	80 38 00             	cmpb   $0x0,(%eax)
f010167f:	74 19                	je     f010169a <mem_init+0x515>
f0101681:	68 11 49 10 f0       	push   $0xf0104911
f0101686:	68 c6 47 10 f0       	push   $0xf01047c6
f010168b:	68 d3 02 00 00       	push   $0x2d3
f0101690:	68 a0 47 10 f0       	push   $0xf01047a0
f0101695:	e8 06 ea ff ff       	call   f01000a0 <_panic>
f010169a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010169d:	39 d0                	cmp    %edx,%eax
f010169f:	75 db                	jne    f010167c <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01016a1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016a4:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f01016a9:	83 ec 0c             	sub    $0xc,%esp
f01016ac:	56                   	push   %esi
f01016ad:	e8 7b f8 ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f01016b2:	89 3c 24             	mov    %edi,(%esp)
f01016b5:	e8 73 f8 ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f01016ba:	83 c4 04             	add    $0x4,%esp
f01016bd:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016c0:	e8 68 f8 ff ff       	call   f0100f2d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016c5:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01016ca:	83 c4 10             	add    $0x10,%esp
f01016cd:	eb 05                	jmp    f01016d4 <mem_init+0x54f>
		--nfree;
f01016cf:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016d2:	8b 00                	mov    (%eax),%eax
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	75 f7                	jne    f01016cf <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01016d8:	85 db                	test   %ebx,%ebx
f01016da:	74 19                	je     f01016f5 <mem_init+0x570>
f01016dc:	68 1b 49 10 f0       	push   $0xf010491b
f01016e1:	68 c6 47 10 f0       	push   $0xf01047c6
f01016e6:	68 e0 02 00 00       	push   $0x2e0
f01016eb:	68 a0 47 10 f0       	push   $0xf01047a0
f01016f0:	e8 ab e9 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016f5:	83 ec 0c             	sub    $0xc,%esp
f01016f8:	68 1c 4c 10 f0       	push   $0xf0104c1c
f01016fd:	e8 4c 16 00 00       	call   f0102d4e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101702:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101709:	e8 af f7 ff ff       	call   f0100ebd <page_alloc>
f010170e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101711:	83 c4 10             	add    $0x10,%esp
f0101714:	85 c0                	test   %eax,%eax
f0101716:	75 19                	jne    f0101731 <mem_init+0x5ac>
f0101718:	68 80 48 10 f0       	push   $0xf0104880
f010171d:	68 c6 47 10 f0       	push   $0xf01047c6
f0101722:	68 41 03 00 00       	push   $0x341
f0101727:	68 a0 47 10 f0       	push   $0xf01047a0
f010172c:	e8 6f e9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101731:	83 ec 0c             	sub    $0xc,%esp
f0101734:	6a 00                	push   $0x0
f0101736:	e8 82 f7 ff ff       	call   f0100ebd <page_alloc>
f010173b:	89 c3                	mov    %eax,%ebx
f010173d:	83 c4 10             	add    $0x10,%esp
f0101740:	85 c0                	test   %eax,%eax
f0101742:	75 19                	jne    f010175d <mem_init+0x5d8>
f0101744:	68 96 48 10 f0       	push   $0xf0104896
f0101749:	68 c6 47 10 f0       	push   $0xf01047c6
f010174e:	68 42 03 00 00       	push   $0x342
f0101753:	68 a0 47 10 f0       	push   $0xf01047a0
f0101758:	e8 43 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010175d:	83 ec 0c             	sub    $0xc,%esp
f0101760:	6a 00                	push   $0x0
f0101762:	e8 56 f7 ff ff       	call   f0100ebd <page_alloc>
f0101767:	89 c6                	mov    %eax,%esi
f0101769:	83 c4 10             	add    $0x10,%esp
f010176c:	85 c0                	test   %eax,%eax
f010176e:	75 19                	jne    f0101789 <mem_init+0x604>
f0101770:	68 ac 48 10 f0       	push   $0xf01048ac
f0101775:	68 c6 47 10 f0       	push   $0xf01047c6
f010177a:	68 43 03 00 00       	push   $0x343
f010177f:	68 a0 47 10 f0       	push   $0xf01047a0
f0101784:	e8 17 e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101789:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010178c:	75 19                	jne    f01017a7 <mem_init+0x622>
f010178e:	68 c2 48 10 f0       	push   $0xf01048c2
f0101793:	68 c6 47 10 f0       	push   $0xf01047c6
f0101798:	68 46 03 00 00       	push   $0x346
f010179d:	68 a0 47 10 f0       	push   $0xf01047a0
f01017a2:	e8 f9 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017a7:	39 c3                	cmp    %eax,%ebx
f01017a9:	74 05                	je     f01017b0 <mem_init+0x62b>
f01017ab:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017ae:	75 19                	jne    f01017c9 <mem_init+0x644>
f01017b0:	68 9c 4b 10 f0       	push   $0xf0104b9c
f01017b5:	68 c6 47 10 f0       	push   $0xf01047c6
f01017ba:	68 47 03 00 00       	push   $0x347
f01017bf:	68 a0 47 10 f0       	push   $0xf01047a0
f01017c4:	e8 d7 e8 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017c9:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01017ce:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017d1:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f01017d8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017db:	83 ec 0c             	sub    $0xc,%esp
f01017de:	6a 00                	push   $0x0
f01017e0:	e8 d8 f6 ff ff       	call   f0100ebd <page_alloc>
f01017e5:	83 c4 10             	add    $0x10,%esp
f01017e8:	85 c0                	test   %eax,%eax
f01017ea:	74 19                	je     f0101805 <mem_init+0x680>
f01017ec:	68 d4 48 10 f0       	push   $0xf01048d4
f01017f1:	68 c6 47 10 f0       	push   $0xf01047c6
f01017f6:	68 4e 03 00 00       	push   $0x34e
f01017fb:	68 a0 47 10 f0       	push   $0xf01047a0
f0101800:	e8 9b e8 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f0101805:	83 ec 04             	sub    $0x4,%esp
f0101808:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010180b:	50                   	push   %eax
f010180c:	6a 00                	push   $0x0
f010180e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101814:	e8 6a f8 ff ff       	call   f0101083 <page_lookup>
f0101819:	83 c4 10             	add    $0x10,%esp
f010181c:	85 c0                	test   %eax,%eax
f010181e:	74 19                	je     f0101839 <mem_init+0x6b4>
f0101820:	68 3c 4c 10 f0       	push   $0xf0104c3c
f0101825:	68 c6 47 10 f0       	push   $0xf01047c6
f010182a:	68 51 03 00 00       	push   $0x351
f010182f:	68 a0 47 10 f0       	push   $0xf01047a0
f0101834:	e8 67 e8 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101839:	6a 02                	push   $0x2
f010183b:	6a 00                	push   $0x0
f010183d:	53                   	push   %ebx
f010183e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101844:	e8 d6 f8 ff ff       	call   f010111f <page_insert>
f0101849:	83 c4 10             	add    $0x10,%esp
f010184c:	85 c0                	test   %eax,%eax
f010184e:	78 19                	js     f0101869 <mem_init+0x6e4>
f0101850:	68 70 4c 10 f0       	push   $0xf0104c70
f0101855:	68 c6 47 10 f0       	push   $0xf01047c6
f010185a:	68 54 03 00 00       	push   $0x354
f010185f:	68 a0 47 10 f0       	push   $0xf01047a0
f0101864:	e8 37 e8 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101869:	83 ec 0c             	sub    $0xc,%esp
f010186c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010186f:	e8 b9 f6 ff ff       	call   f0100f2d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101874:	6a 02                	push   $0x2
f0101876:	6a 00                	push   $0x0
f0101878:	53                   	push   %ebx
f0101879:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010187f:	e8 9b f8 ff ff       	call   f010111f <page_insert>
f0101884:	83 c4 20             	add    $0x20,%esp
f0101887:	85 c0                	test   %eax,%eax
f0101889:	74 19                	je     f01018a4 <mem_init+0x71f>
f010188b:	68 a0 4c 10 f0       	push   $0xf0104ca0
f0101890:	68 c6 47 10 f0       	push   $0xf01047c6
f0101895:	68 58 03 00 00       	push   $0x358
f010189a:	68 a0 47 10 f0       	push   $0xf01047a0
f010189f:	e8 fc e7 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018a4:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01018aa:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f01018af:	89 c1                	mov    %eax,%ecx
f01018b1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018b4:	8b 17                	mov    (%edi),%edx
f01018b6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018bf:	29 c8                	sub    %ecx,%eax
f01018c1:	c1 f8 03             	sar    $0x3,%eax
f01018c4:	c1 e0 0c             	shl    $0xc,%eax
f01018c7:	39 c2                	cmp    %eax,%edx
f01018c9:	74 19                	je     f01018e4 <mem_init+0x75f>
f01018cb:	68 d0 4c 10 f0       	push   $0xf0104cd0
f01018d0:	68 c6 47 10 f0       	push   $0xf01047c6
f01018d5:	68 59 03 00 00       	push   $0x359
f01018da:	68 a0 47 10 f0       	push   $0xf01047a0
f01018df:	e8 bc e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e9:	89 f8                	mov    %edi,%eax
f01018eb:	e8 fd f1 ff ff       	call   f0100aed <check_va2pa>
f01018f0:	89 da                	mov    %ebx,%edx
f01018f2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01018f5:	c1 fa 03             	sar    $0x3,%edx
f01018f8:	c1 e2 0c             	shl    $0xc,%edx
f01018fb:	39 d0                	cmp    %edx,%eax
f01018fd:	74 19                	je     f0101918 <mem_init+0x793>
f01018ff:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0101904:	68 c6 47 10 f0       	push   $0xf01047c6
f0101909:	68 5a 03 00 00       	push   $0x35a
f010190e:	68 a0 47 10 f0       	push   $0xf01047a0
f0101913:	e8 88 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101918:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010191d:	74 19                	je     f0101938 <mem_init+0x7b3>
f010191f:	68 26 49 10 f0       	push   $0xf0104926
f0101924:	68 c6 47 10 f0       	push   $0xf01047c6
f0101929:	68 5b 03 00 00       	push   $0x35b
f010192e:	68 a0 47 10 f0       	push   $0xf01047a0
f0101933:	e8 68 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101938:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010193b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101940:	74 19                	je     f010195b <mem_init+0x7d6>
f0101942:	68 37 49 10 f0       	push   $0xf0104937
f0101947:	68 c6 47 10 f0       	push   $0xf01047c6
f010194c:	68 5c 03 00 00       	push   $0x35c
f0101951:	68 a0 47 10 f0       	push   $0xf01047a0
f0101956:	e8 45 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f010195b:	6a 02                	push   $0x2
f010195d:	68 00 10 00 00       	push   $0x1000
f0101962:	56                   	push   %esi
f0101963:	57                   	push   %edi
f0101964:	e8 b6 f7 ff ff       	call   f010111f <page_insert>
f0101969:	83 c4 10             	add    $0x10,%esp
f010196c:	85 c0                	test   %eax,%eax
f010196e:	74 19                	je     f0101989 <mem_init+0x804>
f0101970:	68 28 4d 10 f0       	push   $0xf0104d28
f0101975:	68 c6 47 10 f0       	push   $0xf01047c6
f010197a:	68 5f 03 00 00       	push   $0x35f
f010197f:	68 a0 47 10 f0       	push   $0xf01047a0
f0101984:	e8 17 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101989:	ba 00 10 00 00       	mov    $0x1000,%edx
f010198e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101993:	e8 55 f1 ff ff       	call   f0100aed <check_va2pa>
f0101998:	89 f2                	mov    %esi,%edx
f010199a:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f01019a0:	c1 fa 03             	sar    $0x3,%edx
f01019a3:	c1 e2 0c             	shl    $0xc,%edx
f01019a6:	39 d0                	cmp    %edx,%eax
f01019a8:	74 19                	je     f01019c3 <mem_init+0x83e>
f01019aa:	68 64 4d 10 f0       	push   $0xf0104d64
f01019af:	68 c6 47 10 f0       	push   $0xf01047c6
f01019b4:	68 60 03 00 00       	push   $0x360
f01019b9:	68 a0 47 10 f0       	push   $0xf01047a0
f01019be:	e8 dd e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019c3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019c8:	74 19                	je     f01019e3 <mem_init+0x85e>
f01019ca:	68 48 49 10 f0       	push   $0xf0104948
f01019cf:	68 c6 47 10 f0       	push   $0xf01047c6
f01019d4:	68 61 03 00 00       	push   $0x361
f01019d9:	68 a0 47 10 f0       	push   $0xf01047a0
f01019de:	e8 bd e6 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01019e3:	83 ec 0c             	sub    $0xc,%esp
f01019e6:	6a 00                	push   $0x0
f01019e8:	e8 d0 f4 ff ff       	call   f0100ebd <page_alloc>
f01019ed:	83 c4 10             	add    $0x10,%esp
f01019f0:	85 c0                	test   %eax,%eax
f01019f2:	74 19                	je     f0101a0d <mem_init+0x888>
f01019f4:	68 d4 48 10 f0       	push   $0xf01048d4
f01019f9:	68 c6 47 10 f0       	push   $0xf01047c6
f01019fe:	68 64 03 00 00       	push   $0x364
f0101a03:	68 a0 47 10 f0       	push   $0xf01047a0
f0101a08:	e8 93 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101a0d:	6a 02                	push   $0x2
f0101a0f:	68 00 10 00 00       	push   $0x1000
f0101a14:	56                   	push   %esi
f0101a15:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a1b:	e8 ff f6 ff ff       	call   f010111f <page_insert>
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	85 c0                	test   %eax,%eax
f0101a25:	74 19                	je     f0101a40 <mem_init+0x8bb>
f0101a27:	68 28 4d 10 f0       	push   $0xf0104d28
f0101a2c:	68 c6 47 10 f0       	push   $0xf01047c6
f0101a31:	68 67 03 00 00       	push   $0x367
f0101a36:	68 a0 47 10 f0       	push   $0xf01047a0
f0101a3b:	e8 60 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a45:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101a4a:	e8 9e f0 ff ff       	call   f0100aed <check_va2pa>
f0101a4f:	89 f2                	mov    %esi,%edx
f0101a51:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101a57:	c1 fa 03             	sar    $0x3,%edx
f0101a5a:	c1 e2 0c             	shl    $0xc,%edx
f0101a5d:	39 d0                	cmp    %edx,%eax
f0101a5f:	74 19                	je     f0101a7a <mem_init+0x8f5>
f0101a61:	68 64 4d 10 f0       	push   $0xf0104d64
f0101a66:	68 c6 47 10 f0       	push   $0xf01047c6
f0101a6b:	68 68 03 00 00       	push   $0x368
f0101a70:	68 a0 47 10 f0       	push   $0xf01047a0
f0101a75:	e8 26 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a7a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a7f:	74 19                	je     f0101a9a <mem_init+0x915>
f0101a81:	68 48 49 10 f0       	push   $0xf0104948
f0101a86:	68 c6 47 10 f0       	push   $0xf01047c6
f0101a8b:	68 69 03 00 00       	push   $0x369
f0101a90:	68 a0 47 10 f0       	push   $0xf01047a0
f0101a95:	e8 06 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a9a:	83 ec 0c             	sub    $0xc,%esp
f0101a9d:	6a 00                	push   $0x0
f0101a9f:	e8 19 f4 ff ff       	call   f0100ebd <page_alloc>
f0101aa4:	83 c4 10             	add    $0x10,%esp
f0101aa7:	85 c0                	test   %eax,%eax
f0101aa9:	74 19                	je     f0101ac4 <mem_init+0x93f>
f0101aab:	68 d4 48 10 f0       	push   $0xf01048d4
f0101ab0:	68 c6 47 10 f0       	push   $0xf01047c6
f0101ab5:	68 6d 03 00 00       	push   $0x36d
f0101aba:	68 a0 47 10 f0       	push   $0xf01047a0
f0101abf:	e8 dc e5 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ac4:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f0101aca:	8b 02                	mov    (%edx),%eax
f0101acc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ad1:	89 c1                	mov    %eax,%ecx
f0101ad3:	c1 e9 0c             	shr    $0xc,%ecx
f0101ad6:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0101adc:	72 15                	jb     f0101af3 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ade:	50                   	push   %eax
f0101adf:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0101ae4:	68 70 03 00 00       	push   $0x370
f0101ae9:	68 a0 47 10 f0       	push   $0xf01047a0
f0101aee:	e8 ad e5 ff ff       	call   f01000a0 <_panic>
f0101af3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101af8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101afb:	83 ec 04             	sub    $0x4,%esp
f0101afe:	6a 00                	push   $0x0
f0101b00:	68 00 10 00 00       	push   $0x1000
f0101b05:	52                   	push   %edx
f0101b06:	e8 84 f4 ff ff       	call   f0100f8f <pgdir_walk>
f0101b0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101b0e:	8d 57 04             	lea    0x4(%edi),%edx
f0101b11:	83 c4 10             	add    $0x10,%esp
f0101b14:	39 d0                	cmp    %edx,%eax
f0101b16:	74 19                	je     f0101b31 <mem_init+0x9ac>
f0101b18:	68 94 4d 10 f0       	push   $0xf0104d94
f0101b1d:	68 c6 47 10 f0       	push   $0xf01047c6
f0101b22:	68 71 03 00 00       	push   $0x371
f0101b27:	68 a0 47 10 f0       	push   $0xf01047a0
f0101b2c:	e8 6f e5 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101b31:	6a 06                	push   $0x6
f0101b33:	68 00 10 00 00       	push   $0x1000
f0101b38:	56                   	push   %esi
f0101b39:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b3f:	e8 db f5 ff ff       	call   f010111f <page_insert>
f0101b44:	83 c4 10             	add    $0x10,%esp
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	74 19                	je     f0101b64 <mem_init+0x9df>
f0101b4b:	68 d4 4d 10 f0       	push   $0xf0104dd4
f0101b50:	68 c6 47 10 f0       	push   $0xf01047c6
f0101b55:	68 74 03 00 00       	push   $0x374
f0101b5a:	68 a0 47 10 f0       	push   $0xf01047a0
f0101b5f:	e8 3c e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b64:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101b6a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b6f:	89 f8                	mov    %edi,%eax
f0101b71:	e8 77 ef ff ff       	call   f0100aed <check_va2pa>
f0101b76:	89 f2                	mov    %esi,%edx
f0101b78:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101b7e:	c1 fa 03             	sar    $0x3,%edx
f0101b81:	c1 e2 0c             	shl    $0xc,%edx
f0101b84:	39 d0                	cmp    %edx,%eax
f0101b86:	74 19                	je     f0101ba1 <mem_init+0xa1c>
f0101b88:	68 64 4d 10 f0       	push   $0xf0104d64
f0101b8d:	68 c6 47 10 f0       	push   $0xf01047c6
f0101b92:	68 75 03 00 00       	push   $0x375
f0101b97:	68 a0 47 10 f0       	push   $0xf01047a0
f0101b9c:	e8 ff e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ba1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ba6:	74 19                	je     f0101bc1 <mem_init+0xa3c>
f0101ba8:	68 48 49 10 f0       	push   $0xf0104948
f0101bad:	68 c6 47 10 f0       	push   $0xf01047c6
f0101bb2:	68 76 03 00 00       	push   $0x376
f0101bb7:	68 a0 47 10 f0       	push   $0xf01047a0
f0101bbc:	e8 df e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101bc1:	83 ec 04             	sub    $0x4,%esp
f0101bc4:	6a 00                	push   $0x0
f0101bc6:	68 00 10 00 00       	push   $0x1000
f0101bcb:	57                   	push   %edi
f0101bcc:	e8 be f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101bd1:	83 c4 10             	add    $0x10,%esp
f0101bd4:	f6 00 04             	testb  $0x4,(%eax)
f0101bd7:	75 19                	jne    f0101bf2 <mem_init+0xa6d>
f0101bd9:	68 18 4e 10 f0       	push   $0xf0104e18
f0101bde:	68 c6 47 10 f0       	push   $0xf01047c6
f0101be3:	68 77 03 00 00       	push   $0x377
f0101be8:	68 a0 47 10 f0       	push   $0xf01047a0
f0101bed:	e8 ae e4 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101bf2:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101bf7:	f6 00 04             	testb  $0x4,(%eax)
f0101bfa:	75 19                	jne    f0101c15 <mem_init+0xa90>
f0101bfc:	68 59 49 10 f0       	push   $0xf0104959
f0101c01:	68 c6 47 10 f0       	push   $0xf01047c6
f0101c06:	68 78 03 00 00       	push   $0x378
f0101c0b:	68 a0 47 10 f0       	push   $0xf01047a0
f0101c10:	e8 8b e4 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101c15:	6a 02                	push   $0x2
f0101c17:	68 00 10 00 00       	push   $0x1000
f0101c1c:	56                   	push   %esi
f0101c1d:	50                   	push   %eax
f0101c1e:	e8 fc f4 ff ff       	call   f010111f <page_insert>
f0101c23:	83 c4 10             	add    $0x10,%esp
f0101c26:	85 c0                	test   %eax,%eax
f0101c28:	74 19                	je     f0101c43 <mem_init+0xabe>
f0101c2a:	68 28 4d 10 f0       	push   $0xf0104d28
f0101c2f:	68 c6 47 10 f0       	push   $0xf01047c6
f0101c34:	68 7b 03 00 00       	push   $0x37b
f0101c39:	68 a0 47 10 f0       	push   $0xf01047a0
f0101c3e:	e8 5d e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101c43:	83 ec 04             	sub    $0x4,%esp
f0101c46:	6a 00                	push   $0x0
f0101c48:	68 00 10 00 00       	push   $0x1000
f0101c4d:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c53:	e8 37 f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101c58:	83 c4 10             	add    $0x10,%esp
f0101c5b:	f6 00 02             	testb  $0x2,(%eax)
f0101c5e:	75 19                	jne    f0101c79 <mem_init+0xaf4>
f0101c60:	68 4c 4e 10 f0       	push   $0xf0104e4c
f0101c65:	68 c6 47 10 f0       	push   $0xf01047c6
f0101c6a:	68 7c 03 00 00       	push   $0x37c
f0101c6f:	68 a0 47 10 f0       	push   $0xf01047a0
f0101c74:	e8 27 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101c79:	83 ec 04             	sub    $0x4,%esp
f0101c7c:	6a 00                	push   $0x0
f0101c7e:	68 00 10 00 00       	push   $0x1000
f0101c83:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c89:	e8 01 f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101c8e:	83 c4 10             	add    $0x10,%esp
f0101c91:	f6 00 04             	testb  $0x4,(%eax)
f0101c94:	74 19                	je     f0101caf <mem_init+0xb2a>
f0101c96:	68 80 4e 10 f0       	push   $0xf0104e80
f0101c9b:	68 c6 47 10 f0       	push   $0xf01047c6
f0101ca0:	68 7d 03 00 00       	push   $0x37d
f0101ca5:	68 a0 47 10 f0       	push   $0xf01047a0
f0101caa:	e8 f1 e3 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101caf:	6a 02                	push   $0x2
f0101cb1:	68 00 00 40 00       	push   $0x400000
f0101cb6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cb9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101cbf:	e8 5b f4 ff ff       	call   f010111f <page_insert>
f0101cc4:	83 c4 10             	add    $0x10,%esp
f0101cc7:	85 c0                	test   %eax,%eax
f0101cc9:	78 19                	js     f0101ce4 <mem_init+0xb5f>
f0101ccb:	68 b8 4e 10 f0       	push   $0xf0104eb8
f0101cd0:	68 c6 47 10 f0       	push   $0xf01047c6
f0101cd5:	68 80 03 00 00       	push   $0x380
f0101cda:	68 a0 47 10 f0       	push   $0xf01047a0
f0101cdf:	e8 bc e3 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101ce4:	6a 02                	push   $0x2
f0101ce6:	68 00 10 00 00       	push   $0x1000
f0101ceb:	53                   	push   %ebx
f0101cec:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101cf2:	e8 28 f4 ff ff       	call   f010111f <page_insert>
f0101cf7:	83 c4 10             	add    $0x10,%esp
f0101cfa:	85 c0                	test   %eax,%eax
f0101cfc:	74 19                	je     f0101d17 <mem_init+0xb92>
f0101cfe:	68 f0 4e 10 f0       	push   $0xf0104ef0
f0101d03:	68 c6 47 10 f0       	push   $0xf01047c6
f0101d08:	68 83 03 00 00       	push   $0x383
f0101d0d:	68 a0 47 10 f0       	push   $0xf01047a0
f0101d12:	e8 89 e3 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101d17:	83 ec 04             	sub    $0x4,%esp
f0101d1a:	6a 00                	push   $0x0
f0101d1c:	68 00 10 00 00       	push   $0x1000
f0101d21:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d27:	e8 63 f2 ff ff       	call   f0100f8f <pgdir_walk>
f0101d2c:	83 c4 10             	add    $0x10,%esp
f0101d2f:	f6 00 04             	testb  $0x4,(%eax)
f0101d32:	74 19                	je     f0101d4d <mem_init+0xbc8>
f0101d34:	68 80 4e 10 f0       	push   $0xf0104e80
f0101d39:	68 c6 47 10 f0       	push   $0xf01047c6
f0101d3e:	68 84 03 00 00       	push   $0x384
f0101d43:	68 a0 47 10 f0       	push   $0xf01047a0
f0101d48:	e8 53 e3 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d4d:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d53:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d58:	89 f8                	mov    %edi,%eax
f0101d5a:	e8 8e ed ff ff       	call   f0100aed <check_va2pa>
f0101d5f:	89 c1                	mov    %eax,%ecx
f0101d61:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d64:	89 d8                	mov    %ebx,%eax
f0101d66:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101d6c:	c1 f8 03             	sar    $0x3,%eax
f0101d6f:	c1 e0 0c             	shl    $0xc,%eax
f0101d72:	39 c1                	cmp    %eax,%ecx
f0101d74:	74 19                	je     f0101d8f <mem_init+0xc0a>
f0101d76:	68 2c 4f 10 f0       	push   $0xf0104f2c
f0101d7b:	68 c6 47 10 f0       	push   $0xf01047c6
f0101d80:	68 87 03 00 00       	push   $0x387
f0101d85:	68 a0 47 10 f0       	push   $0xf01047a0
f0101d8a:	e8 11 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d8f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d94:	89 f8                	mov    %edi,%eax
f0101d96:	e8 52 ed ff ff       	call   f0100aed <check_va2pa>
f0101d9b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d9e:	74 19                	je     f0101db9 <mem_init+0xc34>
f0101da0:	68 58 4f 10 f0       	push   $0xf0104f58
f0101da5:	68 c6 47 10 f0       	push   $0xf01047c6
f0101daa:	68 88 03 00 00       	push   $0x388
f0101daf:	68 a0 47 10 f0       	push   $0xf01047a0
f0101db4:	e8 e7 e2 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101db9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dbe:	74 19                	je     f0101dd9 <mem_init+0xc54>
f0101dc0:	68 6f 49 10 f0       	push   $0xf010496f
f0101dc5:	68 c6 47 10 f0       	push   $0xf01047c6
f0101dca:	68 8a 03 00 00       	push   $0x38a
f0101dcf:	68 a0 47 10 f0       	push   $0xf01047a0
f0101dd4:	e8 c7 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dd9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dde:	74 19                	je     f0101df9 <mem_init+0xc74>
f0101de0:	68 80 49 10 f0       	push   $0xf0104980
f0101de5:	68 c6 47 10 f0       	push   $0xf01047c6
f0101dea:	68 8b 03 00 00       	push   $0x38b
f0101def:	68 a0 47 10 f0       	push   $0xf01047a0
f0101df4:	e8 a7 e2 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101df9:	83 ec 0c             	sub    $0xc,%esp
f0101dfc:	6a 00                	push   $0x0
f0101dfe:	e8 ba f0 ff ff       	call   f0100ebd <page_alloc>
f0101e03:	83 c4 10             	add    $0x10,%esp
f0101e06:	85 c0                	test   %eax,%eax
f0101e08:	74 04                	je     f0101e0e <mem_init+0xc89>
f0101e0a:	39 c6                	cmp    %eax,%esi
f0101e0c:	74 19                	je     f0101e27 <mem_init+0xca2>
f0101e0e:	68 88 4f 10 f0       	push   $0xf0104f88
f0101e13:	68 c6 47 10 f0       	push   $0xf01047c6
f0101e18:	68 8e 03 00 00       	push   $0x38e
f0101e1d:	68 a0 47 10 f0       	push   $0xf01047a0
f0101e22:	e8 79 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e27:	83 ec 08             	sub    $0x8,%esp
f0101e2a:	6a 00                	push   $0x0
f0101e2c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101e32:	e8 a6 f2 ff ff       	call   f01010dd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e37:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101e3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e42:	89 f8                	mov    %edi,%eax
f0101e44:	e8 a4 ec ff ff       	call   f0100aed <check_va2pa>
f0101e49:	83 c4 10             	add    $0x10,%esp
f0101e4c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e4f:	74 19                	je     f0101e6a <mem_init+0xce5>
f0101e51:	68 ac 4f 10 f0       	push   $0xf0104fac
f0101e56:	68 c6 47 10 f0       	push   $0xf01047c6
f0101e5b:	68 92 03 00 00       	push   $0x392
f0101e60:	68 a0 47 10 f0       	push   $0xf01047a0
f0101e65:	e8 36 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e6a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6f:	89 f8                	mov    %edi,%eax
f0101e71:	e8 77 ec ff ff       	call   f0100aed <check_va2pa>
f0101e76:	89 da                	mov    %ebx,%edx
f0101e78:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101e7e:	c1 fa 03             	sar    $0x3,%edx
f0101e81:	c1 e2 0c             	shl    $0xc,%edx
f0101e84:	39 d0                	cmp    %edx,%eax
f0101e86:	74 19                	je     f0101ea1 <mem_init+0xd1c>
f0101e88:	68 58 4f 10 f0       	push   $0xf0104f58
f0101e8d:	68 c6 47 10 f0       	push   $0xf01047c6
f0101e92:	68 93 03 00 00       	push   $0x393
f0101e97:	68 a0 47 10 f0       	push   $0xf01047a0
f0101e9c:	e8 ff e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101ea1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ea6:	74 19                	je     f0101ec1 <mem_init+0xd3c>
f0101ea8:	68 26 49 10 f0       	push   $0xf0104926
f0101ead:	68 c6 47 10 f0       	push   $0xf01047c6
f0101eb2:	68 94 03 00 00       	push   $0x394
f0101eb7:	68 a0 47 10 f0       	push   $0xf01047a0
f0101ebc:	e8 df e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ec1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ec6:	74 19                	je     f0101ee1 <mem_init+0xd5c>
f0101ec8:	68 80 49 10 f0       	push   $0xf0104980
f0101ecd:	68 c6 47 10 f0       	push   $0xf01047c6
f0101ed2:	68 95 03 00 00       	push   $0x395
f0101ed7:	68 a0 47 10 f0       	push   $0xf01047a0
f0101edc:	e8 bf e1 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101ee1:	6a 00                	push   $0x0
f0101ee3:	68 00 10 00 00       	push   $0x1000
f0101ee8:	53                   	push   %ebx
f0101ee9:	57                   	push   %edi
f0101eea:	e8 30 f2 ff ff       	call   f010111f <page_insert>
f0101eef:	83 c4 10             	add    $0x10,%esp
f0101ef2:	85 c0                	test   %eax,%eax
f0101ef4:	74 19                	je     f0101f0f <mem_init+0xd8a>
f0101ef6:	68 d0 4f 10 f0       	push   $0xf0104fd0
f0101efb:	68 c6 47 10 f0       	push   $0xf01047c6
f0101f00:	68 98 03 00 00       	push   $0x398
f0101f05:	68 a0 47 10 f0       	push   $0xf01047a0
f0101f0a:	e8 91 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101f0f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f14:	75 19                	jne    f0101f2f <mem_init+0xdaa>
f0101f16:	68 91 49 10 f0       	push   $0xf0104991
f0101f1b:	68 c6 47 10 f0       	push   $0xf01047c6
f0101f20:	68 99 03 00 00       	push   $0x399
f0101f25:	68 a0 47 10 f0       	push   $0xf01047a0
f0101f2a:	e8 71 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101f2f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f32:	74 19                	je     f0101f4d <mem_init+0xdc8>
f0101f34:	68 9d 49 10 f0       	push   $0xf010499d
f0101f39:	68 c6 47 10 f0       	push   $0xf01047c6
f0101f3e:	68 9a 03 00 00       	push   $0x39a
f0101f43:	68 a0 47 10 f0       	push   $0xf01047a0
f0101f48:	e8 53 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101f4d:	83 ec 08             	sub    $0x8,%esp
f0101f50:	68 00 10 00 00       	push   $0x1000
f0101f55:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101f5b:	e8 7d f1 ff ff       	call   f01010dd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f60:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101f66:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f6b:	89 f8                	mov    %edi,%eax
f0101f6d:	e8 7b eb ff ff       	call   f0100aed <check_va2pa>
f0101f72:	83 c4 10             	add    $0x10,%esp
f0101f75:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f78:	74 19                	je     f0101f93 <mem_init+0xe0e>
f0101f7a:	68 ac 4f 10 f0       	push   $0xf0104fac
f0101f7f:	68 c6 47 10 f0       	push   $0xf01047c6
f0101f84:	68 9e 03 00 00       	push   $0x39e
f0101f89:	68 a0 47 10 f0       	push   $0xf01047a0
f0101f8e:	e8 0d e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f93:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f98:	89 f8                	mov    %edi,%eax
f0101f9a:	e8 4e eb ff ff       	call   f0100aed <check_va2pa>
f0101f9f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa2:	74 19                	je     f0101fbd <mem_init+0xe38>
f0101fa4:	68 08 50 10 f0       	push   $0xf0105008
f0101fa9:	68 c6 47 10 f0       	push   $0xf01047c6
f0101fae:	68 9f 03 00 00       	push   $0x39f
f0101fb3:	68 a0 47 10 f0       	push   $0xf01047a0
f0101fb8:	e8 e3 e0 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101fbd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fc2:	74 19                	je     f0101fdd <mem_init+0xe58>
f0101fc4:	68 b2 49 10 f0       	push   $0xf01049b2
f0101fc9:	68 c6 47 10 f0       	push   $0xf01047c6
f0101fce:	68 a0 03 00 00       	push   $0x3a0
f0101fd3:	68 a0 47 10 f0       	push   $0xf01047a0
f0101fd8:	e8 c3 e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101fdd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fe2:	74 19                	je     f0101ffd <mem_init+0xe78>
f0101fe4:	68 80 49 10 f0       	push   $0xf0104980
f0101fe9:	68 c6 47 10 f0       	push   $0xf01047c6
f0101fee:	68 a1 03 00 00       	push   $0x3a1
f0101ff3:	68 a0 47 10 f0       	push   $0xf01047a0
f0101ff8:	e8 a3 e0 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ffd:	83 ec 0c             	sub    $0xc,%esp
f0102000:	6a 00                	push   $0x0
f0102002:	e8 b6 ee ff ff       	call   f0100ebd <page_alloc>
f0102007:	83 c4 10             	add    $0x10,%esp
f010200a:	39 c3                	cmp    %eax,%ebx
f010200c:	75 04                	jne    f0102012 <mem_init+0xe8d>
f010200e:	85 c0                	test   %eax,%eax
f0102010:	75 19                	jne    f010202b <mem_init+0xea6>
f0102012:	68 30 50 10 f0       	push   $0xf0105030
f0102017:	68 c6 47 10 f0       	push   $0xf01047c6
f010201c:	68 a4 03 00 00       	push   $0x3a4
f0102021:	68 a0 47 10 f0       	push   $0xf01047a0
f0102026:	e8 75 e0 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010202b:	83 ec 0c             	sub    $0xc,%esp
f010202e:	6a 00                	push   $0x0
f0102030:	e8 88 ee ff ff       	call   f0100ebd <page_alloc>
f0102035:	83 c4 10             	add    $0x10,%esp
f0102038:	85 c0                	test   %eax,%eax
f010203a:	74 19                	je     f0102055 <mem_init+0xed0>
f010203c:	68 d4 48 10 f0       	push   $0xf01048d4
f0102041:	68 c6 47 10 f0       	push   $0xf01047c6
f0102046:	68 a7 03 00 00       	push   $0x3a7
f010204b:	68 a0 47 10 f0       	push   $0xf01047a0
f0102050:	e8 4b e0 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102055:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f010205b:	8b 11                	mov    (%ecx),%edx
f010205d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102063:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102066:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010206c:	c1 f8 03             	sar    $0x3,%eax
f010206f:	c1 e0 0c             	shl    $0xc,%eax
f0102072:	39 c2                	cmp    %eax,%edx
f0102074:	74 19                	je     f010208f <mem_init+0xf0a>
f0102076:	68 d0 4c 10 f0       	push   $0xf0104cd0
f010207b:	68 c6 47 10 f0       	push   $0xf01047c6
f0102080:	68 aa 03 00 00       	push   $0x3aa
f0102085:	68 a0 47 10 f0       	push   $0xf01047a0
f010208a:	e8 11 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010208f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102095:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102098:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010209d:	74 19                	je     f01020b8 <mem_init+0xf33>
f010209f:	68 37 49 10 f0       	push   $0xf0104937
f01020a4:	68 c6 47 10 f0       	push   $0xf01047c6
f01020a9:	68 ac 03 00 00       	push   $0x3ac
f01020ae:	68 a0 47 10 f0       	push   $0xf01047a0
f01020b3:	e8 e8 df ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01020b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020bb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020c1:	83 ec 0c             	sub    $0xc,%esp
f01020c4:	50                   	push   %eax
f01020c5:	e8 63 ee ff ff       	call   f0100f2d <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020ca:	83 c4 0c             	add    $0xc,%esp
f01020cd:	6a 01                	push   $0x1
f01020cf:	68 00 10 40 00       	push   $0x401000
f01020d4:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01020da:	e8 b0 ee ff ff       	call   f0100f8f <pgdir_walk>
f01020df:	89 c7                	mov    %eax,%edi
f01020e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020e4:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020e9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020ec:	8b 40 04             	mov    0x4(%eax),%eax
f01020ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020f4:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f01020fa:	89 c2                	mov    %eax,%edx
f01020fc:	c1 ea 0c             	shr    $0xc,%edx
f01020ff:	83 c4 10             	add    $0x10,%esp
f0102102:	39 ca                	cmp    %ecx,%edx
f0102104:	72 15                	jb     f010211b <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102106:	50                   	push   %eax
f0102107:	68 3c 4a 10 f0       	push   $0xf0104a3c
f010210c:	68 b3 03 00 00       	push   $0x3b3
f0102111:	68 a0 47 10 f0       	push   $0xf01047a0
f0102116:	e8 85 df ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010211b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102120:	39 c7                	cmp    %eax,%edi
f0102122:	74 19                	je     f010213d <mem_init+0xfb8>
f0102124:	68 c3 49 10 f0       	push   $0xf01049c3
f0102129:	68 c6 47 10 f0       	push   $0xf01047c6
f010212e:	68 b4 03 00 00       	push   $0x3b4
f0102133:	68 a0 47 10 f0       	push   $0xf01047a0
f0102138:	e8 63 df ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010213d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102140:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102147:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102150:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102156:	c1 f8 03             	sar    $0x3,%eax
f0102159:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010215c:	89 c2                	mov    %eax,%edx
f010215e:	c1 ea 0c             	shr    $0xc,%edx
f0102161:	39 d1                	cmp    %edx,%ecx
f0102163:	77 12                	ja     f0102177 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102165:	50                   	push   %eax
f0102166:	68 3c 4a 10 f0       	push   $0xf0104a3c
f010216b:	6a 5b                	push   $0x5b
f010216d:	68 ac 47 10 f0       	push   $0xf01047ac
f0102172:	e8 29 df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102177:	83 ec 04             	sub    $0x4,%esp
f010217a:	68 00 10 00 00       	push   $0x1000
f010217f:	68 ff 00 00 00       	push   $0xff
f0102184:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102189:	50                   	push   %eax
f010218a:	e8 f3 1a 00 00       	call   f0103c82 <memset>
	page_free(pp0);
f010218f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102192:	89 3c 24             	mov    %edi,(%esp)
f0102195:	e8 93 ed ff ff       	call   f0100f2d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010219a:	83 c4 0c             	add    $0xc,%esp
f010219d:	6a 01                	push   $0x1
f010219f:	6a 00                	push   $0x0
f01021a1:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01021a7:	e8 e3 ed ff ff       	call   f0100f8f <pgdir_walk>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01021ac:	89 fa                	mov    %edi,%edx
f01021ae:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f01021b4:	c1 fa 03             	sar    $0x3,%edx
f01021b7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021ba:	89 d0                	mov    %edx,%eax
f01021bc:	c1 e8 0c             	shr    $0xc,%eax
f01021bf:	83 c4 10             	add    $0x10,%esp
f01021c2:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f01021c8:	72 12                	jb     f01021dc <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021ca:	52                   	push   %edx
f01021cb:	68 3c 4a 10 f0       	push   $0xf0104a3c
f01021d0:	6a 5b                	push   $0x5b
f01021d2:	68 ac 47 10 f0       	push   $0xf01047ac
f01021d7:	e8 c4 de ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01021dc:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f01021e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021e5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021eb:	f6 00 01             	testb  $0x1,(%eax)
f01021ee:	74 19                	je     f0102209 <mem_init+0x1084>
f01021f0:	68 db 49 10 f0       	push   $0xf01049db
f01021f5:	68 c6 47 10 f0       	push   $0xf01047c6
f01021fa:	68 be 03 00 00       	push   $0x3be
f01021ff:	68 a0 47 10 f0       	push   $0xf01047a0
f0102204:	e8 97 de ff ff       	call   f01000a0 <_panic>
f0102209:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f010220c:	39 c2                	cmp    %eax,%edx
f010220e:	75 db                	jne    f01021eb <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102210:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102215:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010221b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010221e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102224:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102227:	89 3d 3c be 17 f0    	mov    %edi,0xf017be3c

	// free the pages we took
	page_free(pp0);
f010222d:	83 ec 0c             	sub    $0xc,%esp
f0102230:	50                   	push   %eax
f0102231:	e8 f7 ec ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f0102236:	89 1c 24             	mov    %ebx,(%esp)
f0102239:	e8 ef ec ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f010223e:	89 34 24             	mov    %esi,(%esp)
f0102241:	e8 e7 ec ff ff       	call   f0100f2d <page_free>

	cprintf("check_page() succeeded!\n");
f0102246:	c7 04 24 f2 49 10 f0 	movl   $0xf01049f2,(%esp)
f010224d:	e8 fc 0a 00 00       	call   f0102d4e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	// 映射 upages,upages+ptsize 到pages，pages+ptsize上
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102252:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102257:	83 c4 10             	add    $0x10,%esp
f010225a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010225f:	77 15                	ja     f0102276 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102261:	50                   	push   %eax
f0102262:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0102267:	68 bc 00 00 00       	push   $0xbc
f010226c:	68 a0 47 10 f0       	push   $0xf01047a0
f0102271:	e8 2a de ff ff       	call   f01000a0 <_panic>
f0102276:	83 ec 08             	sub    $0x8,%esp
f0102279:	6a 04                	push   $0x4
f010227b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102280:	50                   	push   %eax
f0102281:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102286:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010228b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102290:	e8 8e ed ff ff       	call   f0101023 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102295:	a1 48 be 17 f0       	mov    0xf017be48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010229a:	83 c4 10             	add    $0x10,%esp
f010229d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022a2:	77 15                	ja     f01022b9 <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022a4:	50                   	push   %eax
f01022a5:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01022aa:	68 c5 00 00 00       	push   $0xc5
f01022af:	68 a0 47 10 f0       	push   $0xf01047a0
f01022b4:	e8 e7 dd ff ff       	call   f01000a0 <_panic>
f01022b9:	83 ec 08             	sub    $0x8,%esp
f01022bc:	6a 04                	push   $0x4
f01022be:	05 00 00 00 10       	add    $0x10000000,%eax
f01022c3:	50                   	push   %eax
f01022c4:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01022c9:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01022ce:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01022d3:	e8 4b ed ff ff       	call   f0101023 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022d8:	83 c4 10             	add    $0x10,%esp
f01022db:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01022e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022e5:	77 15                	ja     f01022fc <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022e7:	50                   	push   %eax
f01022e8:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01022ed:	68 d1 00 00 00       	push   $0xd1
f01022f2:	68 a0 47 10 f0       	push   $0xf01047a0
f01022f7:	e8 a4 dd ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01022fc:	83 ec 08             	sub    $0x8,%esp
f01022ff:	6a 02                	push   $0x2
f0102301:	68 00 00 11 00       	push   $0x110000
f0102306:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010230b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102310:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102315:	e8 09 ed ff ff       	call   f0101023 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010231a:	83 c4 08             	add    $0x8,%esp
f010231d:	6a 02                	push   $0x2
f010231f:	6a 00                	push   $0x0
f0102321:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102326:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010232b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102330:	e8 ee ec ff ff       	call   f0101023 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102335:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f010233b:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0102340:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102343:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010234a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010234f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102352:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102358:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010235b:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010235e:	be 00 00 00 00       	mov    $0x0,%esi
f0102363:	eb 55                	jmp    f01023ba <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102365:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010236b:	89 d8                	mov    %ebx,%eax
f010236d:	e8 7b e7 ff ff       	call   f0100aed <check_va2pa>
f0102372:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102379:	77 15                	ja     f0102390 <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010237b:	57                   	push   %edi
f010237c:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0102381:	68 f8 02 00 00       	push   $0x2f8
f0102386:	68 a0 47 10 f0       	push   $0xf01047a0
f010238b:	e8 10 dd ff ff       	call   f01000a0 <_panic>
f0102390:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102397:	39 d0                	cmp    %edx,%eax
f0102399:	74 19                	je     f01023b4 <mem_init+0x122f>
f010239b:	68 54 50 10 f0       	push   $0xf0105054
f01023a0:	68 c6 47 10 f0       	push   $0xf01047c6
f01023a5:	68 f8 02 00 00       	push   $0x2f8
f01023aa:	68 a0 47 10 f0       	push   $0xf01047a0
f01023af:	e8 ec dc ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01023b4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023ba:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01023bd:	77 a6                	ja     f0102365 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01023bf:	8b 3d 48 be 17 f0    	mov    0xf017be48,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023c5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01023c8:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01023cd:	89 f2                	mov    %esi,%edx
f01023cf:	89 d8                	mov    %ebx,%eax
f01023d1:	e8 17 e7 ff ff       	call   f0100aed <check_va2pa>
f01023d6:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01023dd:	77 15                	ja     f01023f4 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023df:	57                   	push   %edi
f01023e0:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01023e5:	68 fd 02 00 00       	push   $0x2fd
f01023ea:	68 a0 47 10 f0       	push   $0xf01047a0
f01023ef:	e8 ac dc ff ff       	call   f01000a0 <_panic>
f01023f4:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01023fb:	39 c2                	cmp    %eax,%edx
f01023fd:	74 19                	je     f0102418 <mem_init+0x1293>
f01023ff:	68 88 50 10 f0       	push   $0xf0105088
f0102404:	68 c6 47 10 f0       	push   $0xf01047c6
f0102409:	68 fd 02 00 00       	push   $0x2fd
f010240e:	68 a0 47 10 f0       	push   $0xf01047a0
f0102413:	e8 88 dc ff ff       	call   f01000a0 <_panic>
f0102418:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010241e:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102424:	75 a7                	jne    f01023cd <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102426:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102429:	c1 e7 0c             	shl    $0xc,%edi
f010242c:	be 00 00 00 00       	mov    $0x0,%esi
f0102431:	eb 30                	jmp    f0102463 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102433:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102439:	89 d8                	mov    %ebx,%eax
f010243b:	e8 ad e6 ff ff       	call   f0100aed <check_va2pa>
f0102440:	39 c6                	cmp    %eax,%esi
f0102442:	74 19                	je     f010245d <mem_init+0x12d8>
f0102444:	68 bc 50 10 f0       	push   $0xf01050bc
f0102449:	68 c6 47 10 f0       	push   $0xf01047c6
f010244e:	68 01 03 00 00       	push   $0x301
f0102453:	68 a0 47 10 f0       	push   $0xf01047a0
f0102458:	e8 43 dc ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010245d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102463:	39 fe                	cmp    %edi,%esi
f0102465:	72 cc                	jb     f0102433 <mem_init+0x12ae>
f0102467:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010246c:	89 f2                	mov    %esi,%edx
f010246e:	89 d8                	mov    %ebx,%eax
f0102470:	e8 78 e6 ff ff       	call   f0100aed <check_va2pa>
f0102475:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f010247b:	39 c2                	cmp    %eax,%edx
f010247d:	74 19                	je     f0102498 <mem_init+0x1313>
f010247f:	68 e4 50 10 f0       	push   $0xf01050e4
f0102484:	68 c6 47 10 f0       	push   $0xf01047c6
f0102489:	68 05 03 00 00       	push   $0x305
f010248e:	68 a0 47 10 f0       	push   $0xf01047a0
f0102493:	e8 08 dc ff ff       	call   f01000a0 <_panic>
f0102498:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010249e:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01024a4:	75 c6                	jne    f010246c <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01024a6:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01024ab:	89 d8                	mov    %ebx,%eax
f01024ad:	e8 3b e6 ff ff       	call   f0100aed <check_va2pa>
f01024b2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024b5:	74 51                	je     f0102508 <mem_init+0x1383>
f01024b7:	68 2c 51 10 f0       	push   $0xf010512c
f01024bc:	68 c6 47 10 f0       	push   $0xf01047c6
f01024c1:	68 06 03 00 00       	push   $0x306
f01024c6:	68 a0 47 10 f0       	push   $0xf01047a0
f01024cb:	e8 d0 db ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f01024d0:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01024d5:	72 36                	jb     f010250d <mem_init+0x1388>
f01024d7:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01024dc:	76 07                	jbe    f01024e5 <mem_init+0x1360>
f01024de:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01024e3:	75 28                	jne    f010250d <mem_init+0x1388>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01024e5:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01024e9:	0f 85 83 00 00 00    	jne    f0102572 <mem_init+0x13ed>
f01024ef:	68 0b 4a 10 f0       	push   $0xf0104a0b
f01024f4:	68 c6 47 10 f0       	push   $0xf01047c6
f01024f9:	68 11 03 00 00       	push   $0x311
f01024fe:	68 a0 47 10 f0       	push   $0xf01047a0
f0102503:	e8 98 db ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102508:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE))
f010250d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102512:	76 3f                	jbe    f0102553 <mem_init+0x13ce>
			{
				assert(pgdir[i] & PTE_P);
f0102514:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102517:	f6 c2 01             	test   $0x1,%dl
f010251a:	75 19                	jne    f0102535 <mem_init+0x13b0>
f010251c:	68 0b 4a 10 f0       	push   $0xf0104a0b
f0102521:	68 c6 47 10 f0       	push   $0xf01047c6
f0102526:	68 16 03 00 00       	push   $0x316
f010252b:	68 a0 47 10 f0       	push   $0xf01047a0
f0102530:	e8 6b db ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102535:	f6 c2 02             	test   $0x2,%dl
f0102538:	75 38                	jne    f0102572 <mem_init+0x13ed>
f010253a:	68 1c 4a 10 f0       	push   $0xf0104a1c
f010253f:	68 c6 47 10 f0       	push   $0xf01047c6
f0102544:	68 17 03 00 00       	push   $0x317
f0102549:	68 a0 47 10 f0       	push   $0xf01047a0
f010254e:	e8 4d db ff ff       	call   f01000a0 <_panic>
			}
			else
				assert(pgdir[i] == 0);
f0102553:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102557:	74 19                	je     f0102572 <mem_init+0x13ed>
f0102559:	68 2d 4a 10 f0       	push   $0xf0104a2d
f010255e:	68 c6 47 10 f0       	push   $0xf01047c6
f0102563:	68 1a 03 00 00       	push   $0x31a
f0102568:	68 a0 47 10 f0       	push   $0xf01047a0
f010256d:	e8 2e db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102572:	83 c0 01             	add    $0x1,%eax
f0102575:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010257a:	0f 86 50 ff ff ff    	jbe    f01024d0 <mem_init+0x134b>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102580:	83 ec 0c             	sub    $0xc,%esp
f0102583:	68 5c 51 10 f0       	push   $0xf010515c
f0102588:	e8 c1 07 00 00       	call   f0102d4e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010258d:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102592:	83 c4 10             	add    $0x10,%esp
f0102595:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010259a:	77 15                	ja     f01025b1 <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010259c:	50                   	push   %eax
f010259d:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01025a2:	68 e5 00 00 00       	push   $0xe5
f01025a7:	68 a0 47 10 f0       	push   $0xf01047a0
f01025ac:	e8 ef da ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01025b1:	05 00 00 00 10       	add    $0x10000000,%eax
f01025b6:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01025b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01025be:	e8 8e e5 ff ff       	call   f0100b51 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01025c3:	0f 20 c0             	mov    %cr0,%eax
f01025c6:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01025c9:	0d 23 00 05 80       	or     $0x80050023,%eax
f01025ce:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01025d1:	83 ec 0c             	sub    $0xc,%esp
f01025d4:	6a 00                	push   $0x0
f01025d6:	e8 e2 e8 ff ff       	call   f0100ebd <page_alloc>
f01025db:	89 c3                	mov    %eax,%ebx
f01025dd:	83 c4 10             	add    $0x10,%esp
f01025e0:	85 c0                	test   %eax,%eax
f01025e2:	75 19                	jne    f01025fd <mem_init+0x1478>
f01025e4:	68 80 48 10 f0       	push   $0xf0104880
f01025e9:	68 c6 47 10 f0       	push   $0xf01047c6
f01025ee:	68 d9 03 00 00       	push   $0x3d9
f01025f3:	68 a0 47 10 f0       	push   $0xf01047a0
f01025f8:	e8 a3 da ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01025fd:	83 ec 0c             	sub    $0xc,%esp
f0102600:	6a 00                	push   $0x0
f0102602:	e8 b6 e8 ff ff       	call   f0100ebd <page_alloc>
f0102607:	89 c7                	mov    %eax,%edi
f0102609:	83 c4 10             	add    $0x10,%esp
f010260c:	85 c0                	test   %eax,%eax
f010260e:	75 19                	jne    f0102629 <mem_init+0x14a4>
f0102610:	68 96 48 10 f0       	push   $0xf0104896
f0102615:	68 c6 47 10 f0       	push   $0xf01047c6
f010261a:	68 da 03 00 00       	push   $0x3da
f010261f:	68 a0 47 10 f0       	push   $0xf01047a0
f0102624:	e8 77 da ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102629:	83 ec 0c             	sub    $0xc,%esp
f010262c:	6a 00                	push   $0x0
f010262e:	e8 8a e8 ff ff       	call   f0100ebd <page_alloc>
f0102633:	89 c6                	mov    %eax,%esi
f0102635:	83 c4 10             	add    $0x10,%esp
f0102638:	85 c0                	test   %eax,%eax
f010263a:	75 19                	jne    f0102655 <mem_init+0x14d0>
f010263c:	68 ac 48 10 f0       	push   $0xf01048ac
f0102641:	68 c6 47 10 f0       	push   $0xf01047c6
f0102646:	68 db 03 00 00       	push   $0x3db
f010264b:	68 a0 47 10 f0       	push   $0xf01047a0
f0102650:	e8 4b da ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102655:	83 ec 0c             	sub    $0xc,%esp
f0102658:	53                   	push   %ebx
f0102659:	e8 cf e8 ff ff       	call   f0100f2d <page_free>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010265e:	89 f8                	mov    %edi,%eax
f0102660:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102666:	c1 f8 03             	sar    $0x3,%eax
f0102669:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010266c:	89 c2                	mov    %eax,%edx
f010266e:	c1 ea 0c             	shr    $0xc,%edx
f0102671:	83 c4 10             	add    $0x10,%esp
f0102674:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010267a:	72 12                	jb     f010268e <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010267c:	50                   	push   %eax
f010267d:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0102682:	6a 5b                	push   $0x5b
f0102684:	68 ac 47 10 f0       	push   $0xf01047ac
f0102689:	e8 12 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010268e:	83 ec 04             	sub    $0x4,%esp
f0102691:	68 00 10 00 00       	push   $0x1000
f0102696:	6a 01                	push   $0x1
f0102698:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010269d:	50                   	push   %eax
f010269e:	e8 df 15 00 00       	call   f0103c82 <memset>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01026a3:	89 f0                	mov    %esi,%eax
f01026a5:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01026ab:	c1 f8 03             	sar    $0x3,%eax
f01026ae:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026b1:	89 c2                	mov    %eax,%edx
f01026b3:	c1 ea 0c             	shr    $0xc,%edx
f01026b6:	83 c4 10             	add    $0x10,%esp
f01026b9:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01026bf:	72 12                	jb     f01026d3 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026c1:	50                   	push   %eax
f01026c2:	68 3c 4a 10 f0       	push   $0xf0104a3c
f01026c7:	6a 5b                	push   $0x5b
f01026c9:	68 ac 47 10 f0       	push   $0xf01047ac
f01026ce:	e8 cd d9 ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01026d3:	83 ec 04             	sub    $0x4,%esp
f01026d6:	68 00 10 00 00       	push   $0x1000
f01026db:	6a 02                	push   $0x2
f01026dd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01026e2:	50                   	push   %eax
f01026e3:	e8 9a 15 00 00       	call   f0103c82 <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f01026e8:	6a 02                	push   $0x2
f01026ea:	68 00 10 00 00       	push   $0x1000
f01026ef:	57                   	push   %edi
f01026f0:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01026f6:	e8 24 ea ff ff       	call   f010111f <page_insert>
	assert(pp1->pp_ref == 1);
f01026fb:	83 c4 20             	add    $0x20,%esp
f01026fe:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102703:	74 19                	je     f010271e <mem_init+0x1599>
f0102705:	68 26 49 10 f0       	push   $0xf0104926
f010270a:	68 c6 47 10 f0       	push   $0xf01047c6
f010270f:	68 e0 03 00 00       	push   $0x3e0
f0102714:	68 a0 47 10 f0       	push   $0xf01047a0
f0102719:	e8 82 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010271e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102725:	01 01 01 
f0102728:	74 19                	je     f0102743 <mem_init+0x15be>
f010272a:	68 7c 51 10 f0       	push   $0xf010517c
f010272f:	68 c6 47 10 f0       	push   $0xf01047c6
f0102734:	68 e1 03 00 00       	push   $0x3e1
f0102739:	68 a0 47 10 f0       	push   $0xf01047a0
f010273e:	e8 5d d9 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f0102743:	6a 02                	push   $0x2
f0102745:	68 00 10 00 00       	push   $0x1000
f010274a:	56                   	push   %esi
f010274b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102751:	e8 c9 e9 ff ff       	call   f010111f <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102756:	83 c4 10             	add    $0x10,%esp
f0102759:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102760:	02 02 02 
f0102763:	74 19                	je     f010277e <mem_init+0x15f9>
f0102765:	68 a0 51 10 f0       	push   $0xf01051a0
f010276a:	68 c6 47 10 f0       	push   $0xf01047c6
f010276f:	68 e3 03 00 00       	push   $0x3e3
f0102774:	68 a0 47 10 f0       	push   $0xf01047a0
f0102779:	e8 22 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010277e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102783:	74 19                	je     f010279e <mem_init+0x1619>
f0102785:	68 48 49 10 f0       	push   $0xf0104948
f010278a:	68 c6 47 10 f0       	push   $0xf01047c6
f010278f:	68 e4 03 00 00       	push   $0x3e4
f0102794:	68 a0 47 10 f0       	push   $0xf01047a0
f0102799:	e8 02 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010279e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01027a3:	74 19                	je     f01027be <mem_init+0x1639>
f01027a5:	68 b2 49 10 f0       	push   $0xf01049b2
f01027aa:	68 c6 47 10 f0       	push   $0xf01047c6
f01027af:	68 e5 03 00 00       	push   $0x3e5
f01027b4:	68 a0 47 10 f0       	push   $0xf01047a0
f01027b9:	e8 e2 d8 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01027be:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01027c5:	03 03 03 

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01027c8:	89 f0                	mov    %esi,%eax
f01027ca:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01027d0:	c1 f8 03             	sar    $0x3,%eax
f01027d3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027d6:	89 c2                	mov    %eax,%edx
f01027d8:	c1 ea 0c             	shr    $0xc,%edx
f01027db:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01027e1:	72 12                	jb     f01027f5 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027e3:	50                   	push   %eax
f01027e4:	68 3c 4a 10 f0       	push   $0xf0104a3c
f01027e9:	6a 5b                	push   $0x5b
f01027eb:	68 ac 47 10 f0       	push   $0xf01047ac
f01027f0:	e8 ab d8 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01027f5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01027fc:	03 03 03 
f01027ff:	74 19                	je     f010281a <mem_init+0x1695>
f0102801:	68 c4 51 10 f0       	push   $0xf01051c4
f0102806:	68 c6 47 10 f0       	push   $0xf01047c6
f010280b:	68 e7 03 00 00       	push   $0x3e7
f0102810:	68 a0 47 10 f0       	push   $0xf01047a0
f0102815:	e8 86 d8 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f010281a:	83 ec 08             	sub    $0x8,%esp
f010281d:	68 00 10 00 00       	push   $0x1000
f0102822:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102828:	e8 b0 e8 ff ff       	call   f01010dd <page_remove>
	assert(pp2->pp_ref == 0);
f010282d:	83 c4 10             	add    $0x10,%esp
f0102830:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102835:	74 19                	je     f0102850 <mem_init+0x16cb>
f0102837:	68 80 49 10 f0       	push   $0xf0104980
f010283c:	68 c6 47 10 f0       	push   $0xf01047c6
f0102841:	68 e9 03 00 00       	push   $0x3e9
f0102846:	68 a0 47 10 f0       	push   $0xf01047a0
f010284b:	e8 50 d8 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102850:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0102856:	8b 11                	mov    (%ecx),%edx
f0102858:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010285e:	89 d8                	mov    %ebx,%eax
f0102860:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102866:	c1 f8 03             	sar    $0x3,%eax
f0102869:	c1 e0 0c             	shl    $0xc,%eax
f010286c:	39 c2                	cmp    %eax,%edx
f010286e:	74 19                	je     f0102889 <mem_init+0x1704>
f0102870:	68 d0 4c 10 f0       	push   $0xf0104cd0
f0102875:	68 c6 47 10 f0       	push   $0xf01047c6
f010287a:	68 ec 03 00 00       	push   $0x3ec
f010287f:	68 a0 47 10 f0       	push   $0xf01047a0
f0102884:	e8 17 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102889:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010288f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102894:	74 19                	je     f01028af <mem_init+0x172a>
f0102896:	68 37 49 10 f0       	push   $0xf0104937
f010289b:	68 c6 47 10 f0       	push   $0xf01047c6
f01028a0:	68 ee 03 00 00       	push   $0x3ee
f01028a5:	68 a0 47 10 f0       	push   $0xf01047a0
f01028aa:	e8 f1 d7 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01028af:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01028b5:	83 ec 0c             	sub    $0xc,%esp
f01028b8:	53                   	push   %ebx
f01028b9:	e8 6f e6 ff ff       	call   f0100f2d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01028be:	c7 04 24 f0 51 10 f0 	movl   $0xf01051f0,(%esp)
f01028c5:	e8 84 04 00 00       	call   f0102d4e <cprintf>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01028ca:	83 c4 10             	add    $0x10,%esp
f01028cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028d0:	5b                   	pop    %ebx
f01028d1:	5e                   	pop    %esi
f01028d2:	5f                   	pop    %edi
f01028d3:	5d                   	pop    %ebp
f01028d4:	c3                   	ret    

f01028d5 <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f01028d5:	55                   	push   %ebp
f01028d6:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01028d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028db:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01028de:	5d                   	pop    %ebp
f01028df:	c3                   	ret    

f01028e0 <user_mem_check>:
//
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01028e0:	55                   	push   %ebp
f01028e1:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01028e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01028e8:	5d                   	pop    %ebp
f01028e9:	c3                   	ret    

f01028ea <user_mem_assert>:
// If it can, then the function simply returns.
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01028ea:	55                   	push   %ebp
f01028eb:	89 e5                	mov    %esp,%ebp
		cprintf("[%08x] user_mem_check assertion failure for "
				"va %08x\n",
				env->env_id, user_mem_check_addr);
		env_destroy(env); // may not return
	}
}
f01028ed:	5d                   	pop    %ebp
f01028ee:	c3                   	ret    

f01028ef <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028ef:	55                   	push   %ebp
f01028f0:	89 e5                	mov    %esp,%ebp
f01028f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01028f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0)
f01028f8:	85 d2                	test   %edx,%edx
f01028fa:	75 11                	jne    f010290d <envid2env+0x1e>
	{
		*env_store = curenv;
f01028fc:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102901:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102904:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102906:	b8 00 00 00 00       	mov    $0x0,%eax
f010290b:	eb 5e                	jmp    f010296b <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010290d:	89 d0                	mov    %edx,%eax
f010290f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102914:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102917:	c1 e0 05             	shl    $0x5,%eax
f010291a:	03 05 48 be 17 f0    	add    0xf017be48,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid)
f0102920:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102924:	74 05                	je     f010292b <envid2env+0x3c>
f0102926:	3b 50 48             	cmp    0x48(%eax),%edx
f0102929:	74 10                	je     f010293b <envid2env+0x4c>
	{
		*env_store = 0;
f010292b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010292e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102934:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102939:	eb 30                	jmp    f010296b <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id)
f010293b:	84 c9                	test   %cl,%cl
f010293d:	74 22                	je     f0102961 <envid2env+0x72>
f010293f:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102945:	39 d0                	cmp    %edx,%eax
f0102947:	74 18                	je     f0102961 <envid2env+0x72>
f0102949:	8b 4a 48             	mov    0x48(%edx),%ecx
f010294c:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010294f:	74 10                	je     f0102961 <envid2env+0x72>
	{
		*env_store = 0;
f0102951:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102954:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010295a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010295f:	eb 0a                	jmp    f010296b <envid2env+0x7c>
	}

	*env_store = e;
f0102961:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102964:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102966:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010296b:	5d                   	pop    %ebp
f010296c:	c3                   	ret    

f010296d <env_init>:
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void env_init(void)
{
f010296d:	55                   	push   %ebp
f010296e:	89 e5                	mov    %esp,%ebp
	}
	envs[NENV - 1].env_id = 0;
	envs[NENV - 2].env_link = &envs[NENV - 1];
	// Per-CPU part of the initialization
	env_init_percpu(); */
}
f0102970:	5d                   	pop    %ebp
f0102971:	c3                   	ret    

f0102972 <env_init_percpu>:

// Load GDT and segment descriptors.
void env_init_percpu(void)
{
f0102972:	55                   	push   %ebp
f0102973:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102975:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f010297a:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" ::"a"(GD_UD | 3));
f010297d:	b8 23 00 00 00       	mov    $0x23,%eax
f0102982:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" ::"a"(GD_UD | 3));
f0102984:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" ::"a"(GD_KD));
f0102986:	b8 10 00 00 00       	mov    $0x10,%eax
f010298b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" ::"a"(GD_KD));
f010298d:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" ::"a"(GD_KD));
f010298f:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" ::"i"(GD_KT));
f0102991:	ea 98 29 10 f0 08 00 	ljmp   $0x8,$0xf0102998
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102998:	b8 00 00 00 00       	mov    $0x0,%eax
f010299d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01029a0:	5d                   	pop    %ebp
f01029a1:	c3                   	ret    

f01029a2 <env_alloc>:
// Returns 0 on success, < 0 on failure.  Errors include:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029a2:	55                   	push   %ebp
f01029a3:	89 e5                	mov    %esp,%ebp
f01029a5:	53                   	push   %ebx
f01029a6:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029a9:	8b 1d 4c be 17 f0    	mov    0xf017be4c,%ebx
f01029af:	85 db                	test   %ebx,%ebx
f01029b1:	0f 84 f4 00 00 00    	je     f0102aab <env_alloc+0x109>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029b7:	83 ec 0c             	sub    $0xc,%esp
f01029ba:	6a 01                	push   $0x1
f01029bc:	e8 fc e4 ff ff       	call   f0100ebd <page_alloc>
f01029c1:	83 c4 10             	add    $0x10,%esp
f01029c4:	85 c0                	test   %eax,%eax
f01029c6:	0f 84 e6 00 00 00    	je     f0102ab2 <env_alloc+0x110>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029cc:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029d4:	77 15                	ja     f01029eb <env_alloc+0x49>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d6:	50                   	push   %eax
f01029d7:	68 1c 4b 10 f0       	push   $0xf0104b1c
f01029dc:	68 c0 00 00 00       	push   $0xc0
f01029e1:	68 52 52 10 f0       	push   $0xf0105252
f01029e6:	e8 b5 d6 ff ff       	call   f01000a0 <_panic>
f01029eb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029f1:	83 ca 05             	or     $0x5,%edx
f01029f4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029fa:	8b 43 48             	mov    0x48(%ebx),%eax
f01029fd:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0) // Don't create a negative env_id.
f0102a02:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a07:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a0c:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a0f:	89 da                	mov    %ebx,%edx
f0102a11:	2b 15 48 be 17 f0    	sub    0xf017be48,%edx
f0102a17:	c1 fa 05             	sar    $0x5,%edx
f0102a1a:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a20:	09 d0                	or     %edx,%eax
f0102a22:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a25:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a28:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a2b:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a32:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a39:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a40:	83 ec 04             	sub    $0x4,%esp
f0102a43:	6a 44                	push   $0x44
f0102a45:	6a 00                	push   $0x0
f0102a47:	53                   	push   %ebx
f0102a48:	e8 35 12 00 00       	call   f0103c82 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a4d:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a53:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a59:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a5f:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a66:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a6c:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a6f:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	*newenv_store = e;
f0102a74:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a77:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a79:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a7c:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102a81:	83 c4 10             	add    $0x10,%esp
f0102a84:	85 c0                	test   %eax,%eax
f0102a86:	74 05                	je     f0102a8d <env_alloc+0xeb>
f0102a88:	8b 40 48             	mov    0x48(%eax),%eax
f0102a8b:	eb 05                	jmp    f0102a92 <env_alloc+0xf0>
f0102a8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a92:	83 ec 04             	sub    $0x4,%esp
f0102a95:	52                   	push   %edx
f0102a96:	50                   	push   %eax
f0102a97:	68 5d 52 10 f0       	push   $0xf010525d
f0102a9c:	e8 ad 02 00 00       	call   f0102d4e <cprintf>
	return 0;
f0102aa1:	83 c4 10             	add    $0x10,%esp
f0102aa4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aa9:	eb 0c                	jmp    f0102ab7 <env_alloc+0x115>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102aab:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102ab0:	eb 05                	jmp    f0102ab7 <env_alloc+0x115>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102ab2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102ab7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102aba:	c9                   	leave  
f0102abb:	c3                   	ret    

f0102abc <env_create>:
// This function is ONLY called during kernel initialization,
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void env_create(uint8_t *binary, enum EnvType type)
{
f0102abc:	55                   	push   %ebp
f0102abd:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102abf:	5d                   	pop    %ebp
f0102ac0:	c3                   	ret    

f0102ac1 <env_free>:

//
// Frees env e and all memory it uses.
//
void env_free(struct Env *e)
{
f0102ac1:	55                   	push   %ebp
f0102ac2:	89 e5                	mov    %esp,%ebp
f0102ac4:	57                   	push   %edi
f0102ac5:	56                   	push   %esi
f0102ac6:	53                   	push   %ebx
f0102ac7:	83 ec 1c             	sub    $0x1c,%esp
f0102aca:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102acd:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102ad3:	39 fa                	cmp    %edi,%edx
f0102ad5:	75 29                	jne    f0102b00 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102ad7:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102adc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ae1:	77 15                	ja     f0102af8 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ae3:	50                   	push   %eax
f0102ae4:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0102ae9:	68 6c 01 00 00       	push   $0x16c
f0102aee:	68 52 52 10 f0       	push   $0xf0105252
f0102af3:	e8 a8 d5 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102af8:	05 00 00 00 10       	add    $0x10000000,%eax
f0102afd:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b00:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102b03:	85 d2                	test   %edx,%edx
f0102b05:	74 05                	je     f0102b0c <env_free+0x4b>
f0102b07:	8b 42 48             	mov    0x48(%edx),%eax
f0102b0a:	eb 05                	jmp    f0102b11 <env_free+0x50>
f0102b0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b11:	83 ec 04             	sub    $0x4,%esp
f0102b14:	51                   	push   %ecx
f0102b15:	50                   	push   %eax
f0102b16:	68 72 52 10 f0       	push   $0xf0105272
f0102b1b:	e8 2e 02 00 00       	call   f0102d4e <cprintf>
f0102b20:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++)
f0102b23:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102b2a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b2d:	89 d0                	mov    %edx,%eax
f0102b2f:	c1 e0 02             	shl    $0x2,%eax
f0102b32:	89 45 dc             	mov    %eax,-0x24(%ebp)
	{

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102b35:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b38:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102b3b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102b41:	0f 84 a8 00 00 00    	je     f0102bef <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102b47:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b4d:	89 f0                	mov    %esi,%eax
f0102b4f:	c1 e8 0c             	shr    $0xc,%eax
f0102b52:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b55:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102b5b:	77 15                	ja     f0102b72 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b5d:	56                   	push   %esi
f0102b5e:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0102b63:	68 7c 01 00 00       	push   $0x17c
f0102b68:	68 52 52 10 f0       	push   $0xf0105252
f0102b6d:	e8 2e d5 ff ff       	call   f01000a0 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
		{
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b75:	c1 e0 16             	shl    $0x16,%eax
f0102b78:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *)KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
f0102b7b:	bb 00 00 00 00       	mov    $0x0,%ebx
		{
			if (pt[pteno] & PTE_P)
f0102b80:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102b87:	01 
f0102b88:	74 17                	je     f0102ba1 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b8a:	83 ec 08             	sub    $0x8,%esp
f0102b8d:	89 d8                	mov    %ebx,%eax
f0102b8f:	c1 e0 0c             	shl    $0xc,%eax
f0102b92:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102b95:	50                   	push   %eax
f0102b96:	ff 77 5c             	pushl  0x5c(%edi)
f0102b99:	e8 3f e5 ff ff       	call   f01010dd <page_remove>
f0102b9e:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *)KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++)
f0102ba1:	83 c3 01             	add    $0x1,%ebx
f0102ba4:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102baa:	75 d4                	jne    f0102b80 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102bac:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102baf:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102bb2:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bb9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102bbc:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102bc2:	72 14                	jb     f0102bd8 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102bc4:	83 ec 04             	sub    $0x4,%esp
f0102bc7:	68 40 4b 10 f0       	push   $0xf0104b40
f0102bcc:	6a 54                	push   $0x54
f0102bce:	68 ac 47 10 f0       	push   $0xf01047ac
f0102bd3:	e8 c8 d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102bd8:	83 ec 0c             	sub    $0xc,%esp
f0102bdb:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102be0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102be3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102be6:	50                   	push   %eax
f0102be7:	e8 7c e3 ff ff       	call   f0100f68 <page_decref>
f0102bec:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++)
f0102bef:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102bf3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bf6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102bfb:	0f 85 29 ff ff ff    	jne    f0102b2a <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102c01:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c04:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c09:	77 15                	ja     f0102c20 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c0b:	50                   	push   %eax
f0102c0c:	68 1c 4b 10 f0       	push   $0xf0104b1c
f0102c11:	68 8b 01 00 00       	push   $0x18b
f0102c16:	68 52 52 10 f0       	push   $0xf0105252
f0102c1b:	e8 80 d4 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102c20:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c27:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c2c:	c1 e8 0c             	shr    $0xc,%eax
f0102c2f:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102c35:	72 14                	jb     f0102c4b <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102c37:	83 ec 04             	sub    $0x4,%esp
f0102c3a:	68 40 4b 10 f0       	push   $0xf0104b40
f0102c3f:	6a 54                	push   $0x54
f0102c41:	68 ac 47 10 f0       	push   $0xf01047ac
f0102c46:	e8 55 d4 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102c4b:	83 ec 0c             	sub    $0xc,%esp
f0102c4e:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102c54:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102c57:	50                   	push   %eax
f0102c58:	e8 0b e3 ff ff       	call   f0100f68 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102c5d:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102c64:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
f0102c69:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102c6c:	89 3d 4c be 17 f0    	mov    %edi,0xf017be4c
}
f0102c72:	83 c4 10             	add    $0x10,%esp
f0102c75:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c78:	5b                   	pop    %ebx
f0102c79:	5e                   	pop    %esi
f0102c7a:	5f                   	pop    %edi
f0102c7b:	5d                   	pop    %ebp
f0102c7c:	c3                   	ret    

f0102c7d <env_destroy>:

//
// Frees environment e.
//
void env_destroy(struct Env *e)
{
f0102c7d:	55                   	push   %ebp
f0102c7e:	89 e5                	mov    %esp,%ebp
f0102c80:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102c83:	ff 75 08             	pushl  0x8(%ebp)
f0102c86:	e8 36 fe ff ff       	call   f0102ac1 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102c8b:	c7 04 24 1c 52 10 f0 	movl   $0xf010521c,(%esp)
f0102c92:	e8 b7 00 00 00       	call   f0102d4e <cprintf>
f0102c97:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102c9a:	83 ec 0c             	sub    $0xc,%esp
f0102c9d:	6a 00                	push   $0x0
f0102c9f:	e8 99 dc ff ff       	call   f010093d <monitor>
f0102ca4:	83 c4 10             	add    $0x10,%esp
f0102ca7:	eb f1                	jmp    f0102c9a <env_destroy+0x1d>

f0102ca9 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
//
// This function does not return.
//
void env_pop_tf(struct Trapframe *tf)
{
f0102ca9:	55                   	push   %ebp
f0102caa:	89 e5                	mov    %esp,%ebp
f0102cac:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102caf:	8b 65 08             	mov    0x8(%ebp),%esp
f0102cb2:	61                   	popa   
f0102cb3:	07                   	pop    %es
f0102cb4:	1f                   	pop    %ds
f0102cb5:	83 c4 08             	add    $0x8,%esp
f0102cb8:	cf                   	iret   
					 "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
					 "\tiret"
					 :
					 : "g"(tf)
					 : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0102cb9:	68 88 52 10 f0       	push   $0xf0105288
f0102cbe:	68 b2 01 00 00       	push   $0x1b2
f0102cc3:	68 52 52 10 f0       	push   $0xf0105252
f0102cc8:	e8 d3 d3 ff ff       	call   f01000a0 <_panic>

f0102ccd <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//
// This function does not return.
//
void env_run(struct Env *e)
{
f0102ccd:	55                   	push   %ebp
f0102cce:	89 e5                	mov    %esp,%ebp
f0102cd0:	83 ec 0c             	sub    $0xc,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0102cd3:	68 94 52 10 f0       	push   $0xf0105294
f0102cd8:	68 d0 01 00 00       	push   $0x1d0
f0102cdd:	68 52 52 10 f0       	push   $0xf0105252
f0102ce2:	e8 b9 d3 ff ff       	call   f01000a0 <_panic>

f0102ce7 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ce7:	55                   	push   %ebp
f0102ce8:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cea:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cef:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102cf3:	ba 71 00 00 00       	mov    $0x71,%edx
f0102cf8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102cf9:	0f b6 c0             	movzbl %al,%eax
}
f0102cfc:	5d                   	pop    %ebp
f0102cfd:	c3                   	ret    

f0102cfe <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cfe:	55                   	push   %ebp
f0102cff:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d01:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d06:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d09:	ee                   	out    %al,(%dx)
f0102d0a:	ba 71 00 00 00       	mov    $0x71,%edx
f0102d0f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d12:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d13:	5d                   	pop    %ebp
f0102d14:	c3                   	ret    

f0102d15 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d15:	55                   	push   %ebp
f0102d16:	89 e5                	mov    %esp,%ebp
f0102d18:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102d1b:	ff 75 08             	pushl  0x8(%ebp)
f0102d1e:	e8 e4 d8 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102d23:	83 c4 10             	add    $0x10,%esp
f0102d26:	c9                   	leave  
f0102d27:	c3                   	ret    

f0102d28 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d28:	55                   	push   %ebp
f0102d29:	89 e5                	mov    %esp,%ebp
f0102d2b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102d2e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d35:	ff 75 0c             	pushl  0xc(%ebp)
f0102d38:	ff 75 08             	pushl  0x8(%ebp)
f0102d3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d3e:	50                   	push   %eax
f0102d3f:	68 15 2d 10 f0       	push   $0xf0102d15
f0102d44:	e8 ec 07 00 00       	call   f0103535 <vprintfmt>
	return cnt;
}
f0102d49:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d4c:	c9                   	leave  
f0102d4d:	c3                   	ret    

f0102d4e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d4e:	55                   	push   %ebp
f0102d4f:	89 e5                	mov    %esp,%ebp
f0102d51:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d54:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d57:	50                   	push   %eax
f0102d58:	ff 75 08             	pushl  0x8(%ebp)
f0102d5b:	e8 c8 ff ff ff       	call   f0102d28 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d60:	c9                   	leave  
f0102d61:	c3                   	ret    

f0102d62 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102d62:	55                   	push   %ebp
f0102d63:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102d65:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102d6a:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102d71:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102d74:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102d7b:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102d7d:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102d84:	67 00 
f0102d86:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102d8c:	89 c2                	mov    %eax,%edx
f0102d8e:	c1 ea 10             	shr    $0x10,%edx
f0102d91:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102d97:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102d9e:	c1 e8 18             	shr    $0x18,%eax
f0102da1:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102da6:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102dad:	b8 28 00 00 00       	mov    $0x28,%eax
f0102db2:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102db5:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102dba:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102dbd:	5d                   	pop    %ebp
f0102dbe:	c3                   	ret    

f0102dbf <trap_init>:
}


void
trap_init(void)
{
f0102dbf:	55                   	push   %ebp
f0102dc0:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102dc2:	e8 9b ff ff ff       	call   f0102d62 <trap_init_percpu>
}
f0102dc7:	5d                   	pop    %ebp
f0102dc8:	c3                   	ret    

f0102dc9 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102dc9:	55                   	push   %ebp
f0102dca:	89 e5                	mov    %esp,%ebp
f0102dcc:	53                   	push   %ebx
f0102dcd:	83 ec 0c             	sub    $0xc,%esp
f0102dd0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102dd3:	ff 33                	pushl  (%ebx)
f0102dd5:	68 b0 52 10 f0       	push   $0xf01052b0
f0102dda:	e8 6f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102ddf:	83 c4 08             	add    $0x8,%esp
f0102de2:	ff 73 04             	pushl  0x4(%ebx)
f0102de5:	68 bf 52 10 f0       	push   $0xf01052bf
f0102dea:	e8 5f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102def:	83 c4 08             	add    $0x8,%esp
f0102df2:	ff 73 08             	pushl  0x8(%ebx)
f0102df5:	68 ce 52 10 f0       	push   $0xf01052ce
f0102dfa:	e8 4f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102dff:	83 c4 08             	add    $0x8,%esp
f0102e02:	ff 73 0c             	pushl  0xc(%ebx)
f0102e05:	68 dd 52 10 f0       	push   $0xf01052dd
f0102e0a:	e8 3f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102e0f:	83 c4 08             	add    $0x8,%esp
f0102e12:	ff 73 10             	pushl  0x10(%ebx)
f0102e15:	68 ec 52 10 f0       	push   $0xf01052ec
f0102e1a:	e8 2f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102e1f:	83 c4 08             	add    $0x8,%esp
f0102e22:	ff 73 14             	pushl  0x14(%ebx)
f0102e25:	68 fb 52 10 f0       	push   $0xf01052fb
f0102e2a:	e8 1f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102e2f:	83 c4 08             	add    $0x8,%esp
f0102e32:	ff 73 18             	pushl  0x18(%ebx)
f0102e35:	68 0a 53 10 f0       	push   $0xf010530a
f0102e3a:	e8 0f ff ff ff       	call   f0102d4e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102e3f:	83 c4 08             	add    $0x8,%esp
f0102e42:	ff 73 1c             	pushl  0x1c(%ebx)
f0102e45:	68 19 53 10 f0       	push   $0xf0105319
f0102e4a:	e8 ff fe ff ff       	call   f0102d4e <cprintf>
}
f0102e4f:	83 c4 10             	add    $0x10,%esp
f0102e52:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e55:	c9                   	leave  
f0102e56:	c3                   	ret    

f0102e57 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102e57:	55                   	push   %ebp
f0102e58:	89 e5                	mov    %esp,%ebp
f0102e5a:	56                   	push   %esi
f0102e5b:	53                   	push   %ebx
f0102e5c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102e5f:	83 ec 08             	sub    $0x8,%esp
f0102e62:	53                   	push   %ebx
f0102e63:	68 4f 54 10 f0       	push   $0xf010544f
f0102e68:	e8 e1 fe ff ff       	call   f0102d4e <cprintf>
	print_regs(&tf->tf_regs);
f0102e6d:	89 1c 24             	mov    %ebx,(%esp)
f0102e70:	e8 54 ff ff ff       	call   f0102dc9 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102e75:	83 c4 08             	add    $0x8,%esp
f0102e78:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102e7c:	50                   	push   %eax
f0102e7d:	68 6a 53 10 f0       	push   $0xf010536a
f0102e82:	e8 c7 fe ff ff       	call   f0102d4e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102e87:	83 c4 08             	add    $0x8,%esp
f0102e8a:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102e8e:	50                   	push   %eax
f0102e8f:	68 7d 53 10 f0       	push   $0xf010537d
f0102e94:	e8 b5 fe ff ff       	call   f0102d4e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e99:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0102e9c:	83 c4 10             	add    $0x10,%esp
f0102e9f:	83 f8 13             	cmp    $0x13,%eax
f0102ea2:	77 09                	ja     f0102ead <print_trapframe+0x56>
		return excnames[trapno];
f0102ea4:	8b 14 85 20 56 10 f0 	mov    -0xfefa9e0(,%eax,4),%edx
f0102eab:	eb 10                	jmp    f0102ebd <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102ead:	83 f8 30             	cmp    $0x30,%eax
f0102eb0:	b9 34 53 10 f0       	mov    $0xf0105334,%ecx
f0102eb5:	ba 28 53 10 f0       	mov    $0xf0105328,%edx
f0102eba:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102ebd:	83 ec 04             	sub    $0x4,%esp
f0102ec0:	52                   	push   %edx
f0102ec1:	50                   	push   %eax
f0102ec2:	68 90 53 10 f0       	push   $0xf0105390
f0102ec7:	e8 82 fe ff ff       	call   f0102d4e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102ecc:	83 c4 10             	add    $0x10,%esp
f0102ecf:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0102ed5:	75 1a                	jne    f0102ef1 <print_trapframe+0x9a>
f0102ed7:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102edb:	75 14                	jne    f0102ef1 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0102edd:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102ee0:	83 ec 08             	sub    $0x8,%esp
f0102ee3:	50                   	push   %eax
f0102ee4:	68 a2 53 10 f0       	push   $0xf01053a2
f0102ee9:	e8 60 fe ff ff       	call   f0102d4e <cprintf>
f0102eee:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102ef1:	83 ec 08             	sub    $0x8,%esp
f0102ef4:	ff 73 2c             	pushl  0x2c(%ebx)
f0102ef7:	68 b1 53 10 f0       	push   $0xf01053b1
f0102efc:	e8 4d fe ff ff       	call   f0102d4e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102f01:	83 c4 10             	add    $0x10,%esp
f0102f04:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102f08:	75 49                	jne    f0102f53 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102f0a:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102f0d:	89 c2                	mov    %eax,%edx
f0102f0f:	83 e2 01             	and    $0x1,%edx
f0102f12:	ba 4e 53 10 f0       	mov    $0xf010534e,%edx
f0102f17:	b9 43 53 10 f0       	mov    $0xf0105343,%ecx
f0102f1c:	0f 44 ca             	cmove  %edx,%ecx
f0102f1f:	89 c2                	mov    %eax,%edx
f0102f21:	83 e2 02             	and    $0x2,%edx
f0102f24:	ba 60 53 10 f0       	mov    $0xf0105360,%edx
f0102f29:	be 5a 53 10 f0       	mov    $0xf010535a,%esi
f0102f2e:	0f 45 d6             	cmovne %esi,%edx
f0102f31:	83 e0 04             	and    $0x4,%eax
f0102f34:	be 7a 54 10 f0       	mov    $0xf010547a,%esi
f0102f39:	b8 65 53 10 f0       	mov    $0xf0105365,%eax
f0102f3e:	0f 44 c6             	cmove  %esi,%eax
f0102f41:	51                   	push   %ecx
f0102f42:	52                   	push   %edx
f0102f43:	50                   	push   %eax
f0102f44:	68 bf 53 10 f0       	push   $0xf01053bf
f0102f49:	e8 00 fe ff ff       	call   f0102d4e <cprintf>
f0102f4e:	83 c4 10             	add    $0x10,%esp
f0102f51:	eb 10                	jmp    f0102f63 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102f53:	83 ec 0c             	sub    $0xc,%esp
f0102f56:	68 09 4a 10 f0       	push   $0xf0104a09
f0102f5b:	e8 ee fd ff ff       	call   f0102d4e <cprintf>
f0102f60:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102f63:	83 ec 08             	sub    $0x8,%esp
f0102f66:	ff 73 30             	pushl  0x30(%ebx)
f0102f69:	68 ce 53 10 f0       	push   $0xf01053ce
f0102f6e:	e8 db fd ff ff       	call   f0102d4e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102f73:	83 c4 08             	add    $0x8,%esp
f0102f76:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102f7a:	50                   	push   %eax
f0102f7b:	68 dd 53 10 f0       	push   $0xf01053dd
f0102f80:	e8 c9 fd ff ff       	call   f0102d4e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102f85:	83 c4 08             	add    $0x8,%esp
f0102f88:	ff 73 38             	pushl  0x38(%ebx)
f0102f8b:	68 f0 53 10 f0       	push   $0xf01053f0
f0102f90:	e8 b9 fd ff ff       	call   f0102d4e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102f95:	83 c4 10             	add    $0x10,%esp
f0102f98:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102f9c:	74 25                	je     f0102fc3 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102f9e:	83 ec 08             	sub    $0x8,%esp
f0102fa1:	ff 73 3c             	pushl  0x3c(%ebx)
f0102fa4:	68 ff 53 10 f0       	push   $0xf01053ff
f0102fa9:	e8 a0 fd ff ff       	call   f0102d4e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102fae:	83 c4 08             	add    $0x8,%esp
f0102fb1:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102fb5:	50                   	push   %eax
f0102fb6:	68 0e 54 10 f0       	push   $0xf010540e
f0102fbb:	e8 8e fd ff ff       	call   f0102d4e <cprintf>
f0102fc0:	83 c4 10             	add    $0x10,%esp
	}
}
f0102fc3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102fc6:	5b                   	pop    %ebx
f0102fc7:	5e                   	pop    %esi
f0102fc8:	5d                   	pop    %ebp
f0102fc9:	c3                   	ret    

f0102fca <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102fca:	55                   	push   %ebp
f0102fcb:	89 e5                	mov    %esp,%ebp
f0102fcd:	57                   	push   %edi
f0102fce:	56                   	push   %esi
f0102fcf:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102fd2:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0102fd3:	9c                   	pushf  
f0102fd4:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102fd5:	f6 c4 02             	test   $0x2,%ah
f0102fd8:	74 19                	je     f0102ff3 <trap+0x29>
f0102fda:	68 21 54 10 f0       	push   $0xf0105421
f0102fdf:	68 c6 47 10 f0       	push   $0xf01047c6
f0102fe4:	68 a7 00 00 00       	push   $0xa7
f0102fe9:	68 3a 54 10 f0       	push   $0xf010543a
f0102fee:	e8 ad d0 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102ff3:	83 ec 08             	sub    $0x8,%esp
f0102ff6:	56                   	push   %esi
f0102ff7:	68 46 54 10 f0       	push   $0xf0105446
f0102ffc:	e8 4d fd ff ff       	call   f0102d4e <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103001:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103005:	83 e0 03             	and    $0x3,%eax
f0103008:	83 c4 10             	add    $0x10,%esp
f010300b:	66 83 f8 03          	cmp    $0x3,%ax
f010300f:	75 31                	jne    f0103042 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103011:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103016:	85 c0                	test   %eax,%eax
f0103018:	75 19                	jne    f0103033 <trap+0x69>
f010301a:	68 61 54 10 f0       	push   $0xf0105461
f010301f:	68 c6 47 10 f0       	push   $0xf01047c6
f0103024:	68 ad 00 00 00       	push   $0xad
f0103029:	68 3a 54 10 f0       	push   $0xf010543a
f010302e:	e8 6d d0 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103033:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103038:	89 c7                	mov    %eax,%edi
f010303a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010303c:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103042:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103048:	83 ec 0c             	sub    $0xc,%esp
f010304b:	56                   	push   %esi
f010304c:	e8 06 fe ff ff       	call   f0102e57 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103051:	83 c4 10             	add    $0x10,%esp
f0103054:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103059:	75 17                	jne    f0103072 <trap+0xa8>
		panic("unhandled trap in kernel");
f010305b:	83 ec 04             	sub    $0x4,%esp
f010305e:	68 68 54 10 f0       	push   $0xf0105468
f0103063:	68 96 00 00 00       	push   $0x96
f0103068:	68 3a 54 10 f0       	push   $0xf010543a
f010306d:	e8 2e d0 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103072:	83 ec 0c             	sub    $0xc,%esp
f0103075:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010307b:	e8 fd fb ff ff       	call   f0102c7d <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103080:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103085:	83 c4 10             	add    $0x10,%esp
f0103088:	85 c0                	test   %eax,%eax
f010308a:	74 06                	je     f0103092 <trap+0xc8>
f010308c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103090:	74 19                	je     f01030ab <trap+0xe1>
f0103092:	68 c4 55 10 f0       	push   $0xf01055c4
f0103097:	68 c6 47 10 f0       	push   $0xf01047c6
f010309c:	68 bf 00 00 00       	push   $0xbf
f01030a1:	68 3a 54 10 f0       	push   $0xf010543a
f01030a6:	e8 f5 cf ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01030ab:	83 ec 0c             	sub    $0xc,%esp
f01030ae:	50                   	push   %eax
f01030af:	e8 19 fc ff ff       	call   f0102ccd <env_run>

f01030b4 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	53                   	push   %ebx
f01030b8:	83 ec 04             	sub    $0x4,%esp
f01030bb:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01030be:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01030c1:	ff 73 30             	pushl  0x30(%ebx)
f01030c4:	50                   	push   %eax
f01030c5:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f01030ca:	ff 70 48             	pushl  0x48(%eax)
f01030cd:	68 f0 55 10 f0       	push   $0xf01055f0
f01030d2:	e8 77 fc ff ff       	call   f0102d4e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01030d7:	89 1c 24             	mov    %ebx,(%esp)
f01030da:	e8 78 fd ff ff       	call   f0102e57 <print_trapframe>
	env_destroy(curenv);
f01030df:	83 c4 04             	add    $0x4,%esp
f01030e2:	ff 35 44 be 17 f0    	pushl  0xf017be44
f01030e8:	e8 90 fb ff ff       	call   f0102c7d <env_destroy>
}
f01030ed:	83 c4 10             	add    $0x10,%esp
f01030f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030f3:	c9                   	leave  
f01030f4:	c3                   	ret    

f01030f5 <syscall>:
f01030f5:	55                   	push   %ebp
f01030f6:	89 e5                	mov    %esp,%ebp
f01030f8:	83 ec 0c             	sub    $0xc,%esp
f01030fb:	68 70 56 10 f0       	push   $0xf0105670
f0103100:	6a 49                	push   $0x49
f0103102:	68 88 56 10 f0       	push   $0xf0105688
f0103107:	e8 94 cf ff ff       	call   f01000a0 <_panic>

f010310c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010310c:	55                   	push   %ebp
f010310d:	89 e5                	mov    %esp,%ebp
f010310f:	57                   	push   %edi
f0103110:	56                   	push   %esi
f0103111:	53                   	push   %ebx
f0103112:	83 ec 14             	sub    $0x14,%esp
f0103115:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103118:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010311b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010311e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103121:	8b 1a                	mov    (%edx),%ebx
f0103123:	8b 01                	mov    (%ecx),%eax
f0103125:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103128:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010312f:	eb 7f                	jmp    f01031b0 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103131:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103134:	01 d8                	add    %ebx,%eax
f0103136:	89 c6                	mov    %eax,%esi
f0103138:	c1 ee 1f             	shr    $0x1f,%esi
f010313b:	01 c6                	add    %eax,%esi
f010313d:	d1 fe                	sar    %esi
f010313f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103142:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103145:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103148:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010314a:	eb 03                	jmp    f010314f <stab_binsearch+0x43>
			m--;
f010314c:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010314f:	39 c3                	cmp    %eax,%ebx
f0103151:	7f 0d                	jg     f0103160 <stab_binsearch+0x54>
f0103153:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103157:	83 ea 0c             	sub    $0xc,%edx
f010315a:	39 f9                	cmp    %edi,%ecx
f010315c:	75 ee                	jne    f010314c <stab_binsearch+0x40>
f010315e:	eb 05                	jmp    f0103165 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103160:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103163:	eb 4b                	jmp    f01031b0 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103165:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103168:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010316b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010316f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103172:	76 11                	jbe    f0103185 <stab_binsearch+0x79>
			*region_left = m;
f0103174:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103177:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103179:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010317c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103183:	eb 2b                	jmp    f01031b0 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103185:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103188:	73 14                	jae    f010319e <stab_binsearch+0x92>
			*region_right = m - 1;
f010318a:	83 e8 01             	sub    $0x1,%eax
f010318d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103190:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103193:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103195:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010319c:	eb 12                	jmp    f01031b0 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010319e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031a1:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01031a3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01031a7:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01031a9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01031b0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01031b3:	0f 8e 78 ff ff ff    	jle    f0103131 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01031b9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031bd:	75 0f                	jne    f01031ce <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01031bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031c2:	8b 00                	mov    (%eax),%eax
f01031c4:	83 e8 01             	sub    $0x1,%eax
f01031c7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01031ca:	89 06                	mov    %eax,(%esi)
f01031cc:	eb 2c                	jmp    f01031fa <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031d1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01031d3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031d6:	8b 0e                	mov    (%esi),%ecx
f01031d8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031db:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01031de:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031e1:	eb 03                	jmp    f01031e6 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01031e3:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01031e6:	39 c8                	cmp    %ecx,%eax
f01031e8:	7e 0b                	jle    f01031f5 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01031ea:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01031ee:	83 ea 0c             	sub    $0xc,%edx
f01031f1:	39 df                	cmp    %ebx,%edi
f01031f3:	75 ee                	jne    f01031e3 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01031f5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031f8:	89 06                	mov    %eax,(%esi)
	}
}
f01031fa:	83 c4 14             	add    $0x14,%esp
f01031fd:	5b                   	pop    %ebx
f01031fe:	5e                   	pop    %esi
f01031ff:	5f                   	pop    %edi
f0103200:	5d                   	pop    %ebp
f0103201:	c3                   	ret    

f0103202 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103202:	55                   	push   %ebp
f0103203:	89 e5                	mov    %esp,%ebp
f0103205:	57                   	push   %edi
f0103206:	56                   	push   %esi
f0103207:	53                   	push   %ebx
f0103208:	83 ec 3c             	sub    $0x3c,%esp
f010320b:	8b 75 08             	mov    0x8(%ebp),%esi
f010320e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103211:	c7 03 97 56 10 f0    	movl   $0xf0105697,(%ebx)
	info->eip_line = 0;
f0103217:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010321e:	c7 43 08 97 56 10 f0 	movl   $0xf0105697,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103225:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010322c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010322f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103236:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010323c:	77 21                	ja     f010325f <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010323e:	a1 00 00 20 00       	mov    0x200000,%eax
f0103243:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103246:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010324b:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103251:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103254:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f010325a:	89 7d bc             	mov    %edi,-0x44(%ebp)
f010325d:	eb 1a                	jmp    f0103279 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010325f:	c7 45 bc 9c f4 10 f0 	movl   $0xf010f49c,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103266:	c7 45 b8 d1 ca 10 f0 	movl   $0xf010cad1,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010326d:	b8 d0 ca 10 f0       	mov    $0xf010cad0,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103272:	c7 45 c0 d0 58 10 f0 	movl   $0xf01058d0,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103279:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010327c:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f010327f:	0f 83 a5 01 00 00    	jae    f010342a <debuginfo_eip+0x228>
f0103285:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103289:	0f 85 a2 01 00 00    	jne    f0103431 <debuginfo_eip+0x22f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010328f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103296:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103299:	29 f8                	sub    %edi,%eax
f010329b:	c1 f8 02             	sar    $0x2,%eax
f010329e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01032a4:	83 e8 01             	sub    $0x1,%eax
f01032a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032aa:	56                   	push   %esi
f01032ab:	6a 64                	push   $0x64
f01032ad:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01032b0:	89 c1                	mov    %eax,%ecx
f01032b2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032b5:	89 f8                	mov    %edi,%eax
f01032b7:	e8 50 fe ff ff       	call   f010310c <stab_binsearch>
	if (lfile == 0)
f01032bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032bf:	83 c4 08             	add    $0x8,%esp
f01032c2:	85 c0                	test   %eax,%eax
f01032c4:	0f 84 6e 01 00 00    	je     f0103438 <debuginfo_eip+0x236>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01032ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01032cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032d0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01032d3:	56                   	push   %esi
f01032d4:	6a 24                	push   $0x24
f01032d6:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01032d9:	89 c1                	mov    %eax,%ecx
f01032db:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01032de:	89 f8                	mov    %edi,%eax
f01032e0:	e8 27 fe ff ff       	call   f010310c <stab_binsearch>

	if (lfun <= rfun) {
f01032e5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01032e8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032eb:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01032ee:	83 c4 08             	add    $0x8,%esp
f01032f1:	39 d0                	cmp    %edx,%eax
f01032f3:	7f 2b                	jg     f0103320 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01032f5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032f8:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f01032fb:	8b 11                	mov    (%ecx),%edx
f01032fd:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103300:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103303:	39 fa                	cmp    %edi,%edx
f0103305:	73 06                	jae    f010330d <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103307:	03 55 b8             	add    -0x48(%ebp),%edx
f010330a:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010330d:	8b 51 08             	mov    0x8(%ecx),%edx
f0103310:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103313:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103315:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103318:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010331b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010331e:	eb 0f                	jmp    f010332f <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103320:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103323:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103326:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103329:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010332c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010332f:	83 ec 08             	sub    $0x8,%esp
f0103332:	6a 3a                	push   $0x3a
f0103334:	ff 73 08             	pushl  0x8(%ebx)
f0103337:	e8 2a 09 00 00       	call   f0103c66 <strfind>
f010333c:	2b 43 08             	sub    0x8(%ebx),%eax
f010333f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103342:	83 c4 08             	add    $0x8,%esp
f0103345:	56                   	push   %esi
f0103346:	6a 44                	push   $0x44
f0103348:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010334b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010334e:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103351:	89 f0                	mov    %esi,%eax
f0103353:	e8 b4 fd ff ff       	call   f010310c <stab_binsearch>
    if(lline <= rline){
f0103358:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010335b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010335e:	83 c4 10             	add    $0x10,%esp
f0103361:	39 c2                	cmp    %eax,%edx
f0103363:	7f 0d                	jg     f0103372 <debuginfo_eip+0x170>
        info->eip_line = stabs[rline].n_desc;
f0103365:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103368:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f010336d:	89 43 04             	mov    %eax,0x4(%ebx)
f0103370:	eb 07                	jmp    f0103379 <debuginfo_eip+0x177>
    }
    else
        info->eip_line = -1;
f0103372:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103379:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010337c:	89 d0                	mov    %edx,%eax
f010337e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103381:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103384:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103387:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010338b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010338e:	eb 0a                	jmp    f010339a <debuginfo_eip+0x198>
f0103390:	83 e8 01             	sub    $0x1,%eax
f0103393:	83 ea 0c             	sub    $0xc,%edx
f0103396:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010339a:	39 c7                	cmp    %eax,%edi
f010339c:	7e 05                	jle    f01033a3 <debuginfo_eip+0x1a1>
f010339e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033a1:	eb 47                	jmp    f01033ea <debuginfo_eip+0x1e8>
	       && stabs[lline].n_type != N_SOL
f01033a3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01033a7:	80 f9 84             	cmp    $0x84,%cl
f01033aa:	75 0e                	jne    f01033ba <debuginfo_eip+0x1b8>
f01033ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033af:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033b3:	74 1c                	je     f01033d1 <debuginfo_eip+0x1cf>
f01033b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01033b8:	eb 17                	jmp    f01033d1 <debuginfo_eip+0x1cf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01033ba:	80 f9 64             	cmp    $0x64,%cl
f01033bd:	75 d1                	jne    f0103390 <debuginfo_eip+0x18e>
f01033bf:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01033c3:	74 cb                	je     f0103390 <debuginfo_eip+0x18e>
f01033c5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033c8:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01033cc:	74 03                	je     f01033d1 <debuginfo_eip+0x1cf>
f01033ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01033d1:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01033d4:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01033d7:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01033da:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01033dd:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01033e0:	29 f8                	sub    %edi,%eax
f01033e2:	39 c2                	cmp    %eax,%edx
f01033e4:	73 04                	jae    f01033ea <debuginfo_eip+0x1e8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01033e6:	01 fa                	add    %edi,%edx
f01033e8:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033ea:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01033ed:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033f0:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033f5:	39 f2                	cmp    %esi,%edx
f01033f7:	7d 4b                	jge    f0103444 <debuginfo_eip+0x242>
		for (lline = lfun + 1;
f01033f9:	83 c2 01             	add    $0x1,%edx
f01033fc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01033ff:	89 d0                	mov    %edx,%eax
f0103401:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103404:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103407:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010340a:	eb 04                	jmp    f0103410 <debuginfo_eip+0x20e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010340c:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103410:	39 c6                	cmp    %eax,%esi
f0103412:	7e 2b                	jle    f010343f <debuginfo_eip+0x23d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103414:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103418:	83 c0 01             	add    $0x1,%eax
f010341b:	83 c2 0c             	add    $0xc,%edx
f010341e:	80 f9 a0             	cmp    $0xa0,%cl
f0103421:	74 e9                	je     f010340c <debuginfo_eip+0x20a>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103423:	b8 00 00 00 00       	mov    $0x0,%eax
f0103428:	eb 1a                	jmp    f0103444 <debuginfo_eip+0x242>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010342a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010342f:	eb 13                	jmp    f0103444 <debuginfo_eip+0x242>
f0103431:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103436:	eb 0c                	jmp    f0103444 <debuginfo_eip+0x242>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103438:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010343d:	eb 05                	jmp    f0103444 <debuginfo_eip+0x242>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010343f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103444:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103447:	5b                   	pop    %ebx
f0103448:	5e                   	pop    %esi
f0103449:	5f                   	pop    %edi
f010344a:	5d                   	pop    %ebp
f010344b:	c3                   	ret    

f010344c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010344c:	55                   	push   %ebp
f010344d:	89 e5                	mov    %esp,%ebp
f010344f:	57                   	push   %edi
f0103450:	56                   	push   %esi
f0103451:	53                   	push   %ebx
f0103452:	83 ec 1c             	sub    $0x1c,%esp
f0103455:	89 c7                	mov    %eax,%edi
f0103457:	89 d6                	mov    %edx,%esi
f0103459:	8b 45 08             	mov    0x8(%ebp),%eax
f010345c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010345f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103462:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103465:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103468:	bb 00 00 00 00       	mov    $0x0,%ebx
f010346d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103470:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103473:	39 d3                	cmp    %edx,%ebx
f0103475:	72 05                	jb     f010347c <printnum+0x30>
f0103477:	39 45 10             	cmp    %eax,0x10(%ebp)
f010347a:	77 45                	ja     f01034c1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010347c:	83 ec 0c             	sub    $0xc,%esp
f010347f:	ff 75 18             	pushl  0x18(%ebp)
f0103482:	8b 45 14             	mov    0x14(%ebp),%eax
f0103485:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103488:	53                   	push   %ebx
f0103489:	ff 75 10             	pushl  0x10(%ebp)
f010348c:	83 ec 08             	sub    $0x8,%esp
f010348f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103492:	ff 75 e0             	pushl  -0x20(%ebp)
f0103495:	ff 75 dc             	pushl  -0x24(%ebp)
f0103498:	ff 75 d8             	pushl  -0x28(%ebp)
f010349b:	e8 f0 09 00 00       	call   f0103e90 <__udivdi3>
f01034a0:	83 c4 18             	add    $0x18,%esp
f01034a3:	52                   	push   %edx
f01034a4:	50                   	push   %eax
f01034a5:	89 f2                	mov    %esi,%edx
f01034a7:	89 f8                	mov    %edi,%eax
f01034a9:	e8 9e ff ff ff       	call   f010344c <printnum>
f01034ae:	83 c4 20             	add    $0x20,%esp
f01034b1:	eb 18                	jmp    f01034cb <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01034b3:	83 ec 08             	sub    $0x8,%esp
f01034b6:	56                   	push   %esi
f01034b7:	ff 75 18             	pushl  0x18(%ebp)
f01034ba:	ff d7                	call   *%edi
f01034bc:	83 c4 10             	add    $0x10,%esp
f01034bf:	eb 03                	jmp    f01034c4 <printnum+0x78>
f01034c1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01034c4:	83 eb 01             	sub    $0x1,%ebx
f01034c7:	85 db                	test   %ebx,%ebx
f01034c9:	7f e8                	jg     f01034b3 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01034cb:	83 ec 08             	sub    $0x8,%esp
f01034ce:	56                   	push   %esi
f01034cf:	83 ec 04             	sub    $0x4,%esp
f01034d2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01034d5:	ff 75 e0             	pushl  -0x20(%ebp)
f01034d8:	ff 75 dc             	pushl  -0x24(%ebp)
f01034db:	ff 75 d8             	pushl  -0x28(%ebp)
f01034de:	e8 dd 0a 00 00       	call   f0103fc0 <__umoddi3>
f01034e3:	83 c4 14             	add    $0x14,%esp
f01034e6:	0f be 80 a1 56 10 f0 	movsbl -0xfefa95f(%eax),%eax
f01034ed:	50                   	push   %eax
f01034ee:	ff d7                	call   *%edi
}
f01034f0:	83 c4 10             	add    $0x10,%esp
f01034f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034f6:	5b                   	pop    %ebx
f01034f7:	5e                   	pop    %esi
f01034f8:	5f                   	pop    %edi
f01034f9:	5d                   	pop    %ebp
f01034fa:	c3                   	ret    

f01034fb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01034fb:	55                   	push   %ebp
f01034fc:	89 e5                	mov    %esp,%ebp
f01034fe:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103501:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103505:	8b 10                	mov    (%eax),%edx
f0103507:	3b 50 04             	cmp    0x4(%eax),%edx
f010350a:	73 0a                	jae    f0103516 <sprintputch+0x1b>
		*b->buf++ = ch;
f010350c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010350f:	89 08                	mov    %ecx,(%eax)
f0103511:	8b 45 08             	mov    0x8(%ebp),%eax
f0103514:	88 02                	mov    %al,(%edx)
}
f0103516:	5d                   	pop    %ebp
f0103517:	c3                   	ret    

f0103518 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103518:	55                   	push   %ebp
f0103519:	89 e5                	mov    %esp,%ebp
f010351b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010351e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103521:	50                   	push   %eax
f0103522:	ff 75 10             	pushl  0x10(%ebp)
f0103525:	ff 75 0c             	pushl  0xc(%ebp)
f0103528:	ff 75 08             	pushl  0x8(%ebp)
f010352b:	e8 05 00 00 00       	call   f0103535 <vprintfmt>
	va_end(ap);
}
f0103530:	83 c4 10             	add    $0x10,%esp
f0103533:	c9                   	leave  
f0103534:	c3                   	ret    

f0103535 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103535:	55                   	push   %ebp
f0103536:	89 e5                	mov    %esp,%ebp
f0103538:	57                   	push   %edi
f0103539:	56                   	push   %esi
f010353a:	53                   	push   %ebx
f010353b:	83 ec 2c             	sub    $0x2c,%esp
f010353e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103541:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103544:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103547:	eb 12                	jmp    f010355b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0103549:	85 c0                	test   %eax,%eax
f010354b:	0f 84 6a 04 00 00    	je     f01039bb <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0103551:	83 ec 08             	sub    $0x8,%esp
f0103554:	53                   	push   %ebx
f0103555:	50                   	push   %eax
f0103556:	ff d6                	call   *%esi
f0103558:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f010355b:	83 c7 01             	add    $0x1,%edi
f010355e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103562:	83 f8 25             	cmp    $0x25,%eax
f0103565:	75 e2                	jne    f0103549 <vprintfmt+0x14>
f0103567:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010356b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103572:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103579:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103580:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103585:	eb 07                	jmp    f010358e <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103587:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f010358a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010358e:	8d 47 01             	lea    0x1(%edi),%eax
f0103591:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103594:	0f b6 07             	movzbl (%edi),%eax
f0103597:	0f b6 d0             	movzbl %al,%edx
f010359a:	83 e8 23             	sub    $0x23,%eax
f010359d:	3c 55                	cmp    $0x55,%al
f010359f:	0f 87 fb 03 00 00    	ja     f01039a0 <vprintfmt+0x46b>
f01035a5:	0f b6 c0             	movzbl %al,%eax
f01035a8:	ff 24 85 40 57 10 f0 	jmp    *-0xfefa8c0(,%eax,4)
f01035af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f01035b2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01035b6:	eb d6                	jmp    f010358e <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01035b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01035c0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f01035c3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01035c6:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01035ca:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01035cd:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01035d0:	83 f9 09             	cmp    $0x9,%ecx
f01035d3:	77 3f                	ja     f0103614 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f01035d5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01035d8:	eb e9                	jmp    f01035c3 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f01035da:	8b 45 14             	mov    0x14(%ebp),%eax
f01035dd:	8b 00                	mov    (%eax),%eax
f01035df:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01035e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01035e5:	8d 40 04             	lea    0x4(%eax),%eax
f01035e8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01035eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f01035ee:	eb 2a                	jmp    f010361a <vprintfmt+0xe5>
f01035f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035f3:	85 c0                	test   %eax,%eax
f01035f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01035fa:	0f 49 d0             	cmovns %eax,%edx
f01035fd:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103600:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103603:	eb 89                	jmp    f010358e <vprintfmt+0x59>
f0103605:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103608:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010360f:	e9 7a ff ff ff       	jmp    f010358e <vprintfmt+0x59>
f0103614:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103617:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f010361a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010361e:	0f 89 6a ff ff ff    	jns    f010358e <vprintfmt+0x59>
				width = precision, precision = -1;
f0103624:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103627:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010362a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103631:	e9 58 ff ff ff       	jmp    f010358e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f0103636:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103639:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f010363c:	e9 4d ff ff ff       	jmp    f010358e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0103641:	8b 45 14             	mov    0x14(%ebp),%eax
f0103644:	8d 78 04             	lea    0x4(%eax),%edi
f0103647:	83 ec 08             	sub    $0x8,%esp
f010364a:	53                   	push   %ebx
f010364b:	ff 30                	pushl  (%eax)
f010364d:	ff d6                	call   *%esi
			break;
f010364f:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0103652:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103655:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f0103658:	e9 fe fe ff ff       	jmp    f010355b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010365d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103660:	8d 78 04             	lea    0x4(%eax),%edi
f0103663:	8b 00                	mov    (%eax),%eax
f0103665:	99                   	cltd   
f0103666:	31 d0                	xor    %edx,%eax
f0103668:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010366a:	83 f8 07             	cmp    $0x7,%eax
f010366d:	7f 0b                	jg     f010367a <vprintfmt+0x145>
f010366f:	8b 14 85 a0 58 10 f0 	mov    -0xfefa760(,%eax,4),%edx
f0103676:	85 d2                	test   %edx,%edx
f0103678:	75 1b                	jne    f0103695 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f010367a:	50                   	push   %eax
f010367b:	68 b9 56 10 f0       	push   $0xf01056b9
f0103680:	53                   	push   %ebx
f0103681:	56                   	push   %esi
f0103682:	e8 91 fe ff ff       	call   f0103518 <printfmt>
f0103687:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010368a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010368d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103690:	e9 c6 fe ff ff       	jmp    f010355b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103695:	52                   	push   %edx
f0103696:	68 d8 47 10 f0       	push   $0xf01047d8
f010369b:	53                   	push   %ebx
f010369c:	56                   	push   %esi
f010369d:	e8 76 fe ff ff       	call   f0103518 <printfmt>
f01036a2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01036a5:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01036a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036ab:	e9 ab fe ff ff       	jmp    f010355b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01036b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01036b3:	83 c0 04             	add    $0x4,%eax
f01036b6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01036b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036bc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01036be:	85 ff                	test   %edi,%edi
f01036c0:	b8 b2 56 10 f0       	mov    $0xf01056b2,%eax
f01036c5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01036c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01036cc:	0f 8e 94 00 00 00    	jle    f0103766 <vprintfmt+0x231>
f01036d2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01036d6:	0f 84 98 00 00 00    	je     f0103774 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01036dc:	83 ec 08             	sub    $0x8,%esp
f01036df:	ff 75 d0             	pushl  -0x30(%ebp)
f01036e2:	57                   	push   %edi
f01036e3:	e8 34 04 00 00       	call   f0103b1c <strnlen>
f01036e8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01036eb:	29 c1                	sub    %eax,%ecx
f01036ed:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01036f0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01036f3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01036f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036fa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01036fd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036ff:	eb 0f                	jmp    f0103710 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103701:	83 ec 08             	sub    $0x8,%esp
f0103704:	53                   	push   %ebx
f0103705:	ff 75 e0             	pushl  -0x20(%ebp)
f0103708:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010370a:	83 ef 01             	sub    $0x1,%edi
f010370d:	83 c4 10             	add    $0x10,%esp
f0103710:	85 ff                	test   %edi,%edi
f0103712:	7f ed                	jg     f0103701 <vprintfmt+0x1cc>
f0103714:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103717:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010371a:	85 c9                	test   %ecx,%ecx
f010371c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103721:	0f 49 c1             	cmovns %ecx,%eax
f0103724:	29 c1                	sub    %eax,%ecx
f0103726:	89 75 08             	mov    %esi,0x8(%ebp)
f0103729:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010372c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010372f:	89 cb                	mov    %ecx,%ebx
f0103731:	eb 4d                	jmp    f0103780 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103733:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103737:	74 1b                	je     f0103754 <vprintfmt+0x21f>
f0103739:	0f be c0             	movsbl %al,%eax
f010373c:	83 e8 20             	sub    $0x20,%eax
f010373f:	83 f8 5e             	cmp    $0x5e,%eax
f0103742:	76 10                	jbe    f0103754 <vprintfmt+0x21f>
					putch('?', putdat);
f0103744:	83 ec 08             	sub    $0x8,%esp
f0103747:	ff 75 0c             	pushl  0xc(%ebp)
f010374a:	6a 3f                	push   $0x3f
f010374c:	ff 55 08             	call   *0x8(%ebp)
f010374f:	83 c4 10             	add    $0x10,%esp
f0103752:	eb 0d                	jmp    f0103761 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103754:	83 ec 08             	sub    $0x8,%esp
f0103757:	ff 75 0c             	pushl  0xc(%ebp)
f010375a:	52                   	push   %edx
f010375b:	ff 55 08             	call   *0x8(%ebp)
f010375e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103761:	83 eb 01             	sub    $0x1,%ebx
f0103764:	eb 1a                	jmp    f0103780 <vprintfmt+0x24b>
f0103766:	89 75 08             	mov    %esi,0x8(%ebp)
f0103769:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010376c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010376f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103772:	eb 0c                	jmp    f0103780 <vprintfmt+0x24b>
f0103774:	89 75 08             	mov    %esi,0x8(%ebp)
f0103777:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010377a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010377d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103780:	83 c7 01             	add    $0x1,%edi
f0103783:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103787:	0f be d0             	movsbl %al,%edx
f010378a:	85 d2                	test   %edx,%edx
f010378c:	74 23                	je     f01037b1 <vprintfmt+0x27c>
f010378e:	85 f6                	test   %esi,%esi
f0103790:	78 a1                	js     f0103733 <vprintfmt+0x1fe>
f0103792:	83 ee 01             	sub    $0x1,%esi
f0103795:	79 9c                	jns    f0103733 <vprintfmt+0x1fe>
f0103797:	89 df                	mov    %ebx,%edi
f0103799:	8b 75 08             	mov    0x8(%ebp),%esi
f010379c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010379f:	eb 18                	jmp    f01037b9 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01037a1:	83 ec 08             	sub    $0x8,%esp
f01037a4:	53                   	push   %ebx
f01037a5:	6a 20                	push   $0x20
f01037a7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01037a9:	83 ef 01             	sub    $0x1,%edi
f01037ac:	83 c4 10             	add    $0x10,%esp
f01037af:	eb 08                	jmp    f01037b9 <vprintfmt+0x284>
f01037b1:	89 df                	mov    %ebx,%edi
f01037b3:	8b 75 08             	mov    0x8(%ebp),%esi
f01037b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01037b9:	85 ff                	test   %edi,%edi
f01037bb:	7f e4                	jg     f01037a1 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01037bd:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01037c0:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01037c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037c6:	e9 90 fd ff ff       	jmp    f010355b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01037cb:	83 f9 01             	cmp    $0x1,%ecx
f01037ce:	7e 19                	jle    f01037e9 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f01037d0:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d3:	8b 50 04             	mov    0x4(%eax),%edx
f01037d6:	8b 00                	mov    (%eax),%eax
f01037d8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037db:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037de:	8b 45 14             	mov    0x14(%ebp),%eax
f01037e1:	8d 40 08             	lea    0x8(%eax),%eax
f01037e4:	89 45 14             	mov    %eax,0x14(%ebp)
f01037e7:	eb 38                	jmp    f0103821 <vprintfmt+0x2ec>
	else if (lflag)
f01037e9:	85 c9                	test   %ecx,%ecx
f01037eb:	74 1b                	je     f0103808 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01037ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01037f0:	8b 00                	mov    (%eax),%eax
f01037f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037f5:	89 c1                	mov    %eax,%ecx
f01037f7:	c1 f9 1f             	sar    $0x1f,%ecx
f01037fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037fd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103800:	8d 40 04             	lea    0x4(%eax),%eax
f0103803:	89 45 14             	mov    %eax,0x14(%ebp)
f0103806:	eb 19                	jmp    f0103821 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103808:	8b 45 14             	mov    0x14(%ebp),%eax
f010380b:	8b 00                	mov    (%eax),%eax
f010380d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103810:	89 c1                	mov    %eax,%ecx
f0103812:	c1 f9 1f             	sar    $0x1f,%ecx
f0103815:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103818:	8b 45 14             	mov    0x14(%ebp),%eax
f010381b:	8d 40 04             	lea    0x4(%eax),%eax
f010381e:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103821:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103824:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103827:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010382c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103830:	0f 89 36 01 00 00    	jns    f010396c <vprintfmt+0x437>
				putch('-', putdat);
f0103836:	83 ec 08             	sub    $0x8,%esp
f0103839:	53                   	push   %ebx
f010383a:	6a 2d                	push   $0x2d
f010383c:	ff d6                	call   *%esi
				num = -(long long) num;
f010383e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103841:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103844:	f7 da                	neg    %edx
f0103846:	83 d1 00             	adc    $0x0,%ecx
f0103849:	f7 d9                	neg    %ecx
f010384b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010384e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103853:	e9 14 01 00 00       	jmp    f010396c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103858:	83 f9 01             	cmp    $0x1,%ecx
f010385b:	7e 18                	jle    f0103875 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010385d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103860:	8b 10                	mov    (%eax),%edx
f0103862:	8b 48 04             	mov    0x4(%eax),%ecx
f0103865:	8d 40 08             	lea    0x8(%eax),%eax
f0103868:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010386b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103870:	e9 f7 00 00 00       	jmp    f010396c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103875:	85 c9                	test   %ecx,%ecx
f0103877:	74 1a                	je     f0103893 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103879:	8b 45 14             	mov    0x14(%ebp),%eax
f010387c:	8b 10                	mov    (%eax),%edx
f010387e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103883:	8d 40 04             	lea    0x4(%eax),%eax
f0103886:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103889:	b8 0a 00 00 00       	mov    $0xa,%eax
f010388e:	e9 d9 00 00 00       	jmp    f010396c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103893:	8b 45 14             	mov    0x14(%ebp),%eax
f0103896:	8b 10                	mov    (%eax),%edx
f0103898:	b9 00 00 00 00       	mov    $0x0,%ecx
f010389d:	8d 40 04             	lea    0x4(%eax),%eax
f01038a0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01038a3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01038a8:	e9 bf 00 00 00       	jmp    f010396c <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01038ad:	83 f9 01             	cmp    $0x1,%ecx
f01038b0:	7e 13                	jle    f01038c5 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f01038b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01038b5:	8b 50 04             	mov    0x4(%eax),%edx
f01038b8:	8b 00                	mov    (%eax),%eax
f01038ba:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01038bd:	8d 49 08             	lea    0x8(%ecx),%ecx
f01038c0:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01038c3:	eb 28                	jmp    f01038ed <vprintfmt+0x3b8>
	else if (lflag)
f01038c5:	85 c9                	test   %ecx,%ecx
f01038c7:	74 13                	je     f01038dc <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f01038c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038cc:	8b 10                	mov    (%eax),%edx
f01038ce:	89 d0                	mov    %edx,%eax
f01038d0:	99                   	cltd   
f01038d1:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01038d4:	8d 49 04             	lea    0x4(%ecx),%ecx
f01038d7:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01038da:	eb 11                	jmp    f01038ed <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f01038dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01038df:	8b 10                	mov    (%eax),%edx
f01038e1:	89 d0                	mov    %edx,%eax
f01038e3:	99                   	cltd   
f01038e4:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01038e7:	8d 49 04             	lea    0x4(%ecx),%ecx
f01038ea:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f01038ed:	89 d1                	mov    %edx,%ecx
f01038ef:	89 c2                	mov    %eax,%edx
			base = 8;
f01038f1:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f01038f6:	eb 74                	jmp    f010396c <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f01038f8:	83 ec 08             	sub    $0x8,%esp
f01038fb:	53                   	push   %ebx
f01038fc:	6a 30                	push   $0x30
f01038fe:	ff d6                	call   *%esi
			putch('x', putdat);
f0103900:	83 c4 08             	add    $0x8,%esp
f0103903:	53                   	push   %ebx
f0103904:	6a 78                	push   $0x78
f0103906:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103908:	8b 45 14             	mov    0x14(%ebp),%eax
f010390b:	8b 10                	mov    (%eax),%edx
f010390d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103912:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103915:	8d 40 04             	lea    0x4(%eax),%eax
f0103918:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010391b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103920:	eb 4a                	jmp    f010396c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103922:	83 f9 01             	cmp    $0x1,%ecx
f0103925:	7e 15                	jle    f010393c <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f0103927:	8b 45 14             	mov    0x14(%ebp),%eax
f010392a:	8b 10                	mov    (%eax),%edx
f010392c:	8b 48 04             	mov    0x4(%eax),%ecx
f010392f:	8d 40 08             	lea    0x8(%eax),%eax
f0103932:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103935:	b8 10 00 00 00       	mov    $0x10,%eax
f010393a:	eb 30                	jmp    f010396c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010393c:	85 c9                	test   %ecx,%ecx
f010393e:	74 17                	je     f0103957 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f0103940:	8b 45 14             	mov    0x14(%ebp),%eax
f0103943:	8b 10                	mov    (%eax),%edx
f0103945:	b9 00 00 00 00       	mov    $0x0,%ecx
f010394a:	8d 40 04             	lea    0x4(%eax),%eax
f010394d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103950:	b8 10 00 00 00       	mov    $0x10,%eax
f0103955:	eb 15                	jmp    f010396c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103957:	8b 45 14             	mov    0x14(%ebp),%eax
f010395a:	8b 10                	mov    (%eax),%edx
f010395c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103961:	8d 40 04             	lea    0x4(%eax),%eax
f0103964:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103967:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010396c:	83 ec 0c             	sub    $0xc,%esp
f010396f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103973:	57                   	push   %edi
f0103974:	ff 75 e0             	pushl  -0x20(%ebp)
f0103977:	50                   	push   %eax
f0103978:	51                   	push   %ecx
f0103979:	52                   	push   %edx
f010397a:	89 da                	mov    %ebx,%edx
f010397c:	89 f0                	mov    %esi,%eax
f010397e:	e8 c9 fa ff ff       	call   f010344c <printnum>
			break;
f0103983:	83 c4 20             	add    $0x20,%esp
f0103986:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103989:	e9 cd fb ff ff       	jmp    f010355b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010398e:	83 ec 08             	sub    $0x8,%esp
f0103991:	53                   	push   %ebx
f0103992:	52                   	push   %edx
f0103993:	ff d6                	call   *%esi
			break;
f0103995:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103998:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010399b:	e9 bb fb ff ff       	jmp    f010355b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01039a0:	83 ec 08             	sub    $0x8,%esp
f01039a3:	53                   	push   %ebx
f01039a4:	6a 25                	push   $0x25
f01039a6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01039a8:	83 c4 10             	add    $0x10,%esp
f01039ab:	eb 03                	jmp    f01039b0 <vprintfmt+0x47b>
f01039ad:	83 ef 01             	sub    $0x1,%edi
f01039b0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01039b4:	75 f7                	jne    f01039ad <vprintfmt+0x478>
f01039b6:	e9 a0 fb ff ff       	jmp    f010355b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01039bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039be:	5b                   	pop    %ebx
f01039bf:	5e                   	pop    %esi
f01039c0:	5f                   	pop    %edi
f01039c1:	5d                   	pop    %ebp
f01039c2:	c3                   	ret    

f01039c3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01039c3:	55                   	push   %ebp
f01039c4:	89 e5                	mov    %esp,%ebp
f01039c6:	83 ec 18             	sub    $0x18,%esp
f01039c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039cc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01039cf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039d2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01039d6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01039d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01039e0:	85 c0                	test   %eax,%eax
f01039e2:	74 26                	je     f0103a0a <vsnprintf+0x47>
f01039e4:	85 d2                	test   %edx,%edx
f01039e6:	7e 22                	jle    f0103a0a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01039e8:	ff 75 14             	pushl  0x14(%ebp)
f01039eb:	ff 75 10             	pushl  0x10(%ebp)
f01039ee:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01039f1:	50                   	push   %eax
f01039f2:	68 fb 34 10 f0       	push   $0xf01034fb
f01039f7:	e8 39 fb ff ff       	call   f0103535 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01039fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039ff:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a05:	83 c4 10             	add    $0x10,%esp
f0103a08:	eb 05                	jmp    f0103a0f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103a0a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103a0f:	c9                   	leave  
f0103a10:	c3                   	ret    

f0103a11 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a11:	55                   	push   %ebp
f0103a12:	89 e5                	mov    %esp,%ebp
f0103a14:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a17:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a1a:	50                   	push   %eax
f0103a1b:	ff 75 10             	pushl  0x10(%ebp)
f0103a1e:	ff 75 0c             	pushl  0xc(%ebp)
f0103a21:	ff 75 08             	pushl  0x8(%ebp)
f0103a24:	e8 9a ff ff ff       	call   f01039c3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a29:	c9                   	leave  
f0103a2a:	c3                   	ret    

f0103a2b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a2b:	55                   	push   %ebp
f0103a2c:	89 e5                	mov    %esp,%ebp
f0103a2e:	57                   	push   %edi
f0103a2f:	56                   	push   %esi
f0103a30:	53                   	push   %ebx
f0103a31:	83 ec 0c             	sub    $0xc,%esp
f0103a34:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a37:	85 c0                	test   %eax,%eax
f0103a39:	74 11                	je     f0103a4c <readline+0x21>
		cprintf("%s", prompt);
f0103a3b:	83 ec 08             	sub    $0x8,%esp
f0103a3e:	50                   	push   %eax
f0103a3f:	68 d8 47 10 f0       	push   $0xf01047d8
f0103a44:	e8 05 f3 ff ff       	call   f0102d4e <cprintf>
f0103a49:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103a4c:	83 ec 0c             	sub    $0xc,%esp
f0103a4f:	6a 00                	push   $0x0
f0103a51:	e8 d2 cb ff ff       	call   f0100628 <iscons>
f0103a56:	89 c7                	mov    %eax,%edi
f0103a58:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103a5b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103a60:	e8 b2 cb ff ff       	call   f0100617 <getchar>
f0103a65:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103a67:	85 c0                	test   %eax,%eax
f0103a69:	79 18                	jns    f0103a83 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103a6b:	83 ec 08             	sub    $0x8,%esp
f0103a6e:	50                   	push   %eax
f0103a6f:	68 c0 58 10 f0       	push   $0xf01058c0
f0103a74:	e8 d5 f2 ff ff       	call   f0102d4e <cprintf>
			return NULL;
f0103a79:	83 c4 10             	add    $0x10,%esp
f0103a7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a81:	eb 79                	jmp    f0103afc <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103a83:	83 f8 08             	cmp    $0x8,%eax
f0103a86:	0f 94 c2             	sete   %dl
f0103a89:	83 f8 7f             	cmp    $0x7f,%eax
f0103a8c:	0f 94 c0             	sete   %al
f0103a8f:	08 c2                	or     %al,%dl
f0103a91:	74 1a                	je     f0103aad <readline+0x82>
f0103a93:	85 f6                	test   %esi,%esi
f0103a95:	7e 16                	jle    f0103aad <readline+0x82>
			if (echoing)
f0103a97:	85 ff                	test   %edi,%edi
f0103a99:	74 0d                	je     f0103aa8 <readline+0x7d>
				cputchar('\b');
f0103a9b:	83 ec 0c             	sub    $0xc,%esp
f0103a9e:	6a 08                	push   $0x8
f0103aa0:	e8 62 cb ff ff       	call   f0100607 <cputchar>
f0103aa5:	83 c4 10             	add    $0x10,%esp
			i--;
f0103aa8:	83 ee 01             	sub    $0x1,%esi
f0103aab:	eb b3                	jmp    f0103a60 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103aad:	83 fb 1f             	cmp    $0x1f,%ebx
f0103ab0:	7e 23                	jle    f0103ad5 <readline+0xaa>
f0103ab2:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103ab8:	7f 1b                	jg     f0103ad5 <readline+0xaa>
			if (echoing)
f0103aba:	85 ff                	test   %edi,%edi
f0103abc:	74 0c                	je     f0103aca <readline+0x9f>
				cputchar(c);
f0103abe:	83 ec 0c             	sub    $0xc,%esp
f0103ac1:	53                   	push   %ebx
f0103ac2:	e8 40 cb ff ff       	call   f0100607 <cputchar>
f0103ac7:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103aca:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0103ad0:	8d 76 01             	lea    0x1(%esi),%esi
f0103ad3:	eb 8b                	jmp    f0103a60 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103ad5:	83 fb 0a             	cmp    $0xa,%ebx
f0103ad8:	74 05                	je     f0103adf <readline+0xb4>
f0103ada:	83 fb 0d             	cmp    $0xd,%ebx
f0103add:	75 81                	jne    f0103a60 <readline+0x35>
			if (echoing)
f0103adf:	85 ff                	test   %edi,%edi
f0103ae1:	74 0d                	je     f0103af0 <readline+0xc5>
				cputchar('\n');
f0103ae3:	83 ec 0c             	sub    $0xc,%esp
f0103ae6:	6a 0a                	push   $0xa
f0103ae8:	e8 1a cb ff ff       	call   f0100607 <cputchar>
f0103aed:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103af0:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0103af7:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f0103afc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103aff:	5b                   	pop    %ebx
f0103b00:	5e                   	pop    %esi
f0103b01:	5f                   	pop    %edi
f0103b02:	5d                   	pop    %ebp
f0103b03:	c3                   	ret    

f0103b04 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b04:	55                   	push   %ebp
f0103b05:	89 e5                	mov    %esp,%ebp
f0103b07:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b0f:	eb 03                	jmp    f0103b14 <strlen+0x10>
		n++;
f0103b11:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b14:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b18:	75 f7                	jne    f0103b11 <strlen+0xd>
		n++;
	return n;
}
f0103b1a:	5d                   	pop    %ebp
f0103b1b:	c3                   	ret    

f0103b1c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b1c:	55                   	push   %ebp
f0103b1d:	89 e5                	mov    %esp,%ebp
f0103b1f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b22:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b25:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b2a:	eb 03                	jmp    f0103b2f <strnlen+0x13>
		n++;
f0103b2c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b2f:	39 c2                	cmp    %eax,%edx
f0103b31:	74 08                	je     f0103b3b <strnlen+0x1f>
f0103b33:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103b37:	75 f3                	jne    f0103b2c <strnlen+0x10>
f0103b39:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103b3b:	5d                   	pop    %ebp
f0103b3c:	c3                   	ret    

f0103b3d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b3d:	55                   	push   %ebp
f0103b3e:	89 e5                	mov    %esp,%ebp
f0103b40:	53                   	push   %ebx
f0103b41:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b44:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103b47:	89 c2                	mov    %eax,%edx
f0103b49:	83 c2 01             	add    $0x1,%edx
f0103b4c:	83 c1 01             	add    $0x1,%ecx
f0103b4f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103b53:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103b56:	84 db                	test   %bl,%bl
f0103b58:	75 ef                	jne    f0103b49 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103b5a:	5b                   	pop    %ebx
f0103b5b:	5d                   	pop    %ebp
f0103b5c:	c3                   	ret    

f0103b5d <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103b5d:	55                   	push   %ebp
f0103b5e:	89 e5                	mov    %esp,%ebp
f0103b60:	53                   	push   %ebx
f0103b61:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103b64:	53                   	push   %ebx
f0103b65:	e8 9a ff ff ff       	call   f0103b04 <strlen>
f0103b6a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103b6d:	ff 75 0c             	pushl  0xc(%ebp)
f0103b70:	01 d8                	add    %ebx,%eax
f0103b72:	50                   	push   %eax
f0103b73:	e8 c5 ff ff ff       	call   f0103b3d <strcpy>
	return dst;
}
f0103b78:	89 d8                	mov    %ebx,%eax
f0103b7a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b7d:	c9                   	leave  
f0103b7e:	c3                   	ret    

f0103b7f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b7f:	55                   	push   %ebp
f0103b80:	89 e5                	mov    %esp,%ebp
f0103b82:	56                   	push   %esi
f0103b83:	53                   	push   %ebx
f0103b84:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b87:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b8a:	89 f3                	mov    %esi,%ebx
f0103b8c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b8f:	89 f2                	mov    %esi,%edx
f0103b91:	eb 0f                	jmp    f0103ba2 <strncpy+0x23>
		*dst++ = *src;
f0103b93:	83 c2 01             	add    $0x1,%edx
f0103b96:	0f b6 01             	movzbl (%ecx),%eax
f0103b99:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103b9c:	80 39 01             	cmpb   $0x1,(%ecx)
f0103b9f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ba2:	39 da                	cmp    %ebx,%edx
f0103ba4:	75 ed                	jne    f0103b93 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103ba6:	89 f0                	mov    %esi,%eax
f0103ba8:	5b                   	pop    %ebx
f0103ba9:	5e                   	pop    %esi
f0103baa:	5d                   	pop    %ebp
f0103bab:	c3                   	ret    

f0103bac <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103bac:	55                   	push   %ebp
f0103bad:	89 e5                	mov    %esp,%ebp
f0103baf:	56                   	push   %esi
f0103bb0:	53                   	push   %ebx
f0103bb1:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bb4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103bb7:	8b 55 10             	mov    0x10(%ebp),%edx
f0103bba:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103bbc:	85 d2                	test   %edx,%edx
f0103bbe:	74 21                	je     f0103be1 <strlcpy+0x35>
f0103bc0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103bc4:	89 f2                	mov    %esi,%edx
f0103bc6:	eb 09                	jmp    f0103bd1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103bc8:	83 c2 01             	add    $0x1,%edx
f0103bcb:	83 c1 01             	add    $0x1,%ecx
f0103bce:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103bd1:	39 c2                	cmp    %eax,%edx
f0103bd3:	74 09                	je     f0103bde <strlcpy+0x32>
f0103bd5:	0f b6 19             	movzbl (%ecx),%ebx
f0103bd8:	84 db                	test   %bl,%bl
f0103bda:	75 ec                	jne    f0103bc8 <strlcpy+0x1c>
f0103bdc:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103bde:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103be1:	29 f0                	sub    %esi,%eax
}
f0103be3:	5b                   	pop    %ebx
f0103be4:	5e                   	pop    %esi
f0103be5:	5d                   	pop    %ebp
f0103be6:	c3                   	ret    

f0103be7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103be7:	55                   	push   %ebp
f0103be8:	89 e5                	mov    %esp,%ebp
f0103bea:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bed:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103bf0:	eb 06                	jmp    f0103bf8 <strcmp+0x11>
		p++, q++;
f0103bf2:	83 c1 01             	add    $0x1,%ecx
f0103bf5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103bf8:	0f b6 01             	movzbl (%ecx),%eax
f0103bfb:	84 c0                	test   %al,%al
f0103bfd:	74 04                	je     f0103c03 <strcmp+0x1c>
f0103bff:	3a 02                	cmp    (%edx),%al
f0103c01:	74 ef                	je     f0103bf2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c03:	0f b6 c0             	movzbl %al,%eax
f0103c06:	0f b6 12             	movzbl (%edx),%edx
f0103c09:	29 d0                	sub    %edx,%eax
}
f0103c0b:	5d                   	pop    %ebp
f0103c0c:	c3                   	ret    

f0103c0d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c0d:	55                   	push   %ebp
f0103c0e:	89 e5                	mov    %esp,%ebp
f0103c10:	53                   	push   %ebx
f0103c11:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c14:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c17:	89 c3                	mov    %eax,%ebx
f0103c19:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c1c:	eb 06                	jmp    f0103c24 <strncmp+0x17>
		n--, p++, q++;
f0103c1e:	83 c0 01             	add    $0x1,%eax
f0103c21:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103c24:	39 d8                	cmp    %ebx,%eax
f0103c26:	74 15                	je     f0103c3d <strncmp+0x30>
f0103c28:	0f b6 08             	movzbl (%eax),%ecx
f0103c2b:	84 c9                	test   %cl,%cl
f0103c2d:	74 04                	je     f0103c33 <strncmp+0x26>
f0103c2f:	3a 0a                	cmp    (%edx),%cl
f0103c31:	74 eb                	je     f0103c1e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c33:	0f b6 00             	movzbl (%eax),%eax
f0103c36:	0f b6 12             	movzbl (%edx),%edx
f0103c39:	29 d0                	sub    %edx,%eax
f0103c3b:	eb 05                	jmp    f0103c42 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103c3d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103c42:	5b                   	pop    %ebx
f0103c43:	5d                   	pop    %ebp
f0103c44:	c3                   	ret    

f0103c45 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c45:	55                   	push   %ebp
f0103c46:	89 e5                	mov    %esp,%ebp
f0103c48:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c4b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c4f:	eb 07                	jmp    f0103c58 <strchr+0x13>
		if (*s == c)
f0103c51:	38 ca                	cmp    %cl,%dl
f0103c53:	74 0f                	je     f0103c64 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103c55:	83 c0 01             	add    $0x1,%eax
f0103c58:	0f b6 10             	movzbl (%eax),%edx
f0103c5b:	84 d2                	test   %dl,%dl
f0103c5d:	75 f2                	jne    f0103c51 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103c5f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c64:	5d                   	pop    %ebp
f0103c65:	c3                   	ret    

f0103c66 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103c66:	55                   	push   %ebp
f0103c67:	89 e5                	mov    %esp,%ebp
f0103c69:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c6c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c70:	eb 03                	jmp    f0103c75 <strfind+0xf>
f0103c72:	83 c0 01             	add    $0x1,%eax
f0103c75:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c78:	38 ca                	cmp    %cl,%dl
f0103c7a:	74 04                	je     f0103c80 <strfind+0x1a>
f0103c7c:	84 d2                	test   %dl,%dl
f0103c7e:	75 f2                	jne    f0103c72 <strfind+0xc>
			break;
	return (char *) s;
}
f0103c80:	5d                   	pop    %ebp
f0103c81:	c3                   	ret    

f0103c82 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c82:	55                   	push   %ebp
f0103c83:	89 e5                	mov    %esp,%ebp
f0103c85:	57                   	push   %edi
f0103c86:	56                   	push   %esi
f0103c87:	53                   	push   %ebx
f0103c88:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c8b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103c8e:	85 c9                	test   %ecx,%ecx
f0103c90:	74 36                	je     f0103cc8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c92:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c98:	75 28                	jne    f0103cc2 <memset+0x40>
f0103c9a:	f6 c1 03             	test   $0x3,%cl
f0103c9d:	75 23                	jne    f0103cc2 <memset+0x40>
		c &= 0xFF;
f0103c9f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103ca3:	89 d3                	mov    %edx,%ebx
f0103ca5:	c1 e3 08             	shl    $0x8,%ebx
f0103ca8:	89 d6                	mov    %edx,%esi
f0103caa:	c1 e6 18             	shl    $0x18,%esi
f0103cad:	89 d0                	mov    %edx,%eax
f0103caf:	c1 e0 10             	shl    $0x10,%eax
f0103cb2:	09 f0                	or     %esi,%eax
f0103cb4:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103cb6:	89 d8                	mov    %ebx,%eax
f0103cb8:	09 d0                	or     %edx,%eax
f0103cba:	c1 e9 02             	shr    $0x2,%ecx
f0103cbd:	fc                   	cld    
f0103cbe:	f3 ab                	rep stos %eax,%es:(%edi)
f0103cc0:	eb 06                	jmp    f0103cc8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103cc2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cc5:	fc                   	cld    
f0103cc6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103cc8:	89 f8                	mov    %edi,%eax
f0103cca:	5b                   	pop    %ebx
f0103ccb:	5e                   	pop    %esi
f0103ccc:	5f                   	pop    %edi
f0103ccd:	5d                   	pop    %ebp
f0103cce:	c3                   	ret    

f0103ccf <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ccf:	55                   	push   %ebp
f0103cd0:	89 e5                	mov    %esp,%ebp
f0103cd2:	57                   	push   %edi
f0103cd3:	56                   	push   %esi
f0103cd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cd7:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103cda:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103cdd:	39 c6                	cmp    %eax,%esi
f0103cdf:	73 35                	jae    f0103d16 <memmove+0x47>
f0103ce1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103ce4:	39 d0                	cmp    %edx,%eax
f0103ce6:	73 2e                	jae    f0103d16 <memmove+0x47>
		s += n;
		d += n;
f0103ce8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ceb:	89 d6                	mov    %edx,%esi
f0103ced:	09 fe                	or     %edi,%esi
f0103cef:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103cf5:	75 13                	jne    f0103d0a <memmove+0x3b>
f0103cf7:	f6 c1 03             	test   $0x3,%cl
f0103cfa:	75 0e                	jne    f0103d0a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103cfc:	83 ef 04             	sub    $0x4,%edi
f0103cff:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d02:	c1 e9 02             	shr    $0x2,%ecx
f0103d05:	fd                   	std    
f0103d06:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d08:	eb 09                	jmp    f0103d13 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103d0a:	83 ef 01             	sub    $0x1,%edi
f0103d0d:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103d10:	fd                   	std    
f0103d11:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d13:	fc                   	cld    
f0103d14:	eb 1d                	jmp    f0103d33 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d16:	89 f2                	mov    %esi,%edx
f0103d18:	09 c2                	or     %eax,%edx
f0103d1a:	f6 c2 03             	test   $0x3,%dl
f0103d1d:	75 0f                	jne    f0103d2e <memmove+0x5f>
f0103d1f:	f6 c1 03             	test   $0x3,%cl
f0103d22:	75 0a                	jne    f0103d2e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103d24:	c1 e9 02             	shr    $0x2,%ecx
f0103d27:	89 c7                	mov    %eax,%edi
f0103d29:	fc                   	cld    
f0103d2a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d2c:	eb 05                	jmp    f0103d33 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d2e:	89 c7                	mov    %eax,%edi
f0103d30:	fc                   	cld    
f0103d31:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d33:	5e                   	pop    %esi
f0103d34:	5f                   	pop    %edi
f0103d35:	5d                   	pop    %ebp
f0103d36:	c3                   	ret    

f0103d37 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d37:	55                   	push   %ebp
f0103d38:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103d3a:	ff 75 10             	pushl  0x10(%ebp)
f0103d3d:	ff 75 0c             	pushl  0xc(%ebp)
f0103d40:	ff 75 08             	pushl  0x8(%ebp)
f0103d43:	e8 87 ff ff ff       	call   f0103ccf <memmove>
}
f0103d48:	c9                   	leave  
f0103d49:	c3                   	ret    

f0103d4a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103d4a:	55                   	push   %ebp
f0103d4b:	89 e5                	mov    %esp,%ebp
f0103d4d:	56                   	push   %esi
f0103d4e:	53                   	push   %ebx
f0103d4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d52:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d55:	89 c6                	mov    %eax,%esi
f0103d57:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d5a:	eb 1a                	jmp    f0103d76 <memcmp+0x2c>
		if (*s1 != *s2)
f0103d5c:	0f b6 08             	movzbl (%eax),%ecx
f0103d5f:	0f b6 1a             	movzbl (%edx),%ebx
f0103d62:	38 d9                	cmp    %bl,%cl
f0103d64:	74 0a                	je     f0103d70 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103d66:	0f b6 c1             	movzbl %cl,%eax
f0103d69:	0f b6 db             	movzbl %bl,%ebx
f0103d6c:	29 d8                	sub    %ebx,%eax
f0103d6e:	eb 0f                	jmp    f0103d7f <memcmp+0x35>
		s1++, s2++;
f0103d70:	83 c0 01             	add    $0x1,%eax
f0103d73:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d76:	39 f0                	cmp    %esi,%eax
f0103d78:	75 e2                	jne    f0103d5c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d7f:	5b                   	pop    %ebx
f0103d80:	5e                   	pop    %esi
f0103d81:	5d                   	pop    %ebp
f0103d82:	c3                   	ret    

f0103d83 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d83:	55                   	push   %ebp
f0103d84:	89 e5                	mov    %esp,%ebp
f0103d86:	53                   	push   %ebx
f0103d87:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d8a:	89 c1                	mov    %eax,%ecx
f0103d8c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d8f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d93:	eb 0a                	jmp    f0103d9f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d95:	0f b6 10             	movzbl (%eax),%edx
f0103d98:	39 da                	cmp    %ebx,%edx
f0103d9a:	74 07                	je     f0103da3 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d9c:	83 c0 01             	add    $0x1,%eax
f0103d9f:	39 c8                	cmp    %ecx,%eax
f0103da1:	72 f2                	jb     f0103d95 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103da3:	5b                   	pop    %ebx
f0103da4:	5d                   	pop    %ebp
f0103da5:	c3                   	ret    

f0103da6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103da6:	55                   	push   %ebp
f0103da7:	89 e5                	mov    %esp,%ebp
f0103da9:	57                   	push   %edi
f0103daa:	56                   	push   %esi
f0103dab:	53                   	push   %ebx
f0103dac:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103daf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103db2:	eb 03                	jmp    f0103db7 <strtol+0x11>
		s++;
f0103db4:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103db7:	0f b6 01             	movzbl (%ecx),%eax
f0103dba:	3c 20                	cmp    $0x20,%al
f0103dbc:	74 f6                	je     f0103db4 <strtol+0xe>
f0103dbe:	3c 09                	cmp    $0x9,%al
f0103dc0:	74 f2                	je     f0103db4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103dc2:	3c 2b                	cmp    $0x2b,%al
f0103dc4:	75 0a                	jne    f0103dd0 <strtol+0x2a>
		s++;
f0103dc6:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103dc9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103dce:	eb 11                	jmp    f0103de1 <strtol+0x3b>
f0103dd0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103dd5:	3c 2d                	cmp    $0x2d,%al
f0103dd7:	75 08                	jne    f0103de1 <strtol+0x3b>
		s++, neg = 1;
f0103dd9:	83 c1 01             	add    $0x1,%ecx
f0103ddc:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103de1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103de7:	75 15                	jne    f0103dfe <strtol+0x58>
f0103de9:	80 39 30             	cmpb   $0x30,(%ecx)
f0103dec:	75 10                	jne    f0103dfe <strtol+0x58>
f0103dee:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103df2:	75 7c                	jne    f0103e70 <strtol+0xca>
		s += 2, base = 16;
f0103df4:	83 c1 02             	add    $0x2,%ecx
f0103df7:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103dfc:	eb 16                	jmp    f0103e14 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103dfe:	85 db                	test   %ebx,%ebx
f0103e00:	75 12                	jne    f0103e14 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e02:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e07:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e0a:	75 08                	jne    f0103e14 <strtol+0x6e>
		s++, base = 8;
f0103e0c:	83 c1 01             	add    $0x1,%ecx
f0103e0f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103e14:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e19:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103e1c:	0f b6 11             	movzbl (%ecx),%edx
f0103e1f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103e22:	89 f3                	mov    %esi,%ebx
f0103e24:	80 fb 09             	cmp    $0x9,%bl
f0103e27:	77 08                	ja     f0103e31 <strtol+0x8b>
			dig = *s - '0';
f0103e29:	0f be d2             	movsbl %dl,%edx
f0103e2c:	83 ea 30             	sub    $0x30,%edx
f0103e2f:	eb 22                	jmp    f0103e53 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103e31:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e34:	89 f3                	mov    %esi,%ebx
f0103e36:	80 fb 19             	cmp    $0x19,%bl
f0103e39:	77 08                	ja     f0103e43 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103e3b:	0f be d2             	movsbl %dl,%edx
f0103e3e:	83 ea 57             	sub    $0x57,%edx
f0103e41:	eb 10                	jmp    f0103e53 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103e43:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103e46:	89 f3                	mov    %esi,%ebx
f0103e48:	80 fb 19             	cmp    $0x19,%bl
f0103e4b:	77 16                	ja     f0103e63 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103e4d:	0f be d2             	movsbl %dl,%edx
f0103e50:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103e53:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103e56:	7d 0b                	jge    f0103e63 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103e58:	83 c1 01             	add    $0x1,%ecx
f0103e5b:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103e5f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103e61:	eb b9                	jmp    f0103e1c <strtol+0x76>

	if (endptr)
f0103e63:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e67:	74 0d                	je     f0103e76 <strtol+0xd0>
		*endptr = (char *) s;
f0103e69:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e6c:	89 0e                	mov    %ecx,(%esi)
f0103e6e:	eb 06                	jmp    f0103e76 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e70:	85 db                	test   %ebx,%ebx
f0103e72:	74 98                	je     f0103e0c <strtol+0x66>
f0103e74:	eb 9e                	jmp    f0103e14 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103e76:	89 c2                	mov    %eax,%edx
f0103e78:	f7 da                	neg    %edx
f0103e7a:	85 ff                	test   %edi,%edi
f0103e7c:	0f 45 c2             	cmovne %edx,%eax
}
f0103e7f:	5b                   	pop    %ebx
f0103e80:	5e                   	pop    %esi
f0103e81:	5f                   	pop    %edi
f0103e82:	5d                   	pop    %ebp
f0103e83:	c3                   	ret    
f0103e84:	66 90                	xchg   %ax,%ax
f0103e86:	66 90                	xchg   %ax,%ax
f0103e88:	66 90                	xchg   %ax,%ax
f0103e8a:	66 90                	xchg   %ax,%ax
f0103e8c:	66 90                	xchg   %ax,%ax
f0103e8e:	66 90                	xchg   %ax,%ax

f0103e90 <__udivdi3>:
f0103e90:	55                   	push   %ebp
f0103e91:	57                   	push   %edi
f0103e92:	56                   	push   %esi
f0103e93:	53                   	push   %ebx
f0103e94:	83 ec 1c             	sub    $0x1c,%esp
f0103e97:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103e9b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103e9f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103ea3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ea7:	85 f6                	test   %esi,%esi
f0103ea9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103ead:	89 ca                	mov    %ecx,%edx
f0103eaf:	89 f8                	mov    %edi,%eax
f0103eb1:	75 3d                	jne    f0103ef0 <__udivdi3+0x60>
f0103eb3:	39 cf                	cmp    %ecx,%edi
f0103eb5:	0f 87 c5 00 00 00    	ja     f0103f80 <__udivdi3+0xf0>
f0103ebb:	85 ff                	test   %edi,%edi
f0103ebd:	89 fd                	mov    %edi,%ebp
f0103ebf:	75 0b                	jne    f0103ecc <__udivdi3+0x3c>
f0103ec1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ec6:	31 d2                	xor    %edx,%edx
f0103ec8:	f7 f7                	div    %edi
f0103eca:	89 c5                	mov    %eax,%ebp
f0103ecc:	89 c8                	mov    %ecx,%eax
f0103ece:	31 d2                	xor    %edx,%edx
f0103ed0:	f7 f5                	div    %ebp
f0103ed2:	89 c1                	mov    %eax,%ecx
f0103ed4:	89 d8                	mov    %ebx,%eax
f0103ed6:	89 cf                	mov    %ecx,%edi
f0103ed8:	f7 f5                	div    %ebp
f0103eda:	89 c3                	mov    %eax,%ebx
f0103edc:	89 d8                	mov    %ebx,%eax
f0103ede:	89 fa                	mov    %edi,%edx
f0103ee0:	83 c4 1c             	add    $0x1c,%esp
f0103ee3:	5b                   	pop    %ebx
f0103ee4:	5e                   	pop    %esi
f0103ee5:	5f                   	pop    %edi
f0103ee6:	5d                   	pop    %ebp
f0103ee7:	c3                   	ret    
f0103ee8:	90                   	nop
f0103ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ef0:	39 ce                	cmp    %ecx,%esi
f0103ef2:	77 74                	ja     f0103f68 <__udivdi3+0xd8>
f0103ef4:	0f bd fe             	bsr    %esi,%edi
f0103ef7:	83 f7 1f             	xor    $0x1f,%edi
f0103efa:	0f 84 98 00 00 00    	je     f0103f98 <__udivdi3+0x108>
f0103f00:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103f05:	89 f9                	mov    %edi,%ecx
f0103f07:	89 c5                	mov    %eax,%ebp
f0103f09:	29 fb                	sub    %edi,%ebx
f0103f0b:	d3 e6                	shl    %cl,%esi
f0103f0d:	89 d9                	mov    %ebx,%ecx
f0103f0f:	d3 ed                	shr    %cl,%ebp
f0103f11:	89 f9                	mov    %edi,%ecx
f0103f13:	d3 e0                	shl    %cl,%eax
f0103f15:	09 ee                	or     %ebp,%esi
f0103f17:	89 d9                	mov    %ebx,%ecx
f0103f19:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f1d:	89 d5                	mov    %edx,%ebp
f0103f1f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f23:	d3 ed                	shr    %cl,%ebp
f0103f25:	89 f9                	mov    %edi,%ecx
f0103f27:	d3 e2                	shl    %cl,%edx
f0103f29:	89 d9                	mov    %ebx,%ecx
f0103f2b:	d3 e8                	shr    %cl,%eax
f0103f2d:	09 c2                	or     %eax,%edx
f0103f2f:	89 d0                	mov    %edx,%eax
f0103f31:	89 ea                	mov    %ebp,%edx
f0103f33:	f7 f6                	div    %esi
f0103f35:	89 d5                	mov    %edx,%ebp
f0103f37:	89 c3                	mov    %eax,%ebx
f0103f39:	f7 64 24 0c          	mull   0xc(%esp)
f0103f3d:	39 d5                	cmp    %edx,%ebp
f0103f3f:	72 10                	jb     f0103f51 <__udivdi3+0xc1>
f0103f41:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103f45:	89 f9                	mov    %edi,%ecx
f0103f47:	d3 e6                	shl    %cl,%esi
f0103f49:	39 c6                	cmp    %eax,%esi
f0103f4b:	73 07                	jae    f0103f54 <__udivdi3+0xc4>
f0103f4d:	39 d5                	cmp    %edx,%ebp
f0103f4f:	75 03                	jne    f0103f54 <__udivdi3+0xc4>
f0103f51:	83 eb 01             	sub    $0x1,%ebx
f0103f54:	31 ff                	xor    %edi,%edi
f0103f56:	89 d8                	mov    %ebx,%eax
f0103f58:	89 fa                	mov    %edi,%edx
f0103f5a:	83 c4 1c             	add    $0x1c,%esp
f0103f5d:	5b                   	pop    %ebx
f0103f5e:	5e                   	pop    %esi
f0103f5f:	5f                   	pop    %edi
f0103f60:	5d                   	pop    %ebp
f0103f61:	c3                   	ret    
f0103f62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f68:	31 ff                	xor    %edi,%edi
f0103f6a:	31 db                	xor    %ebx,%ebx
f0103f6c:	89 d8                	mov    %ebx,%eax
f0103f6e:	89 fa                	mov    %edi,%edx
f0103f70:	83 c4 1c             	add    $0x1c,%esp
f0103f73:	5b                   	pop    %ebx
f0103f74:	5e                   	pop    %esi
f0103f75:	5f                   	pop    %edi
f0103f76:	5d                   	pop    %ebp
f0103f77:	c3                   	ret    
f0103f78:	90                   	nop
f0103f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f80:	89 d8                	mov    %ebx,%eax
f0103f82:	f7 f7                	div    %edi
f0103f84:	31 ff                	xor    %edi,%edi
f0103f86:	89 c3                	mov    %eax,%ebx
f0103f88:	89 d8                	mov    %ebx,%eax
f0103f8a:	89 fa                	mov    %edi,%edx
f0103f8c:	83 c4 1c             	add    $0x1c,%esp
f0103f8f:	5b                   	pop    %ebx
f0103f90:	5e                   	pop    %esi
f0103f91:	5f                   	pop    %edi
f0103f92:	5d                   	pop    %ebp
f0103f93:	c3                   	ret    
f0103f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f98:	39 ce                	cmp    %ecx,%esi
f0103f9a:	72 0c                	jb     f0103fa8 <__udivdi3+0x118>
f0103f9c:	31 db                	xor    %ebx,%ebx
f0103f9e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103fa2:	0f 87 34 ff ff ff    	ja     f0103edc <__udivdi3+0x4c>
f0103fa8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103fad:	e9 2a ff ff ff       	jmp    f0103edc <__udivdi3+0x4c>
f0103fb2:	66 90                	xchg   %ax,%ax
f0103fb4:	66 90                	xchg   %ax,%ax
f0103fb6:	66 90                	xchg   %ax,%ax
f0103fb8:	66 90                	xchg   %ax,%ax
f0103fba:	66 90                	xchg   %ax,%ax
f0103fbc:	66 90                	xchg   %ax,%ax
f0103fbe:	66 90                	xchg   %ax,%ax

f0103fc0 <__umoddi3>:
f0103fc0:	55                   	push   %ebp
f0103fc1:	57                   	push   %edi
f0103fc2:	56                   	push   %esi
f0103fc3:	53                   	push   %ebx
f0103fc4:	83 ec 1c             	sub    $0x1c,%esp
f0103fc7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103fcb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103fcf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103fd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103fd7:	85 d2                	test   %edx,%edx
f0103fd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103fdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fe1:	89 f3                	mov    %esi,%ebx
f0103fe3:	89 3c 24             	mov    %edi,(%esp)
f0103fe6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103fea:	75 1c                	jne    f0104008 <__umoddi3+0x48>
f0103fec:	39 f7                	cmp    %esi,%edi
f0103fee:	76 50                	jbe    f0104040 <__umoddi3+0x80>
f0103ff0:	89 c8                	mov    %ecx,%eax
f0103ff2:	89 f2                	mov    %esi,%edx
f0103ff4:	f7 f7                	div    %edi
f0103ff6:	89 d0                	mov    %edx,%eax
f0103ff8:	31 d2                	xor    %edx,%edx
f0103ffa:	83 c4 1c             	add    $0x1c,%esp
f0103ffd:	5b                   	pop    %ebx
f0103ffe:	5e                   	pop    %esi
f0103fff:	5f                   	pop    %edi
f0104000:	5d                   	pop    %ebp
f0104001:	c3                   	ret    
f0104002:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104008:	39 f2                	cmp    %esi,%edx
f010400a:	89 d0                	mov    %edx,%eax
f010400c:	77 52                	ja     f0104060 <__umoddi3+0xa0>
f010400e:	0f bd ea             	bsr    %edx,%ebp
f0104011:	83 f5 1f             	xor    $0x1f,%ebp
f0104014:	75 5a                	jne    f0104070 <__umoddi3+0xb0>
f0104016:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010401a:	0f 82 e0 00 00 00    	jb     f0104100 <__umoddi3+0x140>
f0104020:	39 0c 24             	cmp    %ecx,(%esp)
f0104023:	0f 86 d7 00 00 00    	jbe    f0104100 <__umoddi3+0x140>
f0104029:	8b 44 24 08          	mov    0x8(%esp),%eax
f010402d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104031:	83 c4 1c             	add    $0x1c,%esp
f0104034:	5b                   	pop    %ebx
f0104035:	5e                   	pop    %esi
f0104036:	5f                   	pop    %edi
f0104037:	5d                   	pop    %ebp
f0104038:	c3                   	ret    
f0104039:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104040:	85 ff                	test   %edi,%edi
f0104042:	89 fd                	mov    %edi,%ebp
f0104044:	75 0b                	jne    f0104051 <__umoddi3+0x91>
f0104046:	b8 01 00 00 00       	mov    $0x1,%eax
f010404b:	31 d2                	xor    %edx,%edx
f010404d:	f7 f7                	div    %edi
f010404f:	89 c5                	mov    %eax,%ebp
f0104051:	89 f0                	mov    %esi,%eax
f0104053:	31 d2                	xor    %edx,%edx
f0104055:	f7 f5                	div    %ebp
f0104057:	89 c8                	mov    %ecx,%eax
f0104059:	f7 f5                	div    %ebp
f010405b:	89 d0                	mov    %edx,%eax
f010405d:	eb 99                	jmp    f0103ff8 <__umoddi3+0x38>
f010405f:	90                   	nop
f0104060:	89 c8                	mov    %ecx,%eax
f0104062:	89 f2                	mov    %esi,%edx
f0104064:	83 c4 1c             	add    $0x1c,%esp
f0104067:	5b                   	pop    %ebx
f0104068:	5e                   	pop    %esi
f0104069:	5f                   	pop    %edi
f010406a:	5d                   	pop    %ebp
f010406b:	c3                   	ret    
f010406c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104070:	8b 34 24             	mov    (%esp),%esi
f0104073:	bf 20 00 00 00       	mov    $0x20,%edi
f0104078:	89 e9                	mov    %ebp,%ecx
f010407a:	29 ef                	sub    %ebp,%edi
f010407c:	d3 e0                	shl    %cl,%eax
f010407e:	89 f9                	mov    %edi,%ecx
f0104080:	89 f2                	mov    %esi,%edx
f0104082:	d3 ea                	shr    %cl,%edx
f0104084:	89 e9                	mov    %ebp,%ecx
f0104086:	09 c2                	or     %eax,%edx
f0104088:	89 d8                	mov    %ebx,%eax
f010408a:	89 14 24             	mov    %edx,(%esp)
f010408d:	89 f2                	mov    %esi,%edx
f010408f:	d3 e2                	shl    %cl,%edx
f0104091:	89 f9                	mov    %edi,%ecx
f0104093:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104097:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010409b:	d3 e8                	shr    %cl,%eax
f010409d:	89 e9                	mov    %ebp,%ecx
f010409f:	89 c6                	mov    %eax,%esi
f01040a1:	d3 e3                	shl    %cl,%ebx
f01040a3:	89 f9                	mov    %edi,%ecx
f01040a5:	89 d0                	mov    %edx,%eax
f01040a7:	d3 e8                	shr    %cl,%eax
f01040a9:	89 e9                	mov    %ebp,%ecx
f01040ab:	09 d8                	or     %ebx,%eax
f01040ad:	89 d3                	mov    %edx,%ebx
f01040af:	89 f2                	mov    %esi,%edx
f01040b1:	f7 34 24             	divl   (%esp)
f01040b4:	89 d6                	mov    %edx,%esi
f01040b6:	d3 e3                	shl    %cl,%ebx
f01040b8:	f7 64 24 04          	mull   0x4(%esp)
f01040bc:	39 d6                	cmp    %edx,%esi
f01040be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01040c2:	89 d1                	mov    %edx,%ecx
f01040c4:	89 c3                	mov    %eax,%ebx
f01040c6:	72 08                	jb     f01040d0 <__umoddi3+0x110>
f01040c8:	75 11                	jne    f01040db <__umoddi3+0x11b>
f01040ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01040ce:	73 0b                	jae    f01040db <__umoddi3+0x11b>
f01040d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01040d4:	1b 14 24             	sbb    (%esp),%edx
f01040d7:	89 d1                	mov    %edx,%ecx
f01040d9:	89 c3                	mov    %eax,%ebx
f01040db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01040df:	29 da                	sub    %ebx,%edx
f01040e1:	19 ce                	sbb    %ecx,%esi
f01040e3:	89 f9                	mov    %edi,%ecx
f01040e5:	89 f0                	mov    %esi,%eax
f01040e7:	d3 e0                	shl    %cl,%eax
f01040e9:	89 e9                	mov    %ebp,%ecx
f01040eb:	d3 ea                	shr    %cl,%edx
f01040ed:	89 e9                	mov    %ebp,%ecx
f01040ef:	d3 ee                	shr    %cl,%esi
f01040f1:	09 d0                	or     %edx,%eax
f01040f3:	89 f2                	mov    %esi,%edx
f01040f5:	83 c4 1c             	add    $0x1c,%esp
f01040f8:	5b                   	pop    %ebx
f01040f9:	5e                   	pop    %esi
f01040fa:	5f                   	pop    %edi
f01040fb:	5d                   	pop    %ebp
f01040fc:	c3                   	ret    
f01040fd:	8d 76 00             	lea    0x0(%esi),%esi
f0104100:	29 f9                	sub    %edi,%ecx
f0104102:	19 d6                	sbb    %edx,%esi
f0104104:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104108:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010410c:	e9 18 ff ff ff       	jmp    f0104029 <__umoddi3+0x69>
