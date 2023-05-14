
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
    80000060:	e5478793          	addi	a5,a5,-428 # 80005eb0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	584080e7          	jalr	1412(ra) # 800026aa <either_copyin>
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
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	862080e7          	jalr	-1950(ra) # 80001a30 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	214080e7          	jalr	532(ra) # 800023f2 <sleep>
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
    8000021e:	43a080e7          	jalr	1082(ra) # 80002654 <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	404080e7          	jalr	1028(ra) # 80002700 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	128080e7          	jalr	296(ra) # 80002578 <wakeup>
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
    80000466:	b9e58593          	addi	a1,a1,-1122 # 80008000 <etext>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

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
    800004c8:	b6c60613          	addi	a2,a2,-1172 # 80008030 <digits>
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
    80000560:	aac50513          	addi	a0,a0,-1364 # 80008008 <etext+0x8>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b4250513          	addi	a0,a0,-1214 # 800080b8 <digits+0x88>
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
    800005f4:	a40b8b93          	addi	s7,s7,-1472 # 80008030 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a0450513          	addi	a0,a0,-1532 # 80008018 <etext+0x18>
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
    80000718:	8fc90913          	addi	s2,s2,-1796 # 80008010 <etext+0x10>
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
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
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
    8000078e:	89e58593          	addi	a1,a1,-1890 # 80008028 <etext+0x28>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
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
    800007de:	86e58593          	addi	a1,a1,-1938 # 80008048 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
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
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

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
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
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
    800008ba:	cc2080e7          	jalr	-830(ra) # 80002578 <wakeup>
    
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
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
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
    80000954:	aa2080e7          	jalr	-1374(ra) # 800023f2 <sleep>
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
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
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
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5c650513          	addi	a0,a0,1478 # 80008050 <digits+0x20>
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
    80000af0:	56c58593          	addi	a1,a1,1388 # 80008058 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
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
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
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
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e6a080e7          	jalr	-406(ra) # 80001a14 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	e38080e7          	jalr	-456(ra) # 80001a14 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	e2c080e7          	jalr	-468(ra) # 80001a14 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	e14080e7          	jalr	-492(ra) # 80001a14 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	dd4080e7          	jalr	-556(ra) # 80001a14 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	40c50513          	addi	a0,a0,1036 # 80008060 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	da8080e7          	jalr	-600(ra) # 80001a14 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3c450513          	addi	a0,a0,964 # 80008068 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3cc50513          	addi	a0,a0,972 # 80008080 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	38c50513          	addi	a0,a0,908 # 80008088 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	b3e080e7          	jalr	-1218(ra) # 80001a04 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	b22080e7          	jalr	-1246(ra) # 80001a04 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1bc50513          	addi	a0,a0,444 # 800080a8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	20e080e7          	jalr	526(ra) # 8000110a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	93c080e7          	jalr	-1732(ra) # 80002840 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	fe4080e7          	jalr	-28(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	1e8080e7          	jalr	488(ra) # 800020fc <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	78e080e7          	jalr	1934(ra) # 800066b2 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	18450513          	addi	a0,a0,388 # 800080b8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	14c50513          	addi	a0,a0,332 # 80008090 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	16450513          	addi	a0,a0,356 # 800080b8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	46a080e7          	jalr	1130(ra) # 800013d6 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	196080e7          	jalr	406(ra) # 8000110a <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	a28080e7          	jalr	-1496(ra) # 800019a4 <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	894080e7          	jalr	-1900(ra) # 80002818 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	8b4080e7          	jalr	-1868(ra) # 80002840 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	f46080e7          	jalr	-186(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	f54080e7          	jalr	-172(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	088080e7          	jalr	136(ra) # 8000302c <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	718080e7          	jalr	1816(ra) # 800036c4 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	6b2080e7          	jalr	1714(ra) # 80004666 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	03c080e7          	jalr	60(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	e60080e7          	jalr	-416(ra) # 80001e24 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <traversal_pt>:
  if (flag & PTE_U){
      arr[i] = 'U';
    }
}

static void traversal_pt(pagetable_t pagetable, int level){
    80000fdc:	7119                	addi	sp,sp,-128
    80000fde:	fc86                	sd	ra,120(sp)
    80000fe0:	f8a2                	sd	s0,112(sp)
    80000fe2:	f4a6                	sd	s1,104(sp)
    80000fe4:	f0ca                	sd	s2,96(sp)
    80000fe6:	ecce                	sd	s3,88(sp)
    80000fe8:	e8d2                	sd	s4,80(sp)
    80000fea:	e4d6                	sd	s5,72(sp)
    80000fec:	e0da                	sd	s6,64(sp)
    80000fee:	fc5e                	sd	s7,56(sp)
    80000ff0:	f862                	sd	s8,48(sp)
    80000ff2:	f466                	sd	s9,40(sp)
    80000ff4:	f06a                	sd	s10,32(sp)
    80000ff6:	ec6e                	sd	s11,24(sp)
    80000ff8:	0100                	addi	s0,sp,128
    80000ffa:	8a2e                	mv	s4,a1
  for(int i = 0; i < 512; i++){
    80000ffc:	892a                	mv	s2,a0
    80000ffe:	4481                	li	s1,0
      char arr[4] = {'\0', '\0', '\0', '\0'};
	  flag_to_char(pte % 32, arr);
      if (level == 0){
        printf("..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
        traversal_pt((pagetable_t)child, level + 1);
      }else if (level == 1){
    80001000:	4a85                	li	s5,1
        printf(".. ..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
        traversal_pt((pagetable_t)child, level + 1);
      }else{
        printf(".. .. ..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    80001002:	00007c97          	auipc	s9,0x7
    80001006:	0fec8c93          	addi	s9,s9,254 # 80008100 <digits+0xd0>
        printf(".. ..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    8000100a:	00007d97          	auipc	s11,0x7
    8000100e:	0d6d8d93          	addi	s11,s11,214 # 800080e0 <digits+0xb0>
        printf("..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    80001012:	00007d17          	auipc	s10,0x7
    80001016:	0aed0d13          	addi	s10,s10,174 # 800080c0 <digits+0x90>
      arr[i] = 'U';
    8000101a:	05500c13          	li	s8,85
      arr[i++] = 'X';
    8000101e:	05800b93          	li	s7,88
      arr[i++] = 'W';
    80001022:	05700b13          	li	s6,87
    80001026:	a081                	j	80001066 <traversal_pt+0x8a>
        printf("..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    80001028:	874e                	mv	a4,s3
    8000102a:	f8840693          	addi	a3,s0,-120
    8000102e:	85a6                	mv	a1,s1
    80001030:	856a                	mv	a0,s10
    80001032:	fffff097          	auipc	ra,0xfffff
    80001036:	560080e7          	jalr	1376(ra) # 80000592 <printf>
        traversal_pt((pagetable_t)child, level + 1);
    8000103a:	85d6                	mv	a1,s5
    8000103c:	854e                	mv	a0,s3
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	f9e080e7          	jalr	-98(ra) # 80000fdc <traversal_pt>
    80001046:	a811                	j	8000105a <traversal_pt+0x7e>
        printf(".. .. ..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    80001048:	874e                	mv	a4,s3
    8000104a:	f8840693          	addi	a3,s0,-120
    8000104e:	85a6                	mv	a1,s1
    80001050:	8566                	mv	a0,s9
    80001052:	fffff097          	auipc	ra,0xfffff
    80001056:	540080e7          	jalr	1344(ra) # 80000592 <printf>
  for(int i = 0; i < 512; i++){
    8000105a:	2485                	addiw	s1,s1,1
    8000105c:	0921                	addi	s2,s2,8
    8000105e:	20000793          	li	a5,512
    80001062:	08f48563          	beq	s1,a5,800010ec <traversal_pt+0x110>
    pte_t pte = pagetable[i];
    80001066:	00093603          	ld	a2,0(s2)
    if(pte & PTE_V){
    8000106a:	00167793          	andi	a5,a2,1
    8000106e:	d7f5                	beqz	a5,8000105a <traversal_pt+0x7e>
      uint64 child = PTE2PA(pte);
    80001070:	00a65993          	srli	s3,a2,0xa
    80001074:	09b2                	slli	s3,s3,0xc
      char arr[4] = {'\0', '\0', '\0', '\0'};
    80001076:	f8042423          	sw	zero,-120(s0)
	  flag_to_char(pte % 32, arr);
    8000107a:	0006079b          	sext.w	a5,a2
  if (flag & PTE_R){
    8000107e:	0027f693          	andi	a3,a5,2
    80001082:	0006871b          	sext.w	a4,a3
    80001086:	c691                	beqz	a3,80001092 <traversal_pt+0xb6>
      arr[i++] = 'R';
    80001088:	05200713          	li	a4,82
    8000108c:	f8e40423          	sb	a4,-120(s0)
    80001090:	8756                	mv	a4,s5
  if (flag & PTE_W){
    80001092:	0047f693          	andi	a3,a5,4
    80001096:	c699                	beqz	a3,800010a4 <traversal_pt+0xc8>
      arr[i++] = 'W';
    80001098:	f9040693          	addi	a3,s0,-112
    8000109c:	96ba                	add	a3,a3,a4
    8000109e:	ff668c23          	sb	s6,-8(a3)
    800010a2:	2705                	addiw	a4,a4,1
  if (flag & PTE_X){
    800010a4:	0087f693          	andi	a3,a5,8
    800010a8:	c699                	beqz	a3,800010b6 <traversal_pt+0xda>
      arr[i++] = 'X';
    800010aa:	f9040693          	addi	a3,s0,-112
    800010ae:	96ba                	add	a3,a3,a4
    800010b0:	ff768c23          	sb	s7,-8(a3)
    800010b4:	2705                	addiw	a4,a4,1
  if (flag & PTE_U){
    800010b6:	8bc1                	andi	a5,a5,16
    800010b8:	c791                	beqz	a5,800010c4 <traversal_pt+0xe8>
      arr[i] = 'U';
    800010ba:	f9040793          	addi	a5,s0,-112
    800010be:	973e                	add	a4,a4,a5
    800010c0:	ff870c23          	sb	s8,-8(a4)
      if (level == 0){
    800010c4:	f60a02e3          	beqz	s4,80001028 <traversal_pt+0x4c>
      }else if (level == 1){
    800010c8:	f95a10e3          	bne	s4,s5,80001048 <traversal_pt+0x6c>
        printf(".. ..%d: pte %p (%s) pa %p\n", i, pte, arr, child);
    800010cc:	874e                	mv	a4,s3
    800010ce:	f8840693          	addi	a3,s0,-120
    800010d2:	85a6                	mv	a1,s1
    800010d4:	856e                	mv	a0,s11
    800010d6:	fffff097          	auipc	ra,0xfffff
    800010da:	4bc080e7          	jalr	1212(ra) # 80000592 <printf>
        traversal_pt((pagetable_t)child, level + 1);
    800010de:	4589                	li	a1,2
    800010e0:	854e                	mv	a0,s3
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	efa080e7          	jalr	-262(ra) # 80000fdc <traversal_pt>
    800010ea:	bf85                	j	8000105a <traversal_pt+0x7e>
      }
    }
  }
}
    800010ec:	70e6                	ld	ra,120(sp)
    800010ee:	7446                	ld	s0,112(sp)
    800010f0:	74a6                	ld	s1,104(sp)
    800010f2:	7906                	ld	s2,96(sp)
    800010f4:	69e6                	ld	s3,88(sp)
    800010f6:	6a46                	ld	s4,80(sp)
    800010f8:	6aa6                	ld	s5,72(sp)
    800010fa:	6b06                	ld	s6,64(sp)
    800010fc:	7be2                	ld	s7,56(sp)
    800010fe:	7c42                	ld	s8,48(sp)
    80001100:	7ca2                	ld	s9,40(sp)
    80001102:	7d02                	ld	s10,32(sp)
    80001104:	6de2                	ld	s11,24(sp)
    80001106:	6109                	addi	sp,sp,128
    80001108:	8082                	ret

000000008000110a <kvminithart>:
{
    8000110a:	1141                	addi	sp,sp,-16
    8000110c:	e422                	sd	s0,8(sp)
    8000110e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001110:	00008797          	auipc	a5,0x8
    80001114:	f007b783          	ld	a5,-256(a5) # 80009010 <kernel_pagetable>
    80001118:	83b1                	srli	a5,a5,0xc
    8000111a:	577d                	li	a4,-1
    8000111c:	177e                	slli	a4,a4,0x3f
    8000111e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001120:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001124:	12000073          	sfence.vma
}
    80001128:	6422                	ld	s0,8(sp)
    8000112a:	0141                	addi	sp,sp,16
    8000112c:	8082                	ret

000000008000112e <walk>:
{
    8000112e:	7139                	addi	sp,sp,-64
    80001130:	fc06                	sd	ra,56(sp)
    80001132:	f822                	sd	s0,48(sp)
    80001134:	f426                	sd	s1,40(sp)
    80001136:	f04a                	sd	s2,32(sp)
    80001138:	ec4e                	sd	s3,24(sp)
    8000113a:	e852                	sd	s4,16(sp)
    8000113c:	e456                	sd	s5,8(sp)
    8000113e:	e05a                	sd	s6,0(sp)
    80001140:	0080                	addi	s0,sp,64
    80001142:	84aa                	mv	s1,a0
    80001144:	89ae                	mv	s3,a1
    80001146:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001148:	57fd                	li	a5,-1
    8000114a:	83e9                	srli	a5,a5,0x1a
    8000114c:	4a79                	li	s4,30
  for(int level = 2; level > 0; level--) {
    8000114e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001150:	04b7f263          	bgeu	a5,a1,80001194 <walk+0x66>
    panic("walk");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fcc50513          	addi	a0,a0,-52 # 80008120 <digits+0xf0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3ec080e7          	jalr	1004(ra) # 80000548 <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001164:	060a8663          	beqz	s5,800011d0 <walk+0xa2>
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	9b8080e7          	jalr	-1608(ra) # 80000b20 <kalloc>
    80001170:	84aa                	mv	s1,a0
    80001172:	c529                	beqz	a0,800011bc <walk+0x8e>
      memset(pagetable, 0, PGSIZE);
    80001174:	6605                	lui	a2,0x1
    80001176:	4581                	li	a1,0
    80001178:	00000097          	auipc	ra,0x0
    8000117c:	b94080e7          	jalr	-1132(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001180:	00c4d793          	srli	a5,s1,0xc
    80001184:	07aa                	slli	a5,a5,0xa
    80001186:	0017e793          	ori	a5,a5,1
    8000118a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000118e:	3a5d                	addiw	s4,s4,-9
    80001190:	036a0063          	beq	s4,s6,800011b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001194:	0149d933          	srl	s2,s3,s4
    80001198:	1ff97913          	andi	s2,s2,511
    8000119c:	090e                	slli	s2,s2,0x3
    8000119e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011a0:	00093483          	ld	s1,0(s2)
    800011a4:	0014f793          	andi	a5,s1,1
    800011a8:	dfd5                	beqz	a5,80001164 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011aa:	80a9                	srli	s1,s1,0xa
    800011ac:	04b2                	slli	s1,s1,0xc
    800011ae:	b7c5                	j	8000118e <walk+0x60>
  return &pagetable[PX(0, va)];
    800011b0:	00c9d513          	srli	a0,s3,0xc
    800011b4:	1ff57513          	andi	a0,a0,511
    800011b8:	050e                	slli	a0,a0,0x3
    800011ba:	9526                	add	a0,a0,s1
}
    800011bc:	70e2                	ld	ra,56(sp)
    800011be:	7442                	ld	s0,48(sp)
    800011c0:	74a2                	ld	s1,40(sp)
    800011c2:	7902                	ld	s2,32(sp)
    800011c4:	69e2                	ld	s3,24(sp)
    800011c6:	6a42                	ld	s4,16(sp)
    800011c8:	6aa2                	ld	s5,8(sp)
    800011ca:	6b02                	ld	s6,0(sp)
    800011cc:	6121                	addi	sp,sp,64
    800011ce:	8082                	ret
        return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7ed                	j	800011bc <walk+0x8e>

00000000800011d4 <walkaddr>:
  if(va >= MAXVA)
    800011d4:	57fd                	li	a5,-1
    800011d6:	83e9                	srli	a5,a5,0x1a
    800011d8:	00b7f463          	bgeu	a5,a1,800011e0 <walkaddr+0xc>
    return 0;
    800011dc:	4501                	li	a0,0
}
    800011de:	8082                	ret
{
    800011e0:	1141                	addi	sp,sp,-16
    800011e2:	e406                	sd	ra,8(sp)
    800011e4:	e022                	sd	s0,0(sp)
    800011e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011e8:	4601                	li	a2,0
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f44080e7          	jalr	-188(ra) # 8000112e <walk>
  if(pte == 0)
    800011f2:	c105                	beqz	a0,80001212 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011f6:	0117f693          	andi	a3,a5,17
    800011fa:	4745                	li	a4,17
    return 0;
    800011fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011fe:	00e68663          	beq	a3,a4,8000120a <walkaddr+0x36>
}
    80001202:	60a2                	ld	ra,8(sp)
    80001204:	6402                	ld	s0,0(sp)
    80001206:	0141                	addi	sp,sp,16
    80001208:	8082                	ret
  pa = PTE2PA(*pte);
    8000120a:	00a7d513          	srli	a0,a5,0xa
    8000120e:	0532                	slli	a0,a0,0xc
  return pa;
    80001210:	bfcd                	j	80001202 <walkaddr+0x2e>
    return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7fd                	j	80001202 <walkaddr+0x2e>

0000000080001216 <kvmpa>:
{
    80001216:	1101                	addi	sp,sp,-32
    80001218:	ec06                	sd	ra,24(sp)
    8000121a:	e822                	sd	s0,16(sp)
    8000121c:	e426                	sd	s1,8(sp)
    8000121e:	e04a                	sd	s2,0(sp)
    80001220:	1000                	addi	s0,sp,32
    80001222:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    80001224:	1552                	slli	a0,a0,0x34
    80001226:	03455913          	srli	s2,a0,0x34
  pte = walk(myproc()->kernelPageTable, va, 0);
    8000122a:	00001097          	auipc	ra,0x1
    8000122e:	806080e7          	jalr	-2042(ra) # 80001a30 <myproc>
    80001232:	4601                	li	a2,0
    80001234:	85a6                	mv	a1,s1
    80001236:	6d28                	ld	a0,88(a0)
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	ef6080e7          	jalr	-266(ra) # 8000112e <walk>
  if(pte == 0)
    80001240:	cd11                	beqz	a0,8000125c <kvmpa+0x46>
  if((*pte & PTE_V) == 0)
    80001242:	6108                	ld	a0,0(a0)
    80001244:	00157793          	andi	a5,a0,1
    80001248:	c395                	beqz	a5,8000126c <kvmpa+0x56>
  pa = PTE2PA(*pte);
    8000124a:	8129                	srli	a0,a0,0xa
    8000124c:	0532                	slli	a0,a0,0xc
}
    8000124e:	954a                	add	a0,a0,s2
    80001250:	60e2                	ld	ra,24(sp)
    80001252:	6442                	ld	s0,16(sp)
    80001254:	64a2                	ld	s1,8(sp)
    80001256:	6902                	ld	s2,0(sp)
    80001258:	6105                	addi	sp,sp,32
    8000125a:	8082                	ret
    panic("kvmpa");
    8000125c:	00007517          	auipc	a0,0x7
    80001260:	ecc50513          	addi	a0,a0,-308 # 80008128 <digits+0xf8>
    80001264:	fffff097          	auipc	ra,0xfffff
    80001268:	2e4080e7          	jalr	740(ra) # 80000548 <panic>
    panic("kvmpa");
    8000126c:	00007517          	auipc	a0,0x7
    80001270:	ebc50513          	addi	a0,a0,-324 # 80008128 <digits+0xf8>
    80001274:	fffff097          	auipc	ra,0xfffff
    80001278:	2d4080e7          	jalr	724(ra) # 80000548 <panic>

000000008000127c <mappages>:
{
    8000127c:	715d                	addi	sp,sp,-80
    8000127e:	e486                	sd	ra,72(sp)
    80001280:	e0a2                	sd	s0,64(sp)
    80001282:	fc26                	sd	s1,56(sp)
    80001284:	f84a                	sd	s2,48(sp)
    80001286:	f44e                	sd	s3,40(sp)
    80001288:	f052                	sd	s4,32(sp)
    8000128a:	ec56                	sd	s5,24(sp)
    8000128c:	e85a                	sd	s6,16(sp)
    8000128e:	e45e                	sd	s7,8(sp)
    80001290:	0880                	addi	s0,sp,80
    80001292:	8aaa                	mv	s5,a0
    80001294:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001296:	777d                	lui	a4,0xfffff
    80001298:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000129c:	167d                	addi	a2,a2,-1
    8000129e:	00b609b3          	add	s3,a2,a1
    800012a2:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012a6:	893e                	mv	s2,a5
    800012a8:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    800012ac:	6b85                	lui	s7,0x1
    800012ae:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012b2:	4605                	li	a2,1
    800012b4:	85ca                	mv	a1,s2
    800012b6:	8556                	mv	a0,s5
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	e76080e7          	jalr	-394(ra) # 8000112e <walk>
    800012c0:	c51d                	beqz	a0,800012ee <mappages+0x72>
    if(*pte & PTE_V)
    800012c2:	611c                	ld	a5,0(a0)
    800012c4:	8b85                	andi	a5,a5,1
    800012c6:	ef81                	bnez	a5,800012de <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012c8:	80b1                	srli	s1,s1,0xc
    800012ca:	04aa                	slli	s1,s1,0xa
    800012cc:	0164e4b3          	or	s1,s1,s6
    800012d0:	0014e493          	ori	s1,s1,1
    800012d4:	e104                	sd	s1,0(a0)
    if(a == last)
    800012d6:	03390863          	beq	s2,s3,80001306 <mappages+0x8a>
    a += PGSIZE;
    800012da:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012dc:	bfc9                	j	800012ae <mappages+0x32>
      panic("remap");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	e5250513          	addi	a0,a0,-430 # 80008130 <digits+0x100>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	262080e7          	jalr	610(ra) # 80000548 <panic>
      return -1;
    800012ee:	557d                	li	a0,-1
}
    800012f0:	60a6                	ld	ra,72(sp)
    800012f2:	6406                	ld	s0,64(sp)
    800012f4:	74e2                	ld	s1,56(sp)
    800012f6:	7942                	ld	s2,48(sp)
    800012f8:	79a2                	ld	s3,40(sp)
    800012fa:	7a02                	ld	s4,32(sp)
    800012fc:	6ae2                	ld	s5,24(sp)
    800012fe:	6b42                	ld	s6,16(sp)
    80001300:	6ba2                	ld	s7,8(sp)
    80001302:	6161                	addi	sp,sp,80
    80001304:	8082                	ret
  return 0;
    80001306:	4501                	li	a0,0
    80001308:	b7e5                	j	800012f0 <mappages+0x74>

000000008000130a <kvmmake>:
pagetable_t kvmmake(){
    8000130a:	1101                	addi	sp,sp,-32
    8000130c:	ec06                	sd	ra,24(sp)
    8000130e:	e822                	sd	s0,16(sp)
    80001310:	e426                	sd	s1,8(sp)
    80001312:	e04a                	sd	s2,0(sp)
    80001314:	1000                	addi	s0,sp,32
  pagetable_t kernel_pagetable = (pagetable_t) kalloc();
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	80a080e7          	jalr	-2038(ra) # 80000b20 <kalloc>
    8000131e:	84aa                	mv	s1,a0
  memset(kernel_pagetable, 0, PGSIZE);
    80001320:	6605                	lui	a2,0x1
    80001322:	4581                	li	a1,0
    80001324:	00000097          	auipc	ra,0x0
    80001328:	9e8080e7          	jalr	-1560(ra) # 80000d0c <memset>
  mappages(kernel_pagetable, UART0, PGSIZE, UART0, PTE_R | PTE_W);
    8000132c:	4719                	li	a4,6
    8000132e:	100006b7          	lui	a3,0x10000
    80001332:	6605                	lui	a2,0x1
    80001334:	100005b7          	lui	a1,0x10000
    80001338:	8526                	mv	a0,s1
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f42080e7          	jalr	-190(ra) # 8000127c <mappages>
  mappages(kernel_pagetable, VIRTIO0, PGSIZE, VIRTIO0,PTE_R | PTE_W);
    80001342:	4719                	li	a4,6
    80001344:	100016b7          	lui	a3,0x10001
    80001348:	6605                	lui	a2,0x1
    8000134a:	100015b7          	lui	a1,0x10001
    8000134e:	8526                	mv	a0,s1
    80001350:	00000097          	auipc	ra,0x0
    80001354:	f2c080e7          	jalr	-212(ra) # 8000127c <mappages>
  mappages(kernel_pagetable, PLIC,0x400000, PLIC,PTE_R | PTE_W);
    80001358:	4719                	li	a4,6
    8000135a:	0c0006b7          	lui	a3,0xc000
    8000135e:	00400637          	lui	a2,0x400
    80001362:	0c0005b7          	lui	a1,0xc000
    80001366:	8526                	mv	a0,s1
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	f14080e7          	jalr	-236(ra) # 8000127c <mappages>
  mappages(kernel_pagetable, KERNBASE,(uint64)etext-KERNBASE, KERNBASE, PTE_R | PTE_X);
    80001370:	00007917          	auipc	s2,0x7
    80001374:	c9090913          	addi	s2,s2,-880 # 80008000 <etext>
    80001378:	4729                	li	a4,10
    8000137a:	4685                	li	a3,1
    8000137c:	06fe                	slli	a3,a3,0x1f
    8000137e:	80007617          	auipc	a2,0x80007
    80001382:	c8260613          	addi	a2,a2,-894 # 8000 <_entry-0x7fff8000>
    80001386:	85b6                	mv	a1,a3
    80001388:	8526                	mv	a0,s1
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	ef2080e7          	jalr	-270(ra) # 8000127c <mappages>
  mappages(kernel_pagetable, (uint64)etext,PHYSTOP-(uint64)etext, (uint64)etext,PTE_R | PTE_W);
    80001392:	4719                	li	a4,6
    80001394:	86ca                	mv	a3,s2
    80001396:	4645                	li	a2,17
    80001398:	066e                	slli	a2,a2,0x1b
    8000139a:	41260633          	sub	a2,a2,s2
    8000139e:	85ca                	mv	a1,s2
    800013a0:	8526                	mv	a0,s1
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	eda080e7          	jalr	-294(ra) # 8000127c <mappages>
  mappages(kernel_pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X);
    800013aa:	4729                	li	a4,10
    800013ac:	00006697          	auipc	a3,0x6
    800013b0:	c5468693          	addi	a3,a3,-940 # 80007000 <_trampoline>
    800013b4:	6605                	lui	a2,0x1
    800013b6:	040005b7          	lui	a1,0x4000
    800013ba:	15fd                	addi	a1,a1,-1
    800013bc:	05b2                	slli	a1,a1,0xc
    800013be:	8526                	mv	a0,s1
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	ebc080e7          	jalr	-324(ra) # 8000127c <mappages>
}
    800013c8:	8526                	mv	a0,s1
    800013ca:	60e2                	ld	ra,24(sp)
    800013cc:	6442                	ld	s0,16(sp)
    800013ce:	64a2                	ld	s1,8(sp)
    800013d0:	6902                	ld	s2,0(sp)
    800013d2:	6105                	addi	sp,sp,32
    800013d4:	8082                	ret

00000000800013d6 <kvminit>:
{
    800013d6:	1141                	addi	sp,sp,-16
    800013d8:	e406                	sd	ra,8(sp)
    800013da:	e022                	sd	s0,0(sp)
    800013dc:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	f2c080e7          	jalr	-212(ra) # 8000130a <kvmmake>
    800013e6:	00008797          	auipc	a5,0x8
    800013ea:	c2a7b523          	sd	a0,-982(a5) # 80009010 <kernel_pagetable>
  mappages(kernel_pagetable, CLINT,0x10000, CLINT, PTE_R | PTE_W);
    800013ee:	4719                	li	a4,6
    800013f0:	020006b7          	lui	a3,0x2000
    800013f4:	6641                	lui	a2,0x10
    800013f6:	020005b7          	lui	a1,0x2000
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	e82080e7          	jalr	-382(ra) # 8000127c <mappages>
}
    80001402:	60a2                	ld	ra,8(sp)
    80001404:	6402                	ld	s0,0(sp)
    80001406:	0141                	addi	sp,sp,16
    80001408:	8082                	ret

000000008000140a <kvmmap>:
{
    8000140a:	1141                	addi	sp,sp,-16
    8000140c:	e406                	sd	ra,8(sp)
    8000140e:	e022                	sd	s0,0(sp)
    80001410:	0800                	addi	s0,sp,16
    80001412:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001414:	86ae                	mv	a3,a1
    80001416:	85aa                	mv	a1,a0
    80001418:	00008517          	auipc	a0,0x8
    8000141c:	bf853503          	ld	a0,-1032(a0) # 80009010 <kernel_pagetable>
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5c080e7          	jalr	-420(ra) # 8000127c <mappages>
    80001428:	e509                	bnez	a0,80001432 <kvmmap+0x28>
}
    8000142a:	60a2                	ld	ra,8(sp)
    8000142c:	6402                	ld	s0,0(sp)
    8000142e:	0141                	addi	sp,sp,16
    80001430:	8082                	ret
    panic("kvmmap");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d0650513          	addi	a0,a0,-762 # 80008138 <digits+0x108>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	10e080e7          	jalr	270(ra) # 80000548 <panic>

0000000080001442 <uvmunmap>:
{
    80001442:	715d                	addi	sp,sp,-80
    80001444:	e486                	sd	ra,72(sp)
    80001446:	e0a2                	sd	s0,64(sp)
    80001448:	fc26                	sd	s1,56(sp)
    8000144a:	f84a                	sd	s2,48(sp)
    8000144c:	f44e                	sd	s3,40(sp)
    8000144e:	f052                	sd	s4,32(sp)
    80001450:	ec56                	sd	s5,24(sp)
    80001452:	e85a                	sd	s6,16(sp)
    80001454:	e45e                	sd	s7,8(sp)
    80001456:	0880                	addi	s0,sp,80
  if((va % PGSIZE) != 0)
    80001458:	03459793          	slli	a5,a1,0x34
    8000145c:	e795                	bnez	a5,80001488 <uvmunmap+0x46>
    8000145e:	8a2a                	mv	s4,a0
    80001460:	892e                	mv	s2,a1
    80001462:	8ab6                	mv	s5,a3
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001464:	0632                	slli	a2,a2,0xc
    80001466:	00b609b3          	add	s3,a2,a1
    if(PTE_FLAGS(*pte) == PTE_V)
    8000146a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000146c:	6b05                	lui	s6,0x1
    8000146e:	0735e863          	bltu	a1,s3,800014de <uvmunmap+0x9c>
}
    80001472:	60a6                	ld	ra,72(sp)
    80001474:	6406                	ld	s0,64(sp)
    80001476:	74e2                	ld	s1,56(sp)
    80001478:	7942                	ld	s2,48(sp)
    8000147a:	79a2                	ld	s3,40(sp)
    8000147c:	7a02                	ld	s4,32(sp)
    8000147e:	6ae2                	ld	s5,24(sp)
    80001480:	6b42                	ld	s6,16(sp)
    80001482:	6ba2                	ld	s7,8(sp)
    80001484:	6161                	addi	sp,sp,80
    80001486:	8082                	ret
    panic("uvmunmap: not aligned");
    80001488:	00007517          	auipc	a0,0x7
    8000148c:	cb850513          	addi	a0,a0,-840 # 80008140 <digits+0x110>
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	0b8080e7          	jalr	184(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001498:	00007517          	auipc	a0,0x7
    8000149c:	cc050513          	addi	a0,a0,-832 # 80008158 <digits+0x128>
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	0a8080e7          	jalr	168(ra) # 80000548 <panic>
	  panic("uvmunmap: not mapped");
    800014a8:	00007517          	auipc	a0,0x7
    800014ac:	cc050513          	addi	a0,a0,-832 # 80008168 <digits+0x138>
    800014b0:	fffff097          	auipc	ra,0xfffff
    800014b4:	098080e7          	jalr	152(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800014b8:	00007517          	auipc	a0,0x7
    800014bc:	cc850513          	addi	a0,a0,-824 # 80008180 <digits+0x150>
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	088080e7          	jalr	136(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800014c8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014ca:	0532                	slli	a0,a0,0xc
    800014cc:	fffff097          	auipc	ra,0xfffff
    800014d0:	558080e7          	jalr	1368(ra) # 80000a24 <kfree>
    *pte = 0;
    800014d4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014d8:	995a                	add	s2,s2,s6
    800014da:	f9397ce3          	bgeu	s2,s3,80001472 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014de:	4601                	li	a2,0
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8552                	mv	a0,s4
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	c4a080e7          	jalr	-950(ra) # 8000112e <walk>
    800014ec:	84aa                	mv	s1,a0
    800014ee:	d54d                	beqz	a0,80001498 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0){
    800014f0:	6108                	ld	a0,0(a0)
    800014f2:	00157793          	andi	a5,a0,1
    800014f6:	dbcd                	beqz	a5,800014a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014f8:	3ff57793          	andi	a5,a0,1023
    800014fc:	fb778ee3          	beq	a5,s7,800014b8 <uvmunmap+0x76>
    if(do_free){
    80001500:	fc0a8ae3          	beqz	s5,800014d4 <uvmunmap+0x92>
    80001504:	b7d1                	j	800014c8 <uvmunmap+0x86>

0000000080001506 <uvmcreate>:
{
    80001506:	1101                	addi	sp,sp,-32
    80001508:	ec06                	sd	ra,24(sp)
    8000150a:	e822                	sd	s0,16(sp)
    8000150c:	e426                	sd	s1,8(sp)
    8000150e:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	610080e7          	jalr	1552(ra) # 80000b20 <kalloc>
    80001518:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000151a:	c519                	beqz	a0,80001528 <uvmcreate+0x22>
  memset(pagetable, 0, PGSIZE);
    8000151c:	6605                	lui	a2,0x1
    8000151e:	4581                	li	a1,0
    80001520:	fffff097          	auipc	ra,0xfffff
    80001524:	7ec080e7          	jalr	2028(ra) # 80000d0c <memset>
}
    80001528:	8526                	mv	a0,s1
    8000152a:	60e2                	ld	ra,24(sp)
    8000152c:	6442                	ld	s0,16(sp)
    8000152e:	64a2                	ld	s1,8(sp)
    80001530:	6105                	addi	sp,sp,32
    80001532:	8082                	ret

0000000080001534 <uvminit>:
{
    80001534:	7179                	addi	sp,sp,-48
    80001536:	f406                	sd	ra,40(sp)
    80001538:	f022                	sd	s0,32(sp)
    8000153a:	ec26                	sd	s1,24(sp)
    8000153c:	e84a                	sd	s2,16(sp)
    8000153e:	e44e                	sd	s3,8(sp)
    80001540:	e052                	sd	s4,0(sp)
    80001542:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    80001544:	6785                	lui	a5,0x1
    80001546:	04f67863          	bgeu	a2,a5,80001596 <uvminit+0x62>
    8000154a:	8a2a                	mv	s4,a0
    8000154c:	89ae                	mv	s3,a1
    8000154e:	84b2                	mv	s1,a2
  mem = kalloc();
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	5d0080e7          	jalr	1488(ra) # 80000b20 <kalloc>
    80001558:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000155a:	6605                	lui	a2,0x1
    8000155c:	4581                	li	a1,0
    8000155e:	fffff097          	auipc	ra,0xfffff
    80001562:	7ae080e7          	jalr	1966(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001566:	4779                	li	a4,30
    80001568:	86ca                	mv	a3,s2
    8000156a:	6605                	lui	a2,0x1
    8000156c:	4581                	li	a1,0
    8000156e:	8552                	mv	a0,s4
    80001570:	00000097          	auipc	ra,0x0
    80001574:	d0c080e7          	jalr	-756(ra) # 8000127c <mappages>
  memmove(mem, src, sz);
    80001578:	8626                	mv	a2,s1
    8000157a:	85ce                	mv	a1,s3
    8000157c:	854a                	mv	a0,s2
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	7ee080e7          	jalr	2030(ra) # 80000d6c <memmove>
}
    80001586:	70a2                	ld	ra,40(sp)
    80001588:	7402                	ld	s0,32(sp)
    8000158a:	64e2                	ld	s1,24(sp)
    8000158c:	6942                	ld	s2,16(sp)
    8000158e:	69a2                	ld	s3,8(sp)
    80001590:	6a02                	ld	s4,0(sp)
    80001592:	6145                	addi	sp,sp,48
    80001594:	8082                	ret
    panic("inituvm: more than a page");
    80001596:	00007517          	auipc	a0,0x7
    8000159a:	c0250513          	addi	a0,a0,-1022 # 80008198 <digits+0x168>
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	faa080e7          	jalr	-86(ra) # 80000548 <panic>

00000000800015a6 <uvmdealloc>:
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    return oldsz;
    800015b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015b2:	00b67d63          	bgeu	a2,a1,800015cc <uvmdealloc+0x26>
    800015b6:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015b8:	6785                	lui	a5,0x1
    800015ba:	17fd                	addi	a5,a5,-1
    800015bc:	00f60733          	add	a4,a2,a5
    800015c0:	767d                	lui	a2,0xfffff
    800015c2:	8f71                	and	a4,a4,a2
    800015c4:	97ae                	add	a5,a5,a1
    800015c6:	8ff1                	and	a5,a5,a2
    800015c8:	00f76863          	bltu	a4,a5,800015d8 <uvmdealloc+0x32>
}
    800015cc:	8526                	mv	a0,s1
    800015ce:	60e2                	ld	ra,24(sp)
    800015d0:	6442                	ld	s0,16(sp)
    800015d2:	64a2                	ld	s1,8(sp)
    800015d4:	6105                	addi	sp,sp,32
    800015d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015d8:	8f99                	sub	a5,a5,a4
    800015da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015dc:	4685                	li	a3,1
    800015de:	0007861b          	sext.w	a2,a5
    800015e2:	85ba                	mv	a1,a4
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	e5e080e7          	jalr	-418(ra) # 80001442 <uvmunmap>
    800015ec:	b7c5                	j	800015cc <uvmdealloc+0x26>

00000000800015ee <uvmalloc>:
  if(newsz < oldsz)
    800015ee:	0ab66163          	bltu	a2,a1,80001690 <uvmalloc+0xa2>
{
    800015f2:	7139                	addi	sp,sp,-64
    800015f4:	fc06                	sd	ra,56(sp)
    800015f6:	f822                	sd	s0,48(sp)
    800015f8:	f426                	sd	s1,40(sp)
    800015fa:	f04a                	sd	s2,32(sp)
    800015fc:	ec4e                	sd	s3,24(sp)
    800015fe:	e852                	sd	s4,16(sp)
    80001600:	e456                	sd	s5,8(sp)
    80001602:	0080                	addi	s0,sp,64
    80001604:	8aaa                	mv	s5,a0
    80001606:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001608:	6985                	lui	s3,0x1
    8000160a:	19fd                	addi	s3,s3,-1
    8000160c:	95ce                	add	a1,a1,s3
    8000160e:	79fd                	lui	s3,0xfffff
    80001610:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001614:	08c9f063          	bgeu	s3,a2,80001694 <uvmalloc+0xa6>
    80001618:	894e                	mv	s2,s3
    mem = kalloc();
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	506080e7          	jalr	1286(ra) # 80000b20 <kalloc>
    80001622:	84aa                	mv	s1,a0
    if(mem == 0){
    80001624:	c51d                	beqz	a0,80001652 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001626:	6605                	lui	a2,0x1
    80001628:	4581                	li	a1,0
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	6e2080e7          	jalr	1762(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001632:	4779                	li	a4,30
    80001634:	86a6                	mv	a3,s1
    80001636:	6605                	lui	a2,0x1
    80001638:	85ca                	mv	a1,s2
    8000163a:	8556                	mv	a0,s5
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	c40080e7          	jalr	-960(ra) # 8000127c <mappages>
    80001644:	e905                	bnez	a0,80001674 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001646:	6785                	lui	a5,0x1
    80001648:	993e                	add	s2,s2,a5
    8000164a:	fd4968e3          	bltu	s2,s4,8000161a <uvmalloc+0x2c>
  return newsz;
    8000164e:	8552                	mv	a0,s4
    80001650:	a809                	j	80001662 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001652:	864e                	mv	a2,s3
    80001654:	85ca                	mv	a1,s2
    80001656:	8556                	mv	a0,s5
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	f4e080e7          	jalr	-178(ra) # 800015a6 <uvmdealloc>
      return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	70e2                	ld	ra,56(sp)
    80001664:	7442                	ld	s0,48(sp)
    80001666:	74a2                	ld	s1,40(sp)
    80001668:	7902                	ld	s2,32(sp)
    8000166a:	69e2                	ld	s3,24(sp)
    8000166c:	6a42                	ld	s4,16(sp)
    8000166e:	6aa2                	ld	s5,8(sp)
    80001670:	6121                	addi	sp,sp,64
    80001672:	8082                	ret
      kfree(mem);
    80001674:	8526                	mv	a0,s1
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	3ae080e7          	jalr	942(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000167e:	864e                	mv	a2,s3
    80001680:	85ca                	mv	a1,s2
    80001682:	8556                	mv	a0,s5
    80001684:	00000097          	auipc	ra,0x0
    80001688:	f22080e7          	jalr	-222(ra) # 800015a6 <uvmdealloc>
      return 0;
    8000168c:	4501                	li	a0,0
    8000168e:	bfd1                	j	80001662 <uvmalloc+0x74>
    return oldsz;
    80001690:	852e                	mv	a0,a1
}
    80001692:	8082                	ret
  return newsz;
    80001694:	8532                	mv	a0,a2
    80001696:	b7f1                	j	80001662 <uvmalloc+0x74>

0000000080001698 <freewalk>:
{
    80001698:	7179                	addi	sp,sp,-48
    8000169a:	f406                	sd	ra,40(sp)
    8000169c:	f022                	sd	s0,32(sp)
    8000169e:	ec26                	sd	s1,24(sp)
    800016a0:	e84a                	sd	s2,16(sp)
    800016a2:	e44e                	sd	s3,8(sp)
    800016a4:	e052                	sd	s4,0(sp)
    800016a6:	1800                	addi	s0,sp,48
    800016a8:	8a2a                	mv	s4,a0
  for(int i = 0; i < 512; i++){
    800016aa:	84aa                	mv	s1,a0
    800016ac:	6905                	lui	s2,0x1
    800016ae:	992a                	add	s2,s2,a0
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016b0:	4985                	li	s3,1
    800016b2:	a821                	j	800016ca <freewalk+0x32>
      uint64 child = PTE2PA(pte);
    800016b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016b6:	0532                	slli	a0,a0,0xc
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	fe0080e7          	jalr	-32(ra) # 80001698 <freewalk>
      pagetable[i] = 0;
    800016c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016c4:	04a1                	addi	s1,s1,8
    800016c6:	03248163          	beq	s1,s2,800016e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016cc:	00f57793          	andi	a5,a0,15
    800016d0:	ff3782e3          	beq	a5,s3,800016b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016d4:	8905                	andi	a0,a0,1
    800016d6:	d57d                	beqz	a0,800016c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016d8:	00007517          	auipc	a0,0x7
    800016dc:	ae050513          	addi	a0,a0,-1312 # 800081b8 <digits+0x188>
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	e68080e7          	jalr	-408(ra) # 80000548 <panic>
  kfree((void*)pagetable);
    800016e8:	8552                	mv	a0,s4
    800016ea:	fffff097          	auipc	ra,0xfffff
    800016ee:	33a080e7          	jalr	826(ra) # 80000a24 <kfree>
}
    800016f2:	70a2                	ld	ra,40(sp)
    800016f4:	7402                	ld	s0,32(sp)
    800016f6:	64e2                	ld	s1,24(sp)
    800016f8:	6942                	ld	s2,16(sp)
    800016fa:	69a2                	ld	s3,8(sp)
    800016fc:	6a02                	ld	s4,0(sp)
    800016fe:	6145                	addi	sp,sp,48
    80001700:	8082                	ret

0000000080001702 <uvmfree2>:
{
    80001702:	1101                	addi	sp,sp,-32
    80001704:	ec06                	sd	ra,24(sp)
    80001706:	e822                	sd	s0,16(sp)
    80001708:	e426                	sd	s1,8(sp)
    8000170a:	1000                	addi	s0,sp,32
    8000170c:	84aa                	mv	s1,a0
  if(npages > 0)
    8000170e:	ea19                	bnez	a2,80001724 <uvmfree2+0x22>
  freewalk(pagetable);
    80001710:	8526                	mv	a0,s1
    80001712:	00000097          	auipc	ra,0x0
    80001716:	f86080e7          	jalr	-122(ra) # 80001698 <freewalk>
}
    8000171a:	60e2                	ld	ra,24(sp)
    8000171c:	6442                	ld	s0,16(sp)
    8000171e:	64a2                	ld	s1,8(sp)
    80001720:	6105                	addi	sp,sp,32
    80001722:	8082                	ret
    uvmunmap(pagetable, va, npages, 1);
    80001724:	4685                	li	a3,1
    80001726:	1602                	slli	a2,a2,0x20
    80001728:	9201                	srli	a2,a2,0x20
    8000172a:	00000097          	auipc	ra,0x0
    8000172e:	d18080e7          	jalr	-744(ra) # 80001442 <uvmunmap>
    80001732:	bff9                	j	80001710 <uvmfree2+0xe>

0000000080001734 <uvmfree>:
{
    80001734:	1101                	addi	sp,sp,-32
    80001736:	ec06                	sd	ra,24(sp)
    80001738:	e822                	sd	s0,16(sp)
    8000173a:	e426                	sd	s1,8(sp)
    8000173c:	1000                	addi	s0,sp,32
    8000173e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001740:	e999                	bnez	a1,80001756 <uvmfree+0x22>
  freewalk(pagetable);
    80001742:	8526                	mv	a0,s1
    80001744:	00000097          	auipc	ra,0x0
    80001748:	f54080e7          	jalr	-172(ra) # 80001698 <freewalk>
}
    8000174c:	60e2                	ld	ra,24(sp)
    8000174e:	6442                	ld	s0,16(sp)
    80001750:	64a2                	ld	s1,8(sp)
    80001752:	6105                	addi	sp,sp,32
    80001754:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001756:	6605                	lui	a2,0x1
    80001758:	167d                	addi	a2,a2,-1
    8000175a:	962e                	add	a2,a2,a1
    8000175c:	4685                	li	a3,1
    8000175e:	8231                	srli	a2,a2,0xc
    80001760:	4581                	li	a1,0
    80001762:	00000097          	auipc	ra,0x0
    80001766:	ce0080e7          	jalr	-800(ra) # 80001442 <uvmunmap>
    8000176a:	bfe1                	j	80001742 <uvmfree+0xe>

000000008000176c <uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){
    8000176c:	c679                	beqz	a2,8000183a <uvmcopy+0xce>
{
    8000176e:	715d                	addi	sp,sp,-80
    80001770:	e486                	sd	ra,72(sp)
    80001772:	e0a2                	sd	s0,64(sp)
    80001774:	fc26                	sd	s1,56(sp)
    80001776:	f84a                	sd	s2,48(sp)
    80001778:	f44e                	sd	s3,40(sp)
    8000177a:	f052                	sd	s4,32(sp)
    8000177c:	ec56                	sd	s5,24(sp)
    8000177e:	e85a                	sd	s6,16(sp)
    80001780:	e45e                	sd	s7,8(sp)
    80001782:	0880                	addi	s0,sp,80
    80001784:	8b2a                	mv	s6,a0
    80001786:	8aae                	mv	s5,a1
    80001788:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000178a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000178c:	4601                	li	a2,0
    8000178e:	85ce                	mv	a1,s3
    80001790:	855a                	mv	a0,s6
    80001792:	00000097          	auipc	ra,0x0
    80001796:	99c080e7          	jalr	-1636(ra) # 8000112e <walk>
    8000179a:	c531                	beqz	a0,800017e6 <uvmcopy+0x7a>
    if((*pte & PTE_V) == 0)
    8000179c:	6118                	ld	a4,0(a0)
    8000179e:	00177793          	andi	a5,a4,1
    800017a2:	cbb1                	beqz	a5,800017f6 <uvmcopy+0x8a>
    pa = PTE2PA(*pte);
    800017a4:	00a75593          	srli	a1,a4,0xa
    800017a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017b0:	fffff097          	auipc	ra,0xfffff
    800017b4:	370080e7          	jalr	880(ra) # 80000b20 <kalloc>
    800017b8:	892a                	mv	s2,a0
    800017ba:	c939                	beqz	a0,80001810 <uvmcopy+0xa4>
    memmove(mem, (char*)pa, PGSIZE);
    800017bc:	6605                	lui	a2,0x1
    800017be:	85de                	mv	a1,s7
    800017c0:	fffff097          	auipc	ra,0xfffff
    800017c4:	5ac080e7          	jalr	1452(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800017c8:	8726                	mv	a4,s1
    800017ca:	86ca                	mv	a3,s2
    800017cc:	6605                	lui	a2,0x1
    800017ce:	85ce                	mv	a1,s3
    800017d0:	8556                	mv	a0,s5
    800017d2:	00000097          	auipc	ra,0x0
    800017d6:	aaa080e7          	jalr	-1366(ra) # 8000127c <mappages>
    800017da:	e515                	bnez	a0,80001806 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800017dc:	6785                	lui	a5,0x1
    800017de:	99be                	add	s3,s3,a5
    800017e0:	fb49e6e3          	bltu	s3,s4,8000178c <uvmcopy+0x20>
    800017e4:	a081                	j	80001824 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800017e6:	00007517          	auipc	a0,0x7
    800017ea:	9e250513          	addi	a0,a0,-1566 # 800081c8 <digits+0x198>
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	d5a080e7          	jalr	-678(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800017f6:	00007517          	auipc	a0,0x7
    800017fa:	9f250513          	addi	a0,a0,-1550 # 800081e8 <digits+0x1b8>
    800017fe:	fffff097          	auipc	ra,0xfffff
    80001802:	d4a080e7          	jalr	-694(ra) # 80000548 <panic>
      kfree(mem);
    80001806:	854a                	mv	a0,s2
    80001808:	fffff097          	auipc	ra,0xfffff
    8000180c:	21c080e7          	jalr	540(ra) # 80000a24 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001810:	4685                	li	a3,1
    80001812:	00c9d613          	srli	a2,s3,0xc
    80001816:	4581                	li	a1,0
    80001818:	8556                	mv	a0,s5
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	c28080e7          	jalr	-984(ra) # 80001442 <uvmunmap>
  return -1;
    80001822:	557d                	li	a0,-1
}
    80001824:	60a6                	ld	ra,72(sp)
    80001826:	6406                	ld	s0,64(sp)
    80001828:	74e2                	ld	s1,56(sp)
    8000182a:	7942                	ld	s2,48(sp)
    8000182c:	79a2                	ld	s3,40(sp)
    8000182e:	7a02                	ld	s4,32(sp)
    80001830:	6ae2                	ld	s5,24(sp)
    80001832:	6b42                	ld	s6,16(sp)
    80001834:	6ba2                	ld	s7,8(sp)
    80001836:	6161                	addi	sp,sp,80
    80001838:	8082                	ret
  return 0;
    8000183a:	4501                	li	a0,0
}
    8000183c:	8082                	ret

000000008000183e <uvmclear>:
{
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001846:	4601                	li	a2,0
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	8e6080e7          	jalr	-1818(ra) # 8000112e <walk>
  if(pte == 0)
    80001850:	c901                	beqz	a0,80001860 <uvmclear+0x22>
  *pte &= ~PTE_U;
    80001852:	611c                	ld	a5,0(a0)
    80001854:	9bbd                	andi	a5,a5,-17
    80001856:	e11c                	sd	a5,0(a0)
}
    80001858:	60a2                	ld	ra,8(sp)
    8000185a:	6402                	ld	s0,0(sp)
    8000185c:	0141                	addi	sp,sp,16
    8000185e:	8082                	ret
    panic("uvmclear");
    80001860:	00007517          	auipc	a0,0x7
    80001864:	9a850513          	addi	a0,a0,-1624 # 80008208 <digits+0x1d8>
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	ce0080e7          	jalr	-800(ra) # 80000548 <panic>

0000000080001870 <copyout>:
  while(len > 0){
    80001870:	c6bd                	beqz	a3,800018de <copyout+0x6e>
{
    80001872:	715d                	addi	sp,sp,-80
    80001874:	e486                	sd	ra,72(sp)
    80001876:	e0a2                	sd	s0,64(sp)
    80001878:	fc26                	sd	s1,56(sp)
    8000187a:	f84a                	sd	s2,48(sp)
    8000187c:	f44e                	sd	s3,40(sp)
    8000187e:	f052                	sd	s4,32(sp)
    80001880:	ec56                	sd	s5,24(sp)
    80001882:	e85a                	sd	s6,16(sp)
    80001884:	e45e                	sd	s7,8(sp)
    80001886:	e062                	sd	s8,0(sp)
    80001888:	0880                	addi	s0,sp,80
    8000188a:	8b2a                	mv	s6,a0
    8000188c:	8c2e                	mv	s8,a1
    8000188e:	8a32                	mv	s4,a2
    80001890:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001892:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (dstva - va0);
    80001894:	6a85                	lui	s5,0x1
    80001896:	a015                	j	800018ba <copyout+0x4a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001898:	9562                	add	a0,a0,s8
    8000189a:	0004861b          	sext.w	a2,s1
    8000189e:	85d2                	mv	a1,s4
    800018a0:	41250533          	sub	a0,a0,s2
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	4c8080e7          	jalr	1224(ra) # 80000d6c <memmove>
    len -= n;
    800018ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800018b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800018b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018b6:	02098263          	beqz	s3,800018da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800018ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018be:	85ca                	mv	a1,s2
    800018c0:	855a                	mv	a0,s6
    800018c2:	00000097          	auipc	ra,0x0
    800018c6:	912080e7          	jalr	-1774(ra) # 800011d4 <walkaddr>
    if(pa0 == 0)
    800018ca:	cd01                	beqz	a0,800018e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800018cc:	418904b3          	sub	s1,s2,s8
    800018d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800018d2:	fc99f3e3          	bgeu	s3,s1,80001898 <copyout+0x28>
    800018d6:	84ce                	mv	s1,s3
    800018d8:	b7c1                	j	80001898 <copyout+0x28>
  return 0;
    800018da:	4501                	li	a0,0
    800018dc:	a021                	j	800018e4 <copyout+0x74>
    800018de:	4501                	li	a0,0
}
    800018e0:	8082                	ret
      return -1;
    800018e2:	557d                	li	a0,-1
}
    800018e4:	60a6                	ld	ra,72(sp)
    800018e6:	6406                	ld	s0,64(sp)
    800018e8:	74e2                	ld	s1,56(sp)
    800018ea:	7942                	ld	s2,48(sp)
    800018ec:	79a2                	ld	s3,40(sp)
    800018ee:	7a02                	ld	s4,32(sp)
    800018f0:	6ae2                	ld	s5,24(sp)
    800018f2:	6b42                	ld	s6,16(sp)
    800018f4:	6ba2                	ld	s7,8(sp)
    800018f6:	6c02                	ld	s8,0(sp)
    800018f8:	6161                	addi	sp,sp,80
    800018fa:	8082                	ret

00000000800018fc <copyin>:
{
    800018fc:	1141                	addi	sp,sp,-16
    800018fe:	e406                	sd	ra,8(sp)
    80001900:	e022                	sd	s0,0(sp)
    80001902:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    80001904:	00005097          	auipc	ra,0x5
    80001908:	bfc080e7          	jalr	-1028(ra) # 80006500 <copyin_new>
}
    8000190c:	60a2                	ld	ra,8(sp)
    8000190e:	6402                	ld	s0,0(sp)
    80001910:	0141                	addi	sp,sp,16
    80001912:	8082                	ret

0000000080001914 <copyinstr>:
{
    80001914:	1141                	addi	sp,sp,-16
    80001916:	e406                	sd	ra,8(sp)
    80001918:	e022                	sd	s0,0(sp)
    8000191a:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    8000191c:	00005097          	auipc	ra,0x5
    80001920:	c4c080e7          	jalr	-948(ra) # 80006568 <copyinstr_new>
}
    80001924:	60a2                	ld	ra,8(sp)
    80001926:	6402                	ld	s0,0(sp)
    80001928:	0141                	addi	sp,sp,16
    8000192a:	8082                	ret

000000008000192c <vmprint>:

void
vmprint(pagetable_t pagetable){
    8000192c:	1101                	addi	sp,sp,-32
    8000192e:	ec06                	sd	ra,24(sp)
    80001930:	e822                	sd	s0,16(sp)
    80001932:	e426                	sd	s1,8(sp)
    80001934:	1000                	addi	s0,sp,32
    80001936:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001938:	85aa                	mv	a1,a0
    8000193a:	00007517          	auipc	a0,0x7
    8000193e:	8de50513          	addi	a0,a0,-1826 # 80008218 <digits+0x1e8>
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	c50080e7          	jalr	-944(ra) # 80000592 <printf>
  traversal_pt(pagetable, 0);
    8000194a:	4581                	li	a1,0
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	68e080e7          	jalr	1678(ra) # 80000fdc <traversal_pt>
    80001956:	60e2                	ld	ra,24(sp)
    80001958:	6442                	ld	s0,16(sp)
    8000195a:	64a2                	ld	s1,8(sp)
    8000195c:	6105                	addi	sp,sp,32
    8000195e:	8082                	ret

0000000080001960 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001960:	1101                	addi	sp,sp,-32
    80001962:	ec06                	sd	ra,24(sp)
    80001964:	e822                	sd	s0,16(sp)
    80001966:	e426                	sd	s1,8(sp)
    80001968:	1000                	addi	s0,sp,32
    8000196a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	22a080e7          	jalr	554(ra) # 80000b96 <holding>
    80001974:	c909                	beqz	a0,80001986 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001976:	749c                	ld	a5,40(s1)
    80001978:	00978f63          	beq	a5,s1,80001996 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000197c:	60e2                	ld	ra,24(sp)
    8000197e:	6442                	ld	s0,16(sp)
    80001980:	64a2                	ld	s1,8(sp)
    80001982:	6105                	addi	sp,sp,32
    80001984:	8082                	ret
    panic("wakeup1");
    80001986:	00007517          	auipc	a0,0x7
    8000198a:	8a250513          	addi	a0,a0,-1886 # 80008228 <digits+0x1f8>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	bba080e7          	jalr	-1094(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001996:	4c98                	lw	a4,24(s1)
    80001998:	4785                	li	a5,1
    8000199a:	fef711e3          	bne	a4,a5,8000197c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000199e:	4789                	li	a5,2
    800019a0:	cc9c                	sw	a5,24(s1)
}
    800019a2:	bfe9                	j	8000197c <wakeup1+0x1c>

00000000800019a4 <procinit>:
{
    800019a4:	7179                	addi	sp,sp,-48
    800019a6:	f406                	sd	ra,40(sp)
    800019a8:	f022                	sd	s0,32(sp)
    800019aa:	ec26                	sd	s1,24(sp)
    800019ac:	e84a                	sd	s2,16(sp)
    800019ae:	e44e                	sd	s3,8(sp)
    800019b0:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    800019b2:	00007597          	auipc	a1,0x7
    800019b6:	87e58593          	addi	a1,a1,-1922 # 80008230 <digits+0x200>
    800019ba:	00010517          	auipc	a0,0x10
    800019be:	f9650513          	addi	a0,a0,-106 # 80011950 <pid_lock>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1be080e7          	jalr	446(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ca:	00010497          	auipc	s1,0x10
    800019ce:	39e48493          	addi	s1,s1,926 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019d2:	00007997          	auipc	s3,0x7
    800019d6:	86698993          	addi	s3,s3,-1946 # 80008238 <digits+0x208>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019da:	00016917          	auipc	s2,0x16
    800019de:	f8e90913          	addi	s2,s2,-114 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    800019e2:	85ce                	mv	a1,s3
    800019e4:	8526                	mv	a0,s1
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	19a080e7          	jalr	410(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ee:	17048493          	addi	s1,s1,368
    800019f2:	ff2498e3          	bne	s1,s2,800019e2 <procinit+0x3e>
}
    800019f6:	70a2                	ld	ra,40(sp)
    800019f8:	7402                	ld	s0,32(sp)
    800019fa:	64e2                	ld	s1,24(sp)
    800019fc:	6942                	ld	s2,16(sp)
    800019fe:	69a2                	ld	s3,8(sp)
    80001a00:	6145                	addi	sp,sp,48
    80001a02:	8082                	ret

0000000080001a04 <cpuid>:
{
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e422                	sd	s0,8(sp)
    80001a08:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0a:	8512                	mv	a0,tp
}
    80001a0c:	2501                	sext.w	a0,a0
    80001a0e:	6422                	ld	s0,8(sp)
    80001a10:	0141                	addi	sp,sp,16
    80001a12:	8082                	ret

0000000080001a14 <mycpu>:
mycpu(void) {
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e422                	sd	s0,8(sp)
    80001a18:	0800                	addi	s0,sp,16
    80001a1a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a1c:	2781                	sext.w	a5,a5
    80001a1e:	079e                	slli	a5,a5,0x7
}
    80001a20:	00010517          	auipc	a0,0x10
    80001a24:	f4850513          	addi	a0,a0,-184 # 80011968 <cpus>
    80001a28:	953e                	add	a0,a0,a5
    80001a2a:	6422                	ld	s0,8(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret

0000000080001a30 <myproc>:
myproc(void) {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	1000                	addi	s0,sp,32
  push_off();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	18a080e7          	jalr	394(ra) # 80000bc4 <push_off>
    80001a42:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a44:	2781                	sext.w	a5,a5
    80001a46:	079e                	slli	a5,a5,0x7
    80001a48:	00010717          	auipc	a4,0x10
    80001a4c:	f0870713          	addi	a4,a4,-248 # 80011950 <pid_lock>
    80001a50:	97ba                	add	a5,a5,a4
    80001a52:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	210080e7          	jalr	528(ra) # 80000c64 <pop_off>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <forkret>:
{
    80001a68:	1141                	addi	sp,sp,-16
    80001a6a:	e406                	sd	ra,8(sp)
    80001a6c:	e022                	sd	s0,0(sp)
    80001a6e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	fc0080e7          	jalr	-64(ra) # 80001a30 <myproc>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	24c080e7          	jalr	588(ra) # 80000cc4 <release>
  if (first) {
    80001a80:	00007797          	auipc	a5,0x7
    80001a84:	e307a783          	lw	a5,-464(a5) # 800088b0 <first.1712>
    80001a88:	eb89                	bnez	a5,80001a9a <forkret+0x32>
  usertrapret();
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	dce080e7          	jalr	-562(ra) # 80002858 <usertrapret>
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    first = 0;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	e007ab23          	sw	zero,-490(a5) # 800088b0 <first.1712>
    fsinit(ROOTDEV);
    80001aa2:	4505                	li	a0,1
    80001aa4:	00002097          	auipc	ra,0x2
    80001aa8:	ba0080e7          	jalr	-1120(ra) # 80003644 <fsinit>
    80001aac:	bff9                	j	80001a8a <forkret+0x22>

0000000080001aae <allocpid>:
allocpid() {
    80001aae:	1101                	addi	sp,sp,-32
    80001ab0:	ec06                	sd	ra,24(sp)
    80001ab2:	e822                	sd	s0,16(sp)
    80001ab4:	e426                	sd	s1,8(sp)
    80001ab6:	e04a                	sd	s2,0(sp)
    80001ab8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aba:	00010917          	auipc	s2,0x10
    80001abe:	e9690913          	addi	s2,s2,-362 # 80011950 <pid_lock>
    80001ac2:	854a                	mv	a0,s2
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	14c080e7          	jalr	332(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001acc:	00007797          	auipc	a5,0x7
    80001ad0:	de878793          	addi	a5,a5,-536 # 800088b4 <nextpid>
    80001ad4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad6:	0014871b          	addiw	a4,s1,1
    80001ada:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	1e6080e7          	jalr	486(ra) # 80000cc4 <release>
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret

0000000080001af4 <proc_pagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	a04080e7          	jalr	-1532(ra) # 80001506 <uvmcreate>
    80001b0a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b0c:	c121                	beqz	a0,80001b4c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0e:	4729                	li	a4,10
    80001b10:	00005697          	auipc	a3,0x5
    80001b14:	4f068693          	addi	a3,a3,1264 # 80007000 <_trampoline>
    80001b18:	6605                	lui	a2,0x1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	75a080e7          	jalr	1882(ra) # 8000127c <mappages>
    80001b2a:	02054863          	bltz	a0,80001b5a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2e:	4719                	li	a4,6
    80001b30:	06093683          	ld	a3,96(s2)
    80001b34:	6605                	lui	a2,0x1
    80001b36:	020005b7          	lui	a1,0x2000
    80001b3a:	15fd                	addi	a1,a1,-1
    80001b3c:	05b6                	slli	a1,a1,0xd
    80001b3e:	8526                	mv	a0,s1
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	73c080e7          	jalr	1852(ra) # 8000127c <mappages>
    80001b48:	02054163          	bltz	a0,80001b6a <proc_pagetable+0x76>
}
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	60e2                	ld	ra,24(sp)
    80001b50:	6442                	ld	s0,16(sp)
    80001b52:	64a2                	ld	s1,8(sp)
    80001b54:	6902                	ld	s2,0(sp)
    80001b56:	6105                	addi	sp,sp,32
    80001b58:	8082                	ret
    uvmfree(pagetable, 0);
    80001b5a:	4581                	li	a1,0
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	bd6080e7          	jalr	-1066(ra) # 80001734 <uvmfree>
    return 0;
    80001b66:	4481                	li	s1,0
    80001b68:	b7d5                	j	80001b4c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6a:	4681                	li	a3,0
    80001b6c:	4605                	li	a2,1
    80001b6e:	040005b7          	lui	a1,0x4000
    80001b72:	15fd                	addi	a1,a1,-1
    80001b74:	05b2                	slli	a1,a1,0xc
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	8ca080e7          	jalr	-1846(ra) # 80001442 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b80:	4581                	li	a1,0
    80001b82:	8526                	mv	a0,s1
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	bb0080e7          	jalr	-1104(ra) # 80001734 <uvmfree>
    return 0;
    80001b8c:	4481                	li	s1,0
    80001b8e:	bf7d                	j	80001b4c <proc_pagetable+0x58>

0000000080001b90 <proc_free_kernel_pagetable>:
{
    80001b90:	7179                	addi	sp,sp,-48
    80001b92:	f406                	sd	ra,40(sp)
    80001b94:	f022                	sd	s0,32(sp)
    80001b96:	ec26                	sd	s1,24(sp)
    80001b98:	e84a                	sd	s2,16(sp)
    80001b9a:	e44e                	sd	s3,8(sp)
    80001b9c:	e052                	sd	s4,0(sp)
    80001b9e:	1800                	addi	s0,sp,48
    80001ba0:	89aa                	mv	s3,a0
    80001ba2:	84ae                	mv	s1,a1
    80001ba4:	8932                	mv	s2,a2
  uvmunmap(pagetable, UART0, 1, 0);
    80001ba6:	4681                	li	a3,0
    80001ba8:	4605                	li	a2,1
    80001baa:	100005b7          	lui	a1,0x10000
    80001bae:	8526                	mv	a0,s1
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	892080e7          	jalr	-1902(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, VIRTIO0, 1, 0);
    80001bb8:	4681                	li	a3,0
    80001bba:	4605                	li	a2,1
    80001bbc:	100015b7          	lui	a1,0x10001
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	880080e7          	jalr	-1920(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, PLIC, 0x400000/PGSIZE, 0);
    80001bca:	4681                	li	a3,0
    80001bcc:	40000613          	li	a2,1024
    80001bd0:	0c0005b7          	lui	a1,0xc000
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	86c080e7          	jalr	-1940(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, KERNBASE, ((uint64)etext-KERNBASE)/PGSIZE, 0);
    80001bde:	00006a17          	auipc	s4,0x6
    80001be2:	422a0a13          	addi	s4,s4,1058 # 80008000 <etext>
    80001be6:	4681                	li	a3,0
    80001be8:	80006617          	auipc	a2,0x80006
    80001bec:	41860613          	addi	a2,a2,1048 # 8000 <_entry-0x7fff8000>
    80001bf0:	8231                	srli	a2,a2,0xc
    80001bf2:	4585                	li	a1,1
    80001bf4:	05fe                	slli	a1,a1,0x1f
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	84a080e7          	jalr	-1974(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, (uint64)etext, (PHYSTOP-(uint64)etext)/PGSIZE, 0);
    80001c00:	4645                	li	a2,17
    80001c02:	066e                	slli	a2,a2,0x1b
    80001c04:	41460633          	sub	a2,a2,s4
    80001c08:	4681                	li	a3,0
    80001c0a:	8231                	srli	a2,a2,0xc
    80001c0c:	85d2                	mv	a1,s4
    80001c0e:	8526                	mv	a0,s1
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	832080e7          	jalr	-1998(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c18:	4681                	li	a3,0
    80001c1a:	4605                	li	a2,1
    80001c1c:	040005b7          	lui	a1,0x4000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b2                	slli	a1,a1,0xc
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	81c080e7          	jalr	-2020(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 0);
    80001c2e:	6605                	lui	a2,0x1
    80001c30:	167d                	addi	a2,a2,-1
    80001c32:	964a                	add	a2,a2,s2
    80001c34:	4681                	li	a3,0
    80001c36:	8231                	srli	a2,a2,0xc
    80001c38:	4581                	li	a1,0
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	806080e7          	jalr	-2042(ra) # 80001442 <uvmunmap>
  uvmfree2(pagetable, kstack, 1);
    80001c44:	4605                	li	a2,1
    80001c46:	85ce                	mv	a1,s3
    80001c48:	8526                	mv	a0,s1
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	ab8080e7          	jalr	-1352(ra) # 80001702 <uvmfree2>
}
    80001c52:	70a2                	ld	ra,40(sp)
    80001c54:	7402                	ld	s0,32(sp)
    80001c56:	64e2                	ld	s1,24(sp)
    80001c58:	6942                	ld	s2,16(sp)
    80001c5a:	69a2                	ld	s3,8(sp)
    80001c5c:	6a02                	ld	s4,0(sp)
    80001c5e:	6145                	addi	sp,sp,48
    80001c60:	8082                	ret

0000000080001c62 <proc_freepagetable>:
{
    80001c62:	1101                	addi	sp,sp,-32
    80001c64:	ec06                	sd	ra,24(sp)
    80001c66:	e822                	sd	s0,16(sp)
    80001c68:	e426                	sd	s1,8(sp)
    80001c6a:	e04a                	sd	s2,0(sp)
    80001c6c:	1000                	addi	s0,sp,32
    80001c6e:	84aa                	mv	s1,a0
    80001c70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c72:	4681                	li	a3,0
    80001c74:	4605                	li	a2,1
    80001c76:	040005b7          	lui	a1,0x4000
    80001c7a:	15fd                	addi	a1,a1,-1
    80001c7c:	05b2                	slli	a1,a1,0xc
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	7c4080e7          	jalr	1988(ra) # 80001442 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c86:	4681                	li	a3,0
    80001c88:	4605                	li	a2,1
    80001c8a:	020005b7          	lui	a1,0x2000
    80001c8e:	15fd                	addi	a1,a1,-1
    80001c90:	05b6                	slli	a1,a1,0xd
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	7ae080e7          	jalr	1966(ra) # 80001442 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c9c:	85ca                	mv	a1,s2
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	a94080e7          	jalr	-1388(ra) # 80001734 <uvmfree>
}
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret

0000000080001cb4 <freeproc>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
    80001cbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cc0:	7128                	ld	a0,96(a0)
    80001cc2:	c509                	beqz	a0,80001ccc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	d60080e7          	jalr	-672(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ccc:	0604b023          	sd	zero,96(s1)
  if(p->kernelPageTable)
    80001cd0:	6cac                	ld	a1,88(s1)
    80001cd2:	c599                	beqz	a1,80001ce0 <freeproc+0x2c>
    proc_free_kernel_pagetable(p->kstack, p->kernelPageTable, p->sz);
    80001cd4:	64b0                	ld	a2,72(s1)
    80001cd6:	60a8                	ld	a0,64(s1)
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	eb8080e7          	jalr	-328(ra) # 80001b90 <proc_free_kernel_pagetable>
  p->kernelPageTable = 0;
    80001ce0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ce4:	68a8                	ld	a0,80(s1)
    80001ce6:	c511                	beqz	a0,80001cf2 <freeproc+0x3e>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce8:	64ac                	ld	a1,72(s1)
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	f78080e7          	jalr	-136(ra) # 80001c62 <proc_freepagetable>
  p->pagetable = 0;
    80001cf2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cfa:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cfe:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d02:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001d06:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d0a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d0e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d12:	0004ac23          	sw	zero,24(s1)
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <allocproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2c:	00010497          	auipc	s1,0x10
    80001d30:	03c48493          	addi	s1,s1,60 # 80011d68 <proc>
    80001d34:	00016917          	auipc	s2,0x16
    80001d38:	c3490913          	addi	s2,s2,-972 # 80017968 <tickslock>
    acquire(&p->lock);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	ed2080e7          	jalr	-302(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001d46:	4c9c                	lw	a5,24(s1)
    80001d48:	cf81                	beqz	a5,80001d60 <allocproc+0x40>
      release(&p->lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	f78080e7          	jalr	-136(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d54:	17048493          	addi	s1,s1,368
    80001d58:	ff2492e3          	bne	s1,s2,80001d3c <allocproc+0x1c>
  return 0;
    80001d5c:	4481                	li	s1,0
    80001d5e:	a049                	j	80001de0 <allocproc+0xc0>
  p->pid = allocpid();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	d4e080e7          	jalr	-690(ra) # 80001aae <allocpid>
    80001d68:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	db6080e7          	jalr	-586(ra) # 80000b20 <kalloc>
    80001d72:	892a                	mv	s2,a0
    80001d74:	f0a8                	sd	a0,96(s1)
    80001d76:	cd25                	beqz	a0,80001dee <allocproc+0xce>
  p->kernelPageTable = kvmmake();
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	592080e7          	jalr	1426(ra) # 8000130a <kvmmake>
    80001d80:	eca8                	sd	a0,88(s1)
  char *pa = kalloc();
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	d9e080e7          	jalr	-610(ra) # 80000b20 <kalloc>
    80001d8a:	86aa                	mv	a3,a0
  if(pa == 0)
    80001d8c:	c925                	beqz	a0,80001dfc <allocproc+0xdc>
  mappages(p->kernelPageTable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W);
    80001d8e:	4719                	li	a4,6
    80001d90:	6605                	lui	a2,0x1
    80001d92:	04000937          	lui	s2,0x4000
    80001d96:	1975                	addi	s2,s2,-3
    80001d98:	00c91593          	slli	a1,s2,0xc
    80001d9c:	6ca8                	ld	a0,88(s1)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	4de080e7          	jalr	1246(ra) # 8000127c <mappages>
  p->kstack = va;
    80001da6:	0932                	slli	s2,s2,0xc
    80001da8:	0524b023          	sd	s2,64(s1)
  p->pagetable = proc_pagetable(p);
    80001dac:	8526                	mv	a0,s1
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	d46080e7          	jalr	-698(ra) # 80001af4 <proc_pagetable>
    80001db6:	892a                	mv	s2,a0
    80001db8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dba:	c929                	beqz	a0,80001e0c <allocproc+0xec>
  memset(&p->context, 0, sizeof(p->context));
    80001dbc:	07000613          	li	a2,112
    80001dc0:	4581                	li	a1,0
    80001dc2:	06848513          	addi	a0,s1,104
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	f46080e7          	jalr	-186(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001dce:	00000797          	auipc	a5,0x0
    80001dd2:	c9a78793          	addi	a5,a5,-870 # 80001a68 <forkret>
    80001dd6:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dd8:	60bc                	ld	a5,64(s1)
    80001dda:	6705                	lui	a4,0x1
    80001ddc:	97ba                	add	a5,a5,a4
    80001dde:	f8bc                	sd	a5,112(s1)
}
    80001de0:	8526                	mv	a0,s1
    80001de2:	60e2                	ld	ra,24(sp)
    80001de4:	6442                	ld	s0,16(sp)
    80001de6:	64a2                	ld	s1,8(sp)
    80001de8:	6902                	ld	s2,0(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret
    release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	ed4080e7          	jalr	-300(ra) # 80000cc4 <release>
    return 0;
    80001df8:	84ca                	mv	s1,s2
    80001dfa:	b7dd                	j	80001de0 <allocproc+0xc0>
    panic("kalloc");
    80001dfc:	00006517          	auipc	a0,0x6
    80001e00:	44450513          	addi	a0,a0,1092 # 80008240 <digits+0x210>
    80001e04:	ffffe097          	auipc	ra,0xffffe
    80001e08:	744080e7          	jalr	1860(ra) # 80000548 <panic>
    freeproc(p);
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	ea6080e7          	jalr	-346(ra) # 80001cb4 <freeproc>
    release(&p->lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	eac080e7          	jalr	-340(ra) # 80000cc4 <release>
    return 0;
    80001e20:	84ca                	mv	s1,s2
    80001e22:	bf7d                	j	80001de0 <allocproc+0xc0>

0000000080001e24 <userinit>:
{
    80001e24:	7179                	addi	sp,sp,-48
    80001e26:	f406                	sd	ra,40(sp)
    80001e28:	f022                	sd	s0,32(sp)
    80001e2a:	ec26                	sd	s1,24(sp)
    80001e2c:	e84a                	sd	s2,16(sp)
    80001e2e:	e44e                	sd	s3,8(sp)
    80001e30:	1800                	addi	s0,sp,48
  p = allocproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	eee080e7          	jalr	-274(ra) # 80001d20 <allocproc>
    80001e3a:	84aa                	mv	s1,a0
  initproc = p;
    80001e3c:	00007797          	auipc	a5,0x7
    80001e40:	1ca7be23          	sd	a0,476(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e44:	03400613          	li	a2,52
    80001e48:	00007597          	auipc	a1,0x7
    80001e4c:	a7858593          	addi	a1,a1,-1416 # 800088c0 <initcode>
    80001e50:	6928                	ld	a0,80(a0)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	6e2080e7          	jalr	1762(ra) # 80001534 <uvminit>
  p->sz = PGSIZE;
    80001e5a:	6985                	lui	s3,0x1
    80001e5c:	0534b423          	sd	s3,72(s1)
  pte = walk(p->pagetable, 0, 0);
    80001e60:	4601                	li	a2,0
    80001e62:	4581                	li	a1,0
    80001e64:	68a8                	ld	a0,80(s1)
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	2c8080e7          	jalr	712(ra) # 8000112e <walk>
    80001e6e:	892a                	mv	s2,a0
  kernelPte = walk(p->kernelPageTable, 0, 1);
    80001e70:	4605                	li	a2,1
    80001e72:	4581                	li	a1,0
    80001e74:	6ca8                	ld	a0,88(s1)
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	2b8080e7          	jalr	696(ra) # 8000112e <walk>
  *kernelPte = (*pte) & ~PTE_U;
    80001e7e:	00093783          	ld	a5,0(s2) # 4000000 <_entry-0x7c000000>
    80001e82:	9bbd                	andi	a5,a5,-17
    80001e84:	e11c                	sd	a5,0(a0)
  p->trapframe->epc = 0;      // user program counter
    80001e86:	70bc                	ld	a5,96(s1)
    80001e88:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e8c:	70bc                	ld	a5,96(s1)
    80001e8e:	0337b823          	sd	s3,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e92:	4641                	li	a2,16
    80001e94:	00006597          	auipc	a1,0x6
    80001e98:	3b458593          	addi	a1,a1,948 # 80008248 <digits+0x218>
    80001e9c:	16048513          	addi	a0,s1,352
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	fc2080e7          	jalr	-62(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001ea8:	00006517          	auipc	a0,0x6
    80001eac:	3b050513          	addi	a0,a0,944 # 80008258 <digits+0x228>
    80001eb0:	00002097          	auipc	ra,0x2
    80001eb4:	1bc080e7          	jalr	444(ra) # 8000406c <namei>
    80001eb8:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001ebc:	4789                	li	a5,2
    80001ebe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	e02080e7          	jalr	-510(ra) # 80000cc4 <release>
}
    80001eca:	70a2                	ld	ra,40(sp)
    80001ecc:	7402                	ld	s0,32(sp)
    80001ece:	64e2                	ld	s1,24(sp)
    80001ed0:	6942                	ld	s2,16(sp)
    80001ed2:	69a2                	ld	s3,8(sp)
    80001ed4:	6145                	addi	sp,sp,48
    80001ed6:	8082                	ret

0000000080001ed8 <growproc>:
{
    80001ed8:	1101                	addi	sp,sp,-32
    80001eda:	ec06                	sd	ra,24(sp)
    80001edc:	e822                	sd	s0,16(sp)
    80001ede:	e426                	sd	s1,8(sp)
    80001ee0:	e04a                	sd	s2,0(sp)
    80001ee2:	1000                	addi	s0,sp,32
    80001ee4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	b4a080e7          	jalr	-1206(ra) # 80001a30 <myproc>
    80001eee:	892a                	mv	s2,a0
  sz = p->sz;
    80001ef0:	652c                	ld	a1,72(a0)
    80001ef2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ef6:	00904f63          	bgtz	s1,80001f14 <growproc+0x3c>
  } else if(n < 0){
    80001efa:	0204cc63          	bltz	s1,80001f32 <growproc+0x5a>
  p->sz = sz;
    80001efe:	1602                	slli	a2,a2,0x20
    80001f00:	9201                	srli	a2,a2,0x20
    80001f02:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f06:	4501                	li	a0,0
}
    80001f08:	60e2                	ld	ra,24(sp)
    80001f0a:	6442                	ld	s0,16(sp)
    80001f0c:	64a2                	ld	s1,8(sp)
    80001f0e:	6902                	ld	s2,0(sp)
    80001f10:	6105                	addi	sp,sp,32
    80001f12:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f14:	9e25                	addw	a2,a2,s1
    80001f16:	1602                	slli	a2,a2,0x20
    80001f18:	9201                	srli	a2,a2,0x20
    80001f1a:	1582                	slli	a1,a1,0x20
    80001f1c:	9181                	srli	a1,a1,0x20
    80001f1e:	6928                	ld	a0,80(a0)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	6ce080e7          	jalr	1742(ra) # 800015ee <uvmalloc>
    80001f28:	0005061b          	sext.w	a2,a0
    80001f2c:	fa69                	bnez	a2,80001efe <growproc+0x26>
      return -1;
    80001f2e:	557d                	li	a0,-1
    80001f30:	bfe1                	j	80001f08 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f32:	9e25                	addw	a2,a2,s1
    80001f34:	1602                	slli	a2,a2,0x20
    80001f36:	9201                	srli	a2,a2,0x20
    80001f38:	1582                	slli	a1,a1,0x20
    80001f3a:	9181                	srli	a1,a1,0x20
    80001f3c:	6928                	ld	a0,80(a0)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	668080e7          	jalr	1640(ra) # 800015a6 <uvmdealloc>
    80001f46:	0005061b          	sext.w	a2,a0
    80001f4a:	bf55                	j	80001efe <growproc+0x26>

0000000080001f4c <fork>:
{
    80001f4c:	7139                	addi	sp,sp,-64
    80001f4e:	fc06                	sd	ra,56(sp)
    80001f50:	f822                	sd	s0,48(sp)
    80001f52:	f426                	sd	s1,40(sp)
    80001f54:	f04a                	sd	s2,32(sp)
    80001f56:	ec4e                	sd	s3,24(sp)
    80001f58:	e852                	sd	s4,16(sp)
    80001f5a:	e456                	sd	s5,8(sp)
    80001f5c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	ad2080e7          	jalr	-1326(ra) # 80001a30 <myproc>
    80001f66:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	db8080e7          	jalr	-584(ra) # 80001d20 <allocproc>
    80001f70:	12050163          	beqz	a0,80002092 <fork+0x146>
    80001f74:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f76:	0489b603          	ld	a2,72(s3) # 1048 <_entry-0x7fffefb8>
    80001f7a:	692c                	ld	a1,80(a0)
    80001f7c:	0509b503          	ld	a0,80(s3)
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	7ec080e7          	jalr	2028(ra) # 8000176c <uvmcopy>
    80001f88:	08054563          	bltz	a0,80002012 <fork+0xc6>
  for (j = 0; j < p->sz; j+=PGSIZE){
    80001f8c:	0489b783          	ld	a5,72(s3)
    80001f90:	4481                	li	s1,0
    80001f92:	6a85                	lui	s5,0x1
    80001f94:	cb9d                	beqz	a5,80001fca <fork+0x7e>
    pte = walk(np->pagetable, j, 0);
    80001f96:	4601                	li	a2,0
    80001f98:	85a6                	mv	a1,s1
    80001f9a:	05093503          	ld	a0,80(s2)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	190080e7          	jalr	400(ra) # 8000112e <walk>
    80001fa6:	8a2a                	mv	s4,a0
    kernelPte = walk(np->kernelPageTable, j, 1);
    80001fa8:	4605                	li	a2,1
    80001faa:	85a6                	mv	a1,s1
    80001fac:	05893503          	ld	a0,88(s2)
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	17e080e7          	jalr	382(ra) # 8000112e <walk>
    *kernelPte = (*pte) & ~PTE_U;
    80001fb8:	000a3783          	ld	a5,0(s4)
    80001fbc:	9bbd                	andi	a5,a5,-17
    80001fbe:	e11c                	sd	a5,0(a0)
  for (j = 0; j < p->sz; j+=PGSIZE){
    80001fc0:	0489b783          	ld	a5,72(s3)
    80001fc4:	94d6                	add	s1,s1,s5
    80001fc6:	fcf4e8e3          	bltu	s1,a5,80001f96 <fork+0x4a>
  np->sz = p->sz;
    80001fca:	04f93423          	sd	a5,72(s2)
  np->parent = p;
    80001fce:	03393023          	sd	s3,32(s2)
  *(np->trapframe) = *(p->trapframe);
    80001fd2:	0609b683          	ld	a3,96(s3)
    80001fd6:	87b6                	mv	a5,a3
    80001fd8:	06093703          	ld	a4,96(s2)
    80001fdc:	12068693          	addi	a3,a3,288
    80001fe0:	0007b803          	ld	a6,0(a5)
    80001fe4:	6788                	ld	a0,8(a5)
    80001fe6:	6b8c                	ld	a1,16(a5)
    80001fe8:	6f90                	ld	a2,24(a5)
    80001fea:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001fee:	e708                	sd	a0,8(a4)
    80001ff0:	eb0c                	sd	a1,16(a4)
    80001ff2:	ef10                	sd	a2,24(a4)
    80001ff4:	02078793          	addi	a5,a5,32
    80001ff8:	02070713          	addi	a4,a4,32
    80001ffc:	fed792e3          	bne	a5,a3,80001fe0 <fork+0x94>
  np->trapframe->a0 = 0;
    80002000:	06093783          	ld	a5,96(s2)
    80002004:	0607b823          	sd	zero,112(a5)
    80002008:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000200c:	15800a13          	li	s4,344
    80002010:	a03d                	j	8000203e <fork+0xf2>
    freeproc(np);
    80002012:	854a                	mv	a0,s2
    80002014:	00000097          	auipc	ra,0x0
    80002018:	ca0080e7          	jalr	-864(ra) # 80001cb4 <freeproc>
    release(&np->lock);
    8000201c:	854a                	mv	a0,s2
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	ca6080e7          	jalr	-858(ra) # 80000cc4 <release>
    return -1;
    80002026:	54fd                	li	s1,-1
    80002028:	a899                	j	8000207e <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    8000202a:	00002097          	auipc	ra,0x2
    8000202e:	6ce080e7          	jalr	1742(ra) # 800046f8 <filedup>
    80002032:	009907b3          	add	a5,s2,s1
    80002036:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002038:	04a1                	addi	s1,s1,8
    8000203a:	01448763          	beq	s1,s4,80002048 <fork+0xfc>
    if(p->ofile[i])
    8000203e:	009987b3          	add	a5,s3,s1
    80002042:	6388                	ld	a0,0(a5)
    80002044:	f17d                	bnez	a0,8000202a <fork+0xde>
    80002046:	bfcd                	j	80002038 <fork+0xec>
  np->cwd = idup(p->cwd);
    80002048:	1589b503          	ld	a0,344(s3)
    8000204c:	00002097          	auipc	ra,0x2
    80002050:	832080e7          	jalr	-1998(ra) # 8000387e <idup>
    80002054:	14a93c23          	sd	a0,344(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002058:	4641                	li	a2,16
    8000205a:	16098593          	addi	a1,s3,352
    8000205e:	16090513          	addi	a0,s2,352
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	e00080e7          	jalr	-512(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    8000206a:	03892483          	lw	s1,56(s2)
  np->state = RUNNABLE;
    8000206e:	4789                	li	a5,2
    80002070:	00f92c23          	sw	a5,24(s2)
  release(&np->lock);
    80002074:	854a                	mv	a0,s2
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	c4e080e7          	jalr	-946(ra) # 80000cc4 <release>
}
    8000207e:	8526                	mv	a0,s1
    80002080:	70e2                	ld	ra,56(sp)
    80002082:	7442                	ld	s0,48(sp)
    80002084:	74a2                	ld	s1,40(sp)
    80002086:	7902                	ld	s2,32(sp)
    80002088:	69e2                	ld	s3,24(sp)
    8000208a:	6a42                	ld	s4,16(sp)
    8000208c:	6aa2                	ld	s5,8(sp)
    8000208e:	6121                	addi	sp,sp,64
    80002090:	8082                	ret
    return -1;
    80002092:	54fd                	li	s1,-1
    80002094:	b7ed                	j	8000207e <fork+0x132>

0000000080002096 <reparent>:
{
    80002096:	7179                	addi	sp,sp,-48
    80002098:	f406                	sd	ra,40(sp)
    8000209a:	f022                	sd	s0,32(sp)
    8000209c:	ec26                	sd	s1,24(sp)
    8000209e:	e84a                	sd	s2,16(sp)
    800020a0:	e44e                	sd	s3,8(sp)
    800020a2:	e052                	sd	s4,0(sp)
    800020a4:	1800                	addi	s0,sp,48
    800020a6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020a8:	00010497          	auipc	s1,0x10
    800020ac:	cc048493          	addi	s1,s1,-832 # 80011d68 <proc>
      pp->parent = initproc;
    800020b0:	00007a17          	auipc	s4,0x7
    800020b4:	f68a0a13          	addi	s4,s4,-152 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020b8:	00016997          	auipc	s3,0x16
    800020bc:	8b098993          	addi	s3,s3,-1872 # 80017968 <tickslock>
    800020c0:	a029                	j	800020ca <reparent+0x34>
    800020c2:	17048493          	addi	s1,s1,368
    800020c6:	03348363          	beq	s1,s3,800020ec <reparent+0x56>
    if(pp->parent == p){
    800020ca:	709c                	ld	a5,32(s1)
    800020cc:	ff279be3          	bne	a5,s2,800020c2 <reparent+0x2c>
      acquire(&pp->lock);
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b3e080e7          	jalr	-1218(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    800020da:	000a3783          	ld	a5,0(s4)
    800020de:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	be2080e7          	jalr	-1054(ra) # 80000cc4 <release>
    800020ea:	bfe1                	j	800020c2 <reparent+0x2c>
}
    800020ec:	70a2                	ld	ra,40(sp)
    800020ee:	7402                	ld	s0,32(sp)
    800020f0:	64e2                	ld	s1,24(sp)
    800020f2:	6942                	ld	s2,16(sp)
    800020f4:	69a2                	ld	s3,8(sp)
    800020f6:	6a02                	ld	s4,0(sp)
    800020f8:	6145                	addi	sp,sp,48
    800020fa:	8082                	ret

00000000800020fc <scheduler>:
{
    800020fc:	715d                	addi	sp,sp,-80
    800020fe:	e486                	sd	ra,72(sp)
    80002100:	e0a2                	sd	s0,64(sp)
    80002102:	fc26                	sd	s1,56(sp)
    80002104:	f84a                	sd	s2,48(sp)
    80002106:	f44e                	sd	s3,40(sp)
    80002108:	f052                	sd	s4,32(sp)
    8000210a:	ec56                	sd	s5,24(sp)
    8000210c:	e85a                	sd	s6,16(sp)
    8000210e:	e45e                	sd	s7,8(sp)
    80002110:	e062                	sd	s8,0(sp)
    80002112:	0880                	addi	s0,sp,80
    80002114:	8792                	mv	a5,tp
  int id = r_tp();
    80002116:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002118:	00779b13          	slli	s6,a5,0x7
    8000211c:	00010717          	auipc	a4,0x10
    80002120:	83470713          	addi	a4,a4,-1996 # 80011950 <pid_lock>
    80002124:	975a                	add	a4,a4,s6
    80002126:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000212a:	00010717          	auipc	a4,0x10
    8000212e:	84670713          	addi	a4,a4,-1978 # 80011970 <cpus+0x8>
    80002132:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002134:	079e                	slli	a5,a5,0x7
    80002136:	00010a17          	auipc	s4,0x10
    8000213a:	81aa0a13          	addi	s4,s4,-2022 # 80011950 <pid_lock>
    8000213e:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernelPageTable));
    80002140:	5bfd                	li	s7,-1
    80002142:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002144:	00016997          	auipc	s3,0x16
    80002148:	82498993          	addi	s3,s3,-2012 # 80017968 <tickslock>
    8000214c:	a0bd                	j	800021ba <scheduler+0xbe>
        p->state = RUNNING;
    8000214e:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002152:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernelPageTable));
    80002156:	6cbc                	ld	a5,88(s1)
    80002158:	83b1                	srli	a5,a5,0xc
    8000215a:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    8000215e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80002162:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80002166:	06848593          	addi	a1,s1,104
    8000216a:	855a                	mv	a0,s6
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	642080e7          	jalr	1602(ra) # 800027ae <swtch>
        kvminithart();
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	f96080e7          	jalr	-106(ra) # 8000110a <kvminithart>
        c->proc = 0;
    8000217c:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002180:	4c05                	li	s8,1
      release(&p->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b40080e7          	jalr	-1216(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000218c:	17048493          	addi	s1,s1,368
    80002190:	01348b63          	beq	s1,s3,800021a6 <scheduler+0xaa>
      acquire(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	a7a080e7          	jalr	-1414(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    8000219e:	4c9c                	lw	a5,24(s1)
    800021a0:	ff2791e3          	bne	a5,s2,80002182 <scheduler+0x86>
    800021a4:	b76d                	j	8000214e <scheduler+0x52>
    if(found == 0) {
    800021a6:	000c1a63          	bnez	s8,800021ba <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021b2:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800021b6:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021be:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021c2:	10079073          	csrw	sstatus,a5
    int found = 0;
    800021c6:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800021c8:	00010497          	auipc	s1,0x10
    800021cc:	ba048493          	addi	s1,s1,-1120 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800021d0:	4909                	li	s2,2
        p->state = RUNNING;
    800021d2:	4a8d                	li	s5,3
    800021d4:	b7c1                	j	80002194 <scheduler+0x98>

00000000800021d6 <sched>:
{
    800021d6:	7179                	addi	sp,sp,-48
    800021d8:	f406                	sd	ra,40(sp)
    800021da:	f022                	sd	s0,32(sp)
    800021dc:	ec26                	sd	s1,24(sp)
    800021de:	e84a                	sd	s2,16(sp)
    800021e0:	e44e                	sd	s3,8(sp)
    800021e2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	84c080e7          	jalr	-1972(ra) # 80001a30 <myproc>
    800021ec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	9a8080e7          	jalr	-1624(ra) # 80000b96 <holding>
    800021f6:	c93d                	beqz	a0,8000226c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021fa:	2781                	sext.w	a5,a5
    800021fc:	079e                	slli	a5,a5,0x7
    800021fe:	0000f717          	auipc	a4,0xf
    80002202:	75270713          	addi	a4,a4,1874 # 80011950 <pid_lock>
    80002206:	97ba                	add	a5,a5,a4
    80002208:	0907a703          	lw	a4,144(a5)
    8000220c:	4785                	li	a5,1
    8000220e:	06f71763          	bne	a4,a5,8000227c <sched+0xa6>
  if(p->state == RUNNING)
    80002212:	4c98                	lw	a4,24(s1)
    80002214:	478d                	li	a5,3
    80002216:	06f70b63          	beq	a4,a5,8000228c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000221a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000221e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002220:	efb5                	bnez	a5,8000229c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002222:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002224:	0000f917          	auipc	s2,0xf
    80002228:	72c90913          	addi	s2,s2,1836 # 80011950 <pid_lock>
    8000222c:	2781                	sext.w	a5,a5
    8000222e:	079e                	slli	a5,a5,0x7
    80002230:	97ca                	add	a5,a5,s2
    80002232:	0947a983          	lw	s3,148(a5)
    80002236:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002238:	2781                	sext.w	a5,a5
    8000223a:	079e                	slli	a5,a5,0x7
    8000223c:	0000f597          	auipc	a1,0xf
    80002240:	73458593          	addi	a1,a1,1844 # 80011970 <cpus+0x8>
    80002244:	95be                	add	a1,a1,a5
    80002246:	06848513          	addi	a0,s1,104
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	564080e7          	jalr	1380(ra) # 800027ae <swtch>
    80002252:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002254:	2781                	sext.w	a5,a5
    80002256:	079e                	slli	a5,a5,0x7
    80002258:	97ca                	add	a5,a5,s2
    8000225a:	0937aa23          	sw	s3,148(a5)
}
    8000225e:	70a2                	ld	ra,40(sp)
    80002260:	7402                	ld	s0,32(sp)
    80002262:	64e2                	ld	s1,24(sp)
    80002264:	6942                	ld	s2,16(sp)
    80002266:	69a2                	ld	s3,8(sp)
    80002268:	6145                	addi	sp,sp,48
    8000226a:	8082                	ret
    panic("sched p->lock");
    8000226c:	00006517          	auipc	a0,0x6
    80002270:	ff450513          	addi	a0,a0,-12 # 80008260 <digits+0x230>
    80002274:	ffffe097          	auipc	ra,0xffffe
    80002278:	2d4080e7          	jalr	724(ra) # 80000548 <panic>
    panic("sched locks");
    8000227c:	00006517          	auipc	a0,0x6
    80002280:	ff450513          	addi	a0,a0,-12 # 80008270 <digits+0x240>
    80002284:	ffffe097          	auipc	ra,0xffffe
    80002288:	2c4080e7          	jalr	708(ra) # 80000548 <panic>
    panic("sched running");
    8000228c:	00006517          	auipc	a0,0x6
    80002290:	ff450513          	addi	a0,a0,-12 # 80008280 <digits+0x250>
    80002294:	ffffe097          	auipc	ra,0xffffe
    80002298:	2b4080e7          	jalr	692(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	ff450513          	addi	a0,a0,-12 # 80008290 <digits+0x260>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	2a4080e7          	jalr	676(ra) # 80000548 <panic>

00000000800022ac <exit>:
{
    800022ac:	7179                	addi	sp,sp,-48
    800022ae:	f406                	sd	ra,40(sp)
    800022b0:	f022                	sd	s0,32(sp)
    800022b2:	ec26                	sd	s1,24(sp)
    800022b4:	e84a                	sd	s2,16(sp)
    800022b6:	e44e                	sd	s3,8(sp)
    800022b8:	e052                	sd	s4,0(sp)
    800022ba:	1800                	addi	s0,sp,48
    800022bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	772080e7          	jalr	1906(ra) # 80001a30 <myproc>
    800022c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c8:	00007797          	auipc	a5,0x7
    800022cc:	d507b783          	ld	a5,-688(a5) # 80009018 <initproc>
    800022d0:	0d850493          	addi	s1,a0,216
    800022d4:	15850913          	addi	s2,a0,344
    800022d8:	02a79363          	bne	a5,a0,800022fe <exit+0x52>
    panic("init exiting");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	fcc50513          	addi	a0,a0,-52 # 800082a8 <digits+0x278>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	264080e7          	jalr	612(ra) # 80000548 <panic>
      fileclose(f);
    800022ec:	00002097          	auipc	ra,0x2
    800022f0:	45e080e7          	jalr	1118(ra) # 8000474a <fileclose>
      p->ofile[fd] = 0;
    800022f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022f8:	04a1                	addi	s1,s1,8
    800022fa:	01248563          	beq	s1,s2,80002304 <exit+0x58>
    if(p->ofile[fd]){
    800022fe:	6088                	ld	a0,0(s1)
    80002300:	f575                	bnez	a0,800022ec <exit+0x40>
    80002302:	bfdd                	j	800022f8 <exit+0x4c>
  begin_op();
    80002304:	00002097          	auipc	ra,0x2
    80002308:	f74080e7          	jalr	-140(ra) # 80004278 <begin_op>
  iput(p->cwd);
    8000230c:	1589b503          	ld	a0,344(s3)
    80002310:	00001097          	auipc	ra,0x1
    80002314:	766080e7          	jalr	1894(ra) # 80003a76 <iput>
  end_op();
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	fe0080e7          	jalr	-32(ra) # 800042f8 <end_op>
  p->cwd = 0;
    80002320:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002324:	00007497          	auipc	s1,0x7
    80002328:	cf448493          	addi	s1,s1,-780 # 80009018 <initproc>
    8000232c:	6088                	ld	a0,0(s1)
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8e2080e7          	jalr	-1822(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002336:	6088                	ld	a0,0(s1)
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	628080e7          	jalr	1576(ra) # 80001960 <wakeup1>
  release(&initproc->lock);
    80002340:	6088                	ld	a0,0(s1)
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	982080e7          	jalr	-1662(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000234a:	854e                	mv	a0,s3
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	8c4080e7          	jalr	-1852(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002354:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002358:	854e                	mv	a0,s3
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	96a080e7          	jalr	-1686(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	8ac080e7          	jalr	-1876(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    8000236c:	854e                	mv	a0,s3
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	8a2080e7          	jalr	-1886(ra) # 80000c10 <acquire>
  reparent(p);
    80002376:	854e                	mv	a0,s3
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	d1e080e7          	jalr	-738(ra) # 80002096 <reparent>
  wakeup1(original_parent);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	5de080e7          	jalr	1502(ra) # 80001960 <wakeup1>
  p->xstate = status;
    8000238a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000238e:	4791                	li	a5,4
    80002390:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	92e080e7          	jalr	-1746(ra) # 80000cc4 <release>
  sched();
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	e38080e7          	jalr	-456(ra) # 800021d6 <sched>
  panic("zombie exit");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	f1250513          	addi	a0,a0,-238 # 800082b8 <digits+0x288>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	19a080e7          	jalr	410(ra) # 80000548 <panic>

00000000800023b6 <yield>:
{
    800023b6:	1101                	addi	sp,sp,-32
    800023b8:	ec06                	sd	ra,24(sp)
    800023ba:	e822                	sd	s0,16(sp)
    800023bc:	e426                	sd	s1,8(sp)
    800023be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	670080e7          	jalr	1648(ra) # 80001a30 <myproc>
    800023c8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	846080e7          	jalr	-1978(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800023d2:	4789                	li	a5,2
    800023d4:	cc9c                	sw	a5,24(s1)
  sched();
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	e00080e7          	jalr	-512(ra) # 800021d6 <sched>
  release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8e4080e7          	jalr	-1820(ra) # 80000cc4 <release>
}
    800023e8:	60e2                	ld	ra,24(sp)
    800023ea:	6442                	ld	s0,16(sp)
    800023ec:	64a2                	ld	s1,8(sp)
    800023ee:	6105                	addi	sp,sp,32
    800023f0:	8082                	ret

00000000800023f2 <sleep>:
{
    800023f2:	7179                	addi	sp,sp,-48
    800023f4:	f406                	sd	ra,40(sp)
    800023f6:	f022                	sd	s0,32(sp)
    800023f8:	ec26                	sd	s1,24(sp)
    800023fa:	e84a                	sd	s2,16(sp)
    800023fc:	e44e                	sd	s3,8(sp)
    800023fe:	1800                	addi	s0,sp,48
    80002400:	89aa                	mv	s3,a0
    80002402:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	62c080e7          	jalr	1580(ra) # 80001a30 <myproc>
    8000240c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000240e:	05250663          	beq	a0,s2,8000245a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	7fe080e7          	jalr	2046(ra) # 80000c10 <acquire>
    release(lk);
    8000241a:	854a                	mv	a0,s2
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	8a8080e7          	jalr	-1880(ra) # 80000cc4 <release>
  p->chan = chan;
    80002424:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002428:	4785                	li	a5,1
    8000242a:	cc9c                	sw	a5,24(s1)
  sched();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	daa080e7          	jalr	-598(ra) # 800021d6 <sched>
  p->chan = 0;
    80002434:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	88a080e7          	jalr	-1910(ra) # 80000cc4 <release>
    acquire(lk);
    80002442:	854a                	mv	a0,s2
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	7cc080e7          	jalr	1996(ra) # 80000c10 <acquire>
}
    8000244c:	70a2                	ld	ra,40(sp)
    8000244e:	7402                	ld	s0,32(sp)
    80002450:	64e2                	ld	s1,24(sp)
    80002452:	6942                	ld	s2,16(sp)
    80002454:	69a2                	ld	s3,8(sp)
    80002456:	6145                	addi	sp,sp,48
    80002458:	8082                	ret
  p->chan = chan;
    8000245a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000245e:	4785                	li	a5,1
    80002460:	cd1c                	sw	a5,24(a0)
  sched();
    80002462:	00000097          	auipc	ra,0x0
    80002466:	d74080e7          	jalr	-652(ra) # 800021d6 <sched>
  p->chan = 0;
    8000246a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000246e:	bff9                	j	8000244c <sleep+0x5a>

0000000080002470 <wait>:
{
    80002470:	715d                	addi	sp,sp,-80
    80002472:	e486                	sd	ra,72(sp)
    80002474:	e0a2                	sd	s0,64(sp)
    80002476:	fc26                	sd	s1,56(sp)
    80002478:	f84a                	sd	s2,48(sp)
    8000247a:	f44e                	sd	s3,40(sp)
    8000247c:	f052                	sd	s4,32(sp)
    8000247e:	ec56                	sd	s5,24(sp)
    80002480:	e85a                	sd	s6,16(sp)
    80002482:	e45e                	sd	s7,8(sp)
    80002484:	e062                	sd	s8,0(sp)
    80002486:	0880                	addi	s0,sp,80
    80002488:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	5a6080e7          	jalr	1446(ra) # 80001a30 <myproc>
    80002492:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002494:	8c2a                	mv	s8,a0
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	77a080e7          	jalr	1914(ra) # 80000c10 <acquire>
    havekids = 0;
    8000249e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024a0:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800024a2:	00015997          	auipc	s3,0x15
    800024a6:	4c698993          	addi	s3,s3,1222 # 80017968 <tickslock>
        havekids = 1;
    800024aa:	4a85                	li	s5,1
    havekids = 0;
    800024ac:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024ae:	00010497          	auipc	s1,0x10
    800024b2:	8ba48493          	addi	s1,s1,-1862 # 80011d68 <proc>
    800024b6:	a08d                	j	80002518 <wait+0xa8>
          pid = np->pid;
    800024b8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024bc:	000b0e63          	beqz	s6,800024d8 <wait+0x68>
    800024c0:	4691                	li	a3,4
    800024c2:	03448613          	addi	a2,s1,52
    800024c6:	85da                	mv	a1,s6
    800024c8:	05093503          	ld	a0,80(s2)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	3a4080e7          	jalr	932(ra) # 80001870 <copyout>
    800024d4:	02054263          	bltz	a0,800024f8 <wait+0x88>
          freeproc(np);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	7da080e7          	jalr	2010(ra) # 80001cb4 <freeproc>
          release(&np->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7e0080e7          	jalr	2016(ra) # 80000cc4 <release>
          release(&p->lock);
    800024ec:	854a                	mv	a0,s2
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7d6080e7          	jalr	2006(ra) # 80000cc4 <release>
          return pid;
    800024f6:	a8a9                	j	80002550 <wait+0xe0>
            release(&np->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	7ca080e7          	jalr	1994(ra) # 80000cc4 <release>
            release(&p->lock);
    80002502:	854a                	mv	a0,s2
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	7c0080e7          	jalr	1984(ra) # 80000cc4 <release>
            return -1;
    8000250c:	59fd                	li	s3,-1
    8000250e:	a089                	j	80002550 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002510:	17048493          	addi	s1,s1,368
    80002514:	03348463          	beq	s1,s3,8000253c <wait+0xcc>
      if(np->parent == p){
    80002518:	709c                	ld	a5,32(s1)
    8000251a:	ff279be3          	bne	a5,s2,80002510 <wait+0xa0>
        acquire(&np->lock);
    8000251e:	8526                	mv	a0,s1
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	6f0080e7          	jalr	1776(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002528:	4c9c                	lw	a5,24(s1)
    8000252a:	f94787e3          	beq	a5,s4,800024b8 <wait+0x48>
        release(&np->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	794080e7          	jalr	1940(ra) # 80000cc4 <release>
        havekids = 1;
    80002538:	8756                	mv	a4,s5
    8000253a:	bfd9                	j	80002510 <wait+0xa0>
    if(!havekids || p->killed){
    8000253c:	c701                	beqz	a4,80002544 <wait+0xd4>
    8000253e:	03092783          	lw	a5,48(s2)
    80002542:	c785                	beqz	a5,8000256a <wait+0xfa>
      release(&p->lock);
    80002544:	854a                	mv	a0,s2
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	77e080e7          	jalr	1918(ra) # 80000cc4 <release>
      return -1;
    8000254e:	59fd                	li	s3,-1
}
    80002550:	854e                	mv	a0,s3
    80002552:	60a6                	ld	ra,72(sp)
    80002554:	6406                	ld	s0,64(sp)
    80002556:	74e2                	ld	s1,56(sp)
    80002558:	7942                	ld	s2,48(sp)
    8000255a:	79a2                	ld	s3,40(sp)
    8000255c:	7a02                	ld	s4,32(sp)
    8000255e:	6ae2                	ld	s5,24(sp)
    80002560:	6b42                	ld	s6,16(sp)
    80002562:	6ba2                	ld	s7,8(sp)
    80002564:	6c02                	ld	s8,0(sp)
    80002566:	6161                	addi	sp,sp,80
    80002568:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000256a:	85e2                	mv	a1,s8
    8000256c:	854a                	mv	a0,s2
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	e84080e7          	jalr	-380(ra) # 800023f2 <sleep>
    havekids = 0;
    80002576:	bf1d                	j	800024ac <wait+0x3c>

0000000080002578 <wakeup>:
{
    80002578:	7139                	addi	sp,sp,-64
    8000257a:	fc06                	sd	ra,56(sp)
    8000257c:	f822                	sd	s0,48(sp)
    8000257e:	f426                	sd	s1,40(sp)
    80002580:	f04a                	sd	s2,32(sp)
    80002582:	ec4e                	sd	s3,24(sp)
    80002584:	e852                	sd	s4,16(sp)
    80002586:	e456                	sd	s5,8(sp)
    80002588:	0080                	addi	s0,sp,64
    8000258a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000258c:	0000f497          	auipc	s1,0xf
    80002590:	7dc48493          	addi	s1,s1,2012 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002594:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002596:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002598:	00015917          	auipc	s2,0x15
    8000259c:	3d090913          	addi	s2,s2,976 # 80017968 <tickslock>
    800025a0:	a821                	j	800025b8 <wakeup+0x40>
      p->state = RUNNABLE;
    800025a2:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025a6:	8526                	mv	a0,s1
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	71c080e7          	jalr	1820(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b0:	17048493          	addi	s1,s1,368
    800025b4:	01248e63          	beq	s1,s2,800025d0 <wakeup+0x58>
    acquire(&p->lock);
    800025b8:	8526                	mv	a0,s1
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	656080e7          	jalr	1622(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800025c2:	4c9c                	lw	a5,24(s1)
    800025c4:	ff3791e3          	bne	a5,s3,800025a6 <wakeup+0x2e>
    800025c8:	749c                	ld	a5,40(s1)
    800025ca:	fd479ee3          	bne	a5,s4,800025a6 <wakeup+0x2e>
    800025ce:	bfd1                	j	800025a2 <wakeup+0x2a>
}
    800025d0:	70e2                	ld	ra,56(sp)
    800025d2:	7442                	ld	s0,48(sp)
    800025d4:	74a2                	ld	s1,40(sp)
    800025d6:	7902                	ld	s2,32(sp)
    800025d8:	69e2                	ld	s3,24(sp)
    800025da:	6a42                	ld	s4,16(sp)
    800025dc:	6aa2                	ld	s5,8(sp)
    800025de:	6121                	addi	sp,sp,64
    800025e0:	8082                	ret

00000000800025e2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025e2:	7179                	addi	sp,sp,-48
    800025e4:	f406                	sd	ra,40(sp)
    800025e6:	f022                	sd	s0,32(sp)
    800025e8:	ec26                	sd	s1,24(sp)
    800025ea:	e84a                	sd	s2,16(sp)
    800025ec:	e44e                	sd	s3,8(sp)
    800025ee:	1800                	addi	s0,sp,48
    800025f0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	0000f497          	auipc	s1,0xf
    800025f6:	77648493          	addi	s1,s1,1910 # 80011d68 <proc>
    800025fa:	00015997          	auipc	s3,0x15
    800025fe:	36e98993          	addi	s3,s3,878 # 80017968 <tickslock>
    acquire(&p->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	60c080e7          	jalr	1548(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    8000260c:	5c9c                	lw	a5,56(s1)
    8000260e:	01278d63          	beq	a5,s2,80002628 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	6b0080e7          	jalr	1712(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261c:	17048493          	addi	s1,s1,368
    80002620:	ff3491e3          	bne	s1,s3,80002602 <kill+0x20>
  }
  return -1;
    80002624:	557d                	li	a0,-1
    80002626:	a829                	j	80002640 <kill+0x5e>
      p->killed = 1;
    80002628:	4785                	li	a5,1
    8000262a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000262c:	4c98                	lw	a4,24(s1)
    8000262e:	4785                	li	a5,1
    80002630:	00f70f63          	beq	a4,a5,8000264e <kill+0x6c>
      release(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	68e080e7          	jalr	1678(ra) # 80000cc4 <release>
      return 0;
    8000263e:	4501                	li	a0,0
}
    80002640:	70a2                	ld	ra,40(sp)
    80002642:	7402                	ld	s0,32(sp)
    80002644:	64e2                	ld	s1,24(sp)
    80002646:	6942                	ld	s2,16(sp)
    80002648:	69a2                	ld	s3,8(sp)
    8000264a:	6145                	addi	sp,sp,48
    8000264c:	8082                	ret
        p->state = RUNNABLE;
    8000264e:	4789                	li	a5,2
    80002650:	cc9c                	sw	a5,24(s1)
    80002652:	b7cd                	j	80002634 <kill+0x52>

0000000080002654 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	84aa                	mv	s1,a0
    80002666:	892e                	mv	s2,a1
    80002668:	89b2                	mv	s3,a2
    8000266a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	3c4080e7          	jalr	964(ra) # 80001a30 <myproc>
  if(user_dst){
    80002674:	c08d                	beqz	s1,80002696 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002676:	86d2                	mv	a3,s4
    80002678:	864e                	mv	a2,s3
    8000267a:	85ca                	mv	a1,s2
    8000267c:	6928                	ld	a0,80(a0)
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	1f2080e7          	jalr	498(ra) # 80001870 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002686:	70a2                	ld	ra,40(sp)
    80002688:	7402                	ld	s0,32(sp)
    8000268a:	64e2                	ld	s1,24(sp)
    8000268c:	6942                	ld	s2,16(sp)
    8000268e:	69a2                	ld	s3,8(sp)
    80002690:	6a02                	ld	s4,0(sp)
    80002692:	6145                	addi	sp,sp,48
    80002694:	8082                	ret
    memmove((char *)dst, src, len);
    80002696:	000a061b          	sext.w	a2,s4
    8000269a:	85ce                	mv	a1,s3
    8000269c:	854a                	mv	a0,s2
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	6ce080e7          	jalr	1742(ra) # 80000d6c <memmove>
    return 0;
    800026a6:	8526                	mv	a0,s1
    800026a8:	bff9                	j	80002686 <either_copyout+0x32>

00000000800026aa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026aa:	7179                	addi	sp,sp,-48
    800026ac:	f406                	sd	ra,40(sp)
    800026ae:	f022                	sd	s0,32(sp)
    800026b0:	ec26                	sd	s1,24(sp)
    800026b2:	e84a                	sd	s2,16(sp)
    800026b4:	e44e                	sd	s3,8(sp)
    800026b6:	e052                	sd	s4,0(sp)
    800026b8:	1800                	addi	s0,sp,48
    800026ba:	892a                	mv	s2,a0
    800026bc:	84ae                	mv	s1,a1
    800026be:	89b2                	mv	s3,a2
    800026c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	36e080e7          	jalr	878(ra) # 80001a30 <myproc>
  if(user_src){
    800026ca:	c08d                	beqz	s1,800026ec <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026cc:	86d2                	mv	a3,s4
    800026ce:	864e                	mv	a2,s3
    800026d0:	85ca                	mv	a1,s2
    800026d2:	6928                	ld	a0,80(a0)
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	228080e7          	jalr	552(ra) # 800018fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026dc:	70a2                	ld	ra,40(sp)
    800026de:	7402                	ld	s0,32(sp)
    800026e0:	64e2                	ld	s1,24(sp)
    800026e2:	6942                	ld	s2,16(sp)
    800026e4:	69a2                	ld	s3,8(sp)
    800026e6:	6a02                	ld	s4,0(sp)
    800026e8:	6145                	addi	sp,sp,48
    800026ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800026ec:	000a061b          	sext.w	a2,s4
    800026f0:	85ce                	mv	a1,s3
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	678080e7          	jalr	1656(ra) # 80000d6c <memmove>
    return 0;
    800026fc:	8526                	mv	a0,s1
    800026fe:	bff9                	j	800026dc <either_copyin+0x32>

0000000080002700 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002700:	715d                	addi	sp,sp,-80
    80002702:	e486                	sd	ra,72(sp)
    80002704:	e0a2                	sd	s0,64(sp)
    80002706:	fc26                	sd	s1,56(sp)
    80002708:	f84a                	sd	s2,48(sp)
    8000270a:	f44e                	sd	s3,40(sp)
    8000270c:	f052                	sd	s4,32(sp)
    8000270e:	ec56                	sd	s5,24(sp)
    80002710:	e85a                	sd	s6,16(sp)
    80002712:	e45e                	sd	s7,8(sp)
    80002714:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002716:	00006517          	auipc	a0,0x6
    8000271a:	9a250513          	addi	a0,a0,-1630 # 800080b8 <digits+0x88>
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	e74080e7          	jalr	-396(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002726:	0000f497          	auipc	s1,0xf
    8000272a:	7a248493          	addi	s1,s1,1954 # 80011ec8 <proc+0x160>
    8000272e:	00015917          	auipc	s2,0x15
    80002732:	39a90913          	addi	s2,s2,922 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002736:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002738:	00006997          	auipc	s3,0x6
    8000273c:	b9098993          	addi	s3,s3,-1136 # 800082c8 <digits+0x298>
    printf("%d %s %s", p->pid, state, p->name);
    80002740:	00006a97          	auipc	s5,0x6
    80002744:	b90a8a93          	addi	s5,s5,-1136 # 800082d0 <digits+0x2a0>
    printf("\n");
    80002748:	00006a17          	auipc	s4,0x6
    8000274c:	970a0a13          	addi	s4,s4,-1680 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002750:	00006b97          	auipc	s7,0x6
    80002754:	bb8b8b93          	addi	s7,s7,-1096 # 80008308 <states.1752>
    80002758:	a00d                	j	8000277a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000275a:	ed86a583          	lw	a1,-296(a3)
    8000275e:	8556                	mv	a0,s5
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	e32080e7          	jalr	-462(ra) # 80000592 <printf>
    printf("\n");
    80002768:	8552                	mv	a0,s4
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	e28080e7          	jalr	-472(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002772:	17048493          	addi	s1,s1,368
    80002776:	03248163          	beq	s1,s2,80002798 <procdump+0x98>
    if(p->state == UNUSED)
    8000277a:	86a6                	mv	a3,s1
    8000277c:	eb84a783          	lw	a5,-328(s1)
    80002780:	dbed                	beqz	a5,80002772 <procdump+0x72>
      state = "???";
    80002782:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002784:	fcfb6be3          	bltu	s6,a5,8000275a <procdump+0x5a>
    80002788:	1782                	slli	a5,a5,0x20
    8000278a:	9381                	srli	a5,a5,0x20
    8000278c:	078e                	slli	a5,a5,0x3
    8000278e:	97de                	add	a5,a5,s7
    80002790:	6390                	ld	a2,0(a5)
    80002792:	f661                	bnez	a2,8000275a <procdump+0x5a>
      state = "???";
    80002794:	864e                	mv	a2,s3
    80002796:	b7d1                	j	8000275a <procdump+0x5a>
  }
    80002798:	60a6                	ld	ra,72(sp)
    8000279a:	6406                	ld	s0,64(sp)
    8000279c:	74e2                	ld	s1,56(sp)
    8000279e:	7942                	ld	s2,48(sp)
    800027a0:	79a2                	ld	s3,40(sp)
    800027a2:	7a02                	ld	s4,32(sp)
    800027a4:	6ae2                	ld	s5,24(sp)
    800027a6:	6b42                	ld	s6,16(sp)
    800027a8:	6ba2                	ld	s7,8(sp)
    800027aa:	6161                	addi	sp,sp,80
    800027ac:	8082                	ret

00000000800027ae <swtch>:
    800027ae:	00153023          	sd	ra,0(a0)
    800027b2:	00253423          	sd	sp,8(a0)
    800027b6:	e900                	sd	s0,16(a0)
    800027b8:	ed04                	sd	s1,24(a0)
    800027ba:	03253023          	sd	s2,32(a0)
    800027be:	03353423          	sd	s3,40(a0)
    800027c2:	03453823          	sd	s4,48(a0)
    800027c6:	03553c23          	sd	s5,56(a0)
    800027ca:	05653023          	sd	s6,64(a0)
    800027ce:	05753423          	sd	s7,72(a0)
    800027d2:	05853823          	sd	s8,80(a0)
    800027d6:	05953c23          	sd	s9,88(a0)
    800027da:	07a53023          	sd	s10,96(a0)
    800027de:	07b53423          	sd	s11,104(a0)
    800027e2:	0005b083          	ld	ra,0(a1)
    800027e6:	0085b103          	ld	sp,8(a1)
    800027ea:	6980                	ld	s0,16(a1)
    800027ec:	6d84                	ld	s1,24(a1)
    800027ee:	0205b903          	ld	s2,32(a1)
    800027f2:	0285b983          	ld	s3,40(a1)
    800027f6:	0305ba03          	ld	s4,48(a1)
    800027fa:	0385ba83          	ld	s5,56(a1)
    800027fe:	0405bb03          	ld	s6,64(a1)
    80002802:	0485bb83          	ld	s7,72(a1)
    80002806:	0505bc03          	ld	s8,80(a1)
    8000280a:	0585bc83          	ld	s9,88(a1)
    8000280e:	0605bd03          	ld	s10,96(a1)
    80002812:	0685bd83          	ld	s11,104(a1)
    80002816:	8082                	ret

0000000080002818 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002818:	1141                	addi	sp,sp,-16
    8000281a:	e406                	sd	ra,8(sp)
    8000281c:	e022                	sd	s0,0(sp)
    8000281e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002820:	00006597          	auipc	a1,0x6
    80002824:	b1058593          	addi	a1,a1,-1264 # 80008330 <states.1752+0x28>
    80002828:	00015517          	auipc	a0,0x15
    8000282c:	14050513          	addi	a0,a0,320 # 80017968 <tickslock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	350080e7          	jalr	848(ra) # 80000b80 <initlock>
}
    80002838:	60a2                	ld	ra,8(sp)
    8000283a:	6402                	ld	s0,0(sp)
    8000283c:	0141                	addi	sp,sp,16
    8000283e:	8082                	ret

0000000080002840 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002840:	1141                	addi	sp,sp,-16
    80002842:	e422                	sd	s0,8(sp)
    80002844:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002846:	00003797          	auipc	a5,0x3
    8000284a:	5da78793          	addi	a5,a5,1498 # 80005e20 <kernelvec>
    8000284e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002852:	6422                	ld	s0,8(sp)
    80002854:	0141                	addi	sp,sp,16
    80002856:	8082                	ret

0000000080002858 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002858:	1141                	addi	sp,sp,-16
    8000285a:	e406                	sd	ra,8(sp)
    8000285c:	e022                	sd	s0,0(sp)
    8000285e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	1d0080e7          	jalr	464(ra) # 80001a30 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002872:	00004617          	auipc	a2,0x4
    80002876:	78e60613          	addi	a2,a2,1934 # 80007000 <_trampoline>
    8000287a:	00004697          	auipc	a3,0x4
    8000287e:	78668693          	addi	a3,a3,1926 # 80007000 <_trampoline>
    80002882:	8e91                	sub	a3,a3,a2
    80002884:	040007b7          	lui	a5,0x4000
    80002888:	17fd                	addi	a5,a5,-1
    8000288a:	07b2                	slli	a5,a5,0xc
    8000288c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002892:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002894:	180026f3          	csrr	a3,satp
    80002898:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289a:	7138                	ld	a4,96(a0)
    8000289c:	6134                	ld	a3,64(a0)
    8000289e:	6585                	lui	a1,0x1
    800028a0:	96ae                	add	a3,a3,a1
    800028a2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a4:	7138                	ld	a4,96(a0)
    800028a6:	00000697          	auipc	a3,0x0
    800028aa:	13868693          	addi	a3,a3,312 # 800029de <usertrap>
    800028ae:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028b0:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b2:	8692                	mv	a3,tp
    800028b4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028ba:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028be:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c6:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c8:	6f18                	ld	a4,24(a4)
    800028ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ce:	692c                	ld	a1,80(a0)
    800028d0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028d2:	00004717          	auipc	a4,0x4
    800028d6:	7be70713          	addi	a4,a4,1982 # 80007090 <userret>
    800028da:	8f11                	sub	a4,a4,a2
    800028dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028de:	577d                	li	a4,-1
    800028e0:	177e                	slli	a4,a4,0x3f
    800028e2:	8dd9                	or	a1,a1,a4
    800028e4:	02000537          	lui	a0,0x2000
    800028e8:	157d                	addi	a0,a0,-1
    800028ea:	0536                	slli	a0,a0,0xd
    800028ec:	9782                	jalr	a5
}
    800028ee:	60a2                	ld	ra,8(sp)
    800028f0:	6402                	ld	s0,0(sp)
    800028f2:	0141                	addi	sp,sp,16
    800028f4:	8082                	ret

00000000800028f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028f6:	1101                	addi	sp,sp,-32
    800028f8:	ec06                	sd	ra,24(sp)
    800028fa:	e822                	sd	s0,16(sp)
    800028fc:	e426                	sd	s1,8(sp)
    800028fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002900:	00015497          	auipc	s1,0x15
    80002904:	06848493          	addi	s1,s1,104 # 80017968 <tickslock>
    80002908:	8526                	mv	a0,s1
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	306080e7          	jalr	774(ra) # 80000c10 <acquire>
  ticks++;
    80002912:	00006517          	auipc	a0,0x6
    80002916:	70e50513          	addi	a0,a0,1806 # 80009020 <ticks>
    8000291a:	411c                	lw	a5,0(a0)
    8000291c:	2785                	addiw	a5,a5,1
    8000291e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002920:	00000097          	auipc	ra,0x0
    80002924:	c58080e7          	jalr	-936(ra) # 80002578 <wakeup>
  release(&tickslock);
    80002928:	8526                	mv	a0,s1
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	39a080e7          	jalr	922(ra) # 80000cc4 <release>
}
    80002932:	60e2                	ld	ra,24(sp)
    80002934:	6442                	ld	s0,16(sp)
    80002936:	64a2                	ld	s1,8(sp)
    80002938:	6105                	addi	sp,sp,32
    8000293a:	8082                	ret

000000008000293c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000293c:	1101                	addi	sp,sp,-32
    8000293e:	ec06                	sd	ra,24(sp)
    80002940:	e822                	sd	s0,16(sp)
    80002942:	e426                	sd	s1,8(sp)
    80002944:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002946:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000294a:	00074d63          	bltz	a4,80002964 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000294e:	57fd                	li	a5,-1
    80002950:	17fe                	slli	a5,a5,0x3f
    80002952:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002954:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002956:	06f70363          	beq	a4,a5,800029bc <devintr+0x80>
  }
}
    8000295a:	60e2                	ld	ra,24(sp)
    8000295c:	6442                	ld	s0,16(sp)
    8000295e:	64a2                	ld	s1,8(sp)
    80002960:	6105                	addi	sp,sp,32
    80002962:	8082                	ret
     (scause & 0xff) == 9){
    80002964:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002968:	46a5                	li	a3,9
    8000296a:	fed792e3          	bne	a5,a3,8000294e <devintr+0x12>
    int irq = plic_claim();
    8000296e:	00003097          	auipc	ra,0x3
    80002972:	5ba080e7          	jalr	1466(ra) # 80005f28 <plic_claim>
    80002976:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002978:	47a9                	li	a5,10
    8000297a:	02f50763          	beq	a0,a5,800029a8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000297e:	4785                	li	a5,1
    80002980:	02f50963          	beq	a0,a5,800029b2 <devintr+0x76>
    return 1;
    80002984:	4505                	li	a0,1
    } else if(irq){
    80002986:	d8f1                	beqz	s1,8000295a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002988:	85a6                	mv	a1,s1
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9ae50513          	addi	a0,a0,-1618 # 80008338 <states.1752+0x30>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	c00080e7          	jalr	-1024(ra) # 80000592 <printf>
      plic_complete(irq);
    8000299a:	8526                	mv	a0,s1
    8000299c:	00003097          	auipc	ra,0x3
    800029a0:	5b0080e7          	jalr	1456(ra) # 80005f4c <plic_complete>
    return 1;
    800029a4:	4505                	li	a0,1
    800029a6:	bf55                	j	8000295a <devintr+0x1e>
      uartintr();
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	02c080e7          	jalr	44(ra) # 800009d4 <uartintr>
    800029b0:	b7ed                	j	8000299a <devintr+0x5e>
      virtio_disk_intr();
    800029b2:	00004097          	auipc	ra,0x4
    800029b6:	a34080e7          	jalr	-1484(ra) # 800063e6 <virtio_disk_intr>
    800029ba:	b7c5                	j	8000299a <devintr+0x5e>
    if(cpuid() == 0){
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	048080e7          	jalr	72(ra) # 80001a04 <cpuid>
    800029c4:	c901                	beqz	a0,800029d4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029cc:	14479073          	csrw	sip,a5
    return 2;
    800029d0:	4509                	li	a0,2
    800029d2:	b761                	j	8000295a <devintr+0x1e>
      clockintr();
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	f22080e7          	jalr	-222(ra) # 800028f6 <clockintr>
    800029dc:	b7ed                	j	800029c6 <devintr+0x8a>

00000000800029de <usertrap>:
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	e04a                	sd	s2,0(sp)
    800029e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ee:	1007f793          	andi	a5,a5,256
    800029f2:	e3ad                	bnez	a5,80002a54 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f4:	00003797          	auipc	a5,0x3
    800029f8:	42c78793          	addi	a5,a5,1068 # 80005e20 <kernelvec>
    800029fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	030080e7          	jalr	48(ra) # 80001a30 <myproc>
    80002a08:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a0a:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0c:	14102773          	csrr	a4,sepc
    80002a10:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a12:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a16:	47a1                	li	a5,8
    80002a18:	04f71c63          	bne	a4,a5,80002a70 <usertrap+0x92>
    if(p->killed)
    80002a1c:	591c                	lw	a5,48(a0)
    80002a1e:	e3b9                	bnez	a5,80002a64 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a20:	70b8                	ld	a4,96(s1)
    80002a22:	6f1c                	ld	a5,24(a4)
    80002a24:	0791                	addi	a5,a5,4
    80002a26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a30:	10079073          	csrw	sstatus,a5
    syscall();
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	2e0080e7          	jalr	736(ra) # 80002d14 <syscall>
  if(p->killed)
    80002a3c:	589c                	lw	a5,48(s1)
    80002a3e:	ebc1                	bnez	a5,80002ace <usertrap+0xf0>
  usertrapret();
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	e18080e7          	jalr	-488(ra) # 80002858 <usertrapret>
}
    80002a48:	60e2                	ld	ra,24(sp)
    80002a4a:	6442                	ld	s0,16(sp)
    80002a4c:	64a2                	ld	s1,8(sp)
    80002a4e:	6902                	ld	s2,0(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret
    panic("usertrap: not from user mode");
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	90450513          	addi	a0,a0,-1788 # 80008358 <states.1752+0x50>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	aec080e7          	jalr	-1300(ra) # 80000548 <panic>
      exit(-1);
    80002a64:	557d                	li	a0,-1
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	846080e7          	jalr	-1978(ra) # 800022ac <exit>
    80002a6e:	bf4d                	j	80002a20 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	ecc080e7          	jalr	-308(ra) # 8000293c <devintr>
    80002a78:	892a                	mv	s2,a0
    80002a7a:	c501                	beqz	a0,80002a82 <usertrap+0xa4>
  if(p->killed)
    80002a7c:	589c                	lw	a5,48(s1)
    80002a7e:	c3a1                	beqz	a5,80002abe <usertrap+0xe0>
    80002a80:	a815                	j	80002ab4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a86:	5c90                	lw	a2,56(s1)
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	8f050513          	addi	a0,a0,-1808 # 80008378 <states.1752+0x70>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	b02080e7          	jalr	-1278(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	90850513          	addi	a0,a0,-1784 # 800083a8 <states.1752+0xa0>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	aea080e7          	jalr	-1302(ra) # 80000592 <printf>
    p->killed = 1;
    80002ab0:	4785                	li	a5,1
    80002ab2:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002ab4:	557d                	li	a0,-1
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	7f6080e7          	jalr	2038(ra) # 800022ac <exit>
  if(which_dev == 2)
    80002abe:	4789                	li	a5,2
    80002ac0:	f8f910e3          	bne	s2,a5,80002a40 <usertrap+0x62>
    yield();
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	8f2080e7          	jalr	-1806(ra) # 800023b6 <yield>
    80002acc:	bf95                	j	80002a40 <usertrap+0x62>
  int which_dev = 0;
    80002ace:	4901                	li	s2,0
    80002ad0:	b7d5                	j	80002ab4 <usertrap+0xd6>

0000000080002ad2 <kerneltrap>:
{
    80002ad2:	7179                	addi	sp,sp,-48
    80002ad4:	f406                	sd	ra,40(sp)
    80002ad6:	f022                	sd	s0,32(sp)
    80002ad8:	ec26                	sd	s1,24(sp)
    80002ada:	e84a                	sd	s2,16(sp)
    80002adc:	e44e                	sd	s3,8(sp)
    80002ade:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aec:	1004f793          	andi	a5,s1,256
    80002af0:	cb85                	beqz	a5,80002b20 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002af6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002af8:	ef85                	bnez	a5,80002b30 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	e42080e7          	jalr	-446(ra) # 8000293c <devintr>
    80002b02:	cd1d                	beqz	a0,80002b40 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b04:	4789                	li	a5,2
    80002b06:	06f50a63          	beq	a0,a5,80002b7a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b0a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b0e:	10049073          	csrw	sstatus,s1
}
    80002b12:	70a2                	ld	ra,40(sp)
    80002b14:	7402                	ld	s0,32(sp)
    80002b16:	64e2                	ld	s1,24(sp)
    80002b18:	6942                	ld	s2,16(sp)
    80002b1a:	69a2                	ld	s3,8(sp)
    80002b1c:	6145                	addi	sp,sp,48
    80002b1e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b20:	00006517          	auipc	a0,0x6
    80002b24:	8a850513          	addi	a0,a0,-1880 # 800083c8 <states.1752+0xc0>
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	a20080e7          	jalr	-1504(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	8c050513          	addi	a0,a0,-1856 # 800083f0 <states.1752+0xe8>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a10080e7          	jalr	-1520(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002b40:	85ce                	mv	a1,s3
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	8ce50513          	addi	a0,a0,-1842 # 80008410 <states.1752+0x108>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	a48080e7          	jalr	-1464(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b56:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	8c650513          	addi	a0,a0,-1850 # 80008420 <states.1752+0x118>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a30080e7          	jalr	-1488(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	8ce50513          	addi	a0,a0,-1842 # 80008438 <states.1752+0x130>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	9d6080e7          	jalr	-1578(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	eb6080e7          	jalr	-330(ra) # 80001a30 <myproc>
    80002b82:	d541                	beqz	a0,80002b0a <kerneltrap+0x38>
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	eac080e7          	jalr	-340(ra) # 80001a30 <myproc>
    80002b8c:	4d18                	lw	a4,24(a0)
    80002b8e:	478d                	li	a5,3
    80002b90:	f6f71de3          	bne	a4,a5,80002b0a <kerneltrap+0x38>
    yield();
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	822080e7          	jalr	-2014(ra) # 800023b6 <yield>
    80002b9c:	b7bd                	j	80002b0a <kerneltrap+0x38>

0000000080002b9e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b9e:	1101                	addi	sp,sp,-32
    80002ba0:	ec06                	sd	ra,24(sp)
    80002ba2:	e822                	sd	s0,16(sp)
    80002ba4:	e426                	sd	s1,8(sp)
    80002ba6:	1000                	addi	s0,sp,32
    80002ba8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	e86080e7          	jalr	-378(ra) # 80001a30 <myproc>
  switch (n) {
    80002bb2:	4795                	li	a5,5
    80002bb4:	0497e163          	bltu	a5,s1,80002bf6 <argraw+0x58>
    80002bb8:	048a                	slli	s1,s1,0x2
    80002bba:	00006717          	auipc	a4,0x6
    80002bbe:	8b670713          	addi	a4,a4,-1866 # 80008470 <states.1752+0x168>
    80002bc2:	94ba                	add	s1,s1,a4
    80002bc4:	409c                	lw	a5,0(s1)
    80002bc6:	97ba                	add	a5,a5,a4
    80002bc8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bca:	713c                	ld	a5,96(a0)
    80002bcc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	addi	sp,sp,32
    80002bd6:	8082                	ret
    return p->trapframe->a1;
    80002bd8:	713c                	ld	a5,96(a0)
    80002bda:	7fa8                	ld	a0,120(a5)
    80002bdc:	bfcd                	j	80002bce <argraw+0x30>
    return p->trapframe->a2;
    80002bde:	713c                	ld	a5,96(a0)
    80002be0:	63c8                	ld	a0,128(a5)
    80002be2:	b7f5                	j	80002bce <argraw+0x30>
    return p->trapframe->a3;
    80002be4:	713c                	ld	a5,96(a0)
    80002be6:	67c8                	ld	a0,136(a5)
    80002be8:	b7dd                	j	80002bce <argraw+0x30>
    return p->trapframe->a4;
    80002bea:	713c                	ld	a5,96(a0)
    80002bec:	6bc8                	ld	a0,144(a5)
    80002bee:	b7c5                	j	80002bce <argraw+0x30>
    return p->trapframe->a5;
    80002bf0:	713c                	ld	a5,96(a0)
    80002bf2:	6fc8                	ld	a0,152(a5)
    80002bf4:	bfe9                	j	80002bce <argraw+0x30>
  panic("argraw");
    80002bf6:	00006517          	auipc	a0,0x6
    80002bfa:	85250513          	addi	a0,a0,-1966 # 80008448 <states.1752+0x140>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	94a080e7          	jalr	-1718(ra) # 80000548 <panic>

0000000080002c06 <fetchaddr>:
{
    80002c06:	1101                	addi	sp,sp,-32
    80002c08:	ec06                	sd	ra,24(sp)
    80002c0a:	e822                	sd	s0,16(sp)
    80002c0c:	e426                	sd	s1,8(sp)
    80002c0e:	e04a                	sd	s2,0(sp)
    80002c10:	1000                	addi	s0,sp,32
    80002c12:	84aa                	mv	s1,a0
    80002c14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	e1a080e7          	jalr	-486(ra) # 80001a30 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c1e:	653c                	ld	a5,72(a0)
    80002c20:	02f4f863          	bgeu	s1,a5,80002c50 <fetchaddr+0x4a>
    80002c24:	00848713          	addi	a4,s1,8
    80002c28:	02e7e663          	bltu	a5,a4,80002c54 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c2c:	46a1                	li	a3,8
    80002c2e:	8626                	mv	a2,s1
    80002c30:	85ca                	mv	a1,s2
    80002c32:	6928                	ld	a0,80(a0)
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	cc8080e7          	jalr	-824(ra) # 800018fc <copyin>
    80002c3c:	00a03533          	snez	a0,a0
    80002c40:	40a00533          	neg	a0,a0
}
    80002c44:	60e2                	ld	ra,24(sp)
    80002c46:	6442                	ld	s0,16(sp)
    80002c48:	64a2                	ld	s1,8(sp)
    80002c4a:	6902                	ld	s2,0(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret
    return -1;
    80002c50:	557d                	li	a0,-1
    80002c52:	bfcd                	j	80002c44 <fetchaddr+0x3e>
    80002c54:	557d                	li	a0,-1
    80002c56:	b7fd                	j	80002c44 <fetchaddr+0x3e>

0000000080002c58 <fetchstr>:
{
    80002c58:	7179                	addi	sp,sp,-48
    80002c5a:	f406                	sd	ra,40(sp)
    80002c5c:	f022                	sd	s0,32(sp)
    80002c5e:	ec26                	sd	s1,24(sp)
    80002c60:	e84a                	sd	s2,16(sp)
    80002c62:	e44e                	sd	s3,8(sp)
    80002c64:	1800                	addi	s0,sp,48
    80002c66:	892a                	mv	s2,a0
    80002c68:	84ae                	mv	s1,a1
    80002c6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	dc4080e7          	jalr	-572(ra) # 80001a30 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c74:	86ce                	mv	a3,s3
    80002c76:	864a                	mv	a2,s2
    80002c78:	85a6                	mv	a1,s1
    80002c7a:	6928                	ld	a0,80(a0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	c98080e7          	jalr	-872(ra) # 80001914 <copyinstr>
  if(err < 0)
    80002c84:	00054763          	bltz	a0,80002c92 <fetchstr+0x3a>
  return strlen(buf);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	20a080e7          	jalr	522(ra) # 80000e94 <strlen>
}
    80002c92:	70a2                	ld	ra,40(sp)
    80002c94:	7402                	ld	s0,32(sp)
    80002c96:	64e2                	ld	s1,24(sp)
    80002c98:	6942                	ld	s2,16(sp)
    80002c9a:	69a2                	ld	s3,8(sp)
    80002c9c:	6145                	addi	sp,sp,48
    80002c9e:	8082                	ret

0000000080002ca0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ca0:	1101                	addi	sp,sp,-32
    80002ca2:	ec06                	sd	ra,24(sp)
    80002ca4:	e822                	sd	s0,16(sp)
    80002ca6:	e426                	sd	s1,8(sp)
    80002ca8:	1000                	addi	s0,sp,32
    80002caa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	ef2080e7          	jalr	-270(ra) # 80002b9e <argraw>
    80002cb4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cb6:	4501                	li	a0,0
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret

0000000080002cc2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cc2:	1101                	addi	sp,sp,-32
    80002cc4:	ec06                	sd	ra,24(sp)
    80002cc6:	e822                	sd	s0,16(sp)
    80002cc8:	e426                	sd	s1,8(sp)
    80002cca:	1000                	addi	s0,sp,32
    80002ccc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	ed0080e7          	jalr	-304(ra) # 80002b9e <argraw>
    80002cd6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cd8:	4501                	li	a0,0
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	64a2                	ld	s1,8(sp)
    80002ce0:	6105                	addi	sp,sp,32
    80002ce2:	8082                	ret

0000000080002ce4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	e426                	sd	s1,8(sp)
    80002cec:	e04a                	sd	s2,0(sp)
    80002cee:	1000                	addi	s0,sp,32
    80002cf0:	84ae                	mv	s1,a1
    80002cf2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	eaa080e7          	jalr	-342(ra) # 80002b9e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cfc:	864a                	mv	a2,s2
    80002cfe:	85a6                	mv	a1,s1
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	f58080e7          	jalr	-168(ra) # 80002c58 <fetchstr>
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	64a2                	ld	s1,8(sp)
    80002d0e:	6902                	ld	s2,0(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret

0000000080002d14 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	e04a                	sd	s2,0(sp)
    80002d1e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	d10080e7          	jalr	-752(ra) # 80001a30 <myproc>
    80002d28:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d2a:	06053903          	ld	s2,96(a0)
    80002d2e:	0a893783          	ld	a5,168(s2)
    80002d32:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d36:	37fd                	addiw	a5,a5,-1
    80002d38:	4751                	li	a4,20
    80002d3a:	00f76f63          	bltu	a4,a5,80002d58 <syscall+0x44>
    80002d3e:	00369713          	slli	a4,a3,0x3
    80002d42:	00005797          	auipc	a5,0x5
    80002d46:	74678793          	addi	a5,a5,1862 # 80008488 <syscalls>
    80002d4a:	97ba                	add	a5,a5,a4
    80002d4c:	639c                	ld	a5,0(a5)
    80002d4e:	c789                	beqz	a5,80002d58 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d50:	9782                	jalr	a5
    80002d52:	06a93823          	sd	a0,112(s2)
    80002d56:	a839                	j	80002d74 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d58:	16048613          	addi	a2,s1,352
    80002d5c:	5c8c                	lw	a1,56(s1)
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	6f250513          	addi	a0,a0,1778 # 80008450 <states.1752+0x148>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	82c080e7          	jalr	-2004(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6e:	70bc                	ld	a5,96(s1)
    80002d70:	577d                	li	a4,-1
    80002d72:	fbb8                	sd	a4,112(a5)
  }
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6902                	ld	s2,0(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d88:	fec40593          	addi	a1,s0,-20
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	f12080e7          	jalr	-238(ra) # 80002ca0 <argint>
    return -1;
    80002d96:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d98:	00054963          	bltz	a0,80002daa <sys_exit+0x2a>
  exit(n);
    80002d9c:	fec42503          	lw	a0,-20(s0)
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	50c080e7          	jalr	1292(ra) # 800022ac <exit>
  return 0;  // not reached
    80002da8:	4781                	li	a5,0
}
    80002daa:	853e                	mv	a0,a5
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret

0000000080002db4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002db4:	1141                	addi	sp,sp,-16
    80002db6:	e406                	sd	ra,8(sp)
    80002db8:	e022                	sd	s0,0(sp)
    80002dba:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	c74080e7          	jalr	-908(ra) # 80001a30 <myproc>
}
    80002dc4:	5d08                	lw	a0,56(a0)
    80002dc6:	60a2                	ld	ra,8(sp)
    80002dc8:	6402                	ld	s0,0(sp)
    80002dca:	0141                	addi	sp,sp,16
    80002dcc:	8082                	ret

0000000080002dce <sys_fork>:

uint64
sys_fork(void)
{
    80002dce:	1141                	addi	sp,sp,-16
    80002dd0:	e406                	sd	ra,8(sp)
    80002dd2:	e022                	sd	s0,0(sp)
    80002dd4:	0800                	addi	s0,sp,16
  return fork();
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	176080e7          	jalr	374(ra) # 80001f4c <fork>
}
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <sys_wait>:

uint64
sys_wait(void)
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dee:	fe840593          	addi	a1,s0,-24
    80002df2:	4501                	li	a0,0
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	ece080e7          	jalr	-306(ra) # 80002cc2 <argaddr>
    80002dfc:	87aa                	mv	a5,a0
    return -1;
    80002dfe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e00:	0007c863          	bltz	a5,80002e10 <sys_wait+0x2a>
  return wait(p);
    80002e04:	fe843503          	ld	a0,-24(s0)
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	668080e7          	jalr	1640(ra) # 80002470 <wait>
}
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	6105                	addi	sp,sp,32
    80002e16:	8082                	ret

0000000080002e18 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e18:	711d                	addi	sp,sp,-96
    80002e1a:	ec86                	sd	ra,88(sp)
    80002e1c:	e8a2                	sd	s0,80(sp)
    80002e1e:	e4a6                	sd	s1,72(sp)
    80002e20:	e0ca                	sd	s2,64(sp)
    80002e22:	fc4e                	sd	s3,56(sp)
    80002e24:	f852                	sd	s4,48(sp)
    80002e26:	f456                	sd	s5,40(sp)
    80002e28:	f05a                	sd	s6,32(sp)
    80002e2a:	ec5e                	sd	s7,24(sp)
    80002e2c:	1080                	addi	s0,sp,96
  int addr;
  int n, j;
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	c02080e7          	jalr	-1022(ra) # 80001a30 <myproc>
    80002e36:	84aa                	mv	s1,a0
  pte_t *pte, *kernelPte;

  if(argint(0, &n) < 0)
    80002e38:	fac40593          	addi	a1,s0,-84
    80002e3c:	4501                	li	a0,0
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	e62080e7          	jalr	-414(ra) # 80002ca0 <argint>
    80002e46:	0a054f63          	bltz	a0,80002f04 <sys_sbrk+0xec>
    return -1;
  addr = p->sz;
    80002e4a:	0484aa83          	lw	s5,72(s1)
  if (addr + n >= PLIC){
    80002e4e:	fac42783          	lw	a5,-84(s0)
    80002e52:	015786bb          	addw	a3,a5,s5
    80002e56:	0c000737          	lui	a4,0xc000
    return -1;
    80002e5a:	557d                	li	a0,-1
  if (addr + n >= PLIC){
    80002e5c:	04e6de63          	bge	a3,a4,80002eb8 <sys_sbrk+0xa0>
  }
  if(growproc(n) < 0)
    80002e60:	853e                	mv	a0,a5
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	076080e7          	jalr	118(ra) # 80001ed8 <growproc>
    80002e6a:	08054f63          	bltz	a0,80002f08 <sys_sbrk+0xf0>
    return -1;
  if (n > 0){
    80002e6e:	fac42783          	lw	a5,-84(s0)
    80002e72:	04f05e63          	blez	a5,80002ece <sys_sbrk+0xb6>
    //将进程页表的mapping，复制一份到进程内核页表
    for (j = addr; j < addr + n; j += PGSIZE){
    80002e76:	8956                	mv	s2,s5
    80002e78:	8a56                	mv	s4,s5
    80002e7a:	6b85                	lui	s7,0x1
    80002e7c:	6b05                	lui	s6,0x1
      pte = walk(p->pagetable, j, 0);
    80002e7e:	4601                	li	a2,0
    80002e80:	85ca                	mv	a1,s2
    80002e82:	68a8                	ld	a0,80(s1)
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	2aa080e7          	jalr	682(ra) # 8000112e <walk>
    80002e8c:	89aa                	mv	s3,a0
      kernelPte = walk(p->kernelPageTable, j, 1);
    80002e8e:	4605                	li	a2,1
    80002e90:	85ca                	mv	a1,s2
    80002e92:	6ca8                	ld	a0,88(s1)
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	29a080e7          	jalr	666(ra) # 8000112e <walk>
      *kernelPte = (*pte) & ~PTE_U;
    80002e9c:	0009b783          	ld	a5,0(s3)
    80002ea0:	9bbd                	andi	a5,a5,-17
    80002ea2:	e11c                	sd	a5,0(a0)
    for (j = addr; j < addr + n; j += PGSIZE){
    80002ea4:	014b8a3b          	addw	s4,s7,s4
    80002ea8:	995a                	add	s2,s2,s6
    80002eaa:	fac42783          	lw	a5,-84(s0)
    80002eae:	015787bb          	addw	a5,a5,s5
    80002eb2:	fcfa46e3          	blt	s4,a5,80002e7e <sys_sbrk+0x66>
  }else {
    for (j = addr - PGSIZE; j >= addr + n; j -= PGSIZE){
      uvmunmap(p->kernelPageTable, j, 1, 0);
	}
  }
  return addr;
    80002eb6:	8556                	mv	a0,s5
}
    80002eb8:	60e6                	ld	ra,88(sp)
    80002eba:	6446                	ld	s0,80(sp)
    80002ebc:	64a6                	ld	s1,72(sp)
    80002ebe:	6906                	ld	s2,64(sp)
    80002ec0:	79e2                	ld	s3,56(sp)
    80002ec2:	7a42                	ld	s4,48(sp)
    80002ec4:	7aa2                	ld	s5,40(sp)
    80002ec6:	7b02                	ld	s6,32(sp)
    80002ec8:	6be2                	ld	s7,24(sp)
    80002eca:	6125                	addi	sp,sp,96
    80002ecc:	8082                	ret
    for (j = addr - PGSIZE; j >= addr + n; j -= PGSIZE){
    80002ece:	797d                	lui	s2,0xfffff
    80002ed0:	0159093b          	addw	s2,s2,s5
    80002ed4:	777d                	lui	a4,0xfffff
    80002ed6:	fef740e3          	blt	a4,a5,80002eb6 <sys_sbrk+0x9e>
    80002eda:	89ca                	mv	s3,s2
    80002edc:	7b7d                	lui	s6,0xfffff
    80002ede:	7a7d                	lui	s4,0xfffff
      uvmunmap(p->kernelPageTable, j, 1, 0);
    80002ee0:	4681                	li	a3,0
    80002ee2:	4605                	li	a2,1
    80002ee4:	85ce                	mv	a1,s3
    80002ee6:	6ca8                	ld	a0,88(s1)
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	55a080e7          	jalr	1370(ra) # 80001442 <uvmunmap>
    for (j = addr - PGSIZE; j >= addr + n; j -= PGSIZE){
    80002ef0:	012b093b          	addw	s2,s6,s2
    80002ef4:	99d2                	add	s3,s3,s4
    80002ef6:	fac42783          	lw	a5,-84(s0)
    80002efa:	015787bb          	addw	a5,a5,s5
    80002efe:	fef951e3          	bge	s2,a5,80002ee0 <sys_sbrk+0xc8>
    80002f02:	bf55                	j	80002eb6 <sys_sbrk+0x9e>
    return -1;
    80002f04:	557d                	li	a0,-1
    80002f06:	bf4d                	j	80002eb8 <sys_sbrk+0xa0>
    return -1;
    80002f08:	557d                	li	a0,-1
    80002f0a:	b77d                	j	80002eb8 <sys_sbrk+0xa0>

0000000080002f0c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f0c:	7139                	addi	sp,sp,-64
    80002f0e:	fc06                	sd	ra,56(sp)
    80002f10:	f822                	sd	s0,48(sp)
    80002f12:	f426                	sd	s1,40(sp)
    80002f14:	f04a                	sd	s2,32(sp)
    80002f16:	ec4e                	sd	s3,24(sp)
    80002f18:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f1a:	fcc40593          	addi	a1,s0,-52
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	d80080e7          	jalr	-640(ra) # 80002ca0 <argint>
    return -1;
    80002f28:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f2a:	06054563          	bltz	a0,80002f94 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f2e:	00015517          	auipc	a0,0x15
    80002f32:	a3a50513          	addi	a0,a0,-1478 # 80017968 <tickslock>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	cda080e7          	jalr	-806(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002f3e:	00006917          	auipc	s2,0x6
    80002f42:	0e292903          	lw	s2,226(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f46:	fcc42783          	lw	a5,-52(s0)
    80002f4a:	cf85                	beqz	a5,80002f82 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f4c:	00015997          	auipc	s3,0x15
    80002f50:	a1c98993          	addi	s3,s3,-1508 # 80017968 <tickslock>
    80002f54:	00006497          	auipc	s1,0x6
    80002f58:	0cc48493          	addi	s1,s1,204 # 80009020 <ticks>
    if(myproc()->killed){
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	ad4080e7          	jalr	-1324(ra) # 80001a30 <myproc>
    80002f64:	591c                	lw	a5,48(a0)
    80002f66:	ef9d                	bnez	a5,80002fa4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f68:	85ce                	mv	a1,s3
    80002f6a:	8526                	mv	a0,s1
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	486080e7          	jalr	1158(ra) # 800023f2 <sleep>
  while(ticks - ticks0 < n){
    80002f74:	409c                	lw	a5,0(s1)
    80002f76:	412787bb          	subw	a5,a5,s2
    80002f7a:	fcc42703          	lw	a4,-52(s0)
    80002f7e:	fce7efe3          	bltu	a5,a4,80002f5c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f82:	00015517          	auipc	a0,0x15
    80002f86:	9e650513          	addi	a0,a0,-1562 # 80017968 <tickslock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	d3a080e7          	jalr	-710(ra) # 80000cc4 <release>
  return 0;
    80002f92:	4781                	li	a5,0
}
    80002f94:	853e                	mv	a0,a5
    80002f96:	70e2                	ld	ra,56(sp)
    80002f98:	7442                	ld	s0,48(sp)
    80002f9a:	74a2                	ld	s1,40(sp)
    80002f9c:	7902                	ld	s2,32(sp)
    80002f9e:	69e2                	ld	s3,24(sp)
    80002fa0:	6121                	addi	sp,sp,64
    80002fa2:	8082                	ret
      release(&tickslock);
    80002fa4:	00015517          	auipc	a0,0x15
    80002fa8:	9c450513          	addi	a0,a0,-1596 # 80017968 <tickslock>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	d18080e7          	jalr	-744(ra) # 80000cc4 <release>
      return -1;
    80002fb4:	57fd                	li	a5,-1
    80002fb6:	bff9                	j	80002f94 <sys_sleep+0x88>

0000000080002fb8 <sys_kill>:

uint64
sys_kill(void)
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fc0:	fec40593          	addi	a1,s0,-20
    80002fc4:	4501                	li	a0,0
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	cda080e7          	jalr	-806(ra) # 80002ca0 <argint>
    80002fce:	87aa                	mv	a5,a0
    return -1;
    80002fd0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fd2:	0007c863          	bltz	a5,80002fe2 <sys_kill+0x2a>
  return kill(pid);
    80002fd6:	fec42503          	lw	a0,-20(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	608080e7          	jalr	1544(ra) # 800025e2 <kill>
}
    80002fe2:	60e2                	ld	ra,24(sp)
    80002fe4:	6442                	ld	s0,16(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret

0000000080002fea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fea:	1101                	addi	sp,sp,-32
    80002fec:	ec06                	sd	ra,24(sp)
    80002fee:	e822                	sd	s0,16(sp)
    80002ff0:	e426                	sd	s1,8(sp)
    80002ff2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ff4:	00015517          	auipc	a0,0x15
    80002ff8:	97450513          	addi	a0,a0,-1676 # 80017968 <tickslock>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	c14080e7          	jalr	-1004(ra) # 80000c10 <acquire>
  xticks = ticks;
    80003004:	00006497          	auipc	s1,0x6
    80003008:	01c4a483          	lw	s1,28(s1) # 80009020 <ticks>
  release(&tickslock);
    8000300c:	00015517          	auipc	a0,0x15
    80003010:	95c50513          	addi	a0,a0,-1700 # 80017968 <tickslock>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	cb0080e7          	jalr	-848(ra) # 80000cc4 <release>
  return xticks;
    8000301c:	02049513          	slli	a0,s1,0x20
    80003020:	9101                	srli	a0,a0,0x20
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	64a2                	ld	s1,8(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret

000000008000302c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000302c:	7179                	addi	sp,sp,-48
    8000302e:	f406                	sd	ra,40(sp)
    80003030:	f022                	sd	s0,32(sp)
    80003032:	ec26                	sd	s1,24(sp)
    80003034:	e84a                	sd	s2,16(sp)
    80003036:	e44e                	sd	s3,8(sp)
    80003038:	e052                	sd	s4,0(sp)
    8000303a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000303c:	00005597          	auipc	a1,0x5
    80003040:	4fc58593          	addi	a1,a1,1276 # 80008538 <syscalls+0xb0>
    80003044:	00015517          	auipc	a0,0x15
    80003048:	93c50513          	addi	a0,a0,-1732 # 80017980 <bcache>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	b34080e7          	jalr	-1228(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003054:	0001d797          	auipc	a5,0x1d
    80003058:	92c78793          	addi	a5,a5,-1748 # 8001f980 <bcache+0x8000>
    8000305c:	0001d717          	auipc	a4,0x1d
    80003060:	b8c70713          	addi	a4,a4,-1140 # 8001fbe8 <bcache+0x8268>
    80003064:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003068:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306c:	00015497          	auipc	s1,0x15
    80003070:	92c48493          	addi	s1,s1,-1748 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003074:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003076:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003078:	00005a17          	auipc	s4,0x5
    8000307c:	4c8a0a13          	addi	s4,s4,1224 # 80008540 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003080:	2b893783          	ld	a5,696(s2)
    80003084:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003086:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000308a:	85d2                	mv	a1,s4
    8000308c:	01048513          	addi	a0,s1,16
    80003090:	00001097          	auipc	ra,0x1
    80003094:	4ac080e7          	jalr	1196(ra) # 8000453c <initsleeplock>
    bcache.head.next->prev = b;
    80003098:	2b893783          	ld	a5,696(s2)
    8000309c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000309e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a2:	45848493          	addi	s1,s1,1112
    800030a6:	fd349de3          	bne	s1,s3,80003080 <binit+0x54>
  }
}
    800030aa:	70a2                	ld	ra,40(sp)
    800030ac:	7402                	ld	s0,32(sp)
    800030ae:	64e2                	ld	s1,24(sp)
    800030b0:	6942                	ld	s2,16(sp)
    800030b2:	69a2                	ld	s3,8(sp)
    800030b4:	6a02                	ld	s4,0(sp)
    800030b6:	6145                	addi	sp,sp,48
    800030b8:	8082                	ret

00000000800030ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030ba:	7179                	addi	sp,sp,-48
    800030bc:	f406                	sd	ra,40(sp)
    800030be:	f022                	sd	s0,32(sp)
    800030c0:	ec26                	sd	s1,24(sp)
    800030c2:	e84a                	sd	s2,16(sp)
    800030c4:	e44e                	sd	s3,8(sp)
    800030c6:	1800                	addi	s0,sp,48
    800030c8:	89aa                	mv	s3,a0
    800030ca:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030cc:	00015517          	auipc	a0,0x15
    800030d0:	8b450513          	addi	a0,a0,-1868 # 80017980 <bcache>
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	b3c080e7          	jalr	-1220(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030dc:	0001d497          	auipc	s1,0x1d
    800030e0:	b5c4b483          	ld	s1,-1188(s1) # 8001fc38 <bcache+0x82b8>
    800030e4:	0001d797          	auipc	a5,0x1d
    800030e8:	b0478793          	addi	a5,a5,-1276 # 8001fbe8 <bcache+0x8268>
    800030ec:	02f48f63          	beq	s1,a5,8000312a <bread+0x70>
    800030f0:	873e                	mv	a4,a5
    800030f2:	a021                	j	800030fa <bread+0x40>
    800030f4:	68a4                	ld	s1,80(s1)
    800030f6:	02e48a63          	beq	s1,a4,8000312a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030fa:	449c                	lw	a5,8(s1)
    800030fc:	ff379ce3          	bne	a5,s3,800030f4 <bread+0x3a>
    80003100:	44dc                	lw	a5,12(s1)
    80003102:	ff2799e3          	bne	a5,s2,800030f4 <bread+0x3a>
      b->refcnt++;
    80003106:	40bc                	lw	a5,64(s1)
    80003108:	2785                	addiw	a5,a5,1
    8000310a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000310c:	00015517          	auipc	a0,0x15
    80003110:	87450513          	addi	a0,a0,-1932 # 80017980 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	bb0080e7          	jalr	-1104(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000311c:	01048513          	addi	a0,s1,16
    80003120:	00001097          	auipc	ra,0x1
    80003124:	456080e7          	jalr	1110(ra) # 80004576 <acquiresleep>
      return b;
    80003128:	a8b9                	j	80003186 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312a:	0001d497          	auipc	s1,0x1d
    8000312e:	b064b483          	ld	s1,-1274(s1) # 8001fc30 <bcache+0x82b0>
    80003132:	0001d797          	auipc	a5,0x1d
    80003136:	ab678793          	addi	a5,a5,-1354 # 8001fbe8 <bcache+0x8268>
    8000313a:	00f48863          	beq	s1,a5,8000314a <bread+0x90>
    8000313e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003140:	40bc                	lw	a5,64(s1)
    80003142:	cf81                	beqz	a5,8000315a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003144:	64a4                	ld	s1,72(s1)
    80003146:	fee49de3          	bne	s1,a4,80003140 <bread+0x86>
  panic("bget: no buffers");
    8000314a:	00005517          	auipc	a0,0x5
    8000314e:	3fe50513          	addi	a0,a0,1022 # 80008548 <syscalls+0xc0>
    80003152:	ffffd097          	auipc	ra,0xffffd
    80003156:	3f6080e7          	jalr	1014(ra) # 80000548 <panic>
      b->dev = dev;
    8000315a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000315e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003162:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003166:	4785                	li	a5,1
    80003168:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000316a:	00015517          	auipc	a0,0x15
    8000316e:	81650513          	addi	a0,a0,-2026 # 80017980 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	b52080e7          	jalr	-1198(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000317a:	01048513          	addi	a0,s1,16
    8000317e:	00001097          	auipc	ra,0x1
    80003182:	3f8080e7          	jalr	1016(ra) # 80004576 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003186:	409c                	lw	a5,0(s1)
    80003188:	cb89                	beqz	a5,8000319a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000318a:	8526                	mv	a0,s1
    8000318c:	70a2                	ld	ra,40(sp)
    8000318e:	7402                	ld	s0,32(sp)
    80003190:	64e2                	ld	s1,24(sp)
    80003192:	6942                	ld	s2,16(sp)
    80003194:	69a2                	ld	s3,8(sp)
    80003196:	6145                	addi	sp,sp,48
    80003198:	8082                	ret
    virtio_disk_rw(b, 0);
    8000319a:	4581                	li	a1,0
    8000319c:	8526                	mv	a0,s1
    8000319e:	00003097          	auipc	ra,0x3
    800031a2:	f9e080e7          	jalr	-98(ra) # 8000613c <virtio_disk_rw>
    b->valid = 1;
    800031a6:	4785                	li	a5,1
    800031a8:	c09c                	sw	a5,0(s1)
  return b;
    800031aa:	b7c5                	j	8000318a <bread+0xd0>

00000000800031ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b8:	0541                	addi	a0,a0,16
    800031ba:	00001097          	auipc	ra,0x1
    800031be:	456080e7          	jalr	1110(ra) # 80004610 <holdingsleep>
    800031c2:	cd01                	beqz	a0,800031da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031c4:	4585                	li	a1,1
    800031c6:	8526                	mv	a0,s1
    800031c8:	00003097          	auipc	ra,0x3
    800031cc:	f74080e7          	jalr	-140(ra) # 8000613c <virtio_disk_rw>
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret
    panic("bwrite");
    800031da:	00005517          	auipc	a0,0x5
    800031de:	38650513          	addi	a0,a0,902 # 80008560 <syscalls+0xd8>
    800031e2:	ffffd097          	auipc	ra,0xffffd
    800031e6:	366080e7          	jalr	870(ra) # 80000548 <panic>

00000000800031ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	e04a                	sd	s2,0(sp)
    800031f4:	1000                	addi	s0,sp,32
    800031f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f8:	01050913          	addi	s2,a0,16
    800031fc:	854a                	mv	a0,s2
    800031fe:	00001097          	auipc	ra,0x1
    80003202:	412080e7          	jalr	1042(ra) # 80004610 <holdingsleep>
    80003206:	c92d                	beqz	a0,80003278 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003208:	854a                	mv	a0,s2
    8000320a:	00001097          	auipc	ra,0x1
    8000320e:	3c2080e7          	jalr	962(ra) # 800045cc <releasesleep>

  acquire(&bcache.lock);
    80003212:	00014517          	auipc	a0,0x14
    80003216:	76e50513          	addi	a0,a0,1902 # 80017980 <bcache>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	9f6080e7          	jalr	-1546(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003222:	40bc                	lw	a5,64(s1)
    80003224:	37fd                	addiw	a5,a5,-1
    80003226:	0007871b          	sext.w	a4,a5
    8000322a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000322c:	eb05                	bnez	a4,8000325c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000322e:	68bc                	ld	a5,80(s1)
    80003230:	64b8                	ld	a4,72(s1)
    80003232:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003234:	64bc                	ld	a5,72(s1)
    80003236:	68b8                	ld	a4,80(s1)
    80003238:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000323a:	0001c797          	auipc	a5,0x1c
    8000323e:	74678793          	addi	a5,a5,1862 # 8001f980 <bcache+0x8000>
    80003242:	2b87b703          	ld	a4,696(a5)
    80003246:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003248:	0001d717          	auipc	a4,0x1d
    8000324c:	9a070713          	addi	a4,a4,-1632 # 8001fbe8 <bcache+0x8268>
    80003250:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003252:	2b87b703          	ld	a4,696(a5)
    80003256:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003258:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000325c:	00014517          	auipc	a0,0x14
    80003260:	72450513          	addi	a0,a0,1828 # 80017980 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	a60080e7          	jalr	-1440(ra) # 80000cc4 <release>
}
    8000326c:	60e2                	ld	ra,24(sp)
    8000326e:	6442                	ld	s0,16(sp)
    80003270:	64a2                	ld	s1,8(sp)
    80003272:	6902                	ld	s2,0(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret
    panic("brelse");
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	2f050513          	addi	a0,a0,752 # 80008568 <syscalls+0xe0>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	2c8080e7          	jalr	712(ra) # 80000548 <panic>

0000000080003288 <bpin>:

void
bpin(struct buf *b) {
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	e426                	sd	s1,8(sp)
    80003290:	1000                	addi	s0,sp,32
    80003292:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003294:	00014517          	auipc	a0,0x14
    80003298:	6ec50513          	addi	a0,a0,1772 # 80017980 <bcache>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	974080e7          	jalr	-1676(ra) # 80000c10 <acquire>
  b->refcnt++;
    800032a4:	40bc                	lw	a5,64(s1)
    800032a6:	2785                	addiw	a5,a5,1
    800032a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032aa:	00014517          	auipc	a0,0x14
    800032ae:	6d650513          	addi	a0,a0,1750 # 80017980 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	a12080e7          	jalr	-1518(ra) # 80000cc4 <release>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret

00000000800032c4 <bunpin>:

void
bunpin(struct buf *b) {
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d0:	00014517          	auipc	a0,0x14
    800032d4:	6b050513          	addi	a0,a0,1712 # 80017980 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	938080e7          	jalr	-1736(ra) # 80000c10 <acquire>
  b->refcnt--;
    800032e0:	40bc                	lw	a5,64(s1)
    800032e2:	37fd                	addiw	a5,a5,-1
    800032e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	69a50513          	addi	a0,a0,1690 # 80017980 <bcache>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	9d6080e7          	jalr	-1578(ra) # 80000cc4 <release>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret

0000000080003300 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003300:	1101                	addi	sp,sp,-32
    80003302:	ec06                	sd	ra,24(sp)
    80003304:	e822                	sd	s0,16(sp)
    80003306:	e426                	sd	s1,8(sp)
    80003308:	e04a                	sd	s2,0(sp)
    8000330a:	1000                	addi	s0,sp,32
    8000330c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000330e:	00d5d59b          	srliw	a1,a1,0xd
    80003312:	0001d797          	auipc	a5,0x1d
    80003316:	d4a7a783          	lw	a5,-694(a5) # 8002005c <sb+0x1c>
    8000331a:	9dbd                	addw	a1,a1,a5
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	d9e080e7          	jalr	-610(ra) # 800030ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003324:	0074f713          	andi	a4,s1,7
    80003328:	4785                	li	a5,1
    8000332a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000332e:	14ce                	slli	s1,s1,0x33
    80003330:	90d9                	srli	s1,s1,0x36
    80003332:	00950733          	add	a4,a0,s1
    80003336:	05874703          	lbu	a4,88(a4)
    8000333a:	00e7f6b3          	and	a3,a5,a4
    8000333e:	c69d                	beqz	a3,8000336c <bfree+0x6c>
    80003340:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003342:	94aa                	add	s1,s1,a0
    80003344:	fff7c793          	not	a5,a5
    80003348:	8ff9                	and	a5,a5,a4
    8000334a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	100080e7          	jalr	256(ra) # 8000444e <log_write>
  brelse(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	e92080e7          	jalr	-366(ra) # 800031ea <brelse>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6902                	ld	s2,0(sp)
    80003368:	6105                	addi	sp,sp,32
    8000336a:	8082                	ret
    panic("freeing free block");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	20450513          	addi	a0,a0,516 # 80008570 <syscalls+0xe8>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1d4080e7          	jalr	468(ra) # 80000548 <panic>

000000008000337c <balloc>:
{
    8000337c:	711d                	addi	sp,sp,-96
    8000337e:	ec86                	sd	ra,88(sp)
    80003380:	e8a2                	sd	s0,80(sp)
    80003382:	e4a6                	sd	s1,72(sp)
    80003384:	e0ca                	sd	s2,64(sp)
    80003386:	fc4e                	sd	s3,56(sp)
    80003388:	f852                	sd	s4,48(sp)
    8000338a:	f456                	sd	s5,40(sp)
    8000338c:	f05a                	sd	s6,32(sp)
    8000338e:	ec5e                	sd	s7,24(sp)
    80003390:	e862                	sd	s8,16(sp)
    80003392:	e466                	sd	s9,8(sp)
    80003394:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003396:	0001d797          	auipc	a5,0x1d
    8000339a:	cae7a783          	lw	a5,-850(a5) # 80020044 <sb+0x4>
    8000339e:	cbd1                	beqz	a5,80003432 <balloc+0xb6>
    800033a0:	8baa                	mv	s7,a0
    800033a2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a4:	0001db17          	auipc	s6,0x1d
    800033a8:	c9cb0b13          	addi	s6,s6,-868 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b2:	6c89                	lui	s9,0x2
    800033b4:	a831                	j	800033d0 <balloc+0x54>
    brelse(bp);
    800033b6:	854a                	mv	a0,s2
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	e32080e7          	jalr	-462(ra) # 800031ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033c0:	015c87bb          	addw	a5,s9,s5
    800033c4:	00078a9b          	sext.w	s5,a5
    800033c8:	004b2703          	lw	a4,4(s6)
    800033cc:	06eaf363          	bgeu	s5,a4,80003432 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033d0:	41fad79b          	sraiw	a5,s5,0x1f
    800033d4:	0137d79b          	srliw	a5,a5,0x13
    800033d8:	015787bb          	addw	a5,a5,s5
    800033dc:	40d7d79b          	sraiw	a5,a5,0xd
    800033e0:	01cb2583          	lw	a1,28(s6)
    800033e4:	9dbd                	addw	a1,a1,a5
    800033e6:	855e                	mv	a0,s7
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	cd2080e7          	jalr	-814(ra) # 800030ba <bread>
    800033f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	004b2503          	lw	a0,4(s6)
    800033f6:	000a849b          	sext.w	s1,s5
    800033fa:	8662                	mv	a2,s8
    800033fc:	faa4fde3          	bgeu	s1,a0,800033b6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003400:	41f6579b          	sraiw	a5,a2,0x1f
    80003404:	01d7d69b          	srliw	a3,a5,0x1d
    80003408:	00c6873b          	addw	a4,a3,a2
    8000340c:	00777793          	andi	a5,a4,7
    80003410:	9f95                	subw	a5,a5,a3
    80003412:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003416:	4037571b          	sraiw	a4,a4,0x3
    8000341a:	00e906b3          	add	a3,s2,a4
    8000341e:	0586c683          	lbu	a3,88(a3)
    80003422:	00d7f5b3          	and	a1,a5,a3
    80003426:	cd91                	beqz	a1,80003442 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003428:	2605                	addiw	a2,a2,1
    8000342a:	2485                	addiw	s1,s1,1
    8000342c:	fd4618e3          	bne	a2,s4,800033fc <balloc+0x80>
    80003430:	b759                	j	800033b6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003432:	00005517          	auipc	a0,0x5
    80003436:	15650513          	addi	a0,a0,342 # 80008588 <syscalls+0x100>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	10e080e7          	jalr	270(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003442:	974a                	add	a4,a4,s2
    80003444:	8fd5                	or	a5,a5,a3
    80003446:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000344a:	854a                	mv	a0,s2
    8000344c:	00001097          	auipc	ra,0x1
    80003450:	002080e7          	jalr	2(ra) # 8000444e <log_write>
        brelse(bp);
    80003454:	854a                	mv	a0,s2
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	d94080e7          	jalr	-620(ra) # 800031ea <brelse>
  bp = bread(dev, bno);
    8000345e:	85a6                	mv	a1,s1
    80003460:	855e                	mv	a0,s7
    80003462:	00000097          	auipc	ra,0x0
    80003466:	c58080e7          	jalr	-936(ra) # 800030ba <bread>
    8000346a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000346c:	40000613          	li	a2,1024
    80003470:	4581                	li	a1,0
    80003472:	05850513          	addi	a0,a0,88
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	896080e7          	jalr	-1898(ra) # 80000d0c <memset>
  log_write(bp);
    8000347e:	854a                	mv	a0,s2
    80003480:	00001097          	auipc	ra,0x1
    80003484:	fce080e7          	jalr	-50(ra) # 8000444e <log_write>
  brelse(bp);
    80003488:	854a                	mv	a0,s2
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	d60080e7          	jalr	-672(ra) # 800031ea <brelse>
}
    80003492:	8526                	mv	a0,s1
    80003494:	60e6                	ld	ra,88(sp)
    80003496:	6446                	ld	s0,80(sp)
    80003498:	64a6                	ld	s1,72(sp)
    8000349a:	6906                	ld	s2,64(sp)
    8000349c:	79e2                	ld	s3,56(sp)
    8000349e:	7a42                	ld	s4,48(sp)
    800034a0:	7aa2                	ld	s5,40(sp)
    800034a2:	7b02                	ld	s6,32(sp)
    800034a4:	6be2                	ld	s7,24(sp)
    800034a6:	6c42                	ld	s8,16(sp)
    800034a8:	6ca2                	ld	s9,8(sp)
    800034aa:	6125                	addi	sp,sp,96
    800034ac:	8082                	ret

00000000800034ae <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	e052                	sd	s4,0(sp)
    800034bc:	1800                	addi	s0,sp,48
    800034be:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034c0:	47ad                	li	a5,11
    800034c2:	04b7fe63          	bgeu	a5,a1,8000351e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034c6:	ff45849b          	addiw	s1,a1,-12
    800034ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034ce:	0ff00793          	li	a5,255
    800034d2:	0ae7e363          	bltu	a5,a4,80003578 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034d6:	08052583          	lw	a1,128(a0)
    800034da:	c5ad                	beqz	a1,80003544 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034dc:	00092503          	lw	a0,0(s2)
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	bda080e7          	jalr	-1062(ra) # 800030ba <bread>
    800034e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ee:	02049593          	slli	a1,s1,0x20
    800034f2:	9181                	srli	a1,a1,0x20
    800034f4:	058a                	slli	a1,a1,0x2
    800034f6:	00b784b3          	add	s1,a5,a1
    800034fa:	0004a983          	lw	s3,0(s1)
    800034fe:	04098d63          	beqz	s3,80003558 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003502:	8552                	mv	a0,s4
    80003504:	00000097          	auipc	ra,0x0
    80003508:	ce6080e7          	jalr	-794(ra) # 800031ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000350c:	854e                	mv	a0,s3
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6942                	ld	s2,16(sp)
    80003516:	69a2                	ld	s3,8(sp)
    80003518:	6a02                	ld	s4,0(sp)
    8000351a:	6145                	addi	sp,sp,48
    8000351c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000351e:	02059493          	slli	s1,a1,0x20
    80003522:	9081                	srli	s1,s1,0x20
    80003524:	048a                	slli	s1,s1,0x2
    80003526:	94aa                	add	s1,s1,a0
    80003528:	0504a983          	lw	s3,80(s1)
    8000352c:	fe0990e3          	bnez	s3,8000350c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003530:	4108                	lw	a0,0(a0)
    80003532:	00000097          	auipc	ra,0x0
    80003536:	e4a080e7          	jalr	-438(ra) # 8000337c <balloc>
    8000353a:	0005099b          	sext.w	s3,a0
    8000353e:	0534a823          	sw	s3,80(s1)
    80003542:	b7e9                	j	8000350c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e36080e7          	jalr	-458(ra) # 8000337c <balloc>
    8000354e:	0005059b          	sext.w	a1,a0
    80003552:	08b92023          	sw	a1,128(s2)
    80003556:	b759                	j	800034dc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003558:	00092503          	lw	a0,0(s2)
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	e20080e7          	jalr	-480(ra) # 8000337c <balloc>
    80003564:	0005099b          	sext.w	s3,a0
    80003568:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000356c:	8552                	mv	a0,s4
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	ee0080e7          	jalr	-288(ra) # 8000444e <log_write>
    80003576:	b771                	j	80003502 <bmap+0x54>
  panic("bmap: out of range");
    80003578:	00005517          	auipc	a0,0x5
    8000357c:	02850513          	addi	a0,a0,40 # 800085a0 <syscalls+0x118>
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	fc8080e7          	jalr	-56(ra) # 80000548 <panic>

0000000080003588 <iget>:
{
    80003588:	7179                	addi	sp,sp,-48
    8000358a:	f406                	sd	ra,40(sp)
    8000358c:	f022                	sd	s0,32(sp)
    8000358e:	ec26                	sd	s1,24(sp)
    80003590:	e84a                	sd	s2,16(sp)
    80003592:	e44e                	sd	s3,8(sp)
    80003594:	e052                	sd	s4,0(sp)
    80003596:	1800                	addi	s0,sp,48
    80003598:	89aa                	mv	s3,a0
    8000359a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000359c:	0001d517          	auipc	a0,0x1d
    800035a0:	ac450513          	addi	a0,a0,-1340 # 80020060 <icache>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	66c080e7          	jalr	1644(ra) # 80000c10 <acquire>
  empty = 0;
    800035ac:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035ae:	0001d497          	auipc	s1,0x1d
    800035b2:	aca48493          	addi	s1,s1,-1334 # 80020078 <icache+0x18>
    800035b6:	0001e697          	auipc	a3,0x1e
    800035ba:	55268693          	addi	a3,a3,1362 # 80021b08 <log>
    800035be:	a039                	j	800035cc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c0:	02090b63          	beqz	s2,800035f6 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035c4:	08848493          	addi	s1,s1,136
    800035c8:	02d48a63          	beq	s1,a3,800035fc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035cc:	449c                	lw	a5,8(s1)
    800035ce:	fef059e3          	blez	a5,800035c0 <iget+0x38>
    800035d2:	4098                	lw	a4,0(s1)
    800035d4:	ff3716e3          	bne	a4,s3,800035c0 <iget+0x38>
    800035d8:	40d8                	lw	a4,4(s1)
    800035da:	ff4713e3          	bne	a4,s4,800035c0 <iget+0x38>
      ip->ref++;
    800035de:	2785                	addiw	a5,a5,1
    800035e0:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800035e2:	0001d517          	auipc	a0,0x1d
    800035e6:	a7e50513          	addi	a0,a0,-1410 # 80020060 <icache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	6da080e7          	jalr	1754(ra) # 80000cc4 <release>
      return ip;
    800035f2:	8926                	mv	s2,s1
    800035f4:	a03d                	j	80003622 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035f6:	f7f9                	bnez	a5,800035c4 <iget+0x3c>
    800035f8:	8926                	mv	s2,s1
    800035fa:	b7e9                	j	800035c4 <iget+0x3c>
  if(empty == 0)
    800035fc:	02090c63          	beqz	s2,80003634 <iget+0xac>
  ip->dev = dev;
    80003600:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003604:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003608:	4785                	li	a5,1
    8000360a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000360e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003612:	0001d517          	auipc	a0,0x1d
    80003616:	a4e50513          	addi	a0,a0,-1458 # 80020060 <icache>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	6aa080e7          	jalr	1706(ra) # 80000cc4 <release>
}
    80003622:	854a                	mv	a0,s2
    80003624:	70a2                	ld	ra,40(sp)
    80003626:	7402                	ld	s0,32(sp)
    80003628:	64e2                	ld	s1,24(sp)
    8000362a:	6942                	ld	s2,16(sp)
    8000362c:	69a2                	ld	s3,8(sp)
    8000362e:	6a02                	ld	s4,0(sp)
    80003630:	6145                	addi	sp,sp,48
    80003632:	8082                	ret
    panic("iget: no inodes");
    80003634:	00005517          	auipc	a0,0x5
    80003638:	f8450513          	addi	a0,a0,-124 # 800085b8 <syscalls+0x130>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	f0c080e7          	jalr	-244(ra) # 80000548 <panic>

0000000080003644 <fsinit>:
fsinit(int dev) {
    80003644:	7179                	addi	sp,sp,-48
    80003646:	f406                	sd	ra,40(sp)
    80003648:	f022                	sd	s0,32(sp)
    8000364a:	ec26                	sd	s1,24(sp)
    8000364c:	e84a                	sd	s2,16(sp)
    8000364e:	e44e                	sd	s3,8(sp)
    80003650:	1800                	addi	s0,sp,48
    80003652:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003654:	4585                	li	a1,1
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	a64080e7          	jalr	-1436(ra) # 800030ba <bread>
    8000365e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003660:	0001d997          	auipc	s3,0x1d
    80003664:	9e098993          	addi	s3,s3,-1568 # 80020040 <sb>
    80003668:	02000613          	li	a2,32
    8000366c:	05850593          	addi	a1,a0,88
    80003670:	854e                	mv	a0,s3
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	6fa080e7          	jalr	1786(ra) # 80000d6c <memmove>
  brelse(bp);
    8000367a:	8526                	mv	a0,s1
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	b6e080e7          	jalr	-1170(ra) # 800031ea <brelse>
  if(sb.magic != FSMAGIC)
    80003684:	0009a703          	lw	a4,0(s3)
    80003688:	102037b7          	lui	a5,0x10203
    8000368c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003690:	02f71263          	bne	a4,a5,800036b4 <fsinit+0x70>
  initlog(dev, &sb);
    80003694:	0001d597          	auipc	a1,0x1d
    80003698:	9ac58593          	addi	a1,a1,-1620 # 80020040 <sb>
    8000369c:	854a                	mv	a0,s2
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	b38080e7          	jalr	-1224(ra) # 800041d6 <initlog>
}
    800036a6:	70a2                	ld	ra,40(sp)
    800036a8:	7402                	ld	s0,32(sp)
    800036aa:	64e2                	ld	s1,24(sp)
    800036ac:	6942                	ld	s2,16(sp)
    800036ae:	69a2                	ld	s3,8(sp)
    800036b0:	6145                	addi	sp,sp,48
    800036b2:	8082                	ret
    panic("invalid file system");
    800036b4:	00005517          	auipc	a0,0x5
    800036b8:	f1450513          	addi	a0,a0,-236 # 800085c8 <syscalls+0x140>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	e8c080e7          	jalr	-372(ra) # 80000548 <panic>

00000000800036c4 <iinit>:
{
    800036c4:	7179                	addi	sp,sp,-48
    800036c6:	f406                	sd	ra,40(sp)
    800036c8:	f022                	sd	s0,32(sp)
    800036ca:	ec26                	sd	s1,24(sp)
    800036cc:	e84a                	sd	s2,16(sp)
    800036ce:	e44e                	sd	s3,8(sp)
    800036d0:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036d2:	00005597          	auipc	a1,0x5
    800036d6:	f0e58593          	addi	a1,a1,-242 # 800085e0 <syscalls+0x158>
    800036da:	0001d517          	auipc	a0,0x1d
    800036de:	98650513          	addi	a0,a0,-1658 # 80020060 <icache>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	49e080e7          	jalr	1182(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036ea:	0001d497          	auipc	s1,0x1d
    800036ee:	99e48493          	addi	s1,s1,-1634 # 80020088 <icache+0x28>
    800036f2:	0001e997          	auipc	s3,0x1e
    800036f6:	42698993          	addi	s3,s3,1062 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800036fa:	00005917          	auipc	s2,0x5
    800036fe:	eee90913          	addi	s2,s2,-274 # 800085e8 <syscalls+0x160>
    80003702:	85ca                	mv	a1,s2
    80003704:	8526                	mv	a0,s1
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	e36080e7          	jalr	-458(ra) # 8000453c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000370e:	08848493          	addi	s1,s1,136
    80003712:	ff3498e3          	bne	s1,s3,80003702 <iinit+0x3e>
}
    80003716:	70a2                	ld	ra,40(sp)
    80003718:	7402                	ld	s0,32(sp)
    8000371a:	64e2                	ld	s1,24(sp)
    8000371c:	6942                	ld	s2,16(sp)
    8000371e:	69a2                	ld	s3,8(sp)
    80003720:	6145                	addi	sp,sp,48
    80003722:	8082                	ret

0000000080003724 <ialloc>:
{
    80003724:	715d                	addi	sp,sp,-80
    80003726:	e486                	sd	ra,72(sp)
    80003728:	e0a2                	sd	s0,64(sp)
    8000372a:	fc26                	sd	s1,56(sp)
    8000372c:	f84a                	sd	s2,48(sp)
    8000372e:	f44e                	sd	s3,40(sp)
    80003730:	f052                	sd	s4,32(sp)
    80003732:	ec56                	sd	s5,24(sp)
    80003734:	e85a                	sd	s6,16(sp)
    80003736:	e45e                	sd	s7,8(sp)
    80003738:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000373a:	0001d717          	auipc	a4,0x1d
    8000373e:	91272703          	lw	a4,-1774(a4) # 8002004c <sb+0xc>
    80003742:	4785                	li	a5,1
    80003744:	04e7fa63          	bgeu	a5,a4,80003798 <ialloc+0x74>
    80003748:	8aaa                	mv	s5,a0
    8000374a:	8bae                	mv	s7,a1
    8000374c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000374e:	0001da17          	auipc	s4,0x1d
    80003752:	8f2a0a13          	addi	s4,s4,-1806 # 80020040 <sb>
    80003756:	00048b1b          	sext.w	s6,s1
    8000375a:	0044d593          	srli	a1,s1,0x4
    8000375e:	018a2783          	lw	a5,24(s4)
    80003762:	9dbd                	addw	a1,a1,a5
    80003764:	8556                	mv	a0,s5
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	954080e7          	jalr	-1708(ra) # 800030ba <bread>
    8000376e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003770:	05850993          	addi	s3,a0,88
    80003774:	00f4f793          	andi	a5,s1,15
    80003778:	079a                	slli	a5,a5,0x6
    8000377a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000377c:	00099783          	lh	a5,0(s3)
    80003780:	c785                	beqz	a5,800037a8 <ialloc+0x84>
    brelse(bp);
    80003782:	00000097          	auipc	ra,0x0
    80003786:	a68080e7          	jalr	-1432(ra) # 800031ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000378a:	0485                	addi	s1,s1,1
    8000378c:	00ca2703          	lw	a4,12(s4)
    80003790:	0004879b          	sext.w	a5,s1
    80003794:	fce7e1e3          	bltu	a5,a4,80003756 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	e5850513          	addi	a0,a0,-424 # 800085f0 <syscalls+0x168>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	da8080e7          	jalr	-600(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800037a8:	04000613          	li	a2,64
    800037ac:	4581                	li	a1,0
    800037ae:	854e                	mv	a0,s3
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	55c080e7          	jalr	1372(ra) # 80000d0c <memset>
      dip->type = type;
    800037b8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037bc:	854a                	mv	a0,s2
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	c90080e7          	jalr	-880(ra) # 8000444e <log_write>
      brelse(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	a22080e7          	jalr	-1502(ra) # 800031ea <brelse>
      return iget(dev, inum);
    800037d0:	85da                	mv	a1,s6
    800037d2:	8556                	mv	a0,s5
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	db4080e7          	jalr	-588(ra) # 80003588 <iget>
}
    800037dc:	60a6                	ld	ra,72(sp)
    800037de:	6406                	ld	s0,64(sp)
    800037e0:	74e2                	ld	s1,56(sp)
    800037e2:	7942                	ld	s2,48(sp)
    800037e4:	79a2                	ld	s3,40(sp)
    800037e6:	7a02                	ld	s4,32(sp)
    800037e8:	6ae2                	ld	s5,24(sp)
    800037ea:	6b42                	ld	s6,16(sp)
    800037ec:	6ba2                	ld	s7,8(sp)
    800037ee:	6161                	addi	sp,sp,80
    800037f0:	8082                	ret

00000000800037f2 <iupdate>:
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	e04a                	sd	s2,0(sp)
    800037fc:	1000                	addi	s0,sp,32
    800037fe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003800:	415c                	lw	a5,4(a0)
    80003802:	0047d79b          	srliw	a5,a5,0x4
    80003806:	0001d597          	auipc	a1,0x1d
    8000380a:	8525a583          	lw	a1,-1966(a1) # 80020058 <sb+0x18>
    8000380e:	9dbd                	addw	a1,a1,a5
    80003810:	4108                	lw	a0,0(a0)
    80003812:	00000097          	auipc	ra,0x0
    80003816:	8a8080e7          	jalr	-1880(ra) # 800030ba <bread>
    8000381a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000381c:	05850793          	addi	a5,a0,88
    80003820:	40c8                	lw	a0,4(s1)
    80003822:	893d                	andi	a0,a0,15
    80003824:	051a                	slli	a0,a0,0x6
    80003826:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003828:	04449703          	lh	a4,68(s1)
    8000382c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003830:	04649703          	lh	a4,70(s1)
    80003834:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003838:	04849703          	lh	a4,72(s1)
    8000383c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003840:	04a49703          	lh	a4,74(s1)
    80003844:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003848:	44f8                	lw	a4,76(s1)
    8000384a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000384c:	03400613          	li	a2,52
    80003850:	05048593          	addi	a1,s1,80
    80003854:	0531                	addi	a0,a0,12
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	516080e7          	jalr	1302(ra) # 80000d6c <memmove>
  log_write(bp);
    8000385e:	854a                	mv	a0,s2
    80003860:	00001097          	auipc	ra,0x1
    80003864:	bee080e7          	jalr	-1042(ra) # 8000444e <log_write>
  brelse(bp);
    80003868:	854a                	mv	a0,s2
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	980080e7          	jalr	-1664(ra) # 800031ea <brelse>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6902                	ld	s2,0(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret

000000008000387e <idup>:
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000388a:	0001c517          	auipc	a0,0x1c
    8000388e:	7d650513          	addi	a0,a0,2006 # 80020060 <icache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	37e080e7          	jalr	894(ra) # 80000c10 <acquire>
  ip->ref++;
    8000389a:	449c                	lw	a5,8(s1)
    8000389c:	2785                	addiw	a5,a5,1
    8000389e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038a0:	0001c517          	auipc	a0,0x1c
    800038a4:	7c050513          	addi	a0,a0,1984 # 80020060 <icache>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	41c080e7          	jalr	1052(ra) # 80000cc4 <release>
}
    800038b0:	8526                	mv	a0,s1
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6105                	addi	sp,sp,32
    800038ba:	8082                	ret

00000000800038bc <ilock>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038c8:	c115                	beqz	a0,800038ec <ilock+0x30>
    800038ca:	84aa                	mv	s1,a0
    800038cc:	451c                	lw	a5,8(a0)
    800038ce:	00f05f63          	blez	a5,800038ec <ilock+0x30>
  acquiresleep(&ip->lock);
    800038d2:	0541                	addi	a0,a0,16
    800038d4:	00001097          	auipc	ra,0x1
    800038d8:	ca2080e7          	jalr	-862(ra) # 80004576 <acquiresleep>
  if(ip->valid == 0){
    800038dc:	40bc                	lw	a5,64(s1)
    800038de:	cf99                	beqz	a5,800038fc <ilock+0x40>
}
    800038e0:	60e2                	ld	ra,24(sp)
    800038e2:	6442                	ld	s0,16(sp)
    800038e4:	64a2                	ld	s1,8(sp)
    800038e6:	6902                	ld	s2,0(sp)
    800038e8:	6105                	addi	sp,sp,32
    800038ea:	8082                	ret
    panic("ilock");
    800038ec:	00005517          	auipc	a0,0x5
    800038f0:	d1c50513          	addi	a0,a0,-740 # 80008608 <syscalls+0x180>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	c54080e7          	jalr	-940(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038fc:	40dc                	lw	a5,4(s1)
    800038fe:	0047d79b          	srliw	a5,a5,0x4
    80003902:	0001c597          	auipc	a1,0x1c
    80003906:	7565a583          	lw	a1,1878(a1) # 80020058 <sb+0x18>
    8000390a:	9dbd                	addw	a1,a1,a5
    8000390c:	4088                	lw	a0,0(s1)
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	7ac080e7          	jalr	1964(ra) # 800030ba <bread>
    80003916:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003918:	05850593          	addi	a1,a0,88
    8000391c:	40dc                	lw	a5,4(s1)
    8000391e:	8bbd                	andi	a5,a5,15
    80003920:	079a                	slli	a5,a5,0x6
    80003922:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003924:	00059783          	lh	a5,0(a1)
    80003928:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000392c:	00259783          	lh	a5,2(a1)
    80003930:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003934:	00459783          	lh	a5,4(a1)
    80003938:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000393c:	00659783          	lh	a5,6(a1)
    80003940:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003944:	459c                	lw	a5,8(a1)
    80003946:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003948:	03400613          	li	a2,52
    8000394c:	05b1                	addi	a1,a1,12
    8000394e:	05048513          	addi	a0,s1,80
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	41a080e7          	jalr	1050(ra) # 80000d6c <memmove>
    brelse(bp);
    8000395a:	854a                	mv	a0,s2
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	88e080e7          	jalr	-1906(ra) # 800031ea <brelse>
    ip->valid = 1;
    80003964:	4785                	li	a5,1
    80003966:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003968:	04449783          	lh	a5,68(s1)
    8000396c:	fbb5                	bnez	a5,800038e0 <ilock+0x24>
      panic("ilock: no type");
    8000396e:	00005517          	auipc	a0,0x5
    80003972:	ca250513          	addi	a0,a0,-862 # 80008610 <syscalls+0x188>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	bd2080e7          	jalr	-1070(ra) # 80000548 <panic>

000000008000397e <iunlock>:
{
    8000397e:	1101                	addi	sp,sp,-32
    80003980:	ec06                	sd	ra,24(sp)
    80003982:	e822                	sd	s0,16(sp)
    80003984:	e426                	sd	s1,8(sp)
    80003986:	e04a                	sd	s2,0(sp)
    80003988:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000398a:	c905                	beqz	a0,800039ba <iunlock+0x3c>
    8000398c:	84aa                	mv	s1,a0
    8000398e:	01050913          	addi	s2,a0,16
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	c7c080e7          	jalr	-900(ra) # 80004610 <holdingsleep>
    8000399c:	cd19                	beqz	a0,800039ba <iunlock+0x3c>
    8000399e:	449c                	lw	a5,8(s1)
    800039a0:	00f05d63          	blez	a5,800039ba <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	c26080e7          	jalr	-986(ra) # 800045cc <releasesleep>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6902                	ld	s2,0(sp)
    800039b6:	6105                	addi	sp,sp,32
    800039b8:	8082                	ret
    panic("iunlock");
    800039ba:	00005517          	auipc	a0,0x5
    800039be:	c6650513          	addi	a0,a0,-922 # 80008620 <syscalls+0x198>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	b86080e7          	jalr	-1146(ra) # 80000548 <panic>

00000000800039ca <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ca:	7179                	addi	sp,sp,-48
    800039cc:	f406                	sd	ra,40(sp)
    800039ce:	f022                	sd	s0,32(sp)
    800039d0:	ec26                	sd	s1,24(sp)
    800039d2:	e84a                	sd	s2,16(sp)
    800039d4:	e44e                	sd	s3,8(sp)
    800039d6:	e052                	sd	s4,0(sp)
    800039d8:	1800                	addi	s0,sp,48
    800039da:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039dc:	05050493          	addi	s1,a0,80
    800039e0:	08050913          	addi	s2,a0,128
    800039e4:	a021                	j	800039ec <itrunc+0x22>
    800039e6:	0491                	addi	s1,s1,4
    800039e8:	01248d63          	beq	s1,s2,80003a02 <itrunc+0x38>
    if(ip->addrs[i]){
    800039ec:	408c                	lw	a1,0(s1)
    800039ee:	dde5                	beqz	a1,800039e6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039f0:	0009a503          	lw	a0,0(s3)
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	90c080e7          	jalr	-1780(ra) # 80003300 <bfree>
      ip->addrs[i] = 0;
    800039fc:	0004a023          	sw	zero,0(s1)
    80003a00:	b7dd                	j	800039e6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a02:	0809a583          	lw	a1,128(s3)
    80003a06:	e185                	bnez	a1,80003a26 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a08:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a0c:	854e                	mv	a0,s3
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	de4080e7          	jalr	-540(ra) # 800037f2 <iupdate>
}
    80003a16:	70a2                	ld	ra,40(sp)
    80003a18:	7402                	ld	s0,32(sp)
    80003a1a:	64e2                	ld	s1,24(sp)
    80003a1c:	6942                	ld	s2,16(sp)
    80003a1e:	69a2                	ld	s3,8(sp)
    80003a20:	6a02                	ld	s4,0(sp)
    80003a22:	6145                	addi	sp,sp,48
    80003a24:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	fffff097          	auipc	ra,0xfffff
    80003a2e:	690080e7          	jalr	1680(ra) # 800030ba <bread>
    80003a32:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a34:	05850493          	addi	s1,a0,88
    80003a38:	45850913          	addi	s2,a0,1112
    80003a3c:	a811                	j	80003a50 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a3e:	0009a503          	lw	a0,0(s3)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	8be080e7          	jalr	-1858(ra) # 80003300 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a4a:	0491                	addi	s1,s1,4
    80003a4c:	01248563          	beq	s1,s2,80003a56 <itrunc+0x8c>
      if(a[j])
    80003a50:	408c                	lw	a1,0(s1)
    80003a52:	dde5                	beqz	a1,80003a4a <itrunc+0x80>
    80003a54:	b7ed                	j	80003a3e <itrunc+0x74>
    brelse(bp);
    80003a56:	8552                	mv	a0,s4
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	792080e7          	jalr	1938(ra) # 800031ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a60:	0809a583          	lw	a1,128(s3)
    80003a64:	0009a503          	lw	a0,0(s3)
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	898080e7          	jalr	-1896(ra) # 80003300 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a70:	0809a023          	sw	zero,128(s3)
    80003a74:	bf51                	j	80003a08 <itrunc+0x3e>

0000000080003a76 <iput>:
{
    80003a76:	1101                	addi	sp,sp,-32
    80003a78:	ec06                	sd	ra,24(sp)
    80003a7a:	e822                	sd	s0,16(sp)
    80003a7c:	e426                	sd	s1,8(sp)
    80003a7e:	e04a                	sd	s2,0(sp)
    80003a80:	1000                	addi	s0,sp,32
    80003a82:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a84:	0001c517          	auipc	a0,0x1c
    80003a88:	5dc50513          	addi	a0,a0,1500 # 80020060 <icache>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	184080e7          	jalr	388(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a94:	4498                	lw	a4,8(s1)
    80003a96:	4785                	li	a5,1
    80003a98:	02f70363          	beq	a4,a5,80003abe <iput+0x48>
  ip->ref--;
    80003a9c:	449c                	lw	a5,8(s1)
    80003a9e:	37fd                	addiw	a5,a5,-1
    80003aa0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003aa2:	0001c517          	auipc	a0,0x1c
    80003aa6:	5be50513          	addi	a0,a0,1470 # 80020060 <icache>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	21a080e7          	jalr	538(ra) # 80000cc4 <release>
}
    80003ab2:	60e2                	ld	ra,24(sp)
    80003ab4:	6442                	ld	s0,16(sp)
    80003ab6:	64a2                	ld	s1,8(sp)
    80003ab8:	6902                	ld	s2,0(sp)
    80003aba:	6105                	addi	sp,sp,32
    80003abc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003abe:	40bc                	lw	a5,64(s1)
    80003ac0:	dff1                	beqz	a5,80003a9c <iput+0x26>
    80003ac2:	04a49783          	lh	a5,74(s1)
    80003ac6:	fbf9                	bnez	a5,80003a9c <iput+0x26>
    acquiresleep(&ip->lock);
    80003ac8:	01048913          	addi	s2,s1,16
    80003acc:	854a                	mv	a0,s2
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	aa8080e7          	jalr	-1368(ra) # 80004576 <acquiresleep>
    release(&icache.lock);
    80003ad6:	0001c517          	auipc	a0,0x1c
    80003ada:	58a50513          	addi	a0,a0,1418 # 80020060 <icache>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	1e6080e7          	jalr	486(ra) # 80000cc4 <release>
    itrunc(ip);
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	ee2080e7          	jalr	-286(ra) # 800039ca <itrunc>
    ip->type = 0;
    80003af0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003af4:	8526                	mv	a0,s1
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	cfc080e7          	jalr	-772(ra) # 800037f2 <iupdate>
    ip->valid = 0;
    80003afe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b02:	854a                	mv	a0,s2
    80003b04:	00001097          	auipc	ra,0x1
    80003b08:	ac8080e7          	jalr	-1336(ra) # 800045cc <releasesleep>
    acquire(&icache.lock);
    80003b0c:	0001c517          	auipc	a0,0x1c
    80003b10:	55450513          	addi	a0,a0,1364 # 80020060 <icache>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	0fc080e7          	jalr	252(ra) # 80000c10 <acquire>
    80003b1c:	b741                	j	80003a9c <iput+0x26>

0000000080003b1e <iunlockput>:
{
    80003b1e:	1101                	addi	sp,sp,-32
    80003b20:	ec06                	sd	ra,24(sp)
    80003b22:	e822                	sd	s0,16(sp)
    80003b24:	e426                	sd	s1,8(sp)
    80003b26:	1000                	addi	s0,sp,32
    80003b28:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	e54080e7          	jalr	-428(ra) # 8000397e <iunlock>
  iput(ip);
    80003b32:	8526                	mv	a0,s1
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	f42080e7          	jalr	-190(ra) # 80003a76 <iput>
}
    80003b3c:	60e2                	ld	ra,24(sp)
    80003b3e:	6442                	ld	s0,16(sp)
    80003b40:	64a2                	ld	s1,8(sp)
    80003b42:	6105                	addi	sp,sp,32
    80003b44:	8082                	ret

0000000080003b46 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b46:	1141                	addi	sp,sp,-16
    80003b48:	e422                	sd	s0,8(sp)
    80003b4a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b4c:	411c                	lw	a5,0(a0)
    80003b4e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b50:	415c                	lw	a5,4(a0)
    80003b52:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b54:	04451783          	lh	a5,68(a0)
    80003b58:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b5c:	04a51783          	lh	a5,74(a0)
    80003b60:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b64:	04c56783          	lwu	a5,76(a0)
    80003b68:	e99c                	sd	a5,16(a1)
}
    80003b6a:	6422                	ld	s0,8(sp)
    80003b6c:	0141                	addi	sp,sp,16
    80003b6e:	8082                	ret

0000000080003b70 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b70:	457c                	lw	a5,76(a0)
    80003b72:	0ed7e863          	bltu	a5,a3,80003c62 <readi+0xf2>
{
    80003b76:	7159                	addi	sp,sp,-112
    80003b78:	f486                	sd	ra,104(sp)
    80003b7a:	f0a2                	sd	s0,96(sp)
    80003b7c:	eca6                	sd	s1,88(sp)
    80003b7e:	e8ca                	sd	s2,80(sp)
    80003b80:	e4ce                	sd	s3,72(sp)
    80003b82:	e0d2                	sd	s4,64(sp)
    80003b84:	fc56                	sd	s5,56(sp)
    80003b86:	f85a                	sd	s6,48(sp)
    80003b88:	f45e                	sd	s7,40(sp)
    80003b8a:	f062                	sd	s8,32(sp)
    80003b8c:	ec66                	sd	s9,24(sp)
    80003b8e:	e86a                	sd	s10,16(sp)
    80003b90:	e46e                	sd	s11,8(sp)
    80003b92:	1880                	addi	s0,sp,112
    80003b94:	8baa                	mv	s7,a0
    80003b96:	8c2e                	mv	s8,a1
    80003b98:	8ab2                	mv	s5,a2
    80003b9a:	84b6                	mv	s1,a3
    80003b9c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b9e:	9f35                	addw	a4,a4,a3
    return 0;
    80003ba0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ba2:	08d76f63          	bltu	a4,a3,80003c40 <readi+0xd0>
  if(off + n > ip->size)
    80003ba6:	00e7f463          	bgeu	a5,a4,80003bae <readi+0x3e>
    n = ip->size - off;
    80003baa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bae:	0a0b0863          	beqz	s6,80003c5e <readi+0xee>
    80003bb2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bb8:	5cfd                	li	s9,-1
    80003bba:	a82d                	j	80003bf4 <readi+0x84>
    80003bbc:	020a1d93          	slli	s11,s4,0x20
    80003bc0:	020ddd93          	srli	s11,s11,0x20
    80003bc4:	05890613          	addi	a2,s2,88
    80003bc8:	86ee                	mv	a3,s11
    80003bca:	963a                	add	a2,a2,a4
    80003bcc:	85d6                	mv	a1,s5
    80003bce:	8562                	mv	a0,s8
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	a84080e7          	jalr	-1404(ra) # 80002654 <either_copyout>
    80003bd8:	05950d63          	beq	a0,s9,80003c32 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003bdc:	854a                	mv	a0,s2
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	60c080e7          	jalr	1548(ra) # 800031ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be6:	013a09bb          	addw	s3,s4,s3
    80003bea:	009a04bb          	addw	s1,s4,s1
    80003bee:	9aee                	add	s5,s5,s11
    80003bf0:	0569f663          	bgeu	s3,s6,80003c3c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf4:	000ba903          	lw	s2,0(s7) # 1000 <_entry-0x7ffff000>
    80003bf8:	00a4d59b          	srliw	a1,s1,0xa
    80003bfc:	855e                	mv	a0,s7
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	8b0080e7          	jalr	-1872(ra) # 800034ae <bmap>
    80003c06:	0005059b          	sext.w	a1,a0
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	4ae080e7          	jalr	1198(ra) # 800030ba <bread>
    80003c14:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c16:	3ff4f713          	andi	a4,s1,1023
    80003c1a:	40ed07bb          	subw	a5,s10,a4
    80003c1e:	413b06bb          	subw	a3,s6,s3
    80003c22:	8a3e                	mv	s4,a5
    80003c24:	2781                	sext.w	a5,a5
    80003c26:	0006861b          	sext.w	a2,a3
    80003c2a:	f8f679e3          	bgeu	a2,a5,80003bbc <readi+0x4c>
    80003c2e:	8a36                	mv	s4,a3
    80003c30:	b771                	j	80003bbc <readi+0x4c>
      brelse(bp);
    80003c32:	854a                	mv	a0,s2
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	5b6080e7          	jalr	1462(ra) # 800031ea <brelse>
  }
  return tot;
    80003c3c:	0009851b          	sext.w	a0,s3
}
    80003c40:	70a6                	ld	ra,104(sp)
    80003c42:	7406                	ld	s0,96(sp)
    80003c44:	64e6                	ld	s1,88(sp)
    80003c46:	6946                	ld	s2,80(sp)
    80003c48:	69a6                	ld	s3,72(sp)
    80003c4a:	6a06                	ld	s4,64(sp)
    80003c4c:	7ae2                	ld	s5,56(sp)
    80003c4e:	7b42                	ld	s6,48(sp)
    80003c50:	7ba2                	ld	s7,40(sp)
    80003c52:	7c02                	ld	s8,32(sp)
    80003c54:	6ce2                	ld	s9,24(sp)
    80003c56:	6d42                	ld	s10,16(sp)
    80003c58:	6da2                	ld	s11,8(sp)
    80003c5a:	6165                	addi	sp,sp,112
    80003c5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5e:	89da                	mv	s3,s6
    80003c60:	bff1                	j	80003c3c <readi+0xcc>
    return 0;
    80003c62:	4501                	li	a0,0
}
    80003c64:	8082                	ret

0000000080003c66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c66:	457c                	lw	a5,76(a0)
    80003c68:	10d7e663          	bltu	a5,a3,80003d74 <writei+0x10e>
{
    80003c6c:	7159                	addi	sp,sp,-112
    80003c6e:	f486                	sd	ra,104(sp)
    80003c70:	f0a2                	sd	s0,96(sp)
    80003c72:	eca6                	sd	s1,88(sp)
    80003c74:	e8ca                	sd	s2,80(sp)
    80003c76:	e4ce                	sd	s3,72(sp)
    80003c78:	e0d2                	sd	s4,64(sp)
    80003c7a:	fc56                	sd	s5,56(sp)
    80003c7c:	f85a                	sd	s6,48(sp)
    80003c7e:	f45e                	sd	s7,40(sp)
    80003c80:	f062                	sd	s8,32(sp)
    80003c82:	ec66                	sd	s9,24(sp)
    80003c84:	e86a                	sd	s10,16(sp)
    80003c86:	e46e                	sd	s11,8(sp)
    80003c88:	1880                	addi	s0,sp,112
    80003c8a:	8baa                	mv	s7,a0
    80003c8c:	8c2e                	mv	s8,a1
    80003c8e:	8ab2                	mv	s5,a2
    80003c90:	8936                	mv	s2,a3
    80003c92:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c94:	00e687bb          	addw	a5,a3,a4
    80003c98:	0ed7e063          	bltu	a5,a3,80003d78 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c9c:	00043737          	lui	a4,0x43
    80003ca0:	0cf76e63          	bltu	a4,a5,80003d7c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ca4:	0a0b0763          	beqz	s6,80003d52 <writei+0xec>
    80003ca8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003caa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cae:	5cfd                	li	s9,-1
    80003cb0:	a091                	j	80003cf4 <writei+0x8e>
    80003cb2:	02099d93          	slli	s11,s3,0x20
    80003cb6:	020ddd93          	srli	s11,s11,0x20
    80003cba:	05848513          	addi	a0,s1,88
    80003cbe:	86ee                	mv	a3,s11
    80003cc0:	8656                	mv	a2,s5
    80003cc2:	85e2                	mv	a1,s8
    80003cc4:	953a                	add	a0,a0,a4
    80003cc6:	fffff097          	auipc	ra,0xfffff
    80003cca:	9e4080e7          	jalr	-1564(ra) # 800026aa <either_copyin>
    80003cce:	07950263          	beq	a0,s9,80003d32 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cd2:	8526                	mv	a0,s1
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	77a080e7          	jalr	1914(ra) # 8000444e <log_write>
    brelse(bp);
    80003cdc:	8526                	mv	a0,s1
    80003cde:	fffff097          	auipc	ra,0xfffff
    80003ce2:	50c080e7          	jalr	1292(ra) # 800031ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce6:	01498a3b          	addw	s4,s3,s4
    80003cea:	0129893b          	addw	s2,s3,s2
    80003cee:	9aee                	add	s5,s5,s11
    80003cf0:	056a7663          	bgeu	s4,s6,80003d3c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cf4:	000ba483          	lw	s1,0(s7)
    80003cf8:	00a9559b          	srliw	a1,s2,0xa
    80003cfc:	855e                	mv	a0,s7
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	7b0080e7          	jalr	1968(ra) # 800034ae <bmap>
    80003d06:	0005059b          	sext.w	a1,a0
    80003d0a:	8526                	mv	a0,s1
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	3ae080e7          	jalr	942(ra) # 800030ba <bread>
    80003d14:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d16:	3ff97713          	andi	a4,s2,1023
    80003d1a:	40ed07bb          	subw	a5,s10,a4
    80003d1e:	414b06bb          	subw	a3,s6,s4
    80003d22:	89be                	mv	s3,a5
    80003d24:	2781                	sext.w	a5,a5
    80003d26:	0006861b          	sext.w	a2,a3
    80003d2a:	f8f674e3          	bgeu	a2,a5,80003cb2 <writei+0x4c>
    80003d2e:	89b6                	mv	s3,a3
    80003d30:	b749                	j	80003cb2 <writei+0x4c>
      brelse(bp);
    80003d32:	8526                	mv	a0,s1
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	4b6080e7          	jalr	1206(ra) # 800031ea <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d3c:	04cba783          	lw	a5,76(s7)
    80003d40:	0127f463          	bgeu	a5,s2,80003d48 <writei+0xe2>
      ip->size = off;
    80003d44:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d48:	855e                	mv	a0,s7
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	aa8080e7          	jalr	-1368(ra) # 800037f2 <iupdate>
  }

  return n;
    80003d52:	000b051b          	sext.w	a0,s6
}
    80003d56:	70a6                	ld	ra,104(sp)
    80003d58:	7406                	ld	s0,96(sp)
    80003d5a:	64e6                	ld	s1,88(sp)
    80003d5c:	6946                	ld	s2,80(sp)
    80003d5e:	69a6                	ld	s3,72(sp)
    80003d60:	6a06                	ld	s4,64(sp)
    80003d62:	7ae2                	ld	s5,56(sp)
    80003d64:	7b42                	ld	s6,48(sp)
    80003d66:	7ba2                	ld	s7,40(sp)
    80003d68:	7c02                	ld	s8,32(sp)
    80003d6a:	6ce2                	ld	s9,24(sp)
    80003d6c:	6d42                	ld	s10,16(sp)
    80003d6e:	6da2                	ld	s11,8(sp)
    80003d70:	6165                	addi	sp,sp,112
    80003d72:	8082                	ret
    return -1;
    80003d74:	557d                	li	a0,-1
}
    80003d76:	8082                	ret
    return -1;
    80003d78:	557d                	li	a0,-1
    80003d7a:	bff1                	j	80003d56 <writei+0xf0>
    return -1;
    80003d7c:	557d                	li	a0,-1
    80003d7e:	bfe1                	j	80003d56 <writei+0xf0>

0000000080003d80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d80:	1141                	addi	sp,sp,-16
    80003d82:	e406                	sd	ra,8(sp)
    80003d84:	e022                	sd	s0,0(sp)
    80003d86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d88:	4639                	li	a2,14
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	05e080e7          	jalr	94(ra) # 80000de8 <strncmp>
}
    80003d92:	60a2                	ld	ra,8(sp)
    80003d94:	6402                	ld	s0,0(sp)
    80003d96:	0141                	addi	sp,sp,16
    80003d98:	8082                	ret

0000000080003d9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d9a:	7139                	addi	sp,sp,-64
    80003d9c:	fc06                	sd	ra,56(sp)
    80003d9e:	f822                	sd	s0,48(sp)
    80003da0:	f426                	sd	s1,40(sp)
    80003da2:	f04a                	sd	s2,32(sp)
    80003da4:	ec4e                	sd	s3,24(sp)
    80003da6:	e852                	sd	s4,16(sp)
    80003da8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003daa:	04451703          	lh	a4,68(a0)
    80003dae:	4785                	li	a5,1
    80003db0:	00f71a63          	bne	a4,a5,80003dc4 <dirlookup+0x2a>
    80003db4:	892a                	mv	s2,a0
    80003db6:	89ae                	mv	s3,a1
    80003db8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dba:	457c                	lw	a5,76(a0)
    80003dbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc0:	e79d                	bnez	a5,80003dee <dirlookup+0x54>
    80003dc2:	a8a5                	j	80003e3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dc4:	00005517          	auipc	a0,0x5
    80003dc8:	86450513          	addi	a0,a0,-1948 # 80008628 <syscalls+0x1a0>
    80003dcc:	ffffc097          	auipc	ra,0xffffc
    80003dd0:	77c080e7          	jalr	1916(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003dd4:	00005517          	auipc	a0,0x5
    80003dd8:	86c50513          	addi	a0,a0,-1940 # 80008640 <syscalls+0x1b8>
    80003ddc:	ffffc097          	auipc	ra,0xffffc
    80003de0:	76c080e7          	jalr	1900(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de4:	24c1                	addiw	s1,s1,16
    80003de6:	04c92783          	lw	a5,76(s2)
    80003dea:	04f4f763          	bgeu	s1,a5,80003e38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dee:	4741                	li	a4,16
    80003df0:	86a6                	mv	a3,s1
    80003df2:	fc040613          	addi	a2,s0,-64
    80003df6:	4581                	li	a1,0
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	d76080e7          	jalr	-650(ra) # 80003b70 <readi>
    80003e02:	47c1                	li	a5,16
    80003e04:	fcf518e3          	bne	a0,a5,80003dd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e08:	fc045783          	lhu	a5,-64(s0)
    80003e0c:	dfe1                	beqz	a5,80003de4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e0e:	fc240593          	addi	a1,s0,-62
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	f6c080e7          	jalr	-148(ra) # 80003d80 <namecmp>
    80003e1c:	f561                	bnez	a0,80003de4 <dirlookup+0x4a>
      if(poff)
    80003e1e:	000a0463          	beqz	s4,80003e26 <dirlookup+0x8c>
        *poff = off;
    80003e22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e26:	fc045583          	lhu	a1,-64(s0)
    80003e2a:	00092503          	lw	a0,0(s2)
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	75a080e7          	jalr	1882(ra) # 80003588 <iget>
    80003e36:	a011                	j	80003e3a <dirlookup+0xa0>
  return 0;
    80003e38:	4501                	li	a0,0
}
    80003e3a:	70e2                	ld	ra,56(sp)
    80003e3c:	7442                	ld	s0,48(sp)
    80003e3e:	74a2                	ld	s1,40(sp)
    80003e40:	7902                	ld	s2,32(sp)
    80003e42:	69e2                	ld	s3,24(sp)
    80003e44:	6a42                	ld	s4,16(sp)
    80003e46:	6121                	addi	sp,sp,64
    80003e48:	8082                	ret

0000000080003e4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e4a:	711d                	addi	sp,sp,-96
    80003e4c:	ec86                	sd	ra,88(sp)
    80003e4e:	e8a2                	sd	s0,80(sp)
    80003e50:	e4a6                	sd	s1,72(sp)
    80003e52:	e0ca                	sd	s2,64(sp)
    80003e54:	fc4e                	sd	s3,56(sp)
    80003e56:	f852                	sd	s4,48(sp)
    80003e58:	f456                	sd	s5,40(sp)
    80003e5a:	f05a                	sd	s6,32(sp)
    80003e5c:	ec5e                	sd	s7,24(sp)
    80003e5e:	e862                	sd	s8,16(sp)
    80003e60:	e466                	sd	s9,8(sp)
    80003e62:	1080                	addi	s0,sp,96
    80003e64:	84aa                	mv	s1,a0
    80003e66:	8b2e                	mv	s6,a1
    80003e68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e6a:	00054703          	lbu	a4,0(a0)
    80003e6e:	02f00793          	li	a5,47
    80003e72:	02f70363          	beq	a4,a5,80003e98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e76:	ffffe097          	auipc	ra,0xffffe
    80003e7a:	bba080e7          	jalr	-1094(ra) # 80001a30 <myproc>
    80003e7e:	15853503          	ld	a0,344(a0)
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	9fc080e7          	jalr	-1540(ra) # 8000387e <idup>
    80003e8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e8c:	02f00913          	li	s2,47
  len = path - s;
    80003e90:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e92:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e94:	4c05                	li	s8,1
    80003e96:	a865                	j	80003f4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e98:	4585                	li	a1,1
    80003e9a:	4505                	li	a0,1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	6ec080e7          	jalr	1772(ra) # 80003588 <iget>
    80003ea4:	89aa                	mv	s3,a0
    80003ea6:	b7dd                	j	80003e8c <namex+0x42>
      iunlockput(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	c74080e7          	jalr	-908(ra) # 80003b1e <iunlockput>
      return 0;
    80003eb2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	60e6                	ld	ra,88(sp)
    80003eb8:	6446                	ld	s0,80(sp)
    80003eba:	64a6                	ld	s1,72(sp)
    80003ebc:	6906                	ld	s2,64(sp)
    80003ebe:	79e2                	ld	s3,56(sp)
    80003ec0:	7a42                	ld	s4,48(sp)
    80003ec2:	7aa2                	ld	s5,40(sp)
    80003ec4:	7b02                	ld	s6,32(sp)
    80003ec6:	6be2                	ld	s7,24(sp)
    80003ec8:	6c42                	ld	s8,16(sp)
    80003eca:	6ca2                	ld	s9,8(sp)
    80003ecc:	6125                	addi	sp,sp,96
    80003ece:	8082                	ret
      iunlock(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	aac080e7          	jalr	-1364(ra) # 8000397e <iunlock>
      return ip;
    80003eda:	bfe9                	j	80003eb4 <namex+0x6a>
      iunlockput(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	c40080e7          	jalr	-960(ra) # 80003b1e <iunlockput>
      return 0;
    80003ee6:	89d2                	mv	s3,s4
    80003ee8:	b7f1                	j	80003eb4 <namex+0x6a>
  len = path - s;
    80003eea:	40b48633          	sub	a2,s1,a1
    80003eee:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ef2:	094cd463          	bge	s9,s4,80003f7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ef6:	4639                	li	a2,14
    80003ef8:	8556                	mv	a0,s5
    80003efa:	ffffd097          	auipc	ra,0xffffd
    80003efe:	e72080e7          	jalr	-398(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	01279763          	bne	a5,s2,80003f14 <namex+0xca>
    path++;
    80003f0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f0c:	0004c783          	lbu	a5,0(s1)
    80003f10:	ff278de3          	beq	a5,s2,80003f0a <namex+0xc0>
    ilock(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	9a6080e7          	jalr	-1626(ra) # 800038bc <ilock>
    if(ip->type != T_DIR){
    80003f1e:	04499783          	lh	a5,68(s3)
    80003f22:	f98793e3          	bne	a5,s8,80003ea8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f26:	000b0563          	beqz	s6,80003f30 <namex+0xe6>
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	d3cd                	beqz	a5,80003ed0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f30:	865e                	mv	a2,s7
    80003f32:	85d6                	mv	a1,s5
    80003f34:	854e                	mv	a0,s3
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	e64080e7          	jalr	-412(ra) # 80003d9a <dirlookup>
    80003f3e:	8a2a                	mv	s4,a0
    80003f40:	dd51                	beqz	a0,80003edc <namex+0x92>
    iunlockput(ip);
    80003f42:	854e                	mv	a0,s3
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	bda080e7          	jalr	-1062(ra) # 80003b1e <iunlockput>
    ip = next;
    80003f4c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f4e:	0004c783          	lbu	a5,0(s1)
    80003f52:	05279763          	bne	a5,s2,80003fa0 <namex+0x156>
    path++;
    80003f56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f58:	0004c783          	lbu	a5,0(s1)
    80003f5c:	ff278de3          	beq	a5,s2,80003f56 <namex+0x10c>
  if(*path == 0)
    80003f60:	c79d                	beqz	a5,80003f8e <namex+0x144>
    path++;
    80003f62:	85a6                	mv	a1,s1
  len = path - s;
    80003f64:	8a5e                	mv	s4,s7
    80003f66:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f68:	01278963          	beq	a5,s2,80003f7a <namex+0x130>
    80003f6c:	dfbd                	beqz	a5,80003eea <namex+0xa0>
    path++;
    80003f6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	ff279ce3          	bne	a5,s2,80003f6c <namex+0x122>
    80003f78:	bf8d                	j	80003eea <namex+0xa0>
    memmove(name, s, len);
    80003f7a:	2601                	sext.w	a2,a2
    80003f7c:	8556                	mv	a0,s5
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	dee080e7          	jalr	-530(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003f86:	9a56                	add	s4,s4,s5
    80003f88:	000a0023          	sb	zero,0(s4)
    80003f8c:	bf9d                	j	80003f02 <namex+0xb8>
  if(nameiparent){
    80003f8e:	f20b03e3          	beqz	s6,80003eb4 <namex+0x6a>
    iput(ip);
    80003f92:	854e                	mv	a0,s3
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	ae2080e7          	jalr	-1310(ra) # 80003a76 <iput>
    return 0;
    80003f9c:	4981                	li	s3,0
    80003f9e:	bf19                	j	80003eb4 <namex+0x6a>
  if(*path == 0)
    80003fa0:	d7fd                	beqz	a5,80003f8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	85a6                	mv	a1,s1
    80003fa8:	b7d1                	j	80003f6c <namex+0x122>

0000000080003faa <dirlink>:
{
    80003faa:	7139                	addi	sp,sp,-64
    80003fac:	fc06                	sd	ra,56(sp)
    80003fae:	f822                	sd	s0,48(sp)
    80003fb0:	f426                	sd	s1,40(sp)
    80003fb2:	f04a                	sd	s2,32(sp)
    80003fb4:	ec4e                	sd	s3,24(sp)
    80003fb6:	e852                	sd	s4,16(sp)
    80003fb8:	0080                	addi	s0,sp,64
    80003fba:	892a                	mv	s2,a0
    80003fbc:	8a2e                	mv	s4,a1
    80003fbe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fc0:	4601                	li	a2,0
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	dd8080e7          	jalr	-552(ra) # 80003d9a <dirlookup>
    80003fca:	e93d                	bnez	a0,80004040 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fcc:	04c92483          	lw	s1,76(s2)
    80003fd0:	c49d                	beqz	s1,80003ffe <dirlink+0x54>
    80003fd2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd4:	4741                	li	a4,16
    80003fd6:	86a6                	mv	a3,s1
    80003fd8:	fc040613          	addi	a2,s0,-64
    80003fdc:	4581                	li	a1,0
    80003fde:	854a                	mv	a0,s2
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	b90080e7          	jalr	-1136(ra) # 80003b70 <readi>
    80003fe8:	47c1                	li	a5,16
    80003fea:	06f51163          	bne	a0,a5,8000404c <dirlink+0xa2>
    if(de.inum == 0)
    80003fee:	fc045783          	lhu	a5,-64(s0)
    80003ff2:	c791                	beqz	a5,80003ffe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff4:	24c1                	addiw	s1,s1,16
    80003ff6:	04c92783          	lw	a5,76(s2)
    80003ffa:	fcf4ede3          	bltu	s1,a5,80003fd4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ffe:	4639                	li	a2,14
    80004000:	85d2                	mv	a1,s4
    80004002:	fc240513          	addi	a0,s0,-62
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	e1e080e7          	jalr	-482(ra) # 80000e24 <strncpy>
  de.inum = inum;
    8000400e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004012:	4741                	li	a4,16
    80004014:	86a6                	mv	a3,s1
    80004016:	fc040613          	addi	a2,s0,-64
    8000401a:	4581                	li	a1,0
    8000401c:	854a                	mv	a0,s2
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	c48080e7          	jalr	-952(ra) # 80003c66 <writei>
    80004026:	872a                	mv	a4,a0
    80004028:	47c1                	li	a5,16
  return 0;
    8000402a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402c:	02f71863          	bne	a4,a5,8000405c <dirlink+0xb2>
}
    80004030:	70e2                	ld	ra,56(sp)
    80004032:	7442                	ld	s0,48(sp)
    80004034:	74a2                	ld	s1,40(sp)
    80004036:	7902                	ld	s2,32(sp)
    80004038:	69e2                	ld	s3,24(sp)
    8000403a:	6a42                	ld	s4,16(sp)
    8000403c:	6121                	addi	sp,sp,64
    8000403e:	8082                	ret
    iput(ip);
    80004040:	00000097          	auipc	ra,0x0
    80004044:	a36080e7          	jalr	-1482(ra) # 80003a76 <iput>
    return -1;
    80004048:	557d                	li	a0,-1
    8000404a:	b7dd                	j	80004030 <dirlink+0x86>
      panic("dirlink read");
    8000404c:	00004517          	auipc	a0,0x4
    80004050:	60450513          	addi	a0,a0,1540 # 80008650 <syscalls+0x1c8>
    80004054:	ffffc097          	auipc	ra,0xffffc
    80004058:	4f4080e7          	jalr	1268(ra) # 80000548 <panic>
    panic("dirlink");
    8000405c:	00004517          	auipc	a0,0x4
    80004060:	71450513          	addi	a0,a0,1812 # 80008770 <syscalls+0x2e8>
    80004064:	ffffc097          	auipc	ra,0xffffc
    80004068:	4e4080e7          	jalr	1252(ra) # 80000548 <panic>

000000008000406c <namei>:

struct inode*
namei(char *path)
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004074:	fe040613          	addi	a2,s0,-32
    80004078:	4581                	li	a1,0
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	dd0080e7          	jalr	-560(ra) # 80003e4a <namex>
}
    80004082:	60e2                	ld	ra,24(sp)
    80004084:	6442                	ld	s0,16(sp)
    80004086:	6105                	addi	sp,sp,32
    80004088:	8082                	ret

000000008000408a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000408a:	1141                	addi	sp,sp,-16
    8000408c:	e406                	sd	ra,8(sp)
    8000408e:	e022                	sd	s0,0(sp)
    80004090:	0800                	addi	s0,sp,16
    80004092:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004094:	4585                	li	a1,1
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	db4080e7          	jalr	-588(ra) # 80003e4a <namex>
}
    8000409e:	60a2                	ld	ra,8(sp)
    800040a0:	6402                	ld	s0,0(sp)
    800040a2:	0141                	addi	sp,sp,16
    800040a4:	8082                	ret

00000000800040a6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040a6:	1101                	addi	sp,sp,-32
    800040a8:	ec06                	sd	ra,24(sp)
    800040aa:	e822                	sd	s0,16(sp)
    800040ac:	e426                	sd	s1,8(sp)
    800040ae:	e04a                	sd	s2,0(sp)
    800040b0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040b2:	0001e917          	auipc	s2,0x1e
    800040b6:	a5690913          	addi	s2,s2,-1450 # 80021b08 <log>
    800040ba:	01892583          	lw	a1,24(s2)
    800040be:	02892503          	lw	a0,40(s2)
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	ff8080e7          	jalr	-8(ra) # 800030ba <bread>
    800040ca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040cc:	02c92683          	lw	a3,44(s2)
    800040d0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040d2:	02d05763          	blez	a3,80004100 <write_head+0x5a>
    800040d6:	0001e797          	auipc	a5,0x1e
    800040da:	a6278793          	addi	a5,a5,-1438 # 80021b38 <log+0x30>
    800040de:	05c50713          	addi	a4,a0,92
    800040e2:	36fd                	addiw	a3,a3,-1
    800040e4:	1682                	slli	a3,a3,0x20
    800040e6:	9281                	srli	a3,a3,0x20
    800040e8:	068a                	slli	a3,a3,0x2
    800040ea:	0001e617          	auipc	a2,0x1e
    800040ee:	a5260613          	addi	a2,a2,-1454 # 80021b3c <log+0x34>
    800040f2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040f4:	4390                	lw	a2,0(a5)
    800040f6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040f8:	0791                	addi	a5,a5,4
    800040fa:	0711                	addi	a4,a4,4
    800040fc:	fed79ce3          	bne	a5,a3,800040f4 <write_head+0x4e>
  }
  bwrite(buf);
    80004100:	8526                	mv	a0,s1
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	0aa080e7          	jalr	170(ra) # 800031ac <bwrite>
  brelse(buf);
    8000410a:	8526                	mv	a0,s1
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	0de080e7          	jalr	222(ra) # 800031ea <brelse>
}
    80004114:	60e2                	ld	ra,24(sp)
    80004116:	6442                	ld	s0,16(sp)
    80004118:	64a2                	ld	s1,8(sp)
    8000411a:	6902                	ld	s2,0(sp)
    8000411c:	6105                	addi	sp,sp,32
    8000411e:	8082                	ret

0000000080004120 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004120:	0001e797          	auipc	a5,0x1e
    80004124:	a147a783          	lw	a5,-1516(a5) # 80021b34 <log+0x2c>
    80004128:	0af05663          	blez	a5,800041d4 <install_trans+0xb4>
{
    8000412c:	7139                	addi	sp,sp,-64
    8000412e:	fc06                	sd	ra,56(sp)
    80004130:	f822                	sd	s0,48(sp)
    80004132:	f426                	sd	s1,40(sp)
    80004134:	f04a                	sd	s2,32(sp)
    80004136:	ec4e                	sd	s3,24(sp)
    80004138:	e852                	sd	s4,16(sp)
    8000413a:	e456                	sd	s5,8(sp)
    8000413c:	0080                	addi	s0,sp,64
    8000413e:	0001ea97          	auipc	s5,0x1e
    80004142:	9faa8a93          	addi	s5,s5,-1542 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004146:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004148:	0001e997          	auipc	s3,0x1e
    8000414c:	9c098993          	addi	s3,s3,-1600 # 80021b08 <log>
    80004150:	0189a583          	lw	a1,24(s3)
    80004154:	014585bb          	addw	a1,a1,s4
    80004158:	2585                	addiw	a1,a1,1
    8000415a:	0289a503          	lw	a0,40(s3)
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	f5c080e7          	jalr	-164(ra) # 800030ba <bread>
    80004166:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004168:	000aa583          	lw	a1,0(s5)
    8000416c:	0289a503          	lw	a0,40(s3)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	f4a080e7          	jalr	-182(ra) # 800030ba <bread>
    80004178:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000417a:	40000613          	li	a2,1024
    8000417e:	05890593          	addi	a1,s2,88
    80004182:	05850513          	addi	a0,a0,88
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	be6080e7          	jalr	-1050(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	01c080e7          	jalr	28(ra) # 800031ac <bwrite>
    bunpin(dbuf);
    80004198:	8526                	mv	a0,s1
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	12a080e7          	jalr	298(ra) # 800032c4 <bunpin>
    brelse(lbuf);
    800041a2:	854a                	mv	a0,s2
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	046080e7          	jalr	70(ra) # 800031ea <brelse>
    brelse(dbuf);
    800041ac:	8526                	mv	a0,s1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	03c080e7          	jalr	60(ra) # 800031ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b6:	2a05                	addiw	s4,s4,1
    800041b8:	0a91                	addi	s5,s5,4
    800041ba:	02c9a783          	lw	a5,44(s3)
    800041be:	f8fa49e3          	blt	s4,a5,80004150 <install_trans+0x30>
}
    800041c2:	70e2                	ld	ra,56(sp)
    800041c4:	7442                	ld	s0,48(sp)
    800041c6:	74a2                	ld	s1,40(sp)
    800041c8:	7902                	ld	s2,32(sp)
    800041ca:	69e2                	ld	s3,24(sp)
    800041cc:	6a42                	ld	s4,16(sp)
    800041ce:	6aa2                	ld	s5,8(sp)
    800041d0:	6121                	addi	sp,sp,64
    800041d2:	8082                	ret
    800041d4:	8082                	ret

00000000800041d6 <initlog>:
{
    800041d6:	7179                	addi	sp,sp,-48
    800041d8:	f406                	sd	ra,40(sp)
    800041da:	f022                	sd	s0,32(sp)
    800041dc:	ec26                	sd	s1,24(sp)
    800041de:	e84a                	sd	s2,16(sp)
    800041e0:	e44e                	sd	s3,8(sp)
    800041e2:	1800                	addi	s0,sp,48
    800041e4:	892a                	mv	s2,a0
    800041e6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041e8:	0001e497          	auipc	s1,0x1e
    800041ec:	92048493          	addi	s1,s1,-1760 # 80021b08 <log>
    800041f0:	00004597          	auipc	a1,0x4
    800041f4:	47058593          	addi	a1,a1,1136 # 80008660 <syscalls+0x1d8>
    800041f8:	8526                	mv	a0,s1
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	986080e7          	jalr	-1658(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004202:	0149a583          	lw	a1,20(s3)
    80004206:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004208:	0109a783          	lw	a5,16(s3)
    8000420c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000420e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004212:	854a                	mv	a0,s2
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	ea6080e7          	jalr	-346(ra) # 800030ba <bread>
  log.lh.n = lh->n;
    8000421c:	4d3c                	lw	a5,88(a0)
    8000421e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004220:	02f05563          	blez	a5,8000424a <initlog+0x74>
    80004224:	05c50713          	addi	a4,a0,92
    80004228:	0001e697          	auipc	a3,0x1e
    8000422c:	91068693          	addi	a3,a3,-1776 # 80021b38 <log+0x30>
    80004230:	37fd                	addiw	a5,a5,-1
    80004232:	1782                	slli	a5,a5,0x20
    80004234:	9381                	srli	a5,a5,0x20
    80004236:	078a                	slli	a5,a5,0x2
    80004238:	06050613          	addi	a2,a0,96
    8000423c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000423e:	4310                	lw	a2,0(a4)
    80004240:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004242:	0711                	addi	a4,a4,4
    80004244:	0691                	addi	a3,a3,4
    80004246:	fef71ce3          	bne	a4,a5,8000423e <initlog+0x68>
  brelse(buf);
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	fa0080e7          	jalr	-96(ra) # 800031ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004252:	00000097          	auipc	ra,0x0
    80004256:	ece080e7          	jalr	-306(ra) # 80004120 <install_trans>
  log.lh.n = 0;
    8000425a:	0001e797          	auipc	a5,0x1e
    8000425e:	8c07ad23          	sw	zero,-1830(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004262:	00000097          	auipc	ra,0x0
    80004266:	e44080e7          	jalr	-444(ra) # 800040a6 <write_head>
}
    8000426a:	70a2                	ld	ra,40(sp)
    8000426c:	7402                	ld	s0,32(sp)
    8000426e:	64e2                	ld	s1,24(sp)
    80004270:	6942                	ld	s2,16(sp)
    80004272:	69a2                	ld	s3,8(sp)
    80004274:	6145                	addi	sp,sp,48
    80004276:	8082                	ret

0000000080004278 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004278:	1101                	addi	sp,sp,-32
    8000427a:	ec06                	sd	ra,24(sp)
    8000427c:	e822                	sd	s0,16(sp)
    8000427e:	e426                	sd	s1,8(sp)
    80004280:	e04a                	sd	s2,0(sp)
    80004282:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004284:	0001e517          	auipc	a0,0x1e
    80004288:	88450513          	addi	a0,a0,-1916 # 80021b08 <log>
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	984080e7          	jalr	-1660(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004294:	0001e497          	auipc	s1,0x1e
    80004298:	87448493          	addi	s1,s1,-1932 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429c:	4979                	li	s2,30
    8000429e:	a039                	j	800042ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800042a0:	85a6                	mv	a1,s1
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	14e080e7          	jalr	334(ra) # 800023f2 <sleep>
    if(log.committing){
    800042ac:	50dc                	lw	a5,36(s1)
    800042ae:	fbed                	bnez	a5,800042a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042b0:	509c                	lw	a5,32(s1)
    800042b2:	0017871b          	addiw	a4,a5,1
    800042b6:	0007069b          	sext.w	a3,a4
    800042ba:	0027179b          	slliw	a5,a4,0x2
    800042be:	9fb9                	addw	a5,a5,a4
    800042c0:	0017979b          	slliw	a5,a5,0x1
    800042c4:	54d8                	lw	a4,44(s1)
    800042c6:	9fb9                	addw	a5,a5,a4
    800042c8:	00f95963          	bge	s2,a5,800042da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042cc:	85a6                	mv	a1,s1
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	122080e7          	jalr	290(ra) # 800023f2 <sleep>
    800042d8:	bfd1                	j	800042ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042da:	0001e517          	auipc	a0,0x1e
    800042de:	82e50513          	addi	a0,a0,-2002 # 80021b08 <log>
    800042e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	9e0080e7          	jalr	-1568(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800042ec:	60e2                	ld	ra,24(sp)
    800042ee:	6442                	ld	s0,16(sp)
    800042f0:	64a2                	ld	s1,8(sp)
    800042f2:	6902                	ld	s2,0(sp)
    800042f4:	6105                	addi	sp,sp,32
    800042f6:	8082                	ret

00000000800042f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042f8:	7139                	addi	sp,sp,-64
    800042fa:	fc06                	sd	ra,56(sp)
    800042fc:	f822                	sd	s0,48(sp)
    800042fe:	f426                	sd	s1,40(sp)
    80004300:	f04a                	sd	s2,32(sp)
    80004302:	ec4e                	sd	s3,24(sp)
    80004304:	e852                	sd	s4,16(sp)
    80004306:	e456                	sd	s5,8(sp)
    80004308:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000430a:	0001d497          	auipc	s1,0x1d
    8000430e:	7fe48493          	addi	s1,s1,2046 # 80021b08 <log>
    80004312:	8526                	mv	a0,s1
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	8fc080e7          	jalr	-1796(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    8000431c:	509c                	lw	a5,32(s1)
    8000431e:	37fd                	addiw	a5,a5,-1
    80004320:	0007891b          	sext.w	s2,a5
    80004324:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004326:	50dc                	lw	a5,36(s1)
    80004328:	efb9                	bnez	a5,80004386 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000432a:	06091663          	bnez	s2,80004396 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000432e:	0001d497          	auipc	s1,0x1d
    80004332:	7da48493          	addi	s1,s1,2010 # 80021b08 <log>
    80004336:	4785                	li	a5,1
    80004338:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	988080e7          	jalr	-1656(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004344:	54dc                	lw	a5,44(s1)
    80004346:	06f04763          	bgtz	a5,800043b4 <end_op+0xbc>
    acquire(&log.lock);
    8000434a:	0001d497          	auipc	s1,0x1d
    8000434e:	7be48493          	addi	s1,s1,1982 # 80021b08 <log>
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	8bc080e7          	jalr	-1860(ra) # 80000c10 <acquire>
    log.committing = 0;
    8000435c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	216080e7          	jalr	534(ra) # 80002578 <wakeup>
    release(&log.lock);
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	958080e7          	jalr	-1704(ra) # 80000cc4 <release>
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	6121                	addi	sp,sp,64
    80004384:	8082                	ret
    panic("log.committing");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2e250513          	addi	a0,a0,738 # 80008668 <syscalls+0x1e0>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
    wakeup(&log);
    80004396:	0001d497          	auipc	s1,0x1d
    8000439a:	77248493          	addi	s1,s1,1906 # 80021b08 <log>
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	1d8080e7          	jalr	472(ra) # 80002578 <wakeup>
  release(&log.lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	91a080e7          	jalr	-1766(ra) # 80000cc4 <release>
  if(do_commit){
    800043b2:	b7c9                	j	80004374 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b4:	0001da97          	auipc	s5,0x1d
    800043b8:	784a8a93          	addi	s5,s5,1924 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043bc:	0001da17          	auipc	s4,0x1d
    800043c0:	74ca0a13          	addi	s4,s4,1868 # 80021b08 <log>
    800043c4:	018a2583          	lw	a1,24(s4)
    800043c8:	012585bb          	addw	a1,a1,s2
    800043cc:	2585                	addiw	a1,a1,1
    800043ce:	028a2503          	lw	a0,40(s4)
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	ce8080e7          	jalr	-792(ra) # 800030ba <bread>
    800043da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043dc:	000aa583          	lw	a1,0(s5)
    800043e0:	028a2503          	lw	a0,40(s4)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	cd6080e7          	jalr	-810(ra) # 800030ba <bread>
    800043ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ee:	40000613          	li	a2,1024
    800043f2:	05850593          	addi	a1,a0,88
    800043f6:	05848513          	addi	a0,s1,88
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	972080e7          	jalr	-1678(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004402:	8526                	mv	a0,s1
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	da8080e7          	jalr	-600(ra) # 800031ac <bwrite>
    brelse(from);
    8000440c:	854e                	mv	a0,s3
    8000440e:	fffff097          	auipc	ra,0xfffff
    80004412:	ddc080e7          	jalr	-548(ra) # 800031ea <brelse>
    brelse(to);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	dd2080e7          	jalr	-558(ra) # 800031ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004420:	2905                	addiw	s2,s2,1
    80004422:	0a91                	addi	s5,s5,4
    80004424:	02ca2783          	lw	a5,44(s4)
    80004428:	f8f94ee3          	blt	s2,a5,800043c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	c7a080e7          	jalr	-902(ra) # 800040a6 <write_head>
    install_trans(); // Now install writes to home locations
    80004434:	00000097          	auipc	ra,0x0
    80004438:	cec080e7          	jalr	-788(ra) # 80004120 <install_trans>
    log.lh.n = 0;
    8000443c:	0001d797          	auipc	a5,0x1d
    80004440:	6e07ac23          	sw	zero,1784(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004444:	00000097          	auipc	ra,0x0
    80004448:	c62080e7          	jalr	-926(ra) # 800040a6 <write_head>
    8000444c:	bdfd                	j	8000434a <end_op+0x52>

000000008000444e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000445a:	0001d717          	auipc	a4,0x1d
    8000445e:	6da72703          	lw	a4,1754(a4) # 80021b34 <log+0x2c>
    80004462:	47f5                	li	a5,29
    80004464:	08e7c063          	blt	a5,a4,800044e4 <log_write+0x96>
    80004468:	84aa                	mv	s1,a0
    8000446a:	0001d797          	auipc	a5,0x1d
    8000446e:	6ba7a783          	lw	a5,1722(a5) # 80021b24 <log+0x1c>
    80004472:	37fd                	addiw	a5,a5,-1
    80004474:	06f75863          	bge	a4,a5,800044e4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004478:	0001d797          	auipc	a5,0x1d
    8000447c:	6b07a783          	lw	a5,1712(a5) # 80021b28 <log+0x20>
    80004480:	06f05a63          	blez	a5,800044f4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004484:	0001d917          	auipc	s2,0x1d
    80004488:	68490913          	addi	s2,s2,1668 # 80021b08 <log>
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	782080e7          	jalr	1922(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004496:	02c92603          	lw	a2,44(s2)
    8000449a:	06c05563          	blez	a2,80004504 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000449e:	44cc                	lw	a1,12(s1)
    800044a0:	0001d717          	auipc	a4,0x1d
    800044a4:	69870713          	addi	a4,a4,1688 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044a8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044aa:	4314                	lw	a3,0(a4)
    800044ac:	04b68d63          	beq	a3,a1,80004506 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044b0:	2785                	addiw	a5,a5,1
    800044b2:	0711                	addi	a4,a4,4
    800044b4:	fec79be3          	bne	a5,a2,800044aa <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044b8:	0621                	addi	a2,a2,8
    800044ba:	060a                	slli	a2,a2,0x2
    800044bc:	0001d797          	auipc	a5,0x1d
    800044c0:	64c78793          	addi	a5,a5,1612 # 80021b08 <log>
    800044c4:	963e                	add	a2,a2,a5
    800044c6:	44dc                	lw	a5,12(s1)
    800044c8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ca:	8526                	mv	a0,s1
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	dbc080e7          	jalr	-580(ra) # 80003288 <bpin>
    log.lh.n++;
    800044d4:	0001d717          	auipc	a4,0x1d
    800044d8:	63470713          	addi	a4,a4,1588 # 80021b08 <log>
    800044dc:	575c                	lw	a5,44(a4)
    800044de:	2785                	addiw	a5,a5,1
    800044e0:	d75c                	sw	a5,44(a4)
    800044e2:	a83d                	j	80004520 <log_write+0xd2>
    panic("too big a transaction");
    800044e4:	00004517          	auipc	a0,0x4
    800044e8:	19450513          	addi	a0,a0,404 # 80008678 <syscalls+0x1f0>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	05c080e7          	jalr	92(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	19c50513          	addi	a0,a0,412 # 80008690 <syscalls+0x208>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	04c080e7          	jalr	76(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004504:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004506:	00878713          	addi	a4,a5,8
    8000450a:	00271693          	slli	a3,a4,0x2
    8000450e:	0001d717          	auipc	a4,0x1d
    80004512:	5fa70713          	addi	a4,a4,1530 # 80021b08 <log>
    80004516:	9736                	add	a4,a4,a3
    80004518:	44d4                	lw	a3,12(s1)
    8000451a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000451c:	faf607e3          	beq	a2,a5,800044ca <log_write+0x7c>
  }
  release(&log.lock);
    80004520:	0001d517          	auipc	a0,0x1d
    80004524:	5e850513          	addi	a0,a0,1512 # 80021b08 <log>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	79c080e7          	jalr	1948(ra) # 80000cc4 <release>
}
    80004530:	60e2                	ld	ra,24(sp)
    80004532:	6442                	ld	s0,16(sp)
    80004534:	64a2                	ld	s1,8(sp)
    80004536:	6902                	ld	s2,0(sp)
    80004538:	6105                	addi	sp,sp,32
    8000453a:	8082                	ret

000000008000453c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000453c:	1101                	addi	sp,sp,-32
    8000453e:	ec06                	sd	ra,24(sp)
    80004540:	e822                	sd	s0,16(sp)
    80004542:	e426                	sd	s1,8(sp)
    80004544:	e04a                	sd	s2,0(sp)
    80004546:	1000                	addi	s0,sp,32
    80004548:	84aa                	mv	s1,a0
    8000454a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000454c:	00004597          	auipc	a1,0x4
    80004550:	16458593          	addi	a1,a1,356 # 800086b0 <syscalls+0x228>
    80004554:	0521                	addi	a0,a0,8
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	62a080e7          	jalr	1578(ra) # 80000b80 <initlock>
  lk->name = name;
    8000455e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004562:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004566:	0204a423          	sw	zero,40(s1)
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6902                	ld	s2,0(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	e04a                	sd	s2,0(sp)
    80004580:	1000                	addi	s0,sp,32
    80004582:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004584:	00850913          	addi	s2,a0,8
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	686080e7          	jalr	1670(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004592:	409c                	lw	a5,0(s1)
    80004594:	cb89                	beqz	a5,800045a6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004596:	85ca                	mv	a1,s2
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffe097          	auipc	ra,0xffffe
    8000459e:	e58080e7          	jalr	-424(ra) # 800023f2 <sleep>
  while (lk->locked) {
    800045a2:	409c                	lw	a5,0(s1)
    800045a4:	fbed                	bnez	a5,80004596 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045a6:	4785                	li	a5,1
    800045a8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045aa:	ffffd097          	auipc	ra,0xffffd
    800045ae:	486080e7          	jalr	1158(ra) # 80001a30 <myproc>
    800045b2:	5d1c                	lw	a5,56(a0)
    800045b4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	70c080e7          	jalr	1804(ra) # 80000cc4 <release>
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045da:	00850913          	addi	s2,a0,8
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	630080e7          	jalr	1584(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800045e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ec:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045f0:	8526                	mv	a0,s1
    800045f2:	ffffe097          	auipc	ra,0xffffe
    800045f6:	f86080e7          	jalr	-122(ra) # 80002578 <wakeup>
  release(&lk->lk);
    800045fa:	854a                	mv	a0,s2
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	6c8080e7          	jalr	1736(ra) # 80000cc4 <release>
}
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6902                	ld	s2,0(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret

0000000080004610 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004610:	7179                	addi	sp,sp,-48
    80004612:	f406                	sd	ra,40(sp)
    80004614:	f022                	sd	s0,32(sp)
    80004616:	ec26                	sd	s1,24(sp)
    80004618:	e84a                	sd	s2,16(sp)
    8000461a:	e44e                	sd	s3,8(sp)
    8000461c:	1800                	addi	s0,sp,48
    8000461e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004620:	00850913          	addi	s2,a0,8
    80004624:	854a                	mv	a0,s2
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	5ea080e7          	jalr	1514(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000462e:	409c                	lw	a5,0(s1)
    80004630:	ef99                	bnez	a5,8000464e <holdingsleep+0x3e>
    80004632:	4481                	li	s1,0
  release(&lk->lk);
    80004634:	854a                	mv	a0,s2
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	68e080e7          	jalr	1678(ra) # 80000cc4 <release>
  return r;
}
    8000463e:	8526                	mv	a0,s1
    80004640:	70a2                	ld	ra,40(sp)
    80004642:	7402                	ld	s0,32(sp)
    80004644:	64e2                	ld	s1,24(sp)
    80004646:	6942                	ld	s2,16(sp)
    80004648:	69a2                	ld	s3,8(sp)
    8000464a:	6145                	addi	sp,sp,48
    8000464c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000464e:	0284a983          	lw	s3,40(s1)
    80004652:	ffffd097          	auipc	ra,0xffffd
    80004656:	3de080e7          	jalr	990(ra) # 80001a30 <myproc>
    8000465a:	5d04                	lw	s1,56(a0)
    8000465c:	413484b3          	sub	s1,s1,s3
    80004660:	0014b493          	seqz	s1,s1
    80004664:	bfc1                	j	80004634 <holdingsleep+0x24>

0000000080004666 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004666:	1141                	addi	sp,sp,-16
    80004668:	e406                	sd	ra,8(sp)
    8000466a:	e022                	sd	s0,0(sp)
    8000466c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000466e:	00004597          	auipc	a1,0x4
    80004672:	05258593          	addi	a1,a1,82 # 800086c0 <syscalls+0x238>
    80004676:	0001d517          	auipc	a0,0x1d
    8000467a:	5da50513          	addi	a0,a0,1498 # 80021c50 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	502080e7          	jalr	1282(ra) # 80000b80 <initlock>
}
    80004686:	60a2                	ld	ra,8(sp)
    80004688:	6402                	ld	s0,0(sp)
    8000468a:	0141                	addi	sp,sp,16
    8000468c:	8082                	ret

000000008000468e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	5b850513          	addi	a0,a0,1464 # 80021c50 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	570080e7          	jalr	1392(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a8:	0001d497          	auipc	s1,0x1d
    800046ac:	5c048493          	addi	s1,s1,1472 # 80021c68 <ftable+0x18>
    800046b0:	0001e717          	auipc	a4,0x1e
    800046b4:	55870713          	addi	a4,a4,1368 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800046b8:	40dc                	lw	a5,4(s1)
    800046ba:	cf99                	beqz	a5,800046d8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046bc:	02848493          	addi	s1,s1,40
    800046c0:	fee49ce3          	bne	s1,a4,800046b8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046c4:	0001d517          	auipc	a0,0x1d
    800046c8:	58c50513          	addi	a0,a0,1420 # 80021c50 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	5f8080e7          	jalr	1528(ra) # 80000cc4 <release>
  return 0;
    800046d4:	4481                	li	s1,0
    800046d6:	a819                	j	800046ec <filealloc+0x5e>
      f->ref = 1;
    800046d8:	4785                	li	a5,1
    800046da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046dc:	0001d517          	auipc	a0,0x1d
    800046e0:	57450513          	addi	a0,a0,1396 # 80021c50 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	5e0080e7          	jalr	1504(ra) # 80000cc4 <release>
}
    800046ec:	8526                	mv	a0,s1
    800046ee:	60e2                	ld	ra,24(sp)
    800046f0:	6442                	ld	s0,16(sp)
    800046f2:	64a2                	ld	s1,8(sp)
    800046f4:	6105                	addi	sp,sp,32
    800046f6:	8082                	ret

00000000800046f8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046f8:	1101                	addi	sp,sp,-32
    800046fa:	ec06                	sd	ra,24(sp)
    800046fc:	e822                	sd	s0,16(sp)
    800046fe:	e426                	sd	s1,8(sp)
    80004700:	1000                	addi	s0,sp,32
    80004702:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004704:	0001d517          	auipc	a0,0x1d
    80004708:	54c50513          	addi	a0,a0,1356 # 80021c50 <ftable>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	504080e7          	jalr	1284(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004714:	40dc                	lw	a5,4(s1)
    80004716:	02f05263          	blez	a5,8000473a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000471a:	2785                	addiw	a5,a5,1
    8000471c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000471e:	0001d517          	auipc	a0,0x1d
    80004722:	53250513          	addi	a0,a0,1330 # 80021c50 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	59e080e7          	jalr	1438(ra) # 80000cc4 <release>
  return f;
}
    8000472e:	8526                	mv	a0,s1
    80004730:	60e2                	ld	ra,24(sp)
    80004732:	6442                	ld	s0,16(sp)
    80004734:	64a2                	ld	s1,8(sp)
    80004736:	6105                	addi	sp,sp,32
    80004738:	8082                	ret
    panic("filedup");
    8000473a:	00004517          	auipc	a0,0x4
    8000473e:	f8e50513          	addi	a0,a0,-114 # 800086c8 <syscalls+0x240>
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	e06080e7          	jalr	-506(ra) # 80000548 <panic>

000000008000474a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000474a:	7139                	addi	sp,sp,-64
    8000474c:	fc06                	sd	ra,56(sp)
    8000474e:	f822                	sd	s0,48(sp)
    80004750:	f426                	sd	s1,40(sp)
    80004752:	f04a                	sd	s2,32(sp)
    80004754:	ec4e                	sd	s3,24(sp)
    80004756:	e852                	sd	s4,16(sp)
    80004758:	e456                	sd	s5,8(sp)
    8000475a:	0080                	addi	s0,sp,64
    8000475c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000475e:	0001d517          	auipc	a0,0x1d
    80004762:	4f250513          	addi	a0,a0,1266 # 80021c50 <ftable>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	4aa080e7          	jalr	1194(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000476e:	40dc                	lw	a5,4(s1)
    80004770:	06f05163          	blez	a5,800047d2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004774:	37fd                	addiw	a5,a5,-1
    80004776:	0007871b          	sext.w	a4,a5
    8000477a:	c0dc                	sw	a5,4(s1)
    8000477c:	06e04363          	bgtz	a4,800047e2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004780:	0004a903          	lw	s2,0(s1)
    80004784:	0094ca83          	lbu	s5,9(s1)
    80004788:	0104ba03          	ld	s4,16(s1)
    8000478c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004790:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004794:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004798:	0001d517          	auipc	a0,0x1d
    8000479c:	4b850513          	addi	a0,a0,1208 # 80021c50 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	524080e7          	jalr	1316(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800047a8:	4785                	li	a5,1
    800047aa:	04f90d63          	beq	s2,a5,80004804 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047ae:	3979                	addiw	s2,s2,-2
    800047b0:	4785                	li	a5,1
    800047b2:	0527e063          	bltu	a5,s2,800047f2 <fileclose+0xa8>
    begin_op();
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	ac2080e7          	jalr	-1342(ra) # 80004278 <begin_op>
    iput(ff.ip);
    800047be:	854e                	mv	a0,s3
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	2b6080e7          	jalr	694(ra) # 80003a76 <iput>
    end_op();
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	b30080e7          	jalr	-1232(ra) # 800042f8 <end_op>
    800047d0:	a00d                	j	800047f2 <fileclose+0xa8>
    panic("fileclose");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	efe50513          	addi	a0,a0,-258 # 800086d0 <syscalls+0x248>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d6e080e7          	jalr	-658(ra) # 80000548 <panic>
    release(&ftable.lock);
    800047e2:	0001d517          	auipc	a0,0x1d
    800047e6:	46e50513          	addi	a0,a0,1134 # 80021c50 <ftable>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	4da080e7          	jalr	1242(ra) # 80000cc4 <release>
  }
}
    800047f2:	70e2                	ld	ra,56(sp)
    800047f4:	7442                	ld	s0,48(sp)
    800047f6:	74a2                	ld	s1,40(sp)
    800047f8:	7902                	ld	s2,32(sp)
    800047fa:	69e2                	ld	s3,24(sp)
    800047fc:	6a42                	ld	s4,16(sp)
    800047fe:	6aa2                	ld	s5,8(sp)
    80004800:	6121                	addi	sp,sp,64
    80004802:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004804:	85d6                	mv	a1,s5
    80004806:	8552                	mv	a0,s4
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	372080e7          	jalr	882(ra) # 80004b7a <pipeclose>
    80004810:	b7cd                	j	800047f2 <fileclose+0xa8>

0000000080004812 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004812:	715d                	addi	sp,sp,-80
    80004814:	e486                	sd	ra,72(sp)
    80004816:	e0a2                	sd	s0,64(sp)
    80004818:	fc26                	sd	s1,56(sp)
    8000481a:	f84a                	sd	s2,48(sp)
    8000481c:	f44e                	sd	s3,40(sp)
    8000481e:	0880                	addi	s0,sp,80
    80004820:	84aa                	mv	s1,a0
    80004822:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004824:	ffffd097          	auipc	ra,0xffffd
    80004828:	20c080e7          	jalr	524(ra) # 80001a30 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000482c:	409c                	lw	a5,0(s1)
    8000482e:	37f9                	addiw	a5,a5,-2
    80004830:	4705                	li	a4,1
    80004832:	04f76763          	bltu	a4,a5,80004880 <filestat+0x6e>
    80004836:	892a                	mv	s2,a0
    ilock(f->ip);
    80004838:	6c88                	ld	a0,24(s1)
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	082080e7          	jalr	130(ra) # 800038bc <ilock>
    stati(f->ip, &st);
    80004842:	fb840593          	addi	a1,s0,-72
    80004846:	6c88                	ld	a0,24(s1)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	2fe080e7          	jalr	766(ra) # 80003b46 <stati>
    iunlock(f->ip);
    80004850:	6c88                	ld	a0,24(s1)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	12c080e7          	jalr	300(ra) # 8000397e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000485a:	46e1                	li	a3,24
    8000485c:	fb840613          	addi	a2,s0,-72
    80004860:	85ce                	mv	a1,s3
    80004862:	05093503          	ld	a0,80(s2)
    80004866:	ffffd097          	auipc	ra,0xffffd
    8000486a:	00a080e7          	jalr	10(ra) # 80001870 <copyout>
    8000486e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004872:	60a6                	ld	ra,72(sp)
    80004874:	6406                	ld	s0,64(sp)
    80004876:	74e2                	ld	s1,56(sp)
    80004878:	7942                	ld	s2,48(sp)
    8000487a:	79a2                	ld	s3,40(sp)
    8000487c:	6161                	addi	sp,sp,80
    8000487e:	8082                	ret
  return -1;
    80004880:	557d                	li	a0,-1
    80004882:	bfc5                	j	80004872 <filestat+0x60>

0000000080004884 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004884:	7179                	addi	sp,sp,-48
    80004886:	f406                	sd	ra,40(sp)
    80004888:	f022                	sd	s0,32(sp)
    8000488a:	ec26                	sd	s1,24(sp)
    8000488c:	e84a                	sd	s2,16(sp)
    8000488e:	e44e                	sd	s3,8(sp)
    80004890:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004892:	00854783          	lbu	a5,8(a0)
    80004896:	c3d5                	beqz	a5,8000493a <fileread+0xb6>
    80004898:	84aa                	mv	s1,a0
    8000489a:	89ae                	mv	s3,a1
    8000489c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000489e:	411c                	lw	a5,0(a0)
    800048a0:	4705                	li	a4,1
    800048a2:	04e78963          	beq	a5,a4,800048f4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a6:	470d                	li	a4,3
    800048a8:	04e78d63          	beq	a5,a4,80004902 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048ac:	4709                	li	a4,2
    800048ae:	06e79e63          	bne	a5,a4,8000492a <fileread+0xa6>
    ilock(f->ip);
    800048b2:	6d08                	ld	a0,24(a0)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	008080e7          	jalr	8(ra) # 800038bc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048bc:	874a                	mv	a4,s2
    800048be:	5094                	lw	a3,32(s1)
    800048c0:	864e                	mv	a2,s3
    800048c2:	4585                	li	a1,1
    800048c4:	6c88                	ld	a0,24(s1)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	2aa080e7          	jalr	682(ra) # 80003b70 <readi>
    800048ce:	892a                	mv	s2,a0
    800048d0:	00a05563          	blez	a0,800048da <fileread+0x56>
      f->off += r;
    800048d4:	509c                	lw	a5,32(s1)
    800048d6:	9fa9                	addw	a5,a5,a0
    800048d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048da:	6c88                	ld	a0,24(s1)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	0a2080e7          	jalr	162(ra) # 8000397e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048e4:	854a                	mv	a0,s2
    800048e6:	70a2                	ld	ra,40(sp)
    800048e8:	7402                	ld	s0,32(sp)
    800048ea:	64e2                	ld	s1,24(sp)
    800048ec:	6942                	ld	s2,16(sp)
    800048ee:	69a2                	ld	s3,8(sp)
    800048f0:	6145                	addi	sp,sp,48
    800048f2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048f4:	6908                	ld	a0,16(a0)
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	418080e7          	jalr	1048(ra) # 80004d0e <piperead>
    800048fe:	892a                	mv	s2,a0
    80004900:	b7d5                	j	800048e4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004902:	02451783          	lh	a5,36(a0)
    80004906:	03079693          	slli	a3,a5,0x30
    8000490a:	92c1                	srli	a3,a3,0x30
    8000490c:	4725                	li	a4,9
    8000490e:	02d76863          	bltu	a4,a3,8000493e <fileread+0xba>
    80004912:	0792                	slli	a5,a5,0x4
    80004914:	0001d717          	auipc	a4,0x1d
    80004918:	29c70713          	addi	a4,a4,668 # 80021bb0 <devsw>
    8000491c:	97ba                	add	a5,a5,a4
    8000491e:	639c                	ld	a5,0(a5)
    80004920:	c38d                	beqz	a5,80004942 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004922:	4505                	li	a0,1
    80004924:	9782                	jalr	a5
    80004926:	892a                	mv	s2,a0
    80004928:	bf75                	j	800048e4 <fileread+0x60>
    panic("fileread");
    8000492a:	00004517          	auipc	a0,0x4
    8000492e:	db650513          	addi	a0,a0,-586 # 800086e0 <syscalls+0x258>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	c16080e7          	jalr	-1002(ra) # 80000548 <panic>
    return -1;
    8000493a:	597d                	li	s2,-1
    8000493c:	b765                	j	800048e4 <fileread+0x60>
      return -1;
    8000493e:	597d                	li	s2,-1
    80004940:	b755                	j	800048e4 <fileread+0x60>
    80004942:	597d                	li	s2,-1
    80004944:	b745                	j	800048e4 <fileread+0x60>

0000000080004946 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004946:	00954783          	lbu	a5,9(a0)
    8000494a:	14078563          	beqz	a5,80004a94 <filewrite+0x14e>
{
    8000494e:	715d                	addi	sp,sp,-80
    80004950:	e486                	sd	ra,72(sp)
    80004952:	e0a2                	sd	s0,64(sp)
    80004954:	fc26                	sd	s1,56(sp)
    80004956:	f84a                	sd	s2,48(sp)
    80004958:	f44e                	sd	s3,40(sp)
    8000495a:	f052                	sd	s4,32(sp)
    8000495c:	ec56                	sd	s5,24(sp)
    8000495e:	e85a                	sd	s6,16(sp)
    80004960:	e45e                	sd	s7,8(sp)
    80004962:	e062                	sd	s8,0(sp)
    80004964:	0880                	addi	s0,sp,80
    80004966:	892a                	mv	s2,a0
    80004968:	8aae                	mv	s5,a1
    8000496a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000496c:	411c                	lw	a5,0(a0)
    8000496e:	4705                	li	a4,1
    80004970:	02e78263          	beq	a5,a4,80004994 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004974:	470d                	li	a4,3
    80004976:	02e78563          	beq	a5,a4,800049a0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000497a:	4709                	li	a4,2
    8000497c:	10e79463          	bne	a5,a4,80004a84 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004980:	0ec05e63          	blez	a2,80004a7c <filewrite+0x136>
    int i = 0;
    80004984:	4981                	li	s3,0
    80004986:	6b05                	lui	s6,0x1
    80004988:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000498c:	6b85                	lui	s7,0x1
    8000498e:	c00b8b9b          	addiw	s7,s7,-1024
    80004992:	a851                	j	80004a26 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004994:	6908                	ld	a0,16(a0)
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	254080e7          	jalr	596(ra) # 80004bea <pipewrite>
    8000499e:	a85d                	j	80004a54 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049a0:	02451783          	lh	a5,36(a0)
    800049a4:	03079693          	slli	a3,a5,0x30
    800049a8:	92c1                	srli	a3,a3,0x30
    800049aa:	4725                	li	a4,9
    800049ac:	0ed76663          	bltu	a4,a3,80004a98 <filewrite+0x152>
    800049b0:	0792                	slli	a5,a5,0x4
    800049b2:	0001d717          	auipc	a4,0x1d
    800049b6:	1fe70713          	addi	a4,a4,510 # 80021bb0 <devsw>
    800049ba:	97ba                	add	a5,a5,a4
    800049bc:	679c                	ld	a5,8(a5)
    800049be:	cff9                	beqz	a5,80004a9c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049c0:	4505                	li	a0,1
    800049c2:	9782                	jalr	a5
    800049c4:	a841                	j	80004a54 <filewrite+0x10e>
    800049c6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	8ae080e7          	jalr	-1874(ra) # 80004278 <begin_op>
      ilock(f->ip);
    800049d2:	01893503          	ld	a0,24(s2)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	ee6080e7          	jalr	-282(ra) # 800038bc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049de:	8762                	mv	a4,s8
    800049e0:	02092683          	lw	a3,32(s2)
    800049e4:	01598633          	add	a2,s3,s5
    800049e8:	4585                	li	a1,1
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	278080e7          	jalr	632(ra) # 80003c66 <writei>
    800049f6:	84aa                	mv	s1,a0
    800049f8:	02a05f63          	blez	a0,80004a36 <filewrite+0xf0>
        f->off += r;
    800049fc:	02092783          	lw	a5,32(s2)
    80004a00:	9fa9                	addw	a5,a5,a0
    80004a02:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a06:	01893503          	ld	a0,24(s2)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	f74080e7          	jalr	-140(ra) # 8000397e <iunlock>
      end_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	8e6080e7          	jalr	-1818(ra) # 800042f8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a1a:	049c1963          	bne	s8,s1,80004a6c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a1e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a22:	0349d663          	bge	s3,s4,80004a4e <filewrite+0x108>
      int n1 = n - i;
    80004a26:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a2a:	84be                	mv	s1,a5
    80004a2c:	2781                	sext.w	a5,a5
    80004a2e:	f8fb5ce3          	bge	s6,a5,800049c6 <filewrite+0x80>
    80004a32:	84de                	mv	s1,s7
    80004a34:	bf49                	j	800049c6 <filewrite+0x80>
      iunlock(f->ip);
    80004a36:	01893503          	ld	a0,24(s2)
    80004a3a:	fffff097          	auipc	ra,0xfffff
    80004a3e:	f44080e7          	jalr	-188(ra) # 8000397e <iunlock>
      end_op();
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	8b6080e7          	jalr	-1866(ra) # 800042f8 <end_op>
      if(r < 0)
    80004a4a:	fc04d8e3          	bgez	s1,80004a1a <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a4e:	8552                	mv	a0,s4
    80004a50:	033a1863          	bne	s4,s3,80004a80 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a54:	60a6                	ld	ra,72(sp)
    80004a56:	6406                	ld	s0,64(sp)
    80004a58:	74e2                	ld	s1,56(sp)
    80004a5a:	7942                	ld	s2,48(sp)
    80004a5c:	79a2                	ld	s3,40(sp)
    80004a5e:	7a02                	ld	s4,32(sp)
    80004a60:	6ae2                	ld	s5,24(sp)
    80004a62:	6b42                	ld	s6,16(sp)
    80004a64:	6ba2                	ld	s7,8(sp)
    80004a66:	6c02                	ld	s8,0(sp)
    80004a68:	6161                	addi	sp,sp,80
    80004a6a:	8082                	ret
        panic("short filewrite");
    80004a6c:	00004517          	auipc	a0,0x4
    80004a70:	c8450513          	addi	a0,a0,-892 # 800086f0 <syscalls+0x268>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	ad4080e7          	jalr	-1324(ra) # 80000548 <panic>
    int i = 0;
    80004a7c:	4981                	li	s3,0
    80004a7e:	bfc1                	j	80004a4e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a80:	557d                	li	a0,-1
    80004a82:	bfc9                	j	80004a54 <filewrite+0x10e>
    panic("filewrite");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	c7c50513          	addi	a0,a0,-900 # 80008700 <syscalls+0x278>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	abc080e7          	jalr	-1348(ra) # 80000548 <panic>
    return -1;
    80004a94:	557d                	li	a0,-1
}
    80004a96:	8082                	ret
      return -1;
    80004a98:	557d                	li	a0,-1
    80004a9a:	bf6d                	j	80004a54 <filewrite+0x10e>
    80004a9c:	557d                	li	a0,-1
    80004a9e:	bf5d                	j	80004a54 <filewrite+0x10e>

0000000080004aa0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aa0:	7179                	addi	sp,sp,-48
    80004aa2:	f406                	sd	ra,40(sp)
    80004aa4:	f022                	sd	s0,32(sp)
    80004aa6:	ec26                	sd	s1,24(sp)
    80004aa8:	e84a                	sd	s2,16(sp)
    80004aaa:	e44e                	sd	s3,8(sp)
    80004aac:	e052                	sd	s4,0(sp)
    80004aae:	1800                	addi	s0,sp,48
    80004ab0:	84aa                	mv	s1,a0
    80004ab2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ab4:	0005b023          	sd	zero,0(a1)
    80004ab8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	bd2080e7          	jalr	-1070(ra) # 8000468e <filealloc>
    80004ac4:	e088                	sd	a0,0(s1)
    80004ac6:	c551                	beqz	a0,80004b52 <pipealloc+0xb2>
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	bc6080e7          	jalr	-1082(ra) # 8000468e <filealloc>
    80004ad0:	00aa3023          	sd	a0,0(s4)
    80004ad4:	c92d                	beqz	a0,80004b46 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	04a080e7          	jalr	74(ra) # 80000b20 <kalloc>
    80004ade:	892a                	mv	s2,a0
    80004ae0:	c125                	beqz	a0,80004b40 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ae2:	4985                	li	s3,1
    80004ae4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ae8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aec:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004af0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004af4:	00004597          	auipc	a1,0x4
    80004af8:	c1c58593          	addi	a1,a1,-996 # 80008710 <syscalls+0x288>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004b04:	609c                	ld	a5,0(s1)
    80004b06:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b0a:	609c                	ld	a5,0(s1)
    80004b0c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b10:	609c                	ld	a5,0(s1)
    80004b12:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b16:	609c                	ld	a5,0(s1)
    80004b18:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b1c:	000a3783          	ld	a5,0(s4)
    80004b20:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b24:	000a3783          	ld	a5,0(s4)
    80004b28:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b2c:	000a3783          	ld	a5,0(s4)
    80004b30:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b34:	000a3783          	ld	a5,0(s4)
    80004b38:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b3c:	4501                	li	a0,0
    80004b3e:	a025                	j	80004b66 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b40:	6088                	ld	a0,0(s1)
    80004b42:	e501                	bnez	a0,80004b4a <pipealloc+0xaa>
    80004b44:	a039                	j	80004b52 <pipealloc+0xb2>
    80004b46:	6088                	ld	a0,0(s1)
    80004b48:	c51d                	beqz	a0,80004b76 <pipealloc+0xd6>
    fileclose(*f0);
    80004b4a:	00000097          	auipc	ra,0x0
    80004b4e:	c00080e7          	jalr	-1024(ra) # 8000474a <fileclose>
  if(*f1)
    80004b52:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b56:	557d                	li	a0,-1
  if(*f1)
    80004b58:	c799                	beqz	a5,80004b66 <pipealloc+0xc6>
    fileclose(*f1);
    80004b5a:	853e                	mv	a0,a5
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	bee080e7          	jalr	-1042(ra) # 8000474a <fileclose>
  return -1;
    80004b64:	557d                	li	a0,-1
}
    80004b66:	70a2                	ld	ra,40(sp)
    80004b68:	7402                	ld	s0,32(sp)
    80004b6a:	64e2                	ld	s1,24(sp)
    80004b6c:	6942                	ld	s2,16(sp)
    80004b6e:	69a2                	ld	s3,8(sp)
    80004b70:	6a02                	ld	s4,0(sp)
    80004b72:	6145                	addi	sp,sp,48
    80004b74:	8082                	ret
  return -1;
    80004b76:	557d                	li	a0,-1
    80004b78:	b7fd                	j	80004b66 <pipealloc+0xc6>

0000000080004b7a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b7a:	1101                	addi	sp,sp,-32
    80004b7c:	ec06                	sd	ra,24(sp)
    80004b7e:	e822                	sd	s0,16(sp)
    80004b80:	e426                	sd	s1,8(sp)
    80004b82:	e04a                	sd	s2,0(sp)
    80004b84:	1000                	addi	s0,sp,32
    80004b86:	84aa                	mv	s1,a0
    80004b88:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	086080e7          	jalr	134(ra) # 80000c10 <acquire>
  if(writable){
    80004b92:	02090d63          	beqz	s2,80004bcc <pipeclose+0x52>
    pi->writeopen = 0;
    80004b96:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b9a:	21848513          	addi	a0,s1,536
    80004b9e:	ffffe097          	auipc	ra,0xffffe
    80004ba2:	9da080e7          	jalr	-1574(ra) # 80002578 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ba6:	2204b783          	ld	a5,544(s1)
    80004baa:	eb95                	bnez	a5,80004bde <pipeclose+0x64>
    release(&pi->lock);
    80004bac:	8526                	mv	a0,s1
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	116080e7          	jalr	278(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	e6c080e7          	jalr	-404(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004bc0:	60e2                	ld	ra,24(sp)
    80004bc2:	6442                	ld	s0,16(sp)
    80004bc4:	64a2                	ld	s1,8(sp)
    80004bc6:	6902                	ld	s2,0(sp)
    80004bc8:	6105                	addi	sp,sp,32
    80004bca:	8082                	ret
    pi->readopen = 0;
    80004bcc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bd0:	21c48513          	addi	a0,s1,540
    80004bd4:	ffffe097          	auipc	ra,0xffffe
    80004bd8:	9a4080e7          	jalr	-1628(ra) # 80002578 <wakeup>
    80004bdc:	b7e9                	j	80004ba6 <pipeclose+0x2c>
    release(&pi->lock);
    80004bde:	8526                	mv	a0,s1
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	0e4080e7          	jalr	228(ra) # 80000cc4 <release>
}
    80004be8:	bfe1                	j	80004bc0 <pipeclose+0x46>

0000000080004bea <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bea:	7119                	addi	sp,sp,-128
    80004bec:	fc86                	sd	ra,120(sp)
    80004bee:	f8a2                	sd	s0,112(sp)
    80004bf0:	f4a6                	sd	s1,104(sp)
    80004bf2:	f0ca                	sd	s2,96(sp)
    80004bf4:	ecce                	sd	s3,88(sp)
    80004bf6:	e8d2                	sd	s4,80(sp)
    80004bf8:	e4d6                	sd	s5,72(sp)
    80004bfa:	e0da                	sd	s6,64(sp)
    80004bfc:	fc5e                	sd	s7,56(sp)
    80004bfe:	f862                	sd	s8,48(sp)
    80004c00:	f466                	sd	s9,40(sp)
    80004c02:	f06a                	sd	s10,32(sp)
    80004c04:	ec6e                	sd	s11,24(sp)
    80004c06:	0100                	addi	s0,sp,128
    80004c08:	84aa                	mv	s1,a0
    80004c0a:	8cae                	mv	s9,a1
    80004c0c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	e22080e7          	jalr	-478(ra) # 80001a30 <myproc>
    80004c16:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	ff6080e7          	jalr	-10(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004c22:	0d605963          	blez	s6,80004cf4 <pipewrite+0x10a>
    80004c26:	89a6                	mv	s3,s1
    80004c28:	3b7d                	addiw	s6,s6,-1
    80004c2a:	1b02                	slli	s6,s6,0x20
    80004c2c:	020b5b13          	srli	s6,s6,0x20
    80004c30:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c32:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c36:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c3a:	5dfd                	li	s11,-1
    80004c3c:	000b8d1b          	sext.w	s10,s7
    80004c40:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c42:	2184a783          	lw	a5,536(s1)
    80004c46:	21c4a703          	lw	a4,540(s1)
    80004c4a:	2007879b          	addiw	a5,a5,512
    80004c4e:	02f71b63          	bne	a4,a5,80004c84 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c52:	2204a783          	lw	a5,544(s1)
    80004c56:	cbad                	beqz	a5,80004cc8 <pipewrite+0xde>
    80004c58:	03092783          	lw	a5,48(s2)
    80004c5c:	e7b5                	bnez	a5,80004cc8 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004c5e:	8556                	mv	a0,s5
    80004c60:	ffffe097          	auipc	ra,0xffffe
    80004c64:	918080e7          	jalr	-1768(ra) # 80002578 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c68:	85ce                	mv	a1,s3
    80004c6a:	8552                	mv	a0,s4
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	786080e7          	jalr	1926(ra) # 800023f2 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c74:	2184a783          	lw	a5,536(s1)
    80004c78:	21c4a703          	lw	a4,540(s1)
    80004c7c:	2007879b          	addiw	a5,a5,512
    80004c80:	fcf709e3          	beq	a4,a5,80004c52 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c84:	4685                	li	a3,1
    80004c86:	019b8633          	add	a2,s7,s9
    80004c8a:	f8f40593          	addi	a1,s0,-113
    80004c8e:	05093503          	ld	a0,80(s2)
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	c6a080e7          	jalr	-918(ra) # 800018fc <copyin>
    80004c9a:	05b50e63          	beq	a0,s11,80004cf6 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c9e:	21c4a783          	lw	a5,540(s1)
    80004ca2:	0017871b          	addiw	a4,a5,1
    80004ca6:	20e4ae23          	sw	a4,540(s1)
    80004caa:	1ff7f793          	andi	a5,a5,511
    80004cae:	97a6                	add	a5,a5,s1
    80004cb0:	f8f44703          	lbu	a4,-113(s0)
    80004cb4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004cb8:	001d0c1b          	addiw	s8,s10,1
    80004cbc:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004cc0:	036b8b63          	beq	s7,s6,80004cf6 <pipewrite+0x10c>
    80004cc4:	8bbe                	mv	s7,a5
    80004cc6:	bf9d                	j	80004c3c <pipewrite+0x52>
        release(&pi->lock);
    80004cc8:	8526                	mv	a0,s1
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	ffa080e7          	jalr	-6(ra) # 80000cc4 <release>
        return -1;
    80004cd2:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004cd4:	8562                	mv	a0,s8
    80004cd6:	70e6                	ld	ra,120(sp)
    80004cd8:	7446                	ld	s0,112(sp)
    80004cda:	74a6                	ld	s1,104(sp)
    80004cdc:	7906                	ld	s2,96(sp)
    80004cde:	69e6                	ld	s3,88(sp)
    80004ce0:	6a46                	ld	s4,80(sp)
    80004ce2:	6aa6                	ld	s5,72(sp)
    80004ce4:	6b06                	ld	s6,64(sp)
    80004ce6:	7be2                	ld	s7,56(sp)
    80004ce8:	7c42                	ld	s8,48(sp)
    80004cea:	7ca2                	ld	s9,40(sp)
    80004cec:	7d02                	ld	s10,32(sp)
    80004cee:	6de2                	ld	s11,24(sp)
    80004cf0:	6109                	addi	sp,sp,128
    80004cf2:	8082                	ret
  for(i = 0; i < n; i++){
    80004cf4:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004cf6:	21848513          	addi	a0,s1,536
    80004cfa:	ffffe097          	auipc	ra,0xffffe
    80004cfe:	87e080e7          	jalr	-1922(ra) # 80002578 <wakeup>
  release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	fc0080e7          	jalr	-64(ra) # 80000cc4 <release>
  return i;
    80004d0c:	b7e1                	j	80004cd4 <pipewrite+0xea>

0000000080004d0e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d0e:	715d                	addi	sp,sp,-80
    80004d10:	e486                	sd	ra,72(sp)
    80004d12:	e0a2                	sd	s0,64(sp)
    80004d14:	fc26                	sd	s1,56(sp)
    80004d16:	f84a                	sd	s2,48(sp)
    80004d18:	f44e                	sd	s3,40(sp)
    80004d1a:	f052                	sd	s4,32(sp)
    80004d1c:	ec56                	sd	s5,24(sp)
    80004d1e:	e85a                	sd	s6,16(sp)
    80004d20:	0880                	addi	s0,sp,80
    80004d22:	84aa                	mv	s1,a0
    80004d24:	892e                	mv	s2,a1
    80004d26:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	d08080e7          	jalr	-760(ra) # 80001a30 <myproc>
    80004d30:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d32:	8b26                	mv	s6,s1
    80004d34:	8526                	mv	a0,s1
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	eda080e7          	jalr	-294(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d3e:	2184a703          	lw	a4,536(s1)
    80004d42:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4a:	02f71463          	bne	a4,a5,80004d72 <piperead+0x64>
    80004d4e:	2244a783          	lw	a5,548(s1)
    80004d52:	c385                	beqz	a5,80004d72 <piperead+0x64>
    if(pr->killed){
    80004d54:	030a2783          	lw	a5,48(s4)
    80004d58:	ebc1                	bnez	a5,80004de8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d5a:	85da                	mv	a1,s6
    80004d5c:	854e                	mv	a0,s3
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	694080e7          	jalr	1684(ra) # 800023f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d66:	2184a703          	lw	a4,536(s1)
    80004d6a:	21c4a783          	lw	a5,540(s1)
    80004d6e:	fef700e3          	beq	a4,a5,80004d4e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d72:	09505263          	blez	s5,80004df6 <piperead+0xe8>
    80004d76:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d78:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d7a:	2184a783          	lw	a5,536(s1)
    80004d7e:	21c4a703          	lw	a4,540(s1)
    80004d82:	02f70d63          	beq	a4,a5,80004dbc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d86:	0017871b          	addiw	a4,a5,1
    80004d8a:	20e4ac23          	sw	a4,536(s1)
    80004d8e:	1ff7f793          	andi	a5,a5,511
    80004d92:	97a6                	add	a5,a5,s1
    80004d94:	0187c783          	lbu	a5,24(a5)
    80004d98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d9c:	4685                	li	a3,1
    80004d9e:	fbf40613          	addi	a2,s0,-65
    80004da2:	85ca                	mv	a1,s2
    80004da4:	050a3503          	ld	a0,80(s4)
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	ac8080e7          	jalr	-1336(ra) # 80001870 <copyout>
    80004db0:	01650663          	beq	a0,s6,80004dbc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db4:	2985                	addiw	s3,s3,1
    80004db6:	0905                	addi	s2,s2,1
    80004db8:	fd3a91e3          	bne	s5,s3,80004d7a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dbc:	21c48513          	addi	a0,s1,540
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	7b8080e7          	jalr	1976(ra) # 80002578 <wakeup>
  release(&pi->lock);
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	efa080e7          	jalr	-262(ra) # 80000cc4 <release>
  return i;
}
    80004dd2:	854e                	mv	a0,s3
    80004dd4:	60a6                	ld	ra,72(sp)
    80004dd6:	6406                	ld	s0,64(sp)
    80004dd8:	74e2                	ld	s1,56(sp)
    80004dda:	7942                	ld	s2,48(sp)
    80004ddc:	79a2                	ld	s3,40(sp)
    80004dde:	7a02                	ld	s4,32(sp)
    80004de0:	6ae2                	ld	s5,24(sp)
    80004de2:	6b42                	ld	s6,16(sp)
    80004de4:	6161                	addi	sp,sp,80
    80004de6:	8082                	ret
      release(&pi->lock);
    80004de8:	8526                	mv	a0,s1
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	eda080e7          	jalr	-294(ra) # 80000cc4 <release>
      return -1;
    80004df2:	59fd                	li	s3,-1
    80004df4:	bff9                	j	80004dd2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df6:	4981                	li	s3,0
    80004df8:	b7d1                	j	80004dbc <piperead+0xae>

0000000080004dfa <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004dfa:	df010113          	addi	sp,sp,-528
    80004dfe:	20113423          	sd	ra,520(sp)
    80004e02:	20813023          	sd	s0,512(sp)
    80004e06:	ffa6                	sd	s1,504(sp)
    80004e08:	fbca                	sd	s2,496(sp)
    80004e0a:	f7ce                	sd	s3,488(sp)
    80004e0c:	f3d2                	sd	s4,480(sp)
    80004e0e:	efd6                	sd	s5,472(sp)
    80004e10:	ebda                	sd	s6,464(sp)
    80004e12:	e7de                	sd	s7,456(sp)
    80004e14:	e3e2                	sd	s8,448(sp)
    80004e16:	ff66                	sd	s9,440(sp)
    80004e18:	fb6a                	sd	s10,432(sp)
    80004e1a:	f76e                	sd	s11,424(sp)
    80004e1c:	0c00                	addi	s0,sp,528
    80004e1e:	84aa                	mv	s1,a0
    80004e20:	dea43c23          	sd	a0,-520(s0)
    80004e24:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e28:	ffffd097          	auipc	ra,0xffffd
    80004e2c:	c08080e7          	jalr	-1016(ra) # 80001a30 <myproc>
    80004e30:	892a                	mv	s2,a0
  pte_t *pte, *kernelPte;

  begin_op();
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	446080e7          	jalr	1094(ra) # 80004278 <begin_op>

  if((ip = namei(path)) == 0){
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	230080e7          	jalr	560(ra) # 8000406c <namei>
    80004e44:	c92d                	beqz	a0,80004eb6 <exec+0xbc>
    80004e46:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	a74080e7          	jalr	-1420(ra) # 800038bc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e50:	04000713          	li	a4,64
    80004e54:	4681                	li	a3,0
    80004e56:	e4840613          	addi	a2,s0,-440
    80004e5a:	4581                	li	a1,0
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	d12080e7          	jalr	-750(ra) # 80003b70 <readi>
    80004e66:	04000793          	li	a5,64
    80004e6a:	00f51a63          	bne	a0,a5,80004e7e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e6e:	e4842703          	lw	a4,-440(s0)
    80004e72:	464c47b7          	lui	a5,0x464c4
    80004e76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e7a:	04f70463          	beq	a4,a5,80004ec2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	c9e080e7          	jalr	-866(ra) # 80003b1e <iunlockput>
    end_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	470080e7          	jalr	1136(ra) # 800042f8 <end_op>
  }
  return -1;
    80004e90:	557d                	li	a0,-1
}
    80004e92:	20813083          	ld	ra,520(sp)
    80004e96:	20013403          	ld	s0,512(sp)
    80004e9a:	74fe                	ld	s1,504(sp)
    80004e9c:	795e                	ld	s2,496(sp)
    80004e9e:	79be                	ld	s3,488(sp)
    80004ea0:	7a1e                	ld	s4,480(sp)
    80004ea2:	6afe                	ld	s5,472(sp)
    80004ea4:	6b5e                	ld	s6,464(sp)
    80004ea6:	6bbe                	ld	s7,456(sp)
    80004ea8:	6c1e                	ld	s8,448(sp)
    80004eaa:	7cfa                	ld	s9,440(sp)
    80004eac:	7d5a                	ld	s10,432(sp)
    80004eae:	7dba                	ld	s11,424(sp)
    80004eb0:	21010113          	addi	sp,sp,528
    80004eb4:	8082                	ret
    end_op();
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	442080e7          	jalr	1090(ra) # 800042f8 <end_op>
    return -1;
    80004ebe:	557d                	li	a0,-1
    80004ec0:	bfc9                	j	80004e92 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ec2:	854a                	mv	a0,s2
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	c30080e7          	jalr	-976(ra) # 80001af4 <proc_pagetable>
    80004ecc:	8baa                	mv	s7,a0
    80004ece:	d945                	beqz	a0,80004e7e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed0:	e6842983          	lw	s3,-408(s0)
    80004ed4:	e8045783          	lhu	a5,-384(s0)
    80004ed8:	c7ad                	beqz	a5,80004f42 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004eda:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004edc:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ede:	6c85                	lui	s9,0x1
    80004ee0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ee4:	def43823          	sd	a5,-528(s0)
    80004ee8:	a471                	j	80005174 <exec+0x37a>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eea:	00004517          	auipc	a0,0x4
    80004eee:	82e50513          	addi	a0,a0,-2002 # 80008718 <syscalls+0x290>
    80004ef2:	ffffb097          	auipc	ra,0xffffb
    80004ef6:	656080e7          	jalr	1622(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004efa:	8756                	mv	a4,s5
    80004efc:	012d86bb          	addw	a3,s11,s2
    80004f00:	4581                	li	a1,0
    80004f02:	8526                	mv	a0,s1
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	c6c080e7          	jalr	-916(ra) # 80003b70 <readi>
    80004f0c:	2501                	sext.w	a0,a0
    80004f0e:	20aa9a63          	bne	s5,a0,80005122 <exec+0x328>
  for(i = 0; i < sz; i += PGSIZE){
    80004f12:	6785                	lui	a5,0x1
    80004f14:	0127893b          	addw	s2,a5,s2
    80004f18:	77fd                	lui	a5,0xfffff
    80004f1a:	01478a3b          	addw	s4,a5,s4
    80004f1e:	25897263          	bgeu	s2,s8,80005162 <exec+0x368>
    pa = walkaddr(pagetable, va + i);
    80004f22:	02091593          	slli	a1,s2,0x20
    80004f26:	9181                	srli	a1,a1,0x20
    80004f28:	95ea                	add	a1,a1,s10
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	2a8080e7          	jalr	680(ra) # 800011d4 <walkaddr>
    80004f34:	862a                	mv	a2,a0
    if(pa == 0)
    80004f36:	d955                	beqz	a0,80004eea <exec+0xf0>
      n = PGSIZE;
    80004f38:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f3a:	fd9a70e3          	bgeu	s4,s9,80004efa <exec+0x100>
      n = sz - i;
    80004f3e:	8ad2                	mv	s5,s4
    80004f40:	bf6d                	j	80004efa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f42:	4901                	li	s2,0
  iunlockput(ip);
    80004f44:	8526                	mv	a0,s1
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	bd8080e7          	jalr	-1064(ra) # 80003b1e <iunlockput>
  end_op();
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	3aa080e7          	jalr	938(ra) # 800042f8 <end_op>
  p = myproc();
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	ada080e7          	jalr	-1318(ra) # 80001a30 <myproc>
    80004f5e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f60:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f64:	6785                	lui	a5,0x1
    80004f66:	17fd                	addi	a5,a5,-1
    80004f68:	993e                	add	s2,s2,a5
    80004f6a:	757d                	lui	a0,0xfffff
    80004f6c:	00a977b3          	and	a5,s2,a0
    80004f70:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f74:	6609                	lui	a2,0x2
    80004f76:	963e                	add	a2,a2,a5
    80004f78:	85be                	mv	a1,a5
    80004f7a:	855e                	mv	a0,s7
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	672080e7          	jalr	1650(ra) # 800015ee <uvmalloc>
    80004f84:	8b2a                	mv	s6,a0
  ip = 0;
    80004f86:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f88:	18050d63          	beqz	a0,80005122 <exec+0x328>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f8c:	75f9                	lui	a1,0xffffe
    80004f8e:	95aa                	add	a1,a1,a0
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	8ac080e7          	jalr	-1876(ra) # 8000183e <uvmclear>
  stackbase = sp - PGSIZE;
    80004f9a:	7c7d                	lui	s8,0xfffff
    80004f9c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f9e:	e0043783          	ld	a5,-512(s0)
    80004fa2:	6388                	ld	a0,0(a5)
    80004fa4:	c535                	beqz	a0,80005010 <exec+0x216>
    80004fa6:	e8840993          	addi	s3,s0,-376
    80004faa:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fae:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	ee4080e7          	jalr	-284(ra) # 80000e94 <strlen>
    80004fb8:	2505                	addiw	a0,a0,1
    80004fba:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fbe:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fc2:	19896463          	bltu	s2,s8,8000514a <exec+0x350>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fc6:	e0043d83          	ld	s11,-512(s0)
    80004fca:	000dba03          	ld	s4,0(s11)
    80004fce:	8552                	mv	a0,s4
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	ec4080e7          	jalr	-316(ra) # 80000e94 <strlen>
    80004fd8:	0015069b          	addiw	a3,a0,1
    80004fdc:	8652                	mv	a2,s4
    80004fde:	85ca                	mv	a1,s2
    80004fe0:	855e                	mv	a0,s7
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	88e080e7          	jalr	-1906(ra) # 80001870 <copyout>
    80004fea:	16054463          	bltz	a0,80005152 <exec+0x358>
    ustack[argc] = sp;
    80004fee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ff2:	0485                	addi	s1,s1,1
    80004ff4:	008d8793          	addi	a5,s11,8
    80004ff8:	e0f43023          	sd	a5,-512(s0)
    80004ffc:	008db503          	ld	a0,8(s11)
    80005000:	c911                	beqz	a0,80005014 <exec+0x21a>
    if(argc >= MAXARG)
    80005002:	09a1                	addi	s3,s3,8
    80005004:	fb3c96e3          	bne	s9,s3,80004fb0 <exec+0x1b6>
  sz = sz1;
    80005008:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500c:	4481                	li	s1,0
    8000500e:	aa11                	j	80005122 <exec+0x328>
  sp = sz;
    80005010:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005012:	4481                	li	s1,0
  ustack[argc] = 0;
    80005014:	00349793          	slli	a5,s1,0x3
    80005018:	f9040713          	addi	a4,s0,-112
    8000501c:	97ba                	add	a5,a5,a4
    8000501e:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005022:	00148693          	addi	a3,s1,1
    80005026:	068e                	slli	a3,a3,0x3
    80005028:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000502c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005030:	01897663          	bgeu	s2,s8,8000503c <exec+0x242>
  sz = sz1;
    80005034:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005038:	4481                	li	s1,0
    8000503a:	a0e5                	j	80005122 <exec+0x328>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000503c:	e8840613          	addi	a2,s0,-376
    80005040:	85ca                	mv	a1,s2
    80005042:	855e                	mv	a0,s7
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	82c080e7          	jalr	-2004(ra) # 80001870 <copyout>
    8000504c:	10054763          	bltz	a0,8000515a <exec+0x360>
  uvmunmap(p->kernelPageTable, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    80005050:	6605                	lui	a2,0x1
    80005052:	167d                	addi	a2,a2,-1
    80005054:	966a                	add	a2,a2,s10
    80005056:	4681                	li	a3,0
    80005058:	8231                	srli	a2,a2,0xc
    8000505a:	4581                	li	a1,0
    8000505c:	058ab503          	ld	a0,88(s5)
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	3e2080e7          	jalr	994(ra) # 80001442 <uvmunmap>
    80005068:	4981                	li	s3,0
    8000506a:	6a05                	lui	s4,0x1
    pte = walk(pagetable, j, 0);
    8000506c:	4601                	li	a2,0
    8000506e:	85ce                	mv	a1,s3
    80005070:	855e                	mv	a0,s7
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	0bc080e7          	jalr	188(ra) # 8000112e <walk>
    8000507a:	8c2a                	mv	s8,a0
    kernelPte = walk(p->kernelPageTable, j, 1);
    8000507c:	4605                	li	a2,1
    8000507e:	85ce                	mv	a1,s3
    80005080:	058ab503          	ld	a0,88(s5)
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	0aa080e7          	jalr	170(ra) # 8000112e <walk>
    *kernelPte = (*pte) & ~PTE_U;
    8000508c:	000c3783          	ld	a5,0(s8) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80005090:	9bbd                	andi	a5,a5,-17
    80005092:	e11c                	sd	a5,0(a0)
  for (j = 0; j < sz; j += PGSIZE){
    80005094:	99d2                	add	s3,s3,s4
    80005096:	fd69ebe3          	bltu	s3,s6,8000506c <exec+0x272>
  p->trapframe->a1 = sp;
    8000509a:	060ab783          	ld	a5,96(s5)
    8000509e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050a2:	df843783          	ld	a5,-520(s0)
    800050a6:	0007c703          	lbu	a4,0(a5)
    800050aa:	cf11                	beqz	a4,800050c6 <exec+0x2cc>
    800050ac:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050ae:	02f00693          	li	a3,47
    800050b2:	a039                	j	800050c0 <exec+0x2c6>
      last = s+1;
    800050b4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050b8:	0785                	addi	a5,a5,1
    800050ba:	fff7c703          	lbu	a4,-1(a5)
    800050be:	c701                	beqz	a4,800050c6 <exec+0x2cc>
    if(*s == '/')
    800050c0:	fed71ce3          	bne	a4,a3,800050b8 <exec+0x2be>
    800050c4:	bfc5                	j	800050b4 <exec+0x2ba>
  safestrcpy(p->name, last, sizeof(p->name));
    800050c6:	4641                	li	a2,16
    800050c8:	df843583          	ld	a1,-520(s0)
    800050cc:	160a8513          	addi	a0,s5,352
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	d92080e7          	jalr	-622(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    800050d8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050dc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050e0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050e4:	060ab783          	ld	a5,96(s5)
    800050e8:	e6043703          	ld	a4,-416(s0)
    800050ec:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ee:	060ab783          	ld	a5,96(s5)
    800050f2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050f6:	85ea                	mv	a1,s10
    800050f8:	ffffd097          	auipc	ra,0xffffd
    800050fc:	b6a080e7          	jalr	-1174(ra) # 80001c62 <proc_freepagetable>
  if(p->pid==1){
    80005100:	038aa703          	lw	a4,56(s5)
    80005104:	4785                	li	a5,1
    80005106:	00f70563          	beq	a4,a5,80005110 <exec+0x316>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000510a:	0004851b          	sext.w	a0,s1
    8000510e:	b351                	j	80004e92 <exec+0x98>
    vmprint(p->pagetable);
    80005110:	050ab503          	ld	a0,80(s5)
    80005114:	ffffd097          	auipc	ra,0xffffd
    80005118:	818080e7          	jalr	-2024(ra) # 8000192c <vmprint>
    8000511c:	b7fd                	j	8000510a <exec+0x310>
    8000511e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005122:	e0843583          	ld	a1,-504(s0)
    80005126:	855e                	mv	a0,s7
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	b3a080e7          	jalr	-1222(ra) # 80001c62 <proc_freepagetable>
  if(ip){
    80005130:	d40497e3          	bnez	s1,80004e7e <exec+0x84>
  return -1;
    80005134:	557d                	li	a0,-1
    80005136:	bbb1                	j	80004e92 <exec+0x98>
    80005138:	e1243423          	sd	s2,-504(s0)
    8000513c:	b7dd                	j	80005122 <exec+0x328>
    8000513e:	e1243423          	sd	s2,-504(s0)
    80005142:	b7c5                	j	80005122 <exec+0x328>
    80005144:	e1243423          	sd	s2,-504(s0)
    80005148:	bfe9                	j	80005122 <exec+0x328>
  sz = sz1;
    8000514a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000514e:	4481                	li	s1,0
    80005150:	bfc9                	j	80005122 <exec+0x328>
  sz = sz1;
    80005152:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005156:	4481                	li	s1,0
    80005158:	b7e9                	j	80005122 <exec+0x328>
  sz = sz1;
    8000515a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515e:	4481                	li	s1,0
    80005160:	b7c9                	j	80005122 <exec+0x328>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005162:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005166:	2b05                	addiw	s6,s6,1
    80005168:	0389899b          	addiw	s3,s3,56
    8000516c:	e8045783          	lhu	a5,-384(s0)
    80005170:	dcfb5ae3          	bge	s6,a5,80004f44 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005174:	2981                	sext.w	s3,s3
    80005176:	03800713          	li	a4,56
    8000517a:	86ce                	mv	a3,s3
    8000517c:	e1040613          	addi	a2,s0,-496
    80005180:	4581                	li	a1,0
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	9ec080e7          	jalr	-1556(ra) # 80003b70 <readi>
    8000518c:	03800793          	li	a5,56
    80005190:	f8f517e3          	bne	a0,a5,8000511e <exec+0x324>
    if(ph.type != ELF_PROG_LOAD)
    80005194:	e1042783          	lw	a5,-496(s0)
    80005198:	4705                	li	a4,1
    8000519a:	fce796e3          	bne	a5,a4,80005166 <exec+0x36c>
    if(ph.memsz < ph.filesz)
    8000519e:	e3843603          	ld	a2,-456(s0)
    800051a2:	e3043783          	ld	a5,-464(s0)
    800051a6:	f8f669e3          	bltu	a2,a5,80005138 <exec+0x33e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051aa:	e2043783          	ld	a5,-480(s0)
    800051ae:	963e                	add	a2,a2,a5
    800051b0:	f8f667e3          	bltu	a2,a5,8000513e <exec+0x344>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b4:	85ca                	mv	a1,s2
    800051b6:	855e                	mv	a0,s7
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	436080e7          	jalr	1078(ra) # 800015ee <uvmalloc>
    800051c0:	e0a43423          	sd	a0,-504(s0)
    800051c4:	fff50713          	addi	a4,a0,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    800051c8:	0c0007b7          	lui	a5,0xc000
    800051cc:	f6f77ce3          	bgeu	a4,a5,80005144 <exec+0x34a>
    if(ph.vaddr % PGSIZE != 0)
    800051d0:	e2043d03          	ld	s10,-480(s0)
    800051d4:	df043783          	ld	a5,-528(s0)
    800051d8:	00fd77b3          	and	a5,s10,a5
    800051dc:	f3b9                	bnez	a5,80005122 <exec+0x328>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051de:	e1842d83          	lw	s11,-488(s0)
    800051e2:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e6:	f60c0ee3          	beqz	s8,80005162 <exec+0x368>
    800051ea:	8a62                	mv	s4,s8
    800051ec:	4901                	li	s2,0
    800051ee:	bb15                	j	80004f22 <exec+0x128>

00000000800051f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f0:	7179                	addi	sp,sp,-48
    800051f2:	f406                	sd	ra,40(sp)
    800051f4:	f022                	sd	s0,32(sp)
    800051f6:	ec26                	sd	s1,24(sp)
    800051f8:	e84a                	sd	s2,16(sp)
    800051fa:	1800                	addi	s0,sp,48
    800051fc:	892e                	mv	s2,a1
    800051fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005200:	fdc40593          	addi	a1,s0,-36
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	a9c080e7          	jalr	-1380(ra) # 80002ca0 <argint>
    8000520c:	04054063          	bltz	a0,8000524c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005210:	fdc42703          	lw	a4,-36(s0)
    80005214:	47bd                	li	a5,15
    80005216:	02e7ed63          	bltu	a5,a4,80005250 <argfd+0x60>
    8000521a:	ffffd097          	auipc	ra,0xffffd
    8000521e:	816080e7          	jalr	-2026(ra) # 80001a30 <myproc>
    80005222:	fdc42703          	lw	a4,-36(s0)
    80005226:	01a70793          	addi	a5,a4,26
    8000522a:	078e                	slli	a5,a5,0x3
    8000522c:	953e                	add	a0,a0,a5
    8000522e:	651c                	ld	a5,8(a0)
    80005230:	c395                	beqz	a5,80005254 <argfd+0x64>
    return -1;
  if(pfd)
    80005232:	00090463          	beqz	s2,8000523a <argfd+0x4a>
    *pfd = fd;
    80005236:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523a:	4501                	li	a0,0
  if(pf)
    8000523c:	c091                	beqz	s1,80005240 <argfd+0x50>
    *pf = f;
    8000523e:	e09c                	sd	a5,0(s1)
}
    80005240:	70a2                	ld	ra,40(sp)
    80005242:	7402                	ld	s0,32(sp)
    80005244:	64e2                	ld	s1,24(sp)
    80005246:	6942                	ld	s2,16(sp)
    80005248:	6145                	addi	sp,sp,48
    8000524a:	8082                	ret
    return -1;
    8000524c:	557d                	li	a0,-1
    8000524e:	bfcd                	j	80005240 <argfd+0x50>
    return -1;
    80005250:	557d                	li	a0,-1
    80005252:	b7fd                	j	80005240 <argfd+0x50>
    80005254:	557d                	li	a0,-1
    80005256:	b7ed                	j	80005240 <argfd+0x50>

0000000080005258 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005258:	1101                	addi	sp,sp,-32
    8000525a:	ec06                	sd	ra,24(sp)
    8000525c:	e822                	sd	s0,16(sp)
    8000525e:	e426                	sd	s1,8(sp)
    80005260:	1000                	addi	s0,sp,32
    80005262:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	7cc080e7          	jalr	1996(ra) # 80001a30 <myproc>
    8000526c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000526e:	0d850793          	addi	a5,a0,216
    80005272:	4501                	li	a0,0
    80005274:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005276:	6398                	ld	a4,0(a5)
    80005278:	cb19                	beqz	a4,8000528e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000527a:	2505                	addiw	a0,a0,1
    8000527c:	07a1                	addi	a5,a5,8
    8000527e:	fed51ce3          	bne	a0,a3,80005276 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005282:	557d                	li	a0,-1
}
    80005284:	60e2                	ld	ra,24(sp)
    80005286:	6442                	ld	s0,16(sp)
    80005288:	64a2                	ld	s1,8(sp)
    8000528a:	6105                	addi	sp,sp,32
    8000528c:	8082                	ret
      p->ofile[fd] = f;
    8000528e:	01a50793          	addi	a5,a0,26
    80005292:	078e                	slli	a5,a5,0x3
    80005294:	963e                	add	a2,a2,a5
    80005296:	e604                	sd	s1,8(a2)
      return fd;
    80005298:	b7f5                	j	80005284 <fdalloc+0x2c>

000000008000529a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000529a:	715d                	addi	sp,sp,-80
    8000529c:	e486                	sd	ra,72(sp)
    8000529e:	e0a2                	sd	s0,64(sp)
    800052a0:	fc26                	sd	s1,56(sp)
    800052a2:	f84a                	sd	s2,48(sp)
    800052a4:	f44e                	sd	s3,40(sp)
    800052a6:	f052                	sd	s4,32(sp)
    800052a8:	ec56                	sd	s5,24(sp)
    800052aa:	0880                	addi	s0,sp,80
    800052ac:	89ae                	mv	s3,a1
    800052ae:	8ab2                	mv	s5,a2
    800052b0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	dd4080e7          	jalr	-556(ra) # 8000408a <nameiparent>
    800052be:	892a                	mv	s2,a0
    800052c0:	12050f63          	beqz	a0,800053fe <create+0x164>
    return 0;

  ilock(dp);
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	5f8080e7          	jalr	1528(ra) # 800038bc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052cc:	4601                	li	a2,0
    800052ce:	fb040593          	addi	a1,s0,-80
    800052d2:	854a                	mv	a0,s2
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	ac6080e7          	jalr	-1338(ra) # 80003d9a <dirlookup>
    800052dc:	84aa                	mv	s1,a0
    800052de:	c921                	beqz	a0,8000532e <create+0x94>
    iunlockput(dp);
    800052e0:	854a                	mv	a0,s2
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	83c080e7          	jalr	-1988(ra) # 80003b1e <iunlockput>
    ilock(ip);
    800052ea:	8526                	mv	a0,s1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	5d0080e7          	jalr	1488(ra) # 800038bc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f4:	2981                	sext.w	s3,s3
    800052f6:	4789                	li	a5,2
    800052f8:	02f99463          	bne	s3,a5,80005320 <create+0x86>
    800052fc:	0444d783          	lhu	a5,68(s1)
    80005300:	37f9                	addiw	a5,a5,-2
    80005302:	17c2                	slli	a5,a5,0x30
    80005304:	93c1                	srli	a5,a5,0x30
    80005306:	4705                	li	a4,1
    80005308:	00f76c63          	bltu	a4,a5,80005320 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000530c:	8526                	mv	a0,s1
    8000530e:	60a6                	ld	ra,72(sp)
    80005310:	6406                	ld	s0,64(sp)
    80005312:	74e2                	ld	s1,56(sp)
    80005314:	7942                	ld	s2,48(sp)
    80005316:	79a2                	ld	s3,40(sp)
    80005318:	7a02                	ld	s4,32(sp)
    8000531a:	6ae2                	ld	s5,24(sp)
    8000531c:	6161                	addi	sp,sp,80
    8000531e:	8082                	ret
    iunlockput(ip);
    80005320:	8526                	mv	a0,s1
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	7fc080e7          	jalr	2044(ra) # 80003b1e <iunlockput>
    return 0;
    8000532a:	4481                	li	s1,0
    8000532c:	b7c5                	j	8000530c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000532e:	85ce                	mv	a1,s3
    80005330:	00092503          	lw	a0,0(s2)
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	3f0080e7          	jalr	1008(ra) # 80003724 <ialloc>
    8000533c:	84aa                	mv	s1,a0
    8000533e:	c529                	beqz	a0,80005388 <create+0xee>
  ilock(ip);
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	57c080e7          	jalr	1404(ra) # 800038bc <ilock>
  ip->major = major;
    80005348:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000534c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005350:	4785                	li	a5,1
    80005352:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005356:	8526                	mv	a0,s1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	49a080e7          	jalr	1178(ra) # 800037f2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005360:	2981                	sext.w	s3,s3
    80005362:	4785                	li	a5,1
    80005364:	02f98a63          	beq	s3,a5,80005398 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005368:	40d0                	lw	a2,4(s1)
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	854a                	mv	a0,s2
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	c3a080e7          	jalr	-966(ra) # 80003faa <dirlink>
    80005378:	06054b63          	bltz	a0,800053ee <create+0x154>
  iunlockput(dp);
    8000537c:	854a                	mv	a0,s2
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	7a0080e7          	jalr	1952(ra) # 80003b1e <iunlockput>
  return ip;
    80005386:	b759                	j	8000530c <create+0x72>
    panic("create: ialloc");
    80005388:	00003517          	auipc	a0,0x3
    8000538c:	3b050513          	addi	a0,a0,944 # 80008738 <syscalls+0x2b0>
    80005390:	ffffb097          	auipc	ra,0xffffb
    80005394:	1b8080e7          	jalr	440(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005398:	04a95783          	lhu	a5,74(s2)
    8000539c:	2785                	addiw	a5,a5,1
    8000539e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053a2:	854a                	mv	a0,s2
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	44e080e7          	jalr	1102(ra) # 800037f2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ac:	40d0                	lw	a2,4(s1)
    800053ae:	00003597          	auipc	a1,0x3
    800053b2:	39a58593          	addi	a1,a1,922 # 80008748 <syscalls+0x2c0>
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	bf2080e7          	jalr	-1038(ra) # 80003faa <dirlink>
    800053c0:	00054f63          	bltz	a0,800053de <create+0x144>
    800053c4:	00492603          	lw	a2,4(s2)
    800053c8:	00003597          	auipc	a1,0x3
    800053cc:	38858593          	addi	a1,a1,904 # 80008750 <syscalls+0x2c8>
    800053d0:	8526                	mv	a0,s1
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	bd8080e7          	jalr	-1064(ra) # 80003faa <dirlink>
    800053da:	f80557e3          	bgez	a0,80005368 <create+0xce>
      panic("create dots");
    800053de:	00003517          	auipc	a0,0x3
    800053e2:	37a50513          	addi	a0,a0,890 # 80008758 <syscalls+0x2d0>
    800053e6:	ffffb097          	auipc	ra,0xffffb
    800053ea:	162080e7          	jalr	354(ra) # 80000548 <panic>
    panic("create: dirlink");
    800053ee:	00003517          	auipc	a0,0x3
    800053f2:	37a50513          	addi	a0,a0,890 # 80008768 <syscalls+0x2e0>
    800053f6:	ffffb097          	auipc	ra,0xffffb
    800053fa:	152080e7          	jalr	338(ra) # 80000548 <panic>
    return 0;
    800053fe:	84aa                	mv	s1,a0
    80005400:	b731                	j	8000530c <create+0x72>

0000000080005402 <sys_dup>:
{
    80005402:	7179                	addi	sp,sp,-48
    80005404:	f406                	sd	ra,40(sp)
    80005406:	f022                	sd	s0,32(sp)
    80005408:	ec26                	sd	s1,24(sp)
    8000540a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000540c:	fd840613          	addi	a2,s0,-40
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	ddc080e7          	jalr	-548(ra) # 800051f0 <argfd>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000541e:	02054363          	bltz	a0,80005444 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005422:	fd843503          	ld	a0,-40(s0)
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	e32080e7          	jalr	-462(ra) # 80005258 <fdalloc>
    8000542e:	84aa                	mv	s1,a0
    return -1;
    80005430:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005432:	00054963          	bltz	a0,80005444 <sys_dup+0x42>
  filedup(f);
    80005436:	fd843503          	ld	a0,-40(s0)
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	2be080e7          	jalr	702(ra) # 800046f8 <filedup>
  return fd;
    80005442:	87a6                	mv	a5,s1
}
    80005444:	853e                	mv	a0,a5
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6145                	addi	sp,sp,48
    8000544e:	8082                	ret

0000000080005450 <sys_read>:
{
    80005450:	7179                	addi	sp,sp,-48
    80005452:	f406                	sd	ra,40(sp)
    80005454:	f022                	sd	s0,32(sp)
    80005456:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005458:	fe840613          	addi	a2,s0,-24
    8000545c:	4581                	li	a1,0
    8000545e:	4501                	li	a0,0
    80005460:	00000097          	auipc	ra,0x0
    80005464:	d90080e7          	jalr	-624(ra) # 800051f0 <argfd>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546a:	04054163          	bltz	a0,800054ac <sys_read+0x5c>
    8000546e:	fe440593          	addi	a1,s0,-28
    80005472:	4509                	li	a0,2
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	82c080e7          	jalr	-2004(ra) # 80002ca0 <argint>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	02054763          	bltz	a0,800054ac <sys_read+0x5c>
    80005482:	fd840593          	addi	a1,s0,-40
    80005486:	4505                	li	a0,1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	83a080e7          	jalr	-1990(ra) # 80002cc2 <argaddr>
    return -1;
    80005490:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005492:	00054d63          	bltz	a0,800054ac <sys_read+0x5c>
  return fileread(f, p, n);
    80005496:	fe442603          	lw	a2,-28(s0)
    8000549a:	fd843583          	ld	a1,-40(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	3e2080e7          	jalr	994(ra) # 80004884 <fileread>
    800054aa:	87aa                	mv	a5,a0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	70a2                	ld	ra,40(sp)
    800054b0:	7402                	ld	s0,32(sp)
    800054b2:	6145                	addi	sp,sp,48
    800054b4:	8082                	ret

00000000800054b6 <sys_write>:
{
    800054b6:	7179                	addi	sp,sp,-48
    800054b8:	f406                	sd	ra,40(sp)
    800054ba:	f022                	sd	s0,32(sp)
    800054bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054be:	fe840613          	addi	a2,s0,-24
    800054c2:	4581                	li	a1,0
    800054c4:	4501                	li	a0,0
    800054c6:	00000097          	auipc	ra,0x0
    800054ca:	d2a080e7          	jalr	-726(ra) # 800051f0 <argfd>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	04054163          	bltz	a0,80005512 <sys_write+0x5c>
    800054d4:	fe440593          	addi	a1,s0,-28
    800054d8:	4509                	li	a0,2
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	7c6080e7          	jalr	1990(ra) # 80002ca0 <argint>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	02054763          	bltz	a0,80005512 <sys_write+0x5c>
    800054e8:	fd840593          	addi	a1,s0,-40
    800054ec:	4505                	li	a0,1
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	7d4080e7          	jalr	2004(ra) # 80002cc2 <argaddr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f8:	00054d63          	bltz	a0,80005512 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054fc:	fe442603          	lw	a2,-28(s0)
    80005500:	fd843583          	ld	a1,-40(s0)
    80005504:	fe843503          	ld	a0,-24(s0)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	43e080e7          	jalr	1086(ra) # 80004946 <filewrite>
    80005510:	87aa                	mv	a5,a0
}
    80005512:	853e                	mv	a0,a5
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	6145                	addi	sp,sp,48
    8000551a:	8082                	ret

000000008000551c <sys_close>:
{
    8000551c:	1101                	addi	sp,sp,-32
    8000551e:	ec06                	sd	ra,24(sp)
    80005520:	e822                	sd	s0,16(sp)
    80005522:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005524:	fe040613          	addi	a2,s0,-32
    80005528:	fec40593          	addi	a1,s0,-20
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	cc2080e7          	jalr	-830(ra) # 800051f0 <argfd>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005538:	02054463          	bltz	a0,80005560 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000553c:	ffffc097          	auipc	ra,0xffffc
    80005540:	4f4080e7          	jalr	1268(ra) # 80001a30 <myproc>
    80005544:	fec42783          	lw	a5,-20(s0)
    80005548:	07e9                	addi	a5,a5,26
    8000554a:	078e                	slli	a5,a5,0x3
    8000554c:	97aa                	add	a5,a5,a0
    8000554e:	0007b423          	sd	zero,8(a5) # c000008 <_entry-0x73fffff8>
  fileclose(f);
    80005552:	fe043503          	ld	a0,-32(s0)
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	1f4080e7          	jalr	500(ra) # 8000474a <fileclose>
  return 0;
    8000555e:	4781                	li	a5,0
}
    80005560:	853e                	mv	a0,a5
    80005562:	60e2                	ld	ra,24(sp)
    80005564:	6442                	ld	s0,16(sp)
    80005566:	6105                	addi	sp,sp,32
    80005568:	8082                	ret

000000008000556a <sys_fstat>:
{
    8000556a:	1101                	addi	sp,sp,-32
    8000556c:	ec06                	sd	ra,24(sp)
    8000556e:	e822                	sd	s0,16(sp)
    80005570:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005572:	fe840613          	addi	a2,s0,-24
    80005576:	4581                	li	a1,0
    80005578:	4501                	li	a0,0
    8000557a:	00000097          	auipc	ra,0x0
    8000557e:	c76080e7          	jalr	-906(ra) # 800051f0 <argfd>
    return -1;
    80005582:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005584:	02054563          	bltz	a0,800055ae <sys_fstat+0x44>
    80005588:	fe040593          	addi	a1,s0,-32
    8000558c:	4505                	li	a0,1
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	734080e7          	jalr	1844(ra) # 80002cc2 <argaddr>
    return -1;
    80005596:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005598:	00054b63          	bltz	a0,800055ae <sys_fstat+0x44>
  return filestat(f, st);
    8000559c:	fe043583          	ld	a1,-32(s0)
    800055a0:	fe843503          	ld	a0,-24(s0)
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	26e080e7          	jalr	622(ra) # 80004812 <filestat>
    800055ac:	87aa                	mv	a5,a0
}
    800055ae:	853e                	mv	a0,a5
    800055b0:	60e2                	ld	ra,24(sp)
    800055b2:	6442                	ld	s0,16(sp)
    800055b4:	6105                	addi	sp,sp,32
    800055b6:	8082                	ret

00000000800055b8 <sys_link>:
{
    800055b8:	7169                	addi	sp,sp,-304
    800055ba:	f606                	sd	ra,296(sp)
    800055bc:	f222                	sd	s0,288(sp)
    800055be:	ee26                	sd	s1,280(sp)
    800055c0:	ea4a                	sd	s2,272(sp)
    800055c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c4:	08000613          	li	a2,128
    800055c8:	ed040593          	addi	a1,s0,-304
    800055cc:	4501                	li	a0,0
    800055ce:	ffffd097          	auipc	ra,0xffffd
    800055d2:	716080e7          	jalr	1814(ra) # 80002ce4 <argstr>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d8:	10054e63          	bltz	a0,800056f4 <sys_link+0x13c>
    800055dc:	08000613          	li	a2,128
    800055e0:	f5040593          	addi	a1,s0,-176
    800055e4:	4505                	li	a0,1
    800055e6:	ffffd097          	auipc	ra,0xffffd
    800055ea:	6fe080e7          	jalr	1790(ra) # 80002ce4 <argstr>
    return -1;
    800055ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f0:	10054263          	bltz	a0,800056f4 <sys_link+0x13c>
  begin_op();
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	c84080e7          	jalr	-892(ra) # 80004278 <begin_op>
  if((ip = namei(old)) == 0){
    800055fc:	ed040513          	addi	a0,s0,-304
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	a6c080e7          	jalr	-1428(ra) # 8000406c <namei>
    80005608:	84aa                	mv	s1,a0
    8000560a:	c551                	beqz	a0,80005696 <sys_link+0xde>
  ilock(ip);
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	2b0080e7          	jalr	688(ra) # 800038bc <ilock>
  if(ip->type == T_DIR){
    80005614:	04449703          	lh	a4,68(s1)
    80005618:	4785                	li	a5,1
    8000561a:	08f70463          	beq	a4,a5,800056a2 <sys_link+0xea>
  ip->nlink++;
    8000561e:	04a4d783          	lhu	a5,74(s1)
    80005622:	2785                	addiw	a5,a5,1
    80005624:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	1c8080e7          	jalr	456(ra) # 800037f2 <iupdate>
  iunlock(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	34a080e7          	jalr	842(ra) # 8000397e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000563c:	fd040593          	addi	a1,s0,-48
    80005640:	f5040513          	addi	a0,s0,-176
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	a46080e7          	jalr	-1466(ra) # 8000408a <nameiparent>
    8000564c:	892a                	mv	s2,a0
    8000564e:	c935                	beqz	a0,800056c2 <sys_link+0x10a>
  ilock(dp);
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	26c080e7          	jalr	620(ra) # 800038bc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005658:	00092703          	lw	a4,0(s2)
    8000565c:	409c                	lw	a5,0(s1)
    8000565e:	04f71d63          	bne	a4,a5,800056b8 <sys_link+0x100>
    80005662:	40d0                	lw	a2,4(s1)
    80005664:	fd040593          	addi	a1,s0,-48
    80005668:	854a                	mv	a0,s2
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	940080e7          	jalr	-1728(ra) # 80003faa <dirlink>
    80005672:	04054363          	bltz	a0,800056b8 <sys_link+0x100>
  iunlockput(dp);
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	4a6080e7          	jalr	1190(ra) # 80003b1e <iunlockput>
  iput(ip);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	3f4080e7          	jalr	1012(ra) # 80003a76 <iput>
  end_op();
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	c6e080e7          	jalr	-914(ra) # 800042f8 <end_op>
  return 0;
    80005692:	4781                	li	a5,0
    80005694:	a085                	j	800056f4 <sys_link+0x13c>
    end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	c62080e7          	jalr	-926(ra) # 800042f8 <end_op>
    return -1;
    8000569e:	57fd                	li	a5,-1
    800056a0:	a891                	j	800056f4 <sys_link+0x13c>
    iunlockput(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	47a080e7          	jalr	1146(ra) # 80003b1e <iunlockput>
    end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	c4c080e7          	jalr	-948(ra) # 800042f8 <end_op>
    return -1;
    800056b4:	57fd                	li	a5,-1
    800056b6:	a83d                	j	800056f4 <sys_link+0x13c>
    iunlockput(dp);
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	464080e7          	jalr	1124(ra) # 80003b1e <iunlockput>
  ilock(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	1f8080e7          	jalr	504(ra) # 800038bc <ilock>
  ip->nlink--;
    800056cc:	04a4d783          	lhu	a5,74(s1)
    800056d0:	37fd                	addiw	a5,a5,-1
    800056d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	11a080e7          	jalr	282(ra) # 800037f2 <iupdate>
  iunlockput(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	43c080e7          	jalr	1084(ra) # 80003b1e <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	c0e080e7          	jalr	-1010(ra) # 800042f8 <end_op>
  return -1;
    800056f2:	57fd                	li	a5,-1
}
    800056f4:	853e                	mv	a0,a5
    800056f6:	70b2                	ld	ra,296(sp)
    800056f8:	7412                	ld	s0,288(sp)
    800056fa:	64f2                	ld	s1,280(sp)
    800056fc:	6952                	ld	s2,272(sp)
    800056fe:	6155                	addi	sp,sp,304
    80005700:	8082                	ret

0000000080005702 <sys_unlink>:
{
    80005702:	7151                	addi	sp,sp,-240
    80005704:	f586                	sd	ra,232(sp)
    80005706:	f1a2                	sd	s0,224(sp)
    80005708:	eda6                	sd	s1,216(sp)
    8000570a:	e9ca                	sd	s2,208(sp)
    8000570c:	e5ce                	sd	s3,200(sp)
    8000570e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005710:	08000613          	li	a2,128
    80005714:	f3040593          	addi	a1,s0,-208
    80005718:	4501                	li	a0,0
    8000571a:	ffffd097          	auipc	ra,0xffffd
    8000571e:	5ca080e7          	jalr	1482(ra) # 80002ce4 <argstr>
    80005722:	18054163          	bltz	a0,800058a4 <sys_unlink+0x1a2>
  begin_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	b52080e7          	jalr	-1198(ra) # 80004278 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000572e:	fb040593          	addi	a1,s0,-80
    80005732:	f3040513          	addi	a0,s0,-208
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	954080e7          	jalr	-1708(ra) # 8000408a <nameiparent>
    8000573e:	84aa                	mv	s1,a0
    80005740:	c979                	beqz	a0,80005816 <sys_unlink+0x114>
  ilock(dp);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	17a080e7          	jalr	378(ra) # 800038bc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000574a:	00003597          	auipc	a1,0x3
    8000574e:	ffe58593          	addi	a1,a1,-2 # 80008748 <syscalls+0x2c0>
    80005752:	fb040513          	addi	a0,s0,-80
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	62a080e7          	jalr	1578(ra) # 80003d80 <namecmp>
    8000575e:	14050a63          	beqz	a0,800058b2 <sys_unlink+0x1b0>
    80005762:	00003597          	auipc	a1,0x3
    80005766:	fee58593          	addi	a1,a1,-18 # 80008750 <syscalls+0x2c8>
    8000576a:	fb040513          	addi	a0,s0,-80
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	612080e7          	jalr	1554(ra) # 80003d80 <namecmp>
    80005776:	12050e63          	beqz	a0,800058b2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000577a:	f2c40613          	addi	a2,s0,-212
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	616080e7          	jalr	1558(ra) # 80003d9a <dirlookup>
    8000578c:	892a                	mv	s2,a0
    8000578e:	12050263          	beqz	a0,800058b2 <sys_unlink+0x1b0>
  ilock(ip);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	12a080e7          	jalr	298(ra) # 800038bc <ilock>
  if(ip->nlink < 1)
    8000579a:	04a91783          	lh	a5,74(s2)
    8000579e:	08f05263          	blez	a5,80005822 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057a2:	04491703          	lh	a4,68(s2)
    800057a6:	4785                	li	a5,1
    800057a8:	08f70563          	beq	a4,a5,80005832 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ac:	4641                	li	a2,16
    800057ae:	4581                	li	a1,0
    800057b0:	fc040513          	addi	a0,s0,-64
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	558080e7          	jalr	1368(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057bc:	4741                	li	a4,16
    800057be:	f2c42683          	lw	a3,-212(s0)
    800057c2:	fc040613          	addi	a2,s0,-64
    800057c6:	4581                	li	a1,0
    800057c8:	8526                	mv	a0,s1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	49c080e7          	jalr	1180(ra) # 80003c66 <writei>
    800057d2:	47c1                	li	a5,16
    800057d4:	0af51563          	bne	a0,a5,8000587e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d8:	04491703          	lh	a4,68(s2)
    800057dc:	4785                	li	a5,1
    800057de:	0af70863          	beq	a4,a5,8000588e <sys_unlink+0x18c>
  iunlockput(dp);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	33a080e7          	jalr	826(ra) # 80003b1e <iunlockput>
  ip->nlink--;
    800057ec:	04a95783          	lhu	a5,74(s2)
    800057f0:	37fd                	addiw	a5,a5,-1
    800057f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	ffa080e7          	jalr	-6(ra) # 800037f2 <iupdate>
  iunlockput(ip);
    80005800:	854a                	mv	a0,s2
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	31c080e7          	jalr	796(ra) # 80003b1e <iunlockput>
  end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	aee080e7          	jalr	-1298(ra) # 800042f8 <end_op>
  return 0;
    80005812:	4501                	li	a0,0
    80005814:	a84d                	j	800058c6 <sys_unlink+0x1c4>
    end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	ae2080e7          	jalr	-1310(ra) # 800042f8 <end_op>
    return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	a05d                	j	800058c6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005822:	00003517          	auipc	a0,0x3
    80005826:	f5650513          	addi	a0,a0,-170 # 80008778 <syscalls+0x2f0>
    8000582a:	ffffb097          	auipc	ra,0xffffb
    8000582e:	d1e080e7          	jalr	-738(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005832:	04c92703          	lw	a4,76(s2)
    80005836:	02000793          	li	a5,32
    8000583a:	f6e7f9e3          	bgeu	a5,a4,800057ac <sys_unlink+0xaa>
    8000583e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005842:	4741                	li	a4,16
    80005844:	86ce                	mv	a3,s3
    80005846:	f1840613          	addi	a2,s0,-232
    8000584a:	4581                	li	a1,0
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	322080e7          	jalr	802(ra) # 80003b70 <readi>
    80005856:	47c1                	li	a5,16
    80005858:	00f51b63          	bne	a0,a5,8000586e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000585c:	f1845783          	lhu	a5,-232(s0)
    80005860:	e7a1                	bnez	a5,800058a8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005862:	29c1                	addiw	s3,s3,16
    80005864:	04c92783          	lw	a5,76(s2)
    80005868:	fcf9ede3          	bltu	s3,a5,80005842 <sys_unlink+0x140>
    8000586c:	b781                	j	800057ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000586e:	00003517          	auipc	a0,0x3
    80005872:	f2250513          	addi	a0,a0,-222 # 80008790 <syscalls+0x308>
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	cd2080e7          	jalr	-814(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000587e:	00003517          	auipc	a0,0x3
    80005882:	f2a50513          	addi	a0,a0,-214 # 800087a8 <syscalls+0x320>
    80005886:	ffffb097          	auipc	ra,0xffffb
    8000588a:	cc2080e7          	jalr	-830(ra) # 80000548 <panic>
    dp->nlink--;
    8000588e:	04a4d783          	lhu	a5,74(s1)
    80005892:	37fd                	addiw	a5,a5,-1
    80005894:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	f58080e7          	jalr	-168(ra) # 800037f2 <iupdate>
    800058a2:	b781                	j	800057e2 <sys_unlink+0xe0>
    return -1;
    800058a4:	557d                	li	a0,-1
    800058a6:	a005                	j	800058c6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a8:	854a                	mv	a0,s2
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	274080e7          	jalr	628(ra) # 80003b1e <iunlockput>
  iunlockput(dp);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	26a080e7          	jalr	618(ra) # 80003b1e <iunlockput>
  end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	a3c080e7          	jalr	-1476(ra) # 800042f8 <end_op>
  return -1;
    800058c4:	557d                	li	a0,-1
}
    800058c6:	70ae                	ld	ra,232(sp)
    800058c8:	740e                	ld	s0,224(sp)
    800058ca:	64ee                	ld	s1,216(sp)
    800058cc:	694e                	ld	s2,208(sp)
    800058ce:	69ae                	ld	s3,200(sp)
    800058d0:	616d                	addi	sp,sp,240
    800058d2:	8082                	ret

00000000800058d4 <sys_open>:

uint64
sys_open(void)
{
    800058d4:	7131                	addi	sp,sp,-192
    800058d6:	fd06                	sd	ra,184(sp)
    800058d8:	f922                	sd	s0,176(sp)
    800058da:	f526                	sd	s1,168(sp)
    800058dc:	f14a                	sd	s2,160(sp)
    800058de:	ed4e                	sd	s3,152(sp)
    800058e0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e2:	08000613          	li	a2,128
    800058e6:	f5040593          	addi	a1,s0,-176
    800058ea:	4501                	li	a0,0
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	3f8080e7          	jalr	1016(ra) # 80002ce4 <argstr>
    return -1;
    800058f4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f6:	0c054163          	bltz	a0,800059b8 <sys_open+0xe4>
    800058fa:	f4c40593          	addi	a1,s0,-180
    800058fe:	4505                	li	a0,1
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	3a0080e7          	jalr	928(ra) # 80002ca0 <argint>
    80005908:	0a054863          	bltz	a0,800059b8 <sys_open+0xe4>

  begin_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	96c080e7          	jalr	-1684(ra) # 80004278 <begin_op>

  if(omode & O_CREATE){
    80005914:	f4c42783          	lw	a5,-180(s0)
    80005918:	2007f793          	andi	a5,a5,512
    8000591c:	cbdd                	beqz	a5,800059d2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000591e:	4681                	li	a3,0
    80005920:	4601                	li	a2,0
    80005922:	4589                	li	a1,2
    80005924:	f5040513          	addi	a0,s0,-176
    80005928:	00000097          	auipc	ra,0x0
    8000592c:	972080e7          	jalr	-1678(ra) # 8000529a <create>
    80005930:	892a                	mv	s2,a0
    if(ip == 0){
    80005932:	c959                	beqz	a0,800059c8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005934:	04491703          	lh	a4,68(s2)
    80005938:	478d                	li	a5,3
    8000593a:	00f71763          	bne	a4,a5,80005948 <sys_open+0x74>
    8000593e:	04695703          	lhu	a4,70(s2)
    80005942:	47a5                	li	a5,9
    80005944:	0ce7ec63          	bltu	a5,a4,80005a1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	d46080e7          	jalr	-698(ra) # 8000468e <filealloc>
    80005950:	89aa                	mv	s3,a0
    80005952:	10050263          	beqz	a0,80005a56 <sys_open+0x182>
    80005956:	00000097          	auipc	ra,0x0
    8000595a:	902080e7          	jalr	-1790(ra) # 80005258 <fdalloc>
    8000595e:	84aa                	mv	s1,a0
    80005960:	0e054663          	bltz	a0,80005a4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	478d                	li	a5,3
    8000596a:	0cf70463          	beq	a4,a5,80005a32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000596e:	4789                	li	a5,2
    80005970:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005974:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005978:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000597c:	f4c42783          	lw	a5,-180(s0)
    80005980:	0017c713          	xori	a4,a5,1
    80005984:	8b05                	andi	a4,a4,1
    80005986:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000598a:	0037f713          	andi	a4,a5,3
    8000598e:	00e03733          	snez	a4,a4
    80005992:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005996:	4007f793          	andi	a5,a5,1024
    8000599a:	c791                	beqz	a5,800059a6 <sys_open+0xd2>
    8000599c:	04491703          	lh	a4,68(s2)
    800059a0:	4789                	li	a5,2
    800059a2:	08f70f63          	beq	a4,a5,80005a40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	fd6080e7          	jalr	-42(ra) # 8000397e <iunlock>
  end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	948080e7          	jalr	-1720(ra) # 800042f8 <end_op>

  return fd;
}
    800059b8:	8526                	mv	a0,s1
    800059ba:	70ea                	ld	ra,184(sp)
    800059bc:	744a                	ld	s0,176(sp)
    800059be:	74aa                	ld	s1,168(sp)
    800059c0:	790a                	ld	s2,160(sp)
    800059c2:	69ea                	ld	s3,152(sp)
    800059c4:	6129                	addi	sp,sp,192
    800059c6:	8082                	ret
      end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	930080e7          	jalr	-1744(ra) # 800042f8 <end_op>
      return -1;
    800059d0:	b7e5                	j	800059b8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059d2:	f5040513          	addi	a0,s0,-176
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	696080e7          	jalr	1686(ra) # 8000406c <namei>
    800059de:	892a                	mv	s2,a0
    800059e0:	c905                	beqz	a0,80005a10 <sys_open+0x13c>
    ilock(ip);
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	eda080e7          	jalr	-294(ra) # 800038bc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ea:	04491703          	lh	a4,68(s2)
    800059ee:	4785                	li	a5,1
    800059f0:	f4f712e3          	bne	a4,a5,80005934 <sys_open+0x60>
    800059f4:	f4c42783          	lw	a5,-180(s0)
    800059f8:	dba1                	beqz	a5,80005948 <sys_open+0x74>
      iunlockput(ip);
    800059fa:	854a                	mv	a0,s2
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	122080e7          	jalr	290(ra) # 80003b1e <iunlockput>
      end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	8f4080e7          	jalr	-1804(ra) # 800042f8 <end_op>
      return -1;
    80005a0c:	54fd                	li	s1,-1
    80005a0e:	b76d                	j	800059b8 <sys_open+0xe4>
      end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	8e8080e7          	jalr	-1816(ra) # 800042f8 <end_op>
      return -1;
    80005a18:	54fd                	li	s1,-1
    80005a1a:	bf79                	j	800059b8 <sys_open+0xe4>
    iunlockput(ip);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	100080e7          	jalr	256(ra) # 80003b1e <iunlockput>
    end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	8d2080e7          	jalr	-1838(ra) # 800042f8 <end_op>
    return -1;
    80005a2e:	54fd                	li	s1,-1
    80005a30:	b761                	j	800059b8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a36:	04691783          	lh	a5,70(s2)
    80005a3a:	02f99223          	sh	a5,36(s3)
    80005a3e:	bf2d                	j	80005978 <sys_open+0xa4>
    itrunc(ip);
    80005a40:	854a                	mv	a0,s2
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	f88080e7          	jalr	-120(ra) # 800039ca <itrunc>
    80005a4a:	bfb1                	j	800059a6 <sys_open+0xd2>
      fileclose(f);
    80005a4c:	854e                	mv	a0,s3
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	cfc080e7          	jalr	-772(ra) # 8000474a <fileclose>
    iunlockput(ip);
    80005a56:	854a                	mv	a0,s2
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	0c6080e7          	jalr	198(ra) # 80003b1e <iunlockput>
    end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	898080e7          	jalr	-1896(ra) # 800042f8 <end_op>
    return -1;
    80005a68:	54fd                	li	s1,-1
    80005a6a:	b7b9                	j	800059b8 <sys_open+0xe4>

0000000080005a6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a6c:	7175                	addi	sp,sp,-144
    80005a6e:	e506                	sd	ra,136(sp)
    80005a70:	e122                	sd	s0,128(sp)
    80005a72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	804080e7          	jalr	-2044(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a7c:	08000613          	li	a2,128
    80005a80:	f7040593          	addi	a1,s0,-144
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	25e080e7          	jalr	606(ra) # 80002ce4 <argstr>
    80005a8e:	02054963          	bltz	a0,80005ac0 <sys_mkdir+0x54>
    80005a92:	4681                	li	a3,0
    80005a94:	4601                	li	a2,0
    80005a96:	4585                	li	a1,1
    80005a98:	f7040513          	addi	a0,s0,-144
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	7fe080e7          	jalr	2046(ra) # 8000529a <create>
    80005aa4:	cd11                	beqz	a0,80005ac0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	078080e7          	jalr	120(ra) # 80003b1e <iunlockput>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	84a080e7          	jalr	-1974(ra) # 800042f8 <end_op>
  return 0;
    80005ab6:	4501                	li	a0,0
}
    80005ab8:	60aa                	ld	ra,136(sp)
    80005aba:	640a                	ld	s0,128(sp)
    80005abc:	6149                	addi	sp,sp,144
    80005abe:	8082                	ret
    end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	838080e7          	jalr	-1992(ra) # 800042f8 <end_op>
    return -1;
    80005ac8:	557d                	li	a0,-1
    80005aca:	b7fd                	j	80005ab8 <sys_mkdir+0x4c>

0000000080005acc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005acc:	7135                	addi	sp,sp,-160
    80005ace:	ed06                	sd	ra,152(sp)
    80005ad0:	e922                	sd	s0,144(sp)
    80005ad2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	7a4080e7          	jalr	1956(ra) # 80004278 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005adc:	08000613          	li	a2,128
    80005ae0:	f7040593          	addi	a1,s0,-144
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	1fe080e7          	jalr	510(ra) # 80002ce4 <argstr>
    80005aee:	04054a63          	bltz	a0,80005b42 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005af2:	f6c40593          	addi	a1,s0,-148
    80005af6:	4505                	li	a0,1
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	1a8080e7          	jalr	424(ra) # 80002ca0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b00:	04054163          	bltz	a0,80005b42 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b04:	f6840593          	addi	a1,s0,-152
    80005b08:	4509                	li	a0,2
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	196080e7          	jalr	406(ra) # 80002ca0 <argint>
     argint(1, &major) < 0 ||
    80005b12:	02054863          	bltz	a0,80005b42 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b16:	f6841683          	lh	a3,-152(s0)
    80005b1a:	f6c41603          	lh	a2,-148(s0)
    80005b1e:	458d                	li	a1,3
    80005b20:	f7040513          	addi	a0,s0,-144
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	776080e7          	jalr	1910(ra) # 8000529a <create>
     argint(2, &minor) < 0 ||
    80005b2c:	c919                	beqz	a0,80005b42 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	ff0080e7          	jalr	-16(ra) # 80003b1e <iunlockput>
  end_op();
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	7c2080e7          	jalr	1986(ra) # 800042f8 <end_op>
  return 0;
    80005b3e:	4501                	li	a0,0
    80005b40:	a031                	j	80005b4c <sys_mknod+0x80>
    end_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	7b6080e7          	jalr	1974(ra) # 800042f8 <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
}
    80005b4c:	60ea                	ld	ra,152(sp)
    80005b4e:	644a                	ld	s0,144(sp)
    80005b50:	610d                	addi	sp,sp,160
    80005b52:	8082                	ret

0000000080005b54 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b54:	7135                	addi	sp,sp,-160
    80005b56:	ed06                	sd	ra,152(sp)
    80005b58:	e922                	sd	s0,144(sp)
    80005b5a:	e526                	sd	s1,136(sp)
    80005b5c:	e14a                	sd	s2,128(sp)
    80005b5e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	ed0080e7          	jalr	-304(ra) # 80001a30 <myproc>
    80005b68:	892a                	mv	s2,a0
  
  begin_op();
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	70e080e7          	jalr	1806(ra) # 80004278 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b72:	08000613          	li	a2,128
    80005b76:	f6040593          	addi	a1,s0,-160
    80005b7a:	4501                	li	a0,0
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	168080e7          	jalr	360(ra) # 80002ce4 <argstr>
    80005b84:	04054b63          	bltz	a0,80005bda <sys_chdir+0x86>
    80005b88:	f6040513          	addi	a0,s0,-160
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	4e0080e7          	jalr	1248(ra) # 8000406c <namei>
    80005b94:	84aa                	mv	s1,a0
    80005b96:	c131                	beqz	a0,80005bda <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	d24080e7          	jalr	-732(ra) # 800038bc <ilock>
  if(ip->type != T_DIR){
    80005ba0:	04449703          	lh	a4,68(s1)
    80005ba4:	4785                	li	a5,1
    80005ba6:	04f71063          	bne	a4,a5,80005be6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	dd2080e7          	jalr	-558(ra) # 8000397e <iunlock>
  iput(p->cwd);
    80005bb4:	15893503          	ld	a0,344(s2)
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	ebe080e7          	jalr	-322(ra) # 80003a76 <iput>
  end_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	738080e7          	jalr	1848(ra) # 800042f8 <end_op>
  p->cwd = ip;
    80005bc8:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bcc:	4501                	li	a0,0
}
    80005bce:	60ea                	ld	ra,152(sp)
    80005bd0:	644a                	ld	s0,144(sp)
    80005bd2:	64aa                	ld	s1,136(sp)
    80005bd4:	690a                	ld	s2,128(sp)
    80005bd6:	610d                	addi	sp,sp,160
    80005bd8:	8082                	ret
    end_op();
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	71e080e7          	jalr	1822(ra) # 800042f8 <end_op>
    return -1;
    80005be2:	557d                	li	a0,-1
    80005be4:	b7ed                	j	80005bce <sys_chdir+0x7a>
    iunlockput(ip);
    80005be6:	8526                	mv	a0,s1
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	f36080e7          	jalr	-202(ra) # 80003b1e <iunlockput>
    end_op();
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	708080e7          	jalr	1800(ra) # 800042f8 <end_op>
    return -1;
    80005bf8:	557d                	li	a0,-1
    80005bfa:	bfd1                	j	80005bce <sys_chdir+0x7a>

0000000080005bfc <sys_exec>:

uint64
sys_exec(void)
{
    80005bfc:	7145                	addi	sp,sp,-464
    80005bfe:	e786                	sd	ra,456(sp)
    80005c00:	e3a2                	sd	s0,448(sp)
    80005c02:	ff26                	sd	s1,440(sp)
    80005c04:	fb4a                	sd	s2,432(sp)
    80005c06:	f74e                	sd	s3,424(sp)
    80005c08:	f352                	sd	s4,416(sp)
    80005c0a:	ef56                	sd	s5,408(sp)
    80005c0c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0e:	08000613          	li	a2,128
    80005c12:	f4040593          	addi	a1,s0,-192
    80005c16:	4501                	li	a0,0
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	0cc080e7          	jalr	204(ra) # 80002ce4 <argstr>
    return -1;
    80005c20:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c22:	0c054a63          	bltz	a0,80005cf6 <sys_exec+0xfa>
    80005c26:	e3840593          	addi	a1,s0,-456
    80005c2a:	4505                	li	a0,1
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	096080e7          	jalr	150(ra) # 80002cc2 <argaddr>
    80005c34:	0c054163          	bltz	a0,80005cf6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c38:	10000613          	li	a2,256
    80005c3c:	4581                	li	a1,0
    80005c3e:	e4040513          	addi	a0,s0,-448
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	0ca080e7          	jalr	202(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c4e:	89a6                	mv	s3,s1
    80005c50:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c52:	02000a13          	li	s4,32
    80005c56:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5a:	00391513          	slli	a0,s2,0x3
    80005c5e:	e3040593          	addi	a1,s0,-464
    80005c62:	e3843783          	ld	a5,-456(s0)
    80005c66:	953e                	add	a0,a0,a5
    80005c68:	ffffd097          	auipc	ra,0xffffd
    80005c6c:	f9e080e7          	jalr	-98(ra) # 80002c06 <fetchaddr>
    80005c70:	02054a63          	bltz	a0,80005ca4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c74:	e3043783          	ld	a5,-464(s0)
    80005c78:	c3b9                	beqz	a5,80005cbe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	ea6080e7          	jalr	-346(ra) # 80000b20 <kalloc>
    80005c82:	85aa                	mv	a1,a0
    80005c84:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c88:	cd11                	beqz	a0,80005ca4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8a:	6605                	lui	a2,0x1
    80005c8c:	e3043503          	ld	a0,-464(s0)
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	fc8080e7          	jalr	-56(ra) # 80002c58 <fetchstr>
    80005c98:	00054663          	bltz	a0,80005ca4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c9c:	0905                	addi	s2,s2,1
    80005c9e:	09a1                	addi	s3,s3,8
    80005ca0:	fb491be3          	bne	s2,s4,80005c56 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca4:	10048913          	addi	s2,s1,256
    80005ca8:	6088                	ld	a0,0(s1)
    80005caa:	c529                	beqz	a0,80005cf4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	d78080e7          	jalr	-648(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb4:	04a1                	addi	s1,s1,8
    80005cb6:	ff2499e3          	bne	s1,s2,80005ca8 <sys_exec+0xac>
  return -1;
    80005cba:	597d                	li	s2,-1
    80005cbc:	a82d                	j	80005cf6 <sys_exec+0xfa>
      argv[i] = 0;
    80005cbe:	0a8e                	slli	s5,s5,0x3
    80005cc0:	fc040793          	addi	a5,s0,-64
    80005cc4:	9abe                	add	s5,s5,a5
    80005cc6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cca:	e4040593          	addi	a1,s0,-448
    80005cce:	f4040513          	addi	a0,s0,-192
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	128080e7          	jalr	296(ra) # 80004dfa <exec>
    80005cda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cdc:	10048993          	addi	s3,s1,256
    80005ce0:	6088                	ld	a0,0(s1)
    80005ce2:	c911                	beqz	a0,80005cf6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce4:	ffffb097          	auipc	ra,0xffffb
    80005ce8:	d40080e7          	jalr	-704(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	04a1                	addi	s1,s1,8
    80005cee:	ff3499e3          	bne	s1,s3,80005ce0 <sys_exec+0xe4>
    80005cf2:	a011                	j	80005cf6 <sys_exec+0xfa>
  return -1;
    80005cf4:	597d                	li	s2,-1
}
    80005cf6:	854a                	mv	a0,s2
    80005cf8:	60be                	ld	ra,456(sp)
    80005cfa:	641e                	ld	s0,448(sp)
    80005cfc:	74fa                	ld	s1,440(sp)
    80005cfe:	795a                	ld	s2,432(sp)
    80005d00:	79ba                	ld	s3,424(sp)
    80005d02:	7a1a                	ld	s4,416(sp)
    80005d04:	6afa                	ld	s5,408(sp)
    80005d06:	6179                	addi	sp,sp,464
    80005d08:	8082                	ret

0000000080005d0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0a:	7139                	addi	sp,sp,-64
    80005d0c:	fc06                	sd	ra,56(sp)
    80005d0e:	f822                	sd	s0,48(sp)
    80005d10:	f426                	sd	s1,40(sp)
    80005d12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	d1c080e7          	jalr	-740(ra) # 80001a30 <myproc>
    80005d1c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d1e:	fd840593          	addi	a1,s0,-40
    80005d22:	4501                	li	a0,0
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	f9e080e7          	jalr	-98(ra) # 80002cc2 <argaddr>
    return -1;
    80005d2c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d2e:	0e054063          	bltz	a0,80005e0e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d32:	fc840593          	addi	a1,s0,-56
    80005d36:	fd040513          	addi	a0,s0,-48
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	d66080e7          	jalr	-666(ra) # 80004aa0 <pipealloc>
    return -1;
    80005d42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d44:	0c054563          	bltz	a0,80005e0e <sys_pipe+0x104>
  fd0 = -1;
    80005d48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d4c:	fd043503          	ld	a0,-48(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	508080e7          	jalr	1288(ra) # 80005258 <fdalloc>
    80005d58:	fca42223          	sw	a0,-60(s0)
    80005d5c:	08054c63          	bltz	a0,80005df4 <sys_pipe+0xea>
    80005d60:	fc843503          	ld	a0,-56(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	4f4080e7          	jalr	1268(ra) # 80005258 <fdalloc>
    80005d6c:	fca42023          	sw	a0,-64(s0)
    80005d70:	06054863          	bltz	a0,80005de0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d74:	4691                	li	a3,4
    80005d76:	fc440613          	addi	a2,s0,-60
    80005d7a:	fd843583          	ld	a1,-40(s0)
    80005d7e:	68a8                	ld	a0,80(s1)
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	af0080e7          	jalr	-1296(ra) # 80001870 <copyout>
    80005d88:	02054063          	bltz	a0,80005da8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d8c:	4691                	li	a3,4
    80005d8e:	fc040613          	addi	a2,s0,-64
    80005d92:	fd843583          	ld	a1,-40(s0)
    80005d96:	0591                	addi	a1,a1,4
    80005d98:	68a8                	ld	a0,80(s1)
    80005d9a:	ffffc097          	auipc	ra,0xffffc
    80005d9e:	ad6080e7          	jalr	-1322(ra) # 80001870 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da4:	06055563          	bgez	a0,80005e0e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005da8:	fc442783          	lw	a5,-60(s0)
    80005dac:	07e9                	addi	a5,a5,26
    80005dae:	078e                	slli	a5,a5,0x3
    80005db0:	97a6                	add	a5,a5,s1
    80005db2:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005db6:	fc042503          	lw	a0,-64(s0)
    80005dba:	0569                	addi	a0,a0,26
    80005dbc:	050e                	slli	a0,a0,0x3
    80005dbe:	9526                	add	a0,a0,s1
    80005dc0:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dc4:	fd043503          	ld	a0,-48(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	982080e7          	jalr	-1662(ra) # 8000474a <fileclose>
    fileclose(wf);
    80005dd0:	fc843503          	ld	a0,-56(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	976080e7          	jalr	-1674(ra) # 8000474a <fileclose>
    return -1;
    80005ddc:	57fd                	li	a5,-1
    80005dde:	a805                	j	80005e0e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005de0:	fc442783          	lw	a5,-60(s0)
    80005de4:	0007c863          	bltz	a5,80005df4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005de8:	01a78513          	addi	a0,a5,26
    80005dec:	050e                	slli	a0,a0,0x3
    80005dee:	9526                	add	a0,a0,s1
    80005df0:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005df4:	fd043503          	ld	a0,-48(s0)
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	952080e7          	jalr	-1710(ra) # 8000474a <fileclose>
    fileclose(wf);
    80005e00:	fc843503          	ld	a0,-56(s0)
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	946080e7          	jalr	-1722(ra) # 8000474a <fileclose>
    return -1;
    80005e0c:	57fd                	li	a5,-1
}
    80005e0e:	853e                	mv	a0,a5
    80005e10:	70e2                	ld	ra,56(sp)
    80005e12:	7442                	ld	s0,48(sp)
    80005e14:	74a2                	ld	s1,40(sp)
    80005e16:	6121                	addi	sp,sp,64
    80005e18:	8082                	ret
    80005e1a:	0000                	unimp
    80005e1c:	0000                	unimp
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	c73fc0ef          	jal	ra,80002ad2 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	710c                	ld	a1,32(a0)
    80005ebc:	7510                	ld	a2,40(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	b0c080e7          	jalr	-1268(ra) # 80001a04 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	ad4080e7          	jalr	-1324(ra) # 80001a04 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	aac080e7          	jalr	-1364(ra) # 80001a04 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f84:	0001d797          	auipc	a5,0x1d
    80005f88:	07c78793          	addi	a5,a5,124 # 80023000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	eba1                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451713          	slli	a4,a0,0x4
    80005f9e:	0001f797          	auipc	a5,0x1f
    80005fa2:	0627b783          	ld	a5,98(a5) # 80025000 <disk+0x2000>
    80005fa6:	97ba                	add	a5,a5,a4
    80005fa8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fac:	0001d797          	auipc	a5,0x1d
    80005fb0:	05478793          	addi	a5,a5,84 # 80023000 <disk>
    80005fb4:	97aa                	add	a5,a5,a0
    80005fb6:	6509                	lui	a0,0x2
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fc0:	0001f517          	auipc	a0,0x1f
    80005fc4:	05850513          	addi	a0,a0,88 # 80025018 <disk+0x2018>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	5b0080e7          	jalr	1456(ra) # 80002578 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fd8:	00002517          	auipc	a0,0x2
    80005fdc:	7e050513          	addi	a0,a0,2016 # 800087b8 <syscalls+0x330>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	568080e7          	jalr	1384(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	7e850513          	addi	a0,a0,2024 # 800087d0 <syscalls+0x348>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	558080e7          	jalr	1368(ra) # 80000548 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006002:	00002597          	auipc	a1,0x2
    80006006:	7e658593          	addi	a1,a1,2022 # 800087e8 <syscalls+0x360>
    8000600a:	0001f517          	auipc	a0,0x1f
    8000600e:	09e50513          	addi	a0,a0,158 # 800250a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	b6e080e7          	jalr	-1170(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	4398                	lw	a4,0(a5)
    80006020:	2701                	sext.w	a4,a4
    80006022:	747277b7          	lui	a5,0x74727
    80006026:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602a:	0ef71163          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	43dc                	lw	a5,4(a5)
    80006034:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006036:	4705                	li	a4,1
    80006038:	0ce79a63          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	479c                	lw	a5,8(a5)
    80006042:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006044:	4709                	li	a4,2
    80006046:	0ce79363          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	0af71963          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	4705                	li	a4,1
    80006064:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	470d                	li	a4,3
    80006068:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000606c:	c7ffe737          	lui	a4,0xc7ffe
    80006070:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006074:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006076:	2701                	sext.w	a4,a4
    80006078:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	472d                	li	a4,11
    8000607c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	473d                	li	a4,15
    80006080:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006082:	6705                	lui	a4,0x1
    80006084:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006086:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000608a:	5bdc                	lw	a5,52(a5)
    8000608c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608e:	c7d9                	beqz	a5,8000611c <virtio_disk_init+0x124>
  if(max < NUM)
    80006090:	471d                	li	a4,7
    80006092:	08f77d63          	bgeu	a4,a5,8000612c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006096:	100014b7          	lui	s1,0x10001
    8000609a:	47a1                	li	a5,8
    8000609c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000609e:	6609                	lui	a2,0x2
    800060a0:	4581                	li	a1,0
    800060a2:	0001d517          	auipc	a0,0x1d
    800060a6:	f5e50513          	addi	a0,a0,-162 # 80023000 <disk>
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	c62080e7          	jalr	-926(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060b2:	0001d717          	auipc	a4,0x1d
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80023000 <disk>
    800060ba:	00c75793          	srli	a5,a4,0xc
    800060be:	2781                	sext.w	a5,a5
    800060c0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060c2:	0001f797          	auipc	a5,0x1f
    800060c6:	f3e78793          	addi	a5,a5,-194 # 80025000 <disk+0x2000>
    800060ca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060cc:	0001d717          	auipc	a4,0x1d
    800060d0:	fb470713          	addi	a4,a4,-76 # 80023080 <disk+0x80>
    800060d4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060d6:	0001e717          	auipc	a4,0x1e
    800060da:	f2a70713          	addi	a4,a4,-214 # 80024000 <disk+0x1000>
    800060de:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060e0:	4705                	li	a4,1
    800060e2:	00e78c23          	sb	a4,24(a5)
    800060e6:	00e78ca3          	sb	a4,25(a5)
    800060ea:	00e78d23          	sb	a4,26(a5)
    800060ee:	00e78da3          	sb	a4,27(a5)
    800060f2:	00e78e23          	sb	a4,28(a5)
    800060f6:	00e78ea3          	sb	a4,29(a5)
    800060fa:	00e78f23          	sb	a4,30(a5)
    800060fe:	00e78fa3          	sb	a4,31(a5)
}
    80006102:	60e2                	ld	ra,24(sp)
    80006104:	6442                	ld	s0,16(sp)
    80006106:	64a2                	ld	s1,8(sp)
    80006108:	6105                	addi	sp,sp,32
    8000610a:	8082                	ret
    panic("could not find virtio disk");
    8000610c:	00002517          	auipc	a0,0x2
    80006110:	6ec50513          	addi	a0,a0,1772 # 800087f8 <syscalls+0x370>
    80006114:	ffffa097          	auipc	ra,0xffffa
    80006118:	434080e7          	jalr	1076(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000611c:	00002517          	auipc	a0,0x2
    80006120:	6fc50513          	addi	a0,a0,1788 # 80008818 <syscalls+0x390>
    80006124:	ffffa097          	auipc	ra,0xffffa
    80006128:	424080e7          	jalr	1060(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000612c:	00002517          	auipc	a0,0x2
    80006130:	70c50513          	addi	a0,a0,1804 # 80008838 <syscalls+0x3b0>
    80006134:	ffffa097          	auipc	ra,0xffffa
    80006138:	414080e7          	jalr	1044(ra) # 80000548 <panic>

000000008000613c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000613c:	7119                	addi	sp,sp,-128
    8000613e:	fc86                	sd	ra,120(sp)
    80006140:	f8a2                	sd	s0,112(sp)
    80006142:	f4a6                	sd	s1,104(sp)
    80006144:	f0ca                	sd	s2,96(sp)
    80006146:	ecce                	sd	s3,88(sp)
    80006148:	e8d2                	sd	s4,80(sp)
    8000614a:	e4d6                	sd	s5,72(sp)
    8000614c:	e0da                	sd	s6,64(sp)
    8000614e:	fc5e                	sd	s7,56(sp)
    80006150:	f862                	sd	s8,48(sp)
    80006152:	f466                	sd	s9,40(sp)
    80006154:	f06a                	sd	s10,32(sp)
    80006156:	0100                	addi	s0,sp,128
    80006158:	892a                	mv	s2,a0
    8000615a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000615c:	00c52c83          	lw	s9,12(a0)
    80006160:	001c9c9b          	slliw	s9,s9,0x1
    80006164:	1c82                	slli	s9,s9,0x20
    80006166:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000616a:	0001f517          	auipc	a0,0x1f
    8000616e:	f3e50513          	addi	a0,a0,-194 # 800250a8 <disk+0x20a8>
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000617a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000617c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000617e:	0001db97          	auipc	s7,0x1d
    80006182:	e82b8b93          	addi	s7,s7,-382 # 80023000 <disk>
    80006186:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006188:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000618a:	8a4e                	mv	s4,s3
    8000618c:	a051                	j	80006210 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000618e:	00fb86b3          	add	a3,s7,a5
    80006192:	96da                	add	a3,a3,s6
    80006194:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006198:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000619a:	0207c563          	bltz	a5,800061c4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000619e:	2485                	addiw	s1,s1,1
    800061a0:	0711                	addi	a4,a4,4
    800061a2:	23548d63          	beq	s1,s5,800063dc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800061a6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061a8:	0001f697          	auipc	a3,0x1f
    800061ac:	e7068693          	addi	a3,a3,-400 # 80025018 <disk+0x2018>
    800061b0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061b2:	0006c583          	lbu	a1,0(a3)
    800061b6:	fde1                	bnez	a1,8000618e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061b8:	2785                	addiw	a5,a5,1
    800061ba:	0685                	addi	a3,a3,1
    800061bc:	ff879be3          	bne	a5,s8,800061b2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061c0:	57fd                	li	a5,-1
    800061c2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061c4:	02905a63          	blez	s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061c8:	f9042503          	lw	a0,-112(s0)
    800061cc:	00000097          	auipc	ra,0x0
    800061d0:	daa080e7          	jalr	-598(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061d4:	4785                	li	a5,1
    800061d6:	0297d163          	bge	a5,s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061da:	f9442503          	lw	a0,-108(s0)
    800061de:	00000097          	auipc	ra,0x0
    800061e2:	d98080e7          	jalr	-616(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061e6:	4789                	li	a5,2
    800061e8:	0097d863          	bge	a5,s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061ec:	f9842503          	lw	a0,-104(s0)
    800061f0:	00000097          	auipc	ra,0x0
    800061f4:	d86080e7          	jalr	-634(ra) # 80005f76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061f8:	0001f597          	auipc	a1,0x1f
    800061fc:	eb058593          	addi	a1,a1,-336 # 800250a8 <disk+0x20a8>
    80006200:	0001f517          	auipc	a0,0x1f
    80006204:	e1850513          	addi	a0,a0,-488 # 80025018 <disk+0x2018>
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	1ea080e7          	jalr	490(ra) # 800023f2 <sleep>
  for(int i = 0; i < 3; i++){
    80006210:	f9040713          	addi	a4,s0,-112
    80006214:	84ce                	mv	s1,s3
    80006216:	bf41                	j	800061a6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006218:	4785                	li	a5,1
    8000621a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000621e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006222:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006226:	f9042983          	lw	s3,-112(s0)
    8000622a:	00499493          	slli	s1,s3,0x4
    8000622e:	0001fa17          	auipc	s4,0x1f
    80006232:	dd2a0a13          	addi	s4,s4,-558 # 80025000 <disk+0x2000>
    80006236:	000a3a83          	ld	s5,0(s4)
    8000623a:	9aa6                	add	s5,s5,s1
    8000623c:	f8040513          	addi	a0,s0,-128
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	fd6080e7          	jalr	-42(ra) # 80001216 <kvmpa>
    80006248:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000624c:	000a3783          	ld	a5,0(s4)
    80006250:	97a6                	add	a5,a5,s1
    80006252:	4741                	li	a4,16
    80006254:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006256:	000a3783          	ld	a5,0(s4)
    8000625a:	97a6                	add	a5,a5,s1
    8000625c:	4705                	li	a4,1
    8000625e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006262:	f9442703          	lw	a4,-108(s0)
    80006266:	000a3783          	ld	a5,0(s4)
    8000626a:	97a6                	add	a5,a5,s1
    8000626c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006270:	0712                	slli	a4,a4,0x4
    80006272:	000a3783          	ld	a5,0(s4)
    80006276:	97ba                	add	a5,a5,a4
    80006278:	05890693          	addi	a3,s2,88
    8000627c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000627e:	000a3783          	ld	a5,0(s4)
    80006282:	97ba                	add	a5,a5,a4
    80006284:	40000693          	li	a3,1024
    80006288:	c794                	sw	a3,8(a5)
  if(write)
    8000628a:	100d0a63          	beqz	s10,8000639e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000628e:	0001f797          	auipc	a5,0x1f
    80006292:	d727b783          	ld	a5,-654(a5) # 80025000 <disk+0x2000>
    80006296:	97ba                	add	a5,a5,a4
    80006298:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000629c:	0001d517          	auipc	a0,0x1d
    800062a0:	d6450513          	addi	a0,a0,-668 # 80023000 <disk>
    800062a4:	0001f797          	auipc	a5,0x1f
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80025000 <disk+0x2000>
    800062ac:	6394                	ld	a3,0(a5)
    800062ae:	96ba                	add	a3,a3,a4
    800062b0:	00c6d603          	lhu	a2,12(a3)
    800062b4:	00166613          	ori	a2,a2,1
    800062b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062bc:	f9842683          	lw	a3,-104(s0)
    800062c0:	6390                	ld	a2,0(a5)
    800062c2:	9732                	add	a4,a4,a2
    800062c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800062c8:	20098613          	addi	a2,s3,512
    800062cc:	0612                	slli	a2,a2,0x4
    800062ce:	962a                	add	a2,a2,a0
    800062d0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d4:	00469713          	slli	a4,a3,0x4
    800062d8:	6394                	ld	a3,0(a5)
    800062da:	96ba                	add	a3,a3,a4
    800062dc:	6589                	lui	a1,0x2
    800062de:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800062e2:	94ae                	add	s1,s1,a1
    800062e4:	94aa                	add	s1,s1,a0
    800062e6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800062e8:	6394                	ld	a3,0(a5)
    800062ea:	96ba                	add	a3,a3,a4
    800062ec:	4585                	li	a1,1
    800062ee:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062f0:	6394                	ld	a3,0(a5)
    800062f2:	96ba                	add	a3,a3,a4
    800062f4:	4509                	li	a0,2
    800062f6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062fa:	6394                	ld	a3,0(a5)
    800062fc:	9736                	add	a4,a4,a3
    800062fe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006302:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006306:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000630a:	6794                	ld	a3,8(a5)
    8000630c:	0026d703          	lhu	a4,2(a3)
    80006310:	8b1d                	andi	a4,a4,7
    80006312:	2709                	addiw	a4,a4,2
    80006314:	0706                	slli	a4,a4,0x1
    80006316:	9736                	add	a4,a4,a3
    80006318:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000631c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006320:	6798                	ld	a4,8(a5)
    80006322:	00275783          	lhu	a5,2(a4)
    80006326:	2785                	addiw	a5,a5,1
    80006328:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006334:	00492703          	lw	a4,4(s2)
    80006338:	4785                	li	a5,1
    8000633a:	02f71163          	bne	a4,a5,8000635c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000633e:	0001f997          	auipc	s3,0x1f
    80006342:	d6a98993          	addi	s3,s3,-662 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006346:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006348:	85ce                	mv	a1,s3
    8000634a:	854a                	mv	a0,s2
    8000634c:	ffffc097          	auipc	ra,0xffffc
    80006350:	0a6080e7          	jalr	166(ra) # 800023f2 <sleep>
  while(b->disk == 1) {
    80006354:	00492783          	lw	a5,4(s2)
    80006358:	fe9788e3          	beq	a5,s1,80006348 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000635c:	f9042483          	lw	s1,-112(s0)
    80006360:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006364:	00479713          	slli	a4,a5,0x4
    80006368:	0001d797          	auipc	a5,0x1d
    8000636c:	c9878793          	addi	a5,a5,-872 # 80023000 <disk>
    80006370:	97ba                	add	a5,a5,a4
    80006372:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006376:	0001f917          	auipc	s2,0x1f
    8000637a:	c8a90913          	addi	s2,s2,-886 # 80025000 <disk+0x2000>
    free_desc(i);
    8000637e:	8526                	mv	a0,s1
    80006380:	00000097          	auipc	ra,0x0
    80006384:	bf6080e7          	jalr	-1034(ra) # 80005f76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006388:	0492                	slli	s1,s1,0x4
    8000638a:	00093783          	ld	a5,0(s2)
    8000638e:	94be                	add	s1,s1,a5
    80006390:	00c4d783          	lhu	a5,12(s1)
    80006394:	8b85                	andi	a5,a5,1
    80006396:	cf89                	beqz	a5,800063b0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006398:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000639c:	b7cd                	j	8000637e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000639e:	0001f797          	auipc	a5,0x1f
    800063a2:	c627b783          	ld	a5,-926(a5) # 80025000 <disk+0x2000>
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	4689                	li	a3,2
    800063aa:	00d79623          	sh	a3,12(a5)
    800063ae:	b5fd                	j	8000629c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063b0:	0001f517          	auipc	a0,0x1f
    800063b4:	cf850513          	addi	a0,a0,-776 # 800250a8 <disk+0x20a8>
    800063b8:	ffffb097          	auipc	ra,0xffffb
    800063bc:	90c080e7          	jalr	-1780(ra) # 80000cc4 <release>
}
    800063c0:	70e6                	ld	ra,120(sp)
    800063c2:	7446                	ld	s0,112(sp)
    800063c4:	74a6                	ld	s1,104(sp)
    800063c6:	7906                	ld	s2,96(sp)
    800063c8:	69e6                	ld	s3,88(sp)
    800063ca:	6a46                	ld	s4,80(sp)
    800063cc:	6aa6                	ld	s5,72(sp)
    800063ce:	6b06                	ld	s6,64(sp)
    800063d0:	7be2                	ld	s7,56(sp)
    800063d2:	7c42                	ld	s8,48(sp)
    800063d4:	7ca2                	ld	s9,40(sp)
    800063d6:	7d02                	ld	s10,32(sp)
    800063d8:	6109                	addi	sp,sp,128
    800063da:	8082                	ret
  if(write)
    800063dc:	e20d1ee3          	bnez	s10,80006218 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800063e0:	f8042023          	sw	zero,-128(s0)
    800063e4:	bd2d                	j	8000621e <virtio_disk_rw+0xe2>

00000000800063e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063e6:	1101                	addi	sp,sp,-32
    800063e8:	ec06                	sd	ra,24(sp)
    800063ea:	e822                	sd	s0,16(sp)
    800063ec:	e426                	sd	s1,8(sp)
    800063ee:	e04a                	sd	s2,0(sp)
    800063f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063f2:	0001f517          	auipc	a0,0x1f
    800063f6:	cb650513          	addi	a0,a0,-842 # 800250a8 <disk+0x20a8>
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	816080e7          	jalr	-2026(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006402:	0001f717          	auipc	a4,0x1f
    80006406:	bfe70713          	addi	a4,a4,-1026 # 80025000 <disk+0x2000>
    8000640a:	02075783          	lhu	a5,32(a4)
    8000640e:	6b18                	ld	a4,16(a4)
    80006410:	00275683          	lhu	a3,2(a4)
    80006414:	8ebd                	xor	a3,a3,a5
    80006416:	8a9d                	andi	a3,a3,7
    80006418:	cab9                	beqz	a3,8000646e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000641a:	0001d917          	auipc	s2,0x1d
    8000641e:	be690913          	addi	s2,s2,-1050 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006422:	0001f497          	auipc	s1,0x1f
    80006426:	bde48493          	addi	s1,s1,-1058 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000642a:	078e                	slli	a5,a5,0x3
    8000642c:	97ba                	add	a5,a5,a4
    8000642e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006430:	20078713          	addi	a4,a5,512
    80006434:	0712                	slli	a4,a4,0x4
    80006436:	974a                	add	a4,a4,s2
    80006438:	03074703          	lbu	a4,48(a4)
    8000643c:	ef21                	bnez	a4,80006494 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000643e:	20078793          	addi	a5,a5,512
    80006442:	0792                	slli	a5,a5,0x4
    80006444:	97ca                	add	a5,a5,s2
    80006446:	7798                	ld	a4,40(a5)
    80006448:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000644c:	7788                	ld	a0,40(a5)
    8000644e:	ffffc097          	auipc	ra,0xffffc
    80006452:	12a080e7          	jalr	298(ra) # 80002578 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006456:	0204d783          	lhu	a5,32(s1)
    8000645a:	2785                	addiw	a5,a5,1
    8000645c:	8b9d                	andi	a5,a5,7
    8000645e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006462:	6898                	ld	a4,16(s1)
    80006464:	00275683          	lhu	a3,2(a4)
    80006468:	8a9d                	andi	a3,a3,7
    8000646a:	fcf690e3          	bne	a3,a5,8000642a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000646e:	10001737          	lui	a4,0x10001
    80006472:	533c                	lw	a5,96(a4)
    80006474:	8b8d                	andi	a5,a5,3
    80006476:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006478:	0001f517          	auipc	a0,0x1f
    8000647c:	c3050513          	addi	a0,a0,-976 # 800250a8 <disk+0x20a8>
    80006480:	ffffb097          	auipc	ra,0xffffb
    80006484:	844080e7          	jalr	-1980(ra) # 80000cc4 <release>
}
    80006488:	60e2                	ld	ra,24(sp)
    8000648a:	6442                	ld	s0,16(sp)
    8000648c:	64a2                	ld	s1,8(sp)
    8000648e:	6902                	ld	s2,0(sp)
    80006490:	6105                	addi	sp,sp,32
    80006492:	8082                	ret
      panic("virtio_disk_intr status");
    80006494:	00002517          	auipc	a0,0x2
    80006498:	3c450513          	addi	a0,a0,964 # 80008858 <syscalls+0x3d0>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	0ac080e7          	jalr	172(ra) # 80000548 <panic>

00000000800064a4 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800064a4:	7179                	addi	sp,sp,-48
    800064a6:	f406                	sd	ra,40(sp)
    800064a8:	f022                	sd	s0,32(sp)
    800064aa:	ec26                	sd	s1,24(sp)
    800064ac:	e84a                	sd	s2,16(sp)
    800064ae:	e44e                	sd	s3,8(sp)
    800064b0:	e052                	sd	s4,0(sp)
    800064b2:	1800                	addi	s0,sp,48
    800064b4:	892a                	mv	s2,a0
    800064b6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800064b8:	00003a17          	auipc	s4,0x3
    800064bc:	b70a0a13          	addi	s4,s4,-1168 # 80009028 <stats>
    800064c0:	000a2683          	lw	a3,0(s4)
    800064c4:	00002617          	auipc	a2,0x2
    800064c8:	3ac60613          	addi	a2,a2,940 # 80008870 <syscalls+0x3e8>
    800064cc:	00000097          	auipc	ra,0x0
    800064d0:	2c2080e7          	jalr	706(ra) # 8000678e <snprintf>
    800064d4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800064d6:	004a2683          	lw	a3,4(s4)
    800064da:	00002617          	auipc	a2,0x2
    800064de:	3a660613          	addi	a2,a2,934 # 80008880 <syscalls+0x3f8>
    800064e2:	85ce                	mv	a1,s3
    800064e4:	954a                	add	a0,a0,s2
    800064e6:	00000097          	auipc	ra,0x0
    800064ea:	2a8080e7          	jalr	680(ra) # 8000678e <snprintf>
  return n;
}
    800064ee:	9d25                	addw	a0,a0,s1
    800064f0:	70a2                	ld	ra,40(sp)
    800064f2:	7402                	ld	s0,32(sp)
    800064f4:	64e2                	ld	s1,24(sp)
    800064f6:	6942                	ld	s2,16(sp)
    800064f8:	69a2                	ld	s3,8(sp)
    800064fa:	6a02                	ld	s4,0(sp)
    800064fc:	6145                	addi	sp,sp,48
    800064fe:	8082                	ret

0000000080006500 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006500:	7179                	addi	sp,sp,-48
    80006502:	f406                	sd	ra,40(sp)
    80006504:	f022                	sd	s0,32(sp)
    80006506:	ec26                	sd	s1,24(sp)
    80006508:	e84a                	sd	s2,16(sp)
    8000650a:	e44e                	sd	s3,8(sp)
    8000650c:	1800                	addi	s0,sp,48
    8000650e:	89ae                	mv	s3,a1
    80006510:	84b2                	mv	s1,a2
    80006512:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006514:	ffffb097          	auipc	ra,0xffffb
    80006518:	51c080e7          	jalr	1308(ra) # 80001a30 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000651c:	653c                	ld	a5,72(a0)
    8000651e:	02f4ff63          	bgeu	s1,a5,8000655c <copyin_new+0x5c>
    80006522:	01248733          	add	a4,s1,s2
    80006526:	02f77d63          	bgeu	a4,a5,80006560 <copyin_new+0x60>
    8000652a:	02976d63          	bltu	a4,s1,80006564 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000652e:	0009061b          	sext.w	a2,s2
    80006532:	85a6                	mv	a1,s1
    80006534:	854e                	mv	a0,s3
    80006536:	ffffb097          	auipc	ra,0xffffb
    8000653a:	836080e7          	jalr	-1994(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000653e:	00003717          	auipc	a4,0x3
    80006542:	aea70713          	addi	a4,a4,-1302 # 80009028 <stats>
    80006546:	431c                	lw	a5,0(a4)
    80006548:	2785                	addiw	a5,a5,1
    8000654a:	c31c                	sw	a5,0(a4)
  return 0;
    8000654c:	4501                	li	a0,0
}
    8000654e:	70a2                	ld	ra,40(sp)
    80006550:	7402                	ld	s0,32(sp)
    80006552:	64e2                	ld	s1,24(sp)
    80006554:	6942                	ld	s2,16(sp)
    80006556:	69a2                	ld	s3,8(sp)
    80006558:	6145                	addi	sp,sp,48
    8000655a:	8082                	ret
    return -1;
    8000655c:	557d                	li	a0,-1
    8000655e:	bfc5                	j	8000654e <copyin_new+0x4e>
    80006560:	557d                	li	a0,-1
    80006562:	b7f5                	j	8000654e <copyin_new+0x4e>
    80006564:	557d                	li	a0,-1
    80006566:	b7e5                	j	8000654e <copyin_new+0x4e>

0000000080006568 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006568:	7179                	addi	sp,sp,-48
    8000656a:	f406                	sd	ra,40(sp)
    8000656c:	f022                	sd	s0,32(sp)
    8000656e:	ec26                	sd	s1,24(sp)
    80006570:	e84a                	sd	s2,16(sp)
    80006572:	e44e                	sd	s3,8(sp)
    80006574:	1800                	addi	s0,sp,48
    80006576:	89ae                	mv	s3,a1
    80006578:	8932                	mv	s2,a2
    8000657a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000657c:	ffffb097          	auipc	ra,0xffffb
    80006580:	4b4080e7          	jalr	1204(ra) # 80001a30 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006584:	00003717          	auipc	a4,0x3
    80006588:	aa470713          	addi	a4,a4,-1372 # 80009028 <stats>
    8000658c:	435c                	lw	a5,4(a4)
    8000658e:	2785                	addiw	a5,a5,1
    80006590:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006592:	cc85                	beqz	s1,800065ca <copyinstr_new+0x62>
    80006594:	00990833          	add	a6,s2,s1
    80006598:	87ca                	mv	a5,s2
    8000659a:	6538                	ld	a4,72(a0)
    8000659c:	00e7ff63          	bgeu	a5,a4,800065ba <copyinstr_new+0x52>
    dst[i] = s[i];
    800065a0:	0007c683          	lbu	a3,0(a5)
    800065a4:	41278733          	sub	a4,a5,s2
    800065a8:	974e                	add	a4,a4,s3
    800065aa:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    800065ae:	c285                	beqz	a3,800065ce <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800065b0:	0785                	addi	a5,a5,1
    800065b2:	ff0794e3          	bne	a5,a6,8000659a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800065b6:	557d                	li	a0,-1
    800065b8:	a011                	j	800065bc <copyinstr_new+0x54>
    800065ba:	557d                	li	a0,-1
}
    800065bc:	70a2                	ld	ra,40(sp)
    800065be:	7402                	ld	s0,32(sp)
    800065c0:	64e2                	ld	s1,24(sp)
    800065c2:	6942                	ld	s2,16(sp)
    800065c4:	69a2                	ld	s3,8(sp)
    800065c6:	6145                	addi	sp,sp,48
    800065c8:	8082                	ret
  return -1;
    800065ca:	557d                	li	a0,-1
    800065cc:	bfc5                	j	800065bc <copyinstr_new+0x54>
      return 0;
    800065ce:	4501                	li	a0,0
    800065d0:	b7f5                	j	800065bc <copyinstr_new+0x54>

00000000800065d2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800065d2:	1141                	addi	sp,sp,-16
    800065d4:	e422                	sd	s0,8(sp)
    800065d6:	0800                	addi	s0,sp,16
  return -1;
}
    800065d8:	557d                	li	a0,-1
    800065da:	6422                	ld	s0,8(sp)
    800065dc:	0141                	addi	sp,sp,16
    800065de:	8082                	ret

00000000800065e0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800065e0:	7179                	addi	sp,sp,-48
    800065e2:	f406                	sd	ra,40(sp)
    800065e4:	f022                	sd	s0,32(sp)
    800065e6:	ec26                	sd	s1,24(sp)
    800065e8:	e84a                	sd	s2,16(sp)
    800065ea:	e44e                	sd	s3,8(sp)
    800065ec:	e052                	sd	s4,0(sp)
    800065ee:	1800                	addi	s0,sp,48
    800065f0:	892a                	mv	s2,a0
    800065f2:	89ae                	mv	s3,a1
    800065f4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800065f6:	00020517          	auipc	a0,0x20
    800065fa:	a0a50513          	addi	a0,a0,-1526 # 80026000 <stats>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	612080e7          	jalr	1554(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006606:	00021797          	auipc	a5,0x21
    8000660a:	a127a783          	lw	a5,-1518(a5) # 80027018 <stats+0x1018>
    8000660e:	cbb5                	beqz	a5,80006682 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006610:	00021797          	auipc	a5,0x21
    80006614:	9f078793          	addi	a5,a5,-1552 # 80027000 <stats+0x1000>
    80006618:	4fd8                	lw	a4,28(a5)
    8000661a:	4f9c                	lw	a5,24(a5)
    8000661c:	9f99                	subw	a5,a5,a4
    8000661e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006622:	06d05e63          	blez	a3,8000669e <statsread+0xbe>
    if(m > n)
    80006626:	8a3e                	mv	s4,a5
    80006628:	00d4d363          	bge	s1,a3,8000662e <statsread+0x4e>
    8000662c:	8a26                	mv	s4,s1
    8000662e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006632:	86a6                	mv	a3,s1
    80006634:	00020617          	auipc	a2,0x20
    80006638:	9e460613          	addi	a2,a2,-1564 # 80026018 <stats+0x18>
    8000663c:	963a                	add	a2,a2,a4
    8000663e:	85ce                	mv	a1,s3
    80006640:	854a                	mv	a0,s2
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	012080e7          	jalr	18(ra) # 80002654 <either_copyout>
    8000664a:	57fd                	li	a5,-1
    8000664c:	00f50a63          	beq	a0,a5,80006660 <statsread+0x80>
      stats.off += m;
    80006650:	00021717          	auipc	a4,0x21
    80006654:	9b070713          	addi	a4,a4,-1616 # 80027000 <stats+0x1000>
    80006658:	4f5c                	lw	a5,28(a4)
    8000665a:	014787bb          	addw	a5,a5,s4
    8000665e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006660:	00020517          	auipc	a0,0x20
    80006664:	9a050513          	addi	a0,a0,-1632 # 80026000 <stats>
    80006668:	ffffa097          	auipc	ra,0xffffa
    8000666c:	65c080e7          	jalr	1628(ra) # 80000cc4 <release>
  return m;
}
    80006670:	8526                	mv	a0,s1
    80006672:	70a2                	ld	ra,40(sp)
    80006674:	7402                	ld	s0,32(sp)
    80006676:	64e2                	ld	s1,24(sp)
    80006678:	6942                	ld	s2,16(sp)
    8000667a:	69a2                	ld	s3,8(sp)
    8000667c:	6a02                	ld	s4,0(sp)
    8000667e:	6145                	addi	sp,sp,48
    80006680:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006682:	6585                	lui	a1,0x1
    80006684:	00020517          	auipc	a0,0x20
    80006688:	99450513          	addi	a0,a0,-1644 # 80026018 <stats+0x18>
    8000668c:	00000097          	auipc	ra,0x0
    80006690:	e18080e7          	jalr	-488(ra) # 800064a4 <statscopyin>
    80006694:	00021797          	auipc	a5,0x21
    80006698:	98a7a223          	sw	a0,-1660(a5) # 80027018 <stats+0x1018>
    8000669c:	bf95                	j	80006610 <statsread+0x30>
    stats.sz = 0;
    8000669e:	00021797          	auipc	a5,0x21
    800066a2:	96278793          	addi	a5,a5,-1694 # 80027000 <stats+0x1000>
    800066a6:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800066aa:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800066ae:	54fd                	li	s1,-1
    800066b0:	bf45                	j	80006660 <statsread+0x80>

00000000800066b2 <statsinit>:

void
statsinit(void)
{
    800066b2:	1141                	addi	sp,sp,-16
    800066b4:	e406                	sd	ra,8(sp)
    800066b6:	e022                	sd	s0,0(sp)
    800066b8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800066ba:	00002597          	auipc	a1,0x2
    800066be:	1d658593          	addi	a1,a1,470 # 80008890 <syscalls+0x408>
    800066c2:	00020517          	auipc	a0,0x20
    800066c6:	93e50513          	addi	a0,a0,-1730 # 80026000 <stats>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	4b6080e7          	jalr	1206(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    800066d2:	0001b797          	auipc	a5,0x1b
    800066d6:	4de78793          	addi	a5,a5,1246 # 80021bb0 <devsw>
    800066da:	00000717          	auipc	a4,0x0
    800066de:	f0670713          	addi	a4,a4,-250 # 800065e0 <statsread>
    800066e2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800066e4:	00000717          	auipc	a4,0x0
    800066e8:	eee70713          	addi	a4,a4,-274 # 800065d2 <statswrite>
    800066ec:	f798                	sd	a4,40(a5)
}
    800066ee:	60a2                	ld	ra,8(sp)
    800066f0:	6402                	ld	s0,0(sp)
    800066f2:	0141                	addi	sp,sp,16
    800066f4:	8082                	ret

00000000800066f6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800066f6:	1101                	addi	sp,sp,-32
    800066f8:	ec22                	sd	s0,24(sp)
    800066fa:	1000                	addi	s0,sp,32
    800066fc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800066fe:	c299                	beqz	a3,80006704 <sprintint+0xe>
    80006700:	0805c163          	bltz	a1,80006782 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006704:	2581                	sext.w	a1,a1
    80006706:	4301                	li	t1,0

  i = 0;
    80006708:	fe040713          	addi	a4,s0,-32
    8000670c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000670e:	2601                	sext.w	a2,a2
    80006710:	00002697          	auipc	a3,0x2
    80006714:	18868693          	addi	a3,a3,392 # 80008898 <digits>
    80006718:	88aa                	mv	a7,a0
    8000671a:	2505                	addiw	a0,a0,1
    8000671c:	02c5f7bb          	remuw	a5,a1,a2
    80006720:	1782                	slli	a5,a5,0x20
    80006722:	9381                	srli	a5,a5,0x20
    80006724:	97b6                	add	a5,a5,a3
    80006726:	0007c783          	lbu	a5,0(a5)
    8000672a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000672e:	0005879b          	sext.w	a5,a1
    80006732:	02c5d5bb          	divuw	a1,a1,a2
    80006736:	0705                	addi	a4,a4,1
    80006738:	fec7f0e3          	bgeu	a5,a2,80006718 <sprintint+0x22>

  if(sign)
    8000673c:	00030b63          	beqz	t1,80006752 <sprintint+0x5c>
    buf[i++] = '-';
    80006740:	ff040793          	addi	a5,s0,-16
    80006744:	97aa                	add	a5,a5,a0
    80006746:	02d00713          	li	a4,45
    8000674a:	fee78823          	sb	a4,-16(a5)
    8000674e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006752:	02a05c63          	blez	a0,8000678a <sprintint+0x94>
    80006756:	fe040793          	addi	a5,s0,-32
    8000675a:	00a78733          	add	a4,a5,a0
    8000675e:	87c2                	mv	a5,a6
    80006760:	0805                	addi	a6,a6,1
    80006762:	fff5061b          	addiw	a2,a0,-1
    80006766:	1602                	slli	a2,a2,0x20
    80006768:	9201                	srli	a2,a2,0x20
    8000676a:	9642                	add	a2,a2,a6
  *s = c;
    8000676c:	fff74683          	lbu	a3,-1(a4)
    80006770:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006774:	177d                	addi	a4,a4,-1
    80006776:	0785                	addi	a5,a5,1
    80006778:	fec79ae3          	bne	a5,a2,8000676c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000677c:	6462                	ld	s0,24(sp)
    8000677e:	6105                	addi	sp,sp,32
    80006780:	8082                	ret
    x = -xx;
    80006782:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006786:	4305                	li	t1,1
    x = -xx;
    80006788:	b741                	j	80006708 <sprintint+0x12>
  while(--i >= 0)
    8000678a:	4501                	li	a0,0
    8000678c:	bfc5                	j	8000677c <sprintint+0x86>

000000008000678e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000678e:	7171                	addi	sp,sp,-176
    80006790:	fc86                	sd	ra,120(sp)
    80006792:	f8a2                	sd	s0,112(sp)
    80006794:	f4a6                	sd	s1,104(sp)
    80006796:	f0ca                	sd	s2,96(sp)
    80006798:	ecce                	sd	s3,88(sp)
    8000679a:	e8d2                	sd	s4,80(sp)
    8000679c:	e4d6                	sd	s5,72(sp)
    8000679e:	e0da                	sd	s6,64(sp)
    800067a0:	fc5e                	sd	s7,56(sp)
    800067a2:	f862                	sd	s8,48(sp)
    800067a4:	f466                	sd	s9,40(sp)
    800067a6:	f06a                	sd	s10,32(sp)
    800067a8:	ec6e                	sd	s11,24(sp)
    800067aa:	0100                	addi	s0,sp,128
    800067ac:	e414                	sd	a3,8(s0)
    800067ae:	e818                	sd	a4,16(s0)
    800067b0:	ec1c                	sd	a5,24(s0)
    800067b2:	03043023          	sd	a6,32(s0)
    800067b6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800067ba:	ca0d                	beqz	a2,800067ec <snprintf+0x5e>
    800067bc:	8baa                	mv	s7,a0
    800067be:	89ae                	mv	s3,a1
    800067c0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800067c2:	00840793          	addi	a5,s0,8
    800067c6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    800067ca:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067cc:	4901                	li	s2,0
    800067ce:	02b05763          	blez	a1,800067fc <snprintf+0x6e>
    if(c != '%'){
    800067d2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800067d6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800067da:	02800d93          	li	s11,40
  *s = c;
    800067de:	02500d13          	li	s10,37
    switch(c){
    800067e2:	07800c93          	li	s9,120
    800067e6:	06400c13          	li	s8,100
    800067ea:	a01d                	j	80006810 <snprintf+0x82>
    panic("null fmt");
    800067ec:	00002517          	auipc	a0,0x2
    800067f0:	82c50513          	addi	a0,a0,-2004 # 80008018 <etext+0x18>
    800067f4:	ffffa097          	auipc	ra,0xffffa
    800067f8:	d54080e7          	jalr	-684(ra) # 80000548 <panic>
  int off = 0;
    800067fc:	4481                	li	s1,0
    800067fe:	a86d                	j	800068b8 <snprintf+0x12a>
  *s = c;
    80006800:	009b8733          	add	a4,s7,s1
    80006804:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006808:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000680a:	2905                	addiw	s2,s2,1
    8000680c:	0b34d663          	bge	s1,s3,800068b8 <snprintf+0x12a>
    80006810:	012a07b3          	add	a5,s4,s2
    80006814:	0007c783          	lbu	a5,0(a5)
    80006818:	0007871b          	sext.w	a4,a5
    8000681c:	cfd1                	beqz	a5,800068b8 <snprintf+0x12a>
    if(c != '%'){
    8000681e:	ff5711e3          	bne	a4,s5,80006800 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006822:	2905                	addiw	s2,s2,1
    80006824:	012a07b3          	add	a5,s4,s2
    80006828:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000682c:	c7d1                	beqz	a5,800068b8 <snprintf+0x12a>
    switch(c){
    8000682e:	05678c63          	beq	a5,s6,80006886 <snprintf+0xf8>
    80006832:	02fb6763          	bltu	s6,a5,80006860 <snprintf+0xd2>
    80006836:	0b578763          	beq	a5,s5,800068e4 <snprintf+0x156>
    8000683a:	0b879b63          	bne	a5,s8,800068f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000683e:	f8843783          	ld	a5,-120(s0)
    80006842:	00878713          	addi	a4,a5,8
    80006846:	f8e43423          	sd	a4,-120(s0)
    8000684a:	4685                	li	a3,1
    8000684c:	4629                	li	a2,10
    8000684e:	438c                	lw	a1,0(a5)
    80006850:	009b8533          	add	a0,s7,s1
    80006854:	00000097          	auipc	ra,0x0
    80006858:	ea2080e7          	jalr	-350(ra) # 800066f6 <sprintint>
    8000685c:	9ca9                	addw	s1,s1,a0
      break;
    8000685e:	b775                	j	8000680a <snprintf+0x7c>
    switch(c){
    80006860:	09979863          	bne	a5,s9,800068f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006864:	f8843783          	ld	a5,-120(s0)
    80006868:	00878713          	addi	a4,a5,8
    8000686c:	f8e43423          	sd	a4,-120(s0)
    80006870:	4685                	li	a3,1
    80006872:	4641                	li	a2,16
    80006874:	438c                	lw	a1,0(a5)
    80006876:	009b8533          	add	a0,s7,s1
    8000687a:	00000097          	auipc	ra,0x0
    8000687e:	e7c080e7          	jalr	-388(ra) # 800066f6 <sprintint>
    80006882:	9ca9                	addw	s1,s1,a0
      break;
    80006884:	b759                	j	8000680a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006886:	f8843783          	ld	a5,-120(s0)
    8000688a:	00878713          	addi	a4,a5,8
    8000688e:	f8e43423          	sd	a4,-120(s0)
    80006892:	639c                	ld	a5,0(a5)
    80006894:	c3b1                	beqz	a5,800068d8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006896:	0007c703          	lbu	a4,0(a5)
    8000689a:	db25                	beqz	a4,8000680a <snprintf+0x7c>
    8000689c:	0134de63          	bge	s1,s3,800068b8 <snprintf+0x12a>
    800068a0:	009b86b3          	add	a3,s7,s1
  *s = c;
    800068a4:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800068a8:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800068aa:	0785                	addi	a5,a5,1
    800068ac:	0007c703          	lbu	a4,0(a5)
    800068b0:	df29                	beqz	a4,8000680a <snprintf+0x7c>
    800068b2:	0685                	addi	a3,a3,1
    800068b4:	fe9998e3          	bne	s3,s1,800068a4 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800068b8:	8526                	mv	a0,s1
    800068ba:	70e6                	ld	ra,120(sp)
    800068bc:	7446                	ld	s0,112(sp)
    800068be:	74a6                	ld	s1,104(sp)
    800068c0:	7906                	ld	s2,96(sp)
    800068c2:	69e6                	ld	s3,88(sp)
    800068c4:	6a46                	ld	s4,80(sp)
    800068c6:	6aa6                	ld	s5,72(sp)
    800068c8:	6b06                	ld	s6,64(sp)
    800068ca:	7be2                	ld	s7,56(sp)
    800068cc:	7c42                	ld	s8,48(sp)
    800068ce:	7ca2                	ld	s9,40(sp)
    800068d0:	7d02                	ld	s10,32(sp)
    800068d2:	6de2                	ld	s11,24(sp)
    800068d4:	614d                	addi	sp,sp,176
    800068d6:	8082                	ret
        s = "(null)";
    800068d8:	00001797          	auipc	a5,0x1
    800068dc:	73878793          	addi	a5,a5,1848 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    800068e0:	876e                	mv	a4,s11
    800068e2:	bf6d                	j	8000689c <snprintf+0x10e>
  *s = c;
    800068e4:	009b87b3          	add	a5,s7,s1
    800068e8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800068ec:	2485                	addiw	s1,s1,1
      break;
    800068ee:	bf31                	j	8000680a <snprintf+0x7c>
  *s = c;
    800068f0:	009b8733          	add	a4,s7,s1
    800068f4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800068f8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800068fc:	975e                	add	a4,a4,s7
    800068fe:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006902:	2489                	addiw	s1,s1,2
      break;
    80006904:	b719                	j	8000680a <snprintf+0x7c>
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
