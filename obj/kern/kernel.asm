
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 39 11 f0       	mov    $0xf0113950,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 33 11 f0       	push   $0xf0113300
f0100058:	e8 c2 15 00 00       	call   f010161f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 1a 10 f0       	push   $0xf0101ac0
f010006f:	e8 42 0a 00 00       	call   f0100ab6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 75 08 00 00       	call   f01008ee <mem_init>
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
f0100093:	83 3d 40 39 11 f0 00 	cmpl   $0x0,0xf0113940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 39 11 f0    	mov    %esi,0xf0113940

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
f01000b0:	68 db 1a 10 f0       	push   $0xf0101adb
f01000b5:	e8 fc 09 00 00       	call   f0100ab6 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 cc 09 00 00       	call   f0100a90 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 17 1b 10 f0 	movl   $0xf0101b17,(%esp)
f01000cb:	e8 e6 09 00 00       	call   f0100ab6 <cprintf>
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
f01000f2:	68 f3 1a 10 f0       	push   $0xf0101af3
f01000f7:	e8 ba 09 00 00       	call   f0100ab6 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 88 09 00 00       	call   f0100a90 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 17 1b 10 f0 	movl   $0xf0101b17,(%esp)
f010010f:	e8 a2 09 00 00       	call   f0100ab6 <cprintf>
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
f010014a:	8b 0d 24 35 11 f0    	mov    0xf0113524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
f0100159:	88 81 20 33 11 f0    	mov    %al,-0xfeecce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
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
f0100198:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
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
f01001b0:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 33 11 f0       	mov    %eax,0xf0113300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f0100209:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
f010020f:	0f b6 8a 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 33 11 f0       	mov    %eax,0xf0113300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 40 1b 10 f0 	mov    -0xfefe4c0(,%ecx,4),%ecx
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
f0100260:	68 0d 1b 10 f0       	push   $0xf0101b0d
f0100265:	e8 4c 08 00 00       	call   f0100ab6 <cprintf>
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
f0100346:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
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
f01003d0:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 59 12 00 00       	call   f010166c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
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
f0100434:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
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
f0100472:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
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
f01004b0:	a1 20 35 11 f0       	mov    0xf0113520,%eax
f01004b5:	3b 05 24 35 11 f0    	cmp    0xf0113524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 35 11 f0    	mov    %edx,0xf0113520
f01004c6:	0f b6 88 20 33 11 f0 	movzbl -0xfeecce0(%eax),%ecx
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
f01004d7:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
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
f0100510:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
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
f0100528:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
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
f0100537:	8b 3d 30 35 11 f0    	mov    0xf0113530,%edi
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
f010055c:	89 35 2c 35 11 f0    	mov    %esi,0xf011352c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
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
f01005c8:	0f 95 05 34 35 11 f0 	setne  0xf0113534
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
f01005dd:	68 19 1b 10 f0       	push   $0xf0101b19
f01005e2:	e8 cf 04 00 00       	call   f0100ab6 <cprintf>
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
f0100623:	68 60 1d 10 f0       	push   $0xf0101d60
f0100628:	68 7e 1d 10 f0       	push   $0xf0101d7e
f010062d:	68 83 1d 10 f0       	push   $0xf0101d83
f0100632:	e8 7f 04 00 00       	call   f0100ab6 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 18 1e 10 f0       	push   $0xf0101e18
f010063f:	68 8c 1d 10 f0       	push   $0xf0101d8c
f0100644:	68 83 1d 10 f0       	push   $0xf0101d83
f0100649:	e8 68 04 00 00       	call   f0100ab6 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 40 1e 10 f0       	push   $0xf0101e40
f0100656:	68 95 1d 10 f0       	push   $0xf0101d95
f010065b:	68 83 1d 10 f0       	push   $0xf0101d83
f0100660:	e8 51 04 00 00       	call   f0100ab6 <cprintf>
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
f0100672:	68 9f 1d 10 f0       	push   $0xf0101d9f
f0100677:	e8 3a 04 00 00       	call   f0100ab6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 70 1e 10 f0       	push   $0xf0101e70
f0100689:	e8 28 04 00 00       	call   f0100ab6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 98 1e 10 f0       	push   $0xf0101e98
f01006a0:	e8 11 04 00 00       	call   f0100ab6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 b1 1a 10 00       	push   $0x101ab1
f01006ad:	68 b1 1a 10 f0       	push   $0xf0101ab1
f01006b2:	68 bc 1e 10 f0       	push   $0xf0101ebc
f01006b7:	e8 fa 03 00 00       	call   f0100ab6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 33 11 00       	push   $0x113300
f01006c4:	68 00 33 11 f0       	push   $0xf0113300
f01006c9:	68 e0 1e 10 f0       	push   $0xf0101ee0
f01006ce:	e8 e3 03 00 00       	call   f0100ab6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 50 39 11 00       	push   $0x113950
f01006db:	68 50 39 11 f0       	push   $0xf0113950
f01006e0:	68 04 1f 10 f0       	push   $0xf0101f04
f01006e5:	e8 cc 03 00 00       	call   f0100ab6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
			ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 4f 3d 11 f0       	mov    $0xf0113d4f,%eax
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
f010070b:	68 28 1f 10 f0       	push   $0xf0101f28
f0100710:	e8 a1 03 00 00       	call   f0100ab6 <cprintf>
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
f0100727:	68 b8 1d 10 f0       	push   $0xf0101db8
f010072c:	e8 85 03 00 00       	call   f0100ab6 <cprintf>
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
f010074c:	68 54 1f 10 f0       	push   $0xf0101f54
f0100751:	e8 60 03 00 00       	call   f0100ab6 <cprintf>
		
		debuginfo_eip(ebp[1],&info);
f0100756:	83 c4 18             	add    $0x18,%esp
f0100759:	56                   	push   %esi
f010075a:	ff 73 04             	pushl  0x4(%ebx)
f010075d:	e8 5e 04 00 00       	call   f0100bc0 <debuginfo_eip>

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
f010079a:	68 ca 1d 10 f0       	push   $0xf0101dca
f010079f:	e8 12 03 00 00       	call   f0100ab6 <cprintf>
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
f01007c3:	68 88 1f 10 f0       	push   $0xf0101f88
f01007c8:	e8 e9 02 00 00       	call   f0100ab6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cd:	c7 04 24 ac 1f 10 f0 	movl   $0xf0101fac,(%esp)
f01007d4:	e8 dd 02 00 00       	call   f0100ab6 <cprintf>
f01007d9:	83 c4 10             	add    $0x10,%esp

	while (1)
	{
		buf = readline("K> ");
f01007dc:	83 ec 0c             	sub    $0xc,%esp
f01007df:	68 d9 1d 10 f0       	push   $0xf0101dd9
f01007e4:	e8 df 0b 00 00       	call   f01013c8 <readline>
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
f0100818:	68 dd 1d 10 f0       	push   $0xf0101ddd
f010081d:	e8 c0 0d 00 00       	call   f01015e2 <strchr>
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
f0100838:	68 e2 1d 10 f0       	push   $0xf0101de2
f010083d:	e8 74 02 00 00       	call   f0100ab6 <cprintf>
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
f0100861:	68 dd 1d 10 f0       	push   $0xf0101ddd
f0100866:	e8 77 0d 00 00       	call   f01015e2 <strchr>
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
f010088f:	ff 34 85 e0 1f 10 f0 	pushl  -0xfefe020(,%eax,4)
f0100896:	ff 75 a8             	pushl  -0x58(%ebp)
f0100899:	e8 e6 0c 00 00       	call   f0101584 <strcmp>
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
f01008b3:	ff 14 85 e8 1f 10 f0 	call   *-0xfefe018(,%eax,4)

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
f01008d4:	68 ff 1d 10 f0       	push   $0xf0101dff
f01008d9:	e8 d8 01 00 00       	call   f0100ab6 <cprintf>
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

f01008ee <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01008ee:	55                   	push   %ebp
f01008ef:	89 e5                	mov    %esp,%ebp
f01008f1:	53                   	push   %ebx
f01008f2:	83 ec 10             	sub    $0x10,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008f5:	6a 15                	push   $0x15
f01008f7:	e8 53 01 00 00       	call   f0100a4f <mc146818_read>
f01008fc:	89 c3                	mov    %eax,%ebx
f01008fe:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100905:	e8 45 01 00 00       	call   f0100a4f <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010090a:	c1 e0 08             	shl    $0x8,%eax
f010090d:	09 d8                	or     %ebx,%eax
f010090f:	c1 e0 0a             	shl    $0xa,%eax
f0100912:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100918:	85 c0                	test   %eax,%eax
f010091a:	0f 48 c2             	cmovs  %edx,%eax
f010091d:	c1 f8 0c             	sar    $0xc,%eax
f0100920:	a3 3c 35 11 f0       	mov    %eax,0xf011353c
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100925:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010092c:	e8 1e 01 00 00       	call   f0100a4f <mc146818_read>
f0100931:	89 c3                	mov    %eax,%ebx
f0100933:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010093a:	e8 10 01 00 00       	call   f0100a4f <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010093f:	c1 e0 08             	shl    $0x8,%eax
f0100942:	09 d8                	or     %ebx,%eax
f0100944:	c1 e0 0a             	shl    $0xa,%eax
f0100947:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010094d:	83 c4 10             	add    $0x10,%esp
f0100950:	85 c0                	test   %eax,%eax
f0100952:	0f 48 c2             	cmovs  %edx,%eax
f0100955:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100958:	85 c0                	test   %eax,%eax
f010095a:	74 0e                	je     f010096a <mem_init+0x7c>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010095c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100962:	89 15 44 39 11 f0    	mov    %edx,0xf0113944
f0100968:	eb 0c                	jmp    f0100976 <mem_init+0x88>
	else
		npages = npages_basemem;
f010096a:	8b 15 3c 35 11 f0    	mov    0xf011353c,%edx
f0100970:	89 15 44 39 11 f0    	mov    %edx,0xf0113944

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100976:	c1 e0 0c             	shl    $0xc,%eax
f0100979:	c1 e8 0a             	shr    $0xa,%eax
f010097c:	50                   	push   %eax
f010097d:	a1 3c 35 11 f0       	mov    0xf011353c,%eax
f0100982:	c1 e0 0c             	shl    $0xc,%eax
f0100985:	c1 e8 0a             	shr    $0xa,%eax
f0100988:	50                   	push   %eax
f0100989:	a1 44 39 11 f0       	mov    0xf0113944,%eax
f010098e:	c1 e0 0c             	shl    $0xc,%eax
f0100991:	c1 e8 0a             	shr    $0xa,%eax
f0100994:	50                   	push   %eax
f0100995:	68 04 20 10 f0       	push   $0xf0102004
f010099a:	e8 17 01 00 00       	call   f0100ab6 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f010099f:	83 c4 0c             	add    $0xc,%esp
f01009a2:	68 40 20 10 f0       	push   $0xf0102040
f01009a7:	6a 7c                	push   $0x7c
f01009a9:	68 6c 20 10 f0       	push   $0xf010206c
f01009ae:	e8 d8 f6 ff ff       	call   f010008b <_panic>

f01009b3 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01009b3:	55                   	push   %ebp
f01009b4:	89 e5                	mov    %esp,%ebp
f01009b6:	53                   	push   %ebx
f01009b7:	8b 1d 38 35 11 f0    	mov    0xf0113538,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009bd:	ba 00 00 00 00       	mov    $0x0,%edx
f01009c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01009c7:	eb 27                	jmp    f01009f0 <page_init+0x3d>
f01009c9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f01009d0:	89 d1                	mov    %edx,%ecx
f01009d2:	03 0d 4c 39 11 f0    	add    0xf011394c,%ecx
f01009d8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f01009de:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009e0:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f01009e3:	89 d3                	mov    %edx,%ebx
f01009e5:	03 1d 4c 39 11 f0    	add    0xf011394c,%ebx
f01009eb:	ba 01 00 00 00       	mov    $0x1,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01009f0:	3b 05 44 39 11 f0    	cmp    0xf0113944,%eax
f01009f6:	72 d1                	jb     f01009c9 <page_init+0x16>
f01009f8:	84 d2                	test   %dl,%dl
f01009fa:	74 06                	je     f0100a02 <page_init+0x4f>
f01009fc:	89 1d 38 35 11 f0    	mov    %ebx,0xf0113538
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100a02:	5b                   	pop    %ebx
f0100a03:	5d                   	pop    %ebp
f0100a04:	c3                   	ret    

f0100a05 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100a05:	55                   	push   %ebp
f0100a06:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100a08:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a0d:	5d                   	pop    %ebp
f0100a0e:	c3                   	ret    

f0100a0f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100a0f:	55                   	push   %ebp
f0100a10:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100a12:	5d                   	pop    %ebp
f0100a13:	c3                   	ret    

f0100a14 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100a14:	55                   	push   %ebp
f0100a15:	89 e5                	mov    %esp,%ebp
f0100a17:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100a1a:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100a1f:	5d                   	pop    %ebp
f0100a20:	c3                   	ret    

f0100a21 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100a21:	55                   	push   %ebp
f0100a22:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a29:	5d                   	pop    %ebp
f0100a2a:	c3                   	ret    

f0100a2b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100a2b:	55                   	push   %ebp
f0100a2c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100a2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a33:	5d                   	pop    %ebp
f0100a34:	c3                   	ret    

f0100a35 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100a35:	55                   	push   %ebp
f0100a36:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100a38:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    

f0100a3f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100a3f:	55                   	push   %ebp
f0100a40:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100a42:	5d                   	pop    %ebp
f0100a43:	c3                   	ret    

f0100a44 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100a44:	55                   	push   %ebp
f0100a45:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a4a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100a4d:	5d                   	pop    %ebp
f0100a4e:	c3                   	ret    

f0100a4f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100a4f:	55                   	push   %ebp
f0100a50:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a52:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a57:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a5a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100a5b:	ba 71 00 00 00       	mov    $0x71,%edx
f0100a60:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100a61:	0f b6 c0             	movzbl %al,%eax
}
f0100a64:	5d                   	pop    %ebp
f0100a65:	c3                   	ret    

f0100a66 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100a66:	55                   	push   %ebp
f0100a67:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100a69:	ba 70 00 00 00       	mov    $0x70,%edx
f0100a6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a71:	ee                   	out    %al,(%dx)
f0100a72:	ba 71 00 00 00       	mov    $0x71,%edx
f0100a77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a7a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100a7b:	5d                   	pop    %ebp
f0100a7c:	c3                   	ret    

f0100a7d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a7d:	55                   	push   %ebp
f0100a7e:	89 e5                	mov    %esp,%ebp
f0100a80:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100a83:	ff 75 08             	pushl  0x8(%ebp)
f0100a86:	e8 67 fb ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0100a8b:	83 c4 10             	add    $0x10,%esp
f0100a8e:	c9                   	leave  
f0100a8f:	c3                   	ret    

f0100a90 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a90:	55                   	push   %ebp
f0100a91:	89 e5                	mov    %esp,%ebp
f0100a93:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a9d:	ff 75 0c             	pushl  0xc(%ebp)
f0100aa0:	ff 75 08             	pushl  0x8(%ebp)
f0100aa3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100aa6:	50                   	push   %eax
f0100aa7:	68 7d 0a 10 f0       	push   $0xf0100a7d
f0100aac:	e8 21 04 00 00       	call   f0100ed2 <vprintfmt>
	return cnt;
}
f0100ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ab4:	c9                   	leave  
f0100ab5:	c3                   	ret    

f0100ab6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100ab6:	55                   	push   %ebp
f0100ab7:	89 e5                	mov    %esp,%ebp
f0100ab9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100abc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100abf:	50                   	push   %eax
f0100ac0:	ff 75 08             	pushl  0x8(%ebp)
f0100ac3:	e8 c8 ff ff ff       	call   f0100a90 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100ac8:	c9                   	leave  
f0100ac9:	c3                   	ret    

f0100aca <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100aca:	55                   	push   %ebp
f0100acb:	89 e5                	mov    %esp,%ebp
f0100acd:	57                   	push   %edi
f0100ace:	56                   	push   %esi
f0100acf:	53                   	push   %ebx
f0100ad0:	83 ec 14             	sub    $0x14,%esp
f0100ad3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ad6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ad9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100adc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100adf:	8b 1a                	mov    (%edx),%ebx
f0100ae1:	8b 01                	mov    (%ecx),%eax
f0100ae3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ae6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100aed:	eb 7f                	jmp    f0100b6e <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100aef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100af2:	01 d8                	add    %ebx,%eax
f0100af4:	89 c6                	mov    %eax,%esi
f0100af6:	c1 ee 1f             	shr    $0x1f,%esi
f0100af9:	01 c6                	add    %eax,%esi
f0100afb:	d1 fe                	sar    %esi
f0100afd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100b00:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b03:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100b06:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b08:	eb 03                	jmp    f0100b0d <stab_binsearch+0x43>
			m--;
f0100b0a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b0d:	39 c3                	cmp    %eax,%ebx
f0100b0f:	7f 0d                	jg     f0100b1e <stab_binsearch+0x54>
f0100b11:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100b15:	83 ea 0c             	sub    $0xc,%edx
f0100b18:	39 f9                	cmp    %edi,%ecx
f0100b1a:	75 ee                	jne    f0100b0a <stab_binsearch+0x40>
f0100b1c:	eb 05                	jmp    f0100b23 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b1e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100b21:	eb 4b                	jmp    f0100b6e <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b23:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b26:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b29:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b2d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100b30:	76 11                	jbe    f0100b43 <stab_binsearch+0x79>
			*region_left = m;
f0100b32:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b35:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b37:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b3a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b41:	eb 2b                	jmp    f0100b6e <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b43:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100b46:	73 14                	jae    f0100b5c <stab_binsearch+0x92>
			*region_right = m - 1;
f0100b48:	83 e8 01             	sub    $0x1,%eax
f0100b4b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b4e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b51:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b53:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b5a:	eb 12                	jmp    f0100b6e <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b5c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b5f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b61:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b65:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b67:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b6e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b71:	0f 8e 78 ff ff ff    	jle    f0100aef <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b77:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b7b:	75 0f                	jne    f0100b8c <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100b7d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b80:	8b 00                	mov    (%eax),%eax
f0100b82:	83 e8 01             	sub    $0x1,%eax
f0100b85:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b88:	89 06                	mov    %eax,(%esi)
f0100b8a:	eb 2c                	jmp    f0100bb8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b8f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b91:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b94:	8b 0e                	mov    (%esi),%ecx
f0100b96:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b99:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b9c:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b9f:	eb 03                	jmp    f0100ba4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ba1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ba4:	39 c8                	cmp    %ecx,%eax
f0100ba6:	7e 0b                	jle    f0100bb3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100ba8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100bac:	83 ea 0c             	sub    $0xc,%edx
f0100baf:	39 df                	cmp    %ebx,%edi
f0100bb1:	75 ee                	jne    f0100ba1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100bb3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bb6:	89 06                	mov    %eax,(%esi)
	}
}
f0100bb8:	83 c4 14             	add    $0x14,%esp
f0100bbb:	5b                   	pop    %ebx
f0100bbc:	5e                   	pop    %esi
f0100bbd:	5f                   	pop    %edi
f0100bbe:	5d                   	pop    %ebp
f0100bbf:	c3                   	ret    

f0100bc0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100bc0:	55                   	push   %ebp
f0100bc1:	89 e5                	mov    %esp,%ebp
f0100bc3:	57                   	push   %edi
f0100bc4:	56                   	push   %esi
f0100bc5:	53                   	push   %ebx
f0100bc6:	83 ec 3c             	sub    $0x3c,%esp
f0100bc9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bcc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bcf:	c7 03 78 20 10 f0    	movl   $0xf0102078,(%ebx)
	info->eip_line = 0;
f0100bd5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bdc:	c7 43 08 78 20 10 f0 	movl   $0xf0102078,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100be3:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bea:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bed:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bf4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bfa:	76 11                	jbe    f0100c0d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bfc:	b8 21 80 10 f0       	mov    $0xf0108021,%eax
f0100c01:	3d 59 64 10 f0       	cmp    $0xf0106459,%eax
f0100c06:	77 19                	ja     f0100c21 <debuginfo_eip+0x61>
f0100c08:	e9 ba 01 00 00       	jmp    f0100dc7 <debuginfo_eip+0x207>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100c0d:	83 ec 04             	sub    $0x4,%esp
f0100c10:	68 82 20 10 f0       	push   $0xf0102082
f0100c15:	6a 7f                	push   $0x7f
f0100c17:	68 8f 20 10 f0       	push   $0xf010208f
f0100c1c:	e8 6a f4 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c21:	80 3d 20 80 10 f0 00 	cmpb   $0x0,0xf0108020
f0100c28:	0f 85 a0 01 00 00    	jne    f0100dce <debuginfo_eip+0x20e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c2e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c35:	b8 58 64 10 f0       	mov    $0xf0106458,%eax
f0100c3a:	2d d0 22 10 f0       	sub    $0xf01022d0,%eax
f0100c3f:	c1 f8 02             	sar    $0x2,%eax
f0100c42:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c48:	83 e8 01             	sub    $0x1,%eax
f0100c4b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c4e:	83 ec 08             	sub    $0x8,%esp
f0100c51:	56                   	push   %esi
f0100c52:	6a 64                	push   $0x64
f0100c54:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c57:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c5a:	b8 d0 22 10 f0       	mov    $0xf01022d0,%eax
f0100c5f:	e8 66 fe ff ff       	call   f0100aca <stab_binsearch>
	if (lfile == 0)
f0100c64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c67:	83 c4 10             	add    $0x10,%esp
f0100c6a:	85 c0                	test   %eax,%eax
f0100c6c:	0f 84 63 01 00 00    	je     f0100dd5 <debuginfo_eip+0x215>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c72:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c75:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c78:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c7b:	83 ec 08             	sub    $0x8,%esp
f0100c7e:	56                   	push   %esi
f0100c7f:	6a 24                	push   $0x24
f0100c81:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c84:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c87:	b8 d0 22 10 f0       	mov    $0xf01022d0,%eax
f0100c8c:	e8 39 fe ff ff       	call   f0100aca <stab_binsearch>

	if (lfun <= rfun) {
f0100c91:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c94:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c97:	83 c4 10             	add    $0x10,%esp
f0100c9a:	39 d0                	cmp    %edx,%eax
f0100c9c:	7f 40                	jg     f0100cde <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c9e:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100ca1:	c1 e1 02             	shl    $0x2,%ecx
f0100ca4:	8d b9 d0 22 10 f0    	lea    -0xfefdd30(%ecx),%edi
f0100caa:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100cad:	8b b9 d0 22 10 f0    	mov    -0xfefdd30(%ecx),%edi
f0100cb3:	b9 21 80 10 f0       	mov    $0xf0108021,%ecx
f0100cb8:	81 e9 59 64 10 f0    	sub    $0xf0106459,%ecx
f0100cbe:	39 cf                	cmp    %ecx,%edi
f0100cc0:	73 09                	jae    f0100ccb <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cc2:	81 c7 59 64 10 f0    	add    $0xf0106459,%edi
f0100cc8:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ccb:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100cce:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100cd1:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100cd4:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100cd6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100cd9:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100cdc:	eb 0f                	jmp    f0100ced <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cde:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ce1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ce7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cea:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ced:	83 ec 08             	sub    $0x8,%esp
f0100cf0:	6a 3a                	push   $0x3a
f0100cf2:	ff 73 08             	pushl  0x8(%ebx)
f0100cf5:	e8 09 09 00 00       	call   f0101603 <strfind>
f0100cfa:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cfd:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d00:	83 c4 08             	add    $0x8,%esp
f0100d03:	56                   	push   %esi
f0100d04:	6a 44                	push   $0x44
f0100d06:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d09:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d0c:	b8 d0 22 10 f0       	mov    $0xf01022d0,%eax
f0100d11:	e8 b4 fd ff ff       	call   f0100aca <stab_binsearch>
    if(lline <= rline){
f0100d16:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d19:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100d1c:	83 c4 10             	add    $0x10,%esp
f0100d1f:	39 d0                	cmp    %edx,%eax
f0100d21:	7f 10                	jg     f0100d33 <debuginfo_eip+0x173>
        info->eip_line = stabs[rline].n_desc;
f0100d23:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d26:	0f b7 14 95 d6 22 10 	movzwl -0xfefdd2a(,%edx,4),%edx
f0100d2d:	f0 
f0100d2e:	89 53 04             	mov    %edx,0x4(%ebx)
f0100d31:	eb 07                	jmp    f0100d3a <debuginfo_eip+0x17a>
    }
    else
        info->eip_line = -1;
f0100d33:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d3d:	89 c2                	mov    %eax,%edx
f0100d3f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100d42:	8d 04 85 d0 22 10 f0 	lea    -0xfefdd30(,%eax,4),%eax
f0100d49:	eb 06                	jmp    f0100d51 <debuginfo_eip+0x191>
f0100d4b:	83 ea 01             	sub    $0x1,%edx
f0100d4e:	83 e8 0c             	sub    $0xc,%eax
f0100d51:	39 d7                	cmp    %edx,%edi
f0100d53:	7f 34                	jg     f0100d89 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0100d55:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d59:	80 f9 84             	cmp    $0x84,%cl
f0100d5c:	74 0b                	je     f0100d69 <debuginfo_eip+0x1a9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d5e:	80 f9 64             	cmp    $0x64,%cl
f0100d61:	75 e8                	jne    f0100d4b <debuginfo_eip+0x18b>
f0100d63:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100d67:	74 e2                	je     f0100d4b <debuginfo_eip+0x18b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d69:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100d6c:	8b 14 85 d0 22 10 f0 	mov    -0xfefdd30(,%eax,4),%edx
f0100d73:	b8 21 80 10 f0       	mov    $0xf0108021,%eax
f0100d78:	2d 59 64 10 f0       	sub    $0xf0106459,%eax
f0100d7d:	39 c2                	cmp    %eax,%edx
f0100d7f:	73 08                	jae    f0100d89 <debuginfo_eip+0x1c9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d81:	81 c2 59 64 10 f0    	add    $0xf0106459,%edx
f0100d87:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d89:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d8c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d8f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d94:	39 f2                	cmp    %esi,%edx
f0100d96:	7d 49                	jge    f0100de1 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
f0100d98:	83 c2 01             	add    $0x1,%edx
f0100d9b:	89 d0                	mov    %edx,%eax
f0100d9d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100da0:	8d 14 95 d0 22 10 f0 	lea    -0xfefdd30(,%edx,4),%edx
f0100da7:	eb 04                	jmp    f0100dad <debuginfo_eip+0x1ed>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100da9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100dad:	39 c6                	cmp    %eax,%esi
f0100daf:	7e 2b                	jle    f0100ddc <debuginfo_eip+0x21c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100db1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100db5:	83 c0 01             	add    $0x1,%eax
f0100db8:	83 c2 0c             	add    $0xc,%edx
f0100dbb:	80 f9 a0             	cmp    $0xa0,%cl
f0100dbe:	74 e9                	je     f0100da9 <debuginfo_eip+0x1e9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dc5:	eb 1a                	jmp    f0100de1 <debuginfo_eip+0x221>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dcc:	eb 13                	jmp    f0100de1 <debuginfo_eip+0x221>
f0100dce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dd3:	eb 0c                	jmp    f0100de1 <debuginfo_eip+0x221>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100dd5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dda:	eb 05                	jmp    f0100de1 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ddc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100de1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100de4:	5b                   	pop    %ebx
f0100de5:	5e                   	pop    %esi
f0100de6:	5f                   	pop    %edi
f0100de7:	5d                   	pop    %ebp
f0100de8:	c3                   	ret    

f0100de9 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100de9:	55                   	push   %ebp
f0100dea:	89 e5                	mov    %esp,%ebp
f0100dec:	57                   	push   %edi
f0100ded:	56                   	push   %esi
f0100dee:	53                   	push   %ebx
f0100def:	83 ec 1c             	sub    $0x1c,%esp
f0100df2:	89 c7                	mov    %eax,%edi
f0100df4:	89 d6                	mov    %edx,%esi
f0100df6:	8b 45 08             	mov    0x8(%ebp),%eax
f0100df9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100dfc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100dff:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e02:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100e05:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e0a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100e0d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100e10:	39 d3                	cmp    %edx,%ebx
f0100e12:	72 05                	jb     f0100e19 <printnum+0x30>
f0100e14:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e17:	77 45                	ja     f0100e5e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e19:	83 ec 0c             	sub    $0xc,%esp
f0100e1c:	ff 75 18             	pushl  0x18(%ebp)
f0100e1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e22:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100e25:	53                   	push   %ebx
f0100e26:	ff 75 10             	pushl  0x10(%ebp)
f0100e29:	83 ec 08             	sub    $0x8,%esp
f0100e2c:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e2f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e32:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e35:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e38:	e8 f3 09 00 00       	call   f0101830 <__udivdi3>
f0100e3d:	83 c4 18             	add    $0x18,%esp
f0100e40:	52                   	push   %edx
f0100e41:	50                   	push   %eax
f0100e42:	89 f2                	mov    %esi,%edx
f0100e44:	89 f8                	mov    %edi,%eax
f0100e46:	e8 9e ff ff ff       	call   f0100de9 <printnum>
f0100e4b:	83 c4 20             	add    $0x20,%esp
f0100e4e:	eb 18                	jmp    f0100e68 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e50:	83 ec 08             	sub    $0x8,%esp
f0100e53:	56                   	push   %esi
f0100e54:	ff 75 18             	pushl  0x18(%ebp)
f0100e57:	ff d7                	call   *%edi
f0100e59:	83 c4 10             	add    $0x10,%esp
f0100e5c:	eb 03                	jmp    f0100e61 <printnum+0x78>
f0100e5e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e61:	83 eb 01             	sub    $0x1,%ebx
f0100e64:	85 db                	test   %ebx,%ebx
f0100e66:	7f e8                	jg     f0100e50 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e68:	83 ec 08             	sub    $0x8,%esp
f0100e6b:	56                   	push   %esi
f0100e6c:	83 ec 04             	sub    $0x4,%esp
f0100e6f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e72:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e75:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e78:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e7b:	e8 e0 0a 00 00       	call   f0101960 <__umoddi3>
f0100e80:	83 c4 14             	add    $0x14,%esp
f0100e83:	0f be 80 9d 20 10 f0 	movsbl -0xfefdf63(%eax),%eax
f0100e8a:	50                   	push   %eax
f0100e8b:	ff d7                	call   *%edi
}
f0100e8d:	83 c4 10             	add    $0x10,%esp
f0100e90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e93:	5b                   	pop    %ebx
f0100e94:	5e                   	pop    %esi
f0100e95:	5f                   	pop    %edi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e9e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ea2:	8b 10                	mov    (%eax),%edx
f0100ea4:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ea7:	73 0a                	jae    f0100eb3 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ea9:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100eac:	89 08                	mov    %ecx,(%eax)
f0100eae:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb1:	88 02                	mov    %al,(%edx)
}
f0100eb3:	5d                   	pop    %ebp
f0100eb4:	c3                   	ret    

f0100eb5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ebb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ebe:	50                   	push   %eax
f0100ebf:	ff 75 10             	pushl  0x10(%ebp)
f0100ec2:	ff 75 0c             	pushl  0xc(%ebp)
f0100ec5:	ff 75 08             	pushl  0x8(%ebp)
f0100ec8:	e8 05 00 00 00       	call   f0100ed2 <vprintfmt>
	va_end(ap);
}
f0100ecd:	83 c4 10             	add    $0x10,%esp
f0100ed0:	c9                   	leave  
f0100ed1:	c3                   	ret    

f0100ed2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ed2:	55                   	push   %ebp
f0100ed3:	89 e5                	mov    %esp,%ebp
f0100ed5:	57                   	push   %edi
f0100ed6:	56                   	push   %esi
f0100ed7:	53                   	push   %ebx
f0100ed8:	83 ec 2c             	sub    $0x2c,%esp
f0100edb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ede:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ee1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ee4:	eb 12                	jmp    f0100ef8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')//当然中间如果遇到'\0'，代表这个字符串的访问结束
f0100ee6:	85 c0                	test   %eax,%eax
f0100ee8:	0f 84 6a 04 00 00    	je     f0101358 <vprintfmt+0x486>
				return;
			putch(ch, putdat);//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0100eee:	83 ec 08             	sub    $0x8,%esp
f0100ef1:	53                   	push   %ebx
f0100ef2:	50                   	push   %eax
f0100ef3:	ff d6                	call   *%esi
f0100ef5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') { //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0100ef8:	83 c7 01             	add    $0x1,%edi
f0100efb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100eff:	83 f8 25             	cmp    $0x25,%eax
f0100f02:	75 e2                	jne    f0100ee6 <vprintfmt+0x14>
f0100f04:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f08:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f0f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f16:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100f1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f22:	eb 07                	jmp    f0100f2b <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100f24:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-'://%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f0100f27:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100f2b:	8d 47 01             	lea    0x1(%edi),%eax
f0100f2e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f31:	0f b6 07             	movzbl (%edi),%eax
f0100f34:	0f b6 d0             	movzbl %al,%edx
f0100f37:	83 e8 23             	sub    $0x23,%eax
f0100f3a:	3c 55                	cmp    $0x55,%al
f0100f3c:	0f 87 fb 03 00 00    	ja     f010133d <vprintfmt+0x46b>
f0100f42:	0f b6 c0             	movzbl %al,%eax
f0100f45:	ff 24 85 40 21 10 f0 	jmp    *-0xfefdec0(,%eax,4)
f0100f4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0'://0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';//对其方式标志位变为0
f0100f4f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f53:	eb d6                	jmp    f0100f2b <vprintfmt+0x59>
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100f55:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f58:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f5d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f0100f60:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f63:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f67:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f6a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f6d:	83 f9 09             	cmp    $0x9,%ecx
f0100f70:	77 3f                	ja     f0100fb1 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0100f72:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f75:	eb e9                	jmp    f0100f60 <vprintfmt+0x8e>
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f0100f77:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7a:	8b 00                	mov    (%eax),%eax
f0100f7c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f82:	8d 40 04             	lea    0x4(%eax),%eax
f0100f85:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100f88:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;//跳转到process_precistion子过程

		case '*'://*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f0100f8b:	eb 2a                	jmp    f0100fb7 <vprintfmt+0xe5>
f0100f8d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f90:	85 c0                	test   %eax,%eax
f0100f92:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f97:	0f 49 d0             	cmovns %eax,%edx
f0100f9a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100f9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fa0:	eb 89                	jmp    f0100f2b <vprintfmt+0x59>
f0100fa2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fa5:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fac:	e9 7a ff ff ff       	jmp    f0100f2b <vprintfmt+0x59>
f0100fb1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fb4:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision://处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f0100fb7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fbb:	0f 89 6a ff ff ff    	jns    f0100f2b <vprintfmt+0x59>
				width = precision, precision = -1;
f0100fc1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fc4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fc7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100fce:	e9 58 ff ff ff       	jmp    f0100f2b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
f0100fd3:	83 c1 01             	add    $0x1,%ecx
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100fd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l'://如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;//此时把lflag++
			goto reswitch;
f0100fd9:	e9 4d ff ff ff       	jmp    f0100f2b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0100fde:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe1:	8d 78 04             	lea    0x4(%eax),%edi
f0100fe4:	83 ec 08             	sub    $0x8,%esp
f0100fe7:	53                   	push   %ebx
f0100fe8:	ff 30                	pushl  (%eax)
f0100fea:	ff d6                	call   *%esi
			break;
f0100fec:	83 c4 10             	add    $0x10,%esp
			lflag++;//此时把lflag++
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
f0100fef:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0100ff2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;
f0100ff5:	e9 fe fe ff ff       	jmp    f0100ef8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ffa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffd:	8d 78 04             	lea    0x4(%eax),%edi
f0101000:	8b 00                	mov    (%eax),%eax
f0101002:	99                   	cltd   
f0101003:	31 d0                	xor    %edx,%eax
f0101005:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101007:	83 f8 07             	cmp    $0x7,%eax
f010100a:	7f 0b                	jg     f0101017 <vprintfmt+0x145>
f010100c:	8b 14 85 a0 22 10 f0 	mov    -0xfefdd60(,%eax,4),%edx
f0101013:	85 d2                	test   %edx,%edx
f0101015:	75 1b                	jne    f0101032 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0101017:	50                   	push   %eax
f0101018:	68 b5 20 10 f0       	push   $0xf01020b5
f010101d:	53                   	push   %ebx
f010101e:	56                   	push   %esi
f010101f:	e8 91 fe ff ff       	call   f0100eb5 <printfmt>
f0101024:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101027:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f010102a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010102d:	e9 c6 fe ff ff       	jmp    f0100ef8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101032:	52                   	push   %edx
f0101033:	68 be 20 10 f0       	push   $0xf01020be
f0101038:	53                   	push   %ebx
f0101039:	56                   	push   %esi
f010103a:	e8 76 fe ff ff       	call   f0100eb5 <printfmt>
f010103f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);//调用输出一个字符到内存的函数putch
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101042:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0101045:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101048:	e9 ab fe ff ff       	jmp    f0100ef8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010104d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101050:	83 c0 04             	add    $0x4,%eax
f0101053:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101056:	8b 45 14             	mov    0x14(%ebp),%eax
f0101059:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010105b:	85 ff                	test   %edi,%edi
f010105d:	b8 ae 20 10 f0       	mov    $0xf01020ae,%eax
f0101062:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101065:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101069:	0f 8e 94 00 00 00    	jle    f0101103 <vprintfmt+0x231>
f010106f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101073:	0f 84 98 00 00 00    	je     f0101111 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101079:	83 ec 08             	sub    $0x8,%esp
f010107c:	ff 75 d0             	pushl  -0x30(%ebp)
f010107f:	57                   	push   %edi
f0101080:	e8 34 04 00 00       	call   f01014b9 <strnlen>
f0101085:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101088:	29 c1                	sub    %eax,%ecx
f010108a:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f010108d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101090:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101094:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101097:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010109a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010109c:	eb 0f                	jmp    f01010ad <vprintfmt+0x1db>
					putch(padc, putdat);
f010109e:	83 ec 08             	sub    $0x8,%esp
f01010a1:	53                   	push   %ebx
f01010a2:	ff 75 e0             	pushl  -0x20(%ebp)
f01010a5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a7:	83 ef 01             	sub    $0x1,%edi
f01010aa:	83 c4 10             	add    $0x10,%esp
f01010ad:	85 ff                	test   %edi,%edi
f01010af:	7f ed                	jg     f010109e <vprintfmt+0x1cc>
f01010b1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010b4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01010b7:	85 c9                	test   %ecx,%ecx
f01010b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010be:	0f 49 c1             	cmovns %ecx,%eax
f01010c1:	29 c1                	sub    %eax,%ecx
f01010c3:	89 75 08             	mov    %esi,0x8(%ebp)
f01010c6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010c9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010cc:	89 cb                	mov    %ecx,%ebx
f01010ce:	eb 4d                	jmp    f010111d <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010d0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010d4:	74 1b                	je     f01010f1 <vprintfmt+0x21f>
f01010d6:	0f be c0             	movsbl %al,%eax
f01010d9:	83 e8 20             	sub    $0x20,%eax
f01010dc:	83 f8 5e             	cmp    $0x5e,%eax
f01010df:	76 10                	jbe    f01010f1 <vprintfmt+0x21f>
					putch('?', putdat);
f01010e1:	83 ec 08             	sub    $0x8,%esp
f01010e4:	ff 75 0c             	pushl  0xc(%ebp)
f01010e7:	6a 3f                	push   $0x3f
f01010e9:	ff 55 08             	call   *0x8(%ebp)
f01010ec:	83 c4 10             	add    $0x10,%esp
f01010ef:	eb 0d                	jmp    f01010fe <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f01010f1:	83 ec 08             	sub    $0x8,%esp
f01010f4:	ff 75 0c             	pushl  0xc(%ebp)
f01010f7:	52                   	push   %edx
f01010f8:	ff 55 08             	call   *0x8(%ebp)
f01010fb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010fe:	83 eb 01             	sub    $0x1,%ebx
f0101101:	eb 1a                	jmp    f010111d <vprintfmt+0x24b>
f0101103:	89 75 08             	mov    %esi,0x8(%ebp)
f0101106:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101109:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010110c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010110f:	eb 0c                	jmp    f010111d <vprintfmt+0x24b>
f0101111:	89 75 08             	mov    %esi,0x8(%ebp)
f0101114:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101117:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010111a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010111d:	83 c7 01             	add    $0x1,%edi
f0101120:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101124:	0f be d0             	movsbl %al,%edx
f0101127:	85 d2                	test   %edx,%edx
f0101129:	74 23                	je     f010114e <vprintfmt+0x27c>
f010112b:	85 f6                	test   %esi,%esi
f010112d:	78 a1                	js     f01010d0 <vprintfmt+0x1fe>
f010112f:	83 ee 01             	sub    $0x1,%esi
f0101132:	79 9c                	jns    f01010d0 <vprintfmt+0x1fe>
f0101134:	89 df                	mov    %ebx,%edi
f0101136:	8b 75 08             	mov    0x8(%ebp),%esi
f0101139:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010113c:	eb 18                	jmp    f0101156 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010113e:	83 ec 08             	sub    $0x8,%esp
f0101141:	53                   	push   %ebx
f0101142:	6a 20                	push   $0x20
f0101144:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101146:	83 ef 01             	sub    $0x1,%edi
f0101149:	83 c4 10             	add    $0x10,%esp
f010114c:	eb 08                	jmp    f0101156 <vprintfmt+0x284>
f010114e:	89 df                	mov    %ebx,%edi
f0101150:	8b 75 08             	mov    0x8(%ebp),%esi
f0101153:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101156:	85 ff                	test   %edi,%edi
f0101158:	7f e4                	jg     f010113e <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010115a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010115d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0101160:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101163:	e9 90 fd ff ff       	jmp    f0100ef8 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101168:	83 f9 01             	cmp    $0x1,%ecx
f010116b:	7e 19                	jle    f0101186 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f010116d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101170:	8b 50 04             	mov    0x4(%eax),%edx
f0101173:	8b 00                	mov    (%eax),%eax
f0101175:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101178:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010117b:	8b 45 14             	mov    0x14(%ebp),%eax
f010117e:	8d 40 08             	lea    0x8(%eax),%eax
f0101181:	89 45 14             	mov    %eax,0x14(%ebp)
f0101184:	eb 38                	jmp    f01011be <vprintfmt+0x2ec>
	else if (lflag)
f0101186:	85 c9                	test   %ecx,%ecx
f0101188:	74 1b                	je     f01011a5 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f010118a:	8b 45 14             	mov    0x14(%ebp),%eax
f010118d:	8b 00                	mov    (%eax),%eax
f010118f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101192:	89 c1                	mov    %eax,%ecx
f0101194:	c1 f9 1f             	sar    $0x1f,%ecx
f0101197:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010119a:	8b 45 14             	mov    0x14(%ebp),%eax
f010119d:	8d 40 04             	lea    0x4(%eax),%eax
f01011a0:	89 45 14             	mov    %eax,0x14(%ebp)
f01011a3:	eb 19                	jmp    f01011be <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01011a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a8:	8b 00                	mov    (%eax),%eax
f01011aa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011ad:	89 c1                	mov    %eax,%ecx
f01011af:	c1 f9 1f             	sar    $0x1f,%ecx
f01011b2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b8:	8d 40 04             	lea    0x4(%eax),%eax
f01011bb:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011be:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011c1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011c4:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011c9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011cd:	0f 89 36 01 00 00    	jns    f0101309 <vprintfmt+0x437>
				putch('-', putdat);
f01011d3:	83 ec 08             	sub    $0x8,%esp
f01011d6:	53                   	push   %ebx
f01011d7:	6a 2d                	push   $0x2d
f01011d9:	ff d6                	call   *%esi
				num = -(long long) num;
f01011db:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011de:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011e1:	f7 da                	neg    %edx
f01011e3:	83 d1 00             	adc    $0x0,%ecx
f01011e6:	f7 d9                	neg    %ecx
f01011e8:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01011eb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011f0:	e9 14 01 00 00       	jmp    f0101309 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011f5:	83 f9 01             	cmp    $0x1,%ecx
f01011f8:	7e 18                	jle    f0101212 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f01011fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fd:	8b 10                	mov    (%eax),%edx
f01011ff:	8b 48 04             	mov    0x4(%eax),%ecx
f0101202:	8d 40 08             	lea    0x8(%eax),%eax
f0101205:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101208:	b8 0a 00 00 00       	mov    $0xa,%eax
f010120d:	e9 f7 00 00 00       	jmp    f0101309 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101212:	85 c9                	test   %ecx,%ecx
f0101214:	74 1a                	je     f0101230 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0101216:	8b 45 14             	mov    0x14(%ebp),%eax
f0101219:	8b 10                	mov    (%eax),%edx
f010121b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101220:	8d 40 04             	lea    0x4(%eax),%eax
f0101223:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101226:	b8 0a 00 00 00       	mov    $0xa,%eax
f010122b:	e9 d9 00 00 00       	jmp    f0101309 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101230:	8b 45 14             	mov    0x14(%ebp),%eax
f0101233:	8b 10                	mov    (%eax),%edx
f0101235:	b9 00 00 00 00       	mov    $0x0,%ecx
f010123a:	8d 40 04             	lea    0x4(%eax),%eax
f010123d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101240:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101245:	e9 bf 00 00 00       	jmp    f0101309 <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010124a:	83 f9 01             	cmp    $0x1,%ecx
f010124d:	7e 13                	jle    f0101262 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f010124f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101252:	8b 50 04             	mov    0x4(%eax),%edx
f0101255:	8b 00                	mov    (%eax),%eax
f0101257:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010125a:	8d 49 08             	lea    0x8(%ecx),%ecx
f010125d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101260:	eb 28                	jmp    f010128a <vprintfmt+0x3b8>
	else if (lflag)
f0101262:	85 c9                	test   %ecx,%ecx
f0101264:	74 13                	je     f0101279 <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f0101266:	8b 45 14             	mov    0x14(%ebp),%eax
f0101269:	8b 10                	mov    (%eax),%edx
f010126b:	89 d0                	mov    %edx,%eax
f010126d:	99                   	cltd   
f010126e:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101271:	8d 49 04             	lea    0x4(%ecx),%ecx
f0101274:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101277:	eb 11                	jmp    f010128a <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f0101279:	8b 45 14             	mov    0x14(%ebp),%eax
f010127c:	8b 10                	mov    (%eax),%edx
f010127e:	89 d0                	mov    %edx,%eax
f0101280:	99                   	cltd   
f0101281:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101284:	8d 49 04             	lea    0x4(%ecx),%ecx
f0101287:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap,lflag);
f010128a:	89 d1                	mov    %edx,%ecx
f010128c:	89 c2                	mov    %eax,%edx
			base = 8;
f010128e:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101293:	eb 74                	jmp    f0101309 <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f0101295:	83 ec 08             	sub    $0x8,%esp
f0101298:	53                   	push   %ebx
f0101299:	6a 30                	push   $0x30
f010129b:	ff d6                	call   *%esi
			putch('x', putdat);
f010129d:	83 c4 08             	add    $0x8,%esp
f01012a0:	53                   	push   %ebx
f01012a1:	6a 78                	push   $0x78
f01012a3:	ff d6                	call   *%esi
			num = (unsigned long long)
f01012a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a8:	8b 10                	mov    (%eax),%edx
f01012aa:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01012af:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012b2:	8d 40 04             	lea    0x4(%eax),%eax
f01012b5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012b8:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01012bd:	eb 4a                	jmp    f0101309 <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01012bf:	83 f9 01             	cmp    $0x1,%ecx
f01012c2:	7e 15                	jle    f01012d9 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f01012c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c7:	8b 10                	mov    (%eax),%edx
f01012c9:	8b 48 04             	mov    0x4(%eax),%ecx
f01012cc:	8d 40 08             	lea    0x8(%eax),%eax
f01012cf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012d2:	b8 10 00 00 00       	mov    $0x10,%eax
f01012d7:	eb 30                	jmp    f0101309 <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01012d9:	85 c9                	test   %ecx,%ecx
f01012db:	74 17                	je     f01012f4 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f01012dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e0:	8b 10                	mov    (%eax),%edx
f01012e2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012e7:	8d 40 04             	lea    0x4(%eax),%eax
f01012ea:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012ed:	b8 10 00 00 00       	mov    $0x10,%eax
f01012f2:	eb 15                	jmp    f0101309 <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01012f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f7:	8b 10                	mov    (%eax),%edx
f01012f9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012fe:	8d 40 04             	lea    0x4(%eax),%eax
f0101301:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101304:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101309:	83 ec 0c             	sub    $0xc,%esp
f010130c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101310:	57                   	push   %edi
f0101311:	ff 75 e0             	pushl  -0x20(%ebp)
f0101314:	50                   	push   %eax
f0101315:	51                   	push   %ecx
f0101316:	52                   	push   %edx
f0101317:	89 da                	mov    %ebx,%edx
f0101319:	89 f0                	mov    %esi,%eax
f010131b:	e8 c9 fa ff ff       	call   f0100de9 <printnum>
			break;
f0101320:	83 c4 20             	add    $0x20,%esp
f0101323:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101326:	e9 cd fb ff ff       	jmp    f0100ef8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010132b:	83 ec 08             	sub    $0x8,%esp
f010132e:	53                   	push   %ebx
f010132f:	52                   	push   %edx
f0101330:	ff d6                	call   *%esi
			break;
f0101332:	83 c4 10             	add    $0x10,%esp
		width = -1;//整数部分有效数字位数
		precision = -1;//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {//根据位于'%'后面的第一个字符进行分情况处理
f0101335:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101338:	e9 bb fb ff ff       	jmp    f0100ef8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010133d:	83 ec 08             	sub    $0x8,%esp
f0101340:	53                   	push   %ebx
f0101341:	6a 25                	push   $0x25
f0101343:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101345:	83 c4 10             	add    $0x10,%esp
f0101348:	eb 03                	jmp    f010134d <vprintfmt+0x47b>
f010134a:	83 ef 01             	sub    $0x1,%edi
f010134d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101351:	75 f7                	jne    f010134a <vprintfmt+0x478>
f0101353:	e9 a0 fb ff ff       	jmp    f0100ef8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101358:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010135b:	5b                   	pop    %ebx
f010135c:	5e                   	pop    %esi
f010135d:	5f                   	pop    %edi
f010135e:	5d                   	pop    %ebp
f010135f:	c3                   	ret    

f0101360 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101360:	55                   	push   %ebp
f0101361:	89 e5                	mov    %esp,%ebp
f0101363:	83 ec 18             	sub    $0x18,%esp
f0101366:	8b 45 08             	mov    0x8(%ebp),%eax
f0101369:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010136c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010136f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101373:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101376:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010137d:	85 c0                	test   %eax,%eax
f010137f:	74 26                	je     f01013a7 <vsnprintf+0x47>
f0101381:	85 d2                	test   %edx,%edx
f0101383:	7e 22                	jle    f01013a7 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101385:	ff 75 14             	pushl  0x14(%ebp)
f0101388:	ff 75 10             	pushl  0x10(%ebp)
f010138b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010138e:	50                   	push   %eax
f010138f:	68 98 0e 10 f0       	push   $0xf0100e98
f0101394:	e8 39 fb ff ff       	call   f0100ed2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101399:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010139c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010139f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013a2:	83 c4 10             	add    $0x10,%esp
f01013a5:	eb 05                	jmp    f01013ac <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013a7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013ac:	c9                   	leave  
f01013ad:	c3                   	ret    

f01013ae <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013ae:	55                   	push   %ebp
f01013af:	89 e5                	mov    %esp,%ebp
f01013b1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013b4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013b7:	50                   	push   %eax
f01013b8:	ff 75 10             	pushl  0x10(%ebp)
f01013bb:	ff 75 0c             	pushl  0xc(%ebp)
f01013be:	ff 75 08             	pushl  0x8(%ebp)
f01013c1:	e8 9a ff ff ff       	call   f0101360 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013c6:	c9                   	leave  
f01013c7:	c3                   	ret    

f01013c8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	57                   	push   %edi
f01013cc:	56                   	push   %esi
f01013cd:	53                   	push   %ebx
f01013ce:	83 ec 0c             	sub    $0xc,%esp
f01013d1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	74 11                	je     f01013e9 <readline+0x21>
		cprintf("%s", prompt);
f01013d8:	83 ec 08             	sub    $0x8,%esp
f01013db:	50                   	push   %eax
f01013dc:	68 be 20 10 f0       	push   $0xf01020be
f01013e1:	e8 d0 f6 ff ff       	call   f0100ab6 <cprintf>
f01013e6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013e9:	83 ec 0c             	sub    $0xc,%esp
f01013ec:	6a 00                	push   $0x0
f01013ee:	e8 20 f2 ff ff       	call   f0100613 <iscons>
f01013f3:	89 c7                	mov    %eax,%edi
f01013f5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013f8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013fd:	e8 00 f2 ff ff       	call   f0100602 <getchar>
f0101402:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101404:	85 c0                	test   %eax,%eax
f0101406:	79 18                	jns    f0101420 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101408:	83 ec 08             	sub    $0x8,%esp
f010140b:	50                   	push   %eax
f010140c:	68 c0 22 10 f0       	push   $0xf01022c0
f0101411:	e8 a0 f6 ff ff       	call   f0100ab6 <cprintf>
			return NULL;
f0101416:	83 c4 10             	add    $0x10,%esp
f0101419:	b8 00 00 00 00       	mov    $0x0,%eax
f010141e:	eb 79                	jmp    f0101499 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101420:	83 f8 08             	cmp    $0x8,%eax
f0101423:	0f 94 c2             	sete   %dl
f0101426:	83 f8 7f             	cmp    $0x7f,%eax
f0101429:	0f 94 c0             	sete   %al
f010142c:	08 c2                	or     %al,%dl
f010142e:	74 1a                	je     f010144a <readline+0x82>
f0101430:	85 f6                	test   %esi,%esi
f0101432:	7e 16                	jle    f010144a <readline+0x82>
			if (echoing)
f0101434:	85 ff                	test   %edi,%edi
f0101436:	74 0d                	je     f0101445 <readline+0x7d>
				cputchar('\b');
f0101438:	83 ec 0c             	sub    $0xc,%esp
f010143b:	6a 08                	push   $0x8
f010143d:	e8 b0 f1 ff ff       	call   f01005f2 <cputchar>
f0101442:	83 c4 10             	add    $0x10,%esp
			i--;
f0101445:	83 ee 01             	sub    $0x1,%esi
f0101448:	eb b3                	jmp    f01013fd <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010144a:	83 fb 1f             	cmp    $0x1f,%ebx
f010144d:	7e 23                	jle    f0101472 <readline+0xaa>
f010144f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101455:	7f 1b                	jg     f0101472 <readline+0xaa>
			if (echoing)
f0101457:	85 ff                	test   %edi,%edi
f0101459:	74 0c                	je     f0101467 <readline+0x9f>
				cputchar(c);
f010145b:	83 ec 0c             	sub    $0xc,%esp
f010145e:	53                   	push   %ebx
f010145f:	e8 8e f1 ff ff       	call   f01005f2 <cputchar>
f0101464:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101467:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f010146d:	8d 76 01             	lea    0x1(%esi),%esi
f0101470:	eb 8b                	jmp    f01013fd <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101472:	83 fb 0a             	cmp    $0xa,%ebx
f0101475:	74 05                	je     f010147c <readline+0xb4>
f0101477:	83 fb 0d             	cmp    $0xd,%ebx
f010147a:	75 81                	jne    f01013fd <readline+0x35>
			if (echoing)
f010147c:	85 ff                	test   %edi,%edi
f010147e:	74 0d                	je     f010148d <readline+0xc5>
				cputchar('\n');
f0101480:	83 ec 0c             	sub    $0xc,%esp
f0101483:	6a 0a                	push   $0xa
f0101485:	e8 68 f1 ff ff       	call   f01005f2 <cputchar>
f010148a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010148d:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f0101494:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
		}
	}
}
f0101499:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010149c:	5b                   	pop    %ebx
f010149d:	5e                   	pop    %esi
f010149e:	5f                   	pop    %edi
f010149f:	5d                   	pop    %ebp
f01014a0:	c3                   	ret    

f01014a1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014a1:	55                   	push   %ebp
f01014a2:	89 e5                	mov    %esp,%ebp
f01014a4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01014ac:	eb 03                	jmp    f01014b1 <strlen+0x10>
		n++;
f01014ae:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014b1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014b5:	75 f7                	jne    f01014ae <strlen+0xd>
		n++;
	return n;
}
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
f01014bc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014bf:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01014c7:	eb 03                	jmp    f01014cc <strnlen+0x13>
		n++;
f01014c9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014cc:	39 c2                	cmp    %eax,%edx
f01014ce:	74 08                	je     f01014d8 <strnlen+0x1f>
f01014d0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01014d4:	75 f3                	jne    f01014c9 <strnlen+0x10>
f01014d6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01014d8:	5d                   	pop    %ebp
f01014d9:	c3                   	ret    

f01014da <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014da:	55                   	push   %ebp
f01014db:	89 e5                	mov    %esp,%ebp
f01014dd:	53                   	push   %ebx
f01014de:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014e4:	89 c2                	mov    %eax,%edx
f01014e6:	83 c2 01             	add    $0x1,%edx
f01014e9:	83 c1 01             	add    $0x1,%ecx
f01014ec:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014f0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014f3:	84 db                	test   %bl,%bl
f01014f5:	75 ef                	jne    f01014e6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014f7:	5b                   	pop    %ebx
f01014f8:	5d                   	pop    %ebp
f01014f9:	c3                   	ret    

f01014fa <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014fa:	55                   	push   %ebp
f01014fb:	89 e5                	mov    %esp,%ebp
f01014fd:	53                   	push   %ebx
f01014fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101501:	53                   	push   %ebx
f0101502:	e8 9a ff ff ff       	call   f01014a1 <strlen>
f0101507:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010150a:	ff 75 0c             	pushl  0xc(%ebp)
f010150d:	01 d8                	add    %ebx,%eax
f010150f:	50                   	push   %eax
f0101510:	e8 c5 ff ff ff       	call   f01014da <strcpy>
	return dst;
}
f0101515:	89 d8                	mov    %ebx,%eax
f0101517:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010151a:	c9                   	leave  
f010151b:	c3                   	ret    

f010151c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010151c:	55                   	push   %ebp
f010151d:	89 e5                	mov    %esp,%ebp
f010151f:	56                   	push   %esi
f0101520:	53                   	push   %ebx
f0101521:	8b 75 08             	mov    0x8(%ebp),%esi
f0101524:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101527:	89 f3                	mov    %esi,%ebx
f0101529:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010152c:	89 f2                	mov    %esi,%edx
f010152e:	eb 0f                	jmp    f010153f <strncpy+0x23>
		*dst++ = *src;
f0101530:	83 c2 01             	add    $0x1,%edx
f0101533:	0f b6 01             	movzbl (%ecx),%eax
f0101536:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101539:	80 39 01             	cmpb   $0x1,(%ecx)
f010153c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010153f:	39 da                	cmp    %ebx,%edx
f0101541:	75 ed                	jne    f0101530 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101543:	89 f0                	mov    %esi,%eax
f0101545:	5b                   	pop    %ebx
f0101546:	5e                   	pop    %esi
f0101547:	5d                   	pop    %ebp
f0101548:	c3                   	ret    

f0101549 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101549:	55                   	push   %ebp
f010154a:	89 e5                	mov    %esp,%ebp
f010154c:	56                   	push   %esi
f010154d:	53                   	push   %ebx
f010154e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101551:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101554:	8b 55 10             	mov    0x10(%ebp),%edx
f0101557:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101559:	85 d2                	test   %edx,%edx
f010155b:	74 21                	je     f010157e <strlcpy+0x35>
f010155d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101561:	89 f2                	mov    %esi,%edx
f0101563:	eb 09                	jmp    f010156e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101565:	83 c2 01             	add    $0x1,%edx
f0101568:	83 c1 01             	add    $0x1,%ecx
f010156b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010156e:	39 c2                	cmp    %eax,%edx
f0101570:	74 09                	je     f010157b <strlcpy+0x32>
f0101572:	0f b6 19             	movzbl (%ecx),%ebx
f0101575:	84 db                	test   %bl,%bl
f0101577:	75 ec                	jne    f0101565 <strlcpy+0x1c>
f0101579:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010157b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010157e:	29 f0                	sub    %esi,%eax
}
f0101580:	5b                   	pop    %ebx
f0101581:	5e                   	pop    %esi
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    

f0101584 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101584:	55                   	push   %ebp
f0101585:	89 e5                	mov    %esp,%ebp
f0101587:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010158a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010158d:	eb 06                	jmp    f0101595 <strcmp+0x11>
		p++, q++;
f010158f:	83 c1 01             	add    $0x1,%ecx
f0101592:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101595:	0f b6 01             	movzbl (%ecx),%eax
f0101598:	84 c0                	test   %al,%al
f010159a:	74 04                	je     f01015a0 <strcmp+0x1c>
f010159c:	3a 02                	cmp    (%edx),%al
f010159e:	74 ef                	je     f010158f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a0:	0f b6 c0             	movzbl %al,%eax
f01015a3:	0f b6 12             	movzbl (%edx),%edx
f01015a6:	29 d0                	sub    %edx,%eax
}
f01015a8:	5d                   	pop    %ebp
f01015a9:	c3                   	ret    

f01015aa <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015aa:	55                   	push   %ebp
f01015ab:	89 e5                	mov    %esp,%ebp
f01015ad:	53                   	push   %ebx
f01015ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015b4:	89 c3                	mov    %eax,%ebx
f01015b6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015b9:	eb 06                	jmp    f01015c1 <strncmp+0x17>
		n--, p++, q++;
f01015bb:	83 c0 01             	add    $0x1,%eax
f01015be:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015c1:	39 d8                	cmp    %ebx,%eax
f01015c3:	74 15                	je     f01015da <strncmp+0x30>
f01015c5:	0f b6 08             	movzbl (%eax),%ecx
f01015c8:	84 c9                	test   %cl,%cl
f01015ca:	74 04                	je     f01015d0 <strncmp+0x26>
f01015cc:	3a 0a                	cmp    (%edx),%cl
f01015ce:	74 eb                	je     f01015bb <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d0:	0f b6 00             	movzbl (%eax),%eax
f01015d3:	0f b6 12             	movzbl (%edx),%edx
f01015d6:	29 d0                	sub    %edx,%eax
f01015d8:	eb 05                	jmp    f01015df <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015da:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015df:	5b                   	pop    %ebx
f01015e0:	5d                   	pop    %ebp
f01015e1:	c3                   	ret    

f01015e2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015e2:	55                   	push   %ebp
f01015e3:	89 e5                	mov    %esp,%ebp
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015ec:	eb 07                	jmp    f01015f5 <strchr+0x13>
		if (*s == c)
f01015ee:	38 ca                	cmp    %cl,%dl
f01015f0:	74 0f                	je     f0101601 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015f2:	83 c0 01             	add    $0x1,%eax
f01015f5:	0f b6 10             	movzbl (%eax),%edx
f01015f8:	84 d2                	test   %dl,%dl
f01015fa:	75 f2                	jne    f01015ee <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101601:	5d                   	pop    %ebp
f0101602:	c3                   	ret    

f0101603 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101603:	55                   	push   %ebp
f0101604:	89 e5                	mov    %esp,%ebp
f0101606:	8b 45 08             	mov    0x8(%ebp),%eax
f0101609:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010160d:	eb 03                	jmp    f0101612 <strfind+0xf>
f010160f:	83 c0 01             	add    $0x1,%eax
f0101612:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101615:	38 ca                	cmp    %cl,%dl
f0101617:	74 04                	je     f010161d <strfind+0x1a>
f0101619:	84 d2                	test   %dl,%dl
f010161b:	75 f2                	jne    f010160f <strfind+0xc>
			break;
	return (char *) s;
}
f010161d:	5d                   	pop    %ebp
f010161e:	c3                   	ret    

f010161f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010161f:	55                   	push   %ebp
f0101620:	89 e5                	mov    %esp,%ebp
f0101622:	57                   	push   %edi
f0101623:	56                   	push   %esi
f0101624:	53                   	push   %ebx
f0101625:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101628:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010162b:	85 c9                	test   %ecx,%ecx
f010162d:	74 36                	je     f0101665 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010162f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101635:	75 28                	jne    f010165f <memset+0x40>
f0101637:	f6 c1 03             	test   $0x3,%cl
f010163a:	75 23                	jne    f010165f <memset+0x40>
		c &= 0xFF;
f010163c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101640:	89 d3                	mov    %edx,%ebx
f0101642:	c1 e3 08             	shl    $0x8,%ebx
f0101645:	89 d6                	mov    %edx,%esi
f0101647:	c1 e6 18             	shl    $0x18,%esi
f010164a:	89 d0                	mov    %edx,%eax
f010164c:	c1 e0 10             	shl    $0x10,%eax
f010164f:	09 f0                	or     %esi,%eax
f0101651:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101653:	89 d8                	mov    %ebx,%eax
f0101655:	09 d0                	or     %edx,%eax
f0101657:	c1 e9 02             	shr    $0x2,%ecx
f010165a:	fc                   	cld    
f010165b:	f3 ab                	rep stos %eax,%es:(%edi)
f010165d:	eb 06                	jmp    f0101665 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010165f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101662:	fc                   	cld    
f0101663:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101665:	89 f8                	mov    %edi,%eax
f0101667:	5b                   	pop    %ebx
f0101668:	5e                   	pop    %esi
f0101669:	5f                   	pop    %edi
f010166a:	5d                   	pop    %ebp
f010166b:	c3                   	ret    

f010166c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010166c:	55                   	push   %ebp
f010166d:	89 e5                	mov    %esp,%ebp
f010166f:	57                   	push   %edi
f0101670:	56                   	push   %esi
f0101671:	8b 45 08             	mov    0x8(%ebp),%eax
f0101674:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101677:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010167a:	39 c6                	cmp    %eax,%esi
f010167c:	73 35                	jae    f01016b3 <memmove+0x47>
f010167e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101681:	39 d0                	cmp    %edx,%eax
f0101683:	73 2e                	jae    f01016b3 <memmove+0x47>
		s += n;
		d += n;
f0101685:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101688:	89 d6                	mov    %edx,%esi
f010168a:	09 fe                	or     %edi,%esi
f010168c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101692:	75 13                	jne    f01016a7 <memmove+0x3b>
f0101694:	f6 c1 03             	test   $0x3,%cl
f0101697:	75 0e                	jne    f01016a7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101699:	83 ef 04             	sub    $0x4,%edi
f010169c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010169f:	c1 e9 02             	shr    $0x2,%ecx
f01016a2:	fd                   	std    
f01016a3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016a5:	eb 09                	jmp    f01016b0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016a7:	83 ef 01             	sub    $0x1,%edi
f01016aa:	8d 72 ff             	lea    -0x1(%edx),%esi
f01016ad:	fd                   	std    
f01016ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016b0:	fc                   	cld    
f01016b1:	eb 1d                	jmp    f01016d0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016b3:	89 f2                	mov    %esi,%edx
f01016b5:	09 c2                	or     %eax,%edx
f01016b7:	f6 c2 03             	test   $0x3,%dl
f01016ba:	75 0f                	jne    f01016cb <memmove+0x5f>
f01016bc:	f6 c1 03             	test   $0x3,%cl
f01016bf:	75 0a                	jne    f01016cb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01016c1:	c1 e9 02             	shr    $0x2,%ecx
f01016c4:	89 c7                	mov    %eax,%edi
f01016c6:	fc                   	cld    
f01016c7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016c9:	eb 05                	jmp    f01016d0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016cb:	89 c7                	mov    %eax,%edi
f01016cd:	fc                   	cld    
f01016ce:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016d0:	5e                   	pop    %esi
f01016d1:	5f                   	pop    %edi
f01016d2:	5d                   	pop    %ebp
f01016d3:	c3                   	ret    

f01016d4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016d4:	55                   	push   %ebp
f01016d5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016d7:	ff 75 10             	pushl  0x10(%ebp)
f01016da:	ff 75 0c             	pushl  0xc(%ebp)
f01016dd:	ff 75 08             	pushl  0x8(%ebp)
f01016e0:	e8 87 ff ff ff       	call   f010166c <memmove>
}
f01016e5:	c9                   	leave  
f01016e6:	c3                   	ret    

f01016e7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016e7:	55                   	push   %ebp
f01016e8:	89 e5                	mov    %esp,%ebp
f01016ea:	56                   	push   %esi
f01016eb:	53                   	push   %ebx
f01016ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ef:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016f2:	89 c6                	mov    %eax,%esi
f01016f4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016f7:	eb 1a                	jmp    f0101713 <memcmp+0x2c>
		if (*s1 != *s2)
f01016f9:	0f b6 08             	movzbl (%eax),%ecx
f01016fc:	0f b6 1a             	movzbl (%edx),%ebx
f01016ff:	38 d9                	cmp    %bl,%cl
f0101701:	74 0a                	je     f010170d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101703:	0f b6 c1             	movzbl %cl,%eax
f0101706:	0f b6 db             	movzbl %bl,%ebx
f0101709:	29 d8                	sub    %ebx,%eax
f010170b:	eb 0f                	jmp    f010171c <memcmp+0x35>
		s1++, s2++;
f010170d:	83 c0 01             	add    $0x1,%eax
f0101710:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101713:	39 f0                	cmp    %esi,%eax
f0101715:	75 e2                	jne    f01016f9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101717:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010171c:	5b                   	pop    %ebx
f010171d:	5e                   	pop    %esi
f010171e:	5d                   	pop    %ebp
f010171f:	c3                   	ret    

f0101720 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101720:	55                   	push   %ebp
f0101721:	89 e5                	mov    %esp,%ebp
f0101723:	53                   	push   %ebx
f0101724:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101727:	89 c1                	mov    %eax,%ecx
f0101729:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010172c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101730:	eb 0a                	jmp    f010173c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101732:	0f b6 10             	movzbl (%eax),%edx
f0101735:	39 da                	cmp    %ebx,%edx
f0101737:	74 07                	je     f0101740 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101739:	83 c0 01             	add    $0x1,%eax
f010173c:	39 c8                	cmp    %ecx,%eax
f010173e:	72 f2                	jb     f0101732 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101740:	5b                   	pop    %ebx
f0101741:	5d                   	pop    %ebp
f0101742:	c3                   	ret    

f0101743 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101743:	55                   	push   %ebp
f0101744:	89 e5                	mov    %esp,%ebp
f0101746:	57                   	push   %edi
f0101747:	56                   	push   %esi
f0101748:	53                   	push   %ebx
f0101749:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010174c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010174f:	eb 03                	jmp    f0101754 <strtol+0x11>
		s++;
f0101751:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101754:	0f b6 01             	movzbl (%ecx),%eax
f0101757:	3c 20                	cmp    $0x20,%al
f0101759:	74 f6                	je     f0101751 <strtol+0xe>
f010175b:	3c 09                	cmp    $0x9,%al
f010175d:	74 f2                	je     f0101751 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010175f:	3c 2b                	cmp    $0x2b,%al
f0101761:	75 0a                	jne    f010176d <strtol+0x2a>
		s++;
f0101763:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101766:	bf 00 00 00 00       	mov    $0x0,%edi
f010176b:	eb 11                	jmp    f010177e <strtol+0x3b>
f010176d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101772:	3c 2d                	cmp    $0x2d,%al
f0101774:	75 08                	jne    f010177e <strtol+0x3b>
		s++, neg = 1;
f0101776:	83 c1 01             	add    $0x1,%ecx
f0101779:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010177e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101784:	75 15                	jne    f010179b <strtol+0x58>
f0101786:	80 39 30             	cmpb   $0x30,(%ecx)
f0101789:	75 10                	jne    f010179b <strtol+0x58>
f010178b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010178f:	75 7c                	jne    f010180d <strtol+0xca>
		s += 2, base = 16;
f0101791:	83 c1 02             	add    $0x2,%ecx
f0101794:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101799:	eb 16                	jmp    f01017b1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010179b:	85 db                	test   %ebx,%ebx
f010179d:	75 12                	jne    f01017b1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010179f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017a4:	80 39 30             	cmpb   $0x30,(%ecx)
f01017a7:	75 08                	jne    f01017b1 <strtol+0x6e>
		s++, base = 8;
f01017a9:	83 c1 01             	add    $0x1,%ecx
f01017ac:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01017b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017b9:	0f b6 11             	movzbl (%ecx),%edx
f01017bc:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017bf:	89 f3                	mov    %esi,%ebx
f01017c1:	80 fb 09             	cmp    $0x9,%bl
f01017c4:	77 08                	ja     f01017ce <strtol+0x8b>
			dig = *s - '0';
f01017c6:	0f be d2             	movsbl %dl,%edx
f01017c9:	83 ea 30             	sub    $0x30,%edx
f01017cc:	eb 22                	jmp    f01017f0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01017ce:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017d1:	89 f3                	mov    %esi,%ebx
f01017d3:	80 fb 19             	cmp    $0x19,%bl
f01017d6:	77 08                	ja     f01017e0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01017d8:	0f be d2             	movsbl %dl,%edx
f01017db:	83 ea 57             	sub    $0x57,%edx
f01017de:	eb 10                	jmp    f01017f0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01017e0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017e3:	89 f3                	mov    %esi,%ebx
f01017e5:	80 fb 19             	cmp    $0x19,%bl
f01017e8:	77 16                	ja     f0101800 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01017ea:	0f be d2             	movsbl %dl,%edx
f01017ed:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01017f0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017f3:	7d 0b                	jge    f0101800 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01017f5:	83 c1 01             	add    $0x1,%ecx
f01017f8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017fc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01017fe:	eb b9                	jmp    f01017b9 <strtol+0x76>

	if (endptr)
f0101800:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101804:	74 0d                	je     f0101813 <strtol+0xd0>
		*endptr = (char *) s;
f0101806:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101809:	89 0e                	mov    %ecx,(%esi)
f010180b:	eb 06                	jmp    f0101813 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010180d:	85 db                	test   %ebx,%ebx
f010180f:	74 98                	je     f01017a9 <strtol+0x66>
f0101811:	eb 9e                	jmp    f01017b1 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101813:	89 c2                	mov    %eax,%edx
f0101815:	f7 da                	neg    %edx
f0101817:	85 ff                	test   %edi,%edi
f0101819:	0f 45 c2             	cmovne %edx,%eax
}
f010181c:	5b                   	pop    %ebx
f010181d:	5e                   	pop    %esi
f010181e:	5f                   	pop    %edi
f010181f:	5d                   	pop    %ebp
f0101820:	c3                   	ret    
f0101821:	66 90                	xchg   %ax,%ax
f0101823:	66 90                	xchg   %ax,%ax
f0101825:	66 90                	xchg   %ax,%ax
f0101827:	66 90                	xchg   %ax,%ax
f0101829:	66 90                	xchg   %ax,%ax
f010182b:	66 90                	xchg   %ax,%ax
f010182d:	66 90                	xchg   %ax,%ax
f010182f:	90                   	nop

f0101830 <__udivdi3>:
f0101830:	55                   	push   %ebp
f0101831:	57                   	push   %edi
f0101832:	56                   	push   %esi
f0101833:	53                   	push   %ebx
f0101834:	83 ec 1c             	sub    $0x1c,%esp
f0101837:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010183b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010183f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101843:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101847:	85 f6                	test   %esi,%esi
f0101849:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010184d:	89 ca                	mov    %ecx,%edx
f010184f:	89 f8                	mov    %edi,%eax
f0101851:	75 3d                	jne    f0101890 <__udivdi3+0x60>
f0101853:	39 cf                	cmp    %ecx,%edi
f0101855:	0f 87 c5 00 00 00    	ja     f0101920 <__udivdi3+0xf0>
f010185b:	85 ff                	test   %edi,%edi
f010185d:	89 fd                	mov    %edi,%ebp
f010185f:	75 0b                	jne    f010186c <__udivdi3+0x3c>
f0101861:	b8 01 00 00 00       	mov    $0x1,%eax
f0101866:	31 d2                	xor    %edx,%edx
f0101868:	f7 f7                	div    %edi
f010186a:	89 c5                	mov    %eax,%ebp
f010186c:	89 c8                	mov    %ecx,%eax
f010186e:	31 d2                	xor    %edx,%edx
f0101870:	f7 f5                	div    %ebp
f0101872:	89 c1                	mov    %eax,%ecx
f0101874:	89 d8                	mov    %ebx,%eax
f0101876:	89 cf                	mov    %ecx,%edi
f0101878:	f7 f5                	div    %ebp
f010187a:	89 c3                	mov    %eax,%ebx
f010187c:	89 d8                	mov    %ebx,%eax
f010187e:	89 fa                	mov    %edi,%edx
f0101880:	83 c4 1c             	add    $0x1c,%esp
f0101883:	5b                   	pop    %ebx
f0101884:	5e                   	pop    %esi
f0101885:	5f                   	pop    %edi
f0101886:	5d                   	pop    %ebp
f0101887:	c3                   	ret    
f0101888:	90                   	nop
f0101889:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101890:	39 ce                	cmp    %ecx,%esi
f0101892:	77 74                	ja     f0101908 <__udivdi3+0xd8>
f0101894:	0f bd fe             	bsr    %esi,%edi
f0101897:	83 f7 1f             	xor    $0x1f,%edi
f010189a:	0f 84 98 00 00 00    	je     f0101938 <__udivdi3+0x108>
f01018a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01018a5:	89 f9                	mov    %edi,%ecx
f01018a7:	89 c5                	mov    %eax,%ebp
f01018a9:	29 fb                	sub    %edi,%ebx
f01018ab:	d3 e6                	shl    %cl,%esi
f01018ad:	89 d9                	mov    %ebx,%ecx
f01018af:	d3 ed                	shr    %cl,%ebp
f01018b1:	89 f9                	mov    %edi,%ecx
f01018b3:	d3 e0                	shl    %cl,%eax
f01018b5:	09 ee                	or     %ebp,%esi
f01018b7:	89 d9                	mov    %ebx,%ecx
f01018b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018bd:	89 d5                	mov    %edx,%ebp
f01018bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018c3:	d3 ed                	shr    %cl,%ebp
f01018c5:	89 f9                	mov    %edi,%ecx
f01018c7:	d3 e2                	shl    %cl,%edx
f01018c9:	89 d9                	mov    %ebx,%ecx
f01018cb:	d3 e8                	shr    %cl,%eax
f01018cd:	09 c2                	or     %eax,%edx
f01018cf:	89 d0                	mov    %edx,%eax
f01018d1:	89 ea                	mov    %ebp,%edx
f01018d3:	f7 f6                	div    %esi
f01018d5:	89 d5                	mov    %edx,%ebp
f01018d7:	89 c3                	mov    %eax,%ebx
f01018d9:	f7 64 24 0c          	mull   0xc(%esp)
f01018dd:	39 d5                	cmp    %edx,%ebp
f01018df:	72 10                	jb     f01018f1 <__udivdi3+0xc1>
f01018e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01018e5:	89 f9                	mov    %edi,%ecx
f01018e7:	d3 e6                	shl    %cl,%esi
f01018e9:	39 c6                	cmp    %eax,%esi
f01018eb:	73 07                	jae    f01018f4 <__udivdi3+0xc4>
f01018ed:	39 d5                	cmp    %edx,%ebp
f01018ef:	75 03                	jne    f01018f4 <__udivdi3+0xc4>
f01018f1:	83 eb 01             	sub    $0x1,%ebx
f01018f4:	31 ff                	xor    %edi,%edi
f01018f6:	89 d8                	mov    %ebx,%eax
f01018f8:	89 fa                	mov    %edi,%edx
f01018fa:	83 c4 1c             	add    $0x1c,%esp
f01018fd:	5b                   	pop    %ebx
f01018fe:	5e                   	pop    %esi
f01018ff:	5f                   	pop    %edi
f0101900:	5d                   	pop    %ebp
f0101901:	c3                   	ret    
f0101902:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101908:	31 ff                	xor    %edi,%edi
f010190a:	31 db                	xor    %ebx,%ebx
f010190c:	89 d8                	mov    %ebx,%eax
f010190e:	89 fa                	mov    %edi,%edx
f0101910:	83 c4 1c             	add    $0x1c,%esp
f0101913:	5b                   	pop    %ebx
f0101914:	5e                   	pop    %esi
f0101915:	5f                   	pop    %edi
f0101916:	5d                   	pop    %ebp
f0101917:	c3                   	ret    
f0101918:	90                   	nop
f0101919:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101920:	89 d8                	mov    %ebx,%eax
f0101922:	f7 f7                	div    %edi
f0101924:	31 ff                	xor    %edi,%edi
f0101926:	89 c3                	mov    %eax,%ebx
f0101928:	89 d8                	mov    %ebx,%eax
f010192a:	89 fa                	mov    %edi,%edx
f010192c:	83 c4 1c             	add    $0x1c,%esp
f010192f:	5b                   	pop    %ebx
f0101930:	5e                   	pop    %esi
f0101931:	5f                   	pop    %edi
f0101932:	5d                   	pop    %ebp
f0101933:	c3                   	ret    
f0101934:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101938:	39 ce                	cmp    %ecx,%esi
f010193a:	72 0c                	jb     f0101948 <__udivdi3+0x118>
f010193c:	31 db                	xor    %ebx,%ebx
f010193e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101942:	0f 87 34 ff ff ff    	ja     f010187c <__udivdi3+0x4c>
f0101948:	bb 01 00 00 00       	mov    $0x1,%ebx
f010194d:	e9 2a ff ff ff       	jmp    f010187c <__udivdi3+0x4c>
f0101952:	66 90                	xchg   %ax,%ax
f0101954:	66 90                	xchg   %ax,%ax
f0101956:	66 90                	xchg   %ax,%ax
f0101958:	66 90                	xchg   %ax,%ax
f010195a:	66 90                	xchg   %ax,%ax
f010195c:	66 90                	xchg   %ax,%ax
f010195e:	66 90                	xchg   %ax,%ax

f0101960 <__umoddi3>:
f0101960:	55                   	push   %ebp
f0101961:	57                   	push   %edi
f0101962:	56                   	push   %esi
f0101963:	53                   	push   %ebx
f0101964:	83 ec 1c             	sub    $0x1c,%esp
f0101967:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010196b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010196f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101973:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101977:	85 d2                	test   %edx,%edx
f0101979:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010197d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101981:	89 f3                	mov    %esi,%ebx
f0101983:	89 3c 24             	mov    %edi,(%esp)
f0101986:	89 74 24 04          	mov    %esi,0x4(%esp)
f010198a:	75 1c                	jne    f01019a8 <__umoddi3+0x48>
f010198c:	39 f7                	cmp    %esi,%edi
f010198e:	76 50                	jbe    f01019e0 <__umoddi3+0x80>
f0101990:	89 c8                	mov    %ecx,%eax
f0101992:	89 f2                	mov    %esi,%edx
f0101994:	f7 f7                	div    %edi
f0101996:	89 d0                	mov    %edx,%eax
f0101998:	31 d2                	xor    %edx,%edx
f010199a:	83 c4 1c             	add    $0x1c,%esp
f010199d:	5b                   	pop    %ebx
f010199e:	5e                   	pop    %esi
f010199f:	5f                   	pop    %edi
f01019a0:	5d                   	pop    %ebp
f01019a1:	c3                   	ret    
f01019a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019a8:	39 f2                	cmp    %esi,%edx
f01019aa:	89 d0                	mov    %edx,%eax
f01019ac:	77 52                	ja     f0101a00 <__umoddi3+0xa0>
f01019ae:	0f bd ea             	bsr    %edx,%ebp
f01019b1:	83 f5 1f             	xor    $0x1f,%ebp
f01019b4:	75 5a                	jne    f0101a10 <__umoddi3+0xb0>
f01019b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01019ba:	0f 82 e0 00 00 00    	jb     f0101aa0 <__umoddi3+0x140>
f01019c0:	39 0c 24             	cmp    %ecx,(%esp)
f01019c3:	0f 86 d7 00 00 00    	jbe    f0101aa0 <__umoddi3+0x140>
f01019c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01019d1:	83 c4 1c             	add    $0x1c,%esp
f01019d4:	5b                   	pop    %ebx
f01019d5:	5e                   	pop    %esi
f01019d6:	5f                   	pop    %edi
f01019d7:	5d                   	pop    %ebp
f01019d8:	c3                   	ret    
f01019d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	85 ff                	test   %edi,%edi
f01019e2:	89 fd                	mov    %edi,%ebp
f01019e4:	75 0b                	jne    f01019f1 <__umoddi3+0x91>
f01019e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019eb:	31 d2                	xor    %edx,%edx
f01019ed:	f7 f7                	div    %edi
f01019ef:	89 c5                	mov    %eax,%ebp
f01019f1:	89 f0                	mov    %esi,%eax
f01019f3:	31 d2                	xor    %edx,%edx
f01019f5:	f7 f5                	div    %ebp
f01019f7:	89 c8                	mov    %ecx,%eax
f01019f9:	f7 f5                	div    %ebp
f01019fb:	89 d0                	mov    %edx,%eax
f01019fd:	eb 99                	jmp    f0101998 <__umoddi3+0x38>
f01019ff:	90                   	nop
f0101a00:	89 c8                	mov    %ecx,%eax
f0101a02:	89 f2                	mov    %esi,%edx
f0101a04:	83 c4 1c             	add    $0x1c,%esp
f0101a07:	5b                   	pop    %ebx
f0101a08:	5e                   	pop    %esi
f0101a09:	5f                   	pop    %edi
f0101a0a:	5d                   	pop    %ebp
f0101a0b:	c3                   	ret    
f0101a0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a10:	8b 34 24             	mov    (%esp),%esi
f0101a13:	bf 20 00 00 00       	mov    $0x20,%edi
f0101a18:	89 e9                	mov    %ebp,%ecx
f0101a1a:	29 ef                	sub    %ebp,%edi
f0101a1c:	d3 e0                	shl    %cl,%eax
f0101a1e:	89 f9                	mov    %edi,%ecx
f0101a20:	89 f2                	mov    %esi,%edx
f0101a22:	d3 ea                	shr    %cl,%edx
f0101a24:	89 e9                	mov    %ebp,%ecx
f0101a26:	09 c2                	or     %eax,%edx
f0101a28:	89 d8                	mov    %ebx,%eax
f0101a2a:	89 14 24             	mov    %edx,(%esp)
f0101a2d:	89 f2                	mov    %esi,%edx
f0101a2f:	d3 e2                	shl    %cl,%edx
f0101a31:	89 f9                	mov    %edi,%ecx
f0101a33:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101a37:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101a3b:	d3 e8                	shr    %cl,%eax
f0101a3d:	89 e9                	mov    %ebp,%ecx
f0101a3f:	89 c6                	mov    %eax,%esi
f0101a41:	d3 e3                	shl    %cl,%ebx
f0101a43:	89 f9                	mov    %edi,%ecx
f0101a45:	89 d0                	mov    %edx,%eax
f0101a47:	d3 e8                	shr    %cl,%eax
f0101a49:	89 e9                	mov    %ebp,%ecx
f0101a4b:	09 d8                	or     %ebx,%eax
f0101a4d:	89 d3                	mov    %edx,%ebx
f0101a4f:	89 f2                	mov    %esi,%edx
f0101a51:	f7 34 24             	divl   (%esp)
f0101a54:	89 d6                	mov    %edx,%esi
f0101a56:	d3 e3                	shl    %cl,%ebx
f0101a58:	f7 64 24 04          	mull   0x4(%esp)
f0101a5c:	39 d6                	cmp    %edx,%esi
f0101a5e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101a62:	89 d1                	mov    %edx,%ecx
f0101a64:	89 c3                	mov    %eax,%ebx
f0101a66:	72 08                	jb     f0101a70 <__umoddi3+0x110>
f0101a68:	75 11                	jne    f0101a7b <__umoddi3+0x11b>
f0101a6a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101a6e:	73 0b                	jae    f0101a7b <__umoddi3+0x11b>
f0101a70:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101a74:	1b 14 24             	sbb    (%esp),%edx
f0101a77:	89 d1                	mov    %edx,%ecx
f0101a79:	89 c3                	mov    %eax,%ebx
f0101a7b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0101a7f:	29 da                	sub    %ebx,%edx
f0101a81:	19 ce                	sbb    %ecx,%esi
f0101a83:	89 f9                	mov    %edi,%ecx
f0101a85:	89 f0                	mov    %esi,%eax
f0101a87:	d3 e0                	shl    %cl,%eax
f0101a89:	89 e9                	mov    %ebp,%ecx
f0101a8b:	d3 ea                	shr    %cl,%edx
f0101a8d:	89 e9                	mov    %ebp,%ecx
f0101a8f:	d3 ee                	shr    %cl,%esi
f0101a91:	09 d0                	or     %edx,%eax
f0101a93:	89 f2                	mov    %esi,%edx
f0101a95:	83 c4 1c             	add    $0x1c,%esp
f0101a98:	5b                   	pop    %ebx
f0101a99:	5e                   	pop    %esi
f0101a9a:	5f                   	pop    %edi
f0101a9b:	5d                   	pop    %ebp
f0101a9c:	c3                   	ret    
f0101a9d:	8d 76 00             	lea    0x0(%esi),%esi
f0101aa0:	29 f9                	sub    %edi,%ecx
f0101aa2:	19 d6                	sbb    %edx,%esi
f0101aa4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101aa8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101aac:	e9 18 ff ff ff       	jmp    f01019c9 <__umoddi3+0x69>
