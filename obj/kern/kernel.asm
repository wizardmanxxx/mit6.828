
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
f0100058:	e8 c8 3b 00 00       	call   f0103c25 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// 在此之前无法调用cprintf
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 40 10 f0       	push   $0xf01040c0
f010006f:	e8 7d 2c 00 00       	call   f0102cf1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 0c 11 00 00       	call   f0101185 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 bd 28 00 00       	call   f010293b <env_init>
	trap_init();
f010007e:	e8 df 2c 00 00       	call   f0102d62 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 cd 29 00 00       	call   f0102a5f <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 be 17 f0    	pushl  0xf017be48
f010009b:	e8 d0 2b 00 00       	call   f0102c70 <env_run>

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
f01000c5:	68 db 40 10 f0       	push   $0xf01040db
f01000ca:	e8 22 2c 00 00       	call   f0102cf1 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 f2 2b 00 00       	call   f0102ccb <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 a9 49 10 f0 	movl   $0xf01049a9,(%esp)
f01000e0:	e8 0c 2c 00 00       	call   f0102cf1 <cprintf>
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
f0100107:	68 f3 40 10 f0       	push   $0xf01040f3
f010010c:	e8 e0 2b 00 00       	call   f0102cf1 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 ae 2b 00 00       	call   f0102ccb <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 a9 49 10 f0 	movl   $0xf01049a9,(%esp)
f0100124:	e8 c8 2b 00 00       	call   f0102cf1 <cprintf>
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
f01001db:	0f b6 82 60 42 10 f0 	movzbl -0xfefbda0(%edx),%eax
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
f0100217:	0f b6 82 60 42 10 f0 	movzbl -0xfefbda0(%edx),%eax
f010021e:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f0100224:	0f b6 8a 60 41 10 f0 	movzbl -0xfefbea0(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 40 41 10 f0 	mov    -0xfefbec0(,%ecx,4),%ecx
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
f0100275:	68 0d 41 10 f0       	push   $0xf010410d
f010027a:	e8 72 2a 00 00       	call   f0102cf1 <cprintf>
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
f0100423:	e8 4a 38 00 00       	call   f0103c72 <memmove>
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
f01005f2:	68 19 41 10 f0       	push   $0xf0104119
f01005f7:	e8 f5 26 00 00       	call   f0102cf1 <cprintf>
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
f0100637:	bb 00 47 10 f0       	mov    $0xf0104700,%ebx
f010063c:	be 30 47 10 f0       	mov    $0xf0104730,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100641:	83 ec 04             	sub    $0x4,%esp
f0100644:	ff 73 04             	pushl  0x4(%ebx)
f0100647:	ff 33                	pushl  (%ebx)
f0100649:	68 60 43 10 f0       	push   $0xf0104360
f010064e:	e8 9e 26 00 00       	call   f0102cf1 <cprintf>
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
f010066f:	68 69 43 10 f0       	push   $0xf0104369
f0100674:	e8 78 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100679:	83 c4 08             	add    $0x8,%esp
f010067c:	68 0c 00 10 00       	push   $0x10000c
f0100681:	68 50 44 10 f0       	push   $0xf0104450
f0100686:	e8 66 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068b:	83 c4 0c             	add    $0xc,%esp
f010068e:	68 0c 00 10 00       	push   $0x10000c
f0100693:	68 0c 00 10 f0       	push   $0xf010000c
f0100698:	68 78 44 10 f0       	push   $0xf0104478
f010069d:	e8 4f 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a2:	83 c4 0c             	add    $0xc,%esp
f01006a5:	68 b1 40 10 00       	push   $0x1040b1
f01006aa:	68 b1 40 10 f0       	push   $0xf01040b1
f01006af:	68 9c 44 10 f0       	push   $0xf010449c
f01006b4:	e8 38 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b9:	83 c4 0c             	add    $0xc,%esp
f01006bc:	68 ee bb 17 00       	push   $0x17bbee
f01006c1:	68 ee bb 17 f0       	push   $0xf017bbee
f01006c6:	68 c0 44 10 f0       	push   $0xf01044c0
f01006cb:	e8 21 26 00 00       	call   f0102cf1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d0:	83 c4 0c             	add    $0xc,%esp
f01006d3:	68 10 cb 17 00       	push   $0x17cb10
f01006d8:	68 10 cb 17 f0       	push   $0xf017cb10
f01006dd:	68 e4 44 10 f0       	push   $0xf01044e4
f01006e2:	e8 0a 26 00 00       	call   f0102cf1 <cprintf>
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
f0100708:	68 08 45 10 f0       	push   $0xf0104508
f010070d:	e8 df 25 00 00       	call   f0102cf1 <cprintf>
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
f0100724:	68 82 43 10 f0       	push   $0xf0104382
f0100729:	e8 c3 25 00 00       	call   f0102cf1 <cprintf>
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
f0100749:	68 34 45 10 f0       	push   $0xf0104534
f010074e:	e8 9e 25 00 00       	call   f0102cf1 <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f0100753:	83 c4 18             	add    $0x18,%esp
f0100756:	56                   	push   %esi
f0100757:	ff 73 04             	pushl  0x4(%ebx)
f010075a:	e8 46 2a 00 00       	call   f01031a5 <debuginfo_eip>

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
f0100797:	68 94 43 10 f0       	push   $0xf0104394
f010079c:	e8 50 25 00 00       	call   f0102cf1 <cprintf>
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
f01007cc:	68 68 45 10 f0       	push   $0xf0104568
f01007d1:	e8 1b 25 00 00       	call   f0102cf1 <cprintf>
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
f01007ef:	e8 55 35 00 00       	call   f0103d49 <strtol>
f01007f4:	89 c3                	mov    %eax,%ebx
	if (*errChar) {
f01007f6:	83 c4 10             	add    $0x10,%esp
f01007f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007fc:	80 38 00             	cmpb   $0x0,(%eax)
f01007ff:	74 1d                	je     f010081e <mon_showmappings+0x67>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f0100801:	83 ec 08             	sub    $0x8,%esp
f0100804:	ff 76 04             	pushl  0x4(%esi)
f0100807:	68 a3 43 10 f0       	push   $0xf01043a3
f010080c:	e8 e0 24 00 00       	call   f0102cf1 <cprintf>
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
f010082a:	e8 1a 35 00 00       	call   f0103d49 <strtol>
	if(*errChar){
f010082f:	83 c4 10             	add    $0x10,%esp
f0100832:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100835:	80 3a 00             	cmpb   $0x0,(%edx)
f0100838:	74 1d                	je     f0100857 <mon_showmappings+0xa0>
		cprintf("Invalid virtual address: %s.\n", argv[1]);
f010083a:	83 ec 08             	sub    $0x8,%esp
f010083d:	ff 76 04             	pushl  0x4(%esi)
f0100840:	68 a3 43 10 f0       	push   $0xf01043a3
f0100845:	e8 a7 24 00 00       	call   f0102cf1 <cprintf>
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
f010085e:	68 90 45 10 f0       	push   $0xf0104590
f0100863:	e8 89 24 00 00       	call   f0102cf1 <cprintf>
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
f01008b0:	68 b8 45 10 f0       	push   $0xf01045b8
f01008b5:	e8 37 24 00 00       	call   f0102cf1 <cprintf>
			continue;
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	eb 63                	jmp    f0100922 <mon_showmappings+0x16b>
		}
		cprintf( "Virtual address [%08x] - physical address [%08x], permission: ", entry, PTE_ADDR(*entry));
f01008bf:	83 ec 04             	sub    $0x4,%esp
f01008c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008c7:	50                   	push   %eax
f01008c8:	56                   	push   %esi
f01008c9:	68 e0 45 10 f0       	push   $0xf01045e0
f01008ce:	e8 1e 24 00 00       	call   f0102cf1 <cprintf>
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
f0100915:	68 c1 43 10 f0       	push   $0xf01043c1
f010091a:	e8 d2 23 00 00       	call   f0102cf1 <cprintf>
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
f0100946:	68 20 46 10 f0       	push   $0xf0104620
f010094b:	e8 a1 23 00 00       	call   f0102cf1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100950:	c7 04 24 44 46 10 f0 	movl   $0xf0104644,(%esp)
f0100957:	e8 95 23 00 00       	call   f0102cf1 <cprintf>

	if (tf != NULL)
f010095c:	83 c4 10             	add    $0x10,%esp
f010095f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100963:	74 0e                	je     f0100973 <monitor+0x36>
		print_trapframe(tf);
f0100965:	83 ec 0c             	sub    $0xc,%esp
f0100968:	ff 75 08             	pushl  0x8(%ebp)
f010096b:	e8 8a 24 00 00       	call   f0102dfa <print_trapframe>
f0100970:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100973:	83 ec 0c             	sub    $0xc,%esp
f0100976:	68 cf 43 10 f0       	push   $0xf01043cf
f010097b:	e8 4e 30 00 00       	call   f01039ce <readline>
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
f01009af:	68 d3 43 10 f0       	push   $0xf01043d3
f01009b4:	e8 2f 32 00 00       	call   f0103be8 <strchr>
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
f01009cf:	68 d8 43 10 f0       	push   $0xf01043d8
f01009d4:	e8 18 23 00 00       	call   f0102cf1 <cprintf>
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
f01009f8:	68 d3 43 10 f0       	push   $0xf01043d3
f01009fd:	e8 e6 31 00 00       	call   f0103be8 <strchr>
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
f0100a26:	ff 34 85 00 47 10 f0 	pushl  -0xfefb900(,%eax,4)
f0100a2d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a30:	e8 55 31 00 00       	call   f0103b8a <strcmp>
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
f0100a4a:	ff 14 85 08 47 10 f0 	call   *-0xfefb8f8(,%eax,4)
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
f0100a6b:	68 f5 43 10 f0       	push   $0xf01043f5
f0100a70:	e8 7c 22 00 00       	call   f0102cf1 <cprintf>
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
f0100ad5:	68 30 47 10 f0       	push   $0xf0104730
f0100ada:	6a 69                	push   $0x69
f0100adc:	68 40 47 10 f0       	push   $0xf0104740
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
f0100b12:	68 dc 49 10 f0       	push   $0xf01049dc
f0100b17:	68 2b 03 00 00       	push   $0x32b
f0100b1c:	68 40 47 10 f0       	push   $0xf0104740
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
f0100b6a:	68 00 4a 10 f0       	push   $0xf0104a00
f0100b6f:	68 62 02 00 00       	push   $0x262
f0100b74:	68 40 47 10 f0       	push   $0xf0104740
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
f0100bf9:	68 dc 49 10 f0       	push   $0xf01049dc
f0100bfe:	6a 5b                	push   $0x5b
f0100c00:	68 4c 47 10 f0       	push   $0xf010474c
f0100c05:	e8 96 f4 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c0a:	83 ec 04             	sub    $0x4,%esp
f0100c0d:	68 80 00 00 00       	push   $0x80
f0100c12:	68 97 00 00 00       	push   $0x97
f0100c17:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c1c:	50                   	push   %eax
f0100c1d:	e8 03 30 00 00       	call   f0103c25 <memset>
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
f0100c63:	68 5a 47 10 f0       	push   $0xf010475a
f0100c68:	68 66 47 10 f0       	push   $0xf0104766
f0100c6d:	68 7f 02 00 00       	push   $0x27f
f0100c72:	68 40 47 10 f0       	push   $0xf0104740
f0100c77:	e8 24 f4 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100c7c:	39 fa                	cmp    %edi,%edx
f0100c7e:	72 19                	jb     f0100c99 <check_page_free_list+0x148>
f0100c80:	68 7b 47 10 f0       	push   $0xf010477b
f0100c85:	68 66 47 10 f0       	push   $0xf0104766
f0100c8a:	68 80 02 00 00       	push   $0x280
f0100c8f:	68 40 47 10 f0       	push   $0xf0104740
f0100c94:	e8 07 f4 ff ff       	call   f01000a0 <_panic>
		assert(((char *)pp - (char *)pages) % sizeof(*pp) == 0);
f0100c99:	89 d0                	mov    %edx,%eax
f0100c9b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c9e:	a8 07                	test   $0x7,%al
f0100ca0:	74 19                	je     f0100cbb <check_page_free_list+0x16a>
f0100ca2:	68 24 4a 10 f0       	push   $0xf0104a24
f0100ca7:	68 66 47 10 f0       	push   $0xf0104766
f0100cac:	68 81 02 00 00       	push   $0x281
f0100cb1:	68 40 47 10 f0       	push   $0xf0104740
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
f0100cc5:	68 8f 47 10 f0       	push   $0xf010478f
f0100cca:	68 66 47 10 f0       	push   $0xf0104766
f0100ccf:	68 84 02 00 00       	push   $0x284
f0100cd4:	68 40 47 10 f0       	push   $0xf0104740
f0100cd9:	e8 c2 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cde:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ce3:	75 19                	jne    f0100cfe <check_page_free_list+0x1ad>
f0100ce5:	68 a0 47 10 f0       	push   $0xf01047a0
f0100cea:	68 66 47 10 f0       	push   $0xf0104766
f0100cef:	68 85 02 00 00       	push   $0x285
f0100cf4:	68 40 47 10 f0       	push   $0xf0104740
f0100cf9:	e8 a2 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cfe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d03:	75 19                	jne    f0100d1e <check_page_free_list+0x1cd>
f0100d05:	68 54 4a 10 f0       	push   $0xf0104a54
f0100d0a:	68 66 47 10 f0       	push   $0xf0104766
f0100d0f:	68 86 02 00 00       	push   $0x286
f0100d14:	68 40 47 10 f0       	push   $0xf0104740
f0100d19:	e8 82 f3 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d1e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d23:	75 19                	jne    f0100d3e <check_page_free_list+0x1ed>
f0100d25:	68 b9 47 10 f0       	push   $0xf01047b9
f0100d2a:	68 66 47 10 f0       	push   $0xf0104766
f0100d2f:	68 87 02 00 00       	push   $0x287
f0100d34:	68 40 47 10 f0       	push   $0xf0104740
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
f0100d50:	68 dc 49 10 f0       	push   $0xf01049dc
f0100d55:	6a 5b                	push   $0x5b
f0100d57:	68 4c 47 10 f0       	push   $0xf010474c
f0100d5c:	e8 3f f3 ff ff       	call   f01000a0 <_panic>
f0100d61:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d66:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d69:	76 1e                	jbe    f0100d89 <check_page_free_list+0x238>
f0100d6b:	68 78 4a 10 f0       	push   $0xf0104a78
f0100d70:	68 66 47 10 f0       	push   $0xf0104766
f0100d75:	68 88 02 00 00       	push   $0x288
f0100d7a:	68 40 47 10 f0       	push   $0xf0104740
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
f0100d9e:	68 d3 47 10 f0       	push   $0xf01047d3
f0100da3:	68 66 47 10 f0       	push   $0xf0104766
f0100da8:	68 90 02 00 00       	push   $0x290
f0100dad:	68 40 47 10 f0       	push   $0xf0104740
f0100db2:	e8 e9 f2 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100db7:	85 db                	test   %ebx,%ebx
f0100db9:	7f 42                	jg     f0100dfd <check_page_free_list+0x2ac>
f0100dbb:	68 e5 47 10 f0       	push   $0xf01047e5
f0100dc0:	68 66 47 10 f0       	push   $0xf0104766
f0100dc5:	68 91 02 00 00       	push   $0x291
f0100dca:	68 40 47 10 f0       	push   $0xf0104740
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
f0100e4b:	68 bc 4a 10 f0       	push   $0xf0104abc
f0100e50:	68 1f 01 00 00       	push   $0x11f
f0100e55:	68 40 47 10 f0       	push   $0xf0104740
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
f0100efd:	68 dc 49 10 f0       	push   $0xf01049dc
f0100f02:	6a 5b                	push   $0x5b
f0100f04:	68 4c 47 10 f0       	push   $0xf010474c
f0100f09:	e8 92 f1 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(p), 0, PGSIZE);
f0100f0e:	83 ec 04             	sub    $0x4,%esp
f0100f11:	68 00 10 00 00       	push   $0x1000
f0100f16:	6a 00                	push   $0x0
f0100f18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f1d:	50                   	push   %eax
f0100f1e:	e8 02 2d 00 00       	call   f0103c25 <memset>
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
f0100f45:	68 f6 47 10 f0       	push   $0xf01047f6
f0100f4a:	68 59 01 00 00       	push   $0x159
f0100f4f:	68 40 47 10 f0       	push   $0xf0104740
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
f0100fea:	68 dc 49 10 f0       	push   $0xf01049dc
f0100fef:	68 96 01 00 00       	push   $0x196
f0100ff4:	68 40 47 10 f0       	push   $0xf0104740
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
	for (size_t i=0; i<pg_num; i++) {
f0101038:	89 c3                	mov    %eax,%ebx
f010103a:	be 00 00 00 00       	mov    $0x0,%esi
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f010103f:	89 d7                	mov    %edx,%edi
f0101041:	29 c7                	sub    %eax,%edi
		if (!pgtab) {
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
	for (size_t i=0; i<pg_num; i++) {
f010104c:	eb 28                	jmp    f0101076 <boot_map_region+0x53>
		pgtab = pgdir_walk(pgdir, (void *)va, 1);
f010104e:	83 ec 04             	sub    $0x4,%esp
f0101051:	6a 01                	push   $0x1
f0101053:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101056:	50                   	push   %eax
f0101057:	ff 75 e0             	pushl  -0x20(%ebp)
f010105a:	e8 30 ff ff ff       	call   f0100f8f <pgdir_walk>
		if (!pgtab) {
f010105f:	83 c4 10             	add    $0x10,%esp
f0101062:	85 c0                	test   %eax,%eax
f0101064:	74 15                	je     f010107b <boot_map_region+0x58>
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
	for (size_t i=0; i<pg_num; i++) {
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
f01010b7:	68 e0 4a 10 f0       	push   $0xf0104ae0
f01010bc:	6a 54                	push   $0x54
f01010be:	68 4c 47 10 f0       	push   $0xf010474c
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
f0101190:	e8 f5 1a 00 00       	call   f0102c8a <mc146818_read>
f0101195:	89 c3                	mov    %eax,%ebx
f0101197:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010119e:	e8 e7 1a 00 00       	call   f0102c8a <mc146818_read>
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
f01011c5:	e8 c0 1a 00 00       	call   f0102c8a <mc146818_read>
f01011ca:	89 c3                	mov    %eax,%ebx
f01011cc:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011d3:	e8 b2 1a 00 00       	call   f0102c8a <mc146818_read>
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
f010122e:	68 00 4b 10 f0       	push   $0xf0104b00
f0101233:	e8 b9 1a 00 00       	call   f0102cf1 <cprintf>
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
f0101252:	e8 ce 29 00 00       	call   f0103c25 <memset>
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
f0101267:	68 bc 4a 10 f0       	push   $0xf0104abc
f010126c:	68 92 00 00 00       	push   $0x92
f0101271:	68 40 47 10 f0       	push   $0xf0104740
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
f01012b0:	e8 70 29 00 00       	call   f0103c25 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012b5:	e8 4b fb ff ff       	call   f0100e05 <page_init>

	check_page_free_list(1);
f01012ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01012bf:	e8 8d f8 ff ff       	call   f0100b51 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012c4:	83 c4 10             	add    $0x10,%esp
f01012c7:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01012ce:	75 17                	jne    f01012e7 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01012d0:	83 ec 04             	sub    $0x4,%esp
f01012d3:	68 05 48 10 f0       	push   $0xf0104805
f01012d8:	68 a2 02 00 00       	push   $0x2a2
f01012dd:	68 40 47 10 f0       	push   $0xf0104740
f01012e2:	e8 b9 ed ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012e7:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01012ec:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012f1:	eb 05                	jmp    f01012f8 <mem_init+0x173>
		++nfree;
f01012f3:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012f6:	8b 00                	mov    (%eax),%eax
f01012f8:	85 c0                	test   %eax,%eax
f01012fa:	75 f7                	jne    f01012f3 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012fc:	83 ec 0c             	sub    $0xc,%esp
f01012ff:	6a 00                	push   $0x0
f0101301:	e8 b7 fb ff ff       	call   f0100ebd <page_alloc>
f0101306:	89 c7                	mov    %eax,%edi
f0101308:	83 c4 10             	add    $0x10,%esp
f010130b:	85 c0                	test   %eax,%eax
f010130d:	75 19                	jne    f0101328 <mem_init+0x1a3>
f010130f:	68 20 48 10 f0       	push   $0xf0104820
f0101314:	68 66 47 10 f0       	push   $0xf0104766
f0101319:	68 aa 02 00 00       	push   $0x2aa
f010131e:	68 40 47 10 f0       	push   $0xf0104740
f0101323:	e8 78 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101328:	83 ec 0c             	sub    $0xc,%esp
f010132b:	6a 00                	push   $0x0
f010132d:	e8 8b fb ff ff       	call   f0100ebd <page_alloc>
f0101332:	89 c6                	mov    %eax,%esi
f0101334:	83 c4 10             	add    $0x10,%esp
f0101337:	85 c0                	test   %eax,%eax
f0101339:	75 19                	jne    f0101354 <mem_init+0x1cf>
f010133b:	68 36 48 10 f0       	push   $0xf0104836
f0101340:	68 66 47 10 f0       	push   $0xf0104766
f0101345:	68 ab 02 00 00       	push   $0x2ab
f010134a:	68 40 47 10 f0       	push   $0xf0104740
f010134f:	e8 4c ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101354:	83 ec 0c             	sub    $0xc,%esp
f0101357:	6a 00                	push   $0x0
f0101359:	e8 5f fb ff ff       	call   f0100ebd <page_alloc>
f010135e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 19                	jne    f0101381 <mem_init+0x1fc>
f0101368:	68 4c 48 10 f0       	push   $0xf010484c
f010136d:	68 66 47 10 f0       	push   $0xf0104766
f0101372:	68 ac 02 00 00       	push   $0x2ac
f0101377:	68 40 47 10 f0       	push   $0xf0104740
f010137c:	e8 1f ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101381:	39 f7                	cmp    %esi,%edi
f0101383:	75 19                	jne    f010139e <mem_init+0x219>
f0101385:	68 62 48 10 f0       	push   $0xf0104862
f010138a:	68 66 47 10 f0       	push   $0xf0104766
f010138f:	68 af 02 00 00       	push   $0x2af
f0101394:	68 40 47 10 f0       	push   $0xf0104740
f0101399:	e8 02 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010139e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013a1:	39 c6                	cmp    %eax,%esi
f01013a3:	74 04                	je     f01013a9 <mem_init+0x224>
f01013a5:	39 c7                	cmp    %eax,%edi
f01013a7:	75 19                	jne    f01013c2 <mem_init+0x23d>
f01013a9:	68 3c 4b 10 f0       	push   $0xf0104b3c
f01013ae:	68 66 47 10 f0       	push   $0xf0104766
f01013b3:	68 b0 02 00 00       	push   $0x2b0
f01013b8:	68 40 47 10 f0       	push   $0xf0104740
f01013bd:	e8 de ec ff ff       	call   f01000a0 <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01013c2:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages * PGSIZE);
f01013c8:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01013ce:	c1 e2 0c             	shl    $0xc,%edx
f01013d1:	89 f8                	mov    %edi,%eax
f01013d3:	29 c8                	sub    %ecx,%eax
f01013d5:	c1 f8 03             	sar    $0x3,%eax
f01013d8:	c1 e0 0c             	shl    $0xc,%eax
f01013db:	39 d0                	cmp    %edx,%eax
f01013dd:	72 19                	jb     f01013f8 <mem_init+0x273>
f01013df:	68 5c 4b 10 f0       	push   $0xf0104b5c
f01013e4:	68 66 47 10 f0       	push   $0xf0104766
f01013e9:	68 b1 02 00 00       	push   $0x2b1
f01013ee:	68 40 47 10 f0       	push   $0xf0104740
f01013f3:	e8 a8 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f01013f8:	89 f0                	mov    %esi,%eax
f01013fa:	29 c8                	sub    %ecx,%eax
f01013fc:	c1 f8 03             	sar    $0x3,%eax
f01013ff:	c1 e0 0c             	shl    $0xc,%eax
f0101402:	39 c2                	cmp    %eax,%edx
f0101404:	77 19                	ja     f010141f <mem_init+0x29a>
f0101406:	68 7c 4b 10 f0       	push   $0xf0104b7c
f010140b:	68 66 47 10 f0       	push   $0xf0104766
f0101410:	68 b2 02 00 00       	push   $0x2b2
f0101415:	68 40 47 10 f0       	push   $0xf0104740
f010141a:	e8 81 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f010141f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101422:	29 c8                	sub    %ecx,%eax
f0101424:	c1 f8 03             	sar    $0x3,%eax
f0101427:	c1 e0 0c             	shl    $0xc,%eax
f010142a:	39 c2                	cmp    %eax,%edx
f010142c:	77 19                	ja     f0101447 <mem_init+0x2c2>
f010142e:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0101433:	68 66 47 10 f0       	push   $0xf0104766
f0101438:	68 b3 02 00 00       	push   $0x2b3
f010143d:	68 40 47 10 f0       	push   $0xf0104740
f0101442:	e8 59 ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101447:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f010144c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010144f:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0101456:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101459:	83 ec 0c             	sub    $0xc,%esp
f010145c:	6a 00                	push   $0x0
f010145e:	e8 5a fa ff ff       	call   f0100ebd <page_alloc>
f0101463:	83 c4 10             	add    $0x10,%esp
f0101466:	85 c0                	test   %eax,%eax
f0101468:	74 19                	je     f0101483 <mem_init+0x2fe>
f010146a:	68 74 48 10 f0       	push   $0xf0104874
f010146f:	68 66 47 10 f0       	push   $0xf0104766
f0101474:	68 ba 02 00 00       	push   $0x2ba
f0101479:	68 40 47 10 f0       	push   $0xf0104740
f010147e:	e8 1d ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101483:	83 ec 0c             	sub    $0xc,%esp
f0101486:	57                   	push   %edi
f0101487:	e8 a1 fa ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f010148c:	89 34 24             	mov    %esi,(%esp)
f010148f:	e8 99 fa ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f0101494:	83 c4 04             	add    $0x4,%esp
f0101497:	ff 75 d4             	pushl  -0x2c(%ebp)
f010149a:	e8 8e fa ff ff       	call   f0100f2d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010149f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014a6:	e8 12 fa ff ff       	call   f0100ebd <page_alloc>
f01014ab:	89 c6                	mov    %eax,%esi
f01014ad:	83 c4 10             	add    $0x10,%esp
f01014b0:	85 c0                	test   %eax,%eax
f01014b2:	75 19                	jne    f01014cd <mem_init+0x348>
f01014b4:	68 20 48 10 f0       	push   $0xf0104820
f01014b9:	68 66 47 10 f0       	push   $0xf0104766
f01014be:	68 c1 02 00 00       	push   $0x2c1
f01014c3:	68 40 47 10 f0       	push   $0xf0104740
f01014c8:	e8 d3 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014cd:	83 ec 0c             	sub    $0xc,%esp
f01014d0:	6a 00                	push   $0x0
f01014d2:	e8 e6 f9 ff ff       	call   f0100ebd <page_alloc>
f01014d7:	89 c7                	mov    %eax,%edi
f01014d9:	83 c4 10             	add    $0x10,%esp
f01014dc:	85 c0                	test   %eax,%eax
f01014de:	75 19                	jne    f01014f9 <mem_init+0x374>
f01014e0:	68 36 48 10 f0       	push   $0xf0104836
f01014e5:	68 66 47 10 f0       	push   $0xf0104766
f01014ea:	68 c2 02 00 00       	push   $0x2c2
f01014ef:	68 40 47 10 f0       	push   $0xf0104740
f01014f4:	e8 a7 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01014f9:	83 ec 0c             	sub    $0xc,%esp
f01014fc:	6a 00                	push   $0x0
f01014fe:	e8 ba f9 ff ff       	call   f0100ebd <page_alloc>
f0101503:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101506:	83 c4 10             	add    $0x10,%esp
f0101509:	85 c0                	test   %eax,%eax
f010150b:	75 19                	jne    f0101526 <mem_init+0x3a1>
f010150d:	68 4c 48 10 f0       	push   $0xf010484c
f0101512:	68 66 47 10 f0       	push   $0xf0104766
f0101517:	68 c3 02 00 00       	push   $0x2c3
f010151c:	68 40 47 10 f0       	push   $0xf0104740
f0101521:	e8 7a eb ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101526:	39 fe                	cmp    %edi,%esi
f0101528:	75 19                	jne    f0101543 <mem_init+0x3be>
f010152a:	68 62 48 10 f0       	push   $0xf0104862
f010152f:	68 66 47 10 f0       	push   $0xf0104766
f0101534:	68 c5 02 00 00       	push   $0x2c5
f0101539:	68 40 47 10 f0       	push   $0xf0104740
f010153e:	e8 5d eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101543:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101546:	39 c7                	cmp    %eax,%edi
f0101548:	74 04                	je     f010154e <mem_init+0x3c9>
f010154a:	39 c6                	cmp    %eax,%esi
f010154c:	75 19                	jne    f0101567 <mem_init+0x3e2>
f010154e:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101553:	68 66 47 10 f0       	push   $0xf0104766
f0101558:	68 c6 02 00 00       	push   $0x2c6
f010155d:	68 40 47 10 f0       	push   $0xf0104740
f0101562:	e8 39 eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101567:	83 ec 0c             	sub    $0xc,%esp
f010156a:	6a 00                	push   $0x0
f010156c:	e8 4c f9 ff ff       	call   f0100ebd <page_alloc>
f0101571:	83 c4 10             	add    $0x10,%esp
f0101574:	85 c0                	test   %eax,%eax
f0101576:	74 19                	je     f0101591 <mem_init+0x40c>
f0101578:	68 74 48 10 f0       	push   $0xf0104874
f010157d:	68 66 47 10 f0       	push   $0xf0104766
f0101582:	68 c7 02 00 00       	push   $0x2c7
f0101587:	68 40 47 10 f0       	push   $0xf0104740
f010158c:	e8 0f eb ff ff       	call   f01000a0 <_panic>
f0101591:	89 f0                	mov    %esi,%eax
f0101593:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101599:	c1 f8 03             	sar    $0x3,%eax
f010159c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010159f:	89 c2                	mov    %eax,%edx
f01015a1:	c1 ea 0c             	shr    $0xc,%edx
f01015a4:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01015aa:	72 12                	jb     f01015be <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015ac:	50                   	push   %eax
f01015ad:	68 dc 49 10 f0       	push   $0xf01049dc
f01015b2:	6a 5b                	push   $0x5b
f01015b4:	68 4c 47 10 f0       	push   $0xf010474c
f01015b9:	e8 e2 ea ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01015be:	83 ec 04             	sub    $0x4,%esp
f01015c1:	68 00 10 00 00       	push   $0x1000
f01015c6:	6a 01                	push   $0x1
f01015c8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015cd:	50                   	push   %eax
f01015ce:	e8 52 26 00 00       	call   f0103c25 <memset>
	page_free(pp0);
f01015d3:	89 34 24             	mov    %esi,(%esp)
f01015d6:	e8 52 f9 ff ff       	call   f0100f2d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015e2:	e8 d6 f8 ff ff       	call   f0100ebd <page_alloc>
f01015e7:	83 c4 10             	add    $0x10,%esp
f01015ea:	85 c0                	test   %eax,%eax
f01015ec:	75 19                	jne    f0101607 <mem_init+0x482>
f01015ee:	68 83 48 10 f0       	push   $0xf0104883
f01015f3:	68 66 47 10 f0       	push   $0xf0104766
f01015f8:	68 cc 02 00 00       	push   $0x2cc
f01015fd:	68 40 47 10 f0       	push   $0xf0104740
f0101602:	e8 99 ea ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101607:	39 c6                	cmp    %eax,%esi
f0101609:	74 19                	je     f0101624 <mem_init+0x49f>
f010160b:	68 a1 48 10 f0       	push   $0xf01048a1
f0101610:	68 66 47 10 f0       	push   $0xf0104766
f0101615:	68 cd 02 00 00       	push   $0x2cd
f010161a:	68 40 47 10 f0       	push   $0xf0104740
f010161f:	e8 7c ea ff ff       	call   f01000a0 <_panic>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0101624:	89 f0                	mov    %esi,%eax
f0101626:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010162c:	c1 f8 03             	sar    $0x3,%eax
f010162f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101632:	89 c2                	mov    %eax,%edx
f0101634:	c1 ea 0c             	shr    $0xc,%edx
f0101637:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010163d:	72 12                	jb     f0101651 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010163f:	50                   	push   %eax
f0101640:	68 dc 49 10 f0       	push   $0xf01049dc
f0101645:	6a 5b                	push   $0x5b
f0101647:	68 4c 47 10 f0       	push   $0xf010474c
f010164c:	e8 4f ea ff ff       	call   f01000a0 <_panic>
f0101651:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101657:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010165d:	80 38 00             	cmpb   $0x0,(%eax)
f0101660:	74 19                	je     f010167b <mem_init+0x4f6>
f0101662:	68 b1 48 10 f0       	push   $0xf01048b1
f0101667:	68 66 47 10 f0       	push   $0xf0104766
f010166c:	68 d0 02 00 00       	push   $0x2d0
f0101671:	68 40 47 10 f0       	push   $0xf0104740
f0101676:	e8 25 ea ff ff       	call   f01000a0 <_panic>
f010167b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010167e:	39 d0                	cmp    %edx,%eax
f0101680:	75 db                	jne    f010165d <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101682:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101685:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f010168a:	83 ec 0c             	sub    $0xc,%esp
f010168d:	56                   	push   %esi
f010168e:	e8 9a f8 ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f0101693:	89 3c 24             	mov    %edi,(%esp)
f0101696:	e8 92 f8 ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f010169b:	83 c4 04             	add    $0x4,%esp
f010169e:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016a1:	e8 87 f8 ff ff       	call   f0100f2d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016a6:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01016ab:	83 c4 10             	add    $0x10,%esp
f01016ae:	eb 05                	jmp    f01016b5 <mem_init+0x530>
		--nfree;
f01016b0:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016b3:	8b 00                	mov    (%eax),%eax
f01016b5:	85 c0                	test   %eax,%eax
f01016b7:	75 f7                	jne    f01016b0 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01016b9:	85 db                	test   %ebx,%ebx
f01016bb:	74 19                	je     f01016d6 <mem_init+0x551>
f01016bd:	68 bb 48 10 f0       	push   $0xf01048bb
f01016c2:	68 66 47 10 f0       	push   $0xf0104766
f01016c7:	68 dd 02 00 00       	push   $0x2dd
f01016cc:	68 40 47 10 f0       	push   $0xf0104740
f01016d1:	e8 ca e9 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01016d6:	83 ec 0c             	sub    $0xc,%esp
f01016d9:	68 bc 4b 10 f0       	push   $0xf0104bbc
f01016de:	e8 0e 16 00 00       	call   f0102cf1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016ea:	e8 ce f7 ff ff       	call   f0100ebd <page_alloc>
f01016ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016f2:	83 c4 10             	add    $0x10,%esp
f01016f5:	85 c0                	test   %eax,%eax
f01016f7:	75 19                	jne    f0101712 <mem_init+0x58d>
f01016f9:	68 20 48 10 f0       	push   $0xf0104820
f01016fe:	68 66 47 10 f0       	push   $0xf0104766
f0101703:	68 3e 03 00 00       	push   $0x33e
f0101708:	68 40 47 10 f0       	push   $0xf0104740
f010170d:	e8 8e e9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101712:	83 ec 0c             	sub    $0xc,%esp
f0101715:	6a 00                	push   $0x0
f0101717:	e8 a1 f7 ff ff       	call   f0100ebd <page_alloc>
f010171c:	89 c3                	mov    %eax,%ebx
f010171e:	83 c4 10             	add    $0x10,%esp
f0101721:	85 c0                	test   %eax,%eax
f0101723:	75 19                	jne    f010173e <mem_init+0x5b9>
f0101725:	68 36 48 10 f0       	push   $0xf0104836
f010172a:	68 66 47 10 f0       	push   $0xf0104766
f010172f:	68 3f 03 00 00       	push   $0x33f
f0101734:	68 40 47 10 f0       	push   $0xf0104740
f0101739:	e8 62 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010173e:	83 ec 0c             	sub    $0xc,%esp
f0101741:	6a 00                	push   $0x0
f0101743:	e8 75 f7 ff ff       	call   f0100ebd <page_alloc>
f0101748:	89 c6                	mov    %eax,%esi
f010174a:	83 c4 10             	add    $0x10,%esp
f010174d:	85 c0                	test   %eax,%eax
f010174f:	75 19                	jne    f010176a <mem_init+0x5e5>
f0101751:	68 4c 48 10 f0       	push   $0xf010484c
f0101756:	68 66 47 10 f0       	push   $0xf0104766
f010175b:	68 40 03 00 00       	push   $0x340
f0101760:	68 40 47 10 f0       	push   $0xf0104740
f0101765:	e8 36 e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010176a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010176d:	75 19                	jne    f0101788 <mem_init+0x603>
f010176f:	68 62 48 10 f0       	push   $0xf0104862
f0101774:	68 66 47 10 f0       	push   $0xf0104766
f0101779:	68 43 03 00 00       	push   $0x343
f010177e:	68 40 47 10 f0       	push   $0xf0104740
f0101783:	e8 18 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101788:	39 c3                	cmp    %eax,%ebx
f010178a:	74 05                	je     f0101791 <mem_init+0x60c>
f010178c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010178f:	75 19                	jne    f01017aa <mem_init+0x625>
f0101791:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101796:	68 66 47 10 f0       	push   $0xf0104766
f010179b:	68 44 03 00 00       	push   $0x344
f01017a0:	68 40 47 10 f0       	push   $0xf0104740
f01017a5:	e8 f6 e8 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017aa:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01017af:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017b2:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f01017b9:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017bc:	83 ec 0c             	sub    $0xc,%esp
f01017bf:	6a 00                	push   $0x0
f01017c1:	e8 f7 f6 ff ff       	call   f0100ebd <page_alloc>
f01017c6:	83 c4 10             	add    $0x10,%esp
f01017c9:	85 c0                	test   %eax,%eax
f01017cb:	74 19                	je     f01017e6 <mem_init+0x661>
f01017cd:	68 74 48 10 f0       	push   $0xf0104874
f01017d2:	68 66 47 10 f0       	push   $0xf0104766
f01017d7:	68 4b 03 00 00       	push   $0x34b
f01017dc:	68 40 47 10 f0       	push   $0xf0104740
f01017e1:	e8 ba e8 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *)0x0, &ptep) == NULL);
f01017e6:	83 ec 04             	sub    $0x4,%esp
f01017e9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01017ec:	50                   	push   %eax
f01017ed:	6a 00                	push   $0x0
f01017ef:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01017f5:	e8 89 f8 ff ff       	call   f0101083 <page_lookup>
f01017fa:	83 c4 10             	add    $0x10,%esp
f01017fd:	85 c0                	test   %eax,%eax
f01017ff:	74 19                	je     f010181a <mem_init+0x695>
f0101801:	68 dc 4b 10 f0       	push   $0xf0104bdc
f0101806:	68 66 47 10 f0       	push   $0xf0104766
f010180b:	68 4e 03 00 00       	push   $0x34e
f0101810:	68 40 47 10 f0       	push   $0xf0104740
f0101815:	e8 86 e8 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010181a:	6a 02                	push   $0x2
f010181c:	6a 00                	push   $0x0
f010181e:	53                   	push   %ebx
f010181f:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101825:	e8 f5 f8 ff ff       	call   f010111f <page_insert>
f010182a:	83 c4 10             	add    $0x10,%esp
f010182d:	85 c0                	test   %eax,%eax
f010182f:	78 19                	js     f010184a <mem_init+0x6c5>
f0101831:	68 10 4c 10 f0       	push   $0xf0104c10
f0101836:	68 66 47 10 f0       	push   $0xf0104766
f010183b:	68 51 03 00 00       	push   $0x351
f0101840:	68 40 47 10 f0       	push   $0xf0104740
f0101845:	e8 56 e8 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010184a:	83 ec 0c             	sub    $0xc,%esp
f010184d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101850:	e8 d8 f6 ff ff       	call   f0100f2d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101855:	6a 02                	push   $0x2
f0101857:	6a 00                	push   $0x0
f0101859:	53                   	push   %ebx
f010185a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101860:	e8 ba f8 ff ff       	call   f010111f <page_insert>
f0101865:	83 c4 20             	add    $0x20,%esp
f0101868:	85 c0                	test   %eax,%eax
f010186a:	74 19                	je     f0101885 <mem_init+0x700>
f010186c:	68 40 4c 10 f0       	push   $0xf0104c40
f0101871:	68 66 47 10 f0       	push   $0xf0104766
f0101876:	68 55 03 00 00       	push   $0x355
f010187b:	68 40 47 10 f0       	push   $0xf0104740
f0101880:	e8 1b e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101885:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010188b:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0101890:	89 c1                	mov    %eax,%ecx
f0101892:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101895:	8b 17                	mov    (%edi),%edx
f0101897:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010189d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018a0:	29 c8                	sub    %ecx,%eax
f01018a2:	c1 f8 03             	sar    $0x3,%eax
f01018a5:	c1 e0 0c             	shl    $0xc,%eax
f01018a8:	39 c2                	cmp    %eax,%edx
f01018aa:	74 19                	je     f01018c5 <mem_init+0x740>
f01018ac:	68 70 4c 10 f0       	push   $0xf0104c70
f01018b1:	68 66 47 10 f0       	push   $0xf0104766
f01018b6:	68 56 03 00 00       	push   $0x356
f01018bb:	68 40 47 10 f0       	push   $0xf0104740
f01018c0:	e8 db e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01018ca:	89 f8                	mov    %edi,%eax
f01018cc:	e8 1c f2 ff ff       	call   f0100aed <check_va2pa>
f01018d1:	89 da                	mov    %ebx,%edx
f01018d3:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01018d6:	c1 fa 03             	sar    $0x3,%edx
f01018d9:	c1 e2 0c             	shl    $0xc,%edx
f01018dc:	39 d0                	cmp    %edx,%eax
f01018de:	74 19                	je     f01018f9 <mem_init+0x774>
f01018e0:	68 98 4c 10 f0       	push   $0xf0104c98
f01018e5:	68 66 47 10 f0       	push   $0xf0104766
f01018ea:	68 57 03 00 00       	push   $0x357
f01018ef:	68 40 47 10 f0       	push   $0xf0104740
f01018f4:	e8 a7 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01018f9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018fe:	74 19                	je     f0101919 <mem_init+0x794>
f0101900:	68 c6 48 10 f0       	push   $0xf01048c6
f0101905:	68 66 47 10 f0       	push   $0xf0104766
f010190a:	68 58 03 00 00       	push   $0x358
f010190f:	68 40 47 10 f0       	push   $0xf0104740
f0101914:	e8 87 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101919:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010191c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101921:	74 19                	je     f010193c <mem_init+0x7b7>
f0101923:	68 d7 48 10 f0       	push   $0xf01048d7
f0101928:	68 66 47 10 f0       	push   $0xf0104766
f010192d:	68 59 03 00 00       	push   $0x359
f0101932:	68 40 47 10 f0       	push   $0xf0104740
f0101937:	e8 64 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f010193c:	6a 02                	push   $0x2
f010193e:	68 00 10 00 00       	push   $0x1000
f0101943:	56                   	push   %esi
f0101944:	57                   	push   %edi
f0101945:	e8 d5 f7 ff ff       	call   f010111f <page_insert>
f010194a:	83 c4 10             	add    $0x10,%esp
f010194d:	85 c0                	test   %eax,%eax
f010194f:	74 19                	je     f010196a <mem_init+0x7e5>
f0101951:	68 c8 4c 10 f0       	push   $0xf0104cc8
f0101956:	68 66 47 10 f0       	push   $0xf0104766
f010195b:	68 5c 03 00 00       	push   $0x35c
f0101960:	68 40 47 10 f0       	push   $0xf0104740
f0101965:	e8 36 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010196a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010196f:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101974:	e8 74 f1 ff ff       	call   f0100aed <check_va2pa>
f0101979:	89 f2                	mov    %esi,%edx
f010197b:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101981:	c1 fa 03             	sar    $0x3,%edx
f0101984:	c1 e2 0c             	shl    $0xc,%edx
f0101987:	39 d0                	cmp    %edx,%eax
f0101989:	74 19                	je     f01019a4 <mem_init+0x81f>
f010198b:	68 04 4d 10 f0       	push   $0xf0104d04
f0101990:	68 66 47 10 f0       	push   $0xf0104766
f0101995:	68 5d 03 00 00       	push   $0x35d
f010199a:	68 40 47 10 f0       	push   $0xf0104740
f010199f:	e8 fc e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019a4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019a9:	74 19                	je     f01019c4 <mem_init+0x83f>
f01019ab:	68 e8 48 10 f0       	push   $0xf01048e8
f01019b0:	68 66 47 10 f0       	push   $0xf0104766
f01019b5:	68 5e 03 00 00       	push   $0x35e
f01019ba:	68 40 47 10 f0       	push   $0xf0104740
f01019bf:	e8 dc e6 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01019c4:	83 ec 0c             	sub    $0xc,%esp
f01019c7:	6a 00                	push   $0x0
f01019c9:	e8 ef f4 ff ff       	call   f0100ebd <page_alloc>
f01019ce:	83 c4 10             	add    $0x10,%esp
f01019d1:	85 c0                	test   %eax,%eax
f01019d3:	74 19                	je     f01019ee <mem_init+0x869>
f01019d5:	68 74 48 10 f0       	push   $0xf0104874
f01019da:	68 66 47 10 f0       	push   $0xf0104766
f01019df:	68 61 03 00 00       	push   $0x361
f01019e4:	68 40 47 10 f0       	push   $0xf0104740
f01019e9:	e8 b2 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f01019ee:	6a 02                	push   $0x2
f01019f0:	68 00 10 00 00       	push   $0x1000
f01019f5:	56                   	push   %esi
f01019f6:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01019fc:	e8 1e f7 ff ff       	call   f010111f <page_insert>
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	85 c0                	test   %eax,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x89c>
f0101a08:	68 c8 4c 10 f0       	push   $0xf0104cc8
f0101a0d:	68 66 47 10 f0       	push   $0xf0104766
f0101a12:	68 64 03 00 00       	push   $0x364
f0101a17:	68 40 47 10 f0       	push   $0xf0104740
f0101a1c:	e8 7f e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a26:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101a2b:	e8 bd f0 ff ff       	call   f0100aed <check_va2pa>
f0101a30:	89 f2                	mov    %esi,%edx
f0101a32:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101a38:	c1 fa 03             	sar    $0x3,%edx
f0101a3b:	c1 e2 0c             	shl    $0xc,%edx
f0101a3e:	39 d0                	cmp    %edx,%eax
f0101a40:	74 19                	je     f0101a5b <mem_init+0x8d6>
f0101a42:	68 04 4d 10 f0       	push   $0xf0104d04
f0101a47:	68 66 47 10 f0       	push   $0xf0104766
f0101a4c:	68 65 03 00 00       	push   $0x365
f0101a51:	68 40 47 10 f0       	push   $0xf0104740
f0101a56:	e8 45 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a5b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a60:	74 19                	je     f0101a7b <mem_init+0x8f6>
f0101a62:	68 e8 48 10 f0       	push   $0xf01048e8
f0101a67:	68 66 47 10 f0       	push   $0xf0104766
f0101a6c:	68 66 03 00 00       	push   $0x366
f0101a71:	68 40 47 10 f0       	push   $0xf0104740
f0101a76:	e8 25 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a7b:	83 ec 0c             	sub    $0xc,%esp
f0101a7e:	6a 00                	push   $0x0
f0101a80:	e8 38 f4 ff ff       	call   f0100ebd <page_alloc>
f0101a85:	83 c4 10             	add    $0x10,%esp
f0101a88:	85 c0                	test   %eax,%eax
f0101a8a:	74 19                	je     f0101aa5 <mem_init+0x920>
f0101a8c:	68 74 48 10 f0       	push   $0xf0104874
f0101a91:	68 66 47 10 f0       	push   $0xf0104766
f0101a96:	68 6a 03 00 00       	push   $0x36a
f0101a9b:	68 40 47 10 f0       	push   $0xf0104740
f0101aa0:	e8 fb e5 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101aa5:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f0101aab:	8b 02                	mov    (%edx),%eax
f0101aad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ab2:	89 c1                	mov    %eax,%ecx
f0101ab4:	c1 e9 0c             	shr    $0xc,%ecx
f0101ab7:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0101abd:	72 15                	jb     f0101ad4 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101abf:	50                   	push   %eax
f0101ac0:	68 dc 49 10 f0       	push   $0xf01049dc
f0101ac5:	68 6d 03 00 00       	push   $0x36d
f0101aca:	68 40 47 10 f0       	push   $0xf0104740
f0101acf:	e8 cc e5 ff ff       	call   f01000a0 <_panic>
f0101ad4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ad9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101adc:	83 ec 04             	sub    $0x4,%esp
f0101adf:	6a 00                	push   $0x0
f0101ae1:	68 00 10 00 00       	push   $0x1000
f0101ae6:	52                   	push   %edx
f0101ae7:	e8 a3 f4 ff ff       	call   f0100f8f <pgdir_walk>
f0101aec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101aef:	8d 57 04             	lea    0x4(%edi),%edx
f0101af2:	83 c4 10             	add    $0x10,%esp
f0101af5:	39 d0                	cmp    %edx,%eax
f0101af7:	74 19                	je     f0101b12 <mem_init+0x98d>
f0101af9:	68 34 4d 10 f0       	push   $0xf0104d34
f0101afe:	68 66 47 10 f0       	push   $0xf0104766
f0101b03:	68 6e 03 00 00       	push   $0x36e
f0101b08:	68 40 47 10 f0       	push   $0xf0104740
f0101b0d:	e8 8e e5 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W | PTE_U) == 0);
f0101b12:	6a 06                	push   $0x6
f0101b14:	68 00 10 00 00       	push   $0x1000
f0101b19:	56                   	push   %esi
f0101b1a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b20:	e8 fa f5 ff ff       	call   f010111f <page_insert>
f0101b25:	83 c4 10             	add    $0x10,%esp
f0101b28:	85 c0                	test   %eax,%eax
f0101b2a:	74 19                	je     f0101b45 <mem_init+0x9c0>
f0101b2c:	68 74 4d 10 f0       	push   $0xf0104d74
f0101b31:	68 66 47 10 f0       	push   $0xf0104766
f0101b36:	68 71 03 00 00       	push   $0x371
f0101b3b:	68 40 47 10 f0       	push   $0xf0104740
f0101b40:	e8 5b e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b45:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101b4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b50:	89 f8                	mov    %edi,%eax
f0101b52:	e8 96 ef ff ff       	call   f0100aed <check_va2pa>
f0101b57:	89 f2                	mov    %esi,%edx
f0101b59:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101b5f:	c1 fa 03             	sar    $0x3,%edx
f0101b62:	c1 e2 0c             	shl    $0xc,%edx
f0101b65:	39 d0                	cmp    %edx,%eax
f0101b67:	74 19                	je     f0101b82 <mem_init+0x9fd>
f0101b69:	68 04 4d 10 f0       	push   $0xf0104d04
f0101b6e:	68 66 47 10 f0       	push   $0xf0104766
f0101b73:	68 72 03 00 00       	push   $0x372
f0101b78:	68 40 47 10 f0       	push   $0xf0104740
f0101b7d:	e8 1e e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101b82:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b87:	74 19                	je     f0101ba2 <mem_init+0xa1d>
f0101b89:	68 e8 48 10 f0       	push   $0xf01048e8
f0101b8e:	68 66 47 10 f0       	push   $0xf0104766
f0101b93:	68 73 03 00 00       	push   $0x373
f0101b98:	68 40 47 10 f0       	push   $0xf0104740
f0101b9d:	e8 fe e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U);
f0101ba2:	83 ec 04             	sub    $0x4,%esp
f0101ba5:	6a 00                	push   $0x0
f0101ba7:	68 00 10 00 00       	push   $0x1000
f0101bac:	57                   	push   %edi
f0101bad:	e8 dd f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101bb2:	83 c4 10             	add    $0x10,%esp
f0101bb5:	f6 00 04             	testb  $0x4,(%eax)
f0101bb8:	75 19                	jne    f0101bd3 <mem_init+0xa4e>
f0101bba:	68 b8 4d 10 f0       	push   $0xf0104db8
f0101bbf:	68 66 47 10 f0       	push   $0xf0104766
f0101bc4:	68 74 03 00 00       	push   $0x374
f0101bc9:	68 40 47 10 f0       	push   $0xf0104740
f0101bce:	e8 cd e4 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101bd3:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101bd8:	f6 00 04             	testb  $0x4,(%eax)
f0101bdb:	75 19                	jne    f0101bf6 <mem_init+0xa71>
f0101bdd:	68 f9 48 10 f0       	push   $0xf01048f9
f0101be2:	68 66 47 10 f0       	push   $0xf0104766
f0101be7:	68 75 03 00 00       	push   $0x375
f0101bec:	68 40 47 10 f0       	push   $0xf0104740
f0101bf1:	e8 aa e4 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W) == 0);
f0101bf6:	6a 02                	push   $0x2
f0101bf8:	68 00 10 00 00       	push   $0x1000
f0101bfd:	56                   	push   %esi
f0101bfe:	50                   	push   %eax
f0101bff:	e8 1b f5 ff ff       	call   f010111f <page_insert>
f0101c04:	83 c4 10             	add    $0x10,%esp
f0101c07:	85 c0                	test   %eax,%eax
f0101c09:	74 19                	je     f0101c24 <mem_init+0xa9f>
f0101c0b:	68 c8 4c 10 f0       	push   $0xf0104cc8
f0101c10:	68 66 47 10 f0       	push   $0xf0104766
f0101c15:	68 78 03 00 00       	push   $0x378
f0101c1a:	68 40 47 10 f0       	push   $0xf0104740
f0101c1f:	e8 7c e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_W);
f0101c24:	83 ec 04             	sub    $0x4,%esp
f0101c27:	6a 00                	push   $0x0
f0101c29:	68 00 10 00 00       	push   $0x1000
f0101c2e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c34:	e8 56 f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101c39:	83 c4 10             	add    $0x10,%esp
f0101c3c:	f6 00 02             	testb  $0x2,(%eax)
f0101c3f:	75 19                	jne    f0101c5a <mem_init+0xad5>
f0101c41:	68 ec 4d 10 f0       	push   $0xf0104dec
f0101c46:	68 66 47 10 f0       	push   $0xf0104766
f0101c4b:	68 79 03 00 00       	push   $0x379
f0101c50:	68 40 47 10 f0       	push   $0xf0104740
f0101c55:	e8 46 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101c5a:	83 ec 04             	sub    $0x4,%esp
f0101c5d:	6a 00                	push   $0x0
f0101c5f:	68 00 10 00 00       	push   $0x1000
f0101c64:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c6a:	e8 20 f3 ff ff       	call   f0100f8f <pgdir_walk>
f0101c6f:	83 c4 10             	add    $0x10,%esp
f0101c72:	f6 00 04             	testb  $0x4,(%eax)
f0101c75:	74 19                	je     f0101c90 <mem_init+0xb0b>
f0101c77:	68 20 4e 10 f0       	push   $0xf0104e20
f0101c7c:	68 66 47 10 f0       	push   $0xf0104766
f0101c81:	68 7a 03 00 00       	push   $0x37a
f0101c86:	68 40 47 10 f0       	push   $0xf0104740
f0101c8b:	e8 10 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void *)PTSIZE, PTE_W) < 0);
f0101c90:	6a 02                	push   $0x2
f0101c92:	68 00 00 40 00       	push   $0x400000
f0101c97:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c9a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101ca0:	e8 7a f4 ff ff       	call   f010111f <page_insert>
f0101ca5:	83 c4 10             	add    $0x10,%esp
f0101ca8:	85 c0                	test   %eax,%eax
f0101caa:	78 19                	js     f0101cc5 <mem_init+0xb40>
f0101cac:	68 58 4e 10 f0       	push   $0xf0104e58
f0101cb1:	68 66 47 10 f0       	push   $0xf0104766
f0101cb6:	68 7d 03 00 00       	push   $0x37d
f0101cbb:	68 40 47 10 f0       	push   $0xf0104740
f0101cc0:	e8 db e3 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W) == 0);
f0101cc5:	6a 02                	push   $0x2
f0101cc7:	68 00 10 00 00       	push   $0x1000
f0101ccc:	53                   	push   %ebx
f0101ccd:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101cd3:	e8 47 f4 ff ff       	call   f010111f <page_insert>
f0101cd8:	83 c4 10             	add    $0x10,%esp
f0101cdb:	85 c0                	test   %eax,%eax
f0101cdd:	74 19                	je     f0101cf8 <mem_init+0xb73>
f0101cdf:	68 90 4e 10 f0       	push   $0xf0104e90
f0101ce4:	68 66 47 10 f0       	push   $0xf0104766
f0101ce9:	68 80 03 00 00       	push   $0x380
f0101cee:	68 40 47 10 f0       	push   $0xf0104740
f0101cf3:	e8 a8 e3 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *)PGSIZE, 0) & PTE_U));
f0101cf8:	83 ec 04             	sub    $0x4,%esp
f0101cfb:	6a 00                	push   $0x0
f0101cfd:	68 00 10 00 00       	push   $0x1000
f0101d02:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d08:	e8 82 f2 ff ff       	call   f0100f8f <pgdir_walk>
f0101d0d:	83 c4 10             	add    $0x10,%esp
f0101d10:	f6 00 04             	testb  $0x4,(%eax)
f0101d13:	74 19                	je     f0101d2e <mem_init+0xba9>
f0101d15:	68 20 4e 10 f0       	push   $0xf0104e20
f0101d1a:	68 66 47 10 f0       	push   $0xf0104766
f0101d1f:	68 81 03 00 00       	push   $0x381
f0101d24:	68 40 47 10 f0       	push   $0xf0104740
f0101d29:	e8 72 e3 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d2e:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d34:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d39:	89 f8                	mov    %edi,%eax
f0101d3b:	e8 ad ed ff ff       	call   f0100aed <check_va2pa>
f0101d40:	89 c1                	mov    %eax,%ecx
f0101d42:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d45:	89 d8                	mov    %ebx,%eax
f0101d47:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101d4d:	c1 f8 03             	sar    $0x3,%eax
f0101d50:	c1 e0 0c             	shl    $0xc,%eax
f0101d53:	39 c1                	cmp    %eax,%ecx
f0101d55:	74 19                	je     f0101d70 <mem_init+0xbeb>
f0101d57:	68 cc 4e 10 f0       	push   $0xf0104ecc
f0101d5c:	68 66 47 10 f0       	push   $0xf0104766
f0101d61:	68 84 03 00 00       	push   $0x384
f0101d66:	68 40 47 10 f0       	push   $0xf0104740
f0101d6b:	e8 30 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d75:	89 f8                	mov    %edi,%eax
f0101d77:	e8 71 ed ff ff       	call   f0100aed <check_va2pa>
f0101d7c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d7f:	74 19                	je     f0101d9a <mem_init+0xc15>
f0101d81:	68 f8 4e 10 f0       	push   $0xf0104ef8
f0101d86:	68 66 47 10 f0       	push   $0xf0104766
f0101d8b:	68 85 03 00 00       	push   $0x385
f0101d90:	68 40 47 10 f0       	push   $0xf0104740
f0101d95:	e8 06 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d9a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d9f:	74 19                	je     f0101dba <mem_init+0xc35>
f0101da1:	68 0f 49 10 f0       	push   $0xf010490f
f0101da6:	68 66 47 10 f0       	push   $0xf0104766
f0101dab:	68 87 03 00 00       	push   $0x387
f0101db0:	68 40 47 10 f0       	push   $0xf0104740
f0101db5:	e8 e6 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dbf:	74 19                	je     f0101dda <mem_init+0xc55>
f0101dc1:	68 20 49 10 f0       	push   $0xf0104920
f0101dc6:	68 66 47 10 f0       	push   $0xf0104766
f0101dcb:	68 88 03 00 00       	push   $0x388
f0101dd0:	68 40 47 10 f0       	push   $0xf0104740
f0101dd5:	e8 c6 e2 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101dda:	83 ec 0c             	sub    $0xc,%esp
f0101ddd:	6a 00                	push   $0x0
f0101ddf:	e8 d9 f0 ff ff       	call   f0100ebd <page_alloc>
f0101de4:	83 c4 10             	add    $0x10,%esp
f0101de7:	85 c0                	test   %eax,%eax
f0101de9:	74 04                	je     f0101def <mem_init+0xc6a>
f0101deb:	39 c6                	cmp    %eax,%esi
f0101ded:	74 19                	je     f0101e08 <mem_init+0xc83>
f0101def:	68 28 4f 10 f0       	push   $0xf0104f28
f0101df4:	68 66 47 10 f0       	push   $0xf0104766
f0101df9:	68 8b 03 00 00       	push   $0x38b
f0101dfe:	68 40 47 10 f0       	push   $0xf0104740
f0101e03:	e8 98 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e08:	83 ec 08             	sub    $0x8,%esp
f0101e0b:	6a 00                	push   $0x0
f0101e0d:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101e13:	e8 c5 f2 ff ff       	call   f01010dd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e18:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101e1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e23:	89 f8                	mov    %edi,%eax
f0101e25:	e8 c3 ec ff ff       	call   f0100aed <check_va2pa>
f0101e2a:	83 c4 10             	add    $0x10,%esp
f0101e2d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e30:	74 19                	je     f0101e4b <mem_init+0xcc6>
f0101e32:	68 4c 4f 10 f0       	push   $0xf0104f4c
f0101e37:	68 66 47 10 f0       	push   $0xf0104766
f0101e3c:	68 8f 03 00 00       	push   $0x38f
f0101e41:	68 40 47 10 f0       	push   $0xf0104740
f0101e46:	e8 55 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e50:	89 f8                	mov    %edi,%eax
f0101e52:	e8 96 ec ff ff       	call   f0100aed <check_va2pa>
f0101e57:	89 da                	mov    %ebx,%edx
f0101e59:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101e5f:	c1 fa 03             	sar    $0x3,%edx
f0101e62:	c1 e2 0c             	shl    $0xc,%edx
f0101e65:	39 d0                	cmp    %edx,%eax
f0101e67:	74 19                	je     f0101e82 <mem_init+0xcfd>
f0101e69:	68 f8 4e 10 f0       	push   $0xf0104ef8
f0101e6e:	68 66 47 10 f0       	push   $0xf0104766
f0101e73:	68 90 03 00 00       	push   $0x390
f0101e78:	68 40 47 10 f0       	push   $0xf0104740
f0101e7d:	e8 1e e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101e82:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e87:	74 19                	je     f0101ea2 <mem_init+0xd1d>
f0101e89:	68 c6 48 10 f0       	push   $0xf01048c6
f0101e8e:	68 66 47 10 f0       	push   $0xf0104766
f0101e93:	68 91 03 00 00       	push   $0x391
f0101e98:	68 40 47 10 f0       	push   $0xf0104740
f0101e9d:	e8 fe e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ea2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea7:	74 19                	je     f0101ec2 <mem_init+0xd3d>
f0101ea9:	68 20 49 10 f0       	push   $0xf0104920
f0101eae:	68 66 47 10 f0       	push   $0xf0104766
f0101eb3:	68 92 03 00 00       	push   $0x392
f0101eb8:	68 40 47 10 f0       	push   $0xf0104740
f0101ebd:	e8 de e1 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *)PGSIZE, 0) == 0);
f0101ec2:	6a 00                	push   $0x0
f0101ec4:	68 00 10 00 00       	push   $0x1000
f0101ec9:	53                   	push   %ebx
f0101eca:	57                   	push   %edi
f0101ecb:	e8 4f f2 ff ff       	call   f010111f <page_insert>
f0101ed0:	83 c4 10             	add    $0x10,%esp
f0101ed3:	85 c0                	test   %eax,%eax
f0101ed5:	74 19                	je     f0101ef0 <mem_init+0xd6b>
f0101ed7:	68 70 4f 10 f0       	push   $0xf0104f70
f0101edc:	68 66 47 10 f0       	push   $0xf0104766
f0101ee1:	68 95 03 00 00       	push   $0x395
f0101ee6:	68 40 47 10 f0       	push   $0xf0104740
f0101eeb:	e8 b0 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101ef0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ef5:	75 19                	jne    f0101f10 <mem_init+0xd8b>
f0101ef7:	68 31 49 10 f0       	push   $0xf0104931
f0101efc:	68 66 47 10 f0       	push   $0xf0104766
f0101f01:	68 96 03 00 00       	push   $0x396
f0101f06:	68 40 47 10 f0       	push   $0xf0104740
f0101f0b:	e8 90 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101f10:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f13:	74 19                	je     f0101f2e <mem_init+0xda9>
f0101f15:	68 3d 49 10 f0       	push   $0xf010493d
f0101f1a:	68 66 47 10 f0       	push   $0xf0104766
f0101f1f:	68 97 03 00 00       	push   $0x397
f0101f24:	68 40 47 10 f0       	push   $0xf0104740
f0101f29:	e8 72 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *)PGSIZE);
f0101f2e:	83 ec 08             	sub    $0x8,%esp
f0101f31:	68 00 10 00 00       	push   $0x1000
f0101f36:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101f3c:	e8 9c f1 ff ff       	call   f01010dd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f41:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101f47:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f4c:	89 f8                	mov    %edi,%eax
f0101f4e:	e8 9a eb ff ff       	call   f0100aed <check_va2pa>
f0101f53:	83 c4 10             	add    $0x10,%esp
f0101f56:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f59:	74 19                	je     f0101f74 <mem_init+0xdef>
f0101f5b:	68 4c 4f 10 f0       	push   $0xf0104f4c
f0101f60:	68 66 47 10 f0       	push   $0xf0104766
f0101f65:	68 9b 03 00 00       	push   $0x39b
f0101f6a:	68 40 47 10 f0       	push   $0xf0104740
f0101f6f:	e8 2c e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f74:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f79:	89 f8                	mov    %edi,%eax
f0101f7b:	e8 6d eb ff ff       	call   f0100aed <check_va2pa>
f0101f80:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f83:	74 19                	je     f0101f9e <mem_init+0xe19>
f0101f85:	68 a8 4f 10 f0       	push   $0xf0104fa8
f0101f8a:	68 66 47 10 f0       	push   $0xf0104766
f0101f8f:	68 9c 03 00 00       	push   $0x39c
f0101f94:	68 40 47 10 f0       	push   $0xf0104740
f0101f99:	e8 02 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101f9e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fa3:	74 19                	je     f0101fbe <mem_init+0xe39>
f0101fa5:	68 52 49 10 f0       	push   $0xf0104952
f0101faa:	68 66 47 10 f0       	push   $0xf0104766
f0101faf:	68 9d 03 00 00       	push   $0x39d
f0101fb4:	68 40 47 10 f0       	push   $0xf0104740
f0101fb9:	e8 e2 e0 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101fbe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fc3:	74 19                	je     f0101fde <mem_init+0xe59>
f0101fc5:	68 20 49 10 f0       	push   $0xf0104920
f0101fca:	68 66 47 10 f0       	push   $0xf0104766
f0101fcf:	68 9e 03 00 00       	push   $0x39e
f0101fd4:	68 40 47 10 f0       	push   $0xf0104740
f0101fd9:	e8 c2 e0 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101fde:	83 ec 0c             	sub    $0xc,%esp
f0101fe1:	6a 00                	push   $0x0
f0101fe3:	e8 d5 ee ff ff       	call   f0100ebd <page_alloc>
f0101fe8:	83 c4 10             	add    $0x10,%esp
f0101feb:	39 c3                	cmp    %eax,%ebx
f0101fed:	75 04                	jne    f0101ff3 <mem_init+0xe6e>
f0101fef:	85 c0                	test   %eax,%eax
f0101ff1:	75 19                	jne    f010200c <mem_init+0xe87>
f0101ff3:	68 d0 4f 10 f0       	push   $0xf0104fd0
f0101ff8:	68 66 47 10 f0       	push   $0xf0104766
f0101ffd:	68 a1 03 00 00       	push   $0x3a1
f0102002:	68 40 47 10 f0       	push   $0xf0104740
f0102007:	e8 94 e0 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010200c:	83 ec 0c             	sub    $0xc,%esp
f010200f:	6a 00                	push   $0x0
f0102011:	e8 a7 ee ff ff       	call   f0100ebd <page_alloc>
f0102016:	83 c4 10             	add    $0x10,%esp
f0102019:	85 c0                	test   %eax,%eax
f010201b:	74 19                	je     f0102036 <mem_init+0xeb1>
f010201d:	68 74 48 10 f0       	push   $0xf0104874
f0102022:	68 66 47 10 f0       	push   $0xf0104766
f0102027:	68 a4 03 00 00       	push   $0x3a4
f010202c:	68 40 47 10 f0       	push   $0xf0104740
f0102031:	e8 6a e0 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102036:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f010203c:	8b 11                	mov    (%ecx),%edx
f010203e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102044:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102047:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010204d:	c1 f8 03             	sar    $0x3,%eax
f0102050:	c1 e0 0c             	shl    $0xc,%eax
f0102053:	39 c2                	cmp    %eax,%edx
f0102055:	74 19                	je     f0102070 <mem_init+0xeeb>
f0102057:	68 70 4c 10 f0       	push   $0xf0104c70
f010205c:	68 66 47 10 f0       	push   $0xf0104766
f0102061:	68 a7 03 00 00       	push   $0x3a7
f0102066:	68 40 47 10 f0       	push   $0xf0104740
f010206b:	e8 30 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102070:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102076:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102079:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010207e:	74 19                	je     f0102099 <mem_init+0xf14>
f0102080:	68 d7 48 10 f0       	push   $0xf01048d7
f0102085:	68 66 47 10 f0       	push   $0xf0104766
f010208a:	68 a9 03 00 00       	push   $0x3a9
f010208f:	68 40 47 10 f0       	push   $0xf0104740
f0102094:	e8 07 e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102099:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020a2:	83 ec 0c             	sub    $0xc,%esp
f01020a5:	50                   	push   %eax
f01020a6:	e8 82 ee ff ff       	call   f0100f2d <page_free>
	va = (void *)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020ab:	83 c4 0c             	add    $0xc,%esp
f01020ae:	6a 01                	push   $0x1
f01020b0:	68 00 10 40 00       	push   $0x401000
f01020b5:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01020bb:	e8 cf ee ff ff       	call   f0100f8f <pgdir_walk>
f01020c0:	89 c7                	mov    %eax,%edi
f01020c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *)KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020c5:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020ca:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020cd:	8b 40 04             	mov    0x4(%eax),%eax
f01020d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020d5:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f01020db:	89 c2                	mov    %eax,%edx
f01020dd:	c1 ea 0c             	shr    $0xc,%edx
f01020e0:	83 c4 10             	add    $0x10,%esp
f01020e3:	39 ca                	cmp    %ecx,%edx
f01020e5:	72 15                	jb     f01020fc <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020e7:	50                   	push   %eax
f01020e8:	68 dc 49 10 f0       	push   $0xf01049dc
f01020ed:	68 b0 03 00 00       	push   $0x3b0
f01020f2:	68 40 47 10 f0       	push   $0xf0104740
f01020f7:	e8 a4 df ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01020fc:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102101:	39 c7                	cmp    %eax,%edi
f0102103:	74 19                	je     f010211e <mem_init+0xf99>
f0102105:	68 63 49 10 f0       	push   $0xf0104963
f010210a:	68 66 47 10 f0       	push   $0xf0104766
f010210f:	68 b1 03 00 00       	push   $0x3b1
f0102114:	68 40 47 10 f0       	push   $0xf0104740
f0102119:	e8 82 df ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010211e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102121:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102128:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010212b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102131:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102137:	c1 f8 03             	sar    $0x3,%eax
f010213a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010213d:	89 c2                	mov    %eax,%edx
f010213f:	c1 ea 0c             	shr    $0xc,%edx
f0102142:	39 d1                	cmp    %edx,%ecx
f0102144:	77 12                	ja     f0102158 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102146:	50                   	push   %eax
f0102147:	68 dc 49 10 f0       	push   $0xf01049dc
f010214c:	6a 5b                	push   $0x5b
f010214e:	68 4c 47 10 f0       	push   $0xf010474c
f0102153:	e8 48 df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102158:	83 ec 04             	sub    $0x4,%esp
f010215b:	68 00 10 00 00       	push   $0x1000
f0102160:	68 ff 00 00 00       	push   $0xff
f0102165:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010216a:	50                   	push   %eax
f010216b:	e8 b5 1a 00 00       	call   f0103c25 <memset>
	page_free(pp0);
f0102170:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102173:	89 3c 24             	mov    %edi,(%esp)
f0102176:	e8 b2 ed ff ff       	call   f0100f2d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010217b:	83 c4 0c             	add    $0xc,%esp
f010217e:	6a 01                	push   $0x1
f0102180:	6a 00                	push   $0x0
f0102182:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102188:	e8 02 ee ff ff       	call   f0100f8f <pgdir_walk>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f010218d:	89 fa                	mov    %edi,%edx
f010218f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0102195:	c1 fa 03             	sar    $0x3,%edx
f0102198:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010219b:	89 d0                	mov    %edx,%eax
f010219d:	c1 e8 0c             	shr    $0xc,%eax
f01021a0:	83 c4 10             	add    $0x10,%esp
f01021a3:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f01021a9:	72 12                	jb     f01021bd <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021ab:	52                   	push   %edx
f01021ac:	68 dc 49 10 f0       	push   $0xf01049dc
f01021b1:	6a 5b                	push   $0x5b
f01021b3:	68 4c 47 10 f0       	push   $0xf010474c
f01021b8:	e8 e3 de ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01021bd:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *)page2kva(pp0);
f01021c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021c6:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021cc:	f6 00 01             	testb  $0x1,(%eax)
f01021cf:	74 19                	je     f01021ea <mem_init+0x1065>
f01021d1:	68 7b 49 10 f0       	push   $0xf010497b
f01021d6:	68 66 47 10 f0       	push   $0xf0104766
f01021db:	68 bb 03 00 00       	push   $0x3bb
f01021e0:	68 40 47 10 f0       	push   $0xf0104740
f01021e5:	e8 b6 de ff ff       	call   f01000a0 <_panic>
f01021ea:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *)page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f01021ed:	39 c2                	cmp    %eax,%edx
f01021ef:	75 db                	jne    f01021cc <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01021f1:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01021f6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ff:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102205:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102208:	89 3d 3c be 17 f0    	mov    %edi,0xf017be3c

	// free the pages we took
	page_free(pp0);
f010220e:	83 ec 0c             	sub    $0xc,%esp
f0102211:	50                   	push   %eax
f0102212:	e8 16 ed ff ff       	call   f0100f2d <page_free>
	page_free(pp1);
f0102217:	89 1c 24             	mov    %ebx,(%esp)
f010221a:	e8 0e ed ff ff       	call   f0100f2d <page_free>
	page_free(pp2);
f010221f:	89 34 24             	mov    %esi,(%esp)
f0102222:	e8 06 ed ff ff       	call   f0100f2d <page_free>

	cprintf("check_page() succeeded!\n");
f0102227:	c7 04 24 92 49 10 f0 	movl   $0xf0104992,(%esp)
f010222e:	e8 be 0a 00 00       	call   f0102cf1 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	// 映射 upages,upages+ptsize 到pages，pages+ptsize上
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U);
f0102233:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102238:	83 c4 10             	add    $0x10,%esp
f010223b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102240:	77 15                	ja     f0102257 <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102242:	50                   	push   %eax
f0102243:	68 bc 4a 10 f0       	push   $0xf0104abc
f0102248:	68 ba 00 00 00       	push   $0xba
f010224d:	68 40 47 10 f0       	push   $0xf0104740
f0102252:	e8 49 de ff ff       	call   f01000a0 <_panic>
f0102257:	83 ec 08             	sub    $0x8,%esp
f010225a:	6a 04                	push   $0x4
f010225c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102261:	50                   	push   %eax
f0102262:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102267:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010226c:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102271:	e8 ad ed ff ff       	call   f0101023 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102276:	83 c4 10             	add    $0x10,%esp
f0102279:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f010227e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102283:	77 15                	ja     f010229a <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102285:	50                   	push   %eax
f0102286:	68 bc 4a 10 f0       	push   $0xf0104abc
f010228b:	68 cf 00 00 00       	push   $0xcf
f0102290:	68 40 47 10 f0       	push   $0xf0104740
f0102295:	e8 06 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f010229a:	83 ec 08             	sub    $0x8,%esp
f010229d:	6a 02                	push   $0x2
f010229f:	68 00 00 11 00       	push   $0x110000
f01022a4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022a9:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01022ae:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01022b3:	e8 6b ed ff ff       	call   f0101023 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0,PTE_W);
f01022b8:	83 c4 08             	add    $0x8,%esp
f01022bb:	6a 02                	push   $0x2
f01022bd:	6a 00                	push   $0x0
f01022bf:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01022c4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022c9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01022ce:	e8 50 ed ff ff       	call   f0101023 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01022d3:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f01022d9:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f01022de:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022e1:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022e8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022f0:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022f6:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01022f9:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022fc:	be 00 00 00 00       	mov    $0x0,%esi
f0102301:	eb 55                	jmp    f0102358 <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102303:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102309:	89 d8                	mov    %ebx,%eax
f010230b:	e8 dd e7 ff ff       	call   f0100aed <check_va2pa>
f0102310:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102317:	77 15                	ja     f010232e <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102319:	57                   	push   %edi
f010231a:	68 bc 4a 10 f0       	push   $0xf0104abc
f010231f:	68 f5 02 00 00       	push   $0x2f5
f0102324:	68 40 47 10 f0       	push   $0xf0104740
f0102329:	e8 72 dd ff ff       	call   f01000a0 <_panic>
f010232e:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102335:	39 d0                	cmp    %edx,%eax
f0102337:	74 19                	je     f0102352 <mem_init+0x11cd>
f0102339:	68 f4 4f 10 f0       	push   $0xf0104ff4
f010233e:	68 66 47 10 f0       	push   $0xf0104766
f0102343:	68 f5 02 00 00       	push   $0x2f5
f0102348:	68 40 47 10 f0       	push   $0xf0104740
f010234d:	e8 4e dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102352:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102358:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010235b:	77 a6                	ja     f0102303 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010235d:	8b 3d 48 be 17 f0    	mov    0xf017be48,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102363:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102366:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010236b:	89 f2                	mov    %esi,%edx
f010236d:	89 d8                	mov    %ebx,%eax
f010236f:	e8 79 e7 ff ff       	call   f0100aed <check_va2pa>
f0102374:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010237b:	77 15                	ja     f0102392 <mem_init+0x120d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010237d:	57                   	push   %edi
f010237e:	68 bc 4a 10 f0       	push   $0xf0104abc
f0102383:	68 fa 02 00 00       	push   $0x2fa
f0102388:	68 40 47 10 f0       	push   $0xf0104740
f010238d:	e8 0e dd ff ff       	call   f01000a0 <_panic>
f0102392:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102399:	39 c2                	cmp    %eax,%edx
f010239b:	74 19                	je     f01023b6 <mem_init+0x1231>
f010239d:	68 28 50 10 f0       	push   $0xf0105028
f01023a2:	68 66 47 10 f0       	push   $0xf0104766
f01023a7:	68 fa 02 00 00       	push   $0x2fa
f01023ac:	68 40 47 10 f0       	push   $0xf0104740
f01023b1:	e8 ea dc ff ff       	call   f01000a0 <_panic>
f01023b6:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01023bc:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01023c2:	75 a7                	jne    f010236b <mem_init+0x11e6>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023c4:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01023c7:	c1 e7 0c             	shl    $0xc,%edi
f01023ca:	be 00 00 00 00       	mov    $0x0,%esi
f01023cf:	eb 30                	jmp    f0102401 <mem_init+0x127c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01023d1:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01023d7:	89 d8                	mov    %ebx,%eax
f01023d9:	e8 0f e7 ff ff       	call   f0100aed <check_va2pa>
f01023de:	39 c6                	cmp    %eax,%esi
f01023e0:	74 19                	je     f01023fb <mem_init+0x1276>
f01023e2:	68 5c 50 10 f0       	push   $0xf010505c
f01023e7:	68 66 47 10 f0       	push   $0xf0104766
f01023ec:	68 fe 02 00 00       	push   $0x2fe
f01023f1:	68 40 47 10 f0       	push   $0xf0104740
f01023f6:	e8 a5 dc ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023fb:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102401:	39 fe                	cmp    %edi,%esi
f0102403:	72 cc                	jb     f01023d1 <mem_init+0x124c>
f0102405:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010240a:	89 f2                	mov    %esi,%edx
f010240c:	89 d8                	mov    %ebx,%eax
f010240e:	e8 da e6 ff ff       	call   f0100aed <check_va2pa>
f0102413:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102419:	39 c2                	cmp    %eax,%edx
f010241b:	74 19                	je     f0102436 <mem_init+0x12b1>
f010241d:	68 84 50 10 f0       	push   $0xf0105084
f0102422:	68 66 47 10 f0       	push   $0xf0104766
f0102427:	68 02 03 00 00       	push   $0x302
f010242c:	68 40 47 10 f0       	push   $0xf0104740
f0102431:	e8 6a dc ff ff       	call   f01000a0 <_panic>
f0102436:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010243c:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102442:	75 c6                	jne    f010240a <mem_init+0x1285>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102444:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102449:	89 d8                	mov    %ebx,%eax
f010244b:	e8 9d e6 ff ff       	call   f0100aed <check_va2pa>
f0102450:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102453:	74 51                	je     f01024a6 <mem_init+0x1321>
f0102455:	68 cc 50 10 f0       	push   $0xf01050cc
f010245a:	68 66 47 10 f0       	push   $0xf0104766
f010245f:	68 03 03 00 00       	push   $0x303
f0102464:	68 40 47 10 f0       	push   $0xf0104740
f0102469:	e8 32 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
	{
		switch (i)
f010246e:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102473:	72 36                	jb     f01024ab <mem_init+0x1326>
f0102475:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010247a:	76 07                	jbe    f0102483 <mem_init+0x12fe>
f010247c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102481:	75 28                	jne    f01024ab <mem_init+0x1326>
		{
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102483:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102487:	0f 85 83 00 00 00    	jne    f0102510 <mem_init+0x138b>
f010248d:	68 ab 49 10 f0       	push   $0xf01049ab
f0102492:	68 66 47 10 f0       	push   $0xf0104766
f0102497:	68 0e 03 00 00       	push   $0x30e
f010249c:	68 40 47 10 f0       	push   $0xf0104740
f01024a1:	e8 fa db ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01024a6:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE))
f01024ab:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01024b0:	76 3f                	jbe    f01024f1 <mem_init+0x136c>
			{
				assert(pgdir[i] & PTE_P);
f01024b2:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01024b5:	f6 c2 01             	test   $0x1,%dl
f01024b8:	75 19                	jne    f01024d3 <mem_init+0x134e>
f01024ba:	68 ab 49 10 f0       	push   $0xf01049ab
f01024bf:	68 66 47 10 f0       	push   $0xf0104766
f01024c4:	68 13 03 00 00       	push   $0x313
f01024c9:	68 40 47 10 f0       	push   $0xf0104740
f01024ce:	e8 cd db ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01024d3:	f6 c2 02             	test   $0x2,%dl
f01024d6:	75 38                	jne    f0102510 <mem_init+0x138b>
f01024d8:	68 bc 49 10 f0       	push   $0xf01049bc
f01024dd:	68 66 47 10 f0       	push   $0xf0104766
f01024e2:	68 14 03 00 00       	push   $0x314
f01024e7:	68 40 47 10 f0       	push   $0xf0104740
f01024ec:	e8 af db ff ff       	call   f01000a0 <_panic>
			}
			else
				assert(pgdir[i] == 0);
f01024f1:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01024f5:	74 19                	je     f0102510 <mem_init+0x138b>
f01024f7:	68 cd 49 10 f0       	push   $0xf01049cd
f01024fc:	68 66 47 10 f0       	push   $0xf0104766
f0102501:	68 17 03 00 00       	push   $0x317
f0102506:	68 40 47 10 f0       	push   $0xf0104740
f010250b:	e8 90 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++)
f0102510:	83 c0 01             	add    $0x1,%eax
f0102513:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102518:	0f 86 50 ff ff ff    	jbe    f010246e <mem_init+0x12e9>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010251e:	83 ec 0c             	sub    $0xc,%esp
f0102521:	68 fc 50 10 f0       	push   $0xf01050fc
f0102526:	e8 c6 07 00 00       	call   f0102cf1 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010252b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102530:	83 c4 10             	add    $0x10,%esp
f0102533:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102538:	77 15                	ja     f010254f <mem_init+0x13ca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010253a:	50                   	push   %eax
f010253b:	68 bc 4a 10 f0       	push   $0xf0104abc
f0102540:	68 e3 00 00 00       	push   $0xe3
f0102545:	68 40 47 10 f0       	push   $0xf0104740
f010254a:	e8 51 db ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010254f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102554:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102557:	b8 00 00 00 00       	mov    $0x0,%eax
f010255c:	e8 f0 e5 ff ff       	call   f0100b51 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102561:	0f 20 c0             	mov    %cr0,%eax
f0102564:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102567:	0d 23 00 05 80       	or     $0x80050023,%eax
f010256c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010256f:	83 ec 0c             	sub    $0xc,%esp
f0102572:	6a 00                	push   $0x0
f0102574:	e8 44 e9 ff ff       	call   f0100ebd <page_alloc>
f0102579:	89 c3                	mov    %eax,%ebx
f010257b:	83 c4 10             	add    $0x10,%esp
f010257e:	85 c0                	test   %eax,%eax
f0102580:	75 19                	jne    f010259b <mem_init+0x1416>
f0102582:	68 20 48 10 f0       	push   $0xf0104820
f0102587:	68 66 47 10 f0       	push   $0xf0104766
f010258c:	68 d6 03 00 00       	push   $0x3d6
f0102591:	68 40 47 10 f0       	push   $0xf0104740
f0102596:	e8 05 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010259b:	83 ec 0c             	sub    $0xc,%esp
f010259e:	6a 00                	push   $0x0
f01025a0:	e8 18 e9 ff ff       	call   f0100ebd <page_alloc>
f01025a5:	89 c7                	mov    %eax,%edi
f01025a7:	83 c4 10             	add    $0x10,%esp
f01025aa:	85 c0                	test   %eax,%eax
f01025ac:	75 19                	jne    f01025c7 <mem_init+0x1442>
f01025ae:	68 36 48 10 f0       	push   $0xf0104836
f01025b3:	68 66 47 10 f0       	push   $0xf0104766
f01025b8:	68 d7 03 00 00       	push   $0x3d7
f01025bd:	68 40 47 10 f0       	push   $0xf0104740
f01025c2:	e8 d9 da ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01025c7:	83 ec 0c             	sub    $0xc,%esp
f01025ca:	6a 00                	push   $0x0
f01025cc:	e8 ec e8 ff ff       	call   f0100ebd <page_alloc>
f01025d1:	89 c6                	mov    %eax,%esi
f01025d3:	83 c4 10             	add    $0x10,%esp
f01025d6:	85 c0                	test   %eax,%eax
f01025d8:	75 19                	jne    f01025f3 <mem_init+0x146e>
f01025da:	68 4c 48 10 f0       	push   $0xf010484c
f01025df:	68 66 47 10 f0       	push   $0xf0104766
f01025e4:	68 d8 03 00 00       	push   $0x3d8
f01025e9:	68 40 47 10 f0       	push   $0xf0104740
f01025ee:	e8 ad da ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01025f3:	83 ec 0c             	sub    $0xc,%esp
f01025f6:	53                   	push   %ebx
f01025f7:	e8 31 e9 ff ff       	call   f0100f2d <page_free>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f01025fc:	89 f8                	mov    %edi,%eax
f01025fe:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102604:	c1 f8 03             	sar    $0x3,%eax
f0102607:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010260a:	89 c2                	mov    %eax,%edx
f010260c:	c1 ea 0c             	shr    $0xc,%edx
f010260f:	83 c4 10             	add    $0x10,%esp
f0102612:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102618:	72 12                	jb     f010262c <mem_init+0x14a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010261a:	50                   	push   %eax
f010261b:	68 dc 49 10 f0       	push   $0xf01049dc
f0102620:	6a 5b                	push   $0x5b
f0102622:	68 4c 47 10 f0       	push   $0xf010474c
f0102627:	e8 74 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010262c:	83 ec 04             	sub    $0x4,%esp
f010262f:	68 00 10 00 00       	push   $0x1000
f0102634:	6a 01                	push   $0x1
f0102636:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010263b:	50                   	push   %eax
f010263c:	e8 e4 15 00 00       	call   f0103c25 <memset>

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102641:	89 f0                	mov    %esi,%eax
f0102643:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102649:	c1 f8 03             	sar    $0x3,%eax
f010264c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010264f:	89 c2                	mov    %eax,%edx
f0102651:	c1 ea 0c             	shr    $0xc,%edx
f0102654:	83 c4 10             	add    $0x10,%esp
f0102657:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010265d:	72 12                	jb     f0102671 <mem_init+0x14ec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010265f:	50                   	push   %eax
f0102660:	68 dc 49 10 f0       	push   $0xf01049dc
f0102665:	6a 5b                	push   $0x5b
f0102667:	68 4c 47 10 f0       	push   $0xf010474c
f010266c:	e8 2f da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102671:	83 ec 04             	sub    $0x4,%esp
f0102674:	68 00 10 00 00       	push   $0x1000
f0102679:	6a 02                	push   $0x2
f010267b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102680:	50                   	push   %eax
f0102681:	e8 9f 15 00 00       	call   f0103c25 <memset>
	page_insert(kern_pgdir, pp1, (void *)PGSIZE, PTE_W);
f0102686:	6a 02                	push   $0x2
f0102688:	68 00 10 00 00       	push   $0x1000
f010268d:	57                   	push   %edi
f010268e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102694:	e8 86 ea ff ff       	call   f010111f <page_insert>
	assert(pp1->pp_ref == 1);
f0102699:	83 c4 20             	add    $0x20,%esp
f010269c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01026a1:	74 19                	je     f01026bc <mem_init+0x1537>
f01026a3:	68 c6 48 10 f0       	push   $0xf01048c6
f01026a8:	68 66 47 10 f0       	push   $0xf0104766
f01026ad:	68 dd 03 00 00       	push   $0x3dd
f01026b2:	68 40 47 10 f0       	push   $0xf0104740
f01026b7:	e8 e4 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01026bc:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01026c3:	01 01 01 
f01026c6:	74 19                	je     f01026e1 <mem_init+0x155c>
f01026c8:	68 1c 51 10 f0       	push   $0xf010511c
f01026cd:	68 66 47 10 f0       	push   $0xf0104766
f01026d2:	68 de 03 00 00       	push   $0x3de
f01026d7:	68 40 47 10 f0       	push   $0xf0104740
f01026dc:	e8 bf d9 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void *)PGSIZE, PTE_W);
f01026e1:	6a 02                	push   $0x2
f01026e3:	68 00 10 00 00       	push   $0x1000
f01026e8:	56                   	push   %esi
f01026e9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01026ef:	e8 2b ea ff ff       	call   f010111f <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01026f4:	83 c4 10             	add    $0x10,%esp
f01026f7:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01026fe:	02 02 02 
f0102701:	74 19                	je     f010271c <mem_init+0x1597>
f0102703:	68 40 51 10 f0       	push   $0xf0105140
f0102708:	68 66 47 10 f0       	push   $0xf0104766
f010270d:	68 e0 03 00 00       	push   $0x3e0
f0102712:	68 40 47 10 f0       	push   $0xf0104740
f0102717:	e8 84 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010271c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102721:	74 19                	je     f010273c <mem_init+0x15b7>
f0102723:	68 e8 48 10 f0       	push   $0xf01048e8
f0102728:	68 66 47 10 f0       	push   $0xf0104766
f010272d:	68 e1 03 00 00       	push   $0x3e1
f0102732:	68 40 47 10 f0       	push   $0xf0104740
f0102737:	e8 64 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010273c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102741:	74 19                	je     f010275c <mem_init+0x15d7>
f0102743:	68 52 49 10 f0       	push   $0xf0104952
f0102748:	68 66 47 10 f0       	push   $0xf0104766
f010274d:	68 e2 03 00 00       	push   $0x3e2
f0102752:	68 40 47 10 f0       	push   $0xf0104740
f0102757:	e8 44 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010275c:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102763:	03 03 03 

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	//pp-pages 为第几个页帧，左移12bit即为该页所在的物理地址
	return (pp - pages) << PGSHIFT;
f0102766:	89 f0                	mov    %esi,%eax
f0102768:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010276e:	c1 f8 03             	sar    $0x3,%eax
f0102771:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102774:	89 c2                	mov    %eax,%edx
f0102776:	c1 ea 0c             	shr    $0xc,%edx
f0102779:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010277f:	72 12                	jb     f0102793 <mem_init+0x160e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102781:	50                   	push   %eax
f0102782:	68 dc 49 10 f0       	push   $0xf01049dc
f0102787:	6a 5b                	push   $0x5b
f0102789:	68 4c 47 10 f0       	push   $0xf010474c
f010278e:	e8 0d d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102793:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010279a:	03 03 03 
f010279d:	74 19                	je     f01027b8 <mem_init+0x1633>
f010279f:	68 64 51 10 f0       	push   $0xf0105164
f01027a4:	68 66 47 10 f0       	push   $0xf0104766
f01027a9:	68 e4 03 00 00       	push   $0x3e4
f01027ae:	68 40 47 10 f0       	push   $0xf0104740
f01027b3:	e8 e8 d8 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void *)PGSIZE);
f01027b8:	83 ec 08             	sub    $0x8,%esp
f01027bb:	68 00 10 00 00       	push   $0x1000
f01027c0:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01027c6:	e8 12 e9 ff ff       	call   f01010dd <page_remove>
	assert(pp2->pp_ref == 0);
f01027cb:	83 c4 10             	add    $0x10,%esp
f01027ce:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027d3:	74 19                	je     f01027ee <mem_init+0x1669>
f01027d5:	68 20 49 10 f0       	push   $0xf0104920
f01027da:	68 66 47 10 f0       	push   $0xf0104766
f01027df:	68 e6 03 00 00       	push   $0x3e6
f01027e4:	68 40 47 10 f0       	push   $0xf0104740
f01027e9:	e8 b2 d8 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027ee:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f01027f4:	8b 11                	mov    (%ecx),%edx
f01027f6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027fc:	89 d8                	mov    %ebx,%eax
f01027fe:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102804:	c1 f8 03             	sar    $0x3,%eax
f0102807:	c1 e0 0c             	shl    $0xc,%eax
f010280a:	39 c2                	cmp    %eax,%edx
f010280c:	74 19                	je     f0102827 <mem_init+0x16a2>
f010280e:	68 70 4c 10 f0       	push   $0xf0104c70
f0102813:	68 66 47 10 f0       	push   $0xf0104766
f0102818:	68 e9 03 00 00       	push   $0x3e9
f010281d:	68 40 47 10 f0       	push   $0xf0104740
f0102822:	e8 79 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102827:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010282d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102832:	74 19                	je     f010284d <mem_init+0x16c8>
f0102834:	68 d7 48 10 f0       	push   $0xf01048d7
f0102839:	68 66 47 10 f0       	push   $0xf0104766
f010283e:	68 eb 03 00 00       	push   $0x3eb
f0102843:	68 40 47 10 f0       	push   $0xf0104740
f0102848:	e8 53 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f010284d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102853:	83 ec 0c             	sub    $0xc,%esp
f0102856:	53                   	push   %ebx
f0102857:	e8 d1 e6 ff ff       	call   f0100f2d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010285c:	c7 04 24 90 51 10 f0 	movl   $0xf0105190,(%esp)
f0102863:	e8 89 04 00 00       	call   f0102cf1 <cprintf>
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102868:	83 c4 10             	add    $0x10,%esp
f010286b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010286e:	5b                   	pop    %ebx
f010286f:	5e                   	pop    %esi
f0102870:	5f                   	pop    %edi
f0102871:	5d                   	pop    %ebp
f0102872:	c3                   	ret    

f0102873 <tlb_invalidate>:
//
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void tlb_invalidate(pde_t *pgdir, void *va)
{
f0102873:	55                   	push   %ebp
f0102874:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102876:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102879:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010287c:	5d                   	pop    %ebp
f010287d:	c3                   	ret    

f010287e <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010287e:	55                   	push   %ebp
f010287f:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102881:	b8 00 00 00 00       	mov    $0x0,%eax
f0102886:	5d                   	pop    %ebp
f0102887:	c3                   	ret    

f0102888 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102888:	55                   	push   %ebp
f0102889:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f010288b:	5d                   	pop    %ebp
f010288c:	c3                   	ret    

f010288d <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010288d:	55                   	push   %ebp
f010288e:	89 e5                	mov    %esp,%ebp
f0102890:	8b 55 08             	mov    0x8(%ebp),%edx
f0102893:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102896:	85 d2                	test   %edx,%edx
f0102898:	75 11                	jne    f01028ab <envid2env+0x1e>
		*env_store = curenv;
f010289a:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010289f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028a2:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01028a9:	eb 5e                	jmp    f0102909 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028ab:	89 d0                	mov    %edx,%eax
f01028ad:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028b2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028b5:	c1 e0 05             	shl    $0x5,%eax
f01028b8:	03 05 48 be 17 f0    	add    0xf017be48,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028be:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028c2:	74 05                	je     f01028c9 <envid2env+0x3c>
f01028c4:	3b 50 48             	cmp    0x48(%eax),%edx
f01028c7:	74 10                	je     f01028d9 <envid2env+0x4c>
		*env_store = 0;
f01028c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028cc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028d2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028d7:	eb 30                	jmp    f0102909 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01028d9:	84 c9                	test   %cl,%cl
f01028db:	74 22                	je     f01028ff <envid2env+0x72>
f01028dd:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f01028e3:	39 d0                	cmp    %edx,%eax
f01028e5:	74 18                	je     f01028ff <envid2env+0x72>
f01028e7:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028ea:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028ed:	74 10                	je     f01028ff <envid2env+0x72>
		*env_store = 0;
f01028ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028f8:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028fd:	eb 0a                	jmp    f0102909 <envid2env+0x7c>
	}

	*env_store = e;
f01028ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102902:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102904:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102909:	5d                   	pop    %ebp
f010290a:	c3                   	ret    

f010290b <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010290b:	55                   	push   %ebp
f010290c:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010290e:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102913:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102916:	b8 23 00 00 00       	mov    $0x23,%eax
f010291b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010291d:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010291f:	b8 10 00 00 00       	mov    $0x10,%eax
f0102924:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102926:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102928:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010292a:	ea 31 29 10 f0 08 00 	ljmp   $0x8,$0xf0102931
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102931:	b8 00 00 00 00       	mov    $0x0,%eax
f0102936:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102939:	5d                   	pop    %ebp
f010293a:	c3                   	ret    

f010293b <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010293b:	55                   	push   %ebp
f010293c:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.

	// Per-CPU part of the initialization
	env_init_percpu();
f010293e:	e8 c8 ff ff ff       	call   f010290b <env_init_percpu>
}
f0102943:	5d                   	pop    %ebp
f0102944:	c3                   	ret    

f0102945 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102945:	55                   	push   %ebp
f0102946:	89 e5                	mov    %esp,%ebp
f0102948:	53                   	push   %ebx
f0102949:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010294c:	8b 1d 4c be 17 f0    	mov    0xf017be4c,%ebx
f0102952:	85 db                	test   %ebx,%ebx
f0102954:	0f 84 f4 00 00 00    	je     f0102a4e <env_alloc+0x109>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010295a:	83 ec 0c             	sub    $0xc,%esp
f010295d:	6a 01                	push   $0x1
f010295f:	e8 59 e5 ff ff       	call   f0100ebd <page_alloc>
f0102964:	83 c4 10             	add    $0x10,%esp
f0102967:	85 c0                	test   %eax,%eax
f0102969:	0f 84 e6 00 00 00    	je     f0102a55 <env_alloc+0x110>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010296f:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102972:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102977:	77 15                	ja     f010298e <env_alloc+0x49>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102979:	50                   	push   %eax
f010297a:	68 bc 4a 10 f0       	push   $0xf0104abc
f010297f:	68 b9 00 00 00       	push   $0xb9
f0102984:	68 f2 51 10 f0       	push   $0xf01051f2
f0102989:	e8 12 d7 ff ff       	call   f01000a0 <_panic>
f010298e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102994:	83 ca 05             	or     $0x5,%edx
f0102997:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010299d:	8b 43 48             	mov    0x48(%ebx),%eax
f01029a0:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029a5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029aa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029af:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029b2:	89 da                	mov    %ebx,%edx
f01029b4:	2b 15 48 be 17 f0    	sub    0xf017be48,%edx
f01029ba:	c1 fa 05             	sar    $0x5,%edx
f01029bd:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01029c3:	09 d0                	or     %edx,%eax
f01029c5:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01029c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029cb:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01029ce:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01029d5:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01029dc:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01029e3:	83 ec 04             	sub    $0x4,%esp
f01029e6:	6a 44                	push   $0x44
f01029e8:	6a 00                	push   $0x0
f01029ea:	53                   	push   %ebx
f01029eb:	e8 35 12 00 00       	call   f0103c25 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01029f0:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01029f6:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01029fc:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a02:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a09:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a0f:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a12:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	*newenv_store = e;
f0102a17:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a1a:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a1c:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a1f:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102a24:	83 c4 10             	add    $0x10,%esp
f0102a27:	85 c0                	test   %eax,%eax
f0102a29:	74 05                	je     f0102a30 <env_alloc+0xeb>
f0102a2b:	8b 40 48             	mov    0x48(%eax),%eax
f0102a2e:	eb 05                	jmp    f0102a35 <env_alloc+0xf0>
f0102a30:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a35:	83 ec 04             	sub    $0x4,%esp
f0102a38:	52                   	push   %edx
f0102a39:	50                   	push   %eax
f0102a3a:	68 fd 51 10 f0       	push   $0xf01051fd
f0102a3f:	e8 ad 02 00 00       	call   f0102cf1 <cprintf>
	return 0;
f0102a44:	83 c4 10             	add    $0x10,%esp
f0102a47:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a4c:	eb 0c                	jmp    f0102a5a <env_alloc+0x115>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a4e:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a53:	eb 05                	jmp    f0102a5a <env_alloc+0x115>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a55:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a5a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a5d:	c9                   	leave  
f0102a5e:	c3                   	ret    

f0102a5f <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102a5f:	55                   	push   %ebp
f0102a60:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102a62:	5d                   	pop    %ebp
f0102a63:	c3                   	ret    

f0102a64 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102a64:	55                   	push   %ebp
f0102a65:	89 e5                	mov    %esp,%ebp
f0102a67:	57                   	push   %edi
f0102a68:	56                   	push   %esi
f0102a69:	53                   	push   %ebx
f0102a6a:	83 ec 1c             	sub    $0x1c,%esp
f0102a6d:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102a70:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102a76:	39 fa                	cmp    %edi,%edx
f0102a78:	75 29                	jne    f0102aa3 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102a7a:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a7f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a84:	77 15                	ja     f0102a9b <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a86:	50                   	push   %eax
f0102a87:	68 bc 4a 10 f0       	push   $0xf0104abc
f0102a8c:	68 68 01 00 00       	push   $0x168
f0102a91:	68 f2 51 10 f0       	push   $0xf01051f2
f0102a96:	e8 05 d6 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a9b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102aa0:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102aa3:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102aa6:	85 d2                	test   %edx,%edx
f0102aa8:	74 05                	je     f0102aaf <env_free+0x4b>
f0102aaa:	8b 42 48             	mov    0x48(%edx),%eax
f0102aad:	eb 05                	jmp    f0102ab4 <env_free+0x50>
f0102aaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ab4:	83 ec 04             	sub    $0x4,%esp
f0102ab7:	51                   	push   %ecx
f0102ab8:	50                   	push   %eax
f0102ab9:	68 12 52 10 f0       	push   $0xf0105212
f0102abe:	e8 2e 02 00 00       	call   f0102cf1 <cprintf>
f0102ac3:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ac6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102acd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102ad0:	89 d0                	mov    %edx,%eax
f0102ad2:	c1 e0 02             	shl    $0x2,%eax
f0102ad5:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102ad8:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102adb:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102ade:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102ae4:	0f 84 a8 00 00 00    	je     f0102b92 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102aea:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af0:	89 f0                	mov    %esi,%eax
f0102af2:	c1 e8 0c             	shr    $0xc,%eax
f0102af5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102af8:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102afe:	77 15                	ja     f0102b15 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b00:	56                   	push   %esi
f0102b01:	68 dc 49 10 f0       	push   $0xf01049dc
f0102b06:	68 77 01 00 00       	push   $0x177
f0102b0b:	68 f2 51 10 f0       	push   $0xf01051f2
f0102b10:	e8 8b d5 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b15:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b18:	c1 e0 16             	shl    $0x16,%eax
f0102b1b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b1e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102b23:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102b2a:	01 
f0102b2b:	74 17                	je     f0102b44 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b2d:	83 ec 08             	sub    $0x8,%esp
f0102b30:	89 d8                	mov    %ebx,%eax
f0102b32:	c1 e0 0c             	shl    $0xc,%eax
f0102b35:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102b38:	50                   	push   %eax
f0102b39:	ff 77 5c             	pushl  0x5c(%edi)
f0102b3c:	e8 9c e5 ff ff       	call   f01010dd <page_remove>
f0102b41:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b44:	83 c3 01             	add    $0x1,%ebx
f0102b47:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102b4d:	75 d4                	jne    f0102b23 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102b4f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b52:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b55:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b5c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102b5f:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102b65:	72 14                	jb     f0102b7b <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102b67:	83 ec 04             	sub    $0x4,%esp
f0102b6a:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0102b6f:	6a 54                	push   $0x54
f0102b71:	68 4c 47 10 f0       	push   $0xf010474c
f0102b76:	e8 25 d5 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102b7b:	83 ec 0c             	sub    $0xc,%esp
f0102b7e:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102b83:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102b86:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102b89:	50                   	push   %eax
f0102b8a:	e8 d9 e3 ff ff       	call   f0100f68 <page_decref>
f0102b8f:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102b92:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102b96:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b99:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102b9e:	0f 85 29 ff ff ff    	jne    f0102acd <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102ba4:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ba7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bac:	77 15                	ja     f0102bc3 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bae:	50                   	push   %eax
f0102baf:	68 bc 4a 10 f0       	push   $0xf0104abc
f0102bb4:	68 85 01 00 00       	push   $0x185
f0102bb9:	68 f2 51 10 f0       	push   $0xf01051f2
f0102bbe:	e8 dd d4 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102bc3:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bca:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bcf:	c1 e8 0c             	shr    $0xc,%eax
f0102bd2:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102bd8:	72 14                	jb     f0102bee <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102bda:	83 ec 04             	sub    $0x4,%esp
f0102bdd:	68 e0 4a 10 f0       	push   $0xf0104ae0
f0102be2:	6a 54                	push   $0x54
f0102be4:	68 4c 47 10 f0       	push   $0xf010474c
f0102be9:	e8 b2 d4 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102bee:	83 ec 0c             	sub    $0xc,%esp
f0102bf1:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102bf7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102bfa:	50                   	push   %eax
f0102bfb:	e8 68 e3 ff ff       	call   f0100f68 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102c00:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102c07:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
f0102c0c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102c0f:	89 3d 4c be 17 f0    	mov    %edi,0xf017be4c
}
f0102c15:	83 c4 10             	add    $0x10,%esp
f0102c18:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c1b:	5b                   	pop    %ebx
f0102c1c:	5e                   	pop    %esi
f0102c1d:	5f                   	pop    %edi
f0102c1e:	5d                   	pop    %ebp
f0102c1f:	c3                   	ret    

f0102c20 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102c20:	55                   	push   %ebp
f0102c21:	89 e5                	mov    %esp,%ebp
f0102c23:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102c26:	ff 75 08             	pushl  0x8(%ebp)
f0102c29:	e8 36 fe ff ff       	call   f0102a64 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102c2e:	c7 04 24 bc 51 10 f0 	movl   $0xf01051bc,(%esp)
f0102c35:	e8 b7 00 00 00       	call   f0102cf1 <cprintf>
f0102c3a:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102c3d:	83 ec 0c             	sub    $0xc,%esp
f0102c40:	6a 00                	push   $0x0
f0102c42:	e8 f6 dc ff ff       	call   f010093d <monitor>
f0102c47:	83 c4 10             	add    $0x10,%esp
f0102c4a:	eb f1                	jmp    f0102c3d <env_destroy+0x1d>

f0102c4c <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102c4c:	55                   	push   %ebp
f0102c4d:	89 e5                	mov    %esp,%ebp
f0102c4f:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102c52:	8b 65 08             	mov    0x8(%ebp),%esp
f0102c55:	61                   	popa   
f0102c56:	07                   	pop    %es
f0102c57:	1f                   	pop    %ds
f0102c58:	83 c4 08             	add    $0x8,%esp
f0102c5b:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102c5c:	68 28 52 10 f0       	push   $0xf0105228
f0102c61:	68 ad 01 00 00       	push   $0x1ad
f0102c66:	68 f2 51 10 f0       	push   $0xf01051f2
f0102c6b:	e8 30 d4 ff ff       	call   f01000a0 <_panic>

f0102c70 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102c70:	55                   	push   %ebp
f0102c71:	89 e5                	mov    %esp,%ebp
f0102c73:	83 ec 0c             	sub    $0xc,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0102c76:	68 34 52 10 f0       	push   $0xf0105234
f0102c7b:	68 cc 01 00 00       	push   $0x1cc
f0102c80:	68 f2 51 10 f0       	push   $0xf01051f2
f0102c85:	e8 16 d4 ff ff       	call   f01000a0 <_panic>

f0102c8a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c8a:	55                   	push   %ebp
f0102c8b:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c8d:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c92:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c95:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102c96:	ba 71 00 00 00       	mov    $0x71,%edx
f0102c9b:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102c9c:	0f b6 c0             	movzbl %al,%eax
}
f0102c9f:	5d                   	pop    %ebp
f0102ca0:	c3                   	ret    

f0102ca1 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ca1:	55                   	push   %ebp
f0102ca2:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ca4:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ca9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cac:	ee                   	out    %al,(%dx)
f0102cad:	ba 71 00 00 00       	mov    $0x71,%edx
f0102cb2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cb5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102cb6:	5d                   	pop    %ebp
f0102cb7:	c3                   	ret    

f0102cb8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102cb8:	55                   	push   %ebp
f0102cb9:	89 e5                	mov    %esp,%ebp
f0102cbb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102cbe:	ff 75 08             	pushl  0x8(%ebp)
f0102cc1:	e8 41 d9 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102cc6:	83 c4 10             	add    $0x10,%esp
f0102cc9:	c9                   	leave  
f0102cca:	c3                   	ret    

f0102ccb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ccb:	55                   	push   %ebp
f0102ccc:	89 e5                	mov    %esp,%ebp
f0102cce:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102cd1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102cd8:	ff 75 0c             	pushl  0xc(%ebp)
f0102cdb:	ff 75 08             	pushl  0x8(%ebp)
f0102cde:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ce1:	50                   	push   %eax
f0102ce2:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0102ce7:	e8 ec 07 00 00       	call   f01034d8 <vprintfmt>
	return cnt;
}
f0102cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102cef:	c9                   	leave  
f0102cf0:	c3                   	ret    

f0102cf1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102cf1:	55                   	push   %ebp
f0102cf2:	89 e5                	mov    %esp,%ebp
f0102cf4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102cf7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102cfa:	50                   	push   %eax
f0102cfb:	ff 75 08             	pushl  0x8(%ebp)
f0102cfe:	e8 c8 ff ff ff       	call   f0102ccb <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d03:	c9                   	leave  
f0102d04:	c3                   	ret    

f0102d05 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102d05:	55                   	push   %ebp
f0102d06:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102d08:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102d0d:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102d14:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102d17:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102d1e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102d20:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102d27:	67 00 
f0102d29:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102d2f:	89 c2                	mov    %eax,%edx
f0102d31:	c1 ea 10             	shr    $0x10,%edx
f0102d34:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102d3a:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102d41:	c1 e8 18             	shr    $0x18,%eax
f0102d44:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102d49:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102d50:	b8 28 00 00 00       	mov    $0x28,%eax
f0102d55:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102d58:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102d5d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102d60:	5d                   	pop    %ebp
f0102d61:	c3                   	ret    

f0102d62 <trap_init>:
}


void
trap_init(void)
{
f0102d62:	55                   	push   %ebp
f0102d63:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102d65:	e8 9b ff ff ff       	call   f0102d05 <trap_init_percpu>
}
f0102d6a:	5d                   	pop    %ebp
f0102d6b:	c3                   	ret    

f0102d6c <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102d6c:	55                   	push   %ebp
f0102d6d:	89 e5                	mov    %esp,%ebp
f0102d6f:	53                   	push   %ebx
f0102d70:	83 ec 0c             	sub    $0xc,%esp
f0102d73:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102d76:	ff 33                	pushl  (%ebx)
f0102d78:	68 50 52 10 f0       	push   $0xf0105250
f0102d7d:	e8 6f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102d82:	83 c4 08             	add    $0x8,%esp
f0102d85:	ff 73 04             	pushl  0x4(%ebx)
f0102d88:	68 5f 52 10 f0       	push   $0xf010525f
f0102d8d:	e8 5f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102d92:	83 c4 08             	add    $0x8,%esp
f0102d95:	ff 73 08             	pushl  0x8(%ebx)
f0102d98:	68 6e 52 10 f0       	push   $0xf010526e
f0102d9d:	e8 4f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102da2:	83 c4 08             	add    $0x8,%esp
f0102da5:	ff 73 0c             	pushl  0xc(%ebx)
f0102da8:	68 7d 52 10 f0       	push   $0xf010527d
f0102dad:	e8 3f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102db2:	83 c4 08             	add    $0x8,%esp
f0102db5:	ff 73 10             	pushl  0x10(%ebx)
f0102db8:	68 8c 52 10 f0       	push   $0xf010528c
f0102dbd:	e8 2f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102dc2:	83 c4 08             	add    $0x8,%esp
f0102dc5:	ff 73 14             	pushl  0x14(%ebx)
f0102dc8:	68 9b 52 10 f0       	push   $0xf010529b
f0102dcd:	e8 1f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102dd2:	83 c4 08             	add    $0x8,%esp
f0102dd5:	ff 73 18             	pushl  0x18(%ebx)
f0102dd8:	68 aa 52 10 f0       	push   $0xf01052aa
f0102ddd:	e8 0f ff ff ff       	call   f0102cf1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102de2:	83 c4 08             	add    $0x8,%esp
f0102de5:	ff 73 1c             	pushl  0x1c(%ebx)
f0102de8:	68 b9 52 10 f0       	push   $0xf01052b9
f0102ded:	e8 ff fe ff ff       	call   f0102cf1 <cprintf>
}
f0102df2:	83 c4 10             	add    $0x10,%esp
f0102df5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102df8:	c9                   	leave  
f0102df9:	c3                   	ret    

f0102dfa <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102dfa:	55                   	push   %ebp
f0102dfb:	89 e5                	mov    %esp,%ebp
f0102dfd:	56                   	push   %esi
f0102dfe:	53                   	push   %ebx
f0102dff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102e02:	83 ec 08             	sub    $0x8,%esp
f0102e05:	53                   	push   %ebx
f0102e06:	68 ef 53 10 f0       	push   $0xf01053ef
f0102e0b:	e8 e1 fe ff ff       	call   f0102cf1 <cprintf>
	print_regs(&tf->tf_regs);
f0102e10:	89 1c 24             	mov    %ebx,(%esp)
f0102e13:	e8 54 ff ff ff       	call   f0102d6c <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102e18:	83 c4 08             	add    $0x8,%esp
f0102e1b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102e1f:	50                   	push   %eax
f0102e20:	68 0a 53 10 f0       	push   $0xf010530a
f0102e25:	e8 c7 fe ff ff       	call   f0102cf1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102e2a:	83 c4 08             	add    $0x8,%esp
f0102e2d:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102e31:	50                   	push   %eax
f0102e32:	68 1d 53 10 f0       	push   $0xf010531d
f0102e37:	e8 b5 fe ff ff       	call   f0102cf1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e3c:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0102e3f:	83 c4 10             	add    $0x10,%esp
f0102e42:	83 f8 13             	cmp    $0x13,%eax
f0102e45:	77 09                	ja     f0102e50 <print_trapframe+0x56>
		return excnames[trapno];
f0102e47:	8b 14 85 c0 55 10 f0 	mov    -0xfefaa40(,%eax,4),%edx
f0102e4e:	eb 10                	jmp    f0102e60 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102e50:	83 f8 30             	cmp    $0x30,%eax
f0102e53:	b9 d4 52 10 f0       	mov    $0xf01052d4,%ecx
f0102e58:	ba c8 52 10 f0       	mov    $0xf01052c8,%edx
f0102e5d:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e60:	83 ec 04             	sub    $0x4,%esp
f0102e63:	52                   	push   %edx
f0102e64:	50                   	push   %eax
f0102e65:	68 30 53 10 f0       	push   $0xf0105330
f0102e6a:	e8 82 fe ff ff       	call   f0102cf1 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102e6f:	83 c4 10             	add    $0x10,%esp
f0102e72:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0102e78:	75 1a                	jne    f0102e94 <print_trapframe+0x9a>
f0102e7a:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102e7e:	75 14                	jne    f0102e94 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0102e80:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102e83:	83 ec 08             	sub    $0x8,%esp
f0102e86:	50                   	push   %eax
f0102e87:	68 42 53 10 f0       	push   $0xf0105342
f0102e8c:	e8 60 fe ff ff       	call   f0102cf1 <cprintf>
f0102e91:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102e94:	83 ec 08             	sub    $0x8,%esp
f0102e97:	ff 73 2c             	pushl  0x2c(%ebx)
f0102e9a:	68 51 53 10 f0       	push   $0xf0105351
f0102e9f:	e8 4d fe ff ff       	call   f0102cf1 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102ea4:	83 c4 10             	add    $0x10,%esp
f0102ea7:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102eab:	75 49                	jne    f0102ef6 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102ead:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102eb0:	89 c2                	mov    %eax,%edx
f0102eb2:	83 e2 01             	and    $0x1,%edx
f0102eb5:	ba ee 52 10 f0       	mov    $0xf01052ee,%edx
f0102eba:	b9 e3 52 10 f0       	mov    $0xf01052e3,%ecx
f0102ebf:	0f 44 ca             	cmove  %edx,%ecx
f0102ec2:	89 c2                	mov    %eax,%edx
f0102ec4:	83 e2 02             	and    $0x2,%edx
f0102ec7:	ba 00 53 10 f0       	mov    $0xf0105300,%edx
f0102ecc:	be fa 52 10 f0       	mov    $0xf01052fa,%esi
f0102ed1:	0f 45 d6             	cmovne %esi,%edx
f0102ed4:	83 e0 04             	and    $0x4,%eax
f0102ed7:	be 1a 54 10 f0       	mov    $0xf010541a,%esi
f0102edc:	b8 05 53 10 f0       	mov    $0xf0105305,%eax
f0102ee1:	0f 44 c6             	cmove  %esi,%eax
f0102ee4:	51                   	push   %ecx
f0102ee5:	52                   	push   %edx
f0102ee6:	50                   	push   %eax
f0102ee7:	68 5f 53 10 f0       	push   $0xf010535f
f0102eec:	e8 00 fe ff ff       	call   f0102cf1 <cprintf>
f0102ef1:	83 c4 10             	add    $0x10,%esp
f0102ef4:	eb 10                	jmp    f0102f06 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102ef6:	83 ec 0c             	sub    $0xc,%esp
f0102ef9:	68 a9 49 10 f0       	push   $0xf01049a9
f0102efe:	e8 ee fd ff ff       	call   f0102cf1 <cprintf>
f0102f03:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102f06:	83 ec 08             	sub    $0x8,%esp
f0102f09:	ff 73 30             	pushl  0x30(%ebx)
f0102f0c:	68 6e 53 10 f0       	push   $0xf010536e
f0102f11:	e8 db fd ff ff       	call   f0102cf1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102f16:	83 c4 08             	add    $0x8,%esp
f0102f19:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102f1d:	50                   	push   %eax
f0102f1e:	68 7d 53 10 f0       	push   $0xf010537d
f0102f23:	e8 c9 fd ff ff       	call   f0102cf1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102f28:	83 c4 08             	add    $0x8,%esp
f0102f2b:	ff 73 38             	pushl  0x38(%ebx)
f0102f2e:	68 90 53 10 f0       	push   $0xf0105390
f0102f33:	e8 b9 fd ff ff       	call   f0102cf1 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102f38:	83 c4 10             	add    $0x10,%esp
f0102f3b:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102f3f:	74 25                	je     f0102f66 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102f41:	83 ec 08             	sub    $0x8,%esp
f0102f44:	ff 73 3c             	pushl  0x3c(%ebx)
f0102f47:	68 9f 53 10 f0       	push   $0xf010539f
f0102f4c:	e8 a0 fd ff ff       	call   f0102cf1 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102f51:	83 c4 08             	add    $0x8,%esp
f0102f54:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102f58:	50                   	push   %eax
f0102f59:	68 ae 53 10 f0       	push   $0xf01053ae
f0102f5e:	e8 8e fd ff ff       	call   f0102cf1 <cprintf>
f0102f63:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f66:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102f69:	5b                   	pop    %ebx
f0102f6a:	5e                   	pop    %esi
f0102f6b:	5d                   	pop    %ebp
f0102f6c:	c3                   	ret    

f0102f6d <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102f6d:	55                   	push   %ebp
f0102f6e:	89 e5                	mov    %esp,%ebp
f0102f70:	57                   	push   %edi
f0102f71:	56                   	push   %esi
f0102f72:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102f75:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0102f76:	9c                   	pushf  
f0102f77:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102f78:	f6 c4 02             	test   $0x2,%ah
f0102f7b:	74 19                	je     f0102f96 <trap+0x29>
f0102f7d:	68 c1 53 10 f0       	push   $0xf01053c1
f0102f82:	68 66 47 10 f0       	push   $0xf0104766
f0102f87:	68 a7 00 00 00       	push   $0xa7
f0102f8c:	68 da 53 10 f0       	push   $0xf01053da
f0102f91:	e8 0a d1 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102f96:	83 ec 08             	sub    $0x8,%esp
f0102f99:	56                   	push   %esi
f0102f9a:	68 e6 53 10 f0       	push   $0xf01053e6
f0102f9f:	e8 4d fd ff ff       	call   f0102cf1 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0102fa4:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0102fa8:	83 e0 03             	and    $0x3,%eax
f0102fab:	83 c4 10             	add    $0x10,%esp
f0102fae:	66 83 f8 03          	cmp    $0x3,%ax
f0102fb2:	75 31                	jne    f0102fe5 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0102fb4:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102fb9:	85 c0                	test   %eax,%eax
f0102fbb:	75 19                	jne    f0102fd6 <trap+0x69>
f0102fbd:	68 01 54 10 f0       	push   $0xf0105401
f0102fc2:	68 66 47 10 f0       	push   $0xf0104766
f0102fc7:	68 ad 00 00 00       	push   $0xad
f0102fcc:	68 da 53 10 f0       	push   $0xf01053da
f0102fd1:	e8 ca d0 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0102fd6:	b9 11 00 00 00       	mov    $0x11,%ecx
f0102fdb:	89 c7                	mov    %eax,%edi
f0102fdd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0102fdf:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0102fe5:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0102feb:	83 ec 0c             	sub    $0xc,%esp
f0102fee:	56                   	push   %esi
f0102fef:	e8 06 fe ff ff       	call   f0102dfa <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0102ff4:	83 c4 10             	add    $0x10,%esp
f0102ff7:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0102ffc:	75 17                	jne    f0103015 <trap+0xa8>
		panic("unhandled trap in kernel");
f0102ffe:	83 ec 04             	sub    $0x4,%esp
f0103001:	68 08 54 10 f0       	push   $0xf0105408
f0103006:	68 96 00 00 00       	push   $0x96
f010300b:	68 da 53 10 f0       	push   $0xf01053da
f0103010:	e8 8b d0 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103015:	83 ec 0c             	sub    $0xc,%esp
f0103018:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010301e:	e8 fd fb ff ff       	call   f0102c20 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103023:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103028:	83 c4 10             	add    $0x10,%esp
f010302b:	85 c0                	test   %eax,%eax
f010302d:	74 06                	je     f0103035 <trap+0xc8>
f010302f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103033:	74 19                	je     f010304e <trap+0xe1>
f0103035:	68 64 55 10 f0       	push   $0xf0105564
f010303a:	68 66 47 10 f0       	push   $0xf0104766
f010303f:	68 bf 00 00 00       	push   $0xbf
f0103044:	68 da 53 10 f0       	push   $0xf01053da
f0103049:	e8 52 d0 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010304e:	83 ec 0c             	sub    $0xc,%esp
f0103051:	50                   	push   %eax
f0103052:	e8 19 fc ff ff       	call   f0102c70 <env_run>

f0103057 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103057:	55                   	push   %ebp
f0103058:	89 e5                	mov    %esp,%ebp
f010305a:	53                   	push   %ebx
f010305b:	83 ec 04             	sub    $0x4,%esp
f010305e:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103061:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103064:	ff 73 30             	pushl  0x30(%ebx)
f0103067:	50                   	push   %eax
f0103068:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010306d:	ff 70 48             	pushl  0x48(%eax)
f0103070:	68 90 55 10 f0       	push   $0xf0105590
f0103075:	e8 77 fc ff ff       	call   f0102cf1 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010307a:	89 1c 24             	mov    %ebx,(%esp)
f010307d:	e8 78 fd ff ff       	call   f0102dfa <print_trapframe>
	env_destroy(curenv);
f0103082:	83 c4 04             	add    $0x4,%esp
f0103085:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010308b:	e8 90 fb ff ff       	call   f0102c20 <env_destroy>
}
f0103090:	83 c4 10             	add    $0x10,%esp
f0103093:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103096:	c9                   	leave  
f0103097:	c3                   	ret    

f0103098 <syscall>:
f0103098:	55                   	push   %ebp
f0103099:	89 e5                	mov    %esp,%ebp
f010309b:	83 ec 0c             	sub    $0xc,%esp
f010309e:	68 10 56 10 f0       	push   $0xf0105610
f01030a3:	6a 49                	push   $0x49
f01030a5:	68 28 56 10 f0       	push   $0xf0105628
f01030aa:	e8 f1 cf ff ff       	call   f01000a0 <_panic>

f01030af <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01030af:	55                   	push   %ebp
f01030b0:	89 e5                	mov    %esp,%ebp
f01030b2:	57                   	push   %edi
f01030b3:	56                   	push   %esi
f01030b4:	53                   	push   %ebx
f01030b5:	83 ec 14             	sub    $0x14,%esp
f01030b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030bb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01030be:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01030c1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01030c4:	8b 1a                	mov    (%edx),%ebx
f01030c6:	8b 01                	mov    (%ecx),%eax
f01030c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030cb:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01030d2:	eb 7f                	jmp    f0103153 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01030d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030d7:	01 d8                	add    %ebx,%eax
f01030d9:	89 c6                	mov    %eax,%esi
f01030db:	c1 ee 1f             	shr    $0x1f,%esi
f01030de:	01 c6                	add    %eax,%esi
f01030e0:	d1 fe                	sar    %esi
f01030e2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01030e5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030e8:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01030eb:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01030ed:	eb 03                	jmp    f01030f2 <stab_binsearch+0x43>
			m--;
f01030ef:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01030f2:	39 c3                	cmp    %eax,%ebx
f01030f4:	7f 0d                	jg     f0103103 <stab_binsearch+0x54>
f01030f6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01030fa:	83 ea 0c             	sub    $0xc,%edx
f01030fd:	39 f9                	cmp    %edi,%ecx
f01030ff:	75 ee                	jne    f01030ef <stab_binsearch+0x40>
f0103101:	eb 05                	jmp    f0103108 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103103:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103106:	eb 4b                	jmp    f0103153 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103108:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010310b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010310e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103112:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103115:	76 11                	jbe    f0103128 <stab_binsearch+0x79>
			*region_left = m;
f0103117:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010311a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010311c:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010311f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103126:	eb 2b                	jmp    f0103153 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103128:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010312b:	73 14                	jae    f0103141 <stab_binsearch+0x92>
			*region_right = m - 1;
f010312d:	83 e8 01             	sub    $0x1,%eax
f0103130:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103133:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103136:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103138:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010313f:	eb 12                	jmp    f0103153 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103141:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103144:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103146:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010314a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010314c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103153:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103156:	0f 8e 78 ff ff ff    	jle    f01030d4 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010315c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103160:	75 0f                	jne    f0103171 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103162:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103165:	8b 00                	mov    (%eax),%eax
f0103167:	83 e8 01             	sub    $0x1,%eax
f010316a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010316d:	89 06                	mov    %eax,(%esi)
f010316f:	eb 2c                	jmp    f010319d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103171:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103174:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103176:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103179:	8b 0e                	mov    (%esi),%ecx
f010317b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010317e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103181:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103184:	eb 03                	jmp    f0103189 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103186:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103189:	39 c8                	cmp    %ecx,%eax
f010318b:	7e 0b                	jle    f0103198 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010318d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103191:	83 ea 0c             	sub    $0xc,%edx
f0103194:	39 df                	cmp    %ebx,%edi
f0103196:	75 ee                	jne    f0103186 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103198:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010319b:	89 06                	mov    %eax,(%esi)
	}
}
f010319d:	83 c4 14             	add    $0x14,%esp
f01031a0:	5b                   	pop    %ebx
f01031a1:	5e                   	pop    %esi
f01031a2:	5f                   	pop    %edi
f01031a3:	5d                   	pop    %ebp
f01031a4:	c3                   	ret    

f01031a5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01031a5:	55                   	push   %ebp
f01031a6:	89 e5                	mov    %esp,%ebp
f01031a8:	57                   	push   %edi
f01031a9:	56                   	push   %esi
f01031aa:	53                   	push   %ebx
f01031ab:	83 ec 3c             	sub    $0x3c,%esp
f01031ae:	8b 75 08             	mov    0x8(%ebp),%esi
f01031b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01031b4:	c7 03 37 56 10 f0    	movl   $0xf0105637,(%ebx)
	info->eip_line = 0;
f01031ba:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01031c1:	c7 43 08 37 56 10 f0 	movl   $0xf0105637,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01031c8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01031cf:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01031d2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01031d9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01031df:	77 21                	ja     f0103202 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01031e1:	a1 00 00 20 00       	mov    0x200000,%eax
f01031e6:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01031e9:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01031ee:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01031f4:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01031f7:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01031fd:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103200:	eb 1a                	jmp    f010321c <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103202:	c7 45 bc e8 f3 10 f0 	movl   $0xf010f3e8,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103209:	c7 45 b8 1d ca 10 f0 	movl   $0xf010ca1d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103210:	b8 1c ca 10 f0       	mov    $0xf010ca1c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103215:	c7 45 c0 70 58 10 f0 	movl   $0xf0105870,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010321c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010321f:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103222:	0f 83 a5 01 00 00    	jae    f01033cd <debuginfo_eip+0x228>
f0103228:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f010322c:	0f 85 a2 01 00 00    	jne    f01033d4 <debuginfo_eip+0x22f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103232:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103239:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010323c:	29 f8                	sub    %edi,%eax
f010323e:	c1 f8 02             	sar    $0x2,%eax
f0103241:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103247:	83 e8 01             	sub    $0x1,%eax
f010324a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010324d:	56                   	push   %esi
f010324e:	6a 64                	push   $0x64
f0103250:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103253:	89 c1                	mov    %eax,%ecx
f0103255:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103258:	89 f8                	mov    %edi,%eax
f010325a:	e8 50 fe ff ff       	call   f01030af <stab_binsearch>
	if (lfile == 0)
f010325f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103262:	83 c4 08             	add    $0x8,%esp
f0103265:	85 c0                	test   %eax,%eax
f0103267:	0f 84 6e 01 00 00    	je     f01033db <debuginfo_eip+0x236>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010326d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103270:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103273:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103276:	56                   	push   %esi
f0103277:	6a 24                	push   $0x24
f0103279:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010327c:	89 c1                	mov    %eax,%ecx
f010327e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103281:	89 f8                	mov    %edi,%eax
f0103283:	e8 27 fe ff ff       	call   f01030af <stab_binsearch>

	if (lfun <= rfun) {
f0103288:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010328b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010328e:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103291:	83 c4 08             	add    $0x8,%esp
f0103294:	39 d0                	cmp    %edx,%eax
f0103296:	7f 2b                	jg     f01032c3 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103298:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010329b:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f010329e:	8b 11                	mov    (%ecx),%edx
f01032a0:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01032a3:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01032a6:	39 fa                	cmp    %edi,%edx
f01032a8:	73 06                	jae    f01032b0 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01032aa:	03 55 b8             	add    -0x48(%ebp),%edx
f01032ad:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01032b0:	8b 51 08             	mov    0x8(%ecx),%edx
f01032b3:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01032b6:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01032b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01032bb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01032be:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01032c1:	eb 0f                	jmp    f01032d2 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01032c3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01032c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01032cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032cf:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01032d2:	83 ec 08             	sub    $0x8,%esp
f01032d5:	6a 3a                	push   $0x3a
f01032d7:	ff 73 08             	pushl  0x8(%ebx)
f01032da:	e8 2a 09 00 00       	call   f0103c09 <strfind>
f01032df:	2b 43 08             	sub    0x8(%ebx),%eax
f01032e2:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01032e5:	83 c4 08             	add    $0x8,%esp
f01032e8:	56                   	push   %esi
f01032e9:	6a 44                	push   $0x44
f01032eb:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01032ee:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01032f1:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01032f4:	89 f0                	mov    %esi,%eax
f01032f6:	e8 b4 fd ff ff       	call   f01030af <stab_binsearch>
    if(lline <= rline){
f01032fb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01032fe:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103301:	83 c4 10             	add    $0x10,%esp
f0103304:	39 c2                	cmp    %eax,%edx
f0103306:	7f 0d                	jg     f0103315 <debuginfo_eip+0x170>
        info->eip_line = stabs[rline].n_desc;
f0103308:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010330b:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103310:	89 43 04             	mov    %eax,0x4(%ebx)
f0103313:	eb 07                	jmp    f010331c <debuginfo_eip+0x177>
    }
    else
        info->eip_line = -1;
f0103315:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010331c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010331f:	89 d0                	mov    %edx,%eax
f0103321:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103324:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103327:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010332a:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010332e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103331:	eb 0a                	jmp    f010333d <debuginfo_eip+0x198>
f0103333:	83 e8 01             	sub    $0x1,%eax
f0103336:	83 ea 0c             	sub    $0xc,%edx
f0103339:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010333d:	39 c7                	cmp    %eax,%edi
f010333f:	7e 05                	jle    f0103346 <debuginfo_eip+0x1a1>
f0103341:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103344:	eb 47                	jmp    f010338d <debuginfo_eip+0x1e8>
	       && stabs[lline].n_type != N_SOL
f0103346:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010334a:	80 f9 84             	cmp    $0x84,%cl
f010334d:	75 0e                	jne    f010335d <debuginfo_eip+0x1b8>
f010334f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103352:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103356:	74 1c                	je     f0103374 <debuginfo_eip+0x1cf>
f0103358:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010335b:	eb 17                	jmp    f0103374 <debuginfo_eip+0x1cf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010335d:	80 f9 64             	cmp    $0x64,%cl
f0103360:	75 d1                	jne    f0103333 <debuginfo_eip+0x18e>
f0103362:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103366:	74 cb                	je     f0103333 <debuginfo_eip+0x18e>
f0103368:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010336b:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010336f:	74 03                	je     f0103374 <debuginfo_eip+0x1cf>
f0103371:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103374:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103377:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010337a:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010337d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103380:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103383:	29 f8                	sub    %edi,%eax
f0103385:	39 c2                	cmp    %eax,%edx
f0103387:	73 04                	jae    f010338d <debuginfo_eip+0x1e8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103389:	01 fa                	add    %edi,%edx
f010338b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010338d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103390:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103393:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103398:	39 f2                	cmp    %esi,%edx
f010339a:	7d 4b                	jge    f01033e7 <debuginfo_eip+0x242>
		for (lline = lfun + 1;
f010339c:	83 c2 01             	add    $0x1,%edx
f010339f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01033a2:	89 d0                	mov    %edx,%eax
f01033a4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01033a7:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01033aa:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01033ad:	eb 04                	jmp    f01033b3 <debuginfo_eip+0x20e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01033af:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01033b3:	39 c6                	cmp    %eax,%esi
f01033b5:	7e 2b                	jle    f01033e2 <debuginfo_eip+0x23d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01033b7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01033bb:	83 c0 01             	add    $0x1,%eax
f01033be:	83 c2 0c             	add    $0xc,%edx
f01033c1:	80 f9 a0             	cmp    $0xa0,%cl
f01033c4:	74 e9                	je     f01033af <debuginfo_eip+0x20a>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01033cb:	eb 1a                	jmp    f01033e7 <debuginfo_eip+0x242>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01033cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033d2:	eb 13                	jmp    f01033e7 <debuginfo_eip+0x242>
f01033d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033d9:	eb 0c                	jmp    f01033e7 <debuginfo_eip+0x242>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01033db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033e0:	eb 05                	jmp    f01033e7 <debuginfo_eip+0x242>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033ea:	5b                   	pop    %ebx
f01033eb:	5e                   	pop    %esi
f01033ec:	5f                   	pop    %edi
f01033ed:	5d                   	pop    %ebp
f01033ee:	c3                   	ret    

f01033ef <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01033ef:	55                   	push   %ebp
f01033f0:	89 e5                	mov    %esp,%ebp
f01033f2:	57                   	push   %edi
f01033f3:	56                   	push   %esi
f01033f4:	53                   	push   %ebx
f01033f5:	83 ec 1c             	sub    $0x1c,%esp
f01033f8:	89 c7                	mov    %eax,%edi
f01033fa:	89 d6                	mov    %edx,%esi
f01033fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01033ff:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103402:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103405:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103408:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010340b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103410:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103413:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103416:	39 d3                	cmp    %edx,%ebx
f0103418:	72 05                	jb     f010341f <printnum+0x30>
f010341a:	39 45 10             	cmp    %eax,0x10(%ebp)
f010341d:	77 45                	ja     f0103464 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010341f:	83 ec 0c             	sub    $0xc,%esp
f0103422:	ff 75 18             	pushl  0x18(%ebp)
f0103425:	8b 45 14             	mov    0x14(%ebp),%eax
f0103428:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010342b:	53                   	push   %ebx
f010342c:	ff 75 10             	pushl  0x10(%ebp)
f010342f:	83 ec 08             	sub    $0x8,%esp
f0103432:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103435:	ff 75 e0             	pushl  -0x20(%ebp)
f0103438:	ff 75 dc             	pushl  -0x24(%ebp)
f010343b:	ff 75 d8             	pushl  -0x28(%ebp)
f010343e:	e8 ed 09 00 00       	call   f0103e30 <__udivdi3>
f0103443:	83 c4 18             	add    $0x18,%esp
f0103446:	52                   	push   %edx
f0103447:	50                   	push   %eax
f0103448:	89 f2                	mov    %esi,%edx
f010344a:	89 f8                	mov    %edi,%eax
f010344c:	e8 9e ff ff ff       	call   f01033ef <printnum>
f0103451:	83 c4 20             	add    $0x20,%esp
f0103454:	eb 18                	jmp    f010346e <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103456:	83 ec 08             	sub    $0x8,%esp
f0103459:	56                   	push   %esi
f010345a:	ff 75 18             	pushl  0x18(%ebp)
f010345d:	ff d7                	call   *%edi
f010345f:	83 c4 10             	add    $0x10,%esp
f0103462:	eb 03                	jmp    f0103467 <printnum+0x78>
f0103464:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103467:	83 eb 01             	sub    $0x1,%ebx
f010346a:	85 db                	test   %ebx,%ebx
f010346c:	7f e8                	jg     f0103456 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010346e:	83 ec 08             	sub    $0x8,%esp
f0103471:	56                   	push   %esi
f0103472:	83 ec 04             	sub    $0x4,%esp
f0103475:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103478:	ff 75 e0             	pushl  -0x20(%ebp)
f010347b:	ff 75 dc             	pushl  -0x24(%ebp)
f010347e:	ff 75 d8             	pushl  -0x28(%ebp)
f0103481:	e8 da 0a 00 00       	call   f0103f60 <__umoddi3>
f0103486:	83 c4 14             	add    $0x14,%esp
f0103489:	0f be 80 41 56 10 f0 	movsbl -0xfefa9bf(%eax),%eax
f0103490:	50                   	push   %eax
f0103491:	ff d7                	call   *%edi
}
f0103493:	83 c4 10             	add    $0x10,%esp
f0103496:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103499:	5b                   	pop    %ebx
f010349a:	5e                   	pop    %esi
f010349b:	5f                   	pop    %edi
f010349c:	5d                   	pop    %ebp
f010349d:	c3                   	ret    

f010349e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010349e:	55                   	push   %ebp
f010349f:	89 e5                	mov    %esp,%ebp
f01034a1:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01034a4:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01034a8:	8b 10                	mov    (%eax),%edx
f01034aa:	3b 50 04             	cmp    0x4(%eax),%edx
f01034ad:	73 0a                	jae    f01034b9 <sprintputch+0x1b>
		*b->buf++ = ch;
f01034af:	8d 4a 01             	lea    0x1(%edx),%ecx
f01034b2:	89 08                	mov    %ecx,(%eax)
f01034b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01034b7:	88 02                	mov    %al,(%edx)
}
f01034b9:	5d                   	pop    %ebp
f01034ba:	c3                   	ret    

f01034bb <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01034bb:	55                   	push   %ebp
f01034bc:	89 e5                	mov    %esp,%ebp
f01034be:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01034c1:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01034c4:	50                   	push   %eax
f01034c5:	ff 75 10             	pushl  0x10(%ebp)
f01034c8:	ff 75 0c             	pushl  0xc(%ebp)
f01034cb:	ff 75 08             	pushl  0x8(%ebp)
f01034ce:	e8 05 00 00 00       	call   f01034d8 <vprintfmt>
	va_end(ap);
}
f01034d3:	83 c4 10             	add    $0x10,%esp
f01034d6:	c9                   	leave  
f01034d7:	c3                   	ret    

f01034d8 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01034d8:	55                   	push   %ebp
f01034d9:	89 e5                	mov    %esp,%ebp
f01034db:	57                   	push   %edi
f01034dc:	56                   	push   %esi
f01034dd:	53                   	push   %ebx
f01034de:	83 ec 2c             	sub    $0x2c,%esp
f01034e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01034e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034e7:	8b 7d 10             	mov    0x10(%ebp),%edi
f01034ea:	eb 12                	jmp    f01034fe <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f01034ec:	85 c0                	test   %eax,%eax
f01034ee:	0f 84 6a 04 00 00    	je     f010395e <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f01034f4:	83 ec 08             	sub    $0x8,%esp
f01034f7:	53                   	push   %ebx
f01034f8:	50                   	push   %eax
f01034f9:	ff d6                	call   *%esi
f01034fb:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f01034fe:	83 c7 01             	add    $0x1,%edi
f0103501:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103505:	83 f8 25             	cmp    $0x25,%eax
f0103508:	75 e2                	jne    f01034ec <vprintfmt+0x14>
f010350a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010350e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103515:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010351c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103523:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103528:	eb 07                	jmp    f0103531 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010352a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f010352d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103531:	8d 47 01             	lea    0x1(%edi),%eax
f0103534:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103537:	0f b6 07             	movzbl (%edi),%eax
f010353a:	0f b6 d0             	movzbl %al,%edx
f010353d:	83 e8 23             	sub    $0x23,%eax
f0103540:	3c 55                	cmp    $0x55,%al
f0103542:	0f 87 fb 03 00 00    	ja     f0103943 <vprintfmt+0x46b>
f0103548:	0f b6 c0             	movzbl %al,%eax
f010354b:	ff 24 85 e0 56 10 f0 	jmp    *-0xfefa920(,%eax,4)
f0103552:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f0103555:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103559:	eb d6                	jmp    f0103531 <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010355b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010355e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103563:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0103566:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103569:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010356d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103570:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103573:	83 f9 09             	cmp    $0x9,%ecx
f0103576:	77 3f                	ja     f01035b7 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0103578:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010357b:	eb e9                	jmp    f0103566 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f010357d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103580:	8b 00                	mov    (%eax),%eax
f0103582:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103585:	8b 45 14             	mov    0x14(%ebp),%eax
f0103588:	8d 40 04             	lea    0x4(%eax),%eax
f010358b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010358e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0103591:	eb 2a                	jmp    f01035bd <vprintfmt+0xe5>
f0103593:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103596:	85 c0                	test   %eax,%eax
f0103598:	ba 00 00 00 00       	mov    $0x0,%edx
f010359d:	0f 49 d0             	cmovns %eax,%edx
f01035a0:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01035a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035a6:	eb 89                	jmp    f0103531 <vprintfmt+0x59>
f01035a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01035ab:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01035b2:	e9 7a ff ff ff       	jmp    f0103531 <vprintfmt+0x59>
f01035b7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01035ba:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f01035bd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035c1:	0f 89 6a ff ff ff    	jns    f0103531 <vprintfmt+0x59>
				width = precision, precision = -1;
f01035c7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01035ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035cd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01035d4:	e9 58 ff ff ff       	jmp    f0103531 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f01035d9:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01035dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f01035df:	e9 4d ff ff ff       	jmp    f0103531 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f01035e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01035e7:	8d 78 04             	lea    0x4(%eax),%edi
f01035ea:	83 ec 08             	sub    $0x8,%esp
f01035ed:	53                   	push   %ebx
f01035ee:	ff 30                	pushl  (%eax)
f01035f0:	ff d6                	call   *%esi
			break;
f01035f2:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f01035f5:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f01035f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f01035fb:	e9 fe fe ff ff       	jmp    f01034fe <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103600:	8b 45 14             	mov    0x14(%ebp),%eax
f0103603:	8d 78 04             	lea    0x4(%eax),%edi
f0103606:	8b 00                	mov    (%eax),%eax
f0103608:	99                   	cltd   
f0103609:	31 d0                	xor    %edx,%eax
f010360b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010360d:	83 f8 07             	cmp    $0x7,%eax
f0103610:	7f 0b                	jg     f010361d <vprintfmt+0x145>
f0103612:	8b 14 85 40 58 10 f0 	mov    -0xfefa7c0(,%eax,4),%edx
f0103619:	85 d2                	test   %edx,%edx
f010361b:	75 1b                	jne    f0103638 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f010361d:	50                   	push   %eax
f010361e:	68 59 56 10 f0       	push   $0xf0105659
f0103623:	53                   	push   %ebx
f0103624:	56                   	push   %esi
f0103625:	e8 91 fe ff ff       	call   f01034bb <printfmt>
f010362a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010362d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103630:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103633:	e9 c6 fe ff ff       	jmp    f01034fe <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103638:	52                   	push   %edx
f0103639:	68 78 47 10 f0       	push   $0xf0104778
f010363e:	53                   	push   %ebx
f010363f:	56                   	push   %esi
f0103640:	e8 76 fe ff ff       	call   f01034bb <printfmt>
f0103645:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103648:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010364b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010364e:	e9 ab fe ff ff       	jmp    f01034fe <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103653:	8b 45 14             	mov    0x14(%ebp),%eax
f0103656:	83 c0 04             	add    $0x4,%eax
f0103659:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010365c:	8b 45 14             	mov    0x14(%ebp),%eax
f010365f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103661:	85 ff                	test   %edi,%edi
f0103663:	b8 52 56 10 f0       	mov    $0xf0105652,%eax
f0103668:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010366b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010366f:	0f 8e 94 00 00 00    	jle    f0103709 <vprintfmt+0x231>
f0103675:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103679:	0f 84 98 00 00 00    	je     f0103717 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f010367f:	83 ec 08             	sub    $0x8,%esp
f0103682:	ff 75 d0             	pushl  -0x30(%ebp)
f0103685:	57                   	push   %edi
f0103686:	e8 34 04 00 00       	call   f0103abf <strnlen>
f010368b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010368e:	29 c1                	sub    %eax,%ecx
f0103690:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103693:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103696:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010369a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010369d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01036a0:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036a2:	eb 0f                	jmp    f01036b3 <vprintfmt+0x1db>
					putch(padc, putdat);
f01036a4:	83 ec 08             	sub    $0x8,%esp
f01036a7:	53                   	push   %ebx
f01036a8:	ff 75 e0             	pushl  -0x20(%ebp)
f01036ab:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036ad:	83 ef 01             	sub    $0x1,%edi
f01036b0:	83 c4 10             	add    $0x10,%esp
f01036b3:	85 ff                	test   %edi,%edi
f01036b5:	7f ed                	jg     f01036a4 <vprintfmt+0x1cc>
f01036b7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01036ba:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01036bd:	85 c9                	test   %ecx,%ecx
f01036bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01036c4:	0f 49 c1             	cmovns %ecx,%eax
f01036c7:	29 c1                	sub    %eax,%ecx
f01036c9:	89 75 08             	mov    %esi,0x8(%ebp)
f01036cc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01036cf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01036d2:	89 cb                	mov    %ecx,%ebx
f01036d4:	eb 4d                	jmp    f0103723 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01036d6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01036da:	74 1b                	je     f01036f7 <vprintfmt+0x21f>
f01036dc:	0f be c0             	movsbl %al,%eax
f01036df:	83 e8 20             	sub    $0x20,%eax
f01036e2:	83 f8 5e             	cmp    $0x5e,%eax
f01036e5:	76 10                	jbe    f01036f7 <vprintfmt+0x21f>
					putch('?', putdat);
f01036e7:	83 ec 08             	sub    $0x8,%esp
f01036ea:	ff 75 0c             	pushl  0xc(%ebp)
f01036ed:	6a 3f                	push   $0x3f
f01036ef:	ff 55 08             	call   *0x8(%ebp)
f01036f2:	83 c4 10             	add    $0x10,%esp
f01036f5:	eb 0d                	jmp    f0103704 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f01036f7:	83 ec 08             	sub    $0x8,%esp
f01036fa:	ff 75 0c             	pushl  0xc(%ebp)
f01036fd:	52                   	push   %edx
f01036fe:	ff 55 08             	call   *0x8(%ebp)
f0103701:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103704:	83 eb 01             	sub    $0x1,%ebx
f0103707:	eb 1a                	jmp    f0103723 <vprintfmt+0x24b>
f0103709:	89 75 08             	mov    %esi,0x8(%ebp)
f010370c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010370f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103712:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103715:	eb 0c                	jmp    f0103723 <vprintfmt+0x24b>
f0103717:	89 75 08             	mov    %esi,0x8(%ebp)
f010371a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010371d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103720:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103723:	83 c7 01             	add    $0x1,%edi
f0103726:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010372a:	0f be d0             	movsbl %al,%edx
f010372d:	85 d2                	test   %edx,%edx
f010372f:	74 23                	je     f0103754 <vprintfmt+0x27c>
f0103731:	85 f6                	test   %esi,%esi
f0103733:	78 a1                	js     f01036d6 <vprintfmt+0x1fe>
f0103735:	83 ee 01             	sub    $0x1,%esi
f0103738:	79 9c                	jns    f01036d6 <vprintfmt+0x1fe>
f010373a:	89 df                	mov    %ebx,%edi
f010373c:	8b 75 08             	mov    0x8(%ebp),%esi
f010373f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103742:	eb 18                	jmp    f010375c <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103744:	83 ec 08             	sub    $0x8,%esp
f0103747:	53                   	push   %ebx
f0103748:	6a 20                	push   $0x20
f010374a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010374c:	83 ef 01             	sub    $0x1,%edi
f010374f:	83 c4 10             	add    $0x10,%esp
f0103752:	eb 08                	jmp    f010375c <vprintfmt+0x284>
f0103754:	89 df                	mov    %ebx,%edi
f0103756:	8b 75 08             	mov    0x8(%ebp),%esi
f0103759:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010375c:	85 ff                	test   %edi,%edi
f010375e:	7f e4                	jg     f0103744 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103760:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103763:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0103766:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103769:	e9 90 fd ff ff       	jmp    f01034fe <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010376e:	83 f9 01             	cmp    $0x1,%ecx
f0103771:	7e 19                	jle    f010378c <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103773:	8b 45 14             	mov    0x14(%ebp),%eax
f0103776:	8b 50 04             	mov    0x4(%eax),%edx
f0103779:	8b 00                	mov    (%eax),%eax
f010377b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010377e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103781:	8b 45 14             	mov    0x14(%ebp),%eax
f0103784:	8d 40 08             	lea    0x8(%eax),%eax
f0103787:	89 45 14             	mov    %eax,0x14(%ebp)
f010378a:	eb 38                	jmp    f01037c4 <vprintfmt+0x2ec>
	else if (lflag)
f010378c:	85 c9                	test   %ecx,%ecx
f010378e:	74 1b                	je     f01037ab <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103790:	8b 45 14             	mov    0x14(%ebp),%eax
f0103793:	8b 00                	mov    (%eax),%eax
f0103795:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103798:	89 c1                	mov    %eax,%ecx
f010379a:	c1 f9 1f             	sar    $0x1f,%ecx
f010379d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01037a3:	8d 40 04             	lea    0x4(%eax),%eax
f01037a6:	89 45 14             	mov    %eax,0x14(%ebp)
f01037a9:	eb 19                	jmp    f01037c4 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01037ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ae:	8b 00                	mov    (%eax),%eax
f01037b0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037b3:	89 c1                	mov    %eax,%ecx
f01037b5:	c1 f9 1f             	sar    $0x1f,%ecx
f01037b8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01037be:	8d 40 04             	lea    0x4(%eax),%eax
f01037c1:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01037c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01037ca:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01037cf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01037d3:	0f 89 36 01 00 00    	jns    f010390f <vprintfmt+0x437>
				putch('-', putdat);
f01037d9:	83 ec 08             	sub    $0x8,%esp
f01037dc:	53                   	push   %ebx
f01037dd:	6a 2d                	push   $0x2d
f01037df:	ff d6                	call   *%esi
				num = -(long long) num;
f01037e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037e4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01037e7:	f7 da                	neg    %edx
f01037e9:	83 d1 00             	adc    $0x0,%ecx
f01037ec:	f7 d9                	neg    %ecx
f01037ee:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01037f1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037f6:	e9 14 01 00 00       	jmp    f010390f <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01037fb:	83 f9 01             	cmp    $0x1,%ecx
f01037fe:	7e 18                	jle    f0103818 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103800:	8b 45 14             	mov    0x14(%ebp),%eax
f0103803:	8b 10                	mov    (%eax),%edx
f0103805:	8b 48 04             	mov    0x4(%eax),%ecx
f0103808:	8d 40 08             	lea    0x8(%eax),%eax
f010380b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010380e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103813:	e9 f7 00 00 00       	jmp    f010390f <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103818:	85 c9                	test   %ecx,%ecx
f010381a:	74 1a                	je     f0103836 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f010381c:	8b 45 14             	mov    0x14(%ebp),%eax
f010381f:	8b 10                	mov    (%eax),%edx
f0103821:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103826:	8d 40 04             	lea    0x4(%eax),%eax
f0103829:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010382c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103831:	e9 d9 00 00 00       	jmp    f010390f <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103836:	8b 45 14             	mov    0x14(%ebp),%eax
f0103839:	8b 10                	mov    (%eax),%edx
f010383b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103840:	8d 40 04             	lea    0x4(%eax),%eax
f0103843:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103846:	b8 0a 00 00 00       	mov    $0xa,%eax
f010384b:	e9 bf 00 00 00       	jmp    f010390f <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103850:	83 f9 01             	cmp    $0x1,%ecx
f0103853:	7e 13                	jle    f0103868 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f0103855:	8b 45 14             	mov    0x14(%ebp),%eax
f0103858:	8b 50 04             	mov    0x4(%eax),%edx
f010385b:	8b 00                	mov    (%eax),%eax
f010385d:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0103860:	8d 49 08             	lea    0x8(%ecx),%ecx
f0103863:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103866:	eb 28                	jmp    f0103890 <vprintfmt+0x3b8>
	else if (lflag)
f0103868:	85 c9                	test   %ecx,%ecx
f010386a:	74 13                	je     f010387f <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f010386c:	8b 45 14             	mov    0x14(%ebp),%eax
f010386f:	8b 10                	mov    (%eax),%edx
f0103871:	89 d0                	mov    %edx,%eax
f0103873:	99                   	cltd   
f0103874:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0103877:	8d 49 04             	lea    0x4(%ecx),%ecx
f010387a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010387d:	eb 11                	jmp    f0103890 <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f010387f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103882:	8b 10                	mov    (%eax),%edx
f0103884:	89 d0                	mov    %edx,%eax
f0103886:	99                   	cltd   
f0103887:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010388a:	8d 49 04             	lea    0x4(%ecx),%ecx
f010388d:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f0103890:	89 d1                	mov    %edx,%ecx
f0103892:	89 c2                	mov    %eax,%edx
			base = 8;
f0103894:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103899:	eb 74                	jmp    f010390f <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f010389b:	83 ec 08             	sub    $0x8,%esp
f010389e:	53                   	push   %ebx
f010389f:	6a 30                	push   $0x30
f01038a1:	ff d6                	call   *%esi
			putch('x', putdat);
f01038a3:	83 c4 08             	add    $0x8,%esp
f01038a6:	53                   	push   %ebx
f01038a7:	6a 78                	push   $0x78
f01038a9:	ff d6                	call   *%esi
			num = (unsigned long long)
f01038ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ae:	8b 10                	mov    (%eax),%edx
f01038b0:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01038b5:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01038b8:	8d 40 04             	lea    0x4(%eax),%eax
f01038bb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01038be:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01038c3:	eb 4a                	jmp    f010390f <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01038c5:	83 f9 01             	cmp    $0x1,%ecx
f01038c8:	7e 15                	jle    f01038df <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f01038ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01038cd:	8b 10                	mov    (%eax),%edx
f01038cf:	8b 48 04             	mov    0x4(%eax),%ecx
f01038d2:	8d 40 08             	lea    0x8(%eax),%eax
f01038d5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01038d8:	b8 10 00 00 00       	mov    $0x10,%eax
f01038dd:	eb 30                	jmp    f010390f <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01038df:	85 c9                	test   %ecx,%ecx
f01038e1:	74 17                	je     f01038fa <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f01038e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01038e6:	8b 10                	mov    (%eax),%edx
f01038e8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038ed:	8d 40 04             	lea    0x4(%eax),%eax
f01038f0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01038f3:	b8 10 00 00 00       	mov    $0x10,%eax
f01038f8:	eb 15                	jmp    f010390f <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01038fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01038fd:	8b 10                	mov    (%eax),%edx
f01038ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103904:	8d 40 04             	lea    0x4(%eax),%eax
f0103907:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010390a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010390f:	83 ec 0c             	sub    $0xc,%esp
f0103912:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103916:	57                   	push   %edi
f0103917:	ff 75 e0             	pushl  -0x20(%ebp)
f010391a:	50                   	push   %eax
f010391b:	51                   	push   %ecx
f010391c:	52                   	push   %edx
f010391d:	89 da                	mov    %ebx,%edx
f010391f:	89 f0                	mov    %esi,%eax
f0103921:	e8 c9 fa ff ff       	call   f01033ef <printnum>
			break;
f0103926:	83 c4 20             	add    $0x20,%esp
f0103929:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010392c:	e9 cd fb ff ff       	jmp    f01034fe <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103931:	83 ec 08             	sub    $0x8,%esp
f0103934:	53                   	push   %ebx
f0103935:	52                   	push   %edx
f0103936:	ff d6                	call   *%esi
			break;
f0103938:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010393b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010393e:	e9 bb fb ff ff       	jmp    f01034fe <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103943:	83 ec 08             	sub    $0x8,%esp
f0103946:	53                   	push   %ebx
f0103947:	6a 25                	push   $0x25
f0103949:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010394b:	83 c4 10             	add    $0x10,%esp
f010394e:	eb 03                	jmp    f0103953 <vprintfmt+0x47b>
f0103950:	83 ef 01             	sub    $0x1,%edi
f0103953:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103957:	75 f7                	jne    f0103950 <vprintfmt+0x478>
f0103959:	e9 a0 fb ff ff       	jmp    f01034fe <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010395e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103961:	5b                   	pop    %ebx
f0103962:	5e                   	pop    %esi
f0103963:	5f                   	pop    %edi
f0103964:	5d                   	pop    %ebp
f0103965:	c3                   	ret    

f0103966 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103966:	55                   	push   %ebp
f0103967:	89 e5                	mov    %esp,%ebp
f0103969:	83 ec 18             	sub    $0x18,%esp
f010396c:	8b 45 08             	mov    0x8(%ebp),%eax
f010396f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103972:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103975:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103979:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010397c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103983:	85 c0                	test   %eax,%eax
f0103985:	74 26                	je     f01039ad <vsnprintf+0x47>
f0103987:	85 d2                	test   %edx,%edx
f0103989:	7e 22                	jle    f01039ad <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010398b:	ff 75 14             	pushl  0x14(%ebp)
f010398e:	ff 75 10             	pushl  0x10(%ebp)
f0103991:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103994:	50                   	push   %eax
f0103995:	68 9e 34 10 f0       	push   $0xf010349e
f010399a:	e8 39 fb ff ff       	call   f01034d8 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010399f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039a2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01039a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039a8:	83 c4 10             	add    $0x10,%esp
f01039ab:	eb 05                	jmp    f01039b2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01039ad:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01039b2:	c9                   	leave  
f01039b3:	c3                   	ret    

f01039b4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01039b4:	55                   	push   %ebp
f01039b5:	89 e5                	mov    %esp,%ebp
f01039b7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01039ba:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01039bd:	50                   	push   %eax
f01039be:	ff 75 10             	pushl  0x10(%ebp)
f01039c1:	ff 75 0c             	pushl  0xc(%ebp)
f01039c4:	ff 75 08             	pushl  0x8(%ebp)
f01039c7:	e8 9a ff ff ff       	call   f0103966 <vsnprintf>
	va_end(ap);

	return rc;
}
f01039cc:	c9                   	leave  
f01039cd:	c3                   	ret    

f01039ce <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01039ce:	55                   	push   %ebp
f01039cf:	89 e5                	mov    %esp,%ebp
f01039d1:	57                   	push   %edi
f01039d2:	56                   	push   %esi
f01039d3:	53                   	push   %ebx
f01039d4:	83 ec 0c             	sub    $0xc,%esp
f01039d7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01039da:	85 c0                	test   %eax,%eax
f01039dc:	74 11                	je     f01039ef <readline+0x21>
		cprintf("%s", prompt);
f01039de:	83 ec 08             	sub    $0x8,%esp
f01039e1:	50                   	push   %eax
f01039e2:	68 78 47 10 f0       	push   $0xf0104778
f01039e7:	e8 05 f3 ff ff       	call   f0102cf1 <cprintf>
f01039ec:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01039ef:	83 ec 0c             	sub    $0xc,%esp
f01039f2:	6a 00                	push   $0x0
f01039f4:	e8 2f cc ff ff       	call   f0100628 <iscons>
f01039f9:	89 c7                	mov    %eax,%edi
f01039fb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01039fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103a03:	e8 0f cc ff ff       	call   f0100617 <getchar>
f0103a08:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103a0a:	85 c0                	test   %eax,%eax
f0103a0c:	79 18                	jns    f0103a26 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103a0e:	83 ec 08             	sub    $0x8,%esp
f0103a11:	50                   	push   %eax
f0103a12:	68 60 58 10 f0       	push   $0xf0105860
f0103a17:	e8 d5 f2 ff ff       	call   f0102cf1 <cprintf>
			return NULL;
f0103a1c:	83 c4 10             	add    $0x10,%esp
f0103a1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a24:	eb 79                	jmp    f0103a9f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103a26:	83 f8 08             	cmp    $0x8,%eax
f0103a29:	0f 94 c2             	sete   %dl
f0103a2c:	83 f8 7f             	cmp    $0x7f,%eax
f0103a2f:	0f 94 c0             	sete   %al
f0103a32:	08 c2                	or     %al,%dl
f0103a34:	74 1a                	je     f0103a50 <readline+0x82>
f0103a36:	85 f6                	test   %esi,%esi
f0103a38:	7e 16                	jle    f0103a50 <readline+0x82>
			if (echoing)
f0103a3a:	85 ff                	test   %edi,%edi
f0103a3c:	74 0d                	je     f0103a4b <readline+0x7d>
				cputchar('\b');
f0103a3e:	83 ec 0c             	sub    $0xc,%esp
f0103a41:	6a 08                	push   $0x8
f0103a43:	e8 bf cb ff ff       	call   f0100607 <cputchar>
f0103a48:	83 c4 10             	add    $0x10,%esp
			i--;
f0103a4b:	83 ee 01             	sub    $0x1,%esi
f0103a4e:	eb b3                	jmp    f0103a03 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103a50:	83 fb 1f             	cmp    $0x1f,%ebx
f0103a53:	7e 23                	jle    f0103a78 <readline+0xaa>
f0103a55:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103a5b:	7f 1b                	jg     f0103a78 <readline+0xaa>
			if (echoing)
f0103a5d:	85 ff                	test   %edi,%edi
f0103a5f:	74 0c                	je     f0103a6d <readline+0x9f>
				cputchar(c);
f0103a61:	83 ec 0c             	sub    $0xc,%esp
f0103a64:	53                   	push   %ebx
f0103a65:	e8 9d cb ff ff       	call   f0100607 <cputchar>
f0103a6a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103a6d:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0103a73:	8d 76 01             	lea    0x1(%esi),%esi
f0103a76:	eb 8b                	jmp    f0103a03 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103a78:	83 fb 0a             	cmp    $0xa,%ebx
f0103a7b:	74 05                	je     f0103a82 <readline+0xb4>
f0103a7d:	83 fb 0d             	cmp    $0xd,%ebx
f0103a80:	75 81                	jne    f0103a03 <readline+0x35>
			if (echoing)
f0103a82:	85 ff                	test   %edi,%edi
f0103a84:	74 0d                	je     f0103a93 <readline+0xc5>
				cputchar('\n');
f0103a86:	83 ec 0c             	sub    $0xc,%esp
f0103a89:	6a 0a                	push   $0xa
f0103a8b:	e8 77 cb ff ff       	call   f0100607 <cputchar>
f0103a90:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103a93:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0103a9a:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f0103a9f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103aa2:	5b                   	pop    %ebx
f0103aa3:	5e                   	pop    %esi
f0103aa4:	5f                   	pop    %edi
f0103aa5:	5d                   	pop    %ebp
f0103aa6:	c3                   	ret    

f0103aa7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103aa7:	55                   	push   %ebp
f0103aa8:	89 e5                	mov    %esp,%ebp
f0103aaa:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103aad:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ab2:	eb 03                	jmp    f0103ab7 <strlen+0x10>
		n++;
f0103ab4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103ab7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103abb:	75 f7                	jne    f0103ab4 <strlen+0xd>
		n++;
	return n;
}
f0103abd:	5d                   	pop    %ebp
f0103abe:	c3                   	ret    

f0103abf <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103abf:	55                   	push   %ebp
f0103ac0:	89 e5                	mov    %esp,%ebp
f0103ac2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ac5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ac8:	ba 00 00 00 00       	mov    $0x0,%edx
f0103acd:	eb 03                	jmp    f0103ad2 <strnlen+0x13>
		n++;
f0103acf:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ad2:	39 c2                	cmp    %eax,%edx
f0103ad4:	74 08                	je     f0103ade <strnlen+0x1f>
f0103ad6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103ada:	75 f3                	jne    f0103acf <strnlen+0x10>
f0103adc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103ade:	5d                   	pop    %ebp
f0103adf:	c3                   	ret    

f0103ae0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103ae0:	55                   	push   %ebp
f0103ae1:	89 e5                	mov    %esp,%ebp
f0103ae3:	53                   	push   %ebx
f0103ae4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ae7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103aea:	89 c2                	mov    %eax,%edx
f0103aec:	83 c2 01             	add    $0x1,%edx
f0103aef:	83 c1 01             	add    $0x1,%ecx
f0103af2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103af6:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103af9:	84 db                	test   %bl,%bl
f0103afb:	75 ef                	jne    f0103aec <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103afd:	5b                   	pop    %ebx
f0103afe:	5d                   	pop    %ebp
f0103aff:	c3                   	ret    

f0103b00 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103b00:	55                   	push   %ebp
f0103b01:	89 e5                	mov    %esp,%ebp
f0103b03:	53                   	push   %ebx
f0103b04:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103b07:	53                   	push   %ebx
f0103b08:	e8 9a ff ff ff       	call   f0103aa7 <strlen>
f0103b0d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103b10:	ff 75 0c             	pushl  0xc(%ebp)
f0103b13:	01 d8                	add    %ebx,%eax
f0103b15:	50                   	push   %eax
f0103b16:	e8 c5 ff ff ff       	call   f0103ae0 <strcpy>
	return dst;
}
f0103b1b:	89 d8                	mov    %ebx,%eax
f0103b1d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b20:	c9                   	leave  
f0103b21:	c3                   	ret    

f0103b22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b22:	55                   	push   %ebp
f0103b23:	89 e5                	mov    %esp,%ebp
f0103b25:	56                   	push   %esi
f0103b26:	53                   	push   %ebx
f0103b27:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b2d:	89 f3                	mov    %esi,%ebx
f0103b2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b32:	89 f2                	mov    %esi,%edx
f0103b34:	eb 0f                	jmp    f0103b45 <strncpy+0x23>
		*dst++ = *src;
f0103b36:	83 c2 01             	add    $0x1,%edx
f0103b39:	0f b6 01             	movzbl (%ecx),%eax
f0103b3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103b3f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103b42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b45:	39 da                	cmp    %ebx,%edx
f0103b47:	75 ed                	jne    f0103b36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103b49:	89 f0                	mov    %esi,%eax
f0103b4b:	5b                   	pop    %ebx
f0103b4c:	5e                   	pop    %esi
f0103b4d:	5d                   	pop    %ebp
f0103b4e:	c3                   	ret    

f0103b4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	56                   	push   %esi
f0103b53:	53                   	push   %ebx
f0103b54:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b57:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b5a:	8b 55 10             	mov    0x10(%ebp),%edx
f0103b5d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103b5f:	85 d2                	test   %edx,%edx
f0103b61:	74 21                	je     f0103b84 <strlcpy+0x35>
f0103b63:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103b67:	89 f2                	mov    %esi,%edx
f0103b69:	eb 09                	jmp    f0103b74 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103b6b:	83 c2 01             	add    $0x1,%edx
f0103b6e:	83 c1 01             	add    $0x1,%ecx
f0103b71:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103b74:	39 c2                	cmp    %eax,%edx
f0103b76:	74 09                	je     f0103b81 <strlcpy+0x32>
f0103b78:	0f b6 19             	movzbl (%ecx),%ebx
f0103b7b:	84 db                	test   %bl,%bl
f0103b7d:	75 ec                	jne    f0103b6b <strlcpy+0x1c>
f0103b7f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103b81:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b84:	29 f0                	sub    %esi,%eax
}
f0103b86:	5b                   	pop    %ebx
f0103b87:	5e                   	pop    %esi
f0103b88:	5d                   	pop    %ebp
f0103b89:	c3                   	ret    

f0103b8a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b8a:	55                   	push   %ebp
f0103b8b:	89 e5                	mov    %esp,%ebp
f0103b8d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b90:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b93:	eb 06                	jmp    f0103b9b <strcmp+0x11>
		p++, q++;
f0103b95:	83 c1 01             	add    $0x1,%ecx
f0103b98:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b9b:	0f b6 01             	movzbl (%ecx),%eax
f0103b9e:	84 c0                	test   %al,%al
f0103ba0:	74 04                	je     f0103ba6 <strcmp+0x1c>
f0103ba2:	3a 02                	cmp    (%edx),%al
f0103ba4:	74 ef                	je     f0103b95 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ba6:	0f b6 c0             	movzbl %al,%eax
f0103ba9:	0f b6 12             	movzbl (%edx),%edx
f0103bac:	29 d0                	sub    %edx,%eax
}
f0103bae:	5d                   	pop    %ebp
f0103baf:	c3                   	ret    

f0103bb0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103bb0:	55                   	push   %ebp
f0103bb1:	89 e5                	mov    %esp,%ebp
f0103bb3:	53                   	push   %ebx
f0103bb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bb7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bba:	89 c3                	mov    %eax,%ebx
f0103bbc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103bbf:	eb 06                	jmp    f0103bc7 <strncmp+0x17>
		n--, p++, q++;
f0103bc1:	83 c0 01             	add    $0x1,%eax
f0103bc4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103bc7:	39 d8                	cmp    %ebx,%eax
f0103bc9:	74 15                	je     f0103be0 <strncmp+0x30>
f0103bcb:	0f b6 08             	movzbl (%eax),%ecx
f0103bce:	84 c9                	test   %cl,%cl
f0103bd0:	74 04                	je     f0103bd6 <strncmp+0x26>
f0103bd2:	3a 0a                	cmp    (%edx),%cl
f0103bd4:	74 eb                	je     f0103bc1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103bd6:	0f b6 00             	movzbl (%eax),%eax
f0103bd9:	0f b6 12             	movzbl (%edx),%edx
f0103bdc:	29 d0                	sub    %edx,%eax
f0103bde:	eb 05                	jmp    f0103be5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103be0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103be5:	5b                   	pop    %ebx
f0103be6:	5d                   	pop    %ebp
f0103be7:	c3                   	ret    

f0103be8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103be8:	55                   	push   %ebp
f0103be9:	89 e5                	mov    %esp,%ebp
f0103beb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103bf2:	eb 07                	jmp    f0103bfb <strchr+0x13>
		if (*s == c)
f0103bf4:	38 ca                	cmp    %cl,%dl
f0103bf6:	74 0f                	je     f0103c07 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103bf8:	83 c0 01             	add    $0x1,%eax
f0103bfb:	0f b6 10             	movzbl (%eax),%edx
f0103bfe:	84 d2                	test   %dl,%dl
f0103c00:	75 f2                	jne    f0103bf4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103c02:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c07:	5d                   	pop    %ebp
f0103c08:	c3                   	ret    

f0103c09 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103c09:	55                   	push   %ebp
f0103c0a:	89 e5                	mov    %esp,%ebp
f0103c0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c0f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c13:	eb 03                	jmp    f0103c18 <strfind+0xf>
f0103c15:	83 c0 01             	add    $0x1,%eax
f0103c18:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c1b:	38 ca                	cmp    %cl,%dl
f0103c1d:	74 04                	je     f0103c23 <strfind+0x1a>
f0103c1f:	84 d2                	test   %dl,%dl
f0103c21:	75 f2                	jne    f0103c15 <strfind+0xc>
			break;
	return (char *) s;
}
f0103c23:	5d                   	pop    %ebp
f0103c24:	c3                   	ret    

f0103c25 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c25:	55                   	push   %ebp
f0103c26:	89 e5                	mov    %esp,%ebp
f0103c28:	57                   	push   %edi
f0103c29:	56                   	push   %esi
f0103c2a:	53                   	push   %ebx
f0103c2b:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c2e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103c31:	85 c9                	test   %ecx,%ecx
f0103c33:	74 36                	je     f0103c6b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c35:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c3b:	75 28                	jne    f0103c65 <memset+0x40>
f0103c3d:	f6 c1 03             	test   $0x3,%cl
f0103c40:	75 23                	jne    f0103c65 <memset+0x40>
		c &= 0xFF;
f0103c42:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c46:	89 d3                	mov    %edx,%ebx
f0103c48:	c1 e3 08             	shl    $0x8,%ebx
f0103c4b:	89 d6                	mov    %edx,%esi
f0103c4d:	c1 e6 18             	shl    $0x18,%esi
f0103c50:	89 d0                	mov    %edx,%eax
f0103c52:	c1 e0 10             	shl    $0x10,%eax
f0103c55:	09 f0                	or     %esi,%eax
f0103c57:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103c59:	89 d8                	mov    %ebx,%eax
f0103c5b:	09 d0                	or     %edx,%eax
f0103c5d:	c1 e9 02             	shr    $0x2,%ecx
f0103c60:	fc                   	cld    
f0103c61:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c63:	eb 06                	jmp    f0103c6b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103c65:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c68:	fc                   	cld    
f0103c69:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103c6b:	89 f8                	mov    %edi,%eax
f0103c6d:	5b                   	pop    %ebx
f0103c6e:	5e                   	pop    %esi
f0103c6f:	5f                   	pop    %edi
f0103c70:	5d                   	pop    %ebp
f0103c71:	c3                   	ret    

f0103c72 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c72:	55                   	push   %ebp
f0103c73:	89 e5                	mov    %esp,%ebp
f0103c75:	57                   	push   %edi
f0103c76:	56                   	push   %esi
f0103c77:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c7a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c7d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c80:	39 c6                	cmp    %eax,%esi
f0103c82:	73 35                	jae    f0103cb9 <memmove+0x47>
f0103c84:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c87:	39 d0                	cmp    %edx,%eax
f0103c89:	73 2e                	jae    f0103cb9 <memmove+0x47>
		s += n;
		d += n;
f0103c8b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c8e:	89 d6                	mov    %edx,%esi
f0103c90:	09 fe                	or     %edi,%esi
f0103c92:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c98:	75 13                	jne    f0103cad <memmove+0x3b>
f0103c9a:	f6 c1 03             	test   $0x3,%cl
f0103c9d:	75 0e                	jne    f0103cad <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103c9f:	83 ef 04             	sub    $0x4,%edi
f0103ca2:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103ca5:	c1 e9 02             	shr    $0x2,%ecx
f0103ca8:	fd                   	std    
f0103ca9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103cab:	eb 09                	jmp    f0103cb6 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103cad:	83 ef 01             	sub    $0x1,%edi
f0103cb0:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103cb3:	fd                   	std    
f0103cb4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103cb6:	fc                   	cld    
f0103cb7:	eb 1d                	jmp    f0103cd6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103cb9:	89 f2                	mov    %esi,%edx
f0103cbb:	09 c2                	or     %eax,%edx
f0103cbd:	f6 c2 03             	test   $0x3,%dl
f0103cc0:	75 0f                	jne    f0103cd1 <memmove+0x5f>
f0103cc2:	f6 c1 03             	test   $0x3,%cl
f0103cc5:	75 0a                	jne    f0103cd1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103cc7:	c1 e9 02             	shr    $0x2,%ecx
f0103cca:	89 c7                	mov    %eax,%edi
f0103ccc:	fc                   	cld    
f0103ccd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103ccf:	eb 05                	jmp    f0103cd6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103cd1:	89 c7                	mov    %eax,%edi
f0103cd3:	fc                   	cld    
f0103cd4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103cd6:	5e                   	pop    %esi
f0103cd7:	5f                   	pop    %edi
f0103cd8:	5d                   	pop    %ebp
f0103cd9:	c3                   	ret    

f0103cda <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103cda:	55                   	push   %ebp
f0103cdb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103cdd:	ff 75 10             	pushl  0x10(%ebp)
f0103ce0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ce3:	ff 75 08             	pushl  0x8(%ebp)
f0103ce6:	e8 87 ff ff ff       	call   f0103c72 <memmove>
}
f0103ceb:	c9                   	leave  
f0103cec:	c3                   	ret    

f0103ced <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103ced:	55                   	push   %ebp
f0103cee:	89 e5                	mov    %esp,%ebp
f0103cf0:	56                   	push   %esi
f0103cf1:	53                   	push   %ebx
f0103cf2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cf5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cf8:	89 c6                	mov    %eax,%esi
f0103cfa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103cfd:	eb 1a                	jmp    f0103d19 <memcmp+0x2c>
		if (*s1 != *s2)
f0103cff:	0f b6 08             	movzbl (%eax),%ecx
f0103d02:	0f b6 1a             	movzbl (%edx),%ebx
f0103d05:	38 d9                	cmp    %bl,%cl
f0103d07:	74 0a                	je     f0103d13 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103d09:	0f b6 c1             	movzbl %cl,%eax
f0103d0c:	0f b6 db             	movzbl %bl,%ebx
f0103d0f:	29 d8                	sub    %ebx,%eax
f0103d11:	eb 0f                	jmp    f0103d22 <memcmp+0x35>
		s1++, s2++;
f0103d13:	83 c0 01             	add    $0x1,%eax
f0103d16:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d19:	39 f0                	cmp    %esi,%eax
f0103d1b:	75 e2                	jne    f0103cff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d22:	5b                   	pop    %ebx
f0103d23:	5e                   	pop    %esi
f0103d24:	5d                   	pop    %ebp
f0103d25:	c3                   	ret    

f0103d26 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d26:	55                   	push   %ebp
f0103d27:	89 e5                	mov    %esp,%ebp
f0103d29:	53                   	push   %ebx
f0103d2a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d2d:	89 c1                	mov    %eax,%ecx
f0103d2f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d32:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d36:	eb 0a                	jmp    f0103d42 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d38:	0f b6 10             	movzbl (%eax),%edx
f0103d3b:	39 da                	cmp    %ebx,%edx
f0103d3d:	74 07                	je     f0103d46 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d3f:	83 c0 01             	add    $0x1,%eax
f0103d42:	39 c8                	cmp    %ecx,%eax
f0103d44:	72 f2                	jb     f0103d38 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d46:	5b                   	pop    %ebx
f0103d47:	5d                   	pop    %ebp
f0103d48:	c3                   	ret    

f0103d49 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d49:	55                   	push   %ebp
f0103d4a:	89 e5                	mov    %esp,%ebp
f0103d4c:	57                   	push   %edi
f0103d4d:	56                   	push   %esi
f0103d4e:	53                   	push   %ebx
f0103d4f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d52:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d55:	eb 03                	jmp    f0103d5a <strtol+0x11>
		s++;
f0103d57:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d5a:	0f b6 01             	movzbl (%ecx),%eax
f0103d5d:	3c 20                	cmp    $0x20,%al
f0103d5f:	74 f6                	je     f0103d57 <strtol+0xe>
f0103d61:	3c 09                	cmp    $0x9,%al
f0103d63:	74 f2                	je     f0103d57 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d65:	3c 2b                	cmp    $0x2b,%al
f0103d67:	75 0a                	jne    f0103d73 <strtol+0x2a>
		s++;
f0103d69:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103d6c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d71:	eb 11                	jmp    f0103d84 <strtol+0x3b>
f0103d73:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103d78:	3c 2d                	cmp    $0x2d,%al
f0103d7a:	75 08                	jne    f0103d84 <strtol+0x3b>
		s++, neg = 1;
f0103d7c:	83 c1 01             	add    $0x1,%ecx
f0103d7f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d84:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d8a:	75 15                	jne    f0103da1 <strtol+0x58>
f0103d8c:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d8f:	75 10                	jne    f0103da1 <strtol+0x58>
f0103d91:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d95:	75 7c                	jne    f0103e13 <strtol+0xca>
		s += 2, base = 16;
f0103d97:	83 c1 02             	add    $0x2,%ecx
f0103d9a:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d9f:	eb 16                	jmp    f0103db7 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103da1:	85 db                	test   %ebx,%ebx
f0103da3:	75 12                	jne    f0103db7 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103da5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103daa:	80 39 30             	cmpb   $0x30,(%ecx)
f0103dad:	75 08                	jne    f0103db7 <strtol+0x6e>
		s++, base = 8;
f0103daf:	83 c1 01             	add    $0x1,%ecx
f0103db2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103db7:	b8 00 00 00 00       	mov    $0x0,%eax
f0103dbc:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103dbf:	0f b6 11             	movzbl (%ecx),%edx
f0103dc2:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103dc5:	89 f3                	mov    %esi,%ebx
f0103dc7:	80 fb 09             	cmp    $0x9,%bl
f0103dca:	77 08                	ja     f0103dd4 <strtol+0x8b>
			dig = *s - '0';
f0103dcc:	0f be d2             	movsbl %dl,%edx
f0103dcf:	83 ea 30             	sub    $0x30,%edx
f0103dd2:	eb 22                	jmp    f0103df6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103dd4:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103dd7:	89 f3                	mov    %esi,%ebx
f0103dd9:	80 fb 19             	cmp    $0x19,%bl
f0103ddc:	77 08                	ja     f0103de6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103dde:	0f be d2             	movsbl %dl,%edx
f0103de1:	83 ea 57             	sub    $0x57,%edx
f0103de4:	eb 10                	jmp    f0103df6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103de6:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103de9:	89 f3                	mov    %esi,%ebx
f0103deb:	80 fb 19             	cmp    $0x19,%bl
f0103dee:	77 16                	ja     f0103e06 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103df0:	0f be d2             	movsbl %dl,%edx
f0103df3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103df6:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103df9:	7d 0b                	jge    f0103e06 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103dfb:	83 c1 01             	add    $0x1,%ecx
f0103dfe:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103e02:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103e04:	eb b9                	jmp    f0103dbf <strtol+0x76>

	if (endptr)
f0103e06:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e0a:	74 0d                	je     f0103e19 <strtol+0xd0>
		*endptr = (char *) s;
f0103e0c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103e0f:	89 0e                	mov    %ecx,(%esi)
f0103e11:	eb 06                	jmp    f0103e19 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e13:	85 db                	test   %ebx,%ebx
f0103e15:	74 98                	je     f0103daf <strtol+0x66>
f0103e17:	eb 9e                	jmp    f0103db7 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103e19:	89 c2                	mov    %eax,%edx
f0103e1b:	f7 da                	neg    %edx
f0103e1d:	85 ff                	test   %edi,%edi
f0103e1f:	0f 45 c2             	cmovne %edx,%eax
}
f0103e22:	5b                   	pop    %ebx
f0103e23:	5e                   	pop    %esi
f0103e24:	5f                   	pop    %edi
f0103e25:	5d                   	pop    %ebp
f0103e26:	c3                   	ret    
f0103e27:	66 90                	xchg   %ax,%ax
f0103e29:	66 90                	xchg   %ax,%ax
f0103e2b:	66 90                	xchg   %ax,%ax
f0103e2d:	66 90                	xchg   %ax,%ax
f0103e2f:	90                   	nop

f0103e30 <__udivdi3>:
f0103e30:	55                   	push   %ebp
f0103e31:	57                   	push   %edi
f0103e32:	56                   	push   %esi
f0103e33:	53                   	push   %ebx
f0103e34:	83 ec 1c             	sub    $0x1c,%esp
f0103e37:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103e3b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103e3f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103e43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103e47:	85 f6                	test   %esi,%esi
f0103e49:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103e4d:	89 ca                	mov    %ecx,%edx
f0103e4f:	89 f8                	mov    %edi,%eax
f0103e51:	75 3d                	jne    f0103e90 <__udivdi3+0x60>
f0103e53:	39 cf                	cmp    %ecx,%edi
f0103e55:	0f 87 c5 00 00 00    	ja     f0103f20 <__udivdi3+0xf0>
f0103e5b:	85 ff                	test   %edi,%edi
f0103e5d:	89 fd                	mov    %edi,%ebp
f0103e5f:	75 0b                	jne    f0103e6c <__udivdi3+0x3c>
f0103e61:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e66:	31 d2                	xor    %edx,%edx
f0103e68:	f7 f7                	div    %edi
f0103e6a:	89 c5                	mov    %eax,%ebp
f0103e6c:	89 c8                	mov    %ecx,%eax
f0103e6e:	31 d2                	xor    %edx,%edx
f0103e70:	f7 f5                	div    %ebp
f0103e72:	89 c1                	mov    %eax,%ecx
f0103e74:	89 d8                	mov    %ebx,%eax
f0103e76:	89 cf                	mov    %ecx,%edi
f0103e78:	f7 f5                	div    %ebp
f0103e7a:	89 c3                	mov    %eax,%ebx
f0103e7c:	89 d8                	mov    %ebx,%eax
f0103e7e:	89 fa                	mov    %edi,%edx
f0103e80:	83 c4 1c             	add    $0x1c,%esp
f0103e83:	5b                   	pop    %ebx
f0103e84:	5e                   	pop    %esi
f0103e85:	5f                   	pop    %edi
f0103e86:	5d                   	pop    %ebp
f0103e87:	c3                   	ret    
f0103e88:	90                   	nop
f0103e89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e90:	39 ce                	cmp    %ecx,%esi
f0103e92:	77 74                	ja     f0103f08 <__udivdi3+0xd8>
f0103e94:	0f bd fe             	bsr    %esi,%edi
f0103e97:	83 f7 1f             	xor    $0x1f,%edi
f0103e9a:	0f 84 98 00 00 00    	je     f0103f38 <__udivdi3+0x108>
f0103ea0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103ea5:	89 f9                	mov    %edi,%ecx
f0103ea7:	89 c5                	mov    %eax,%ebp
f0103ea9:	29 fb                	sub    %edi,%ebx
f0103eab:	d3 e6                	shl    %cl,%esi
f0103ead:	89 d9                	mov    %ebx,%ecx
f0103eaf:	d3 ed                	shr    %cl,%ebp
f0103eb1:	89 f9                	mov    %edi,%ecx
f0103eb3:	d3 e0                	shl    %cl,%eax
f0103eb5:	09 ee                	or     %ebp,%esi
f0103eb7:	89 d9                	mov    %ebx,%ecx
f0103eb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ebd:	89 d5                	mov    %edx,%ebp
f0103ebf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103ec3:	d3 ed                	shr    %cl,%ebp
f0103ec5:	89 f9                	mov    %edi,%ecx
f0103ec7:	d3 e2                	shl    %cl,%edx
f0103ec9:	89 d9                	mov    %ebx,%ecx
f0103ecb:	d3 e8                	shr    %cl,%eax
f0103ecd:	09 c2                	or     %eax,%edx
f0103ecf:	89 d0                	mov    %edx,%eax
f0103ed1:	89 ea                	mov    %ebp,%edx
f0103ed3:	f7 f6                	div    %esi
f0103ed5:	89 d5                	mov    %edx,%ebp
f0103ed7:	89 c3                	mov    %eax,%ebx
f0103ed9:	f7 64 24 0c          	mull   0xc(%esp)
f0103edd:	39 d5                	cmp    %edx,%ebp
f0103edf:	72 10                	jb     f0103ef1 <__udivdi3+0xc1>
f0103ee1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ee5:	89 f9                	mov    %edi,%ecx
f0103ee7:	d3 e6                	shl    %cl,%esi
f0103ee9:	39 c6                	cmp    %eax,%esi
f0103eeb:	73 07                	jae    f0103ef4 <__udivdi3+0xc4>
f0103eed:	39 d5                	cmp    %edx,%ebp
f0103eef:	75 03                	jne    f0103ef4 <__udivdi3+0xc4>
f0103ef1:	83 eb 01             	sub    $0x1,%ebx
f0103ef4:	31 ff                	xor    %edi,%edi
f0103ef6:	89 d8                	mov    %ebx,%eax
f0103ef8:	89 fa                	mov    %edi,%edx
f0103efa:	83 c4 1c             	add    $0x1c,%esp
f0103efd:	5b                   	pop    %ebx
f0103efe:	5e                   	pop    %esi
f0103eff:	5f                   	pop    %edi
f0103f00:	5d                   	pop    %ebp
f0103f01:	c3                   	ret    
f0103f02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f08:	31 ff                	xor    %edi,%edi
f0103f0a:	31 db                	xor    %ebx,%ebx
f0103f0c:	89 d8                	mov    %ebx,%eax
f0103f0e:	89 fa                	mov    %edi,%edx
f0103f10:	83 c4 1c             	add    $0x1c,%esp
f0103f13:	5b                   	pop    %ebx
f0103f14:	5e                   	pop    %esi
f0103f15:	5f                   	pop    %edi
f0103f16:	5d                   	pop    %ebp
f0103f17:	c3                   	ret    
f0103f18:	90                   	nop
f0103f19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f20:	89 d8                	mov    %ebx,%eax
f0103f22:	f7 f7                	div    %edi
f0103f24:	31 ff                	xor    %edi,%edi
f0103f26:	89 c3                	mov    %eax,%ebx
f0103f28:	89 d8                	mov    %ebx,%eax
f0103f2a:	89 fa                	mov    %edi,%edx
f0103f2c:	83 c4 1c             	add    $0x1c,%esp
f0103f2f:	5b                   	pop    %ebx
f0103f30:	5e                   	pop    %esi
f0103f31:	5f                   	pop    %edi
f0103f32:	5d                   	pop    %ebp
f0103f33:	c3                   	ret    
f0103f34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f38:	39 ce                	cmp    %ecx,%esi
f0103f3a:	72 0c                	jb     f0103f48 <__udivdi3+0x118>
f0103f3c:	31 db                	xor    %ebx,%ebx
f0103f3e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103f42:	0f 87 34 ff ff ff    	ja     f0103e7c <__udivdi3+0x4c>
f0103f48:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103f4d:	e9 2a ff ff ff       	jmp    f0103e7c <__udivdi3+0x4c>
f0103f52:	66 90                	xchg   %ax,%ax
f0103f54:	66 90                	xchg   %ax,%ax
f0103f56:	66 90                	xchg   %ax,%ax
f0103f58:	66 90                	xchg   %ax,%ax
f0103f5a:	66 90                	xchg   %ax,%ax
f0103f5c:	66 90                	xchg   %ax,%ax
f0103f5e:	66 90                	xchg   %ax,%ax

f0103f60 <__umoddi3>:
f0103f60:	55                   	push   %ebp
f0103f61:	57                   	push   %edi
f0103f62:	56                   	push   %esi
f0103f63:	53                   	push   %ebx
f0103f64:	83 ec 1c             	sub    $0x1c,%esp
f0103f67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f6b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103f6f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103f77:	85 d2                	test   %edx,%edx
f0103f79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103f7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f81:	89 f3                	mov    %esi,%ebx
f0103f83:	89 3c 24             	mov    %edi,(%esp)
f0103f86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f8a:	75 1c                	jne    f0103fa8 <__umoddi3+0x48>
f0103f8c:	39 f7                	cmp    %esi,%edi
f0103f8e:	76 50                	jbe    f0103fe0 <__umoddi3+0x80>
f0103f90:	89 c8                	mov    %ecx,%eax
f0103f92:	89 f2                	mov    %esi,%edx
f0103f94:	f7 f7                	div    %edi
f0103f96:	89 d0                	mov    %edx,%eax
f0103f98:	31 d2                	xor    %edx,%edx
f0103f9a:	83 c4 1c             	add    $0x1c,%esp
f0103f9d:	5b                   	pop    %ebx
f0103f9e:	5e                   	pop    %esi
f0103f9f:	5f                   	pop    %edi
f0103fa0:	5d                   	pop    %ebp
f0103fa1:	c3                   	ret    
f0103fa2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103fa8:	39 f2                	cmp    %esi,%edx
f0103faa:	89 d0                	mov    %edx,%eax
f0103fac:	77 52                	ja     f0104000 <__umoddi3+0xa0>
f0103fae:	0f bd ea             	bsr    %edx,%ebp
f0103fb1:	83 f5 1f             	xor    $0x1f,%ebp
f0103fb4:	75 5a                	jne    f0104010 <__umoddi3+0xb0>
f0103fb6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103fba:	0f 82 e0 00 00 00    	jb     f01040a0 <__umoddi3+0x140>
f0103fc0:	39 0c 24             	cmp    %ecx,(%esp)
f0103fc3:	0f 86 d7 00 00 00    	jbe    f01040a0 <__umoddi3+0x140>
f0103fc9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103fcd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103fd1:	83 c4 1c             	add    $0x1c,%esp
f0103fd4:	5b                   	pop    %ebx
f0103fd5:	5e                   	pop    %esi
f0103fd6:	5f                   	pop    %edi
f0103fd7:	5d                   	pop    %ebp
f0103fd8:	c3                   	ret    
f0103fd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fe0:	85 ff                	test   %edi,%edi
f0103fe2:	89 fd                	mov    %edi,%ebp
f0103fe4:	75 0b                	jne    f0103ff1 <__umoddi3+0x91>
f0103fe6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103feb:	31 d2                	xor    %edx,%edx
f0103fed:	f7 f7                	div    %edi
f0103fef:	89 c5                	mov    %eax,%ebp
f0103ff1:	89 f0                	mov    %esi,%eax
f0103ff3:	31 d2                	xor    %edx,%edx
f0103ff5:	f7 f5                	div    %ebp
f0103ff7:	89 c8                	mov    %ecx,%eax
f0103ff9:	f7 f5                	div    %ebp
f0103ffb:	89 d0                	mov    %edx,%eax
f0103ffd:	eb 99                	jmp    f0103f98 <__umoddi3+0x38>
f0103fff:	90                   	nop
f0104000:	89 c8                	mov    %ecx,%eax
f0104002:	89 f2                	mov    %esi,%edx
f0104004:	83 c4 1c             	add    $0x1c,%esp
f0104007:	5b                   	pop    %ebx
f0104008:	5e                   	pop    %esi
f0104009:	5f                   	pop    %edi
f010400a:	5d                   	pop    %ebp
f010400b:	c3                   	ret    
f010400c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104010:	8b 34 24             	mov    (%esp),%esi
f0104013:	bf 20 00 00 00       	mov    $0x20,%edi
f0104018:	89 e9                	mov    %ebp,%ecx
f010401a:	29 ef                	sub    %ebp,%edi
f010401c:	d3 e0                	shl    %cl,%eax
f010401e:	89 f9                	mov    %edi,%ecx
f0104020:	89 f2                	mov    %esi,%edx
f0104022:	d3 ea                	shr    %cl,%edx
f0104024:	89 e9                	mov    %ebp,%ecx
f0104026:	09 c2                	or     %eax,%edx
f0104028:	89 d8                	mov    %ebx,%eax
f010402a:	89 14 24             	mov    %edx,(%esp)
f010402d:	89 f2                	mov    %esi,%edx
f010402f:	d3 e2                	shl    %cl,%edx
f0104031:	89 f9                	mov    %edi,%ecx
f0104033:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104037:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010403b:	d3 e8                	shr    %cl,%eax
f010403d:	89 e9                	mov    %ebp,%ecx
f010403f:	89 c6                	mov    %eax,%esi
f0104041:	d3 e3                	shl    %cl,%ebx
f0104043:	89 f9                	mov    %edi,%ecx
f0104045:	89 d0                	mov    %edx,%eax
f0104047:	d3 e8                	shr    %cl,%eax
f0104049:	89 e9                	mov    %ebp,%ecx
f010404b:	09 d8                	or     %ebx,%eax
f010404d:	89 d3                	mov    %edx,%ebx
f010404f:	89 f2                	mov    %esi,%edx
f0104051:	f7 34 24             	divl   (%esp)
f0104054:	89 d6                	mov    %edx,%esi
f0104056:	d3 e3                	shl    %cl,%ebx
f0104058:	f7 64 24 04          	mull   0x4(%esp)
f010405c:	39 d6                	cmp    %edx,%esi
f010405e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104062:	89 d1                	mov    %edx,%ecx
f0104064:	89 c3                	mov    %eax,%ebx
f0104066:	72 08                	jb     f0104070 <__umoddi3+0x110>
f0104068:	75 11                	jne    f010407b <__umoddi3+0x11b>
f010406a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010406e:	73 0b                	jae    f010407b <__umoddi3+0x11b>
f0104070:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104074:	1b 14 24             	sbb    (%esp),%edx
f0104077:	89 d1                	mov    %edx,%ecx
f0104079:	89 c3                	mov    %eax,%ebx
f010407b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010407f:	29 da                	sub    %ebx,%edx
f0104081:	19 ce                	sbb    %ecx,%esi
f0104083:	89 f9                	mov    %edi,%ecx
f0104085:	89 f0                	mov    %esi,%eax
f0104087:	d3 e0                	shl    %cl,%eax
f0104089:	89 e9                	mov    %ebp,%ecx
f010408b:	d3 ea                	shr    %cl,%edx
f010408d:	89 e9                	mov    %ebp,%ecx
f010408f:	d3 ee                	shr    %cl,%esi
f0104091:	09 d0                	or     %edx,%eax
f0104093:	89 f2                	mov    %esi,%edx
f0104095:	83 c4 1c             	add    $0x1c,%esp
f0104098:	5b                   	pop    %ebx
f0104099:	5e                   	pop    %esi
f010409a:	5f                   	pop    %edi
f010409b:	5d                   	pop    %ebp
f010409c:	c3                   	ret    
f010409d:	8d 76 00             	lea    0x0(%esi),%esi
f01040a0:	29 f9                	sub    %edi,%ecx
f01040a2:	19 d6                	sbb    %edx,%esi
f01040a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01040a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01040ac:	e9 18 ff ff ff       	jmp    f0103fc9 <__umoddi3+0x69>
