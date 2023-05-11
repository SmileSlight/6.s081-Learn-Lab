
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c8478793          	addi	a5,a5,-892 # 80005ce0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3d2080e7          	jalr	978(ra) # 800024f8 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	85a080e7          	jalr	-1958(ra) # 80001a28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	062080e7          	jalr	98(ra) # 80002240 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	288080e7          	jalr	648(ra) # 800024a2 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	252080e7          	jalr	594(ra) # 8000254e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f76080e7          	jalr	-138(ra) # 800023c6 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b10080e7          	jalr	-1264(ra) # 800023c6 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8f0080e7          	jalr	-1808(ra) # 80002240 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <count_free_mem>:

uint64
count_free_mem(void) // added for counting free memory in bytes (lab2)
{
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  acquire(&kmem.lock); // 必须先锁内存管理结构，防止竞态条件出现
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  
  // 统计空闲页数，乘上页大小 PGSIZE 就是空闲的内存字节数
  uint64 mem_bytes = 0;
  struct run *r = kmem.freelist;
    80000b9c:	6c9c                	ld	a5,24(s1)
  while(r){
    80000b9e:	c785                	beqz	a5,80000bc6 <count_free_mem+0x46>
  uint64 mem_bytes = 0;
    80000ba0:	4481                	li	s1,0
    mem_bytes += PGSIZE;
    80000ba2:	6705                	lui	a4,0x1
    80000ba4:	94ba                	add	s1,s1,a4
    r = r->next;
    80000ba6:	639c                	ld	a5,0(a5)
  while(r){
    80000ba8:	fff5                	bnez	a5,80000ba4 <count_free_mem+0x24>
  }

  release(&kmem.lock);
    80000baa:	00011517          	auipc	a0,0x11
    80000bae:	d8650513          	addi	a0,a0,-634 # 80011930 <kmem>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	15c080e7          	jalr	348(ra) # 80000d0e <release>

  return mem_bytes;
    80000bba:	8526                	mv	a0,s1
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  uint64 mem_bytes = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7cd                	j	80000baa <count_free_mem+0x2a>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e18080e7          	jalr	-488(ra) # 80001a0c <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de6080e7          	jalr	-538(ra) # 80001a0c <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dda080e7          	jalr	-550(ra) # 80001a0c <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc2080e7          	jalr	-574(ra) # 80001a0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d56080e7          	jalr	-682(ra) # 80001a0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4) # 1000 <_entry-0x7ffff000>
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	aec080e7          	jalr	-1300(ra) # 800019fc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	ad0080e7          	jalr	-1328(ra) # 800019fc <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	76e080e7          	jalr	1902(ra) # 800026bc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	dca080e7          	jalr	-566(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	006080e7          	jalr	6(ra) # 80001f64 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	80a080e7          	jalr	-2038(ra) # 80000778 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	614080e7          	jalr	1556(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	11a50513          	addi	a0,a0,282 # 800080a0 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	604080e7          	jalr	1540(ra) # 80000592 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13250513          	addi	a0,a0,306 # 800080c8 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b3e080e7          	jalr	-1218(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	96e080e7          	jalr	-1682(ra) # 8000192c <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	6ce080e7          	jalr	1742(ra) # 80002694 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	6ee080e7          	jalr	1774(ra) # 800026bc <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	d34080e7          	jalr	-716(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	d42080e7          	jalr	-702(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	ee8080e7          	jalr	-280(ra) # 80002ece <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	578080e7          	jalr	1400(ra) # 80003566 <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	512080e7          	jalr	1298(ra) # 80004508 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	e2a080e7          	jalr	-470(ra) # 80005e28 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	cf0080e7          	jalr	-784(ra) # 80001cf6 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srli	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	slli	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	06850513          	addi	a0,a0,104 # 800080d0 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	aa4080e7          	jalr	-1372(ra) # 80000b20 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cca080e7          	jalr	-822(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srli	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	andi	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	addi	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	00a7d513          	srli	a0,a5,0xa
    80001122:	0532                	slli	a0,a0,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	addi	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	addi	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	slli	a0,a0,0x34
    80001138:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	andi	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srli	a0,a0,0xa
    8000115a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	addi	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f6050513          	addi	a0,a0,-160 # 800080d8 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	addi	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	addi	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	167d                	addi	a2,a2,-1
    800011aa:	00b609b3          	add	s3,a2,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	addi	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	addi	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	addi	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	302080e7          	jalr	770(ra) # 80000548 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	addi	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	8c8080e7          	jalr	-1848(ra) # 80000b20 <kalloc>
    80001260:	00008797          	auipc	a5,0x8
    80001264:	daa7b823          	sd	a0,-592(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	aea080e7          	jalr	-1302(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	addi	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	addi	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	slli	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	slli	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	addi	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	addi	a0,a0,-1
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	addi	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	slli	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	slli	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e863          	bltu	a1,s3,800013bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	addi	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	d8a50513          	addi	a0,a0,-630 # 800080f0 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	d9250513          	addi	a0,a0,-622 # 80008108 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	d9250513          	addi	a0,a0,-622 # 80008118 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	d9a50513          	addi	a0,a0,-614 # 80008130 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	67a080e7          	jalr	1658(ra) # 80000a24 <kfree>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	f9397ce3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	c80080e7          	jalr	-896(ra) # 80001042 <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d54d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dbcd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fb778ee3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x92>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	732080e7          	jalr	1842(ra) # 80000b20 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	958080e7          	jalr	-1704(ra) # 80000d56 <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6f2080e7          	jalr	1778(ra) # 80000b20 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	91a080e7          	jalr	-1766(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95a080e7          	jalr	-1702(ra) # 80000db6 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cd450513          	addi	a0,a0,-812 # 80008148 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	767d                	lui	a2,0xfffff
    800014a0:	8f71                	and	a4,a4,a2
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff1                	and	a5,a5,a2
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6985                	lui	s3,0x1
    800014e8:	19fd                	addi	s3,s3,-1
    800014ea:	95ce                	add	a1,a1,s3
    800014ec:	79fd                	lui	s3,0xfffff
    800014ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	628080e7          	jalr	1576(ra) # 80000b20 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	84e080e7          	jalr	-1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4d0080e7          	jalr	1232(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a821                	j	800015a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001594:	0532                	slli	a0,a0,0xc
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	fe0080e7          	jalr	-32(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    8000159e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a2:	04a1                	addi	s1,s1,8
    800015a4:	03248163          	beq	s1,s2,800015c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015aa:	00f57793          	andi	a5,a0,15
    800015ae:	ff3782e3          	beq	a5,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b2:	8905                	andi	a0,a0,1
    800015b4:	d57d                	beqz	a0,800015a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bb250513          	addi	a0,a0,-1102 # 80008168 <digits+0x128>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c6:	8552                	mv	a0,s4
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	45c080e7          	jalr	1116(ra) # 80000a24 <kfree>
}
    800015d0:	70a2                	ld	ra,40(sp)
    800015d2:	7402                	ld	s0,32(sp)
    800015d4:	64e2                	ld	s1,24(sp)
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	69a2                	ld	s3,8(sp)
    800015da:	6a02                	ld	s4,0(sp)
    800015dc:	6145                	addi	sp,sp,48
    800015de:	8082                	ret

00000000800015e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e0:	1101                	addi	sp,sp,-32
    800015e2:	ec06                	sd	ra,24(sp)
    800015e4:	e822                	sd	s0,16(sp)
    800015e6:	e426                	sd	s1,8(sp)
    800015e8:	1000                	addi	s0,sp,32
    800015ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ec:	e999                	bnez	a1,80001602 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f86080e7          	jalr	-122(ra) # 80001576 <freewalk>
}
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6105                	addi	sp,sp,32
    80001600:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001602:	6605                	lui	a2,0x1
    80001604:	167d                	addi	a2,a2,-1
    80001606:	962e                	add	a2,a2,a1
    80001608:	4685                	li	a3,1
    8000160a:	8231                	srli	a2,a2,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d12080e7          	jalr	-750(ra) # 80001320 <uvmunmap>
    80001616:	bfe1                	j	800015ee <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a04080e7          	jalr	-1532(ra) # 80001042 <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4c4080e7          	jalr	1220(ra) # 80000b20 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	74a080e7          	jalr	1866(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b0a080e7          	jalr	-1270(ra) # 80001188 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	370080e7          	jalr	880(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c5a080e7          	jalr	-934(ra) # 80001320 <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94e080e7          	jalr	-1714(ra) # 80001042 <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e34080e7          	jalr	-460(ra) # 80000548 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	666080e7          	jalr	1638(ra) # 80000db6 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97a080e7          	jalr	-1670(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	c6bd                	beqz	a3,80001816 <copyin+0x6e>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a015                	j	800017f2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	9562                	add	a0,a0,s8
    800017d2:	0004861b          	sext.w	a2,s1
    800017d6:	412505b3          	sub	a1,a0,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	5da080e7          	jalr	1498(ra) # 80000db6 <memmove>

    len -= n;
    800017e4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ee:	02098263          	beqz	s3,80001812 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85ca                	mv	a1,s2
    800017f8:	855a                	mv	a0,s6
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	8ee080e7          	jalr	-1810(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001802:	cd01                	beqz	a0,8000181a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001804:	418904b3          	sub	s1,s2,s8
    80001808:	94d6                	add	s1,s1,s5
    if(n > len)
    8000180a:	fc99f3e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    8000180e:	84ce                	mv	s1,s3
    80001810:	b7c1                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001812:	4501                	li	a0,0
    80001814:	a021                	j	8000181c <copyin+0x74>
    80001816:	4501                	li	a0,0
}
    80001818:	8082                	ret
      return -1;
    8000181a:	557d                	li	a0,-1
}
    8000181c:	60a6                	ld	ra,72(sp)
    8000181e:	6406                	ld	s0,64(sp)
    80001820:	74e2                	ld	s1,56(sp)
    80001822:	7942                	ld	s2,48(sp)
    80001824:	79a2                	ld	s3,40(sp)
    80001826:	7a02                	ld	s4,32(sp)
    80001828:	6ae2                	ld	s5,24(sp)
    8000182a:	6b42                	ld	s6,16(sp)
    8000182c:	6ba2                	ld	s7,8(sp)
    8000182e:	6c02                	ld	s8,0(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret

0000000080001834 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001834:	c6c5                	beqz	a3,800018dc <copyinstr+0xa8>
{
    80001836:	715d                	addi	sp,sp,-80
    80001838:	e486                	sd	ra,72(sp)
    8000183a:	e0a2                	sd	s0,64(sp)
    8000183c:	fc26                	sd	s1,56(sp)
    8000183e:	f84a                	sd	s2,48(sp)
    80001840:	f44e                	sd	s3,40(sp)
    80001842:	f052                	sd	s4,32(sp)
    80001844:	ec56                	sd	s5,24(sp)
    80001846:	e85a                	sd	s6,16(sp)
    80001848:	e45e                	sd	s7,8(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8a2a                	mv	s4,a0
    8000184e:	8b2e                	mv	s6,a1
    80001850:	8bb2                	mv	s7,a2
    80001852:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6985                	lui	s3,0x1
    80001858:	a035                	j	80001884 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001860:	0017b793          	seqz	a5,a5
    80001864:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	85c080e7          	jalr	-1956(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001896:	41790833          	sub	a6,s2,s7
    8000189a:	984e                	add	a6,a6,s3
    if(n > max)
    8000189c:	0104f363          	bgeu	s1,a6,800018a2 <copyinstr+0x6e>
    800018a0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	fc080be3          	beqz	a6,8000187e <copyinstr+0x4a>
    800018ac:	985a                	add	a6,a6,s6
    800018ae:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b0:	41650633          	sub	a2,a0,s6
    800018b4:	14fd                	addi	s1,s1,-1
    800018b6:	9b26                	add	s6,s6,s1
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c0:	df49                	beqz	a4,8000185a <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	ff0796e3          	bne	a5,a6,800018b8 <copyinstr+0x84>
      dst++;
    800018d0:	8b42                	mv	s6,a6
    800018d2:	b775                	j	8000187e <copyinstr+0x4a>
    800018d4:	4781                	li	a5,0
    800018d6:	b769                	j	80001860 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x34>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	0017b793          	seqz	a5,a5
    800018e2:	40f00533          	neg	a0,a5
}
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	2ec080e7          	jalr	748(ra) # 80000be0 <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8ba50513          	addi	a0,a0,-1862 # 800081c8 <digits+0x188>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <procinit>:
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	88e58593          	addi	a1,a1,-1906 # 800081d0 <digits+0x190>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	00650513          	addi	a0,a0,6 # 80011950 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	278080e7          	jalr	632(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010917          	auipc	s2,0x10
    8000195e:	40e90913          	addi	s2,s2,1038 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b97          	auipc	s7,0x7
    80001966:	876b8b93          	addi	s7,s7,-1930 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196a:	8b4a                	mv	s6,s2
    8000196c:	00006a97          	auipc	s5,0x6
    80001970:	694a8a93          	addi	s5,s5,1684 # 80008000 <etext>
    80001974:	040009b7          	lui	s3,0x4000
    80001978:	19fd                	addi	s3,s3,-1
    8000197a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016a17          	auipc	s4,0x16
    80001980:	feca0a13          	addi	s4,s4,-20 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85de                	mv	a1,s7
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	242080e7          	jalr	578(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80001998:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199a:	c929                	beqz	a0,800019ec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199c:	416904b3          	sub	s1,s2,s6
    800019a0:	8491                	srai	s1,s1,0x4
    800019a2:	000ab783          	ld	a5,0(s5)
    800019a6:	02f484b3          	mul	s1,s1,a5
    800019aa:	2485                	addiw	s1,s1,1
    800019ac:	00d4949b          	slliw	s1,s1,0xd
    800019b0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4699                	li	a3,6
    800019b6:	6605                	lui	a2,0x1
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	85c080e7          	jalr	-1956(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	17090913          	addi	s2,s2,368
    800019ca:	fb491de3          	bne	s2,s4,80001984 <procinit+0x58>
  kvminithart();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	650080e7          	jalr	1616(ra) # 8000101e <kvminithart>
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6161                	addi	sp,sp,80
    800019ea:	8082                	ret
        panic("kalloc");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7f450513          	addi	a0,a0,2036 # 800081e0 <digits+0x1a0>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>

00000000800019fc <cpuid>:
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a02:	8512                	mv	a0,tp
}
    80001a04:	2501                	sext.w	a0,a0
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <mycpu>:
mycpu(void) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
}
    80001a18:	00010517          	auipc	a0,0x10
    80001a1c:	f5050513          	addi	a0,a0,-176 # 80011968 <cpus>
    80001a20:	953e                	add	a0,a0,a5
    80001a22:	6422                	ld	s0,8(sp)
    80001a24:	0141                	addi	sp,sp,16
    80001a26:	8082                	ret

0000000080001a28 <myproc>:
myproc(void) {
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
  push_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1dc080e7          	jalr	476(ra) # 80000c0e <push_off>
    80001a3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3c:	2781                	sext.w	a5,a5
    80001a3e:	079e                	slli	a5,a5,0x7
    80001a40:	00010717          	auipc	a4,0x10
    80001a44:	f1070713          	addi	a4,a4,-240 # 80011950 <pid_lock>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	262080e7          	jalr	610(ra) # 80000cae <pop_off>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6105                	addi	sp,sp,32
    80001a5e:	8082                	ret

0000000080001a60 <forkret>:
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e406                	sd	ra,8(sp)
    80001a64:	e022                	sd	s0,0(sp)
    80001a66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	fc0080e7          	jalr	-64(ra) # 80001a28 <myproc>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	29e080e7          	jalr	670(ra) # 80000d0e <release>
  if (first) {
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	e787a783          	lw	a5,-392(a5) # 800088f0 <first.1667>
    80001a80:	eb89                	bnez	a5,80001a92 <forkret+0x32>
  usertrapret();
    80001a82:	00001097          	auipc	ra,0x1
    80001a86:	c52080e7          	jalr	-942(ra) # 800026d4 <usertrapret>
}
    80001a8a:	60a2                	ld	ra,8(sp)
    80001a8c:	6402                	ld	s0,0(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret
    first = 0;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	e407af23          	sw	zero,-418(a5) # 800088f0 <first.1667>
    fsinit(ROOTDEV);
    80001a9a:	4505                	li	a0,1
    80001a9c:	00002097          	auipc	ra,0x2
    80001aa0:	a4a080e7          	jalr	-1462(ra) # 800034e6 <fsinit>
    80001aa4:	bff9                	j	80001a82 <forkret+0x22>

0000000080001aa6 <allocpid>:
allocpid() {
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab2:	00010917          	auipc	s2,0x10
    80001ab6:	e9e90913          	addi	s2,s2,-354 # 80011950 <pid_lock>
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac4:	00007797          	auipc	a5,0x7
    80001ac8:	e3078793          	addi	a5,a5,-464 # 800088f4 <nextpid>
    80001acc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ace:	0014871b          	addiw	a4,s1,1
    80001ad2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	238080e7          	jalr	568(ra) # 80000d0e <release>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret

0000000080001aec <proc_pagetable>:
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	e04a                	sd	s2,0(sp)
    80001af6:	1000                	addi	s0,sp,32
    80001af8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	8ea080e7          	jalr	-1814(ra) # 800013e4 <uvmcreate>
    80001b02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b04:	c121                	beqz	a0,80001b44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b06:	4729                	li	a4,10
    80001b08:	00005697          	auipc	a3,0x5
    80001b0c:	4f868693          	addi	a3,a3,1272 # 80007000 <_trampoline>
    80001b10:	6605                	lui	a2,0x1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	66e080e7          	jalr	1646(ra) # 80001188 <mappages>
    80001b22:	02054863          	bltz	a0,80001b52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b26:	4719                	li	a4,6
    80001b28:	05893683          	ld	a3,88(s2)
    80001b2c:	6605                	lui	a2,0x1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	650080e7          	jalr	1616(ra) # 80001188 <mappages>
    80001b40:	02054163          	bltz	a0,80001b62 <proc_pagetable+0x76>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	addi	sp,sp,32
    80001b50:	8082                	ret
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a8a080e7          	jalr	-1398(ra) # 800015e0 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	b7d5                	j	80001b44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	7b0080e7          	jalr	1968(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b78:	4581                	li	a1,0
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a64080e7          	jalr	-1436(ra) # 800015e0 <uvmfree>
    return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	bf7d                	j	80001b44 <proc_pagetable+0x58>

0000000080001b88 <proc_freepagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	84aa                	mv	s1,a0
    80001b96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b98:	4681                	li	a3,0
    80001b9a:	4605                	li	a2,1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	77c080e7          	jalr	1916(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	020005b7          	lui	a1,0x2000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b6                	slli	a1,a1,0xd
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	766080e7          	jalr	1894(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc2:	85ca                	mv	a1,s2
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a1a080e7          	jalr	-1510(ra) # 800015e0 <uvmfree>
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <freeproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be6:	6d28                	ld	a0,88(a0)
    80001be8:	c509                	beqz	a0,80001bf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	e3a080e7          	jalr	-454(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf6:	68a8                	ld	a0,80(s1)
    80001bf8:	c511                	beqz	a0,80001c04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfa:	64ac                	ld	a1,72(s1)
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	f8c080e7          	jalr	-116(ra) # 80001b88 <proc_freepagetable>
  p->pagetable = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c24:	0004ac23          	sw	zero,24(s1)
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <allocproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3e:	00010497          	auipc	s1,0x10
    80001c42:	12a48493          	addi	s1,s1,298 # 80011d68 <proc>
    80001c46:	00016917          	auipc	s2,0x16
    80001c4a:	d2290913          	addi	s2,s2,-734 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	00a080e7          	jalr	10(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c58:	4c9c                	lw	a5,24(s1)
    80001c5a:	cf81                	beqz	a5,80001c72 <allocproc+0x40>
      release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	0b0080e7          	jalr	176(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	17048493          	addi	s1,s1,368
    80001c6a:	ff2492e3          	bne	s1,s2,80001c4e <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a889                	j	80001cc2 <allocproc+0x90>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e34080e7          	jalr	-460(ra) # 80001aa6 <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	ea4080e7          	jalr	-348(ra) # 80000b20 <kalloc>
    80001c84:	892a                	mv	s2,a0
    80001c86:	eca8                	sd	a0,88(s1)
    80001c88:	c521                	beqz	a0,80001cd0 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e60080e7          	jalr	-416(ra) # 80001aec <proc_pagetable>
    80001c94:	892a                	mv	s2,a0
    80001c96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c98:	c139                	beqz	a0,80001cde <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80001c9a:	07000613          	li	a2,112
    80001c9e:	4581                	li	a1,0
    80001ca0:	06048513          	addi	a0,s1,96
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0b2080e7          	jalr	178(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cac:	00000797          	auipc	a5,0x0
    80001cb0:	db478793          	addi	a5,a5,-588 # 80001a60 <forkret>
    80001cb4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb6:	60bc                	ld	a5,64(s1)
    80001cb8:	6705                	lui	a4,0x1
    80001cba:	97ba                	add	a5,a5,a4
    80001cbc:	f4bc                	sd	a5,104(s1)
  p->syscall_trace = 0; // (newly added) 为 syscall_trace 设置一个 0 的默认值
    80001cbe:	1604b423          	sd	zero,360(s1)
}
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	60e2                	ld	ra,24(sp)
    80001cc6:	6442                	ld	s0,16(sp)
    80001cc8:	64a2                	ld	s1,8(sp)
    80001cca:	6902                	ld	s2,0(sp)
    80001ccc:	6105                	addi	sp,sp,32
    80001cce:	8082                	ret
    release(&p->lock);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	03c080e7          	jalr	60(ra) # 80000d0e <release>
    return 0;
    80001cda:	84ca                	mv	s1,s2
    80001cdc:	b7dd                	j	80001cc2 <allocproc+0x90>
    freeproc(p);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	efa080e7          	jalr	-262(ra) # 80001bda <freeproc>
    release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	024080e7          	jalr	36(ra) # 80000d0e <release>
    return 0;
    80001cf2:	84ca                	mv	s1,s2
    80001cf4:	b7f9                	j	80001cc2 <allocproc+0x90>

0000000080001cf6 <userinit>:
{
    80001cf6:	1101                	addi	sp,sp,-32
    80001cf8:	ec06                	sd	ra,24(sp)
    80001cfa:	e822                	sd	s0,16(sp)
    80001cfc:	e426                	sd	s1,8(sp)
    80001cfe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	f32080e7          	jalr	-206(ra) # 80001c32 <allocproc>
    80001d08:	84aa                	mv	s1,a0
  initproc = p;
    80001d0a:	00007797          	auipc	a5,0x7
    80001d0e:	30a7b723          	sd	a0,782(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d12:	03400613          	li	a2,52
    80001d16:	00007597          	auipc	a1,0x7
    80001d1a:	bea58593          	addi	a1,a1,-1046 # 80008900 <initcode>
    80001d1e:	6928                	ld	a0,80(a0)
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	6f2080e7          	jalr	1778(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d28:	6785                	lui	a5,0x1
    80001d2a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d2c:	6cb8                	ld	a4,88(s1)
    80001d2e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d32:	6cb8                	ld	a4,88(s1)
    80001d34:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d36:	4641                	li	a2,16
    80001d38:	00006597          	auipc	a1,0x6
    80001d3c:	4b058593          	addi	a1,a1,1200 # 800081e8 <digits+0x1a8>
    80001d40:	15848513          	addi	a0,s1,344
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	168080e7          	jalr	360(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d4c:	00006517          	auipc	a0,0x6
    80001d50:	4ac50513          	addi	a0,a0,1196 # 800081f8 <digits+0x1b8>
    80001d54:	00002097          	auipc	ra,0x2
    80001d58:	1ba080e7          	jalr	442(ra) # 80003f0e <namei>
    80001d5c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d60:	4789                	li	a5,2
    80001d62:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	fa8080e7          	jalr	-88(ra) # 80000d0e <release>
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <growproc>:
{
    80001d78:	1101                	addi	sp,sp,-32
    80001d7a:	ec06                	sd	ra,24(sp)
    80001d7c:	e822                	sd	s0,16(sp)
    80001d7e:	e426                	sd	s1,8(sp)
    80001d80:	e04a                	sd	s2,0(sp)
    80001d82:	1000                	addi	s0,sp,32
    80001d84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ca2080e7          	jalr	-862(ra) # 80001a28 <myproc>
    80001d8e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d90:	652c                	ld	a1,72(a0)
    80001d92:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d96:	00904f63          	bgtz	s1,80001db4 <growproc+0x3c>
  } else if(n < 0){
    80001d9a:	0204cc63          	bltz	s1,80001dd2 <growproc+0x5a>
  p->sz = sz;
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da6:	4501                	li	a0,0
}
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6902                	ld	s2,0(sp)
    80001db0:	6105                	addi	sp,sp,32
    80001db2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db4:	9e25                	addw	a2,a2,s1
    80001db6:	1602                	slli	a2,a2,0x20
    80001db8:	9201                	srli	a2,a2,0x20
    80001dba:	1582                	slli	a1,a1,0x20
    80001dbc:	9181                	srli	a1,a1,0x20
    80001dbe:	6928                	ld	a0,80(a0)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	70c080e7          	jalr	1804(ra) # 800014cc <uvmalloc>
    80001dc8:	0005061b          	sext.w	a2,a0
    80001dcc:	fa69                	bnez	a2,80001d9e <growproc+0x26>
      return -1;
    80001dce:	557d                	li	a0,-1
    80001dd0:	bfe1                	j	80001da8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd2:	9e25                	addw	a2,a2,s1
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	1582                	slli	a1,a1,0x20
    80001dda:	9181                	srli	a1,a1,0x20
    80001ddc:	6928                	ld	a0,80(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	6a6080e7          	jalr	1702(ra) # 80001484 <uvmdealloc>
    80001de6:	0005061b          	sext.w	a2,a0
    80001dea:	bf55                	j	80001d9e <growproc+0x26>

0000000080001dec <fork>:
{
    80001dec:	7179                	addi	sp,sp,-48
    80001dee:	f406                	sd	ra,40(sp)
    80001df0:	f022                	sd	s0,32(sp)
    80001df2:	ec26                	sd	s1,24(sp)
    80001df4:	e84a                	sd	s2,16(sp)
    80001df6:	e44e                	sd	s3,8(sp)
    80001df8:	e052                	sd	s4,0(sp)
    80001dfa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	c2c080e7          	jalr	-980(ra) # 80001a28 <myproc>
    80001e04:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	e2c080e7          	jalr	-468(ra) # 80001c32 <allocproc>
    80001e0e:	c575                	beqz	a0,80001efa <fork+0x10e>
    80001e10:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e12:	04893603          	ld	a2,72(s2)
    80001e16:	692c                	ld	a1,80(a0)
    80001e18:	05093503          	ld	a0,80(s2)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	7fc080e7          	jalr	2044(ra) # 80001618 <uvmcopy>
    80001e24:	04054863          	bltz	a0,80001e74 <fork+0x88>
  np->sz = p->sz;
    80001e28:	04893783          	ld	a5,72(s2)
    80001e2c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e30:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e34:	05893683          	ld	a3,88(s2)
    80001e38:	87b6                	mv	a5,a3
    80001e3a:	0589b703          	ld	a4,88(s3)
    80001e3e:	12068693          	addi	a3,a3,288
    80001e42:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e46:	6788                	ld	a0,8(a5)
    80001e48:	6b8c                	ld	a1,16(a5)
    80001e4a:	6f90                	ld	a2,24(a5)
    80001e4c:	01073023          	sd	a6,0(a4)
    80001e50:	e708                	sd	a0,8(a4)
    80001e52:	eb0c                	sd	a1,16(a4)
    80001e54:	ef10                	sd	a2,24(a4)
    80001e56:	02078793          	addi	a5,a5,32
    80001e5a:	02070713          	addi	a4,a4,32
    80001e5e:	fed792e3          	bne	a5,a3,80001e42 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e62:	0589b783          	ld	a5,88(s3)
    80001e66:	0607b823          	sd	zero,112(a5)
    80001e6a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e6e:	15000a13          	li	s4,336
    80001e72:	a03d                	j	80001ea0 <fork+0xb4>
    freeproc(np);
    80001e74:	854e                	mv	a0,s3
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	d64080e7          	jalr	-668(ra) # 80001bda <freeproc>
    release(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e8e080e7          	jalr	-370(ra) # 80000d0e <release>
    return -1;
    80001e88:	54fd                	li	s1,-1
    80001e8a:	a8b9                	j	80001ee8 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	70e080e7          	jalr	1806(ra) # 8000459a <filedup>
    80001e94:	009987b3          	add	a5,s3,s1
    80001e98:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9a:	04a1                	addi	s1,s1,8
    80001e9c:	01448763          	beq	s1,s4,80001eaa <fork+0xbe>
    if(p->ofile[i])
    80001ea0:	009907b3          	add	a5,s2,s1
    80001ea4:	6388                	ld	a0,0(a5)
    80001ea6:	f17d                	bnez	a0,80001e8c <fork+0xa0>
    80001ea8:	bfcd                	j	80001e9a <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eaa:	15093503          	ld	a0,336(s2)
    80001eae:	00002097          	auipc	ra,0x2
    80001eb2:	872080e7          	jalr	-1934(ra) # 80003720 <idup>
    80001eb6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eba:	4641                	li	a2,16
    80001ebc:	15890593          	addi	a1,s2,344
    80001ec0:	15898513          	addi	a0,s3,344
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	fe8080e7          	jalr	-24(ra) # 80000eac <safestrcpy>
  np->syscall_trace = p->syscall_trace; // HERE!!! 子进程继承父进程的 syscall_trace
    80001ecc:	16893783          	ld	a5,360(s2)
    80001ed0:	16f9b423          	sd	a5,360(s3)
  pid = np->pid;
    80001ed4:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ed8:	4789                	li	a5,2
    80001eda:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	e2e080e7          	jalr	-466(ra) # 80000d0e <release>
}
    80001ee8:	8526                	mv	a0,s1
    80001eea:	70a2                	ld	ra,40(sp)
    80001eec:	7402                	ld	s0,32(sp)
    80001eee:	64e2                	ld	s1,24(sp)
    80001ef0:	6942                	ld	s2,16(sp)
    80001ef2:	69a2                	ld	s3,8(sp)
    80001ef4:	6a02                	ld	s4,0(sp)
    80001ef6:	6145                	addi	sp,sp,48
    80001ef8:	8082                	ret
    return -1;
    80001efa:	54fd                	li	s1,-1
    80001efc:	b7f5                	j	80001ee8 <fork+0xfc>

0000000080001efe <reparent>:
{
    80001efe:	7179                	addi	sp,sp,-48
    80001f00:	f406                	sd	ra,40(sp)
    80001f02:	f022                	sd	s0,32(sp)
    80001f04:	ec26                	sd	s1,24(sp)
    80001f06:	e84a                	sd	s2,16(sp)
    80001f08:	e44e                	sd	s3,8(sp)
    80001f0a:	e052                	sd	s4,0(sp)
    80001f0c:	1800                	addi	s0,sp,48
    80001f0e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f10:	00010497          	auipc	s1,0x10
    80001f14:	e5848493          	addi	s1,s1,-424 # 80011d68 <proc>
      pp->parent = initproc;
    80001f18:	00007a17          	auipc	s4,0x7
    80001f1c:	100a0a13          	addi	s4,s4,256 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f20:	00016997          	auipc	s3,0x16
    80001f24:	a4898993          	addi	s3,s3,-1464 # 80017968 <tickslock>
    80001f28:	a029                	j	80001f32 <reparent+0x34>
    80001f2a:	17048493          	addi	s1,s1,368
    80001f2e:	03348363          	beq	s1,s3,80001f54 <reparent+0x56>
    if(pp->parent == p){
    80001f32:	709c                	ld	a5,32(s1)
    80001f34:	ff279be3          	bne	a5,s2,80001f2a <reparent+0x2c>
      acquire(&pp->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d20080e7          	jalr	-736(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f42:	000a3783          	ld	a5,0(s4)
    80001f46:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	dc4080e7          	jalr	-572(ra) # 80000d0e <release>
    80001f52:	bfe1                	j	80001f2a <reparent+0x2c>
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6a02                	ld	s4,0(sp)
    80001f60:	6145                	addi	sp,sp,48
    80001f62:	8082                	ret

0000000080001f64 <scheduler>:
{
    80001f64:	715d                	addi	sp,sp,-80
    80001f66:	e486                	sd	ra,72(sp)
    80001f68:	e0a2                	sd	s0,64(sp)
    80001f6a:	fc26                	sd	s1,56(sp)
    80001f6c:	f84a                	sd	s2,48(sp)
    80001f6e:	f44e                	sd	s3,40(sp)
    80001f70:	f052                	sd	s4,32(sp)
    80001f72:	ec56                	sd	s5,24(sp)
    80001f74:	e85a                	sd	s6,16(sp)
    80001f76:	e45e                	sd	s7,8(sp)
    80001f78:	e062                	sd	s8,0(sp)
    80001f7a:	0880                	addi	s0,sp,80
    80001f7c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f80:	00779b13          	slli	s6,a5,0x7
    80001f84:	00010717          	auipc	a4,0x10
    80001f88:	9cc70713          	addi	a4,a4,-1588 # 80011950 <pid_lock>
    80001f8c:	975a                	add	a4,a4,s6
    80001f8e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f92:	00010717          	auipc	a4,0x10
    80001f96:	9de70713          	addi	a4,a4,-1570 # 80011970 <cpus+0x8>
    80001f9a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f9c:	4c0d                	li	s8,3
        c->proc = p;
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	00010a17          	auipc	s4,0x10
    80001fa4:	9b0a0a13          	addi	s4,s4,-1616 # 80011950 <pid_lock>
    80001fa8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	00016997          	auipc	s3,0x16
    80001fae:	9be98993          	addi	s3,s3,-1602 # 80017968 <tickslock>
        found = 1;
    80001fb2:	4b85                	li	s7,1
    80001fb4:	a899                	j	8000200a <scheduler+0xa6>
        p->state = RUNNING;
    80001fb6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fba:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fbe:	06048593          	addi	a1,s1,96
    80001fc2:	855a                	mv	a0,s6
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	666080e7          	jalr	1638(ra) # 8000262a <swtch>
        c->proc = 0;
    80001fcc:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fd0:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d3a080e7          	jalr	-710(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fdc:	17048493          	addi	s1,s1,368
    80001fe0:	01348b63          	beq	s1,s3,80001ff6 <scheduler+0x92>
      acquire(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	c74080e7          	jalr	-908(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff2791e3          	bne	a5,s2,80001fd2 <scheduler+0x6e>
    80001ff4:	b7c9                	j	80001fb6 <scheduler+0x52>
    if(found == 0) {
    80001ff6:	000a9a63          	bnez	s5,8000200a <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002002:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002006:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002012:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002016:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002018:	00010497          	auipc	s1,0x10
    8000201c:	d5048493          	addi	s1,s1,-688 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002020:	4909                	li	s2,2
    80002022:	b7c9                	j	80001fe4 <scheduler+0x80>

0000000080002024 <sched>:
{
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	9f6080e7          	jalr	-1546(ra) # 80001a28 <myproc>
    8000203a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	ba4080e7          	jalr	-1116(ra) # 80000be0 <holding>
    80002044:	c93d                	beqz	a0,800020ba <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002046:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	00010717          	auipc	a4,0x10
    80002050:	90470713          	addi	a4,a4,-1788 # 80011950 <pid_lock>
    80002054:	97ba                	add	a5,a5,a4
    80002056:	0907a703          	lw	a4,144(a5)
    8000205a:	4785                	li	a5,1
    8000205c:	06f71763          	bne	a4,a5,800020ca <sched+0xa6>
  if(p->state == RUNNING)
    80002060:	4c98                	lw	a4,24(s1)
    80002062:	478d                	li	a5,3
    80002064:	06f70b63          	beq	a4,a5,800020da <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002068:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000206c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000206e:	efb5                	bnez	a5,800020ea <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002070:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002072:	00010917          	auipc	s2,0x10
    80002076:	8de90913          	addi	s2,s2,-1826 # 80011950 <pid_lock>
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	0947a983          	lw	s3,148(a5)
    80002084:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	00010597          	auipc	a1,0x10
    8000208e:	8e658593          	addi	a1,a1,-1818 # 80011970 <cpus+0x8>
    80002092:	95be                	add	a1,a1,a5
    80002094:	06048513          	addi	a0,s1,96
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	592080e7          	jalr	1426(ra) # 8000262a <swtch>
    800020a0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a2:	2781                	sext.w	a5,a5
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	97ca                	add	a5,a5,s2
    800020a8:	0937aa23          	sw	s3,148(a5)
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret
    panic("sched p->lock");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	14650513          	addi	a0,a0,326 # 80008200 <digits+0x1c0>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	486080e7          	jalr	1158(ra) # 80000548 <panic>
    panic("sched locks");
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	14650513          	addi	a0,a0,326 # 80008210 <digits+0x1d0>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	476080e7          	jalr	1142(ra) # 80000548 <panic>
    panic("sched running");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	14650513          	addi	a0,a0,326 # 80008220 <digits+0x1e0>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	466080e7          	jalr	1126(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	14650513          	addi	a0,a0,326 # 80008230 <digits+0x1f0>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	456080e7          	jalr	1110(ra) # 80000548 <panic>

00000000800020fa <exit>:
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	e052                	sd	s4,0(sp)
    80002108:	1800                	addi	s0,sp,48
    8000210a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	91c080e7          	jalr	-1764(ra) # 80001a28 <myproc>
    80002114:	89aa                	mv	s3,a0
  if(p == initproc)
    80002116:	00007797          	auipc	a5,0x7
    8000211a:	f027b783          	ld	a5,-254(a5) # 80009018 <initproc>
    8000211e:	0d050493          	addi	s1,a0,208
    80002122:	15050913          	addi	s2,a0,336
    80002126:	02a79363          	bne	a5,a0,8000214c <exit+0x52>
    panic("init exiting");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	11e50513          	addi	a0,a0,286 # 80008248 <digits+0x208>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	416080e7          	jalr	1046(ra) # 80000548 <panic>
      fileclose(f);
    8000213a:	00002097          	auipc	ra,0x2
    8000213e:	4b2080e7          	jalr	1202(ra) # 800045ec <fileclose>
      p->ofile[fd] = 0;
    80002142:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002146:	04a1                	addi	s1,s1,8
    80002148:	01248563          	beq	s1,s2,80002152 <exit+0x58>
    if(p->ofile[fd]){
    8000214c:	6088                	ld	a0,0(s1)
    8000214e:	f575                	bnez	a0,8000213a <exit+0x40>
    80002150:	bfdd                	j	80002146 <exit+0x4c>
  begin_op();
    80002152:	00002097          	auipc	ra,0x2
    80002156:	fc8080e7          	jalr	-56(ra) # 8000411a <begin_op>
  iput(p->cwd);
    8000215a:	1509b503          	ld	a0,336(s3)
    8000215e:	00001097          	auipc	ra,0x1
    80002162:	7ba080e7          	jalr	1978(ra) # 80003918 <iput>
  end_op();
    80002166:	00002097          	auipc	ra,0x2
    8000216a:	034080e7          	jalr	52(ra) # 8000419a <end_op>
  p->cwd = 0;
    8000216e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002172:	00007497          	auipc	s1,0x7
    80002176:	ea648493          	addi	s1,s1,-346 # 80009018 <initproc>
    8000217a:	6088                	ld	a0,0(s1)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	ade080e7          	jalr	-1314(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002184:	6088                	ld	a0,0(s1)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	762080e7          	jalr	1890(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    8000218e:	6088                	ld	a0,0(s1)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b7e080e7          	jalr	-1154(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002198:	854e                	mv	a0,s3
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	ac0080e7          	jalr	-1344(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800021a2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a6:	854e                	mv	a0,s3
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	b66080e7          	jalr	-1178(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	aa8080e7          	jalr	-1368(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021ba:	854e                	mv	a0,s3
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a9e080e7          	jalr	-1378(ra) # 80000c5a <acquire>
  reparent(p);
    800021c4:	854e                	mv	a0,s3
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	d38080e7          	jalr	-712(ra) # 80001efe <reparent>
  wakeup1(original_parent);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	718080e7          	jalr	1816(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800021d8:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021dc:	4791                	li	a5,4
    800021de:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	b2a080e7          	jalr	-1238(ra) # 80000d0e <release>
  sched();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	e38080e7          	jalr	-456(ra) # 80002024 <sched>
  panic("zombie exit");
    800021f4:	00006517          	auipc	a0,0x6
    800021f8:	06450513          	addi	a0,a0,100 # 80008258 <digits+0x218>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080002204 <yield>:
{
    80002204:	1101                	addi	sp,sp,-32
    80002206:	ec06                	sd	ra,24(sp)
    80002208:	e822                	sd	s0,16(sp)
    8000220a:	e426                	sd	s1,8(sp)
    8000220c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	81a080e7          	jalr	-2022(ra) # 80001a28 <myproc>
    80002216:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a42080e7          	jalr	-1470(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002220:	4789                	li	a5,2
    80002222:	cc9c                	sw	a5,24(s1)
  sched();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	e00080e7          	jalr	-512(ra) # 80002024 <sched>
  release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	ae0080e7          	jalr	-1312(ra) # 80000d0e <release>
}
    80002236:	60e2                	ld	ra,24(sp)
    80002238:	6442                	ld	s0,16(sp)
    8000223a:	64a2                	ld	s1,8(sp)
    8000223c:	6105                	addi	sp,sp,32
    8000223e:	8082                	ret

0000000080002240 <sleep>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
    8000224e:	89aa                	mv	s3,a0
    80002250:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	7d6080e7          	jalr	2006(ra) # 80001a28 <myproc>
    8000225a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000225c:	05250663          	beq	a0,s2,800022a8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	9fa080e7          	jalr	-1542(ra) # 80000c5a <acquire>
    release(lk);
    80002268:	854a                	mv	a0,s2
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	aa4080e7          	jalr	-1372(ra) # 80000d0e <release>
  p->chan = chan;
    80002272:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002276:	4785                	li	a5,1
    80002278:	cc9c                	sw	a5,24(s1)
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	daa080e7          	jalr	-598(ra) # 80002024 <sched>
  p->chan = 0;
    80002282:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a86080e7          	jalr	-1402(ra) # 80000d0e <release>
    acquire(lk);
    80002290:	854a                	mv	a0,s2
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9c8080e7          	jalr	-1592(ra) # 80000c5a <acquire>
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6145                	addi	sp,sp,48
    800022a6:	8082                	ret
  p->chan = chan;
    800022a8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ac:	4785                	li	a5,1
    800022ae:	cd1c                	sw	a5,24(a0)
  sched();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	d74080e7          	jalr	-652(ra) # 80002024 <sched>
  p->chan = 0;
    800022b8:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022bc:	bff9                	j	8000229a <sleep+0x5a>

00000000800022be <wait>:
{
    800022be:	715d                	addi	sp,sp,-80
    800022c0:	e486                	sd	ra,72(sp)
    800022c2:	e0a2                	sd	s0,64(sp)
    800022c4:	fc26                	sd	s1,56(sp)
    800022c6:	f84a                	sd	s2,48(sp)
    800022c8:	f44e                	sd	s3,40(sp)
    800022ca:	f052                	sd	s4,32(sp)
    800022cc:	ec56                	sd	s5,24(sp)
    800022ce:	e85a                	sd	s6,16(sp)
    800022d0:	e45e                	sd	s7,8(sp)
    800022d2:	e062                	sd	s8,0(sp)
    800022d4:	0880                	addi	s0,sp,80
    800022d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	750080e7          	jalr	1872(ra) # 80001a28 <myproc>
    800022e0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e2:	8c2a                	mv	s8,a0
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	976080e7          	jalr	-1674(ra) # 80000c5a <acquire>
    havekids = 0;
    800022ec:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ee:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	67898993          	addi	s3,s3,1656 # 80017968 <tickslock>
        havekids = 1;
    800022f8:	4a85                	li	s5,1
    havekids = 0;
    800022fa:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fc:	00010497          	auipc	s1,0x10
    80002300:	a6c48493          	addi	s1,s1,-1428 # 80011d68 <proc>
    80002304:	a08d                	j	80002366 <wait+0xa8>
          pid = np->pid;
    80002306:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000230a:	000b0e63          	beqz	s6,80002326 <wait+0x68>
    8000230e:	4691                	li	a3,4
    80002310:	03448613          	addi	a2,s1,52
    80002314:	85da                	mv	a1,s6
    80002316:	05093503          	ld	a0,80(s2)
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	402080e7          	jalr	1026(ra) # 8000171c <copyout>
    80002322:	02054263          	bltz	a0,80002346 <wait+0x88>
          freeproc(np);
    80002326:	8526                	mv	a0,s1
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	8b2080e7          	jalr	-1870(ra) # 80001bda <freeproc>
          release(&np->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	9dc080e7          	jalr	-1572(ra) # 80000d0e <release>
          release(&p->lock);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	9d2080e7          	jalr	-1582(ra) # 80000d0e <release>
          return pid;
    80002344:	a8a9                	j	8000239e <wait+0xe0>
            release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	9c6080e7          	jalr	-1594(ra) # 80000d0e <release>
            release(&p->lock);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	9bc080e7          	jalr	-1604(ra) # 80000d0e <release>
            return -1;
    8000235a:	59fd                	li	s3,-1
    8000235c:	a089                	j	8000239e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235e:	17048493          	addi	s1,s1,368
    80002362:	03348463          	beq	s1,s3,8000238a <wait+0xcc>
      if(np->parent == p){
    80002366:	709c                	ld	a5,32(s1)
    80002368:	ff279be3          	bne	a5,s2,8000235e <wait+0xa0>
        acquire(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	8ec080e7          	jalr	-1812(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002376:	4c9c                	lw	a5,24(s1)
    80002378:	f94787e3          	beq	a5,s4,80002306 <wait+0x48>
        release(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	990080e7          	jalr	-1648(ra) # 80000d0e <release>
        havekids = 1;
    80002386:	8756                	mv	a4,s5
    80002388:	bfd9                	j	8000235e <wait+0xa0>
    if(!havekids || p->killed){
    8000238a:	c701                	beqz	a4,80002392 <wait+0xd4>
    8000238c:	03092783          	lw	a5,48(s2)
    80002390:	c785                	beqz	a5,800023b8 <wait+0xfa>
      release(&p->lock);
    80002392:	854a                	mv	a0,s2
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	97a080e7          	jalr	-1670(ra) # 80000d0e <release>
      return -1;
    8000239c:	59fd                	li	s3,-1
}
    8000239e:	854e                	mv	a0,s3
    800023a0:	60a6                	ld	ra,72(sp)
    800023a2:	6406                	ld	s0,64(sp)
    800023a4:	74e2                	ld	s1,56(sp)
    800023a6:	7942                	ld	s2,48(sp)
    800023a8:	79a2                	ld	s3,40(sp)
    800023aa:	7a02                	ld	s4,32(sp)
    800023ac:	6ae2                	ld	s5,24(sp)
    800023ae:	6b42                	ld	s6,16(sp)
    800023b0:	6ba2                	ld	s7,8(sp)
    800023b2:	6c02                	ld	s8,0(sp)
    800023b4:	6161                	addi	sp,sp,80
    800023b6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b8:	85e2                	mv	a1,s8
    800023ba:	854a                	mv	a0,s2
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e84080e7          	jalr	-380(ra) # 80002240 <sleep>
    havekids = 0;
    800023c4:	bf1d                	j	800022fa <wait+0x3c>

00000000800023c6 <wakeup>:
{
    800023c6:	7139                	addi	sp,sp,-64
    800023c8:	fc06                	sd	ra,56(sp)
    800023ca:	f822                	sd	s0,48(sp)
    800023cc:	f426                	sd	s1,40(sp)
    800023ce:	f04a                	sd	s2,32(sp)
    800023d0:	ec4e                	sd	s3,24(sp)
    800023d2:	e852                	sd	s4,16(sp)
    800023d4:	e456                	sd	s5,8(sp)
    800023d6:	0080                	addi	s0,sp,64
    800023d8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023da:	00010497          	auipc	s1,0x10
    800023de:	98e48493          	addi	s1,s1,-1650 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	00015917          	auipc	s2,0x15
    800023ea:	58290913          	addi	s2,s2,1410 # 80017968 <tickslock>
    800023ee:	a821                	j	80002406 <wakeup+0x40>
      p->state = RUNNABLE;
    800023f0:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	918080e7          	jalr	-1768(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fe:	17048493          	addi	s1,s1,368
    80002402:	01248e63          	beq	s1,s2,8000241e <wakeup+0x58>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	852080e7          	jalr	-1966(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002410:	4c9c                	lw	a5,24(s1)
    80002412:	ff3791e3          	bne	a5,s3,800023f4 <wakeup+0x2e>
    80002416:	749c                	ld	a5,40(s1)
    80002418:	fd479ee3          	bne	a5,s4,800023f4 <wakeup+0x2e>
    8000241c:	bfd1                	j	800023f0 <wakeup+0x2a>
}
    8000241e:	70e2                	ld	ra,56(sp)
    80002420:	7442                	ld	s0,48(sp)
    80002422:	74a2                	ld	s1,40(sp)
    80002424:	7902                	ld	s2,32(sp)
    80002426:	69e2                	ld	s3,24(sp)
    80002428:	6a42                	ld	s4,16(sp)
    8000242a:	6aa2                	ld	s5,8(sp)
    8000242c:	6121                	addi	sp,sp,64
    8000242e:	8082                	ret

0000000080002430 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002430:	7179                	addi	sp,sp,-48
    80002432:	f406                	sd	ra,40(sp)
    80002434:	f022                	sd	s0,32(sp)
    80002436:	ec26                	sd	s1,24(sp)
    80002438:	e84a                	sd	s2,16(sp)
    8000243a:	e44e                	sd	s3,8(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002440:	00010497          	auipc	s1,0x10
    80002444:	92848493          	addi	s1,s1,-1752 # 80011d68 <proc>
    80002448:	00015997          	auipc	s3,0x15
    8000244c:	52098993          	addi	s3,s3,1312 # 80017968 <tickslock>
    acquire(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	808080e7          	jalr	-2040(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    8000245a:	5c9c                	lw	a5,56(s1)
    8000245c:	01278d63          	beq	a5,s2,80002476 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	8ac080e7          	jalr	-1876(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246a:	17048493          	addi	s1,s1,368
    8000246e:	ff3491e3          	bne	s1,s3,80002450 <kill+0x20>
  }
  return -1;
    80002472:	557d                	li	a0,-1
    80002474:	a829                	j	8000248e <kill+0x5e>
      p->killed = 1;
    80002476:	4785                	li	a5,1
    80002478:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000247a:	4c98                	lw	a4,24(s1)
    8000247c:	4785                	li	a5,1
    8000247e:	00f70f63          	beq	a4,a5,8000249c <kill+0x6c>
      release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	88a080e7          	jalr	-1910(ra) # 80000d0e <release>
      return 0;
    8000248c:	4501                	li	a0,0
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret
        p->state = RUNNABLE;
    8000249c:	4789                	li	a5,2
    8000249e:	cc9c                	sw	a5,24(s1)
    800024a0:	b7cd                	j	80002482 <kill+0x52>

00000000800024a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	84aa                	mv	s1,a0
    800024b4:	892e                	mv	s2,a1
    800024b6:	89b2                	mv	s3,a2
    800024b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	56e080e7          	jalr	1390(ra) # 80001a28 <myproc>
  if(user_dst){
    800024c2:	c08d                	beqz	s1,800024e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c4:	86d2                	mv	a3,s4
    800024c6:	864e                	mv	a2,s3
    800024c8:	85ca                	mv	a1,s2
    800024ca:	6928                	ld	a0,80(a0)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	250080e7          	jalr	592(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d4:	70a2                	ld	ra,40(sp)
    800024d6:	7402                	ld	s0,32(sp)
    800024d8:	64e2                	ld	s1,24(sp)
    800024da:	6942                	ld	s2,16(sp)
    800024dc:	69a2                	ld	s3,8(sp)
    800024de:	6a02                	ld	s4,0(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
    memmove((char *)dst, src, len);
    800024e4:	000a061b          	sext.w	a2,s4
    800024e8:	85ce                	mv	a1,s3
    800024ea:	854a                	mv	a0,s2
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	8ca080e7          	jalr	-1846(ra) # 80000db6 <memmove>
    return 0;
    800024f4:	8526                	mv	a0,s1
    800024f6:	bff9                	j	800024d4 <either_copyout+0x32>

00000000800024f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
    8000250a:	84ae                	mv	s1,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	518080e7          	jalr	1304(ra) # 80001a28 <myproc>
  if(user_src){
    80002518:	c08d                	beqz	s1,8000253a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000251a:	86d2                	mv	a3,s4
    8000251c:	864e                	mv	a2,s3
    8000251e:	85ca                	mv	a1,s2
    80002520:	6928                	ld	a0,80(a0)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	286080e7          	jalr	646(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    memmove(dst, (char*)src, len);
    8000253a:	000a061b          	sext.w	a2,s4
    8000253e:	85ce                	mv	a1,s3
    80002540:	854a                	mv	a0,s2
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	874080e7          	jalr	-1932(ra) # 80000db6 <memmove>
    return 0;
    8000254a:	8526                	mv	a0,s1
    8000254c:	bff9                	j	8000252a <either_copyin+0x32>

000000008000254e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000254e:	715d                	addi	sp,sp,-80
    80002550:	e486                	sd	ra,72(sp)
    80002552:	e0a2                	sd	s0,64(sp)
    80002554:	fc26                	sd	s1,56(sp)
    80002556:	f84a                	sd	s2,48(sp)
    80002558:	f44e                	sd	s3,40(sp)
    8000255a:	f052                	sd	s4,32(sp)
    8000255c:	ec56                	sd	s5,24(sp)
    8000255e:	e85a                	sd	s6,16(sp)
    80002560:	e45e                	sd	s7,8(sp)
    80002562:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002564:	00006517          	auipc	a0,0x6
    80002568:	b6450513          	addi	a0,a0,-1180 # 800080c8 <digits+0x88>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	026080e7          	jalr	38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002574:	00010497          	auipc	s1,0x10
    80002578:	94c48493          	addi	s1,s1,-1716 # 80011ec0 <proc+0x158>
    8000257c:	00015917          	auipc	s2,0x15
    80002580:	54490913          	addi	s2,s2,1348 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002586:	00006997          	auipc	s3,0x6
    8000258a:	ce298993          	addi	s3,s3,-798 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000258e:	00006a97          	auipc	s5,0x6
    80002592:	ce2a8a93          	addi	s5,s5,-798 # 80008270 <digits+0x230>
    printf("\n");
    80002596:	00006a17          	auipc	s4,0x6
    8000259a:	b32a0a13          	addi	s4,s4,-1230 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	00006b97          	auipc	s7,0x6
    800025a2:	d0ab8b93          	addi	s7,s7,-758 # 800082a8 <states.1707>
    800025a6:	a00d                	j	800025c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a8:	ee06a583          	lw	a1,-288(a3)
    800025ac:	8556                	mv	a0,s5
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	fe4080e7          	jalr	-28(ra) # 80000592 <printf>
    printf("\n");
    800025b6:	8552                	mv	a0,s4
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	fda080e7          	jalr	-38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c0:	17048493          	addi	s1,s1,368
    800025c4:	03248163          	beq	s1,s2,800025e6 <procdump+0x98>
    if(p->state == UNUSED)
    800025c8:	86a6                	mv	a3,s1
    800025ca:	ec04a783          	lw	a5,-320(s1)
    800025ce:	dbed                	beqz	a5,800025c0 <procdump+0x72>
      state = "???";
    800025d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d2:	fcfb6be3          	bltu	s6,a5,800025a8 <procdump+0x5a>
    800025d6:	1782                	slli	a5,a5,0x20
    800025d8:	9381                	srli	a5,a5,0x20
    800025da:	078e                	slli	a5,a5,0x3
    800025dc:	97de                	add	a5,a5,s7
    800025de:	6390                	ld	a2,0(a5)
    800025e0:	f661                	bnez	a2,800025a8 <procdump+0x5a>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    800025e4:	b7d1                	j	800025a8 <procdump+0x5a>
  }
}
    800025e6:	60a6                	ld	ra,72(sp)
    800025e8:	6406                	ld	s0,64(sp)
    800025ea:	74e2                	ld	s1,56(sp)
    800025ec:	7942                	ld	s2,48(sp)
    800025ee:	79a2                	ld	s3,40(sp)
    800025f0:	7a02                	ld	s4,32(sp)
    800025f2:	6ae2                	ld	s5,24(sp)
    800025f4:	6b42                	ld	s6,16(sp)
    800025f6:	6ba2                	ld	s7,8(sp)
    800025f8:	6161                	addi	sp,sp,80
    800025fa:	8082                	ret

00000000800025fc <count_process>:

uint64
count_process(void) { // added function for counting used process slots (lab2)
    800025fc:	1141                	addi	sp,sp,-16
    800025fe:	e422                	sd	s0,8(sp)
    80002600:	0800                	addi	s0,sp,16
  uint64 cnt = 0;
  for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002602:	0000f797          	auipc	a5,0xf
    80002606:	76678793          	addi	a5,a5,1894 # 80011d68 <proc>
  uint64 cnt = 0;
    8000260a:	4501                	li	a0,0
  for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    8000260c:	00015697          	auipc	a3,0x15
    80002610:	35c68693          	addi	a3,a3,860 # 80017968 <tickslock>
    // acquire(&p->lock);
    // 不需要锁进程 proc 结构，因为我们只需要读取进程列表，不需要写
    if(p->state != UNUSED) { // 不是 UNUSED 的进程位，就是已经分配的
    80002614:	4f98                	lw	a4,24(a5)
        cnt++;
    80002616:	00e03733          	snez	a4,a4
    8000261a:	953a                	add	a0,a0,a4
  for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    8000261c:	17078793          	addi	a5,a5,368
    80002620:	fed79ae3          	bne	a5,a3,80002614 <count_process+0x18>
    }
  }
  return cnt;
    80002624:	6422                	ld	s0,8(sp)
    80002626:	0141                	addi	sp,sp,16
    80002628:	8082                	ret

000000008000262a <swtch>:
    8000262a:	00153023          	sd	ra,0(a0)
    8000262e:	00253423          	sd	sp,8(a0)
    80002632:	e900                	sd	s0,16(a0)
    80002634:	ed04                	sd	s1,24(a0)
    80002636:	03253023          	sd	s2,32(a0)
    8000263a:	03353423          	sd	s3,40(a0)
    8000263e:	03453823          	sd	s4,48(a0)
    80002642:	03553c23          	sd	s5,56(a0)
    80002646:	05653023          	sd	s6,64(a0)
    8000264a:	05753423          	sd	s7,72(a0)
    8000264e:	05853823          	sd	s8,80(a0)
    80002652:	05953c23          	sd	s9,88(a0)
    80002656:	07a53023          	sd	s10,96(a0)
    8000265a:	07b53423          	sd	s11,104(a0)
    8000265e:	0005b083          	ld	ra,0(a1)
    80002662:	0085b103          	ld	sp,8(a1)
    80002666:	6980                	ld	s0,16(a1)
    80002668:	6d84                	ld	s1,24(a1)
    8000266a:	0205b903          	ld	s2,32(a1)
    8000266e:	0285b983          	ld	s3,40(a1)
    80002672:	0305ba03          	ld	s4,48(a1)
    80002676:	0385ba83          	ld	s5,56(a1)
    8000267a:	0405bb03          	ld	s6,64(a1)
    8000267e:	0485bb83          	ld	s7,72(a1)
    80002682:	0505bc03          	ld	s8,80(a1)
    80002686:	0585bc83          	ld	s9,88(a1)
    8000268a:	0605bd03          	ld	s10,96(a1)
    8000268e:	0685bd83          	ld	s11,104(a1)
    80002692:	8082                	ret

0000000080002694 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e406                	sd	ra,8(sp)
    80002698:	e022                	sd	s0,0(sp)
    8000269a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000269c:	00006597          	auipc	a1,0x6
    800026a0:	c3458593          	addi	a1,a1,-972 # 800082d0 <states.1707+0x28>
    800026a4:	00015517          	auipc	a0,0x15
    800026a8:	2c450513          	addi	a0,a0,708 # 80017968 <tickslock>
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	51e080e7          	jalr	1310(ra) # 80000bca <initlock>
}
    800026b4:	60a2                	ld	ra,8(sp)
    800026b6:	6402                	ld	s0,0(sp)
    800026b8:	0141                	addi	sp,sp,16
    800026ba:	8082                	ret

00000000800026bc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026bc:	1141                	addi	sp,sp,-16
    800026be:	e422                	sd	s0,8(sp)
    800026c0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026c2:	00003797          	auipc	a5,0x3
    800026c6:	58e78793          	addi	a5,a5,1422 # 80005c50 <kernelvec>
    800026ca:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ce:	6422                	ld	s0,8(sp)
    800026d0:	0141                	addi	sp,sp,16
    800026d2:	8082                	ret

00000000800026d4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026d4:	1141                	addi	sp,sp,-16
    800026d6:	e406                	sd	ra,8(sp)
    800026d8:	e022                	sd	s0,0(sp)
    800026da:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	34c080e7          	jalr	844(ra) # 80001a28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ea:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ee:	00005617          	auipc	a2,0x5
    800026f2:	91260613          	addi	a2,a2,-1774 # 80007000 <_trampoline>
    800026f6:	00005697          	auipc	a3,0x5
    800026fa:	90a68693          	addi	a3,a3,-1782 # 80007000 <_trampoline>
    800026fe:	8e91                	sub	a3,a3,a2
    80002700:	040007b7          	lui	a5,0x4000
    80002704:	17fd                	addi	a5,a5,-1
    80002706:	07b2                	slli	a5,a5,0xc
    80002708:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000270a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000270e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002710:	180026f3          	csrr	a3,satp
    80002714:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002716:	6d38                	ld	a4,88(a0)
    80002718:	6134                	ld	a3,64(a0)
    8000271a:	6585                	lui	a1,0x1
    8000271c:	96ae                	add	a3,a3,a1
    8000271e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002720:	6d38                	ld	a4,88(a0)
    80002722:	00000697          	auipc	a3,0x0
    80002726:	13868693          	addi	a3,a3,312 # 8000285a <usertrap>
    8000272a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000272c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000272e:	8692                	mv	a3,tp
    80002730:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002732:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002736:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000273a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000273e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002744:	6f18                	ld	a4,24(a4)
    80002746:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000274a:	692c                	ld	a1,80(a0)
    8000274c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000274e:	00005717          	auipc	a4,0x5
    80002752:	94270713          	addi	a4,a4,-1726 # 80007090 <userret>
    80002756:	8f11                	sub	a4,a4,a2
    80002758:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000275a:	577d                	li	a4,-1
    8000275c:	177e                	slli	a4,a4,0x3f
    8000275e:	8dd9                	or	a1,a1,a4
    80002760:	02000537          	lui	a0,0x2000
    80002764:	157d                	addi	a0,a0,-1
    80002766:	0536                	slli	a0,a0,0xd
    80002768:	9782                	jalr	a5
}
    8000276a:	60a2                	ld	ra,8(sp)
    8000276c:	6402                	ld	s0,0(sp)
    8000276e:	0141                	addi	sp,sp,16
    80002770:	8082                	ret

0000000080002772 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000277c:	00015497          	auipc	s1,0x15
    80002780:	1ec48493          	addi	s1,s1,492 # 80017968 <tickslock>
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	4d4080e7          	jalr	1236(ra) # 80000c5a <acquire>
  ticks++;
    8000278e:	00007517          	auipc	a0,0x7
    80002792:	89250513          	addi	a0,a0,-1902 # 80009020 <ticks>
    80002796:	411c                	lw	a5,0(a0)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	c2a080e7          	jalr	-982(ra) # 800023c6 <wakeup>
  release(&tickslock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	568080e7          	jalr	1384(ra) # 80000d0e <release>
}
    800027ae:	60e2                	ld	ra,24(sp)
    800027b0:	6442                	ld	s0,16(sp)
    800027b2:	64a2                	ld	s1,8(sp)
    800027b4:	6105                	addi	sp,sp,32
    800027b6:	8082                	ret

00000000800027b8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027b8:	1101                	addi	sp,sp,-32
    800027ba:	ec06                	sd	ra,24(sp)
    800027bc:	e822                	sd	s0,16(sp)
    800027be:	e426                	sd	s1,8(sp)
    800027c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027c6:	00074d63          	bltz	a4,800027e0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ca:	57fd                	li	a5,-1
    800027cc:	17fe                	slli	a5,a5,0x3f
    800027ce:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027d0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027d2:	06f70363          	beq	a4,a5,80002838 <devintr+0x80>
  }
}
    800027d6:	60e2                	ld	ra,24(sp)
    800027d8:	6442                	ld	s0,16(sp)
    800027da:	64a2                	ld	s1,8(sp)
    800027dc:	6105                	addi	sp,sp,32
    800027de:	8082                	ret
     (scause & 0xff) == 9){
    800027e0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027e4:	46a5                	li	a3,9
    800027e6:	fed792e3          	bne	a5,a3,800027ca <devintr+0x12>
    int irq = plic_claim();
    800027ea:	00003097          	auipc	ra,0x3
    800027ee:	56e080e7          	jalr	1390(ra) # 80005d58 <plic_claim>
    800027f2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027f4:	47a9                	li	a5,10
    800027f6:	02f50763          	beq	a0,a5,80002824 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027fa:	4785                	li	a5,1
    800027fc:	02f50963          	beq	a0,a5,8000282e <devintr+0x76>
    return 1;
    80002800:	4505                	li	a0,1
    } else if(irq){
    80002802:	d8f1                	beqz	s1,800027d6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002804:	85a6                	mv	a1,s1
    80002806:	00006517          	auipc	a0,0x6
    8000280a:	ad250513          	addi	a0,a0,-1326 # 800082d8 <states.1707+0x30>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d84080e7          	jalr	-636(ra) # 80000592 <printf>
      plic_complete(irq);
    80002816:	8526                	mv	a0,s1
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	564080e7          	jalr	1380(ra) # 80005d7c <plic_complete>
    return 1;
    80002820:	4505                	li	a0,1
    80002822:	bf55                	j	800027d6 <devintr+0x1e>
      uartintr();
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	1b0080e7          	jalr	432(ra) # 800009d4 <uartintr>
    8000282c:	b7ed                	j	80002816 <devintr+0x5e>
      virtio_disk_intr();
    8000282e:	00004097          	auipc	ra,0x4
    80002832:	9e8080e7          	jalr	-1560(ra) # 80006216 <virtio_disk_intr>
    80002836:	b7c5                	j	80002816 <devintr+0x5e>
    if(cpuid() == 0){
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	1c4080e7          	jalr	452(ra) # 800019fc <cpuid>
    80002840:	c901                	beqz	a0,80002850 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002842:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002846:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002848:	14479073          	csrw	sip,a5
    return 2;
    8000284c:	4509                	li	a0,2
    8000284e:	b761                	j	800027d6 <devintr+0x1e>
      clockintr();
    80002850:	00000097          	auipc	ra,0x0
    80002854:	f22080e7          	jalr	-222(ra) # 80002772 <clockintr>
    80002858:	b7ed                	j	80002842 <devintr+0x8a>

000000008000285a <usertrap>:
{
    8000285a:	1101                	addi	sp,sp,-32
    8000285c:	ec06                	sd	ra,24(sp)
    8000285e:	e822                	sd	s0,16(sp)
    80002860:	e426                	sd	s1,8(sp)
    80002862:	e04a                	sd	s2,0(sp)
    80002864:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002866:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000286a:	1007f793          	andi	a5,a5,256
    8000286e:	e3ad                	bnez	a5,800028d0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002870:	00003797          	auipc	a5,0x3
    80002874:	3e078793          	addi	a5,a5,992 # 80005c50 <kernelvec>
    80002878:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000287c:	fffff097          	auipc	ra,0xfffff
    80002880:	1ac080e7          	jalr	428(ra) # 80001a28 <myproc>
    80002884:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002886:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002888:	14102773          	csrr	a4,sepc
    8000288c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002892:	47a1                	li	a5,8
    80002894:	04f71c63          	bne	a4,a5,800028ec <usertrap+0x92>
    if(p->killed)
    80002898:	591c                	lw	a5,48(a0)
    8000289a:	e3b9                	bnez	a5,800028e0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000289c:	6cb8                	ld	a4,88(s1)
    8000289e:	6f1c                	ld	a5,24(a4)
    800028a0:	0791                	addi	a5,a5,4
    800028a2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ac:	10079073          	csrw	sstatus,a5
    syscall();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	2e0080e7          	jalr	736(ra) # 80002b90 <syscall>
  if(p->killed)
    800028b8:	589c                	lw	a5,48(s1)
    800028ba:	ebc1                	bnez	a5,8000294a <usertrap+0xf0>
  usertrapret();
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	e18080e7          	jalr	-488(ra) # 800026d4 <usertrapret>
}
    800028c4:	60e2                	ld	ra,24(sp)
    800028c6:	6442                	ld	s0,16(sp)
    800028c8:	64a2                	ld	s1,8(sp)
    800028ca:	6902                	ld	s2,0(sp)
    800028cc:	6105                	addi	sp,sp,32
    800028ce:	8082                	ret
    panic("usertrap: not from user mode");
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	a2850513          	addi	a0,a0,-1496 # 800082f8 <states.1707+0x50>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	c70080e7          	jalr	-912(ra) # 80000548 <panic>
      exit(-1);
    800028e0:	557d                	li	a0,-1
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	818080e7          	jalr	-2024(ra) # 800020fa <exit>
    800028ea:	bf4d                	j	8000289c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	ecc080e7          	jalr	-308(ra) # 800027b8 <devintr>
    800028f4:	892a                	mv	s2,a0
    800028f6:	c501                	beqz	a0,800028fe <usertrap+0xa4>
  if(p->killed)
    800028f8:	589c                	lw	a5,48(s1)
    800028fa:	c3a1                	beqz	a5,8000293a <usertrap+0xe0>
    800028fc:	a815                	j	80002930 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002902:	5c90                	lw	a2,56(s1)
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a1450513          	addi	a0,a0,-1516 # 80008318 <states.1707+0x70>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c86080e7          	jalr	-890(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002914:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002918:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a2c50513          	addi	a0,a0,-1492 # 80008348 <states.1707+0xa0>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c6e080e7          	jalr	-914(ra) # 80000592 <printf>
    p->killed = 1;
    8000292c:	4785                	li	a5,1
    8000292e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002930:	557d                	li	a0,-1
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	7c8080e7          	jalr	1992(ra) # 800020fa <exit>
  if(which_dev == 2)
    8000293a:	4789                	li	a5,2
    8000293c:	f8f910e3          	bne	s2,a5,800028bc <usertrap+0x62>
    yield();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	8c4080e7          	jalr	-1852(ra) # 80002204 <yield>
    80002948:	bf95                	j	800028bc <usertrap+0x62>
  int which_dev = 0;
    8000294a:	4901                	li	s2,0
    8000294c:	b7d5                	j	80002930 <usertrap+0xd6>

000000008000294e <kerneltrap>:
{
    8000294e:	7179                	addi	sp,sp,-48
    80002950:	f406                	sd	ra,40(sp)
    80002952:	f022                	sd	s0,32(sp)
    80002954:	ec26                	sd	s1,24(sp)
    80002956:	e84a                	sd	s2,16(sp)
    80002958:	e44e                	sd	s3,8(sp)
    8000295a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002960:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002964:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002968:	1004f793          	andi	a5,s1,256
    8000296c:	cb85                	beqz	a5,8000299c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002972:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002974:	ef85                	bnez	a5,800029ac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	e42080e7          	jalr	-446(ra) # 800027b8 <devintr>
    8000297e:	cd1d                	beqz	a0,800029bc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002980:	4789                	li	a5,2
    80002982:	06f50a63          	beq	a0,a5,800029f6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002986:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000298a:	10049073          	csrw	sstatus,s1
}
    8000298e:	70a2                	ld	ra,40(sp)
    80002990:	7402                	ld	s0,32(sp)
    80002992:	64e2                	ld	s1,24(sp)
    80002994:	6942                	ld	s2,16(sp)
    80002996:	69a2                	ld	s3,8(sp)
    80002998:	6145                	addi	sp,sp,48
    8000299a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	9cc50513          	addi	a0,a0,-1588 # 80008368 <states.1707+0xc0>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	ba4080e7          	jalr	-1116(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	9e450513          	addi	a0,a0,-1564 # 80008390 <states.1707+0xe8>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	b94080e7          	jalr	-1132(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    800029bc:	85ce                	mv	a1,s3
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	9f250513          	addi	a0,a0,-1550 # 800083b0 <states.1707+0x108>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	bcc080e7          	jalr	-1076(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d6:	00006517          	auipc	a0,0x6
    800029da:	9ea50513          	addi	a0,a0,-1558 # 800083c0 <states.1707+0x118>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	bb4080e7          	jalr	-1100(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029e6:	00006517          	auipc	a0,0x6
    800029ea:	9f250513          	addi	a0,a0,-1550 # 800083d8 <states.1707+0x130>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b5a080e7          	jalr	-1190(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	032080e7          	jalr	50(ra) # 80001a28 <myproc>
    800029fe:	d541                	beqz	a0,80002986 <kerneltrap+0x38>
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	028080e7          	jalr	40(ra) # 80001a28 <myproc>
    80002a08:	4d18                	lw	a4,24(a0)
    80002a0a:	478d                	li	a5,3
    80002a0c:	f6f71de3          	bne	a4,a5,80002986 <kerneltrap+0x38>
    yield();
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	7f4080e7          	jalr	2036(ra) # 80002204 <yield>
    80002a18:	b7bd                	j	80002986 <kerneltrap+0x38>

0000000080002a1a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	1000                	addi	s0,sp,32
    80002a24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	002080e7          	jalr	2(ra) # 80001a28 <myproc>
  switch (n) {
    80002a2e:	4795                	li	a5,5
    80002a30:	0497e163          	bltu	a5,s1,80002a72 <argraw+0x58>
    80002a34:	048a                	slli	s1,s1,0x2
    80002a36:	00006717          	auipc	a4,0x6
    80002a3a:	aaa70713          	addi	a4,a4,-1366 # 800084e0 <states.1707+0x238>
    80002a3e:	94ba                	add	s1,s1,a4
    80002a40:	409c                	lw	a5,0(s1)
    80002a42:	97ba                	add	a5,a5,a4
    80002a44:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a46:	6d3c                	ld	a5,88(a0)
    80002a48:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a4a:	60e2                	ld	ra,24(sp)
    80002a4c:	6442                	ld	s0,16(sp)
    80002a4e:	64a2                	ld	s1,8(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret
    return p->trapframe->a1;
    80002a54:	6d3c                	ld	a5,88(a0)
    80002a56:	7fa8                	ld	a0,120(a5)
    80002a58:	bfcd                	j	80002a4a <argraw+0x30>
    return p->trapframe->a2;
    80002a5a:	6d3c                	ld	a5,88(a0)
    80002a5c:	63c8                	ld	a0,128(a5)
    80002a5e:	b7f5                	j	80002a4a <argraw+0x30>
    return p->trapframe->a3;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	67c8                	ld	a0,136(a5)
    80002a64:	b7dd                	j	80002a4a <argraw+0x30>
    return p->trapframe->a4;
    80002a66:	6d3c                	ld	a5,88(a0)
    80002a68:	6bc8                	ld	a0,144(a5)
    80002a6a:	b7c5                	j	80002a4a <argraw+0x30>
    return p->trapframe->a5;
    80002a6c:	6d3c                	ld	a5,88(a0)
    80002a6e:	6fc8                	ld	a0,152(a5)
    80002a70:	bfe9                	j	80002a4a <argraw+0x30>
  panic("argraw");
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	97650513          	addi	a0,a0,-1674 # 800083e8 <states.1707+0x140>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	ace080e7          	jalr	-1330(ra) # 80000548 <panic>

0000000080002a82 <fetchaddr>:
{
    80002a82:	1101                	addi	sp,sp,-32
    80002a84:	ec06                	sd	ra,24(sp)
    80002a86:	e822                	sd	s0,16(sp)
    80002a88:	e426                	sd	s1,8(sp)
    80002a8a:	e04a                	sd	s2,0(sp)
    80002a8c:	1000                	addi	s0,sp,32
    80002a8e:	84aa                	mv	s1,a0
    80002a90:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	f96080e7          	jalr	-106(ra) # 80001a28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a9a:	653c                	ld	a5,72(a0)
    80002a9c:	02f4f863          	bgeu	s1,a5,80002acc <fetchaddr+0x4a>
    80002aa0:	00848713          	addi	a4,s1,8
    80002aa4:	02e7e663          	bltu	a5,a4,80002ad0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aa8:	46a1                	li	a3,8
    80002aaa:	8626                	mv	a2,s1
    80002aac:	85ca                	mv	a1,s2
    80002aae:	6928                	ld	a0,80(a0)
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	cf8080e7          	jalr	-776(ra) # 800017a8 <copyin>
    80002ab8:	00a03533          	snez	a0,a0
    80002abc:	40a00533          	neg	a0,a0
}
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6902                	ld	s2,0(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret
    return -1;
    80002acc:	557d                	li	a0,-1
    80002ace:	bfcd                	j	80002ac0 <fetchaddr+0x3e>
    80002ad0:	557d                	li	a0,-1
    80002ad2:	b7fd                	j	80002ac0 <fetchaddr+0x3e>

0000000080002ad4 <fetchstr>:
{
    80002ad4:	7179                	addi	sp,sp,-48
    80002ad6:	f406                	sd	ra,40(sp)
    80002ad8:	f022                	sd	s0,32(sp)
    80002ada:	ec26                	sd	s1,24(sp)
    80002adc:	e84a                	sd	s2,16(sp)
    80002ade:	e44e                	sd	s3,8(sp)
    80002ae0:	1800                	addi	s0,sp,48
    80002ae2:	892a                	mv	s2,a0
    80002ae4:	84ae                	mv	s1,a1
    80002ae6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	f40080e7          	jalr	-192(ra) # 80001a28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002af0:	86ce                	mv	a3,s3
    80002af2:	864a                	mv	a2,s2
    80002af4:	85a6                	mv	a1,s1
    80002af6:	6928                	ld	a0,80(a0)
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	d3c080e7          	jalr	-708(ra) # 80001834 <copyinstr>
  if(err < 0)
    80002b00:	00054763          	bltz	a0,80002b0e <fetchstr+0x3a>
  return strlen(buf);
    80002b04:	8526                	mv	a0,s1
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	3d8080e7          	jalr	984(ra) # 80000ede <strlen>
}
    80002b0e:	70a2                	ld	ra,40(sp)
    80002b10:	7402                	ld	s0,32(sp)
    80002b12:	64e2                	ld	s1,24(sp)
    80002b14:	6942                	ld	s2,16(sp)
    80002b16:	69a2                	ld	s3,8(sp)
    80002b18:	6145                	addi	sp,sp,48
    80002b1a:	8082                	ret

0000000080002b1c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	ef2080e7          	jalr	-270(ra) # 80002a1a <argraw>
    80002b30:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b32:	4501                	li	a0,0
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret

0000000080002b3e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	ed0080e7          	jalr	-304(ra) # 80002a1a <argraw>
    80002b52:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b54:	4501                	li	a0,0
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret

0000000080002b60 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	e04a                	sd	s2,0(sp)
    80002b6a:	1000                	addi	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
    80002b6e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	eaa080e7          	jalr	-342(ra) # 80002a1a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b78:	864a                	mv	a2,s2
    80002b7a:	85a6                	mv	a1,s1
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	f58080e7          	jalr	-168(ra) # 80002ad4 <fetchstr>
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6902                	ld	s2,0(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret

0000000080002b90 <syscall>:
[SYS_sysinfo] "sys_sysinfo",
};

void
syscall(void)
{
    80002b90:	7179                	addi	sp,sp,-48
    80002b92:	f406                	sd	ra,40(sp)
    80002b94:	f022                	sd	s0,32(sp)
    80002b96:	ec26                	sd	s1,24(sp)
    80002b98:	e84a                	sd	s2,16(sp)
    80002b9a:	e44e                	sd	s3,8(sp)
    80002b9c:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e8a080e7          	jalr	-374(ra) # 80001a28 <myproc>
    80002ba6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ba8:	05853903          	ld	s2,88(a0)
    80002bac:	0a893783          	ld	a5,168(s2)
    80002bb0:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) { // 如果系统调用编号有效
    80002bb4:	37fd                	addiw	a5,a5,-1
    80002bb6:	4759                	li	a4,22
    80002bb8:	04f76863          	bltu	a4,a5,80002c08 <syscall+0x78>
    80002bbc:	00399713          	slli	a4,s3,0x3
    80002bc0:	00006797          	auipc	a5,0x6
    80002bc4:	93878793          	addi	a5,a5,-1736 # 800084f8 <syscalls>
    80002bc8:	97ba                	add	a5,a5,a4
    80002bca:	639c                	ld	a5,0(a5)
    80002bcc:	cf95                	beqz	a5,80002c08 <syscall+0x78>
    p->trapframe->a0 = syscalls[num](); // 通过系统调用编号，获取系统调用处理函数的指针，调用并将返回值存到用户进程的 a0 寄存器中
    80002bce:	9782                	jalr	a5
    80002bd0:	06a93823          	sd	a0,112(s2)
	  // 如果当前进程设置了对该编号系统调用的 trace，则打出 pid、系统调用名称和返回值。
    if((p->syscall_trace >> num) & 1) {
    80002bd4:	1684b783          	ld	a5,360(s1)
    80002bd8:	0137d7b3          	srl	a5,a5,s3
    80002bdc:	8b85                	andi	a5,a5,1
    80002bde:	c7a1                	beqz	a5,80002c26 <syscall+0x96>
      printf("%d: syscall %s -> %d\n",p->pid, syscall_names[num], p->trapframe->a0); // syscall_names[num]: 从 syscall 编号到 syscall 名的映射表
    80002be0:	6cb8                	ld	a4,88(s1)
    80002be2:	098e                	slli	s3,s3,0x3
    80002be4:	00006797          	auipc	a5,0x6
    80002be8:	d5478793          	addi	a5,a5,-684 # 80008938 <syscall_names>
    80002bec:	99be                	add	s3,s3,a5
    80002bee:	7b34                	ld	a3,112(a4)
    80002bf0:	0009b603          	ld	a2,0(s3)
    80002bf4:	5c8c                	lw	a1,56(s1)
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	7fa50513          	addi	a0,a0,2042 # 800083f0 <states.1707+0x148>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	994080e7          	jalr	-1644(ra) # 80000592 <printf>
    80002c06:	a005                	j	80002c26 <syscall+0x96>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c08:	86ce                	mv	a3,s3
    80002c0a:	15848613          	addi	a2,s1,344
    80002c0e:	5c8c                	lw	a1,56(s1)
    80002c10:	00005517          	auipc	a0,0x5
    80002c14:	7f850513          	addi	a0,a0,2040 # 80008408 <states.1707+0x160>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	97a080e7          	jalr	-1670(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c20:	6cbc                	ld	a5,88(s1)
    80002c22:	577d                	li	a4,-1
    80002c24:	fbb8                	sd	a4,112(a5)
  }
}
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6942                	ld	s2,16(sp)
    80002c2e:	69a2                	ld	s3,8(sp)
    80002c30:	6145                	addi	sp,sp,48
    80002c32:	8082                	ret

0000000080002c34 <sys_trace>:
#include "sysinfo.h"

// Lab2:syscall(1)
uint64
sys_trace(void)
{
    80002c34:	7179                	addi	sp,sp,-48
    80002c36:	f406                	sd	ra,40(sp)
    80002c38:	f022                	sd	s0,32(sp)
    80002c3a:	ec26                	sd	s1,24(sp)
    80002c3c:	1800                	addi	s0,sp,48
  int mask;
  if(argint(0, &mask) < 0)
    80002c3e:	fdc40593          	addi	a1,s0,-36
    80002c42:	4501                	li	a0,0
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	ed8080e7          	jalr	-296(ra) # 80002b1c <argint>
    return -1;
    80002c4c:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0)
    80002c4e:	00054b63          	bltz	a0,80002c64 <sys_trace+0x30>
  myproc()->syscall_trace = mask;
    80002c52:	fdc42483          	lw	s1,-36(s0)
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	dd2080e7          	jalr	-558(ra) # 80001a28 <myproc>
    80002c5e:	16953423          	sd	s1,360(a0)
  return 0;
    80002c62:	4781                	li	a5,0
}
    80002c64:	853e                	mv	a0,a5
    80002c66:	70a2                	ld	ra,40(sp)
    80002c68:	7402                	ld	s0,32(sp)
    80002c6a:	64e2                	ld	s1,24(sp)
    80002c6c:	6145                	addi	sp,sp,48
    80002c6e:	8082                	ret

0000000080002c70 <sys_sysinfo>:

// Lab2:syscall(2)
uint64
sys_sysinfo(void)
{
    80002c70:	7179                	addi	sp,sp,-48
    80002c72:	f406                	sd	ra,40(sp)
    80002c74:	f022                	sd	s0,32(sp)
    80002c76:	1800                	addi	s0,sp,48
  // 从用户态读入一个指针，作为存放 sysinfo 结构的缓冲区
  uint64 addr;
  if(argaddr(0, &addr) < 0)
    80002c78:	fe840593          	addi	a1,s0,-24
    80002c7c:	4501                	li	a0,0
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	ec0080e7          	jalr	-320(ra) # 80002b3e <argaddr>
    80002c86:	87aa                	mv	a5,a0
    return -1;
    80002c88:	557d                	li	a0,-1
  if(argaddr(0, &addr) < 0)
    80002c8a:	0207cd63          	bltz	a5,80002cc4 <sys_sysinfo+0x54>
  
  struct sysinfo sinfo;
  sinfo.freemem = count_free_mem(); // kalloc.c
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	ef2080e7          	jalr	-270(ra) # 80000b80 <count_free_mem>
    80002c96:	fca43c23          	sd	a0,-40(s0)
  sinfo.nproc = count_process(); // proc.c
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	962080e7          	jalr	-1694(ra) # 800025fc <count_process>
    80002ca2:	fea43023          	sd	a0,-32(s0)
  
  // 使用 copyout，结合当前进程的页表，获得进程传进来的指针（逻辑地址）对应的物理地址
  // 然后将 &sinfo 中的数据复制到该指针所指位置，供用户进程使用。
  if(copyout(myproc()->pagetable, addr, (char *)&sinfo, sizeof(sinfo)) < 0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	d82080e7          	jalr	-638(ra) # 80001a28 <myproc>
    80002cae:	46c1                	li	a3,16
    80002cb0:	fd840613          	addi	a2,s0,-40
    80002cb4:	fe843583          	ld	a1,-24(s0)
    80002cb8:	6928                	ld	a0,80(a0)
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	a62080e7          	jalr	-1438(ra) # 8000171c <copyout>
    80002cc2:	957d                	srai	a0,a0,0x3f
    return -1;
  return 0;
}
    80002cc4:	70a2                	ld	ra,40(sp)
    80002cc6:	7402                	ld	s0,32(sp)
    80002cc8:	6145                	addi	sp,sp,48
    80002cca:	8082                	ret

0000000080002ccc <sys_exit>:

uint64
sys_exit(void)
{
    80002ccc:	1101                	addi	sp,sp,-32
    80002cce:	ec06                	sd	ra,24(sp)
    80002cd0:	e822                	sd	s0,16(sp)
    80002cd2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cd4:	fec40593          	addi	a1,s0,-20
    80002cd8:	4501                	li	a0,0
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	e42080e7          	jalr	-446(ra) # 80002b1c <argint>
    return -1;
    80002ce2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ce4:	00054963          	bltz	a0,80002cf6 <sys_exit+0x2a>
  exit(n);
    80002ce8:	fec42503          	lw	a0,-20(s0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	40e080e7          	jalr	1038(ra) # 800020fa <exit>
  return 0;  // not reached
    80002cf4:	4781                	li	a5,0
}
    80002cf6:	853e                	mv	a0,a5
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	6105                	addi	sp,sp,32
    80002cfe:	8082                	ret

0000000080002d00 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d00:	1141                	addi	sp,sp,-16
    80002d02:	e406                	sd	ra,8(sp)
    80002d04:	e022                	sd	s0,0(sp)
    80002d06:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	d20080e7          	jalr	-736(ra) # 80001a28 <myproc>
}
    80002d10:	5d08                	lw	a0,56(a0)
    80002d12:	60a2                	ld	ra,8(sp)
    80002d14:	6402                	ld	s0,0(sp)
    80002d16:	0141                	addi	sp,sp,16
    80002d18:	8082                	ret

0000000080002d1a <sys_fork>:

uint64
sys_fork(void)
{
    80002d1a:	1141                	addi	sp,sp,-16
    80002d1c:	e406                	sd	ra,8(sp)
    80002d1e:	e022                	sd	s0,0(sp)
    80002d20:	0800                	addi	s0,sp,16
  return fork();
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	0ca080e7          	jalr	202(ra) # 80001dec <fork>
}
    80002d2a:	60a2                	ld	ra,8(sp)
    80002d2c:	6402                	ld	s0,0(sp)
    80002d2e:	0141                	addi	sp,sp,16
    80002d30:	8082                	ret

0000000080002d32 <sys_wait>:

uint64
sys_wait(void)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d3a:	fe840593          	addi	a1,s0,-24
    80002d3e:	4501                	li	a0,0
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	dfe080e7          	jalr	-514(ra) # 80002b3e <argaddr>
    80002d48:	87aa                	mv	a5,a0
    return -1;
    80002d4a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d4c:	0007c863          	bltz	a5,80002d5c <sys_wait+0x2a>
  return wait(p);
    80002d50:	fe843503          	ld	a0,-24(s0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	56a080e7          	jalr	1386(ra) # 800022be <wait>
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d64:	7179                	addi	sp,sp,-48
    80002d66:	f406                	sd	ra,40(sp)
    80002d68:	f022                	sd	s0,32(sp)
    80002d6a:	ec26                	sd	s1,24(sp)
    80002d6c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d6e:	fdc40593          	addi	a1,s0,-36
    80002d72:	4501                	li	a0,0
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	da8080e7          	jalr	-600(ra) # 80002b1c <argint>
    80002d7c:	87aa                	mv	a5,a0
    return -1;
    80002d7e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d80:	0207c063          	bltz	a5,80002da0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	ca4080e7          	jalr	-860(ra) # 80001a28 <myproc>
    80002d8c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d8e:	fdc42503          	lw	a0,-36(s0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	fe6080e7          	jalr	-26(ra) # 80001d78 <growproc>
    80002d9a:	00054863          	bltz	a0,80002daa <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d9e:	8526                	mv	a0,s1
}
    80002da0:	70a2                	ld	ra,40(sp)
    80002da2:	7402                	ld	s0,32(sp)
    80002da4:	64e2                	ld	s1,24(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret
    return -1;
    80002daa:	557d                	li	a0,-1
    80002dac:	bfd5                	j	80002da0 <sys_sbrk+0x3c>

0000000080002dae <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dae:	7139                	addi	sp,sp,-64
    80002db0:	fc06                	sd	ra,56(sp)
    80002db2:	f822                	sd	s0,48(sp)
    80002db4:	f426                	sd	s1,40(sp)
    80002db6:	f04a                	sd	s2,32(sp)
    80002db8:	ec4e                	sd	s3,24(sp)
    80002dba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dbc:	fcc40593          	addi	a1,s0,-52
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	d5a080e7          	jalr	-678(ra) # 80002b1c <argint>
    return -1;
    80002dca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dcc:	06054563          	bltz	a0,80002e36 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dd0:	00015517          	auipc	a0,0x15
    80002dd4:	b9850513          	addi	a0,a0,-1128 # 80017968 <tickslock>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	e82080e7          	jalr	-382(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002de0:	00006917          	auipc	s2,0x6
    80002de4:	24092903          	lw	s2,576(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002de8:	fcc42783          	lw	a5,-52(s0)
    80002dec:	cf85                	beqz	a5,80002e24 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dee:	00015997          	auipc	s3,0x15
    80002df2:	b7a98993          	addi	s3,s3,-1158 # 80017968 <tickslock>
    80002df6:	00006497          	auipc	s1,0x6
    80002dfa:	22a48493          	addi	s1,s1,554 # 80009020 <ticks>
    if(myproc()->killed){
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	c2a080e7          	jalr	-982(ra) # 80001a28 <myproc>
    80002e06:	591c                	lw	a5,48(a0)
    80002e08:	ef9d                	bnez	a5,80002e46 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e0a:	85ce                	mv	a1,s3
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	432080e7          	jalr	1074(ra) # 80002240 <sleep>
  while(ticks - ticks0 < n){
    80002e16:	409c                	lw	a5,0(s1)
    80002e18:	412787bb          	subw	a5,a5,s2
    80002e1c:	fcc42703          	lw	a4,-52(s0)
    80002e20:	fce7efe3          	bltu	a5,a4,80002dfe <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e24:	00015517          	auipc	a0,0x15
    80002e28:	b4450513          	addi	a0,a0,-1212 # 80017968 <tickslock>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	ee2080e7          	jalr	-286(ra) # 80000d0e <release>
  return 0;
    80002e34:	4781                	li	a5,0
}
    80002e36:	853e                	mv	a0,a5
    80002e38:	70e2                	ld	ra,56(sp)
    80002e3a:	7442                	ld	s0,48(sp)
    80002e3c:	74a2                	ld	s1,40(sp)
    80002e3e:	7902                	ld	s2,32(sp)
    80002e40:	69e2                	ld	s3,24(sp)
    80002e42:	6121                	addi	sp,sp,64
    80002e44:	8082                	ret
      release(&tickslock);
    80002e46:	00015517          	auipc	a0,0x15
    80002e4a:	b2250513          	addi	a0,a0,-1246 # 80017968 <tickslock>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	ec0080e7          	jalr	-320(ra) # 80000d0e <release>
      return -1;
    80002e56:	57fd                	li	a5,-1
    80002e58:	bff9                	j	80002e36 <sys_sleep+0x88>

0000000080002e5a <sys_kill>:

uint64
sys_kill(void)
{
    80002e5a:	1101                	addi	sp,sp,-32
    80002e5c:	ec06                	sd	ra,24(sp)
    80002e5e:	e822                	sd	s0,16(sp)
    80002e60:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e62:	fec40593          	addi	a1,s0,-20
    80002e66:	4501                	li	a0,0
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	cb4080e7          	jalr	-844(ra) # 80002b1c <argint>
    80002e70:	87aa                	mv	a5,a0
    return -1;
    80002e72:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e74:	0007c863          	bltz	a5,80002e84 <sys_kill+0x2a>
  return kill(pid);
    80002e78:	fec42503          	lw	a0,-20(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	5b4080e7          	jalr	1460(ra) # 80002430 <kill>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	e426                	sd	s1,8(sp)
    80002e94:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e96:	00015517          	auipc	a0,0x15
    80002e9a:	ad250513          	addi	a0,a0,-1326 # 80017968 <tickslock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	dbc080e7          	jalr	-580(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002ea6:	00006497          	auipc	s1,0x6
    80002eaa:	17a4a483          	lw	s1,378(s1) # 80009020 <ticks>
  release(&tickslock);
    80002eae:	00015517          	auipc	a0,0x15
    80002eb2:	aba50513          	addi	a0,a0,-1350 # 80017968 <tickslock>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	e58080e7          	jalr	-424(ra) # 80000d0e <release>
  return xticks;
}
    80002ebe:	02049513          	slli	a0,s1,0x20
    80002ec2:	9101                	srli	a0,a0,0x20
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6105                	addi	sp,sp,32
    80002ecc:	8082                	ret

0000000080002ece <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ece:	7179                	addi	sp,sp,-48
    80002ed0:	f406                	sd	ra,40(sp)
    80002ed2:	f022                	sd	s0,32(sp)
    80002ed4:	ec26                	sd	s1,24(sp)
    80002ed6:	e84a                	sd	s2,16(sp)
    80002ed8:	e44e                	sd	s3,8(sp)
    80002eda:	e052                	sd	s4,0(sp)
    80002edc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ede:	00005597          	auipc	a1,0x5
    80002ee2:	6da58593          	addi	a1,a1,1754 # 800085b8 <syscalls+0xc0>
    80002ee6:	00015517          	auipc	a0,0x15
    80002eea:	a9a50513          	addi	a0,a0,-1382 # 80017980 <bcache>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	cdc080e7          	jalr	-804(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ef6:	0001d797          	auipc	a5,0x1d
    80002efa:	a8a78793          	addi	a5,a5,-1398 # 8001f980 <bcache+0x8000>
    80002efe:	0001d717          	auipc	a4,0x1d
    80002f02:	cea70713          	addi	a4,a4,-790 # 8001fbe8 <bcache+0x8268>
    80002f06:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f0a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f0e:	00015497          	auipc	s1,0x15
    80002f12:	a8a48493          	addi	s1,s1,-1398 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002f16:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f18:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f1a:	00005a17          	auipc	s4,0x5
    80002f1e:	6a6a0a13          	addi	s4,s4,1702 # 800085c0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f22:	2b893783          	ld	a5,696(s2)
    80002f26:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f28:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f2c:	85d2                	mv	a1,s4
    80002f2e:	01048513          	addi	a0,s1,16
    80002f32:	00001097          	auipc	ra,0x1
    80002f36:	4ac080e7          	jalr	1196(ra) # 800043de <initsleeplock>
    bcache.head.next->prev = b;
    80002f3a:	2b893783          	ld	a5,696(s2)
    80002f3e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f40:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f44:	45848493          	addi	s1,s1,1112
    80002f48:	fd349de3          	bne	s1,s3,80002f22 <binit+0x54>
  }
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	69a2                	ld	s3,8(sp)
    80002f56:	6a02                	ld	s4,0(sp)
    80002f58:	6145                	addi	sp,sp,48
    80002f5a:	8082                	ret

0000000080002f5c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	1800                	addi	s0,sp,48
    80002f6a:	89aa                	mv	s3,a0
    80002f6c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f6e:	00015517          	auipc	a0,0x15
    80002f72:	a1250513          	addi	a0,a0,-1518 # 80017980 <bcache>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	ce4080e7          	jalr	-796(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f7e:	0001d497          	auipc	s1,0x1d
    80002f82:	cba4b483          	ld	s1,-838(s1) # 8001fc38 <bcache+0x82b8>
    80002f86:	0001d797          	auipc	a5,0x1d
    80002f8a:	c6278793          	addi	a5,a5,-926 # 8001fbe8 <bcache+0x8268>
    80002f8e:	02f48f63          	beq	s1,a5,80002fcc <bread+0x70>
    80002f92:	873e                	mv	a4,a5
    80002f94:	a021                	j	80002f9c <bread+0x40>
    80002f96:	68a4                	ld	s1,80(s1)
    80002f98:	02e48a63          	beq	s1,a4,80002fcc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f9c:	449c                	lw	a5,8(s1)
    80002f9e:	ff379ce3          	bne	a5,s3,80002f96 <bread+0x3a>
    80002fa2:	44dc                	lw	a5,12(s1)
    80002fa4:	ff2799e3          	bne	a5,s2,80002f96 <bread+0x3a>
      b->refcnt++;
    80002fa8:	40bc                	lw	a5,64(s1)
    80002faa:	2785                	addiw	a5,a5,1
    80002fac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fae:	00015517          	auipc	a0,0x15
    80002fb2:	9d250513          	addi	a0,a0,-1582 # 80017980 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	d58080e7          	jalr	-680(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002fbe:	01048513          	addi	a0,s1,16
    80002fc2:	00001097          	auipc	ra,0x1
    80002fc6:	456080e7          	jalr	1110(ra) # 80004418 <acquiresleep>
      return b;
    80002fca:	a8b9                	j	80003028 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fcc:	0001d497          	auipc	s1,0x1d
    80002fd0:	c644b483          	ld	s1,-924(s1) # 8001fc30 <bcache+0x82b0>
    80002fd4:	0001d797          	auipc	a5,0x1d
    80002fd8:	c1478793          	addi	a5,a5,-1004 # 8001fbe8 <bcache+0x8268>
    80002fdc:	00f48863          	beq	s1,a5,80002fec <bread+0x90>
    80002fe0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	cf81                	beqz	a5,80002ffc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe6:	64a4                	ld	s1,72(s1)
    80002fe8:	fee49de3          	bne	s1,a4,80002fe2 <bread+0x86>
  panic("bget: no buffers");
    80002fec:	00005517          	auipc	a0,0x5
    80002ff0:	5dc50513          	addi	a0,a0,1500 # 800085c8 <syscalls+0xd0>
    80002ff4:	ffffd097          	auipc	ra,0xffffd
    80002ff8:	554080e7          	jalr	1364(ra) # 80000548 <panic>
      b->dev = dev;
    80002ffc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003000:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003004:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003008:	4785                	li	a5,1
    8000300a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300c:	00015517          	auipc	a0,0x15
    80003010:	97450513          	addi	a0,a0,-1676 # 80017980 <bcache>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	cfa080e7          	jalr	-774(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    8000301c:	01048513          	addi	a0,s1,16
    80003020:	00001097          	auipc	ra,0x1
    80003024:	3f8080e7          	jalr	1016(ra) # 80004418 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003028:	409c                	lw	a5,0(s1)
    8000302a:	cb89                	beqz	a5,8000303c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000302c:	8526                	mv	a0,s1
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6942                	ld	s2,16(sp)
    80003036:	69a2                	ld	s3,8(sp)
    80003038:	6145                	addi	sp,sp,48
    8000303a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000303c:	4581                	li	a1,0
    8000303e:	8526                	mv	a0,s1
    80003040:	00003097          	auipc	ra,0x3
    80003044:	f2c080e7          	jalr	-212(ra) # 80005f6c <virtio_disk_rw>
    b->valid = 1;
    80003048:	4785                	li	a5,1
    8000304a:	c09c                	sw	a5,0(s1)
  return b;
    8000304c:	b7c5                	j	8000302c <bread+0xd0>

000000008000304e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	1000                	addi	s0,sp,32
    80003058:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000305a:	0541                	addi	a0,a0,16
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	456080e7          	jalr	1110(ra) # 800044b2 <holdingsleep>
    80003064:	cd01                	beqz	a0,8000307c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003066:	4585                	li	a1,1
    80003068:	8526                	mv	a0,s1
    8000306a:	00003097          	auipc	ra,0x3
    8000306e:	f02080e7          	jalr	-254(ra) # 80005f6c <virtio_disk_rw>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret
    panic("bwrite");
    8000307c:	00005517          	auipc	a0,0x5
    80003080:	56450513          	addi	a0,a0,1380 # 800085e0 <syscalls+0xe8>
    80003084:	ffffd097          	auipc	ra,0xffffd
    80003088:	4c4080e7          	jalr	1220(ra) # 80000548 <panic>

000000008000308c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000308c:	1101                	addi	sp,sp,-32
    8000308e:	ec06                	sd	ra,24(sp)
    80003090:	e822                	sd	s0,16(sp)
    80003092:	e426                	sd	s1,8(sp)
    80003094:	e04a                	sd	s2,0(sp)
    80003096:	1000                	addi	s0,sp,32
    80003098:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000309a:	01050913          	addi	s2,a0,16
    8000309e:	854a                	mv	a0,s2
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	412080e7          	jalr	1042(ra) # 800044b2 <holdingsleep>
    800030a8:	c92d                	beqz	a0,8000311a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030aa:	854a                	mv	a0,s2
    800030ac:	00001097          	auipc	ra,0x1
    800030b0:	3c2080e7          	jalr	962(ra) # 8000446e <releasesleep>

  acquire(&bcache.lock);
    800030b4:	00015517          	auipc	a0,0x15
    800030b8:	8cc50513          	addi	a0,a0,-1844 # 80017980 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	b9e080e7          	jalr	-1122(ra) # 80000c5a <acquire>
  b->refcnt--;
    800030c4:	40bc                	lw	a5,64(s1)
    800030c6:	37fd                	addiw	a5,a5,-1
    800030c8:	0007871b          	sext.w	a4,a5
    800030cc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ce:	eb05                	bnez	a4,800030fe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030d0:	68bc                	ld	a5,80(s1)
    800030d2:	64b8                	ld	a4,72(s1)
    800030d4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030d6:	64bc                	ld	a5,72(s1)
    800030d8:	68b8                	ld	a4,80(s1)
    800030da:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030dc:	0001d797          	auipc	a5,0x1d
    800030e0:	8a478793          	addi	a5,a5,-1884 # 8001f980 <bcache+0x8000>
    800030e4:	2b87b703          	ld	a4,696(a5)
    800030e8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ea:	0001d717          	auipc	a4,0x1d
    800030ee:	afe70713          	addi	a4,a4,-1282 # 8001fbe8 <bcache+0x8268>
    800030f2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030f4:	2b87b703          	ld	a4,696(a5)
    800030f8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030fa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030fe:	00015517          	auipc	a0,0x15
    80003102:	88250513          	addi	a0,a0,-1918 # 80017980 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	c08080e7          	jalr	-1016(ra) # 80000d0e <release>
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6902                	ld	s2,0(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret
    panic("brelse");
    8000311a:	00005517          	auipc	a0,0x5
    8000311e:	4ce50513          	addi	a0,a0,1230 # 800085e8 <syscalls+0xf0>
    80003122:	ffffd097          	auipc	ra,0xffffd
    80003126:	426080e7          	jalr	1062(ra) # 80000548 <panic>

000000008000312a <bpin>:

void
bpin(struct buf *b) {
    8000312a:	1101                	addi	sp,sp,-32
    8000312c:	ec06                	sd	ra,24(sp)
    8000312e:	e822                	sd	s0,16(sp)
    80003130:	e426                	sd	s1,8(sp)
    80003132:	1000                	addi	s0,sp,32
    80003134:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003136:	00015517          	auipc	a0,0x15
    8000313a:	84a50513          	addi	a0,a0,-1974 # 80017980 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b1c080e7          	jalr	-1252(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003146:	40bc                	lw	a5,64(s1)
    80003148:	2785                	addiw	a5,a5,1
    8000314a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000314c:	00015517          	auipc	a0,0x15
    80003150:	83450513          	addi	a0,a0,-1996 # 80017980 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	bba080e7          	jalr	-1094(ra) # 80000d0e <release>
}
    8000315c:	60e2                	ld	ra,24(sp)
    8000315e:	6442                	ld	s0,16(sp)
    80003160:	64a2                	ld	s1,8(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <bunpin>:

void
bunpin(struct buf *b) {
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	1000                	addi	s0,sp,32
    80003170:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003172:	00015517          	auipc	a0,0x15
    80003176:	80e50513          	addi	a0,a0,-2034 # 80017980 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	ae0080e7          	jalr	-1312(ra) # 80000c5a <acquire>
  b->refcnt--;
    80003182:	40bc                	lw	a5,64(s1)
    80003184:	37fd                	addiw	a5,a5,-1
    80003186:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003188:	00014517          	auipc	a0,0x14
    8000318c:	7f850513          	addi	a0,a0,2040 # 80017980 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b7e080e7          	jalr	-1154(ra) # 80000d0e <release>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	64a2                	ld	s1,8(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	e04a                	sd	s2,0(sp)
    800031ac:	1000                	addi	s0,sp,32
    800031ae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031b0:	00d5d59b          	srliw	a1,a1,0xd
    800031b4:	0001d797          	auipc	a5,0x1d
    800031b8:	ea87a783          	lw	a5,-344(a5) # 8002005c <sb+0x1c>
    800031bc:	9dbd                	addw	a1,a1,a5
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	d9e080e7          	jalr	-610(ra) # 80002f5c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031c6:	0074f713          	andi	a4,s1,7
    800031ca:	4785                	li	a5,1
    800031cc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031d0:	14ce                	slli	s1,s1,0x33
    800031d2:	90d9                	srli	s1,s1,0x36
    800031d4:	00950733          	add	a4,a0,s1
    800031d8:	05874703          	lbu	a4,88(a4)
    800031dc:	00e7f6b3          	and	a3,a5,a4
    800031e0:	c69d                	beqz	a3,8000320e <bfree+0x6c>
    800031e2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031e4:	94aa                	add	s1,s1,a0
    800031e6:	fff7c793          	not	a5,a5
    800031ea:	8ff9                	and	a5,a5,a4
    800031ec:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	100080e7          	jalr	256(ra) # 800042f0 <log_write>
  brelse(bp);
    800031f8:	854a                	mv	a0,s2
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	e92080e7          	jalr	-366(ra) # 8000308c <brelse>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	64a2                	ld	s1,8(sp)
    80003208:	6902                	ld	s2,0(sp)
    8000320a:	6105                	addi	sp,sp,32
    8000320c:	8082                	ret
    panic("freeing free block");
    8000320e:	00005517          	auipc	a0,0x5
    80003212:	3e250513          	addi	a0,a0,994 # 800085f0 <syscalls+0xf8>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	332080e7          	jalr	818(ra) # 80000548 <panic>

000000008000321e <balloc>:
{
    8000321e:	711d                	addi	sp,sp,-96
    80003220:	ec86                	sd	ra,88(sp)
    80003222:	e8a2                	sd	s0,80(sp)
    80003224:	e4a6                	sd	s1,72(sp)
    80003226:	e0ca                	sd	s2,64(sp)
    80003228:	fc4e                	sd	s3,56(sp)
    8000322a:	f852                	sd	s4,48(sp)
    8000322c:	f456                	sd	s5,40(sp)
    8000322e:	f05a                	sd	s6,32(sp)
    80003230:	ec5e                	sd	s7,24(sp)
    80003232:	e862                	sd	s8,16(sp)
    80003234:	e466                	sd	s9,8(sp)
    80003236:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003238:	0001d797          	auipc	a5,0x1d
    8000323c:	e0c7a783          	lw	a5,-500(a5) # 80020044 <sb+0x4>
    80003240:	cbd1                	beqz	a5,800032d4 <balloc+0xb6>
    80003242:	8baa                	mv	s7,a0
    80003244:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003246:	0001db17          	auipc	s6,0x1d
    8000324a:	dfab0b13          	addi	s6,s6,-518 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000324e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003250:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003252:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003254:	6c89                	lui	s9,0x2
    80003256:	a831                	j	80003272 <balloc+0x54>
    brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	e32080e7          	jalr	-462(ra) # 8000308c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003262:	015c87bb          	addw	a5,s9,s5
    80003266:	00078a9b          	sext.w	s5,a5
    8000326a:	004b2703          	lw	a4,4(s6)
    8000326e:	06eaf363          	bgeu	s5,a4,800032d4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003272:	41fad79b          	sraiw	a5,s5,0x1f
    80003276:	0137d79b          	srliw	a5,a5,0x13
    8000327a:	015787bb          	addw	a5,a5,s5
    8000327e:	40d7d79b          	sraiw	a5,a5,0xd
    80003282:	01cb2583          	lw	a1,28(s6)
    80003286:	9dbd                	addw	a1,a1,a5
    80003288:	855e                	mv	a0,s7
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	cd2080e7          	jalr	-814(ra) # 80002f5c <bread>
    80003292:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003294:	004b2503          	lw	a0,4(s6)
    80003298:	000a849b          	sext.w	s1,s5
    8000329c:	8662                	mv	a2,s8
    8000329e:	faa4fde3          	bgeu	s1,a0,80003258 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032a2:	41f6579b          	sraiw	a5,a2,0x1f
    800032a6:	01d7d69b          	srliw	a3,a5,0x1d
    800032aa:	00c6873b          	addw	a4,a3,a2
    800032ae:	00777793          	andi	a5,a4,7
    800032b2:	9f95                	subw	a5,a5,a3
    800032b4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032b8:	4037571b          	sraiw	a4,a4,0x3
    800032bc:	00e906b3          	add	a3,s2,a4
    800032c0:	0586c683          	lbu	a3,88(a3)
    800032c4:	00d7f5b3          	and	a1,a5,a3
    800032c8:	cd91                	beqz	a1,800032e4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ca:	2605                	addiw	a2,a2,1
    800032cc:	2485                	addiw	s1,s1,1
    800032ce:	fd4618e3          	bne	a2,s4,8000329e <balloc+0x80>
    800032d2:	b759                	j	80003258 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	33450513          	addi	a0,a0,820 # 80008608 <syscalls+0x110>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	26c080e7          	jalr	620(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032e4:	974a                	add	a4,a4,s2
    800032e6:	8fd5                	or	a5,a5,a3
    800032e8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	002080e7          	jalr	2(ra) # 800042f0 <log_write>
        brelse(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	d94080e7          	jalr	-620(ra) # 8000308c <brelse>
  bp = bread(dev, bno);
    80003300:	85a6                	mv	a1,s1
    80003302:	855e                	mv	a0,s7
    80003304:	00000097          	auipc	ra,0x0
    80003308:	c58080e7          	jalr	-936(ra) # 80002f5c <bread>
    8000330c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000330e:	40000613          	li	a2,1024
    80003312:	4581                	li	a1,0
    80003314:	05850513          	addi	a0,a0,88
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	a3e080e7          	jalr	-1474(ra) # 80000d56 <memset>
  log_write(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	fce080e7          	jalr	-50(ra) # 800042f0 <log_write>
  brelse(bp);
    8000332a:	854a                	mv	a0,s2
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	d60080e7          	jalr	-672(ra) # 8000308c <brelse>
}
    80003334:	8526                	mv	a0,s1
    80003336:	60e6                	ld	ra,88(sp)
    80003338:	6446                	ld	s0,80(sp)
    8000333a:	64a6                	ld	s1,72(sp)
    8000333c:	6906                	ld	s2,64(sp)
    8000333e:	79e2                	ld	s3,56(sp)
    80003340:	7a42                	ld	s4,48(sp)
    80003342:	7aa2                	ld	s5,40(sp)
    80003344:	7b02                	ld	s6,32(sp)
    80003346:	6be2                	ld	s7,24(sp)
    80003348:	6c42                	ld	s8,16(sp)
    8000334a:	6ca2                	ld	s9,8(sp)
    8000334c:	6125                	addi	sp,sp,96
    8000334e:	8082                	ret

0000000080003350 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003350:	7179                	addi	sp,sp,-48
    80003352:	f406                	sd	ra,40(sp)
    80003354:	f022                	sd	s0,32(sp)
    80003356:	ec26                	sd	s1,24(sp)
    80003358:	e84a                	sd	s2,16(sp)
    8000335a:	e44e                	sd	s3,8(sp)
    8000335c:	e052                	sd	s4,0(sp)
    8000335e:	1800                	addi	s0,sp,48
    80003360:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003362:	47ad                	li	a5,11
    80003364:	04b7fe63          	bgeu	a5,a1,800033c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003368:	ff45849b          	addiw	s1,a1,-12
    8000336c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003370:	0ff00793          	li	a5,255
    80003374:	0ae7e363          	bltu	a5,a4,8000341a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003378:	08052583          	lw	a1,128(a0)
    8000337c:	c5ad                	beqz	a1,800033e6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000337e:	00092503          	lw	a0,0(s2)
    80003382:	00000097          	auipc	ra,0x0
    80003386:	bda080e7          	jalr	-1062(ra) # 80002f5c <bread>
    8000338a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000338c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003390:	02049593          	slli	a1,s1,0x20
    80003394:	9181                	srli	a1,a1,0x20
    80003396:	058a                	slli	a1,a1,0x2
    80003398:	00b784b3          	add	s1,a5,a1
    8000339c:	0004a983          	lw	s3,0(s1)
    800033a0:	04098d63          	beqz	s3,800033fa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033a4:	8552                	mv	a0,s4
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	ce6080e7          	jalr	-794(ra) # 8000308c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ae:	854e                	mv	a0,s3
    800033b0:	70a2                	ld	ra,40(sp)
    800033b2:	7402                	ld	s0,32(sp)
    800033b4:	64e2                	ld	s1,24(sp)
    800033b6:	6942                	ld	s2,16(sp)
    800033b8:	69a2                	ld	s3,8(sp)
    800033ba:	6a02                	ld	s4,0(sp)
    800033bc:	6145                	addi	sp,sp,48
    800033be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033c0:	02059493          	slli	s1,a1,0x20
    800033c4:	9081                	srli	s1,s1,0x20
    800033c6:	048a                	slli	s1,s1,0x2
    800033c8:	94aa                	add	s1,s1,a0
    800033ca:	0504a983          	lw	s3,80(s1)
    800033ce:	fe0990e3          	bnez	s3,800033ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033d2:	4108                	lw	a0,0(a0)
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	e4a080e7          	jalr	-438(ra) # 8000321e <balloc>
    800033dc:	0005099b          	sext.w	s3,a0
    800033e0:	0534a823          	sw	s3,80(s1)
    800033e4:	b7e9                	j	800033ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033e6:	4108                	lw	a0,0(a0)
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e36080e7          	jalr	-458(ra) # 8000321e <balloc>
    800033f0:	0005059b          	sext.w	a1,a0
    800033f4:	08b92023          	sw	a1,128(s2)
    800033f8:	b759                	j	8000337e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033fa:	00092503          	lw	a0,0(s2)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e20080e7          	jalr	-480(ra) # 8000321e <balloc>
    80003406:	0005099b          	sext.w	s3,a0
    8000340a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000340e:	8552                	mv	a0,s4
    80003410:	00001097          	auipc	ra,0x1
    80003414:	ee0080e7          	jalr	-288(ra) # 800042f0 <log_write>
    80003418:	b771                	j	800033a4 <bmap+0x54>
  panic("bmap: out of range");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	20650513          	addi	a0,a0,518 # 80008620 <syscalls+0x128>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	126080e7          	jalr	294(ra) # 80000548 <panic>

000000008000342a <iget>:
{
    8000342a:	7179                	addi	sp,sp,-48
    8000342c:	f406                	sd	ra,40(sp)
    8000342e:	f022                	sd	s0,32(sp)
    80003430:	ec26                	sd	s1,24(sp)
    80003432:	e84a                	sd	s2,16(sp)
    80003434:	e44e                	sd	s3,8(sp)
    80003436:	e052                	sd	s4,0(sp)
    80003438:	1800                	addi	s0,sp,48
    8000343a:	89aa                	mv	s3,a0
    8000343c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000343e:	0001d517          	auipc	a0,0x1d
    80003442:	c2250513          	addi	a0,a0,-990 # 80020060 <icache>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	814080e7          	jalr	-2028(ra) # 80000c5a <acquire>
  empty = 0;
    8000344e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003450:	0001d497          	auipc	s1,0x1d
    80003454:	c2848493          	addi	s1,s1,-984 # 80020078 <icache+0x18>
    80003458:	0001e697          	auipc	a3,0x1e
    8000345c:	6b068693          	addi	a3,a3,1712 # 80021b08 <log>
    80003460:	a039                	j	8000346e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003462:	02090b63          	beqz	s2,80003498 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003466:	08848493          	addi	s1,s1,136
    8000346a:	02d48a63          	beq	s1,a3,8000349e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000346e:	449c                	lw	a5,8(s1)
    80003470:	fef059e3          	blez	a5,80003462 <iget+0x38>
    80003474:	4098                	lw	a4,0(s1)
    80003476:	ff3716e3          	bne	a4,s3,80003462 <iget+0x38>
    8000347a:	40d8                	lw	a4,4(s1)
    8000347c:	ff4713e3          	bne	a4,s4,80003462 <iget+0x38>
      ip->ref++;
    80003480:	2785                	addiw	a5,a5,1
    80003482:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003484:	0001d517          	auipc	a0,0x1d
    80003488:	bdc50513          	addi	a0,a0,-1060 # 80020060 <icache>
    8000348c:	ffffe097          	auipc	ra,0xffffe
    80003490:	882080e7          	jalr	-1918(ra) # 80000d0e <release>
      return ip;
    80003494:	8926                	mv	s2,s1
    80003496:	a03d                	j	800034c4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003498:	f7f9                	bnez	a5,80003466 <iget+0x3c>
    8000349a:	8926                	mv	s2,s1
    8000349c:	b7e9                	j	80003466 <iget+0x3c>
  if(empty == 0)
    8000349e:	02090c63          	beqz	s2,800034d6 <iget+0xac>
  ip->dev = dev;
    800034a2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034a6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034aa:	4785                	li	a5,1
    800034ac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034b0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034b4:	0001d517          	auipc	a0,0x1d
    800034b8:	bac50513          	addi	a0,a0,-1108 # 80020060 <icache>
    800034bc:	ffffe097          	auipc	ra,0xffffe
    800034c0:	852080e7          	jalr	-1966(ra) # 80000d0e <release>
}
    800034c4:	854a                	mv	a0,s2
    800034c6:	70a2                	ld	ra,40(sp)
    800034c8:	7402                	ld	s0,32(sp)
    800034ca:	64e2                	ld	s1,24(sp)
    800034cc:	6942                	ld	s2,16(sp)
    800034ce:	69a2                	ld	s3,8(sp)
    800034d0:	6a02                	ld	s4,0(sp)
    800034d2:	6145                	addi	sp,sp,48
    800034d4:	8082                	ret
    panic("iget: no inodes");
    800034d6:	00005517          	auipc	a0,0x5
    800034da:	16250513          	addi	a0,a0,354 # 80008638 <syscalls+0x140>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	06a080e7          	jalr	106(ra) # 80000548 <panic>

00000000800034e6 <fsinit>:
fsinit(int dev) {
    800034e6:	7179                	addi	sp,sp,-48
    800034e8:	f406                	sd	ra,40(sp)
    800034ea:	f022                	sd	s0,32(sp)
    800034ec:	ec26                	sd	s1,24(sp)
    800034ee:	e84a                	sd	s2,16(sp)
    800034f0:	e44e                	sd	s3,8(sp)
    800034f2:	1800                	addi	s0,sp,48
    800034f4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034f6:	4585                	li	a1,1
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	a64080e7          	jalr	-1436(ra) # 80002f5c <bread>
    80003500:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003502:	0001d997          	auipc	s3,0x1d
    80003506:	b3e98993          	addi	s3,s3,-1218 # 80020040 <sb>
    8000350a:	02000613          	li	a2,32
    8000350e:	05850593          	addi	a1,a0,88
    80003512:	854e                	mv	a0,s3
    80003514:	ffffe097          	auipc	ra,0xffffe
    80003518:	8a2080e7          	jalr	-1886(ra) # 80000db6 <memmove>
  brelse(bp);
    8000351c:	8526                	mv	a0,s1
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	b6e080e7          	jalr	-1170(ra) # 8000308c <brelse>
  if(sb.magic != FSMAGIC)
    80003526:	0009a703          	lw	a4,0(s3)
    8000352a:	102037b7          	lui	a5,0x10203
    8000352e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003532:	02f71263          	bne	a4,a5,80003556 <fsinit+0x70>
  initlog(dev, &sb);
    80003536:	0001d597          	auipc	a1,0x1d
    8000353a:	b0a58593          	addi	a1,a1,-1270 # 80020040 <sb>
    8000353e:	854a                	mv	a0,s2
    80003540:	00001097          	auipc	ra,0x1
    80003544:	b38080e7          	jalr	-1224(ra) # 80004078 <initlog>
}
    80003548:	70a2                	ld	ra,40(sp)
    8000354a:	7402                	ld	s0,32(sp)
    8000354c:	64e2                	ld	s1,24(sp)
    8000354e:	6942                	ld	s2,16(sp)
    80003550:	69a2                	ld	s3,8(sp)
    80003552:	6145                	addi	sp,sp,48
    80003554:	8082                	ret
    panic("invalid file system");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	0f250513          	addi	a0,a0,242 # 80008648 <syscalls+0x150>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fea080e7          	jalr	-22(ra) # 80000548 <panic>

0000000080003566 <iinit>:
{
    80003566:	7179                	addi	sp,sp,-48
    80003568:	f406                	sd	ra,40(sp)
    8000356a:	f022                	sd	s0,32(sp)
    8000356c:	ec26                	sd	s1,24(sp)
    8000356e:	e84a                	sd	s2,16(sp)
    80003570:	e44e                	sd	s3,8(sp)
    80003572:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003574:	00005597          	auipc	a1,0x5
    80003578:	0ec58593          	addi	a1,a1,236 # 80008660 <syscalls+0x168>
    8000357c:	0001d517          	auipc	a0,0x1d
    80003580:	ae450513          	addi	a0,a0,-1308 # 80020060 <icache>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	646080e7          	jalr	1606(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    8000358c:	0001d497          	auipc	s1,0x1d
    80003590:	afc48493          	addi	s1,s1,-1284 # 80020088 <icache+0x28>
    80003594:	0001e997          	auipc	s3,0x1e
    80003598:	58498993          	addi	s3,s3,1412 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000359c:	00005917          	auipc	s2,0x5
    800035a0:	0cc90913          	addi	s2,s2,204 # 80008668 <syscalls+0x170>
    800035a4:	85ca                	mv	a1,s2
    800035a6:	8526                	mv	a0,s1
    800035a8:	00001097          	auipc	ra,0x1
    800035ac:	e36080e7          	jalr	-458(ra) # 800043de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035b0:	08848493          	addi	s1,s1,136
    800035b4:	ff3498e3          	bne	s1,s3,800035a4 <iinit+0x3e>
}
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6145                	addi	sp,sp,48
    800035c4:	8082                	ret

00000000800035c6 <ialloc>:
{
    800035c6:	715d                	addi	sp,sp,-80
    800035c8:	e486                	sd	ra,72(sp)
    800035ca:	e0a2                	sd	s0,64(sp)
    800035cc:	fc26                	sd	s1,56(sp)
    800035ce:	f84a                	sd	s2,48(sp)
    800035d0:	f44e                	sd	s3,40(sp)
    800035d2:	f052                	sd	s4,32(sp)
    800035d4:	ec56                	sd	s5,24(sp)
    800035d6:	e85a                	sd	s6,16(sp)
    800035d8:	e45e                	sd	s7,8(sp)
    800035da:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035dc:	0001d717          	auipc	a4,0x1d
    800035e0:	a7072703          	lw	a4,-1424(a4) # 8002004c <sb+0xc>
    800035e4:	4785                	li	a5,1
    800035e6:	04e7fa63          	bgeu	a5,a4,8000363a <ialloc+0x74>
    800035ea:	8aaa                	mv	s5,a0
    800035ec:	8bae                	mv	s7,a1
    800035ee:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f0:	0001da17          	auipc	s4,0x1d
    800035f4:	a50a0a13          	addi	s4,s4,-1456 # 80020040 <sb>
    800035f8:	00048b1b          	sext.w	s6,s1
    800035fc:	0044d593          	srli	a1,s1,0x4
    80003600:	018a2783          	lw	a5,24(s4)
    80003604:	9dbd                	addw	a1,a1,a5
    80003606:	8556                	mv	a0,s5
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	954080e7          	jalr	-1708(ra) # 80002f5c <bread>
    80003610:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003612:	05850993          	addi	s3,a0,88
    80003616:	00f4f793          	andi	a5,s1,15
    8000361a:	079a                	slli	a5,a5,0x6
    8000361c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000361e:	00099783          	lh	a5,0(s3)
    80003622:	c785                	beqz	a5,8000364a <ialloc+0x84>
    brelse(bp);
    80003624:	00000097          	auipc	ra,0x0
    80003628:	a68080e7          	jalr	-1432(ra) # 8000308c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000362c:	0485                	addi	s1,s1,1
    8000362e:	00ca2703          	lw	a4,12(s4)
    80003632:	0004879b          	sext.w	a5,s1
    80003636:	fce7e1e3          	bltu	a5,a4,800035f8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	03650513          	addi	a0,a0,54 # 80008670 <syscalls+0x178>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	f06080e7          	jalr	-250(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000364a:	04000613          	li	a2,64
    8000364e:	4581                	li	a1,0
    80003650:	854e                	mv	a0,s3
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	704080e7          	jalr	1796(ra) # 80000d56 <memset>
      dip->type = type;
    8000365a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	c90080e7          	jalr	-880(ra) # 800042f0 <log_write>
      brelse(bp);
    80003668:	854a                	mv	a0,s2
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	a22080e7          	jalr	-1502(ra) # 8000308c <brelse>
      return iget(dev, inum);
    80003672:	85da                	mv	a1,s6
    80003674:	8556                	mv	a0,s5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	db4080e7          	jalr	-588(ra) # 8000342a <iget>
}
    8000367e:	60a6                	ld	ra,72(sp)
    80003680:	6406                	ld	s0,64(sp)
    80003682:	74e2                	ld	s1,56(sp)
    80003684:	7942                	ld	s2,48(sp)
    80003686:	79a2                	ld	s3,40(sp)
    80003688:	7a02                	ld	s4,32(sp)
    8000368a:	6ae2                	ld	s5,24(sp)
    8000368c:	6b42                	ld	s6,16(sp)
    8000368e:	6ba2                	ld	s7,8(sp)
    80003690:	6161                	addi	sp,sp,80
    80003692:	8082                	ret

0000000080003694 <iupdate>:
{
    80003694:	1101                	addi	sp,sp,-32
    80003696:	ec06                	sd	ra,24(sp)
    80003698:	e822                	sd	s0,16(sp)
    8000369a:	e426                	sd	s1,8(sp)
    8000369c:	e04a                	sd	s2,0(sp)
    8000369e:	1000                	addi	s0,sp,32
    800036a0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036a2:	415c                	lw	a5,4(a0)
    800036a4:	0047d79b          	srliw	a5,a5,0x4
    800036a8:	0001d597          	auipc	a1,0x1d
    800036ac:	9b05a583          	lw	a1,-1616(a1) # 80020058 <sb+0x18>
    800036b0:	9dbd                	addw	a1,a1,a5
    800036b2:	4108                	lw	a0,0(a0)
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	8a8080e7          	jalr	-1880(ra) # 80002f5c <bread>
    800036bc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036be:	05850793          	addi	a5,a0,88
    800036c2:	40c8                	lw	a0,4(s1)
    800036c4:	893d                	andi	a0,a0,15
    800036c6:	051a                	slli	a0,a0,0x6
    800036c8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036ca:	04449703          	lh	a4,68(s1)
    800036ce:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036d2:	04649703          	lh	a4,70(s1)
    800036d6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036da:	04849703          	lh	a4,72(s1)
    800036de:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036e2:	04a49703          	lh	a4,74(s1)
    800036e6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036ea:	44f8                	lw	a4,76(s1)
    800036ec:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ee:	03400613          	li	a2,52
    800036f2:	05048593          	addi	a1,s1,80
    800036f6:	0531                	addi	a0,a0,12
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	6be080e7          	jalr	1726(ra) # 80000db6 <memmove>
  log_write(bp);
    80003700:	854a                	mv	a0,s2
    80003702:	00001097          	auipc	ra,0x1
    80003706:	bee080e7          	jalr	-1042(ra) # 800042f0 <log_write>
  brelse(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	980080e7          	jalr	-1664(ra) # 8000308c <brelse>
}
    80003714:	60e2                	ld	ra,24(sp)
    80003716:	6442                	ld	s0,16(sp)
    80003718:	64a2                	ld	s1,8(sp)
    8000371a:	6902                	ld	s2,0(sp)
    8000371c:	6105                	addi	sp,sp,32
    8000371e:	8082                	ret

0000000080003720 <idup>:
{
    80003720:	1101                	addi	sp,sp,-32
    80003722:	ec06                	sd	ra,24(sp)
    80003724:	e822                	sd	s0,16(sp)
    80003726:	e426                	sd	s1,8(sp)
    80003728:	1000                	addi	s0,sp,32
    8000372a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000372c:	0001d517          	auipc	a0,0x1d
    80003730:	93450513          	addi	a0,a0,-1740 # 80020060 <icache>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	526080e7          	jalr	1318(ra) # 80000c5a <acquire>
  ip->ref++;
    8000373c:	449c                	lw	a5,8(s1)
    8000373e:	2785                	addiw	a5,a5,1
    80003740:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003742:	0001d517          	auipc	a0,0x1d
    80003746:	91e50513          	addi	a0,a0,-1762 # 80020060 <icache>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	5c4080e7          	jalr	1476(ra) # 80000d0e <release>
}
    80003752:	8526                	mv	a0,s1
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <ilock>:
{
    8000375e:	1101                	addi	sp,sp,-32
    80003760:	ec06                	sd	ra,24(sp)
    80003762:	e822                	sd	s0,16(sp)
    80003764:	e426                	sd	s1,8(sp)
    80003766:	e04a                	sd	s2,0(sp)
    80003768:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000376a:	c115                	beqz	a0,8000378e <ilock+0x30>
    8000376c:	84aa                	mv	s1,a0
    8000376e:	451c                	lw	a5,8(a0)
    80003770:	00f05f63          	blez	a5,8000378e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003774:	0541                	addi	a0,a0,16
    80003776:	00001097          	auipc	ra,0x1
    8000377a:	ca2080e7          	jalr	-862(ra) # 80004418 <acquiresleep>
  if(ip->valid == 0){
    8000377e:	40bc                	lw	a5,64(s1)
    80003780:	cf99                	beqz	a5,8000379e <ilock+0x40>
}
    80003782:	60e2                	ld	ra,24(sp)
    80003784:	6442                	ld	s0,16(sp)
    80003786:	64a2                	ld	s1,8(sp)
    80003788:	6902                	ld	s2,0(sp)
    8000378a:	6105                	addi	sp,sp,32
    8000378c:	8082                	ret
    panic("ilock");
    8000378e:	00005517          	auipc	a0,0x5
    80003792:	efa50513          	addi	a0,a0,-262 # 80008688 <syscalls+0x190>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	db2080e7          	jalr	-590(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000379e:	40dc                	lw	a5,4(s1)
    800037a0:	0047d79b          	srliw	a5,a5,0x4
    800037a4:	0001d597          	auipc	a1,0x1d
    800037a8:	8b45a583          	lw	a1,-1868(a1) # 80020058 <sb+0x18>
    800037ac:	9dbd                	addw	a1,a1,a5
    800037ae:	4088                	lw	a0,0(s1)
    800037b0:	fffff097          	auipc	ra,0xfffff
    800037b4:	7ac080e7          	jalr	1964(ra) # 80002f5c <bread>
    800037b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ba:	05850593          	addi	a1,a0,88
    800037be:	40dc                	lw	a5,4(s1)
    800037c0:	8bbd                	andi	a5,a5,15
    800037c2:	079a                	slli	a5,a5,0x6
    800037c4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037c6:	00059783          	lh	a5,0(a1)
    800037ca:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ce:	00259783          	lh	a5,2(a1)
    800037d2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037d6:	00459783          	lh	a5,4(a1)
    800037da:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037de:	00659783          	lh	a5,6(a1)
    800037e2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037e6:	459c                	lw	a5,8(a1)
    800037e8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ea:	03400613          	li	a2,52
    800037ee:	05b1                	addi	a1,a1,12
    800037f0:	05048513          	addi	a0,s1,80
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	5c2080e7          	jalr	1474(ra) # 80000db6 <memmove>
    brelse(bp);
    800037fc:	854a                	mv	a0,s2
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	88e080e7          	jalr	-1906(ra) # 8000308c <brelse>
    ip->valid = 1;
    80003806:	4785                	li	a5,1
    80003808:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000380a:	04449783          	lh	a5,68(s1)
    8000380e:	fbb5                	bnez	a5,80003782 <ilock+0x24>
      panic("ilock: no type");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	e8050513          	addi	a0,a0,-384 # 80008690 <syscalls+0x198>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d30080e7          	jalr	-720(ra) # 80000548 <panic>

0000000080003820 <iunlock>:
{
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	e04a                	sd	s2,0(sp)
    8000382a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000382c:	c905                	beqz	a0,8000385c <iunlock+0x3c>
    8000382e:	84aa                	mv	s1,a0
    80003830:	01050913          	addi	s2,a0,16
    80003834:	854a                	mv	a0,s2
    80003836:	00001097          	auipc	ra,0x1
    8000383a:	c7c080e7          	jalr	-900(ra) # 800044b2 <holdingsleep>
    8000383e:	cd19                	beqz	a0,8000385c <iunlock+0x3c>
    80003840:	449c                	lw	a5,8(s1)
    80003842:	00f05d63          	blez	a5,8000385c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003846:	854a                	mv	a0,s2
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	c26080e7          	jalr	-986(ra) # 8000446e <releasesleep>
}
    80003850:	60e2                	ld	ra,24(sp)
    80003852:	6442                	ld	s0,16(sp)
    80003854:	64a2                	ld	s1,8(sp)
    80003856:	6902                	ld	s2,0(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret
    panic("iunlock");
    8000385c:	00005517          	auipc	a0,0x5
    80003860:	e4450513          	addi	a0,a0,-444 # 800086a0 <syscalls+0x1a8>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	ce4080e7          	jalr	-796(ra) # 80000548 <panic>

000000008000386c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000386c:	7179                	addi	sp,sp,-48
    8000386e:	f406                	sd	ra,40(sp)
    80003870:	f022                	sd	s0,32(sp)
    80003872:	ec26                	sd	s1,24(sp)
    80003874:	e84a                	sd	s2,16(sp)
    80003876:	e44e                	sd	s3,8(sp)
    80003878:	e052                	sd	s4,0(sp)
    8000387a:	1800                	addi	s0,sp,48
    8000387c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000387e:	05050493          	addi	s1,a0,80
    80003882:	08050913          	addi	s2,a0,128
    80003886:	a021                	j	8000388e <itrunc+0x22>
    80003888:	0491                	addi	s1,s1,4
    8000388a:	01248d63          	beq	s1,s2,800038a4 <itrunc+0x38>
    if(ip->addrs[i]){
    8000388e:	408c                	lw	a1,0(s1)
    80003890:	dde5                	beqz	a1,80003888 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003892:	0009a503          	lw	a0,0(s3)
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	90c080e7          	jalr	-1780(ra) # 800031a2 <bfree>
      ip->addrs[i] = 0;
    8000389e:	0004a023          	sw	zero,0(s1)
    800038a2:	b7dd                	j	80003888 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038a4:	0809a583          	lw	a1,128(s3)
    800038a8:	e185                	bnez	a1,800038c8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038aa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ae:	854e                	mv	a0,s3
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	de4080e7          	jalr	-540(ra) # 80003694 <iupdate>
}
    800038b8:	70a2                	ld	ra,40(sp)
    800038ba:	7402                	ld	s0,32(sp)
    800038bc:	64e2                	ld	s1,24(sp)
    800038be:	6942                	ld	s2,16(sp)
    800038c0:	69a2                	ld	s3,8(sp)
    800038c2:	6a02                	ld	s4,0(sp)
    800038c4:	6145                	addi	sp,sp,48
    800038c6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038c8:	0009a503          	lw	a0,0(s3)
    800038cc:	fffff097          	auipc	ra,0xfffff
    800038d0:	690080e7          	jalr	1680(ra) # 80002f5c <bread>
    800038d4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038d6:	05850493          	addi	s1,a0,88
    800038da:	45850913          	addi	s2,a0,1112
    800038de:	a811                	j	800038f2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038e0:	0009a503          	lw	a0,0(s3)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	8be080e7          	jalr	-1858(ra) # 800031a2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038ec:	0491                	addi	s1,s1,4
    800038ee:	01248563          	beq	s1,s2,800038f8 <itrunc+0x8c>
      if(a[j])
    800038f2:	408c                	lw	a1,0(s1)
    800038f4:	dde5                	beqz	a1,800038ec <itrunc+0x80>
    800038f6:	b7ed                	j	800038e0 <itrunc+0x74>
    brelse(bp);
    800038f8:	8552                	mv	a0,s4
    800038fa:	fffff097          	auipc	ra,0xfffff
    800038fe:	792080e7          	jalr	1938(ra) # 8000308c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003902:	0809a583          	lw	a1,128(s3)
    80003906:	0009a503          	lw	a0,0(s3)
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	898080e7          	jalr	-1896(ra) # 800031a2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003912:	0809a023          	sw	zero,128(s3)
    80003916:	bf51                	j	800038aa <itrunc+0x3e>

0000000080003918 <iput>:
{
    80003918:	1101                	addi	sp,sp,-32
    8000391a:	ec06                	sd	ra,24(sp)
    8000391c:	e822                	sd	s0,16(sp)
    8000391e:	e426                	sd	s1,8(sp)
    80003920:	e04a                	sd	s2,0(sp)
    80003922:	1000                	addi	s0,sp,32
    80003924:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003926:	0001c517          	auipc	a0,0x1c
    8000392a:	73a50513          	addi	a0,a0,1850 # 80020060 <icache>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	32c080e7          	jalr	812(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003936:	4498                	lw	a4,8(s1)
    80003938:	4785                	li	a5,1
    8000393a:	02f70363          	beq	a4,a5,80003960 <iput+0x48>
  ip->ref--;
    8000393e:	449c                	lw	a5,8(s1)
    80003940:	37fd                	addiw	a5,a5,-1
    80003942:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003944:	0001c517          	auipc	a0,0x1c
    80003948:	71c50513          	addi	a0,a0,1820 # 80020060 <icache>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	3c2080e7          	jalr	962(ra) # 80000d0e <release>
}
    80003954:	60e2                	ld	ra,24(sp)
    80003956:	6442                	ld	s0,16(sp)
    80003958:	64a2                	ld	s1,8(sp)
    8000395a:	6902                	ld	s2,0(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003960:	40bc                	lw	a5,64(s1)
    80003962:	dff1                	beqz	a5,8000393e <iput+0x26>
    80003964:	04a49783          	lh	a5,74(s1)
    80003968:	fbf9                	bnez	a5,8000393e <iput+0x26>
    acquiresleep(&ip->lock);
    8000396a:	01048913          	addi	s2,s1,16
    8000396e:	854a                	mv	a0,s2
    80003970:	00001097          	auipc	ra,0x1
    80003974:	aa8080e7          	jalr	-1368(ra) # 80004418 <acquiresleep>
    release(&icache.lock);
    80003978:	0001c517          	auipc	a0,0x1c
    8000397c:	6e850513          	addi	a0,a0,1768 # 80020060 <icache>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	38e080e7          	jalr	910(ra) # 80000d0e <release>
    itrunc(ip);
    80003988:	8526                	mv	a0,s1
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	ee2080e7          	jalr	-286(ra) # 8000386c <itrunc>
    ip->type = 0;
    80003992:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003996:	8526                	mv	a0,s1
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	cfc080e7          	jalr	-772(ra) # 80003694 <iupdate>
    ip->valid = 0;
    800039a0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	ac8080e7          	jalr	-1336(ra) # 8000446e <releasesleep>
    acquire(&icache.lock);
    800039ae:	0001c517          	auipc	a0,0x1c
    800039b2:	6b250513          	addi	a0,a0,1714 # 80020060 <icache>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2a4080e7          	jalr	676(ra) # 80000c5a <acquire>
    800039be:	b741                	j	8000393e <iput+0x26>

00000000800039c0 <iunlockput>:
{
    800039c0:	1101                	addi	sp,sp,-32
    800039c2:	ec06                	sd	ra,24(sp)
    800039c4:	e822                	sd	s0,16(sp)
    800039c6:	e426                	sd	s1,8(sp)
    800039c8:	1000                	addi	s0,sp,32
    800039ca:	84aa                	mv	s1,a0
  iunlock(ip);
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	e54080e7          	jalr	-428(ra) # 80003820 <iunlock>
  iput(ip);
    800039d4:	8526                	mv	a0,s1
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	f42080e7          	jalr	-190(ra) # 80003918 <iput>
}
    800039de:	60e2                	ld	ra,24(sp)
    800039e0:	6442                	ld	s0,16(sp)
    800039e2:	64a2                	ld	s1,8(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret

00000000800039e8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039e8:	1141                	addi	sp,sp,-16
    800039ea:	e422                	sd	s0,8(sp)
    800039ec:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ee:	411c                	lw	a5,0(a0)
    800039f0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039f2:	415c                	lw	a5,4(a0)
    800039f4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039f6:	04451783          	lh	a5,68(a0)
    800039fa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039fe:	04a51783          	lh	a5,74(a0)
    80003a02:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a06:	04c56783          	lwu	a5,76(a0)
    80003a0a:	e99c                	sd	a5,16(a1)
}
    80003a0c:	6422                	ld	s0,8(sp)
    80003a0e:	0141                	addi	sp,sp,16
    80003a10:	8082                	ret

0000000080003a12 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a12:	457c                	lw	a5,76(a0)
    80003a14:	0ed7e863          	bltu	a5,a3,80003b04 <readi+0xf2>
{
    80003a18:	7159                	addi	sp,sp,-112
    80003a1a:	f486                	sd	ra,104(sp)
    80003a1c:	f0a2                	sd	s0,96(sp)
    80003a1e:	eca6                	sd	s1,88(sp)
    80003a20:	e8ca                	sd	s2,80(sp)
    80003a22:	e4ce                	sd	s3,72(sp)
    80003a24:	e0d2                	sd	s4,64(sp)
    80003a26:	fc56                	sd	s5,56(sp)
    80003a28:	f85a                	sd	s6,48(sp)
    80003a2a:	f45e                	sd	s7,40(sp)
    80003a2c:	f062                	sd	s8,32(sp)
    80003a2e:	ec66                	sd	s9,24(sp)
    80003a30:	e86a                	sd	s10,16(sp)
    80003a32:	e46e                	sd	s11,8(sp)
    80003a34:	1880                	addi	s0,sp,112
    80003a36:	8baa                	mv	s7,a0
    80003a38:	8c2e                	mv	s8,a1
    80003a3a:	8ab2                	mv	s5,a2
    80003a3c:	84b6                	mv	s1,a3
    80003a3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a40:	9f35                	addw	a4,a4,a3
    return 0;
    80003a42:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a44:	08d76f63          	bltu	a4,a3,80003ae2 <readi+0xd0>
  if(off + n > ip->size)
    80003a48:	00e7f463          	bgeu	a5,a4,80003a50 <readi+0x3e>
    n = ip->size - off;
    80003a4c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a50:	0a0b0863          	beqz	s6,80003b00 <readi+0xee>
    80003a54:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a56:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a5a:	5cfd                	li	s9,-1
    80003a5c:	a82d                	j	80003a96 <readi+0x84>
    80003a5e:	020a1d93          	slli	s11,s4,0x20
    80003a62:	020ddd93          	srli	s11,s11,0x20
    80003a66:	05890613          	addi	a2,s2,88
    80003a6a:	86ee                	mv	a3,s11
    80003a6c:	963a                	add	a2,a2,a4
    80003a6e:	85d6                	mv	a1,s5
    80003a70:	8562                	mv	a0,s8
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	a30080e7          	jalr	-1488(ra) # 800024a2 <either_copyout>
    80003a7a:	05950d63          	beq	a0,s9,80003ad4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a7e:	854a                	mv	a0,s2
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	60c080e7          	jalr	1548(ra) # 8000308c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a88:	013a09bb          	addw	s3,s4,s3
    80003a8c:	009a04bb          	addw	s1,s4,s1
    80003a90:	9aee                	add	s5,s5,s11
    80003a92:	0569f663          	bgeu	s3,s6,80003ade <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a96:	000ba903          	lw	s2,0(s7)
    80003a9a:	00a4d59b          	srliw	a1,s1,0xa
    80003a9e:	855e                	mv	a0,s7
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	8b0080e7          	jalr	-1872(ra) # 80003350 <bmap>
    80003aa8:	0005059b          	sext.w	a1,a0
    80003aac:	854a                	mv	a0,s2
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	4ae080e7          	jalr	1198(ra) # 80002f5c <bread>
    80003ab6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab8:	3ff4f713          	andi	a4,s1,1023
    80003abc:	40ed07bb          	subw	a5,s10,a4
    80003ac0:	413b06bb          	subw	a3,s6,s3
    80003ac4:	8a3e                	mv	s4,a5
    80003ac6:	2781                	sext.w	a5,a5
    80003ac8:	0006861b          	sext.w	a2,a3
    80003acc:	f8f679e3          	bgeu	a2,a5,80003a5e <readi+0x4c>
    80003ad0:	8a36                	mv	s4,a3
    80003ad2:	b771                	j	80003a5e <readi+0x4c>
      brelse(bp);
    80003ad4:	854a                	mv	a0,s2
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	5b6080e7          	jalr	1462(ra) # 8000308c <brelse>
  }
  return tot;
    80003ade:	0009851b          	sext.w	a0,s3
}
    80003ae2:	70a6                	ld	ra,104(sp)
    80003ae4:	7406                	ld	s0,96(sp)
    80003ae6:	64e6                	ld	s1,88(sp)
    80003ae8:	6946                	ld	s2,80(sp)
    80003aea:	69a6                	ld	s3,72(sp)
    80003aec:	6a06                	ld	s4,64(sp)
    80003aee:	7ae2                	ld	s5,56(sp)
    80003af0:	7b42                	ld	s6,48(sp)
    80003af2:	7ba2                	ld	s7,40(sp)
    80003af4:	7c02                	ld	s8,32(sp)
    80003af6:	6ce2                	ld	s9,24(sp)
    80003af8:	6d42                	ld	s10,16(sp)
    80003afa:	6da2                	ld	s11,8(sp)
    80003afc:	6165                	addi	sp,sp,112
    80003afe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b00:	89da                	mv	s3,s6
    80003b02:	bff1                	j	80003ade <readi+0xcc>
    return 0;
    80003b04:	4501                	li	a0,0
}
    80003b06:	8082                	ret

0000000080003b08 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b08:	457c                	lw	a5,76(a0)
    80003b0a:	10d7e663          	bltu	a5,a3,80003c16 <writei+0x10e>
{
    80003b0e:	7159                	addi	sp,sp,-112
    80003b10:	f486                	sd	ra,104(sp)
    80003b12:	f0a2                	sd	s0,96(sp)
    80003b14:	eca6                	sd	s1,88(sp)
    80003b16:	e8ca                	sd	s2,80(sp)
    80003b18:	e4ce                	sd	s3,72(sp)
    80003b1a:	e0d2                	sd	s4,64(sp)
    80003b1c:	fc56                	sd	s5,56(sp)
    80003b1e:	f85a                	sd	s6,48(sp)
    80003b20:	f45e                	sd	s7,40(sp)
    80003b22:	f062                	sd	s8,32(sp)
    80003b24:	ec66                	sd	s9,24(sp)
    80003b26:	e86a                	sd	s10,16(sp)
    80003b28:	e46e                	sd	s11,8(sp)
    80003b2a:	1880                	addi	s0,sp,112
    80003b2c:	8baa                	mv	s7,a0
    80003b2e:	8c2e                	mv	s8,a1
    80003b30:	8ab2                	mv	s5,a2
    80003b32:	8936                	mv	s2,a3
    80003b34:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b36:	00e687bb          	addw	a5,a3,a4
    80003b3a:	0ed7e063          	bltu	a5,a3,80003c1a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b3e:	00043737          	lui	a4,0x43
    80003b42:	0cf76e63          	bltu	a4,a5,80003c1e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b46:	0a0b0763          	beqz	s6,80003bf4 <writei+0xec>
    80003b4a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b50:	5cfd                	li	s9,-1
    80003b52:	a091                	j	80003b96 <writei+0x8e>
    80003b54:	02099d93          	slli	s11,s3,0x20
    80003b58:	020ddd93          	srli	s11,s11,0x20
    80003b5c:	05848513          	addi	a0,s1,88
    80003b60:	86ee                	mv	a3,s11
    80003b62:	8656                	mv	a2,s5
    80003b64:	85e2                	mv	a1,s8
    80003b66:	953a                	add	a0,a0,a4
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	990080e7          	jalr	-1648(ra) # 800024f8 <either_copyin>
    80003b70:	07950263          	beq	a0,s9,80003bd4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b74:	8526                	mv	a0,s1
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	77a080e7          	jalr	1914(ra) # 800042f0 <log_write>
    brelse(bp);
    80003b7e:	8526                	mv	a0,s1
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	50c080e7          	jalr	1292(ra) # 8000308c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b88:	01498a3b          	addw	s4,s3,s4
    80003b8c:	0129893b          	addw	s2,s3,s2
    80003b90:	9aee                	add	s5,s5,s11
    80003b92:	056a7663          	bgeu	s4,s6,80003bde <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b96:	000ba483          	lw	s1,0(s7)
    80003b9a:	00a9559b          	srliw	a1,s2,0xa
    80003b9e:	855e                	mv	a0,s7
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	7b0080e7          	jalr	1968(ra) # 80003350 <bmap>
    80003ba8:	0005059b          	sext.w	a1,a0
    80003bac:	8526                	mv	a0,s1
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	3ae080e7          	jalr	942(ra) # 80002f5c <bread>
    80003bb6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb8:	3ff97713          	andi	a4,s2,1023
    80003bbc:	40ed07bb          	subw	a5,s10,a4
    80003bc0:	414b06bb          	subw	a3,s6,s4
    80003bc4:	89be                	mv	s3,a5
    80003bc6:	2781                	sext.w	a5,a5
    80003bc8:	0006861b          	sext.w	a2,a3
    80003bcc:	f8f674e3          	bgeu	a2,a5,80003b54 <writei+0x4c>
    80003bd0:	89b6                	mv	s3,a3
    80003bd2:	b749                	j	80003b54 <writei+0x4c>
      brelse(bp);
    80003bd4:	8526                	mv	a0,s1
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	4b6080e7          	jalr	1206(ra) # 8000308c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bde:	04cba783          	lw	a5,76(s7)
    80003be2:	0127f463          	bgeu	a5,s2,80003bea <writei+0xe2>
      ip->size = off;
    80003be6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bea:	855e                	mv	a0,s7
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	aa8080e7          	jalr	-1368(ra) # 80003694 <iupdate>
  }

  return n;
    80003bf4:	000b051b          	sext.w	a0,s6
}
    80003bf8:	70a6                	ld	ra,104(sp)
    80003bfa:	7406                	ld	s0,96(sp)
    80003bfc:	64e6                	ld	s1,88(sp)
    80003bfe:	6946                	ld	s2,80(sp)
    80003c00:	69a6                	ld	s3,72(sp)
    80003c02:	6a06                	ld	s4,64(sp)
    80003c04:	7ae2                	ld	s5,56(sp)
    80003c06:	7b42                	ld	s6,48(sp)
    80003c08:	7ba2                	ld	s7,40(sp)
    80003c0a:	7c02                	ld	s8,32(sp)
    80003c0c:	6ce2                	ld	s9,24(sp)
    80003c0e:	6d42                	ld	s10,16(sp)
    80003c10:	6da2                	ld	s11,8(sp)
    80003c12:	6165                	addi	sp,sp,112
    80003c14:	8082                	ret
    return -1;
    80003c16:	557d                	li	a0,-1
}
    80003c18:	8082                	ret
    return -1;
    80003c1a:	557d                	li	a0,-1
    80003c1c:	bff1                	j	80003bf8 <writei+0xf0>
    return -1;
    80003c1e:	557d                	li	a0,-1
    80003c20:	bfe1                	j	80003bf8 <writei+0xf0>

0000000080003c22 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c22:	1141                	addi	sp,sp,-16
    80003c24:	e406                	sd	ra,8(sp)
    80003c26:	e022                	sd	s0,0(sp)
    80003c28:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c2a:	4639                	li	a2,14
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	206080e7          	jalr	518(ra) # 80000e32 <strncmp>
}
    80003c34:	60a2                	ld	ra,8(sp)
    80003c36:	6402                	ld	s0,0(sp)
    80003c38:	0141                	addi	sp,sp,16
    80003c3a:	8082                	ret

0000000080003c3c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c3c:	7139                	addi	sp,sp,-64
    80003c3e:	fc06                	sd	ra,56(sp)
    80003c40:	f822                	sd	s0,48(sp)
    80003c42:	f426                	sd	s1,40(sp)
    80003c44:	f04a                	sd	s2,32(sp)
    80003c46:	ec4e                	sd	s3,24(sp)
    80003c48:	e852                	sd	s4,16(sp)
    80003c4a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c4c:	04451703          	lh	a4,68(a0)
    80003c50:	4785                	li	a5,1
    80003c52:	00f71a63          	bne	a4,a5,80003c66 <dirlookup+0x2a>
    80003c56:	892a                	mv	s2,a0
    80003c58:	89ae                	mv	s3,a1
    80003c5a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5c:	457c                	lw	a5,76(a0)
    80003c5e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c60:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c62:	e79d                	bnez	a5,80003c90 <dirlookup+0x54>
    80003c64:	a8a5                	j	80003cdc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c66:	00005517          	auipc	a0,0x5
    80003c6a:	a4250513          	addi	a0,a0,-1470 # 800086a8 <syscalls+0x1b0>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8da080e7          	jalr	-1830(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c76:	00005517          	auipc	a0,0x5
    80003c7a:	a4a50513          	addi	a0,a0,-1462 # 800086c0 <syscalls+0x1c8>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	8ca080e7          	jalr	-1846(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c86:	24c1                	addiw	s1,s1,16
    80003c88:	04c92783          	lw	a5,76(s2)
    80003c8c:	04f4f763          	bgeu	s1,a5,80003cda <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c90:	4741                	li	a4,16
    80003c92:	86a6                	mv	a3,s1
    80003c94:	fc040613          	addi	a2,s0,-64
    80003c98:	4581                	li	a1,0
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	d76080e7          	jalr	-650(ra) # 80003a12 <readi>
    80003ca4:	47c1                	li	a5,16
    80003ca6:	fcf518e3          	bne	a0,a5,80003c76 <dirlookup+0x3a>
    if(de.inum == 0)
    80003caa:	fc045783          	lhu	a5,-64(s0)
    80003cae:	dfe1                	beqz	a5,80003c86 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cb0:	fc240593          	addi	a1,s0,-62
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	f6c080e7          	jalr	-148(ra) # 80003c22 <namecmp>
    80003cbe:	f561                	bnez	a0,80003c86 <dirlookup+0x4a>
      if(poff)
    80003cc0:	000a0463          	beqz	s4,80003cc8 <dirlookup+0x8c>
        *poff = off;
    80003cc4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cc8:	fc045583          	lhu	a1,-64(s0)
    80003ccc:	00092503          	lw	a0,0(s2)
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	75a080e7          	jalr	1882(ra) # 8000342a <iget>
    80003cd8:	a011                	j	80003cdc <dirlookup+0xa0>
  return 0;
    80003cda:	4501                	li	a0,0
}
    80003cdc:	70e2                	ld	ra,56(sp)
    80003cde:	7442                	ld	s0,48(sp)
    80003ce0:	74a2                	ld	s1,40(sp)
    80003ce2:	7902                	ld	s2,32(sp)
    80003ce4:	69e2                	ld	s3,24(sp)
    80003ce6:	6a42                	ld	s4,16(sp)
    80003ce8:	6121                	addi	sp,sp,64
    80003cea:	8082                	ret

0000000080003cec <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cec:	711d                	addi	sp,sp,-96
    80003cee:	ec86                	sd	ra,88(sp)
    80003cf0:	e8a2                	sd	s0,80(sp)
    80003cf2:	e4a6                	sd	s1,72(sp)
    80003cf4:	e0ca                	sd	s2,64(sp)
    80003cf6:	fc4e                	sd	s3,56(sp)
    80003cf8:	f852                	sd	s4,48(sp)
    80003cfa:	f456                	sd	s5,40(sp)
    80003cfc:	f05a                	sd	s6,32(sp)
    80003cfe:	ec5e                	sd	s7,24(sp)
    80003d00:	e862                	sd	s8,16(sp)
    80003d02:	e466                	sd	s9,8(sp)
    80003d04:	1080                	addi	s0,sp,96
    80003d06:	84aa                	mv	s1,a0
    80003d08:	8b2e                	mv	s6,a1
    80003d0a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d0c:	00054703          	lbu	a4,0(a0)
    80003d10:	02f00793          	li	a5,47
    80003d14:	02f70363          	beq	a4,a5,80003d3a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d18:	ffffe097          	auipc	ra,0xffffe
    80003d1c:	d10080e7          	jalr	-752(ra) # 80001a28 <myproc>
    80003d20:	15053503          	ld	a0,336(a0)
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	9fc080e7          	jalr	-1540(ra) # 80003720 <idup>
    80003d2c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d2e:	02f00913          	li	s2,47
  len = path - s;
    80003d32:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d34:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d36:	4c05                	li	s8,1
    80003d38:	a865                	j	80003df0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d3a:	4585                	li	a1,1
    80003d3c:	4505                	li	a0,1
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	6ec080e7          	jalr	1772(ra) # 8000342a <iget>
    80003d46:	89aa                	mv	s3,a0
    80003d48:	b7dd                	j	80003d2e <namex+0x42>
      iunlockput(ip);
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	c74080e7          	jalr	-908(ra) # 800039c0 <iunlockput>
      return 0;
    80003d54:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d56:	854e                	mv	a0,s3
    80003d58:	60e6                	ld	ra,88(sp)
    80003d5a:	6446                	ld	s0,80(sp)
    80003d5c:	64a6                	ld	s1,72(sp)
    80003d5e:	6906                	ld	s2,64(sp)
    80003d60:	79e2                	ld	s3,56(sp)
    80003d62:	7a42                	ld	s4,48(sp)
    80003d64:	7aa2                	ld	s5,40(sp)
    80003d66:	7b02                	ld	s6,32(sp)
    80003d68:	6be2                	ld	s7,24(sp)
    80003d6a:	6c42                	ld	s8,16(sp)
    80003d6c:	6ca2                	ld	s9,8(sp)
    80003d6e:	6125                	addi	sp,sp,96
    80003d70:	8082                	ret
      iunlock(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	aac080e7          	jalr	-1364(ra) # 80003820 <iunlock>
      return ip;
    80003d7c:	bfe9                	j	80003d56 <namex+0x6a>
      iunlockput(ip);
    80003d7e:	854e                	mv	a0,s3
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	c40080e7          	jalr	-960(ra) # 800039c0 <iunlockput>
      return 0;
    80003d88:	89d2                	mv	s3,s4
    80003d8a:	b7f1                	j	80003d56 <namex+0x6a>
  len = path - s;
    80003d8c:	40b48633          	sub	a2,s1,a1
    80003d90:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d94:	094cd463          	bge	s9,s4,80003e1c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d98:	4639                	li	a2,14
    80003d9a:	8556                	mv	a0,s5
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	01a080e7          	jalr	26(ra) # 80000db6 <memmove>
  while(*path == '/')
    80003da4:	0004c783          	lbu	a5,0(s1)
    80003da8:	01279763          	bne	a5,s2,80003db6 <namex+0xca>
    path++;
    80003dac:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	ff278de3          	beq	a5,s2,80003dac <namex+0xc0>
    ilock(ip);
    80003db6:	854e                	mv	a0,s3
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	9a6080e7          	jalr	-1626(ra) # 8000375e <ilock>
    if(ip->type != T_DIR){
    80003dc0:	04499783          	lh	a5,68(s3)
    80003dc4:	f98793e3          	bne	a5,s8,80003d4a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dc8:	000b0563          	beqz	s6,80003dd2 <namex+0xe6>
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	d3cd                	beqz	a5,80003d72 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dd2:	865e                	mv	a2,s7
    80003dd4:	85d6                	mv	a1,s5
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	e64080e7          	jalr	-412(ra) # 80003c3c <dirlookup>
    80003de0:	8a2a                	mv	s4,a0
    80003de2:	dd51                	beqz	a0,80003d7e <namex+0x92>
    iunlockput(ip);
    80003de4:	854e                	mv	a0,s3
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	bda080e7          	jalr	-1062(ra) # 800039c0 <iunlockput>
    ip = next;
    80003dee:	89d2                	mv	s3,s4
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	05279763          	bne	a5,s2,80003e42 <namex+0x156>
    path++;
    80003df8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	ff278de3          	beq	a5,s2,80003df8 <namex+0x10c>
  if(*path == 0)
    80003e02:	c79d                	beqz	a5,80003e30 <namex+0x144>
    path++;
    80003e04:	85a6                	mv	a1,s1
  len = path - s;
    80003e06:	8a5e                	mv	s4,s7
    80003e08:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e0a:	01278963          	beq	a5,s2,80003e1c <namex+0x130>
    80003e0e:	dfbd                	beqz	a5,80003d8c <namex+0xa0>
    path++;
    80003e10:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	ff279ce3          	bne	a5,s2,80003e0e <namex+0x122>
    80003e1a:	bf8d                	j	80003d8c <namex+0xa0>
    memmove(name, s, len);
    80003e1c:	2601                	sext.w	a2,a2
    80003e1e:	8556                	mv	a0,s5
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	f96080e7          	jalr	-106(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003e28:	9a56                	add	s4,s4,s5
    80003e2a:	000a0023          	sb	zero,0(s4)
    80003e2e:	bf9d                	j	80003da4 <namex+0xb8>
  if(nameiparent){
    80003e30:	f20b03e3          	beqz	s6,80003d56 <namex+0x6a>
    iput(ip);
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	ae2080e7          	jalr	-1310(ra) # 80003918 <iput>
    return 0;
    80003e3e:	4981                	li	s3,0
    80003e40:	bf19                	j	80003d56 <namex+0x6a>
  if(*path == 0)
    80003e42:	d7fd                	beqz	a5,80003e30 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	85a6                	mv	a1,s1
    80003e4a:	b7d1                	j	80003e0e <namex+0x122>

0000000080003e4c <dirlink>:
{
    80003e4c:	7139                	addi	sp,sp,-64
    80003e4e:	fc06                	sd	ra,56(sp)
    80003e50:	f822                	sd	s0,48(sp)
    80003e52:	f426                	sd	s1,40(sp)
    80003e54:	f04a                	sd	s2,32(sp)
    80003e56:	ec4e                	sd	s3,24(sp)
    80003e58:	e852                	sd	s4,16(sp)
    80003e5a:	0080                	addi	s0,sp,64
    80003e5c:	892a                	mv	s2,a0
    80003e5e:	8a2e                	mv	s4,a1
    80003e60:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e62:	4601                	li	a2,0
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	dd8080e7          	jalr	-552(ra) # 80003c3c <dirlookup>
    80003e6c:	e93d                	bnez	a0,80003ee2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6e:	04c92483          	lw	s1,76(s2)
    80003e72:	c49d                	beqz	s1,80003ea0 <dirlink+0x54>
    80003e74:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e76:	4741                	li	a4,16
    80003e78:	86a6                	mv	a3,s1
    80003e7a:	fc040613          	addi	a2,s0,-64
    80003e7e:	4581                	li	a1,0
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	b90080e7          	jalr	-1136(ra) # 80003a12 <readi>
    80003e8a:	47c1                	li	a5,16
    80003e8c:	06f51163          	bne	a0,a5,80003eee <dirlink+0xa2>
    if(de.inum == 0)
    80003e90:	fc045783          	lhu	a5,-64(s0)
    80003e94:	c791                	beqz	a5,80003ea0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e96:	24c1                	addiw	s1,s1,16
    80003e98:	04c92783          	lw	a5,76(s2)
    80003e9c:	fcf4ede3          	bltu	s1,a5,80003e76 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ea0:	4639                	li	a2,14
    80003ea2:	85d2                	mv	a1,s4
    80003ea4:	fc240513          	addi	a0,s0,-62
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	fc6080e7          	jalr	-58(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003eb0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb4:	4741                	li	a4,16
    80003eb6:	86a6                	mv	a3,s1
    80003eb8:	fc040613          	addi	a2,s0,-64
    80003ebc:	4581                	li	a1,0
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	c48080e7          	jalr	-952(ra) # 80003b08 <writei>
    80003ec8:	872a                	mv	a4,a0
    80003eca:	47c1                	li	a5,16
  return 0;
    80003ecc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ece:	02f71863          	bne	a4,a5,80003efe <dirlink+0xb2>
}
    80003ed2:	70e2                	ld	ra,56(sp)
    80003ed4:	7442                	ld	s0,48(sp)
    80003ed6:	74a2                	ld	s1,40(sp)
    80003ed8:	7902                	ld	s2,32(sp)
    80003eda:	69e2                	ld	s3,24(sp)
    80003edc:	6a42                	ld	s4,16(sp)
    80003ede:	6121                	addi	sp,sp,64
    80003ee0:	8082                	ret
    iput(ip);
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	a36080e7          	jalr	-1482(ra) # 80003918 <iput>
    return -1;
    80003eea:	557d                	li	a0,-1
    80003eec:	b7dd                	j	80003ed2 <dirlink+0x86>
      panic("dirlink read");
    80003eee:	00004517          	auipc	a0,0x4
    80003ef2:	7e250513          	addi	a0,a0,2018 # 800086d0 <syscalls+0x1d8>
    80003ef6:	ffffc097          	auipc	ra,0xffffc
    80003efa:	652080e7          	jalr	1618(ra) # 80000548 <panic>
    panic("dirlink");
    80003efe:	00005517          	auipc	a0,0x5
    80003f02:	8ea50513          	addi	a0,a0,-1814 # 800087e8 <syscalls+0x2f0>
    80003f06:	ffffc097          	auipc	ra,0xffffc
    80003f0a:	642080e7          	jalr	1602(ra) # 80000548 <panic>

0000000080003f0e <namei>:

struct inode*
namei(char *path)
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f16:	fe040613          	addi	a2,s0,-32
    80003f1a:	4581                	li	a1,0
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	dd0080e7          	jalr	-560(ra) # 80003cec <namex>
}
    80003f24:	60e2                	ld	ra,24(sp)
    80003f26:	6442                	ld	s0,16(sp)
    80003f28:	6105                	addi	sp,sp,32
    80003f2a:	8082                	ret

0000000080003f2c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f2c:	1141                	addi	sp,sp,-16
    80003f2e:	e406                	sd	ra,8(sp)
    80003f30:	e022                	sd	s0,0(sp)
    80003f32:	0800                	addi	s0,sp,16
    80003f34:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f36:	4585                	li	a1,1
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	db4080e7          	jalr	-588(ra) # 80003cec <namex>
}
    80003f40:	60a2                	ld	ra,8(sp)
    80003f42:	6402                	ld	s0,0(sp)
    80003f44:	0141                	addi	sp,sp,16
    80003f46:	8082                	ret

0000000080003f48 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f48:	1101                	addi	sp,sp,-32
    80003f4a:	ec06                	sd	ra,24(sp)
    80003f4c:	e822                	sd	s0,16(sp)
    80003f4e:	e426                	sd	s1,8(sp)
    80003f50:	e04a                	sd	s2,0(sp)
    80003f52:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f54:	0001e917          	auipc	s2,0x1e
    80003f58:	bb490913          	addi	s2,s2,-1100 # 80021b08 <log>
    80003f5c:	01892583          	lw	a1,24(s2)
    80003f60:	02892503          	lw	a0,40(s2)
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	ff8080e7          	jalr	-8(ra) # 80002f5c <bread>
    80003f6c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f6e:	02c92683          	lw	a3,44(s2)
    80003f72:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f74:	02d05763          	blez	a3,80003fa2 <write_head+0x5a>
    80003f78:	0001e797          	auipc	a5,0x1e
    80003f7c:	bc078793          	addi	a5,a5,-1088 # 80021b38 <log+0x30>
    80003f80:	05c50713          	addi	a4,a0,92
    80003f84:	36fd                	addiw	a3,a3,-1
    80003f86:	1682                	slli	a3,a3,0x20
    80003f88:	9281                	srli	a3,a3,0x20
    80003f8a:	068a                	slli	a3,a3,0x2
    80003f8c:	0001e617          	auipc	a2,0x1e
    80003f90:	bb060613          	addi	a2,a2,-1104 # 80021b3c <log+0x34>
    80003f94:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f96:	4390                	lw	a2,0(a5)
    80003f98:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f9a:	0791                	addi	a5,a5,4
    80003f9c:	0711                	addi	a4,a4,4
    80003f9e:	fed79ce3          	bne	a5,a3,80003f96 <write_head+0x4e>
  }
  bwrite(buf);
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	0aa080e7          	jalr	170(ra) # 8000304e <bwrite>
  brelse(buf);
    80003fac:	8526                	mv	a0,s1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	0de080e7          	jalr	222(ra) # 8000308c <brelse>
}
    80003fb6:	60e2                	ld	ra,24(sp)
    80003fb8:	6442                	ld	s0,16(sp)
    80003fba:	64a2                	ld	s1,8(sp)
    80003fbc:	6902                	ld	s2,0(sp)
    80003fbe:	6105                	addi	sp,sp,32
    80003fc0:	8082                	ret

0000000080003fc2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc2:	0001e797          	auipc	a5,0x1e
    80003fc6:	b727a783          	lw	a5,-1166(a5) # 80021b34 <log+0x2c>
    80003fca:	0af05663          	blez	a5,80004076 <install_trans+0xb4>
{
    80003fce:	7139                	addi	sp,sp,-64
    80003fd0:	fc06                	sd	ra,56(sp)
    80003fd2:	f822                	sd	s0,48(sp)
    80003fd4:	f426                	sd	s1,40(sp)
    80003fd6:	f04a                	sd	s2,32(sp)
    80003fd8:	ec4e                	sd	s3,24(sp)
    80003fda:	e852                	sd	s4,16(sp)
    80003fdc:	e456                	sd	s5,8(sp)
    80003fde:	0080                	addi	s0,sp,64
    80003fe0:	0001ea97          	auipc	s5,0x1e
    80003fe4:	b58a8a93          	addi	s5,s5,-1192 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fe8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fea:	0001e997          	auipc	s3,0x1e
    80003fee:	b1e98993          	addi	s3,s3,-1250 # 80021b08 <log>
    80003ff2:	0189a583          	lw	a1,24(s3)
    80003ff6:	014585bb          	addw	a1,a1,s4
    80003ffa:	2585                	addiw	a1,a1,1
    80003ffc:	0289a503          	lw	a0,40(s3)
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	f5c080e7          	jalr	-164(ra) # 80002f5c <bread>
    80004008:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000400a:	000aa583          	lw	a1,0(s5)
    8000400e:	0289a503          	lw	a0,40(s3)
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	f4a080e7          	jalr	-182(ra) # 80002f5c <bread>
    8000401a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000401c:	40000613          	li	a2,1024
    80004020:	05890593          	addi	a1,s2,88
    80004024:	05850513          	addi	a0,a0,88
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	d8e080e7          	jalr	-626(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	01c080e7          	jalr	28(ra) # 8000304e <bwrite>
    bunpin(dbuf);
    8000403a:	8526                	mv	a0,s1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	12a080e7          	jalr	298(ra) # 80003166 <bunpin>
    brelse(lbuf);
    80004044:	854a                	mv	a0,s2
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	046080e7          	jalr	70(ra) # 8000308c <brelse>
    brelse(dbuf);
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	03c080e7          	jalr	60(ra) # 8000308c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004058:	2a05                	addiw	s4,s4,1
    8000405a:	0a91                	addi	s5,s5,4
    8000405c:	02c9a783          	lw	a5,44(s3)
    80004060:	f8fa49e3          	blt	s4,a5,80003ff2 <install_trans+0x30>
}
    80004064:	70e2                	ld	ra,56(sp)
    80004066:	7442                	ld	s0,48(sp)
    80004068:	74a2                	ld	s1,40(sp)
    8000406a:	7902                	ld	s2,32(sp)
    8000406c:	69e2                	ld	s3,24(sp)
    8000406e:	6a42                	ld	s4,16(sp)
    80004070:	6aa2                	ld	s5,8(sp)
    80004072:	6121                	addi	sp,sp,64
    80004074:	8082                	ret
    80004076:	8082                	ret

0000000080004078 <initlog>:
{
    80004078:	7179                	addi	sp,sp,-48
    8000407a:	f406                	sd	ra,40(sp)
    8000407c:	f022                	sd	s0,32(sp)
    8000407e:	ec26                	sd	s1,24(sp)
    80004080:	e84a                	sd	s2,16(sp)
    80004082:	e44e                	sd	s3,8(sp)
    80004084:	1800                	addi	s0,sp,48
    80004086:	892a                	mv	s2,a0
    80004088:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000408a:	0001e497          	auipc	s1,0x1e
    8000408e:	a7e48493          	addi	s1,s1,-1410 # 80021b08 <log>
    80004092:	00004597          	auipc	a1,0x4
    80004096:	64e58593          	addi	a1,a1,1614 # 800086e0 <syscalls+0x1e8>
    8000409a:	8526                	mv	a0,s1
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	b2e080e7          	jalr	-1234(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    800040a4:	0149a583          	lw	a1,20(s3)
    800040a8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040aa:	0109a783          	lw	a5,16(s3)
    800040ae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040b0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040b4:	854a                	mv	a0,s2
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	ea6080e7          	jalr	-346(ra) # 80002f5c <bread>
  log.lh.n = lh->n;
    800040be:	4d3c                	lw	a5,88(a0)
    800040c0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040c2:	02f05563          	blez	a5,800040ec <initlog+0x74>
    800040c6:	05c50713          	addi	a4,a0,92
    800040ca:	0001e697          	auipc	a3,0x1e
    800040ce:	a6e68693          	addi	a3,a3,-1426 # 80021b38 <log+0x30>
    800040d2:	37fd                	addiw	a5,a5,-1
    800040d4:	1782                	slli	a5,a5,0x20
    800040d6:	9381                	srli	a5,a5,0x20
    800040d8:	078a                	slli	a5,a5,0x2
    800040da:	06050613          	addi	a2,a0,96
    800040de:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040e0:	4310                	lw	a2,0(a4)
    800040e2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040e4:	0711                	addi	a4,a4,4
    800040e6:	0691                	addi	a3,a3,4
    800040e8:	fef71ce3          	bne	a4,a5,800040e0 <initlog+0x68>
  brelse(buf);
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	fa0080e7          	jalr	-96(ra) # 8000308c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	ece080e7          	jalr	-306(ra) # 80003fc2 <install_trans>
  log.lh.n = 0;
    800040fc:	0001e797          	auipc	a5,0x1e
    80004100:	a207ac23          	sw	zero,-1480(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004104:	00000097          	auipc	ra,0x0
    80004108:	e44080e7          	jalr	-444(ra) # 80003f48 <write_head>
}
    8000410c:	70a2                	ld	ra,40(sp)
    8000410e:	7402                	ld	s0,32(sp)
    80004110:	64e2                	ld	s1,24(sp)
    80004112:	6942                	ld	s2,16(sp)
    80004114:	69a2                	ld	s3,8(sp)
    80004116:	6145                	addi	sp,sp,48
    80004118:	8082                	ret

000000008000411a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	e426                	sd	s1,8(sp)
    80004122:	e04a                	sd	s2,0(sp)
    80004124:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004126:	0001e517          	auipc	a0,0x1e
    8000412a:	9e250513          	addi	a0,a0,-1566 # 80021b08 <log>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	b2c080e7          	jalr	-1236(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    80004136:	0001e497          	auipc	s1,0x1e
    8000413a:	9d248493          	addi	s1,s1,-1582 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000413e:	4979                	li	s2,30
    80004140:	a039                	j	8000414e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004142:	85a6                	mv	a1,s1
    80004144:	8526                	mv	a0,s1
    80004146:	ffffe097          	auipc	ra,0xffffe
    8000414a:	0fa080e7          	jalr	250(ra) # 80002240 <sleep>
    if(log.committing){
    8000414e:	50dc                	lw	a5,36(s1)
    80004150:	fbed                	bnez	a5,80004142 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004152:	509c                	lw	a5,32(s1)
    80004154:	0017871b          	addiw	a4,a5,1
    80004158:	0007069b          	sext.w	a3,a4
    8000415c:	0027179b          	slliw	a5,a4,0x2
    80004160:	9fb9                	addw	a5,a5,a4
    80004162:	0017979b          	slliw	a5,a5,0x1
    80004166:	54d8                	lw	a4,44(s1)
    80004168:	9fb9                	addw	a5,a5,a4
    8000416a:	00f95963          	bge	s2,a5,8000417c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000416e:	85a6                	mv	a1,s1
    80004170:	8526                	mv	a0,s1
    80004172:	ffffe097          	auipc	ra,0xffffe
    80004176:	0ce080e7          	jalr	206(ra) # 80002240 <sleep>
    8000417a:	bfd1                	j	8000414e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000417c:	0001e517          	auipc	a0,0x1e
    80004180:	98c50513          	addi	a0,a0,-1652 # 80021b08 <log>
    80004184:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	b88080e7          	jalr	-1144(ra) # 80000d0e <release>
      break;
    }
  }
}
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6902                	ld	s2,0(sp)
    80004196:	6105                	addi	sp,sp,32
    80004198:	8082                	ret

000000008000419a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000419a:	7139                	addi	sp,sp,-64
    8000419c:	fc06                	sd	ra,56(sp)
    8000419e:	f822                	sd	s0,48(sp)
    800041a0:	f426                	sd	s1,40(sp)
    800041a2:	f04a                	sd	s2,32(sp)
    800041a4:	ec4e                	sd	s3,24(sp)
    800041a6:	e852                	sd	s4,16(sp)
    800041a8:	e456                	sd	s5,8(sp)
    800041aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ac:	0001e497          	auipc	s1,0x1e
    800041b0:	95c48493          	addi	s1,s1,-1700 # 80021b08 <log>
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	aa4080e7          	jalr	-1372(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    800041be:	509c                	lw	a5,32(s1)
    800041c0:	37fd                	addiw	a5,a5,-1
    800041c2:	0007891b          	sext.w	s2,a5
    800041c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041c8:	50dc                	lw	a5,36(s1)
    800041ca:	efb9                	bnez	a5,80004228 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041cc:	06091663          	bnez	s2,80004238 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041d0:	0001e497          	auipc	s1,0x1e
    800041d4:	93848493          	addi	s1,s1,-1736 # 80021b08 <log>
    800041d8:	4785                	li	a5,1
    800041da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	b30080e7          	jalr	-1232(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041e6:	54dc                	lw	a5,44(s1)
    800041e8:	06f04763          	bgtz	a5,80004256 <end_op+0xbc>
    acquire(&log.lock);
    800041ec:	0001e497          	auipc	s1,0x1e
    800041f0:	91c48493          	addi	s1,s1,-1764 # 80021b08 <log>
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	a64080e7          	jalr	-1436(ra) # 80000c5a <acquire>
    log.committing = 0;
    800041fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	1c2080e7          	jalr	450(ra) # 800023c6 <wakeup>
    release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	b00080e7          	jalr	-1280(ra) # 80000d0e <release>
}
    80004216:	70e2                	ld	ra,56(sp)
    80004218:	7442                	ld	s0,48(sp)
    8000421a:	74a2                	ld	s1,40(sp)
    8000421c:	7902                	ld	s2,32(sp)
    8000421e:	69e2                	ld	s3,24(sp)
    80004220:	6a42                	ld	s4,16(sp)
    80004222:	6aa2                	ld	s5,8(sp)
    80004224:	6121                	addi	sp,sp,64
    80004226:	8082                	ret
    panic("log.committing");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	4c050513          	addi	a0,a0,1216 # 800086e8 <syscalls+0x1f0>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	318080e7          	jalr	792(ra) # 80000548 <panic>
    wakeup(&log);
    80004238:	0001e497          	auipc	s1,0x1e
    8000423c:	8d048493          	addi	s1,s1,-1840 # 80021b08 <log>
    80004240:	8526                	mv	a0,s1
    80004242:	ffffe097          	auipc	ra,0xffffe
    80004246:	184080e7          	jalr	388(ra) # 800023c6 <wakeup>
  release(&log.lock);
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
  if(do_commit){
    80004254:	b7c9                	j	80004216 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004256:	0001ea97          	auipc	s5,0x1e
    8000425a:	8e2a8a93          	addi	s5,s5,-1822 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000425e:	0001ea17          	auipc	s4,0x1e
    80004262:	8aaa0a13          	addi	s4,s4,-1878 # 80021b08 <log>
    80004266:	018a2583          	lw	a1,24(s4)
    8000426a:	012585bb          	addw	a1,a1,s2
    8000426e:	2585                	addiw	a1,a1,1
    80004270:	028a2503          	lw	a0,40(s4)
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	ce8080e7          	jalr	-792(ra) # 80002f5c <bread>
    8000427c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000427e:	000aa583          	lw	a1,0(s5)
    80004282:	028a2503          	lw	a0,40(s4)
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	cd6080e7          	jalr	-810(ra) # 80002f5c <bread>
    8000428e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004290:	40000613          	li	a2,1024
    80004294:	05850593          	addi	a1,a0,88
    80004298:	05848513          	addi	a0,s1,88
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	b1a080e7          	jalr	-1254(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    800042a4:	8526                	mv	a0,s1
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	da8080e7          	jalr	-600(ra) # 8000304e <bwrite>
    brelse(from);
    800042ae:	854e                	mv	a0,s3
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	ddc080e7          	jalr	-548(ra) # 8000308c <brelse>
    brelse(to);
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	dd2080e7          	jalr	-558(ra) # 8000308c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	2905                	addiw	s2,s2,1
    800042c4:	0a91                	addi	s5,s5,4
    800042c6:	02ca2783          	lw	a5,44(s4)
    800042ca:	f8f94ee3          	blt	s2,a5,80004266 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c7a080e7          	jalr	-902(ra) # 80003f48 <write_head>
    install_trans(); // Now install writes to home locations
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	cec080e7          	jalr	-788(ra) # 80003fc2 <install_trans>
    log.lh.n = 0;
    800042de:	0001e797          	auipc	a5,0x1e
    800042e2:	8407ab23          	sw	zero,-1962(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	c62080e7          	jalr	-926(ra) # 80003f48 <write_head>
    800042ee:	bdfd                	j	800041ec <end_op+0x52>

00000000800042f0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	e426                	sd	s1,8(sp)
    800042f8:	e04a                	sd	s2,0(sp)
    800042fa:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042fc:	0001e717          	auipc	a4,0x1e
    80004300:	83872703          	lw	a4,-1992(a4) # 80021b34 <log+0x2c>
    80004304:	47f5                	li	a5,29
    80004306:	08e7c063          	blt	a5,a4,80004386 <log_write+0x96>
    8000430a:	84aa                	mv	s1,a0
    8000430c:	0001e797          	auipc	a5,0x1e
    80004310:	8187a783          	lw	a5,-2024(a5) # 80021b24 <log+0x1c>
    80004314:	37fd                	addiw	a5,a5,-1
    80004316:	06f75863          	bge	a4,a5,80004386 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000431a:	0001e797          	auipc	a5,0x1e
    8000431e:	80e7a783          	lw	a5,-2034(a5) # 80021b28 <log+0x20>
    80004322:	06f05a63          	blez	a5,80004396 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004326:	0001d917          	auipc	s2,0x1d
    8000432a:	7e290913          	addi	s2,s2,2018 # 80021b08 <log>
    8000432e:	854a                	mv	a0,s2
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	92a080e7          	jalr	-1750(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004338:	02c92603          	lw	a2,44(s2)
    8000433c:	06c05563          	blez	a2,800043a6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004340:	44cc                	lw	a1,12(s1)
    80004342:	0001d717          	auipc	a4,0x1d
    80004346:	7f670713          	addi	a4,a4,2038 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000434a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000434c:	4314                	lw	a3,0(a4)
    8000434e:	04b68d63          	beq	a3,a1,800043a8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004352:	2785                	addiw	a5,a5,1
    80004354:	0711                	addi	a4,a4,4
    80004356:	fec79be3          	bne	a5,a2,8000434c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000435a:	0621                	addi	a2,a2,8
    8000435c:	060a                	slli	a2,a2,0x2
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	7aa78793          	addi	a5,a5,1962 # 80021b08 <log>
    80004366:	963e                	add	a2,a2,a5
    80004368:	44dc                	lw	a5,12(s1)
    8000436a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	dbc080e7          	jalr	-580(ra) # 8000312a <bpin>
    log.lh.n++;
    80004376:	0001d717          	auipc	a4,0x1d
    8000437a:	79270713          	addi	a4,a4,1938 # 80021b08 <log>
    8000437e:	575c                	lw	a5,44(a4)
    80004380:	2785                	addiw	a5,a5,1
    80004382:	d75c                	sw	a5,44(a4)
    80004384:	a83d                	j	800043c2 <log_write+0xd2>
    panic("too big a transaction");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	37250513          	addi	a0,a0,882 # 800086f8 <syscalls+0x200>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004396:	00004517          	auipc	a0,0x4
    8000439a:	37a50513          	addi	a0,a0,890 # 80008710 <syscalls+0x218>
    8000439e:	ffffc097          	auipc	ra,0xffffc
    800043a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043a6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043a8:	00878713          	addi	a4,a5,8
    800043ac:	00271693          	slli	a3,a4,0x2
    800043b0:	0001d717          	auipc	a4,0x1d
    800043b4:	75870713          	addi	a4,a4,1880 # 80021b08 <log>
    800043b8:	9736                	add	a4,a4,a3
    800043ba:	44d4                	lw	a3,12(s1)
    800043bc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043be:	faf607e3          	beq	a2,a5,8000436c <log_write+0x7c>
  }
  release(&log.lock);
    800043c2:	0001d517          	auipc	a0,0x1d
    800043c6:	74650513          	addi	a0,a0,1862 # 80021b08 <log>
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	944080e7          	jalr	-1724(ra) # 80000d0e <release>
}
    800043d2:	60e2                	ld	ra,24(sp)
    800043d4:	6442                	ld	s0,16(sp)
    800043d6:	64a2                	ld	s1,8(sp)
    800043d8:	6902                	ld	s2,0(sp)
    800043da:	6105                	addi	sp,sp,32
    800043dc:	8082                	ret

00000000800043de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	e426                	sd	s1,8(sp)
    800043e6:	e04a                	sd	s2,0(sp)
    800043e8:	1000                	addi	s0,sp,32
    800043ea:	84aa                	mv	s1,a0
    800043ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043ee:	00004597          	auipc	a1,0x4
    800043f2:	34258593          	addi	a1,a1,834 # 80008730 <syscalls+0x238>
    800043f6:	0521                	addi	a0,a0,8
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	7d2080e7          	jalr	2002(ra) # 80000bca <initlock>
  lk->name = name;
    80004400:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004404:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004408:	0204a423          	sw	zero,40(s1)
}
    8000440c:	60e2                	ld	ra,24(sp)
    8000440e:	6442                	ld	s0,16(sp)
    80004410:	64a2                	ld	s1,8(sp)
    80004412:	6902                	ld	s2,0(sp)
    80004414:	6105                	addi	sp,sp,32
    80004416:	8082                	ret

0000000080004418 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004418:	1101                	addi	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	e04a                	sd	s2,0(sp)
    80004422:	1000                	addi	s0,sp,32
    80004424:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004426:	00850913          	addi	s2,a0,8
    8000442a:	854a                	mv	a0,s2
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	82e080e7          	jalr	-2002(ra) # 80000c5a <acquire>
  while (lk->locked) {
    80004434:	409c                	lw	a5,0(s1)
    80004436:	cb89                	beqz	a5,80004448 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004438:	85ca                	mv	a1,s2
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffe097          	auipc	ra,0xffffe
    80004440:	e04080e7          	jalr	-508(ra) # 80002240 <sleep>
  while (lk->locked) {
    80004444:	409c                	lw	a5,0(s1)
    80004446:	fbed                	bnez	a5,80004438 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004448:	4785                	li	a5,1
    8000444a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	5dc080e7          	jalr	1500(ra) # 80001a28 <myproc>
    80004454:	5d1c                	lw	a5,56(a0)
    80004456:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	8b4080e7          	jalr	-1868(ra) # 80000d0e <release>
}
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6902                	ld	s2,0(sp)
    8000446a:	6105                	addi	sp,sp,32
    8000446c:	8082                	ret

000000008000446e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000446e:	1101                	addi	sp,sp,-32
    80004470:	ec06                	sd	ra,24(sp)
    80004472:	e822                	sd	s0,16(sp)
    80004474:	e426                	sd	s1,8(sp)
    80004476:	e04a                	sd	s2,0(sp)
    80004478:	1000                	addi	s0,sp,32
    8000447a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000447c:	00850913          	addi	s2,a0,8
    80004480:	854a                	mv	a0,s2
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	7d8080e7          	jalr	2008(ra) # 80000c5a <acquire>
  lk->locked = 0;
    8000448a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000448e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004492:	8526                	mv	a0,s1
    80004494:	ffffe097          	auipc	ra,0xffffe
    80004498:	f32080e7          	jalr	-206(ra) # 800023c6 <wakeup>
  release(&lk->lk);
    8000449c:	854a                	mv	a0,s2
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	870080e7          	jalr	-1936(ra) # 80000d0e <release>
}
    800044a6:	60e2                	ld	ra,24(sp)
    800044a8:	6442                	ld	s0,16(sp)
    800044aa:	64a2                	ld	s1,8(sp)
    800044ac:	6902                	ld	s2,0(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret

00000000800044b2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044b2:	7179                	addi	sp,sp,-48
    800044b4:	f406                	sd	ra,40(sp)
    800044b6:	f022                	sd	s0,32(sp)
    800044b8:	ec26                	sd	s1,24(sp)
    800044ba:	e84a                	sd	s2,16(sp)
    800044bc:	e44e                	sd	s3,8(sp)
    800044be:	1800                	addi	s0,sp,48
    800044c0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044c2:	00850913          	addi	s2,a0,8
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	792080e7          	jalr	1938(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d0:	409c                	lw	a5,0(s1)
    800044d2:	ef99                	bnez	a5,800044f0 <holdingsleep+0x3e>
    800044d4:	4481                	li	s1,0
  release(&lk->lk);
    800044d6:	854a                	mv	a0,s2
    800044d8:	ffffd097          	auipc	ra,0xffffd
    800044dc:	836080e7          	jalr	-1994(ra) # 80000d0e <release>
  return r;
}
    800044e0:	8526                	mv	a0,s1
    800044e2:	70a2                	ld	ra,40(sp)
    800044e4:	7402                	ld	s0,32(sp)
    800044e6:	64e2                	ld	s1,24(sp)
    800044e8:	6942                	ld	s2,16(sp)
    800044ea:	69a2                	ld	s3,8(sp)
    800044ec:	6145                	addi	sp,sp,48
    800044ee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f0:	0284a983          	lw	s3,40(s1)
    800044f4:	ffffd097          	auipc	ra,0xffffd
    800044f8:	534080e7          	jalr	1332(ra) # 80001a28 <myproc>
    800044fc:	5d04                	lw	s1,56(a0)
    800044fe:	413484b3          	sub	s1,s1,s3
    80004502:	0014b493          	seqz	s1,s1
    80004506:	bfc1                	j	800044d6 <holdingsleep+0x24>

0000000080004508 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004508:	1141                	addi	sp,sp,-16
    8000450a:	e406                	sd	ra,8(sp)
    8000450c:	e022                	sd	s0,0(sp)
    8000450e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004510:	00004597          	auipc	a1,0x4
    80004514:	23058593          	addi	a1,a1,560 # 80008740 <syscalls+0x248>
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	73850513          	addi	a0,a0,1848 # 80021c50 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6aa080e7          	jalr	1706(ra) # 80000bca <initlock>
}
    80004528:	60a2                	ld	ra,8(sp)
    8000452a:	6402                	ld	s0,0(sp)
    8000452c:	0141                	addi	sp,sp,16
    8000452e:	8082                	ret

0000000080004530 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004530:	1101                	addi	sp,sp,-32
    80004532:	ec06                	sd	ra,24(sp)
    80004534:	e822                	sd	s0,16(sp)
    80004536:	e426                	sd	s1,8(sp)
    80004538:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	71650513          	addi	a0,a0,1814 # 80021c50 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	718080e7          	jalr	1816(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000454a:	0001d497          	auipc	s1,0x1d
    8000454e:	71e48493          	addi	s1,s1,1822 # 80021c68 <ftable+0x18>
    80004552:	0001e717          	auipc	a4,0x1e
    80004556:	6b670713          	addi	a4,a4,1718 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000455a:	40dc                	lw	a5,4(s1)
    8000455c:	cf99                	beqz	a5,8000457a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000455e:	02848493          	addi	s1,s1,40
    80004562:	fee49ce3          	bne	s1,a4,8000455a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004566:	0001d517          	auipc	a0,0x1d
    8000456a:	6ea50513          	addi	a0,a0,1770 # 80021c50 <ftable>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	7a0080e7          	jalr	1952(ra) # 80000d0e <release>
  return 0;
    80004576:	4481                	li	s1,0
    80004578:	a819                	j	8000458e <filealloc+0x5e>
      f->ref = 1;
    8000457a:	4785                	li	a5,1
    8000457c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000457e:	0001d517          	auipc	a0,0x1d
    80004582:	6d250513          	addi	a0,a0,1746 # 80021c50 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	788080e7          	jalr	1928(ra) # 80000d0e <release>
}
    8000458e:	8526                	mv	a0,s1
    80004590:	60e2                	ld	ra,24(sp)
    80004592:	6442                	ld	s0,16(sp)
    80004594:	64a2                	ld	s1,8(sp)
    80004596:	6105                	addi	sp,sp,32
    80004598:	8082                	ret

000000008000459a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000459a:	1101                	addi	sp,sp,-32
    8000459c:	ec06                	sd	ra,24(sp)
    8000459e:	e822                	sd	s0,16(sp)
    800045a0:	e426                	sd	s1,8(sp)
    800045a2:	1000                	addi	s0,sp,32
    800045a4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045a6:	0001d517          	auipc	a0,0x1d
    800045aa:	6aa50513          	addi	a0,a0,1706 # 80021c50 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ac080e7          	jalr	1708(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800045b6:	40dc                	lw	a5,4(s1)
    800045b8:	02f05263          	blez	a5,800045dc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045bc:	2785                	addiw	a5,a5,1
    800045be:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045c0:	0001d517          	auipc	a0,0x1d
    800045c4:	69050513          	addi	a0,a0,1680 # 80021c50 <ftable>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	746080e7          	jalr	1862(ra) # 80000d0e <release>
  return f;
}
    800045d0:	8526                	mv	a0,s1
    800045d2:	60e2                	ld	ra,24(sp)
    800045d4:	6442                	ld	s0,16(sp)
    800045d6:	64a2                	ld	s1,8(sp)
    800045d8:	6105                	addi	sp,sp,32
    800045da:	8082                	ret
    panic("filedup");
    800045dc:	00004517          	auipc	a0,0x4
    800045e0:	16c50513          	addi	a0,a0,364 # 80008748 <syscalls+0x250>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	f64080e7          	jalr	-156(ra) # 80000548 <panic>

00000000800045ec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045ec:	7139                	addi	sp,sp,-64
    800045ee:	fc06                	sd	ra,56(sp)
    800045f0:	f822                	sd	s0,48(sp)
    800045f2:	f426                	sd	s1,40(sp)
    800045f4:	f04a                	sd	s2,32(sp)
    800045f6:	ec4e                	sd	s3,24(sp)
    800045f8:	e852                	sd	s4,16(sp)
    800045fa:	e456                	sd	s5,8(sp)
    800045fc:	0080                	addi	s0,sp,64
    800045fe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004600:	0001d517          	auipc	a0,0x1d
    80004604:	65050513          	addi	a0,a0,1616 # 80021c50 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	652080e7          	jalr	1618(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004610:	40dc                	lw	a5,4(s1)
    80004612:	06f05163          	blez	a5,80004674 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004616:	37fd                	addiw	a5,a5,-1
    80004618:	0007871b          	sext.w	a4,a5
    8000461c:	c0dc                	sw	a5,4(s1)
    8000461e:	06e04363          	bgtz	a4,80004684 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004622:	0004a903          	lw	s2,0(s1)
    80004626:	0094ca83          	lbu	s5,9(s1)
    8000462a:	0104ba03          	ld	s4,16(s1)
    8000462e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004632:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004636:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000463a:	0001d517          	auipc	a0,0x1d
    8000463e:	61650513          	addi	a0,a0,1558 # 80021c50 <ftable>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	6cc080e7          	jalr	1740(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    8000464a:	4785                	li	a5,1
    8000464c:	04f90d63          	beq	s2,a5,800046a6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004650:	3979                	addiw	s2,s2,-2
    80004652:	4785                	li	a5,1
    80004654:	0527e063          	bltu	a5,s2,80004694 <fileclose+0xa8>
    begin_op();
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	ac2080e7          	jalr	-1342(ra) # 8000411a <begin_op>
    iput(ff.ip);
    80004660:	854e                	mv	a0,s3
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	2b6080e7          	jalr	694(ra) # 80003918 <iput>
    end_op();
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	b30080e7          	jalr	-1232(ra) # 8000419a <end_op>
    80004672:	a00d                	j	80004694 <fileclose+0xa8>
    panic("fileclose");
    80004674:	00004517          	auipc	a0,0x4
    80004678:	0dc50513          	addi	a0,a0,220 # 80008750 <syscalls+0x258>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	ecc080e7          	jalr	-308(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004684:	0001d517          	auipc	a0,0x1d
    80004688:	5cc50513          	addi	a0,a0,1484 # 80021c50 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	682080e7          	jalr	1666(ra) # 80000d0e <release>
  }
}
    80004694:	70e2                	ld	ra,56(sp)
    80004696:	7442                	ld	s0,48(sp)
    80004698:	74a2                	ld	s1,40(sp)
    8000469a:	7902                	ld	s2,32(sp)
    8000469c:	69e2                	ld	s3,24(sp)
    8000469e:	6a42                	ld	s4,16(sp)
    800046a0:	6aa2                	ld	s5,8(sp)
    800046a2:	6121                	addi	sp,sp,64
    800046a4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046a6:	85d6                	mv	a1,s5
    800046a8:	8552                	mv	a0,s4
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	372080e7          	jalr	882(ra) # 80004a1c <pipeclose>
    800046b2:	b7cd                	j	80004694 <fileclose+0xa8>

00000000800046b4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046b4:	715d                	addi	sp,sp,-80
    800046b6:	e486                	sd	ra,72(sp)
    800046b8:	e0a2                	sd	s0,64(sp)
    800046ba:	fc26                	sd	s1,56(sp)
    800046bc:	f84a                	sd	s2,48(sp)
    800046be:	f44e                	sd	s3,40(sp)
    800046c0:	0880                	addi	s0,sp,80
    800046c2:	84aa                	mv	s1,a0
    800046c4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046c6:	ffffd097          	auipc	ra,0xffffd
    800046ca:	362080e7          	jalr	866(ra) # 80001a28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ce:	409c                	lw	a5,0(s1)
    800046d0:	37f9                	addiw	a5,a5,-2
    800046d2:	4705                	li	a4,1
    800046d4:	04f76763          	bltu	a4,a5,80004722 <filestat+0x6e>
    800046d8:	892a                	mv	s2,a0
    ilock(f->ip);
    800046da:	6c88                	ld	a0,24(s1)
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	082080e7          	jalr	130(ra) # 8000375e <ilock>
    stati(f->ip, &st);
    800046e4:	fb840593          	addi	a1,s0,-72
    800046e8:	6c88                	ld	a0,24(s1)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	2fe080e7          	jalr	766(ra) # 800039e8 <stati>
    iunlock(f->ip);
    800046f2:	6c88                	ld	a0,24(s1)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	12c080e7          	jalr	300(ra) # 80003820 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046fc:	46e1                	li	a3,24
    800046fe:	fb840613          	addi	a2,s0,-72
    80004702:	85ce                	mv	a1,s3
    80004704:	05093503          	ld	a0,80(s2)
    80004708:	ffffd097          	auipc	ra,0xffffd
    8000470c:	014080e7          	jalr	20(ra) # 8000171c <copyout>
    80004710:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004714:	60a6                	ld	ra,72(sp)
    80004716:	6406                	ld	s0,64(sp)
    80004718:	74e2                	ld	s1,56(sp)
    8000471a:	7942                	ld	s2,48(sp)
    8000471c:	79a2                	ld	s3,40(sp)
    8000471e:	6161                	addi	sp,sp,80
    80004720:	8082                	ret
  return -1;
    80004722:	557d                	li	a0,-1
    80004724:	bfc5                	j	80004714 <filestat+0x60>

0000000080004726 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004726:	7179                	addi	sp,sp,-48
    80004728:	f406                	sd	ra,40(sp)
    8000472a:	f022                	sd	s0,32(sp)
    8000472c:	ec26                	sd	s1,24(sp)
    8000472e:	e84a                	sd	s2,16(sp)
    80004730:	e44e                	sd	s3,8(sp)
    80004732:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004734:	00854783          	lbu	a5,8(a0)
    80004738:	c3d5                	beqz	a5,800047dc <fileread+0xb6>
    8000473a:	84aa                	mv	s1,a0
    8000473c:	89ae                	mv	s3,a1
    8000473e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004740:	411c                	lw	a5,0(a0)
    80004742:	4705                	li	a4,1
    80004744:	04e78963          	beq	a5,a4,80004796 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004748:	470d                	li	a4,3
    8000474a:	04e78d63          	beq	a5,a4,800047a4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000474e:	4709                	li	a4,2
    80004750:	06e79e63          	bne	a5,a4,800047cc <fileread+0xa6>
    ilock(f->ip);
    80004754:	6d08                	ld	a0,24(a0)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	008080e7          	jalr	8(ra) # 8000375e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000475e:	874a                	mv	a4,s2
    80004760:	5094                	lw	a3,32(s1)
    80004762:	864e                	mv	a2,s3
    80004764:	4585                	li	a1,1
    80004766:	6c88                	ld	a0,24(s1)
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	2aa080e7          	jalr	682(ra) # 80003a12 <readi>
    80004770:	892a                	mv	s2,a0
    80004772:	00a05563          	blez	a0,8000477c <fileread+0x56>
      f->off += r;
    80004776:	509c                	lw	a5,32(s1)
    80004778:	9fa9                	addw	a5,a5,a0
    8000477a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000477c:	6c88                	ld	a0,24(s1)
    8000477e:	fffff097          	auipc	ra,0xfffff
    80004782:	0a2080e7          	jalr	162(ra) # 80003820 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004786:	854a                	mv	a0,s2
    80004788:	70a2                	ld	ra,40(sp)
    8000478a:	7402                	ld	s0,32(sp)
    8000478c:	64e2                	ld	s1,24(sp)
    8000478e:	6942                	ld	s2,16(sp)
    80004790:	69a2                	ld	s3,8(sp)
    80004792:	6145                	addi	sp,sp,48
    80004794:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004796:	6908                	ld	a0,16(a0)
    80004798:	00000097          	auipc	ra,0x0
    8000479c:	418080e7          	jalr	1048(ra) # 80004bb0 <piperead>
    800047a0:	892a                	mv	s2,a0
    800047a2:	b7d5                	j	80004786 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047a4:	02451783          	lh	a5,36(a0)
    800047a8:	03079693          	slli	a3,a5,0x30
    800047ac:	92c1                	srli	a3,a3,0x30
    800047ae:	4725                	li	a4,9
    800047b0:	02d76863          	bltu	a4,a3,800047e0 <fileread+0xba>
    800047b4:	0792                	slli	a5,a5,0x4
    800047b6:	0001d717          	auipc	a4,0x1d
    800047ba:	3fa70713          	addi	a4,a4,1018 # 80021bb0 <devsw>
    800047be:	97ba                	add	a5,a5,a4
    800047c0:	639c                	ld	a5,0(a5)
    800047c2:	c38d                	beqz	a5,800047e4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047c4:	4505                	li	a0,1
    800047c6:	9782                	jalr	a5
    800047c8:	892a                	mv	s2,a0
    800047ca:	bf75                	j	80004786 <fileread+0x60>
    panic("fileread");
    800047cc:	00004517          	auipc	a0,0x4
    800047d0:	f9450513          	addi	a0,a0,-108 # 80008760 <syscalls+0x268>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	d74080e7          	jalr	-652(ra) # 80000548 <panic>
    return -1;
    800047dc:	597d                	li	s2,-1
    800047de:	b765                	j	80004786 <fileread+0x60>
      return -1;
    800047e0:	597d                	li	s2,-1
    800047e2:	b755                	j	80004786 <fileread+0x60>
    800047e4:	597d                	li	s2,-1
    800047e6:	b745                	j	80004786 <fileread+0x60>

00000000800047e8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047e8:	00954783          	lbu	a5,9(a0)
    800047ec:	14078563          	beqz	a5,80004936 <filewrite+0x14e>
{
    800047f0:	715d                	addi	sp,sp,-80
    800047f2:	e486                	sd	ra,72(sp)
    800047f4:	e0a2                	sd	s0,64(sp)
    800047f6:	fc26                	sd	s1,56(sp)
    800047f8:	f84a                	sd	s2,48(sp)
    800047fa:	f44e                	sd	s3,40(sp)
    800047fc:	f052                	sd	s4,32(sp)
    800047fe:	ec56                	sd	s5,24(sp)
    80004800:	e85a                	sd	s6,16(sp)
    80004802:	e45e                	sd	s7,8(sp)
    80004804:	e062                	sd	s8,0(sp)
    80004806:	0880                	addi	s0,sp,80
    80004808:	892a                	mv	s2,a0
    8000480a:	8aae                	mv	s5,a1
    8000480c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000480e:	411c                	lw	a5,0(a0)
    80004810:	4705                	li	a4,1
    80004812:	02e78263          	beq	a5,a4,80004836 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004816:	470d                	li	a4,3
    80004818:	02e78563          	beq	a5,a4,80004842 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000481c:	4709                	li	a4,2
    8000481e:	10e79463          	bne	a5,a4,80004926 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004822:	0ec05e63          	blez	a2,8000491e <filewrite+0x136>
    int i = 0;
    80004826:	4981                	li	s3,0
    80004828:	6b05                	lui	s6,0x1
    8000482a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000482e:	6b85                	lui	s7,0x1
    80004830:	c00b8b9b          	addiw	s7,s7,-1024
    80004834:	a851                	j	800048c8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004836:	6908                	ld	a0,16(a0)
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	254080e7          	jalr	596(ra) # 80004a8c <pipewrite>
    80004840:	a85d                	j	800048f6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004842:	02451783          	lh	a5,36(a0)
    80004846:	03079693          	slli	a3,a5,0x30
    8000484a:	92c1                	srli	a3,a3,0x30
    8000484c:	4725                	li	a4,9
    8000484e:	0ed76663          	bltu	a4,a3,8000493a <filewrite+0x152>
    80004852:	0792                	slli	a5,a5,0x4
    80004854:	0001d717          	auipc	a4,0x1d
    80004858:	35c70713          	addi	a4,a4,860 # 80021bb0 <devsw>
    8000485c:	97ba                	add	a5,a5,a4
    8000485e:	679c                	ld	a5,8(a5)
    80004860:	cff9                	beqz	a5,8000493e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004862:	4505                	li	a0,1
    80004864:	9782                	jalr	a5
    80004866:	a841                	j	800048f6 <filewrite+0x10e>
    80004868:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	8ae080e7          	jalr	-1874(ra) # 8000411a <begin_op>
      ilock(f->ip);
    80004874:	01893503          	ld	a0,24(s2)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	ee6080e7          	jalr	-282(ra) # 8000375e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004880:	8762                	mv	a4,s8
    80004882:	02092683          	lw	a3,32(s2)
    80004886:	01598633          	add	a2,s3,s5
    8000488a:	4585                	li	a1,1
    8000488c:	01893503          	ld	a0,24(s2)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	278080e7          	jalr	632(ra) # 80003b08 <writei>
    80004898:	84aa                	mv	s1,a0
    8000489a:	02a05f63          	blez	a0,800048d8 <filewrite+0xf0>
        f->off += r;
    8000489e:	02092783          	lw	a5,32(s2)
    800048a2:	9fa9                	addw	a5,a5,a0
    800048a4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048a8:	01893503          	ld	a0,24(s2)
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	f74080e7          	jalr	-140(ra) # 80003820 <iunlock>
      end_op();
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	8e6080e7          	jalr	-1818(ra) # 8000419a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048bc:	049c1963          	bne	s8,s1,8000490e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048c0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048c4:	0349d663          	bge	s3,s4,800048f0 <filewrite+0x108>
      int n1 = n - i;
    800048c8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048cc:	84be                	mv	s1,a5
    800048ce:	2781                	sext.w	a5,a5
    800048d0:	f8fb5ce3          	bge	s6,a5,80004868 <filewrite+0x80>
    800048d4:	84de                	mv	s1,s7
    800048d6:	bf49                	j	80004868 <filewrite+0x80>
      iunlock(f->ip);
    800048d8:	01893503          	ld	a0,24(s2)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	f44080e7          	jalr	-188(ra) # 80003820 <iunlock>
      end_op();
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	8b6080e7          	jalr	-1866(ra) # 8000419a <end_op>
      if(r < 0)
    800048ec:	fc04d8e3          	bgez	s1,800048bc <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048f0:	8552                	mv	a0,s4
    800048f2:	033a1863          	bne	s4,s3,80004922 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048f6:	60a6                	ld	ra,72(sp)
    800048f8:	6406                	ld	s0,64(sp)
    800048fa:	74e2                	ld	s1,56(sp)
    800048fc:	7942                	ld	s2,48(sp)
    800048fe:	79a2                	ld	s3,40(sp)
    80004900:	7a02                	ld	s4,32(sp)
    80004902:	6ae2                	ld	s5,24(sp)
    80004904:	6b42                	ld	s6,16(sp)
    80004906:	6ba2                	ld	s7,8(sp)
    80004908:	6c02                	ld	s8,0(sp)
    8000490a:	6161                	addi	sp,sp,80
    8000490c:	8082                	ret
        panic("short filewrite");
    8000490e:	00004517          	auipc	a0,0x4
    80004912:	e6250513          	addi	a0,a0,-414 # 80008770 <syscalls+0x278>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
    int i = 0;
    8000491e:	4981                	li	s3,0
    80004920:	bfc1                	j	800048f0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004922:	557d                	li	a0,-1
    80004924:	bfc9                	j	800048f6 <filewrite+0x10e>
    panic("filewrite");
    80004926:	00004517          	auipc	a0,0x4
    8000492a:	e5a50513          	addi	a0,a0,-422 # 80008780 <syscalls+0x288>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	c1a080e7          	jalr	-998(ra) # 80000548 <panic>
    return -1;
    80004936:	557d                	li	a0,-1
}
    80004938:	8082                	ret
      return -1;
    8000493a:	557d                	li	a0,-1
    8000493c:	bf6d                	j	800048f6 <filewrite+0x10e>
    8000493e:	557d                	li	a0,-1
    80004940:	bf5d                	j	800048f6 <filewrite+0x10e>

0000000080004942 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004942:	7179                	addi	sp,sp,-48
    80004944:	f406                	sd	ra,40(sp)
    80004946:	f022                	sd	s0,32(sp)
    80004948:	ec26                	sd	s1,24(sp)
    8000494a:	e84a                	sd	s2,16(sp)
    8000494c:	e44e                	sd	s3,8(sp)
    8000494e:	e052                	sd	s4,0(sp)
    80004950:	1800                	addi	s0,sp,48
    80004952:	84aa                	mv	s1,a0
    80004954:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004956:	0005b023          	sd	zero,0(a1)
    8000495a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	bd2080e7          	jalr	-1070(ra) # 80004530 <filealloc>
    80004966:	e088                	sd	a0,0(s1)
    80004968:	c551                	beqz	a0,800049f4 <pipealloc+0xb2>
    8000496a:	00000097          	auipc	ra,0x0
    8000496e:	bc6080e7          	jalr	-1082(ra) # 80004530 <filealloc>
    80004972:	00aa3023          	sd	a0,0(s4)
    80004976:	c92d                	beqz	a0,800049e8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	1a8080e7          	jalr	424(ra) # 80000b20 <kalloc>
    80004980:	892a                	mv	s2,a0
    80004982:	c125                	beqz	a0,800049e2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004984:	4985                	li	s3,1
    80004986:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000498a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000498e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004992:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004996:	00004597          	auipc	a1,0x4
    8000499a:	aaa58593          	addi	a1,a1,-1366 # 80008440 <states.1707+0x198>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	22c080e7          	jalr	556(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    800049a6:	609c                	ld	a5,0(s1)
    800049a8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ac:	609c                	ld	a5,0(s1)
    800049ae:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049b2:	609c                	ld	a5,0(s1)
    800049b4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049b8:	609c                	ld	a5,0(s1)
    800049ba:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049be:	000a3783          	ld	a5,0(s4)
    800049c2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049c6:	000a3783          	ld	a5,0(s4)
    800049ca:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ce:	000a3783          	ld	a5,0(s4)
    800049d2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049d6:	000a3783          	ld	a5,0(s4)
    800049da:	0127b823          	sd	s2,16(a5)
  return 0;
    800049de:	4501                	li	a0,0
    800049e0:	a025                	j	80004a08 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049e2:	6088                	ld	a0,0(s1)
    800049e4:	e501                	bnez	a0,800049ec <pipealloc+0xaa>
    800049e6:	a039                	j	800049f4 <pipealloc+0xb2>
    800049e8:	6088                	ld	a0,0(s1)
    800049ea:	c51d                	beqz	a0,80004a18 <pipealloc+0xd6>
    fileclose(*f0);
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	c00080e7          	jalr	-1024(ra) # 800045ec <fileclose>
  if(*f1)
    800049f4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049f8:	557d                	li	a0,-1
  if(*f1)
    800049fa:	c799                	beqz	a5,80004a08 <pipealloc+0xc6>
    fileclose(*f1);
    800049fc:	853e                	mv	a0,a5
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	bee080e7          	jalr	-1042(ra) # 800045ec <fileclose>
  return -1;
    80004a06:	557d                	li	a0,-1
}
    80004a08:	70a2                	ld	ra,40(sp)
    80004a0a:	7402                	ld	s0,32(sp)
    80004a0c:	64e2                	ld	s1,24(sp)
    80004a0e:	6942                	ld	s2,16(sp)
    80004a10:	69a2                	ld	s3,8(sp)
    80004a12:	6a02                	ld	s4,0(sp)
    80004a14:	6145                	addi	sp,sp,48
    80004a16:	8082                	ret
  return -1;
    80004a18:	557d                	li	a0,-1
    80004a1a:	b7fd                	j	80004a08 <pipealloc+0xc6>

0000000080004a1c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a1c:	1101                	addi	sp,sp,-32
    80004a1e:	ec06                	sd	ra,24(sp)
    80004a20:	e822                	sd	s0,16(sp)
    80004a22:	e426                	sd	s1,8(sp)
    80004a24:	e04a                	sd	s2,0(sp)
    80004a26:	1000                	addi	s0,sp,32
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	22e080e7          	jalr	558(ra) # 80000c5a <acquire>
  if(writable){
    80004a34:	02090d63          	beqz	s2,80004a6e <pipeclose+0x52>
    pi->writeopen = 0;
    80004a38:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a3c:	21848513          	addi	a0,s1,536
    80004a40:	ffffe097          	auipc	ra,0xffffe
    80004a44:	986080e7          	jalr	-1658(ra) # 800023c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a48:	2204b783          	ld	a5,544(s1)
    80004a4c:	eb95                	bnez	a5,80004a80 <pipeclose+0x64>
    release(&pi->lock);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	2be080e7          	jalr	702(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	fca080e7          	jalr	-54(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a62:	60e2                	ld	ra,24(sp)
    80004a64:	6442                	ld	s0,16(sp)
    80004a66:	64a2                	ld	s1,8(sp)
    80004a68:	6902                	ld	s2,0(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret
    pi->readopen = 0;
    80004a6e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a72:	21c48513          	addi	a0,s1,540
    80004a76:	ffffe097          	auipc	ra,0xffffe
    80004a7a:	950080e7          	jalr	-1712(ra) # 800023c6 <wakeup>
    80004a7e:	b7e9                	j	80004a48 <pipeclose+0x2c>
    release(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	28c080e7          	jalr	652(ra) # 80000d0e <release>
}
    80004a8a:	bfe1                	j	80004a62 <pipeclose+0x46>

0000000080004a8c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a8c:	7119                	addi	sp,sp,-128
    80004a8e:	fc86                	sd	ra,120(sp)
    80004a90:	f8a2                	sd	s0,112(sp)
    80004a92:	f4a6                	sd	s1,104(sp)
    80004a94:	f0ca                	sd	s2,96(sp)
    80004a96:	ecce                	sd	s3,88(sp)
    80004a98:	e8d2                	sd	s4,80(sp)
    80004a9a:	e4d6                	sd	s5,72(sp)
    80004a9c:	e0da                	sd	s6,64(sp)
    80004a9e:	fc5e                	sd	s7,56(sp)
    80004aa0:	f862                	sd	s8,48(sp)
    80004aa2:	f466                	sd	s9,40(sp)
    80004aa4:	f06a                	sd	s10,32(sp)
    80004aa6:	ec6e                	sd	s11,24(sp)
    80004aa8:	0100                	addi	s0,sp,128
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	8cae                	mv	s9,a1
    80004aae:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	f78080e7          	jalr	-136(ra) # 80001a28 <myproc>
    80004ab8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004aba:	8526                	mv	a0,s1
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004ac4:	0d605963          	blez	s6,80004b96 <pipewrite+0x10a>
    80004ac8:	89a6                	mv	s3,s1
    80004aca:	3b7d                	addiw	s6,s6,-1
    80004acc:	1b02                	slli	s6,s6,0x20
    80004ace:	020b5b13          	srli	s6,s6,0x20
    80004ad2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ad4:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ad8:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004adc:	5dfd                	li	s11,-1
    80004ade:	000b8d1b          	sext.w	s10,s7
    80004ae2:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ae4:	2184a783          	lw	a5,536(s1)
    80004ae8:	21c4a703          	lw	a4,540(s1)
    80004aec:	2007879b          	addiw	a5,a5,512
    80004af0:	02f71b63          	bne	a4,a5,80004b26 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004af4:	2204a783          	lw	a5,544(s1)
    80004af8:	cbad                	beqz	a5,80004b6a <pipewrite+0xde>
    80004afa:	03092783          	lw	a5,48(s2)
    80004afe:	e7b5                	bnez	a5,80004b6a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b00:	8556                	mv	a0,s5
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	8c4080e7          	jalr	-1852(ra) # 800023c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b0a:	85ce                	mv	a1,s3
    80004b0c:	8552                	mv	a0,s4
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	732080e7          	jalr	1842(ra) # 80002240 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b16:	2184a783          	lw	a5,536(s1)
    80004b1a:	21c4a703          	lw	a4,540(s1)
    80004b1e:	2007879b          	addiw	a5,a5,512
    80004b22:	fcf709e3          	beq	a4,a5,80004af4 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b26:	4685                	li	a3,1
    80004b28:	019b8633          	add	a2,s7,s9
    80004b2c:	f8f40593          	addi	a1,s0,-113
    80004b30:	05093503          	ld	a0,80(s2)
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	c74080e7          	jalr	-908(ra) # 800017a8 <copyin>
    80004b3c:	05b50e63          	beq	a0,s11,80004b98 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b40:	21c4a783          	lw	a5,540(s1)
    80004b44:	0017871b          	addiw	a4,a5,1
    80004b48:	20e4ae23          	sw	a4,540(s1)
    80004b4c:	1ff7f793          	andi	a5,a5,511
    80004b50:	97a6                	add	a5,a5,s1
    80004b52:	f8f44703          	lbu	a4,-113(s0)
    80004b56:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b5a:	001d0c1b          	addiw	s8,s10,1
    80004b5e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b62:	036b8b63          	beq	s7,s6,80004b98 <pipewrite+0x10c>
    80004b66:	8bbe                	mv	s7,a5
    80004b68:	bf9d                	j	80004ade <pipewrite+0x52>
        release(&pi->lock);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	1a2080e7          	jalr	418(ra) # 80000d0e <release>
        return -1;
    80004b74:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b76:	8562                	mv	a0,s8
    80004b78:	70e6                	ld	ra,120(sp)
    80004b7a:	7446                	ld	s0,112(sp)
    80004b7c:	74a6                	ld	s1,104(sp)
    80004b7e:	7906                	ld	s2,96(sp)
    80004b80:	69e6                	ld	s3,88(sp)
    80004b82:	6a46                	ld	s4,80(sp)
    80004b84:	6aa6                	ld	s5,72(sp)
    80004b86:	6b06                	ld	s6,64(sp)
    80004b88:	7be2                	ld	s7,56(sp)
    80004b8a:	7c42                	ld	s8,48(sp)
    80004b8c:	7ca2                	ld	s9,40(sp)
    80004b8e:	7d02                	ld	s10,32(sp)
    80004b90:	6de2                	ld	s11,24(sp)
    80004b92:	6109                	addi	sp,sp,128
    80004b94:	8082                	ret
  for(i = 0; i < n; i++){
    80004b96:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b98:	21848513          	addi	a0,s1,536
    80004b9c:	ffffe097          	auipc	ra,0xffffe
    80004ba0:	82a080e7          	jalr	-2006(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	168080e7          	jalr	360(ra) # 80000d0e <release>
  return i;
    80004bae:	b7e1                	j	80004b76 <pipewrite+0xea>

0000000080004bb0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb0:	715d                	addi	sp,sp,-80
    80004bb2:	e486                	sd	ra,72(sp)
    80004bb4:	e0a2                	sd	s0,64(sp)
    80004bb6:	fc26                	sd	s1,56(sp)
    80004bb8:	f84a                	sd	s2,48(sp)
    80004bba:	f44e                	sd	s3,40(sp)
    80004bbc:	f052                	sd	s4,32(sp)
    80004bbe:	ec56                	sd	s5,24(sp)
    80004bc0:	e85a                	sd	s6,16(sp)
    80004bc2:	0880                	addi	s0,sp,80
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	892e                	mv	s2,a1
    80004bc8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	e5e080e7          	jalr	-418(ra) # 80001a28 <myproc>
    80004bd2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bd4:	8b26                	mv	s6,s1
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	082080e7          	jalr	130(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be0:	2184a703          	lw	a4,536(s1)
    80004be4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bec:	02f71463          	bne	a4,a5,80004c14 <piperead+0x64>
    80004bf0:	2244a783          	lw	a5,548(s1)
    80004bf4:	c385                	beqz	a5,80004c14 <piperead+0x64>
    if(pr->killed){
    80004bf6:	030a2783          	lw	a5,48(s4)
    80004bfa:	ebc1                	bnez	a5,80004c8a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfc:	85da                	mv	a1,s6
    80004bfe:	854e                	mv	a0,s3
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	640080e7          	jalr	1600(ra) # 80002240 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c08:	2184a703          	lw	a4,536(s1)
    80004c0c:	21c4a783          	lw	a5,540(s1)
    80004c10:	fef700e3          	beq	a4,a5,80004bf0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c14:	09505263          	blez	s5,80004c98 <piperead+0xe8>
    80004c18:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c1c:	2184a783          	lw	a5,536(s1)
    80004c20:	21c4a703          	lw	a4,540(s1)
    80004c24:	02f70d63          	beq	a4,a5,80004c5e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c28:	0017871b          	addiw	a4,a5,1
    80004c2c:	20e4ac23          	sw	a4,536(s1)
    80004c30:	1ff7f793          	andi	a5,a5,511
    80004c34:	97a6                	add	a5,a5,s1
    80004c36:	0187c783          	lbu	a5,24(a5)
    80004c3a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c3e:	4685                	li	a3,1
    80004c40:	fbf40613          	addi	a2,s0,-65
    80004c44:	85ca                	mv	a1,s2
    80004c46:	050a3503          	ld	a0,80(s4)
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	ad2080e7          	jalr	-1326(ra) # 8000171c <copyout>
    80004c52:	01650663          	beq	a0,s6,80004c5e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c56:	2985                	addiw	s3,s3,1
    80004c58:	0905                	addi	s2,s2,1
    80004c5a:	fd3a91e3          	bne	s5,s3,80004c1c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c5e:	21c48513          	addi	a0,s1,540
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	764080e7          	jalr	1892(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	0a2080e7          	jalr	162(ra) # 80000d0e <release>
  return i;
}
    80004c74:	854e                	mv	a0,s3
    80004c76:	60a6                	ld	ra,72(sp)
    80004c78:	6406                	ld	s0,64(sp)
    80004c7a:	74e2                	ld	s1,56(sp)
    80004c7c:	7942                	ld	s2,48(sp)
    80004c7e:	79a2                	ld	s3,40(sp)
    80004c80:	7a02                	ld	s4,32(sp)
    80004c82:	6ae2                	ld	s5,24(sp)
    80004c84:	6b42                	ld	s6,16(sp)
    80004c86:	6161                	addi	sp,sp,80
    80004c88:	8082                	ret
      release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	082080e7          	jalr	130(ra) # 80000d0e <release>
      return -1;
    80004c94:	59fd                	li	s3,-1
    80004c96:	bff9                	j	80004c74 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c98:	4981                	li	s3,0
    80004c9a:	b7d1                	j	80004c5e <piperead+0xae>

0000000080004c9c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c9c:	df010113          	addi	sp,sp,-528
    80004ca0:	20113423          	sd	ra,520(sp)
    80004ca4:	20813023          	sd	s0,512(sp)
    80004ca8:	ffa6                	sd	s1,504(sp)
    80004caa:	fbca                	sd	s2,496(sp)
    80004cac:	f7ce                	sd	s3,488(sp)
    80004cae:	f3d2                	sd	s4,480(sp)
    80004cb0:	efd6                	sd	s5,472(sp)
    80004cb2:	ebda                	sd	s6,464(sp)
    80004cb4:	e7de                	sd	s7,456(sp)
    80004cb6:	e3e2                	sd	s8,448(sp)
    80004cb8:	ff66                	sd	s9,440(sp)
    80004cba:	fb6a                	sd	s10,432(sp)
    80004cbc:	f76e                	sd	s11,424(sp)
    80004cbe:	0c00                	addi	s0,sp,528
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	dea43c23          	sd	a0,-520(s0)
    80004cc6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	d5e080e7          	jalr	-674(ra) # 80001a28 <myproc>
    80004cd2:	892a                	mv	s2,a0

  begin_op();
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	446080e7          	jalr	1094(ra) # 8000411a <begin_op>

  if((ip = namei(path)) == 0){
    80004cdc:	8526                	mv	a0,s1
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	230080e7          	jalr	560(ra) # 80003f0e <namei>
    80004ce6:	c92d                	beqz	a0,80004d58 <exec+0xbc>
    80004ce8:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	a74080e7          	jalr	-1420(ra) # 8000375e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cf2:	04000713          	li	a4,64
    80004cf6:	4681                	li	a3,0
    80004cf8:	e4840613          	addi	a2,s0,-440
    80004cfc:	4581                	li	a1,0
    80004cfe:	8526                	mv	a0,s1
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	d12080e7          	jalr	-750(ra) # 80003a12 <readi>
    80004d08:	04000793          	li	a5,64
    80004d0c:	00f51a63          	bne	a0,a5,80004d20 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d10:	e4842703          	lw	a4,-440(s0)
    80004d14:	464c47b7          	lui	a5,0x464c4
    80004d18:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d1c:	04f70463          	beq	a4,a5,80004d64 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d20:	8526                	mv	a0,s1
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	c9e080e7          	jalr	-866(ra) # 800039c0 <iunlockput>
    end_op();
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	470080e7          	jalr	1136(ra) # 8000419a <end_op>
  }
  return -1;
    80004d32:	557d                	li	a0,-1
}
    80004d34:	20813083          	ld	ra,520(sp)
    80004d38:	20013403          	ld	s0,512(sp)
    80004d3c:	74fe                	ld	s1,504(sp)
    80004d3e:	795e                	ld	s2,496(sp)
    80004d40:	79be                	ld	s3,488(sp)
    80004d42:	7a1e                	ld	s4,480(sp)
    80004d44:	6afe                	ld	s5,472(sp)
    80004d46:	6b5e                	ld	s6,464(sp)
    80004d48:	6bbe                	ld	s7,456(sp)
    80004d4a:	6c1e                	ld	s8,448(sp)
    80004d4c:	7cfa                	ld	s9,440(sp)
    80004d4e:	7d5a                	ld	s10,432(sp)
    80004d50:	7dba                	ld	s11,424(sp)
    80004d52:	21010113          	addi	sp,sp,528
    80004d56:	8082                	ret
    end_op();
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	442080e7          	jalr	1090(ra) # 8000419a <end_op>
    return -1;
    80004d60:	557d                	li	a0,-1
    80004d62:	bfc9                	j	80004d34 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d64:	854a                	mv	a0,s2
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	d86080e7          	jalr	-634(ra) # 80001aec <proc_pagetable>
    80004d6e:	8baa                	mv	s7,a0
    80004d70:	d945                	beqz	a0,80004d20 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d72:	e6842983          	lw	s3,-408(s0)
    80004d76:	e8045783          	lhu	a5,-384(s0)
    80004d7a:	c7ad                	beqz	a5,80004de4 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d7c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d80:	6c85                	lui	s9,0x1
    80004d82:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d86:	def43823          	sd	a5,-528(s0)
    80004d8a:	a42d                	j	80004fb4 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d8c:	00004517          	auipc	a0,0x4
    80004d90:	a0450513          	addi	a0,a0,-1532 # 80008790 <syscalls+0x298>
    80004d94:	ffffb097          	auipc	ra,0xffffb
    80004d98:	7b4080e7          	jalr	1972(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d9c:	8756                	mv	a4,s5
    80004d9e:	012d86bb          	addw	a3,s11,s2
    80004da2:	4581                	li	a1,0
    80004da4:	8526                	mv	a0,s1
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	c6c080e7          	jalr	-916(ra) # 80003a12 <readi>
    80004dae:	2501                	sext.w	a0,a0
    80004db0:	1aaa9963          	bne	s5,a0,80004f62 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004db4:	6785                	lui	a5,0x1
    80004db6:	0127893b          	addw	s2,a5,s2
    80004dba:	77fd                	lui	a5,0xfffff
    80004dbc:	01478a3b          	addw	s4,a5,s4
    80004dc0:	1f897163          	bgeu	s2,s8,80004fa2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dc4:	02091593          	slli	a1,s2,0x20
    80004dc8:	9181                	srli	a1,a1,0x20
    80004dca:	95ea                	add	a1,a1,s10
    80004dcc:	855e                	mv	a0,s7
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	31a080e7          	jalr	794(ra) # 800010e8 <walkaddr>
    80004dd6:	862a                	mv	a2,a0
    if(pa == 0)
    80004dd8:	d955                	beqz	a0,80004d8c <exec+0xf0>
      n = PGSIZE;
    80004dda:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ddc:	fd9a70e3          	bgeu	s4,s9,80004d9c <exec+0x100>
      n = sz - i;
    80004de0:	8ad2                	mv	s5,s4
    80004de2:	bf6d                	j	80004d9c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de4:	4901                	li	s2,0
  iunlockput(ip);
    80004de6:	8526                	mv	a0,s1
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	bd8080e7          	jalr	-1064(ra) # 800039c0 <iunlockput>
  end_op();
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	3aa080e7          	jalr	938(ra) # 8000419a <end_op>
  p = myproc();
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	c30080e7          	jalr	-976(ra) # 80001a28 <myproc>
    80004e00:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e02:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e06:	6785                	lui	a5,0x1
    80004e08:	17fd                	addi	a5,a5,-1
    80004e0a:	993e                	add	s2,s2,a5
    80004e0c:	757d                	lui	a0,0xfffff
    80004e0e:	00a977b3          	and	a5,s2,a0
    80004e12:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e16:	6609                	lui	a2,0x2
    80004e18:	963e                	add	a2,a2,a5
    80004e1a:	85be                	mv	a1,a5
    80004e1c:	855e                	mv	a0,s7
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	6ae080e7          	jalr	1710(ra) # 800014cc <uvmalloc>
    80004e26:	8b2a                	mv	s6,a0
  ip = 0;
    80004e28:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e2a:	12050c63          	beqz	a0,80004f62 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e2e:	75f9                	lui	a1,0xffffe
    80004e30:	95aa                	add	a1,a1,a0
    80004e32:	855e                	mv	a0,s7
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	8b6080e7          	jalr	-1866(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004e3c:	7c7d                	lui	s8,0xfffff
    80004e3e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e40:	e0043783          	ld	a5,-512(s0)
    80004e44:	6388                	ld	a0,0(a5)
    80004e46:	c535                	beqz	a0,80004eb2 <exec+0x216>
    80004e48:	e8840993          	addi	s3,s0,-376
    80004e4c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e50:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	08c080e7          	jalr	140(ra) # 80000ede <strlen>
    80004e5a:	2505                	addiw	a0,a0,1
    80004e5c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e60:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e64:	13896363          	bltu	s2,s8,80004f8a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e68:	e0043d83          	ld	s11,-512(s0)
    80004e6c:	000dba03          	ld	s4,0(s11)
    80004e70:	8552                	mv	a0,s4
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	06c080e7          	jalr	108(ra) # 80000ede <strlen>
    80004e7a:	0015069b          	addiw	a3,a0,1
    80004e7e:	8652                	mv	a2,s4
    80004e80:	85ca                	mv	a1,s2
    80004e82:	855e                	mv	a0,s7
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	898080e7          	jalr	-1896(ra) # 8000171c <copyout>
    80004e8c:	10054363          	bltz	a0,80004f92 <exec+0x2f6>
    ustack[argc] = sp;
    80004e90:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e94:	0485                	addi	s1,s1,1
    80004e96:	008d8793          	addi	a5,s11,8
    80004e9a:	e0f43023          	sd	a5,-512(s0)
    80004e9e:	008db503          	ld	a0,8(s11)
    80004ea2:	c911                	beqz	a0,80004eb6 <exec+0x21a>
    if(argc >= MAXARG)
    80004ea4:	09a1                	addi	s3,s3,8
    80004ea6:	fb3c96e3          	bne	s9,s3,80004e52 <exec+0x1b6>
  sz = sz1;
    80004eaa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eae:	4481                	li	s1,0
    80004eb0:	a84d                	j	80004f62 <exec+0x2c6>
  sp = sz;
    80004eb2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eb4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eb6:	00349793          	slli	a5,s1,0x3
    80004eba:	f9040713          	addi	a4,s0,-112
    80004ebe:	97ba                	add	a5,a5,a4
    80004ec0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ec4:	00148693          	addi	a3,s1,1
    80004ec8:	068e                	slli	a3,a3,0x3
    80004eca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ece:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ed2:	01897663          	bgeu	s2,s8,80004ede <exec+0x242>
  sz = sz1;
    80004ed6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eda:	4481                	li	s1,0
    80004edc:	a059                	j	80004f62 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ede:	e8840613          	addi	a2,s0,-376
    80004ee2:	85ca                	mv	a1,s2
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	836080e7          	jalr	-1994(ra) # 8000171c <copyout>
    80004eee:	0a054663          	bltz	a0,80004f9a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ef2:	058ab783          	ld	a5,88(s5)
    80004ef6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004efa:	df843783          	ld	a5,-520(s0)
    80004efe:	0007c703          	lbu	a4,0(a5)
    80004f02:	cf11                	beqz	a4,80004f1e <exec+0x282>
    80004f04:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f06:	02f00693          	li	a3,47
    80004f0a:	a029                	j	80004f14 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f0c:	0785                	addi	a5,a5,1
    80004f0e:	fff7c703          	lbu	a4,-1(a5)
    80004f12:	c711                	beqz	a4,80004f1e <exec+0x282>
    if(*s == '/')
    80004f14:	fed71ce3          	bne	a4,a3,80004f0c <exec+0x270>
      last = s+1;
    80004f18:	def43c23          	sd	a5,-520(s0)
    80004f1c:	bfc5                	j	80004f0c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f1e:	4641                	li	a2,16
    80004f20:	df843583          	ld	a1,-520(s0)
    80004f24:	158a8513          	addi	a0,s5,344
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	f84080e7          	jalr	-124(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f30:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f34:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f38:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f3c:	058ab783          	ld	a5,88(s5)
    80004f40:	e6043703          	ld	a4,-416(s0)
    80004f44:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f46:	058ab783          	ld	a5,88(s5)
    80004f4a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f4e:	85ea                	mv	a1,s10
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	c38080e7          	jalr	-968(ra) # 80001b88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f58:	0004851b          	sext.w	a0,s1
    80004f5c:	bbe1                	j	80004d34 <exec+0x98>
    80004f5e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f62:	e0843583          	ld	a1,-504(s0)
    80004f66:	855e                	mv	a0,s7
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	c20080e7          	jalr	-992(ra) # 80001b88 <proc_freepagetable>
  if(ip){
    80004f70:	da0498e3          	bnez	s1,80004d20 <exec+0x84>
  return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	bb7d                	j	80004d34 <exec+0x98>
    80004f78:	e1243423          	sd	s2,-504(s0)
    80004f7c:	b7dd                	j	80004f62 <exec+0x2c6>
    80004f7e:	e1243423          	sd	s2,-504(s0)
    80004f82:	b7c5                	j	80004f62 <exec+0x2c6>
    80004f84:	e1243423          	sd	s2,-504(s0)
    80004f88:	bfe9                	j	80004f62 <exec+0x2c6>
  sz = sz1;
    80004f8a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8e:	4481                	li	s1,0
    80004f90:	bfc9                	j	80004f62 <exec+0x2c6>
  sz = sz1;
    80004f92:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f96:	4481                	li	s1,0
    80004f98:	b7e9                	j	80004f62 <exec+0x2c6>
  sz = sz1;
    80004f9a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f9e:	4481                	li	s1,0
    80004fa0:	b7c9                	j	80004f62 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fa2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa6:	2b05                	addiw	s6,s6,1
    80004fa8:	0389899b          	addiw	s3,s3,56
    80004fac:	e8045783          	lhu	a5,-384(s0)
    80004fb0:	e2fb5be3          	bge	s6,a5,80004de6 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fb4:	2981                	sext.w	s3,s3
    80004fb6:	03800713          	li	a4,56
    80004fba:	86ce                	mv	a3,s3
    80004fbc:	e1040613          	addi	a2,s0,-496
    80004fc0:	4581                	li	a1,0
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	a4e080e7          	jalr	-1458(ra) # 80003a12 <readi>
    80004fcc:	03800793          	li	a5,56
    80004fd0:	f8f517e3          	bne	a0,a5,80004f5e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fd4:	e1042783          	lw	a5,-496(s0)
    80004fd8:	4705                	li	a4,1
    80004fda:	fce796e3          	bne	a5,a4,80004fa6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fde:	e3843603          	ld	a2,-456(s0)
    80004fe2:	e3043783          	ld	a5,-464(s0)
    80004fe6:	f8f669e3          	bltu	a2,a5,80004f78 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fea:	e2043783          	ld	a5,-480(s0)
    80004fee:	963e                	add	a2,a2,a5
    80004ff0:	f8f667e3          	bltu	a2,a5,80004f7e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ff4:	85ca                	mv	a1,s2
    80004ff6:	855e                	mv	a0,s7
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	4d4080e7          	jalr	1236(ra) # 800014cc <uvmalloc>
    80005000:	e0a43423          	sd	a0,-504(s0)
    80005004:	d141                	beqz	a0,80004f84 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005006:	e2043d03          	ld	s10,-480(s0)
    8000500a:	df043783          	ld	a5,-528(s0)
    8000500e:	00fd77b3          	and	a5,s10,a5
    80005012:	fba1                	bnez	a5,80004f62 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005014:	e1842d83          	lw	s11,-488(s0)
    80005018:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000501c:	f80c03e3          	beqz	s8,80004fa2 <exec+0x306>
    80005020:	8a62                	mv	s4,s8
    80005022:	4901                	li	s2,0
    80005024:	b345                	j	80004dc4 <exec+0x128>

0000000080005026 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005026:	7179                	addi	sp,sp,-48
    80005028:	f406                	sd	ra,40(sp)
    8000502a:	f022                	sd	s0,32(sp)
    8000502c:	ec26                	sd	s1,24(sp)
    8000502e:	e84a                	sd	s2,16(sp)
    80005030:	1800                	addi	s0,sp,48
    80005032:	892e                	mv	s2,a1
    80005034:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005036:	fdc40593          	addi	a1,s0,-36
    8000503a:	ffffe097          	auipc	ra,0xffffe
    8000503e:	ae2080e7          	jalr	-1310(ra) # 80002b1c <argint>
    80005042:	04054063          	bltz	a0,80005082 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005046:	fdc42703          	lw	a4,-36(s0)
    8000504a:	47bd                	li	a5,15
    8000504c:	02e7ed63          	bltu	a5,a4,80005086 <argfd+0x60>
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	9d8080e7          	jalr	-1576(ra) # 80001a28 <myproc>
    80005058:	fdc42703          	lw	a4,-36(s0)
    8000505c:	01a70793          	addi	a5,a4,26
    80005060:	078e                	slli	a5,a5,0x3
    80005062:	953e                	add	a0,a0,a5
    80005064:	611c                	ld	a5,0(a0)
    80005066:	c395                	beqz	a5,8000508a <argfd+0x64>
    return -1;
  if(pfd)
    80005068:	00090463          	beqz	s2,80005070 <argfd+0x4a>
    *pfd = fd;
    8000506c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005070:	4501                	li	a0,0
  if(pf)
    80005072:	c091                	beqz	s1,80005076 <argfd+0x50>
    *pf = f;
    80005074:	e09c                	sd	a5,0(s1)
}
    80005076:	70a2                	ld	ra,40(sp)
    80005078:	7402                	ld	s0,32(sp)
    8000507a:	64e2                	ld	s1,24(sp)
    8000507c:	6942                	ld	s2,16(sp)
    8000507e:	6145                	addi	sp,sp,48
    80005080:	8082                	ret
    return -1;
    80005082:	557d                	li	a0,-1
    80005084:	bfcd                	j	80005076 <argfd+0x50>
    return -1;
    80005086:	557d                	li	a0,-1
    80005088:	b7fd                	j	80005076 <argfd+0x50>
    8000508a:	557d                	li	a0,-1
    8000508c:	b7ed                	j	80005076 <argfd+0x50>

000000008000508e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	1000                	addi	s0,sp,32
    80005098:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	98e080e7          	jalr	-1650(ra) # 80001a28 <myproc>
    800050a2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050a4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050a8:	4501                	li	a0,0
    800050aa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ac:	6398                	ld	a4,0(a5)
    800050ae:	cb19                	beqz	a4,800050c4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050b0:	2505                	addiw	a0,a0,1
    800050b2:	07a1                	addi	a5,a5,8
    800050b4:	fed51ce3          	bne	a0,a3,800050ac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b8:	557d                	li	a0,-1
}
    800050ba:	60e2                	ld	ra,24(sp)
    800050bc:	6442                	ld	s0,16(sp)
    800050be:	64a2                	ld	s1,8(sp)
    800050c0:	6105                	addi	sp,sp,32
    800050c2:	8082                	ret
      p->ofile[fd] = f;
    800050c4:	01a50793          	addi	a5,a0,26
    800050c8:	078e                	slli	a5,a5,0x3
    800050ca:	963e                	add	a2,a2,a5
    800050cc:	e204                	sd	s1,0(a2)
      return fd;
    800050ce:	b7f5                	j	800050ba <fdalloc+0x2c>

00000000800050d0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050d0:	715d                	addi	sp,sp,-80
    800050d2:	e486                	sd	ra,72(sp)
    800050d4:	e0a2                	sd	s0,64(sp)
    800050d6:	fc26                	sd	s1,56(sp)
    800050d8:	f84a                	sd	s2,48(sp)
    800050da:	f44e                	sd	s3,40(sp)
    800050dc:	f052                	sd	s4,32(sp)
    800050de:	ec56                	sd	s5,24(sp)
    800050e0:	0880                	addi	s0,sp,80
    800050e2:	89ae                	mv	s3,a1
    800050e4:	8ab2                	mv	s5,a2
    800050e6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050e8:	fb040593          	addi	a1,s0,-80
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	e40080e7          	jalr	-448(ra) # 80003f2c <nameiparent>
    800050f4:	892a                	mv	s2,a0
    800050f6:	12050f63          	beqz	a0,80005234 <create+0x164>
    return 0;

  ilock(dp);
    800050fa:	ffffe097          	auipc	ra,0xffffe
    800050fe:	664080e7          	jalr	1636(ra) # 8000375e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005102:	4601                	li	a2,0
    80005104:	fb040593          	addi	a1,s0,-80
    80005108:	854a                	mv	a0,s2
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	b32080e7          	jalr	-1230(ra) # 80003c3c <dirlookup>
    80005112:	84aa                	mv	s1,a0
    80005114:	c921                	beqz	a0,80005164 <create+0x94>
    iunlockput(dp);
    80005116:	854a                	mv	a0,s2
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	8a8080e7          	jalr	-1880(ra) # 800039c0 <iunlockput>
    ilock(ip);
    80005120:	8526                	mv	a0,s1
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	63c080e7          	jalr	1596(ra) # 8000375e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000512a:	2981                	sext.w	s3,s3
    8000512c:	4789                	li	a5,2
    8000512e:	02f99463          	bne	s3,a5,80005156 <create+0x86>
    80005132:	0444d783          	lhu	a5,68(s1)
    80005136:	37f9                	addiw	a5,a5,-2
    80005138:	17c2                	slli	a5,a5,0x30
    8000513a:	93c1                	srli	a5,a5,0x30
    8000513c:	4705                	li	a4,1
    8000513e:	00f76c63          	bltu	a4,a5,80005156 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005142:	8526                	mv	a0,s1
    80005144:	60a6                	ld	ra,72(sp)
    80005146:	6406                	ld	s0,64(sp)
    80005148:	74e2                	ld	s1,56(sp)
    8000514a:	7942                	ld	s2,48(sp)
    8000514c:	79a2                	ld	s3,40(sp)
    8000514e:	7a02                	ld	s4,32(sp)
    80005150:	6ae2                	ld	s5,24(sp)
    80005152:	6161                	addi	sp,sp,80
    80005154:	8082                	ret
    iunlockput(ip);
    80005156:	8526                	mv	a0,s1
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	868080e7          	jalr	-1944(ra) # 800039c0 <iunlockput>
    return 0;
    80005160:	4481                	li	s1,0
    80005162:	b7c5                	j	80005142 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005164:	85ce                	mv	a1,s3
    80005166:	00092503          	lw	a0,0(s2)
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	45c080e7          	jalr	1116(ra) # 800035c6 <ialloc>
    80005172:	84aa                	mv	s1,a0
    80005174:	c529                	beqz	a0,800051be <create+0xee>
  ilock(ip);
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	5e8080e7          	jalr	1512(ra) # 8000375e <ilock>
  ip->major = major;
    8000517e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005182:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005186:	4785                	li	a5,1
    80005188:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	506080e7          	jalr	1286(ra) # 80003694 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005196:	2981                	sext.w	s3,s3
    80005198:	4785                	li	a5,1
    8000519a:	02f98a63          	beq	s3,a5,800051ce <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000519e:	40d0                	lw	a2,4(s1)
    800051a0:	fb040593          	addi	a1,s0,-80
    800051a4:	854a                	mv	a0,s2
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	ca6080e7          	jalr	-858(ra) # 80003e4c <dirlink>
    800051ae:	06054b63          	bltz	a0,80005224 <create+0x154>
  iunlockput(dp);
    800051b2:	854a                	mv	a0,s2
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	80c080e7          	jalr	-2036(ra) # 800039c0 <iunlockput>
  return ip;
    800051bc:	b759                	j	80005142 <create+0x72>
    panic("create: ialloc");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	5f250513          	addi	a0,a0,1522 # 800087b0 <syscalls+0x2b8>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	382080e7          	jalr	898(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051ce:	04a95783          	lhu	a5,74(s2)
    800051d2:	2785                	addiw	a5,a5,1
    800051d4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051d8:	854a                	mv	a0,s2
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	4ba080e7          	jalr	1210(ra) # 80003694 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051e2:	40d0                	lw	a2,4(s1)
    800051e4:	00003597          	auipc	a1,0x3
    800051e8:	5dc58593          	addi	a1,a1,1500 # 800087c0 <syscalls+0x2c8>
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	c5e080e7          	jalr	-930(ra) # 80003e4c <dirlink>
    800051f6:	00054f63          	bltz	a0,80005214 <create+0x144>
    800051fa:	00492603          	lw	a2,4(s2)
    800051fe:	00003597          	auipc	a1,0x3
    80005202:	5ca58593          	addi	a1,a1,1482 # 800087c8 <syscalls+0x2d0>
    80005206:	8526                	mv	a0,s1
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	c44080e7          	jalr	-956(ra) # 80003e4c <dirlink>
    80005210:	f80557e3          	bgez	a0,8000519e <create+0xce>
      panic("create dots");
    80005214:	00003517          	auipc	a0,0x3
    80005218:	5bc50513          	addi	a0,a0,1468 # 800087d0 <syscalls+0x2d8>
    8000521c:	ffffb097          	auipc	ra,0xffffb
    80005220:	32c080e7          	jalr	812(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005224:	00003517          	auipc	a0,0x3
    80005228:	5bc50513          	addi	a0,a0,1468 # 800087e0 <syscalls+0x2e8>
    8000522c:	ffffb097          	auipc	ra,0xffffb
    80005230:	31c080e7          	jalr	796(ra) # 80000548 <panic>
    return 0;
    80005234:	84aa                	mv	s1,a0
    80005236:	b731                	j	80005142 <create+0x72>

0000000080005238 <sys_dup>:
{
    80005238:	7179                	addi	sp,sp,-48
    8000523a:	f406                	sd	ra,40(sp)
    8000523c:	f022                	sd	s0,32(sp)
    8000523e:	ec26                	sd	s1,24(sp)
    80005240:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005242:	fd840613          	addi	a2,s0,-40
    80005246:	4581                	li	a1,0
    80005248:	4501                	li	a0,0
    8000524a:	00000097          	auipc	ra,0x0
    8000524e:	ddc080e7          	jalr	-548(ra) # 80005026 <argfd>
    return -1;
    80005252:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005254:	02054363          	bltz	a0,8000527a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005258:	fd843503          	ld	a0,-40(s0)
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	e32080e7          	jalr	-462(ra) # 8000508e <fdalloc>
    80005264:	84aa                	mv	s1,a0
    return -1;
    80005266:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005268:	00054963          	bltz	a0,8000527a <sys_dup+0x42>
  filedup(f);
    8000526c:	fd843503          	ld	a0,-40(s0)
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	32a080e7          	jalr	810(ra) # 8000459a <filedup>
  return fd;
    80005278:	87a6                	mv	a5,s1
}
    8000527a:	853e                	mv	a0,a5
    8000527c:	70a2                	ld	ra,40(sp)
    8000527e:	7402                	ld	s0,32(sp)
    80005280:	64e2                	ld	s1,24(sp)
    80005282:	6145                	addi	sp,sp,48
    80005284:	8082                	ret

0000000080005286 <sys_read>:
{
    80005286:	7179                	addi	sp,sp,-48
    80005288:	f406                	sd	ra,40(sp)
    8000528a:	f022                	sd	s0,32(sp)
    8000528c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528e:	fe840613          	addi	a2,s0,-24
    80005292:	4581                	li	a1,0
    80005294:	4501                	li	a0,0
    80005296:	00000097          	auipc	ra,0x0
    8000529a:	d90080e7          	jalr	-624(ra) # 80005026 <argfd>
    return -1;
    8000529e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a0:	04054163          	bltz	a0,800052e2 <sys_read+0x5c>
    800052a4:	fe440593          	addi	a1,s0,-28
    800052a8:	4509                	li	a0,2
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	872080e7          	jalr	-1934(ra) # 80002b1c <argint>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b4:	02054763          	bltz	a0,800052e2 <sys_read+0x5c>
    800052b8:	fd840593          	addi	a1,s0,-40
    800052bc:	4505                	li	a0,1
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	880080e7          	jalr	-1920(ra) # 80002b3e <argaddr>
    return -1;
    800052c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c8:	00054d63          	bltz	a0,800052e2 <sys_read+0x5c>
  return fileread(f, p, n);
    800052cc:	fe442603          	lw	a2,-28(s0)
    800052d0:	fd843583          	ld	a1,-40(s0)
    800052d4:	fe843503          	ld	a0,-24(s0)
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	44e080e7          	jalr	1102(ra) # 80004726 <fileread>
    800052e0:	87aa                	mv	a5,a0
}
    800052e2:	853e                	mv	a0,a5
    800052e4:	70a2                	ld	ra,40(sp)
    800052e6:	7402                	ld	s0,32(sp)
    800052e8:	6145                	addi	sp,sp,48
    800052ea:	8082                	ret

00000000800052ec <sys_write>:
{
    800052ec:	7179                	addi	sp,sp,-48
    800052ee:	f406                	sd	ra,40(sp)
    800052f0:	f022                	sd	s0,32(sp)
    800052f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f4:	fe840613          	addi	a2,s0,-24
    800052f8:	4581                	li	a1,0
    800052fa:	4501                	li	a0,0
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	d2a080e7          	jalr	-726(ra) # 80005026 <argfd>
    return -1;
    80005304:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005306:	04054163          	bltz	a0,80005348 <sys_write+0x5c>
    8000530a:	fe440593          	addi	a1,s0,-28
    8000530e:	4509                	li	a0,2
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	80c080e7          	jalr	-2036(ra) # 80002b1c <argint>
    return -1;
    80005318:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531a:	02054763          	bltz	a0,80005348 <sys_write+0x5c>
    8000531e:	fd840593          	addi	a1,s0,-40
    80005322:	4505                	li	a0,1
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	81a080e7          	jalr	-2022(ra) # 80002b3e <argaddr>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532e:	00054d63          	bltz	a0,80005348 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005332:	fe442603          	lw	a2,-28(s0)
    80005336:	fd843583          	ld	a1,-40(s0)
    8000533a:	fe843503          	ld	a0,-24(s0)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	4aa080e7          	jalr	1194(ra) # 800047e8 <filewrite>
    80005346:	87aa                	mv	a5,a0
}
    80005348:	853e                	mv	a0,a5
    8000534a:	70a2                	ld	ra,40(sp)
    8000534c:	7402                	ld	s0,32(sp)
    8000534e:	6145                	addi	sp,sp,48
    80005350:	8082                	ret

0000000080005352 <sys_close>:
{
    80005352:	1101                	addi	sp,sp,-32
    80005354:	ec06                	sd	ra,24(sp)
    80005356:	e822                	sd	s0,16(sp)
    80005358:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000535a:	fe040613          	addi	a2,s0,-32
    8000535e:	fec40593          	addi	a1,s0,-20
    80005362:	4501                	li	a0,0
    80005364:	00000097          	auipc	ra,0x0
    80005368:	cc2080e7          	jalr	-830(ra) # 80005026 <argfd>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000536e:	02054463          	bltz	a0,80005396 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005372:	ffffc097          	auipc	ra,0xffffc
    80005376:	6b6080e7          	jalr	1718(ra) # 80001a28 <myproc>
    8000537a:	fec42783          	lw	a5,-20(s0)
    8000537e:	07e9                	addi	a5,a5,26
    80005380:	078e                	slli	a5,a5,0x3
    80005382:	97aa                	add	a5,a5,a0
    80005384:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005388:	fe043503          	ld	a0,-32(s0)
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	260080e7          	jalr	608(ra) # 800045ec <fileclose>
  return 0;
    80005394:	4781                	li	a5,0
}
    80005396:	853e                	mv	a0,a5
    80005398:	60e2                	ld	ra,24(sp)
    8000539a:	6442                	ld	s0,16(sp)
    8000539c:	6105                	addi	sp,sp,32
    8000539e:	8082                	ret

00000000800053a0 <sys_fstat>:
{
    800053a0:	1101                	addi	sp,sp,-32
    800053a2:	ec06                	sd	ra,24(sp)
    800053a4:	e822                	sd	s0,16(sp)
    800053a6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a8:	fe840613          	addi	a2,s0,-24
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	c76080e7          	jalr	-906(ra) # 80005026 <argfd>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ba:	02054563          	bltz	a0,800053e4 <sys_fstat+0x44>
    800053be:	fe040593          	addi	a1,s0,-32
    800053c2:	4505                	li	a0,1
    800053c4:	ffffd097          	auipc	ra,0xffffd
    800053c8:	77a080e7          	jalr	1914(ra) # 80002b3e <argaddr>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ce:	00054b63          	bltz	a0,800053e4 <sys_fstat+0x44>
  return filestat(f, st);
    800053d2:	fe043583          	ld	a1,-32(s0)
    800053d6:	fe843503          	ld	a0,-24(s0)
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	2da080e7          	jalr	730(ra) # 800046b4 <filestat>
    800053e2:	87aa                	mv	a5,a0
}
    800053e4:	853e                	mv	a0,a5
    800053e6:	60e2                	ld	ra,24(sp)
    800053e8:	6442                	ld	s0,16(sp)
    800053ea:	6105                	addi	sp,sp,32
    800053ec:	8082                	ret

00000000800053ee <sys_link>:
{
    800053ee:	7169                	addi	sp,sp,-304
    800053f0:	f606                	sd	ra,296(sp)
    800053f2:	f222                	sd	s0,288(sp)
    800053f4:	ee26                	sd	s1,280(sp)
    800053f6:	ea4a                	sd	s2,272(sp)
    800053f8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053fa:	08000613          	li	a2,128
    800053fe:	ed040593          	addi	a1,s0,-304
    80005402:	4501                	li	a0,0
    80005404:	ffffd097          	auipc	ra,0xffffd
    80005408:	75c080e7          	jalr	1884(ra) # 80002b60 <argstr>
    return -1;
    8000540c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000540e:	10054e63          	bltz	a0,8000552a <sys_link+0x13c>
    80005412:	08000613          	li	a2,128
    80005416:	f5040593          	addi	a1,s0,-176
    8000541a:	4505                	li	a0,1
    8000541c:	ffffd097          	auipc	ra,0xffffd
    80005420:	744080e7          	jalr	1860(ra) # 80002b60 <argstr>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005426:	10054263          	bltz	a0,8000552a <sys_link+0x13c>
  begin_op();
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	cf0080e7          	jalr	-784(ra) # 8000411a <begin_op>
  if((ip = namei(old)) == 0){
    80005432:	ed040513          	addi	a0,s0,-304
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	ad8080e7          	jalr	-1320(ra) # 80003f0e <namei>
    8000543e:	84aa                	mv	s1,a0
    80005440:	c551                	beqz	a0,800054cc <sys_link+0xde>
  ilock(ip);
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	31c080e7          	jalr	796(ra) # 8000375e <ilock>
  if(ip->type == T_DIR){
    8000544a:	04449703          	lh	a4,68(s1)
    8000544e:	4785                	li	a5,1
    80005450:	08f70463          	beq	a4,a5,800054d8 <sys_link+0xea>
  ip->nlink++;
    80005454:	04a4d783          	lhu	a5,74(s1)
    80005458:	2785                	addiw	a5,a5,1
    8000545a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	234080e7          	jalr	564(ra) # 80003694 <iupdate>
  iunlock(ip);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	3b6080e7          	jalr	950(ra) # 80003820 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005472:	fd040593          	addi	a1,s0,-48
    80005476:	f5040513          	addi	a0,s0,-176
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	ab2080e7          	jalr	-1358(ra) # 80003f2c <nameiparent>
    80005482:	892a                	mv	s2,a0
    80005484:	c935                	beqz	a0,800054f8 <sys_link+0x10a>
  ilock(dp);
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	2d8080e7          	jalr	728(ra) # 8000375e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000548e:	00092703          	lw	a4,0(s2)
    80005492:	409c                	lw	a5,0(s1)
    80005494:	04f71d63          	bne	a4,a5,800054ee <sys_link+0x100>
    80005498:	40d0                	lw	a2,4(s1)
    8000549a:	fd040593          	addi	a1,s0,-48
    8000549e:	854a                	mv	a0,s2
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	9ac080e7          	jalr	-1620(ra) # 80003e4c <dirlink>
    800054a8:	04054363          	bltz	a0,800054ee <sys_link+0x100>
  iunlockput(dp);
    800054ac:	854a                	mv	a0,s2
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	512080e7          	jalr	1298(ra) # 800039c0 <iunlockput>
  iput(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	460080e7          	jalr	1120(ra) # 80003918 <iput>
  end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	cda080e7          	jalr	-806(ra) # 8000419a <end_op>
  return 0;
    800054c8:	4781                	li	a5,0
    800054ca:	a085                	j	8000552a <sys_link+0x13c>
    end_op();
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	cce080e7          	jalr	-818(ra) # 8000419a <end_op>
    return -1;
    800054d4:	57fd                	li	a5,-1
    800054d6:	a891                	j	8000552a <sys_link+0x13c>
    iunlockput(ip);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	4e6080e7          	jalr	1254(ra) # 800039c0 <iunlockput>
    end_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	cb8080e7          	jalr	-840(ra) # 8000419a <end_op>
    return -1;
    800054ea:	57fd                	li	a5,-1
    800054ec:	a83d                	j	8000552a <sys_link+0x13c>
    iunlockput(dp);
    800054ee:	854a                	mv	a0,s2
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	4d0080e7          	jalr	1232(ra) # 800039c0 <iunlockput>
  ilock(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	264080e7          	jalr	612(ra) # 8000375e <ilock>
  ip->nlink--;
    80005502:	04a4d783          	lhu	a5,74(s1)
    80005506:	37fd                	addiw	a5,a5,-1
    80005508:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	186080e7          	jalr	390(ra) # 80003694 <iupdate>
  iunlockput(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	4a8080e7          	jalr	1192(ra) # 800039c0 <iunlockput>
  end_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	c7a080e7          	jalr	-902(ra) # 8000419a <end_op>
  return -1;
    80005528:	57fd                	li	a5,-1
}
    8000552a:	853e                	mv	a0,a5
    8000552c:	70b2                	ld	ra,296(sp)
    8000552e:	7412                	ld	s0,288(sp)
    80005530:	64f2                	ld	s1,280(sp)
    80005532:	6952                	ld	s2,272(sp)
    80005534:	6155                	addi	sp,sp,304
    80005536:	8082                	ret

0000000080005538 <sys_unlink>:
{
    80005538:	7151                	addi	sp,sp,-240
    8000553a:	f586                	sd	ra,232(sp)
    8000553c:	f1a2                	sd	s0,224(sp)
    8000553e:	eda6                	sd	s1,216(sp)
    80005540:	e9ca                	sd	s2,208(sp)
    80005542:	e5ce                	sd	s3,200(sp)
    80005544:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005546:	08000613          	li	a2,128
    8000554a:	f3040593          	addi	a1,s0,-208
    8000554e:	4501                	li	a0,0
    80005550:	ffffd097          	auipc	ra,0xffffd
    80005554:	610080e7          	jalr	1552(ra) # 80002b60 <argstr>
    80005558:	18054163          	bltz	a0,800056da <sys_unlink+0x1a2>
  begin_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	bbe080e7          	jalr	-1090(ra) # 8000411a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005564:	fb040593          	addi	a1,s0,-80
    80005568:	f3040513          	addi	a0,s0,-208
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	9c0080e7          	jalr	-1600(ra) # 80003f2c <nameiparent>
    80005574:	84aa                	mv	s1,a0
    80005576:	c979                	beqz	a0,8000564c <sys_unlink+0x114>
  ilock(dp);
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	1e6080e7          	jalr	486(ra) # 8000375e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005580:	00003597          	auipc	a1,0x3
    80005584:	24058593          	addi	a1,a1,576 # 800087c0 <syscalls+0x2c8>
    80005588:	fb040513          	addi	a0,s0,-80
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	696080e7          	jalr	1686(ra) # 80003c22 <namecmp>
    80005594:	14050a63          	beqz	a0,800056e8 <sys_unlink+0x1b0>
    80005598:	00003597          	auipc	a1,0x3
    8000559c:	23058593          	addi	a1,a1,560 # 800087c8 <syscalls+0x2d0>
    800055a0:	fb040513          	addi	a0,s0,-80
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	67e080e7          	jalr	1662(ra) # 80003c22 <namecmp>
    800055ac:	12050e63          	beqz	a0,800056e8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055b0:	f2c40613          	addi	a2,s0,-212
    800055b4:	fb040593          	addi	a1,s0,-80
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	682080e7          	jalr	1666(ra) # 80003c3c <dirlookup>
    800055c2:	892a                	mv	s2,a0
    800055c4:	12050263          	beqz	a0,800056e8 <sys_unlink+0x1b0>
  ilock(ip);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	196080e7          	jalr	406(ra) # 8000375e <ilock>
  if(ip->nlink < 1)
    800055d0:	04a91783          	lh	a5,74(s2)
    800055d4:	08f05263          	blez	a5,80005658 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055d8:	04491703          	lh	a4,68(s2)
    800055dc:	4785                	li	a5,1
    800055de:	08f70563          	beq	a4,a5,80005668 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055e2:	4641                	li	a2,16
    800055e4:	4581                	li	a1,0
    800055e6:	fc040513          	addi	a0,s0,-64
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	76c080e7          	jalr	1900(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f2:	4741                	li	a4,16
    800055f4:	f2c42683          	lw	a3,-212(s0)
    800055f8:	fc040613          	addi	a2,s0,-64
    800055fc:	4581                	li	a1,0
    800055fe:	8526                	mv	a0,s1
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	508080e7          	jalr	1288(ra) # 80003b08 <writei>
    80005608:	47c1                	li	a5,16
    8000560a:	0af51563          	bne	a0,a5,800056b4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000560e:	04491703          	lh	a4,68(s2)
    80005612:	4785                	li	a5,1
    80005614:	0af70863          	beq	a4,a5,800056c4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	3a6080e7          	jalr	934(ra) # 800039c0 <iunlockput>
  ip->nlink--;
    80005622:	04a95783          	lhu	a5,74(s2)
    80005626:	37fd                	addiw	a5,a5,-1
    80005628:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	066080e7          	jalr	102(ra) # 80003694 <iupdate>
  iunlockput(ip);
    80005636:	854a                	mv	a0,s2
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	388080e7          	jalr	904(ra) # 800039c0 <iunlockput>
  end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b5a080e7          	jalr	-1190(ra) # 8000419a <end_op>
  return 0;
    80005648:	4501                	li	a0,0
    8000564a:	a84d                	j	800056fc <sys_unlink+0x1c4>
    end_op();
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	b4e080e7          	jalr	-1202(ra) # 8000419a <end_op>
    return -1;
    80005654:	557d                	li	a0,-1
    80005656:	a05d                	j	800056fc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005658:	00003517          	auipc	a0,0x3
    8000565c:	19850513          	addi	a0,a0,408 # 800087f0 <syscalls+0x2f8>
    80005660:	ffffb097          	auipc	ra,0xffffb
    80005664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005668:	04c92703          	lw	a4,76(s2)
    8000566c:	02000793          	li	a5,32
    80005670:	f6e7f9e3          	bgeu	a5,a4,800055e2 <sys_unlink+0xaa>
    80005674:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005678:	4741                	li	a4,16
    8000567a:	86ce                	mv	a3,s3
    8000567c:	f1840613          	addi	a2,s0,-232
    80005680:	4581                	li	a1,0
    80005682:	854a                	mv	a0,s2
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	38e080e7          	jalr	910(ra) # 80003a12 <readi>
    8000568c:	47c1                	li	a5,16
    8000568e:	00f51b63          	bne	a0,a5,800056a4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005692:	f1845783          	lhu	a5,-232(s0)
    80005696:	e7a1                	bnez	a5,800056de <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005698:	29c1                	addiw	s3,s3,16
    8000569a:	04c92783          	lw	a5,76(s2)
    8000569e:	fcf9ede3          	bltu	s3,a5,80005678 <sys_unlink+0x140>
    800056a2:	b781                	j	800055e2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056a4:	00003517          	auipc	a0,0x3
    800056a8:	16450513          	addi	a0,a0,356 # 80008808 <syscalls+0x310>
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	e9c080e7          	jalr	-356(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056b4:	00003517          	auipc	a0,0x3
    800056b8:	16c50513          	addi	a0,a0,364 # 80008820 <syscalls+0x328>
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	e8c080e7          	jalr	-372(ra) # 80000548 <panic>
    dp->nlink--;
    800056c4:	04a4d783          	lhu	a5,74(s1)
    800056c8:	37fd                	addiw	a5,a5,-1
    800056ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ce:	8526                	mv	a0,s1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	fc4080e7          	jalr	-60(ra) # 80003694 <iupdate>
    800056d8:	b781                	j	80005618 <sys_unlink+0xe0>
    return -1;
    800056da:	557d                	li	a0,-1
    800056dc:	a005                	j	800056fc <sys_unlink+0x1c4>
    iunlockput(ip);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	2e0080e7          	jalr	736(ra) # 800039c0 <iunlockput>
  iunlockput(dp);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	2d6080e7          	jalr	726(ra) # 800039c0 <iunlockput>
  end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	aa8080e7          	jalr	-1368(ra) # 8000419a <end_op>
  return -1;
    800056fa:	557d                	li	a0,-1
}
    800056fc:	70ae                	ld	ra,232(sp)
    800056fe:	740e                	ld	s0,224(sp)
    80005700:	64ee                	ld	s1,216(sp)
    80005702:	694e                	ld	s2,208(sp)
    80005704:	69ae                	ld	s3,200(sp)
    80005706:	616d                	addi	sp,sp,240
    80005708:	8082                	ret

000000008000570a <sys_open>:

uint64
sys_open(void)
{
    8000570a:	7131                	addi	sp,sp,-192
    8000570c:	fd06                	sd	ra,184(sp)
    8000570e:	f922                	sd	s0,176(sp)
    80005710:	f526                	sd	s1,168(sp)
    80005712:	f14a                	sd	s2,160(sp)
    80005714:	ed4e                	sd	s3,152(sp)
    80005716:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005718:	08000613          	li	a2,128
    8000571c:	f5040593          	addi	a1,s0,-176
    80005720:	4501                	li	a0,0
    80005722:	ffffd097          	auipc	ra,0xffffd
    80005726:	43e080e7          	jalr	1086(ra) # 80002b60 <argstr>
    return -1;
    8000572a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000572c:	0c054163          	bltz	a0,800057ee <sys_open+0xe4>
    80005730:	f4c40593          	addi	a1,s0,-180
    80005734:	4505                	li	a0,1
    80005736:	ffffd097          	auipc	ra,0xffffd
    8000573a:	3e6080e7          	jalr	998(ra) # 80002b1c <argint>
    8000573e:	0a054863          	bltz	a0,800057ee <sys_open+0xe4>

  begin_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	9d8080e7          	jalr	-1576(ra) # 8000411a <begin_op>

  if(omode & O_CREATE){
    8000574a:	f4c42783          	lw	a5,-180(s0)
    8000574e:	2007f793          	andi	a5,a5,512
    80005752:	cbdd                	beqz	a5,80005808 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005754:	4681                	li	a3,0
    80005756:	4601                	li	a2,0
    80005758:	4589                	li	a1,2
    8000575a:	f5040513          	addi	a0,s0,-176
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	972080e7          	jalr	-1678(ra) # 800050d0 <create>
    80005766:	892a                	mv	s2,a0
    if(ip == 0){
    80005768:	c959                	beqz	a0,800057fe <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000576a:	04491703          	lh	a4,68(s2)
    8000576e:	478d                	li	a5,3
    80005770:	00f71763          	bne	a4,a5,8000577e <sys_open+0x74>
    80005774:	04695703          	lhu	a4,70(s2)
    80005778:	47a5                	li	a5,9
    8000577a:	0ce7ec63          	bltu	a5,a4,80005852 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	db2080e7          	jalr	-590(ra) # 80004530 <filealloc>
    80005786:	89aa                	mv	s3,a0
    80005788:	10050263          	beqz	a0,8000588c <sys_open+0x182>
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	902080e7          	jalr	-1790(ra) # 8000508e <fdalloc>
    80005794:	84aa                	mv	s1,a0
    80005796:	0e054663          	bltz	a0,80005882 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000579a:	04491703          	lh	a4,68(s2)
    8000579e:	478d                	li	a5,3
    800057a0:	0cf70463          	beq	a4,a5,80005868 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057a4:	4789                	li	a5,2
    800057a6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057aa:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ae:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057b2:	f4c42783          	lw	a5,-180(s0)
    800057b6:	0017c713          	xori	a4,a5,1
    800057ba:	8b05                	andi	a4,a4,1
    800057bc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057c0:	0037f713          	andi	a4,a5,3
    800057c4:	00e03733          	snez	a4,a4
    800057c8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057cc:	4007f793          	andi	a5,a5,1024
    800057d0:	c791                	beqz	a5,800057dc <sys_open+0xd2>
    800057d2:	04491703          	lh	a4,68(s2)
    800057d6:	4789                	li	a5,2
    800057d8:	08f70f63          	beq	a4,a5,80005876 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057dc:	854a                	mv	a0,s2
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	042080e7          	jalr	66(ra) # 80003820 <iunlock>
  end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	9b4080e7          	jalr	-1612(ra) # 8000419a <end_op>

  return fd;
}
    800057ee:	8526                	mv	a0,s1
    800057f0:	70ea                	ld	ra,184(sp)
    800057f2:	744a                	ld	s0,176(sp)
    800057f4:	74aa                	ld	s1,168(sp)
    800057f6:	790a                	ld	s2,160(sp)
    800057f8:	69ea                	ld	s3,152(sp)
    800057fa:	6129                	addi	sp,sp,192
    800057fc:	8082                	ret
      end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	99c080e7          	jalr	-1636(ra) # 8000419a <end_op>
      return -1;
    80005806:	b7e5                	j	800057ee <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005808:	f5040513          	addi	a0,s0,-176
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	702080e7          	jalr	1794(ra) # 80003f0e <namei>
    80005814:	892a                	mv	s2,a0
    80005816:	c905                	beqz	a0,80005846 <sys_open+0x13c>
    ilock(ip);
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	f46080e7          	jalr	-186(ra) # 8000375e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005820:	04491703          	lh	a4,68(s2)
    80005824:	4785                	li	a5,1
    80005826:	f4f712e3          	bne	a4,a5,8000576a <sys_open+0x60>
    8000582a:	f4c42783          	lw	a5,-180(s0)
    8000582e:	dba1                	beqz	a5,8000577e <sys_open+0x74>
      iunlockput(ip);
    80005830:	854a                	mv	a0,s2
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	18e080e7          	jalr	398(ra) # 800039c0 <iunlockput>
      end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	960080e7          	jalr	-1696(ra) # 8000419a <end_op>
      return -1;
    80005842:	54fd                	li	s1,-1
    80005844:	b76d                	j	800057ee <sys_open+0xe4>
      end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	954080e7          	jalr	-1708(ra) # 8000419a <end_op>
      return -1;
    8000584e:	54fd                	li	s1,-1
    80005850:	bf79                	j	800057ee <sys_open+0xe4>
    iunlockput(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	16c080e7          	jalr	364(ra) # 800039c0 <iunlockput>
    end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	93e080e7          	jalr	-1730(ra) # 8000419a <end_op>
    return -1;
    80005864:	54fd                	li	s1,-1
    80005866:	b761                	j	800057ee <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005868:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000586c:	04691783          	lh	a5,70(s2)
    80005870:	02f99223          	sh	a5,36(s3)
    80005874:	bf2d                	j	800057ae <sys_open+0xa4>
    itrunc(ip);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	ff4080e7          	jalr	-12(ra) # 8000386c <itrunc>
    80005880:	bfb1                	j	800057dc <sys_open+0xd2>
      fileclose(f);
    80005882:	854e                	mv	a0,s3
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	d68080e7          	jalr	-664(ra) # 800045ec <fileclose>
    iunlockput(ip);
    8000588c:	854a                	mv	a0,s2
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	132080e7          	jalr	306(ra) # 800039c0 <iunlockput>
    end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	904080e7          	jalr	-1788(ra) # 8000419a <end_op>
    return -1;
    8000589e:	54fd                	li	s1,-1
    800058a0:	b7b9                	j	800057ee <sys_open+0xe4>

00000000800058a2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058a2:	7175                	addi	sp,sp,-144
    800058a4:	e506                	sd	ra,136(sp)
    800058a6:	e122                	sd	s0,128(sp)
    800058a8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	870080e7          	jalr	-1936(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058b2:	08000613          	li	a2,128
    800058b6:	f7040593          	addi	a1,s0,-144
    800058ba:	4501                	li	a0,0
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	2a4080e7          	jalr	676(ra) # 80002b60 <argstr>
    800058c4:	02054963          	bltz	a0,800058f6 <sys_mkdir+0x54>
    800058c8:	4681                	li	a3,0
    800058ca:	4601                	li	a2,0
    800058cc:	4585                	li	a1,1
    800058ce:	f7040513          	addi	a0,s0,-144
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	7fe080e7          	jalr	2046(ra) # 800050d0 <create>
    800058da:	cd11                	beqz	a0,800058f6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	0e4080e7          	jalr	228(ra) # 800039c0 <iunlockput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	8b6080e7          	jalr	-1866(ra) # 8000419a <end_op>
  return 0;
    800058ec:	4501                	li	a0,0
}
    800058ee:	60aa                	ld	ra,136(sp)
    800058f0:	640a                	ld	s0,128(sp)
    800058f2:	6149                	addi	sp,sp,144
    800058f4:	8082                	ret
    end_op();
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	8a4080e7          	jalr	-1884(ra) # 8000419a <end_op>
    return -1;
    800058fe:	557d                	li	a0,-1
    80005900:	b7fd                	j	800058ee <sys_mkdir+0x4c>

0000000080005902 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005902:	7135                	addi	sp,sp,-160
    80005904:	ed06                	sd	ra,152(sp)
    80005906:	e922                	sd	s0,144(sp)
    80005908:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	810080e7          	jalr	-2032(ra) # 8000411a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005912:	08000613          	li	a2,128
    80005916:	f7040593          	addi	a1,s0,-144
    8000591a:	4501                	li	a0,0
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	244080e7          	jalr	580(ra) # 80002b60 <argstr>
    80005924:	04054a63          	bltz	a0,80005978 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005928:	f6c40593          	addi	a1,s0,-148
    8000592c:	4505                	li	a0,1
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	1ee080e7          	jalr	494(ra) # 80002b1c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005936:	04054163          	bltz	a0,80005978 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000593a:	f6840593          	addi	a1,s0,-152
    8000593e:	4509                	li	a0,2
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	1dc080e7          	jalr	476(ra) # 80002b1c <argint>
     argint(1, &major) < 0 ||
    80005948:	02054863          	bltz	a0,80005978 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000594c:	f6841683          	lh	a3,-152(s0)
    80005950:	f6c41603          	lh	a2,-148(s0)
    80005954:	458d                	li	a1,3
    80005956:	f7040513          	addi	a0,s0,-144
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	776080e7          	jalr	1910(ra) # 800050d0 <create>
     argint(2, &minor) < 0 ||
    80005962:	c919                	beqz	a0,80005978 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	05c080e7          	jalr	92(ra) # 800039c0 <iunlockput>
  end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	82e080e7          	jalr	-2002(ra) # 8000419a <end_op>
  return 0;
    80005974:	4501                	li	a0,0
    80005976:	a031                	j	80005982 <sys_mknod+0x80>
    end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	822080e7          	jalr	-2014(ra) # 8000419a <end_op>
    return -1;
    80005980:	557d                	li	a0,-1
}
    80005982:	60ea                	ld	ra,152(sp)
    80005984:	644a                	ld	s0,144(sp)
    80005986:	610d                	addi	sp,sp,160
    80005988:	8082                	ret

000000008000598a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000598a:	7135                	addi	sp,sp,-160
    8000598c:	ed06                	sd	ra,152(sp)
    8000598e:	e922                	sd	s0,144(sp)
    80005990:	e526                	sd	s1,136(sp)
    80005992:	e14a                	sd	s2,128(sp)
    80005994:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005996:	ffffc097          	auipc	ra,0xffffc
    8000599a:	092080e7          	jalr	146(ra) # 80001a28 <myproc>
    8000599e:	892a                	mv	s2,a0
  
  begin_op();
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	77a080e7          	jalr	1914(ra) # 8000411a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059a8:	08000613          	li	a2,128
    800059ac:	f6040593          	addi	a1,s0,-160
    800059b0:	4501                	li	a0,0
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	1ae080e7          	jalr	430(ra) # 80002b60 <argstr>
    800059ba:	04054b63          	bltz	a0,80005a10 <sys_chdir+0x86>
    800059be:	f6040513          	addi	a0,s0,-160
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	54c080e7          	jalr	1356(ra) # 80003f0e <namei>
    800059ca:	84aa                	mv	s1,a0
    800059cc:	c131                	beqz	a0,80005a10 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	d90080e7          	jalr	-624(ra) # 8000375e <ilock>
  if(ip->type != T_DIR){
    800059d6:	04449703          	lh	a4,68(s1)
    800059da:	4785                	li	a5,1
    800059dc:	04f71063          	bne	a4,a5,80005a1c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	e3e080e7          	jalr	-450(ra) # 80003820 <iunlock>
  iput(p->cwd);
    800059ea:	15093503          	ld	a0,336(s2)
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	f2a080e7          	jalr	-214(ra) # 80003918 <iput>
  end_op();
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	7a4080e7          	jalr	1956(ra) # 8000419a <end_op>
  p->cwd = ip;
    800059fe:	14993823          	sd	s1,336(s2)
  return 0;
    80005a02:	4501                	li	a0,0
}
    80005a04:	60ea                	ld	ra,152(sp)
    80005a06:	644a                	ld	s0,144(sp)
    80005a08:	64aa                	ld	s1,136(sp)
    80005a0a:	690a                	ld	s2,128(sp)
    80005a0c:	610d                	addi	sp,sp,160
    80005a0e:	8082                	ret
    end_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	78a080e7          	jalr	1930(ra) # 8000419a <end_op>
    return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	b7ed                	j	80005a04 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	fa2080e7          	jalr	-94(ra) # 800039c0 <iunlockput>
    end_op();
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	774080e7          	jalr	1908(ra) # 8000419a <end_op>
    return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	bfd1                	j	80005a04 <sys_chdir+0x7a>

0000000080005a32 <sys_exec>:

uint64
sys_exec(void)
{
    80005a32:	7145                	addi	sp,sp,-464
    80005a34:	e786                	sd	ra,456(sp)
    80005a36:	e3a2                	sd	s0,448(sp)
    80005a38:	ff26                	sd	s1,440(sp)
    80005a3a:	fb4a                	sd	s2,432(sp)
    80005a3c:	f74e                	sd	s3,424(sp)
    80005a3e:	f352                	sd	s4,416(sp)
    80005a40:	ef56                	sd	s5,408(sp)
    80005a42:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a44:	08000613          	li	a2,128
    80005a48:	f4040593          	addi	a1,s0,-192
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	112080e7          	jalr	274(ra) # 80002b60 <argstr>
    return -1;
    80005a56:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a58:	0c054a63          	bltz	a0,80005b2c <sys_exec+0xfa>
    80005a5c:	e3840593          	addi	a1,s0,-456
    80005a60:	4505                	li	a0,1
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	0dc080e7          	jalr	220(ra) # 80002b3e <argaddr>
    80005a6a:	0c054163          	bltz	a0,80005b2c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a6e:	10000613          	li	a2,256
    80005a72:	4581                	li	a1,0
    80005a74:	e4040513          	addi	a0,s0,-448
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	2de080e7          	jalr	734(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a80:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a84:	89a6                	mv	s3,s1
    80005a86:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a88:	02000a13          	li	s4,32
    80005a8c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a90:	00391513          	slli	a0,s2,0x3
    80005a94:	e3040593          	addi	a1,s0,-464
    80005a98:	e3843783          	ld	a5,-456(s0)
    80005a9c:	953e                	add	a0,a0,a5
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	fe4080e7          	jalr	-28(ra) # 80002a82 <fetchaddr>
    80005aa6:	02054a63          	bltz	a0,80005ada <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aaa:	e3043783          	ld	a5,-464(s0)
    80005aae:	c3b9                	beqz	a5,80005af4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	070080e7          	jalr	112(ra) # 80000b20 <kalloc>
    80005ab8:	85aa                	mv	a1,a0
    80005aba:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005abe:	cd11                	beqz	a0,80005ada <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ac0:	6605                	lui	a2,0x1
    80005ac2:	e3043503          	ld	a0,-464(s0)
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	00e080e7          	jalr	14(ra) # 80002ad4 <fetchstr>
    80005ace:	00054663          	bltz	a0,80005ada <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ad2:	0905                	addi	s2,s2,1
    80005ad4:	09a1                	addi	s3,s3,8
    80005ad6:	fb491be3          	bne	s2,s4,80005a8c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ada:	10048913          	addi	s2,s1,256
    80005ade:	6088                	ld	a0,0(s1)
    80005ae0:	c529                	beqz	a0,80005b2a <sys_exec+0xf8>
    kfree(argv[i]);
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	f42080e7          	jalr	-190(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aea:	04a1                	addi	s1,s1,8
    80005aec:	ff2499e3          	bne	s1,s2,80005ade <sys_exec+0xac>
  return -1;
    80005af0:	597d                	li	s2,-1
    80005af2:	a82d                	j	80005b2c <sys_exec+0xfa>
      argv[i] = 0;
    80005af4:	0a8e                	slli	s5,s5,0x3
    80005af6:	fc040793          	addi	a5,s0,-64
    80005afa:	9abe                	add	s5,s5,a5
    80005afc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b00:	e4040593          	addi	a1,s0,-448
    80005b04:	f4040513          	addi	a0,s0,-192
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	194080e7          	jalr	404(ra) # 80004c9c <exec>
    80005b10:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b12:	10048993          	addi	s3,s1,256
    80005b16:	6088                	ld	a0,0(s1)
    80005b18:	c911                	beqz	a0,80005b2c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b1a:	ffffb097          	auipc	ra,0xffffb
    80005b1e:	f0a080e7          	jalr	-246(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b22:	04a1                	addi	s1,s1,8
    80005b24:	ff3499e3          	bne	s1,s3,80005b16 <sys_exec+0xe4>
    80005b28:	a011                	j	80005b2c <sys_exec+0xfa>
  return -1;
    80005b2a:	597d                	li	s2,-1
}
    80005b2c:	854a                	mv	a0,s2
    80005b2e:	60be                	ld	ra,456(sp)
    80005b30:	641e                	ld	s0,448(sp)
    80005b32:	74fa                	ld	s1,440(sp)
    80005b34:	795a                	ld	s2,432(sp)
    80005b36:	79ba                	ld	s3,424(sp)
    80005b38:	7a1a                	ld	s4,416(sp)
    80005b3a:	6afa                	ld	s5,408(sp)
    80005b3c:	6179                	addi	sp,sp,464
    80005b3e:	8082                	ret

0000000080005b40 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b40:	7139                	addi	sp,sp,-64
    80005b42:	fc06                	sd	ra,56(sp)
    80005b44:	f822                	sd	s0,48(sp)
    80005b46:	f426                	sd	s1,40(sp)
    80005b48:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	ede080e7          	jalr	-290(ra) # 80001a28 <myproc>
    80005b52:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b54:	fd840593          	addi	a1,s0,-40
    80005b58:	4501                	li	a0,0
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	fe4080e7          	jalr	-28(ra) # 80002b3e <argaddr>
    return -1;
    80005b62:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b64:	0e054063          	bltz	a0,80005c44 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b68:	fc840593          	addi	a1,s0,-56
    80005b6c:	fd040513          	addi	a0,s0,-48
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	dd2080e7          	jalr	-558(ra) # 80004942 <pipealloc>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b7a:	0c054563          	bltz	a0,80005c44 <sys_pipe+0x104>
  fd0 = -1;
    80005b7e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b82:	fd043503          	ld	a0,-48(s0)
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	508080e7          	jalr	1288(ra) # 8000508e <fdalloc>
    80005b8e:	fca42223          	sw	a0,-60(s0)
    80005b92:	08054c63          	bltz	a0,80005c2a <sys_pipe+0xea>
    80005b96:	fc843503          	ld	a0,-56(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	4f4080e7          	jalr	1268(ra) # 8000508e <fdalloc>
    80005ba2:	fca42023          	sw	a0,-64(s0)
    80005ba6:	06054863          	bltz	a0,80005c16 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005baa:	4691                	li	a3,4
    80005bac:	fc440613          	addi	a2,s0,-60
    80005bb0:	fd843583          	ld	a1,-40(s0)
    80005bb4:	68a8                	ld	a0,80(s1)
    80005bb6:	ffffc097          	auipc	ra,0xffffc
    80005bba:	b66080e7          	jalr	-1178(ra) # 8000171c <copyout>
    80005bbe:	02054063          	bltz	a0,80005bde <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bc2:	4691                	li	a3,4
    80005bc4:	fc040613          	addi	a2,s0,-64
    80005bc8:	fd843583          	ld	a1,-40(s0)
    80005bcc:	0591                	addi	a1,a1,4
    80005bce:	68a8                	ld	a0,80(s1)
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	b4c080e7          	jalr	-1204(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bd8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bda:	06055563          	bgez	a0,80005c44 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bde:	fc442783          	lw	a5,-60(s0)
    80005be2:	07e9                	addi	a5,a5,26
    80005be4:	078e                	slli	a5,a5,0x3
    80005be6:	97a6                	add	a5,a5,s1
    80005be8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bec:	fc042503          	lw	a0,-64(s0)
    80005bf0:	0569                	addi	a0,a0,26
    80005bf2:	050e                	slli	a0,a0,0x3
    80005bf4:	9526                	add	a0,a0,s1
    80005bf6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bfa:	fd043503          	ld	a0,-48(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	9ee080e7          	jalr	-1554(ra) # 800045ec <fileclose>
    fileclose(wf);
    80005c06:	fc843503          	ld	a0,-56(s0)
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	9e2080e7          	jalr	-1566(ra) # 800045ec <fileclose>
    return -1;
    80005c12:	57fd                	li	a5,-1
    80005c14:	a805                	j	80005c44 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c16:	fc442783          	lw	a5,-60(s0)
    80005c1a:	0007c863          	bltz	a5,80005c2a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c1e:	01a78513          	addi	a0,a5,26
    80005c22:	050e                	slli	a0,a0,0x3
    80005c24:	9526                	add	a0,a0,s1
    80005c26:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c2a:	fd043503          	ld	a0,-48(s0)
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	9be080e7          	jalr	-1602(ra) # 800045ec <fileclose>
    fileclose(wf);
    80005c36:	fc843503          	ld	a0,-56(s0)
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	9b2080e7          	jalr	-1614(ra) # 800045ec <fileclose>
    return -1;
    80005c42:	57fd                	li	a5,-1
}
    80005c44:	853e                	mv	a0,a5
    80005c46:	70e2                	ld	ra,56(sp)
    80005c48:	7442                	ld	s0,48(sp)
    80005c4a:	74a2                	ld	s1,40(sp)
    80005c4c:	6121                	addi	sp,sp,64
    80005c4e:	8082                	ret

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	cbffc0ef          	jal	ra,8000294e <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	710c                	ld	a1,32(a0)
    80005cec:	7510                	ld	a2,40(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	cd4080e7          	jalr	-812(ra) # 800019fc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	953e                	add	a0,a0,a5
    80005d4c:	00052023          	sw	zero,0(a0)
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	c9c080e7          	jalr	-868(ra) # 800019fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5179b          	slliw	a5,a0,0xd
    80005d6c:	0c201537          	lui	a0,0xc201
    80005d70:	953e                	add	a0,a0,a5
  return irq;
}
    80005d72:	4148                	lw	a0,4(a0)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	c74080e7          	jalr	-908(ra) # 800019fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	04a7cc63          	blt	a5,a0,80005e08 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005db4:	0001d797          	auipc	a5,0x1d
    80005db8:	24c78793          	addi	a5,a5,588 # 80023000 <disk>
    80005dbc:	00a78733          	add	a4,a5,a0
    80005dc0:	6789                	lui	a5,0x2
    80005dc2:	97ba                	add	a5,a5,a4
    80005dc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc8:	eba1                	bnez	a5,80005e18 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dca:	00451713          	slli	a4,a0,0x4
    80005dce:	0001f797          	auipc	a5,0x1f
    80005dd2:	2327b783          	ld	a5,562(a5) # 80025000 <disk+0x2000>
    80005dd6:	97ba                	add	a5,a5,a4
    80005dd8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ddc:	0001d797          	auipc	a5,0x1d
    80005de0:	22478793          	addi	a5,a5,548 # 80023000 <disk>
    80005de4:	97aa                	add	a5,a5,a0
    80005de6:	6509                	lui	a0,0x2
    80005de8:	953e                	add	a0,a0,a5
    80005dea:	4785                	li	a5,1
    80005dec:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005df0:	0001f517          	auipc	a0,0x1f
    80005df4:	22850513          	addi	a0,a0,552 # 80025018 <disk+0x2018>
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	5ce080e7          	jalr	1486(ra) # 800023c6 <wakeup>
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	a2850513          	addi	a0,a0,-1496 # 80008830 <syscalls+0x338>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	738080e7          	jalr	1848(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	a3050513          	addi	a0,a0,-1488 # 80008848 <syscalls+0x350>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	728080e7          	jalr	1832(ra) # 80000548 <panic>

0000000080005e28 <virtio_disk_init>:
{
    80005e28:	1101                	addi	sp,sp,-32
    80005e2a:	ec06                	sd	ra,24(sp)
    80005e2c:	e822                	sd	s0,16(sp)
    80005e2e:	e426                	sd	s1,8(sp)
    80005e30:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e32:	00003597          	auipc	a1,0x3
    80005e36:	a2e58593          	addi	a1,a1,-1490 # 80008860 <syscalls+0x368>
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	26e50513          	addi	a0,a0,622 # 800250a8 <disk+0x20a8>
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	d88080e7          	jalr	-632(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	4398                	lw	a4,0(a5)
    80005e50:	2701                	sext.w	a4,a4
    80005e52:	747277b7          	lui	a5,0x74727
    80005e56:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e5a:	0ef71163          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	43dc                	lw	a5,4(a5)
    80005e64:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e66:	4705                	li	a4,1
    80005e68:	0ce79a63          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	479c                	lw	a5,8(a5)
    80005e72:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e74:	4709                	li	a4,2
    80005e76:	0ce79363          	bne	a5,a4,80005f3c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e7a:	100017b7          	lui	a5,0x10001
    80005e7e:	47d8                	lw	a4,12(a5)
    80005e80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e82:	554d47b7          	lui	a5,0x554d4
    80005e86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e8a:	0af71963          	bne	a4,a5,80005f3c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	100017b7          	lui	a5,0x10001
    80005e92:	4705                	li	a4,1
    80005e94:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e96:	470d                	li	a4,3
    80005e98:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e9a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e9c:	c7ffe737          	lui	a4,0xc7ffe
    80005ea0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ea4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea6:	2701                	sext.w	a4,a4
    80005ea8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	472d                	li	a4,11
    80005eac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	473d                	li	a4,15
    80005eb0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eb2:	6705                	lui	a4,0x1
    80005eb4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eba:	5bdc                	lw	a5,52(a5)
    80005ebc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ebe:	c7d9                	beqz	a5,80005f4c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ec0:	471d                	li	a4,7
    80005ec2:	08f77d63          	bgeu	a4,a5,80005f5c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec6:	100014b7          	lui	s1,0x10001
    80005eca:	47a1                	li	a5,8
    80005ecc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ece:	6609                	lui	a2,0x2
    80005ed0:	4581                	li	a1,0
    80005ed2:	0001d517          	auipc	a0,0x1d
    80005ed6:	12e50513          	addi	a0,a0,302 # 80023000 <disk>
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	e7c080e7          	jalr	-388(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	11e70713          	addi	a4,a4,286 # 80023000 <disk>
    80005eea:	00c75793          	srli	a5,a4,0xc
    80005eee:	2781                	sext.w	a5,a5
    80005ef0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ef2:	0001f797          	auipc	a5,0x1f
    80005ef6:	10e78793          	addi	a5,a5,270 # 80025000 <disk+0x2000>
    80005efa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005efc:	0001d717          	auipc	a4,0x1d
    80005f00:	18470713          	addi	a4,a4,388 # 80023080 <disk+0x80>
    80005f04:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f06:	0001e717          	auipc	a4,0x1e
    80005f0a:	0fa70713          	addi	a4,a4,250 # 80024000 <disk+0x1000>
    80005f0e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f10:	4705                	li	a4,1
    80005f12:	00e78c23          	sb	a4,24(a5)
    80005f16:	00e78ca3          	sb	a4,25(a5)
    80005f1a:	00e78d23          	sb	a4,26(a5)
    80005f1e:	00e78da3          	sb	a4,27(a5)
    80005f22:	00e78e23          	sb	a4,28(a5)
    80005f26:	00e78ea3          	sb	a4,29(a5)
    80005f2a:	00e78f23          	sb	a4,30(a5)
    80005f2e:	00e78fa3          	sb	a4,31(a5)
}
    80005f32:	60e2                	ld	ra,24(sp)
    80005f34:	6442                	ld	s0,16(sp)
    80005f36:	64a2                	ld	s1,8(sp)
    80005f38:	6105                	addi	sp,sp,32
    80005f3a:	8082                	ret
    panic("could not find virtio disk");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	93450513          	addi	a0,a0,-1740 # 80008870 <syscalls+0x378>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	94450513          	addi	a0,a0,-1724 # 80008890 <syscalls+0x398>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5f4080e7          	jalr	1524(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	95450513          	addi	a0,a0,-1708 # 800088b0 <syscalls+0x3b8>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>

0000000080005f6c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f6c:	7119                	addi	sp,sp,-128
    80005f6e:	fc86                	sd	ra,120(sp)
    80005f70:	f8a2                	sd	s0,112(sp)
    80005f72:	f4a6                	sd	s1,104(sp)
    80005f74:	f0ca                	sd	s2,96(sp)
    80005f76:	ecce                	sd	s3,88(sp)
    80005f78:	e8d2                	sd	s4,80(sp)
    80005f7a:	e4d6                	sd	s5,72(sp)
    80005f7c:	e0da                	sd	s6,64(sp)
    80005f7e:	fc5e                	sd	s7,56(sp)
    80005f80:	f862                	sd	s8,48(sp)
    80005f82:	f466                	sd	s9,40(sp)
    80005f84:	f06a                	sd	s10,32(sp)
    80005f86:	0100                	addi	s0,sp,128
    80005f88:	892a                	mv	s2,a0
    80005f8a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f8c:	00c52c83          	lw	s9,12(a0)
    80005f90:	001c9c9b          	slliw	s9,s9,0x1
    80005f94:	1c82                	slli	s9,s9,0x20
    80005f96:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	cb8080e7          	jalr	-840(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80005faa:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fac:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fae:	0001db97          	auipc	s7,0x1d
    80005fb2:	052b8b93          	addi	s7,s7,82 # 80023000 <disk>
    80005fb6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fb8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fba:	8a4e                	mv	s4,s3
    80005fbc:	a051                	j	80006040 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fbe:	00fb86b3          	add	a3,s7,a5
    80005fc2:	96da                	add	a3,a3,s6
    80005fc4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fc8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fca:	0207c563          	bltz	a5,80005ff4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fce:	2485                	addiw	s1,s1,1
    80005fd0:	0711                	addi	a4,a4,4
    80005fd2:	23548d63          	beq	s1,s5,8000620c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fd6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fd8:	0001f697          	auipc	a3,0x1f
    80005fdc:	04068693          	addi	a3,a3,64 # 80025018 <disk+0x2018>
    80005fe0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fe2:	0006c583          	lbu	a1,0(a3)
    80005fe6:	fde1                	bnez	a1,80005fbe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe8:	2785                	addiw	a5,a5,1
    80005fea:	0685                	addi	a3,a3,1
    80005fec:	ff879be3          	bne	a5,s8,80005fe2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005ff0:	57fd                	li	a5,-1
    80005ff2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ff4:	02905a63          	blez	s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff8:	f9042503          	lw	a0,-112(s0)
    80005ffc:	00000097          	auipc	ra,0x0
    80006000:	daa080e7          	jalr	-598(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006004:	4785                	li	a5,1
    80006006:	0297d163          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000600a:	f9442503          	lw	a0,-108(s0)
    8000600e:	00000097          	auipc	ra,0x0
    80006012:	d98080e7          	jalr	-616(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006016:	4789                	li	a5,2
    80006018:	0097d863          	bge	a5,s1,80006028 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000601c:	f9842503          	lw	a0,-104(s0)
    80006020:	00000097          	auipc	ra,0x0
    80006024:	d86080e7          	jalr	-634(ra) # 80005da6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006028:	0001f597          	auipc	a1,0x1f
    8000602c:	08058593          	addi	a1,a1,128 # 800250a8 <disk+0x20a8>
    80006030:	0001f517          	auipc	a0,0x1f
    80006034:	fe850513          	addi	a0,a0,-24 # 80025018 <disk+0x2018>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	208080e7          	jalr	520(ra) # 80002240 <sleep>
  for(int i = 0; i < 3; i++){
    80006040:	f9040713          	addi	a4,s0,-112
    80006044:	84ce                	mv	s1,s3
    80006046:	bf41                	j	80005fd6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006048:	4785                	li	a5,1
    8000604a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000604e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006052:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006056:	f9042983          	lw	s3,-112(s0)
    8000605a:	00499493          	slli	s1,s3,0x4
    8000605e:	0001fa17          	auipc	s4,0x1f
    80006062:	fa2a0a13          	addi	s4,s4,-94 # 80025000 <disk+0x2000>
    80006066:	000a3a83          	ld	s5,0(s4)
    8000606a:	9aa6                	add	s5,s5,s1
    8000606c:	f8040513          	addi	a0,s0,-128
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	0ba080e7          	jalr	186(ra) # 8000112a <kvmpa>
    80006078:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000607c:	000a3783          	ld	a5,0(s4)
    80006080:	97a6                	add	a5,a5,s1
    80006082:	4741                	li	a4,16
    80006084:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006086:	000a3783          	ld	a5,0(s4)
    8000608a:	97a6                	add	a5,a5,s1
    8000608c:	4705                	li	a4,1
    8000608e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006092:	f9442703          	lw	a4,-108(s0)
    80006096:	000a3783          	ld	a5,0(s4)
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060a0:	0712                	slli	a4,a4,0x4
    800060a2:	000a3783          	ld	a5,0(s4)
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	05890693          	addi	a3,s2,88
    800060ac:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ae:	000a3783          	ld	a5,0(s4)
    800060b2:	97ba                	add	a5,a5,a4
    800060b4:	40000693          	li	a3,1024
    800060b8:	c794                	sw	a3,8(a5)
  if(write)
    800060ba:	100d0a63          	beqz	s10,800061ce <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060be:	0001f797          	auipc	a5,0x1f
    800060c2:	f427b783          	ld	a5,-190(a5) # 80025000 <disk+0x2000>
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	0001f797          	auipc	a5,0x1f
    800060d8:	f2c78793          	addi	a5,a5,-212 # 80025000 <disk+0x2000>
    800060dc:	6394                	ld	a3,0(a5)
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00c6d603          	lhu	a2,12(a3)
    800060e4:	00166613          	ori	a2,a2,1
    800060e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ec:	f9842683          	lw	a3,-104(s0)
    800060f0:	6390                	ld	a2,0(a5)
    800060f2:	9732                	add	a4,a4,a2
    800060f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060f8:	20098613          	addi	a2,s3,512
    800060fc:	0612                	slli	a2,a2,0x4
    800060fe:	962a                	add	a2,a2,a0
    80006100:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006104:	00469713          	slli	a4,a3,0x4
    80006108:	6394                	ld	a3,0(a5)
    8000610a:	96ba                	add	a3,a3,a4
    8000610c:	6589                	lui	a1,0x2
    8000610e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006112:	94ae                	add	s1,s1,a1
    80006114:	94aa                	add	s1,s1,a0
    80006116:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006118:	6394                	ld	a3,0(a5)
    8000611a:	96ba                	add	a3,a3,a4
    8000611c:	4585                	li	a1,1
    8000611e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4509                	li	a0,2
    80006126:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000612a:	6394                	ld	a3,0(a5)
    8000612c:	9736                	add	a4,a4,a3
    8000612e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006132:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006136:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000613a:	6794                	ld	a3,8(a5)
    8000613c:	0026d703          	lhu	a4,2(a3)
    80006140:	8b1d                	andi	a4,a4,7
    80006142:	2709                	addiw	a4,a4,2
    80006144:	0706                	slli	a4,a4,0x1
    80006146:	9736                	add	a4,a4,a3
    80006148:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000614c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006150:	6798                	ld	a4,8(a5)
    80006152:	00275783          	lhu	a5,2(a4)
    80006156:	2785                	addiw	a5,a5,1
    80006158:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006164:	00492703          	lw	a4,4(s2)
    80006168:	4785                	li	a5,1
    8000616a:	02f71163          	bne	a4,a5,8000618c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	f3a98993          	addi	s3,s3,-198 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006176:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006178:	85ce                	mv	a1,s3
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	0c4080e7          	jalr	196(ra) # 80002240 <sleep>
  while(b->disk == 1) {
    80006184:	00492783          	lw	a5,4(s2)
    80006188:	fe9788e3          	beq	a5,s1,80006178 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000618c:	f9042483          	lw	s1,-112(s0)
    80006190:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006194:	00479713          	slli	a4,a5,0x4
    80006198:	0001d797          	auipc	a5,0x1d
    8000619c:	e6878793          	addi	a5,a5,-408 # 80023000 <disk>
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061a6:	0001f917          	auipc	s2,0x1f
    800061aa:	e5a90913          	addi	s2,s2,-422 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ae:	8526                	mv	a0,s1
    800061b0:	00000097          	auipc	ra,0x0
    800061b4:	bf6080e7          	jalr	-1034(ra) # 80005da6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061b8:	0492                	slli	s1,s1,0x4
    800061ba:	00093783          	ld	a5,0(s2)
    800061be:	94be                	add	s1,s1,a5
    800061c0:	00c4d783          	lhu	a5,12(s1)
    800061c4:	8b85                	andi	a5,a5,1
    800061c6:	cf89                	beqz	a5,800061e0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061c8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061cc:	b7cd                	j	800061ae <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ce:	0001f797          	auipc	a5,0x1f
    800061d2:	e327b783          	ld	a5,-462(a5) # 80025000 <disk+0x2000>
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	4689                	li	a3,2
    800061da:	00d79623          	sh	a3,12(a5)
    800061de:	b5fd                	j	800060cc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061e0:	0001f517          	auipc	a0,0x1f
    800061e4:	ec850513          	addi	a0,a0,-312 # 800250a8 <disk+0x20a8>
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	b26080e7          	jalr	-1242(ra) # 80000d0e <release>
}
    800061f0:	70e6                	ld	ra,120(sp)
    800061f2:	7446                	ld	s0,112(sp)
    800061f4:	74a6                	ld	s1,104(sp)
    800061f6:	7906                	ld	s2,96(sp)
    800061f8:	69e6                	ld	s3,88(sp)
    800061fa:	6a46                	ld	s4,80(sp)
    800061fc:	6aa6                	ld	s5,72(sp)
    800061fe:	6b06                	ld	s6,64(sp)
    80006200:	7be2                	ld	s7,56(sp)
    80006202:	7c42                	ld	s8,48(sp)
    80006204:	7ca2                	ld	s9,40(sp)
    80006206:	7d02                	ld	s10,32(sp)
    80006208:	6109                	addi	sp,sp,128
    8000620a:	8082                	ret
  if(write)
    8000620c:	e20d1ee3          	bnez	s10,80006048 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006210:	f8042023          	sw	zero,-128(s0)
    80006214:	bd2d                	j	8000604e <virtio_disk_rw+0xe2>

0000000080006216 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006216:	1101                	addi	sp,sp,-32
    80006218:	ec06                	sd	ra,24(sp)
    8000621a:	e822                	sd	s0,16(sp)
    8000621c:	e426                	sd	s1,8(sp)
    8000621e:	e04a                	sd	s2,0(sp)
    80006220:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006222:	0001f517          	auipc	a0,0x1f
    80006226:	e8650513          	addi	a0,a0,-378 # 800250a8 <disk+0x20a8>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	a30080e7          	jalr	-1488(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	0001f717          	auipc	a4,0x1f
    80006236:	dce70713          	addi	a4,a4,-562 # 80025000 <disk+0x2000>
    8000623a:	02075783          	lhu	a5,32(a4)
    8000623e:	6b18                	ld	a4,16(a4)
    80006240:	00275683          	lhu	a3,2(a4)
    80006244:	8ebd                	xor	a3,a3,a5
    80006246:	8a9d                	andi	a3,a3,7
    80006248:	cab9                	beqz	a3,8000629e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000624a:	0001d917          	auipc	s2,0x1d
    8000624e:	db690913          	addi	s2,s2,-586 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006252:	0001f497          	auipc	s1,0x1f
    80006256:	dae48493          	addi	s1,s1,-594 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000625a:	078e                	slli	a5,a5,0x3
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006260:	20078713          	addi	a4,a5,512
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	974a                	add	a4,a4,s2
    80006268:	03074703          	lbu	a4,48(a4)
    8000626c:	ef21                	bnez	a4,800062c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000626e:	20078793          	addi	a5,a5,512
    80006272:	0792                	slli	a5,a5,0x4
    80006274:	97ca                	add	a5,a5,s2
    80006276:	7798                	ld	a4,40(a5)
    80006278:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000627c:	7788                	ld	a0,40(a5)
    8000627e:	ffffc097          	auipc	ra,0xffffc
    80006282:	148080e7          	jalr	328(ra) # 800023c6 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006286:	0204d783          	lhu	a5,32(s1)
    8000628a:	2785                	addiw	a5,a5,1
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	6898                	ld	a4,16(s1)
    80006294:	00275683          	lhu	a3,2(a4)
    80006298:	8a9d                	andi	a3,a3,7
    8000629a:	fcf690e3          	bne	a3,a5,8000625a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000629e:	10001737          	lui	a4,0x10001
    800062a2:	533c                	lw	a5,96(a4)
    800062a4:	8b8d                	andi	a5,a5,3
    800062a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062a8:	0001f517          	auipc	a0,0x1f
    800062ac:	e0050513          	addi	a0,a0,-512 # 800250a8 <disk+0x20a8>
    800062b0:	ffffb097          	auipc	ra,0xffffb
    800062b4:	a5e080e7          	jalr	-1442(ra) # 80000d0e <release>
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6902                	ld	s2,0(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret
      panic("virtio_disk_intr status");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	60c50513          	addi	a0,a0,1548 # 800088d0 <syscalls+0x3d8>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	27c080e7          	jalr	636(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
