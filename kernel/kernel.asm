
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	99013103          	ld	sp,-1648(sp) # 80008990 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9a070713          	addi	a4,a4,-1632 # 800089f0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	cae78793          	addi	a5,a5,-850 # 80005d10 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc99f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	9a650513          	addi	a0,a0,-1626 # 80010b30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	99648493          	addi	s1,s1,-1642 # 80010b30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a2690913          	addi	s2,s2,-1498 # 80010bc8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	90a50513          	addi	a0,a0,-1782 # 80010b30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8f450513          	addi	a0,a0,-1804 # 80010b30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	94f72b23          	sw	a5,-1706(a4) # 80010bc8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	86450513          	addi	a0,a0,-1948 # 80010b30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	83650513          	addi	a0,a0,-1994 # 80010b30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	81270713          	addi	a4,a4,-2030 # 80010b30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7e878793          	addi	a5,a5,2024 # 80010b30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8527a783          	lw	a5,-1966(a5) # 80010bc8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7a670713          	addi	a4,a4,1958 # 80010b30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	79648493          	addi	s1,s1,1942 # 80010b30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	75a70713          	addi	a4,a4,1882 # 80010b30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7ef72223          	sw	a5,2020(a4) # 80010bd0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	71e78793          	addi	a5,a5,1822 # 80010b30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	78c7ab23          	sw	a2,1942(a5) # 80010bcc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	78a50513          	addi	a0,a0,1930 # 80010bc8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6d050513          	addi	a0,a0,1744 # 80010b30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	85078793          	addi	a5,a5,-1968 # 80020cc8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6a07a223          	sw	zero,1700(a5) # 80010bf0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	42f72823          	sw	a5,1072(a4) # 800089b0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	634dad83          	lw	s11,1588(s11) # 80010bf0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	5de50513          	addi	a0,a0,1502 # 80010bd8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	48050513          	addi	a0,a0,1152 # 80010bd8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	46448493          	addi	s1,s1,1124 # 80010bd8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	42450513          	addi	a0,a0,1060 # 80010bf8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1b07a783          	lw	a5,432(a5) # 800089b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1807b783          	ld	a5,384(a5) # 800089b8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	18073703          	ld	a4,384(a4) # 800089c0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	396a0a13          	addi	s4,s4,918 # 80010bf8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	14e48493          	addi	s1,s1,334 # 800089b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	14e98993          	addi	s3,s3,334 # 800089c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	32850513          	addi	a0,a0,808 # 80010bf8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0d07a783          	lw	a5,208(a5) # 800089b0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	0d673703          	ld	a4,214(a4) # 800089c0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0c67b783          	ld	a5,198(a5) # 800089b8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	2fa98993          	addi	s3,s3,762 # 80010bf8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0b248493          	addi	s1,s1,178 # 800089b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0b290913          	addi	s2,s2,178 # 800089c0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	2c448493          	addi	s1,s1,708 # 80010bf8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	06e7bc23          	sd	a4,120(a5) # 800089c0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	23e48493          	addi	s1,s1,574 # 80010bf8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	46478793          	addi	a5,a5,1124 # 80021e60 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	21490913          	addi	s2,s2,532 # 80010c30 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	17650513          	addi	a0,a0,374 # 80010c30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	39250513          	addi	a0,a0,914 # 80021e60 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	14048493          	addi	s1,s1,320 # 80010c30 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	12850513          	addi	a0,a0,296 # 80010c30 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	0fc50513          	addi	a0,a0,252 # 80010c30 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd1a1>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b4070713          	addi	a4,a4,-1216 # 800089c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	890080e7          	jalr	-1904(ra) # 8000274e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e8a080e7          	jalr	-374(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	7f0080e7          	jalr	2032(ra) # 80002726 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	810080e7          	jalr	-2032(ra) # 8000274e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	df4080e7          	jalr	-524(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e02080e7          	jalr	-510(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f9a080e7          	jalr	-102(ra) # 80002ef0 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	63a080e7          	jalr	1594(ra) # 80003598 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5e0080e7          	jalr	1504(ra) # 80004546 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	eea080e7          	jalr	-278(ra) # 80005e58 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a4f72223          	sw	a5,-1468(a4) # 800089c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a387b783          	ld	a5,-1480(a5) # 800089d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd197>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	76a7be23          	sd	a0,1916(a5) # 800089d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd1a0>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	83448493          	addi	s1,s1,-1996 # 80011080 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	21aa0a13          	addi	s4,s4,538 # 80016a80 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	36850513          	addi	a0,a0,872 # 80010c50 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	36850513          	addi	a0,a0,872 # 80010c68 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	77048493          	addi	s1,s1,1904 # 80011080 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	14e98993          	addi	s3,s3,334 # 80016a80 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	2e450513          	addi	a0,a0,740 # 80010c80 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	28c70713          	addi	a4,a4,652 # 80010c50 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	f447a783          	lw	a5,-188(a5) # 80008940 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d60080e7          	jalr	-672(ra) # 80002766 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f207a523          	sw	zero,-214(a5) # 80008940 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	af8080e7          	jalr	-1288(ra) # 80003518 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	21a90913          	addi	s2,s2,538 # 80010c50 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	efc78793          	addi	a5,a5,-260 # 80008944 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	4be48493          	addi	s1,s1,1214 # 80011080 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	eb690913          	addi	s2,s2,-330 # 80016a80 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	d4a7b423          	sd	a0,-696(a5) # 800089e0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	cac58593          	addi	a1,a1,-852 # 80008950 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	260080e7          	jalr	608(ra) # 80003f42 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	7c6080e7          	jalr	1990(ra) # 800045d8 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	934080e7          	jalr	-1740(ra) # 80003758 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	e1848493          	addi	s1,s1,-488 # 80010c68 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	d9270713          	addi	a4,a4,-622 # 80010c50 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	dbc70713          	addi	a4,a4,-580 # 80010c88 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	d74a0a13          	addi	s4,s4,-652 # 80010c50 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	b9a90913          	addi	s2,s2,-1126 # 80016a80 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	18648493          	addi	s1,s1,390 # 80011080 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	788080e7          	jalr	1928(ra) # 800026bc <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	ce670713          	addi	a4,a4,-794 # 80010c50 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	cc090913          	addi	s2,s2,-832 # 80010c50 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	ce058593          	addi	a1,a1,-800 # 80010c88 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	706080e7          	jalr	1798(ra) # 800026bc <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	fb448493          	addi	s1,s1,-76 # 80011080 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	9a890913          	addi	s2,s2,-1624 # 80016a80 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	f4048493          	addi	s1,s1,-192 # 80011080 <proc>
      pp->parent = initproc;
    80002148:	00007a17          	auipc	s4,0x7
    8000214c:	898a0a13          	addi	s4,s4,-1896 # 800089e0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	93098993          	addi	s3,s3,-1744 # 80016a80 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00007797          	auipc	a5,0x7
    800021a8:	83c7b783          	ld	a5,-1988(a5) # 800089e0 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	462080e7          	jalr	1122(ra) # 8000462a <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f82080e7          	jalr	-126(ra) # 80004162 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	764080e7          	jalr	1892(ra) # 80003950 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	fec080e7          	jalr	-20(ra) # 800041e0 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	a6848493          	addi	s1,s1,-1432 # 80010c68 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	e1248493          	addi	s1,s1,-494 # 80011080 <proc>
    80002276:	00015997          	auipc	s3,0x15
    8000227a:	80a98993          	addi	s3,s3,-2038 # 80016a80 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	91650513          	addi	a0,a0,-1770 # 80010c68 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	71898993          	addi	s3,s3,1816 # 80016a80 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	8f8c0c13          	addi	s8,s8,-1800 # 80010c68 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	d0648493          	addi	s1,s1,-762 # 80011080 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	8b050513          	addi	a0,a0,-1872 # 80010c68 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	89450513          	addi	a0,a0,-1900 # 80010c68 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000f517          	auipc	a0,0xf
    80002426:	84650513          	addi	a0,a0,-1978 # 80010c68 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	caa48493          	addi	s1,s1,-854 # 800111d8 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	6a290913          	addi	s2,s2,1698 # 80016bd8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	e58b8b93          	addi	s7,s7,-424 # 800083b0 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <print_hello>:

void
print_hello(int n)
{
    800025b8:	1141                	addi	sp,sp,-16
    800025ba:	e406                	sd	ra,8(sp)
    800025bc:	e022                	sd	s0,0(sp)
    800025be:	0800                	addi	s0,sp,16
    800025c0:	85aa                	mv	a1,a0
	printf("Hello from the kernel space %d\n",n);
    800025c2:	00006517          	auipc	a0,0x6
    800025c6:	cd650513          	addi	a0,a0,-810 # 80008298 <digits+0x258>
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fc0080e7          	jalr	-64(ra) # 8000058a <printf>
}
    800025d2:	60a2                	ld	ra,8(sp)
    800025d4:	6402                	ld	s0,0(sp)
    800025d6:	0141                	addi	sp,sp,16
    800025d8:	8082                	ret

00000000800025da <actproc>:


int
actproc(void)
{
    800025da:	7179                	addi	sp,sp,-48
    800025dc:	f406                	sd	ra,40(sp)
    800025de:	f022                	sd	s0,32(sp)
    800025e0:	ec26                	sd	s1,24(sp)
    800025e2:	e84a                	sd	s2,16(sp)
    800025e4:	e44e                	sd	s3,8(sp)
    800025e6:	1800                	addi	s0,sp,48
	struct proc *p;
	int num=0;
    800025e8:	4901                	li	s2,0
	p=proc;
    800025ea:	0000f497          	auipc	s1,0xf
    800025ee:	a9648493          	addi	s1,s1,-1386 # 80011080 <proc>
	while(p<&proc[NPROC])
    800025f2:	00014997          	auipc	s3,0x14
    800025f6:	48e98993          	addi	s3,s3,1166 # 80016a80 <tickslock>
    800025fa:	a811                	j	8000260e <actproc+0x34>
	{
		acquire(&p->lock);
		if(p->state !=UNUSED){
			num++;
		}
		release(&p->lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	68c080e7          	jalr	1676(ra) # 80000c8a <release>
		p++;
    80002606:	16848493          	addi	s1,s1,360
	while(p<&proc[NPROC])
    8000260a:	01348b63          	beq	s1,s3,80002620 <actproc+0x46>
		acquire(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5c6080e7          	jalr	1478(ra) # 80000bd6 <acquire>
		if(p->state !=UNUSED){
    80002618:	4c9c                	lw	a5,24(s1)
    8000261a:	d3ed                	beqz	a5,800025fc <actproc+0x22>
			num++;
    8000261c:	2905                	addiw	s2,s2,1
    8000261e:	bff9                	j	800025fc <actproc+0x22>
	}
	return num;
}
    80002620:	854a                	mv	a0,s2
    80002622:	70a2                	ld	ra,40(sp)
    80002624:	7402                	ld	s0,32(sp)
    80002626:	64e2                	ld	s1,24(sp)
    80002628:	6942                	ld	s2,16(sp)
    8000262a:	69a2                	ld	s3,8(sp)
    8000262c:	6145                	addi	sp,sp,48
    8000262e:	8082                	ret

0000000080002630 <outputsysinfo>:

void
outputsysinfo(int i)
{
    80002630:	1101                	addi	sp,sp,-32
    80002632:	ec06                	sd	ra,24(sp)
    80002634:	e822                	sd	s0,16(sp)
    80002636:	e426                	sd	s1,8(sp)
    80002638:	1000                	addi	s0,sp,32
    8000263a:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	370080e7          	jalr	880(ra) # 800019ac <myproc>
	switch(i){
    80002644:	4789                	li	a5,2
    80002646:	04f48363          	beq	s1,a5,8000268c <outputsysinfo+0x5c>
    8000264a:	478d                	li	a5,3
    8000264c:	04f48d63          	beq	s1,a5,800026a6 <outputsysinfo+0x76>
    80002650:	4785                	li	a5,1
    80002652:	00f48b63          	beq	s1,a5,80002668 <outputsysinfo+0x38>
		       break;
		case 2:printf("The total number of system calls that has made so far since the system boot up is %d\n", syscallcounts);
		       break;
		case 3:printf("The number of free memory pages in the system is %d\n",p->sz/PGSIZE);
		       break;
		default:printf("ERROR\n");
    80002656:	00006517          	auipc	a0,0x6
    8000265a:	d2250513          	addi	a0,a0,-734 # 80008378 <digits+0x338>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	f2c080e7          	jalr	-212(ra) # 8000058a <printf>
	}
}
    80002666:	a831                	j	80002682 <outputsysinfo+0x52>
		case 1:int n=actproc();
    80002668:	00000097          	auipc	ra,0x0
    8000266c:	f72080e7          	jalr	-142(ra) # 800025da <actproc>
    80002670:	85aa                	mv	a1,a0
		       printf("The total number of active processes is %d\n",n);
    80002672:	00006517          	auipc	a0,0x6
    80002676:	c4650513          	addi	a0,a0,-954 # 800082b8 <digits+0x278>
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	f10080e7          	jalr	-240(ra) # 8000058a <printf>
}
    80002682:	60e2                	ld	ra,24(sp)
    80002684:	6442                	ld	s0,16(sp)
    80002686:	64a2                	ld	s1,8(sp)
    80002688:	6105                	addi	sp,sp,32
    8000268a:	8082                	ret
		case 2:printf("The total number of system calls that has made so far since the system boot up is %d\n", syscallcounts);
    8000268c:	00006597          	auipc	a1,0x6
    80002690:	34c5a583          	lw	a1,844(a1) # 800089d8 <syscallcounts>
    80002694:	00006517          	auipc	a0,0x6
    80002698:	c5450513          	addi	a0,a0,-940 # 800082e8 <digits+0x2a8>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	eee080e7          	jalr	-274(ra) # 8000058a <printf>
		       break;
    800026a4:	bff9                	j	80002682 <outputsysinfo+0x52>
		case 3:printf("The number of free memory pages in the system is %d\n",p->sz/PGSIZE);
    800026a6:	652c                	ld	a1,72(a0)
    800026a8:	81b1                	srli	a1,a1,0xc
    800026aa:	00006517          	auipc	a0,0x6
    800026ae:	c9650513          	addi	a0,a0,-874 # 80008340 <digits+0x300>
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	ed8080e7          	jalr	-296(ra) # 8000058a <printf>
		       break;
    800026ba:	b7e1                	j	80002682 <outputsysinfo+0x52>

00000000800026bc <swtch>:
    800026bc:	00153023          	sd	ra,0(a0)
    800026c0:	00253423          	sd	sp,8(a0)
    800026c4:	e900                	sd	s0,16(a0)
    800026c6:	ed04                	sd	s1,24(a0)
    800026c8:	03253023          	sd	s2,32(a0)
    800026cc:	03353423          	sd	s3,40(a0)
    800026d0:	03453823          	sd	s4,48(a0)
    800026d4:	03553c23          	sd	s5,56(a0)
    800026d8:	05653023          	sd	s6,64(a0)
    800026dc:	05753423          	sd	s7,72(a0)
    800026e0:	05853823          	sd	s8,80(a0)
    800026e4:	05953c23          	sd	s9,88(a0)
    800026e8:	07a53023          	sd	s10,96(a0)
    800026ec:	07b53423          	sd	s11,104(a0)
    800026f0:	0005b083          	ld	ra,0(a1)
    800026f4:	0085b103          	ld	sp,8(a1)
    800026f8:	6980                	ld	s0,16(a1)
    800026fa:	6d84                	ld	s1,24(a1)
    800026fc:	0205b903          	ld	s2,32(a1)
    80002700:	0285b983          	ld	s3,40(a1)
    80002704:	0305ba03          	ld	s4,48(a1)
    80002708:	0385ba83          	ld	s5,56(a1)
    8000270c:	0405bb03          	ld	s6,64(a1)
    80002710:	0485bb83          	ld	s7,72(a1)
    80002714:	0505bc03          	ld	s8,80(a1)
    80002718:	0585bc83          	ld	s9,88(a1)
    8000271c:	0605bd03          	ld	s10,96(a1)
    80002720:	0685bd83          	ld	s11,104(a1)
    80002724:	8082                	ret

0000000080002726 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002726:	1141                	addi	sp,sp,-16
    80002728:	e406                	sd	ra,8(sp)
    8000272a:	e022                	sd	s0,0(sp)
    8000272c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000272e:	00006597          	auipc	a1,0x6
    80002732:	cb258593          	addi	a1,a1,-846 # 800083e0 <states.0+0x30>
    80002736:	00014517          	auipc	a0,0x14
    8000273a:	34a50513          	addi	a0,a0,842 # 80016a80 <tickslock>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	408080e7          	jalr	1032(ra) # 80000b46 <initlock>
}
    80002746:	60a2                	ld	ra,8(sp)
    80002748:	6402                	ld	s0,0(sp)
    8000274a:	0141                	addi	sp,sp,16
    8000274c:	8082                	ret

000000008000274e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000274e:	1141                	addi	sp,sp,-16
    80002750:	e422                	sd	s0,8(sp)
    80002752:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002754:	00003797          	auipc	a5,0x3
    80002758:	52c78793          	addi	a5,a5,1324 # 80005c80 <kernelvec>
    8000275c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002760:	6422                	ld	s0,8(sp)
    80002762:	0141                	addi	sp,sp,16
    80002764:	8082                	ret

0000000080002766 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002766:	1141                	addi	sp,sp,-16
    80002768:	e406                	sd	ra,8(sp)
    8000276a:	e022                	sd	s0,0(sp)
    8000276c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	23e080e7          	jalr	574(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002776:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000277a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002780:	00005697          	auipc	a3,0x5
    80002784:	88068693          	addi	a3,a3,-1920 # 80007000 <_trampoline>
    80002788:	00005717          	auipc	a4,0x5
    8000278c:	87870713          	addi	a4,a4,-1928 # 80007000 <_trampoline>
    80002790:	8f15                	sub	a4,a4,a3
    80002792:	040007b7          	lui	a5,0x4000
    80002796:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002798:	07b2                	slli	a5,a5,0xc
    8000279a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000279c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027a2:	18002673          	csrr	a2,satp
    800027a6:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027a8:	6d30                	ld	a2,88(a0)
    800027aa:	6138                	ld	a4,64(a0)
    800027ac:	6585                	lui	a1,0x1
    800027ae:	972e                	add	a4,a4,a1
    800027b0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027b2:	6d38                	ld	a4,88(a0)
    800027b4:	00000617          	auipc	a2,0x0
    800027b8:	13060613          	addi	a2,a2,304 # 800028e4 <usertrap>
    800027bc:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027be:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c0:	8612                	mv	a2,tp
    800027c2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027c8:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027cc:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027d4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027d6:	6f18                	ld	a4,24(a4)
    800027d8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027dc:	6928                	ld	a0,80(a0)
    800027de:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027e0:	00005717          	auipc	a4,0x5
    800027e4:	8bc70713          	addi	a4,a4,-1860 # 8000709c <userret>
    800027e8:	8f15                	sub	a4,a4,a3
    800027ea:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027ec:	577d                	li	a4,-1
    800027ee:	177e                	slli	a4,a4,0x3f
    800027f0:	8d59                	or	a0,a0,a4
    800027f2:	9782                	jalr	a5
}
    800027f4:	60a2                	ld	ra,8(sp)
    800027f6:	6402                	ld	s0,0(sp)
    800027f8:	0141                	addi	sp,sp,16
    800027fa:	8082                	ret

00000000800027fc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027fc:	1101                	addi	sp,sp,-32
    800027fe:	ec06                	sd	ra,24(sp)
    80002800:	e822                	sd	s0,16(sp)
    80002802:	e426                	sd	s1,8(sp)
    80002804:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002806:	00014497          	auipc	s1,0x14
    8000280a:	27a48493          	addi	s1,s1,634 # 80016a80 <tickslock>
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	3c6080e7          	jalr	966(ra) # 80000bd6 <acquire>
  ticks++;
    80002818:	00006517          	auipc	a0,0x6
    8000281c:	1d050513          	addi	a0,a0,464 # 800089e8 <ticks>
    80002820:	411c                	lw	a5,0(a0)
    80002822:	2785                	addiw	a5,a5,1
    80002824:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002826:	00000097          	auipc	ra,0x0
    8000282a:	892080e7          	jalr	-1902(ra) # 800020b8 <wakeup>
  release(&tickslock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	45a080e7          	jalr	1114(ra) # 80000c8a <release>
}
    80002838:	60e2                	ld	ra,24(sp)
    8000283a:	6442                	ld	s0,16(sp)
    8000283c:	64a2                	ld	s1,8(sp)
    8000283e:	6105                	addi	sp,sp,32
    80002840:	8082                	ret

0000000080002842 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002842:	1101                	addi	sp,sp,-32
    80002844:	ec06                	sd	ra,24(sp)
    80002846:	e822                	sd	s0,16(sp)
    80002848:	e426                	sd	s1,8(sp)
    8000284a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000284c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002850:	00074d63          	bltz	a4,8000286a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002854:	57fd                	li	a5,-1
    80002856:	17fe                	slli	a5,a5,0x3f
    80002858:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000285a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000285c:	06f70363          	beq	a4,a5,800028c2 <devintr+0x80>
  }
}
    80002860:	60e2                	ld	ra,24(sp)
    80002862:	6442                	ld	s0,16(sp)
    80002864:	64a2                	ld	s1,8(sp)
    80002866:	6105                	addi	sp,sp,32
    80002868:	8082                	ret
     (scause & 0xff) == 9){
    8000286a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000286e:	46a5                	li	a3,9
    80002870:	fed792e3          	bne	a5,a3,80002854 <devintr+0x12>
    int irq = plic_claim();
    80002874:	00003097          	auipc	ra,0x3
    80002878:	514080e7          	jalr	1300(ra) # 80005d88 <plic_claim>
    8000287c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000287e:	47a9                	li	a5,10
    80002880:	02f50763          	beq	a0,a5,800028ae <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002884:	4785                	li	a5,1
    80002886:	02f50963          	beq	a0,a5,800028b8 <devintr+0x76>
    return 1;
    8000288a:	4505                	li	a0,1
    } else if(irq){
    8000288c:	d8f1                	beqz	s1,80002860 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000288e:	85a6                	mv	a1,s1
    80002890:	00006517          	auipc	a0,0x6
    80002894:	b5850513          	addi	a0,a0,-1192 # 800083e8 <states.0+0x38>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	cf2080e7          	jalr	-782(ra) # 8000058a <printf>
      plic_complete(irq);
    800028a0:	8526                	mv	a0,s1
    800028a2:	00003097          	auipc	ra,0x3
    800028a6:	50a080e7          	jalr	1290(ra) # 80005dac <plic_complete>
    return 1;
    800028aa:	4505                	li	a0,1
    800028ac:	bf55                	j	80002860 <devintr+0x1e>
      uartintr();
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	0ea080e7          	jalr	234(ra) # 80000998 <uartintr>
    800028b6:	b7ed                	j	800028a0 <devintr+0x5e>
      virtio_disk_intr();
    800028b8:	00004097          	auipc	ra,0x4
    800028bc:	9bc080e7          	jalr	-1604(ra) # 80006274 <virtio_disk_intr>
    800028c0:	b7c5                	j	800028a0 <devintr+0x5e>
    if(cpuid() == 0){
    800028c2:	fffff097          	auipc	ra,0xfffff
    800028c6:	0be080e7          	jalr	190(ra) # 80001980 <cpuid>
    800028ca:	c901                	beqz	a0,800028da <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028cc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028d2:	14479073          	csrw	sip,a5
    return 2;
    800028d6:	4509                	li	a0,2
    800028d8:	b761                	j	80002860 <devintr+0x1e>
      clockintr();
    800028da:	00000097          	auipc	ra,0x0
    800028de:	f22080e7          	jalr	-222(ra) # 800027fc <clockintr>
    800028e2:	b7ed                	j	800028cc <devintr+0x8a>

00000000800028e4 <usertrap>:
{
    800028e4:	1101                	addi	sp,sp,-32
    800028e6:	ec06                	sd	ra,24(sp)
    800028e8:	e822                	sd	s0,16(sp)
    800028ea:	e426                	sd	s1,8(sp)
    800028ec:	e04a                	sd	s2,0(sp)
    800028ee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028f4:	1007f793          	andi	a5,a5,256
    800028f8:	e3b1                	bnez	a5,8000293c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028fa:	00003797          	auipc	a5,0x3
    800028fe:	38678793          	addi	a5,a5,902 # 80005c80 <kernelvec>
    80002902:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002906:	fffff097          	auipc	ra,0xfffff
    8000290a:	0a6080e7          	jalr	166(ra) # 800019ac <myproc>
    8000290e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002910:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002912:	14102773          	csrr	a4,sepc
    80002916:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002918:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000291c:	47a1                	li	a5,8
    8000291e:	02f70763          	beq	a4,a5,8000294c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002922:	00000097          	auipc	ra,0x0
    80002926:	f20080e7          	jalr	-224(ra) # 80002842 <devintr>
    8000292a:	892a                	mv	s2,a0
    8000292c:	c151                	beqz	a0,800029b0 <usertrap+0xcc>
  if(killed(p))
    8000292e:	8526                	mv	a0,s1
    80002930:	00000097          	auipc	ra,0x0
    80002934:	9cc080e7          	jalr	-1588(ra) # 800022fc <killed>
    80002938:	c929                	beqz	a0,8000298a <usertrap+0xa6>
    8000293a:	a099                	j	80002980 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	acc50513          	addi	a0,a0,-1332 # 80008408 <states.0+0x58>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	bfc080e7          	jalr	-1028(ra) # 80000540 <panic>
    if(killed(p))
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	9b0080e7          	jalr	-1616(ra) # 800022fc <killed>
    80002954:	e921                	bnez	a0,800029a4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002956:	6cb8                	ld	a4,88(s1)
    80002958:	6f1c                	ld	a5,24(a4)
    8000295a:	0791                	addi	a5,a5,4
    8000295c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002962:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002966:	10079073          	csrw	sstatus,a5
    syscall();
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	2d4080e7          	jalr	724(ra) # 80002c3e <syscall>
  if(killed(p))
    80002972:	8526                	mv	a0,s1
    80002974:	00000097          	auipc	ra,0x0
    80002978:	988080e7          	jalr	-1656(ra) # 800022fc <killed>
    8000297c:	c911                	beqz	a0,80002990 <usertrap+0xac>
    8000297e:	4901                	li	s2,0
    exit(-1);
    80002980:	557d                	li	a0,-1
    80002982:	00000097          	auipc	ra,0x0
    80002986:	806080e7          	jalr	-2042(ra) # 80002188 <exit>
  if(which_dev == 2)
    8000298a:	4789                	li	a5,2
    8000298c:	04f90f63          	beq	s2,a5,800029ea <usertrap+0x106>
  usertrapret();
    80002990:	00000097          	auipc	ra,0x0
    80002994:	dd6080e7          	jalr	-554(ra) # 80002766 <usertrapret>
}
    80002998:	60e2                	ld	ra,24(sp)
    8000299a:	6442                	ld	s0,16(sp)
    8000299c:	64a2                	ld	s1,8(sp)
    8000299e:	6902                	ld	s2,0(sp)
    800029a0:	6105                	addi	sp,sp,32
    800029a2:	8082                	ret
      exit(-1);
    800029a4:	557d                	li	a0,-1
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	7e2080e7          	jalr	2018(ra) # 80002188 <exit>
    800029ae:	b765                	j	80002956 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029b4:	5890                	lw	a2,48(s1)
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	a7250513          	addi	a0,a0,-1422 # 80008428 <states.0+0x78>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	bcc080e7          	jalr	-1076(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ca:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	a8a50513          	addi	a0,a0,-1398 # 80008458 <states.0+0xa8>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bb4080e7          	jalr	-1100(ra) # 8000058a <printf>
    setkilled(p);
    800029de:	8526                	mv	a0,s1
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	8f0080e7          	jalr	-1808(ra) # 800022d0 <setkilled>
    800029e8:	b769                	j	80002972 <usertrap+0x8e>
    yield();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	62e080e7          	jalr	1582(ra) # 80002018 <yield>
    800029f2:	bf79                	j	80002990 <usertrap+0xac>

00000000800029f4 <kerneltrap>:
{
    800029f4:	7179                	addi	sp,sp,-48
    800029f6:	f406                	sd	ra,40(sp)
    800029f8:	f022                	sd	s0,32(sp)
    800029fa:	ec26                	sd	s1,24(sp)
    800029fc:	e84a                	sd	s2,16(sp)
    800029fe:	e44e                	sd	s3,8(sp)
    80002a00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0e:	1004f793          	andi	a5,s1,256
    80002a12:	cb85                	beqz	a5,80002a42 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a18:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a1a:	ef85                	bnez	a5,80002a52 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a1c:	00000097          	auipc	ra,0x0
    80002a20:	e26080e7          	jalr	-474(ra) # 80002842 <devintr>
    80002a24:	cd1d                	beqz	a0,80002a62 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a26:	4789                	li	a5,2
    80002a28:	06f50a63          	beq	a0,a5,80002a9c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a30:	10049073          	csrw	sstatus,s1
}
    80002a34:	70a2                	ld	ra,40(sp)
    80002a36:	7402                	ld	s0,32(sp)
    80002a38:	64e2                	ld	s1,24(sp)
    80002a3a:	6942                	ld	s2,16(sp)
    80002a3c:	69a2                	ld	s3,8(sp)
    80002a3e:	6145                	addi	sp,sp,48
    80002a40:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	a3650513          	addi	a0,a0,-1482 # 80008478 <states.0+0xc8>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	af6080e7          	jalr	-1290(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	a4e50513          	addi	a0,a0,-1458 # 800084a0 <states.0+0xf0>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	ae6080e7          	jalr	-1306(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a62:	85ce                	mv	a1,s3
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	a5c50513          	addi	a0,a0,-1444 # 800084c0 <states.0+0x110>
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	b1e080e7          	jalr	-1250(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	a5450513          	addi	a0,a0,-1452 # 800084d0 <states.0+0x120>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	b06080e7          	jalr	-1274(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	a5c50513          	addi	a0,a0,-1444 # 800084e8 <states.0+0x138>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	aac080e7          	jalr	-1364(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	f10080e7          	jalr	-240(ra) # 800019ac <myproc>
    80002aa4:	d541                	beqz	a0,80002a2c <kerneltrap+0x38>
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	f06080e7          	jalr	-250(ra) # 800019ac <myproc>
    80002aae:	4d18                	lw	a4,24(a0)
    80002ab0:	4791                	li	a5,4
    80002ab2:	f6f71de3          	bne	a4,a5,80002a2c <kerneltrap+0x38>
    yield();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	562080e7          	jalr	1378(ra) # 80002018 <yield>
    80002abe:	b7bd                	j	80002a2c <kerneltrap+0x38>

0000000080002ac0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	ee0080e7          	jalr	-288(ra) # 800019ac <myproc>
  switch (n) {
    80002ad4:	4795                	li	a5,5
    80002ad6:	0497e163          	bltu	a5,s1,80002b18 <argraw+0x58>
    80002ada:	048a                	slli	s1,s1,0x2
    80002adc:	00006717          	auipc	a4,0x6
    80002ae0:	a4470713          	addi	a4,a4,-1468 # 80008520 <states.0+0x170>
    80002ae4:	94ba                	add	s1,s1,a4
    80002ae6:	409c                	lw	a5,0(s1)
    80002ae8:	97ba                	add	a5,a5,a4
    80002aea:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aec:	6d3c                	ld	a5,88(a0)
    80002aee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002af0:	60e2                	ld	ra,24(sp)
    80002af2:	6442                	ld	s0,16(sp)
    80002af4:	64a2                	ld	s1,8(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
    return p->trapframe->a1;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	7fa8                	ld	a0,120(a5)
    80002afe:	bfcd                	j	80002af0 <argraw+0x30>
    return p->trapframe->a2;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	63c8                	ld	a0,128(a5)
    80002b04:	b7f5                	j	80002af0 <argraw+0x30>
    return p->trapframe->a3;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	67c8                	ld	a0,136(a5)
    80002b0a:	b7dd                	j	80002af0 <argraw+0x30>
    return p->trapframe->a4;
    80002b0c:	6d3c                	ld	a5,88(a0)
    80002b0e:	6bc8                	ld	a0,144(a5)
    80002b10:	b7c5                	j	80002af0 <argraw+0x30>
    return p->trapframe->a5;
    80002b12:	6d3c                	ld	a5,88(a0)
    80002b14:	6fc8                	ld	a0,152(a5)
    80002b16:	bfe9                	j	80002af0 <argraw+0x30>
  panic("argraw");
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	9e050513          	addi	a0,a0,-1568 # 800084f8 <states.0+0x148>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a20080e7          	jalr	-1504(ra) # 80000540 <panic>

0000000080002b28 <fetchaddr>:
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
    80002b34:	84aa                	mv	s1,a0
    80002b36:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	e74080e7          	jalr	-396(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b40:	653c                	ld	a5,72(a0)
    80002b42:	02f4f863          	bgeu	s1,a5,80002b72 <fetchaddr+0x4a>
    80002b46:	00848713          	addi	a4,s1,8
    80002b4a:	02e7e663          	bltu	a5,a4,80002b76 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4e:	46a1                	li	a3,8
    80002b50:	8626                	mv	a2,s1
    80002b52:	85ca                	mv	a1,s2
    80002b54:	6928                	ld	a0,80(a0)
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	ba2080e7          	jalr	-1118(ra) # 800016f8 <copyin>
    80002b5e:	00a03533          	snez	a0,a0
    80002b62:	40a00533          	neg	a0,a0
}
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6902                	ld	s2,0(sp)
    80002b6e:	6105                	addi	sp,sp,32
    80002b70:	8082                	ret
    return -1;
    80002b72:	557d                	li	a0,-1
    80002b74:	bfcd                	j	80002b66 <fetchaddr+0x3e>
    80002b76:	557d                	li	a0,-1
    80002b78:	b7fd                	j	80002b66 <fetchaddr+0x3e>

0000000080002b7a <fetchstr>:
{
    80002b7a:	7179                	addi	sp,sp,-48
    80002b7c:	f406                	sd	ra,40(sp)
    80002b7e:	f022                	sd	s0,32(sp)
    80002b80:	ec26                	sd	s1,24(sp)
    80002b82:	e84a                	sd	s2,16(sp)
    80002b84:	e44e                	sd	s3,8(sp)
    80002b86:	1800                	addi	s0,sp,48
    80002b88:	892a                	mv	s2,a0
    80002b8a:	84ae                	mv	s1,a1
    80002b8c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	e1e080e7          	jalr	-482(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b96:	86ce                	mv	a3,s3
    80002b98:	864a                	mv	a2,s2
    80002b9a:	85a6                	mv	a1,s1
    80002b9c:	6928                	ld	a0,80(a0)
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	be8080e7          	jalr	-1048(ra) # 80001786 <copyinstr>
    80002ba6:	00054e63          	bltz	a0,80002bc2 <fetchstr+0x48>
  return strlen(buf);
    80002baa:	8526                	mv	a0,s1
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	2a2080e7          	jalr	674(ra) # 80000e4e <strlen>
}
    80002bb4:	70a2                	ld	ra,40(sp)
    80002bb6:	7402                	ld	s0,32(sp)
    80002bb8:	64e2                	ld	s1,24(sp)
    80002bba:	6942                	ld	s2,16(sp)
    80002bbc:	69a2                	ld	s3,8(sp)
    80002bbe:	6145                	addi	sp,sp,48
    80002bc0:	8082                	ret
    return -1;
    80002bc2:	557d                	li	a0,-1
    80002bc4:	bfc5                	j	80002bb4 <fetchstr+0x3a>

0000000080002bc6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	eee080e7          	jalr	-274(ra) # 80002ac0 <argraw>
    80002bda:	c088                	sw	a0,0(s1)
}
    80002bdc:	60e2                	ld	ra,24(sp)
    80002bde:	6442                	ld	s0,16(sp)
    80002be0:	64a2                	ld	s1,8(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	e426                	sd	s1,8(sp)
    80002bee:	1000                	addi	s0,sp,32
    80002bf0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	ece080e7          	jalr	-306(ra) # 80002ac0 <argraw>
    80002bfa:	e088                	sd	a0,0(s1)
}
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6105                	addi	sp,sp,32
    80002c04:	8082                	ret

0000000080002c06 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c06:	7179                	addi	sp,sp,-48
    80002c08:	f406                	sd	ra,40(sp)
    80002c0a:	f022                	sd	s0,32(sp)
    80002c0c:	ec26                	sd	s1,24(sp)
    80002c0e:	e84a                	sd	s2,16(sp)
    80002c10:	1800                	addi	s0,sp,48
    80002c12:	84ae                	mv	s1,a1
    80002c14:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c16:	fd840593          	addi	a1,s0,-40
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	fcc080e7          	jalr	-52(ra) # 80002be6 <argaddr>
  return fetchstr(addr, buf, max);
    80002c22:	864a                	mv	a2,s2
    80002c24:	85a6                	mv	a1,s1
    80002c26:	fd843503          	ld	a0,-40(s0)
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	f50080e7          	jalr	-176(ra) # 80002b7a <fetchstr>
}
    80002c32:	70a2                	ld	ra,40(sp)
    80002c34:	7402                	ld	s0,32(sp)
    80002c36:	64e2                	ld	s1,24(sp)
    80002c38:	6942                	ld	s2,16(sp)
    80002c3a:	6145                	addi	sp,sp,48
    80002c3c:	8082                	ret

0000000080002c3e <syscall>:
[SYS_sysinfo]  sys_sysinfo,//lab1->sysinfo
};

void
syscall(void)
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	e04a                	sd	s2,0(sp)
    80002c48:	1000                	addi	s0,sp,32
  int num;
  syscallcounts++;//lab1->system call will increase this global var syscallcounts.
    80002c4a:	00006717          	auipc	a4,0x6
    80002c4e:	d8e70713          	addi	a4,a4,-626 # 800089d8 <syscallcounts>
    80002c52:	431c                	lw	a5,0(a4)
    80002c54:	2785                	addiw	a5,a5,1
    80002c56:	c31c                	sw	a5,0(a4)
  struct proc *p = myproc();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	d54080e7          	jalr	-684(ra) # 800019ac <myproc>
    80002c60:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c62:	05853903          	ld	s2,88(a0)
    80002c66:	0a893783          	ld	a5,168(s2)
    80002c6a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c6e:	37fd                	addiw	a5,a5,-1
    80002c70:	4759                	li	a4,22
    80002c72:	00f76f63          	bltu	a4,a5,80002c90 <syscall+0x52>
    80002c76:	00369713          	slli	a4,a3,0x3
    80002c7a:	00006797          	auipc	a5,0x6
    80002c7e:	8be78793          	addi	a5,a5,-1858 # 80008538 <syscalls>
    80002c82:	97ba                	add	a5,a5,a4
    80002c84:	639c                	ld	a5,0(a5)
    80002c86:	c789                	beqz	a5,80002c90 <syscall+0x52>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c88:	9782                	jalr	a5
    80002c8a:	06a93823          	sd	a0,112(s2)
    80002c8e:	a839                	j	80002cac <syscall+0x6e>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c90:	15848613          	addi	a2,s1,344
    80002c94:	588c                	lw	a1,48(s1)
    80002c96:	00006517          	auipc	a0,0x6
    80002c9a:	86a50513          	addi	a0,a0,-1942 # 80008500 <states.0+0x150>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ec080e7          	jalr	-1812(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca6:	6cbc                	ld	a5,88(s1)
    80002ca8:	577d                	li	a4,-1
    80002caa:	fbb8                	sd	a4,112(a5)
  }
}
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6902                	ld	s2,0(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cc0:	fec40593          	addi	a1,s0,-20
    80002cc4:	4501                	li	a0,0
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	f00080e7          	jalr	-256(ra) # 80002bc6 <argint>
  exit(n);
    80002cce:	fec42503          	lw	a0,-20(s0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	4b6080e7          	jalr	1206(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002cda:	4501                	li	a0,0
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	6105                	addi	sp,sp,32
    80002ce2:	8082                	ret

0000000080002ce4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ce4:	1141                	addi	sp,sp,-16
    80002ce6:	e406                	sd	ra,8(sp)
    80002ce8:	e022                	sd	s0,0(sp)
    80002cea:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	cc0080e7          	jalr	-832(ra) # 800019ac <myproc>
}
    80002cf4:	5908                	lw	a0,48(a0)
    80002cf6:	60a2                	ld	ra,8(sp)
    80002cf8:	6402                	ld	s0,0(sp)
    80002cfa:	0141                	addi	sp,sp,16
    80002cfc:	8082                	ret

0000000080002cfe <sys_fork>:

uint64
sys_fork(void)
{
    80002cfe:	1141                	addi	sp,sp,-16
    80002d00:	e406                	sd	ra,8(sp)
    80002d02:	e022                	sd	s0,0(sp)
    80002d04:	0800                	addi	s0,sp,16
  return fork();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	05c080e7          	jalr	92(ra) # 80001d62 <fork>
}
    80002d0e:	60a2                	ld	ra,8(sp)
    80002d10:	6402                	ld	s0,0(sp)
    80002d12:	0141                	addi	sp,sp,16
    80002d14:	8082                	ret

0000000080002d16 <sys_wait>:

uint64
sys_wait(void)
{
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d1e:	fe840593          	addi	a1,s0,-24
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	ec2080e7          	jalr	-318(ra) # 80002be6 <argaddr>
  return wait(p);
    80002d2c:	fe843503          	ld	a0,-24(s0)
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	5fe080e7          	jalr	1534(ra) # 8000232e <wait>
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d4a:	fdc40593          	addi	a1,s0,-36
    80002d4e:	4501                	li	a0,0
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	e76080e7          	jalr	-394(ra) # 80002bc6 <argint>
  addr = myproc()->sz;
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	c54080e7          	jalr	-940(ra) # 800019ac <myproc>
    80002d60:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d62:	fdc42503          	lw	a0,-36(s0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	fa0080e7          	jalr	-96(ra) # 80001d06 <growproc>
    80002d6e:	00054863          	bltz	a0,80002d7e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d72:	8526                	mv	a0,s1
    80002d74:	70a2                	ld	ra,40(sp)
    80002d76:	7402                	ld	s0,32(sp)
    80002d78:	64e2                	ld	s1,24(sp)
    80002d7a:	6145                	addi	sp,sp,48
    80002d7c:	8082                	ret
    return -1;
    80002d7e:	54fd                	li	s1,-1
    80002d80:	bfcd                	j	80002d72 <sys_sbrk+0x32>

0000000080002d82 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d82:	7139                	addi	sp,sp,-64
    80002d84:	fc06                	sd	ra,56(sp)
    80002d86:	f822                	sd	s0,48(sp)
    80002d88:	f426                	sd	s1,40(sp)
    80002d8a:	f04a                	sd	s2,32(sp)
    80002d8c:	ec4e                	sd	s3,24(sp)
    80002d8e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d90:	fcc40593          	addi	a1,s0,-52
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	e30080e7          	jalr	-464(ra) # 80002bc6 <argint>
  acquire(&tickslock);
    80002d9e:	00014517          	auipc	a0,0x14
    80002da2:	ce250513          	addi	a0,a0,-798 # 80016a80 <tickslock>
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	e30080e7          	jalr	-464(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002dae:	00006917          	auipc	s2,0x6
    80002db2:	c3a92903          	lw	s2,-966(s2) # 800089e8 <ticks>
  while(ticks - ticks0 < n){
    80002db6:	fcc42783          	lw	a5,-52(s0)
    80002dba:	cf9d                	beqz	a5,80002df8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dbc:	00014997          	auipc	s3,0x14
    80002dc0:	cc498993          	addi	s3,s3,-828 # 80016a80 <tickslock>
    80002dc4:	00006497          	auipc	s1,0x6
    80002dc8:	c2448493          	addi	s1,s1,-988 # 800089e8 <ticks>
    if(killed(myproc())){
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	be0080e7          	jalr	-1056(ra) # 800019ac <myproc>
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	528080e7          	jalr	1320(ra) # 800022fc <killed>
    80002ddc:	ed15                	bnez	a0,80002e18 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dde:	85ce                	mv	a1,s3
    80002de0:	8526                	mv	a0,s1
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	272080e7          	jalr	626(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002dea:	409c                	lw	a5,0(s1)
    80002dec:	412787bb          	subw	a5,a5,s2
    80002df0:	fcc42703          	lw	a4,-52(s0)
    80002df4:	fce7ece3          	bltu	a5,a4,80002dcc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002df8:	00014517          	auipc	a0,0x14
    80002dfc:	c8850513          	addi	a0,a0,-888 # 80016a80 <tickslock>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	e8a080e7          	jalr	-374(ra) # 80000c8a <release>
  return 0;
    80002e08:	4501                	li	a0,0
}
    80002e0a:	70e2                	ld	ra,56(sp)
    80002e0c:	7442                	ld	s0,48(sp)
    80002e0e:	74a2                	ld	s1,40(sp)
    80002e10:	7902                	ld	s2,32(sp)
    80002e12:	69e2                	ld	s3,24(sp)
    80002e14:	6121                	addi	sp,sp,64
    80002e16:	8082                	ret
      release(&tickslock);
    80002e18:	00014517          	auipc	a0,0x14
    80002e1c:	c6850513          	addi	a0,a0,-920 # 80016a80 <tickslock>
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	e6a080e7          	jalr	-406(ra) # 80000c8a <release>
      return -1;
    80002e28:	557d                	li	a0,-1
    80002e2a:	b7c5                	j	80002e0a <sys_sleep+0x88>

0000000080002e2c <sys_kill>:

uint64
sys_kill(void)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e34:	fec40593          	addi	a1,s0,-20
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	d8c080e7          	jalr	-628(ra) # 80002bc6 <argint>
  return kill(pid);
    80002e42:	fec42503          	lw	a0,-20(s0)
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	418080e7          	jalr	1048(ra) # 8000225e <kill>
}
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e60:	00014517          	auipc	a0,0x14
    80002e64:	c2050513          	addi	a0,a0,-992 # 80016a80 <tickslock>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	d6e080e7          	jalr	-658(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e70:	00006497          	auipc	s1,0x6
    80002e74:	b784a483          	lw	s1,-1160(s1) # 800089e8 <ticks>
  release(&tickslock);
    80002e78:	00014517          	auipc	a0,0x14
    80002e7c:	c0850513          	addi	a0,a0,-1016 # 80016a80 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
  return xticks;
}
    80002e88:	02049513          	slli	a0,s1,0x20
    80002e8c:	9101                	srli	a0,a0,0x20
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	64a2                	ld	s1,8(sp)
    80002e94:	6105                	addi	sp,sp,32
    80002e96:	8082                	ret

0000000080002e98 <sys_hello>:


uint64
sys_hello(void)
{
    80002e98:	1101                	addi	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ea0:	fec40593          	addi	a1,s0,-20
    80002ea4:	4501                	li	a0,0
    80002ea6:	00000097          	auipc	ra,0x0
    80002eaa:	d20080e7          	jalr	-736(ra) # 80002bc6 <argint>
  print_hello(n);
    80002eae:	fec42503          	lw	a0,-20(s0)
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	706080e7          	jalr	1798(ra) # 800025b8 <print_hello>
  return 0;
}
    80002eba:	4501                	li	a0,0
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <sys_sysinfo>:
//lab1->sysinfo
uint64
sys_sysinfo(void)
{
    80002ec4:	1101                	addi	sp,sp,-32
    80002ec6:	ec06                	sd	ra,24(sp)
    80002ec8:	e822                	sd	s0,16(sp)
    80002eca:	1000                	addi	s0,sp,32
	int p;
	argint(0,&p);
    80002ecc:	fec40593          	addi	a1,s0,-20
    80002ed0:	4501                	li	a0,0
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	cf4080e7          	jalr	-780(ra) # 80002bc6 <argint>
	outputsysinfo(p);
    80002eda:	fec42503          	lw	a0,-20(s0)
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	752080e7          	jalr	1874(ra) # 80002630 <outputsysinfo>
	return 0;
}
    80002ee6:	4501                	li	a0,0
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ef0:	7179                	addi	sp,sp,-48
    80002ef2:	f406                	sd	ra,40(sp)
    80002ef4:	f022                	sd	s0,32(sp)
    80002ef6:	ec26                	sd	s1,24(sp)
    80002ef8:	e84a                	sd	s2,16(sp)
    80002efa:	e44e                	sd	s3,8(sp)
    80002efc:	e052                	sd	s4,0(sp)
    80002efe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f00:	00005597          	auipc	a1,0x5
    80002f04:	6f858593          	addi	a1,a1,1784 # 800085f8 <syscalls+0xc0>
    80002f08:	00014517          	auipc	a0,0x14
    80002f0c:	b9050513          	addi	a0,a0,-1136 # 80016a98 <bcache>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	c36080e7          	jalr	-970(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f18:	0001c797          	auipc	a5,0x1c
    80002f1c:	b8078793          	addi	a5,a5,-1152 # 8001ea98 <bcache+0x8000>
    80002f20:	0001c717          	auipc	a4,0x1c
    80002f24:	de070713          	addi	a4,a4,-544 # 8001ed00 <bcache+0x8268>
    80002f28:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f2c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f30:	00014497          	auipc	s1,0x14
    80002f34:	b8048493          	addi	s1,s1,-1152 # 80016ab0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f38:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f3a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f3c:	00005a17          	auipc	s4,0x5
    80002f40:	6c4a0a13          	addi	s4,s4,1732 # 80008600 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f44:	2b893783          	ld	a5,696(s2)
    80002f48:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f4a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f4e:	85d2                	mv	a1,s4
    80002f50:	01048513          	addi	a0,s1,16
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	4c8080e7          	jalr	1224(ra) # 8000441c <initsleeplock>
    bcache.head.next->prev = b;
    80002f5c:	2b893783          	ld	a5,696(s2)
    80002f60:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f62:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f66:	45848493          	addi	s1,s1,1112
    80002f6a:	fd349de3          	bne	s1,s3,80002f44 <binit+0x54>
  }
}
    80002f6e:	70a2                	ld	ra,40(sp)
    80002f70:	7402                	ld	s0,32(sp)
    80002f72:	64e2                	ld	s1,24(sp)
    80002f74:	6942                	ld	s2,16(sp)
    80002f76:	69a2                	ld	s3,8(sp)
    80002f78:	6a02                	ld	s4,0(sp)
    80002f7a:	6145                	addi	sp,sp,48
    80002f7c:	8082                	ret

0000000080002f7e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f7e:	7179                	addi	sp,sp,-48
    80002f80:	f406                	sd	ra,40(sp)
    80002f82:	f022                	sd	s0,32(sp)
    80002f84:	ec26                	sd	s1,24(sp)
    80002f86:	e84a                	sd	s2,16(sp)
    80002f88:	e44e                	sd	s3,8(sp)
    80002f8a:	1800                	addi	s0,sp,48
    80002f8c:	892a                	mv	s2,a0
    80002f8e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	b0850513          	addi	a0,a0,-1272 # 80016a98 <bcache>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	c3e080e7          	jalr	-962(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fa0:	0001c497          	auipc	s1,0x1c
    80002fa4:	db04b483          	ld	s1,-592(s1) # 8001ed50 <bcache+0x82b8>
    80002fa8:	0001c797          	auipc	a5,0x1c
    80002fac:	d5878793          	addi	a5,a5,-680 # 8001ed00 <bcache+0x8268>
    80002fb0:	02f48f63          	beq	s1,a5,80002fee <bread+0x70>
    80002fb4:	873e                	mv	a4,a5
    80002fb6:	a021                	j	80002fbe <bread+0x40>
    80002fb8:	68a4                	ld	s1,80(s1)
    80002fba:	02e48a63          	beq	s1,a4,80002fee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fbe:	449c                	lw	a5,8(s1)
    80002fc0:	ff279ce3          	bne	a5,s2,80002fb8 <bread+0x3a>
    80002fc4:	44dc                	lw	a5,12(s1)
    80002fc6:	ff3799e3          	bne	a5,s3,80002fb8 <bread+0x3a>
      b->refcnt++;
    80002fca:	40bc                	lw	a5,64(s1)
    80002fcc:	2785                	addiw	a5,a5,1
    80002fce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd0:	00014517          	auipc	a0,0x14
    80002fd4:	ac850513          	addi	a0,a0,-1336 # 80016a98 <bcache>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	cb2080e7          	jalr	-846(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fe0:	01048513          	addi	a0,s1,16
    80002fe4:	00001097          	auipc	ra,0x1
    80002fe8:	472080e7          	jalr	1138(ra) # 80004456 <acquiresleep>
      return b;
    80002fec:	a8b9                	j	8000304a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fee:	0001c497          	auipc	s1,0x1c
    80002ff2:	d5a4b483          	ld	s1,-678(s1) # 8001ed48 <bcache+0x82b0>
    80002ff6:	0001c797          	auipc	a5,0x1c
    80002ffa:	d0a78793          	addi	a5,a5,-758 # 8001ed00 <bcache+0x8268>
    80002ffe:	00f48863          	beq	s1,a5,8000300e <bread+0x90>
    80003002:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003004:	40bc                	lw	a5,64(s1)
    80003006:	cf81                	beqz	a5,8000301e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003008:	64a4                	ld	s1,72(s1)
    8000300a:	fee49de3          	bne	s1,a4,80003004 <bread+0x86>
  panic("bget: no buffers");
    8000300e:	00005517          	auipc	a0,0x5
    80003012:	5fa50513          	addi	a0,a0,1530 # 80008608 <syscalls+0xd0>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	52a080e7          	jalr	1322(ra) # 80000540 <panic>
      b->dev = dev;
    8000301e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003022:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003026:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000302a:	4785                	li	a5,1
    8000302c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302e:	00014517          	auipc	a0,0x14
    80003032:	a6a50513          	addi	a0,a0,-1430 # 80016a98 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c54080e7          	jalr	-940(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000303e:	01048513          	addi	a0,s1,16
    80003042:	00001097          	auipc	ra,0x1
    80003046:	414080e7          	jalr	1044(ra) # 80004456 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000304a:	409c                	lw	a5,0(s1)
    8000304c:	cb89                	beqz	a5,8000305e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000304e:	8526                	mv	a0,s1
    80003050:	70a2                	ld	ra,40(sp)
    80003052:	7402                	ld	s0,32(sp)
    80003054:	64e2                	ld	s1,24(sp)
    80003056:	6942                	ld	s2,16(sp)
    80003058:	69a2                	ld	s3,8(sp)
    8000305a:	6145                	addi	sp,sp,48
    8000305c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000305e:	4581                	li	a1,0
    80003060:	8526                	mv	a0,s1
    80003062:	00003097          	auipc	ra,0x3
    80003066:	fe0080e7          	jalr	-32(ra) # 80006042 <virtio_disk_rw>
    b->valid = 1;
    8000306a:	4785                	li	a5,1
    8000306c:	c09c                	sw	a5,0(s1)
  return b;
    8000306e:	b7c5                	j	8000304e <bread+0xd0>

0000000080003070 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	e426                	sd	s1,8(sp)
    80003078:	1000                	addi	s0,sp,32
    8000307a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000307c:	0541                	addi	a0,a0,16
    8000307e:	00001097          	auipc	ra,0x1
    80003082:	472080e7          	jalr	1138(ra) # 800044f0 <holdingsleep>
    80003086:	cd01                	beqz	a0,8000309e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003088:	4585                	li	a1,1
    8000308a:	8526                	mv	a0,s1
    8000308c:	00003097          	auipc	ra,0x3
    80003090:	fb6080e7          	jalr	-74(ra) # 80006042 <virtio_disk_rw>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret
    panic("bwrite");
    8000309e:	00005517          	auipc	a0,0x5
    800030a2:	58250513          	addi	a0,a0,1410 # 80008620 <syscalls+0xe8>
    800030a6:	ffffd097          	auipc	ra,0xffffd
    800030aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>

00000000800030ae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	e04a                	sd	s2,0(sp)
    800030b8:	1000                	addi	s0,sp,32
    800030ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030bc:	01050913          	addi	s2,a0,16
    800030c0:	854a                	mv	a0,s2
    800030c2:	00001097          	auipc	ra,0x1
    800030c6:	42e080e7          	jalr	1070(ra) # 800044f0 <holdingsleep>
    800030ca:	c92d                	beqz	a0,8000313c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030cc:	854a                	mv	a0,s2
    800030ce:	00001097          	auipc	ra,0x1
    800030d2:	3de080e7          	jalr	990(ra) # 800044ac <releasesleep>

  acquire(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	9c250513          	addi	a0,a0,-1598 # 80016a98 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	af8080e7          	jalr	-1288(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030e6:	40bc                	lw	a5,64(s1)
    800030e8:	37fd                	addiw	a5,a5,-1
    800030ea:	0007871b          	sext.w	a4,a5
    800030ee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030f0:	eb05                	bnez	a4,80003120 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030f2:	68bc                	ld	a5,80(s1)
    800030f4:	64b8                	ld	a4,72(s1)
    800030f6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f8:	64bc                	ld	a5,72(s1)
    800030fa:	68b8                	ld	a4,80(s1)
    800030fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030fe:	0001c797          	auipc	a5,0x1c
    80003102:	99a78793          	addi	a5,a5,-1638 # 8001ea98 <bcache+0x8000>
    80003106:	2b87b703          	ld	a4,696(a5)
    8000310a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000310c:	0001c717          	auipc	a4,0x1c
    80003110:	bf470713          	addi	a4,a4,-1036 # 8001ed00 <bcache+0x8268>
    80003114:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003116:	2b87b703          	ld	a4,696(a5)
    8000311a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000311c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	97850513          	addi	a0,a0,-1672 # 80016a98 <bcache>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b62080e7          	jalr	-1182(ra) # 80000c8a <release>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	64a2                	ld	s1,8(sp)
    80003136:	6902                	ld	s2,0(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret
    panic("brelse");
    8000313c:	00005517          	auipc	a0,0x5
    80003140:	4ec50513          	addi	a0,a0,1260 # 80008628 <syscalls+0xf0>
    80003144:	ffffd097          	auipc	ra,0xffffd
    80003148:	3fc080e7          	jalr	1020(ra) # 80000540 <panic>

000000008000314c <bpin>:

void
bpin(struct buf *b) {
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	e426                	sd	s1,8(sp)
    80003154:	1000                	addi	s0,sp,32
    80003156:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003158:	00014517          	auipc	a0,0x14
    8000315c:	94050513          	addi	a0,a0,-1728 # 80016a98 <bcache>
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	a76080e7          	jalr	-1418(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003168:	40bc                	lw	a5,64(s1)
    8000316a:	2785                	addiw	a5,a5,1
    8000316c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	92a50513          	addi	a0,a0,-1750 # 80016a98 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b14080e7          	jalr	-1260(ra) # 80000c8a <release>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	64a2                	ld	s1,8(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret

0000000080003188 <bunpin>:

void
bunpin(struct buf *b) {
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	e426                	sd	s1,8(sp)
    80003190:	1000                	addi	s0,sp,32
    80003192:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003194:	00014517          	auipc	a0,0x14
    80003198:	90450513          	addi	a0,a0,-1788 # 80016a98 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	a3a080e7          	jalr	-1478(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031a4:	40bc                	lw	a5,64(s1)
    800031a6:	37fd                	addiw	a5,a5,-1
    800031a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	8ee50513          	addi	a0,a0,-1810 # 80016a98 <bcache>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	ad8080e7          	jalr	-1320(ra) # 80000c8a <release>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	e426                	sd	s1,8(sp)
    800031cc:	e04a                	sd	s2,0(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031d2:	00d5d59b          	srliw	a1,a1,0xd
    800031d6:	0001c797          	auipc	a5,0x1c
    800031da:	f9e7a783          	lw	a5,-98(a5) # 8001f174 <sb+0x1c>
    800031de:	9dbd                	addw	a1,a1,a5
    800031e0:	00000097          	auipc	ra,0x0
    800031e4:	d9e080e7          	jalr	-610(ra) # 80002f7e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e8:	0074f713          	andi	a4,s1,7
    800031ec:	4785                	li	a5,1
    800031ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031f2:	14ce                	slli	s1,s1,0x33
    800031f4:	90d9                	srli	s1,s1,0x36
    800031f6:	00950733          	add	a4,a0,s1
    800031fa:	05874703          	lbu	a4,88(a4)
    800031fe:	00e7f6b3          	and	a3,a5,a4
    80003202:	c69d                	beqz	a3,80003230 <bfree+0x6c>
    80003204:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003206:	94aa                	add	s1,s1,a0
    80003208:	fff7c793          	not	a5,a5
    8000320c:	8f7d                	and	a4,a4,a5
    8000320e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003212:	00001097          	auipc	ra,0x1
    80003216:	126080e7          	jalr	294(ra) # 80004338 <log_write>
  brelse(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	e92080e7          	jalr	-366(ra) # 800030ae <brelse>
}
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	64a2                	ld	s1,8(sp)
    8000322a:	6902                	ld	s2,0(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret
    panic("freeing free block");
    80003230:	00005517          	auipc	a0,0x5
    80003234:	40050513          	addi	a0,a0,1024 # 80008630 <syscalls+0xf8>
    80003238:	ffffd097          	auipc	ra,0xffffd
    8000323c:	308080e7          	jalr	776(ra) # 80000540 <panic>

0000000080003240 <balloc>:
{
    80003240:	711d                	addi	sp,sp,-96
    80003242:	ec86                	sd	ra,88(sp)
    80003244:	e8a2                	sd	s0,80(sp)
    80003246:	e4a6                	sd	s1,72(sp)
    80003248:	e0ca                	sd	s2,64(sp)
    8000324a:	fc4e                	sd	s3,56(sp)
    8000324c:	f852                	sd	s4,48(sp)
    8000324e:	f456                	sd	s5,40(sp)
    80003250:	f05a                	sd	s6,32(sp)
    80003252:	ec5e                	sd	s7,24(sp)
    80003254:	e862                	sd	s8,16(sp)
    80003256:	e466                	sd	s9,8(sp)
    80003258:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000325a:	0001c797          	auipc	a5,0x1c
    8000325e:	f027a783          	lw	a5,-254(a5) # 8001f15c <sb+0x4>
    80003262:	cff5                	beqz	a5,8000335e <balloc+0x11e>
    80003264:	8baa                	mv	s7,a0
    80003266:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003268:	0001cb17          	auipc	s6,0x1c
    8000326c:	ef0b0b13          	addi	s6,s6,-272 # 8001f158 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003272:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003274:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003276:	6c89                	lui	s9,0x2
    80003278:	a061                	j	80003300 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000327a:	97ca                	add	a5,a5,s2
    8000327c:	8e55                	or	a2,a2,a3
    8000327e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003282:	854a                	mv	a0,s2
    80003284:	00001097          	auipc	ra,0x1
    80003288:	0b4080e7          	jalr	180(ra) # 80004338 <log_write>
        brelse(bp);
    8000328c:	854a                	mv	a0,s2
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	e20080e7          	jalr	-480(ra) # 800030ae <brelse>
  bp = bread(dev, bno);
    80003296:	85a6                	mv	a1,s1
    80003298:	855e                	mv	a0,s7
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	ce4080e7          	jalr	-796(ra) # 80002f7e <bread>
    800032a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a4:	40000613          	li	a2,1024
    800032a8:	4581                	li	a1,0
    800032aa:	05850513          	addi	a0,a0,88
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	a24080e7          	jalr	-1500(ra) # 80000cd2 <memset>
  log_write(bp);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	080080e7          	jalr	128(ra) # 80004338 <log_write>
  brelse(bp);
    800032c0:	854a                	mv	a0,s2
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	dec080e7          	jalr	-532(ra) # 800030ae <brelse>
}
    800032ca:	8526                	mv	a0,s1
    800032cc:	60e6                	ld	ra,88(sp)
    800032ce:	6446                	ld	s0,80(sp)
    800032d0:	64a6                	ld	s1,72(sp)
    800032d2:	6906                	ld	s2,64(sp)
    800032d4:	79e2                	ld	s3,56(sp)
    800032d6:	7a42                	ld	s4,48(sp)
    800032d8:	7aa2                	ld	s5,40(sp)
    800032da:	7b02                	ld	s6,32(sp)
    800032dc:	6be2                	ld	s7,24(sp)
    800032de:	6c42                	ld	s8,16(sp)
    800032e0:	6ca2                	ld	s9,8(sp)
    800032e2:	6125                	addi	sp,sp,96
    800032e4:	8082                	ret
    brelse(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	dc6080e7          	jalr	-570(ra) # 800030ae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032f0:	015c87bb          	addw	a5,s9,s5
    800032f4:	00078a9b          	sext.w	s5,a5
    800032f8:	004b2703          	lw	a4,4(s6)
    800032fc:	06eaf163          	bgeu	s5,a4,8000335e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003300:	41fad79b          	sraiw	a5,s5,0x1f
    80003304:	0137d79b          	srliw	a5,a5,0x13
    80003308:	015787bb          	addw	a5,a5,s5
    8000330c:	40d7d79b          	sraiw	a5,a5,0xd
    80003310:	01cb2583          	lw	a1,28(s6)
    80003314:	9dbd                	addw	a1,a1,a5
    80003316:	855e                	mv	a0,s7
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	c66080e7          	jalr	-922(ra) # 80002f7e <bread>
    80003320:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003322:	004b2503          	lw	a0,4(s6)
    80003326:	000a849b          	sext.w	s1,s5
    8000332a:	8762                	mv	a4,s8
    8000332c:	faa4fde3          	bgeu	s1,a0,800032e6 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003330:	00777693          	andi	a3,a4,7
    80003334:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003338:	41f7579b          	sraiw	a5,a4,0x1f
    8000333c:	01d7d79b          	srliw	a5,a5,0x1d
    80003340:	9fb9                	addw	a5,a5,a4
    80003342:	4037d79b          	sraiw	a5,a5,0x3
    80003346:	00f90633          	add	a2,s2,a5
    8000334a:	05864603          	lbu	a2,88(a2)
    8000334e:	00c6f5b3          	and	a1,a3,a2
    80003352:	d585                	beqz	a1,8000327a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003354:	2705                	addiw	a4,a4,1
    80003356:	2485                	addiw	s1,s1,1
    80003358:	fd471ae3          	bne	a4,s4,8000332c <balloc+0xec>
    8000335c:	b769                	j	800032e6 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	2ea50513          	addi	a0,a0,746 # 80008648 <syscalls+0x110>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	224080e7          	jalr	548(ra) # 8000058a <printf>
  return 0;
    8000336e:	4481                	li	s1,0
    80003370:	bfa9                	j	800032ca <balloc+0x8a>

0000000080003372 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003372:	7179                	addi	sp,sp,-48
    80003374:	f406                	sd	ra,40(sp)
    80003376:	f022                	sd	s0,32(sp)
    80003378:	ec26                	sd	s1,24(sp)
    8000337a:	e84a                	sd	s2,16(sp)
    8000337c:	e44e                	sd	s3,8(sp)
    8000337e:	e052                	sd	s4,0(sp)
    80003380:	1800                	addi	s0,sp,48
    80003382:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003384:	47ad                	li	a5,11
    80003386:	02b7e863          	bltu	a5,a1,800033b6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000338a:	02059793          	slli	a5,a1,0x20
    8000338e:	01e7d593          	srli	a1,a5,0x1e
    80003392:	00b504b3          	add	s1,a0,a1
    80003396:	0504a903          	lw	s2,80(s1)
    8000339a:	06091e63          	bnez	s2,80003416 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000339e:	4108                	lw	a0,0(a0)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	ea0080e7          	jalr	-352(ra) # 80003240 <balloc>
    800033a8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ac:	06090563          	beqz	s2,80003416 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033b0:	0524a823          	sw	s2,80(s1)
    800033b4:	a08d                	j	80003416 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033b6:	ff45849b          	addiw	s1,a1,-12
    800033ba:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033be:	0ff00793          	li	a5,255
    800033c2:	08e7e563          	bltu	a5,a4,8000344c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033c6:	08052903          	lw	s2,128(a0)
    800033ca:	00091d63          	bnez	s2,800033e4 <bmap+0x72>
      addr = balloc(ip->dev);
    800033ce:	4108                	lw	a0,0(a0)
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	e70080e7          	jalr	-400(ra) # 80003240 <balloc>
    800033d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033dc:	02090d63          	beqz	s2,80003416 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033e0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033e4:	85ca                	mv	a1,s2
    800033e6:	0009a503          	lw	a0,0(s3)
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	b94080e7          	jalr	-1132(ra) # 80002f7e <bread>
    800033f2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033f4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033f8:	02049713          	slli	a4,s1,0x20
    800033fc:	01e75593          	srli	a1,a4,0x1e
    80003400:	00b784b3          	add	s1,a5,a1
    80003404:	0004a903          	lw	s2,0(s1)
    80003408:	02090063          	beqz	s2,80003428 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000340c:	8552                	mv	a0,s4
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	ca0080e7          	jalr	-864(ra) # 800030ae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003416:	854a                	mv	a0,s2
    80003418:	70a2                	ld	ra,40(sp)
    8000341a:	7402                	ld	s0,32(sp)
    8000341c:	64e2                	ld	s1,24(sp)
    8000341e:	6942                	ld	s2,16(sp)
    80003420:	69a2                	ld	s3,8(sp)
    80003422:	6a02                	ld	s4,0(sp)
    80003424:	6145                	addi	sp,sp,48
    80003426:	8082                	ret
      addr = balloc(ip->dev);
    80003428:	0009a503          	lw	a0,0(s3)
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	e14080e7          	jalr	-492(ra) # 80003240 <balloc>
    80003434:	0005091b          	sext.w	s2,a0
      if(addr){
    80003438:	fc090ae3          	beqz	s2,8000340c <bmap+0x9a>
        a[bn] = addr;
    8000343c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003440:	8552                	mv	a0,s4
    80003442:	00001097          	auipc	ra,0x1
    80003446:	ef6080e7          	jalr	-266(ra) # 80004338 <log_write>
    8000344a:	b7c9                	j	8000340c <bmap+0x9a>
  panic("bmap: out of range");
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	21450513          	addi	a0,a0,532 # 80008660 <syscalls+0x128>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	0ec080e7          	jalr	236(ra) # 80000540 <panic>

000000008000345c <iget>:
{
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	e84a                	sd	s2,16(sp)
    80003466:	e44e                	sd	s3,8(sp)
    80003468:	e052                	sd	s4,0(sp)
    8000346a:	1800                	addi	s0,sp,48
    8000346c:	89aa                	mv	s3,a0
    8000346e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003470:	0001c517          	auipc	a0,0x1c
    80003474:	d0850513          	addi	a0,a0,-760 # 8001f178 <itable>
    80003478:	ffffd097          	auipc	ra,0xffffd
    8000347c:	75e080e7          	jalr	1886(ra) # 80000bd6 <acquire>
  empty = 0;
    80003480:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003482:	0001c497          	auipc	s1,0x1c
    80003486:	d0e48493          	addi	s1,s1,-754 # 8001f190 <itable+0x18>
    8000348a:	0001d697          	auipc	a3,0x1d
    8000348e:	79668693          	addi	a3,a3,1942 # 80020c20 <log>
    80003492:	a039                	j	800034a0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003494:	02090b63          	beqz	s2,800034ca <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003498:	08848493          	addi	s1,s1,136
    8000349c:	02d48a63          	beq	s1,a3,800034d0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a0:	449c                	lw	a5,8(s1)
    800034a2:	fef059e3          	blez	a5,80003494 <iget+0x38>
    800034a6:	4098                	lw	a4,0(s1)
    800034a8:	ff3716e3          	bne	a4,s3,80003494 <iget+0x38>
    800034ac:	40d8                	lw	a4,4(s1)
    800034ae:	ff4713e3          	bne	a4,s4,80003494 <iget+0x38>
      ip->ref++;
    800034b2:	2785                	addiw	a5,a5,1
    800034b4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034b6:	0001c517          	auipc	a0,0x1c
    800034ba:	cc250513          	addi	a0,a0,-830 # 8001f178 <itable>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	7cc080e7          	jalr	1996(ra) # 80000c8a <release>
      return ip;
    800034c6:	8926                	mv	s2,s1
    800034c8:	a03d                	j	800034f6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ca:	f7f9                	bnez	a5,80003498 <iget+0x3c>
    800034cc:	8926                	mv	s2,s1
    800034ce:	b7e9                	j	80003498 <iget+0x3c>
  if(empty == 0)
    800034d0:	02090c63          	beqz	s2,80003508 <iget+0xac>
  ip->dev = dev;
    800034d4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034d8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034dc:	4785                	li	a5,1
    800034de:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034e6:	0001c517          	auipc	a0,0x1c
    800034ea:	c9250513          	addi	a0,a0,-878 # 8001f178 <itable>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	79c080e7          	jalr	1948(ra) # 80000c8a <release>
}
    800034f6:	854a                	mv	a0,s2
    800034f8:	70a2                	ld	ra,40(sp)
    800034fa:	7402                	ld	s0,32(sp)
    800034fc:	64e2                	ld	s1,24(sp)
    800034fe:	6942                	ld	s2,16(sp)
    80003500:	69a2                	ld	s3,8(sp)
    80003502:	6a02                	ld	s4,0(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    panic("iget: no inodes");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	17050513          	addi	a0,a0,368 # 80008678 <syscalls+0x140>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	030080e7          	jalr	48(ra) # 80000540 <panic>

0000000080003518 <fsinit>:
fsinit(int dev) {
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
    80003526:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003528:	4585                	li	a1,1
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	a54080e7          	jalr	-1452(ra) # 80002f7e <bread>
    80003532:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003534:	0001c997          	auipc	s3,0x1c
    80003538:	c2498993          	addi	s3,s3,-988 # 8001f158 <sb>
    8000353c:	02000613          	li	a2,32
    80003540:	05850593          	addi	a1,a0,88
    80003544:	854e                	mv	a0,s3
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	7e8080e7          	jalr	2024(ra) # 80000d2e <memmove>
  brelse(bp);
    8000354e:	8526                	mv	a0,s1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	b5e080e7          	jalr	-1186(ra) # 800030ae <brelse>
  if(sb.magic != FSMAGIC)
    80003558:	0009a703          	lw	a4,0(s3)
    8000355c:	102037b7          	lui	a5,0x10203
    80003560:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003564:	02f71263          	bne	a4,a5,80003588 <fsinit+0x70>
  initlog(dev, &sb);
    80003568:	0001c597          	auipc	a1,0x1c
    8000356c:	bf058593          	addi	a1,a1,-1040 # 8001f158 <sb>
    80003570:	854a                	mv	a0,s2
    80003572:	00001097          	auipc	ra,0x1
    80003576:	b4a080e7          	jalr	-1206(ra) # 800040bc <initlog>
}
    8000357a:	70a2                	ld	ra,40(sp)
    8000357c:	7402                	ld	s0,32(sp)
    8000357e:	64e2                	ld	s1,24(sp)
    80003580:	6942                	ld	s2,16(sp)
    80003582:	69a2                	ld	s3,8(sp)
    80003584:	6145                	addi	sp,sp,48
    80003586:	8082                	ret
    panic("invalid file system");
    80003588:	00005517          	auipc	a0,0x5
    8000358c:	10050513          	addi	a0,a0,256 # 80008688 <syscalls+0x150>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	fb0080e7          	jalr	-80(ra) # 80000540 <panic>

0000000080003598 <iinit>:
{
    80003598:	7179                	addi	sp,sp,-48
    8000359a:	f406                	sd	ra,40(sp)
    8000359c:	f022                	sd	s0,32(sp)
    8000359e:	ec26                	sd	s1,24(sp)
    800035a0:	e84a                	sd	s2,16(sp)
    800035a2:	e44e                	sd	s3,8(sp)
    800035a4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035a6:	00005597          	auipc	a1,0x5
    800035aa:	0fa58593          	addi	a1,a1,250 # 800086a0 <syscalls+0x168>
    800035ae:	0001c517          	auipc	a0,0x1c
    800035b2:	bca50513          	addi	a0,a0,-1078 # 8001f178 <itable>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	590080e7          	jalr	1424(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035be:	0001c497          	auipc	s1,0x1c
    800035c2:	be248493          	addi	s1,s1,-1054 # 8001f1a0 <itable+0x28>
    800035c6:	0001d997          	auipc	s3,0x1d
    800035ca:	66a98993          	addi	s3,s3,1642 # 80020c30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ce:	00005917          	auipc	s2,0x5
    800035d2:	0da90913          	addi	s2,s2,218 # 800086a8 <syscalls+0x170>
    800035d6:	85ca                	mv	a1,s2
    800035d8:	8526                	mv	a0,s1
    800035da:	00001097          	auipc	ra,0x1
    800035de:	e42080e7          	jalr	-446(ra) # 8000441c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e2:	08848493          	addi	s1,s1,136
    800035e6:	ff3498e3          	bne	s1,s3,800035d6 <iinit+0x3e>
}
    800035ea:	70a2                	ld	ra,40(sp)
    800035ec:	7402                	ld	s0,32(sp)
    800035ee:	64e2                	ld	s1,24(sp)
    800035f0:	6942                	ld	s2,16(sp)
    800035f2:	69a2                	ld	s3,8(sp)
    800035f4:	6145                	addi	sp,sp,48
    800035f6:	8082                	ret

00000000800035f8 <ialloc>:
{
    800035f8:	715d                	addi	sp,sp,-80
    800035fa:	e486                	sd	ra,72(sp)
    800035fc:	e0a2                	sd	s0,64(sp)
    800035fe:	fc26                	sd	s1,56(sp)
    80003600:	f84a                	sd	s2,48(sp)
    80003602:	f44e                	sd	s3,40(sp)
    80003604:	f052                	sd	s4,32(sp)
    80003606:	ec56                	sd	s5,24(sp)
    80003608:	e85a                	sd	s6,16(sp)
    8000360a:	e45e                	sd	s7,8(sp)
    8000360c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360e:	0001c717          	auipc	a4,0x1c
    80003612:	b5672703          	lw	a4,-1194(a4) # 8001f164 <sb+0xc>
    80003616:	4785                	li	a5,1
    80003618:	04e7fa63          	bgeu	a5,a4,8000366c <ialloc+0x74>
    8000361c:	8aaa                	mv	s5,a0
    8000361e:	8bae                	mv	s7,a1
    80003620:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003622:	0001ca17          	auipc	s4,0x1c
    80003626:	b36a0a13          	addi	s4,s4,-1226 # 8001f158 <sb>
    8000362a:	00048b1b          	sext.w	s6,s1
    8000362e:	0044d593          	srli	a1,s1,0x4
    80003632:	018a2783          	lw	a5,24(s4)
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	8556                	mv	a0,s5
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	944080e7          	jalr	-1724(ra) # 80002f7e <bread>
    80003642:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003644:	05850993          	addi	s3,a0,88
    80003648:	00f4f793          	andi	a5,s1,15
    8000364c:	079a                	slli	a5,a5,0x6
    8000364e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003650:	00099783          	lh	a5,0(s3)
    80003654:	c3a1                	beqz	a5,80003694 <ialloc+0x9c>
    brelse(bp);
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	a58080e7          	jalr	-1448(ra) # 800030ae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365e:	0485                	addi	s1,s1,1
    80003660:	00ca2703          	lw	a4,12(s4)
    80003664:	0004879b          	sext.w	a5,s1
    80003668:	fce7e1e3          	bltu	a5,a4,8000362a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000366c:	00005517          	auipc	a0,0x5
    80003670:	04450513          	addi	a0,a0,68 # 800086b0 <syscalls+0x178>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	f16080e7          	jalr	-234(ra) # 8000058a <printf>
  return 0;
    8000367c:	4501                	li	a0,0
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
      memset(dip, 0, sizeof(*dip));
    80003694:	04000613          	li	a2,64
    80003698:	4581                	li	a1,0
    8000369a:	854e                	mv	a0,s3
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	636080e7          	jalr	1590(ra) # 80000cd2 <memset>
      dip->type = type;
    800036a4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036a8:	854a                	mv	a0,s2
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	c8e080e7          	jalr	-882(ra) # 80004338 <log_write>
      brelse(bp);
    800036b2:	854a                	mv	a0,s2
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	9fa080e7          	jalr	-1542(ra) # 800030ae <brelse>
      return iget(dev, inum);
    800036bc:	85da                	mv	a1,s6
    800036be:	8556                	mv	a0,s5
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	d9c080e7          	jalr	-612(ra) # 8000345c <iget>
    800036c8:	bf5d                	j	8000367e <ialloc+0x86>

00000000800036ca <iupdate>:
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	e04a                	sd	s2,0(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d8:	415c                	lw	a5,4(a0)
    800036da:	0047d79b          	srliw	a5,a5,0x4
    800036de:	0001c597          	auipc	a1,0x1c
    800036e2:	a925a583          	lw	a1,-1390(a1) # 8001f170 <sb+0x18>
    800036e6:	9dbd                	addw	a1,a1,a5
    800036e8:	4108                	lw	a0,0(a0)
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	894080e7          	jalr	-1900(ra) # 80002f7e <bread>
    800036f2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f4:	05850793          	addi	a5,a0,88
    800036f8:	40d8                	lw	a4,4(s1)
    800036fa:	8b3d                	andi	a4,a4,15
    800036fc:	071a                	slli	a4,a4,0x6
    800036fe:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003700:	04449703          	lh	a4,68(s1)
    80003704:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003708:	04649703          	lh	a4,70(s1)
    8000370c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003710:	04849703          	lh	a4,72(s1)
    80003714:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003718:	04a49703          	lh	a4,74(s1)
    8000371c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003720:	44f8                	lw	a4,76(s1)
    80003722:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003724:	03400613          	li	a2,52
    80003728:	05048593          	addi	a1,s1,80
    8000372c:	00c78513          	addi	a0,a5,12
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	5fe080e7          	jalr	1534(ra) # 80000d2e <memmove>
  log_write(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	bfe080e7          	jalr	-1026(ra) # 80004338 <log_write>
  brelse(bp);
    80003742:	854a                	mv	a0,s2
    80003744:	00000097          	auipc	ra,0x0
    80003748:	96a080e7          	jalr	-1686(ra) # 800030ae <brelse>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6902                	ld	s2,0(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret

0000000080003758 <idup>:
{
    80003758:	1101                	addi	sp,sp,-32
    8000375a:	ec06                	sd	ra,24(sp)
    8000375c:	e822                	sd	s0,16(sp)
    8000375e:	e426                	sd	s1,8(sp)
    80003760:	1000                	addi	s0,sp,32
    80003762:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003764:	0001c517          	auipc	a0,0x1c
    80003768:	a1450513          	addi	a0,a0,-1516 # 8001f178 <itable>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	46a080e7          	jalr	1130(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003774:	449c                	lw	a5,8(s1)
    80003776:	2785                	addiw	a5,a5,1
    80003778:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	9fe50513          	addi	a0,a0,-1538 # 8001f178 <itable>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	508080e7          	jalr	1288(ra) # 80000c8a <release>
}
    8000378a:	8526                	mv	a0,s1
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret

0000000080003796 <ilock>:
{
    80003796:	1101                	addi	sp,sp,-32
    80003798:	ec06                	sd	ra,24(sp)
    8000379a:	e822                	sd	s0,16(sp)
    8000379c:	e426                	sd	s1,8(sp)
    8000379e:	e04a                	sd	s2,0(sp)
    800037a0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a2:	c115                	beqz	a0,800037c6 <ilock+0x30>
    800037a4:	84aa                	mv	s1,a0
    800037a6:	451c                	lw	a5,8(a0)
    800037a8:	00f05f63          	blez	a5,800037c6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ac:	0541                	addi	a0,a0,16
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	ca8080e7          	jalr	-856(ra) # 80004456 <acquiresleep>
  if(ip->valid == 0){
    800037b6:	40bc                	lw	a5,64(s1)
    800037b8:	cf99                	beqz	a5,800037d6 <ilock+0x40>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6902                	ld	s2,0(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret
    panic("ilock");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	f0250513          	addi	a0,a0,-254 # 800086c8 <syscalls+0x190>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d72080e7          	jalr	-654(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d6:	40dc                	lw	a5,4(s1)
    800037d8:	0047d79b          	srliw	a5,a5,0x4
    800037dc:	0001c597          	auipc	a1,0x1c
    800037e0:	9945a583          	lw	a1,-1644(a1) # 8001f170 <sb+0x18>
    800037e4:	9dbd                	addw	a1,a1,a5
    800037e6:	4088                	lw	a0,0(s1)
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	796080e7          	jalr	1942(ra) # 80002f7e <bread>
    800037f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f2:	05850593          	addi	a1,a0,88
    800037f6:	40dc                	lw	a5,4(s1)
    800037f8:	8bbd                	andi	a5,a5,15
    800037fa:	079a                	slli	a5,a5,0x6
    800037fc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037fe:	00059783          	lh	a5,0(a1)
    80003802:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003806:	00259783          	lh	a5,2(a1)
    8000380a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000380e:	00459783          	lh	a5,4(a1)
    80003812:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003816:	00659783          	lh	a5,6(a1)
    8000381a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000381e:	459c                	lw	a5,8(a1)
    80003820:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003822:	03400613          	li	a2,52
    80003826:	05b1                	addi	a1,a1,12
    80003828:	05048513          	addi	a0,s1,80
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	502080e7          	jalr	1282(ra) # 80000d2e <memmove>
    brelse(bp);
    80003834:	854a                	mv	a0,s2
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	878080e7          	jalr	-1928(ra) # 800030ae <brelse>
    ip->valid = 1;
    8000383e:	4785                	li	a5,1
    80003840:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003842:	04449783          	lh	a5,68(s1)
    80003846:	fbb5                	bnez	a5,800037ba <ilock+0x24>
      panic("ilock: no type");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	e8850513          	addi	a0,a0,-376 # 800086d0 <syscalls+0x198>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cf0080e7          	jalr	-784(ra) # 80000540 <panic>

0000000080003858 <iunlock>:
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	e04a                	sd	s2,0(sp)
    80003862:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003864:	c905                	beqz	a0,80003894 <iunlock+0x3c>
    80003866:	84aa                	mv	s1,a0
    80003868:	01050913          	addi	s2,a0,16
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	c82080e7          	jalr	-894(ra) # 800044f0 <holdingsleep>
    80003876:	cd19                	beqz	a0,80003894 <iunlock+0x3c>
    80003878:	449c                	lw	a5,8(s1)
    8000387a:	00f05d63          	blez	a5,80003894 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c2c080e7          	jalr	-980(ra) # 800044ac <releasesleep>
}
    80003888:	60e2                	ld	ra,24(sp)
    8000388a:	6442                	ld	s0,16(sp)
    8000388c:	64a2                	ld	s1,8(sp)
    8000388e:	6902                	ld	s2,0(sp)
    80003890:	6105                	addi	sp,sp,32
    80003892:	8082                	ret
    panic("iunlock");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	e4c50513          	addi	a0,a0,-436 # 800086e0 <syscalls+0x1a8>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	ca4080e7          	jalr	-860(ra) # 80000540 <panic>

00000000800038a4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a4:	7179                	addi	sp,sp,-48
    800038a6:	f406                	sd	ra,40(sp)
    800038a8:	f022                	sd	s0,32(sp)
    800038aa:	ec26                	sd	s1,24(sp)
    800038ac:	e84a                	sd	s2,16(sp)
    800038ae:	e44e                	sd	s3,8(sp)
    800038b0:	e052                	sd	s4,0(sp)
    800038b2:	1800                	addi	s0,sp,48
    800038b4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b6:	05050493          	addi	s1,a0,80
    800038ba:	08050913          	addi	s2,a0,128
    800038be:	a021                	j	800038c6 <itrunc+0x22>
    800038c0:	0491                	addi	s1,s1,4
    800038c2:	01248d63          	beq	s1,s2,800038dc <itrunc+0x38>
    if(ip->addrs[i]){
    800038c6:	408c                	lw	a1,0(s1)
    800038c8:	dde5                	beqz	a1,800038c0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ca:	0009a503          	lw	a0,0(s3)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	8f6080e7          	jalr	-1802(ra) # 800031c4 <bfree>
      ip->addrs[i] = 0;
    800038d6:	0004a023          	sw	zero,0(s1)
    800038da:	b7dd                	j	800038c0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038dc:	0809a583          	lw	a1,128(s3)
    800038e0:	e185                	bnez	a1,80003900 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e6:	854e                	mv	a0,s3
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	de2080e7          	jalr	-542(ra) # 800036ca <iupdate>
}
    800038f0:	70a2                	ld	ra,40(sp)
    800038f2:	7402                	ld	s0,32(sp)
    800038f4:	64e2                	ld	s1,24(sp)
    800038f6:	6942                	ld	s2,16(sp)
    800038f8:	69a2                	ld	s3,8(sp)
    800038fa:	6a02                	ld	s4,0(sp)
    800038fc:	6145                	addi	sp,sp,48
    800038fe:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	67a080e7          	jalr	1658(ra) # 80002f7e <bread>
    8000390c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000390e:	05850493          	addi	s1,a0,88
    80003912:	45850913          	addi	s2,a0,1112
    80003916:	a021                	j	8000391e <itrunc+0x7a>
    80003918:	0491                	addi	s1,s1,4
    8000391a:	01248b63          	beq	s1,s2,80003930 <itrunc+0x8c>
      if(a[j])
    8000391e:	408c                	lw	a1,0(s1)
    80003920:	dde5                	beqz	a1,80003918 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003922:	0009a503          	lw	a0,0(s3)
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	89e080e7          	jalr	-1890(ra) # 800031c4 <bfree>
    8000392e:	b7ed                	j	80003918 <itrunc+0x74>
    brelse(bp);
    80003930:	8552                	mv	a0,s4
    80003932:	fffff097          	auipc	ra,0xfffff
    80003936:	77c080e7          	jalr	1916(ra) # 800030ae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000393a:	0809a583          	lw	a1,128(s3)
    8000393e:	0009a503          	lw	a0,0(s3)
    80003942:	00000097          	auipc	ra,0x0
    80003946:	882080e7          	jalr	-1918(ra) # 800031c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000394a:	0809a023          	sw	zero,128(s3)
    8000394e:	bf51                	j	800038e2 <itrunc+0x3e>

0000000080003950 <iput>:
{
    80003950:	1101                	addi	sp,sp,-32
    80003952:	ec06                	sd	ra,24(sp)
    80003954:	e822                	sd	s0,16(sp)
    80003956:	e426                	sd	s1,8(sp)
    80003958:	e04a                	sd	s2,0(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	81a50513          	addi	a0,a0,-2022 # 8001f178 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	270080e7          	jalr	624(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396e:	4498                	lw	a4,8(s1)
    80003970:	4785                	li	a5,1
    80003972:	02f70363          	beq	a4,a5,80003998 <iput+0x48>
  ip->ref--;
    80003976:	449c                	lw	a5,8(s1)
    80003978:	37fd                	addiw	a5,a5,-1
    8000397a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000397c:	0001b517          	auipc	a0,0x1b
    80003980:	7fc50513          	addi	a0,a0,2044 # 8001f178 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	306080e7          	jalr	774(ra) # 80000c8a <release>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003998:	40bc                	lw	a5,64(s1)
    8000399a:	dff1                	beqz	a5,80003976 <iput+0x26>
    8000399c:	04a49783          	lh	a5,74(s1)
    800039a0:	fbf9                	bnez	a5,80003976 <iput+0x26>
    acquiresleep(&ip->lock);
    800039a2:	01048913          	addi	s2,s1,16
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	aae080e7          	jalr	-1362(ra) # 80004456 <acquiresleep>
    release(&itable.lock);
    800039b0:	0001b517          	auipc	a0,0x1b
    800039b4:	7c850513          	addi	a0,a0,1992 # 8001f178 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2d2080e7          	jalr	722(ra) # 80000c8a <release>
    itrunc(ip);
    800039c0:	8526                	mv	a0,s1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	ee2080e7          	jalr	-286(ra) # 800038a4 <itrunc>
    ip->type = 0;
    800039ca:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ce:	8526                	mv	a0,s1
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	cfa080e7          	jalr	-774(ra) # 800036ca <iupdate>
    ip->valid = 0;
    800039d8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	ace080e7          	jalr	-1330(ra) # 800044ac <releasesleep>
    acquire(&itable.lock);
    800039e6:	0001b517          	auipc	a0,0x1b
    800039ea:	79250513          	addi	a0,a0,1938 # 8001f178 <itable>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	1e8080e7          	jalr	488(ra) # 80000bd6 <acquire>
    800039f6:	b741                	j	80003976 <iput+0x26>

00000000800039f8 <iunlockput>:
{
    800039f8:	1101                	addi	sp,sp,-32
    800039fa:	ec06                	sd	ra,24(sp)
    800039fc:	e822                	sd	s0,16(sp)
    800039fe:	e426                	sd	s1,8(sp)
    80003a00:	1000                	addi	s0,sp,32
    80003a02:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	e54080e7          	jalr	-428(ra) # 80003858 <iunlock>
  iput(ip);
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	f42080e7          	jalr	-190(ra) # 80003950 <iput>
}
    80003a16:	60e2                	ld	ra,24(sp)
    80003a18:	6442                	ld	s0,16(sp)
    80003a1a:	64a2                	ld	s1,8(sp)
    80003a1c:	6105                	addi	sp,sp,32
    80003a1e:	8082                	ret

0000000080003a20 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a20:	1141                	addi	sp,sp,-16
    80003a22:	e422                	sd	s0,8(sp)
    80003a24:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a26:	411c                	lw	a5,0(a0)
    80003a28:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a2a:	415c                	lw	a5,4(a0)
    80003a2c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a2e:	04451783          	lh	a5,68(a0)
    80003a32:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a36:	04a51783          	lh	a5,74(a0)
    80003a3a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a3e:	04c56783          	lwu	a5,76(a0)
    80003a42:	e99c                	sd	a5,16(a1)
}
    80003a44:	6422                	ld	s0,8(sp)
    80003a46:	0141                	addi	sp,sp,16
    80003a48:	8082                	ret

0000000080003a4a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a4a:	457c                	lw	a5,76(a0)
    80003a4c:	0ed7e963          	bltu	a5,a3,80003b3e <readi+0xf4>
{
    80003a50:	7159                	addi	sp,sp,-112
    80003a52:	f486                	sd	ra,104(sp)
    80003a54:	f0a2                	sd	s0,96(sp)
    80003a56:	eca6                	sd	s1,88(sp)
    80003a58:	e8ca                	sd	s2,80(sp)
    80003a5a:	e4ce                	sd	s3,72(sp)
    80003a5c:	e0d2                	sd	s4,64(sp)
    80003a5e:	fc56                	sd	s5,56(sp)
    80003a60:	f85a                	sd	s6,48(sp)
    80003a62:	f45e                	sd	s7,40(sp)
    80003a64:	f062                	sd	s8,32(sp)
    80003a66:	ec66                	sd	s9,24(sp)
    80003a68:	e86a                	sd	s10,16(sp)
    80003a6a:	e46e                	sd	s11,8(sp)
    80003a6c:	1880                	addi	s0,sp,112
    80003a6e:	8b2a                	mv	s6,a0
    80003a70:	8bae                	mv	s7,a1
    80003a72:	8a32                	mv	s4,a2
    80003a74:	84b6                	mv	s1,a3
    80003a76:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a78:	9f35                	addw	a4,a4,a3
    return 0;
    80003a7a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a7c:	0ad76063          	bltu	a4,a3,80003b1c <readi+0xd2>
  if(off + n > ip->size)
    80003a80:	00e7f463          	bgeu	a5,a4,80003a88 <readi+0x3e>
    n = ip->size - off;
    80003a84:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a88:	0a0a8963          	beqz	s5,80003b3a <readi+0xf0>
    80003a8c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a92:	5c7d                	li	s8,-1
    80003a94:	a82d                	j	80003ace <readi+0x84>
    80003a96:	020d1d93          	slli	s11,s10,0x20
    80003a9a:	020ddd93          	srli	s11,s11,0x20
    80003a9e:	05890613          	addi	a2,s2,88
    80003aa2:	86ee                	mv	a3,s11
    80003aa4:	963a                	add	a2,a2,a4
    80003aa6:	85d2                	mv	a1,s4
    80003aa8:	855e                	mv	a0,s7
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	9b2080e7          	jalr	-1614(ra) # 8000245c <either_copyout>
    80003ab2:	05850d63          	beq	a0,s8,80003b0c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	5f6080e7          	jalr	1526(ra) # 800030ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac0:	013d09bb          	addw	s3,s10,s3
    80003ac4:	009d04bb          	addw	s1,s10,s1
    80003ac8:	9a6e                	add	s4,s4,s11
    80003aca:	0559f763          	bgeu	s3,s5,80003b18 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ace:	00a4d59b          	srliw	a1,s1,0xa
    80003ad2:	855a                	mv	a0,s6
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	89e080e7          	jalr	-1890(ra) # 80003372 <bmap>
    80003adc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ae0:	cd85                	beqz	a1,80003b18 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ae2:	000b2503          	lw	a0,0(s6)
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	498080e7          	jalr	1176(ra) # 80002f7e <bread>
    80003aee:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af0:	3ff4f713          	andi	a4,s1,1023
    80003af4:	40ec87bb          	subw	a5,s9,a4
    80003af8:	413a86bb          	subw	a3,s5,s3
    80003afc:	8d3e                	mv	s10,a5
    80003afe:	2781                	sext.w	a5,a5
    80003b00:	0006861b          	sext.w	a2,a3
    80003b04:	f8f679e3          	bgeu	a2,a5,80003a96 <readi+0x4c>
    80003b08:	8d36                	mv	s10,a3
    80003b0a:	b771                	j	80003a96 <readi+0x4c>
      brelse(bp);
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	5a0080e7          	jalr	1440(ra) # 800030ae <brelse>
      tot = -1;
    80003b16:	59fd                	li	s3,-1
  }
  return tot;
    80003b18:	0009851b          	sext.w	a0,s3
}
    80003b1c:	70a6                	ld	ra,104(sp)
    80003b1e:	7406                	ld	s0,96(sp)
    80003b20:	64e6                	ld	s1,88(sp)
    80003b22:	6946                	ld	s2,80(sp)
    80003b24:	69a6                	ld	s3,72(sp)
    80003b26:	6a06                	ld	s4,64(sp)
    80003b28:	7ae2                	ld	s5,56(sp)
    80003b2a:	7b42                	ld	s6,48(sp)
    80003b2c:	7ba2                	ld	s7,40(sp)
    80003b2e:	7c02                	ld	s8,32(sp)
    80003b30:	6ce2                	ld	s9,24(sp)
    80003b32:	6d42                	ld	s10,16(sp)
    80003b34:	6da2                	ld	s11,8(sp)
    80003b36:	6165                	addi	sp,sp,112
    80003b38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3a:	89d6                	mv	s3,s5
    80003b3c:	bff1                	j	80003b18 <readi+0xce>
    return 0;
    80003b3e:	4501                	li	a0,0
}
    80003b40:	8082                	ret

0000000080003b42 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b42:	457c                	lw	a5,76(a0)
    80003b44:	10d7e863          	bltu	a5,a3,80003c54 <writei+0x112>
{
    80003b48:	7159                	addi	sp,sp,-112
    80003b4a:	f486                	sd	ra,104(sp)
    80003b4c:	f0a2                	sd	s0,96(sp)
    80003b4e:	eca6                	sd	s1,88(sp)
    80003b50:	e8ca                	sd	s2,80(sp)
    80003b52:	e4ce                	sd	s3,72(sp)
    80003b54:	e0d2                	sd	s4,64(sp)
    80003b56:	fc56                	sd	s5,56(sp)
    80003b58:	f85a                	sd	s6,48(sp)
    80003b5a:	f45e                	sd	s7,40(sp)
    80003b5c:	f062                	sd	s8,32(sp)
    80003b5e:	ec66                	sd	s9,24(sp)
    80003b60:	e86a                	sd	s10,16(sp)
    80003b62:	e46e                	sd	s11,8(sp)
    80003b64:	1880                	addi	s0,sp,112
    80003b66:	8aaa                	mv	s5,a0
    80003b68:	8bae                	mv	s7,a1
    80003b6a:	8a32                	mv	s4,a2
    80003b6c:	8936                	mv	s2,a3
    80003b6e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b70:	00e687bb          	addw	a5,a3,a4
    80003b74:	0ed7e263          	bltu	a5,a3,80003c58 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b78:	00043737          	lui	a4,0x43
    80003b7c:	0ef76063          	bltu	a4,a5,80003c5c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b80:	0c0b0863          	beqz	s6,80003c50 <writei+0x10e>
    80003b84:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b86:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b8a:	5c7d                	li	s8,-1
    80003b8c:	a091                	j	80003bd0 <writei+0x8e>
    80003b8e:	020d1d93          	slli	s11,s10,0x20
    80003b92:	020ddd93          	srli	s11,s11,0x20
    80003b96:	05848513          	addi	a0,s1,88
    80003b9a:	86ee                	mv	a3,s11
    80003b9c:	8652                	mv	a2,s4
    80003b9e:	85de                	mv	a1,s7
    80003ba0:	953a                	add	a0,a0,a4
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	910080e7          	jalr	-1776(ra) # 800024b2 <either_copyin>
    80003baa:	07850263          	beq	a0,s8,80003c0e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	788080e7          	jalr	1928(ra) # 80004338 <log_write>
    brelse(bp);
    80003bb8:	8526                	mv	a0,s1
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	4f4080e7          	jalr	1268(ra) # 800030ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc2:	013d09bb          	addw	s3,s10,s3
    80003bc6:	012d093b          	addw	s2,s10,s2
    80003bca:	9a6e                	add	s4,s4,s11
    80003bcc:	0569f663          	bgeu	s3,s6,80003c18 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bd0:	00a9559b          	srliw	a1,s2,0xa
    80003bd4:	8556                	mv	a0,s5
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	79c080e7          	jalr	1948(ra) # 80003372 <bmap>
    80003bde:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003be2:	c99d                	beqz	a1,80003c18 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003be4:	000aa503          	lw	a0,0(s5)
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	396080e7          	jalr	918(ra) # 80002f7e <bread>
    80003bf0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf2:	3ff97713          	andi	a4,s2,1023
    80003bf6:	40ec87bb          	subw	a5,s9,a4
    80003bfa:	413b06bb          	subw	a3,s6,s3
    80003bfe:	8d3e                	mv	s10,a5
    80003c00:	2781                	sext.w	a5,a5
    80003c02:	0006861b          	sext.w	a2,a3
    80003c06:	f8f674e3          	bgeu	a2,a5,80003b8e <writei+0x4c>
    80003c0a:	8d36                	mv	s10,a3
    80003c0c:	b749                	j	80003b8e <writei+0x4c>
      brelse(bp);
    80003c0e:	8526                	mv	a0,s1
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	49e080e7          	jalr	1182(ra) # 800030ae <brelse>
  }

  if(off > ip->size)
    80003c18:	04caa783          	lw	a5,76(s5)
    80003c1c:	0127f463          	bgeu	a5,s2,80003c24 <writei+0xe2>
    ip->size = off;
    80003c20:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c24:	8556                	mv	a0,s5
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	aa4080e7          	jalr	-1372(ra) # 800036ca <iupdate>

  return tot;
    80003c2e:	0009851b          	sext.w	a0,s3
}
    80003c32:	70a6                	ld	ra,104(sp)
    80003c34:	7406                	ld	s0,96(sp)
    80003c36:	64e6                	ld	s1,88(sp)
    80003c38:	6946                	ld	s2,80(sp)
    80003c3a:	69a6                	ld	s3,72(sp)
    80003c3c:	6a06                	ld	s4,64(sp)
    80003c3e:	7ae2                	ld	s5,56(sp)
    80003c40:	7b42                	ld	s6,48(sp)
    80003c42:	7ba2                	ld	s7,40(sp)
    80003c44:	7c02                	ld	s8,32(sp)
    80003c46:	6ce2                	ld	s9,24(sp)
    80003c48:	6d42                	ld	s10,16(sp)
    80003c4a:	6da2                	ld	s11,8(sp)
    80003c4c:	6165                	addi	sp,sp,112
    80003c4e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c50:	89da                	mv	s3,s6
    80003c52:	bfc9                	j	80003c24 <writei+0xe2>
    return -1;
    80003c54:	557d                	li	a0,-1
}
    80003c56:	8082                	ret
    return -1;
    80003c58:	557d                	li	a0,-1
    80003c5a:	bfe1                	j	80003c32 <writei+0xf0>
    return -1;
    80003c5c:	557d                	li	a0,-1
    80003c5e:	bfd1                	j	80003c32 <writei+0xf0>

0000000080003c60 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c60:	1141                	addi	sp,sp,-16
    80003c62:	e406                	sd	ra,8(sp)
    80003c64:	e022                	sd	s0,0(sp)
    80003c66:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c68:	4639                	li	a2,14
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	138080e7          	jalr	312(ra) # 80000da2 <strncmp>
}
    80003c72:	60a2                	ld	ra,8(sp)
    80003c74:	6402                	ld	s0,0(sp)
    80003c76:	0141                	addi	sp,sp,16
    80003c78:	8082                	ret

0000000080003c7a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7a:	7139                	addi	sp,sp,-64
    80003c7c:	fc06                	sd	ra,56(sp)
    80003c7e:	f822                	sd	s0,48(sp)
    80003c80:	f426                	sd	s1,40(sp)
    80003c82:	f04a                	sd	s2,32(sp)
    80003c84:	ec4e                	sd	s3,24(sp)
    80003c86:	e852                	sd	s4,16(sp)
    80003c88:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8a:	04451703          	lh	a4,68(a0)
    80003c8e:	4785                	li	a5,1
    80003c90:	00f71a63          	bne	a4,a5,80003ca4 <dirlookup+0x2a>
    80003c94:	892a                	mv	s2,a0
    80003c96:	89ae                	mv	s3,a1
    80003c98:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9a:	457c                	lw	a5,76(a0)
    80003c9c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c9e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca0:	e79d                	bnez	a5,80003cce <dirlookup+0x54>
    80003ca2:	a8a5                	j	80003d1a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	a4450513          	addi	a0,a0,-1468 # 800086e8 <syscalls+0x1b0>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	894080e7          	jalr	-1900(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003cb4:	00005517          	auipc	a0,0x5
    80003cb8:	a4c50513          	addi	a0,a0,-1460 # 80008700 <syscalls+0x1c8>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	884080e7          	jalr	-1916(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc4:	24c1                	addiw	s1,s1,16
    80003cc6:	04c92783          	lw	a5,76(s2)
    80003cca:	04f4f763          	bgeu	s1,a5,80003d18 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cce:	4741                	li	a4,16
    80003cd0:	86a6                	mv	a3,s1
    80003cd2:	fc040613          	addi	a2,s0,-64
    80003cd6:	4581                	li	a1,0
    80003cd8:	854a                	mv	a0,s2
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	d70080e7          	jalr	-656(ra) # 80003a4a <readi>
    80003ce2:	47c1                	li	a5,16
    80003ce4:	fcf518e3          	bne	a0,a5,80003cb4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ce8:	fc045783          	lhu	a5,-64(s0)
    80003cec:	dfe1                	beqz	a5,80003cc4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cee:	fc240593          	addi	a1,s0,-62
    80003cf2:	854e                	mv	a0,s3
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	f6c080e7          	jalr	-148(ra) # 80003c60 <namecmp>
    80003cfc:	f561                	bnez	a0,80003cc4 <dirlookup+0x4a>
      if(poff)
    80003cfe:	000a0463          	beqz	s4,80003d06 <dirlookup+0x8c>
        *poff = off;
    80003d02:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d06:	fc045583          	lhu	a1,-64(s0)
    80003d0a:	00092503          	lw	a0,0(s2)
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	74e080e7          	jalr	1870(ra) # 8000345c <iget>
    80003d16:	a011                	j	80003d1a <dirlookup+0xa0>
  return 0;
    80003d18:	4501                	li	a0,0
}
    80003d1a:	70e2                	ld	ra,56(sp)
    80003d1c:	7442                	ld	s0,48(sp)
    80003d1e:	74a2                	ld	s1,40(sp)
    80003d20:	7902                	ld	s2,32(sp)
    80003d22:	69e2                	ld	s3,24(sp)
    80003d24:	6a42                	ld	s4,16(sp)
    80003d26:	6121                	addi	sp,sp,64
    80003d28:	8082                	ret

0000000080003d2a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2a:	711d                	addi	sp,sp,-96
    80003d2c:	ec86                	sd	ra,88(sp)
    80003d2e:	e8a2                	sd	s0,80(sp)
    80003d30:	e4a6                	sd	s1,72(sp)
    80003d32:	e0ca                	sd	s2,64(sp)
    80003d34:	fc4e                	sd	s3,56(sp)
    80003d36:	f852                	sd	s4,48(sp)
    80003d38:	f456                	sd	s5,40(sp)
    80003d3a:	f05a                	sd	s6,32(sp)
    80003d3c:	ec5e                	sd	s7,24(sp)
    80003d3e:	e862                	sd	s8,16(sp)
    80003d40:	e466                	sd	s9,8(sp)
    80003d42:	e06a                	sd	s10,0(sp)
    80003d44:	1080                	addi	s0,sp,96
    80003d46:	84aa                	mv	s1,a0
    80003d48:	8b2e                	mv	s6,a1
    80003d4a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4c:	00054703          	lbu	a4,0(a0)
    80003d50:	02f00793          	li	a5,47
    80003d54:	02f70363          	beq	a4,a5,80003d7a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d58:	ffffe097          	auipc	ra,0xffffe
    80003d5c:	c54080e7          	jalr	-940(ra) # 800019ac <myproc>
    80003d60:	15053503          	ld	a0,336(a0)
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	9f4080e7          	jalr	-1548(ra) # 80003758 <idup>
    80003d6c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d6e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d72:	4cb5                	li	s9,13
  len = path - s;
    80003d74:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d76:	4c05                	li	s8,1
    80003d78:	a87d                	j	80003e36 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d7a:	4585                	li	a1,1
    80003d7c:	4505                	li	a0,1
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	6de080e7          	jalr	1758(ra) # 8000345c <iget>
    80003d86:	8a2a                	mv	s4,a0
    80003d88:	b7dd                	j	80003d6e <namex+0x44>
      iunlockput(ip);
    80003d8a:	8552                	mv	a0,s4
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	c6c080e7          	jalr	-916(ra) # 800039f8 <iunlockput>
      return 0;
    80003d94:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d96:	8552                	mv	a0,s4
    80003d98:	60e6                	ld	ra,88(sp)
    80003d9a:	6446                	ld	s0,80(sp)
    80003d9c:	64a6                	ld	s1,72(sp)
    80003d9e:	6906                	ld	s2,64(sp)
    80003da0:	79e2                	ld	s3,56(sp)
    80003da2:	7a42                	ld	s4,48(sp)
    80003da4:	7aa2                	ld	s5,40(sp)
    80003da6:	7b02                	ld	s6,32(sp)
    80003da8:	6be2                	ld	s7,24(sp)
    80003daa:	6c42                	ld	s8,16(sp)
    80003dac:	6ca2                	ld	s9,8(sp)
    80003dae:	6d02                	ld	s10,0(sp)
    80003db0:	6125                	addi	sp,sp,96
    80003db2:	8082                	ret
      iunlock(ip);
    80003db4:	8552                	mv	a0,s4
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	aa2080e7          	jalr	-1374(ra) # 80003858 <iunlock>
      return ip;
    80003dbe:	bfe1                	j	80003d96 <namex+0x6c>
      iunlockput(ip);
    80003dc0:	8552                	mv	a0,s4
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c36080e7          	jalr	-970(ra) # 800039f8 <iunlockput>
      return 0;
    80003dca:	8a4e                	mv	s4,s3
    80003dcc:	b7e9                	j	80003d96 <namex+0x6c>
  len = path - s;
    80003dce:	40998633          	sub	a2,s3,s1
    80003dd2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dd6:	09acd863          	bge	s9,s10,80003e66 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dda:	4639                	li	a2,14
    80003ddc:	85a6                	mv	a1,s1
    80003dde:	8556                	mv	a0,s5
    80003de0:	ffffd097          	auipc	ra,0xffffd
    80003de4:	f4e080e7          	jalr	-178(ra) # 80000d2e <memmove>
    80003de8:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	01279763          	bne	a5,s2,80003dfc <namex+0xd2>
    path++;
    80003df2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df4:	0004c783          	lbu	a5,0(s1)
    80003df8:	ff278de3          	beq	a5,s2,80003df2 <namex+0xc8>
    ilock(ip);
    80003dfc:	8552                	mv	a0,s4
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	998080e7          	jalr	-1640(ra) # 80003796 <ilock>
    if(ip->type != T_DIR){
    80003e06:	044a1783          	lh	a5,68(s4)
    80003e0a:	f98790e3          	bne	a5,s8,80003d8a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e0e:	000b0563          	beqz	s6,80003e18 <namex+0xee>
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	dfd9                	beqz	a5,80003db4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e18:	865e                	mv	a2,s7
    80003e1a:	85d6                	mv	a1,s5
    80003e1c:	8552                	mv	a0,s4
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	e5c080e7          	jalr	-420(ra) # 80003c7a <dirlookup>
    80003e26:	89aa                	mv	s3,a0
    80003e28:	dd41                	beqz	a0,80003dc0 <namex+0x96>
    iunlockput(ip);
    80003e2a:	8552                	mv	a0,s4
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	bcc080e7          	jalr	-1076(ra) # 800039f8 <iunlockput>
    ip = next;
    80003e34:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	01279763          	bne	a5,s2,80003e48 <namex+0x11e>
    path++;
    80003e3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	ff278de3          	beq	a5,s2,80003e3e <namex+0x114>
  if(*path == 0)
    80003e48:	cb9d                	beqz	a5,80003e7e <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	89a6                	mv	s3,s1
  len = path - s;
    80003e50:	8d5e                	mv	s10,s7
    80003e52:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e54:	01278963          	beq	a5,s2,80003e66 <namex+0x13c>
    80003e58:	dbbd                	beqz	a5,80003dce <namex+0xa4>
    path++;
    80003e5a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e5c:	0009c783          	lbu	a5,0(s3)
    80003e60:	ff279ce3          	bne	a5,s2,80003e58 <namex+0x12e>
    80003e64:	b7ad                	j	80003dce <namex+0xa4>
    memmove(name, s, len);
    80003e66:	2601                	sext.w	a2,a2
    80003e68:	85a6                	mv	a1,s1
    80003e6a:	8556                	mv	a0,s5
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	ec2080e7          	jalr	-318(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e74:	9d56                	add	s10,s10,s5
    80003e76:	000d0023          	sb	zero,0(s10)
    80003e7a:	84ce                	mv	s1,s3
    80003e7c:	b7bd                	j	80003dea <namex+0xc0>
  if(nameiparent){
    80003e7e:	f00b0ce3          	beqz	s6,80003d96 <namex+0x6c>
    iput(ip);
    80003e82:	8552                	mv	a0,s4
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	acc080e7          	jalr	-1332(ra) # 80003950 <iput>
    return 0;
    80003e8c:	4a01                	li	s4,0
    80003e8e:	b721                	j	80003d96 <namex+0x6c>

0000000080003e90 <dirlink>:
{
    80003e90:	7139                	addi	sp,sp,-64
    80003e92:	fc06                	sd	ra,56(sp)
    80003e94:	f822                	sd	s0,48(sp)
    80003e96:	f426                	sd	s1,40(sp)
    80003e98:	f04a                	sd	s2,32(sp)
    80003e9a:	ec4e                	sd	s3,24(sp)
    80003e9c:	e852                	sd	s4,16(sp)
    80003e9e:	0080                	addi	s0,sp,64
    80003ea0:	892a                	mv	s2,a0
    80003ea2:	8a2e                	mv	s4,a1
    80003ea4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea6:	4601                	li	a2,0
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	dd2080e7          	jalr	-558(ra) # 80003c7a <dirlookup>
    80003eb0:	e93d                	bnez	a0,80003f26 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb2:	04c92483          	lw	s1,76(s2)
    80003eb6:	c49d                	beqz	s1,80003ee4 <dirlink+0x54>
    80003eb8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eba:	4741                	li	a4,16
    80003ebc:	86a6                	mv	a3,s1
    80003ebe:	fc040613          	addi	a2,s0,-64
    80003ec2:	4581                	li	a1,0
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	b84080e7          	jalr	-1148(ra) # 80003a4a <readi>
    80003ece:	47c1                	li	a5,16
    80003ed0:	06f51163          	bne	a0,a5,80003f32 <dirlink+0xa2>
    if(de.inum == 0)
    80003ed4:	fc045783          	lhu	a5,-64(s0)
    80003ed8:	c791                	beqz	a5,80003ee4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eda:	24c1                	addiw	s1,s1,16
    80003edc:	04c92783          	lw	a5,76(s2)
    80003ee0:	fcf4ede3          	bltu	s1,a5,80003eba <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee4:	4639                	li	a2,14
    80003ee6:	85d2                	mv	a1,s4
    80003ee8:	fc240513          	addi	a0,s0,-62
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	ef2080e7          	jalr	-270(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003ef4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef8:	4741                	li	a4,16
    80003efa:	86a6                	mv	a3,s1
    80003efc:	fc040613          	addi	a2,s0,-64
    80003f00:	4581                	li	a1,0
    80003f02:	854a                	mv	a0,s2
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	c3e080e7          	jalr	-962(ra) # 80003b42 <writei>
    80003f0c:	1541                	addi	a0,a0,-16
    80003f0e:	00a03533          	snez	a0,a0
    80003f12:	40a00533          	neg	a0,a0
}
    80003f16:	70e2                	ld	ra,56(sp)
    80003f18:	7442                	ld	s0,48(sp)
    80003f1a:	74a2                	ld	s1,40(sp)
    80003f1c:	7902                	ld	s2,32(sp)
    80003f1e:	69e2                	ld	s3,24(sp)
    80003f20:	6a42                	ld	s4,16(sp)
    80003f22:	6121                	addi	sp,sp,64
    80003f24:	8082                	ret
    iput(ip);
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	a2a080e7          	jalr	-1494(ra) # 80003950 <iput>
    return -1;
    80003f2e:	557d                	li	a0,-1
    80003f30:	b7dd                	j	80003f16 <dirlink+0x86>
      panic("dirlink read");
    80003f32:	00004517          	auipc	a0,0x4
    80003f36:	7de50513          	addi	a0,a0,2014 # 80008710 <syscalls+0x1d8>
    80003f3a:	ffffc097          	auipc	ra,0xffffc
    80003f3e:	606080e7          	jalr	1542(ra) # 80000540 <panic>

0000000080003f42 <namei>:

struct inode*
namei(char *path)
{
    80003f42:	1101                	addi	sp,sp,-32
    80003f44:	ec06                	sd	ra,24(sp)
    80003f46:	e822                	sd	s0,16(sp)
    80003f48:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f4a:	fe040613          	addi	a2,s0,-32
    80003f4e:	4581                	li	a1,0
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	dda080e7          	jalr	-550(ra) # 80003d2a <namex>
}
    80003f58:	60e2                	ld	ra,24(sp)
    80003f5a:	6442                	ld	s0,16(sp)
    80003f5c:	6105                	addi	sp,sp,32
    80003f5e:	8082                	ret

0000000080003f60 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f60:	1141                	addi	sp,sp,-16
    80003f62:	e406                	sd	ra,8(sp)
    80003f64:	e022                	sd	s0,0(sp)
    80003f66:	0800                	addi	s0,sp,16
    80003f68:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f6a:	4585                	li	a1,1
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	dbe080e7          	jalr	-578(ra) # 80003d2a <namex>
}
    80003f74:	60a2                	ld	ra,8(sp)
    80003f76:	6402                	ld	s0,0(sp)
    80003f78:	0141                	addi	sp,sp,16
    80003f7a:	8082                	ret

0000000080003f7c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	e04a                	sd	s2,0(sp)
    80003f86:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f88:	0001d917          	auipc	s2,0x1d
    80003f8c:	c9890913          	addi	s2,s2,-872 # 80020c20 <log>
    80003f90:	01892583          	lw	a1,24(s2)
    80003f94:	02892503          	lw	a0,40(s2)
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	fe6080e7          	jalr	-26(ra) # 80002f7e <bread>
    80003fa0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fa2:	02c92683          	lw	a3,44(s2)
    80003fa6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa8:	02d05863          	blez	a3,80003fd8 <write_head+0x5c>
    80003fac:	0001d797          	auipc	a5,0x1d
    80003fb0:	ca478793          	addi	a5,a5,-860 # 80020c50 <log+0x30>
    80003fb4:	05c50713          	addi	a4,a0,92
    80003fb8:	36fd                	addiw	a3,a3,-1
    80003fba:	02069613          	slli	a2,a3,0x20
    80003fbe:	01e65693          	srli	a3,a2,0x1e
    80003fc2:	0001d617          	auipc	a2,0x1d
    80003fc6:	c9260613          	addi	a2,a2,-878 # 80020c54 <log+0x34>
    80003fca:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fcc:	4390                	lw	a2,0(a5)
    80003fce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fd0:	0791                	addi	a5,a5,4
    80003fd2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fd4:	fed79ce3          	bne	a5,a3,80003fcc <write_head+0x50>
  }
  bwrite(buf);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	096080e7          	jalr	150(ra) # 80003070 <bwrite>
  brelse(buf);
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	0ca080e7          	jalr	202(ra) # 800030ae <brelse>
}
    80003fec:	60e2                	ld	ra,24(sp)
    80003fee:	6442                	ld	s0,16(sp)
    80003ff0:	64a2                	ld	s1,8(sp)
    80003ff2:	6902                	ld	s2,0(sp)
    80003ff4:	6105                	addi	sp,sp,32
    80003ff6:	8082                	ret

0000000080003ff8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff8:	0001d797          	auipc	a5,0x1d
    80003ffc:	c547a783          	lw	a5,-940(a5) # 80020c4c <log+0x2c>
    80004000:	0af05d63          	blez	a5,800040ba <install_trans+0xc2>
{
    80004004:	7139                	addi	sp,sp,-64
    80004006:	fc06                	sd	ra,56(sp)
    80004008:	f822                	sd	s0,48(sp)
    8000400a:	f426                	sd	s1,40(sp)
    8000400c:	f04a                	sd	s2,32(sp)
    8000400e:	ec4e                	sd	s3,24(sp)
    80004010:	e852                	sd	s4,16(sp)
    80004012:	e456                	sd	s5,8(sp)
    80004014:	e05a                	sd	s6,0(sp)
    80004016:	0080                	addi	s0,sp,64
    80004018:	8b2a                	mv	s6,a0
    8000401a:	0001da97          	auipc	s5,0x1d
    8000401e:	c36a8a93          	addi	s5,s5,-970 # 80020c50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004022:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004024:	0001d997          	auipc	s3,0x1d
    80004028:	bfc98993          	addi	s3,s3,-1028 # 80020c20 <log>
    8000402c:	a00d                	j	8000404e <install_trans+0x56>
    brelse(lbuf);
    8000402e:	854a                	mv	a0,s2
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	07e080e7          	jalr	126(ra) # 800030ae <brelse>
    brelse(dbuf);
    80004038:	8526                	mv	a0,s1
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	074080e7          	jalr	116(ra) # 800030ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004042:	2a05                	addiw	s4,s4,1
    80004044:	0a91                	addi	s5,s5,4
    80004046:	02c9a783          	lw	a5,44(s3)
    8000404a:	04fa5e63          	bge	s4,a5,800040a6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404e:	0189a583          	lw	a1,24(s3)
    80004052:	014585bb          	addw	a1,a1,s4
    80004056:	2585                	addiw	a1,a1,1
    80004058:	0289a503          	lw	a0,40(s3)
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	f22080e7          	jalr	-222(ra) # 80002f7e <bread>
    80004064:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004066:	000aa583          	lw	a1,0(s5)
    8000406a:	0289a503          	lw	a0,40(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	f10080e7          	jalr	-240(ra) # 80002f7e <bread>
    80004076:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004078:	40000613          	li	a2,1024
    8000407c:	05890593          	addi	a1,s2,88
    80004080:	05850513          	addi	a0,a0,88
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	caa080e7          	jalr	-854(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000408c:	8526                	mv	a0,s1
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	fe2080e7          	jalr	-30(ra) # 80003070 <bwrite>
    if(recovering == 0)
    80004096:	f80b1ce3          	bnez	s6,8000402e <install_trans+0x36>
      bunpin(dbuf);
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	0ec080e7          	jalr	236(ra) # 80003188 <bunpin>
    800040a4:	b769                	j	8000402e <install_trans+0x36>
}
    800040a6:	70e2                	ld	ra,56(sp)
    800040a8:	7442                	ld	s0,48(sp)
    800040aa:	74a2                	ld	s1,40(sp)
    800040ac:	7902                	ld	s2,32(sp)
    800040ae:	69e2                	ld	s3,24(sp)
    800040b0:	6a42                	ld	s4,16(sp)
    800040b2:	6aa2                	ld	s5,8(sp)
    800040b4:	6b02                	ld	s6,0(sp)
    800040b6:	6121                	addi	sp,sp,64
    800040b8:	8082                	ret
    800040ba:	8082                	ret

00000000800040bc <initlog>:
{
    800040bc:	7179                	addi	sp,sp,-48
    800040be:	f406                	sd	ra,40(sp)
    800040c0:	f022                	sd	s0,32(sp)
    800040c2:	ec26                	sd	s1,24(sp)
    800040c4:	e84a                	sd	s2,16(sp)
    800040c6:	e44e                	sd	s3,8(sp)
    800040c8:	1800                	addi	s0,sp,48
    800040ca:	892a                	mv	s2,a0
    800040cc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	b5248493          	addi	s1,s1,-1198 # 80020c20 <log>
    800040d6:	00004597          	auipc	a1,0x4
    800040da:	64a58593          	addi	a1,a1,1610 # 80008720 <syscalls+0x1e8>
    800040de:	8526                	mv	a0,s1
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	a66080e7          	jalr	-1434(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040e8:	0149a583          	lw	a1,20(s3)
    800040ec:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040ee:	0109a783          	lw	a5,16(s3)
    800040f2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040f8:	854a                	mv	a0,s2
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	e84080e7          	jalr	-380(ra) # 80002f7e <bread>
  log.lh.n = lh->n;
    80004102:	4d34                	lw	a3,88(a0)
    80004104:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004106:	02d05663          	blez	a3,80004132 <initlog+0x76>
    8000410a:	05c50793          	addi	a5,a0,92
    8000410e:	0001d717          	auipc	a4,0x1d
    80004112:	b4270713          	addi	a4,a4,-1214 # 80020c50 <log+0x30>
    80004116:	36fd                	addiw	a3,a3,-1
    80004118:	02069613          	slli	a2,a3,0x20
    8000411c:	01e65693          	srli	a3,a2,0x1e
    80004120:	06050613          	addi	a2,a0,96
    80004124:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004126:	4390                	lw	a2,0(a5)
    80004128:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000412a:	0791                	addi	a5,a5,4
    8000412c:	0711                	addi	a4,a4,4
    8000412e:	fed79ce3          	bne	a5,a3,80004126 <initlog+0x6a>
  brelse(buf);
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	f7c080e7          	jalr	-132(ra) # 800030ae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000413a:	4505                	li	a0,1
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	ebc080e7          	jalr	-324(ra) # 80003ff8 <install_trans>
  log.lh.n = 0;
    80004144:	0001d797          	auipc	a5,0x1d
    80004148:	b007a423          	sw	zero,-1272(a5) # 80020c4c <log+0x2c>
  write_head(); // clear the log
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	e30080e7          	jalr	-464(ra) # 80003f7c <write_head>
}
    80004154:	70a2                	ld	ra,40(sp)
    80004156:	7402                	ld	s0,32(sp)
    80004158:	64e2                	ld	s1,24(sp)
    8000415a:	6942                	ld	s2,16(sp)
    8000415c:	69a2                	ld	s3,8(sp)
    8000415e:	6145                	addi	sp,sp,48
    80004160:	8082                	ret

0000000080004162 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004162:	1101                	addi	sp,sp,-32
    80004164:	ec06                	sd	ra,24(sp)
    80004166:	e822                	sd	s0,16(sp)
    80004168:	e426                	sd	s1,8(sp)
    8000416a:	e04a                	sd	s2,0(sp)
    8000416c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000416e:	0001d517          	auipc	a0,0x1d
    80004172:	ab250513          	addi	a0,a0,-1358 # 80020c20 <log>
    80004176:	ffffd097          	auipc	ra,0xffffd
    8000417a:	a60080e7          	jalr	-1440(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000417e:	0001d497          	auipc	s1,0x1d
    80004182:	aa248493          	addi	s1,s1,-1374 # 80020c20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004186:	4979                	li	s2,30
    80004188:	a039                	j	80004196 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000418a:	85a6                	mv	a1,s1
    8000418c:	8526                	mv	a0,s1
    8000418e:	ffffe097          	auipc	ra,0xffffe
    80004192:	ec6080e7          	jalr	-314(ra) # 80002054 <sleep>
    if(log.committing){
    80004196:	50dc                	lw	a5,36(s1)
    80004198:	fbed                	bnez	a5,8000418a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419a:	5098                	lw	a4,32(s1)
    8000419c:	2705                	addiw	a4,a4,1
    8000419e:	0007069b          	sext.w	a3,a4
    800041a2:	0027179b          	slliw	a5,a4,0x2
    800041a6:	9fb9                	addw	a5,a5,a4
    800041a8:	0017979b          	slliw	a5,a5,0x1
    800041ac:	54d8                	lw	a4,44(s1)
    800041ae:	9fb9                	addw	a5,a5,a4
    800041b0:	00f95963          	bge	s2,a5,800041c2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041b4:	85a6                	mv	a1,s1
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffe097          	auipc	ra,0xffffe
    800041bc:	e9c080e7          	jalr	-356(ra) # 80002054 <sleep>
    800041c0:	bfd9                	j	80004196 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041c2:	0001d517          	auipc	a0,0x1d
    800041c6:	a5e50513          	addi	a0,a0,-1442 # 80020c20 <log>
    800041ca:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	abe080e7          	jalr	-1346(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041d4:	60e2                	ld	ra,24(sp)
    800041d6:	6442                	ld	s0,16(sp)
    800041d8:	64a2                	ld	s1,8(sp)
    800041da:	6902                	ld	s2,0(sp)
    800041dc:	6105                	addi	sp,sp,32
    800041de:	8082                	ret

00000000800041e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041e0:	7139                	addi	sp,sp,-64
    800041e2:	fc06                	sd	ra,56(sp)
    800041e4:	f822                	sd	s0,48(sp)
    800041e6:	f426                	sd	s1,40(sp)
    800041e8:	f04a                	sd	s2,32(sp)
    800041ea:	ec4e                	sd	s3,24(sp)
    800041ec:	e852                	sd	s4,16(sp)
    800041ee:	e456                	sd	s5,8(sp)
    800041f0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041f2:	0001d497          	auipc	s1,0x1d
    800041f6:	a2e48493          	addi	s1,s1,-1490 # 80020c20 <log>
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	9da080e7          	jalr	-1574(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004204:	509c                	lw	a5,32(s1)
    80004206:	37fd                	addiw	a5,a5,-1
    80004208:	0007891b          	sext.w	s2,a5
    8000420c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000420e:	50dc                	lw	a5,36(s1)
    80004210:	e7b9                	bnez	a5,8000425e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004212:	04091e63          	bnez	s2,8000426e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004216:	0001d497          	auipc	s1,0x1d
    8000421a:	a0a48493          	addi	s1,s1,-1526 # 80020c20 <log>
    8000421e:	4785                	li	a5,1
    80004220:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	a66080e7          	jalr	-1434(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000422c:	54dc                	lw	a5,44(s1)
    8000422e:	06f04763          	bgtz	a5,8000429c <end_op+0xbc>
    acquire(&log.lock);
    80004232:	0001d497          	auipc	s1,0x1d
    80004236:	9ee48493          	addi	s1,s1,-1554 # 80020c20 <log>
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	99a080e7          	jalr	-1638(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004244:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffe097          	auipc	ra,0xffffe
    8000424e:	e6e080e7          	jalr	-402(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a36080e7          	jalr	-1482(ra) # 80000c8a <release>
}
    8000425c:	a03d                	j	8000428a <end_op+0xaa>
    panic("log.committing");
    8000425e:	00004517          	auipc	a0,0x4
    80004262:	4ca50513          	addi	a0,a0,1226 # 80008728 <syscalls+0x1f0>
    80004266:	ffffc097          	auipc	ra,0xffffc
    8000426a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
    wakeup(&log);
    8000426e:	0001d497          	auipc	s1,0x1d
    80004272:	9b248493          	addi	s1,s1,-1614 # 80020c20 <log>
    80004276:	8526                	mv	a0,s1
    80004278:	ffffe097          	auipc	ra,0xffffe
    8000427c:	e40080e7          	jalr	-448(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
}
    8000428a:	70e2                	ld	ra,56(sp)
    8000428c:	7442                	ld	s0,48(sp)
    8000428e:	74a2                	ld	s1,40(sp)
    80004290:	7902                	ld	s2,32(sp)
    80004292:	69e2                	ld	s3,24(sp)
    80004294:	6a42                	ld	s4,16(sp)
    80004296:	6aa2                	ld	s5,8(sp)
    80004298:	6121                	addi	sp,sp,64
    8000429a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	0001da97          	auipc	s5,0x1d
    800042a0:	9b4a8a93          	addi	s5,s5,-1612 # 80020c50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042a4:	0001da17          	auipc	s4,0x1d
    800042a8:	97ca0a13          	addi	s4,s4,-1668 # 80020c20 <log>
    800042ac:	018a2583          	lw	a1,24(s4)
    800042b0:	012585bb          	addw	a1,a1,s2
    800042b4:	2585                	addiw	a1,a1,1
    800042b6:	028a2503          	lw	a0,40(s4)
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	cc4080e7          	jalr	-828(ra) # 80002f7e <bread>
    800042c2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042c4:	000aa583          	lw	a1,0(s5)
    800042c8:	028a2503          	lw	a0,40(s4)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	cb2080e7          	jalr	-846(ra) # 80002f7e <bread>
    800042d4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042d6:	40000613          	li	a2,1024
    800042da:	05850593          	addi	a1,a0,88
    800042de:	05848513          	addi	a0,s1,88
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	a4c080e7          	jalr	-1460(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800042ea:	8526                	mv	a0,s1
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	d84080e7          	jalr	-636(ra) # 80003070 <bwrite>
    brelse(from);
    800042f4:	854e                	mv	a0,s3
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	db8080e7          	jalr	-584(ra) # 800030ae <brelse>
    brelse(to);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	dae080e7          	jalr	-594(ra) # 800030ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004308:	2905                	addiw	s2,s2,1
    8000430a:	0a91                	addi	s5,s5,4
    8000430c:	02ca2783          	lw	a5,44(s4)
    80004310:	f8f94ee3          	blt	s2,a5,800042ac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c68080e7          	jalr	-920(ra) # 80003f7c <write_head>
    install_trans(0); // Now install writes to home locations
    8000431c:	4501                	li	a0,0
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	cda080e7          	jalr	-806(ra) # 80003ff8 <install_trans>
    log.lh.n = 0;
    80004326:	0001d797          	auipc	a5,0x1d
    8000432a:	9207a323          	sw	zero,-1754(a5) # 80020c4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	c4e080e7          	jalr	-946(ra) # 80003f7c <write_head>
    80004336:	bdf5                	j	80004232 <end_op+0x52>

0000000080004338 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004338:	1101                	addi	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	e426                	sd	s1,8(sp)
    80004340:	e04a                	sd	s2,0(sp)
    80004342:	1000                	addi	s0,sp,32
    80004344:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004346:	0001d917          	auipc	s2,0x1d
    8000434a:	8da90913          	addi	s2,s2,-1830 # 80020c20 <log>
    8000434e:	854a                	mv	a0,s2
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	886080e7          	jalr	-1914(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004358:	02c92603          	lw	a2,44(s2)
    8000435c:	47f5                	li	a5,29
    8000435e:	06c7c563          	blt	a5,a2,800043c8 <log_write+0x90>
    80004362:	0001d797          	auipc	a5,0x1d
    80004366:	8da7a783          	lw	a5,-1830(a5) # 80020c3c <log+0x1c>
    8000436a:	37fd                	addiw	a5,a5,-1
    8000436c:	04f65e63          	bge	a2,a5,800043c8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004370:	0001d797          	auipc	a5,0x1d
    80004374:	8d07a783          	lw	a5,-1840(a5) # 80020c40 <log+0x20>
    80004378:	06f05063          	blez	a5,800043d8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000437c:	4781                	li	a5,0
    8000437e:	06c05563          	blez	a2,800043e8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004382:	44cc                	lw	a1,12(s1)
    80004384:	0001d717          	auipc	a4,0x1d
    80004388:	8cc70713          	addi	a4,a4,-1844 # 80020c50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000438c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438e:	4314                	lw	a3,0(a4)
    80004390:	04b68c63          	beq	a3,a1,800043e8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004394:	2785                	addiw	a5,a5,1
    80004396:	0711                	addi	a4,a4,4
    80004398:	fef61be3          	bne	a2,a5,8000438e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000439c:	0621                	addi	a2,a2,8
    8000439e:	060a                	slli	a2,a2,0x2
    800043a0:	0001d797          	auipc	a5,0x1d
    800043a4:	88078793          	addi	a5,a5,-1920 # 80020c20 <log>
    800043a8:	97b2                	add	a5,a5,a2
    800043aa:	44d8                	lw	a4,12(s1)
    800043ac:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ae:	8526                	mv	a0,s1
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	d9c080e7          	jalr	-612(ra) # 8000314c <bpin>
    log.lh.n++;
    800043b8:	0001d717          	auipc	a4,0x1d
    800043bc:	86870713          	addi	a4,a4,-1944 # 80020c20 <log>
    800043c0:	575c                	lw	a5,44(a4)
    800043c2:	2785                	addiw	a5,a5,1
    800043c4:	d75c                	sw	a5,44(a4)
    800043c6:	a82d                	j	80004400 <log_write+0xc8>
    panic("too big a transaction");
    800043c8:	00004517          	auipc	a0,0x4
    800043cc:	37050513          	addi	a0,a0,880 # 80008738 <syscalls+0x200>
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	170080e7          	jalr	368(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043d8:	00004517          	auipc	a0,0x4
    800043dc:	37850513          	addi	a0,a0,888 # 80008750 <syscalls+0x218>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	160080e7          	jalr	352(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043e8:	00878693          	addi	a3,a5,8
    800043ec:	068a                	slli	a3,a3,0x2
    800043ee:	0001d717          	auipc	a4,0x1d
    800043f2:	83270713          	addi	a4,a4,-1998 # 80020c20 <log>
    800043f6:	9736                	add	a4,a4,a3
    800043f8:	44d4                	lw	a3,12(s1)
    800043fa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043fc:	faf609e3          	beq	a2,a5,800043ae <log_write+0x76>
  }
  release(&log.lock);
    80004400:	0001d517          	auipc	a0,0x1d
    80004404:	82050513          	addi	a0,a0,-2016 # 80020c20 <log>
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret

000000008000441c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000441c:	1101                	addi	sp,sp,-32
    8000441e:	ec06                	sd	ra,24(sp)
    80004420:	e822                	sd	s0,16(sp)
    80004422:	e426                	sd	s1,8(sp)
    80004424:	e04a                	sd	s2,0(sp)
    80004426:	1000                	addi	s0,sp,32
    80004428:	84aa                	mv	s1,a0
    8000442a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000442c:	00004597          	auipc	a1,0x4
    80004430:	34458593          	addi	a1,a1,836 # 80008770 <syscalls+0x238>
    80004434:	0521                	addi	a0,a0,8
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	710080e7          	jalr	1808(ra) # 80000b46 <initlock>
  lk->name = name;
    8000443e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004442:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004446:	0204a423          	sw	zero,40(s1)
}
    8000444a:	60e2                	ld	ra,24(sp)
    8000444c:	6442                	ld	s0,16(sp)
    8000444e:	64a2                	ld	s1,8(sp)
    80004450:	6902                	ld	s2,0(sp)
    80004452:	6105                	addi	sp,sp,32
    80004454:	8082                	ret

0000000080004456 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004456:	1101                	addi	sp,sp,-32
    80004458:	ec06                	sd	ra,24(sp)
    8000445a:	e822                	sd	s0,16(sp)
    8000445c:	e426                	sd	s1,8(sp)
    8000445e:	e04a                	sd	s2,0(sp)
    80004460:	1000                	addi	s0,sp,32
    80004462:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004464:	00850913          	addi	s2,a0,8
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	76c080e7          	jalr	1900(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004472:	409c                	lw	a5,0(s1)
    80004474:	cb89                	beqz	a5,80004486 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004476:	85ca                	mv	a1,s2
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffe097          	auipc	ra,0xffffe
    8000447e:	bda080e7          	jalr	-1062(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004482:	409c                	lw	a5,0(s1)
    80004484:	fbed                	bnez	a5,80004476 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004486:	4785                	li	a5,1
    80004488:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	522080e7          	jalr	1314(ra) # 800019ac <myproc>
    80004492:	591c                	lw	a5,48(a0)
    80004494:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004496:	854a                	mv	a0,s2
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	7f2080e7          	jalr	2034(ra) # 80000c8a <release>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret

00000000800044ac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ac:	1101                	addi	sp,sp,-32
    800044ae:	ec06                	sd	ra,24(sp)
    800044b0:	e822                	sd	s0,16(sp)
    800044b2:	e426                	sd	s1,8(sp)
    800044b4:	e04a                	sd	s2,0(sp)
    800044b6:	1000                	addi	s0,sp,32
    800044b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ba:	00850913          	addi	s2,a0,8
    800044be:	854a                	mv	a0,s2
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	716080e7          	jalr	1814(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044cc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffe097          	auipc	ra,0xffffe
    800044d6:	be6080e7          	jalr	-1050(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800044da:	854a                	mv	a0,s2
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7ae080e7          	jalr	1966(ra) # 80000c8a <release>
}
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6902                	ld	s2,0(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret

00000000800044f0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044f0:	7179                	addi	sp,sp,-48
    800044f2:	f406                	sd	ra,40(sp)
    800044f4:	f022                	sd	s0,32(sp)
    800044f6:	ec26                	sd	s1,24(sp)
    800044f8:	e84a                	sd	s2,16(sp)
    800044fa:	e44e                	sd	s3,8(sp)
    800044fc:	1800                	addi	s0,sp,48
    800044fe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004500:	00850913          	addi	s2,a0,8
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	6d0080e7          	jalr	1744(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450e:	409c                	lw	a5,0(s1)
    80004510:	ef99                	bnez	a5,8000452e <holdingsleep+0x3e>
    80004512:	4481                	li	s1,0
  release(&lk->lk);
    80004514:	854a                	mv	a0,s2
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	774080e7          	jalr	1908(ra) # 80000c8a <release>
  return r;
}
    8000451e:	8526                	mv	a0,s1
    80004520:	70a2                	ld	ra,40(sp)
    80004522:	7402                	ld	s0,32(sp)
    80004524:	64e2                	ld	s1,24(sp)
    80004526:	6942                	ld	s2,16(sp)
    80004528:	69a2                	ld	s3,8(sp)
    8000452a:	6145                	addi	sp,sp,48
    8000452c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452e:	0284a983          	lw	s3,40(s1)
    80004532:	ffffd097          	auipc	ra,0xffffd
    80004536:	47a080e7          	jalr	1146(ra) # 800019ac <myproc>
    8000453a:	5904                	lw	s1,48(a0)
    8000453c:	413484b3          	sub	s1,s1,s3
    80004540:	0014b493          	seqz	s1,s1
    80004544:	bfc1                	j	80004514 <holdingsleep+0x24>

0000000080004546 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004546:	1141                	addi	sp,sp,-16
    80004548:	e406                	sd	ra,8(sp)
    8000454a:	e022                	sd	s0,0(sp)
    8000454c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000454e:	00004597          	auipc	a1,0x4
    80004552:	23258593          	addi	a1,a1,562 # 80008780 <syscalls+0x248>
    80004556:	0001d517          	auipc	a0,0x1d
    8000455a:	81250513          	addi	a0,a0,-2030 # 80020d68 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	5e8080e7          	jalr	1512(ra) # 80000b46 <initlock>
}
    80004566:	60a2                	ld	ra,8(sp)
    80004568:	6402                	ld	s0,0(sp)
    8000456a:	0141                	addi	sp,sp,16
    8000456c:	8082                	ret

000000008000456e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004578:	0001c517          	auipc	a0,0x1c
    8000457c:	7f050513          	addi	a0,a0,2032 # 80020d68 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	656080e7          	jalr	1622(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004588:	0001c497          	auipc	s1,0x1c
    8000458c:	7f848493          	addi	s1,s1,2040 # 80020d80 <ftable+0x18>
    80004590:	0001d717          	auipc	a4,0x1d
    80004594:	79070713          	addi	a4,a4,1936 # 80021d20 <disk>
    if(f->ref == 0){
    80004598:	40dc                	lw	a5,4(s1)
    8000459a:	cf99                	beqz	a5,800045b8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459c:	02848493          	addi	s1,s1,40
    800045a0:	fee49ce3          	bne	s1,a4,80004598 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045a4:	0001c517          	auipc	a0,0x1c
    800045a8:	7c450513          	addi	a0,a0,1988 # 80020d68 <ftable>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	6de080e7          	jalr	1758(ra) # 80000c8a <release>
  return 0;
    800045b4:	4481                	li	s1,0
    800045b6:	a819                	j	800045cc <filealloc+0x5e>
      f->ref = 1;
    800045b8:	4785                	li	a5,1
    800045ba:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045bc:	0001c517          	auipc	a0,0x1c
    800045c0:	7ac50513          	addi	a0,a0,1964 # 80020d68 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6c6080e7          	jalr	1734(ra) # 80000c8a <release>
}
    800045cc:	8526                	mv	a0,s1
    800045ce:	60e2                	ld	ra,24(sp)
    800045d0:	6442                	ld	s0,16(sp)
    800045d2:	64a2                	ld	s1,8(sp)
    800045d4:	6105                	addi	sp,sp,32
    800045d6:	8082                	ret

00000000800045d8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045d8:	1101                	addi	sp,sp,-32
    800045da:	ec06                	sd	ra,24(sp)
    800045dc:	e822                	sd	s0,16(sp)
    800045de:	e426                	sd	s1,8(sp)
    800045e0:	1000                	addi	s0,sp,32
    800045e2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045e4:	0001c517          	auipc	a0,0x1c
    800045e8:	78450513          	addi	a0,a0,1924 # 80020d68 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	5ea080e7          	jalr	1514(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045f4:	40dc                	lw	a5,4(s1)
    800045f6:	02f05263          	blez	a5,8000461a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045fa:	2785                	addiw	a5,a5,1
    800045fc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045fe:	0001c517          	auipc	a0,0x1c
    80004602:	76a50513          	addi	a0,a0,1898 # 80020d68 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	684080e7          	jalr	1668(ra) # 80000c8a <release>
  return f;
}
    8000460e:	8526                	mv	a0,s1
    80004610:	60e2                	ld	ra,24(sp)
    80004612:	6442                	ld	s0,16(sp)
    80004614:	64a2                	ld	s1,8(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret
    panic("filedup");
    8000461a:	00004517          	auipc	a0,0x4
    8000461e:	16e50513          	addi	a0,a0,366 # 80008788 <syscalls+0x250>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	f1e080e7          	jalr	-226(ra) # 80000540 <panic>

000000008000462a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000462a:	7139                	addi	sp,sp,-64
    8000462c:	fc06                	sd	ra,56(sp)
    8000462e:	f822                	sd	s0,48(sp)
    80004630:	f426                	sd	s1,40(sp)
    80004632:	f04a                	sd	s2,32(sp)
    80004634:	ec4e                	sd	s3,24(sp)
    80004636:	e852                	sd	s4,16(sp)
    80004638:	e456                	sd	s5,8(sp)
    8000463a:	0080                	addi	s0,sp,64
    8000463c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000463e:	0001c517          	auipc	a0,0x1c
    80004642:	72a50513          	addi	a0,a0,1834 # 80020d68 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	590080e7          	jalr	1424(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	06f05163          	blez	a5,800046b2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004654:	37fd                	addiw	a5,a5,-1
    80004656:	0007871b          	sext.w	a4,a5
    8000465a:	c0dc                	sw	a5,4(s1)
    8000465c:	06e04363          	bgtz	a4,800046c2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004660:	0004a903          	lw	s2,0(s1)
    80004664:	0094ca83          	lbu	s5,9(s1)
    80004668:	0104ba03          	ld	s4,16(s1)
    8000466c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004670:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004674:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004678:	0001c517          	auipc	a0,0x1c
    8000467c:	6f050513          	addi	a0,a0,1776 # 80020d68 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	60a080e7          	jalr	1546(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004688:	4785                	li	a5,1
    8000468a:	04f90d63          	beq	s2,a5,800046e4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000468e:	3979                	addiw	s2,s2,-2
    80004690:	4785                	li	a5,1
    80004692:	0527e063          	bltu	a5,s2,800046d2 <fileclose+0xa8>
    begin_op();
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	acc080e7          	jalr	-1332(ra) # 80004162 <begin_op>
    iput(ff.ip);
    8000469e:	854e                	mv	a0,s3
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	2b0080e7          	jalr	688(ra) # 80003950 <iput>
    end_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	b38080e7          	jalr	-1224(ra) # 800041e0 <end_op>
    800046b0:	a00d                	j	800046d2 <fileclose+0xa8>
    panic("fileclose");
    800046b2:	00004517          	auipc	a0,0x4
    800046b6:	0de50513          	addi	a0,a0,222 # 80008790 <syscalls+0x258>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	e86080e7          	jalr	-378(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046c2:	0001c517          	auipc	a0,0x1c
    800046c6:	6a650513          	addi	a0,a0,1702 # 80020d68 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5c0080e7          	jalr	1472(ra) # 80000c8a <release>
  }
}
    800046d2:	70e2                	ld	ra,56(sp)
    800046d4:	7442                	ld	s0,48(sp)
    800046d6:	74a2                	ld	s1,40(sp)
    800046d8:	7902                	ld	s2,32(sp)
    800046da:	69e2                	ld	s3,24(sp)
    800046dc:	6a42                	ld	s4,16(sp)
    800046de:	6aa2                	ld	s5,8(sp)
    800046e0:	6121                	addi	sp,sp,64
    800046e2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046e4:	85d6                	mv	a1,s5
    800046e6:	8552                	mv	a0,s4
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	34c080e7          	jalr	844(ra) # 80004a34 <pipeclose>
    800046f0:	b7cd                	j	800046d2 <fileclose+0xa8>

00000000800046f2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046f2:	715d                	addi	sp,sp,-80
    800046f4:	e486                	sd	ra,72(sp)
    800046f6:	e0a2                	sd	s0,64(sp)
    800046f8:	fc26                	sd	s1,56(sp)
    800046fa:	f84a                	sd	s2,48(sp)
    800046fc:	f44e                	sd	s3,40(sp)
    800046fe:	0880                	addi	s0,sp,80
    80004700:	84aa                	mv	s1,a0
    80004702:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	2a8080e7          	jalr	680(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000470c:	409c                	lw	a5,0(s1)
    8000470e:	37f9                	addiw	a5,a5,-2
    80004710:	4705                	li	a4,1
    80004712:	04f76763          	bltu	a4,a5,80004760 <filestat+0x6e>
    80004716:	892a                	mv	s2,a0
    ilock(f->ip);
    80004718:	6c88                	ld	a0,24(s1)
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	07c080e7          	jalr	124(ra) # 80003796 <ilock>
    stati(f->ip, &st);
    80004722:	fb840593          	addi	a1,s0,-72
    80004726:	6c88                	ld	a0,24(s1)
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	2f8080e7          	jalr	760(ra) # 80003a20 <stati>
    iunlock(f->ip);
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	126080e7          	jalr	294(ra) # 80003858 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000473a:	46e1                	li	a3,24
    8000473c:	fb840613          	addi	a2,s0,-72
    80004740:	85ce                	mv	a1,s3
    80004742:	05093503          	ld	a0,80(s2)
    80004746:	ffffd097          	auipc	ra,0xffffd
    8000474a:	f26080e7          	jalr	-218(ra) # 8000166c <copyout>
    8000474e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004752:	60a6                	ld	ra,72(sp)
    80004754:	6406                	ld	s0,64(sp)
    80004756:	74e2                	ld	s1,56(sp)
    80004758:	7942                	ld	s2,48(sp)
    8000475a:	79a2                	ld	s3,40(sp)
    8000475c:	6161                	addi	sp,sp,80
    8000475e:	8082                	ret
  return -1;
    80004760:	557d                	li	a0,-1
    80004762:	bfc5                	j	80004752 <filestat+0x60>

0000000080004764 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004764:	7179                	addi	sp,sp,-48
    80004766:	f406                	sd	ra,40(sp)
    80004768:	f022                	sd	s0,32(sp)
    8000476a:	ec26                	sd	s1,24(sp)
    8000476c:	e84a                	sd	s2,16(sp)
    8000476e:	e44e                	sd	s3,8(sp)
    80004770:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004772:	00854783          	lbu	a5,8(a0)
    80004776:	c3d5                	beqz	a5,8000481a <fileread+0xb6>
    80004778:	84aa                	mv	s1,a0
    8000477a:	89ae                	mv	s3,a1
    8000477c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477e:	411c                	lw	a5,0(a0)
    80004780:	4705                	li	a4,1
    80004782:	04e78963          	beq	a5,a4,800047d4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004786:	470d                	li	a4,3
    80004788:	04e78d63          	beq	a5,a4,800047e2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000478c:	4709                	li	a4,2
    8000478e:	06e79e63          	bne	a5,a4,8000480a <fileread+0xa6>
    ilock(f->ip);
    80004792:	6d08                	ld	a0,24(a0)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	002080e7          	jalr	2(ra) # 80003796 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000479c:	874a                	mv	a4,s2
    8000479e:	5094                	lw	a3,32(s1)
    800047a0:	864e                	mv	a2,s3
    800047a2:	4585                	li	a1,1
    800047a4:	6c88                	ld	a0,24(s1)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	2a4080e7          	jalr	676(ra) # 80003a4a <readi>
    800047ae:	892a                	mv	s2,a0
    800047b0:	00a05563          	blez	a0,800047ba <fileread+0x56>
      f->off += r;
    800047b4:	509c                	lw	a5,32(s1)
    800047b6:	9fa9                	addw	a5,a5,a0
    800047b8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	09c080e7          	jalr	156(ra) # 80003858 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047c4:	854a                	mv	a0,s2
    800047c6:	70a2                	ld	ra,40(sp)
    800047c8:	7402                	ld	s0,32(sp)
    800047ca:	64e2                	ld	s1,24(sp)
    800047cc:	6942                	ld	s2,16(sp)
    800047ce:	69a2                	ld	s3,8(sp)
    800047d0:	6145                	addi	sp,sp,48
    800047d2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047d4:	6908                	ld	a0,16(a0)
    800047d6:	00000097          	auipc	ra,0x0
    800047da:	3c6080e7          	jalr	966(ra) # 80004b9c <piperead>
    800047de:	892a                	mv	s2,a0
    800047e0:	b7d5                	j	800047c4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047e2:	02451783          	lh	a5,36(a0)
    800047e6:	03079693          	slli	a3,a5,0x30
    800047ea:	92c1                	srli	a3,a3,0x30
    800047ec:	4725                	li	a4,9
    800047ee:	02d76863          	bltu	a4,a3,8000481e <fileread+0xba>
    800047f2:	0792                	slli	a5,a5,0x4
    800047f4:	0001c717          	auipc	a4,0x1c
    800047f8:	4d470713          	addi	a4,a4,1236 # 80020cc8 <devsw>
    800047fc:	97ba                	add	a5,a5,a4
    800047fe:	639c                	ld	a5,0(a5)
    80004800:	c38d                	beqz	a5,80004822 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004802:	4505                	li	a0,1
    80004804:	9782                	jalr	a5
    80004806:	892a                	mv	s2,a0
    80004808:	bf75                	j	800047c4 <fileread+0x60>
    panic("fileread");
    8000480a:	00004517          	auipc	a0,0x4
    8000480e:	f9650513          	addi	a0,a0,-106 # 800087a0 <syscalls+0x268>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d2e080e7          	jalr	-722(ra) # 80000540 <panic>
    return -1;
    8000481a:	597d                	li	s2,-1
    8000481c:	b765                	j	800047c4 <fileread+0x60>
      return -1;
    8000481e:	597d                	li	s2,-1
    80004820:	b755                	j	800047c4 <fileread+0x60>
    80004822:	597d                	li	s2,-1
    80004824:	b745                	j	800047c4 <fileread+0x60>

0000000080004826 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004826:	715d                	addi	sp,sp,-80
    80004828:	e486                	sd	ra,72(sp)
    8000482a:	e0a2                	sd	s0,64(sp)
    8000482c:	fc26                	sd	s1,56(sp)
    8000482e:	f84a                	sd	s2,48(sp)
    80004830:	f44e                	sd	s3,40(sp)
    80004832:	f052                	sd	s4,32(sp)
    80004834:	ec56                	sd	s5,24(sp)
    80004836:	e85a                	sd	s6,16(sp)
    80004838:	e45e                	sd	s7,8(sp)
    8000483a:	e062                	sd	s8,0(sp)
    8000483c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000483e:	00954783          	lbu	a5,9(a0)
    80004842:	10078663          	beqz	a5,8000494e <filewrite+0x128>
    80004846:	892a                	mv	s2,a0
    80004848:	8b2e                	mv	s6,a1
    8000484a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484c:	411c                	lw	a5,0(a0)
    8000484e:	4705                	li	a4,1
    80004850:	02e78263          	beq	a5,a4,80004874 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004854:	470d                	li	a4,3
    80004856:	02e78663          	beq	a5,a4,80004882 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000485a:	4709                	li	a4,2
    8000485c:	0ee79163          	bne	a5,a4,8000493e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004860:	0ac05d63          	blez	a2,8000491a <filewrite+0xf4>
    int i = 0;
    80004864:	4981                	li	s3,0
    80004866:	6b85                	lui	s7,0x1
    80004868:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000486c:	6c05                	lui	s8,0x1
    8000486e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004872:	a861                	j	8000490a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004874:	6908                	ld	a0,16(a0)
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	22e080e7          	jalr	558(ra) # 80004aa4 <pipewrite>
    8000487e:	8a2a                	mv	s4,a0
    80004880:	a045                	j	80004920 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004882:	02451783          	lh	a5,36(a0)
    80004886:	03079693          	slli	a3,a5,0x30
    8000488a:	92c1                	srli	a3,a3,0x30
    8000488c:	4725                	li	a4,9
    8000488e:	0cd76263          	bltu	a4,a3,80004952 <filewrite+0x12c>
    80004892:	0792                	slli	a5,a5,0x4
    80004894:	0001c717          	auipc	a4,0x1c
    80004898:	43470713          	addi	a4,a4,1076 # 80020cc8 <devsw>
    8000489c:	97ba                	add	a5,a5,a4
    8000489e:	679c                	ld	a5,8(a5)
    800048a0:	cbdd                	beqz	a5,80004956 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048a2:	4505                	li	a0,1
    800048a4:	9782                	jalr	a5
    800048a6:	8a2a                	mv	s4,a0
    800048a8:	a8a5                	j	80004920 <filewrite+0xfa>
    800048aa:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	8b4080e7          	jalr	-1868(ra) # 80004162 <begin_op>
      ilock(f->ip);
    800048b6:	01893503          	ld	a0,24(s2)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	edc080e7          	jalr	-292(ra) # 80003796 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048c2:	8756                	mv	a4,s5
    800048c4:	02092683          	lw	a3,32(s2)
    800048c8:	01698633          	add	a2,s3,s6
    800048cc:	4585                	li	a1,1
    800048ce:	01893503          	ld	a0,24(s2)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	270080e7          	jalr	624(ra) # 80003b42 <writei>
    800048da:	84aa                	mv	s1,a0
    800048dc:	00a05763          	blez	a0,800048ea <filewrite+0xc4>
        f->off += r;
    800048e0:	02092783          	lw	a5,32(s2)
    800048e4:	9fa9                	addw	a5,a5,a0
    800048e6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048ea:	01893503          	ld	a0,24(s2)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	f6a080e7          	jalr	-150(ra) # 80003858 <iunlock>
      end_op();
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	8ea080e7          	jalr	-1814(ra) # 800041e0 <end_op>

      if(r != n1){
    800048fe:	009a9f63          	bne	s5,s1,8000491c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004902:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004906:	0149db63          	bge	s3,s4,8000491c <filewrite+0xf6>
      int n1 = n - i;
    8000490a:	413a04bb          	subw	s1,s4,s3
    8000490e:	0004879b          	sext.w	a5,s1
    80004912:	f8fbdce3          	bge	s7,a5,800048aa <filewrite+0x84>
    80004916:	84e2                	mv	s1,s8
    80004918:	bf49                	j	800048aa <filewrite+0x84>
    int i = 0;
    8000491a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000491c:	013a1f63          	bne	s4,s3,8000493a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004920:	8552                	mv	a0,s4
    80004922:	60a6                	ld	ra,72(sp)
    80004924:	6406                	ld	s0,64(sp)
    80004926:	74e2                	ld	s1,56(sp)
    80004928:	7942                	ld	s2,48(sp)
    8000492a:	79a2                	ld	s3,40(sp)
    8000492c:	7a02                	ld	s4,32(sp)
    8000492e:	6ae2                	ld	s5,24(sp)
    80004930:	6b42                	ld	s6,16(sp)
    80004932:	6ba2                	ld	s7,8(sp)
    80004934:	6c02                	ld	s8,0(sp)
    80004936:	6161                	addi	sp,sp,80
    80004938:	8082                	ret
    ret = (i == n ? n : -1);
    8000493a:	5a7d                	li	s4,-1
    8000493c:	b7d5                	j	80004920 <filewrite+0xfa>
    panic("filewrite");
    8000493e:	00004517          	auipc	a0,0x4
    80004942:	e7250513          	addi	a0,a0,-398 # 800087b0 <syscalls+0x278>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	bfa080e7          	jalr	-1030(ra) # 80000540 <panic>
    return -1;
    8000494e:	5a7d                	li	s4,-1
    80004950:	bfc1                	j	80004920 <filewrite+0xfa>
      return -1;
    80004952:	5a7d                	li	s4,-1
    80004954:	b7f1                	j	80004920 <filewrite+0xfa>
    80004956:	5a7d                	li	s4,-1
    80004958:	b7e1                	j	80004920 <filewrite+0xfa>

000000008000495a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000495a:	7179                	addi	sp,sp,-48
    8000495c:	f406                	sd	ra,40(sp)
    8000495e:	f022                	sd	s0,32(sp)
    80004960:	ec26                	sd	s1,24(sp)
    80004962:	e84a                	sd	s2,16(sp)
    80004964:	e44e                	sd	s3,8(sp)
    80004966:	e052                	sd	s4,0(sp)
    80004968:	1800                	addi	s0,sp,48
    8000496a:	84aa                	mv	s1,a0
    8000496c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496e:	0005b023          	sd	zero,0(a1)
    80004972:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	bf8080e7          	jalr	-1032(ra) # 8000456e <filealloc>
    8000497e:	e088                	sd	a0,0(s1)
    80004980:	c551                	beqz	a0,80004a0c <pipealloc+0xb2>
    80004982:	00000097          	auipc	ra,0x0
    80004986:	bec080e7          	jalr	-1044(ra) # 8000456e <filealloc>
    8000498a:	00aa3023          	sd	a0,0(s4)
    8000498e:	c92d                	beqz	a0,80004a00 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	156080e7          	jalr	342(ra) # 80000ae6 <kalloc>
    80004998:	892a                	mv	s2,a0
    8000499a:	c125                	beqz	a0,800049fa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000499c:	4985                	li	s3,1
    8000499e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049aa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ae:	00004597          	auipc	a1,0x4
    800049b2:	e1258593          	addi	a1,a1,-494 # 800087c0 <syscalls+0x288>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	190080e7          	jalr	400(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049be:	609c                	ld	a5,0(s1)
    800049c0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c4:	609c                	ld	a5,0(s1)
    800049c6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ca:	609c                	ld	a5,0(s1)
    800049cc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d6:	000a3783          	ld	a5,0(s4)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049de:	000a3783          	ld	a5,0(s4)
    800049e2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e6:	000a3783          	ld	a5,0(s4)
    800049ea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ee:	000a3783          	ld	a5,0(s4)
    800049f2:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f6:	4501                	li	a0,0
    800049f8:	a025                	j	80004a20 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049fa:	6088                	ld	a0,0(s1)
    800049fc:	e501                	bnez	a0,80004a04 <pipealloc+0xaa>
    800049fe:	a039                	j	80004a0c <pipealloc+0xb2>
    80004a00:	6088                	ld	a0,0(s1)
    80004a02:	c51d                	beqz	a0,80004a30 <pipealloc+0xd6>
    fileclose(*f0);
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	c26080e7          	jalr	-986(ra) # 8000462a <fileclose>
  if(*f1)
    80004a0c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a10:	557d                	li	a0,-1
  if(*f1)
    80004a12:	c799                	beqz	a5,80004a20 <pipealloc+0xc6>
    fileclose(*f1);
    80004a14:	853e                	mv	a0,a5
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c14080e7          	jalr	-1004(ra) # 8000462a <fileclose>
  return -1;
    80004a1e:	557d                	li	a0,-1
}
    80004a20:	70a2                	ld	ra,40(sp)
    80004a22:	7402                	ld	s0,32(sp)
    80004a24:	64e2                	ld	s1,24(sp)
    80004a26:	6942                	ld	s2,16(sp)
    80004a28:	69a2                	ld	s3,8(sp)
    80004a2a:	6a02                	ld	s4,0(sp)
    80004a2c:	6145                	addi	sp,sp,48
    80004a2e:	8082                	ret
  return -1;
    80004a30:	557d                	li	a0,-1
    80004a32:	b7fd                	j	80004a20 <pipealloc+0xc6>

0000000080004a34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a34:	1101                	addi	sp,sp,-32
    80004a36:	ec06                	sd	ra,24(sp)
    80004a38:	e822                	sd	s0,16(sp)
    80004a3a:	e426                	sd	s1,8(sp)
    80004a3c:	e04a                	sd	s2,0(sp)
    80004a3e:	1000                	addi	s0,sp,32
    80004a40:	84aa                	mv	s1,a0
    80004a42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	192080e7          	jalr	402(ra) # 80000bd6 <acquire>
  if(writable){
    80004a4c:	02090d63          	beqz	s2,80004a86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a54:	21848513          	addi	a0,s1,536
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	660080e7          	jalr	1632(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a60:	2204b783          	ld	a5,544(s1)
    80004a64:	eb95                	bnez	a5,80004a98 <pipeclose+0x64>
    release(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	222080e7          	jalr	546(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	f76080e7          	jalr	-138(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret
    pi->readopen = 0;
    80004a86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a8a:	21c48513          	addi	a0,s1,540
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	62a080e7          	jalr	1578(ra) # 800020b8 <wakeup>
    80004a96:	b7e9                	j	80004a60 <pipeclose+0x2c>
    release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1f0080e7          	jalr	496(ra) # 80000c8a <release>
}
    80004aa2:	bfe1                	j	80004a7a <pipeclose+0x46>

0000000080004aa4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa4:	711d                	addi	sp,sp,-96
    80004aa6:	ec86                	sd	ra,88(sp)
    80004aa8:	e8a2                	sd	s0,80(sp)
    80004aaa:	e4a6                	sd	s1,72(sp)
    80004aac:	e0ca                	sd	s2,64(sp)
    80004aae:	fc4e                	sd	s3,56(sp)
    80004ab0:	f852                	sd	s4,48(sp)
    80004ab2:	f456                	sd	s5,40(sp)
    80004ab4:	f05a                	sd	s6,32(sp)
    80004ab6:	ec5e                	sd	s7,24(sp)
    80004ab8:	e862                	sd	s8,16(sp)
    80004aba:	1080                	addi	s0,sp,96
    80004abc:	84aa                	mv	s1,a0
    80004abe:	8aae                	mv	s5,a1
    80004ac0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	eea080e7          	jalr	-278(ra) # 800019ac <myproc>
    80004aca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	108080e7          	jalr	264(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ad6:	0b405663          	blez	s4,80004b82 <pipewrite+0xde>
  int i = 0;
    80004ada:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004adc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ade:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ae2:	21c48b93          	addi	s7,s1,540
    80004ae6:	a089                	j	80004b28 <pipewrite+0x84>
      release(&pi->lock);
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	1a0080e7          	jalr	416(ra) # 80000c8a <release>
      return -1;
    80004af2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004af4:	854a                	mv	a0,s2
    80004af6:	60e6                	ld	ra,88(sp)
    80004af8:	6446                	ld	s0,80(sp)
    80004afa:	64a6                	ld	s1,72(sp)
    80004afc:	6906                	ld	s2,64(sp)
    80004afe:	79e2                	ld	s3,56(sp)
    80004b00:	7a42                	ld	s4,48(sp)
    80004b02:	7aa2                	ld	s5,40(sp)
    80004b04:	7b02                	ld	s6,32(sp)
    80004b06:	6be2                	ld	s7,24(sp)
    80004b08:	6c42                	ld	s8,16(sp)
    80004b0a:	6125                	addi	sp,sp,96
    80004b0c:	8082                	ret
      wakeup(&pi->nread);
    80004b0e:	8562                	mv	a0,s8
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	5a8080e7          	jalr	1448(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b18:	85a6                	mv	a1,s1
    80004b1a:	855e                	mv	a0,s7
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	538080e7          	jalr	1336(ra) # 80002054 <sleep>
  while(i < n){
    80004b24:	07495063          	bge	s2,s4,80004b84 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b28:	2204a783          	lw	a5,544(s1)
    80004b2c:	dfd5                	beqz	a5,80004ae8 <pipewrite+0x44>
    80004b2e:	854e                	mv	a0,s3
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	7cc080e7          	jalr	1996(ra) # 800022fc <killed>
    80004b38:	f945                	bnez	a0,80004ae8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b3a:	2184a783          	lw	a5,536(s1)
    80004b3e:	21c4a703          	lw	a4,540(s1)
    80004b42:	2007879b          	addiw	a5,a5,512
    80004b46:	fcf704e3          	beq	a4,a5,80004b0e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b4a:	4685                	li	a3,1
    80004b4c:	01590633          	add	a2,s2,s5
    80004b50:	faf40593          	addi	a1,s0,-81
    80004b54:	0509b503          	ld	a0,80(s3)
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	ba0080e7          	jalr	-1120(ra) # 800016f8 <copyin>
    80004b60:	03650263          	beq	a0,s6,80004b84 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b64:	21c4a783          	lw	a5,540(s1)
    80004b68:	0017871b          	addiw	a4,a5,1
    80004b6c:	20e4ae23          	sw	a4,540(s1)
    80004b70:	1ff7f793          	andi	a5,a5,511
    80004b74:	97a6                	add	a5,a5,s1
    80004b76:	faf44703          	lbu	a4,-81(s0)
    80004b7a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b7e:	2905                	addiw	s2,s2,1
    80004b80:	b755                	j	80004b24 <pipewrite+0x80>
  int i = 0;
    80004b82:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b84:	21848513          	addi	a0,s1,536
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	530080e7          	jalr	1328(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	0f8080e7          	jalr	248(ra) # 80000c8a <release>
  return i;
    80004b9a:	bfa9                	j	80004af4 <pipewrite+0x50>

0000000080004b9c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b9c:	715d                	addi	sp,sp,-80
    80004b9e:	e486                	sd	ra,72(sp)
    80004ba0:	e0a2                	sd	s0,64(sp)
    80004ba2:	fc26                	sd	s1,56(sp)
    80004ba4:	f84a                	sd	s2,48(sp)
    80004ba6:	f44e                	sd	s3,40(sp)
    80004ba8:	f052                	sd	s4,32(sp)
    80004baa:	ec56                	sd	s5,24(sp)
    80004bac:	e85a                	sd	s6,16(sp)
    80004bae:	0880                	addi	s0,sp,80
    80004bb0:	84aa                	mv	s1,a0
    80004bb2:	892e                	mv	s2,a1
    80004bb4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	df6080e7          	jalr	-522(ra) # 800019ac <myproc>
    80004bbe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	014080e7          	jalr	20(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bca:	2184a703          	lw	a4,536(s1)
    80004bce:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bd2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	02f71763          	bne	a4,a5,80004c04 <piperead+0x68>
    80004bda:	2244a783          	lw	a5,548(s1)
    80004bde:	c39d                	beqz	a5,80004c04 <piperead+0x68>
    if(killed(pr)){
    80004be0:	8552                	mv	a0,s4
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	71a080e7          	jalr	1818(ra) # 800022fc <killed>
    80004bea:	e949                	bnez	a0,80004c7c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bec:	85a6                	mv	a1,s1
    80004bee:	854e                	mv	a0,s3
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	464080e7          	jalr	1124(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf8:	2184a703          	lw	a4,536(s1)
    80004bfc:	21c4a783          	lw	a5,540(s1)
    80004c00:	fcf70de3          	beq	a4,a5,80004bda <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c04:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c06:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c08:	05505463          	blez	s5,80004c50 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c0c:	2184a783          	lw	a5,536(s1)
    80004c10:	21c4a703          	lw	a4,540(s1)
    80004c14:	02f70e63          	beq	a4,a5,80004c50 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c18:	0017871b          	addiw	a4,a5,1
    80004c1c:	20e4ac23          	sw	a4,536(s1)
    80004c20:	1ff7f793          	andi	a5,a5,511
    80004c24:	97a6                	add	a5,a5,s1
    80004c26:	0187c783          	lbu	a5,24(a5)
    80004c2a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c2e:	4685                	li	a3,1
    80004c30:	fbf40613          	addi	a2,s0,-65
    80004c34:	85ca                	mv	a1,s2
    80004c36:	050a3503          	ld	a0,80(s4)
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	a32080e7          	jalr	-1486(ra) # 8000166c <copyout>
    80004c42:	01650763          	beq	a0,s6,80004c50 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c46:	2985                	addiw	s3,s3,1
    80004c48:	0905                	addi	s2,s2,1
    80004c4a:	fd3a91e3          	bne	s5,s3,80004c0c <piperead+0x70>
    80004c4e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c50:	21c48513          	addi	a0,s1,540
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	464080e7          	jalr	1124(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	02c080e7          	jalr	44(ra) # 80000c8a <release>
  return i;
}
    80004c66:	854e                	mv	a0,s3
    80004c68:	60a6                	ld	ra,72(sp)
    80004c6a:	6406                	ld	s0,64(sp)
    80004c6c:	74e2                	ld	s1,56(sp)
    80004c6e:	7942                	ld	s2,48(sp)
    80004c70:	79a2                	ld	s3,40(sp)
    80004c72:	7a02                	ld	s4,32(sp)
    80004c74:	6ae2                	ld	s5,24(sp)
    80004c76:	6b42                	ld	s6,16(sp)
    80004c78:	6161                	addi	sp,sp,80
    80004c7a:	8082                	ret
      release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	00c080e7          	jalr	12(ra) # 80000c8a <release>
      return -1;
    80004c86:	59fd                	li	s3,-1
    80004c88:	bff9                	j	80004c66 <piperead+0xca>

0000000080004c8a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c8a:	1141                	addi	sp,sp,-16
    80004c8c:	e422                	sd	s0,8(sp)
    80004c8e:	0800                	addi	s0,sp,16
    80004c90:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c92:	8905                	andi	a0,a0,1
    80004c94:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c96:	8b89                	andi	a5,a5,2
    80004c98:	c399                	beqz	a5,80004c9e <flags2perm+0x14>
      perm |= PTE_W;
    80004c9a:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c9e:	6422                	ld	s0,8(sp)
    80004ca0:	0141                	addi	sp,sp,16
    80004ca2:	8082                	ret

0000000080004ca4 <exec>:

int
exec(char *path, char **argv)
{
    80004ca4:	de010113          	addi	sp,sp,-544
    80004ca8:	20113c23          	sd	ra,536(sp)
    80004cac:	20813823          	sd	s0,528(sp)
    80004cb0:	20913423          	sd	s1,520(sp)
    80004cb4:	21213023          	sd	s2,512(sp)
    80004cb8:	ffce                	sd	s3,504(sp)
    80004cba:	fbd2                	sd	s4,496(sp)
    80004cbc:	f7d6                	sd	s5,488(sp)
    80004cbe:	f3da                	sd	s6,480(sp)
    80004cc0:	efde                	sd	s7,472(sp)
    80004cc2:	ebe2                	sd	s8,464(sp)
    80004cc4:	e7e6                	sd	s9,456(sp)
    80004cc6:	e3ea                	sd	s10,448(sp)
    80004cc8:	ff6e                	sd	s11,440(sp)
    80004cca:	1400                	addi	s0,sp,544
    80004ccc:	892a                	mv	s2,a0
    80004cce:	dea43423          	sd	a0,-536(s0)
    80004cd2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	cd6080e7          	jalr	-810(ra) # 800019ac <myproc>
    80004cde:	84aa                	mv	s1,a0

  begin_op();
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	482080e7          	jalr	1154(ra) # 80004162 <begin_op>

  if((ip = namei(path)) == 0){
    80004ce8:	854a                	mv	a0,s2
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	258080e7          	jalr	600(ra) # 80003f42 <namei>
    80004cf2:	c93d                	beqz	a0,80004d68 <exec+0xc4>
    80004cf4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	aa0080e7          	jalr	-1376(ra) # 80003796 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cfe:	04000713          	li	a4,64
    80004d02:	4681                	li	a3,0
    80004d04:	e5040613          	addi	a2,s0,-432
    80004d08:	4581                	li	a1,0
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	d3e080e7          	jalr	-706(ra) # 80003a4a <readi>
    80004d14:	04000793          	li	a5,64
    80004d18:	00f51a63          	bne	a0,a5,80004d2c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d1c:	e5042703          	lw	a4,-432(s0)
    80004d20:	464c47b7          	lui	a5,0x464c4
    80004d24:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d28:	04f70663          	beq	a4,a5,80004d74 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d2c:	8556                	mv	a0,s5
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	cca080e7          	jalr	-822(ra) # 800039f8 <iunlockput>
    end_op();
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	4aa080e7          	jalr	1194(ra) # 800041e0 <end_op>
  }
  return -1;
    80004d3e:	557d                	li	a0,-1
}
    80004d40:	21813083          	ld	ra,536(sp)
    80004d44:	21013403          	ld	s0,528(sp)
    80004d48:	20813483          	ld	s1,520(sp)
    80004d4c:	20013903          	ld	s2,512(sp)
    80004d50:	79fe                	ld	s3,504(sp)
    80004d52:	7a5e                	ld	s4,496(sp)
    80004d54:	7abe                	ld	s5,488(sp)
    80004d56:	7b1e                	ld	s6,480(sp)
    80004d58:	6bfe                	ld	s7,472(sp)
    80004d5a:	6c5e                	ld	s8,464(sp)
    80004d5c:	6cbe                	ld	s9,456(sp)
    80004d5e:	6d1e                	ld	s10,448(sp)
    80004d60:	7dfa                	ld	s11,440(sp)
    80004d62:	22010113          	addi	sp,sp,544
    80004d66:	8082                	ret
    end_op();
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	478080e7          	jalr	1144(ra) # 800041e0 <end_op>
    return -1;
    80004d70:	557d                	li	a0,-1
    80004d72:	b7f9                	j	80004d40 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d74:	8526                	mv	a0,s1
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	cfa080e7          	jalr	-774(ra) # 80001a70 <proc_pagetable>
    80004d7e:	8b2a                	mv	s6,a0
    80004d80:	d555                	beqz	a0,80004d2c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d82:	e7042783          	lw	a5,-400(s0)
    80004d86:	e8845703          	lhu	a4,-376(s0)
    80004d8a:	c735                	beqz	a4,80004df6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d8c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d92:	6a05                	lui	s4,0x1
    80004d94:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d98:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d9c:	6d85                	lui	s11,0x1
    80004d9e:	7d7d                	lui	s10,0xfffff
    80004da0:	ac3d                	j	80004fde <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da2:	00004517          	auipc	a0,0x4
    80004da6:	a2650513          	addi	a0,a0,-1498 # 800087c8 <syscalls+0x290>
    80004daa:	ffffb097          	auipc	ra,0xffffb
    80004dae:	796080e7          	jalr	1942(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db2:	874a                	mv	a4,s2
    80004db4:	009c86bb          	addw	a3,s9,s1
    80004db8:	4581                	li	a1,0
    80004dba:	8556                	mv	a0,s5
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	c8e080e7          	jalr	-882(ra) # 80003a4a <readi>
    80004dc4:	2501                	sext.w	a0,a0
    80004dc6:	1aa91963          	bne	s2,a0,80004f78 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004dca:	009d84bb          	addw	s1,s11,s1
    80004dce:	013d09bb          	addw	s3,s10,s3
    80004dd2:	1f74f663          	bgeu	s1,s7,80004fbe <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004dd6:	02049593          	slli	a1,s1,0x20
    80004dda:	9181                	srli	a1,a1,0x20
    80004ddc:	95e2                	add	a1,a1,s8
    80004dde:	855a                	mv	a0,s6
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	27c080e7          	jalr	636(ra) # 8000105c <walkaddr>
    80004de8:	862a                	mv	a2,a0
    if(pa == 0)
    80004dea:	dd45                	beqz	a0,80004da2 <exec+0xfe>
      n = PGSIZE;
    80004dec:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dee:	fd49f2e3          	bgeu	s3,s4,80004db2 <exec+0x10e>
      n = sz - i;
    80004df2:	894e                	mv	s2,s3
    80004df4:	bf7d                	j	80004db2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df6:	4901                	li	s2,0
  iunlockput(ip);
    80004df8:	8556                	mv	a0,s5
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	bfe080e7          	jalr	-1026(ra) # 800039f8 <iunlockput>
  end_op();
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	3de080e7          	jalr	990(ra) # 800041e0 <end_op>
  p = myproc();
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	ba2080e7          	jalr	-1118(ra) # 800019ac <myproc>
    80004e12:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e14:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e18:	6785                	lui	a5,0x1
    80004e1a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e1c:	97ca                	add	a5,a5,s2
    80004e1e:	777d                	lui	a4,0xfffff
    80004e20:	8ff9                	and	a5,a5,a4
    80004e22:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e26:	4691                	li	a3,4
    80004e28:	6609                	lui	a2,0x2
    80004e2a:	963e                	add	a2,a2,a5
    80004e2c:	85be                	mv	a1,a5
    80004e2e:	855a                	mv	a0,s6
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	5e0080e7          	jalr	1504(ra) # 80001410 <uvmalloc>
    80004e38:	8c2a                	mv	s8,a0
  ip = 0;
    80004e3a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e3c:	12050e63          	beqz	a0,80004f78 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e40:	75f9                	lui	a1,0xffffe
    80004e42:	95aa                	add	a1,a1,a0
    80004e44:	855a                	mv	a0,s6
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	7f4080e7          	jalr	2036(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e4e:	7afd                	lui	s5,0xfffff
    80004e50:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e52:	df043783          	ld	a5,-528(s0)
    80004e56:	6388                	ld	a0,0(a5)
    80004e58:	c925                	beqz	a0,80004ec8 <exec+0x224>
    80004e5a:	e9040993          	addi	s3,s0,-368
    80004e5e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e62:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e64:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	fe8080e7          	jalr	-24(ra) # 80000e4e <strlen>
    80004e6e:	0015079b          	addiw	a5,a0,1
    80004e72:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e76:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e7a:	13596663          	bltu	s2,s5,80004fa6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7e:	df043d83          	ld	s11,-528(s0)
    80004e82:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e86:	8552                	mv	a0,s4
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	fc6080e7          	jalr	-58(ra) # 80000e4e <strlen>
    80004e90:	0015069b          	addiw	a3,a0,1
    80004e94:	8652                	mv	a2,s4
    80004e96:	85ca                	mv	a1,s2
    80004e98:	855a                	mv	a0,s6
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	7d2080e7          	jalr	2002(ra) # 8000166c <copyout>
    80004ea2:	10054663          	bltz	a0,80004fae <exec+0x30a>
    ustack[argc] = sp;
    80004ea6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eaa:	0485                	addi	s1,s1,1
    80004eac:	008d8793          	addi	a5,s11,8
    80004eb0:	def43823          	sd	a5,-528(s0)
    80004eb4:	008db503          	ld	a0,8(s11)
    80004eb8:	c911                	beqz	a0,80004ecc <exec+0x228>
    if(argc >= MAXARG)
    80004eba:	09a1                	addi	s3,s3,8
    80004ebc:	fb3c95e3          	bne	s9,s3,80004e66 <exec+0x1c2>
  sz = sz1;
    80004ec0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec4:	4a81                	li	s5,0
    80004ec6:	a84d                	j	80004f78 <exec+0x2d4>
  sp = sz;
    80004ec8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ecc:	00349793          	slli	a5,s1,0x3
    80004ed0:	f9078793          	addi	a5,a5,-112
    80004ed4:	97a2                	add	a5,a5,s0
    80004ed6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eda:	00148693          	addi	a3,s1,1
    80004ede:	068e                	slli	a3,a3,0x3
    80004ee0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee8:	01597663          	bgeu	s2,s5,80004ef4 <exec+0x250>
  sz = sz1;
    80004eec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef0:	4a81                	li	s5,0
    80004ef2:	a059                	j	80004f78 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef4:	e9040613          	addi	a2,s0,-368
    80004ef8:	85ca                	mv	a1,s2
    80004efa:	855a                	mv	a0,s6
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	770080e7          	jalr	1904(ra) # 8000166c <copyout>
    80004f04:	0a054963          	bltz	a0,80004fb6 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f08:	058bb783          	ld	a5,88(s7)
    80004f0c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f10:	de843783          	ld	a5,-536(s0)
    80004f14:	0007c703          	lbu	a4,0(a5)
    80004f18:	cf11                	beqz	a4,80004f34 <exec+0x290>
    80004f1a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1c:	02f00693          	li	a3,47
    80004f20:	a039                	j	80004f2e <exec+0x28a>
      last = s+1;
    80004f22:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f26:	0785                	addi	a5,a5,1
    80004f28:	fff7c703          	lbu	a4,-1(a5)
    80004f2c:	c701                	beqz	a4,80004f34 <exec+0x290>
    if(*s == '/')
    80004f2e:	fed71ce3          	bne	a4,a3,80004f26 <exec+0x282>
    80004f32:	bfc5                	j	80004f22 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f34:	4641                	li	a2,16
    80004f36:	de843583          	ld	a1,-536(s0)
    80004f3a:	158b8513          	addi	a0,s7,344
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	ede080e7          	jalr	-290(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f46:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f4a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f4e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f52:	058bb783          	ld	a5,88(s7)
    80004f56:	e6843703          	ld	a4,-408(s0)
    80004f5a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5c:	058bb783          	ld	a5,88(s7)
    80004f60:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f64:	85ea                	mv	a1,s10
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	ba6080e7          	jalr	-1114(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6e:	0004851b          	sext.w	a0,s1
    80004f72:	b3f9                	j	80004d40 <exec+0x9c>
    80004f74:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f78:	df843583          	ld	a1,-520(s0)
    80004f7c:	855a                	mv	a0,s6
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	b8e080e7          	jalr	-1138(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f86:	da0a93e3          	bnez	s5,80004d2c <exec+0x88>
  return -1;
    80004f8a:	557d                	li	a0,-1
    80004f8c:	bb55                	j	80004d40 <exec+0x9c>
    80004f8e:	df243c23          	sd	s2,-520(s0)
    80004f92:	b7dd                	j	80004f78 <exec+0x2d4>
    80004f94:	df243c23          	sd	s2,-520(s0)
    80004f98:	b7c5                	j	80004f78 <exec+0x2d4>
    80004f9a:	df243c23          	sd	s2,-520(s0)
    80004f9e:	bfe9                	j	80004f78 <exec+0x2d4>
    80004fa0:	df243c23          	sd	s2,-520(s0)
    80004fa4:	bfd1                	j	80004f78 <exec+0x2d4>
  sz = sz1;
    80004fa6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004faa:	4a81                	li	s5,0
    80004fac:	b7f1                	j	80004f78 <exec+0x2d4>
  sz = sz1;
    80004fae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fb2:	4a81                	li	s5,0
    80004fb4:	b7d1                	j	80004f78 <exec+0x2d4>
  sz = sz1;
    80004fb6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fba:	4a81                	li	s5,0
    80004fbc:	bf75                	j	80004f78 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fbe:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc2:	e0843783          	ld	a5,-504(s0)
    80004fc6:	0017869b          	addiw	a3,a5,1
    80004fca:	e0d43423          	sd	a3,-504(s0)
    80004fce:	e0043783          	ld	a5,-512(s0)
    80004fd2:	0387879b          	addiw	a5,a5,56
    80004fd6:	e8845703          	lhu	a4,-376(s0)
    80004fda:	e0e6dfe3          	bge	a3,a4,80004df8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fde:	2781                	sext.w	a5,a5
    80004fe0:	e0f43023          	sd	a5,-512(s0)
    80004fe4:	03800713          	li	a4,56
    80004fe8:	86be                	mv	a3,a5
    80004fea:	e1840613          	addi	a2,s0,-488
    80004fee:	4581                	li	a1,0
    80004ff0:	8556                	mv	a0,s5
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	a58080e7          	jalr	-1448(ra) # 80003a4a <readi>
    80004ffa:	03800793          	li	a5,56
    80004ffe:	f6f51be3          	bne	a0,a5,80004f74 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005002:	e1842783          	lw	a5,-488(s0)
    80005006:	4705                	li	a4,1
    80005008:	fae79de3          	bne	a5,a4,80004fc2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000500c:	e4043483          	ld	s1,-448(s0)
    80005010:	e3843783          	ld	a5,-456(s0)
    80005014:	f6f4ede3          	bltu	s1,a5,80004f8e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005018:	e2843783          	ld	a5,-472(s0)
    8000501c:	94be                	add	s1,s1,a5
    8000501e:	f6f4ebe3          	bltu	s1,a5,80004f94 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005022:	de043703          	ld	a4,-544(s0)
    80005026:	8ff9                	and	a5,a5,a4
    80005028:	fbad                	bnez	a5,80004f9a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000502a:	e1c42503          	lw	a0,-484(s0)
    8000502e:	00000097          	auipc	ra,0x0
    80005032:	c5c080e7          	jalr	-932(ra) # 80004c8a <flags2perm>
    80005036:	86aa                	mv	a3,a0
    80005038:	8626                	mv	a2,s1
    8000503a:	85ca                	mv	a1,s2
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	3d2080e7          	jalr	978(ra) # 80001410 <uvmalloc>
    80005046:	dea43c23          	sd	a0,-520(s0)
    8000504a:	d939                	beqz	a0,80004fa0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000504c:	e2843c03          	ld	s8,-472(s0)
    80005050:	e2042c83          	lw	s9,-480(s0)
    80005054:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005058:	f60b83e3          	beqz	s7,80004fbe <exec+0x31a>
    8000505c:	89de                	mv	s3,s7
    8000505e:	4481                	li	s1,0
    80005060:	bb9d                	j	80004dd6 <exec+0x132>

0000000080005062 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005062:	7179                	addi	sp,sp,-48
    80005064:	f406                	sd	ra,40(sp)
    80005066:	f022                	sd	s0,32(sp)
    80005068:	ec26                	sd	s1,24(sp)
    8000506a:	e84a                	sd	s2,16(sp)
    8000506c:	1800                	addi	s0,sp,48
    8000506e:	892e                	mv	s2,a1
    80005070:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005072:	fdc40593          	addi	a1,s0,-36
    80005076:	ffffe097          	auipc	ra,0xffffe
    8000507a:	b50080e7          	jalr	-1200(ra) # 80002bc6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000507e:	fdc42703          	lw	a4,-36(s0)
    80005082:	47bd                	li	a5,15
    80005084:	02e7eb63          	bltu	a5,a4,800050ba <argfd+0x58>
    80005088:	ffffd097          	auipc	ra,0xffffd
    8000508c:	924080e7          	jalr	-1756(ra) # 800019ac <myproc>
    80005090:	fdc42703          	lw	a4,-36(s0)
    80005094:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd1ba>
    80005098:	078e                	slli	a5,a5,0x3
    8000509a:	953e                	add	a0,a0,a5
    8000509c:	611c                	ld	a5,0(a0)
    8000509e:	c385                	beqz	a5,800050be <argfd+0x5c>
    return -1;
  if(pfd)
    800050a0:	00090463          	beqz	s2,800050a8 <argfd+0x46>
    *pfd = fd;
    800050a4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050a8:	4501                	li	a0,0
  if(pf)
    800050aa:	c091                	beqz	s1,800050ae <argfd+0x4c>
    *pf = f;
    800050ac:	e09c                	sd	a5,0(s1)
}
    800050ae:	70a2                	ld	ra,40(sp)
    800050b0:	7402                	ld	s0,32(sp)
    800050b2:	64e2                	ld	s1,24(sp)
    800050b4:	6942                	ld	s2,16(sp)
    800050b6:	6145                	addi	sp,sp,48
    800050b8:	8082                	ret
    return -1;
    800050ba:	557d                	li	a0,-1
    800050bc:	bfcd                	j	800050ae <argfd+0x4c>
    800050be:	557d                	li	a0,-1
    800050c0:	b7fd                	j	800050ae <argfd+0x4c>

00000000800050c2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c2:	1101                	addi	sp,sp,-32
    800050c4:	ec06                	sd	ra,24(sp)
    800050c6:	e822                	sd	s0,16(sp)
    800050c8:	e426                	sd	s1,8(sp)
    800050ca:	1000                	addi	s0,sp,32
    800050cc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	8de080e7          	jalr	-1826(ra) # 800019ac <myproc>
    800050d6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d8:	0d050793          	addi	a5,a0,208
    800050dc:	4501                	li	a0,0
    800050de:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050e0:	6398                	ld	a4,0(a5)
    800050e2:	cb19                	beqz	a4,800050f8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e4:	2505                	addiw	a0,a0,1
    800050e6:	07a1                	addi	a5,a5,8
    800050e8:	fed51ce3          	bne	a0,a3,800050e0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ec:	557d                	li	a0,-1
}
    800050ee:	60e2                	ld	ra,24(sp)
    800050f0:	6442                	ld	s0,16(sp)
    800050f2:	64a2                	ld	s1,8(sp)
    800050f4:	6105                	addi	sp,sp,32
    800050f6:	8082                	ret
      p->ofile[fd] = f;
    800050f8:	01a50793          	addi	a5,a0,26
    800050fc:	078e                	slli	a5,a5,0x3
    800050fe:	963e                	add	a2,a2,a5
    80005100:	e204                	sd	s1,0(a2)
      return fd;
    80005102:	b7f5                	j	800050ee <fdalloc+0x2c>

0000000080005104 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005104:	715d                	addi	sp,sp,-80
    80005106:	e486                	sd	ra,72(sp)
    80005108:	e0a2                	sd	s0,64(sp)
    8000510a:	fc26                	sd	s1,56(sp)
    8000510c:	f84a                	sd	s2,48(sp)
    8000510e:	f44e                	sd	s3,40(sp)
    80005110:	f052                	sd	s4,32(sp)
    80005112:	ec56                	sd	s5,24(sp)
    80005114:	e85a                	sd	s6,16(sp)
    80005116:	0880                	addi	s0,sp,80
    80005118:	8b2e                	mv	s6,a1
    8000511a:	89b2                	mv	s3,a2
    8000511c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000511e:	fb040593          	addi	a1,s0,-80
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	e3e080e7          	jalr	-450(ra) # 80003f60 <nameiparent>
    8000512a:	84aa                	mv	s1,a0
    8000512c:	14050f63          	beqz	a0,8000528a <create+0x186>
    return 0;

  ilock(dp);
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	666080e7          	jalr	1638(ra) # 80003796 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005138:	4601                	li	a2,0
    8000513a:	fb040593          	addi	a1,s0,-80
    8000513e:	8526                	mv	a0,s1
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	b3a080e7          	jalr	-1222(ra) # 80003c7a <dirlookup>
    80005148:	8aaa                	mv	s5,a0
    8000514a:	c931                	beqz	a0,8000519e <create+0x9a>
    iunlockput(dp);
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	8aa080e7          	jalr	-1878(ra) # 800039f8 <iunlockput>
    ilock(ip);
    80005156:	8556                	mv	a0,s5
    80005158:	ffffe097          	auipc	ra,0xffffe
    8000515c:	63e080e7          	jalr	1598(ra) # 80003796 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005160:	000b059b          	sext.w	a1,s6
    80005164:	4789                	li	a5,2
    80005166:	02f59563          	bne	a1,a5,80005190 <create+0x8c>
    8000516a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd1e4>
    8000516e:	37f9                	addiw	a5,a5,-2
    80005170:	17c2                	slli	a5,a5,0x30
    80005172:	93c1                	srli	a5,a5,0x30
    80005174:	4705                	li	a4,1
    80005176:	00f76d63          	bltu	a4,a5,80005190 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000517a:	8556                	mv	a0,s5
    8000517c:	60a6                	ld	ra,72(sp)
    8000517e:	6406                	ld	s0,64(sp)
    80005180:	74e2                	ld	s1,56(sp)
    80005182:	7942                	ld	s2,48(sp)
    80005184:	79a2                	ld	s3,40(sp)
    80005186:	7a02                	ld	s4,32(sp)
    80005188:	6ae2                	ld	s5,24(sp)
    8000518a:	6b42                	ld	s6,16(sp)
    8000518c:	6161                	addi	sp,sp,80
    8000518e:	8082                	ret
    iunlockput(ip);
    80005190:	8556                	mv	a0,s5
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	866080e7          	jalr	-1946(ra) # 800039f8 <iunlockput>
    return 0;
    8000519a:	4a81                	li	s5,0
    8000519c:	bff9                	j	8000517a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000519e:	85da                	mv	a1,s6
    800051a0:	4088                	lw	a0,0(s1)
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	456080e7          	jalr	1110(ra) # 800035f8 <ialloc>
    800051aa:	8a2a                	mv	s4,a0
    800051ac:	c539                	beqz	a0,800051fa <create+0xf6>
  ilock(ip);
    800051ae:	ffffe097          	auipc	ra,0xffffe
    800051b2:	5e8080e7          	jalr	1512(ra) # 80003796 <ilock>
  ip->major = major;
    800051b6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051ba:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051be:	4905                	li	s2,1
    800051c0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051c4:	8552                	mv	a0,s4
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	504080e7          	jalr	1284(ra) # 800036ca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ce:	000b059b          	sext.w	a1,s6
    800051d2:	03258b63          	beq	a1,s2,80005208 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051d6:	004a2603          	lw	a2,4(s4)
    800051da:	fb040593          	addi	a1,s0,-80
    800051de:	8526                	mv	a0,s1
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	cb0080e7          	jalr	-848(ra) # 80003e90 <dirlink>
    800051e8:	06054f63          	bltz	a0,80005266 <create+0x162>
  iunlockput(dp);
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	80a080e7          	jalr	-2038(ra) # 800039f8 <iunlockput>
  return ip;
    800051f6:	8ad2                	mv	s5,s4
    800051f8:	b749                	j	8000517a <create+0x76>
    iunlockput(dp);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	7fc080e7          	jalr	2044(ra) # 800039f8 <iunlockput>
    return 0;
    80005204:	8ad2                	mv	s5,s4
    80005206:	bf95                	j	8000517a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005208:	004a2603          	lw	a2,4(s4)
    8000520c:	00003597          	auipc	a1,0x3
    80005210:	5dc58593          	addi	a1,a1,1500 # 800087e8 <syscalls+0x2b0>
    80005214:	8552                	mv	a0,s4
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	c7a080e7          	jalr	-902(ra) # 80003e90 <dirlink>
    8000521e:	04054463          	bltz	a0,80005266 <create+0x162>
    80005222:	40d0                	lw	a2,4(s1)
    80005224:	00003597          	auipc	a1,0x3
    80005228:	5cc58593          	addi	a1,a1,1484 # 800087f0 <syscalls+0x2b8>
    8000522c:	8552                	mv	a0,s4
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	c62080e7          	jalr	-926(ra) # 80003e90 <dirlink>
    80005236:	02054863          	bltz	a0,80005266 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000523a:	004a2603          	lw	a2,4(s4)
    8000523e:	fb040593          	addi	a1,s0,-80
    80005242:	8526                	mv	a0,s1
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	c4c080e7          	jalr	-948(ra) # 80003e90 <dirlink>
    8000524c:	00054d63          	bltz	a0,80005266 <create+0x162>
    dp->nlink++;  // for ".."
    80005250:	04a4d783          	lhu	a5,74(s1)
    80005254:	2785                	addiw	a5,a5,1
    80005256:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000525a:	8526                	mv	a0,s1
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	46e080e7          	jalr	1134(ra) # 800036ca <iupdate>
    80005264:	b761                	j	800051ec <create+0xe8>
  ip->nlink = 0;
    80005266:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000526a:	8552                	mv	a0,s4
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	45e080e7          	jalr	1118(ra) # 800036ca <iupdate>
  iunlockput(ip);
    80005274:	8552                	mv	a0,s4
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	782080e7          	jalr	1922(ra) # 800039f8 <iunlockput>
  iunlockput(dp);
    8000527e:	8526                	mv	a0,s1
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	778080e7          	jalr	1912(ra) # 800039f8 <iunlockput>
  return 0;
    80005288:	bdcd                	j	8000517a <create+0x76>
    return 0;
    8000528a:	8aaa                	mv	s5,a0
    8000528c:	b5fd                	j	8000517a <create+0x76>

000000008000528e <sys_dup>:
{
    8000528e:	7179                	addi	sp,sp,-48
    80005290:	f406                	sd	ra,40(sp)
    80005292:	f022                	sd	s0,32(sp)
    80005294:	ec26                	sd	s1,24(sp)
    80005296:	e84a                	sd	s2,16(sp)
    80005298:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000529a:	fd840613          	addi	a2,s0,-40
    8000529e:	4581                	li	a1,0
    800052a0:	4501                	li	a0,0
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	dc0080e7          	jalr	-576(ra) # 80005062 <argfd>
    return -1;
    800052aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ac:	02054363          	bltz	a0,800052d2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052b0:	fd843903          	ld	s2,-40(s0)
    800052b4:	854a                	mv	a0,s2
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	e0c080e7          	jalr	-500(ra) # 800050c2 <fdalloc>
    800052be:	84aa                	mv	s1,a0
    return -1;
    800052c0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c2:	00054863          	bltz	a0,800052d2 <sys_dup+0x44>
  filedup(f);
    800052c6:	854a                	mv	a0,s2
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	310080e7          	jalr	784(ra) # 800045d8 <filedup>
  return fd;
    800052d0:	87a6                	mv	a5,s1
}
    800052d2:	853e                	mv	a0,a5
    800052d4:	70a2                	ld	ra,40(sp)
    800052d6:	7402                	ld	s0,32(sp)
    800052d8:	64e2                	ld	s1,24(sp)
    800052da:	6942                	ld	s2,16(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_read>:
{
    800052e0:	7179                	addi	sp,sp,-48
    800052e2:	f406                	sd	ra,40(sp)
    800052e4:	f022                	sd	s0,32(sp)
    800052e6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052e8:	fd840593          	addi	a1,s0,-40
    800052ec:	4505                	li	a0,1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	8f8080e7          	jalr	-1800(ra) # 80002be6 <argaddr>
  argint(2, &n);
    800052f6:	fe440593          	addi	a1,s0,-28
    800052fa:	4509                	li	a0,2
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	8ca080e7          	jalr	-1846(ra) # 80002bc6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005304:	fe840613          	addi	a2,s0,-24
    80005308:	4581                	li	a1,0
    8000530a:	4501                	li	a0,0
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	d56080e7          	jalr	-682(ra) # 80005062 <argfd>
    80005314:	87aa                	mv	a5,a0
    return -1;
    80005316:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005318:	0007cc63          	bltz	a5,80005330 <sys_read+0x50>
  return fileread(f, p, n);
    8000531c:	fe442603          	lw	a2,-28(s0)
    80005320:	fd843583          	ld	a1,-40(s0)
    80005324:	fe843503          	ld	a0,-24(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	43c080e7          	jalr	1084(ra) # 80004764 <fileread>
}
    80005330:	70a2                	ld	ra,40(sp)
    80005332:	7402                	ld	s0,32(sp)
    80005334:	6145                	addi	sp,sp,48
    80005336:	8082                	ret

0000000080005338 <sys_write>:
{
    80005338:	7179                	addi	sp,sp,-48
    8000533a:	f406                	sd	ra,40(sp)
    8000533c:	f022                	sd	s0,32(sp)
    8000533e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005340:	fd840593          	addi	a1,s0,-40
    80005344:	4505                	li	a0,1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	8a0080e7          	jalr	-1888(ra) # 80002be6 <argaddr>
  argint(2, &n);
    8000534e:	fe440593          	addi	a1,s0,-28
    80005352:	4509                	li	a0,2
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	872080e7          	jalr	-1934(ra) # 80002bc6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000535c:	fe840613          	addi	a2,s0,-24
    80005360:	4581                	li	a1,0
    80005362:	4501                	li	a0,0
    80005364:	00000097          	auipc	ra,0x0
    80005368:	cfe080e7          	jalr	-770(ra) # 80005062 <argfd>
    8000536c:	87aa                	mv	a5,a0
    return -1;
    8000536e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005370:	0007cc63          	bltz	a5,80005388 <sys_write+0x50>
  return filewrite(f, p, n);
    80005374:	fe442603          	lw	a2,-28(s0)
    80005378:	fd843583          	ld	a1,-40(s0)
    8000537c:	fe843503          	ld	a0,-24(s0)
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	4a6080e7          	jalr	1190(ra) # 80004826 <filewrite>
}
    80005388:	70a2                	ld	ra,40(sp)
    8000538a:	7402                	ld	s0,32(sp)
    8000538c:	6145                	addi	sp,sp,48
    8000538e:	8082                	ret

0000000080005390 <sys_close>:
{
    80005390:	1101                	addi	sp,sp,-32
    80005392:	ec06                	sd	ra,24(sp)
    80005394:	e822                	sd	s0,16(sp)
    80005396:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005398:	fe040613          	addi	a2,s0,-32
    8000539c:	fec40593          	addi	a1,s0,-20
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	cc0080e7          	jalr	-832(ra) # 80005062 <argfd>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ac:	02054463          	bltz	a0,800053d4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	5fc080e7          	jalr	1532(ra) # 800019ac <myproc>
    800053b8:	fec42783          	lw	a5,-20(s0)
    800053bc:	07e9                	addi	a5,a5,26
    800053be:	078e                	slli	a5,a5,0x3
    800053c0:	953e                	add	a0,a0,a5
    800053c2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053c6:	fe043503          	ld	a0,-32(s0)
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	260080e7          	jalr	608(ra) # 8000462a <fileclose>
  return 0;
    800053d2:	4781                	li	a5,0
}
    800053d4:	853e                	mv	a0,a5
    800053d6:	60e2                	ld	ra,24(sp)
    800053d8:	6442                	ld	s0,16(sp)
    800053da:	6105                	addi	sp,sp,32
    800053dc:	8082                	ret

00000000800053de <sys_fstat>:
{
    800053de:	1101                	addi	sp,sp,-32
    800053e0:	ec06                	sd	ra,24(sp)
    800053e2:	e822                	sd	s0,16(sp)
    800053e4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053e6:	fe040593          	addi	a1,s0,-32
    800053ea:	4505                	li	a0,1
    800053ec:	ffffd097          	auipc	ra,0xffffd
    800053f0:	7fa080e7          	jalr	2042(ra) # 80002be6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053f4:	fe840613          	addi	a2,s0,-24
    800053f8:	4581                	li	a1,0
    800053fa:	4501                	li	a0,0
    800053fc:	00000097          	auipc	ra,0x0
    80005400:	c66080e7          	jalr	-922(ra) # 80005062 <argfd>
    80005404:	87aa                	mv	a5,a0
    return -1;
    80005406:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005408:	0007ca63          	bltz	a5,8000541c <sys_fstat+0x3e>
  return filestat(f, st);
    8000540c:	fe043583          	ld	a1,-32(s0)
    80005410:	fe843503          	ld	a0,-24(s0)
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	2de080e7          	jalr	734(ra) # 800046f2 <filestat>
}
    8000541c:	60e2                	ld	ra,24(sp)
    8000541e:	6442                	ld	s0,16(sp)
    80005420:	6105                	addi	sp,sp,32
    80005422:	8082                	ret

0000000080005424 <sys_link>:
{
    80005424:	7169                	addi	sp,sp,-304
    80005426:	f606                	sd	ra,296(sp)
    80005428:	f222                	sd	s0,288(sp)
    8000542a:	ee26                	sd	s1,280(sp)
    8000542c:	ea4a                	sd	s2,272(sp)
    8000542e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005430:	08000613          	li	a2,128
    80005434:	ed040593          	addi	a1,s0,-304
    80005438:	4501                	li	a0,0
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	7cc080e7          	jalr	1996(ra) # 80002c06 <argstr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005444:	10054e63          	bltz	a0,80005560 <sys_link+0x13c>
    80005448:	08000613          	li	a2,128
    8000544c:	f5040593          	addi	a1,s0,-176
    80005450:	4505                	li	a0,1
    80005452:	ffffd097          	auipc	ra,0xffffd
    80005456:	7b4080e7          	jalr	1972(ra) # 80002c06 <argstr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545c:	10054263          	bltz	a0,80005560 <sys_link+0x13c>
  begin_op();
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	d02080e7          	jalr	-766(ra) # 80004162 <begin_op>
  if((ip = namei(old)) == 0){
    80005468:	ed040513          	addi	a0,s0,-304
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	ad6080e7          	jalr	-1322(ra) # 80003f42 <namei>
    80005474:	84aa                	mv	s1,a0
    80005476:	c551                	beqz	a0,80005502 <sys_link+0xde>
  ilock(ip);
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	31e080e7          	jalr	798(ra) # 80003796 <ilock>
  if(ip->type == T_DIR){
    80005480:	04449703          	lh	a4,68(s1)
    80005484:	4785                	li	a5,1
    80005486:	08f70463          	beq	a4,a5,8000550e <sys_link+0xea>
  ip->nlink++;
    8000548a:	04a4d783          	lhu	a5,74(s1)
    8000548e:	2785                	addiw	a5,a5,1
    80005490:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	234080e7          	jalr	564(ra) # 800036ca <iupdate>
  iunlock(ip);
    8000549e:	8526                	mv	a0,s1
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	3b8080e7          	jalr	952(ra) # 80003858 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a8:	fd040593          	addi	a1,s0,-48
    800054ac:	f5040513          	addi	a0,s0,-176
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	ab0080e7          	jalr	-1360(ra) # 80003f60 <nameiparent>
    800054b8:	892a                	mv	s2,a0
    800054ba:	c935                	beqz	a0,8000552e <sys_link+0x10a>
  ilock(dp);
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	2da080e7          	jalr	730(ra) # 80003796 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c4:	00092703          	lw	a4,0(s2)
    800054c8:	409c                	lw	a5,0(s1)
    800054ca:	04f71d63          	bne	a4,a5,80005524 <sys_link+0x100>
    800054ce:	40d0                	lw	a2,4(s1)
    800054d0:	fd040593          	addi	a1,s0,-48
    800054d4:	854a                	mv	a0,s2
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	9ba080e7          	jalr	-1606(ra) # 80003e90 <dirlink>
    800054de:	04054363          	bltz	a0,80005524 <sys_link+0x100>
  iunlockput(dp);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	514080e7          	jalr	1300(ra) # 800039f8 <iunlockput>
  iput(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	462080e7          	jalr	1122(ra) # 80003950 <iput>
  end_op();
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	cea080e7          	jalr	-790(ra) # 800041e0 <end_op>
  return 0;
    800054fe:	4781                	li	a5,0
    80005500:	a085                	j	80005560 <sys_link+0x13c>
    end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cde080e7          	jalr	-802(ra) # 800041e0 <end_op>
    return -1;
    8000550a:	57fd                	li	a5,-1
    8000550c:	a891                	j	80005560 <sys_link+0x13c>
    iunlockput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4e8080e7          	jalr	1256(ra) # 800039f8 <iunlockput>
    end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cc8080e7          	jalr	-824(ra) # 800041e0 <end_op>
    return -1;
    80005520:	57fd                	li	a5,-1
    80005522:	a83d                	j	80005560 <sys_link+0x13c>
    iunlockput(dp);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	4d2080e7          	jalr	1234(ra) # 800039f8 <iunlockput>
  ilock(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	266080e7          	jalr	614(ra) # 80003796 <ilock>
  ip->nlink--;
    80005538:	04a4d783          	lhu	a5,74(s1)
    8000553c:	37fd                	addiw	a5,a5,-1
    8000553e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	186080e7          	jalr	390(ra) # 800036ca <iupdate>
  iunlockput(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	4aa080e7          	jalr	1194(ra) # 800039f8 <iunlockput>
  end_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	c8a080e7          	jalr	-886(ra) # 800041e0 <end_op>
  return -1;
    8000555e:	57fd                	li	a5,-1
}
    80005560:	853e                	mv	a0,a5
    80005562:	70b2                	ld	ra,296(sp)
    80005564:	7412                	ld	s0,288(sp)
    80005566:	64f2                	ld	s1,280(sp)
    80005568:	6952                	ld	s2,272(sp)
    8000556a:	6155                	addi	sp,sp,304
    8000556c:	8082                	ret

000000008000556e <sys_unlink>:
{
    8000556e:	7151                	addi	sp,sp,-240
    80005570:	f586                	sd	ra,232(sp)
    80005572:	f1a2                	sd	s0,224(sp)
    80005574:	eda6                	sd	s1,216(sp)
    80005576:	e9ca                	sd	s2,208(sp)
    80005578:	e5ce                	sd	s3,200(sp)
    8000557a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000557c:	08000613          	li	a2,128
    80005580:	f3040593          	addi	a1,s0,-208
    80005584:	4501                	li	a0,0
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	680080e7          	jalr	1664(ra) # 80002c06 <argstr>
    8000558e:	18054163          	bltz	a0,80005710 <sys_unlink+0x1a2>
  begin_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	bd0080e7          	jalr	-1072(ra) # 80004162 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000559a:	fb040593          	addi	a1,s0,-80
    8000559e:	f3040513          	addi	a0,s0,-208
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	9be080e7          	jalr	-1602(ra) # 80003f60 <nameiparent>
    800055aa:	84aa                	mv	s1,a0
    800055ac:	c979                	beqz	a0,80005682 <sys_unlink+0x114>
  ilock(dp);
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	1e8080e7          	jalr	488(ra) # 80003796 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b6:	00003597          	auipc	a1,0x3
    800055ba:	23258593          	addi	a1,a1,562 # 800087e8 <syscalls+0x2b0>
    800055be:	fb040513          	addi	a0,s0,-80
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	69e080e7          	jalr	1694(ra) # 80003c60 <namecmp>
    800055ca:	14050a63          	beqz	a0,8000571e <sys_unlink+0x1b0>
    800055ce:	00003597          	auipc	a1,0x3
    800055d2:	22258593          	addi	a1,a1,546 # 800087f0 <syscalls+0x2b8>
    800055d6:	fb040513          	addi	a0,s0,-80
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	686080e7          	jalr	1670(ra) # 80003c60 <namecmp>
    800055e2:	12050e63          	beqz	a0,8000571e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e6:	f2c40613          	addi	a2,s0,-212
    800055ea:	fb040593          	addi	a1,s0,-80
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	68a080e7          	jalr	1674(ra) # 80003c7a <dirlookup>
    800055f8:	892a                	mv	s2,a0
    800055fa:	12050263          	beqz	a0,8000571e <sys_unlink+0x1b0>
  ilock(ip);
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	198080e7          	jalr	408(ra) # 80003796 <ilock>
  if(ip->nlink < 1)
    80005606:	04a91783          	lh	a5,74(s2)
    8000560a:	08f05263          	blez	a5,8000568e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000560e:	04491703          	lh	a4,68(s2)
    80005612:	4785                	li	a5,1
    80005614:	08f70563          	beq	a4,a5,8000569e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005618:	4641                	li	a2,16
    8000561a:	4581                	li	a1,0
    8000561c:	fc040513          	addi	a0,s0,-64
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	6b2080e7          	jalr	1714(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005628:	4741                	li	a4,16
    8000562a:	f2c42683          	lw	a3,-212(s0)
    8000562e:	fc040613          	addi	a2,s0,-64
    80005632:	4581                	li	a1,0
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	50c080e7          	jalr	1292(ra) # 80003b42 <writei>
    8000563e:	47c1                	li	a5,16
    80005640:	0af51563          	bne	a0,a5,800056ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005644:	04491703          	lh	a4,68(s2)
    80005648:	4785                	li	a5,1
    8000564a:	0af70863          	beq	a4,a5,800056fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	3a8080e7          	jalr	936(ra) # 800039f8 <iunlockput>
  ip->nlink--;
    80005658:	04a95783          	lhu	a5,74(s2)
    8000565c:	37fd                	addiw	a5,a5,-1
    8000565e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	066080e7          	jalr	102(ra) # 800036ca <iupdate>
  iunlockput(ip);
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	38a080e7          	jalr	906(ra) # 800039f8 <iunlockput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	b6a080e7          	jalr	-1174(ra) # 800041e0 <end_op>
  return 0;
    8000567e:	4501                	li	a0,0
    80005680:	a84d                	j	80005732 <sys_unlink+0x1c4>
    end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	b5e080e7          	jalr	-1186(ra) # 800041e0 <end_op>
    return -1;
    8000568a:	557d                	li	a0,-1
    8000568c:	a05d                	j	80005732 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000568e:	00003517          	auipc	a0,0x3
    80005692:	16a50513          	addi	a0,a0,362 # 800087f8 <syscalls+0x2c0>
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	eaa080e7          	jalr	-342(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569e:	04c92703          	lw	a4,76(s2)
    800056a2:	02000793          	li	a5,32
    800056a6:	f6e7f9e3          	bgeu	a5,a4,80005618 <sys_unlink+0xaa>
    800056aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ae:	4741                	li	a4,16
    800056b0:	86ce                	mv	a3,s3
    800056b2:	f1840613          	addi	a2,s0,-232
    800056b6:	4581                	li	a1,0
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	390080e7          	jalr	912(ra) # 80003a4a <readi>
    800056c2:	47c1                	li	a5,16
    800056c4:	00f51b63          	bne	a0,a5,800056da <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c8:	f1845783          	lhu	a5,-232(s0)
    800056cc:	e7a1                	bnez	a5,80005714 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ce:	29c1                	addiw	s3,s3,16
    800056d0:	04c92783          	lw	a5,76(s2)
    800056d4:	fcf9ede3          	bltu	s3,a5,800056ae <sys_unlink+0x140>
    800056d8:	b781                	j	80005618 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056da:	00003517          	auipc	a0,0x3
    800056de:	13650513          	addi	a0,a0,310 # 80008810 <syscalls+0x2d8>
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	e5e080e7          	jalr	-418(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056ea:	00003517          	auipc	a0,0x3
    800056ee:	13e50513          	addi	a0,a0,318 # 80008828 <syscalls+0x2f0>
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	e4e080e7          	jalr	-434(ra) # 80000540 <panic>
    dp->nlink--;
    800056fa:	04a4d783          	lhu	a5,74(s1)
    800056fe:	37fd                	addiw	a5,a5,-1
    80005700:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005704:	8526                	mv	a0,s1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	fc4080e7          	jalr	-60(ra) # 800036ca <iupdate>
    8000570e:	b781                	j	8000564e <sys_unlink+0xe0>
    return -1;
    80005710:	557d                	li	a0,-1
    80005712:	a005                	j	80005732 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005714:	854a                	mv	a0,s2
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	2e2080e7          	jalr	738(ra) # 800039f8 <iunlockput>
  iunlockput(dp);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	2d8080e7          	jalr	728(ra) # 800039f8 <iunlockput>
  end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	ab8080e7          	jalr	-1352(ra) # 800041e0 <end_op>
  return -1;
    80005730:	557d                	li	a0,-1
}
    80005732:	70ae                	ld	ra,232(sp)
    80005734:	740e                	ld	s0,224(sp)
    80005736:	64ee                	ld	s1,216(sp)
    80005738:	694e                	ld	s2,208(sp)
    8000573a:	69ae                	ld	s3,200(sp)
    8000573c:	616d                	addi	sp,sp,240
    8000573e:	8082                	ret

0000000080005740 <sys_open>:

uint64
sys_open(void)
{
    80005740:	7131                	addi	sp,sp,-192
    80005742:	fd06                	sd	ra,184(sp)
    80005744:	f922                	sd	s0,176(sp)
    80005746:	f526                	sd	s1,168(sp)
    80005748:	f14a                	sd	s2,160(sp)
    8000574a:	ed4e                	sd	s3,152(sp)
    8000574c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000574e:	f4c40593          	addi	a1,s0,-180
    80005752:	4505                	li	a0,1
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	472080e7          	jalr	1138(ra) # 80002bc6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575c:	08000613          	li	a2,128
    80005760:	f5040593          	addi	a1,s0,-176
    80005764:	4501                	li	a0,0
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	4a0080e7          	jalr	1184(ra) # 80002c06 <argstr>
    8000576e:	87aa                	mv	a5,a0
    return -1;
    80005770:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005772:	0a07c963          	bltz	a5,80005824 <sys_open+0xe4>

  begin_op();
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	9ec080e7          	jalr	-1556(ra) # 80004162 <begin_op>

  if(omode & O_CREATE){
    8000577e:	f4c42783          	lw	a5,-180(s0)
    80005782:	2007f793          	andi	a5,a5,512
    80005786:	cfc5                	beqz	a5,8000583e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005788:	4681                	li	a3,0
    8000578a:	4601                	li	a2,0
    8000578c:	4589                	li	a1,2
    8000578e:	f5040513          	addi	a0,s0,-176
    80005792:	00000097          	auipc	ra,0x0
    80005796:	972080e7          	jalr	-1678(ra) # 80005104 <create>
    8000579a:	84aa                	mv	s1,a0
    if(ip == 0){
    8000579c:	c959                	beqz	a0,80005832 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000579e:	04449703          	lh	a4,68(s1)
    800057a2:	478d                	li	a5,3
    800057a4:	00f71763          	bne	a4,a5,800057b2 <sys_open+0x72>
    800057a8:	0464d703          	lhu	a4,70(s1)
    800057ac:	47a5                	li	a5,9
    800057ae:	0ce7ed63          	bltu	a5,a4,80005888 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	dbc080e7          	jalr	-580(ra) # 8000456e <filealloc>
    800057ba:	89aa                	mv	s3,a0
    800057bc:	10050363          	beqz	a0,800058c2 <sys_open+0x182>
    800057c0:	00000097          	auipc	ra,0x0
    800057c4:	902080e7          	jalr	-1790(ra) # 800050c2 <fdalloc>
    800057c8:	892a                	mv	s2,a0
    800057ca:	0e054763          	bltz	a0,800058b8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ce:	04449703          	lh	a4,68(s1)
    800057d2:	478d                	li	a5,3
    800057d4:	0cf70563          	beq	a4,a5,8000589e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d8:	4789                	li	a5,2
    800057da:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057de:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057e2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e6:	f4c42783          	lw	a5,-180(s0)
    800057ea:	0017c713          	xori	a4,a5,1
    800057ee:	8b05                	andi	a4,a4,1
    800057f0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f4:	0037f713          	andi	a4,a5,3
    800057f8:	00e03733          	snez	a4,a4
    800057fc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005800:	4007f793          	andi	a5,a5,1024
    80005804:	c791                	beqz	a5,80005810 <sys_open+0xd0>
    80005806:	04449703          	lh	a4,68(s1)
    8000580a:	4789                	li	a5,2
    8000580c:	0af70063          	beq	a4,a5,800058ac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	046080e7          	jalr	70(ra) # 80003858 <iunlock>
  end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	9c6080e7          	jalr	-1594(ra) # 800041e0 <end_op>

  return fd;
    80005822:	854a                	mv	a0,s2
}
    80005824:	70ea                	ld	ra,184(sp)
    80005826:	744a                	ld	s0,176(sp)
    80005828:	74aa                	ld	s1,168(sp)
    8000582a:	790a                	ld	s2,160(sp)
    8000582c:	69ea                	ld	s3,152(sp)
    8000582e:	6129                	addi	sp,sp,192
    80005830:	8082                	ret
      end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9ae080e7          	jalr	-1618(ra) # 800041e0 <end_op>
      return -1;
    8000583a:	557d                	li	a0,-1
    8000583c:	b7e5                	j	80005824 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000583e:	f5040513          	addi	a0,s0,-176
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	700080e7          	jalr	1792(ra) # 80003f42 <namei>
    8000584a:	84aa                	mv	s1,a0
    8000584c:	c905                	beqz	a0,8000587c <sys_open+0x13c>
    ilock(ip);
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	f48080e7          	jalr	-184(ra) # 80003796 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005856:	04449703          	lh	a4,68(s1)
    8000585a:	4785                	li	a5,1
    8000585c:	f4f711e3          	bne	a4,a5,8000579e <sys_open+0x5e>
    80005860:	f4c42783          	lw	a5,-180(s0)
    80005864:	d7b9                	beqz	a5,800057b2 <sys_open+0x72>
      iunlockput(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	190080e7          	jalr	400(ra) # 800039f8 <iunlockput>
      end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	970080e7          	jalr	-1680(ra) # 800041e0 <end_op>
      return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	b76d                	j	80005824 <sys_open+0xe4>
      end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	964080e7          	jalr	-1692(ra) # 800041e0 <end_op>
      return -1;
    80005884:	557d                	li	a0,-1
    80005886:	bf79                	j	80005824 <sys_open+0xe4>
    iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	16e080e7          	jalr	366(ra) # 800039f8 <iunlockput>
    end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	94e080e7          	jalr	-1714(ra) # 800041e0 <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b761                	j	80005824 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000589e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058a2:	04649783          	lh	a5,70(s1)
    800058a6:	02f99223          	sh	a5,36(s3)
    800058aa:	bf25                	j	800057e2 <sys_open+0xa2>
    itrunc(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	ff6080e7          	jalr	-10(ra) # 800038a4 <itrunc>
    800058b6:	bfa9                	j	80005810 <sys_open+0xd0>
      fileclose(f);
    800058b8:	854e                	mv	a0,s3
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	d70080e7          	jalr	-656(ra) # 8000462a <fileclose>
    iunlockput(ip);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	134080e7          	jalr	308(ra) # 800039f8 <iunlockput>
    end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	914080e7          	jalr	-1772(ra) # 800041e0 <end_op>
    return -1;
    800058d4:	557d                	li	a0,-1
    800058d6:	b7b9                	j	80005824 <sys_open+0xe4>

00000000800058d8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d8:	7175                	addi	sp,sp,-144
    800058da:	e506                	sd	ra,136(sp)
    800058dc:	e122                	sd	s0,128(sp)
    800058de:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	882080e7          	jalr	-1918(ra) # 80004162 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e8:	08000613          	li	a2,128
    800058ec:	f7040593          	addi	a1,s0,-144
    800058f0:	4501                	li	a0,0
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	314080e7          	jalr	788(ra) # 80002c06 <argstr>
    800058fa:	02054963          	bltz	a0,8000592c <sys_mkdir+0x54>
    800058fe:	4681                	li	a3,0
    80005900:	4601                	li	a2,0
    80005902:	4585                	li	a1,1
    80005904:	f7040513          	addi	a0,s0,-144
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	7fc080e7          	jalr	2044(ra) # 80005104 <create>
    80005910:	cd11                	beqz	a0,8000592c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	0e6080e7          	jalr	230(ra) # 800039f8 <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	8c6080e7          	jalr	-1850(ra) # 800041e0 <end_op>
  return 0;
    80005922:	4501                	li	a0,0
}
    80005924:	60aa                	ld	ra,136(sp)
    80005926:	640a                	ld	s0,128(sp)
    80005928:	6149                	addi	sp,sp,144
    8000592a:	8082                	ret
    end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	8b4080e7          	jalr	-1868(ra) # 800041e0 <end_op>
    return -1;
    80005934:	557d                	li	a0,-1
    80005936:	b7fd                	j	80005924 <sys_mkdir+0x4c>

0000000080005938 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005938:	7135                	addi	sp,sp,-160
    8000593a:	ed06                	sd	ra,152(sp)
    8000593c:	e922                	sd	s0,144(sp)
    8000593e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	822080e7          	jalr	-2014(ra) # 80004162 <begin_op>
  argint(1, &major);
    80005948:	f6c40593          	addi	a1,s0,-148
    8000594c:	4505                	li	a0,1
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	278080e7          	jalr	632(ra) # 80002bc6 <argint>
  argint(2, &minor);
    80005956:	f6840593          	addi	a1,s0,-152
    8000595a:	4509                	li	a0,2
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	26a080e7          	jalr	618(ra) # 80002bc6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005964:	08000613          	li	a2,128
    80005968:	f7040593          	addi	a1,s0,-144
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	298080e7          	jalr	664(ra) # 80002c06 <argstr>
    80005976:	02054b63          	bltz	a0,800059ac <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597a:	f6841683          	lh	a3,-152(s0)
    8000597e:	f6c41603          	lh	a2,-148(s0)
    80005982:	458d                	li	a1,3
    80005984:	f7040513          	addi	a0,s0,-144
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	77c080e7          	jalr	1916(ra) # 80005104 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005990:	cd11                	beqz	a0,800059ac <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	066080e7          	jalr	102(ra) # 800039f8 <iunlockput>
  end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	846080e7          	jalr	-1978(ra) # 800041e0 <end_op>
  return 0;
    800059a2:	4501                	li	a0,0
}
    800059a4:	60ea                	ld	ra,152(sp)
    800059a6:	644a                	ld	s0,144(sp)
    800059a8:	610d                	addi	sp,sp,160
    800059aa:	8082                	ret
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	834080e7          	jalr	-1996(ra) # 800041e0 <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	b7fd                	j	800059a4 <sys_mknod+0x6c>

00000000800059b8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b8:	7135                	addi	sp,sp,-160
    800059ba:	ed06                	sd	ra,152(sp)
    800059bc:	e922                	sd	s0,144(sp)
    800059be:	e526                	sd	s1,136(sp)
    800059c0:	e14a                	sd	s2,128(sp)
    800059c2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c4:	ffffc097          	auipc	ra,0xffffc
    800059c8:	fe8080e7          	jalr	-24(ra) # 800019ac <myproc>
    800059cc:	892a                	mv	s2,a0
  
  begin_op();
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	794080e7          	jalr	1940(ra) # 80004162 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d6:	08000613          	li	a2,128
    800059da:	f6040593          	addi	a1,s0,-160
    800059de:	4501                	li	a0,0
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	226080e7          	jalr	550(ra) # 80002c06 <argstr>
    800059e8:	04054b63          	bltz	a0,80005a3e <sys_chdir+0x86>
    800059ec:	f6040513          	addi	a0,s0,-160
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	552080e7          	jalr	1362(ra) # 80003f42 <namei>
    800059f8:	84aa                	mv	s1,a0
    800059fa:	c131                	beqz	a0,80005a3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	d9a080e7          	jalr	-614(ra) # 80003796 <ilock>
  if(ip->type != T_DIR){
    80005a04:	04449703          	lh	a4,68(s1)
    80005a08:	4785                	li	a5,1
    80005a0a:	04f71063          	bne	a4,a5,80005a4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	e48080e7          	jalr	-440(ra) # 80003858 <iunlock>
  iput(p->cwd);
    80005a18:	15093503          	ld	a0,336(s2)
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	f34080e7          	jalr	-204(ra) # 80003950 <iput>
  end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	7bc080e7          	jalr	1980(ra) # 800041e0 <end_op>
  p->cwd = ip;
    80005a2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a30:	4501                	li	a0,0
}
    80005a32:	60ea                	ld	ra,152(sp)
    80005a34:	644a                	ld	s0,144(sp)
    80005a36:	64aa                	ld	s1,136(sp)
    80005a38:	690a                	ld	s2,128(sp)
    80005a3a:	610d                	addi	sp,sp,160
    80005a3c:	8082                	ret
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	7a2080e7          	jalr	1954(ra) # 800041e0 <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	b7ed                	j	80005a32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	fac080e7          	jalr	-84(ra) # 800039f8 <iunlockput>
    end_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	78c080e7          	jalr	1932(ra) # 800041e0 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	bfd1                	j	80005a32 <sys_chdir+0x7a>

0000000080005a60 <sys_exec>:

uint64
sys_exec(void)
{
    80005a60:	7145                	addi	sp,sp,-464
    80005a62:	e786                	sd	ra,456(sp)
    80005a64:	e3a2                	sd	s0,448(sp)
    80005a66:	ff26                	sd	s1,440(sp)
    80005a68:	fb4a                	sd	s2,432(sp)
    80005a6a:	f74e                	sd	s3,424(sp)
    80005a6c:	f352                	sd	s4,416(sp)
    80005a6e:	ef56                	sd	s5,408(sp)
    80005a70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a72:	e3840593          	addi	a1,s0,-456
    80005a76:	4505                	li	a0,1
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	16e080e7          	jalr	366(ra) # 80002be6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a80:	08000613          	li	a2,128
    80005a84:	f4040593          	addi	a1,s0,-192
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	17c080e7          	jalr	380(ra) # 80002c06 <argstr>
    80005a92:	87aa                	mv	a5,a0
    return -1;
    80005a94:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a96:	0c07c363          	bltz	a5,80005b5c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a9a:	10000613          	li	a2,256
    80005a9e:	4581                	li	a1,0
    80005aa0:	e4040513          	addi	a0,s0,-448
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	22e080e7          	jalr	558(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab0:	89a6                	mv	s3,s1
    80005ab2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab4:	02000a13          	li	s4,32
    80005ab8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005abc:	00391513          	slli	a0,s2,0x3
    80005ac0:	e3040593          	addi	a1,s0,-464
    80005ac4:	e3843783          	ld	a5,-456(s0)
    80005ac8:	953e                	add	a0,a0,a5
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	05e080e7          	jalr	94(ra) # 80002b28 <fetchaddr>
    80005ad2:	02054a63          	bltz	a0,80005b06 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ad6:	e3043783          	ld	a5,-464(s0)
    80005ada:	c3b9                	beqz	a5,80005b20 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	00a080e7          	jalr	10(ra) # 80000ae6 <kalloc>
    80005ae4:	85aa                	mv	a1,a0
    80005ae6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aea:	cd11                	beqz	a0,80005b06 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aec:	6605                	lui	a2,0x1
    80005aee:	e3043503          	ld	a0,-464(s0)
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	088080e7          	jalr	136(ra) # 80002b7a <fetchstr>
    80005afa:	00054663          	bltz	a0,80005b06 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005afe:	0905                	addi	s2,s2,1
    80005b00:	09a1                	addi	s3,s3,8
    80005b02:	fb491be3          	bne	s2,s4,80005ab8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	f4040913          	addi	s2,s0,-192
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c539                	beqz	a0,80005b5a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	eda080e7          	jalr	-294(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff2499e3          	bne	s1,s2,80005b0a <sys_exec+0xaa>
  return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	a83d                	j	80005b5c <sys_exec+0xfc>
      argv[i] = 0;
    80005b20:	0a8e                	slli	s5,s5,0x3
    80005b22:	fc0a8793          	addi	a5,s5,-64
    80005b26:	00878ab3          	add	s5,a5,s0
    80005b2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2e:	e4040593          	addi	a1,s0,-448
    80005b32:	f4040513          	addi	a0,s0,-192
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	16e080e7          	jalr	366(ra) # 80004ca4 <exec>
    80005b3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	f4040993          	addi	s3,s0,-192
    80005b44:	6088                	ld	a0,0(s1)
    80005b46:	c901                	beqz	a0,80005b56 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	ea0080e7          	jalr	-352(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b50:	04a1                	addi	s1,s1,8
    80005b52:	ff3499e3          	bne	s1,s3,80005b44 <sys_exec+0xe4>
  return ret;
    80005b56:	854a                	mv	a0,s2
    80005b58:	a011                	j	80005b5c <sys_exec+0xfc>
  return -1;
    80005b5a:	557d                	li	a0,-1
}
    80005b5c:	60be                	ld	ra,456(sp)
    80005b5e:	641e                	ld	s0,448(sp)
    80005b60:	74fa                	ld	s1,440(sp)
    80005b62:	795a                	ld	s2,432(sp)
    80005b64:	79ba                	ld	s3,424(sp)
    80005b66:	7a1a                	ld	s4,416(sp)
    80005b68:	6afa                	ld	s5,408(sp)
    80005b6a:	6179                	addi	sp,sp,464
    80005b6c:	8082                	ret

0000000080005b6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6e:	7139                	addi	sp,sp,-64
    80005b70:	fc06                	sd	ra,56(sp)
    80005b72:	f822                	sd	s0,48(sp)
    80005b74:	f426                	sd	s1,40(sp)
    80005b76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	e34080e7          	jalr	-460(ra) # 800019ac <myproc>
    80005b80:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b82:	fd840593          	addi	a1,s0,-40
    80005b86:	4501                	li	a0,0
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	05e080e7          	jalr	94(ra) # 80002be6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b90:	fc840593          	addi	a1,s0,-56
    80005b94:	fd040513          	addi	a0,s0,-48
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	dc2080e7          	jalr	-574(ra) # 8000495a <pipealloc>
    return -1;
    80005ba0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba2:	0c054463          	bltz	a0,80005c6a <sys_pipe+0xfc>
  fd0 = -1;
    80005ba6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005baa:	fd043503          	ld	a0,-48(s0)
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	514080e7          	jalr	1300(ra) # 800050c2 <fdalloc>
    80005bb6:	fca42223          	sw	a0,-60(s0)
    80005bba:	08054b63          	bltz	a0,80005c50 <sys_pipe+0xe2>
    80005bbe:	fc843503          	ld	a0,-56(s0)
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	500080e7          	jalr	1280(ra) # 800050c2 <fdalloc>
    80005bca:	fca42023          	sw	a0,-64(s0)
    80005bce:	06054863          	bltz	a0,80005c3e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd2:	4691                	li	a3,4
    80005bd4:	fc440613          	addi	a2,s0,-60
    80005bd8:	fd843583          	ld	a1,-40(s0)
    80005bdc:	68a8                	ld	a0,80(s1)
    80005bde:	ffffc097          	auipc	ra,0xffffc
    80005be2:	a8e080e7          	jalr	-1394(ra) # 8000166c <copyout>
    80005be6:	02054063          	bltz	a0,80005c06 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bea:	4691                	li	a3,4
    80005bec:	fc040613          	addi	a2,s0,-64
    80005bf0:	fd843583          	ld	a1,-40(s0)
    80005bf4:	0591                	addi	a1,a1,4
    80005bf6:	68a8                	ld	a0,80(s1)
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	a74080e7          	jalr	-1420(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c00:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c02:	06055463          	bgez	a0,80005c6a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c06:	fc442783          	lw	a5,-60(s0)
    80005c0a:	07e9                	addi	a5,a5,26
    80005c0c:	078e                	slli	a5,a5,0x3
    80005c0e:	97a6                	add	a5,a5,s1
    80005c10:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c14:	fc042783          	lw	a5,-64(s0)
    80005c18:	07e9                	addi	a5,a5,26
    80005c1a:	078e                	slli	a5,a5,0x3
    80005c1c:	94be                	add	s1,s1,a5
    80005c1e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c22:	fd043503          	ld	a0,-48(s0)
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	a04080e7          	jalr	-1532(ra) # 8000462a <fileclose>
    fileclose(wf);
    80005c2e:	fc843503          	ld	a0,-56(s0)
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	9f8080e7          	jalr	-1544(ra) # 8000462a <fileclose>
    return -1;
    80005c3a:	57fd                	li	a5,-1
    80005c3c:	a03d                	j	80005c6a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c3e:	fc442783          	lw	a5,-60(s0)
    80005c42:	0007c763          	bltz	a5,80005c50 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c46:	07e9                	addi	a5,a5,26
    80005c48:	078e                	slli	a5,a5,0x3
    80005c4a:	97a6                	add	a5,a5,s1
    80005c4c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c50:	fd043503          	ld	a0,-48(s0)
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	9d6080e7          	jalr	-1578(ra) # 8000462a <fileclose>
    fileclose(wf);
    80005c5c:	fc843503          	ld	a0,-56(s0)
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	9ca080e7          	jalr	-1590(ra) # 8000462a <fileclose>
    return -1;
    80005c68:	57fd                	li	a5,-1
}
    80005c6a:	853e                	mv	a0,a5
    80005c6c:	70e2                	ld	ra,56(sp)
    80005c6e:	7442                	ld	s0,48(sp)
    80005c70:	74a2                	ld	s1,40(sp)
    80005c72:	6121                	addi	sp,sp,64
    80005c74:	8082                	ret
	...

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	d35fc0ef          	jal	ra,800029f4 <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c28080e7          	jalr	-984(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	97aa                	add	a5,a5,a0
    80005d7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	bf0080e7          	jalr	-1040(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5151b          	slliw	a0,a0,0xd
    80005d9c:	0c2017b7          	lui	a5,0xc201
    80005da0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005da2:	43c8                	lw	a0,4(a5)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bc8080e7          	jalr	-1080(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	04a7cc63          	blt	a5,a0,80005e38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001c797          	auipc	a5,0x1c
    80005de8:	f3c78793          	addi	a5,a5,-196 # 80021d20 <disk>
    80005dec:	97aa                	add	a5,a5,a0
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	ebb9                	bnez	a5,80005e48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005df4:	00451693          	slli	a3,a0,0x4
    80005df8:	0001c797          	auipc	a5,0x1c
    80005dfc:	f2878793          	addi	a5,a5,-216 # 80021d20 <disk>
    80005e00:	6398                	ld	a4,0(a5)
    80005e02:	9736                	add	a4,a4,a3
    80005e04:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e08:	6398                	ld	a4,0(a5)
    80005e0a:	9736                	add	a4,a4,a3
    80005e0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	4705                	li	a4,1
    80005e1c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e20:	0001c517          	auipc	a0,0x1c
    80005e24:	f1850513          	addi	a0,a0,-232 # 80021d38 <disk+0x18>
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	290080e7          	jalr	656(ra) # 800020b8 <wakeup>
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret
    panic("free_desc 1");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	a0050513          	addi	a0,a0,-1536 # 80008838 <syscalls+0x300>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	700080e7          	jalr	1792(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	a0050513          	addi	a0,a0,-1536 # 80008848 <syscalls+0x310>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>

0000000080005e58 <virtio_disk_init>:
{
    80005e58:	1101                	addi	sp,sp,-32
    80005e5a:	ec06                	sd	ra,24(sp)
    80005e5c:	e822                	sd	s0,16(sp)
    80005e5e:	e426                	sd	s1,8(sp)
    80005e60:	e04a                	sd	s2,0(sp)
    80005e62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e64:	00003597          	auipc	a1,0x3
    80005e68:	9f458593          	addi	a1,a1,-1548 # 80008858 <syscalls+0x320>
    80005e6c:	0001c517          	auipc	a0,0x1c
    80005e70:	fdc50513          	addi	a0,a0,-36 # 80021e48 <disk+0x128>
    80005e74:	ffffb097          	auipc	ra,0xffffb
    80005e78:	cd2080e7          	jalr	-814(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	4398                	lw	a4,0(a5)
    80005e82:	2701                	sext.w	a4,a4
    80005e84:	747277b7          	lui	a5,0x74727
    80005e88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e8c:	14f71b63          	bne	a4,a5,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e90:	100017b7          	lui	a5,0x10001
    80005e94:	43dc                	lw	a5,4(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e98:	4709                	li	a4,2
    80005e9a:	14e79463          	bne	a5,a4,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	479c                	lw	a5,8(a5)
    80005ea4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea6:	12e79e63          	bne	a5,a4,80005fe2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eaa:	100017b7          	lui	a5,0x10001
    80005eae:	47d8                	lw	a4,12(a5)
    80005eb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb2:	554d47b7          	lui	a5,0x554d4
    80005eb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eba:	12f71463          	bne	a4,a5,80005fe2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec6:	4705                	li	a4,1
    80005ec8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	470d                	li	a4,3
    80005ecc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ece:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ed4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc8ff>
    80005ed8:	8f75                	and	a4,a4,a3
    80005eda:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005edc:	472d                	li	a4,11
    80005ede:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ee0:	5bbc                	lw	a5,112(a5)
    80005ee2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ee6:	8ba1                	andi	a5,a5,8
    80005ee8:	10078563          	beqz	a5,80005ff2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ef4:	43fc                	lw	a5,68(a5)
    80005ef6:	2781                	sext.w	a5,a5
    80005ef8:	10079563          	bnez	a5,80006002 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	5bdc                	lw	a5,52(a5)
    80005f02:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f04:	10078763          	beqz	a5,80006012 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f08:	471d                	li	a4,7
    80005f0a:	10f77c63          	bgeu	a4,a5,80006022 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	bd8080e7          	jalr	-1064(ra) # 80000ae6 <kalloc>
    80005f16:	0001c497          	auipc	s1,0x1c
    80005f1a:	e0a48493          	addi	s1,s1,-502 # 80021d20 <disk>
    80005f1e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	bc6080e7          	jalr	-1082(ra) # 80000ae6 <kalloc>
    80005f28:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	bbc080e7          	jalr	-1092(ra) # 80000ae6 <kalloc>
    80005f32:	87aa                	mv	a5,a0
    80005f34:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f36:	6088                	ld	a0,0(s1)
    80005f38:	cd6d                	beqz	a0,80006032 <virtio_disk_init+0x1da>
    80005f3a:	0001c717          	auipc	a4,0x1c
    80005f3e:	dee73703          	ld	a4,-530(a4) # 80021d28 <disk+0x8>
    80005f42:	cb65                	beqz	a4,80006032 <virtio_disk_init+0x1da>
    80005f44:	c7fd                	beqz	a5,80006032 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f46:	6605                	lui	a2,0x1
    80005f48:	4581                	li	a1,0
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	d88080e7          	jalr	-632(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f52:	0001c497          	auipc	s1,0x1c
    80005f56:	dce48493          	addi	s1,s1,-562 # 80021d20 <disk>
    80005f5a:	6605                	lui	a2,0x1
    80005f5c:	4581                	li	a1,0
    80005f5e:	6488                	ld	a0,8(s1)
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	d72080e7          	jalr	-654(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f68:	6605                	lui	a2,0x1
    80005f6a:	4581                	li	a1,0
    80005f6c:	6888                	ld	a0,16(s1)
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	d64080e7          	jalr	-668(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f76:	100017b7          	lui	a5,0x10001
    80005f7a:	4721                	li	a4,8
    80005f7c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f7e:	4098                	lw	a4,0(s1)
    80005f80:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f84:	40d8                	lw	a4,4(s1)
    80005f86:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f8a:	6498                	ld	a4,8(s1)
    80005f8c:	0007069b          	sext.w	a3,a4
    80005f90:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f94:	9701                	srai	a4,a4,0x20
    80005f96:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f9a:	6898                	ld	a4,16(s1)
    80005f9c:	0007069b          	sext.w	a3,a4
    80005fa0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fa4:	9701                	srai	a4,a4,0x20
    80005fa6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005faa:	4705                	li	a4,1
    80005fac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fae:	00e48c23          	sb	a4,24(s1)
    80005fb2:	00e48ca3          	sb	a4,25(s1)
    80005fb6:	00e48d23          	sb	a4,26(s1)
    80005fba:	00e48da3          	sb	a4,27(s1)
    80005fbe:	00e48e23          	sb	a4,28(s1)
    80005fc2:	00e48ea3          	sb	a4,29(s1)
    80005fc6:	00e48f23          	sb	a4,30(s1)
    80005fca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd2:	0727a823          	sw	s2,112(a5)
}
    80005fd6:	60e2                	ld	ra,24(sp)
    80005fd8:	6442                	ld	s0,16(sp)
    80005fda:	64a2                	ld	s1,8(sp)
    80005fdc:	6902                	ld	s2,0(sp)
    80005fde:	6105                	addi	sp,sp,32
    80005fe0:	8082                	ret
    panic("could not find virtio disk");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	88650513          	addi	a0,a0,-1914 # 80008868 <syscalls+0x330>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	89650513          	addi	a0,a0,-1898 # 80008888 <syscalls+0x350>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	8a650513          	addi	a0,a0,-1882 # 800088a8 <syscalls+0x370>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	8b650513          	addi	a0,a0,-1866 # 800088c8 <syscalls+0x390>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	8c650513          	addi	a0,a0,-1850 # 800088e8 <syscalls+0x3b0>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006032:	00003517          	auipc	a0,0x3
    80006036:	8d650513          	addi	a0,a0,-1834 # 80008908 <syscalls+0x3d0>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	506080e7          	jalr	1286(ra) # 80000540 <panic>

0000000080006042 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006042:	7119                	addi	sp,sp,-128
    80006044:	fc86                	sd	ra,120(sp)
    80006046:	f8a2                	sd	s0,112(sp)
    80006048:	f4a6                	sd	s1,104(sp)
    8000604a:	f0ca                	sd	s2,96(sp)
    8000604c:	ecce                	sd	s3,88(sp)
    8000604e:	e8d2                	sd	s4,80(sp)
    80006050:	e4d6                	sd	s5,72(sp)
    80006052:	e0da                	sd	s6,64(sp)
    80006054:	fc5e                	sd	s7,56(sp)
    80006056:	f862                	sd	s8,48(sp)
    80006058:	f466                	sd	s9,40(sp)
    8000605a:	f06a                	sd	s10,32(sp)
    8000605c:	ec6e                	sd	s11,24(sp)
    8000605e:	0100                	addi	s0,sp,128
    80006060:	8aaa                	mv	s5,a0
    80006062:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006064:	00c52d03          	lw	s10,12(a0)
    80006068:	001d1d1b          	slliw	s10,s10,0x1
    8000606c:	1d02                	slli	s10,s10,0x20
    8000606e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006072:	0001c517          	auipc	a0,0x1c
    80006076:	dd650513          	addi	a0,a0,-554 # 80021e48 <disk+0x128>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	b5c080e7          	jalr	-1188(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006082:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006084:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006086:	0001cb97          	auipc	s7,0x1c
    8000608a:	c9ab8b93          	addi	s7,s7,-870 # 80021d20 <disk>
  for(int i = 0; i < 3; i++){
    8000608e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006090:	0001cc97          	auipc	s9,0x1c
    80006094:	db8c8c93          	addi	s9,s9,-584 # 80021e48 <disk+0x128>
    80006098:	a08d                	j	800060fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000609a:	00fb8733          	add	a4,s7,a5
    8000609e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060a4:	0207c563          	bltz	a5,800060ce <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060a8:	2905                	addiw	s2,s2,1
    800060aa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800060ac:	05690c63          	beq	s2,s6,80006104 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060b2:	0001c717          	auipc	a4,0x1c
    800060b6:	c6e70713          	addi	a4,a4,-914 # 80021d20 <disk>
    800060ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060bc:	01874683          	lbu	a3,24(a4)
    800060c0:	fee9                	bnez	a3,8000609a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	0705                	addi	a4,a4,1
    800060c6:	fe979be3          	bne	a5,s1,800060bc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060ca:	57fd                	li	a5,-1
    800060cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ce:	01205d63          	blez	s2,800060e8 <virtio_disk_rw+0xa6>
    800060d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060d4:	000a2503          	lw	a0,0(s4)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	cfe080e7          	jalr	-770(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	2d85                	addiw	s11,s11,1
    800060e2:	0a11                	addi	s4,s4,4
    800060e4:	ff2d98e3          	bne	s11,s2,800060d4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060e8:	85e6                	mv	a1,s9
    800060ea:	0001c517          	auipc	a0,0x1c
    800060ee:	c4e50513          	addi	a0,a0,-946 # 80021d38 <disk+0x18>
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	f62080e7          	jalr	-158(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    800060fa:	f8040a13          	addi	s4,s0,-128
{
    800060fe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006100:	894e                	mv	s2,s3
    80006102:	b77d                	j	800060b0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006104:	f8042503          	lw	a0,-128(s0)
    80006108:	00a50713          	addi	a4,a0,10
    8000610c:	0712                	slli	a4,a4,0x4

  if(write)
    8000610e:	0001c797          	auipc	a5,0x1c
    80006112:	c1278793          	addi	a5,a5,-1006 # 80021d20 <disk>
    80006116:	00e786b3          	add	a3,a5,a4
    8000611a:	01803633          	snez	a2,s8
    8000611e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006120:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006124:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006128:	f6070613          	addi	a2,a4,-160
    8000612c:	6394                	ld	a3,0(a5)
    8000612e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006130:	00870593          	addi	a1,a4,8
    80006134:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006136:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006138:	0007b803          	ld	a6,0(a5)
    8000613c:	9642                	add	a2,a2,a6
    8000613e:	46c1                	li	a3,16
    80006140:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006142:	4585                	li	a1,1
    80006144:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006148:	f8442683          	lw	a3,-124(s0)
    8000614c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006150:	0692                	slli	a3,a3,0x4
    80006152:	9836                	add	a6,a6,a3
    80006154:	058a8613          	addi	a2,s5,88
    80006158:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000615c:	0007b803          	ld	a6,0(a5)
    80006160:	96c2                	add	a3,a3,a6
    80006162:	40000613          	li	a2,1024
    80006166:	c690                	sw	a2,8(a3)
  if(write)
    80006168:	001c3613          	seqz	a2,s8
    8000616c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006170:	00166613          	ori	a2,a2,1
    80006174:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006178:	f8842603          	lw	a2,-120(s0)
    8000617c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006180:	00250693          	addi	a3,a0,2
    80006184:	0692                	slli	a3,a3,0x4
    80006186:	96be                	add	a3,a3,a5
    80006188:	58fd                	li	a7,-1
    8000618a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000618e:	0612                	slli	a2,a2,0x4
    80006190:	9832                	add	a6,a6,a2
    80006192:	f9070713          	addi	a4,a4,-112
    80006196:	973e                	add	a4,a4,a5
    80006198:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000619c:	6398                	ld	a4,0(a5)
    8000619e:	9732                	add	a4,a4,a2
    800061a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061a2:	4609                	li	a2,2
    800061a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ac:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061b0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061b4:	6794                	ld	a3,8(a5)
    800061b6:	0026d703          	lhu	a4,2(a3)
    800061ba:	8b1d                	andi	a4,a4,7
    800061bc:	0706                	slli	a4,a4,0x1
    800061be:	96ba                	add	a3,a3,a4
    800061c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061c8:	6798                	ld	a4,8(a5)
    800061ca:	00275783          	lhu	a5,2(a4)
    800061ce:	2785                	addiw	a5,a5,1
    800061d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061d8:	100017b7          	lui	a5,0x10001
    800061dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061e0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061e4:	0001c917          	auipc	s2,0x1c
    800061e8:	c6490913          	addi	s2,s2,-924 # 80021e48 <disk+0x128>
  while(b->disk == 1) {
    800061ec:	4485                	li	s1,1
    800061ee:	00b79c63          	bne	a5,a1,80006206 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061f2:	85ca                	mv	a1,s2
    800061f4:	8556                	mv	a0,s5
    800061f6:	ffffc097          	auipc	ra,0xffffc
    800061fa:	e5e080e7          	jalr	-418(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800061fe:	004aa783          	lw	a5,4(s5)
    80006202:	fe9788e3          	beq	a5,s1,800061f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006206:	f8042903          	lw	s2,-128(s0)
    8000620a:	00290713          	addi	a4,s2,2
    8000620e:	0712                	slli	a4,a4,0x4
    80006210:	0001c797          	auipc	a5,0x1c
    80006214:	b1078793          	addi	a5,a5,-1264 # 80021d20 <disk>
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000621e:	0001c997          	auipc	s3,0x1c
    80006222:	b0298993          	addi	s3,s3,-1278 # 80021d20 <disk>
    80006226:	00491713          	slli	a4,s2,0x4
    8000622a:	0009b783          	ld	a5,0(s3)
    8000622e:	97ba                	add	a5,a5,a4
    80006230:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006234:	854a                	mv	a0,s2
    80006236:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000623a:	00000097          	auipc	ra,0x0
    8000623e:	b9c080e7          	jalr	-1124(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006242:	8885                	andi	s1,s1,1
    80006244:	f0ed                	bnez	s1,80006226 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006246:	0001c517          	auipc	a0,0x1c
    8000624a:	c0250513          	addi	a0,a0,-1022 # 80021e48 <disk+0x128>
    8000624e:	ffffb097          	auipc	ra,0xffffb
    80006252:	a3c080e7          	jalr	-1476(ra) # 80000c8a <release>
}
    80006256:	70e6                	ld	ra,120(sp)
    80006258:	7446                	ld	s0,112(sp)
    8000625a:	74a6                	ld	s1,104(sp)
    8000625c:	7906                	ld	s2,96(sp)
    8000625e:	69e6                	ld	s3,88(sp)
    80006260:	6a46                	ld	s4,80(sp)
    80006262:	6aa6                	ld	s5,72(sp)
    80006264:	6b06                	ld	s6,64(sp)
    80006266:	7be2                	ld	s7,56(sp)
    80006268:	7c42                	ld	s8,48(sp)
    8000626a:	7ca2                	ld	s9,40(sp)
    8000626c:	7d02                	ld	s10,32(sp)
    8000626e:	6de2                	ld	s11,24(sp)
    80006270:	6109                	addi	sp,sp,128
    80006272:	8082                	ret

0000000080006274 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006274:	1101                	addi	sp,sp,-32
    80006276:	ec06                	sd	ra,24(sp)
    80006278:	e822                	sd	s0,16(sp)
    8000627a:	e426                	sd	s1,8(sp)
    8000627c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000627e:	0001c497          	auipc	s1,0x1c
    80006282:	aa248493          	addi	s1,s1,-1374 # 80021d20 <disk>
    80006286:	0001c517          	auipc	a0,0x1c
    8000628a:	bc250513          	addi	a0,a0,-1086 # 80021e48 <disk+0x128>
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	948080e7          	jalr	-1720(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006296:	10001737          	lui	a4,0x10001
    8000629a:	533c                	lw	a5,96(a4)
    8000629c:	8b8d                	andi	a5,a5,3
    8000629e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a4:	689c                	ld	a5,16(s1)
    800062a6:	0204d703          	lhu	a4,32(s1)
    800062aa:	0027d783          	lhu	a5,2(a5)
    800062ae:	04f70863          	beq	a4,a5,800062fe <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062b6:	6898                	ld	a4,16(s1)
    800062b8:	0204d783          	lhu	a5,32(s1)
    800062bc:	8b9d                	andi	a5,a5,7
    800062be:	078e                	slli	a5,a5,0x3
    800062c0:	97ba                	add	a5,a5,a4
    800062c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062c4:	00278713          	addi	a4,a5,2
    800062c8:	0712                	slli	a4,a4,0x4
    800062ca:	9726                	add	a4,a4,s1
    800062cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062d0:	e721                	bnez	a4,80006318 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062d2:	0789                	addi	a5,a5,2
    800062d4:	0792                	slli	a5,a5,0x4
    800062d6:	97a6                	add	a5,a5,s1
    800062d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062de:	ffffc097          	auipc	ra,0xffffc
    800062e2:	dda080e7          	jalr	-550(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    800062e6:	0204d783          	lhu	a5,32(s1)
    800062ea:	2785                	addiw	a5,a5,1
    800062ec:	17c2                	slli	a5,a5,0x30
    800062ee:	93c1                	srli	a5,a5,0x30
    800062f0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062f4:	6898                	ld	a4,16(s1)
    800062f6:	00275703          	lhu	a4,2(a4)
    800062fa:	faf71ce3          	bne	a4,a5,800062b2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062fe:	0001c517          	auipc	a0,0x1c
    80006302:	b4a50513          	addi	a0,a0,-1206 # 80021e48 <disk+0x128>
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	984080e7          	jalr	-1660(ra) # 80000c8a <release>
}
    8000630e:	60e2                	ld	ra,24(sp)
    80006310:	6442                	ld	s0,16(sp)
    80006312:	64a2                	ld	s1,8(sp)
    80006314:	6105                	addi	sp,sp,32
    80006316:	8082                	ret
      panic("virtio_disk_intr status");
    80006318:	00002517          	auipc	a0,0x2
    8000631c:	60850513          	addi	a0,a0,1544 # 80008920 <syscalls+0x3e8>
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	220080e7          	jalr	544(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
